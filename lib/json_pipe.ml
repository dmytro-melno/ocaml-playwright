(* A message pipe that the driver holds open to a Playwright server.  It carries the protocol of
   a remote connection, see {!Remote}. *)

type t = {
    channel : Channel.t;
    inbox : Json.t option Eio.Stream.t;  (* [None] marks the end *)
    mutable close_reason : string option;
}

type Connection.impl += Json_pipe of t

(* Messages are collected from the moment the pipe exists, so that none is lost before the
   remote connection starts reading. *)
let create (channel : Channel.t) =
    let pipe = { channel; inbox = Eio.Stream.create max_int; close_reason = None } in
    channel.impl <- Json_pipe pipe;
    channel.on_event <-
        (fun name params ->
            match Protocol.Json_pipe.event_of_json channel.conn name params with
            | Some (Message { message }) -> Eio.Stream.add pipe.inbox (Some message)
            | Some (Closed { reason }) ->
                if pipe.close_reason = None then pipe.close_reason <- reason;
                Eio.Stream.add pipe.inbox None
            | None -> ())

let of_channel (channel : Channel.t) =
    match channel.impl with
    | Json_pipe pipe -> pipe
    | _ -> Json.decode_error "object %S is a %s, not a JsonPipe" channel.guid channel.type_

let close pipe =
    (try Protocol.Json_pipe.close pipe.channel with Error.E _ -> ());
    Eio.Stream.add pipe.inbox None

(* The pipe as a transport.  It ends when the pipe is closed or the connection that the pipe
   itself lives on is; [on_end] runs first. *)
let transport ~on_end pipe : Transport.t =
    let ended = ref false in
    let receive () =
        if !ended then None
        else
            let message =
                Eio.Fiber.first
                    (fun () -> Eio.Stream.take pipe.inbox)
                    (fun () ->
                        ignore (Eio.Promise.await (Connection.closed pipe.channel.conn));
                        None)
            in
            if message = None then begin
                ended := true;
                on_end ()
            end;
            message
    in
    { send = (fun message -> Protocol.Json_pipe.send ~message pipe.channel); receive }
