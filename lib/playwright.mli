(** Browser automation with {{:https://playwright.dev} Playwright}.

    This library drives Chromium, Firefox and WebKit through the Playwright driver, which it talks to over
    Playwright's own client protocol. It follows the official Playwright API: a class is a module, a method is a
    function, and what the {{:https://playwright.dev/docs/api/class-playwright} upstream documentation} says about
    a method holds for the function of the same name, read with the conventions below. Where a function
    deliberately behaves differently, its documentation here says so. The file [doc/parity.md] that comes with the
    sources lists these differences, and the parts of Playwright that this library does not cover.

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

    {2 Names and arguments}

    - Every Playwright class is a module with the same name ([Page], [BrowserContext], [Locator], ...), its objects
      are of the type [t] of that module ([Page.t]), and its methods are functions in [snake_case]. A name that is an
      OCaml keyword gets a trailing underscore ([type_], [method_]).
    - The object a function operates on comes {e last}, so calls compose with [|>]. Required arguments are
      positional and precede it; everything optional is an optional labelled argument. Where two required
      arguments of the same type follow each other, a label tells them apart:
      [Page.fill "#name" ~value:"Ada" page], [Mouse.move ~x:10. ~y:20. mouse].
    - Timeouts and other durations are in milliseconds, as in Playwright. A timeout of [0.] disables the timeout.
    - JavaScript regular expressions are given as literals in a string, such as ["/sign (in|up)/i"], to the
      functions and arguments named [..._regex].
    - URL patterns are {{:https://playwright.dev/docs/network#glob-url-patterns} glob patterns}: [*] stands for
      any characters but [/], [**] for any characters, [{a,b}] for either, and a backslash makes the next character
      literal. A pattern that does not start with [*] is resolved against the base URL of the context. Braces that
      are nested or not balanced are an {!exception-Error} where the pattern is given. Functions named
      [..._matching] take an OCaml predicate on the URL instead.
    - The library opens no files. Images, documents and the state of a context are returned, and scripts and
      certificates are passed, as values; reading and writing them is left to the program. Paths are given only for
      what the driver itself reads or writes: uploads, downloads, videos, traces, profile directories.

    {2 Calls, failures and cancellation}

    - All functions block the calling fiber until the browser has answered, and other fibers run meanwhile. Run
      them in separate {{:https://github.com/ocaml-multicore/eio} Eio} fibers to work with several pages
      concurrently; any number of fibers may use the same object. A driver and its objects are used from the
      domain that started the driver, and no other.
    - Failures are reported with the exception {!exception-Error}; [Invalid_argument] is reserved for misuse of the
      API that no browser needs to be asked about.
    - Cancelling a fiber cancels the call it is blocked in, and the driver is told to give the operation up.
      [Eio.Time.with_timeout] thus puts a limit on anything. What a cancelled call was creating — a page, a
      context, a browser — is closed as soon as it exists.
    - The functions that release something ([close], [dispose], [detach], {!Disposable.dispose}) carry it out even
      when the fiber that calls them is cancelled, which makes them safe to use in [Fun.protect ~finally] and
      [Eio.Switch.on_release]. They do nothing for what is gone already, and when several fibers close the same
      object, all of them wait for the one close.
    - When the driver is closed, and when it dies, calls that are under way fail with a [Target_closed] error and
      every object reports that it is closed: the [Close] and disconnection listeners are called, and [is_closed]
      is true.

    {2 Events and handlers}

    - Events are values of a GADT, which gives every event its payload type:
      [Page.on Page.Console (fun message -> ...) page].
    - What registers something for later — an event listener, a route, an init script, an exposed function —
      returns a {!Disposable.t} to take it back with. [ignore] it when the registration is to last as long as its
      page.
    - Every call of a handler — an event listener, a route handler, an exposed function — runs in a fiber of its
      own, so a handler may block and may call any function of this library. The calls start in the order of the
      events. An exception that escapes from a listener or a route handler is passed to the [on_error] function
      of {!create} and does not stop the program; one that escapes from an exposed function rejects the promise
      that the page got. Handlers that are still running when the driver is closed are cancelled. {!create} also
      tells how many calls may be in progress at a time.

    {2 Identity}

    - Pages, frames, requests and the other objects have identity. Each of their modules has [equal], [compare] and
      [hash], see {!Identity}, which also makes it an argument for [Set.Make], [Map.Make] and [Hashtbl.Make]. The
      polymorphic [=], [compare] and [Hashtbl.hash] must not be used on objects: they look into values that are
      none of their business, and may fail or not return. *)

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

type aria_role =
    [ `Alert | `Alertdialog | `Application | `Article | `Banner | `Blockquote | `Button | `Caption | `Cell | `Checkbox | `Code
    | `Columnheader | `Combobox | `Complementary | `Contentinfo | `Definition | `Deletion | `Dialog | `Directory | `Document
    | `Emphasis | `Feed | `Figure | `Form | `Generic | `Grid | `Gridcell | `Group | `Heading | `Img | `Insertion | `Link | `List
    | `Listbox | `Listitem | `Log | `Main | `Marquee | `Math | `Menu | `Menubar | `Menuitem | `Menuitemcheckbox
    | `Menuitemradio | `Meter | `Navigation | `None | `Note | `Option | `Paragraph | `Presentation | `Progressbar | `Radio
    | `Radiogroup | `Region | `Row | `Rowgroup | `Rowheader | `Scrollbar | `Search | `Searchbox | `Separator | `Slider
    | `Spinbutton | `Status | `Strong | `Subscript | `Superscript | `Switch | `Tab | `Table | `Tablist | `Tabpanel | `Term
    | `Textbox | `Time | `Timer | `Toolbar | `Tooltip | `Tree | `Treegrid | `Treeitem ]

(** What a registration returns: {!Page.on}, {!Page.route}, {!Page.add_init_script}, {!Page.expose_function} and
    their like each give one of these, to take the registration back with.

    {[
      let listener = Page.on Page.Console (fun message -> print_endline (ConsoleMessage.text message)) page in
      Page.evaluate "console.log('heard')" page |> ignore;
      Disposable.dispose listener;
      Page.evaluate "console.log('not heard')" page |> ignore
    ]}

    A registration that is to last as long as its page is never taken back: [ignore] what it returned. *)
module Disposable : sig
    type t

    val dispose : t -> unit
    (** Takes the registration back: the listener is not called again, the route no longer intercepts, the script
        is not added to further documents, the function is no longer exposed. Does nothing once that is done, and
        nothing for what has gone away with its page or context. A listener is removed on the spot. For the
        others the driver is asked: fibers that ask at the same time wait for the one answer, and if the driver
        fails to do it, the error is raised and [dispose] can be called again. *)
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

(** A position on Earth for a context to report, see {!BrowserContext.set_geolocation}. *)
module Geolocation : sig
    type t = { latitude : float; longitude : float; accuracy : float option }

    val make : ?accuracy:float -> latitude:float -> longitude:float -> unit -> t
end

(** A user name and a password for HTTP authentication. *)
module Http_credentials : sig
    type t = { username : string; password : string; origin : string option; send : [ `Always | `Unauthorized ] option }

    val make : ?origin:string -> ?send:[ `Always | `Unauthorized ] -> username:string -> password:string -> unit -> t
    (** [origin] restricts the credentials to one origin, e.g. ["https://example.com:8443"]; contexts take a list of
        credentials, for one origin each or for all of them. [send] matters to {!APIRequestContext} only, whose
        requests carry the credentials from the start with [`Always], and by default, [`Unauthorized], only once a
        server has answered 401. *)
end

(** A TLS client certificate, for a context or a request context to present to the servers of one origin. *)
module Client_certificate : sig
    type t

    val pem : ?passphrase:string -> origin:string -> cert:string -> key:string -> unit -> t
    (** A certificate and its private key in PEM format, each given as what its file holds, for the servers of
        [origin], which has to match exactly, e.g. ["https://example.com:8443"]. [passphrase] is what the key is
        encrypted with. *)

    val pfx : ?passphrase:string -> origin:string -> string -> t
    (** A private key with its certificate chain in PFX, also known as PKCS #12, format: the bytes of such a file. *)
end

(** A proxy server for a browser, a context or a request context to go through. *)
module Proxy : sig
    type t = { server : string; bypass : string option; username : string option; password : string option }

    val make : ?bypass:string -> ?username:string -> ?password:string -> string -> t
    (** [make server] with a server such as ["http://proxy.example:3128"] or ["socks5://127.0.0.1:1080"]. [bypass] is
        a comma-separated list of domains to reach directly. *)
end

(** Cookies, as a context holds them and as they are given to it. *)
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
        ?partition_key:string -> string -> value:string -> init
    (** [make name ~value]. Either [url], or both [domain] and [path] are required. *)

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
(** The options of a browser context, see
    {{:https://playwright.dev/docs/api/class-browser#browser-new-context} [browser.newContext]}.

    - [device] emulates a device, see {!val-device}; the options given explicitly take precedence over it.
    - [viewport] is [(width, height)], 1280×720 by default; [no_viewport] makes the page follow the window size.
    - [base_url] is what relative URLs given to {!Page.goto}, {!Page.route} and the like are resolved against.
    - [record_video_dir] turns video recording on, see {!Video}.
    - [storage_state] restores cookies and local storage saved with {!BrowserContext.storage_state}.
    - [client_certificates] are what the context has to show to the servers of their origins that ask for a
      certificate. *)

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
(** The options for starting a browser, see
    {{:https://playwright.dev/docs/api/class-browsertype#browser-type-launch} [browserType.launch]}.

    - [headless] defaults to [true].
    - [executable_path] runs a browser that Playwright did not install; [channel] selects a branded one such as
      ["chrome"] or ["msedge"].
    - [timeout] is the time the browser has to start, 180 seconds by default.
    - [artifacts_dir] is where traces, videos and downloads are kept while the browser runs. Unlike the
      temporary directory that is used by default, it is not removed when the browser is closed.
    - [slow_mo] delays every operation by that many milliseconds. *)

(** {1 Playwright}

    Everything starts with a running driver, a value of type {!t}. Browsers are launched from one of its three
    engines, {!chromium}, {!firefox} and {!webkit}; these and the other things that a driver gives access to are
    declared {{!section-roots} after the objects} that they return. *)

type t
(** A running Playwright driver and everything that was created through it. *)

val create :
    ?on_error:(string -> exn -> unit) ->
    ?handler_concurrency:int ->
    ?handler_backlog:int ->
    sw:Eio.Switch.t ->
    env:Eio_unix.Stdenv.base ->
    unit ->
    t
(** Starts the Playwright driver. It is stopped, and all its browsers are closed, by {!close} or when [sw] finishes.

    The driver is the [playwright-core] package for Node.js in the version this library was built for, {!version}.
    It is downloaded from the npm registry on first use and cached in the user's cache directory; [node] has to be
    installed. Both can be overridden with environment variables, see the user guide. Browsers are installed with
    [ocaml-playwright install], or an installed one is used through [executable_path] or [channel].

    Other fibers run while the driver is downloaded and started. The call can be cancelled at any time, which
    also ends a download; [Eio.Time.with_timeout] thus limits how long starting may take. A download is given up
    after five minutes, or what [PLAYWRIGHT_OCAML_DRIVER_INSTALL_TIMEOUT] says.

    [on_error what exn] is called for exceptions that have no caller to be raised in, namely those escaping from
    event listeners and route handlers; [what] says where [exn] comes from. The default prints them to standard
    error. The function is called in a handler of [exn], so [Printexc.get_raw_backtrace ()] is its backtrace. It
    runs in the fiber where the failure was noticed, which goes on once the function returns, so it should not
    take long. It should not raise: an exception that escapes from it is printed to standard error together with
    the one it was called for, and otherwise ignored.

    [handler_concurrency] and [handler_backlog] bound what events may cost. Every call of a handler (an event
    listener, a route handler, an exposed function) runs in a fiber of its own, and events arrive at the pace of the
    browser, not of the handlers: a page that logs ten thousand lines calls a console listener ten thousand times
    before the first of those calls can get an answer from the driver. At most [handler_concurrency] calls (1024 by
    default) are in progress at a time; the others wait for their turn, in the order of their events. When more than
    [handler_backlog] calls (65536 by default) are waiting, handlers are not keeping up or not returning, and the
    instance is given up rather than the memory: its connection is closed with an error that says so, which is also
    passed to [on_error].

    Setting the environment variable [DEBUG=pw:channel] logs the protocol messages to standard error.

    Raises [Invalid_argument] if [handler_concurrency] is less than 1 or [handler_backlog] is negative. *)

val close : t -> unit
(** Closes all browsers and stops the driver, and returns when the driver has exited. Calls that are still running
    fail with a [Target_closed] error, the listeners for [Close] and disconnection of every object are called,
    and handlers that are still running are cancelled. Does nothing when already closed.

    A handler may close the driver it is called by; being a handler, it is cancelled at that point. *)

val run :
    ?on_error:(string -> exn -> unit) -> ?handler_concurrency:int -> ?handler_backlog:int -> env:Eio_unix.Stdenv.base -> (t -> 'a) -> 'a
(** [run ~env f] calls [f] with a new driver, which it stops once [f] returns or raises. The optional arguments are
    those of {!create}. *)

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

(** What makes two values the same object. The module of every kind of object includes this signature, so that
    objects can be compared, collected in sets and used as keys:
    {[
      let module Pages = Set.Make (Page) in
      let seen = ref Pages.empty in
      BrowserContext.on BrowserContext.Page (fun page -> seen := Pages.add page !seen) context
    ]} *)
module type Identity = sig
    type t

    val equal : t -> t -> bool
    (** Whether the two are the same object in the browser: the same page, the same request. Two locators are the
        same when they look for the same thing in the same frame. *)

    val compare : t -> t -> int
    (** A total order that agrees with {!equal}. It is otherwise arbitrary, and holds for one run of the program. *)

    val hash : t -> int
end

(** Finding elements the way users and assistive technology perceive them. These functions are provided by {!Page},
    {!Frame}, {!Locator} and {!FrameLocator}; see {{:https://playwright.dev/docs/locators} Locators}.

    The [..._regex] variants take a JavaScript regular expression literal such as ["/^total: \\d+$/i"]. *)
module type Locator_queries = sig
    type t

    type locator
    (** Stands for {!Locator.t}, which is declared further down. *)

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

    (** The following types stand for {!Js.t}, {!JSHandle.t}, {!ElementHandle.t} and {!Response.t}, which are declared
        further down. *)

    type js_value
    type js_handle
    type element_handle
    type response

    (** {2 Navigation} *)

    val goto : ?timeout:float -> ?wait_until:lifecycle_event -> ?referer:string -> string -> t -> response option
    (** Navigates to the URL and waits for the navigation to get as far as [wait_until]. Returns the response of the
        main resource, the last one in case of redirects, or [None] for navigations that have none such as to
        [about:blank] or to a different anchor of the same document. HTTP error statuses are not failures. *)

    val set_content : ?timeout:float -> ?wait_until:lifecycle_event -> string -> t -> unit
    (** Replaces the document with the given HTML. *)

    val content : ?include_shadow:bool -> t -> string
    (** The HTML of the document, including the doctype. [include_shadow] adds the contents of open shadow roots, as
        [<template shadowrootmode="open">] elements within their hosts. *)

    val title : t -> string
    val wait_for_load_state : ?timeout:float -> ?state:lifecycle_event -> t -> unit

    val wait_for_url : ?timeout:float -> ?wait_until:lifecycle_event -> string -> t -> unit
    (** Waits until the frame has navigated to a URL matching the glob pattern. Returns at once if it is there already. *)

    val wait_for_url_matching : ?timeout:float -> ?wait_until:lifecycle_event -> (string -> bool) -> t -> unit

    val expect_navigation :
        ?timeout:float -> ?wait_until:lifecycle_event -> ?url:string -> ?url_matching:(string -> bool) -> (unit -> unit) -> t -> response option
    (** Runs the action and waits for the navigation that it causes: the next one, or the next one to a URL that
        matches the glob pattern [url] and satisfies [url_matching], as far as they are given. *)

    val wait_for_timeout : float -> t -> unit
    (** Sleeps. Meant for debugging: waiting for a fixed time makes automation slow and flaky. *)

    (** {2 Evaluating JavaScript} *)

    val evaluate : ?arg:js_value -> string -> t -> js_value
    (** [evaluate expression] evaluates a JavaScript expression in the frame and returns its value; a promise is
        awaited first. If the expression evaluates to a function, that function is called with [arg].

        {[
          let title = Page.evaluate "document.title" page |> Js.to_string in
          let sum = Page.evaluate "([a, b]) => a + b" ~arg:(Js.list Js.int [ 1; 2 ]) page |> Js.to_int in
          Printf.printf "%s: %d\n" title sum
        ]} *)

    val evaluate_handle : ?arg:js_value -> string -> t -> js_handle
    (** Like {!evaluate}, but returns a handle to the resulting object instead of a copy of it. *)

    val wait_for_function : ?timeout:float -> ?polling:float -> ?arg:js_value -> string -> t -> js_handle
    (** Waits until the expression evaluates to a truthy value, and returns that. It is evaluated on every animation
        frame, or every [polling] milliseconds. *)

    val add_script_tag : ?type_:string -> [ `Content of string | `Url of string ] -> t -> element_handle
    (** Adds a [<script>] element to the document, with the content or for the URL, and returns it once the script
        has run. [type_] is its [type] attribute, ["module"] for instance. *)

    val add_style_tag : [ `Content of string | `Url of string ] -> t -> element_handle
    (** Adds a [<style>] element with the content, or a [<link rel="stylesheet">] to the URL. *)

    (** {2 Operations by selector} *)

    val query_selector : ?strict:bool -> string -> t -> element_handle option
    val query_selector_all : string -> t -> element_handle list

    val wait_for_selector : ?timeout:float -> ?strict:bool -> ?state:element_state -> string -> t -> element_handle option
    (** Waits for an element to reach [state], [`Visible] by default. [None] when waiting for [`Hidden] or [`Detached]. *)

    val eval_on_selector : ?strict:bool -> ?arg:js_value -> string -> expression:string -> t -> js_value
    (** [eval_on_selector selector expression] calls the function that [expression] evaluates to with the element. *)

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
    (** [fill selector value]. *)

    val focus : ?timeout:float -> ?strict:bool -> string -> t -> unit
    val blur : ?timeout:float -> ?strict:bool -> string -> t -> unit

    val press : ?timeout:float -> ?strict:bool -> ?delay:float -> ?no_wait_after:bool -> string -> key:string -> t -> unit
    (** [press selector key]. *)

    val type_ : ?timeout:float -> ?strict:bool -> ?delay:float -> string -> text:string -> t -> unit
    (** [type_ selector text]. *)

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
    (** [get_attribute selector name]. *)

    val input_value : ?timeout:float -> ?strict:bool -> string -> t -> string
    val is_checked : ?timeout:float -> ?strict:bool -> string -> t -> bool
    val is_disabled : ?timeout:float -> ?strict:bool -> string -> t -> bool
    val is_editable : ?timeout:float -> ?strict:bool -> string -> t -> bool
    val is_enabled : ?timeout:float -> ?strict:bool -> string -> t -> bool
    val is_hidden : ?strict:bool -> string -> t -> bool
    val is_visible : ?strict:bool -> string -> t -> bool
end

(** {1 JavaScript values}

    From here to {!CDPSession}, the modules are declared as one recursive group, [module rec ... and ...], for the
    only reason that their types refer to one another. *)

(** JavaScript values, as they are passed to and returned from code evaluated in a page.

    Unlike JSON this covers everything that Playwright can transfer: [undefined], [NaN] and the infinities, dates,
    big integers, regular expressions, errors, typed arrays and, in arguments, handles to objects living in the page.

    A value is a tree. An object that occurs at several places of a result is repeated at each of them, and a
    structure that contains itself is cut off with [Undefined] at the place where it comes round. *)
module rec Js : sig
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
        | Handle of JSHandle.t  (** Only in arguments: the object that the handle refers to. *)

    (** {2 Constructing} *)

    val undefined : t
    val null : t
    val bool : bool -> t
    val int : int -> t
    (** A [Number]. Raises [Invalid_argument] for an integer beyond ±(2{^53} - 1), which a JavaScript number would
        round: such a one is either a [Bigint] or, knowingly, a {!float}. *)

    val float : float -> t
    val string : string -> t
    val list : ('a -> t) -> 'a list -> t
    val obj : (string * t) list -> t

    val option : ('a -> t) -> 'a option -> t
    (** [None] becomes [Null]. *)

    val of_json : Yojson.Safe.t -> t
    (** Integers become [Number]s, and [Bigint]s when they are beyond ±(2{^53} - 1). *)

    (** {2 Inspecting}

        The [to_...] functions raise {!exception-Error} when the value is of another kind. *)

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
    (** The value as JSON. For what JSON has a notion of, this is what [JSON.stringify] gives: [Undefined] becomes
        [`Null] in an array and is left out of an object, numbers that are not finite become [`Null], dates and
        URLs become strings; integral numbers become [`Int]. The rest is rendered rather than lost: a bigint becomes
        an [`Intlit], a regular expression the string ["/source/flags"], an error an object of its [name], [message]
        and [stack], and a typed array its bytes in Base64. Fails for a value with a [Handle] in it. *)

    val show : t -> string
    (** A JavaScript-like rendering, for messages and debugging. *)

    val pp : Format.formatter -> t -> unit
end

(** {1 Browsers} *)

(** A kind of browser: Chromium, Firefox or WebKit. Obtained from {!chromium}, {!firefox} and {!webkit}. *)
and BrowserType : sig
    type t

    val name : t -> string
    (** ["chromium"], ["firefox"] or ["webkit"]. *)

    val executable_path : t -> string
    (** Where Playwright expects to find the browser that it installs. *)

    val launch : (t -> Browser.t) with_launch_options
    (** Starts a browser.

        {[
          BrowserType.launch ~headless:false ~args:[ "--start-maximized" ] (Playwright.chromium pw)
        ]} *)

    val launch_persistent_context : (string -> (t -> BrowserContext.t) with_context_options) with_launch_options
    (** [launch_persistent_context user_data_dir] starts a browser that keeps its profile in the given directory, and
        returns its only context. An empty string stands for a temporary directory. Closing the context closes the
        browser. *)

    val connect_over_cdp :
        ?timeout:float -> ?headers:(string * string) list -> ?slow_mo:float -> ?is_local:bool -> ?no_defaults:bool -> ?artifacts_dir:string -> string ->
        t -> Browser.t
    (** [connect_over_cdp endpoint] attaches to a running Chromium-based browser through the Chrome DevTools Protocol,
        given an HTTP endpoint such as ["http://localhost:9222"] or a WebSocket URL. The contexts and pages that are
        open already are available from {!Browser.contexts}.

        - [is_local] tells that the browser runs on the machine of the driver, and so shares its file system, which
          makes some operations cheaper.
        - [no_defaults] leaves the default context of the browser as it is: downloads, fonts, focus and media
          emulation keep the settings of the browser. This suits a browser that a person is using.
        - [artifacts_dir] is where traces and downloads are kept. *)

    include Identity with type t := t
end

(** A running browser. *)
and Browser : sig
    type t

    val new_context : ?proxy:Proxy.t -> (t -> BrowserContext.t) with_context_options
    (** Creates an isolated browser context, comparable to a fresh incognito profile. *)

    val new_page : ?proxy:Proxy.t -> (t -> Page.t) with_context_options
    (** Creates a page in a new context of its own, which is closed together with the page. *)

    val contexts : t -> BrowserContext.t list
    val browser_type : t -> BrowserType.t

    val version : t -> string
    (** The version of the browser. *)

    val name : t -> string
    val is_connected : t -> bool

    val on_disconnected : (t -> unit) -> t -> Disposable.t
    (** Registers a function to call when the browser has been closed, has crashed or the connection to it was lost. *)

    val on_context : (BrowserContext.t -> unit) -> t -> Disposable.t
    (** Registers a function to call with each context that is created in the browser from now on, including the
        one that {!new_page} creates. It may be called before the function that created the context has returned. *)

    val new_browser_cdp_session : t -> CDPSession.t
    (** A Chrome DevTools Protocol session with the browser itself. Chromium only. *)

    val close : ?reason:string -> t -> unit
    (** Closes the browser with all its contexts and pages; for a browser that was connected to, disconnects from it.
        [reason] is reported by the operations that this interrupts. Does nothing if the browser is gone already.

        The browser is closed even if the calling fiber is cancelled meanwhile. Fibers that close the same browser at
        the same time all wait for it to be closed, and a close that failed can be tried again. *)

    include Identity with type t := t
end

(** An isolated browser session: pages of the same context share cookies, storage, permissions and settings, and
    those of different contexts do not. *)
and BrowserContext : sig
    type t

    val new_page : t -> Page.t
    val pages : t -> Page.t list

    val browser : t -> Browser.t option
    (** [None] for a persistent context. *)

    val close : ?reason:string -> t -> unit
    (** Closes the context and its pages. This is also when recorded videos are written. Does nothing if
        the context is closed already. {!Browser.close} tells what happens on cancellation and when fibers close the
        same context concurrently. *)

    val is_closed : t -> bool
    (** Whether the context has been closed, or is being closed. *)

    val set_default_timeout : float -> t -> unit

    val set_default_navigation_timeout : float -> t -> unit
    (** Takes precedence over {!set_default_timeout} for navigations. *)

    (** {1 Events} *)

    type _ event =
        | Close : t event
        | Console : ConsoleMessage.t event
        | Dialog : Dialog.t event  (** See {!Page.Dialog}. *)
        | Dialog_closed : Dialog.t event
        | Download : Download.t event
        | Frame_attached : Frame.t event
        | Frame_detached : Frame.t event
        | Frame_navigated : Frame.t event
        | Page : Page.t event  (** A page was created in the context, by {!new_page} or as a popup. *)
        | Page_close : Page.t event
        | Page_load : Page.t event  (** The [load] event of a page: see {!Page.Load}. *)
        | Request : Request.t event
        | Request_failed : Request.t event
        | Request_finished : Request.t event
        | Response : Response.t event
        | Service_worker : Worker.t event
        | Web_error : WebError.t event  (** An exception was not handled in one of the pages. *)
    (** What happens in a page of the context is reported both to the listeners of the page and to those of the
        context. *)

    val on : 'a event -> ('a -> unit) -> t -> Disposable.t
    (** Registers a listener, which {!Disposable.dispose} removes again. Each call of a listener runs in a fiber of
        its own, so a listener may block and may call back into Playwright; events are nevertheless delivered to it
        in order of arrival when it does not. A listener that has been removed is not called any more, not even for
        events that arrived before it was removed.

        An exception that escapes from a listener is passed to the [on_error] function of {!create}. {!create} also
        tells how many calls of listeners may be in progress at a time, and what happens beyond that. *)

    val once : 'a event -> ('a -> unit) -> t -> Disposable.t
    (** Registers a listener for the next event only. *)

    val expect_event : ?timeout:float -> ?predicate:('a -> bool) -> 'a event -> (unit -> unit) -> t -> 'a
    (** [expect_event event action] starts listening, runs [action], and returns the first [event] satisfying
        [predicate] that occurs from then on. Listening first means that an event emitted before the action returns
        is not missed. To wait for an event that something else causes, pass [ignore] as the action.

        - [timeout] counts from before the action, and it limits when the event may {e arrive}: one that arrived in
          time is returned however long [action] and [predicate] take, and without one a [Timeout] error is raised
          once [action] has returned. The default is the timeout of the context, see {!set_default_timeout}.
        - [action] is not interrupted when the time is up, and when it raises, its exception is the one that
          [expect_event] raises.
        - [predicate] is called for each event when it arrives, also while [action] is still running, for one event
          at a time, until it returns [true]. It may block and may call back into Playwright. An exception that
          escapes from it is raised by [expect_event].
        - The wait ends with a [Target_closed] error when the object that would emit the event is closed.

        The other [expect_...] functions of this library follow the same rules. *)

    (** {1 Network} *)

    val route : ?times:int -> string -> (Route.t -> unit) -> t -> Disposable.t
    (** [route glob handler] intercepts the requests of all pages of the context whose URL matches the glob pattern.
        The handler has to {!Route.fulfill}, {!Route.continue}, {!Route.fallback} or {!Route.abort} each of them.
        Handlers registered later take precedence, and those of a page take precedence over those of its context.
        With [times], the handler is used for that many requests only.

        A handler that raises before it has settled its route fails the request, as {!Route.abort} does, and the
        exception is passed to the [on_error] of {!Playwright.create}. *)

    val route_matching : ?times:int -> (string -> bool) -> (Route.t -> unit) -> t -> Disposable.t

    val unroute_all : ?behavior:[ `Default | `Wait | `Ignore_errors ] -> t -> unit
    (** Removes all handlers; {!Disposable.dispose} removes a single one. [behavior] says what becomes of the handlers
        that are at work at that moment: by default they finish like any other; with [`Wait] the function returns
        once they have finished, so it must not be called from a route handler; and with [`Ignore_errors] what
        they raise from now on is dropped, their requests going on to the network. *)


    val route_web_socket : string -> (WebSocketRoute.t -> unit) -> t -> Disposable.t
    (** Intercepts the WebSocket connections that pages open to matching URLs, see {!WebSocketRoute}. *)

    val route_web_socket_matching : (string -> bool) -> (WebSocketRoute.t -> unit) -> t -> Disposable.t
    val set_extra_http_headers : (string * string) list -> t -> unit
    val set_offline : bool -> t -> unit

    val request : t -> APIRequestContext.t
    (** For sending HTTP requests that share the cookies of the context. *)

    (** {1 State} *)

    val cookies : ?urls:string list -> t -> Cookie.t list
    val add_cookies : Cookie.init list -> t -> unit
    val clear_cookies : ?name:string -> ?domain:string -> ?path:string -> t -> unit

    val storage_state : ?indexed_db:bool -> ?opfs:bool -> ?credentials:bool -> t -> Yojson.Safe.t
    (** The cookies and the local storage of the context, for the [storage_state] option of a later context: a JSON
        value, which [Yojson.Safe.to_file] saves and [Yojson.Safe.from_file] reads. [indexed_db] and [opfs] add the IndexedDB databases and the
        origin private file systems of the pages, and [credentials] the passkeys of the context's virtual WebAuthn
        authenticator, private keys included. *)

    val set_storage_state : Yojson.Safe.t -> t -> unit
    (** Replaces the cookies and the local storage of the context by those of a state that {!storage_state}
        returned. *)

    val grant_permissions : ?origin:string -> string list -> t -> unit
    val clear_permissions : t -> unit
    val set_geolocation : Geolocation.t option -> t -> unit

    (** {1 Scripting} *)

    val add_init_script : string -> t -> Disposable.t
    (** Evaluates JavaScript in every page and frame of the context before any of the page's own scripts run. *)

    val expose_function : string -> (Js.t list -> Js.t) -> t -> Disposable.t
    (** [expose_function name f] makes [f] available to all pages as [window.name]. Calling it in the page returns a
        promise of the result of [f]; if [f] raises, the promise is rejected. *)

    type binding_source = { context : t; page : Page.t; frame : Frame.t }
    (** Where a call of an exposed binding came from. *)

    val expose_binding : string -> (binding_source -> Js.t list -> Js.t) -> t -> Disposable.t
    (** Like {!expose_function}, for a function that also wants to know which page and frame called it. *)

    val service_workers : t -> Worker.t list
    val tracing : t -> Tracing.t

    val new_cdp_session : Page.t -> t -> CDPSession.t
    (** A Chrome DevTools Protocol session with a page. Chromium only. *)

    val new_cdp_session_for_frame : Frame.t -> t -> CDPSession.t

    include Identity with type t := t
end

(** {1 Pages} *)

(** A tab or a popup window. *)
and Page : sig
    type t

    (** {1 Locators} *)

    val locator :
        ?has_text:string -> ?has_text_regex:string -> ?has_not_text:string -> ?has_not_text_regex:string -> ?has:Locator.t -> ?has_not:Locator.t ->
        string -> t -> Locator.t
    (** The elements matching a {{:https://playwright.dev/docs/other-locators} selector}, CSS or XPath for instance,
        optionally filtered as by {!Locator.filter}. *)

    include Locator_queries with type t := t and type locator := Locator.t

    val get_by_ref : string -> t -> Locator.t
    (** The element with a reference such as ["e2"] or ["f1e3"] in the latest {!aria_snapshot} that was taken with
        [~mode:`Ai], where it reads [[ref=e2]]. This is how a program that is shown such a snapshot, a language
        model for instance, says which element it means. A reference holds until the next snapshot of the frame;
        {!Locator.normalize} gives a locator that lasts. *)

    val frame_locator : string -> t -> FrameLocator.t
    (** The content of the [<iframe>] that the selector matches. *)

    (** {1 Navigation, JavaScript and operations by selector} *)

    include
        Frame_operations
            with type t := t
             and type js_value := Js.t
             and type js_handle := JSHandle.t
             and type element_handle := ElementHandle.t
             and type response := Response.t

    val reload : ?timeout:float -> ?wait_until:lifecycle_event -> t -> Response.t option
    val go_back : ?timeout:float -> ?wait_until:lifecycle_event -> t -> Response.t option
    (** [None] if there is no previous page in the history. *)

    val go_forward : ?timeout:float -> ?wait_until:lifecycle_event -> t -> Response.t option
    val url : t -> string

    (** {1 The page} *)

    val context : t -> BrowserContext.t

    val opener : t -> t option
    (** The page that opened this popup, unless that is closed. *)

    val main_frame : t -> Frame.t
    val frames : t -> Frame.t list

    val frame : [ `Name of string | `Url of string ] -> t -> Frame.t option
    (** The frame with this [name] attribute, or the first one whose URL matches the glob pattern. *)

    val workers : t -> Worker.t list
    val keyboard : t -> Keyboard.t
    val mouse : t -> Mouse.t
    val touchscreen : t -> Touchscreen.t

    val request : t -> APIRequestContext.t
    (** The same as {!BrowserContext.request} of the page's context. *)

    val video : t -> Video.t option
    (** The video recording of the page, when the context was created with [record_video_dir]. *)

    val close : ?run_before_unload:bool -> ?reason:string -> t -> unit
    (** Closes the page. Does nothing if it is closed already. With [run_before_unload], the page's [beforeunload]
        handlers run first and may keep it open, and the function does not wait for the page to close.

        The page is closed even if the calling fiber is cancelled meanwhile. *)

    val is_closed : t -> bool
    val bring_to_front : t -> unit
    val set_default_timeout : float -> t -> unit
    val set_default_navigation_timeout : float -> t -> unit

    val pause : t -> unit
    (** Opens the Playwright Inspector and waits for the user to resume. For headed browsers. *)

    val pick_locator : t -> Locator.t
    (** Lets the person in front of a headed browser point at an element of the page, and returns a locator for the
        one they click on. It waits for as long as that takes; {!cancel_pick_locator}, called from another fiber,
        ends the picking. *)

    val cancel_pick_locator : t -> unit

    val hide_highlight : t -> unit
    (** Removes the marks that {!Locator.highlight} put on elements of the page. *)

    (** {1 Events} *)

    type _ event =
        | Close : t event
        | Console : ConsoleMessage.t event
        | Crash : t event
        | Dialog : Dialog.t event
              (** A JavaScript dialog opened. It must be accepted or dismissed, or the page stays blocked; dialogs
                  are dismissed automatically while there is no listener for this event. *)
        | Dialog_closed : Dialog.t event  (** A dialog was accepted or dismissed, by a listener or by the user. *)
        | Dom_content_loaded : t event
        | Download : Download.t event
        | File_chooser : FileChooser.t event
        | Frame_attached : Frame.t event
        | Frame_detached : Frame.t event
        | Frame_navigated : Frame.t event
        | Load : t event
        | Page_error : Error.t event  (** An exception was not handled in the page. *)
        | Popup : t event
        | Request : Request.t event
        | Request_failed : Request.t event
        | Request_finished : Request.t event
        | Response : Response.t event
        | Web_socket : WebSocket.t event
        | Worker : Worker.t event

    val on : 'a event -> ('a -> unit) -> t -> Disposable.t
    (** See {!BrowserContext.on}. *)

    val once : 'a event -> ('a -> unit) -> t -> Disposable.t

    val expect_event : ?timeout:float -> ?predicate:('a -> bool) -> 'a event -> (unit -> unit) -> t -> 'a
    (** See {!BrowserContext.expect_event}.

        {[
          let download = Page.expect_event Page.Download (fun () -> Locator.click locator) page in
          Download.save_as "report.pdf" download
        ]} *)

    val expect_request : ?timeout:float -> ?url:string -> ?predicate:(Request.t -> bool) -> (unit -> unit) -> t -> Request.t
    (** Runs the action and returns the first request made from then on whose URL matches the glob pattern [url] and
        that satisfies [predicate]. *)

    val expect_response : ?timeout:float -> ?url:string -> ?predicate:(Response.t -> bool) -> (unit -> unit) -> t -> Response.t

    (** {1 Network} *)

    val route : ?times:int -> string -> (Route.t -> unit) -> t -> Disposable.t
    (** Intercepts the requests of this page, see {!BrowserContext.route}.

        {[
          let user = Page.route "**/api/user" (Route.fulfill ~json:(`Assoc [ "name", `String "Ada" ])) page in
          Page.route "**/*.{png,jpg}" Route.abort page |> ignore;
          Page.reload page |> ignore;
          Disposable.dispose user
        ]} *)

    val route_matching : ?times:int -> (string -> bool) -> (Route.t -> unit) -> t -> Disposable.t
    val unroute_all : ?behavior:[ `Default | `Wait | `Ignore_errors ] -> t -> unit

    val route_web_socket : string -> (WebSocketRoute.t -> unit) -> t -> Disposable.t
    val route_web_socket_matching : (string -> bool) -> (WebSocketRoute.t -> unit) -> t -> Disposable.t
    val set_extra_http_headers : (string * string) list -> t -> unit

    val requests : t -> Request.t list
    (** The most recent requests of the page, up to a limit set by the browser. *)

    (** {1 History}

        What happened in the page before anyone listened: the browser keeps the most recent console messages and
        uncaught errors of every page. *)

    val console_messages : ?filter:[ `All | `Since_navigation ] -> t -> ConsoleMessage.t list
    (** The console messages of the page so far, the oldest first; with [`Since_navigation] only those of the
        document that it shows now. *)

    val clear_console_messages : t -> unit

    val page_errors : ?filter:[ `All | `Since_navigation ] -> t -> Error.t list
    (** The exceptions that scripts of the page did not catch, as the [Page_error] event reports them. *)

    val clear_page_errors : t -> unit

    (** {1 Storage} *)

    val local_storage : t -> WebStorage.t
    (** The [localStorage] of the page for the origin that it shows, see {!WebStorage}. *)

    val session_storage : t -> WebStorage.t

    (** {1 Scripting} *)

    val add_init_script : string -> t -> Disposable.t
    val expose_function : string -> (Js.t list -> Js.t) -> t -> Disposable.t
    val expose_binding : string -> (BrowserContext.binding_source -> Js.t list -> Js.t) -> t -> Disposable.t

    val add_locator_handler : ?times:int -> ?no_wait_after:bool -> Locator.t -> (Locator.t -> unit) -> t -> unit
    (** [add_locator_handler locator handler] calls [handler] whenever an action is about to be performed while
        [locator] is visible, typically to dismiss an overlay that would be in the way. *)

    val remove_locator_handler : Locator.t -> t -> unit

    (** {1 Rendering} *)

    val screenshot :
        ?full_page:bool -> ?clip:rect ->
        ?timeout:float -> ?type_:[ `Png | `Jpeg | `Webp ] -> ?quality:int -> ?omit_background:bool ->
        ?caret:[ `Hide | `Initial ] -> ?animations:[ `Allow | `Disabled ] -> ?scale:[ `Css | `Device ] -> ?mask:Locator.t list ->
        ?mask_color:string -> ?style:string -> t -> string
    (** Takes a screenshot of the viewport, of the whole scrollable page with [full_page], or of the area [clip].
        Returns the image: the bytes of a file of [type_], PNG by default. [quality] is 0-100 and applies to JPEG and
        WebP only. The elements in [mask] are covered with
        boxes of [mask_color], and [style] is a style sheet that is applied while the screenshot is taken. *)

    val pdf :
        ?scale:float -> ?display_header_footer:bool -> ?header_template:string -> ?footer_template:string ->
        ?print_background:bool -> ?landscape:bool -> ?page_ranges:string -> ?format:string -> ?width:string -> ?height:string ->
        ?prefer_css_page_size:bool -> ?margin_top:string -> ?margin_right:string -> ?margin_bottom:string -> ?margin_left:string ->
        ?tagged:bool -> ?outline:bool -> t -> string
    (** Prints the page to PDF and returns the document: the bytes of a PDF file. Headless Chromium only. Lengths are strings with a unit,
        e.g. ["10mm"]. *)

    val aria_snapshot : ?timeout:float -> ?mode:[ `Ai | `Default ] -> ?depth:int -> ?boxes:bool -> t -> string
    (** The accessibility tree of the page as YAML, see {!Locator.aria_snapshot}. *)

    val aria_snapshot_json : ?timeout:float -> ?mode:[ `Ai | `Default ] -> ?depth:int -> ?boxes:bool -> t -> Yojson.Safe.t
    (** The same tree as JSON, see {!Locator.aria_snapshot_json}. *)

    val viewport_size : t -> (int * int) option
    val set_viewport_size : int * int -> t -> unit

    val emulate_media :
        ?media:[ `Screen | `Print | `No_override ] -> ?color_scheme:color_scheme -> ?reduced_motion:reduced_motion ->
        ?forced_colors:forced_colors -> ?contrast:contrast -> t -> unit

    val request_gc : t -> unit

    include Identity with type t := t
end

(** A frame of a page: its main frame or the content of an [<iframe>]. *)
and Frame : sig
    type t

    val locator :
        ?has_text:string -> ?has_text_regex:string -> ?has_not_text:string -> ?has_not_text_regex:string -> ?has:Locator.t -> ?has_not:Locator.t ->
        string -> t -> Locator.t

    include Locator_queries with type t := t and type locator := Locator.t

    val frame_locator : string -> t -> FrameLocator.t

    include
        Frame_operations
            with type t := t
             and type js_value := Js.t
             and type js_handle := JSHandle.t
             and type element_handle := ElementHandle.t
             and type response := Response.t

    val page : t -> Page.t
    val url : t -> string

    val name : t -> string
    (** The [name] attribute of the frame's element; empty for the main frame. *)

    val parent_frame : t -> t option
    val child_frames : t -> t list
    val is_detached : t -> bool

    val frame_element : t -> ElementHandle.t
    (** The [<iframe>] or [<frame>] element that holds the frame. *)

    include Identity with type t := t
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
and Locator : sig
    type t

    (** {1 Narrowing down} *)

    val locator :
        ?has_text:string -> ?has_text_regex:string -> ?has_not_text:string -> ?has_not_text_regex:string -> ?has:t -> ?has_not:t -> string -> t -> t
    (** The descendants of the located elements that match the selector. *)

    include Locator_queries with type t := t and type locator := t

    val filter :
        ?has_text:string -> ?has_text_regex:string -> ?has_not_text:string -> ?has_not_text_regex:string -> ?has:t -> ?has_not:t ->
        ?visible:bool -> t -> t
    (** Keeps the elements that contain the text ([has_text], [has_text_regex]) or a descendant matching another
        locator ([has]), that do not ([has_not_text], [has_not_text_regex], [has_not]), or that are visible or not.
        An element is kept when it meets all of the conditions given. *)

    val first : t -> t
    val last : t -> t

    val nth : int -> t -> t
    (** Counting from 0; negative numbers count from the end. *)

    val and_ : t -> t -> t
    (** The elements that both locators match. *)

    val or_ : t -> t -> t
    (** The elements that either locator matches. *)

    val visible : t -> t

    val within : t -> t -> t
    (** [within outer inner] are the elements of [inner] inside an element of [outer], with [inner] looked up in each
        of those separately: [Page.get_by_role `Cell page |> Locator.nth 2 |> Locator.within (Page.get_by_role `Row page)]
        is the third cell of every row, where [Locator.get_by_role `Cell row |> Locator.nth 2] is the third cell of
        all. *)

    val describe : string -> t -> t
    (** Gives the locator a name to show in traces and error messages. *)

    val description : t -> string option
    (** The name that {!describe} gave to the locator. *)

    val normalize : t -> t
    (** A locator for the same element as Playwright itself would write it, by role, label, text or test id where
        that is possible. This asks the browser, and fails when the locator matches no element.

        {[
          Page.get_by_ref "e2" page |> Locator.normalize |> Locator.selector
          (* internal:role=button[name="Submit"i] *)
        ]} *)

    val frame_locator : string -> t -> FrameLocator.t

    val content_frame : t -> FrameLocator.t
    (** For a locator of an [<iframe>]: the content of that frame. *)

    val page : t -> Page.t
    val frame : t -> Frame.t

    val selector : t -> string
    (** The selector that the locator stands for, which {!Page.locator} accepts. *)

    val to_string : t -> string
    (** The locator for the eyes of a person: ["Locator@"] and its selector. *)

    (** {1 Actions} *)

    val click :
        ?timeout:float -> ?force:bool -> ?scroll:[ `Auto | `None ] -> ?no_wait_after:bool -> ?modifiers:keyboard_modifier list -> ?position:float * float -> ?delay:float ->
        ?button:mouse_button -> ?click_count:int -> ?trial:bool -> ?steps:int -> t -> unit
    (** Scrolls the element into view if needed, waits for it to be visible, stable, enabled and not covered, and
        clicks its centre or [position] relative to its top left corner. [force] skips the waiting; [trial] does
        the waiting but not the click. With [~scroll:`None] nothing is scrolled, and the click fails when the
        element is not within the viewport already, which shows whether a user could reach it as the page is.
        The other actions that take these arguments use them alike. *)

    val dblclick :
        ?timeout:float -> ?force:bool -> ?scroll:[ `Auto | `None ] -> ?modifiers:keyboard_modifier list -> ?position:float * float -> ?delay:float -> ?button:mouse_button ->
        ?trial:bool -> ?steps:int -> t -> unit

    val tap : ?timeout:float -> ?force:bool -> ?scroll:[ `Auto | `None ] -> ?modifiers:keyboard_modifier list -> ?position:float * float -> ?trial:bool -> t -> unit
    (** Requires a context with [has_touch]. *)

    val hover : ?timeout:float -> ?force:bool -> ?scroll:[ `Auto | `None ] -> ?modifiers:keyboard_modifier list -> ?position:float * float -> ?trial:bool -> t -> unit

    val drag_to :
        ?timeout:float -> ?force:bool -> ?scroll:[ `Auto | `None ] -> ?trial:bool -> ?source_position:float * float -> ?target_position:float * float -> ?steps:int ->
        target:t -> t -> unit
    (** [drag_to ~target source] drags the element of [source] onto that of [target]. *)

    val fill : ?timeout:float -> ?force:bool -> string -> t -> unit
    (** Sets the value of an [<input>], [<textarea>] or [contenteditable] element and dispatches the [input] event. *)

    val clear : ?timeout:float -> ?force:bool -> t -> unit
    val focus : ?timeout:float -> t -> unit
    val blur : ?timeout:float -> t -> unit

    val press : ?timeout:float -> ?delay:float -> ?no_wait_after:bool -> string -> t -> unit
    (** Focuses the element and presses a key or a combination of keys, e.g. ["Enter"] or ["Control+A"]. *)

    val press_sequentially : ?timeout:float -> ?delay:float -> string -> t -> unit
    (** Types the text key by key. Use {!fill} unless the page needs to see the individual key events. *)

    val check : ?timeout:float -> ?force:bool -> ?scroll:[ `Auto | `None ] -> ?position:float * float -> ?trial:bool -> t -> unit
    val uncheck : ?timeout:float -> ?force:bool -> ?scroll:[ `Auto | `None ] -> ?position:float * float -> ?trial:bool -> t -> unit
    val set_checked : ?timeout:float -> ?force:bool -> ?scroll:[ `Auto | `None ] -> ?position:float * float -> ?trial:bool -> bool -> t -> unit

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

    val highlight : ?style:string -> t -> Disposable.t
    (** Marks the matching elements in the page, for the eyes of whoever is debugging, until the result is
        disposed of or {!hide_highlight} is called. *)

    val hide_highlight : t -> unit

    val wait_for_function : ?timeout:float -> ?arg:Js.t -> string -> t -> unit
    (** [wait_for_function expression] waits until the JavaScript function, which is called with the element and
        [arg], returns something truthy: [Locator.wait_for_function "input => input.value.length > 3" locator]. *)

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
        {{:https://playwright.dev/docs/aria-snapshots} ARIA snapshots}. With [~mode:`Ai] the snapshot is the one
        meant for language models: it goes into frames and gives every element a reference, for {!Page.get_by_ref}.
        [depth] limits how deep the tree goes, and [boxes] adds the position and size of every element. *)

    val aria_snapshot_json : ?timeout:float -> ?mode:[ `Ai | `Default ] -> ?depth:int -> ?boxes:bool -> t -> Yojson.Safe.t
    (** The tree of {!aria_snapshot} as JSON rather than YAML: an object for each element with its [role], [name],
        the states that apply and its [children], and a string for each text. *)

    val screenshot :
        ?timeout:float -> ?type_:[ `Png | `Jpeg | `Webp ] -> ?quality:int -> ?omit_background:bool ->
        ?caret:[ `Hide | `Initial ] -> ?animations:[ `Allow | `Disabled ] -> ?scale:[ `Css | `Device ] -> ?mask:t list ->
        ?mask_color:string -> ?style:string -> t -> string
    (** A screenshot of the element, with the options of {!Page.screenshot}. *)

    val wait_for : ?timeout:float -> ?state:element_state -> t -> unit
    (** Waits until the element is in the given state, [`Visible] by default. *)

    (** {1 JavaScript} *)

    val evaluate : ?timeout:float -> ?arg:Js.t -> string -> t -> Js.t
    (** Calls the function that the expression evaluates to with the element and [arg]:
        [Locator.evaluate "element => element.scrollTop" locator]. *)

    val evaluate_handle : ?timeout:float -> ?arg:Js.t -> string -> t -> JSHandle.t

    val evaluate_all : ?arg:Js.t -> string -> t -> Js.t
    (** Calls the function with the array of all elements that match right now. *)

    val element_handle : ?timeout:float -> t -> ElementHandle.t
    val element_handles : t -> ElementHandle.t list

    include Identity with type t := t
end

(** The content of an [<iframe>], for locating elements inside it:
    [Page.frame_locator "#payment" page |> FrameLocator.get_by_label "Card number" |> Locator.fill "4242..."]. *)
and FrameLocator : sig
    type t

    val locator :
        ?has_text:string -> ?has_text_regex:string -> ?has_not_text:string -> ?has_not_text_regex:string -> ?has:Locator.t -> ?has_not:Locator.t ->
        string -> t -> Locator.t

    include Locator_queries with type t := t and type locator := Locator.t

    val frame_locator : string -> t -> t

    val owner : t -> Locator.t
    (** The [<iframe>] element itself. *)

    val first : t -> t
    val last : t -> t
    val nth : int -> t -> t

    include Identity with type t := t
end

(** {1 Handles and input devices} *)

(** A reference to a JavaScript object in a page. Handles keep their objects alive until they are disposed of or the
    page navigates. *)
and JSHandle : sig
    type t

    val evaluate : ?arg:Js.t -> string -> t -> Js.t
    (** Calls the function that the expression evaluates to with the object and [arg]. *)

    val evaluate_handle : ?arg:Js.t -> string -> t -> t
    val get_property : string -> t -> t
    val get_properties : t -> (string * t) list

    val json_value : t -> Js.t
    (** A copy of the object. *)

    val as_element : t -> ElementHandle.t option
    (** The handle as an element handle, if the object is a DOM element. *)

    val to_string : t -> string
    val dispose : t -> unit

    include Identity with type t := t
end

(** A reference to a DOM element in a page. {!Locator}s are the better tool for nearly everything: an element
    handle refers to one particular element, which the page may replace at any time. *)
and ElementHandle : sig
    type t

    val as_js_handle : t -> JSHandle.t
    val evaluate : ?arg:Js.t -> string -> t -> Js.t
    val evaluate_handle : ?arg:Js.t -> string -> t -> JSHandle.t
    val dispose : t -> unit

    val owner_frame : t -> Frame.t option
    (** The frame whose document the element is in. *)

    val content_frame : t -> Frame.t option
    (** For an [<iframe>] element: the frame that it holds. *)

    val query_selector : string -> t -> t option
    val query_selector_all : string -> t -> t list
    val eval_on_selector : ?arg:Js.t -> string -> expression:string -> t -> Js.t
    val eval_on_selector_all : ?arg:Js.t -> string -> expression:string -> t -> Js.t
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

    val screenshot :
        ?timeout:float -> ?type_:[ `Png | `Jpeg | `Webp ] -> ?quality:int -> ?omit_background:bool ->
        ?caret:[ `Hide | `Initial ] -> ?animations:[ `Allow | `Disabled ] -> ?scale:[ `Css | `Device ] -> ?mask:Locator.t list ->
        ?mask_color:string -> ?style:string -> t -> string
    (** A screenshot of the element, with the options of {!Page.screenshot}. *)

    val scroll_into_view_if_needed : ?timeout:float -> t -> unit
    val dispatch_event : ?event_init:Js.t -> string -> t -> unit

    val click :
        ?timeout:float -> ?force:bool -> ?scroll:[ `Auto | `None ] -> ?no_wait_after:bool -> ?modifiers:keyboard_modifier list -> ?position:float * float -> ?delay:float ->
        ?button:mouse_button -> ?click_count:int -> ?trial:bool -> ?steps:int -> t -> unit

    val dblclick :
        ?timeout:float -> ?force:bool -> ?scroll:[ `Auto | `None ] -> ?modifiers:keyboard_modifier list -> ?position:float * float -> ?delay:float -> ?button:mouse_button ->
        ?trial:bool -> ?steps:int -> t -> unit

    val tap : ?timeout:float -> ?force:bool -> ?scroll:[ `Auto | `None ] -> ?modifiers:keyboard_modifier list -> ?position:float * float -> ?trial:bool -> t -> unit
    val hover : ?timeout:float -> ?force:bool -> ?scroll:[ `Auto | `None ] -> ?modifiers:keyboard_modifier list -> ?position:float * float -> ?trial:bool -> t -> unit
    val fill : ?timeout:float -> ?force:bool -> string -> t -> unit
    val select_text : ?timeout:float -> ?force:bool -> t -> unit
    val focus : t -> unit
    val press : ?timeout:float -> ?delay:float -> ?no_wait_after:bool -> string -> t -> unit
    val type_ : ?timeout:float -> ?delay:float -> string -> t -> unit
    val check : ?timeout:float -> ?force:bool -> ?scroll:[ `Auto | `None ] -> ?position:float * float -> ?trial:bool -> t -> unit
    val uncheck : ?timeout:float -> ?force:bool -> ?scroll:[ `Auto | `None ] -> ?position:float * float -> ?trial:bool -> t -> unit
    val set_checked : ?timeout:float -> ?force:bool -> ?scroll:[ `Auto | `None ] -> ?position:float * float -> ?trial:bool -> bool -> t -> unit
    val select_option : ?timeout:float -> ?force:bool -> select_option list -> t -> string list
    val set_input_files : ?timeout:float -> string list -> t -> unit
    val set_input_payloads : ?timeout:float -> file_payload list -> t -> unit

    include Identity with type t := t
end

(** The keyboard of a page, see {!Page.keyboard}. Keys are named as in
    {{:https://playwright.dev/docs/api/class-keyboard#keyboard-press} [keyboard.press]}: ["a"], ["Enter"],
    ["ArrowLeft"], or a combination such as ["Shift+Tab"] or ["ControlOrMeta+C"]. *)
and Keyboard : sig
    type t

    val press : ?delay:float -> string -> t -> unit

    val type_ : ?delay:float -> string -> t -> unit
    (** Sends the key events for each character of the text. *)

    val insert_text : string -> t -> unit
    (** Inserts the text without key events. *)

    val down : string -> t -> unit
    val up : string -> t -> unit

    include Identity with type t := t
end

(** The mouse of a page, see {!Page.mouse}. Coordinates are in CSS pixels relative to the top left corner of the
    viewport. *)
and Mouse : sig
    type t

    val move : ?steps:int -> x:float -> y:float -> t -> unit
    val down : ?button:mouse_button -> ?click_count:int -> t -> unit
    val up : ?button:mouse_button -> ?click_count:int -> t -> unit
    val click : ?delay:float -> ?button:mouse_button -> ?click_count:int -> x:float -> y:float -> t -> unit
    val dblclick : ?delay:float -> ?button:mouse_button -> x:float -> y:float -> t -> unit

    val wheel : delta_x:float -> delta_y:float -> t -> unit
    (** Scrolls. *)

    include Identity with type t := t
end

(** The touchscreen of a page, see {!Page.touchscreen}. It takes a context that was created with [has_touch]. *)
and Touchscreen : sig
    type t

    val tap : x:float -> y:float -> t -> unit

    include Identity with type t := t
end

(** {1 Network} *)

(** A request made by a page. *)
and Request : sig
    type t

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

    val response : t -> Response.t option
    (** Waits for the response. [None] if the request failed. *)

    val existing_response : t -> Response.t option
    (** The response if it has been received already. Does not wait. *)

    val frame : t -> Frame.t
    (** The frame that made the request. Fails for requests of service workers. *)

    val service_worker : t -> Worker.t option
    val is_navigation_request : t -> bool

    val redirected_from : t -> t option
    (** The request that the server answered with a redirect to this one. *)

    val redirected_to : t -> t option

    val failure : t -> string option
    (** The reason why the request failed, e.g. ["net::ERR_FAILED"]; [None] unless it has failed. *)

    val timing : t -> timing

    val sizes : t -> sizes
    (** Waits for the response to finish. *)

    include Identity with type t := t
end

(** The response to a {!Request}. *)
and Response : sig
    type t

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

    val request : t -> Request.t
    val frame : t -> Frame.t
    val from_service_worker : t -> bool
    val http_version : t -> string
    val server_addr : t -> server_addr option
    val security_details : t -> security_details option

    include Identity with type t := t
end

(** An intercepted request, see {!Page.route}. A handler has to conclude each route in exactly one way. *)
and Route : sig
    type t

    val request : t -> Request.t

    val fulfill :
        ?status:int -> ?headers:(string * string) list -> ?content_type:string -> ?body:string -> ?json:Yojson.Safe.t ->
        ?response:APIResponse.t -> t -> unit
    (** Answers the request without sending it: with [body] or [json], or with a [response] that was obtained from
        {!fetch}, of which the other arguments override parts. The status defaults to 200, and [content_type] to
        that of JSON for [json]; a [body] has the type that [headers] or [content_type] give it. *)

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
        ?max_retries:int -> t -> APIResponse.t
    (** Performs the request and returns the response without passing it to the page, so that it can be inspected
        and modified before {!fulfill}. *)

    include Identity with type t := t
end

(** A WebSocket connection opened by a page. *)
and WebSocket : sig
    type t

    val url : t -> string
    val is_closed : t -> bool

    type _ event =
        | Close : t event
        | Frame_sent : web_socket_message event
        | Frame_received : web_socket_message event
        | Socket_error : string event

    val on : 'a event -> ('a -> unit) -> t -> Disposable.t
    val once : 'a event -> ('a -> unit) -> t -> Disposable.t
    val expect_event : ?timeout:float -> ?predicate:('a -> bool) -> 'a event -> (unit -> unit) -> t -> 'a

    include Identity with type t := t
end

(** An intercepted WebSocket connection, see {!Page.route_web_socket}.

    The value given to the handler is the connection to the page. Unless {!WebSocketRoute.connect_to_server} is called, the page is
    not connected to any server, and the handler plays the server: it receives what the page sends with
    {!WebSocketRoute.on_message} and talks to the page with {!WebSocketRoute.send}.

    [connect_to_server] opens the connection to the actual server and returns the server's side of it. Messages are
    then forwarded in both directions, except that a side with an [on_message] handler has its messages given to
    that handler instead, which may pass them on with [send] to the other side. *)
and WebSocketRoute : sig
    type t

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

    include Identity with type t := t
end

(** {1 Things that pages report} *)

(** A JavaScript dialog: [alert], [confirm], [prompt] or [beforeunload]. See {!Page.Dialog}. *)
and Dialog : sig
    type t

    val type_ : t -> string
    (** ["alert"], ["confirm"], ["prompt"] or ["beforeunload"]. *)

    val message : t -> string
    val default_value : t -> string
    val page : t -> Page.t option
    val accept : ?prompt_text:string -> t -> unit
    val dismiss : t -> unit

    include Identity with type t := t
end

(** Something that a page or a worker wrote to the console, see {!Page.Console}. *)
and ConsoleMessage : sig
    type t

    type location = { url : string; line_number : int; column_number : int }

    val type_ : t -> string
    (** ["log"], ["debug"], ["info"], ["error"], ["warning"], ["dir"], ["trace"], ["assert"], ... *)

    val text : t -> string
    val args : t -> JSHandle.t list
    val location : t -> location
    val page : t -> Page.t option
    val worker : t -> Worker.t option

    val timestamp : t -> float
    (** Milliseconds since the Unix epoch. *)

    include Identity with type t := t
end

(** A file that a page downloads. Downloads are stored in a temporary directory and deleted when the context is
    closed; use {!Download.save_as} to keep one. *)
and Download : sig
    type t

    val url : t -> string
    val suggested_filename : t -> string
    val page : t -> Page.t

    val path : t -> string
    (** Waits for the download to finish and returns where it was stored. *)

    val save_as : string -> t -> unit
    (** Waits for the download to finish and copies it to the given path. *)

    val failure : t -> string option
    (** Waits for the download to finish; the reason if it failed. *)

    val cancel : t -> unit
    val delete : t -> unit

    include Identity with type t := t
end

(** A file chooser that a page opened: the value of the event {!Page.File_chooser}. *)
and FileChooser : sig
    type t

    val page : t -> Page.t
    val element : t -> ElementHandle.t
    val is_multiple : t -> bool
    val set_files : ?timeout:float -> string list -> t -> unit
    val set_payloads : ?timeout:float -> file_payload list -> t -> unit

    include Identity with type t := t
end

(** An exception that was not handled in a page, see {!BrowserContext.Web_error}. *)
and WebError : sig
    type t

    val page : t -> Page.t option
    val error : t -> Error.t

    val location : t -> ConsoleMessage.location
    (** Where in the page's code the exception was thrown. *)

    include Identity with type t := t
end

(** A web worker or a service worker. *)
and Worker : sig
    type t

    val url : t -> string
    val evaluate : ?arg:Js.t -> string -> t -> Js.t
    val evaluate_handle : ?arg:Js.t -> string -> t -> JSHandle.t

    type _ event = Close : t event | Console : ConsoleMessage.t event

    val on : 'a event -> ('a -> unit) -> t -> Disposable.t
    val once : 'a event -> ('a -> unit) -> t -> Disposable.t
    val expect_event : ?timeout:float -> ?predicate:('a -> bool) -> 'a event -> (unit -> unit) -> t -> 'a

    include Identity with type t := t
end

(** The [localStorage] or [sessionStorage] of a page, see {!Page.local_storage}. It always is the storage of the
    origin that the page shows at the time of the call. *)
and WebStorage : sig
    type t

    val items : t -> (string * string) list
    val get_item : string -> t -> string option
    val set_item : string -> value:string -> t -> unit
    val remove_item : string -> t -> unit
    val clear : t -> unit

    include Identity with type t := t
end

(** The video recording of a page. The file is complete once the page has been closed. *)
and Video : sig
    type t

    val path : t -> string
    (** Where the video is, or will be, stored. *)

    val save_as : string -> t -> unit
    (** Waits for the page to close and copies the video to the given path. *)

    val delete : t -> unit

    include Identity with type t := t
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
and Tracing : sig
    type t

    val start : ?name:string -> ?title:string -> ?snapshots:bool -> ?screenshots:bool -> ?live:bool -> t -> unit

    val stop : ?path:string -> t -> unit
    (** Stops tracing, and writes the trace to [path] if that is given. *)

    val start_chunk : ?name:string -> ?title:string -> t -> unit
    (** Starts a new part of the trace, after {!start}; each part can be saved to a file of its own. *)

    val stop_chunk : ?path:string -> t -> unit

    val group : ?location:string * int * int * int -> string -> t -> unit
    (** Groups the following operations under a name in the trace viewer, until {!group_end}. [location] is the
        place in the source code to show for the group: a file, a line and a column in the form that [__POS__]
        has, so that [~location:__POS__] stands for the place of the call itself. *)

    val group_end : t -> unit

    include Identity with type t := t
end

(** The response to a request made with {!APIRequestContext}. *)
and APIResponse : sig
    type t

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

    val server_addr : t -> Response.server_addr option
    (** The address of the server that answered. *)

    val security_details : t -> Response.security_details option
    (** The certificate of the server, for a response that came over TLS. *)

    val timing : t -> timing
    (** When the phases of the request took place, as for {!Request.timing}. *)

    val dispose : t -> unit
    (** Frees the body, which the driver otherwise keeps until the request context is disposed of. *)

    include Identity with type t := t
end

(** Sending HTTP requests without a page, for instance to prepare the state of a server or to check on it. Requests
    made with {!BrowserContext.request} share the cookies of that browser context, in both directions. *)
and APIRequestContext : sig
    type t

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
    (** [params] are added to the query string. The body is one of: [data] byte for byte (the headers
        do not change how it is sent), [json] serialised with the
        content type [application/json], [form] encoded as [application/x-www-form-urlencoded], or [multipart]
        encoded as [multipart/form-data]. With [fail_on_status_code], a status outside of 200-399 is an error. *)

    val get : (string -> t -> APIResponse.t) with_request_options
    val post : (string -> t -> APIResponse.t) with_request_options
    val put : (string -> t -> APIResponse.t) with_request_options
    val patch : (string -> t -> APIResponse.t) with_request_options
    val delete : (string -> t -> APIResponse.t) with_request_options
    val head : (string -> t -> APIResponse.t) with_request_options

    val fetch : ?method_:string -> (string -> t -> APIResponse.t) with_request_options
    (** A request with any method, [GET] by default. *)

    val storage_state : ?indexed_db:bool -> ?opfs:bool -> t -> Yojson.Safe.t

    val cookies : ?urls:string list -> t -> Cookie.t list
    (** The cookies that the context holds and sends, which for {!BrowserContext.request} and {!Page.request} are
        those of the browser context. *)

    val add_cookies : Cookie.init list -> t -> unit
    val clear_cookies : ?name:string -> ?domain:string -> ?path:string -> t -> unit

    val tracing : t -> Tracing.t
    (** Records the requests of the context into a trace, as {!BrowserContext.tracing} does for a browser context. *)

    val dispose : ?reason:string -> t -> unit
    (** Frees the context and all responses that it holds. Only for contexts made with {!APIRequest.new_context}. *)

    include Identity with type t := t
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
and CDPSession : sig
    type t

    val send : ?params:Yojson.Safe.t -> string -> t -> Yojson.Safe.t
    (** [send method_] calls a method of the protocol and returns its result. *)

    val on_event : (string -> Yojson.Safe.t -> unit) -> t -> Disposable.t
    (** Registers a listener for the events of the session; it is given the name and the parameters of each. *)

    val on_close : (t -> unit) -> t -> Disposable.t
    val detach : t -> unit

    include Identity with type t := t
end

(** Control over the time that the pages of a context see: [Date], [setTimeout], [requestAnimationFrame] and the
    like. Points in time are in milliseconds since the Unix epoch, durations in milliseconds. *)
module Clock : sig
    val install : ?time:float -> BrowserContext.t -> unit
    (** Replaces the native clock with a fake one, optionally set to [time]. Required before the functions that move
        the clock: {!fast_forward}, {!run_for}, {!pause_at} and {!resume}. *)

    val fast_forward : float -> BrowserContext.t -> unit
    (** Jumps ahead, firing due timers at most once, as when a laptop is opened again after a while. *)

    val run_for : float -> BrowserContext.t -> unit
    (** Advances the clock, firing all timers that become due on the way. *)

    val pause_at : float -> BrowserContext.t -> unit
    val resume : BrowserContext.t -> unit

    val set_fixed_time : float -> BrowserContext.t -> unit
    (** Makes [Date.now] return this time forever, while timers keep running. *)

    val set_system_time : float -> BrowserContext.t -> unit
end

(** {1 Assertions} *)

(** Assertions that wait: each of them checks its condition repeatedly until it holds, and fails with an {!exception-Error} of
    kind [Assertion_failed] when it does not come to hold within the timeout, 5 seconds by default. The error
    message says what was expected, what was found instead, and includes the call log.

    {[
      Expect.to_be_visible (Page.get_by_role `Heading ~name:"Welcome" page);
      Expect.to_have_text "3 items" (Page.get_by_test_id "cart-count" page);
      Expect.Not.to_be_checked (Page.get_by_label "Subscribe" page);
      Expect.to_have_url_regex "/\\/checkout$/" page
    ]} *)
module Expect : sig
    module type Assertions = sig
        (** {2 Locators} *)

        val to_be_attached : ?timeout:float -> Locator.t -> unit
        (** An element matching the locator is in the document. *)

        val to_be_detached : ?timeout:float -> Locator.t -> unit
        val to_be_visible : ?timeout:float -> Locator.t -> unit
        val to_be_hidden : ?timeout:float -> Locator.t -> unit
        val to_be_enabled : ?timeout:float -> Locator.t -> unit
        val to_be_disabled : ?timeout:float -> Locator.t -> unit
        val to_be_editable : ?timeout:float -> Locator.t -> unit
        val to_be_read_only : ?timeout:float -> Locator.t -> unit

        val to_be_empty : ?timeout:float -> Locator.t -> unit
        (** An editable element has no value, or another element has no text. *)

        val to_be_focused : ?timeout:float -> Locator.t -> unit
        val to_be_checked : ?timeout:float -> ?checked:bool -> Locator.t -> unit
        val to_be_indeterminate : ?timeout:float -> Locator.t -> unit

        val to_be_in_viewport : ?timeout:float -> ?ratio:float -> Locator.t -> unit
        (** At least the fraction [ratio] of the element intersects the viewport; any part of it by default. *)

        val to_have_text : ?timeout:float -> ?ignore_case:bool -> ?use_inner_text:bool -> string -> Locator.t -> unit
        (** The text of the element is the given one, with whitespace normalised. *)

        val to_have_text_regex : ?timeout:float -> ?use_inner_text:bool -> string -> Locator.t -> unit

        val to_contain_text : ?timeout:float -> ?ignore_case:bool -> ?use_inner_text:bool -> string -> Locator.t -> unit
        (** The text of the element contains the given one. *)

        val to_have_texts : ?timeout:float -> ?ignore_case:bool -> ?use_inner_text:bool -> string list -> Locator.t -> unit
        (** The locator matches as many elements as there are texts, and they have these texts in this order. *)

        val to_contain_texts : ?timeout:float -> ?ignore_case:bool -> ?use_inner_text:bool -> string list -> Locator.t -> unit

        val to_have_attribute : ?timeout:float -> ?ignore_case:bool -> string -> value:string -> Locator.t -> unit
        (** [to_have_attribute name ~value]. *)

        val to_have_attribute_regex : ?timeout:float -> string -> value:string -> Locator.t -> unit

        val to_have_attribute_present : ?timeout:float -> string -> Locator.t -> unit
        (** The element has the attribute, with whatever value. *)

        val to_have_class : ?timeout:float -> string -> Locator.t -> unit
        (** The [class] attribute is exactly the given string. *)

        val to_have_class_regex : ?timeout:float -> string -> Locator.t -> unit

        val to_contain_class : ?timeout:float -> string -> Locator.t -> unit
        (** The element has all of the given space-separated classes. *)

        val to_have_id : ?timeout:float -> string -> Locator.t -> unit
        val to_have_role : ?timeout:float -> aria_role -> Locator.t -> unit
        val to_have_value : ?timeout:float -> string -> Locator.t -> unit
        val to_have_value_regex : ?timeout:float -> string -> Locator.t -> unit

        val to_have_values : ?timeout:float -> string list -> Locator.t -> unit
        (** The selected options of a [<select multiple>]. *)

        val to_have_css : ?timeout:float -> ?pseudo:[ `Before | `After ] -> string -> value:string -> Locator.t -> unit
        (** [to_have_css property ~value] compares against the computed style of the element. *)

        val to_have_js_property : ?timeout:float -> string -> Js.t -> Locator.t -> unit
        val to_have_count : ?timeout:float -> int -> Locator.t -> unit
        val to_have_accessible_name : ?timeout:float -> ?ignore_case:bool -> string -> Locator.t -> unit
        val to_have_accessible_name_regex : ?timeout:float -> string -> Locator.t -> unit
        val to_have_accessible_description : ?timeout:float -> ?ignore_case:bool -> string -> Locator.t -> unit
        val to_have_accessible_description_regex : ?timeout:float -> string -> Locator.t -> unit

        val to_have_accessible_error_message : ?timeout:float -> ?ignore_case:bool -> string -> Locator.t -> unit
        (** The text of what [aria-errormessage] refers to, for an element that is marked as invalid. *)

        val to_have_accessible_error_message_regex : ?timeout:float -> string -> Locator.t -> unit

        val to_match_aria_snapshot : ?timeout:float -> string -> Locator.t -> unit
        (** The accessibility tree of the element matches the given
            {{:https://playwright.dev/docs/aria-snapshots} ARIA snapshot} template. *)

        (** {2 Pages} *)

        val to_have_title : ?timeout:float -> string -> Page.t -> unit
        val to_have_title_regex : ?timeout:float -> string -> Page.t -> unit

        val to_have_url : ?timeout:float -> ?ignore_case:bool -> string -> Page.t -> unit
        (** The URL of the page is the given one. This is a comparison of strings, so the URL has to be written as
            the browser reports it: the host in lower case, no default port, special characters percent-encoded. Two
            things are done for it: a relative URL is resolved against the [base_url] of the context, and a URL that
            ends with the host gets the path [/]. For patterns there is {!to_have_url_regex}. *)

        val to_have_url_regex : ?timeout:float -> string -> Page.t -> unit

        (** {2 Responses} *)

        val to_be_ok : APIResponse.t -> unit
        (** The status is in the range 200-299. This one does not wait. *)
    end

    include Assertions

    (** The opposite assertions: [Expect.Not.to_be_visible locator] waits for the element to be hidden. *)
    module Not : Assertions

    val set_default_timeout : float -> t -> unit
    (** Sets the timeout of the assertions that are not given one, which is 5 seconds at first. The setting is that
        of a driver: it applies to the assertions about its pages, those of browsers that it has connected to
        included, and to no others. *)
end

(** {1:roots What a driver gives access to} *)

val chromium : t -> BrowserType.t
(** The three browser engines. Browsers are launched from them: [BrowserType.launch (chromium pw)]. *)

val firefox : t -> BrowserType.t
val webkit : t -> BrowserType.t

(** Request contexts that are independent of any browser, see {!APIRequestContext}. *)
module APIRequest : sig
    val new_context :
        ?base_url:string -> ?user_agent:string -> ?ignore_https_errors:bool -> ?extra_http_headers:(string * string) list ->
        ?fail_on_status_code:bool -> ?max_redirects:int -> ?http_credentials:Http_credentials.t list ->
        ?client_certificates:Client_certificate.t list -> ?proxy:Proxy.t ->
        ?storage_state:Yojson.Safe.t -> ?timeout:float -> t -> APIRequestContext.t
    (** Creates a request context that is independent of any browser. [timeout] is the default timeout of its
        requests. *)
end

(** Custom selector engines and the attribute used by [get_by_test_id]. The settings apply to all browser contexts
    of the driver, those that exist already included. *)
module Selectors : sig
    val register : ?content_script:bool -> string -> string -> t -> unit
    (** [register name script] registers a
        {{:https://playwright.dev/docs/extensibility#custom-selector-engines} selector engine}, which the JavaScript
        of [script] evaluates to, for selectors of the form [name=...]. *)

    val set_test_id_attribute : string -> t -> unit
end
