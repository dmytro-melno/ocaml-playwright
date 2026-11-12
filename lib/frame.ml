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
        | None, Some page, Some `Load ->
            emit session page.pe_load page;
            emit session page.context.ce_page_load page
        | None, Some page, Some `Domcontentloaded -> emit session page.pe_dom_content_loaded page
        | _ -> ())
    | Navigated { url; name; error; _ } ->
        frame.f_url <- url;
        frame.f_name <- name;
        emit session frame.fe_navigated { n_url = url; n_error = error };
        (match error, frame.page with
        | None, Some page ->
            emit session page.pe_frame_navigated frame;
            emit session page.context.ce_frame_navigated frame
        | _ -> ())

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
let url_matcher (frame : t) glob = Url_match.of_glob frame.f_session ?base_url:(base_url frame) glob

type input_files =
    | Paths of string list
    | Payloads of Protocol.Frame.Set_input_files_payloads.t list

let max_payload_size = 50 * 1024 * 1024

(* How files are handed to the driver: it takes in-memory payloads inline and reads local paths
   itself. *)
type converted_files = {
    payloads : Protocol.Frame.Set_input_files_payloads.t list option;
    local_paths : string list option;
    local_directory : string option;
}

let no_files = { payloads = None; local_paths = None; local_directory = None }

let convert_input_files = function
    | Payloads payloads ->
        let size = List.fold_left (fun size (payload : Protocol.Frame.Set_input_files_payloads.t) -> size + String.length payload.buffer) 0 payloads in
        if size > max_payload_size then
            Error.raise_ "Cannot set buffer larger than 50Mb, please write it to a file and pass its path instead.";
        { no_files with payloads = Some payloads }
    | Paths [] -> { no_files with payloads = Some [] }  (* clears the input *)
    | Paths paths ->
        let paths = List.map Files.absolute paths in
        let files, directory =
            match Files.partition_directories paths with
            | [], files -> files, None
            | [ directory ], [] -> [], Some directory
            | _ :: _ :: _, [] -> Error.raise_ "Multiple directories are not supported"
            | _ -> Error.raise_ "File paths must be all files or a single directory"
        in
        { no_files with local_paths = (if directory = None then Some files else None); local_directory = directory }

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

(* Waits for the next navigation to a URL that [matches], and for it to reach [wait_until]. *)
let wait_for_navigation ?timeout ?(wait_until = `Load) ~matches (frame : t) =
    navigation_waiter ?timeout frame (fun waiter ->
        Waiter.listen waiter frame.fe_navigated (fun navigation -> Some (`Navigated navigation));
        Waiter.listen waiter frame.fe_load_state (fun state -> Some (`Load_state state));
        (* First the navigation, then the state that it is to reach, unless it is in it already. *)
        let navigated = ref false in
        Waiter.next waiter (function
            | `Navigated navigation when (not !navigated) && (navigation.n_error <> None || matches navigation.n_url) ->
                (* Any failed navigation ends the wait. *)
                Option.iter (fun message -> raise (Error.E (Error.make message))) navigation.n_error;
                if List.mem wait_until frame.load_states then Some ()
                else begin
                    navigated := true;
                    None
                end
            | `Load_state state when !navigated && state = wait_until -> Some ()
            | _ -> None))

let wait_for_load_state ?timeout ?(state = `Load) (frame : t) =
    navigation_waiter ?timeout frame (fun waiter ->
        Waiter.listen waiter frame.fe_load_state Option.some;
        if List.mem state frame.load_states then begin
            if (page_of_frame frame).closed then raise (Error.E (page_close_error (page_of_frame frame)))
        end
        else Waiter.next waiter (fun reached -> if reached = state then Some () else None))

let wait_for_url_matching ?timeout ?wait_until (frame : t) matches =
    if matches frame.f_url then wait_for_load_state ?timeout ?state:wait_until frame
    else wait_for_navigation ?timeout ?wait_until ~matches frame

let wait_for_url ?timeout ?wait_until (frame : t) glob = wait_for_url_matching frame ?timeout ?wait_until (url_matcher frame glob)

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
    let goto ?timeout ?(wait_until = `Load) ?referer t url =
        let frame = T.frame t in
        Protocol.Frame.goto ~timeout:(navigation_timeout ?timeout frame) ~url ~wait_until ?referer frame.f_channel
        |> Option.map Types.response

    let set_content ?timeout ?(wait_until = `Load) t html =
        let frame = T.frame t in
        Protocol.Frame.set_content ~timeout:(navigation_timeout ?timeout frame) ~html ~wait_until frame.f_channel

    let content ?include_shadow t = Protocol.Frame.content ?include_shadow (T.frame t).f_channel
    let title t = Protocol.Frame.title (T.frame t).f_channel
    let wait_for_load_state ?timeout ?state t = wait_for_load_state ?timeout ?state (T.frame t)
    let wait_for_url ?timeout ?wait_until t glob = wait_for_url (T.frame t) ?timeout ?wait_until glob
    let wait_for_url_matching ?timeout ?wait_until t matches = wait_for_url_matching (T.frame t) ?timeout ?wait_until matches

    (* {2 JavaScript} *)

    let evaluate ?(arg = Js.Undefined) t expression =
        Protocol.Frame.evaluate_expression ~expression ~arg:(Js.to_argument arg) (T.frame t).f_channel |> Js.of_wire

    let evaluate_handle ?(arg = Js.Undefined) t expression =
        Protocol.Frame.evaluate_expression_handle ~expression ~arg:(Js.to_argument arg) (T.frame t).f_channel |> Types.js_handle

    let wait_for_function ?timeout ?polling ?(arg = Js.Undefined) t expression =
        let frame = T.frame t in
        match
            Protocol.Frame.wait_for_function ~timeout:(action_timeout ?timeout frame) ~expression ~arg:(Js.to_argument arg)
                ?polling_interval:polling frame.f_channel
        with
        | Some handle -> Types.js_handle handle
        | None -> Error.raise_ "The driver returned no handle for the awaited function"

    let tag_source : [ `Content of string | `Url of string ] -> string option * string option = function
        | `Url url -> Some url, None
        | `Content content -> None, Some content

    let add_script_tag ?type_ t source =
        let url, content = tag_source source in
        Protocol.Frame.add_script_tag ?url ?content ?type_ (T.frame t).f_channel |> Types.element

    let add_style_tag t source =
        let url, content = tag_source source in
        Protocol.Frame.add_style_tag ?url ?content (T.frame t).f_channel |> Types.element

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
