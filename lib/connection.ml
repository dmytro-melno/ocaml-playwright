(* The client side of the Playwright RPC connection.

   The driver owns a tree of remote objects.  It announces each one with [__create__], moves it
   with [__adopt__] and retires it (and its whole subtree) with [__dispose__].  The client mirrors
   that tree as {!channel} values, sends commands addressed to them and receives their events.

   Concurrency model: a single reader fiber decodes every incoming message and runs the object's
   event hook synchronously, so client-side state is always updated in protocol order.  Hooks must
   not block; anything that may is given a fiber of its own: user callbacks with {!handle}, which
   limits how many of them run at a time, and follow-up commands with {!fork}.  The reader never
   waits for either.

   Lifetime: a connection ends exactly once, in {!close}, whatever the cause: the program closing
   it, the driver going away, a transport failure or a message that cannot be understood.  Ending
   it is one step that does not block: the commands in flight fail, every object that still
   exists is told that it is lost and settles its own state (see [on_lost]), and the tables are
   emptied.  No fiber is left waiting on a connection that has ended. *)

open Eio.Std

(* Where the fibers that serve a Playwright instance run: the readers of its connections, the
   handlers of its events and the work that follows from them.  It exists for as long as the
   connection to the driver runs, and is shared with the connections made through that one to
   Playwright servers, so that a handler lives as long as the instance and no longer. *)
type scope = {
    mutable switch : Switch.t option;
    (* What the events of the instance may cost at any moment: see {!handle}. *)
    handler_concurrency : int;
    handler_backlog : int;
    mutable running : int;  (* handler calls in progress *)
    waiting : (unit -> unit) Queue.t;  (* what starts those that wait for one of them to end, oldest first *)
    mutable admitting : bool;  (* the waiting ones are being started, by a handler that has just ended *)
}

let default_handler_concurrency = 1024
let default_handler_backlog = 65536

type t = {
    transport : Transport.t;
    scope : scope;
    owns_scope : bool;
    clock : float Eio.Time.clock_ty r;
    objects : (string, channel) Hashtbl.t;
    pending : (string, (Json.t, Error.t) result -> unit) Hashtbl.t;  (* what to do with the reply to each command in flight *)
    outbox : Json.t Eio.Stream.t;
    id_prefix : string;
    mutable last_id : int;
    mutable last_object : int;
    mutable closed : Error.t option;
    closed_promise : Error.t Promise.t;
    closed_resolver : Error.t Promise.u;
    stopped_promise : unit Promise.t;  (* resolved when {!run} has returned *)
    stopped_resolver : unit Promise.u;
    mutable factory : channel -> impl;  (* makes the client side of an object that the driver announces *)
    report : string -> exn -> Printexc.raw_backtrace -> unit;
    trace : (string -> unit) option;
    render_value : Json.t -> string;
}

and channel = {
    conn : t;
    guid : string;
    type_ : string;
    order : int;  (* of creation, within the connection *)
    mutable initializer_ : Json.t;  (* [`Null] once a client object has been built from it *)
    mutable parent : channel option;
    children : (string, channel) Hashtbl.t;
    mutable impl : impl;
    mutable on_event : string -> Json.t -> unit;
    (* Called when the connection ends while the object exists, with the reason.  The object is
       gone with it: this is where it settles what the driver can no longer tell it to. *)
    mutable on_lost : Error.t -> unit;
    mutable disposed : bool;
    mutable collected : bool;  (* disposed by the driver's garbage collector while still referenced *)
}

(* The client object attached to a channel.  Extended by [Types]. *)
and impl = ..

type impl += No_impl

let make_channel conn ~parent ~guid ~type_ ~initializer_ =
    conn.last_object <- conn.last_object + 1;
    let channel =
        { conn; guid; type_; order = conn.last_object; initializer_; parent; children = Hashtbl.create 4; impl = No_impl;
          on_event = (fun _ _ -> ()); on_lost = ignore; disposed = false; collected = false }
    in
    Hashtbl.replace conn.objects guid channel;
    Option.iter (fun (p : channel) -> Hashtbl.replace p.children guid channel) parent;
    channel

let random_prefix () =
    let state = Random.State.make_self_init () in
    String.init 4 (fun _ -> Char.chr (Char.code 'a' + Random.State.int state 26))

let make ~scope ~owns_scope ~clock ~report ~trace ~render_value transport =
    let closed_promise, closed_resolver = Promise.create () in
    let stopped_promise, stopped_resolver = Promise.create () in
    let conn =
        { transport; scope; owns_scope; clock; objects = Hashtbl.create 256; pending = Hashtbl.create 64; outbox = Eio.Stream.create max_int;
          id_prefix = random_prefix (); last_id = 0; last_object = 0; closed = None; closed_promise; closed_resolver; stopped_promise;
          stopped_resolver; factory = (fun _ -> No_impl); report; trace; render_value }
    in
    ignore (make_channel conn ~parent:None ~guid:"" ~type_:"Root" ~initializer_:(`Assoc []));
    conn

(* The connection to a driver.  Running it makes the scope of the instance. *)
let create ~clock ~report ?trace ?(handler_concurrency = default_handler_concurrency) ?(handler_backlog = default_handler_backlog) ~render_value
        transport =
    if handler_concurrency < 1 then invalid_arg "Playwright: handler_concurrency must be positive";
    if handler_backlog < 0 then invalid_arg "Playwright: handler_backlog must not be negative";
    let scope = { switch = None; handler_concurrency; handler_backlog; running = 0; waiting = Queue.create (); admitting = false } in
    make ~scope ~owns_scope:true ~clock:(clock :> float Eio.Time.clock_ty r) ~report ~trace ~render_value transport

(* A connection that is relayed by [parent], which lends it its scope and settings. *)
let create_relayed (parent : t) transport =
    make ~scope:parent.scope ~owns_scope:false ~clock:parent.clock ~report:parent.report ~trace:parent.trace ~render_value:parent.render_value
        transport

let root conn =
    match Hashtbl.find_opt conn.objects "" with
    | Some root -> root
    | None -> raise (Error.E (Option.value conn.closed ~default:(Error.target_closed ())))

let find conn guid = Hashtbl.find_opt conn.objects guid
let is_closed conn = conn.closed <> None
let closed conn = conn.closed_promise
let stopped conn = conn.stopped_promise

let is_cancellation = Fibers.is_cancellation

(* Runs [f] in a fiber of its own in the scope of the instance, and tells whether it did: nothing
   is started once the scope is gone.  The fiber starts immediately and runs until it first
   blocks.  It is cancelled when the instance is closed. *)
let forked conn what f =
    match conn.scope.switch with
    | None -> false
    | Some sw ->
        let started = ref false in
        (try
            Fiber.fork_daemon ~sw (fun () ->
                started := true;
                (try f () with ex when not (is_cancellation ex) -> conn.report what ex (Printexc.get_raw_backtrace ()));
                `Stop_daemon)
         with ex when is_cancellation ex -> ());
        !started

(* Internal follow-up work: what the client itself does in answer to an event.  It is short and
   there is no more of it than there are events, so it is not counted like {!handle}'s. *)
let fork conn what f = ignore (forked conn what f)

(* Every object of the connection, each after the objects below it, those in the order in which
   they were created: a page comes after its frames and workers, a context after its pages. *)
let objects_bottom_up conn =
    (* [visited] is in reverse. *)
    let rec visit visited (channel : channel) =
        let children = Hashtbl.fold (fun _ child acc -> child :: acc) channel.children [] in
        let children = List.sort (fun (a : channel) (b : channel) -> Int.compare a.order b.order) children in
        channel :: List.fold_left visit visited children
    in
    match Hashtbl.find_opt conn.objects "" with
    | Some root -> List.rev (visit [] root)
    | None -> []

(* The single transition to closed.  It does not block, and may be made from any fiber:
   - every command in flight, and every later one, fails with [error];
   - every object is told that it is lost, which is when the close and disconnect events that
     the driver did not get to send are emitted; their handlers start right away;
   - the tables are emptied, so that a closed connection retains nothing. *)
let close conn error =
    if conn.closed = None then begin
        conn.closed <- Some error;
        let pending = Hashtbl.fold (fun _ settle acc -> settle :: acc) conn.pending [] in
        Hashtbl.reset conn.pending;
        List.iter (fun settle -> settle (Error error)) pending;
        let objects = objects_bottom_up conn in
        List.iter
            (fun (channel : channel) ->
                try channel.on_lost error with ex when not (is_cancellation ex) -> conn.report "closing the connection" ex (Printexc.get_raw_backtrace ()))
            objects;
        List.iter
            (fun (channel : channel) ->
                channel.disposed <- true;
                channel.on_event <- (fun _ _ -> ());
                channel.on_lost <- ignore;
                Hashtbl.reset channel.children)
            objects;
        Hashtbl.reset conn.objects;
        Promise.resolve conn.closed_resolver error
    end

(* {1 Handlers}

   A handler is user code that an event calls: a listener, a route handler, an exposed function.
   Each call gets a fiber of its own, because it may block, typically on the driver, whose
   reply only the reader can deliver.  Calls start in the order of their events and, as long as
   there is room, at once, in the state that the event left things in.

   The reader cannot be made to wait for them, so events arrive at their own pace: a page that
   logs ten thousand lines calls a console listener ten thousand times before the first reply
   to anything those calls ask can be read.  Two numbers keep that within bounds:
   - no more than [handler_concurrency] calls are in progress at a time; the others wait for
     their turn, which costs little more than the event itself;
   - no more than [handler_backlog] wait.  Beyond that the handlers are not keeping up, or not
     returning at all, and the connection is given up rather than the memory: it is closed with
     an error that says so, which is also reported.  No call is ever dropped: those that wait
     still get their turn for as long as the instance lives. *)

let end_handler scope =
    scope.running <- scope.running - 1;
    (* One loop starts all that can start, including after the calls that end while it runs:
       started from the end of each of those in turn, they would nest without bound. *)
    if not scope.admitting then begin
        scope.admitting <- true;
        while scope.running < scope.handler_concurrency && not (Queue.is_empty scope.waiting) do
            (Queue.take scope.waiting) ()
        done;
        scope.admitting <- false
    end

let begin_handler conn what f =
    let scope = conn.scope in
    scope.running <- scope.running + 1;
    if not (forked conn what (fun () -> Fun.protect f ~finally:(fun () -> end_handler scope))) then scope.running <- scope.running - 1

let handle conn what f =
    let scope = conn.scope in
    if scope.switch <> None then
        if scope.running < scope.handler_concurrency && Queue.is_empty scope.waiting then begin_handler conn what f
        else begin
            Queue.add (fun () -> begin_handler conn what f) scope.waiting;
            (* The events that closing itself causes are few, and their handlers the last to be called. *)
            if Queue.length scope.waiting > scope.handler_backlog && conn.closed = None then begin
                let error =
                    Error.target_closed
                        ~message:
                            (Printf.sprintf
                                 "The Playwright connection was closed because event handlers do not keep up: %d calls are in progress and %d more are waiting (the last one for: %s)"
                                 scope.running scope.handler_backlog what)
                        ()
                in
                conn.report "event handlers" (Error.E error) (Printexc.get_callstack 0);
                close conn error
            end
        end

let enqueue conn (message : Json.t) =
    if conn.closed = None then begin
        Option.iter (fun trace -> trace ("SEND> " ^ Json.to_string message)) conn.trace;
        Eio.Stream.add conn.outbox message
    end

(* Sends a command and waits for its reply, which [decode] turns into the result.  [timeout]
   is in milliseconds and enforced by the driver; [0.] disables it.

   The reply is decoded by the reader, before the command counts as answered: a reply that
   cannot be understood is a protocol failure like any other, and the caller sees the error that
   the connection is closed with.

   If the calling fiber is cancelled, the driver is asked to abort the command.  That is only a
   request: the command may have been carried out already, and what it made then belongs to
   nobody.  [orphan] is given the result of such a command, in a fiber of the instance, to
   release what is in it; without it the late reply is dropped.

   The driver does not abort every command cleanly: one that makes a page or a context can
   leave it behind, out of anybody's reach.  Such a command is not [abortable]: it is left to
   finish, and its result goes to [orphan]. *)
let call ?(timeout = 0.) ?orphan ?(abortable = true) (channel : channel) method_ (params : Json.t) (decode : Json.t -> 'a) : 'a =
    let conn = channel.conn in
    Option.iter (fun error -> raise (Error.E error)) conn.closed;
    if channel.collected then Error.raise_ "The object has been collected to prevent unbounded heap growth.";
    conn.last_id <- conn.last_id + 1;
    let id = Printf.sprintf "%s@%d" conn.id_prefix conn.last_id in
    let metadata = if timeout > 0. then `Assoc [ "timeout", Json.float timeout ] else `Assoc [] in
    let promise, resolver = Promise.create () in
    Hashtbl.replace conn.pending id (fun reply -> Promise.resolve resolver (Result.map decode reply));
    enqueue conn (`Assoc [ "id", `String id; "guid", `String channel.guid; "method", `String method_; "params", params; "metadata", metadata ]);
    match Promise.await promise with
    | Ok result -> result
    | Error error -> raise (Error.E error)
    | exception ex ->
        let backtrace = Printexc.get_raw_backtrace () in
        let release result = Option.iter (fun orphan -> fork conn "releasing the result of a cancelled command" (fun () -> orphan result)) orphan in
        (match Promise.peek promise with
        | Some (Ok result) -> release result  (* the reply and the cancellation crossed *)
        | Some (Error _) -> ()
        | None ->
            if Hashtbl.mem conn.pending id then begin
                (match orphan with
                | None -> Hashtbl.remove conn.pending id
                | Some _ -> Hashtbl.replace conn.pending id (function Ok reply -> release (decode reply) | Error _ -> ()));
                if abortable then
                    enqueue conn
                        (`Assoc [ "guid", `String channel.guid; "method", `String "__abort__";
                                  "params", `Assoc [ "id", `String id; "reason", `String "Cancelled by the client" ] ])
            end);
        Printexc.raise_with_backtrace ex backtrace

(* {1 Work that outlives its caller}

   Closing, disposing and cleaning up must not be left half done because the fiber that asked for
   them was cancelled: usually that is exactly when they are asked for.  Such work is carried out
   in the scope of the instance.  The caller waits for it, and a caller that is cancelled only
   stops waiting. *)

type 'a outcome = ('a, exn * Printexc.raw_backtrace) result

(* Runs [f] in the scope of the instance and passes its outcome to [settle], exactly once.  [f]
   starts immediately and runs until it first blocks.  If the instance ends first, the outcome is
   the error that the connection was closed with. *)
let run_detached conn (f : unit -> 'a) (settle : 'a outcome -> unit) =
    let lost () = Error (Error.E (Option.value conn.closed ~default:(Error.target_closed ())), Printexc.get_callstack 0) in
    let started = ref false in
    Option.iter
        (fun sw ->
            Fiber.fork_daemon ~sw (fun () ->
                started := true;
                settle
                    (match f () with
                    | value -> Ok value
                    | exception ex when is_cancellation ex -> lost ()
                    | exception ex -> Error (ex, Printexc.get_raw_backtrace ()));
                `Stop_daemon))
        conn.scope.switch;
    (* Nothing starts in a scope that is gone or on its way out. *)
    if not !started then settle (lost ())

let start conn f : 'a outcome Promise.t =
    let promise, resolver = Promise.create () in
    run_detached conn f (Promise.resolve resolver);
    promise

let join (outcome : 'a outcome Promise.t) =
    match Promise.await outcome with
    | Ok value -> value
    | Error (ex, backtrace) -> Printexc.raise_with_backtrace ex backtrace

(* [f ()], which cancelling the caller does not interrupt. *)
let detached conn f = join (start conn f)

(* For the step that releases something once an operation is over.  It is carried out even when
   the calling fiber is being cancelled, and it never raises: "target closed" means that there
   was nothing left to release, and any other failure is reported. *)
let cleanup conn what f =
    let outcome =
        start conn (fun () ->
            try f () with
            | Error.E { kind = Target_closed; _ } -> ()
            | ex when not (is_cancellation ex) -> conn.report what ex (Printexc.get_raw_backtrace ()))
    in
    try ignore (Promise.await outcome : unit outcome) with ex when is_cancellation ex -> ()

(* [f ()], with [undo] as its clean-up if it fails or is cancelled: for the steps that follow
   the making of something, which would otherwise be left behind. *)
let guard conn what ~undo f =
    try f ()
    with ex ->
        let backtrace = Printexc.get_raw_backtrace () in
        cleanup conn what undo;
        Printexc.raise_with_backtrace ex backtrace

(* [Fun.protect] for a [finally] that talks to the driver: see {!cleanup}. *)
let protect conn what ~finally f =
    match f () with
    | result -> cleanup conn what finally; result
    | exception ex ->
        let backtrace = Printexc.get_raw_backtrace () in
        cleanup conn what finally;
        Printexc.raise_with_backtrace ex backtrace

let rec dispose (channel : channel) ~collected =
    Option.iter (fun (p : channel) -> Hashtbl.remove p.children channel.guid) channel.parent;
    Hashtbl.remove channel.conn.objects channel.guid;
    channel.disposed <- true;
    channel.collected <- collected;
    let children = Hashtbl.fold (fun _ child acc -> child :: acc) channel.children [] in
    List.iter (fun child -> dispose child ~collected) children

let adopt (parent : channel) (child : channel) =
    Option.iter (fun (p : channel) -> Hashtbl.remove p.children child.guid) child.parent;
    Hashtbl.replace parent.children child.guid child;
    child.parent <- Some parent

(* Whatever goes wrong in here means that the two sides no longer agree on the protocol or on the
   state of the objects, and ends the connection: see {!run}. *)
let dispatch conn (message : Json.t) =
    let module D = Json.Decode in
    match D.member "id" message with
    | Some id ->
        let id = match id with `String s -> s | `Int i -> string_of_int i | j -> D.expected "a call id" j in
        (* A missing entry is the reply to a cancelled command. *)
        (match Hashtbl.find_opt conn.pending id with
        | None -> ()
        | Some settle ->
            let reply =
                match D.member "error" message with
                | Some error when D.member "result" message = None ->
                    let log = Option.value (D.opt "log" (D.list D.string) message) ~default:[] in
                    let details = Option.value (D.member "errorDetails" message) ~default:`Null in
                    Error (Error.of_wire ~log ~details ~render_value:conn.render_value error)
                | _ -> Ok (Option.value (D.member "result" message) ~default:(`Assoc []))
            in
            (* [settle] decodes the result, and may fail.  The caller is released only by what is
               taken out of the table, so a failure leaves it to be failed with the connection. *)
            settle reply;
            Hashtbl.remove conn.pending id)
    | None ->
        let guid = D.req "guid" D.string message in
        let method_ = D.req "method" D.string message in
        let params = Option.value (D.member "params" message) ~default:(`Assoc []) in
        (match find conn guid with
        | None -> Json.decode_error "%s for unknown object %S" method_ guid
        | Some channel ->
            (match method_ with
            | "__create__" ->
                let initializer_ = Option.value (D.member "initializer" params) ~default:(`Assoc []) in
                let child =
                    make_channel conn ~parent:(Some channel) ~guid:(D.req "guid" D.string params)
                        ~type_:(D.req "type" D.string params) ~initializer_
                in
                child.impl <- conn.factory child;
                (* The client object holds the decoded initializer.  Keeping the JSON as well would
                   double what every request and response costs for as long as the driver keeps it. *)
                (match child.impl with No_impl -> () | _ -> child.initializer_ <- `Null)
            | "__adopt__" ->
                let child_guid = D.req "guid" D.string params in
                (match find conn child_guid with
                | Some child -> adopt channel child
                | None -> Json.decode_error "__adopt__ of unknown object %S" child_guid)
            | "__dispose__" -> dispose channel ~collected:(D.opt "reason" D.string params = Some "gc")
            | event -> channel.on_event event params))

let describe_failure = function
    | Json.Decode_error reason | Transport.Violation reason -> reason
    | Error.E error -> error.message
    | ex -> Printexc.to_string ex

(* Reads and dispatches messages until the transport ends or the connection is closed, and
   returns once nothing of the connection runs any more: for the connection to a driver, that
   includes the handlers of its instance, which are cancelled.

   [end_message] describes the end of the transport to the calls that it interrupts. *)
let run ?(end_message = fun () -> "The Playwright driver closed the connection") conn =
    let write () =
        while true do
            conn.transport.send (Eio.Stream.take conn.outbox)
        done
    in
    let read () =
        while conn.closed = None do
            match conn.transport.receive () with
            | None -> close conn (Error.target_closed ~message:(end_message ()) ())
            | Some message ->
                Option.iter (fun trace -> trace ("<RECV " ^ Json.to_string message)) conn.trace;
                (try dispatch conn message
                 with ex when not (is_cancellation ex) ->
                     conn.report "protocol message" ex (Printexc.get_raw_backtrace ());
                     close conn (Error.target_closed ~message:("The Playwright connection was closed after a protocol error: " ^ describe_failure ex) ()))
        done
    in
    let serve () =
        try Fiber.first (fun () -> Fiber.first read write) (fun () -> ignore (Promise.await conn.closed_promise))
        with ex ->
            let bt = Printexc.get_raw_backtrace () in
            close conn (Error.target_closed ~message:("The Playwright connection failed: " ^ describe_failure ex) ());
            if is_cancellation ex then Printexc.raise_with_backtrace ex bt
    in
    Fun.protect
        ~finally:(fun () -> Promise.resolve conn.stopped_resolver ())
        (fun () ->
            if conn.owns_scope then
                Switch.run (fun sw ->
                    conn.scope.switch <- Some sw;
                    Fun.protect
                        ~finally:(fun () ->
                            conn.scope.switch <- None;
                            Queue.clear conn.scope.waiting)
                        serve)
            else serve ())

(* Fails with a {!Error.Timeout} error unless [f] finishes within [timeout] milliseconds;
   [0.] waits forever. *)
let with_timeout conn ~timeout ~message f =
    if timeout <= 0. then f ()
    else
        match Eio.Time.with_timeout conn.clock (timeout /. 1000.) (fun () -> Ok (f ())) with
        | Ok value -> value
        | Error `Timeout -> raise (Error.E (Error.make ~kind:Timeout (message ())))
