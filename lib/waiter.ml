(* Waiting for events.

   A waiter collects the events it is interested in from the moment it is created, so nothing
   that happens between starting an action and waiting for its effect is missed.  The fiber that
   waits examines them itself, which lets predicates be arbitrary user code. *)

open Eio.Std

type 'a t = {
    conn : Connection.t;
    events : ('a, Error.t) result Eio.Stream.t;
    deadline : float option;
    timeout_message : unit -> string;
    mutable cleanups : (unit -> unit) list;
}

(* [timeout] is in milliseconds and counts from now; [0.] waits forever. *)
let create (conn : Connection.t) ~timeout ~timeout_message =
    let deadline = if timeout > 0. then Some (Eio.Time.now conn.clock +. (timeout /. 1000.)) else None in
    { conn; events = Eio.Stream.create max_int; deadline; timeout_message; cleanups = [] }

let dispose t =
    List.iter (fun cleanup -> cleanup ()) t.cleanups;
    t.cleanups <- []

(* Collects the events of [emitter] that [select] keeps. *)
let listen t emitter select =
    let cleanup = Emitter.subscribe emitter (fun event -> Option.iter (fun value -> Eio.Stream.add t.events (Ok value)) (select event)) in
    t.cleanups <- cleanup :: t.cleanups

(* Makes the wait fail when [emitter] fires an event for which [error] returns a reason. *)
let reject_on t emitter error =
    let cleanup = Emitter.subscribe emitter (fun event -> Option.iter (fun error -> Eio.Stream.add t.events (Error error)) (error event)) in
    t.cleanups <- cleanup :: t.cleanups

let reject t error = Eio.Stream.add t.events (Error error)

(* Returns the first collected event that [select] accepts. *)
let next t select =
    let rec take () =
        match Eio.Stream.take t.events with
        | Error error -> raise (Error.E error)
        | Ok event -> (match select event with Some value -> value | None -> take ())
    in
    let guarded () = Fiber.first take (fun () -> raise (Error.E (Promise.await (Connection.closed t.conn)))) in
    match t.deadline with
    | None -> guarded ()
    | Some deadline ->
        let remaining = deadline -. Eio.Time.now t.conn.clock in
        let timed_out () = raise (Error.E (Error.make ~kind:Timeout (t.timeout_message ()))) in
        if remaining <= 0. then
            (* Out of time: still take what has already arrived. *)
            match Eio.Stream.take_nonblocking t.events with
            | None -> timed_out ()
            | Some (Error error) -> raise (Error.E error)
            | Some (Ok event) -> (match select event with Some value -> value | None -> timed_out ())
        else
            match Eio.Time.with_timeout t.conn.clock remaining (fun () -> Ok (guarded ())) with
            | Ok value -> value
            | Error `Timeout -> timed_out ()

let using conn ~timeout ~timeout_message f =
    let t = create conn ~timeout ~timeout_message in
    Fun.protect ~finally:(fun () -> dispose t) (fun () -> f t)

let format_timeout timeout = Printf.sprintf "%.0f" timeout
