open Eio.Std
open Types

type t = browser

let equal (a : t) (b : t) = Channel.equal a.b_channel b.b_channel
let compare (a : t) (b : t) = Channel.compare a.b_channel b.b_channel
let hash (t : t) = Channel.hash t.b_channel

let default_test_id_attribute = "data-testid"

(* Applies what the browser was launched with to a context of its own. *)
let setup_context (browser : t) (context : browser_context) =
    Ownership.add_context browser context;
    Tracing.set_traces_dir context.tracing browser.b_traces_dir;
    Tracing.set_traces_dir context.request.a_tracing browser.b_traces_dir

(* The browser was launched by, or connected to through, this browser type. *)
let adopt (browser_type : browser_type) ?traces_dir (browser : t) =
    browser.browser_type <- Some browser_type;
    browser.b_traces_dir <- traces_dir;
    List.iter (setup_context browser) browser.contexts

(* The browser is gone: it was closed, it crashed, or the connection to it ended. *)
let did_close (browser : t) =
    if Closing.set_closed browser.b_close_state then begin
        Promise.resolve browser.b_closed_resolver ();
        ignore (Emitter.emit browser.b_session.conn browser.e_disconnected browser)
    end

let handle_event (browser : t) : Protocol.Browser.event -> unit = function
    | Context { context } ->
        let context = Types.browser_context context in
        setup_context browser context;
        ignore (Emitter.emit browser.b_session.conn browser.e_context context)
    | Close -> did_close browser

let create session (channel : Protocol.Browser.t) : t =
    let init = Protocol.Browser.initializer_ channel in
    let browser_type = Option.map Types.browser_type (Channel.parent Protocol.Browser_type.kind channel) in
    let b_closed, b_closed_resolver = Promise.create () in
    let browser =
        { b_channel = channel; b_session = session; browser_type; b_name = init.name; version = init.version; contexts = []; b_close_state = Closing.create ();
          b_close_reason = None; b_traces_dir = None; b_closed; b_closed_resolver; e_disconnected = Emitter.create (); e_context = Emitter.create () }
    in
    Protocol.Browser.listen channel (handle_event browser);
    Channel.on_lost channel (fun _ -> did_close browser);
    browser

let browser_type (browser : t) =
    match browser.browser_type with
    | Some browser_type -> browser_type
    | None -> Error.raise_ "The browser is not associated with a browser type"

let contexts (browser : t) = browser.contexts
let version (browser : t) = browser.version
let name (browser : t) = browser.b_name
let is_connected (browser : t) = not (Closing.is_closed browser.b_close_state)
let on_disconnected listener (browser : t) = Disposable.listener (Emitter.on browser.e_disconnected listener)
let on_context listener (browser : t) = Disposable.listener (Emitter.on browser.e_context listener)

let selector_options (session : session) =
    let engines = match session.selectors.selector_engines with [] -> None | engines -> Some engines in
    let test_id_attribute =
        if session.selectors.test_id_attribute = default_test_id_attribute then None else Some session.selectors.test_id_attribute
    in
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
            ?ignore_https_errors:o.ignore_https_errors ?client_certificates:o.client_certificates ?java_script_enabled:o.java_script_enabled ?bypass_csp:o.bypass_csp
            ?user_agent:o.user_agent ?locale:o.locale ?timezone_id:o.timezone_id ?geolocation:o.geolocation ?permissions:o.permissions
            ?extra_http_headers:o.extra_http_headers ?offline:o.offline ?http_credentials:o.http_credentials
            ?device_scale_factor:o.device_scale_factor ?is_mobile:o.is_mobile ?has_touch:o.has_touch ?color_scheme:o.color_scheme
            ?reduced_motion:o.reduced_motion ?forced_colors:o.forced_colors ?accept_downloads:o.accept_downloads ?contrast:o.contrast
            ?base_url:o.base_url ?record_video:o.record_video ?strict_selectors:o.strict_selectors ?service_workers:o.service_workers
            ?selector_engines ?test_id_attribute_name ?proxy ?storage_state browser.b_channel
        |> Types.browser_context
    in
    setup_context browser context;
    Connection.guard session.conn "closing a browser context" ~undo:(fun () -> Browser_context.close context) (fun () ->
        Browser_context.start_har_recording o context);
    context

let new_context ?proxy = Context_options.collect (fun options browser -> new_context_with { options with proxy } browser)

(* A page in a context of its own, which is closed together with the page. *)
let new_page ?proxy =
    Context_options.collect (fun options browser ->
        let context = new_context_with { options with proxy } browser in
        let page =
            Connection.guard browser.b_session.conn "closing a browser context" ~undo:(fun () -> Browser_context.close context) (fun () ->
                Browser_context.new_page context)
        in
        Ownership.give_context page context;
        page)

let new_browser_cdp_session (browser : t) = Protocol.Browser.new_browser_cdp_session browser.b_channel |> Types.cdp_session

(* Closing is idempotent, and a browser that is already gone counts as closed. *)
let close ?reason (browser : t) =
    if Closing.is_open browser.b_close_state then browser.b_close_reason <- reason;
    Closing.close browser.b_session.conn browser.b_close_state (fun () ->
        Protocol.Browser.close ?reason browser.b_channel;
        Promise.await browser.b_closed)
