open Types

type t = cdp_session

(* The session is over: it was detached, or its target or the connection to it went away. *)
let did_close (session : t) =
    if not session.cdp_detached then begin
        session.cdp_detached <- true;
        ignore (Emitter.emit session.cdp_channel.conn session.cdpe_close session)
    end

let handle_event (session : t) name params =
    let conn = session.cdp_channel.conn in
    match Protocol.Cdp_session.event_of_json conn name params with
    | Some (Event { method_; params }) -> ignore (Emitter.emit conn session.cdpe_event (method_, Option.value params ~default:(`Assoc [])))
    | Some Close -> did_close session
    | None -> ()

let create (channel : Channel.t) =
    let session = { cdp_channel = channel; cdp_detached = false; cdpe_event = Emitter.create (); cdpe_close = Emitter.create (); cdp_listeners = [] } in
    channel.impl <- Cdp_session session;
    channel.on_event <- handle_event session;
    channel.on_lost <- (fun _ -> did_close session)

let send ?params method_ (session : t) : Yojson.Safe.t = Protocol.Cdp_session.send ~method_ ?params session.cdp_channel
let detach (session : t) = Connection.detached session.cdp_channel.conn (fun () -> Protocol.Cdp_session.detach session.cdp_channel)

(* [listener] receives the name and parameters of every event of the session. *)
let on_event listener (session : t) =
    let remove = Emitter.on session.cdpe_event (fun (name, params) -> listener name params) in
    session.cdp_listeners <- (listener, remove) :: session.cdp_listeners

let off_event listener (session : t) =
    match List.find_opt (fun (l, _) -> l == listener) session.cdp_listeners with
    | Some ((_, remove) as entry) ->
        session.cdp_listeners <- List.filter (fun e -> e != entry) session.cdp_listeners;
        remove ()
    | None -> ()

let on_close listener (session : t) = ignore (Emitter.on session.cdpe_close listener : unit -> unit)
