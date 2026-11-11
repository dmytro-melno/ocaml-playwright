open Eio.Std
open Types

type t = browser

let default_test_id_attribute = "data-testid"

(* Applies what the browser was launched with to a context of its own. *)
let setup_context (browser : t) (context : browser_context) =
    context.browser <- Some browser;
    if not (List.memq context browser.contexts) then browser.contexts <- browser.contexts @ [ context ];
    context.tracing.traces_dir <- browser.b_traces_dir;
    context.request.a_tracing.traces_dir <- browser.b_traces_dir

let handle_event (browser : t) name params =
    let conn = browser.b_session.conn in
    match Protocol.Browser.event_of_json conn name params with
    | Some (Context { context }) -> setup_context browser (Types.browser_context context)
    | Some Close ->
        browser.connected <- false;
        if not (Promise.is_resolved browser.b_closed) then Promise.resolve browser.b_closed_resolver ();
        ignore (Emitter.emit conn browser.e_disconnected browser)
    | None -> ()

let create session (channel : Channel.t) =
    let init = Protocol.Browser.Initializer.of_json channel.conn channel.initializer_ in
    let browser_type = match channel.parent with Some { impl = Browser_type browser_type; _ } -> Some browser_type | _ -> None in
    let b_closed, b_closed_resolver = Promise.create () in
    let browser =
        { b_channel = channel; b_session = session; browser_type; b_name = init.name; version = init.version; contexts = []; connected = true;
          b_close_reason = None; b_traces_dir = None; disconnect = None; b_closed; b_closed_resolver; e_disconnected = Emitter.create () }
    in
    channel.impl <- Browser browser;
    channel.on_event <- handle_event browser

let browser_type (browser : t) =
    match browser.browser_type with
    | Some browser_type -> browser_type
    | None -> Error.raise_ "The browser is not associated with a browser type"

let contexts (browser : t) = browser.contexts
let version (browser : t) = browser.version
let name (browser : t) = browser.b_name
let is_connected (browser : t) = browser.connected
let on_disconnected listener (browser : t) = Emitter.on browser.e_disconnected listener
let off_disconnected listener (browser : t) = Emitter.off browser.e_disconnected listener

let selector_options (session : session) =
    let engines = match session.selector_engines with [] -> None | engines -> Some engines in
    let test_id_attribute = if session.test_id_attribute = default_test_id_attribute then None else Some session.test_id_attribute in
    engines, test_id_attribute

let new_context_with (o : Context_options.t) (browser : t) =
    let session = browser.b_session in
    let selector_engines, test_id_attribute_name = selector_options session in
    let proxy =
        Option.map
            (fun (p : Context_options.Proxy.t) : Protocol.Browser.New_context_proxy.t ->
                { server = p.server; bypass = p.bypass; username = p.username; password = p.password })
            o.proxy
    in
    let storage_state = Option.map (Protocol.Browser.New_context_storage_state.of_json session.conn) o.storage_state in
    let context =
        Protocol.Browser.new_context ?no_default_viewport:o.no_default_viewport ?viewport:o.viewport ?screen:o.screen
            ?ignore_https_errors:o.ignore_https_errors ?java_script_enabled:o.java_script_enabled ?bypass_csp:o.bypass_csp
            ?user_agent:o.user_agent ?locale:o.locale ?timezone_id:o.timezone_id ?geolocation:o.geolocation ?permissions:o.permissions
            ?extra_http_headers:o.extra_http_headers ?offline:o.offline ?http_credentials:o.http_credentials
            ?device_scale_factor:o.device_scale_factor ?is_mobile:o.is_mobile ?has_touch:o.has_touch ?color_scheme:o.color_scheme
            ?reduced_motion:o.reduced_motion ?forced_colors:o.forced_colors ?accept_downloads:o.accept_downloads ?contrast:o.contrast
            ?base_url:o.base_url ?record_video:o.record_video ?strict_selectors:o.strict_selectors ?service_workers:o.service_workers
            ?selector_engines ?test_id_attribute_name ?proxy ?storage_state browser.b_channel
        |> Types.browser_context
    in
    setup_context browser context;
    Browser_context.start_har_recording o context;
    context

let new_context = Context_options.collect new_context_with

(* A page in a context of its own, which is closed together with the page. *)
let new_page =
    Context_options.collect (fun options browser ->
        let context = new_context_with options browser in
        let page = Browser_context.new_page context in
        page.owned_context <- Some context;
        context.owner_page <- Some page;
        page)

let new_browser_cdp_session (browser : t) = Protocol.Browser.new_browser_cdp_session browser.b_channel |> Types.cdp_session

(* Closing is idempotent, and a browser that is already gone counts as closed. *)
let close ?reason (browser : t) =
    browser.b_close_reason <- reason;
    try
        (match browser.disconnect with
        | Some disconnect -> disconnect ()
        | None ->
            if browser.connected then begin
                Protocol.Browser.close ?reason browser.b_channel;
                Fiber.first (fun () -> Promise.await browser.b_closed) (fun () -> ignore (Promise.await (Connection.closed browser.b_session.conn)))
            end)
    with Error.E { kind = Target_closed; _ } -> ()
