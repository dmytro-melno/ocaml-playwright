open Eio.Std
open Types

type t = browser

let equal (a : t) (b : t) = Channel.equal a.b_channel b.b_channel
let compare (a : t) (b : t) = Channel.compare a.b_channel b.b_channel
let hash (t : t) = Channel.hash t.b_channel

type _ event =
    | Disconnected : browser event
    | Context : browser_context event

let emitter : type a. t -> a event -> a Emitter.t =
    fun browser -> function
    | Disconnected -> browser.e_disconnected
    | Context -> browser.e_context

let event_name : type a. a event -> string = function Disconnected -> "disconnected" | Context -> "context"

let default_test_id_attribute = "data-testid"

(* The browser was launched by, or connected to through, this browser type. *)
let adopt (browser_type : browser_type) (browser : t) =
    browser.browser_type <- Some browser_type;
    List.iter (Ownership.add_context browser) browser.contexts

(* The browser is gone: it was closed, it crashed, or the connection to it ended. *)
let did_close (browser : t) =
    if Closing.set_closed browser.b_close_state then begin
        Promise.resolve browser.b_closed_resolver ();
        ignore (Emitter.emit browser.b_session.conn browser.e_disconnected browser)
    end

let handle_event (browser : t) : Protocol.Browser.event -> unit = function
    | Context { context } ->
        let context = Types.browser_context context in
        Ownership.add_context browser context;
        ignore (Emitter.emit browser.b_session.conn browser.e_context context)
    | Close -> did_close browser

let create session (channel : Protocol.Browser.t) : t =
    let init = Protocol.Browser.initializer_ channel in
    let browser_type = Option.map Types.browser_type (Channel.parent Protocol.Browser_type.kind channel) in
    let b_closed, b_closed_resolver = Promise.create () in
    let browser =
        { b_channel = channel; b_session = session; browser_type; b_name = init.name; version = init.version; contexts = []; b_close_state = Closing.create ();
          b_close_reason = None; b_closed; b_closed_resolver; e_disconnected = Emitter.create (); e_context = Emitter.create () }
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
let on (browser : t) event listener = Disposable.listener (Emitter.on (emitter browser event) listener)
let once (browser : t) event listener = Disposable.listener (Emitter.once (emitter browser event) listener)

let expect_event (type a) ?timeout ?predicate (browser : t) (event : a event) action : a =
    let timeout = Timeouts.action ?timeout (Timeouts.create ()) in
    let rejections waiter =
        match event with
        | Disconnected -> ()
        | Context -> Waiter.reject_on waiter browser.e_disconnected (fun _ -> Some (Error.target_closed ?message:browser.b_close_reason ()))
    in
    Events.expect browser.b_session.conn ~timeout ~name:(event_name event) ?predicate ~rejections (emitter browser event) action

let selector_options (session : session) =
    let engines = match session.selectors.selector_engines with [] -> None | engines -> Some engines in
    let test_id_attribute =
        if session.selectors.test_id_attribute = default_test_id_attribute then None else Some session.selectors.test_id_attribute
    in
    engines, test_id_attribute

(* A proxy of its own and a state to start from are what a new context can have and a persistent one cannot, which
   has the proxy of its browser and the state of its directory.  Hence they are not among the options that both take. *)
let new_context ?(proxy : Context_options.Proxy.t option) ?storage_state =
    Context_options.collect @@ fun (o : Context_options.t) (browser : t) ->
    let session = browser.b_session in
    let selector_engines, test_id_attribute_name = selector_options session in
    let proxy =
        Option.map (fun (p : Context_options.Proxy.t) : Protocol.Browser.New_context_proxy.t -> { server = p.server; bypass = p.bypass; username = p.username; password = p.password }) proxy
    in
    let storage_state = Option.map (Protocol.Browser.New_context_storage_state.of_json session.conn) storage_state in
    let context =
        Protocol.Browser.new_context ?no_default_viewport:o.no_default_viewport ?viewport:o.viewport ?screen:o.screen
            ?ignore_https_errors:o.ignore_https_errors ?client_certificates:o.client_certificates ?java_script_enabled:o.java_script_enabled ?bypass_csp:o.bypass_csp
            ?user_agent:o.user_agent ?locale:o.locale ?timezone_id:o.timezone_id ?geolocation:o.geolocation ?permissions:o.permissions
            ?extra_http_headers:o.extra_http_headers ?offline:o.offline ?http_credentials:o.http_credentials
            ?device_scale_factor:o.device_scale_factor ?is_mobile:o.is_mobile ?has_touch:o.has_touch ?color_scheme:o.color_scheme
            ?reduced_motion:o.reduced_motion ?forced_colors:o.forced_colors ?accept_downloads:o.accept_downloads ?contrast:o.contrast
            ?base_url:o.base_url ?record_video:o.record_video ?service_workers:o.service_workers
            ?selector_engines ?test_id_attribute_name ?proxy ?storage_state browser.b_channel
        |> Types.browser_context
    in
    Ownership.add_context browser context;
    context

let new_browser_cdp_session (browser : t) = Protocol.Browser.new_browser_cdp_session browser.b_channel |> Types.cdp_session

(* Closing is idempotent, and a browser that is already gone counts as closed. *)
let close ?reason (browser : t) =
    if Closing.is_open browser.b_close_state then browser.b_close_reason <- reason;
    Closing.close browser.b_session.conn browser.b_close_state (fun () ->
        Protocol.Browser.close ?reason browser.b_channel;
        Promise.await browser.b_closed)
