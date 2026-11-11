(** Browser automation with {{:https://playwright.dev} Playwright}.

    This library drives Chromium, Firefox and WebKit through the Playwright driver, which it talks to over
    Playwright's own client protocol. It follows the official Playwright API closely; the
    {{:https://playwright.dev/docs/api/class-playwright} upstream documentation} applies almost verbatim once
    the conventions below are taken into account.

    {[
      let () =
          Eio_main.run @@ fun env ->
          Playwright.run ~env @@ fun pw ->
          let browser = Playwright.(BrowserType.launch (chromium pw)) in
          let page = Playwright.Browser.new_page browser in
          ignore (Playwright.Page.goto "https://ocaml.org" page);
          Playwright.Page.get_by_role `Link ~name:"Install" page |> Playwright.Locator.click;
          print_endline (Playwright.Page.title page)
    ]}

    {1 Conventions}

    - Every Playwright class is a module with the same name ([Page], [BrowserContext], [Locator], ...) and methods
      are functions in [snake_case]. A name that is an OCaml keyword gets a trailing underscore ([type_],
      [method_]).
    - The object a function operates on comes {e last}, so calls compose with [|>]. Required arguments are
      positional and precede it; everything optional is an optional labelled argument.
    - All functions block the calling fiber until the browser has answered. Run them in separate
      {{:https://github.com/ocaml-multicore/eio} Eio} fibers to work with several pages concurrently. Cancelling a
      fiber cancels the call it is blocked in.
    - Timeouts and other durations are in milliseconds, as in Playwright. A timeout of [0.] disables the timeout.
    - Failures are reported with the exception {!Error}; [Invalid_argument] is reserved for misuse of the API
      that no browser needs to be asked about.
    - JavaScript regular expressions are given as literals in a string, such as ["/sign (in|up)/i"], to the
      functions and arguments named [..._regex].
    - URL patterns are {{:https://playwright.dev/docs/network#glob-url-patterns} glob patterns}; functions named
      [..._matching] take an OCaml predicate on the URL instead.
    - Events are values of a GADT, which gives every event its payload type:
      [Page.on Page.Console (fun message -> ...) page].
    - Pages, frames, requests and the other objects have identity: the library always returns the same OCaml value
      for the same object in the browser. Compare them with physical equality, [==]; the polymorphic [=] and
      [compare] must not be used on them. *)

(** {1 Errors} *)

module Error : sig
    type kind =
        | Timeout  (** An operation did not complete within its timeout. *)
        | Target_closed  (** The page, context or browser was closed, or the driver went away, during the operation. *)
        | Assertion_failed  (** An {!Expect} assertion did not hold. *)
        | Other

    type t = {
        kind : kind;
        name : string;  (** The name of the error as Playwright reports it, e.g. ["TimeoutError"] or ["Error"]. *)
        message : string;  (** What went wrong, followed by the call log if there is one. *)
        stack : string option;  (** The stack trace of the driver or of the page, when there is one. *)
        log : string list;  (** What the driver did during the failed call; the "call log" of Playwright. *)
        details : Yojson.Safe.t;  (** Structured details that the driver attached to the error, or [`Null]. *)
    }

    val to_string : t -> string
    (** The message, preceded by the name of the error unless that is just ["Error"]. *)

    val pp : Format.formatter -> t -> unit
end

exception Error of Error.t
(** Raised by every function of this library that fails. A printer is registered with [Printexc]. *)

(** {1 Objects}

    The types of the Playwright objects. Each of them is used through the module of the same name, for example
    {!Page} for [page], which also provides it as [Page.t]. *)

type browser_type
type browser
type browser_context
type page
type frame
type locator
type frame_locator
type js_handle
type element_handle
type keyboard
type mouse
type touchscreen
type request
type response
type route
type web_socket
type web_socket_route
type worker
type dialog
type console_message
type download
type file_chooser
type web_error
type video
type web_storage
type tracing
type api_request_context
type api_response
type cdp_session

(** {1 Values} *)

type rect = { x : float; y : float; width : float; height : float }
(** A rectangle in CSS pixels. *)

type mouse_button = [ `Left | `Middle | `Right ]
type keyboard_modifier = [ `Alt | `Control | `Control_or_meta | `Meta | `Shift ]

type lifecycle_event = [ `Load | `Domcontentloaded | `Networkidle | `Commit ]
(** How far a navigation has to get before it counts as finished. The default is [`Load]. *)

type element_state = [ `Attached | `Detached | `Visible | `Hidden ]
type color_scheme = [ `Dark | `Light | `No_preference | `No_override ]
type reduced_motion = [ `Reduce | `No_preference | `No_override ]
type forced_colors = [ `Active | `None | `No_override ]
type contrast = [ `More | `No_preference | `No_override ]

type file_payload = { name : string; mime_type : string option; buffer : string }
(** A file that exists only in memory, for uploads. [buffer] holds its content. *)

type select_option = [ `Value of string | `Label of string | `Index of int | `Value_or_label of string ]
(** Identifies an [<option>] of a [<select>]. *)

type web_socket_message = Text of string | Binary of string

type timing = {
    start_time : float;  (** Milliseconds since the Unix epoch. The other fields are relative to it; [-1.] when unavailable. *)
    domain_lookup_start : float;
    domain_lookup_end : float;
    connect_start : float;
    secure_connection_start : float;
    connect_end : float;
    request_start : float;
    response_start : float;
    response_end : float;
}

type binding_source = { context : browser_context; page : page; frame : frame }
(** Where a call of an exposed binding came from. *)

type aria_role =
    [ `Alert | `Alertdialog | `Application | `Article | `Banner | `Blockquote | `Button | `Caption | `Cell | `Checkbox | `Code
    | `Columnheader | `Combobox | `Complementary | `Contentinfo | `Definition | `Deletion | `Dialog | `Directory | `Document
    | `Emphasis | `Feed | `Figure | `Form | `Generic | `Grid | `Gridcell | `Group | `Heading | `Img | `Insertion | `Link | `List
    | `Listbox | `Listitem | `Log | `Main | `Marquee | `Math | `Menu | `Menubar | `Menuitem | `Menuitemcheckbox
    | `Menuitemradio | `Meter | `Navigation | `None | `Note | `Option | `Paragraph | `Presentation | `Progressbar | `Radio
    | `Radiogroup | `Region | `Row | `Rowgroup | `Rowheader | `Scrollbar | `Search | `Searchbox | `Separator | `Slider
    | `Spinbutton | `Status | `Strong | `Subscript | `Superscript | `Switch | `Tab | `Table | `Tablist | `Tabpanel | `Term
    | `Textbox | `Time | `Timer | `Toolbar | `Tooltip | `Tree | `Treegrid | `Treeitem ]

(** JavaScript values, as they are passed to and returned from code evaluated in a page.

    Unlike JSON this covers everything that Playwright can transfer: [undefined], [NaN] and the infinities, dates,
    big integers, regular expressions, errors, typed arrays and, in arguments, handles to objects living in the page. *)
module Js : sig
    type typed_array_kind = [ `I8 | `Ui8 | `Ui8c | `I16 | `Ui16 | `I32 | `Ui32 | `F32 | `F64 | `Bi64 | `Bui64 ]

    type t =
        | Undefined
        | Null
        | Bool of bool
        | Number of float
        | String of string
        | Bigint of string  (** In decimal notation. *)
        | Date of string  (** In ISO 8601 format, as produced by [Date.prototype.toJSON]. *)
        | Url of string
        | Regexp of { source : string; flags : string }
        | Error of { name : string; message : string; stack : string }
        | Array of t list
        | Object of (string * t) list
        | Typed_array of { kind : typed_array_kind; bytes : string }  (** [bytes] is the content of the underlying buffer. *)
        | Handle of js_handle  (** Only in arguments: the object that the handle refers to. *)

    (** {2 Constructing} *)

    val undefined : t
    val null : t
    val bool : bool -> t
    val int : int -> t
    val float : float -> t
    val string : string -> t
    val list : ('a -> t) -> 'a list -> t
    val obj : (string * t) list -> t

    val option : ('a -> t) -> 'a option -> t
    (** [None] becomes [Null]. *)

    val of_json : Yojson.Safe.t -> t

    (** {2 Inspecting}

        The [to_...] functions raise {!Playwright.Error} when the value is of another kind. *)

    val to_string : t -> string
    val to_bool : t -> bool
    val to_float : t -> float

    val to_int : t -> int
    (** Fails for numbers that are not integers. *)

    val to_list : (t -> 'a) -> t -> 'a list
    val to_assoc : t -> (string * t) list

    val to_option : (t -> 'a) -> t -> 'a option
    (** [None] for [Null] and [Undefined]. *)

    val is_nullish : t -> bool

    val member : string -> t -> t
    (** The property of an [Object]; [Undefined] when it has no such property. *)

    val to_json : t -> Yojson.Safe.t
    (** Converts the way [JSON.stringify] does where it can: [Undefined] and non-finite numbers become [`Null],
        dates and URLs become strings. Integral numbers become [`Int]. Fails for handles. *)

    val show : t -> string
    (** A JavaScript-like rendering, for messages and debugging. *)

    val pp : Format.formatter -> t -> unit
end

(** {1 Options} *)

(** A device descriptor from Playwright's device registry, see {!devices}. *)
module Device : sig
    type t

    val name : t -> string
    val user_agent : t -> string
    val viewport : t -> int * int
    val device_scale_factor : t -> float
    val is_mobile : t -> bool
    val has_touch : t -> bool

    val default_browser_type : t -> [ `Chromium | `Firefox | `Webkit ]
    (** The browser that the device normally runs. *)
end

module Geolocation : sig
    type t = { latitude : float; longitude : float; accuracy : float option }

    val make : ?accuracy:float -> latitude:float -> longitude:float -> unit -> t
end

module Http_credentials : sig
    type t = { username : string; password : string; origin : string option }

    val make : ?origin:string -> username:string -> password:string -> unit -> t
    (** [origin] restricts the credentials to one origin, e.g. ["https://example.com:8443"]. *)
end

module Proxy : sig
    type t = { server : string; bypass : string option; username : string option; password : string option }

    val make : ?bypass:string -> ?username:string -> ?password:string -> string -> t
    (** [make server] with a server such as ["http://proxy.example:3128"] or ["socks5://127.0.0.1:1080"]. [bypass] is
        a comma-separated list of domains to reach directly. *)
end

module Cookie : sig
    type same_site = [ `Strict | `Lax | `None ]

    type t = {
        name : string;
        value : string;
        domain : string;
        path : string;
        expires : float;  (** Seconds since the Unix epoch; [-1.] for a session cookie. *)
        http_only : bool;
        secure : bool;
        same_site : same_site;
        partition_key : string option;
    }

    type init
    (** A cookie to set, see {!BrowserContext.add_cookies}. *)

    val make :
        ?url:string -> ?domain:string -> ?path:string -> ?expires:float -> ?http_only:bool -> ?secure:bool -> ?same_site:same_site ->
        ?partition_key:string -> string -> string -> init
    (** [make name value]. Either [url], or both [domain] and [path] are required. *)

    val to_init : t -> init
end

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
    ?http_credentials:Http_credentials.t ->
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
    ?record_har_path:string ->
    ?record_har_content:[ `Attach | `Embed | `Omit ] ->
    ?record_har_mode:[ `Full | `Minimal ] ->
    ?record_har_url_filter:string ->
    ?strict_selectors:bool ->
    ?service_workers:[ `Allow | `Block ] ->
    ?storage_state:Yojson.Safe.t ->
    ?storage_state_path:string ->
    'a
(** The options of a browser context, see
    {{:https://playwright.dev/docs/api/class-browser#browser-new-context} [browser.newContext]}.

    - [device] emulates a device, see {!val-device}; the options given explicitly take precedence over it.
    - [viewport] is [(width, height)], 1280×720 by default; [no_viewport] makes the page follow the window size.
    - [base_url] is what relative URLs given to {!Page.goto}, {!Page.route} and the like are resolved against.
    - [record_video_dir] turns video recording on, see {!Video}; [record_har_path] records network activity into a
      HAR file, which is written when the context is closed.
    - [storage_state] restores cookies and local storage saved with {!BrowserContext.storage_state};
      [storage_state_path] reads it from a file. *)

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
    ?chromium_sandbox:bool ->
    ?firefox_user_prefs:(string * Yojson.Safe.t) list ->
    ?slow_mo:float ->
    'a
(** The options for starting a browser, see
    {{:https://playwright.dev/docs/api/class-browsertype#browser-type-launch} [browserType.launch]}.

    - [headless] defaults to [true].
    - [executable_path] runs a browser that Playwright did not install; [channel] selects a branded one such as
      ["chrome"] or ["msedge"].
    - [timeout] is the time the browser has to start, 180 seconds by default.
    - [slow_mo] delays every operation by that many milliseconds. *)

type 'a with_screenshot_options =
    ?timeout:float ->
    ?path:string ->
    ?type_:[ `Png | `Jpeg | `Webp ] ->
    ?quality:int ->
    ?omit_background:bool ->
    ?caret:[ `Hide | `Initial ] ->
    ?animations:[ `Allow | `Disabled ] ->
    ?scale:[ `Css | `Device ] ->
    ?mask:locator list ->
    ?mask_color:string ->
    ?style:string ->
    'a
(** The options for taking a screenshot. [path] also saves the image to a file, and determines [type_] from the
    extension unless that is given. [quality] is 0-100 and applies to JPEG and WebP only. *)

(** {1 Playwright} *)

type t
(** A running Playwright driver and everything that was created through it. *)

val create : ?on_error:(string -> exn -> unit) -> sw:Eio.Switch.t -> env:Eio_unix.Stdenv.base -> unit -> t
(** Starts the Playwright driver. It is stopped, and all its browsers are closed, by {!close} or when [sw] finishes.

    The driver is the [playwright-core] package for Node.js in the version this library was built for, {!version}.
    It is downloaded from the npm registry on first use and cached in the user's cache directory; [node] has to be
    installed. Both can be overridden with environment variables, see the user guide. Browsers are installed with
    [ocaml-playwright install], or an installed one is used through [executable_path] or [channel].

    [on_error what exn] is called for exceptions that have no caller to be raised in, namely those escaping from
    event listeners and route handlers. The default prints them to standard error.

    Setting the environment variable [DEBUG=pw:channel] logs the protocol messages to standard error. *)

val close : t -> unit
(** Closes all browsers and stops the driver. Calls that are still running fail with a [Target_closed] error. Does
    nothing when already closed. *)

val run : ?on_error:(string -> exn -> unit) -> env:Eio_unix.Stdenv.base -> (t -> 'a) -> 'a
(** [run ~env f] calls [f] with a new driver, which it stops once [f] returns or raises. *)

val chromium : t -> browser_type
val firefox : t -> browser_type
val webkit : t -> browser_type

val devices : t -> Device.t list

val device : string -> t -> Device.t option
(** The descriptor of a device by its name, e.g. ["iPhone 15"] or ["Pixel 7"]. *)

val version : string
(** The version of Playwright that this library drives, e.g. ["1.65.0"]. *)

(** Playwright's command line tool, which installs browsers, shows traces and more. The [ocaml-playwright]
    program that comes with this library gives access to it from a shell. *)
module Driver : sig
    val command : string list -> string list
    (** [command args] is the command line that runs Playwright's own command line tool with [args]: the path of
        a program followed by its arguments. [command ["install"; "chromium"]] is the one that installs a
        browser, for example, and [command ["show-trace"; "trace.zip"]] the one that opens a trace.

        The driver is installed first if it is not there yet, which blocks until it has been downloaded. *)

    val run : string list -> int
    (** Runs {!command} to its end, with the standard input and output of this process, and returns its exit
        status. Nothing else runs meanwhile; a program that has other fibers to run calls it through
        [Eio_unix.run_in_systhread]. *)
end

(** {1 Shared signatures} *)

(** Finding elements the way users and assistive technology perceive them. These functions are provided by {!Page},
    {!Frame}, {!Locator} and {!FrameLocator}; see {{:https://playwright.dev/docs/locators} Locators}.

    The [..._regex] variants take a JavaScript regular expression literal such as ["/^total: \\d+$/i"]. *)
module type Locator_queries = sig
    type t

    val get_by_role :
        ?checked:bool -> ?disabled:bool -> ?selected:bool -> ?expanded:bool -> ?include_hidden:bool -> ?level:int -> ?name:string ->
        ?name_regex:string -> ?description:string -> ?description_regex:string -> ?exact:bool -> ?pressed:bool -> aria_role -> t -> locator
    (** Elements by their ARIA role, optionally narrowed down by their accessible [name] or [description] and by ARIA
        states. [exact] makes [name] and [description] match in full and case-sensitively instead of as a
        case-insensitive substring. *)

    val get_by_text : ?exact:bool -> string -> t -> locator
    (** Elements containing the text; with [exact], elements whose text is exactly that. *)

    val get_by_text_regex : string -> t -> locator

    val get_by_label : ?exact:bool -> string -> t -> locator
    (** Form controls by the text of their label. *)

    val get_by_label_regex : string -> t -> locator
    val get_by_placeholder : ?exact:bool -> string -> t -> locator
    val get_by_placeholder_regex : string -> t -> locator
    val get_by_alt_text : ?exact:bool -> string -> t -> locator
    val get_by_alt_text_regex : string -> t -> locator
    val get_by_title : ?exact:bool -> string -> t -> locator
    val get_by_title_regex : string -> t -> locator

    val get_by_test_id : string -> t -> locator
    (** Elements by their [data-testid] attribute, or the one set with {!Selectors.set_test_id_attribute}. *)

    val get_by_test_id_regex : string -> t -> locator
end

(** What {!Page} and {!Frame} have in common; the functions of a page operate on its main frame.

    The functions that take a selector are the older way of interacting with a page. They are kept for completeness;
    prefer {!Locator}s, which offer the same operations and can be reused, narrowed down and asserted on. With
    [strict], a selector that matches several elements is an error rather than a reference to the first of them. *)
module type Frame_operations = sig
    type t

    (** {2 Navigation} *)

    val goto : ?timeout:float -> ?wait_until:lifecycle_event -> ?referer:string -> string -> t -> response option
    (** Navigates to the URL and waits for the navigation to get as far as [wait_until]. Returns the response of the
        main resource, the last one in case of redirects, or [None] for navigations that have none such as to
        [about:blank] or to a different anchor of the same document. HTTP error statuses are not failures. *)

    val set_content : ?timeout:float -> ?wait_until:lifecycle_event -> string -> t -> unit
    (** Replaces the document with the given HTML. *)

    val content : t -> string
    (** The HTML of the document, including the doctype. *)

    val title : t -> string
    val wait_for_load_state : ?timeout:float -> ?state:lifecycle_event -> t -> unit

    val wait_for_url : ?timeout:float -> ?wait_until:lifecycle_event -> string -> t -> unit
    (** Waits until the frame has navigated to a URL matching the glob pattern. Returns at once if it is there already. *)

    val wait_for_url_matching : ?timeout:float -> ?wait_until:lifecycle_event -> (string -> bool) -> t -> unit

    val expect_navigation :
        ?timeout:float -> ?wait_until:lifecycle_event -> ?url:string -> ?url_matching:(string -> bool) -> (unit -> unit) -> t -> response option
    (** Runs the action and waits for the navigation that it causes. *)

    val wait_for_timeout : float -> t -> unit
    (** Sleeps. Meant for debugging: waiting for a fixed time makes automation slow and flaky. *)

    (** {2 Evaluating JavaScript} *)

    val evaluate : ?arg:Js.t -> string -> t -> Js.t
    (** [evaluate expression] evaluates a JavaScript expression in the frame and returns its value; a promise is
        awaited first. If the expression evaluates to a function, that function is called with [arg].

        {[
          Page.evaluate "document.title" page |> Js.to_string;
          Page.evaluate "([a, b]) => a + b" ~arg:(Js.list Js.int [ 1; 2 ]) page |> Js.to_int
        ]} *)

    val evaluate_handle : ?arg:Js.t -> string -> t -> js_handle
    (** Like {!evaluate}, but returns a handle to the resulting object instead of a copy of it. *)

    val wait_for_function : ?timeout:float -> ?polling:float -> ?arg:Js.t -> string -> t -> js_handle
    (** Waits until the expression evaluates to a truthy value, and returns that. It is evaluated on every animation
        frame, or every [polling] milliseconds. *)

    val add_script_tag : ?url:string -> ?path:string -> ?content:string -> ?type_:string -> t -> element_handle
    val add_style_tag : ?url:string -> ?path:string -> ?content:string -> t -> element_handle

    (** {2 Operations by selector} *)

    val query_selector : ?strict:bool -> string -> t -> element_handle option
    val query_selector_all : string -> t -> element_handle list

    val wait_for_selector : ?timeout:float -> ?strict:bool -> ?state:element_state -> string -> t -> element_handle option
    (** Waits for an element to reach [state], [`Visible] by default. [None] when waiting for [`Hidden] or [`Detached]. *)

    val eval_on_selector : ?strict:bool -> ?arg:Js.t -> string -> string -> t -> Js.t
    (** [eval_on_selector selector expression] calls the function that [expression] evaluates to with the element. *)

    val eval_on_selector_all : ?arg:Js.t -> string -> string -> t -> Js.t
    val dispatch_event : ?timeout:float -> ?strict:bool -> ?event_init:Js.t -> string -> string -> t -> unit

    val click :
        ?timeout:float -> ?strict:bool -> ?force:bool -> ?no_wait_after:bool -> ?modifiers:keyboard_modifier list -> ?position:float * float ->
        ?delay:float -> ?button:mouse_button -> ?click_count:int -> ?trial:bool -> ?steps:int -> string -> t -> unit

    val dblclick :
        ?timeout:float -> ?strict:bool -> ?force:bool -> ?modifiers:keyboard_modifier list -> ?position:float * float -> ?delay:float ->
        ?button:mouse_button -> ?trial:bool -> ?steps:int -> string -> t -> unit

    val tap :
        ?timeout:float -> ?strict:bool -> ?force:bool -> ?modifiers:keyboard_modifier list -> ?position:float * float -> ?trial:bool -> string ->
        t -> unit

    val hover :
        ?timeout:float -> ?strict:bool -> ?force:bool -> ?modifiers:keyboard_modifier list -> ?position:float * float -> ?trial:bool -> string ->
        t -> unit

    val drag_and_drop :
        ?timeout:float -> ?strict:bool -> ?force:bool -> ?trial:bool -> ?source_position:float * float -> ?target_position:float * float ->
        ?steps:int -> source:string -> target:string -> t -> unit

    val fill : ?timeout:float -> ?strict:bool -> ?force:bool -> string -> string -> t -> unit
    (** [fill selector value]. *)

    val focus : ?timeout:float -> ?strict:bool -> string -> t -> unit
    val blur : ?timeout:float -> ?strict:bool -> string -> t -> unit

    val press : ?timeout:float -> ?strict:bool -> ?delay:float -> ?no_wait_after:bool -> string -> string -> t -> unit
    (** [press selector key]. *)

    val type_ : ?timeout:float -> ?strict:bool -> ?delay:float -> string -> string -> t -> unit
    (** [type_ selector text]. *)

    val check : ?timeout:float -> ?strict:bool -> ?force:bool -> ?position:float * float -> ?trial:bool -> string -> t -> unit
    val uncheck : ?timeout:float -> ?strict:bool -> ?force:bool -> ?position:float * float -> ?trial:bool -> string -> t -> unit
    val set_checked : ?timeout:float -> ?strict:bool -> ?force:bool -> ?position:float * float -> ?trial:bool -> string -> bool -> t -> unit
    val select_option : ?timeout:float -> ?strict:bool -> ?force:bool -> string -> select_option list -> t -> string list
    val set_input_files : ?timeout:float -> ?strict:bool -> string -> string list -> t -> unit
    val set_input_payloads : ?timeout:float -> ?strict:bool -> string -> file_payload list -> t -> unit
    val text_content : ?timeout:float -> ?strict:bool -> string -> t -> string option
    val inner_text : ?timeout:float -> ?strict:bool -> string -> t -> string
    val inner_html : ?timeout:float -> ?strict:bool -> string -> t -> string

    val get_attribute : ?timeout:float -> ?strict:bool -> string -> string -> t -> string option
    (** [get_attribute selector name]. *)

    val input_value : ?timeout:float -> ?strict:bool -> string -> t -> string
    val is_checked : ?timeout:float -> ?strict:bool -> string -> t -> bool
    val is_disabled : ?timeout:float -> ?strict:bool -> string -> t -> bool
    val is_editable : ?timeout:float -> ?strict:bool -> string -> t -> bool
    val is_enabled : ?timeout:float -> ?strict:bool -> string -> t -> bool
    val is_hidden : ?strict:bool -> string -> t -> bool
    val is_visible : ?strict:bool -> string -> t -> bool
end

(** {1 Browsers} *)

(** A kind of browser: Chromium, Firefox or WebKit. Obtained from {!chromium}, {!firefox} and {!webkit}. *)
module BrowserType : sig
    type t = browser_type

    val name : t -> string
    (** ["chromium"], ["firefox"] or ["webkit"]. *)

    val executable_path : t -> string
    (** Where Playwright expects to find the browser that it installs. *)

    val launch : (t -> browser) with_launch_options
    (** Starts a browser.

        {[
          let browser = BrowserType.launch ~headless:false ~args:[ "--start-maximized" ] (Playwright.chromium pw)
        ]} *)

    val launch_persistent_context : (string -> (t -> browser_context) with_context_options) with_launch_options
    (** [launch_persistent_context user_data_dir] starts a browser that keeps its profile in the given directory, and
        returns its only context. An empty string stands for a temporary directory. Closing the context closes the
        browser. *)

    val connect : ?timeout:float -> ?headers:(string * string) list -> ?slow_mo:float -> ?expose_network:string -> string -> t -> browser
    (** [connect ws_endpoint] attaches to a browser that is served by a Playwright server, as started with
        [ocaml-playwright run-server] or [browserType.launchServer]. The server must run the same version of
        Playwright. Closing the browser, or stopping this driver, disconnects from it. *)

    val connect_over_cdp : ?timeout:float -> ?headers:(string * string) list -> ?slow_mo:float -> string -> t -> browser
    (** [connect_over_cdp endpoint] attaches to a running Chromium-based browser through the Chrome DevTools Protocol,
        given an HTTP endpoint such as ["http://localhost:9222"] or a WebSocket URL. The contexts and pages that are
        open already are available from {!Browser.contexts}. *)
end

(** A running browser. *)
module Browser : sig
    type t = browser

    val new_context : ?proxy:Proxy.t -> (t -> browser_context) with_context_options
    (** Creates an isolated browser context, comparable to a fresh incognito profile. *)

    val new_page : ?proxy:Proxy.t -> (t -> page) with_context_options
    (** Creates a page in a new context of its own, which is closed together with the page. *)

    val contexts : t -> browser_context list
    val browser_type : t -> browser_type

    val version : t -> string
    (** The version of the browser. *)

    val name : t -> string
    val is_connected : t -> bool

    val on_disconnected : (t -> unit) -> t -> unit
    (** Registers a function to call when the browser has been closed, has crashed or the connection to it was lost. *)

    val off_disconnected : (t -> unit) -> t -> unit

    val new_browser_cdp_session : t -> cdp_session
    (** A Chrome DevTools Protocol session with the browser itself. Chromium only. *)

    val close : ?reason:string -> t -> unit
    (** Closes the browser with all its contexts and pages; for a browser that was connected to, disconnects from it.
        [reason] is reported by the operations that this interrupts. Does nothing if the browser is gone already. *)
end

(** An isolated browser session: pages of the same context share cookies, storage, permissions and settings, and
    those of different contexts do not. *)
module BrowserContext : sig
    type t = browser_context

    val new_page : t -> page
    val pages : t -> page list

    val browser : t -> browser option
    (** [None] for a persistent context. *)

    val close : ?reason:string -> t -> unit
    (** Closes the context and its pages. This is also when recorded videos and HAR files are written. Does nothing if
        the context is closed already. *)

    val is_closed : t -> bool
    val set_default_timeout : float -> t -> unit

    val set_default_navigation_timeout : float -> t -> unit
    (** Takes precedence over {!set_default_timeout} for navigations. *)

    (** {1 Events} *)

    type _ event =
        | Close : t event
        | Console : console_message event
        | Dialog : dialog event
        | Page : page event  (** A page was created in the context, by {!new_page} or as a popup. *)
        | Web_error : web_error event  (** An exception was not handled in one of the pages. *)
        | Request : request event
        | Request_failed : request event
        | Request_finished : request event
        | Response : response event
        | Service_worker : worker event

    val on : 'a event -> ('a -> unit) -> t -> unit
    (** Registers a listener. Each call of a listener runs in a fiber of its own, so a listener may block and may
        call back into Playwright; events are nevertheless delivered to it in order of arrival when it does not. *)

    val once : 'a event -> ('a -> unit) -> t -> unit

    val off : 'a event -> ('a -> unit) -> t -> unit
    (** Removes a listener, which has to be physically the same function that was registered. *)

    val expect_event : ?timeout:float -> ?predicate:('a -> bool) -> 'a event -> (unit -> unit) -> t -> 'a
    (** [expect_event event action] starts listening, runs [action], and returns the first [event] satisfying
        [predicate] that occurs from then on. Unlike calling {!wait_for_event} after the action, this cannot miss an
        event that is emitted before the action returns. *)

    val wait_for_event : ?timeout:float -> ?predicate:('a -> bool) -> 'a event -> t -> 'a
    val expect_page : ?timeout:float -> ?predicate:(page -> bool) -> (unit -> unit) -> t -> page

    (** {1 Network} *)

    val route : ?times:int -> string -> (route -> unit) -> t -> unit
    (** [route glob handler] intercepts the requests of all pages of the context whose URL matches the glob pattern.
        The handler has to {!Route.fulfill}, {!Route.continue}, {!Route.fallback} or {!Route.abort} each of them.
        Handlers registered later take precedence, and those of a page take precedence over those of its context.
        With [times], the handler is used for that many requests only. *)

    val route_matching : ?times:int -> (string -> bool) -> (route -> unit) -> t -> unit

    val unroute : string -> t -> unit
    (** Removes the handlers that were registered for this glob pattern. *)

    val unroute_all : t -> unit

    val route_from_har :
        ?url:string ->
        ?not_found:[ `Abort | `Fallback ] ->
        ?update:bool ->
        ?update_content:[ `Attach | `Embed | `Omit ] ->
        ?update_mode:[ `Full | `Minimal ] ->
        string ->
        t ->
        unit
    (** [route_from_har file] answers the requests of the context from the HAR file, which is one recorded with the
        [record_har_path] option of a context or with [~update:true]; see
        {{:https://playwright.dev/docs/mock#mocking-with-har-files} Mocking with HAR files}. [url] restricts this to
        the requests matching a glob pattern. A request that the file has no answer for is aborted, or with
        [~not_found:`Fallback] goes to the other handlers and to the network.

        With [~update:true] nothing is intercepted: instead the traffic is recorded, and written to the file when
        the context is closed. *)

    val route_web_socket : string -> (web_socket_route -> unit) -> t -> unit
    (** Intercepts the WebSocket connections that pages open to matching URLs, see {!WebSocketRoute}. *)

    val route_web_socket_matching : (string -> bool) -> (web_socket_route -> unit) -> t -> unit
    val set_extra_http_headers : (string * string) list -> t -> unit
    val set_offline : bool -> t -> unit

    val request : t -> api_request_context
    (** For sending HTTP requests that share the cookies of the context. *)

    (** {1 State} *)

    val cookies : ?urls:string list -> t -> Cookie.t list
    val add_cookies : Cookie.init list -> t -> unit
    val clear_cookies : ?name:string -> ?domain:string -> ?path:string -> t -> unit

    val storage_state : ?path:string -> ?indexed_db:bool -> t -> Yojson.Safe.t
    (** The cookies and the local storage of the context, for the [storage_state] option of a later context. *)

    val set_storage_state : Yojson.Safe.t -> t -> unit
    (** Replaces the cookies and the local storage of the context by those of a state that {!storage_state}
        returned. *)

    val grant_permissions : ?origin:string -> string list -> t -> unit
    val clear_permissions : t -> unit
    val set_geolocation : Geolocation.t option -> t -> unit

    (** {1 Scripting} *)

    val add_init_script : ?path:string -> ?script:string -> t -> unit
    (** Evaluates a script, given as source text or as a file, in every page and frame of the context before any of
        the page's own scripts run. *)

    val expose_function : string -> (Js.t list -> Js.t) -> t -> unit
    (** [expose_function name f] makes [f] available to all pages as [window.name]. Calling it in the page returns a
        promise of the result of [f]; if [f] raises, the promise is rejected. *)

    val expose_binding : string -> (binding_source -> Js.t list -> Js.t) -> t -> unit
    (** Like {!expose_function}, for a function that also wants to know which page and frame called it. *)

    val service_workers : t -> worker list
    val tracing : t -> tracing

    val new_cdp_session : page -> t -> cdp_session
    (** A Chrome DevTools Protocol session with a page. Chromium only. *)

    val new_cdp_session_for_frame : frame -> t -> cdp_session
end

(** {1 Pages} *)

(** A tab or a popup window. *)
module Page : sig
    type t = page

    (** {1 Locators} *)

    val locator :
        ?has_text:string -> ?has_text_regex:string -> ?has_not_text:string -> ?has_not_text_regex:string -> ?has:locator -> ?has_not:locator ->
        string -> t -> locator
    (** The elements matching a {{:https://playwright.dev/docs/other-locators} selector}, CSS or XPath for instance,
        optionally filtered as by {!Locator.filter}. *)

    include Locator_queries with type t := t

    val frame_locator : string -> t -> frame_locator
    (** The content of the [<iframe>] that the selector matches. *)

    (** {1 Navigation, JavaScript and operations by selector} *)

    include Frame_operations with type t := t

    val reload : ?timeout:float -> ?wait_until:lifecycle_event -> t -> response option
    val go_back : ?timeout:float -> ?wait_until:lifecycle_event -> t -> response option
    (** [None] if there is no previous page in the history. *)

    val go_forward : ?timeout:float -> ?wait_until:lifecycle_event -> t -> response option
    val url : t -> string

    (** {1 The page} *)

    val context : t -> browser_context

    val opener : t -> t option
    (** The page that opened this popup, unless that is closed. *)

    val main_frame : t -> frame
    val frames : t -> frame list

    val frame : ?name:string -> ?url:string -> t -> frame option
    (** The frame with the given [name] attribute or whose URL matches the glob pattern. *)

    val workers : t -> worker list
    val keyboard : t -> keyboard
    val mouse : t -> mouse
    val touchscreen : t -> touchscreen

    val request : t -> api_request_context
    (** The same as {!BrowserContext.request} of the page's context. *)

    val video : t -> video option
    (** The video recording of the page, when the context was created with [record_video_dir]. *)

    val close : ?run_before_unload:bool -> ?reason:string -> t -> unit
    (** Closes the page. Does nothing if it is closed already. With [run_before_unload], the page's [beforeunload]
        handlers run first and may keep it open, and the function does not wait for the page to close. *)

    val is_closed : t -> bool
    val bring_to_front : t -> unit
    val set_default_timeout : float -> t -> unit
    val set_default_navigation_timeout : float -> t -> unit

    val pause : t -> unit
    (** Opens the Playwright Inspector and waits for the user to resume. For headed browsers. *)

    (** {1 Events} *)

    type _ event =
        | Close : t event
        | Console : console_message event
        | Crash : t event
        | Dialog : dialog event
              (** A JavaScript dialog opened. It must be accepted or dismissed, or the page stays blocked; dialogs
                  are dismissed automatically while there is no listener for this event. *)
        | Dom_content_loaded : t event
        | Download : download event
        | File_chooser : file_chooser event
        | Frame_attached : frame event
        | Frame_detached : frame event
        | Frame_navigated : frame event
        | Load : t event
        | Page_error : Error.t event  (** An exception was not handled in the page. *)
        | Popup : t event
        | Request : request event
        | Request_failed : request event
        | Request_finished : request event
        | Response : response event
        | Web_socket : web_socket event
        | Worker : worker event

    val on : 'a event -> ('a -> unit) -> t -> unit
    (** See {!BrowserContext.on}. *)

    val once : 'a event -> ('a -> unit) -> t -> unit
    val off : 'a event -> ('a -> unit) -> t -> unit

    val expect_event : ?timeout:float -> ?predicate:('a -> bool) -> 'a event -> (unit -> unit) -> t -> 'a
    (** See {!BrowserContext.expect_event}.

        {[
          let download = Page.expect_event Page.Download (fun () -> Locator.click link) page
        ]} *)

    val wait_for_event : ?timeout:float -> ?predicate:('a -> bool) -> 'a event -> t -> 'a
    val expect_popup : ?timeout:float -> ?predicate:(t -> bool) -> (unit -> unit) -> t -> t
    val expect_download : ?timeout:float -> ?predicate:(download -> bool) -> (unit -> unit) -> t -> download
    val expect_file_chooser : ?timeout:float -> ?predicate:(file_chooser -> bool) -> (unit -> unit) -> t -> file_chooser
    val expect_console_message : ?timeout:float -> ?predicate:(console_message -> bool) -> (unit -> unit) -> t -> console_message
    val expect_web_socket : ?timeout:float -> ?predicate:(web_socket -> bool) -> (unit -> unit) -> t -> web_socket
    val expect_worker : ?timeout:float -> ?predicate:(worker -> bool) -> (unit -> unit) -> t -> worker

    val expect_request : ?timeout:float -> ?url:string -> ?predicate:(request -> bool) -> (unit -> unit) -> t -> request
    (** Runs the action and returns the first request made from then on whose URL matches the glob pattern [url] and
        that satisfies [predicate]. *)

    val expect_request_finished : ?timeout:float -> ?url:string -> ?predicate:(request -> bool) -> (unit -> unit) -> t -> request
    val expect_response : ?timeout:float -> ?url:string -> ?predicate:(response -> bool) -> (unit -> unit) -> t -> response
    val wait_for_request : ?timeout:float -> ?url:string -> ?predicate:(request -> bool) -> t -> request
    val wait_for_response : ?timeout:float -> ?url:string -> ?predicate:(response -> bool) -> t -> response

    (** {1 Network} *)

    val route : ?times:int -> string -> (route -> unit) -> t -> unit
    (** Intercepts the requests of this page, see {!BrowserContext.route}.

        {[
          Page.route "**/api/user" (Route.fulfill ~json:(`Assoc [ "name", `String "Ada" ])) page;
          Page.route "**/*.{png,jpg}" Route.abort page
        ]} *)

    val route_matching : ?times:int -> (string -> bool) -> (route -> unit) -> t -> unit
    val unroute : string -> t -> unit
    val unroute_all : t -> unit

    val route_from_har :
        ?url:string ->
        ?not_found:[ `Abort | `Fallback ] ->
        ?update:bool ->
        ?update_content:[ `Attach | `Embed | `Omit ] ->
        ?update_mode:[ `Full | `Minimal ] ->
        string ->
        t ->
        unit
    (** Answers the requests of this page from a HAR file, see {!BrowserContext.route_from_har}. *)

    val route_web_socket : string -> (web_socket_route -> unit) -> t -> unit
    val route_web_socket_matching : (string -> bool) -> (web_socket_route -> unit) -> t -> unit
    val set_extra_http_headers : (string * string) list -> t -> unit

    val requests : t -> request list
    (** The most recent requests of the page, up to a limit set by the browser. *)

    (** {1 History}

        What happened in the page before anyone listened: the browser keeps the most recent console messages and
        uncaught errors of every page. *)

    val console_messages : ?filter:[ `All | `Since_navigation ] -> t -> console_message list
    (** The console messages of the page so far, the oldest first; with [`Since_navigation] only those of the
        document that it shows now. *)

    val clear_console_messages : t -> unit

    val page_errors : ?filter:[ `All | `Since_navigation ] -> t -> Error.t list
    (** The exceptions that scripts of the page did not catch, as the [Page_error] event reports them. *)

    val clear_page_errors : t -> unit

    (** {1 Storage} *)

    val local_storage : t -> web_storage
    (** The [localStorage] of the page for the origin that it shows, see {!WebStorage}. *)

    val session_storage : t -> web_storage

    (** {1 Scripting} *)

    val add_init_script : ?path:string -> ?script:string -> t -> unit
    val expose_function : string -> (Js.t list -> Js.t) -> t -> unit
    val expose_binding : string -> (binding_source -> Js.t list -> Js.t) -> t -> unit

    val add_locator_handler : ?times:int -> ?no_wait_after:bool -> locator -> (locator -> unit) -> t -> unit
    (** [add_locator_handler locator handler] calls [handler] whenever an action is about to be performed while
        [locator] is visible, typically to dismiss an overlay that would be in the way. *)

    val remove_locator_handler : locator -> t -> unit

    (** {1 Rendering} *)

    val screenshot : ?full_page:bool -> ?clip:rect -> (t -> string) with_screenshot_options
    (** Takes a screenshot of the viewport, of the whole scrollable page with [full_page], or of the area [clip].
        Returns the image data. *)

    val pdf :
        ?path:string -> ?scale:float -> ?display_header_footer:bool -> ?header_template:string -> ?footer_template:string ->
        ?print_background:bool -> ?landscape:bool -> ?page_ranges:string -> ?format:string -> ?width:string -> ?height:string ->
        ?prefer_css_page_size:bool -> ?margin_top:string -> ?margin_right:string -> ?margin_bottom:string -> ?margin_left:string ->
        ?tagged:bool -> ?outline:bool -> t -> string
    (** Prints the page to PDF and returns the document. Headless Chromium only. Lengths are strings with a unit,
        e.g. ["10mm"]. *)

    val aria_snapshot : ?timeout:float -> ?mode:[ `Ai | `Default ] -> ?depth:int -> ?boxes:bool -> t -> string
    (** The accessibility tree of the page as YAML, see {!Locator.aria_snapshot}. *)

    val viewport_size : t -> (int * int) option
    val set_viewport_size : int * int -> t -> unit

    val emulate_media :
        ?media:[ `Screen | `Print | `No_override ] -> ?color_scheme:color_scheme -> ?reduced_motion:reduced_motion ->
        ?forced_colors:forced_colors -> ?contrast:contrast -> t -> unit

    val request_gc : t -> unit
end

(** A frame of a page: its main frame or the content of an [<iframe>]. *)
module Frame : sig
    type t = frame

    val locator :
        ?has_text:string -> ?has_text_regex:string -> ?has_not_text:string -> ?has_not_text_regex:string -> ?has:locator -> ?has_not:locator ->
        string -> t -> locator

    include Locator_queries with type t := t

    val frame_locator : string -> t -> frame_locator

    include Frame_operations with type t := t

    val page : t -> page
    val url : t -> string

    val name : t -> string
    (** The [name] attribute of the frame's element; empty for the main frame. *)

    val parent_frame : t -> t option
    val child_frames : t -> t list
    val is_detached : t -> bool

    val frame_element : t -> element_handle
    (** The [<iframe>] or [<frame>] element that holds the frame. *)
end

(** A way to find elements in a page, and the means to act on them.

    A locator is a description, not a reference: it is resolved every time it is used, and creating one does not
    touch the page. Actions wait until the element is there and
    {{:https://playwright.dev/docs/actionability} ready for the action}, and retry until the timeout expires.
    A locator that is acted on must resolve to exactly one element, or the action fails with a strict mode violation.

    {[
      let row = Page.get_by_role `Row page |> Locator.filter ~has_text:"Ada Lovelace" in
      Locator.get_by_role `Button ~name:"Edit" row |> Locator.click;
      Page.get_by_label "Name" page |> Locator.fill "Ada King"
    ]} *)
module Locator : sig
    type t = locator

    (** {1 Narrowing down} *)

    val locator :
        ?has_text:string -> ?has_text_regex:string -> ?has_not_text:string -> ?has_not_text_regex:string -> ?has:t -> ?has_not:t -> string -> t -> t
    (** The descendants of the located elements that match the selector. *)

    include Locator_queries with type t := t

    val filter :
        ?has_text:string -> ?has_text_regex:string -> ?has_not_text:string -> ?has_not_text_regex:string -> ?has:t -> ?has_not:t ->
        ?visible:bool -> t -> t
    (** Keeps the elements that contain the text ([has_text]) or a descendant matching another locator ([has]), that
        do not ([has_not_text], [has_not]), or that are visible or not. *)

    val first : t -> t
    val last : t -> t

    val nth : int -> t -> t
    (** Counting from 0; negative numbers count from the end. *)

    val and_ : t -> t -> t
    (** The elements that both locators match. *)

    val or_ : t -> t -> t
    (** The elements that either locator matches. *)

    val visible : t -> t

    val describe : string -> t -> t
    (** Gives the locator a name to show in traces and error messages. *)

    val frame_locator : string -> t -> frame_locator

    val content_frame : t -> frame_locator
    (** For a locator of an [<iframe>]: the content of that frame. *)

    val page : t -> page
    val frame : t -> frame

    val to_string : t -> string
    (** The selector that the locator stands for. *)

    val equal : t -> t -> bool

    (** {1 Actions} *)

    val click :
        ?timeout:float -> ?force:bool -> ?no_wait_after:bool -> ?modifiers:keyboard_modifier list -> ?position:float * float -> ?delay:float ->
        ?button:mouse_button -> ?click_count:int -> ?trial:bool -> ?steps:int -> t -> unit
    (** Scrolls the element into view if needed, waits for it to be visible, stable, enabled and not covered, and
        clicks its centre or [position] relative to its top left corner. [force] skips the waiting; [trial] does
        the waiting but not the click. *)

    val dblclick :
        ?timeout:float -> ?force:bool -> ?modifiers:keyboard_modifier list -> ?position:float * float -> ?delay:float -> ?button:mouse_button ->
        ?trial:bool -> ?steps:int -> t -> unit

    val tap : ?timeout:float -> ?force:bool -> ?modifiers:keyboard_modifier list -> ?position:float * float -> ?trial:bool -> t -> unit
    (** Requires a context with [has_touch]. *)

    val hover : ?timeout:float -> ?force:bool -> ?modifiers:keyboard_modifier list -> ?position:float * float -> ?trial:bool -> t -> unit

    val drag_to :
        ?timeout:float -> ?force:bool -> ?trial:bool -> ?source_position:float * float -> ?target_position:float * float -> ?steps:int -> t -> t ->
        unit
    (** [drag_to target source] drags the element of [source] onto that of [target]. *)

    val fill : ?timeout:float -> ?force:bool -> string -> t -> unit
    (** Sets the value of an [<input>], [<textarea>] or [contenteditable] element and dispatches the [input] event. *)

    val clear : ?timeout:float -> ?force:bool -> t -> unit
    val focus : ?timeout:float -> t -> unit
    val blur : ?timeout:float -> t -> unit

    val press : ?timeout:float -> ?delay:float -> ?no_wait_after:bool -> string -> t -> unit
    (** Focuses the element and presses a key or a combination of keys, e.g. ["Enter"] or ["Control+A"]. *)

    val press_sequentially : ?timeout:float -> ?delay:float -> string -> t -> unit
    (** Types the text key by key. Use {!fill} unless the page needs to see the individual key events. *)

    val check : ?timeout:float -> ?force:bool -> ?position:float * float -> ?trial:bool -> t -> unit
    val uncheck : ?timeout:float -> ?force:bool -> ?position:float * float -> ?trial:bool -> t -> unit
    val set_checked : ?timeout:float -> ?force:bool -> ?position:float * float -> ?trial:bool -> bool -> t -> unit

    val select_option : ?timeout:float -> ?force:bool -> select_option list -> t -> string list
    (** Selects options of a [<select>] and returns the values of the selected options. *)

    val set_input_files : ?timeout:float -> string list -> t -> unit
    (** Sets the files of an [<input type=file>] to the files at the given paths. An empty list clears it. A single
        directory can be given for an input with the [webkitdirectory] attribute. *)

    val set_input_payloads : ?timeout:float -> file_payload list -> t -> unit

    val drop :
        ?timeout:float ->
        ?position:float * float ->
        ?files:string list ->
        ?payloads:file_payload list ->
        ?data:(string * string) list ->
        t ->
        unit
    (** Drops something onto the element the way a drag from outside the browser does: the files at the paths
        [files] or the in-memory files [payloads], and [data] as pairs of a MIME type and a value, e.g.
        [("text/plain", "hello")]. The page receives [dragenter], [dragover] and [drop] events. *)

    val select_text : ?timeout:float -> ?force:bool -> t -> unit
    val scroll_into_view_if_needed : ?timeout:float -> t -> unit
    val dispatch_event : ?timeout:float -> ?event_init:Js.t -> string -> t -> unit

    val highlight : ?style:string -> t -> unit
    val hide_highlight : t -> unit

    (** {1 Reading} *)

    val count : t -> int
    (** The number of elements that match right now. *)

    val all : t -> t list
    (** A locator for each of the elements that match right now. Does not wait for elements to appear. *)

    val text_content : ?timeout:float -> t -> string option
    val inner_text : ?timeout:float -> t -> string
    val inner_html : ?timeout:float -> t -> string
    val all_inner_texts : t -> string list
    val all_text_contents : t -> string list
    val get_attribute : ?timeout:float -> string -> t -> string option
    val input_value : ?timeout:float -> t -> string
    val is_checked : ?timeout:float -> t -> bool
    val is_disabled : ?timeout:float -> t -> bool
    val is_editable : ?timeout:float -> t -> bool
    val is_enabled : ?timeout:float -> t -> bool

    val is_hidden : t -> bool
    (** Does not wait. An element that does not exist is hidden. *)

    val is_visible : t -> bool
    val bounding_box : ?timeout:float -> t -> rect option

    val aria_snapshot : ?timeout:float -> ?mode:[ `Ai | `Default ] -> ?depth:int -> ?boxes:bool -> t -> string
    (** The accessibility tree of the element as YAML, see
        {{:https://playwright.dev/docs/aria-snapshots} ARIA snapshots}. *)

    val screenshot : (t -> string) with_screenshot_options

    val wait_for : ?timeout:float -> ?state:element_state -> t -> unit
    (** Waits until the element is in the given state, [`Visible] by default. *)

    (** {1 JavaScript} *)

    val evaluate : ?timeout:float -> ?arg:Js.t -> string -> t -> Js.t
    (** Calls the function that the expression evaluates to with the element and [arg]:
        [Locator.evaluate "element => element.scrollTop" locator]. *)

    val evaluate_handle : ?timeout:float -> ?arg:Js.t -> string -> t -> js_handle

    val evaluate_all : ?arg:Js.t -> string -> t -> Js.t
    (** Calls the function with the array of all elements that match right now. *)

    val element_handle : ?timeout:float -> t -> element_handle
    val element_handles : t -> element_handle list
end

(** The content of an [<iframe>], for locating elements inside it:
    [Page.frame_locator "#payment" page |> FrameLocator.get_by_label "Card number" |> Locator.fill "4242..."]. *)
module FrameLocator : sig
    type t = frame_locator

    val locator :
        ?has_text:string -> ?has_text_regex:string -> ?has_not_text:string -> ?has_not_text_regex:string -> ?has:locator -> ?has_not:locator ->
        string -> t -> locator

    include Locator_queries with type t := t

    val frame_locator : string -> t -> t

    val owner : t -> locator
    (** The [<iframe>] element itself. *)

    val first : t -> t
    val last : t -> t
    val nth : int -> t -> t
end

(** {1 Assertions} *)

(** Assertions that wait: each of them checks its condition repeatedly until it holds, and fails with an {!Error} of
    kind [Assertion_failed] when it does not come to hold within the timeout, 5 seconds by default. The error
    message says what was expected, what was found instead, and includes the call log.

    {[
      Expect.to_be_visible (Page.get_by_role `Heading ~name:"Welcome" page);
      Expect.to_have_text "3 items" (Page.get_by_test_id "cart-count" page);
      Expect.Not.to_be_checked (Page.get_by_label "Subscribe" page);
      Expect.to_have_url "**/checkout" page
    ]} *)
module Expect : sig
    module type Assertions = sig
        (** {2 Locators} *)

        val to_be_attached : ?timeout:float -> locator -> unit
        (** An element matching the locator is in the document. *)

        val to_be_detached : ?timeout:float -> locator -> unit
        val to_be_visible : ?timeout:float -> locator -> unit
        val to_be_hidden : ?timeout:float -> locator -> unit
        val to_be_enabled : ?timeout:float -> locator -> unit
        val to_be_disabled : ?timeout:float -> locator -> unit
        val to_be_editable : ?timeout:float -> locator -> unit
        val to_be_read_only : ?timeout:float -> locator -> unit

        val to_be_empty : ?timeout:float -> locator -> unit
        (** An editable element has no value, or another element has no text. *)

        val to_be_focused : ?timeout:float -> locator -> unit
        val to_be_checked : ?timeout:float -> ?checked:bool -> locator -> unit
        val to_be_indeterminate : ?timeout:float -> locator -> unit

        val to_be_in_viewport : ?timeout:float -> ?ratio:float -> locator -> unit
        (** At least the fraction [ratio] of the element intersects the viewport; any part of it by default. *)

        val to_have_text : ?timeout:float -> ?ignore_case:bool -> ?use_inner_text:bool -> string -> locator -> unit
        (** The text of the element is the given one, with whitespace normalised. *)

        val to_have_text_regex : ?timeout:float -> ?use_inner_text:bool -> string -> locator -> unit

        val to_contain_text : ?timeout:float -> ?ignore_case:bool -> ?use_inner_text:bool -> string -> locator -> unit
        (** The text of the element contains the given one. *)

        val to_have_texts : ?timeout:float -> ?ignore_case:bool -> ?use_inner_text:bool -> string list -> locator -> unit
        (** The locator matches as many elements as there are texts, and they have these texts in this order. *)

        val to_contain_texts : ?timeout:float -> ?ignore_case:bool -> ?use_inner_text:bool -> string list -> locator -> unit

        val to_have_attribute : ?timeout:float -> ?ignore_case:bool -> string -> string -> locator -> unit
        (** [to_have_attribute name value]. *)

        val to_have_attribute_regex : ?timeout:float -> string -> string -> locator -> unit

        val to_have_attribute_present : ?timeout:float -> string -> locator -> unit
        (** The element has the attribute, with whatever value. *)

        val to_have_class : ?timeout:float -> string -> locator -> unit
        (** The [class] attribute is exactly the given string. *)

        val to_have_class_regex : ?timeout:float -> string -> locator -> unit

        val to_contain_class : ?timeout:float -> string -> locator -> unit
        (** The element has all of the given space-separated classes. *)

        val to_have_id : ?timeout:float -> string -> locator -> unit
        val to_have_role : ?timeout:float -> aria_role -> locator -> unit
        val to_have_value : ?timeout:float -> string -> locator -> unit
        val to_have_value_regex : ?timeout:float -> string -> locator -> unit

        val to_have_values : ?timeout:float -> string list -> locator -> unit
        (** The selected options of a [<select multiple>]. *)

        val to_have_css : ?timeout:float -> ?pseudo:[ `Before | `After ] -> string -> string -> locator -> unit
        (** [to_have_css property value] compares against the computed style of the element. *)

        val to_have_js_property : ?timeout:float -> string -> Js.t -> locator -> unit
        val to_have_count : ?timeout:float -> int -> locator -> unit
        val to_have_accessible_name : ?timeout:float -> ?ignore_case:bool -> string -> locator -> unit
        val to_have_accessible_name_regex : ?timeout:float -> string -> locator -> unit
        val to_have_accessible_description : ?timeout:float -> ?ignore_case:bool -> string -> locator -> unit
        val to_have_accessible_description_regex : ?timeout:float -> string -> locator -> unit

        val to_match_aria_snapshot : ?timeout:float -> string -> locator -> unit
        (** The accessibility tree of the element matches the given
            {{:https://playwright.dev/docs/aria-snapshots} ARIA snapshot} template. *)

        (** {2 Pages} *)

        val to_have_title : ?timeout:float -> string -> page -> unit
        val to_have_title_regex : ?timeout:float -> string -> page -> unit

        val to_have_url : ?timeout:float -> ?ignore_case:bool -> string -> page -> unit
        (** The URL of the page matches the glob pattern; a pattern starting with [/] is relative to the [base_url] of
            the context. *)

        val to_have_url_regex : ?timeout:float -> string -> page -> unit

        (** {2 Responses} *)

        val to_be_ok : api_response -> unit
        (** The status is in the range 200-299. This one does not wait. *)
    end

    include Assertions

    (** The opposite assertions: [Expect.Not.to_be_visible locator] waits for the element to be hidden. *)
    module Not : Assertions

    val set_default_timeout : float -> unit
    (** Sets the timeout of the assertions that are not given one, for the whole program. *)
end

(** {1 Handles and input devices} *)

(** A reference to a JavaScript object in a page. Handles keep their objects alive until they are disposed of or the
    page navigates. *)
module JSHandle : sig
    type t = js_handle

    val evaluate : ?arg:Js.t -> string -> t -> Js.t
    (** Calls the function that the expression evaluates to with the object and [arg]. *)

    val evaluate_handle : ?arg:Js.t -> string -> t -> t
    val get_property : string -> t -> t
    val get_properties : t -> (string * t) list

    val json_value : t -> Js.t
    (** A copy of the object. *)

    val as_element : t -> element_handle option
    (** The handle as an element handle, if the object is a DOM element. *)

    val to_string : t -> string
    val dispose : t -> unit
end

(** A reference to a DOM element in a page. {!Locator}s are the better tool for nearly everything: an element
    handle refers to one particular element, which the page may replace at any time. *)
module ElementHandle : sig
    type t = element_handle

    val as_js_handle : t -> js_handle
    val evaluate : ?arg:Js.t -> string -> t -> Js.t
    val evaluate_handle : ?arg:Js.t -> string -> t -> js_handle
    val dispose : t -> unit

    val owner_frame : t -> frame option
    (** The frame whose document the element is in. *)

    val content_frame : t -> frame option
    (** For an [<iframe>] element: the frame that it holds. *)

    val query_selector : string -> t -> t option
    val query_selector_all : string -> t -> t list
    val eval_on_selector : ?arg:Js.t -> string -> string -> t -> Js.t
    val eval_on_selector_all : ?arg:Js.t -> string -> string -> t -> Js.t
    val wait_for_selector : ?timeout:float -> ?strict:bool -> ?state:element_state -> string -> t -> t option
    val wait_for_element_state : ?timeout:float -> [ `Visible | `Hidden | `Stable | `Enabled | `Disabled | `Editable ] -> t -> unit
    val get_attribute : string -> t -> string option
    val text_content : t -> string option
    val inner_text : t -> string
    val inner_html : t -> string
    val input_value : t -> string
    val is_checked : t -> bool
    val is_disabled : t -> bool
    val is_editable : t -> bool
    val is_enabled : t -> bool
    val is_hidden : t -> bool
    val is_visible : t -> bool
    val bounding_box : t -> rect option
    val screenshot : (t -> string) with_screenshot_options
    val scroll_into_view_if_needed : ?timeout:float -> t -> unit
    val dispatch_event : ?event_init:Js.t -> string -> t -> unit

    val click :
        ?timeout:float -> ?force:bool -> ?no_wait_after:bool -> ?modifiers:keyboard_modifier list -> ?position:float * float -> ?delay:float ->
        ?button:mouse_button -> ?click_count:int -> ?trial:bool -> ?steps:int -> t -> unit

    val dblclick :
        ?timeout:float -> ?force:bool -> ?modifiers:keyboard_modifier list -> ?position:float * float -> ?delay:float -> ?button:mouse_button ->
        ?trial:bool -> ?steps:int -> t -> unit

    val tap : ?timeout:float -> ?force:bool -> ?modifiers:keyboard_modifier list -> ?position:float * float -> ?trial:bool -> t -> unit
    val hover : ?timeout:float -> ?force:bool -> ?modifiers:keyboard_modifier list -> ?position:float * float -> ?trial:bool -> t -> unit
    val fill : ?timeout:float -> ?force:bool -> string -> t -> unit
    val select_text : ?timeout:float -> ?force:bool -> t -> unit
    val focus : t -> unit
    val press : ?timeout:float -> ?delay:float -> ?no_wait_after:bool -> string -> t -> unit
    val type_ : ?timeout:float -> ?delay:float -> string -> t -> unit
    val check : ?timeout:float -> ?force:bool -> ?position:float * float -> ?trial:bool -> t -> unit
    val uncheck : ?timeout:float -> ?force:bool -> ?position:float * float -> ?trial:bool -> t -> unit
    val set_checked : ?timeout:float -> ?force:bool -> ?position:float * float -> ?trial:bool -> bool -> t -> unit
    val select_option : ?timeout:float -> ?force:bool -> select_option list -> t -> string list
    val set_input_files : ?timeout:float -> string list -> t -> unit
    val set_input_payloads : ?timeout:float -> file_payload list -> t -> unit
end

(** The keyboard of a page, see {!Page.keyboard}. Keys are named as in
    {{:https://playwright.dev/docs/api/class-keyboard#keyboard-press} [keyboard.press]}: ["a"], ["Enter"],
    ["ArrowLeft"], or a combination such as ["Shift+Tab"] or ["ControlOrMeta+C"]. *)
module Keyboard : sig
    type t = keyboard

    val press : ?delay:float -> string -> t -> unit

    val type_ : ?delay:float -> string -> t -> unit
    (** Sends the key events for each character of the text. *)

    val insert_text : string -> t -> unit
    (** Inserts the text without key events. *)

    val down : string -> t -> unit
    val up : string -> t -> unit
end

(** The mouse of a page, see {!Page.mouse}. Coordinates are in CSS pixels relative to the top left corner of the
    viewport. *)
module Mouse : sig
    type t = mouse

    val move : ?steps:int -> float -> float -> t -> unit
    val down : ?button:mouse_button -> ?click_count:int -> t -> unit
    val up : ?button:mouse_button -> ?click_count:int -> t -> unit
    val click : ?delay:float -> ?button:mouse_button -> ?click_count:int -> float -> float -> t -> unit
    val dblclick : ?delay:float -> ?button:mouse_button -> float -> float -> t -> unit

    val wheel : float -> float -> t -> unit
    (** [wheel delta_x delta_y] scrolls. *)
end

module Touchscreen : sig
    type t = touchscreen

    val tap : float -> float -> t -> unit
end

(** {1 Network} *)

(** A request made by a page. *)
module Request : sig
    type t = request

    type sizes = { request_body_size : int; request_headers_size : int; response_body_size : int; response_headers_size : int }

    val url : t -> string
    val method_ : t -> string

    val resource_type : t -> string
    (** How the page uses the resource: ["document"], ["stylesheet"], ["image"], ["script"], ["xhr"], ["fetch"], ... *)

    val headers : t -> (string * string) list
    (** The headers as the page set them, with names in lower case. This does not include what the browser adds on
        its own, such as cookies; see {!all_headers}. *)

    val all_headers : t -> (string * string) list
    (** All headers that are sent, names in lower case, repeated headers merged. Asks the browser. *)

    val headers_array : t -> (string * string) list
    (** All headers as they are sent, with their original names and repetitions. *)

    val header_value : string -> t -> string option
    val post_data : t -> string option
    val post_data_json : t -> Yojson.Safe.t option

    val response : t -> response option
    (** Waits for the response. [None] if the request failed. *)

    val existing_response : t -> response option
    (** The response if it has been received already. Does not wait. *)

    val frame : t -> frame
    (** The frame that made the request. Fails for requests of service workers. *)

    val service_worker : t -> worker option
    val is_navigation_request : t -> bool

    val redirected_from : t -> t option
    (** The request that the server answered with a redirect to this one. *)

    val redirected_to : t -> t option

    val failure : t -> string option
    (** The reason why the request failed, e.g. ["net::ERR_FAILED"]; [None] unless it has failed. *)

    val timing : t -> timing

    val sizes : t -> sizes
    (** Waits for the response to finish. *)
end

(** The response to a {!Request}. *)
module Response : sig
    type t = response

    type server_addr = { ip_address : string; port : int }

    type security_details = {
        issuer : string option;
        protocol : string option;
        subject_name : string option;
        valid_from : float option;
        valid_to : float option;
    }

    val url : t -> string
    val status : t -> int
    val status_text : t -> string

    val ok : t -> bool
    (** The status is in the range 200-299. *)

    val headers : t -> (string * string) list
    val all_headers : t -> (string * string) list
    val headers_array : t -> (string * string) list
    val header_value : string -> t -> string option
    val header_values : string -> t -> string list

    val body : t -> string
    (** The body, after waiting for it to arrive. Fails for redirects. *)

    val text : t -> string

    val json : t -> Yojson.Safe.t
    (** The body parsed as JSON. *)

    val finished : t -> unit
    (** Waits until the body has been received in full; fails if the request fails before that. *)

    val request : t -> request
    val frame : t -> frame
    val from_service_worker : t -> bool
    val http_version : t -> string
    val server_addr : t -> server_addr option
    val security_details : t -> security_details option
end

(** An intercepted request, see {!Page.route}. A handler has to conclude each route in exactly one way. *)
module Route : sig
    type t = route

    val request : t -> request

    val fulfill :
        ?status:int -> ?headers:(string * string) list -> ?content_type:string -> ?body:string -> ?json:Yojson.Safe.t -> ?path:string ->
        ?response:api_response -> t -> unit
    (** Answers the request without sending it: with [body], [json] or the file at [path], or with a [response] that
        was obtained from {!fetch}, of which the other arguments override parts. The status defaults to 200. *)

    val continue : ?url:string -> ?method_:string -> ?headers:(string * string) list -> ?post_data:string -> t -> unit
    (** Sends the request to the network, optionally modified. *)

    val fallback : ?url:string -> ?method_:string -> ?headers:(string * string) list -> ?post_data:string -> t -> unit
    (** Passes the request, optionally modified, on to the handler that was registered before this one; it is sent
        to the network if there is none. *)

    val abort : ?error_code:string -> t -> unit
    (** Fails the request, with an error such as ["failed"] (the default), ["aborted"], ["blockedbyclient"],
        ["connectionrefused"] or ["timedout"]. *)

    val fetch :
        ?timeout:float -> ?url:string -> ?method_:string -> ?headers:(string * string) list -> ?post_data:string -> ?max_redirects:int ->
        ?max_retries:int -> t -> api_response
    (** Performs the request and returns the response without passing it to the page, so that it can be inspected
        and modified before {!fulfill}. *)
end

(** A WebSocket connection opened by a page. *)
module WebSocket : sig
    type t = web_socket

    val url : t -> string
    val is_closed : t -> bool

    type _ event =
        | Close : t event
        | Frame_sent : web_socket_message event
        | Frame_received : web_socket_message event
        | Socket_error : string event

    val on : 'a event -> ('a -> unit) -> t -> unit
    val once : 'a event -> ('a -> unit) -> t -> unit
    val off : 'a event -> ('a -> unit) -> t -> unit
    val expect_event : ?timeout:float -> ?predicate:('a -> bool) -> 'a event -> (unit -> unit) -> t -> 'a
    val wait_for_event : ?timeout:float -> ?predicate:('a -> bool) -> 'a event -> t -> 'a
end

(** An intercepted WebSocket connection, see {!Page.route_web_socket}.

    The value given to the handler is the connection to the page. Unless {!connect_to_server} is called, the page is
    not connected to any server, and the handler plays the server: it receives what the page sends with
    {!on_message} and talks to the page with {!send}.

    [connect_to_server] opens the connection to the actual server and returns the server's side of it. Messages are
    then forwarded in both directions, except that a side with an {!on_message} handler has its messages given to
    that handler instead, which may pass them on with {!send} to the other side. *)
module WebSocketRoute : sig
    type t = web_socket_route

    val url : t -> string
    val protocols : t -> string list
    val connect_to_server : t -> t

    val send : web_socket_message -> t -> unit
    (** Sends a message to this side: to the page, or to the server for the value returned by {!connect_to_server}. *)

    val on_message : (web_socket_message -> unit) -> t -> unit
    (** Handles the messages coming from this side. *)

    val on_close : (int option -> string option -> unit) -> t -> unit
    (** Handles the closing of the connection by this side, given the close code and reason. Without a handler the
        closure is forwarded to the other side. *)

    val close : ?code:int -> ?reason:string -> t -> unit
end

(** {1 Things that pages report} *)

(** A JavaScript dialog: [alert], [confirm], [prompt] or [beforeunload]. See {!Page.Dialog}. *)
module Dialog : sig
    type t = dialog

    val type_ : t -> string
    (** ["alert"], ["confirm"], ["prompt"] or ["beforeunload"]. *)

    val message : t -> string
    val default_value : t -> string
    val page : t -> page option
    val accept : ?prompt_text:string -> t -> unit
    val dismiss : t -> unit
end

module ConsoleMessage : sig
    type t = console_message

    type location = { url : string; line_number : int; column_number : int }

    val type_ : t -> string
    (** ["log"], ["debug"], ["info"], ["error"], ["warning"], ["dir"], ["trace"], ["assert"], ... *)

    val text : t -> string
    val args : t -> js_handle list
    val location : t -> location
    val page : t -> page option
    val worker : t -> worker option

    val timestamp : t -> float
    (** Milliseconds since the Unix epoch. *)
end

(** A file that a page downloads. Downloads are stored in a temporary directory and deleted when the context is
    closed; use {!save_as} to keep one. *)
module Download : sig
    type t = download

    val url : t -> string
    val suggested_filename : t -> string
    val page : t -> page

    val path : t -> string
    (** Waits for the download to finish and returns where it was stored. *)

    val save_as : string -> t -> unit
    (** Waits for the download to finish and copies it to the given path. *)

    val failure : t -> string option
    (** Waits for the download to finish; the reason if it failed. *)

    val cancel : t -> unit
    val delete : t -> unit
end

(** A file chooser that a page opened, see {!Page.expect_file_chooser}. *)
module FileChooser : sig
    type t = file_chooser

    val page : t -> page
    val element : t -> element_handle
    val is_multiple : t -> bool
    val set_files : ?timeout:float -> string list -> t -> unit
    val set_payloads : ?timeout:float -> file_payload list -> t -> unit
end

(** An exception that was not handled in a page, see {!BrowserContext.Web_error}. *)
module WebError : sig
    type t = web_error

    val page : t -> page option
    val error : t -> Error.t
end

(** A web worker or a service worker. *)
module Worker : sig
    type t = worker

    val url : t -> string
    val evaluate : ?arg:Js.t -> string -> t -> Js.t
    val evaluate_handle : ?arg:Js.t -> string -> t -> js_handle

    type _ event = Close : t event | Console : console_message event

    val on : 'a event -> ('a -> unit) -> t -> unit
    val once : 'a event -> ('a -> unit) -> t -> unit
    val off : 'a event -> ('a -> unit) -> t -> unit
    val expect_event : ?timeout:float -> ?predicate:('a -> bool) -> 'a event -> (unit -> unit) -> t -> 'a
    val wait_for_event : ?timeout:float -> ?predicate:('a -> bool) -> 'a event -> t -> 'a
end

(** The [localStorage] or [sessionStorage] of a page, see {!Page.local_storage}. It always is the storage of the
    origin that the page shows at the time of the call. *)
module WebStorage : sig
    type t = web_storage

    val items : t -> (string * string) list
    val get_item : string -> t -> string option
    val set_item : string -> string -> t -> unit
    val remove_item : string -> t -> unit
    val clear : t -> unit
end

(** The video recording of a page. The file is complete once the page has been closed. *)
module Video : sig
    type t = video

    val path : t -> string
    (** Where the video is, or will be, stored. *)

    val save_as : string -> t -> unit
    (** Waits for the page to close and copies the video to the given path. *)

    val delete : t -> unit
end

(** {1 Tools} *)

(** Recording {{:https://playwright.dev/docs/trace-viewer} traces} of what happens in a context, for
    [ocaml-playwright show-trace]. See {!BrowserContext.tracing}.

    {[
      let tracing = BrowserContext.tracing context in
      Tracing.start ~screenshots:true ~snapshots:true tracing;
      (* ... *)
      Tracing.stop ~path:"trace.zip" tracing
    ]} *)
module Tracing : sig
    type t = tracing

    val start : ?name:string -> ?title:string -> ?snapshots:bool -> ?screenshots:bool -> ?sources:bool -> ?live:bool -> t -> unit

    val stop : ?path:string -> t -> unit
    (** Stops tracing, and writes the trace to [path] if that is given. *)

    val start_chunk : ?name:string -> ?title:string -> t -> unit
    (** Starts a new part of the trace, after {!start}; each part can be saved to a file of its own. *)

    val stop_chunk : ?path:string -> t -> unit

    val group : string -> t -> unit
    (** Groups the following operations under a name in the trace viewer, until {!group_end}. *)

    val group_end : t -> unit

    val start_har : ?content:[ `Attach | `Embed | `Omit ] -> ?mode:[ `Full | `Minimal ] -> ?url_glob:string -> string -> t -> unit
    (** [start_har path] starts recording network activity into a HAR file, which {!stop_har} writes. *)

    val stop_har : t -> unit
end

(** Control over the time that the pages of a context see: [Date], [setTimeout], [requestAnimationFrame] and the
    like. Points in time are in milliseconds since the Unix epoch, durations in milliseconds. *)
module Clock : sig
    val install : ?time:float -> browser_context -> unit
    (** Replaces the native clock with a fake one, optionally set to [time]. Required before the functions that move
        the clock: {!fast_forward}, {!run_for}, {!pause_at} and {!resume}. *)

    val fast_forward : float -> browser_context -> unit
    (** Jumps ahead, firing due timers at most once, as when a laptop is opened again after a while. *)

    val run_for : float -> browser_context -> unit
    (** Advances the clock, firing all timers that become due on the way. *)

    val pause_at : float -> browser_context -> unit
    val resume : browser_context -> unit

    val set_fixed_time : float -> browser_context -> unit
    (** Makes [Date.now] return this time forever, while timers keep running. *)

    val set_system_time : float -> browser_context -> unit
end

(** The response to a request made with {!APIRequestContext}. *)
module APIResponse : sig
    type t = api_response

    val url : t -> string
    val status : t -> int
    val status_text : t -> string
    val ok : t -> bool
    val headers : t -> (string * string) list
    val headers_array : t -> (string * string) list
    val header_value : string -> t -> string option
    val body : t -> string
    val text : t -> string
    val json : t -> Yojson.Safe.t

    val dispose : t -> unit
    (** Frees the body, which the driver otherwise keeps until the request context is disposed of. *)
end

(** Sending HTTP requests without a page, for instance to prepare the state of a server or to check on it. Requests
    made with {!BrowserContext.request} share the cookies of that browser context, in both directions. *)
module APIRequestContext : sig
    type t = api_request_context

    type multipart_value = [ `Text of string | `File of file_payload ]

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
    (** [params] are added to the query string. The body is one of: [data] as it is, [json] serialised with the
        content type [application/json], [form] encoded as [application/x-www-form-urlencoded], or [multipart]
        encoded as [multipart/form-data]. With [fail_on_status_code], a status outside of 200-399 is an error. *)

    val get : (string -> t -> api_response) with_request_options
    val post : (string -> t -> api_response) with_request_options
    val put : (string -> t -> api_response) with_request_options
    val patch : (string -> t -> api_response) with_request_options
    val delete : (string -> t -> api_response) with_request_options
    val head : (string -> t -> api_response) with_request_options

    val fetch : ?method_:string -> (string -> t -> api_response) with_request_options
    (** A request with any method, [GET] by default. *)

    val storage_state : ?path:string -> ?indexed_db:bool -> t -> Yojson.Safe.t

    val cookies : ?urls:string list -> t -> Cookie.t list
    (** The cookies that the context holds and sends, which for {!BrowserContext.request} and {!Page.request} are
        those of the browser context. *)

    val add_cookies : Cookie.init list -> t -> unit
    val clear_cookies : ?name:string -> ?domain:string -> ?path:string -> t -> unit

    val dispose : ?reason:string -> t -> unit
    (** Frees the context and all responses that it holds. Only for contexts made with {!APIRequest.new_context}. *)
end

module APIRequest : sig
    val new_context :
        ?base_url:string -> ?user_agent:string -> ?ignore_https_errors:bool -> ?extra_http_headers:(string * string) list ->
        ?fail_on_status_code:bool -> ?max_redirects:int -> ?http_credentials:Http_credentials.t -> ?proxy:Proxy.t ->
        ?storage_state:Yojson.Safe.t -> ?timeout:float -> t -> api_request_context
    (** Creates a request context that is independent of any browser. [timeout] is the default timeout of its
        requests. *)
end

(** A raw {{:https://chromedevtools.github.io/devtools-protocol/} Chrome DevTools Protocol} session. Chromium only.
    See {!BrowserContext.new_cdp_session}.

    {[
      let session = BrowserContext.new_cdp_session page context in
      ignore (CDPSession.send "Network.enable" session);
      CDPSession.send "Network.emulateNetworkConditions" session
          ~params:(`Assoc [ "offline", `Bool true; "latency", `Int 0; "downloadThroughput", `Int 0; "uploadThroughput", `Int 0 ])
      |> ignore
    ]} *)
module CDPSession : sig
    type t = cdp_session

    val send : ?params:Yojson.Safe.t -> string -> t -> Yojson.Safe.t
    (** [send method_] calls a method of the protocol and returns its result. *)

    val on_event : (string -> Yojson.Safe.t -> unit) -> t -> unit
    (** Registers a listener for the events of the session; it is given the name and the parameters of each. *)

    val off_event : (string -> Yojson.Safe.t -> unit) -> t -> unit
    val on_close : (t -> unit) -> t -> unit
    val detach : t -> unit
end

(** Custom selector engines and the attribute used by [get_by_test_id]. The settings apply to all browser contexts
    of the driver, those that exist already included. *)
module Selectors : sig
    val register : ?content_script:bool -> ?path:string -> ?script:string -> string -> t -> unit
    (** [register name] registers a {{:https://playwright.dev/docs/extensibility#custom-selector-engines} selector
        engine}, given as the source text of a script or as a file, for selectors of the form [name=...]. *)

    val set_test_id_attribute : string -> t -> unit
end
