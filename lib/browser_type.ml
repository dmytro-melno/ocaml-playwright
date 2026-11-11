open Types

type t = browser_type

let equal (a : t) (b : t) = Channel.equal a.bt_channel b.bt_channel
let compare (a : t) (b : t) = Channel.compare a.bt_channel b.bt_channel
let hash (t : t) = Channel.hash t.bt_channel

let create session (channel : Protocol.Browser_type.t) : t =
    let init = Protocol.Browser_type.initializer_ channel in
    { bt_channel = channel; bt_session = session; bt_name = init.name; executable_path = init.executable_path }

let name (t : t) = t.bt_name
let executable_path (t : t) = t.executable_path

type launch_options = {
    channel : string option;
    executable_path : string option;
    args : string list option;
    ignore_all_default_args : bool option;
    ignore_default_args : string list option;
    handle_sigint : bool option;
    handle_sigterm : bool option;
    handle_sighup : bool option;
    timeout : float;
    env : Protocol.Name_value.t list option;
    headless : bool option;
    proxy : Protocol.Launch_options_proxy.t option;
    downloads_path : string option;
    traces_dir : string option;
    artifacts_dir : string option;
    chromium_sandbox : bool option;
    firefox_user_prefs : Json.t option;
    slow_mo : float option;
}

let collect_launch_options k ?channel ?executable_path ?args ?ignore_all_default_args ?ignore_default_args ?handle_sigint ?handle_sigterm
    ?handle_sighup ?timeout ?env ?headless ?(proxy : Context_options.Proxy.t option) ?downloads_path ?traces_dir ?artifacts_dir ?chromium_sandbox
    ?(firefox_user_prefs : (string * Yojson.Safe.t) list option) ?slow_mo target =
    let options =
        { channel; executable_path; args; ignore_all_default_args; ignore_default_args; handle_sigint; handle_sigterm; handle_sighup;
          timeout = Timeouts.launch ?timeout ();
          env = Option.map Network.name_values env;
          headless;
          proxy =
              Option.map
                  (fun (p : Context_options.Proxy.t) : Protocol.Launch_options_proxy.t ->
                      { server = p.server; bypass = p.bypass; username = p.username; password = p.password })
                  proxy;
          downloads_path; traces_dir; artifacts_dir; chromium_sandbox;
          firefox_user_prefs = Option.map (fun prefs -> `Assoc prefs) firefox_user_prefs;
          slow_mo }
    in
    k options target

(* The driver words its hint for the Playwright CLI of the language it believes it serves. *)
let explain_missing_browser f =
    try f ()
    with Error.E error ->
        let replace_all ~sub ~by s =
            let n = String.length sub in
            let buffer = Buffer.create (String.length s) in
            let rec go i =
                if i > String.length s - n then Buffer.add_substring buffer s i (String.length s - i)
                else if String.sub s i n = sub then (Buffer.add_string buffer by; go (i + n))
                else (Buffer.add_char buffer s.[i]; go (i + 1))
            in
            go 0;
            Buffer.contents buffer
        in
        (* The first replacement keeps the frame around the hint straight. *)
        let message =
            error.message
            |> replace_all ~sub:" playwright install      " ~by:" ocaml-playwright install"
            |> replace_all ~sub:" playwright install" ~by:" ocaml-playwright install"
        in
        raise (Error.E { error with message })

let adopt (t : t) ?traces_dir (browser : browser) = Browser.adopt t ?traces_dir browser

let launch =
    collect_launch_options (fun o (t : t) ->
        let browser =
            explain_missing_browser (fun () ->
                Protocol.Browser_type.launch ~timeout:o.timeout ?channel:o.channel ?executable_path:o.executable_path ?args:o.args
                    ?ignore_all_default_args:o.ignore_all_default_args ?ignore_default_args:o.ignore_default_args ?handle_sigint:o.handle_sigint
                    ?handle_sigterm:o.handle_sigterm ?handle_sighup:o.handle_sighup ?env:o.env ?headless:o.headless ?proxy:o.proxy
                    ?downloads_path:o.downloads_path ?traces_dir:o.traces_dir ?artifacts_dir:o.artifacts_dir ?chromium_sandbox:o.chromium_sandbox
                    ?firefox_user_prefs:o.firefox_user_prefs ?slow_mo:o.slow_mo t.bt_channel)
            |> Types.browser
        in
        adopt t ?traces_dir:o.traces_dir browser;
        browser)

(* Launches a browser that keeps its profile in [user_data_dir] and returns its only context. *)
let launch_persistent_context =
    collect_launch_options (fun o user_data_dir ->
        Context_options.collect (fun (c : Context_options.t) (t : t) ->
            if c.storage_state <> None then invalid_arg "Playwright: a persistent context takes its storage state from the user data directory";
            let selector_engines, test_id_attribute_name = Browser.selector_options t.bt_session in
            let user_data_dir = if user_data_dir = "" then user_data_dir else Files.absolute user_data_dir in
            let result =
                explain_missing_browser (fun () ->
                    Protocol.Browser_type.launch_persistent_context ~timeout:o.timeout ?channel:o.channel ?executable_path:o.executable_path
                        ?args:o.args ?ignore_all_default_args:o.ignore_all_default_args ?ignore_default_args:o.ignore_default_args
                        ?handle_sigint:o.handle_sigint ?handle_sigterm:o.handle_sigterm ?handle_sighup:o.handle_sighup ?env:o.env
                        ?headless:o.headless ?proxy:o.proxy ?downloads_path:o.downloads_path ?traces_dir:o.traces_dir
                        ?artifacts_dir:o.artifacts_dir ?chromium_sandbox:o.chromium_sandbox ?firefox_user_prefs:o.firefox_user_prefs
                        ?no_default_viewport:c.no_default_viewport ?viewport:c.viewport ?screen:c.screen
                        ?ignore_https_errors:c.ignore_https_errors ?client_certificates:c.client_certificates ?java_script_enabled:c.java_script_enabled ?bypass_csp:c.bypass_csp
                        ?user_agent:c.user_agent ?locale:c.locale ?timezone_id:c.timezone_id ?geolocation:c.geolocation
                        ?permissions:c.permissions ?extra_http_headers:c.extra_http_headers ?offline:c.offline
                        ?http_credentials:c.http_credentials ?device_scale_factor:c.device_scale_factor ?is_mobile:c.is_mobile
                        ?has_touch:c.has_touch ?color_scheme:c.color_scheme ?reduced_motion:c.reduced_motion ?forced_colors:c.forced_colors
                        ?accept_downloads:c.accept_downloads ?contrast:c.contrast ?base_url:c.base_url ?record_video:c.record_video
                        ?strict_selectors:c.strict_selectors ?service_workers:c.service_workers ?selector_engines ?test_id_attribute_name
                        ~user_data_dir ?slow_mo:o.slow_mo t.bt_channel)
            in
            let browser = Types.browser result.browser in
            let context = Types.browser_context result.context in
            adopt t ?traces_dir:o.traces_dir browser;
            Browser.setup_context browser context;
            Connection.guard t.bt_session.conn "closing a browser" ~undo:(fun () -> Browser.close browser) (fun () ->
                Browser_context.start_har_recording c context);
            context))

(* Attaches to a running browser through the Chrome DevTools Protocol. *)
let connect_over_cdp ?timeout ?headers ?slow_mo ?is_local ?no_defaults ?artifacts_dir endpoint_url (t : t) =
    if t.bt_name <> "chromium" && t.bt_name <> "webkit" then Error.raise_ "Connecting over CDP is only supported in Chromium and WebKit.";
    let result =
        Protocol.Browser_type.connect_over_cdp ~timeout:(Timeouts.action ?timeout (Timeouts.create ())) ~endpoint_url
            ?headers:(Option.map Network.name_values headers) ?slow_mo ?is_local ?no_defaults ?artifacts_dir t.bt_channel
    in
    let browser = Types.browser result.browser in
    adopt t browser;
    browser
