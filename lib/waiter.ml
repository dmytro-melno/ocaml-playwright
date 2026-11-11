(* Waiting for events.

   A waiter collects the events it is interested in from the moment it is created, so nothing
   that happens between starting an action and waiting for its effect is missed.

   What it waits for is decided by a function that may be arbitrary user code, and may block.
   It is applied to each event when the event arrives, in the state that the event left things
   in, while the action is still under way: in a fiber of its own, which the connection's reader
   starts and does not wait for.  One event is examined at a time, in the order of arrival.

   The time limit is on the arrival of the event.  One that arrived in time counts, however long
   the action and the examination take; one that arrives later does not, whatever is still going
   on.  Neither the action nor the examination is interrupted when the time is up. *)

open Eio.Std

type 'a t = {
    conn : Connection.t;
    arrived : ('a, Error.t) result Queue.t;  (* what is still to be examined, and what ends the wait *)
    deadline : float option;
    timeout_message : unit -> string;
    mutable cleanups : (unit -> unit) list;
    mutable examine : unit -> unit;  (* has what arrived examined, unless that is being done *)
}

(* [timeout] is in milliseconds and counts from now; [0.] waits forever. *)
let create (conn : Connection.t) ~timeout ~timeout_message =
    let deadline = if timeout > 0. then Some (Eio.Time.now conn.clock +. (timeout /. 1000.)) else None in
    { conn; arrived = Queue.create (); deadline; timeout_message; cleanups = []; examine = ignore }

(* Stops collecting.  What was collected can still be examined. *)
let stop t =
    List.iter (fun cleanup -> cleanup ()) t.cleanups;
    t.cleanups <- []

let dispose t =
    stop t;
    Queue.clear t.arrived

let remaining t = Option.map (fun deadline -> deadline -. Eio.Time.now t.conn.clock) t.deadline

(* Called by the reader, which must not be held up: what is examined more slowly than it arrives
   is kept, up to the number of handler calls that may wait for their turn.  Beyond that the
   wait fails, when the examination gets there. *)
let add t item =
    if match remaining t with Some time -> time >= 0. | None -> true then begin
        let capacity = t.conn.scope.handler_backlog in
        if Queue.length t.arrived < capacity then Queue.add item t.arrived
        else begin
            stop t;
            Queue.add (Error (Error.make (Printf.sprintf "More than %d events are waiting to be examined: the predicate does not keep up" capacity))) t.arrived
        end;
        t.examine ()
    end

(* Collects the events of [emitter] that [select] keeps.  [select] runs in the reader. *)
let listen t emitter select =
    let cleanup = Emitter.subscribe emitter (fun event -> Option.iter (fun value -> add t (Ok value)) (select event)) in
    t.cleanups <- cleanup :: t.cleanups

(* Makes the wait fail when [emitter] fires an event for which [error] returns a reason. *)
let reject_on t emitter error =
    let cleanup = Emitter.subscribe emitter (fun event -> Option.iter (fun error -> add t (Error error)) (error event)) in
    t.cleanups <- cleanup :: t.cleanups

let reject t error = add t (Error error)

(* Runs [action] and returns its result with the first one that [select] gives for an event,
   those collected so far included.  A waiter serves one wait.

   The action is never interrupted by the wait.  If the wait fails, because the time is up,
   because of what {!reject_on} watches for, or in [select], that is raised when the action is
   over.  If the action fails, the wait is given up. *)
let around t action select =
    Switch.run @@ fun sw ->
    let outcome, resolver = Promise.create () in
    let settle result =
        (* Whatever comes now is of no use to anybody. *)
        dispose t;
        Promise.resolve resolver result
    in
    let failed ex = Error (ex, Printexc.get_raw_backtrace ()) in
    let examining = ref false in
    let examined = Eio.Condition.create () in
    let examination () =
        examining := true;
        let rec next () =
            if not (Promise.is_resolved outcome) then
                match Queue.take_opt t.arrived with
                | None -> ()
                | Some (Error error) -> settle (failed (Error.E error))
                | Some (Ok event) -> (match select event with Some value -> settle (Ok value) | None -> next ())
        in
        (try next () with ex when not (Fibers.is_cancellation ex) -> settle (failed ex));
        examining := false;
        Eio.Condition.broadcast examined
    in
    t.examine <- (fun () -> if not (!examining || Queue.is_empty t.arrived || Promise.is_resolved outcome) then Fiber.fork ~sw examination);
    Fun.protect ~finally:(fun () -> t.examine <- ignore) @@ fun () ->
    t.examine ();
    let result = action () in
    (* Nothing is left to be examined when no examination is under way: what is not settled by
       now waits for more to arrive. *)
    let rec verdict () =
        match Promise.peek outcome with
        | Some (Ok value) -> value
        | Some (Error (ex, backtrace)) -> Printexc.raise_with_backtrace ex backtrace
        | None when !examining ->
            Eio.Condition.await_no_mutex examined;
            verdict ()
        | None ->
            Option.iter (fun error -> raise (Error.E error)) (Promise.peek (Connection.closed t.conn));
            let change () = Fibers.first (fun () -> ignore (Promise.await outcome)) (fun () -> ignore (Promise.await (Connection.closed t.conn) : Error.t)) in
            (match remaining t with
            | None -> change ()
            | Some time when time > 0. -> (match Eio.Time.with_timeout t.conn.clock time (fun () -> Ok (change ())) with Ok () | Error `Timeout -> ())
            | Some _ -> raise (Error.E (Error.make ~kind:Timeout (t.timeout_message ()))));
            verdict ()
    in
    result, verdict ()

(* Without an action: the wait is for what happens by itself. *)
let next t select = snd (around t ignore select)

let using conn ~timeout ~timeout_message f =
    let t = create conn ~timeout ~timeout_message in
    Fun.protect ~finally:(fun () -> dispose t) (fun () -> f t)

let format_timeout timeout = Printf.sprintf "%.0f" timeout
