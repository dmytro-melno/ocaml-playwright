open Eio.Std
open Types

type t = page

let equal (a : t) (b : t) = Channel.equal a.p_channel b.p_channel
let compare (a : t) (b : t) = Channel.compare a.p_channel b.p_channel
let hash (page : t) = Channel.hash page.p_channel

type _ event =
    | Close : page event
    | Console : console_message event
    | Crash : page event
    | Dialog : dialog event
    | Dialog_closed : dialog event
    | Dom_content_loaded : page event
    | Download : download event
    | File_chooser : file_chooser event
    | Frame_attached : frame event
    | Frame_detached : frame event
    | Frame_navigated : frame event
    | Load : page event
    | Page_error : Error.t event
    | Popup : page event
    | Request : request event
    | Request_failed : request event
    | Request_finished : request event
    | Response : response event
    | Web_socket : web_socket event
    | Worker : worker event

let emitter : type a. t -> a event -> a Emitter.t =
    fun page -> function
    | Close -> page.pe_close
    | Console -> page.pe_console
    | Crash -> page.pe_crash
    | Dialog -> page.pe_dialog
    | Dialog_closed -> page.pe_dialog_closed
    | Dom_content_loaded -> page.pe_dom_content_loaded
    | Download -> page.pe_download
    | File_chooser -> page.pe_file_chooser
    | Frame_attached -> page.pe_frame_attached
    | Frame_detached -> page.pe_frame_detached
    | Frame_navigated -> page.pe_frame_navigated
    | Load -> page.pe_load
    | Page_error -> page.pe_page_error
    | Popup -> page.pe_popup
    | Request -> page.pe_request
    | Request_failed -> page.pe_request_failed
    | Request_finished -> page.pe_request_finished
    | Response -> page.pe_response
    | Web_socket -> page.pe_web_socket
    | Worker -> page.pe_worker

let event_name : type a. a event -> string = function
    | Close -> "close"
    | Console -> "console"
    | Crash -> "crash"
    | Dialog -> "dialog"
    | Dialog_closed -> "dialogclosed"
    | Dom_content_loaded -> "domcontentloaded"
    | Download -> "download"
    | File_chooser -> "filechooser"
    | Frame_attached -> "frameattached"
    | Frame_detached -> "framedetached"
    | Frame_navigated -> "framenavigated"
    | Load -> "load"
    | Page_error -> "pageerror"
    | Popup -> "popup"
    | Request -> "request"
    | Request_failed -> "requestfailed"
    | Request_finished -> "requestfinished"
    | Response -> "response"
    | Web_socket -> "websocket"
    | Worker -> "worker"

let session (page : t) = page.main_frame.f_session
let conn (page : t) = (session page).conn
let emit (page : t) emitter value = ignore (Emitter.emit (conn page) emitter value)
let close_error = Frame.page_close_error

(* {1 Network interception} *)

let update_interception (page : t) =
    let patterns =
        Route.Handler.globs (List.map (fun (handler : route_handler) -> handler.rh_matcher) page.p_routes)
        |> List.map (fun glob : Protocol.Page.Set_network_interception_patterns_patterns.t ->
               { glob = Some glob; regex_source = None; regex_flags = None; url_pattern = None })
    in
    Protocol.Page.set_network_interception_patterns ~patterns page.p_channel

let update_web_socket_interception (page : t) =
    let patterns =
        Route.Handler.globs (List.map (fun (handler : ws_route_handler) -> handler.wh_matcher) page.p_ws_routes)
        |> List.map (fun glob : Protocol.Page.Set_web_socket_interception_patterns_patterns.t ->
               { glob = Some glob; regex_source = None; regex_flags = None; url_pattern = None })
    in
    Protocol.Page.set_web_socket_interception_patterns ~patterns page.p_channel

(* The page's own handlers come first; what they leave goes to the context's. *)
let on_route (page : t) (route : route) =
    Route.set_context route page.context;
    let settled =
        Route.Handler.dispatch
            ~handlers:(fun () -> page.p_routes)
            ~remove:(fun handler -> page.p_routes <- List.filter (fun h -> h != handler) page.p_routes)
            ~stalled:(fun () -> page.close_was_called || Browser_context.is_closed page.context)
            ~on_empty:(fun () -> try update_interception page with Error.E _ -> ())
            route
    in
    if not settled then Browser_context.on_route page.context route

let on_web_socket_route (page : t) (route : web_socket_route) =
    if not (Route.Web_socket.dispatch page.p_ws_routes route) then Browser_context.on_web_socket_route page.context route

let on_binding (page : t) (call : Protocol.Binding_call.t) =
    let init = Protocol.Binding_call.initializer_ call in
    match Hashtbl.find_opt page.p_bindings init.name with
    | Some binding -> Route.Binding.call call binding
    | None -> Browser_context.on_binding page.context call

let on_locator_handler_triggered (page : t) uid =
    let remove =
        match Hashtbl.find_opt page.locator_handlers uid with
        | None -> false
        | Some handler ->
            if handler.lh_times <> Some 0 then begin
                handler.lh_times <- Option.map pred handler.lh_times;
                try handler.lh_handler handler.lh_locator
                with ex when not (Connection.is_cancellation ex) -> (conn page).report "locator handler" ex (Printexc.get_raw_backtrace ())
            end;
            handler.lh_times = Some 0
    in
    if remove then Hashtbl.remove page.locator_handlers uid;
    try Protocol.Page.resolve_locator_handler_no_reply ~uid ~remove page.p_channel with Error.E _ -> ()

(* {1 Events from the driver} *)

(* The page is gone: it was closed, or its context, its browser or the connection to it went away. *)
let did_close (page : t) =
    if not page.closed then begin
        page.closed <- true;
        Ownership.remove_page page;
        if not (Promise.is_resolved page.p_gone) then Promise.resolve page.p_gone_resolver (close_error page);
        emit page page.pe_close page;
        emit page page.context.ce_page_close page
    end

let handle_event (page : t) (event : Protocol.Page.event) =
    let handle what f = Connection.handle (conn page) what f in
    match event with
    | Binding_call { binding } -> handle "exposed binding" (fun () -> on_binding page binding)
    | Close -> did_close page
    | Crash ->
        if not (Promise.is_resolved page.p_gone) then Promise.resolve page.p_gone_resolver (Error.target_closed ~message:"Page crashed" ());
        emit page page.pe_crash page
    | Download { url; suggested_filename; artifact } ->
        let download = { dl_page = page; dl_url = url; suggested_filename; dl_artifact = artifact } in
        emit page page.pe_download download;
        emit page page.context.ce_download download
    | Viewport_size_changed { viewport_size } ->
        page.viewport_size <-
            Option.map (fun (size : Protocol.Page.Viewport_size_changed_event_viewport_size.t) -> { width = size.width; height = size.height }) viewport_size
    | File_chooser { element; is_multiple } ->
        emit page page.pe_file_chooser { fc_page = page; fc_element = Types.element element; is_multiple }
    | Frame_attached { frame } ->
        let frame = Types.frame frame in
        Ownership.add_frame page frame;
        emit page page.pe_frame_attached frame;
        emit page page.context.ce_frame_attached frame
    | Frame_detached { frame } ->
        let frame = Types.frame frame in
        Ownership.remove_frame page frame;
        emit page page.pe_frame_detached frame;
        emit page page.context.ce_frame_detached frame
    | Locator_handler_triggered { uid } -> handle "locator handler" (fun () -> on_locator_handler_triggered page uid)
    | Route { route } -> handle "route" (fun () -> on_route page (Types.route route))
    | Web_socket_route { web_socket_route } ->
        handle "WebSocket route" (fun () -> on_web_socket_route page (Types.web_socket_route web_socket_route))
    | Web_socket { web_socket } -> emit page page.pe_web_socket (Types.web_socket web_socket)
    | Worker { worker } ->
        let worker = Types.worker worker in
        Ownership.add_worker page worker;
        emit page page.pe_worker worker
    | Screencast_frame _ -> ()

let create (channel : Protocol.Page.t) : t =
    let init = Protocol.Page.initializer_ channel in
    let context =
        match Channel.parent Protocol.Browser_context.kind channel with
        | Some context -> Types.browser_context context
        | None -> Error.raise_ "Protocol error: page %S does not belong to a browser context" (Channel.guid channel)
    in
    let main_frame = Types.frame init.main_frame in
    let p_gone, p_gone_resolver = Promise.create () in
    let page =
        { p_channel = channel; context; main_frame; frames = []; workers = []; closed = init.is_closed; close_was_called = false;
          p_close_reason = None;
          viewport_size = Option.map (fun (size : Protocol.Page.Initializer_viewport_size.t) -> { width = size.width; height = size.height }) init.viewport_size;
          p_routes = []; p_ws_routes = []; p_bindings = Hashtbl.create 4; p_timeouts = Timeouts.create ~parent:context.c_timeouts ();
          opener = Option.map Types.page init.opener; owned_context = None; video_artifact = init.video; locator_handlers = Hashtbl.create 1;
          p_gone; p_gone_resolver; pe_close = Emitter.create (); pe_console = Emitter.create (); pe_crash = Emitter.create ();
          pe_dialog = Emitter.create (); pe_dialog_closed = Emitter.create (); pe_dom_content_loaded = Emitter.create (); pe_download = Emitter.create ();
          pe_file_chooser = Emitter.create (); pe_frame_attached = Emitter.create (); pe_frame_detached = Emitter.create ();
          pe_frame_navigated = Emitter.create (); pe_load = Emitter.create (); pe_page_error = Emitter.create (); pe_popup = Emitter.create ();
          pe_request = Emitter.create (); pe_request_failed = Emitter.create (); pe_request_finished = Emitter.create ();
          pe_response = Emitter.create (); pe_web_socket = Emitter.create (); pe_worker = Emitter.create () }
    in
    Ownership.add_frame page main_frame;
    let subscribe emitter event =
        Events.subscribe_on_demand (Channel.conn channel) emitter (fun ~enabled -> Protocol.Page.update_subscription ~event ~enabled channel)
    in
    subscribe page.pe_console `Console;
    subscribe page.pe_dialog `Dialog;
    subscribe page.pe_dialog_closed `Dialog_closed;
    subscribe page.pe_request `Request;
    subscribe page.pe_response `Response;
    subscribe page.pe_request_finished `Request_finished;
    subscribe page.pe_request_failed `Request_failed;
    subscribe page.pe_file_chooser `File_chooser;
    Protocol.Page.listen channel (handle_event page);
    Channel.on_lost channel (fun _ -> did_close page);
    page

(* {1 Everything a page shares with its main frame} *)

include Frame.Operations (struct
    type t = page

    let frame (page : t) = page.main_frame
end)

include Locator.Queries (struct
    type t = page

    let session = session
    let find (page : t) selector = Locator.make page.main_frame selector
end)

let locator ?has_text ?has_text_regex ?has_not_text ?has_not_text_regex ?has ?has_not selector (page : t) =
    Locator.make ?has_text ?has_text_regex ?has_not_text ?has_not_text_regex ?has ?has_not page.main_frame selector

let frame_locator selector (page : t) : frame_locator = { fl_frame = page.main_frame; frame_selector = selector }

(* {1 Accessors} *)

let context (page : t) = page.context
let opener (page : t) = match page.opener with Some opener when not opener.closed -> Some opener | _ -> None
let main_frame (page : t) = page.main_frame
let frames (page : t) = page.frames
let url (page : t) = page.main_frame.f_url
let viewport_size (page : t) = Option.map (fun (size : size) -> size.width, size.height) page.viewport_size
let is_closed (page : t) = page.closed
let workers (page : t) = page.workers
let video (page : t) = if page.context.records_video then Some page else None
let set_default_timeout timeout (page : t) = Timeouts.set_default page.p_timeouts timeout
let set_default_navigation_timeout timeout (page : t) = Timeouts.set_default_navigation page.p_timeouts timeout

let frame (which : [ `Name of string | `Url of string ]) (page : t) =
    match which with
    | `Name name -> List.find_opt (fun (frame : frame) -> frame.f_name = name) page.frames
    | `Url glob ->
        let matches = Frame.url_matcher page.main_frame glob in
        List.find_opt (fun (frame : frame) -> matches frame.f_url) page.frames

(* {1 Events for the user} *)

let on event listener (page : t) = Disposable.listener (Emitter.on (emitter page event) listener)
let once event listener (page : t) = Disposable.listener (Emitter.once (emitter page event) listener)

let expect_event (type a) ?timeout ?predicate (event : a event) action (page : t) : a =
    let timeout = Timeouts.action ?timeout page.p_timeouts in
    let rejections waiter =
        (match event with
        | Crash -> ()
        | _ -> Waiter.reject_on waiter page.pe_crash (fun _ -> Some (Error.make "Page crashed")));
        match event with
        | Close -> ()
        | _ -> Waiter.reject_on waiter page.pe_close (fun _ -> Some (close_error page))
    in
    Events.expect (conn page) ~timeout ~name:(event_name event) ?predicate ~rejections (emitter page event) action

let wait_for_event ?timeout ?predicate event page = expect_event ?timeout ?predicate event ignore page
let expect_popup ?timeout ?predicate action page = expect_event ?timeout ?predicate Popup action page
let expect_download ?timeout ?predicate action page = expect_event ?timeout ?predicate Download action page
let expect_file_chooser ?timeout ?predicate action page = expect_event ?timeout ?predicate File_chooser action page
let expect_console_message ?timeout ?predicate action page = expect_event ?timeout ?predicate Console action page
let expect_web_socket ?timeout ?predicate action page = expect_event ?timeout ?predicate Web_socket action page
let expect_worker ?timeout ?predicate action page = expect_event ?timeout ?predicate Worker action page

(* Combines an optional URL glob and an optional predicate on the object carrying the URL. *)
let url_predicate (page : t) ?url ?predicate url_of =
    let matches = Option.map (Frame.url_matcher page.main_frame) url in
    fun value ->
        (match matches with Some matches -> matches (url_of value) | None -> true)
        && match predicate with Some predicate -> predicate value | None -> true

let expect_request ?timeout ?url ?predicate action page =
    expect_event ?timeout ~predicate:(url_predicate page ?url ?predicate Network.Request.url) Request action page

let expect_request_finished ?timeout ?url ?predicate action page =
    expect_event ?timeout ~predicate:(url_predicate page ?url ?predicate Network.Request.url) Request_finished action page

let expect_response ?timeout ?url ?predicate action page =
    expect_event ?timeout ~predicate:(url_predicate page ?url ?predicate Network.Response.url) Response action page

let wait_for_request ?timeout ?url ?predicate page = expect_request ?timeout ?url ?predicate ignore page
let wait_for_response ?timeout ?url ?predicate page = expect_response ?timeout ?url ?predicate ignore page

(* {1 Navigation and state} *)

let reload ?timeout ?(wait_until = `Load) (page : t) =
    Protocol.Page.reload ~timeout:(Timeouts.navigation ?timeout page.p_timeouts) ~wait_until page.p_channel |> Option.map Types.response

let go_back ?timeout ?(wait_until = `Load) (page : t) =
    Protocol.Page.go_back ~timeout:(Timeouts.navigation ?timeout page.p_timeouts) ~wait_until page.p_channel |> Option.map Types.response

let go_forward ?timeout ?(wait_until = `Load) (page : t) =
    Protocol.Page.go_forward ~timeout:(Timeouts.navigation ?timeout page.p_timeouts) ~wait_until page.p_channel |> Option.map Types.response

let bring_to_front (page : t) = Protocol.Page.bring_to_front page.p_channel
let request_gc (page : t) = Protocol.Page.request_gc page.p_channel
let requests (page : t) = Protocol.Page.requests page.p_channel |> List.map Types.request

(* What the page has logged so far, for callers that were not listening when it happened. *)
let console_messages ?filter (page : t) : console_message list =
    Protocol.Page.console_messages ?filter page.p_channel
    |> List.map (fun (message : Protocol.Page.Console_messages_result_messages.t) ->
           { cm_serial = Serial.next (); cm_type = message.type_; cm_text = message.text; cm_args = List.map Types.js_handle message.args; cm_location = message.location;
             cm_timestamp = message.timestamp; cm_page = Some page; cm_worker = None })

let clear_console_messages (page : t) = Protocol.Page.clear_console_messages page.p_channel
let page_errors ?filter (page : t) = Protocol.Page.page_errors ?filter page.p_channel |> List.map Browser_context.js_error
let clear_page_errors (page : t) = Protocol.Page.clear_page_errors page.p_channel

(* The page's local or session storage for its current origin. *)
module Web_storage = struct
    type t = page * [ `Local | `Session ]

    let equal ((a, kind_a) : t) ((b, kind_b) : t) = equal a b && kind_a = kind_b
    let compare ((a, kind_a) : t) ((b, kind_b) : t) = match compare a b with 0 -> Stdlib.compare kind_a kind_b | order -> order
    let hash ((page, kind) : t) = Hashtbl.hash (hash page, kind)

    let items ((page, kind) : t) =
        Protocol.Page.web_storage_items ~kind page.p_channel |> List.map (fun (item : Protocol.Name_value.t) -> item.name, item.value)

    let get_item name ((page, kind) : t) = Protocol.Page.web_storage_get_item ~kind ~name page.p_channel
    let set_item name ~value ((page, kind) : t) = Protocol.Page.web_storage_set_item ~kind ~name ~value page.p_channel
    let remove_item name ((page, kind) : t) = Protocol.Page.web_storage_remove_item ~kind ~name page.p_channel
    let clear ((page, kind) : t) = Protocol.Page.web_storage_clear ~kind page.p_channel
end

let local_storage (page : t) : Web_storage.t = page, `Local
let session_storage (page : t) : Web_storage.t = page, `Session

let set_viewport_size (width, height) (page : t) =
    page.viewport_size <- Some { width; height };
    Protocol.Page.set_viewport_size ~viewport_size:{ width; height } page.p_channel

let emulate_media ?media ?color_scheme ?reduced_motion ?forced_colors ?contrast (page : t) =
    Protocol.Page.emulate_media ?media ?color_scheme ?reduced_motion ?forced_colors ?contrast page.p_channel

let set_extra_http_headers headers (page : t) = Protocol.Page.set_extra_http_headers ~headers:(Network.name_values headers) page.p_channel

let add_init_script script (page : t) =
    Disposable.of_channel (Protocol.Page.add_init_script ~source:(Browser_context.script_source script) page.p_channel)

let expose_binding name (binding : binding) (page : t) =
    Browser_context.keep_binding page.p_bindings name binding (Protocol.Page.expose_binding ~name page.p_channel)

let expose_function name f page = expose_binding name (fun _ args -> f args) page

let aria_snapshot ?timeout ?mode ?depth ?boxes (page : t) =
    Protocol.Frame.aria_snapshot ~timeout:(Timeouts.action ?timeout page.p_timeouts) ?mode ?depth ?boxes page.main_frame.f_channel

let aria_snapshot_json ?timeout ?mode ?depth ?boxes (page : t) =
    Protocol.Frame.aria_snapshot_json ~timeout:(Timeouts.action ?timeout page.p_timeouts) ?mode ?depth ?boxes page.main_frame.f_channel

(* The element that a snapshot for machines marked with [ref=...]. *)
let get_by_ref reference (page : t) = Locator.make page.main_frame ("aria-ref=" ^ reference)

(* Lets the person in front of a headed browser point at an element. *)
let pick_locator (page : t) = Locator.make page.main_frame (Protocol.Page.pick_locator page.p_channel)
let cancel_pick_locator (page : t) = Protocol.Page.cancel_pick_locator page.p_channel
let hide_highlight (page : t) = Protocol.Page.hide_highlight page.p_channel

(* {1 Routing} *)

let remove_routes ?(behavior = `Default) removed (page : t) =
    let removed, remaining = List.partition removed page.p_routes in
    page.p_routes <- remaining;
    List.iter (Route.Handler.stop behavior) removed;
    update_interception page

let add_route ?times matcher handler (page : t) =
    let handler = Route.Handler.make ?base_url:page.context.base_url ?times matcher handler in
    let remove () = remove_routes (fun h -> h == handler) page in
    page.p_routes <- handler :: page.p_routes;
    (* A handler that the driver could not be told about is taken back: nothing else could do that. *)
    Connection.guard (conn page) "taking back a route" ~undo:remove (fun () -> update_interception page);
    Disposable.registration (conn page) remove

let route ?times glob handler page = add_route ?times (Glob glob) handler page
let route_matching ?times predicate handler page = add_route ?times (Predicate predicate) handler page

let route_from_har ?url ?not_found ?(update = false) ?update_content ?update_mode har (page : t) =
    if update then ignore (Tracing.record_into_har ~page ?url_glob:url ?content:update_content ?mode:update_mode page.context.tracing har : string)
    else begin
        let handler, close = Route.Har.open_ (session page) ?not_found har in
        ignore (Emitter.once page.pe_close (fun _ -> close ()) : unit -> unit);
        ignore (add_route (Glob (Option.value url ~default:"**/*")) handler page : Disposable.t)
    end

let unroute glob page = remove_routes (fun (handler : route_handler) -> Route.Handler.matcher_equal handler.rh_matcher (Glob glob)) page
let unroute_all ?behavior page = remove_routes ?behavior (fun _ -> true) page

let add_web_socket_route matcher handler (page : t) =
    let handler = Route.Web_socket.make_handler ?base_url:page.context.base_url matcher handler in
    let remove () =
        page.p_ws_routes <- List.filter (fun h -> h != handler) page.p_ws_routes;
        update_web_socket_interception page
    in
    page.p_ws_routes <- handler :: page.p_ws_routes;
    Connection.guard (conn page) "taking back a WebSocket route" ~undo:remove (fun () -> update_web_socket_interception page);
    Disposable.registration (conn page) remove

let route_web_socket glob handler page = add_web_socket_route (Glob glob) handler page
let route_web_socket_matching predicate handler page = add_web_socket_route (Predicate predicate) handler page

(* {1 Locator handlers} *)

let add_locator_handler ?times ?no_wait_after (locator : locator) handler (page : t) =
    if locator.l_frame != page.main_frame then invalid_arg "Playwright: the locator must belong to the main frame of this page";
    if times <> Some 0 then begin
        let uid = Protocol.Page.register_locator_handler ~selector:locator.selector ?no_wait_after page.p_channel in
        Hashtbl.replace page.locator_handlers uid { lh_locator = locator; lh_handler = handler; lh_times = times }
    end

let remove_locator_handler (locator : locator) (page : t) =
    Hashtbl.to_seq page.locator_handlers
    |> List.of_seq
    |> List.iter (fun (uid, (handler : locator_handler)) ->
           if Locator.equal handler.lh_locator locator then begin
               Hashtbl.remove page.locator_handlers uid;
               try Protocol.Page.unregister_locator_handler ~uid page.p_channel with Error.E _ -> ()
           end)

(* {1 Output} *)

let screenshot ?full_page ?clip ?timeout ?path ?type_ ?quality ?omit_background ?caret ?animations ?scale ?mask ?mask_color ?style (page : t) =
    Protocol.Page.screenshot ~timeout:(Timeouts.action ?timeout page.p_timeouts) ?type_:(Screenshot.image_type ?type_ ?path ()) ?quality
        ?full_page ?clip ?omit_background ?caret ?animations ?scale ?mask:(Option.map Screenshot.mask mask) ?mask_color ?style page.p_channel
    |> Screenshot.save ?path

let pdf ?path ?scale ?display_header_footer ?header_template ?footer_template ?print_background ?landscape ?page_ranges ?format ?width ?height
    ?prefer_css_page_size ?margin_top ?margin_right ?margin_bottom ?margin_left ?tagged ?outline (page : t) =
    let margin : Protocol.Page.Pdf_margin.t option =
        match margin_top, margin_right, margin_bottom, margin_left with
        | None, None, None, None -> None
        | top, right, bottom, left -> Some { top; right; bottom; left }
    in
    Protocol.Page.pdf ?scale ?display_header_footer ?header_template ?footer_template ?print_background ?landscape ?page_ranges ?format ?width
        ?height ?prefer_css_page_size ?margin ?tagged ?outline page.p_channel
    |> Screenshot.save ?path

(* {1 Closing} *)

let close ?(run_before_unload = false) ?reason (page : t) =
    page.p_close_reason <- reason;
    if not run_before_unload then page.close_was_called <- true;
    try
        match page.owned_context with
        | Some context -> Browser_context.close context
        | None ->
            Connection.detached (Channel.conn page.p_channel) (fun () ->
                if run_before_unload then Protocol.Page.run_before_unload page.p_channel else Protocol.Page.close ?reason page.p_channel)
    with Error.E { kind = Target_closed; _ } when not run_before_unload -> ()

(* Hands control to the Playwright inspector until the user resumes the script. *)
let pause (page : t) =
    Timeouts.suspended page.context.c_timeouts (fun () ->
        Fiber.first (fun () -> Protocol.Browser_context.pause page.context.c_channel) (fun () -> ignore (Promise.await page.p_gone)))

(* {1 Input devices} *)

module Keyboard = struct
    type t = page

    let equal = equal
    let compare = compare
    let hash = hash

    let down key (page : t) = Protocol.Page.keyboard_down ~key page.p_channel
    let up key (page : t) = Protocol.Page.keyboard_up ~key page.p_channel
    let insert_text text (page : t) = Protocol.Page.keyboard_insert_text ~text page.p_channel
    let type_ ?delay text (page : t) = Protocol.Page.keyboard_type ~text ?delay page.p_channel
    let press ?delay key (page : t) = Protocol.Page.keyboard_press ~key ?delay page.p_channel
end

module Mouse = struct
    type t = page

    let equal = equal
    let compare = compare
    let hash = hash

    let move ?steps ~x ~y (page : t) = Protocol.Page.mouse_move ~x ~y ?steps page.p_channel
    let down ?button ?click_count (page : t) = Protocol.Page.mouse_down ?button ?click_count page.p_channel
    let up ?button ?click_count (page : t) = Protocol.Page.mouse_up ?button ?click_count page.p_channel
    let click ?delay ?button ?click_count ~x ~y (page : t) = Protocol.Page.mouse_click ~x ~y ?delay ?button ?click_count page.p_channel
    let dblclick ?delay ?button ~x ~y page = click ?delay ?button ~click_count:2 ~x ~y page
    let wheel ~delta_x ~delta_y (page : t) = Protocol.Page.mouse_wheel ~delta_x ~delta_y page.p_channel
end

module Touchscreen = struct
    type t = page

    let equal = equal
    let compare = compare
    let hash = hash

    let tap ~x ~y (page : t) = Protocol.Page.touchscreen_tap ~x ~y page.p_channel
end

module Video = struct
    type t = page

    let equal = equal
    let compare = compare
    let hash = hash

    let artifact (page : t) =
        match page.video_artifact with
        | Some artifact -> artifact
        | None -> Error.raise_ "Video recording has not been started."

    (* Where the browser writes the video.  The file is complete once the page is closed. *)
    let path (page : t) = (Protocol.Artifact.initializer_ (artifact page)).absolute_path

    let save_as path (page : t) = Artifact.save_as (artifact page) path
    let delete (page : t) = Option.iter Artifact.delete page.video_artifact
end
