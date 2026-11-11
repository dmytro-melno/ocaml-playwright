open Types

type t = cdp_session

let handle_event (session : t) name params =
    let conn = session.cdp_channel.conn in
    match Protocol.Cdp_session.event_of_json conn name params with
    | Some (Event { method_; params }) -> ignore (Emitter.emit conn session.cdpe_event (method_, Option.value params ~default:(`Assoc [])))
    | Some Close -> ignore (Emitter.emit conn session.cdpe_close session)
    | None -> ()

let create (channel : Channel.t) =
    let session = { cdp_channel = channel; cdpe_event = Emitter.create (); cdpe_close = Emitter.create () } in
    channel.impl <- Cdp_session session;
    channel.on_event <- handle_event session

let send ?params method_ (session : t) : Yojson.Safe.t = Protocol.Cdp_session.send ~method_ ?params session.cdp_channel
let detach (session : t) = Protocol.Cdp_session.detach session.cdp_channel

(* [listener] receives the name and parameters of every event of the session. *)
let on_event listener (session : t) = Emitter.on session.cdpe_event listener
let off_event listener (session : t) = Emitter.off session.cdpe_event listener
let on_close listener (session : t) = Emitter.on session.cdpe_close listener
