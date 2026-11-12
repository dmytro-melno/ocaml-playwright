open Types

type t = tracing


let create session (channel : Protocol.Tracing.t) : t = { t_channel = channel; t_session = session }

let start ?name ?title ?(snapshots = false) ?(screenshots = false) ?(live = false) (t : t) =
    Protocol.Tracing.tracing_start ?name ~snapshot_dom:snapshots ~screencast:screenshots ~live t.t_channel;
    ignore (Protocol.Tracing.tracing_start_chunk ?name ?title t.t_channel : string)

let start_chunk ?name ?title (t : t) = ignore (Protocol.Tracing.tracing_start_chunk ?name ?title t.t_channel : string)

let group ?location (t : t) name =
    let location =
        Option.map (fun (file, line, column, _) : Protocol.Tracing.Tracing_group_location.t -> { file; line = Some line; column = Some column }) location
    in
    Protocol.Tracing.tracing_group ~name ?location t.t_channel

let group_end (t : t) = Protocol.Tracing.tracing_group_end t.t_channel

(* The driver names the files that make up the trace, and its utilities put them into one
   archive. *)
let stop_chunk ?path (t : t) =
    match path with
    | None -> ignore (Protocol.Tracing.tracing_stop_chunk ~mode:`Discard t.t_channel)
    | Some path ->
        let path = Files.absolute path in
        let result = Protocol.Tracing.tracing_stop_chunk ~mode:`Entries t.t_channel in
        Protocol.Local_utils.zip ~zip_file:path ~entries:(Option.value result.entries ~default:[]) ~mode:`Write ~include_sources:false
            (Local_utils.of_session t.t_session)

(* Tracing is stopped also when the trace could not be saved, which is the failure that counts. *)
let stop ?path (t : t) =
    let stop () = Protocol.Tracing.tracing_stop t.t_channel in
    Connection.guard (Channel.conn t.t_channel) "stopping tracing" ~undo:stop (fun () -> stop_chunk ?path t);
    stop ()
