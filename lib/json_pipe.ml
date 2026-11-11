(* A message pipe that the driver holds open to a Playwright server.  It carries the protocol of
   a remote connection, see {!Remote}. *)

type t = {
    channel : Channel.t;
    inbox : Json.t option Eio.Stream.t;  (* [None] marks the end *)
    mutable ended : bool;
    mutable close_reason : string option;
    (* Called when the connection that the pipe lives on ends, which leaves nothing to read from. *)
    mutable on_lost : Error.t -> unit;
}

type Connection.impl += Json_pipe of t

(* Marks the end of the pipe.  The messages that arrived before it are still read. *)
let finish pipe ~reason =
    if not pipe.ended then begin
        pipe.ended <- true;
        if pipe.close_reason = None then pipe.close_reason <- reason;
        Eio.Stream.add pipe.inbox None
    end

(* Messages are collected from the moment the pipe exists, so that none is lost before the
   remote connection starts reading. *)
let create (channel : Channel.t) =
    let pipe = { channel; inbox = Eio.Stream.create max_int; ended = false; close_reason = None; on_lost = ignore } in
    channel.impl <- Json_pipe pipe;
    channel.on_event <-
        (fun name params ->
            match Protocol.Json_pipe.event_of_json channel.conn name params with
            | Some (Message { message }) -> if not pipe.ended then Eio.Stream.add pipe.inbox (Some message)
            | Some (Closed { reason }) -> finish pipe ~reason
            | None -> ());
    channel.on_lost <-
        (fun error ->
            finish pipe ~reason:(Some error.message);
            pipe.on_lost error)

let of_channel (channel : Channel.t) =
    match channel.impl with
    | Json_pipe pipe -> pipe
    | _ -> Error.raise_ "Protocol error: object %S is a %s, not a JsonPipe" channel.guid channel.type_

(* It is the end of the pipe at once.  The driver is asked to close its end, whether or not it
   hears and whether or not the caller waits for that. *)
let close pipe =
    if not pipe.ended then begin
        finish pipe ~reason:None;
        Connection.cleanup pipe.channel.conn "closing a pipe" (fun () -> try Protocol.Json_pipe.close pipe.channel with Error.E _ -> ())
    end

(* The pipe as a transport, which ends when the pipe does. *)
let transport pipe : Transport.t =
    let drained = ref false in
    let receive () =
        if !drained then None
        else begin
            let message = Eio.Stream.take pipe.inbox in
            if message = None then drained := true;
            message
        end
    in
    { send = (fun message -> Protocol.Json_pipe.send ~message pipe.channel); receive }
