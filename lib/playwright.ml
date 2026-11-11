open Eio.Std

module Error = Error

exception Error = Error.E

module Js = Js

type t = Types.playwright
type rect = Protocol.Rect.t = { x : float; y : float; width : float; height : float }
type lifecycle_event = [ `Load | `Domcontentloaded | `Networkidle | `Commit ]
type keyboard_modifier = [ `Alt | `Control | `Control_or_meta | `Meta | `Shift ]
type mouse_button = [ `Left | `Middle | `Right ]
type file_payload = Protocol.Frame.Set_input_files_payloads.t = { name : string; mime_type : string option; buffer : string }
type select_option = Frame.select_option

type timing = Types.timing = {
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

module Geolocation = Context_options.Geolocation
module Http_credentials = Context_options.Http_credentials
module Proxy = Context_options.Proxy
module Cookie = Browser_context.Cookie

module Device = struct
    type t = Types.device

    let name (d : t) = d.device_name
    let user_agent (d : t) = d.device_user_agent
    let viewport (d : t) = d.device_viewport.width, d.device_viewport.height
    let device_scale_factor (d : t) = d.device_scale_factor
    let is_mobile (d : t) = d.device_is_mobile
    let has_touch (d : t) = d.device_has_touch
    let default_browser_type (d : t) = d.default_browser_type
end

module JSHandle = Js_handle
module ElementHandle = Element_handle
module Request = Network.Request
module Response = Network.Response
module WebSocket = Network.Web_socket
module WebSocketRoute = Route.Web_socket
module Route = Route
module Worker = Worker
module Dialog = Dialog
module ConsoleMessage = Misc.Console_message
module Download = Misc.Download
module FileChooser = Misc.File_chooser
module WebError = Misc.Web_error
module Video = Page.Video
module Keyboard = Page.Keyboard
module Mouse = Page.Mouse
module Touchscreen = Page.Touchscreen
module Tracing = Tracing
module Clock = Browser_context.Clock
module APIResponse = Api_request.Response
module CDPSession = Cdp_session
module Locator = Locator
module FrameLocator = Frame_locator

module Frame = struct
    include Frame

    include Locator.Queries (struct
        type t = Types.frame

        let session (frame : t) = frame.f_session
        let find (frame : t) selector = Locator.make frame selector
    end)

    let locator ?has_text ?has_text_regex ?has_not_text ?has_not_text_regex ?has ?has_not selector (frame : t) =
        Locator.make ?has_text ?has_text_regex ?has_not_text ?has_not_text_regex ?has ?has_not frame selector

    let frame_locator selector (frame : t) : Types.frame_locator = { fl_frame = frame; frame_selector = selector }
    let set_input_payloads ?timeout ?strict selector payloads frame = set_input ?timeout ?strict selector (Payloads payloads) frame
end

module Page = struct
    include Page

    let keyboard (page : t) : Keyboard.t = page
    let mouse (page : t) : Mouse.t = page
    let touchscreen (page : t) : Touchscreen.t = page
    let set_input_payloads ?timeout ?strict selector payloads page = set_input ?timeout ?strict selector (Frame.Payloads payloads) page
end

module BrowserContext = Browser_context
module Browser = Browser
module BrowserType = Browser_type
module Expect = Expect

module APIRequestContext = struct
    include Api_request.Context

    type nonrec file_payload = Api_request.file_payload = { name : string; mime_type : string; buffer : string }
end

module Selectors = struct
    let register ?content_script ?path ?script name (t : t) = Misc.Selectors.register ?content_script ?path ?script name t.session
    let set_test_id_attribute name (t : t) = Misc.Selectors.set_test_id_attribute name t.session
end

(* {1 The driver session} *)

let version = Protocol.playwright_version

let report_to_stderr what ex backtrace =
    Printf.eprintf "Playwright: uncaught exception in %s: %s\n%s%!" what (Printexc.to_string ex) (Printexc.raw_backtrace_to_string backtrace)

(* Protocol tracing, enabled the way it is in every Playwright client: DEBUG=pw:channel. *)
let wire_trace () =
    let enabled =
        match Sys.getenv_opt "DEBUG" with
        | None -> false
        | Some value -> List.exists (fun name -> name = "pw:channel" || name = "pw:*" || name = "*") (String.split_on_char ',' value)
    in
    if not enabled then None
    else
        Some
            (fun line ->
                let limit = 4096 in
                let line = if String.length line > limit then String.sub line 0 limit ^ Printf.sprintf "... (%d bytes)" (String.length line) else line in
                prerr_endline ("pw:channel " ^ line))

let initialize_timeout = 60_000.

let create ?(on_error = fun what ex -> report_to_stderr what ex (Printexc.get_raw_backtrace ())) ~sw ~(env : Eio_unix.Stdenv.base) () : t =
    let driver = Driver.locate () in
    let process = Driver_process.spawn ~sw ~env driver in
    let conn =
        Connection.create ~sw ~clock:(Eio.Stdenv.clock env)
            ~report:(fun what ex _ -> on_error what ex)
            ?trace:(wire_trace ())
            ~render_value:(fun value -> Js.show (Js.of_wire value))
            process.transport
    in
    let session = Objects.new_session conn in
    Fiber.fork_daemon ~sw (fun () ->
        Connection.run conn;
        `Stop_daemon);
    let stopped = ref false in
    let stop () =
        if not !stopped then begin
            stopped := true;
            Connection.close conn (Error.target_closed ~message:"Playwright has been closed" ());
            Promise.await (Connection.stopped conn);
            process.stop ()
        end
    in
    Switch.on_release sw stop;
    match
        let channel =
            Connection.with_timeout conn ~timeout:initialize_timeout
                ~message:(fun () -> "Timed out waiting for the Playwright driver to start")
                (fun () -> Protocol.Root.initialize ~sdk_language:`Python (Connection.root conn))
        in
        let init = Protocol.Playwright.Initializer.of_json conn channel.initializer_ in
        { Types.session; pw_channel = channel; chromium = Types.browser_type init.chromium; firefox = Types.browser_type init.firefox;
          webkit = Types.browser_type init.webkit; stop }
    with
    | playwright -> playwright
    | exception ex ->
        let backtrace = Printexc.get_raw_backtrace () in
        stop ();
        Printexc.raise_with_backtrace ex backtrace

let close (t : t) = t.stop ()

let run ?on_error ~env f =
    Switch.run (fun sw ->
        let t = create ?on_error ~sw ~env () in
        Fun.protect ~finally:(fun () -> close t) (fun () -> f t))

let chromium (t : t) = t.chromium
let firefox (t : t) = t.firefox
let webkit (t : t) = t.webkit
let devices (t : t) = t.session.devices
let device name (t : t) = List.find_opt (fun (device : Device.t) -> device.device_name = name) t.session.devices

module APIRequest = struct
    (* Creates a request context that is independent of any browser. *)
    let new_context ?base_url ?user_agent ?ignore_https_errors ?extra_http_headers ?fail_on_status_code ?max_redirects
        ?(http_credentials : Http_credentials.t option) ?(proxy : Proxy.t option) ?(storage_state : Yojson.Safe.t option) ?timeout (t : t) =
        let conn = t.session.conn in
        let context =
            Protocol.Playwright.new_request ?base_url ?user_agent ?ignore_https_errors
                ?extra_http_headers:(Option.map Network.name_values extra_http_headers) ?fail_on_status_code ?max_redirects
                ?http_credentials:
                    (Option.map
                         (fun (c : Http_credentials.t) : Protocol.Http_credentials.t list ->
                             [ { username = c.username; password = c.password; origin = c.origin; send = None } ])
                         http_credentials)
                ?proxy:
                    (Option.map
                         (fun (p : Proxy.t) : Protocol.Playwright.New_request_proxy.t ->
                             { server = p.server; bypass = p.bypass; username = p.username; password = p.password })
                         proxy)
                ?storage_state:(Option.map (Protocol.Playwright.New_request_storage_state.of_json conn) storage_state)
                t.pw_channel
            |> Types.api_request_context
        in
        Option.iter (fun timeout -> context.a_timeouts.default <- Some timeout) timeout;
        context
end
