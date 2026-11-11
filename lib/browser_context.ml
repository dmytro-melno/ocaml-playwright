open Eio.Std
open Types

type t = browser_context

type _ event =
    | Close : browser_context event
    | Console : console_message event
    | Dialog : dialog event
    | Page : page event
    | Web_error : web_error event
    | Request : request event
    | Request_failed : request event
    | Request_finished : request event
    | Response : response event
    | Service_worker : worker event

let emitter : type a. t -> a event -> a Emitter.t =
    fun context -> function
    | Close -> context.ce_close
    | Console -> context.ce_console
    | Dialog -> context.ce_dialog
    | Page -> context.ce_page
    | Web_error -> context.ce_web_error
    | Request -> context.ce_request
    | Request_failed -> context.ce_request_failed
    | Request_finished -> context.ce_request_finished
    | Response -> context.ce_response
    | Service_worker -> context.ce_service_worker

let event_name : type a. a event -> string = function
    | Close -> "close"
    | Console -> "console"
    | Dialog -> "dialog"
    | Page -> "page"
    | Web_error -> "weberror"
    | Request -> "request"
    | Request_failed -> "requestfailed"
    | Request_finished -> "requestfinished"
    | Response -> "response"
    | Service_worker -> "serviceworker"

let emit (context : t) emitter value = ignore (Emitter.emit context.c_session.conn emitter value)
(* Like the original, this is true from the moment that the context is being closed. *)
let is_closed (context : t) = not (Closing.is_open context.close_state)
let close_error (context : t) = Error.target_closed ?message:(Frame.effective_close_reason context) ()

(* {1 Network interception} *)

let update_interception (context : t) =
    let patterns =
        Route.Handler.globs (List.map (fun (handler : route_handler) -> handler.rh_matcher) context.c_routes)
        |> List.map (fun glob : Protocol.Browser_context.Set_network_interception_patterns_patterns.t ->
               { glob = Some glob; regex_source = None; regex_flags = None; url_pattern = None })
    in
    Protocol.Browser_context.set_network_interception_patterns ~patterns context.c_channel

let update_web_socket_interception (context : t) =
    let patterns =
        Route.Handler.globs (List.map (fun (handler : ws_route_handler) -> handler.wh_matcher) context.c_ws_routes)
        |> List.map (fun glob : Protocol.Browser_context.Set_web_socket_interception_patterns_patterns.t ->
               { glob = Some glob; regex_source = None; regex_flags = None; url_pattern = None })
    in
    Protocol.Browser_context.set_web_socket_interception_patterns ~patterns context.c_channel

(* Offers a route to the context's handlers; a route that nobody settles goes to the network. *)
let on_route (context : t) (route : route) =
    route.rt_context <- Some context;
    let page = Network.Request.safe_page route.rt_request in
    let settled =
        Route.Handler.dispatch
            ~handlers:(fun () -> context.c_routes)
            ~remove:(fun handler -> context.c_routes <- List.filter (fun h -> h != handler) context.c_routes)
            ~stalled:(fun () -> is_closed context || match page with Some page -> page.close_was_called | None -> false)
            ~on_empty:(fun () -> try update_interception context with Error.E _ -> ())
            route
    in
    if not settled then try Route.send_continue route ~is_fallback:true with Error.E _ -> ()

let on_web_socket_route (context : t) (route : web_socket_route) =
    if not (Route.Web_socket.dispatch context.c_ws_routes route) then ignore (Route.Web_socket.connect_to_server route)

let on_binding (context : t) (call : Protocol.Binding_call.t) =
    let init = Protocol.Binding_call.initializer_ call in
    Option.iter (Route.Binding.call call) (Hashtbl.find_opt context.c_bindings init.name)

let add_route ?times matcher handler (context : t) =
    let handler = Route.Handler.make context.c_session ?base_url:context.base_url ?times matcher handler in
    context.c_routes <- handler :: context.c_routes;
    update_interception context

let route ?times glob handler context = add_route ?times (Glob glob) handler context
let route_matching ?times predicate handler context = add_route ?times (Predicate predicate) handler context

(* Answers requests from the HAR file [har], or with [update] records one there instead. *)
let route_from_har ?url ?not_found ?(update = false) ?update_content ?update_mode har (context : t) =
    if update then ignore (Tracing.record_into_har ?url_glob:url ?content:update_content ?mode:update_mode context.tracing har : string)
    else begin
        let handler, close = Route.Har.open_ context.c_session ?not_found har in
        ignore (Emitter.once context.ce_close (fun _ -> close ()) : unit -> unit);
        add_route (Glob (Option.value url ~default:"**/*")) handler context
    end

let unroute glob (context : t) =
    context.c_routes <- List.filter (fun (handler : route_handler) -> not (Route.Handler.matcher_equal handler.rh_matcher (Glob glob))) context.c_routes;
    update_interception context

let unroute_all (context : t) =
    context.c_routes <- [];
    update_interception context

let add_web_socket_route matcher handler (context : t) =
    context.c_ws_routes <- Route.Web_socket.make_handler context.c_session ?base_url:context.base_url matcher handler :: context.c_ws_routes;
    update_web_socket_interception context

let route_web_socket glob handler context = add_web_socket_route (Glob glob) handler context
let route_web_socket_matching predicate handler context = add_web_socket_route (Predicate predicate) handler context

(* {1 Events from the driver} *)

let js_error (error : Protocol.Serialized_error.t) : Error.t =
    match error.error, error.value with
    | Some e, _ -> Error.make ~name:e.name ?stack:e.stack e.message
    | None, Some value -> Error.make (Js.show (Js.of_wire value))
    | None, None -> Error.make ""

(* The context is gone: it was closed, or its browser or the connection to it went away. *)
let did_close (context : t) =
    if Closing.set_closed context.close_state then begin
        Option.iter (fun (browser : browser) -> browser.contexts <- List.filter (fun c -> c != context) browser.contexts) context.browser;
        (let selectors = context.c_session.selectors in
         selectors.all_contexts <- List.filter (fun c -> c != context) selectors.all_contexts);
        Promise.resolve context.c_closed_resolver ();
        emit context context.ce_close context
    end

let handle_event (context : t) (event : Protocol.Browser_context.event) =
    let conn = context.c_session.conn in
    let fork what f = Connection.fork conn what f in
    let handle what f = Connection.handle conn what f in
    match event with
    | Binding_call { binding } -> handle "exposed binding" (fun () -> on_binding context binding)
    | Close -> did_close context
    | Page { page } ->
        let page = Types.page page in
        context.pages <- context.pages @ [ page ];
        emit context context.ce_page page;
        (match page.opener with Some opener when not opener.closed -> emit context opener.pe_popup page | _ -> ())
    | Route { route } -> handle "route" (fun () -> on_route context (Types.route route))
    | Web_socket_route { web_socket_route } ->
        handle "WebSocket route" (fun () -> on_web_socket_route context (Types.web_socket_route web_socket_route))
    | Service_worker { worker } ->
        let worker = Types.worker worker in
        worker.w_context <- Some context;
        context.service_workers <- context.service_workers @ [ worker ];
        emit context context.ce_service_worker worker
    | Console { type_; text; args; location; timestamp; page; worker } ->
        let page = Option.map Types.page page in
        let worker = Option.map Types.worker worker in
        let message =
            { cm_type = type_; cm_text = text; cm_args = List.map Types.js_handle args; cm_location = location; cm_timestamp = timestamp;
              cm_page = page; cm_worker = worker }
        in
        Option.iter (fun (worker : worker) -> emit context worker.we_console message) worker;
        Option.iter (fun (page : page) -> emit context page.pe_console message) page;
        emit context context.ce_console message
    | Page_error { error; page; location = _ } ->
        let page = Types.page page in
        let error = js_error error in
        emit context context.ce_web_error { we_page = Some page; we_error = error };
        emit context page.pe_page_error error
    | Dialog { dialog } ->
        let channel = dialog in
        let dialog = Types.dialog channel in
        let handled = Emitter.emit conn context.ce_dialog dialog in
        let handled = match dialog.d_page with Some page -> Emitter.emit conn page.pe_dialog dialog || handled | None -> handled in
        (* The driver dismisses dialogs nobody subscribed to, but a subscription that was just
           dropped may not have reached it yet. *)
        if not handled then
            fork "dialog" (fun () ->
                try if dialog.d_type = "beforeunload" then Protocol.Dialog.accept channel else Protocol.Dialog.dismiss channel
                with Error.E _ -> ())
    | Dialog_closed _ -> ()
    | Request { request; page } ->
        let request = Types.request request in
        emit context context.ce_request request;
        Option.iter (fun page -> emit context (Types.page page).pe_request request) page
    | Request_failed { request; failure_text; response_end_timing; page } ->
        let request = Types.request request in
        request.failure <- Some (Option.value failure_text ~default:"");
        Network.Request.set_response_end request response_end_timing;
        emit context context.ce_request_failed request;
        Option.iter (fun page -> emit context (Types.page page).pe_request_failed request) page
    | Request_finished { request; response; response_end_timing; page } ->
        let request = Types.request request in
        Network.Request.set_response_end request response_end_timing;
        emit context context.ce_request_finished request;
        Option.iter (fun page -> emit context (Types.page page).pe_request_finished request) page;
        Option.iter
            (fun response ->
                let response = Types.response response in
                if not (Promise.is_resolved response.rs_finished) then Promise.resolve response.rs_finished_resolver (Ok ()))
            response
    | Response { response; page } ->
        let response = Types.response response in
        emit context context.ce_response response;
        Option.iter (fun page -> emit context (Types.page page).pe_response response) page
    | Recorder_event _ -> ()

let create session (channel : Protocol.Browser_context.t) : t =
    let init = Protocol.Browser_context.initializer_ channel in
    let c_closed, c_closed_resolver = Promise.create () in
    let c_timeouts = Timeouts.create () in
    let request = Types.api_request_context init.request_context in
    request.a_timeouts <- c_timeouts;
    let context =
        { c_channel = channel; c_session = session; browser = None; pages = []; c_routes = []; c_ws_routes = []; c_bindings = Hashtbl.create 4;
          c_timeouts; owner_page = None; base_url = init.options.base_url; records_video = init.options.record_video <> None;
          tracing = Types.tracing init.tracing; request; service_workers = []; close_state = Closing.create (); c_close_reason = None; c_closed;
          c_closed_resolver; ce_close = Emitter.create (); ce_console = Emitter.create (); ce_dialog = Emitter.create ();
          ce_page = Emitter.create (); ce_web_error = Emitter.create (); ce_request = Emitter.create (); ce_request_failed = Emitter.create ();
          ce_request_finished = Emitter.create (); ce_response = Emitter.create (); ce_service_worker = Emitter.create () }
    in
    let subscribe emitter event =
        Events.subscribe_on_demand session.conn emitter (fun ~enabled -> Protocol.Browser_context.update_subscription ~event ~enabled channel)
    in
    subscribe context.ce_console `Console;
    subscribe context.ce_dialog `Dialog;
    subscribe context.ce_request `Request;
    subscribe context.ce_response `Response;
    subscribe context.ce_request_finished `Request_finished;
    subscribe context.ce_request_failed `Request_failed;
    session.selectors.all_contexts <- context :: session.selectors.all_contexts;
    Protocol.Browser_context.listen channel (handle_event context);
    Channel.on_lost channel (fun _ -> did_close context);
    context

(* Starts the HAR recording that a context was created with, if any. *)
let start_har_recording (options : Context_options.t) (context : t) =
    Option.iter
        (fun (har : Context_options.har) ->
            let content = match har.har_content with Some content -> content | None -> if Tracing.is_zip har.har_path then `Attach else `Embed in
            ignore
                (Tracing.record_into_har ?url_glob:har.har_url_filter ~content ~mode:(Option.value har.har_mode ~default:`Full) context.tracing
                     har.har_path))
        options.record_har

(* {1 Events for the user} *)

let on event listener (context : t) = ignore (Emitter.on (emitter context event) listener : unit -> unit)
let once event listener (context : t) = ignore (Emitter.once (emitter context event) listener : unit -> unit)
let off event listener (context : t) = Emitter.off (emitter context event) listener

let expect_event (type a) ?timeout ?predicate (event : a event) action (context : t) : a =
    let timeout = Timeouts.action ?timeout context.c_timeouts in
    let rejections waiter =
        match event with
        | Close -> ()
        | _ -> Waiter.reject_on waiter context.ce_close (fun _ -> Some (close_error context))
    in
    Events.expect context.c_session.conn ~timeout ~name:(event_name event) ?predicate ~rejections (emitter context event) action

let wait_for_event ?timeout ?predicate event context = expect_event ?timeout ?predicate event ignore context
let expect_page ?timeout ?predicate action context = expect_event ?timeout ?predicate Page action context

(* {1 Operations} *)

let browser (context : t) = context.browser
let pages (context : t) = context.pages
let service_workers (context : t) = context.service_workers
let tracing (context : t) = context.tracing
let request (context : t) = context.request
let set_default_timeout timeout (context : t) = context.c_timeouts.default <- Some timeout
let set_default_navigation_timeout timeout (context : t) = context.c_timeouts.default_navigation <- Some timeout

let new_page (context : t) =
    if context.owner_page <> None then Error.raise_ "Please use Browser.new_context";
    Protocol.Browser_context.new_page context.c_channel |> Types.page

module Cookie = Cookie

let cookies ?(urls = []) (context : t) = Protocol.Browser_context.cookies ~urls context.c_channel |> List.map Cookie.of_protocol
let add_cookies cookies (context : t) = Protocol.Browser_context.add_cookies ~cookies context.c_channel
let clear_cookies ?name ?domain ?path (context : t) = Protocol.Browser_context.clear_cookies ?name ?domain ?path context.c_channel
let grant_permissions ?origin permissions (context : t) = Protocol.Browser_context.grant_permissions ~permissions ?origin context.c_channel
let clear_permissions (context : t) = Protocol.Browser_context.clear_permissions context.c_channel

let set_geolocation (geolocation : Context_options.Geolocation.t option) (context : t) =
    let geolocation =
        Option.map
            (fun (g : Context_options.Geolocation.t) : Protocol.Browser_context.Set_geolocation_geolocation.t ->
                { longitude = g.longitude; latitude = g.latitude; accuracy = g.accuracy })
            geolocation
    in
    Protocol.Browser_context.set_geolocation ?geolocation context.c_channel

let set_extra_http_headers headers (context : t) =
    Protocol.Browser_context.set_extra_http_headers ~headers:(Network.name_values headers) context.c_channel

let set_offline offline (context : t) = Protocol.Browser_context.set_offline ~offline context.c_channel

let init_script ?path ?script () =
    match path, script with
    | Some path, None -> Frame.script_with_source_url ~path (Files.read path)
    | None, Some script -> script
    | _ -> invalid_arg "Playwright: pass either ~script or ~path"

let add_init_script ?path ?script (context : t) =
    ignore (Protocol.Browser_context.add_init_script ~source:(init_script ?path ?script ()) context.c_channel)

let expose_binding name (binding : binding) (context : t) =
    ignore (Protocol.Browser_context.expose_binding ~name context.c_channel);
    Hashtbl.replace context.c_bindings name binding

let expose_function name f context = expose_binding name (fun _ args -> f args) context

let set_storage_state (state : Yojson.Safe.t) (context : t) =
    Protocol.Browser_context.set_storage_state
        ~storage_state:(Protocol.Browser_context.Set_storage_state_storage_state.of_json context.c_session.conn state)
        context.c_channel

let storage_state ?path ?indexed_db (context : t) : Yojson.Safe.t =
    let state =
        Protocol.Browser_context.storage_state ?indexed_db context.c_channel |> Protocol.Browser_context.Storage_state_result.to_json
    in
    Option.iter (fun path -> Files.write path (Yojson.Safe.pretty_to_string state)) path;
    state

let new_cdp_session_for_page (page : page) (context : t) =
    Protocol.Browser_context.new_cdp_session ~page:page.p_channel context.c_channel |> Types.cdp_session

let new_cdp_session_for_frame (frame : frame) (context : t) =
    Protocol.Browser_context.new_cdp_session ~frame:frame.f_channel context.c_channel |> Types.cdp_session

(* Closing is idempotent, and a context whose browser is already gone counts as closed.  What
   is being recorded is saved first.  If that fails, the context is closed all the same and the
   failure is raised afterwards. *)
let close ?reason (context : t) =
    if Closing.is_open context.close_state then context.c_close_reason <- reason;
    Closing.close context.c_session.conn context.close_state (fun () ->
        let recording_failure =
            try
                Api_request.Context.dispose ?reason context.request;
                Tracing.export_all_hars context.tracing;
                None
            with
            | Error.E { kind = Target_closed; _ } -> None
            | ex when not (Connection.is_cancellation ex) -> Some (ex, Printexc.get_raw_backtrace ())
        in
        Protocol.Browser_context.close ?reason context.c_channel;
        Promise.await context.c_closed;
        Option.iter (fun (ex, backtrace) -> Printexc.raise_with_backtrace ex backtrace) recording_failure)

(* {1 Clock} *)

module Clock = struct
    let install ?time (context : t) = Protocol.Browser_context.clock_install ?time_number:time context.c_channel
    let fast_forward ticks (context : t) = Protocol.Browser_context.clock_fast_forward ~ticks_number:ticks context.c_channel
    let pause_at time (context : t) = Protocol.Browser_context.clock_pause_at ~time_number:time context.c_channel
    let resume (context : t) = Protocol.Browser_context.clock_resume context.c_channel
    let run_for ticks (context : t) = Protocol.Browser_context.clock_run_for ~ticks_number:ticks context.c_channel
    let set_fixed_time time (context : t) = Protocol.Browser_context.clock_set_fixed_time ~time_number:time context.c_channel
    let set_system_time time (context : t) = Protocol.Browser_context.clock_set_system_time ~time_number:time context.c_channel
end
