open Types

type t = tracing

let equal (a : t) (b : t) = Channel.equal a.t_channel b.t_channel
let compare (a : t) (b : t) = Channel.compare a.t_channel b.t_channel
let hash (t : t) = Channel.hash t.t_channel

let create session (channel : Protocol.Tracing.t) : t =
    { t_channel = channel; t_session = session; include_sources = false; is_live = false; traces_dir = None; stacks_id = None }

(* Where the traces of the browser that the context belongs to are kept. *)
let set_traces_dir (t : t) traces_dir = t.traces_dir <- traces_dir

let local_utils (t : t) = Local_utils.of_session t.t_session

let start_collecting_stacks (t : t) trace_name =
    t.stacks_id <- Some (Protocol.Local_utils.tracing_started ?traces_dir:t.traces_dir ~trace_name ~live:t.is_live (local_utils t))

let start ?name ?title ?(snapshots = false) ?(screenshots = false) ?(sources = false) ?(live = false) (t : t) =
    t.include_sources <- sources;
    t.is_live <- live;
    Protocol.Tracing.tracing_start ?name ~snapshot_dom:snapshots ~screencast:screenshots ~live t.t_channel;
    start_collecting_stacks t (Protocol.Tracing.tracing_start_chunk ?name ?title t.t_channel)

let start_chunk ?name ?title (t : t) = start_collecting_stacks t (Protocol.Tracing.tracing_start_chunk ?name ?title t.t_channel)
let group ?location name (t : t) =
    let location =
        Option.map (fun (file, line, column, _) : Protocol.Tracing.Tracing_group_location.t -> { file; line = Some line; column = Some column }) location
    in
    Protocol.Tracing.tracing_group ~name ?location t.t_channel
let group_end (t : t) = Protocol.Tracing.tracing_group_end t.t_channel

let save_chunk (t : t) ?path stacks_id =
    let discard_stacks () = Option.iter (fun stacks_id -> Protocol.Local_utils.trace_discarded ~stacks_id (local_utils t)) stacks_id in
    match path with
    | None ->
        ignore (Protocol.Tracing.tracing_stop_chunk ~mode:`Discard t.t_channel);
        discard_stacks ()
    | Some path ->
        let path = Files.absolute path in
        Files.make_parent path;
        let result = Protocol.Tracing.tracing_stop_chunk ~mode:`Entries t.t_channel in
        Protocol.Local_utils.zip ~zip_file:path ~entries:(Option.value result.entries ~default:[]) ?stacks_id ~mode:`Write
            ~include_sources:t.include_sources (local_utils t)

let stop_chunk ?path (t : t) =
    let stacks_id = t.stacks_id in
    t.stacks_id <- None;
    (* The stacks are released also when the trace could not be saved, otherwise later traces keep
       appending to them. *)
    Connection.guard (Channel.conn t.t_channel) "discarding the stacks of a trace"
        ~undo:(fun () -> Option.iter (fun stacks_id -> try Protocol.Local_utils.trace_discarded ~stacks_id (local_utils t) with Error.E _ -> ()) stacks_id)
        (fun () -> save_chunk t ?path stacks_id)

(* Tracing is stopped also when the trace could not be saved, which is the failure that counts. *)
let stop ?path (t : t) =
    let stop () = Protocol.Tracing.tracing_stop t.t_channel in
    Connection.guard (Channel.conn t.t_channel) "stopping tracing" ~undo:stop (fun () -> stop_chunk ?path t);
    stop ()
