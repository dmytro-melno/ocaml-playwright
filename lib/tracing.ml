open Types

type t = tracing

let create session (channel : Protocol.Tracing.t) : t =
    { t_channel = channel; t_session = session; include_sources = false; is_live = false; traces_dir = None; stacks_id = None; har_id = None;
      har_recorders = Hashtbl.create 1 }

let local_utils (t : t) = Url_match.local_utils t.t_session
let is_zip path = Filename.check_suffix (String.lowercase_ascii path) ".zip"

let start_collecting_stacks (t : t) trace_name =
    t.stacks_id <- Some (Protocol.Local_utils.tracing_started ?traces_dir:t.traces_dir ~trace_name ~live:t.is_live (local_utils t))

let start ?name ?title ?(snapshots = false) ?(screenshots = false) ?(sources = false) ?(live = false) (t : t) =
    t.include_sources <- sources;
    t.is_live <- live;
    Protocol.Tracing.tracing_start ?name ~snapshot_dom:snapshots ~screencast:screenshots ~live t.t_channel;
    start_collecting_stacks t (Protocol.Tracing.tracing_start_chunk ?name ?title t.t_channel)

let start_chunk ?name ?title (t : t) = start_collecting_stacks t (Protocol.Tracing.tracing_start_chunk ?name ?title t.t_channel)
let group name (t : t) = Protocol.Tracing.tracing_group ~name t.t_channel
let group_end (t : t) = Protocol.Tracing.tracing_group_end t.t_channel

let save_chunk (t : t) ?path stacks_id =
    let discard_stacks () = Option.iter (fun stacks_id -> Protocol.Local_utils.trace_discarded ~stacks_id (local_utils t)) stacks_id in
    match path with
    | None ->
        ignore (Protocol.Tracing.tracing_stop_chunk ~mode:`Discard t.t_channel);
        discard_stacks ()
    | Some path when not t.t_session.is_remote ->
        let path = Files.absolute path in
        Files.mkdir_p (Filename.dirname path);
        let result = Protocol.Tracing.tracing_stop_chunk ~mode:`Entries t.t_channel in
        Protocol.Local_utils.zip ~zip_file:path ~entries:(Option.value result.entries ~default:[]) ?stacks_id ~mode:`Write
            ~include_sources:t.include_sources (local_utils t)
    | Some path ->
        let path = Files.absolute path in
        (* The artifact is missing when the browser closed while the trace was being stopped. *)
        (match (Protocol.Tracing.tracing_stop_chunk ~mode:`Archive t.t_channel).artifact with
        | None -> discard_stacks ()
        | Some artifact ->
            Connection.protect (Channel.conn t.t_channel) "deleting a trace"
                ~finally:(fun () -> try Artifact.delete artifact with Error.E _ -> ())
                (fun () -> Artifact.save_as t.t_session artifact path);
            Protocol.Local_utils.zip ~zip_file:path ~entries:[] ?stacks_id ~mode:`Append ~include_sources:t.include_sources (local_utils t))

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

(* {1 HAR recording} *)

let record_into_har ?page ?url_glob ?(content = `Attach) ?(mode = `Minimal) (t : t) path =
    let path = Files.absolute path in
    let options : Protocol.Record_har_options.t =
        { content = Some content; mode = Some mode; url_glob; url_regex_source = None; url_regex_flags = None;
          har_path = (if is_zip path then None else Some path); resources_dir = None }
    in
    let har_id = Protocol.Tracing.har_start ?page:(Option.map (fun (page : page) -> page.p_channel) page) ~options t.t_channel in
    Hashtbl.replace t.har_recorders har_id path;
    har_id

let export_har (t : t) har_id =
    match Hashtbl.find_opt t.har_recorders har_id with
    | None -> ()
    | Some path ->
        Hashtbl.remove t.har_recorders har_id;
        if not t.t_session.is_remote then begin
            (* The driver has written an uncompressed HAR to its final place already. *)
            let result = Protocol.Tracing.har_export ~har_id ~mode:`Entries t.t_channel in
            if is_zip path then begin
                Files.mkdir_p (Filename.dirname path);
                Protocol.Local_utils.zip ~zip_file:path ~entries:(Option.value result.entries ~default:[]) ~mode:`Write ~include_sources:false
                    (local_utils t)
            end
        end
        else
            match (Protocol.Tracing.har_export ~har_id ~mode:`Archive t.t_channel).artifact with
            | None -> ()
            | Some artifact ->
                Connection.protect (Channel.conn t.t_channel) "deleting a recording"
                    ~finally:(fun () -> try Artifact.delete artifact with Error.E _ -> ())
                    (fun () ->
                        if is_zip path then Artifact.save_as t.t_session artifact path
                        else begin
                            let archive = path ^ ".tmp" in
                            Artifact.save_as t.t_session artifact archive;
                            Protocol.Local_utils.har_unzip ~zip_file:archive ~har_file:path (local_utils t)
                        end)

let export_all_hars (t : t) = List.iter (export_har t) (List.of_seq (Hashtbl.to_seq_keys t.har_recorders))

let start_har ?content ?mode ?url_glob path (t : t) =
    if t.har_id <> None then Error.raise_ "HAR recording has already been started";
    let content = match content with Some content -> content | None -> if is_zip path then `Attach else `Embed in
    t.har_id <- Some (record_into_har ?url_glob ~content ~mode:(Option.value mode ~default:`Full) t path)

let stop_har (t : t) =
    match t.har_id with
    | None -> Error.raise_ "HAR recording has not been started"
    | Some har_id ->
        t.har_id <- None;
        export_har t har_id
