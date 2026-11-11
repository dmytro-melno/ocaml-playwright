(* The client side of the Playwright RPC connection.

   The driver owns a tree of remote objects.  It announces each one with [__create__], moves it
   with [__adopt__] and retires it (and its whole subtree) with [__dispose__].  The client mirrors
   that tree as {!channel} values, sends commands addressed to them and receives their events.

   Concurrency model: a single reader fiber decodes every incoming message and runs the object's
   event hook synchronously, so client-side state is always updated in protocol order.  Hooks must
   not block; anything that may (user callbacks, follow-up commands) is forked with {!fork}. *)

open Eio.Std

type t = {
    transport : Transport.t;
    sw : Switch.t;
    clock : float Eio.Time.clock_ty r;
    objects : (string, channel) Hashtbl.t;
    pending : (string, (Json.t, Error.t) result Promise.u) Hashtbl.t;
    outbox : Json.t Eio.Stream.t;
    id_prefix : string;
    mutable last_id : int;
    mutable closed : Error.t option;
    closed_promise : Error.t Promise.t;
    closed_resolver : Error.t Promise.u;
    stopped_promise : unit Promise.t;  (* resolved when {!run} has returned *)
    stopped_resolver : unit Promise.u;
    mutable factory : channel -> unit;
    report : string -> exn -> Printexc.raw_backtrace -> unit;
    trace : (string -> unit) option;
    render_value : Json.t -> string;
}

and channel = {
    conn : t;
    guid : string;
    type_ : string;
    mutable initializer_ : Json.t;  (* [`Null] once a client object has been built from it *)
    mutable parent : channel option;
    children : (string, channel) Hashtbl.t;
    mutable impl : impl;
    mutable on_event : string -> Json.t -> unit;
    mutable disposed : bool;
    mutable collected : bool;  (* disposed by the driver's garbage collector while still referenced *)
}

(* The client object attached to a channel.  Extended by [Types]. *)
and impl = ..

type impl += No_impl

let make_channel conn ~parent ~guid ~type_ ~initializer_ =
    let channel =
        { conn; guid; type_; initializer_; parent; children = Hashtbl.create 4; impl = No_impl;
          on_event = (fun _ _ -> ()); disposed = false; collected = false }
    in
    Hashtbl.replace conn.objects guid channel;
    Option.iter (fun (p : channel) -> Hashtbl.replace p.children guid channel) parent;
    channel

let random_prefix () =
    let state = Random.State.make_self_init () in
    String.init 4 (fun _ -> Char.chr (Char.code 'a' + Random.State.int state 26))

let create ~sw ~clock ~report ?trace ~render_value transport =
    let closed_promise, closed_resolver = Promise.create () in
    let stopped_promise, stopped_resolver = Promise.create () in
    let conn =
        { transport; sw; clock = (clock :> float Eio.Time.clock_ty r); objects = Hashtbl.create 256; pending = Hashtbl.create 64;
          outbox = Eio.Stream.create max_int; id_prefix = random_prefix (); last_id = 0; closed = None;
          closed_promise; closed_resolver; stopped_promise; stopped_resolver; factory = (fun _ -> ()); report; trace; render_value }
    in
    ignore (make_channel conn ~parent:None ~guid:"" ~type_:"Root" ~initializer_:(`Assoc []));
    conn

let root conn = Hashtbl.find conn.objects ""
let find conn guid = Hashtbl.find_opt conn.objects guid
let is_closed conn = conn.closed <> None
let closed conn = conn.closed_promise
let stopped conn = conn.stopped_promise

let is_cancellation = function Eio.Cancel.Cancelled _ -> true | _ -> false

(* Runs [f], which is user code or internal follow-up work, in its own fiber.  The fiber starts
   immediately and runs until it first blocks, so callbacks begin in event order.  It does not
   keep the switch alive: callbacks still running when the program is done are cancelled. *)
let fork conn what f =
    if conn.closed = None then
        try
            Fiber.fork_daemon ~sw:conn.sw (fun () ->
                (try f () with ex when not (is_cancellation ex) -> conn.report what ex (Printexc.get_raw_backtrace ()));
                `Stop_daemon)
        with ex when is_cancellation ex -> ()

(* The single state transition to closed: every pending and future command fails with [error]. *)
let close conn error =
    if conn.closed = None then begin
        conn.closed <- Some error;
        let pending = Hashtbl.fold (fun _ resolver acc -> resolver :: acc) conn.pending [] in
        Hashtbl.reset conn.pending;
        List.iter (fun resolver -> Promise.resolve resolver (Error error)) pending;
        Promise.resolve conn.closed_resolver error
    end

let enqueue conn (message : Json.t) =
    Option.iter (fun trace -> trace ("SEND> " ^ Json.to_string message)) conn.trace;
    Eio.Stream.add conn.outbox message

(* Sends a command and waits for its reply.  [timeout] is in milliseconds and enforced by the
   driver; [0.] disables it.  If the calling fiber is cancelled the driver is asked to abort the
   command, and a reply that still arrives is dropped. *)
let call ?(timeout = 0.) (channel : channel) method_ (params : Json.t) : Json.t =
    let conn = channel.conn in
    Option.iter (fun error -> raise (Error.E error)) conn.closed;
    if channel.collected then Error.raise_ "The object has been collected to prevent unbounded heap growth.";
    conn.last_id <- conn.last_id + 1;
    let id = Printf.sprintf "%s@%d" conn.id_prefix conn.last_id in
    let metadata = if timeout > 0. then `Assoc [ "timeout", Json.float timeout ] else `Assoc [] in
    let promise, resolver = Promise.create () in
    Hashtbl.replace conn.pending id resolver;
    enqueue conn (`Assoc [ "id", `String id; "guid", `String channel.guid; "method", `String method_; "params", params; "metadata", metadata ]);
    match Promise.await promise with
    | Ok result -> result
    | Error error -> raise (Error.E error)
    | exception ex ->
        if Hashtbl.mem conn.pending id then begin
            Hashtbl.remove conn.pending id;
            if conn.closed = None then
                enqueue conn
                    (`Assoc [ "guid", `String channel.guid; "method", `String "__abort__";
                              "params", `Assoc [ "id", `String id; "reason", `String "Cancelled by the client" ] ])
        end;
        raise ex

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

let rec parent_of_type (channel : channel) type_ =
    match channel.parent with
    | Some p when p.type_ = type_ -> Some p
    | Some p -> parent_of_type p type_
    | None -> None

let dispatch conn (message : Json.t) =
    let module D = Json.Decode in
    match D.member "id" message with
    | Some id ->
        let id = match id with `String s -> s | `Int i -> string_of_int i | j -> D.expected "a call id" j in
        (* A missing entry is the reply to a cancelled command. *)
        (match Hashtbl.find_opt conn.pending id with
        | None -> ()
        | Some resolver ->
            Hashtbl.remove conn.pending id;
            let result =
                match D.member "error" message with
                | Some error when D.member "result" message = None ->
                    let log = Option.value (D.opt "log" (D.list D.string) message) ~default:[] in
                    let details = Option.value (D.member "errorDetails" message) ~default:`Null in
                    Error (Error.of_wire ~log ~details ~render_value:conn.render_value error)
                | _ -> Ok (Option.value (D.member "result" message) ~default:(`Assoc []))
            in
            Promise.resolve resolver result)
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
                conn.factory child;
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

(* Reads and dispatches messages until the transport ends or the connection is closed.
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
                 with ex when not (is_cancellation ex) -> conn.report "protocol message" ex (Printexc.get_raw_backtrace ()))
        done
    in
    Fun.protect
        ~finally:(fun () -> Promise.resolve conn.stopped_resolver ())
        (fun () ->
            try
                Fiber.first
                    (fun () -> Fiber.first read write)
                    (fun () -> ignore (Promise.await conn.closed_promise))
            with ex ->
                let bt = Printexc.get_raw_backtrace () in
                close conn (Error.target_closed ~message:("The Playwright connection failed: " ^ Printexc.to_string ex) ());
                if is_cancellation ex then Printexc.raise_with_backtrace ex bt)

(* Fails with a {!Error.Timeout} error unless [f] finishes within [timeout] milliseconds;
   [0.] waits forever. *)
let with_timeout conn ~timeout ~message f =
    if timeout <= 0. then f ()
    else
        match Eio.Time.with_timeout conn.clock (timeout /. 1000.) (fun () -> Ok (f ())) with
        | Ok value -> value
        | Error `Timeout -> raise (Error.E (Error.make ~kind:Timeout (message ())))
