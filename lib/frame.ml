open Types

type t = frame

let equal (a : t) (b : t) = Channel.equal a.f_channel b.f_channel
let compare (a : t) (b : t) = Channel.compare a.f_channel b.f_channel
let hash (t : t) = Channel.hash t.f_channel

let emit (session : session) emitter value = ignore (Emitter.emit session.conn emitter value)

(* {1 Lifecycle} *)

let handle_event (frame : t) : Protocol.Frame.event -> unit =
    let session = frame.f_session in
    function
    | Loadstate { add; remove } ->
        Option.iter
            (fun state ->
                if not (List.mem state frame.load_states) then frame.load_states <- state :: frame.load_states;
                emit session frame.fe_load_state state)
            add;
        Option.iter (fun state -> frame.load_states <- List.filter (fun s -> s <> state) frame.load_states) remove;
        (match frame.parent_frame, frame.page, add with
        | None, Some page, Some `Load -> emit session page.pe_load page
        | None, Some page, Some `Domcontentloaded -> emit session page.pe_dom_content_loaded page
        | _ -> ())
    | Navigated { url; name; new_document; error } ->
        frame.f_url <- url;
        frame.f_name <- name;
        let request = Option.bind new_document (fun (document : Protocol.Frame.Navigated_event_new_document.t) -> Option.map Types.request document.request) in
        emit session frame.fe_navigated { n_url = url; n_error = error; n_request = request };
        (match error, frame.page with None, Some page -> emit session page.pe_frame_navigated frame | _ -> ())

let create session (channel : Protocol.Frame.t) : t =
    let init = Protocol.Frame.initializer_ channel in
    let parent_frame = Option.map Types.frame init.parent_frame in
    let frame =
        { f_channel = channel; f_session = session; page = None; parent_frame; child_frames = []; f_url = init.url; f_name = init.name;
          detached = false; load_states = init.load_states; fe_load_state = Emitter.create (); fe_navigated = Emitter.create () }
    in
    Option.iter (fun parent -> Ownership.add_child_frame parent frame) parent_frame;
    Protocol.Frame.listen channel (handle_event frame);
    frame

(* {1 Helpers shared with locators and pages} *)

let action_timeout ?timeout (frame : t) =
    match frame.page with
    | Some page -> Timeouts.action ?timeout page.p_timeouts
    | None -> Timeouts.action ?timeout (Timeouts.create ())

let navigation_timeout ?timeout (frame : t) =
    match frame.page with
    | Some page -> Timeouts.navigation ?timeout page.p_timeouts
    | None -> Timeouts.navigation ?timeout (Timeouts.create ())

let point (x, y) : Protocol.Point.t = { x; y }

let effective_close_reason (context : browser_context) =
    match context.c_close_reason, context.browser with
    | Some reason, _ -> Some reason
    | None, Some browser -> browser.b_close_reason
    | None, None -> None

let page_close_error (page : page) =
    let reason = match page.p_close_reason with Some reason -> Some reason | None -> effective_close_reason page.context in
    Error.target_closed ?message:reason ()

let base_url (frame : t) = Option.bind frame.page (fun page -> page.context.base_url)
let url_matcher (frame : t) glob = Glob.matcher ?base_url:(base_url frame) glob

type input_files =
    | Paths of string list
    | Payloads of Protocol.Frame.Set_input_files_payloads.t list

let max_payload_size = 50 * 1024 * 1024

(* How files are handed to the driver: it takes in-memory payloads inline and reads local paths
   itself.  A driver on another machine cannot do the latter, so files are streamed to it. *)
type converted_files = {
    payloads : Protocol.Frame.Set_input_files_payloads.t list option;
    local_paths : string list option;
    local_directory : string option;
    streams : Protocol.Writable_stream.t list option;
    directory_stream : Protocol.Writable_stream.t option;
}

let no_files = { payloads = None; local_paths = None; local_directory = None; streams = None; directory_stream = None }
let upload_chunk_size = 1 lsl 20

(* The files below [directory], as paths relative to it. *)
let rec files_below directory =
    Sys.readdir directory |> Array.to_list |> List.sort String.compare
    |> List.concat_map (fun name ->
        let path = Filename.concat directory name in
        if Files.is_directory path then List.map (fun below -> name ^ "/" ^ below) (files_below path) else [ name ])

let upload (context : browser_context) ?directory files =
    let files =
        match directory with
        | Some directory -> List.map (fun name -> name, Filename.concat directory name) (files_below directory)
        | None -> List.map (fun path -> Filename.basename path, path) files
    in
    let items =
        List.map
            (fun (name, path) : Protocol.Browser_context.Create_temp_files_items.t -> { name; last_modified_ms = Some ((Unix.stat path).st_mtime *. 1000.) })
            files
    in
    let result = Protocol.Browser_context.create_temp_files ?root_dir_name:(Option.map Filename.basename directory) ~items context.c_channel in
    let abandon () = List.iter (fun stream -> try Protocol.Writable_stream.close stream with Error.E _ -> ()) result.writable_streams in
    Connection.guard (Channel.conn context.c_channel) "closing the streams of an upload" ~undo:abandon @@ fun () ->
    List.iter2
        (fun (_, path) stream ->
            In_channel.with_open_bin path (fun ic ->
                let buffer = Bytes.create upload_chunk_size in
                let rec copy () =
                    let n = In_channel.input ic buffer 0 upload_chunk_size in
                    if n > 0 then begin
                        Protocol.Writable_stream.write ~binary:(Bytes.sub_string buffer 0 n) stream;
                        copy ()
                    end
                in
                copy ());
            Protocol.Writable_stream.close stream)
        files result.writable_streams;
    match directory with
    | Some _ -> { no_files with directory_stream = result.root_dir }
    | None -> { no_files with streams = Some result.writable_streams }

(* [frame] is the frame that the files are for, when known. *)
let convert_input_files (frame : t option) = function
    | Payloads payloads ->
        let size = List.fold_left (fun size (payload : Protocol.Frame.Set_input_files_payloads.t) -> size + String.length payload.buffer) 0 payloads in
        if size > max_payload_size then
            Error.raise_ "Cannot set buffer larger than 50Mb, please write it to a file and pass its path instead.";
        { no_files with payloads = Some payloads }
    | Paths [] -> { no_files with payloads = Some [] }  (* clears the input *)
    | Paths paths ->
        let paths = List.map Files.absolute paths in
        let files, directory =
            match List.partition Files.is_directory paths with
            | [], files -> files, None
            | [ directory ], [] -> [], Some directory
            | _ :: _ :: _, [] -> Error.raise_ "Multiple directories are not supported"
            | _ -> Error.raise_ "File paths must be all files or a single directory"
        in
        (match frame with
        | Some { f_session = { is_remote = true; _ }; page = Some page; _ } -> upload page.context ?directory files
        | _ -> { no_files with local_paths = (if directory = None then Some files else None); local_directory = directory })

type select_option = [ `Value of string | `Label of string | `Index of int | `Value_or_label of string ]

let select_options (options : select_option list) : Protocol.Frame.Select_option_options.t list =
    let empty : Protocol.Frame.Select_option_options.t = { value_or_label = None; value = None; label = None; index = None } in
    List.map
        (function
            | `Value value -> { empty with value = Some value }
            | `Label label -> { empty with label = Some label }
            | `Index index -> { empty with index = Some index }
            | `Value_or_label text -> { empty with value_or_label = Some text })
        options

let script_with_source_url ~path content = content ^ "\n//# sourceURL=" ^ String.concat "" (String.split_on_char '\n' path)

(* {1 Navigation} *)

let reject_when_gone waiter (frame : t) (page : page) =
    if page.closed then Waiter.reject waiter (page_close_error page);
    Waiter.reject_on waiter page.pe_close (fun _ -> Some (page_close_error page));
    Waiter.reject_on waiter page.pe_crash (fun _ -> Some (Error.make "Navigation failed because page crashed!"));
    Waiter.reject_on waiter page.pe_frame_detached (fun detached ->
        if detached == frame then Some (Error.make "Navigating frame was detached!") else None)

let navigation_waiter ?timeout (frame : t) f =
    let page = page_of_frame frame in
    let timeout = navigation_timeout ?timeout frame in
    Waiter.using frame.f_session.conn ~timeout
        ~timeout_message:(fun () -> Printf.sprintf "Timeout %sms exceeded." (Waiter.format_timeout timeout))
        (fun waiter ->
            reject_when_gone waiter frame page;
            f waiter)

(* Runs [action] and waits for the navigation it causes, and for that navigation to reach
   [wait_until]. *)
let expect_navigation ?timeout ?(wait_until = `Load) ?(matches = fun _ -> true) (frame : t) action =
    navigation_waiter ?timeout frame (fun waiter ->
        Waiter.listen waiter frame.fe_navigated (fun navigation -> Some (`Navigated navigation));
        Waiter.listen waiter frame.fe_load_state (fun state -> Some (`Load_state state));
        (* First the navigation, then the state that it is to reach, unless it is in it already. *)
        let navigated = ref None in
        let select event =
            match event, !navigated with
            | `Navigated navigation, None when navigation.n_error <> None || matches navigation.n_url ->
                (* Any failed navigation ends the wait. *)
                Option.iter (fun message -> raise (Error.E (Error.make message))) navigation.n_error;
                if List.mem wait_until frame.load_states then Some navigation
                else begin
                    navigated := Some navigation;
                    None
                end
            | `Load_state state, Some navigation when state = wait_until -> Some navigation
            | _ -> None
        in
        let result, navigation = Waiter.around waiter action select in
        let rec final (request : request) = match request.redirected_to with Some next -> final next | None -> request in
        let response =
            Option.bind navigation.n_request (fun request -> Option.map Types.response (Protocol.Request.response (final request).r_channel))
        in
        result, response)

let wait_for_load_state ?timeout ?(state = `Load) (frame : t) =
    navigation_waiter ?timeout frame (fun waiter ->
        Waiter.listen waiter frame.fe_load_state Option.some;
        if List.mem state frame.load_states then begin
            if (page_of_frame frame).closed then raise (Error.E (page_close_error (page_of_frame frame)))
        end
        else Waiter.next waiter (fun reached -> if reached = state then Some () else None))

let wait_for_url_matching ?timeout ?wait_until matches (frame : t) =
    if matches frame.f_url then wait_for_load_state ?timeout ?state:wait_until frame
    else ignore (expect_navigation ?timeout ?wait_until ~matches frame ignore)

let wait_for_url ?timeout ?wait_until glob (frame : t) = wait_for_url_matching ?timeout ?wait_until (url_matcher frame glob) frame

(* {1 Assertions} *)

type expectation = {
    matches : bool;
    received : Js.t option;
    received_aria_snapshot : string option;
    log : string list;
    timed_out : bool;
    error_message : string option;
}

(* Evaluates one of the driver's built-in [expect] conditions, retrying until it holds or
   [timeout] expires. *)
let expect ?selector ?expression_arg ?pseudo ?expected_text ?expected_number ?expected_value ?use_inner_text ~is_not ~timeout expression (frame : t) =
    let expected_value = Option.map Js.to_argument expected_value in
    match
        Protocol.Frame.expect ~timeout ?selector ~expression ?expression_arg ?pseudo ?expected_text ?expected_number ?expected_value
            ?use_inner_text ~is_not frame.f_channel
    with
    | () -> { matches = not is_not; received = None; received_aria_snapshot = None; log = []; timed_out = false; error_message = None }
    | exception Error.E ({ details = `Assoc _ as details; _ } as error) ->
        let details = Protocol.Frame.Expect_error_details.of_json frame.f_session.conn details in
        let received = Option.bind details.received (fun received -> Option.map Js.of_wire received.value) in
        let received_aria_snapshot = Option.bind details.received (fun received -> received.aria_snapshot) in
        { matches = is_not; received; received_aria_snapshot; log = error.log; timed_out = details.timed_out = Some true;
          error_message = details.custom_error_message }

(* {1 Operations shared by frames and pages}

   A page forwards these to its main frame. *)

module Operations (T : sig
    type t

    val frame : t -> frame
end) =
struct
    let goto ?timeout ?(wait_until = `Load) ?referer url t =
        let frame = T.frame t in
        Protocol.Frame.goto ~timeout:(navigation_timeout ?timeout frame) ~url ~wait_until ?referer frame.f_channel
        |> Option.map Types.response

    let set_content ?timeout ?(wait_until = `Load) html t =
        let frame = T.frame t in
        Protocol.Frame.set_content ~timeout:(navigation_timeout ?timeout frame) ~html ~wait_until frame.f_channel

    let content t = Protocol.Frame.content (T.frame t).f_channel
    let title t = Protocol.Frame.title (T.frame t).f_channel
    let wait_for_load_state ?timeout ?state t = wait_for_load_state ?timeout ?state (T.frame t)
    let wait_for_url ?timeout ?wait_until glob t = wait_for_url ?timeout ?wait_until glob (T.frame t)
    let wait_for_url_matching ?timeout ?wait_until matches t = wait_for_url_matching ?timeout ?wait_until matches (T.frame t)

    let expect_navigation ?timeout ?wait_until ?url ?url_matching action t =
        let frame = T.frame t in
        let matches =
            match Option.map (url_matcher frame) url, url_matching with
            | Some glob, Some matching -> Some (fun url -> glob url && matching url)
            | (Some _ as one), None | None, one -> one
        in
        snd (expect_navigation ?timeout ?wait_until ?matches frame action)

    let wait_for_timeout milliseconds t = Protocol.Frame.wait_for_timeout ~wait_timeout:milliseconds (T.frame t).f_channel

    (* {2 JavaScript} *)

    let evaluate ?(arg = Js.Undefined) expression t =
        Protocol.Frame.evaluate_expression ~expression ~arg:(Js.to_argument arg) (T.frame t).f_channel |> Js.of_wire

    let evaluate_handle ?(arg = Js.Undefined) expression t =
        Protocol.Frame.evaluate_expression_handle ~expression ~arg:(Js.to_argument arg) (T.frame t).f_channel |> Types.js_handle

    let wait_for_function ?timeout ?polling ?(arg = Js.Undefined) expression t =
        let frame = T.frame t in
        match
            Protocol.Frame.wait_for_function ~timeout:(action_timeout ?timeout frame) ~expression ~arg:(Js.to_argument arg)
                ?polling_interval:polling frame.f_channel
        with
        | Some handle -> Types.js_handle handle
        | None -> Error.raise_ "The driver returned no handle for the awaited function"

    let add_script_tag ?type_ (source : [ `Content of string | `Path of string | `Url of string ]) t =
        let url, content =
            match source with
            | `Url url -> Some url, None
            | `Content content -> None, Some content
            | `Path path -> None, Some (script_with_source_url ~path (Files.read path))
        in
        Protocol.Frame.add_script_tag ?url ?content ?type_ (T.frame t).f_channel |> Types.element

    let add_style_tag (source : [ `Content of string | `Path of string | `Url of string ]) t =
        let url, content =
            match source with
            | `Url url -> Some url, None
            | `Content content -> None, Some content
            | `Path path -> None, Some (Files.read path ^ "/*# sourceURL=" ^ String.concat "" (String.split_on_char '\n' path) ^ "*/")
        in
        Protocol.Frame.add_style_tag ?url ?content (T.frame t).f_channel |> Types.element

    (* {2 Selector-based queries and actions} *)

    let query_selector ?strict selector t =
        Protocol.Frame.query_selector ~selector ?strict (T.frame t).f_channel |> Option.map Types.element

    let query_selector_all selector t = Protocol.Frame.query_selector_all ~selector (T.frame t).f_channel |> List.map Types.element

    let wait_for_selector ?timeout ?strict ?state selector t =
        let frame = T.frame t in
        Protocol.Frame.wait_for_selector ~timeout:(action_timeout ?timeout frame) ~selector ?strict ?state frame.f_channel
        |> Option.map Types.element

    let eval_on_selector ?strict ?(arg = Js.Undefined) selector ~expression t =
        Protocol.Frame.eval_on_selector ~selector ?strict ~expression ~arg:(Js.to_argument arg) (T.frame t).f_channel |> Js.of_wire

    let eval_on_selector_all ?(arg = Js.Undefined) selector ~expression t =
        Protocol.Frame.eval_on_selector_all ~selector ~expression ~arg:(Js.to_argument arg) (T.frame t).f_channel |> Js.of_wire

    let dispatch_event ?timeout ?strict ?(event_init = Js.Undefined) selector ~type_ t =
        let frame = T.frame t in
        Protocol.Frame.dispatch_event ~timeout:(action_timeout ?timeout frame) ~selector ?strict ~type_ ~event_init:(Js.to_argument event_init)
            frame.f_channel

    let click ?timeout ?strict ?force ?no_wait_after ?modifiers ?position ?delay ?button ?click_count ?trial ?steps selector t =
        let frame = T.frame t in
        Protocol.Frame.click ~timeout:(action_timeout ?timeout frame) ~selector ?strict ?force ?no_wait_after ?modifiers
            ?position:(Option.map point position) ?delay ?button ?click_count ?trial ?steps frame.f_channel

    let dblclick ?timeout ?strict ?force ?modifiers ?position ?delay ?button ?trial ?steps selector t =
        let frame = T.frame t in
        Protocol.Frame.dblclick ~timeout:(action_timeout ?timeout frame) ~selector ?strict ?force ?modifiers
            ?position:(Option.map point position) ?delay ?button ?trial ?steps frame.f_channel

    let tap ?timeout ?strict ?force ?modifiers ?position ?trial selector t =
        let frame = T.frame t in
        Protocol.Frame.tap ~timeout:(action_timeout ?timeout frame) ~selector ?strict ?force ?modifiers ?position:(Option.map point position)
            ?trial frame.f_channel

    let hover ?timeout ?strict ?force ?modifiers ?position ?trial selector t =
        let frame = T.frame t in
        Protocol.Frame.hover ~timeout:(action_timeout ?timeout frame) ~selector ?strict ?force ?modifiers ?position:(Option.map point position)
            ?trial frame.f_channel

    let drag_and_drop ?timeout ?strict ?force ?trial ?source_position ?target_position ?steps ~source ~target t =
        let frame = T.frame t in
        Protocol.Frame.drag_and_drop ~timeout:(action_timeout ?timeout frame) ~source ~target ?force ?trial
            ?source_position:(Option.map point source_position) ?target_position:(Option.map point target_position) ?strict ?steps
            frame.f_channel

    let fill ?timeout ?strict ?force selector ~value t =
        let frame = T.frame t in
        Protocol.Frame.fill ~timeout:(action_timeout ?timeout frame) ~selector ?strict ~value ?force frame.f_channel

    let focus ?timeout ?strict selector t =
        let frame = T.frame t in
        Protocol.Frame.focus ~timeout:(action_timeout ?timeout frame) ~selector ?strict frame.f_channel

    let blur ?timeout ?strict selector t =
        let frame = T.frame t in
        Protocol.Frame.blur ~timeout:(action_timeout ?timeout frame) ~selector ?strict frame.f_channel

    let press ?timeout ?strict ?delay ?no_wait_after selector ~key t =
        let frame = T.frame t in
        Protocol.Frame.press ~timeout:(action_timeout ?timeout frame) ~selector ?strict ~key ?delay ?no_wait_after frame.f_channel

    let type_ ?timeout ?strict ?delay selector ~text t =
        let frame = T.frame t in
        Protocol.Frame.type_ ~timeout:(action_timeout ?timeout frame) ~selector ?strict ~text ?delay frame.f_channel

    let check ?timeout ?strict ?force ?position ?trial selector t =
        let frame = T.frame t in
        Protocol.Frame.check ~timeout:(action_timeout ?timeout frame) ~selector ?strict ?force ?position:(Option.map point position) ?trial
            frame.f_channel

    let uncheck ?timeout ?strict ?force ?position ?trial selector t =
        let frame = T.frame t in
        Protocol.Frame.uncheck ~timeout:(action_timeout ?timeout frame) ~selector ?strict ?force ?position:(Option.map point position) ?trial
            frame.f_channel

    let set_checked ?timeout ?strict ?force ?position ?trial selector checked t =
        if checked then check ?timeout ?strict ?force ?position ?trial selector t
        else uncheck ?timeout ?strict ?force ?position ?trial selector t

    let select_option ?timeout ?strict ?force selector options t =
        let frame = T.frame t in
        Protocol.Frame.select_option ~timeout:(action_timeout ?timeout frame) ~selector ?strict ~options:(select_options options) ?force
            frame.f_channel

    let set_input ?timeout ?strict selector files t =
        let frame = T.frame t in
        let converted = convert_input_files (Some frame) files in
        Protocol.Frame.set_input_files ~timeout:(action_timeout ?timeout frame) ~selector ?strict ?payloads:converted.payloads
            ?local_directory:converted.local_directory ?directory_stream:converted.directory_stream ?local_paths:converted.local_paths
            ?streams:converted.streams frame.f_channel

    (* Drops files, data or both onto the element, as a drag from outside the page would. *)
    let drop ?timeout ?strict ?position ?files ?(data = []) selector t =
        let frame = T.frame t in
        let converted = Option.map (convert_input_files (Some frame)) files in
        (match converted with
        | Some { local_directory = Some _; _ } | Some { directory_stream = Some _; _ } ->
            Error.raise_ "Dropping a directory is not supported, pass individual files."
        | _ -> ());
        let payloads =
            Option.bind converted (fun converted -> converted.payloads)
            |> Option.map
                   (List.map (fun (payload : Protocol.Frame.Set_input_files_payloads.t) : Protocol.Frame.Drop_payloads.t ->
                        { name = payload.name; mime_type = payload.mime_type; buffer = payload.buffer }))
        in
        let data = List.map (fun (mime_type, value) : Protocol.Frame.Drop_data.t -> { mime_type; value }) data in
        Protocol.Frame.drop ~timeout:(action_timeout ?timeout frame) ~selector ?strict ?position:(Option.map point position) ?payloads
            ?local_paths:(Option.bind converted (fun converted -> converted.local_paths))
            ?streams:(Option.bind converted (fun converted -> converted.streams))
            ?data:(if data = [] then None else Some data)
            frame.f_channel

    let set_input_files ?timeout ?strict selector paths t = set_input ?timeout ?strict selector (Paths paths) t
    let set_input_payloads ?timeout ?strict selector payloads t = set_input ?timeout ?strict selector (Payloads payloads) t

    let text_content ?timeout ?strict selector t =
        let frame = T.frame t in
        Protocol.Frame.text_content ~timeout:(action_timeout ?timeout frame) ~selector ?strict frame.f_channel

    let inner_text ?timeout ?strict selector t =
        let frame = T.frame t in
        Protocol.Frame.inner_text ~timeout:(action_timeout ?timeout frame) ~selector ?strict frame.f_channel

    let inner_html ?timeout ?strict selector t =
        let frame = T.frame t in
        Protocol.Frame.inner_html ~timeout:(action_timeout ?timeout frame) ~selector ?strict frame.f_channel

    let get_attribute ?timeout ?strict selector ~name t =
        let frame = T.frame t in
        Protocol.Frame.get_attribute ~timeout:(action_timeout ?timeout frame) ~selector ?strict ~name frame.f_channel

    let input_value ?timeout ?strict selector t =
        let frame = T.frame t in
        Protocol.Frame.input_value ~timeout:(action_timeout ?timeout frame) ~selector ?strict frame.f_channel

    let is_checked ?timeout ?strict selector t =
        let frame = T.frame t in
        Protocol.Frame.is_checked ~timeout:(action_timeout ?timeout frame) ~selector ?strict frame.f_channel

    let is_disabled ?timeout ?strict selector t =
        let frame = T.frame t in
        Protocol.Frame.is_disabled ~timeout:(action_timeout ?timeout frame) ~selector ?strict frame.f_channel

    let is_editable ?timeout ?strict selector t =
        let frame = T.frame t in
        Protocol.Frame.is_editable ~timeout:(action_timeout ?timeout frame) ~selector ?strict frame.f_channel

    let is_enabled ?timeout ?strict selector t =
        let frame = T.frame t in
        Protocol.Frame.is_enabled ~timeout:(action_timeout ?timeout frame) ~selector ?strict frame.f_channel

    let is_hidden ?strict selector t = Protocol.Frame.is_hidden ~selector ?strict (T.frame t).f_channel
    let is_visible ?strict selector t = Protocol.Frame.is_visible ~selector ?strict (T.frame t).f_channel
end

include Operations (struct
    type t = frame

    let frame frame = frame
end)

(* {1 Frame-specific accessors} *)

let page = page_of_frame
let url (frame : t) = frame.f_url
let name (frame : t) = frame.f_name
let parent_frame (frame : t) = frame.parent_frame
let child_frames (frame : t) = frame.child_frames
let is_detached (frame : t) = frame.detached
let frame_element (frame : t) = Protocol.Frame.frame_element frame.f_channel |> Types.element
