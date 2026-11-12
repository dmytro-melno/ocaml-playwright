open Playwright_internal
module Error = Error

exception Error = Error.E

(* {1 What the interface defines}

   A type or a module type that an interface defines has to be defined by the implementation as well. Those of
   [playwright.mli] are therefore stated a second time here, without their documentation; the compiler checks that
   the two agree. The types of the objects are not among them: the interface declares each of them in its module. *)

type t = Types.playwright
type rect = Protocol.Rect.t = { x : float; y : float; width : float; height : float }
type mouse_button = [ `Left | `Middle | `Right ]
type keyboard_modifier = [ `Alt | `Control | `Control_or_meta | `Meta | `Shift ]
type lifecycle_event = [ `Load | `Domcontentloaded | `Networkidle | `Commit ]
type element_state = [ `Attached | `Detached | `Visible | `Hidden ]
type color_scheme = [ `Dark | `Light | `No_preference | `No_override ]
type reduced_motion = [ `Reduce | `No_preference | `No_override ]
type forced_colors = [ `Active | `None | `No_override ]
type contrast = [ `More | `No_preference | `No_override ]
type file_payload = Protocol.Frame.Set_input_files_payloads.t = { name : string; mime_type : string option; buffer : string }
type select_option = Frame.select_option
type web_socket_message = Types.ws_payload = Text of string | Binary of string

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

type aria_role = Locator.role

module Disposable = Disposable

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

module Geolocation = Context_options.Geolocation
module Http_credentials = Context_options.Http_credentials
module Client_certificate = Context_options.Client_certificate
module Proxy = Context_options.Proxy
module Cookie = Browser_context.Cookie

type 'a with_context_options =
    ?device:Device.t ->
    ?viewport:int * int ->
    ?no_viewport:bool ->
    ?screen:int * int ->
    ?ignore_https_errors:bool ->
    ?java_script_enabled:bool ->
    ?bypass_csp:bool ->
    ?user_agent:string ->
    ?locale:string ->
    ?timezone_id:string ->
    ?geolocation:Geolocation.t ->
    ?permissions:string list ->
    ?extra_http_headers:(string * string) list ->
    ?offline:bool ->
    ?http_credentials:Http_credentials.t list ->
    ?client_certificates:Client_certificate.t list ->
    ?device_scale_factor:float ->
    ?is_mobile:bool ->
    ?has_touch:bool ->
    ?color_scheme:color_scheme ->
    ?reduced_motion:reduced_motion ->
    ?forced_colors:forced_colors ->
    ?contrast:contrast ->
    ?accept_downloads:bool ->
    ?base_url:string ->
    ?record_video_dir:string ->
    ?record_video_size:int * int ->
    ?strict_selectors:bool ->
    ?service_workers:[ `Allow | `Block ] ->
    ?storage_state:Yojson.Safe.t ->
    'a

type 'a with_launch_options =
    ?channel:string ->
    ?executable_path:string ->
    ?args:string list ->
    ?ignore_all_default_args:bool ->
    ?ignore_default_args:string list ->
    ?handle_sigint:bool ->
    ?handle_sigterm:bool ->
    ?handle_sighup:bool ->
    ?timeout:float ->
    ?env:(string * string) list ->
    ?headless:bool ->
    ?proxy:Proxy.t ->
    ?downloads_path:string ->
    ?traces_dir:string ->
    ?artifacts_dir:string ->
    ?chromium_sandbox:bool ->
    ?firefox_user_prefs:(string * Yojson.Safe.t) list ->
    ?slow_mo:float ->
    'a
module type Identity = sig
    type t

    val equal : t -> t -> bool
    val compare : t -> t -> int
    val hash : t -> int
end

module type Locator_queries = sig
    type t
    type locator

    val get_by_role :
        ?checked:bool -> ?disabled:bool -> ?selected:bool -> ?expanded:bool -> ?include_hidden:bool -> ?level:int -> ?name:string ->
        ?name_regex:string -> ?description:string -> ?description_regex:string -> ?exact:bool -> ?pressed:bool -> aria_role -> t -> locator
    val get_by_text : ?exact:bool -> string -> t -> locator
    val get_by_text_regex : string -> t -> locator
    val get_by_label : ?exact:bool -> string -> t -> locator
    val get_by_label_regex : string -> t -> locator
    val get_by_placeholder : ?exact:bool -> string -> t -> locator
    val get_by_placeholder_regex : string -> t -> locator
    val get_by_alt_text : ?exact:bool -> string -> t -> locator
    val get_by_alt_text_regex : string -> t -> locator
    val get_by_title : ?exact:bool -> string -> t -> locator
    val get_by_title_regex : string -> t -> locator
    val get_by_test_id : string -> t -> locator
    val get_by_test_id_regex : string -> t -> locator
end

module type Frame_operations = sig
    type t
    type js_value
    type js_handle
    type element_handle
    type response

    val goto : ?timeout:float -> ?wait_until:lifecycle_event -> ?referer:string -> string -> t -> response option
    val set_content : ?timeout:float -> ?wait_until:lifecycle_event -> string -> t -> unit
    val content : ?include_shadow:bool -> t -> string
    val title : t -> string
    val wait_for_load_state : ?timeout:float -> ?state:lifecycle_event -> t -> unit
    val wait_for_url : ?timeout:float -> ?wait_until:lifecycle_event -> string -> t -> unit
    val wait_for_url_matching : ?timeout:float -> ?wait_until:lifecycle_event -> (string -> bool) -> t -> unit
    val expect_navigation :
        ?timeout:float -> ?wait_until:lifecycle_event -> ?url:string -> ?url_matching:(string -> bool) -> (unit -> unit) -> t -> response option
    val wait_for_timeout : float -> t -> unit
    val evaluate : ?arg:js_value -> string -> t -> js_value
    val evaluate_handle : ?arg:js_value -> string -> t -> js_handle
    val wait_for_function : ?timeout:float -> ?polling:float -> ?arg:js_value -> string -> t -> js_handle
    val add_script_tag : ?type_:string -> [ `Content of string | `Url of string ] -> t -> element_handle
    val add_style_tag : [ `Content of string | `Url of string ] -> t -> element_handle
    val query_selector : ?strict:bool -> string -> t -> element_handle option
    val query_selector_all : string -> t -> element_handle list
    val wait_for_selector : ?timeout:float -> ?strict:bool -> ?state:element_state -> string -> t -> element_handle option
    val eval_on_selector : ?strict:bool -> ?arg:js_value -> string -> expression:string -> t -> js_value
    val eval_on_selector_all : ?arg:js_value -> string -> expression:string -> t -> js_value
    val dispatch_event : ?timeout:float -> ?strict:bool -> ?event_init:js_value -> string -> type_:string -> t -> unit
    val click :
        ?timeout:float -> ?strict:bool -> ?force:bool -> ?scroll:[ `Auto | `None ] -> ?no_wait_after:bool -> ?modifiers:keyboard_modifier list -> ?position:float * float ->
        ?delay:float -> ?button:mouse_button -> ?click_count:int -> ?trial:bool -> ?steps:int -> string -> t -> unit
    val dblclick :
        ?timeout:float -> ?strict:bool -> ?force:bool -> ?scroll:[ `Auto | `None ] -> ?modifiers:keyboard_modifier list -> ?position:float * float -> ?delay:float ->
        ?button:mouse_button -> ?trial:bool -> ?steps:int -> string -> t -> unit
    val tap :
        ?timeout:float -> ?strict:bool -> ?force:bool -> ?scroll:[ `Auto | `None ] -> ?modifiers:keyboard_modifier list -> ?position:float * float -> ?trial:bool -> string ->
        t -> unit
    val hover :
        ?timeout:float -> ?strict:bool -> ?force:bool -> ?scroll:[ `Auto | `None ] -> ?modifiers:keyboard_modifier list -> ?position:float * float -> ?trial:bool -> string ->
        t -> unit
    val drag_and_drop :
        ?timeout:float -> ?strict:bool -> ?force:bool -> ?scroll:[ `Auto | `None ] -> ?trial:bool -> ?source_position:float * float -> ?target_position:float * float ->
        ?steps:int -> source:string -> target:string -> t -> unit
    val fill : ?timeout:float -> ?strict:bool -> ?force:bool -> string -> value:string -> t -> unit
    val focus : ?timeout:float -> ?strict:bool -> string -> t -> unit
    val blur : ?timeout:float -> ?strict:bool -> string -> t -> unit
    val press : ?timeout:float -> ?strict:bool -> ?delay:float -> ?no_wait_after:bool -> string -> key:string -> t -> unit
    val type_ : ?timeout:float -> ?strict:bool -> ?delay:float -> string -> text:string -> t -> unit
    val check : ?timeout:float -> ?strict:bool -> ?force:bool -> ?scroll:[ `Auto | `None ] -> ?position:float * float -> ?trial:bool -> string -> t -> unit
    val uncheck : ?timeout:float -> ?strict:bool -> ?force:bool -> ?scroll:[ `Auto | `None ] -> ?position:float * float -> ?trial:bool -> string -> t -> unit
    val set_checked : ?timeout:float -> ?strict:bool -> ?force:bool -> ?scroll:[ `Auto | `None ] -> ?position:float * float -> ?trial:bool -> string -> bool -> t -> unit
    val select_option : ?timeout:float -> ?strict:bool -> ?force:bool -> string -> select_option list -> t -> string list
    val set_input_files : ?timeout:float -> ?strict:bool -> string -> string list -> t -> unit
    val set_input_payloads : ?timeout:float -> ?strict:bool -> string -> file_payload list -> t -> unit
    val text_content : ?timeout:float -> ?strict:bool -> string -> t -> string option
    val inner_text : ?timeout:float -> ?strict:bool -> string -> t -> string
    val inner_html : ?timeout:float -> ?strict:bool -> string -> t -> string
    val get_attribute : ?timeout:float -> ?strict:bool -> string -> name:string -> t -> string option
    val input_value : ?timeout:float -> ?strict:bool -> string -> t -> string
    val is_checked : ?timeout:float -> ?strict:bool -> string -> t -> bool
    val is_disabled : ?timeout:float -> ?strict:bool -> string -> t -> bool
    val is_editable : ?timeout:float -> ?strict:bool -> string -> t -> bool
    val is_enabled : ?timeout:float -> ?strict:bool -> string -> t -> bool
    val is_hidden : ?strict:bool -> string -> t -> bool
    val is_visible : ?strict:bool -> string -> t -> bool
end

(* {1 Objects} *)

module Js = Js

module BrowserType = Browser_type
module Browser = Browser

module BrowserContext = struct
    include Browser_context

    type binding_source = { context : Types.browser_context; page : Types.page; frame : Types.frame }

    let binding f : Types.binding = fun source args -> f { context = source.bs_context; page = source.bs_page; frame = source.bs_frame } args
    let expose_binding name f context = Browser_context.expose_binding name (binding f) context
    let new_cdp_session = new_cdp_session_for_page
end

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
end

module Page = struct
    include Page

    let keyboard (page : t) : Keyboard.t = page
    let mouse (page : t) : Mouse.t = page
    let touchscreen (page : t) : Touchscreen.t = page
    let request (page : t) = Browser_context.request (context page)
    let expose_binding name f page = Page.expose_binding name (BrowserContext.binding f) page
end

module Locator = Locator
module FrameLocator = Frame_locator

module Expect = struct
    (* The functor that makes the assertions returns exactly what the interface asks for. *)
    module type Assertions = module type of Expect.Not

    include Expect

    let set_default_timeout timeout (t : t) = set_default_timeout timeout t.session
end

module JSHandle = Js_handle
module ElementHandle = Element_handle
module Keyboard = Page.Keyboard
module Mouse = Page.Mouse
module Touchscreen = Page.Touchscreen

module Request = struct
    include Network.Request

    type sizes = Protocol.Request_sizes.t = {
        request_body_size : int;
        request_headers_size : int;
        response_body_size : int;
        response_headers_size : int;
    }
end

module Response = struct
    include Network.Response

    type server_addr = Protocol.Remote_addr.t = { ip_address : string; port : int }

    type security_details = Protocol.Security_details.t = {
        issuer : string option;
        protocol : string option;
        subject_name : string option;
        valid_from : float option;
        valid_to : float option;
    }
end

module WebSocket = Network.Web_socket
module WebSocketRoute = Route.Web_socket
module Route = Route
module Dialog = Dialog
module ConsoleMessage = Misc.Console_message
module Download = Misc.Download
module FileChooser = Misc.File_chooser
module WebError = Misc.Web_error
module Worker = Worker
module Video = Page.Video
module WebStorage = Page.Web_storage
module Tracing = Tracing
module Clock = Browser_context.Clock
module APIResponse = Api_request.Response

module APIRequestContext = struct
    include Api_request.Context

    type multipart_value = Api_request.multipart_value

    type 'a with_request_options =
        ?timeout:float ->
        ?headers:(string * string) list ->
        ?params:(string * string) list ->
        ?data:string ->
        ?json:Yojson.Safe.t ->
        ?form:(string * string) list ->
        ?multipart:(string * multipart_value) list ->
        ?fail_on_status_code:bool ->
        ?ignore_https_errors:bool ->
        ?max_redirects:int ->
        ?max_retries:int ->
        'a

    let fetch ?method_ ?timeout ?headers ?params ?data ?json ?form ?multipart ?fail_on_status_code ?ignore_https_errors ?max_redirects
        ?max_retries url t =
        Api_request.Context.fetch ?timeout ?method_ ?headers ?params ?data ?json ?form ?multipart ?fail_on_status_code ?ignore_https_errors
            ?max_redirects ?max_retries url t
end

module CDPSession = Cdp_session

module Selectors = struct
    let register ?content_script name script (t : t) = Misc.Selectors.register ?content_script name script t.session
    let set_test_id_attribute name (t : t) = Misc.Selectors.set_test_id_attribute name t.session
end

(* {1 The driver session} *)

let version = Instance.version
let create = Instance.create
let close = Instance.close
let run = Instance.run
let chromium (t : t) = t.chromium
let firefox (t : t) = t.firefox
let webkit (t : t) = t.webkit
let devices (t : t) = t.session.devices
let device name (t : t) = List.find_opt (fun (device : Device.t) -> device.device_name = name) t.session.devices

module APIRequest = struct
    let new_context = Api_request.new_context
end

module Driver = struct
    let command = Driver.command
    let run = Driver.run_command
end

