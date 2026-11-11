(* The client-side objects.

   Playwright's objects refer to each other freely (a page knows its frames, a frame its page,
   a request its frame, ...), so their representations are defined together here.  The behaviour
   lives in one module per object; this module holds data only. *)

open Eio.Std

type size = { width : int; height : int }

type lifecycle_event = Protocol.Lifecycle_event.t

(* State shared by everything created over one connection. *)
type session = {
    conn : Connection.t;
    is_remote : bool;  (* the browser runs behind a Playwright server: files must be streamed to and from it *)
    mutable local_utils : Channel.t option;  (* always the utilities of the local driver *)
    selectors : selectors;
    url_matchers : (string, string -> bool) Hashtbl.t;  (* compiled globs, by base URL and glob *)
    mutable devices : device list;
}

(* Selector settings apply to every context, including those of remote sessions, so a remote
   session shares this record with the local one. *)
and selectors = {
    mutable test_id_attribute : string;
    mutable selector_engines : Protocol.Selector_engine.t list;
    mutable all_contexts : browser_context list;
}

and device = {
    device_name : string;
    device_user_agent : string;
    device_viewport : size;
    device_screen : size option;
    device_scale_factor : float;
    device_is_mobile : bool;
    device_has_touch : bool;
    default_browser_type : [ `Chromium | `Firefox | `Webkit ];
}

(* A JavaScript value that crosses the boundary between OCaml and the page. *)
and js =
    | Undefined
    | Null
    | Bool of bool
    | Number of float
    | String of string
    | Bigint of string
    | Date of string
    | Url of string
    | Regexp of { source : string; flags : string }
    | Error of { name : string; message : string; stack : string }
    | Array of js list
    | Object of (string * js) list
    | Typed_array of { kind : typed_array_kind; bytes : string }
    | Handle of js_handle

and typed_array_kind = [ `I8 | `Ui8 | `Ui8c | `I16 | `Ui16 | `I32 | `Ui32 | `F32 | `F64 | `Bi64 | `Bui64 ]

and js_handle = {
    h_channel : Channel.t;
    h_session : session;
    mutable preview : string;
}

and browser_type = {
    bt_channel : Channel.t;
    bt_session : session;
    bt_name : string;
    executable_path : string;
}

and browser = {
    b_channel : Channel.t;
    b_session : session;
    mutable browser_type : browser_type option;
    b_name : string;
    version : string;
    mutable contexts : browser_context list;
    b_close_state : Closing.t;
    mutable b_close_reason : string option;
    mutable b_traces_dir : string option;
    (* For a browser reached through its own connection: how to drop that connection. *)
    mutable disconnect : (unit -> unit) option;
    b_closed : unit Promise.t;
    b_closed_resolver : unit Promise.u;
    e_disconnected : browser Emitter.t;
}

and browser_context = {
    c_channel : Channel.t;
    c_session : session;
    mutable browser : browser option;
    mutable pages : page list;
    mutable c_routes : route_handler list;
    mutable c_ws_routes : ws_route_handler list;
    c_bindings : (string, binding) Hashtbl.t;
    c_timeouts : Timeouts.t;
    mutable owner_page : page option;
    base_url : string option;
    records_video : bool;
    tracing : tracing;
    request : api_request_context;
    mutable service_workers : worker list;
    close_state : Closing.t;
    mutable c_close_reason : string option;
    c_closed : unit Promise.t;
    c_closed_resolver : unit Promise.u;
    ce_close : browser_context Emitter.t;
    ce_console : console_message Emitter.t;
    ce_dialog : dialog Emitter.t;
    ce_page : page Emitter.t;
    ce_web_error : web_error Emitter.t;
    ce_request : request Emitter.t;
    ce_request_failed : request Emitter.t;
    ce_request_finished : request Emitter.t;
    ce_response : response Emitter.t;
    ce_service_worker : worker Emitter.t;
}

and page = {
    p_channel : Channel.t;
    context : browser_context;
    main_frame : frame;
    mutable frames : frame list;
    mutable workers : worker list;
    mutable closed : bool;
    mutable close_was_called : bool;
    mutable p_close_reason : string option;
    mutable viewport_size : size option;
    mutable p_routes : route_handler list;
    mutable p_ws_routes : ws_route_handler list;
    p_bindings : (string, binding) Hashtbl.t;
    p_timeouts : Timeouts.t;
    opener : page option;
    mutable owned_context : browser_context option;
    video_artifact : Channel.t option;
    locator_handlers : (int, locator_handler) Hashtbl.t;
    (* Resolved with the reason once the page is closed or has crashed. *)
    p_gone : Error.t Promise.t;
    p_gone_resolver : Error.t Promise.u;
    pe_close : page Emitter.t;
    pe_console : console_message Emitter.t;
    pe_crash : page Emitter.t;
    pe_dialog : dialog Emitter.t;
    pe_dom_content_loaded : page Emitter.t;
    pe_download : download Emitter.t;
    pe_file_chooser : file_chooser Emitter.t;
    pe_frame_attached : frame Emitter.t;
    pe_frame_detached : frame Emitter.t;
    pe_frame_navigated : frame Emitter.t;
    pe_load : page Emitter.t;
    pe_page_error : Error.t Emitter.t;
    pe_popup : page Emitter.t;
    pe_request : request Emitter.t;
    pe_request_failed : request Emitter.t;
    pe_request_finished : request Emitter.t;
    pe_response : response Emitter.t;
    pe_web_socket : web_socket Emitter.t;
    pe_worker : worker Emitter.t;
}

and frame = {
    f_channel : Channel.t;
    f_session : session;
    mutable page : page option;  (* set as soon as the page that owns the frame is announced *)
    parent_frame : frame option;
    mutable child_frames : frame list;
    mutable f_url : string;
    mutable f_name : string;
    mutable detached : bool;
    mutable load_states : lifecycle_event list;
    fe_load_state : lifecycle_event Emitter.t;
    fe_navigated : navigation Emitter.t;
}

and navigation = {
    n_url : string;
    n_error : string option;
    n_request : request option;  (* the document request, for navigations that load a new document *)
}

and locator = {
    l_frame : frame;
    selector : string;
}

and frame_locator = {
    fl_frame : frame;
    frame_selector : string;
}

and locator_handler = {
    lh_locator : locator;
    lh_handler : locator -> unit;
    mutable lh_times : int option;
}

and request = {
    r_channel : Channel.t;
    r_init : Protocol.Request.Initializer.t;
    redirected_from : request option;
    mutable redirected_to : request option;
    mutable failure : string option;
    mutable r_response : response option;
    mutable timing : timing;
    mutable raw_headers : (string * string) list option;
    mutable overrides : request_overrides;
}

and timing = {
    start_time : float;
    domain_lookup_start : float;
    domain_lookup_end : float;
    connect_start : float;
    secure_connection_start : float;
    connect_end : float;
    request_start : float;
    response_start : float;
    response_end : float;
}

and request_overrides = {
    o_url : string option;
    o_method : string option;
    o_headers : (string * string) list option;
    o_post_data : string option;
}

and response = {
    rs_channel : Channel.t;
    rs_init : Protocol.Response.Initializer.t;
    rs_request : request;
    mutable rs_raw_headers : (string * string) list option;
    (* Resolved once the body has been received in full, or cannot be any more. *)
    rs_finished : (unit, Error.t) result Promise.t;
    rs_finished_resolver : (unit, Error.t) result Promise.u;
}

and route = {
    rt_channel : Channel.t;
    rt_request : request;
    mutable rt_context : browser_context option;
    (* Present while a handler is expected to decide; resolved with whether it did, as opposed to
       passing the request on to the next handler. *)
    mutable handling : bool Promise.u option;
}

and url_matcher =
    | Glob of string
    | Predicate of (string -> bool)

and route_handler = {
    rh_matcher : url_matcher;
    rh_matches : string -> bool;
    rh_handler : route -> unit;
    rh_times : int option;
    mutable rh_handled : int;
}

and ws_route_handler = {
    wh_matcher : url_matcher;
    wh_matches : string -> bool;
    wh_handler : web_socket_route -> unit;
}

and web_socket = {
    ws_channel : Channel.t;
    ws_url : string;
    ws_page : page option;
    mutable ws_closed : bool;
    wse_close : web_socket Emitter.t;
    wse_frame_sent : ws_payload Emitter.t;
    wse_frame_received : ws_payload Emitter.t;
    wse_socket_error : string Emitter.t;
}

and ws_payload =
    | Text of string
    | Binary of string

(* One side of an intercepted WebSocket: the page's or, once connected, the server's. *)
and web_socket_route = {
    wr_channel : Channel.t;
    wr_side : [ `Page | `Server ];
    wr_state : ws_route_state;
}

and ws_route_state = {
    wr_url : string;
    wr_protocols : string list;
    mutable wr_connected : bool;
    mutable on_page_message : (ws_payload -> unit) option;
    mutable on_page_close : (int option -> string option -> unit) option;
    mutable on_server_message : (ws_payload -> unit) option;
    mutable on_server_close : (int option -> string option -> unit) option;
}

and worker = {
    w_channel : Channel.t;
    w_session : session;
    w_url : string;
    mutable w_page : page option;
    mutable w_context : browser_context option;
    w_gone : Error.t Promise.t;
    w_gone_resolver : Error.t Promise.u;
    we_close : worker Emitter.t;
    we_console : console_message Emitter.t;
}

and dialog = {
    d_channel : Channel.t;
    d_page : page option;
    d_type : string;
    d_message : string;
    d_default_value : string;
}

and console_message = {
    cm_type : string;
    cm_text : string;
    cm_args : js_handle list;
    cm_location : Protocol.Console_message_location.t;
    cm_timestamp : float;
    cm_page : page option;
    cm_worker : worker option;
}

(* An uncaught error thrown in a page. *)
and web_error = {
    we_page : page option;
    we_error : Error.t;
}

and download = {
    dl_page : page;
    dl_url : string;
    suggested_filename : string;
    dl_artifact : Channel.t;
}

and file_chooser = {
    fc_page : page;
    fc_element : js_handle;
    is_multiple : bool;
}

and binding_source = {
    bs_context : browser_context;
    bs_page : page;
    bs_frame : frame;
}

and binding = binding_source -> js list -> js

and tracing = {
    t_channel : Channel.t;
    t_session : session;
    mutable include_sources : bool;
    mutable is_live : bool;
    mutable traces_dir : string option;
    mutable stacks_id : string option;
    mutable har_id : string option;
    har_recorders : (string, string) Hashtbl.t;  (* recording id to output path *)
}

and api_request_context = {
    a_channel : Channel.t;
    a_session : session;
    a_tracing : tracing;
    mutable a_timeouts : Timeouts.t;
    mutable a_close_reason : string option;
    a_close_state : Closing.t;
}

and api_response = {
    ar_context : api_request_context;
    ar_init : Protocol.Api_response.t;
}

and cdp_session = {
    cdp_channel : Channel.t;
    mutable cdp_detached : bool;
    cdpe_event : (string * Json.t) Emitter.t;
    cdpe_close : cdp_session Emitter.t;
    mutable cdp_listeners : ((string -> Json.t -> unit) * (string * Json.t -> unit)) list;  (* public listeners and what stands for them *)
}

type playwright = {
    session : session;
    pw_channel : Channel.t;
    chromium : browser_type;
    firefox : browser_type;
    webkit : browser_type;
    stopped : unit Promise.t;  (* resolved once the connection has ended and the driver is gone *)
}

(* The client object behind each channel. *)
type Connection.impl +=
    | Browser_type of browser_type
    | Browser of browser
    | Browser_context of browser_context
    | Page of page
    | Frame of frame
    | Js_handle of js_handle
    | Request of request
    | Response of response
    | Route of route
    | Web_socket of web_socket
    | Web_socket_route of web_socket_route
    | Worker of worker
    | Dialog of dialog
    | Tracing of tracing
    | Api_request_context of api_request_context
    | Cdp_session of cdp_session

let mismatch (channel : Channel.t) expected =
    Error.raise_ "Protocol error: object %S is a %s, not a %s" channel.guid channel.type_ expected

let browser_type (c : Channel.t) = match c.impl with Browser_type x -> x | _ -> mismatch c "BrowserType"
let browser (c : Channel.t) = match c.impl with Browser x -> x | _ -> mismatch c "Browser"
let browser_context (c : Channel.t) = match c.impl with Browser_context x -> x | _ -> mismatch c "BrowserContext"
let page (c : Channel.t) = match c.impl with Page x -> x | _ -> mismatch c "Page"
let frame (c : Channel.t) = match c.impl with Frame x -> x | _ -> mismatch c "Frame"
let js_handle (c : Channel.t) = match c.impl with Js_handle x -> x | _ -> mismatch c "JSHandle"
let request (c : Channel.t) = match c.impl with Request x -> x | _ -> mismatch c "Request"
let response (c : Channel.t) = match c.impl with Response x -> x | _ -> mismatch c "Response"
let route (c : Channel.t) = match c.impl with Route x -> x | _ -> mismatch c "Route"
let web_socket (c : Channel.t) = match c.impl with Web_socket x -> x | _ -> mismatch c "WebSocket"
let web_socket_route (c : Channel.t) = match c.impl with Web_socket_route x -> x | _ -> mismatch c "WebSocketRoute"
let worker (c : Channel.t) = match c.impl with Worker x -> x | _ -> mismatch c "Worker"
let dialog (c : Channel.t) = match c.impl with Dialog x -> x | _ -> mismatch c "Dialog"
let tracing (c : Channel.t) = match c.impl with Tracing x -> x | _ -> mismatch c "Tracing"
let api_request_context (c : Channel.t) = match c.impl with Api_request_context x -> x | _ -> mismatch c "APIRequestContext"
let cdp_session (c : Channel.t) = match c.impl with Cdp_session x -> x | _ -> mismatch c "CDPSession"

let is_element (handle : js_handle) = handle.h_channel.type_ = "ElementHandle"

let element (c : Channel.t) =
    let handle = js_handle c in
    if is_element handle then handle else mismatch c "ElementHandle"

let page_of_frame (frame : frame) =
    match frame.page with
    | Some page -> page
    | None -> Error.raise_ "The frame is not attached to a page yet"
