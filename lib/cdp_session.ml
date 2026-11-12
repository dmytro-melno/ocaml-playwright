open Types

type t = cdp_session

let equal (a : t) (b : t) = Channel.equal a.cdp_channel b.cdp_channel
let compare (a : t) (b : t) = Channel.compare a.cdp_channel b.cdp_channel
let hash (t : t) = Channel.hash t.cdp_channel

(* The session is over: it was detached, or its target or the connection to it went away. *)
let did_close (session : t) =
    if not session.cdp_detached then begin
        session.cdp_detached <- true;
        ignore (Emitter.emit (Channel.conn session.cdp_channel) session.cdpe_close session)
    end

let handle_event (session : t) : Protocol.Cdp_session.event -> unit = function
    | Event { method_; params } -> ignore (Emitter.emit (Channel.conn session.cdp_channel) session.cdpe_event (method_, Option.value params ~default:(`Assoc [])))
    | Close -> did_close session

let create (channel : Protocol.Cdp_session.t) : t =
    let session = { cdp_channel = channel; cdp_detached = false; cdpe_event = Emitter.create (); cdpe_close = Emitter.create () } in
    Protocol.Cdp_session.listen channel (handle_event session);
    Channel.on_lost channel (fun _ -> did_close session);
    session

let send ?params method_ (session : t) : Yojson.Safe.t = Protocol.Cdp_session.send ~method_ ?params session.cdp_channel
let detach (session : t) = Connection.detached (Channel.conn session.cdp_channel) (fun () -> Protocol.Cdp_session.detach session.cdp_channel)

(* [listener] receives the name and parameters of every event of the session. *)
let on_event listener (session : t) = Disposable.listener (Emitter.on session.cdpe_event (fun (name, params) -> listener name params))
let on_close listener (session : t) = Disposable.listener (Emitter.on session.cdpe_close listener)
