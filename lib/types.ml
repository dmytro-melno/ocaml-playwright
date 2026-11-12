(* The client-side objects.

   Playwright's objects refer to each other freely (a page knows its frames, a frame its page,
   a request its frame, ...), so their representations are defined together here.  The behaviour
   lives in one module per object; this module holds data only.

   Every module can read every field.  Who writes is settled as follows:

   - A mutable field is written by the module of its record: [page.closed] by {!Page},
     [request.failure] by {!Network.Request}.  Another module that has something to tell calls
     a function of that module.
   - The fields that tie two objects together ([context.pages], [frame.page], [worker.w_page],
     ...) are written by {!Ownership}, which keeps the two ends in step.
   - An emitter is fired by the module that hears from the driver of what happened.  For some
     events of a page that is its context, or one of its frames: see {!page}. *)

open Eio.Std

type size = { width : int; height : int }

type lifecycle_event = Protocol.Lifecycle_event.t

(* State shared by everything created over one connection. *)
type session = {
    conn : Connection.t;
    mutable local_utils : Protocol.Local_utils.t option;
    selectors : selectors;
    mutable devices : device list;
    assertions : assertions;
}

(* Like the selector settings below, these are those of the driver. *)
and assertions = { mutable assertion_timeout : float  (* of the assertions that are not given one *) }

(* Selector settings apply to every context. *)
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
    h_channel : Protocol.Js_handle.t;
    h_session : session;
    mutable preview : string;
}

(* A handle to an element: the handle, and its channel once more as one of the interface that has
   the commands for elements. *)
and element_handle = { e_handle : js_handle; e_channel : Protocol.Element_handle.t }

and browser_type = {
    bt_channel : Protocol.Browser_type.t;
    bt_session : session;
    bt_name : string;
    executable_path : string;
}

and browser = {
    b_channel : Protocol.Browser.t;
    b_session : session;
    mutable browser_type : browser_type option;
    b_name : string;
    version : string;
    mutable contexts : browser_context list;
    b_close_state : Closing.t;
    mutable b_close_reason : string option;
    b_closed : unit Promise.t;
    b_closed_resolver : unit Promise.u;
    e_disconnected : browser Emitter.t;
    e_context : browser_context Emitter.t;
}

and browser_context = {
    c_channel : Protocol.Browser_context.t;
    c_session : session;
    mutable browser : browser option;
    mutable pages : page list;
    mutable c_routes : route_handler list;
    mutable c_ws_routes : ws_route_handler list;
    c_bindings : (string, binding) Hashtbl.t;
    c_timeouts : Timeouts.t;
    base_url : string option;
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
    ce_dialog_closed : dialog Emitter.t;
    ce_page : page Emitter.t;
    ce_web_error : web_error Emitter.t;
    ce_request : request Emitter.t;
    ce_request_failed : request Emitter.t;
    ce_request_finished : request Emitter.t;
    ce_response : response Emitter.t;
    ce_service_worker : worker Emitter.t;
    (* The driver tells the pages and frames of these, which pass them on: see {!Page} and {!Frame}. *)
    ce_download : download Emitter.t;
    ce_frame_attached : frame Emitter.t;
    ce_frame_detached : frame Emitter.t;
    ce_frame_navigated : frame Emitter.t;
    ce_page_close : page Emitter.t;
    ce_page_load : page Emitter.t;
}

and page = {
    p_channel : Protocol.Page.t;
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
    video_artifact : Protocol.Artifact.t option;
    locator_handlers : (int, locator_handler) Hashtbl.t;
    (* Resolved with the reason once the page is closed or has crashed. *)
    p_gone : Error.t Promise.t;
    p_gone_resolver : Error.t Promise.u;
    pe_close : page Emitter.t;
    pe_crash : page Emitter.t;
    pe_download : download Emitter.t;
    pe_file_chooser : file_chooser Emitter.t;
    pe_frame_attached : frame Emitter.t;
    pe_frame_detached : frame Emitter.t;
    pe_web_socket : web_socket Emitter.t;
    pe_worker : worker Emitter.t;
    (* The driver tells the context of these, which fires them: see {!Browser_context}. *)
    pe_console : console_message Emitter.t;
    pe_dialog : dialog Emitter.t;
    pe_dialog_closed : dialog Emitter.t;
    pe_page_error : Error.t Emitter.t;
    pe_popup : page Emitter.t;
    pe_request : request Emitter.t;
    pe_request_failed : request Emitter.t;
    pe_request_finished : request Emitter.t;
    pe_response : response Emitter.t;
    (* And the main frame of these: see {!Frame}. *)
    pe_dom_content_loaded : page Emitter.t;
    pe_frame_navigated : frame Emitter.t;
    pe_load : page Emitter.t;
}

and frame = {
    f_channel : Protocol.Frame.t;
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
    r_channel : Protocol.Request.t;
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
    rs_channel : Protocol.Response.t;
    rs_init : Protocol.Response.Initializer.t;
    rs_request : request;
    mutable rs_raw_headers : (string * string) list option;
    (* Resolved once the body has been received in full, or cannot be any more. *)
    rs_finished : (unit, Error.t) result Promise.t;
    rs_finished_resolver : (unit, Error.t) result Promise.u;
}

and route = {
    rt_channel : Protocol.Route.t;
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
    mutable rh_running : int;  (* calls under way: [rh_handler] has not returned, or has not settled its route *)
    rh_idle : Eio.Condition.t;  (* signalled when [rh_running] drops to zero *)
    mutable rh_quiet : bool;  (* removed with [`Ignore_errors]: what the calls under way raise is dropped *)
}

and ws_route_handler = {
    wh_matcher : url_matcher;
    wh_matches : string -> bool;
    wh_handler : web_socket_route -> unit;
}

and web_socket = {
    ws_channel : Protocol.Web_socket.t;
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
    wr_channel : Protocol.Web_socket_route.t;
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
    w_channel : Protocol.Worker.t;
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
    d_channel : Protocol.Dialog.t;
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
    we_location : Protocol.Browser_context.Page_error_event_location.t;
}

and download = {
    dl_page : page;
    dl_url : string;
    suggested_filename : string;
    dl_artifact : Protocol.Artifact.t;
}

and file_chooser = {
    fc_page : page;
    fc_element : element_handle;
    is_multiple : bool;
}

and binding_source = {
    bs_context : browser_context;
    bs_page : page;
    bs_frame : frame;
}

and binding = binding_source -> js list -> js

and tracing = {
    t_channel : Protocol.Tracing.t;
    t_session : session;
}

and api_request_context = {
    a_channel : Protocol.Api_request_context.t;
    a_session : session;
    a_tracing : tracing;
    a_timeouts : Timeouts.t;
    mutable a_close_reason : string option;
    a_close_state : Closing.t;
}

and api_response = {
    ar_context : api_request_context;
    ar_init : Protocol.Api_response.t;
}

and cdp_session = {
    cdp_channel : Protocol.Cdp_session.t;
    mutable cdp_detached : bool;
    cdpe_event : (string * Json.t) Emitter.t;
    cdpe_close : cdp_session Emitter.t;
}

type playwright = {
    session : session;
    pw_channel : Protocol.Playwright.t;
    chromium : browser_type;
    firefox : browser_type;
    webkit : browser_type;
    stopped : unit Promise.t;  (* resolved once the connection has ended and the driver is gone *)
}

(* The client object behind each channel.  [Objects] makes it as the driver announces the object,
   before anything can refer to it: a channel of one of these interfaces always leads to its
   client object. *)
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

let client channel = (Channel.any channel).impl

(* Not reached, for the reason given above. *)
let unbound channel =
    let channel = Channel.any channel in
    Error.raise_ "Internal error: object %S, a %s, has no client side" channel.guid channel.type_

let browser_type (c : Protocol.Browser_type.t) = match client c with Browser_type x -> x | _ -> unbound c
let browser (c : Protocol.Browser.t) = match client c with Browser x -> x | _ -> unbound c
let browser_context (c : Protocol.Browser_context.t) = match client c with Browser_context x -> x | _ -> unbound c
let page (c : Protocol.Page.t) = match client c with Page x -> x | _ -> unbound c
let frame (c : Protocol.Frame.t) = match client c with Frame x -> x | _ -> unbound c
let js_handle (c : [> Protocol.Js_handle.kind ] Channel.t) = match client c with Js_handle x -> x | _ -> unbound c
let request (c : Protocol.Request.t) = match client c with Request x -> x | _ -> unbound c
let response (c : Protocol.Response.t) = match client c with Response x -> x | _ -> unbound c
let route (c : Protocol.Route.t) = match client c with Route x -> x | _ -> unbound c
let web_socket (c : Protocol.Web_socket.t) = match client c with Web_socket x -> x | _ -> unbound c
let web_socket_route (c : Protocol.Web_socket_route.t) = match client c with Web_socket_route x -> x | _ -> unbound c
let worker (c : Protocol.Worker.t) = match client c with Worker x -> x | _ -> unbound c
let dialog (c : Protocol.Dialog.t) = match client c with Dialog x -> x | _ -> unbound c
let tracing (c : Protocol.Tracing.t) = match client c with Tracing x -> x | _ -> unbound c
let api_request_context (c : Protocol.Api_request_context.t) = match client c with Api_request_context x -> x | _ -> unbound c
let cdp_session (c : Protocol.Cdp_session.t) = match client c with Cdp_session x -> x | _ -> unbound c

(* A handle to an element is a handle like any other, to an object of an interface that has more
   commands. *)
let element (c : Protocol.Element_handle.t) = { e_handle = js_handle c; e_channel = c }

let page_of_frame (frame : frame) =
    match frame.page with
    | Some page -> page
    | None -> Error.raise_ "The frame is not attached to a page yet"
