[@@@ocaml.warning "-30-39-32"]

type internal_obj
type any = Yojson.Safe.t
type json = Yojson.Safe.t

module Channel : sig type t = { guid: string } [@@deriving yojson] end
module StackFrame : sig
    module rec Wrap : sig type t = {
        file : string [@key "file"];
        line : int [@key "line"];
        column : int [@key "column"];
        function_ : string option [@key "function"] [@default None];
    } [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module Metadata : sig
    module rec Wrap : sig type t = {
        location : Location.t option [@key "location"] [@default None];
        title : string option [@key "title"] [@default None];
        internal : bool option [@key "internal"] [@default None];
        step_id : string option [@key "stepId"] [@default None];
    } [@@deriving yojson]
    end

    and Location : sig type t = {
        file : string [@key "file"];
        line : int option [@key "line"] [@default None];
        column : int option [@key "column"] [@default None];
    } [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module ClientSideCallMetadata : sig
    module rec Wrap : sig type t = {
        id : int [@key "id"];
        stack : StackFrame.t array option [@key "stack"] [@default None];
    } [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module Point : sig
    module rec Wrap : sig type t = {
        x : float [@key "x"];
        y : float [@key "y"];
    } [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module Rect : sig
    module rec Wrap : sig type t = {
        x : float [@key "x"];
        y : float [@key "y"];
        width : float [@key "width"];
        height : float [@key "height"];
    } [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module SerializedValue : sig
    module rec Wrap : sig type t = {
        n : float option [@key "n"] [@default None];
        b : bool option [@key "b"] [@default None];
        s : string option [@key "s"] [@default None];
        v : V.t option [@key "v"] [@default None];
        d : string option [@key "d"] [@default None];
        u : string option [@key "u"] [@default None];
        bi : string option [@key "bi"] [@default None];
        ta : Ta.t option [@key "ta"] [@default None];
        e : E.t option [@key "e"] [@default None];
        r : R.t option [@key "r"] [@default None];
        a : t array option [@key "a"] [@default None];
        o : O.t array option [@key "o"] [@default None];
        h : int option [@key "h"] [@default None];
        id : int option [@key "id"] [@default None];
        ref : int option [@key "ref"] [@default None];
    } [@@deriving yojson]
    end

    and O : sig type t = {
        k : string [@key "k"];
        v : Wrap.t [@key "v"];
    } [@@deriving yojson]
    end

    and R : sig type t = {
        p : string [@key "p"];
        f : string [@key "f"];
    } [@@deriving yojson]
    end

    and E : sig type t = {
        m : string [@key "m"];
        n : string [@key "n"];
        s : string [@key "s"];
    } [@@deriving yojson]
    end

    and Ta : sig type t = {
        b : string [@key "b"];
        k : K.t [@key "k"];
    } [@@deriving yojson]
    end

    and K : sig type t = [
        | `I8 [@name "i8"]
        | `Ui8 [@name "ui8"]
        | `Ui8c [@name "ui8c"]
        | `I16 [@name "i16"]
        | `Ui16 [@name "ui16"]
        | `I32 [@name "i32"]
        | `Ui32 [@name "ui32"]
        | `F32 [@name "f32"]
        | `F64 [@name "f64"]
        | `Bi64 [@name "bi64"]
        | `Bui64 [@name "bui64"]
    ] [@@deriving yojson]
    end

    and V : sig type t = [
        | `Null [@name "null"]
        | `Undefined [@name "undefined"]
        | `Nan [@name "nan"]
        | `Inf [@name "inf"]
        | `Minus_inf [@name "-inf"]
        | `Minus_zero [@name "-0"]
    ] [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module SerializedArgument : sig
    module rec Wrap : sig type t = {
        value : SerializedValue.t [@key "value"];
        handles : Channel.t array [@key "handles"];
    } [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module ExpectedTextValue : sig
    module rec Wrap : sig type t = {
        string : string option [@key "string"] [@default None];
        regex_source : string option [@key "regexSource"] [@default None];
        regex_flags : string option [@key "regexFlags"] [@default None];
        match_substring : bool option [@key "matchSubstring"] [@default None];
        ignore_case : bool option [@key "ignoreCase"] [@default None];
        normalize_white_space : bool option [@key "normalizeWhiteSpace"] [@default None];
    } [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module SelectorEngine : sig
    module rec Wrap : sig type t = {
        name : string [@key "name"];
        source : string [@key "source"];
        content_script : bool option [@key "contentScript"] [@default None];
    } [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module URLPattern : sig
    module rec Wrap : sig type t = {
        hash : string [@key "hash"];
        hostname : string [@key "hostname"];
        password : string [@key "password"];
        pathname : string [@key "pathname"];
        port : string [@key "port"];
        protocol : string [@key "protocol"];
        search : string [@key "search"];
        username : string [@key "username"];
    } [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module SetNetworkCookie : sig
    module rec Wrap : sig type t = {
        name : string [@key "name"];
        value : string [@key "value"];
        url : string option [@key "url"] [@default None];
        domain : string option [@key "domain"] [@default None];
        path : string option [@key "path"] [@default None];
        expires : float option [@key "expires"] [@default None];
        http_only : bool option [@key "httpOnly"] [@default None];
        secure : bool option [@key "secure"] [@default None];
        same_site : SameSite.t option [@key "sameSite"] [@default None];
        partition_key : string option [@key "partitionKey"] [@default None];
        cr_has_cross_site_ancestor : bool option [@key "_crHasCrossSiteAncestor"] [@default None];
    } [@@deriving yojson]
    end

    and SameSite : sig type t = [
        | `Strict [@name "Strict"]
        | `Lax [@name "Lax"]
        | `None [@name "None"]
    ] [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module NetworkCookie : sig
    module rec Wrap : sig type t = {
        name : string [@key "name"];
        value : string [@key "value"];
        domain : string [@key "domain"];
        path : string [@key "path"];
        expires : float [@key "expires"];
        http_only : bool [@key "httpOnly"];
        secure : bool [@key "secure"];
        same_site : SameSite.t [@key "sameSite"];
        partition_key : string option [@key "partitionKey"] [@default None];
        cr_has_cross_site_ancestor : bool option [@key "_crHasCrossSiteAncestor"] [@default None];
    } [@@deriving yojson]
    end

    and SameSite : sig type t = [
        | `Strict [@name "Strict"]
        | `Lax [@name "Lax"]
        | `None [@name "None"]
    ] [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module NameValue : sig
    module rec Wrap : sig type t = {
        name : string [@key "name"];
        value : string [@key "value"];
    } [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module IndexedDBDatabase : sig
    module rec Wrap : sig type t = {
        name : string [@key "name"];
        version : int [@key "version"];
        stores : Stores.t array [@key "stores"];
    } [@@deriving yojson]
    end

    and Stores : sig type t = {
        name : string [@key "name"];
        auto_increment : bool [@key "autoIncrement"];
        key_path : string option [@key "keyPath"] [@default None];
        key_path_array : string array option [@key "keyPathArray"] [@default None];
        records : Records.t array [@key "records"];
        indexes : Indexes.t array [@key "indexes"];
    } [@@deriving yojson]
    end

    and Indexes : sig type t = {
        name : string [@key "name"];
        key_path : string option [@key "keyPath"] [@default None];
        key_path_array : string array option [@key "keyPathArray"] [@default None];
        multi_entry : bool [@key "multiEntry"];
        unique : bool [@key "unique"];
    } [@@deriving yojson]
    end

    and Records : sig type t = {
        key : json option [@key "key"] [@default None];
        key_encoded : json option [@key "keyEncoded"] [@default None];
        value : json option [@key "value"] [@default None];
        value_encoded : json option [@key "valueEncoded"] [@default None];
    } [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module SetOriginStorage : sig
    module rec Wrap : sig type t = {
        origin : string [@key "origin"];
        local_storage : NameValue.t array [@key "localStorage"];
        indexed_db : IndexedDBDatabase.t array option [@key "indexedDB"] [@default None];
    } [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module OriginStorage : sig
    module rec Wrap : sig type t = {
        origin : string [@key "origin"];
        local_storage : NameValue.t array [@key "localStorage"];
        indexed_db : IndexedDBDatabase.t array option [@key "indexedDB"] [@default None];
    } [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module SerializedError : sig
    module rec Wrap : sig type t = {
        error : Error.t option [@key "error"] [@default None];
        value : SerializedValue.t option [@key "value"] [@default None];
    } [@@deriving yojson]
    end

    and Error : sig type t = {
        message : string [@key "message"];
        name : string [@key "name"];
        stack : string option [@key "stack"] [@default None];
    } [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module RecordHarOptions : sig
    module rec Wrap : sig type t = {
        zip : bool option [@key "zip"] [@default None];
        content : Content.t option [@key "content"] [@default None];
        mode : Mode.t option [@key "mode"] [@default None];
        url_glob : string option [@key "urlGlob"] [@default None];
        url_regex_source : string option [@key "urlRegexSource"] [@default None];
        url_regex_flags : string option [@key "urlRegexFlags"] [@default None];
    } [@@deriving yojson]
    end

    and Mode : sig type t = [
        | `Full [@name "full"]
        | `Minimal [@name "minimal"]
    ] [@@deriving yojson]
    end

    and Content : sig type t = [
        | `Embed [@name "embed"]
        | `Attach [@name "attach"]
        | `Omit [@name "omit"]
    ] [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module FormField : sig
    module rec Wrap : sig type t = {
        name : string [@key "name"];
        value : string option [@key "value"] [@default None];
        file : File.t option [@key "file"] [@default None];
    } [@@deriving yojson]
    end

    and File : sig type t = {
        name : string [@key "name"];
        mime_type : string option [@key "mimeType"] [@default None];
        buffer : string [@key "buffer"];
    } [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module SDKLanguage : sig
    module rec Wrap : sig type t = [
        `Javascript [@name "javascript"]
        |         `Python [@name "python"]
        |         `Java [@name "java"]
        |         `Csharp [@name "csharp"]
    ] [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module APIResponse : sig
    module rec Wrap : sig type t = {
        fetch_uid : string [@key "fetchUid"];
        url : string [@key "url"];
        status : int [@key "status"];
        status_text : string [@key "statusText"];
        headers : NameValue.t array [@key "headers"];
    } [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module LifecycleEvent : sig
    module rec Wrap : sig type t = [
        `Load [@name "load"]
        |         `Domcontentloaded [@name "domcontentloaded"]
        |         `Networkidle [@name "networkidle"]
        |         `Commit [@name "commit"]
    ] [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module ConsoleMessagesFilter : sig
    module rec Wrap : sig type t = [
        `All [@name "all"]
        |         `Since_navigation [@name "since-navigation"]
    ] [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module RecorderSource : sig
    module rec Wrap : sig type t = {
        is_recorded : bool [@key "isRecorded"];
        id : string [@key "id"];
        label : string [@key "label"];
        text : string [@key "text"];
        language : string [@key "language"];
        highlight : Highlight.t array [@key "highlight"];
        reveal_line : int option [@key "revealLine"] [@default None];
        group : string option [@key "group"] [@default None];
    } [@@deriving yojson]
    end

    and Highlight : sig type t = {
        line : int [@key "line"];
        type_ : string [@key "type"];
    } [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module ResourceTiming : sig
    module rec Wrap : sig type t = {
        start_time : float [@key "startTime"];
        domain_lookup_start : float [@key "domainLookupStart"];
        domain_lookup_end : float [@key "domainLookupEnd"];
        connect_start : float [@key "connectStart"];
        secure_connection_start : float [@key "secureConnectionStart"];
        connect_end : float [@key "connectEnd"];
        request_start : float [@key "requestStart"];
        response_start : float [@key "responseStart"];
    } [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module SecurityDetails : sig
    module rec Wrap : sig type t = {
        issuer : string option [@key "issuer"] [@default None];
        protocol : string option [@key "protocol"] [@default None];
        subject_name : string option [@key "subjectName"] [@default None];
        valid_from : float option [@key "validFrom"] [@default None];
        valid_to : float option [@key "validTo"] [@default None];
    } [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module RequestSizes : sig
    module rec Wrap : sig type t = {
        request_body_size : int [@key "requestBodySize"];
        request_headers_size : int [@key "requestHeadersSize"];
        response_body_size : int [@key "responseBodySize"];
        response_headers_size : int [@key "responseHeadersSize"];
    } [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module RemoteAddr : sig
    module rec Wrap : sig type t = {
        ip_address : string [@key "ipAddress"];
        port : int [@key "port"];
    } [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module AndroidWebView : sig
    module rec Wrap : sig type t = {
        pid : int [@key "pid"];
        pkg : string [@key "pkg"];
        socket_name : string [@key "socketName"];
    } [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module AndroidSelector : sig
    module rec Wrap : sig type t = {
        checkable : bool option [@key "checkable"] [@default None];
        checked : bool option [@key "checked"] [@default None];
        clazz : string option [@key "clazz"] [@default None];
        clickable : bool option [@key "clickable"] [@default None];
        depth : int option [@key "depth"] [@default None];
        desc : string option [@key "desc"] [@default None];
        enabled : bool option [@key "enabled"] [@default None];
        focusable : bool option [@key "focusable"] [@default None];
        focused : bool option [@key "focused"] [@default None];
        has_child : HasChild.t option [@key "hasChild"] [@default None];
        has_descendant : HasDescendant.t option [@key "hasDescendant"] [@default None];
        long_clickable : bool option [@key "longClickable"] [@default None];
        pkg : string option [@key "pkg"] [@default None];
        res : string option [@key "res"] [@default None];
        scrollable : bool option [@key "scrollable"] [@default None];
        selected : bool option [@key "selected"] [@default None];
        text : string option [@key "text"] [@default None];
    } [@@deriving yojson]
    end

    and HasDescendant : sig type t = {
        android_selector : Wrap.t [@key "androidSelector"];
        max_depth : int option [@key "maxDepth"] [@default None];
    } [@@deriving yojson]
    end

    and HasChild : sig type t = {
        android_selector : Wrap.t [@key "androidSelector"];
    } [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module AndroidElementInfo : sig
    module rec Wrap : sig type t = {
        children : t array option [@key "children"] [@default None];
        clazz : string [@key "clazz"];
        desc : string [@key "desc"];
        res : string [@key "res"];
        pkg : string [@key "pkg"];
        text : string [@key "text"];
        bounds : Rect.t [@key "bounds"];
        checkable : bool [@key "checkable"];
        checked : bool [@key "checked"];
        clickable : bool [@key "clickable"];
        enabled : bool [@key "enabled"];
        focusable : bool [@key "focusable"];
        focused : bool [@key "focused"];
        long_clickable : bool [@key "longClickable"];
        scrollable : bool [@key "scrollable"];
        selected : bool [@key "selected"];
    } [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]

end

module rec APIRequestContext : sig
    module rec Wrap : sig type t = {
        tracing : Tracing.t [@key "tracing"];
    __internal_obj : internal_obj;
    } [@@deriving yojson]

    end
    type t = Wrap.t [@@deriving yojson]


    val fetch : url:string -> ?encoded_params:string -> ?params:NameValue.t array -> ?method_:string -> ?headers:NameValue.t array -> ?post_data:string -> ?json_data:string -> ?form_data:NameValue.t array -> ?multipart_data:FormField.t array -> timeout:float -> ?fail_on_status_code:bool -> ?ignore_https_errors:bool -> ?max_redirects:int -> ?max_retries:int -> t -> APIResponse.t
    val fetch_response_body : fetch_uid:string -> t -> string option
    val fetch_log : fetch_uid:string -> t -> string array

    module rec StorageStateResult : sig type t = {
        cookies : NetworkCookie.t array [@key "cookies"];
        origins : OriginStorage.t array [@key "origins"];
    } [@@deriving yojson {strict = false}]
    end

    val storage_state : ?indexed_db:bool -> t -> StorageStateResult.t
    val dispose_api_response : fetch_uid:string -> t -> unit
    val dispose : ?reason:string -> t -> unit
end
and LocalUtils : sig
    module rec Wrap : sig type t = {
        device_descriptors : DeviceDescriptors.t array [@key "deviceDescriptors"];
    __internal_obj : internal_obj;
    } [@@deriving yojson]

    end

    and DeviceDescriptors : sig type t = {
        name : string [@key "name"];
        descriptor : Descriptor.t [@key "descriptor"];
    } [@@deriving yojson]
    end

    and Descriptor : sig type t = {
        user_agent : string [@key "userAgent"];
        viewport : Viewport.t [@key "viewport"];
        screen : Screen.t option [@key "screen"] [@default None];
        device_scale_factor : float [@key "deviceScaleFactor"];
        is_mobile : bool [@key "isMobile"];
        has_touch : bool [@key "hasTouch"];
        default_browser_type : DefaultBrowserType.t [@key "defaultBrowserType"];
    } [@@deriving yojson]
    end

    and DefaultBrowserType : sig type t = [
        | `Chromium [@name "chromium"]
        | `Firefox [@name "firefox"]
        | `Webkit [@name "webkit"]
    ] [@@deriving yojson]
    end

    and Screen : sig type t = {
        width : int [@key "width"];
        height : int [@key "height"];
    } [@@deriving yojson]
    end

    and Viewport : sig type t = {
        width : int [@key "width"];
        height : int [@key "height"];
    } [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]



    module rec Mode : sig type t = [
        | `Write [@name "write"]
        | `Append [@name "append"]
    ] [@@deriving yojson]
    end

    val zip : zip_file:string -> entries:NameValue.t array -> ?stacks_id:string -> mode:Mode.t -> include_sources:bool -> ?additional_sources:string array -> t -> unit

    module rec HarOpenResult : sig type t = {
        har_id : string option [@key "harId"] [@default None];
        error : string option [@key "error"] [@default None];
    } [@@deriving yojson {strict = false}]
    end

    val har_open : file:string -> t -> HarOpenResult.t

    module rec HarLookupResult : sig type t = {
        action : Action.t [@key "action"];
        message : string option [@key "message"] [@default None];
        redirect_url : string option [@key "redirectURL"] [@default None];
        status : int option [@key "status"] [@default None];
        headers : NameValue.t array option [@key "headers"] [@default None];
        body : string option [@key "body"] [@default None];
    } [@@deriving yojson {strict = false}]
    end

    and Action : sig type t = [
        | `Error [@name "error"]
        | `Redirect [@name "redirect"]
        | `Fulfill [@name "fulfill"]
        | `Noentry [@name "noentry"]
    ] [@@deriving yojson]
    end

    val har_lookup : har_id:string -> url:string -> method_:string -> headers:NameValue.t array -> ?post_data:string -> is_navigation_request:bool -> t -> HarLookupResult.t
    val har_close : har_id:string -> t -> unit
    val har_unzip : zip_file:string -> har_file:string -> t -> unit

    module rec ConnectResult : sig type t = {
        pipe : JsonPipe.t [@key "pipe"];
        headers : NameValue.t array [@key "headers"];
    } [@@deriving yojson {strict = false}]
    end

    val connect : endpoint:string -> ?headers:json -> ?expose_network:string -> ?slow_mo:float -> timeout:float -> ?socks_proxy_redirect_port_for_test:int -> t -> ConnectResult.t
    val tracing_started : ?traces_dir:string -> trace_name:string -> ?live:bool -> t -> string
    val add_stack_to_tracing_no_reply : call_data:ClientSideCallMetadata.t -> t -> unit
    val trace_discarded : stacks_id:string -> t -> unit
    val glob_to_regex : glob:string -> ?base_url:string -> ?web_socket_url:bool -> t -> string
end
and Root : sig
    type t [@@deriving yojson]

    val initialize : sdk_language:SDKLanguage.t -> t -> Playwright.t
end
and Playwright : sig
    module rec Wrap : sig type t = {
        chromium : BrowserType.t [@key "chromium"];
        firefox : BrowserType.t [@key "firefox"];
        webkit : BrowserType.t [@key "webkit"];
        android : Android.t [@key "android"];
        utils : LocalUtils.t option [@key "utils"] [@default None];
        pre_launched_browser : Browser.t option [@key "preLaunchedBrowser"] [@default None];
        pre_connected_android_device : AndroidDevice.t option [@key "preConnectedAndroidDevice"] [@default None];
        socks_support : SocksSupport.t option [@key "socksSupport"] [@default None];
    __internal_obj : internal_obj;
    } [@@deriving yojson]

    end
    type t = Wrap.t [@@deriving yojson]



    module rec Storage_state : sig type t = {
        cookies : NetworkCookie.t array option [@key "cookies"] [@default None];
        origins : SetOriginStorage.t array option [@key "origins"] [@default None];
    } [@@deriving yojson]
    end

    and Proxy : sig type t = {
        server : string [@key "server"];
        bypass : string option [@key "bypass"] [@default None];
        username : string option [@key "username"] [@default None];
        password : string option [@key "password"] [@default None];
    } [@@deriving yojson]
    end

    and Http_credentials : sig type t = {
        username : string [@key "username"];
        password : string [@key "password"];
        origin : string option [@key "origin"] [@default None];
        send : Send.t option [@key "send"] [@default None];
    } [@@deriving yojson]
    end

    and Send : sig type t = [
        | `Always [@name "always"]
        | `Unauthorized [@name "unauthorized"]
    ] [@@deriving yojson]
    end

    and Client_certificates : sig type t = {
        origin : string [@key "origin"];
        cert : string option [@key "cert"] [@default None];
        key : string option [@key "key"] [@default None];
        passphrase : string option [@key "passphrase"] [@default None];
        pfx : string option [@key "pfx"] [@default None];
    } [@@deriving yojson]
    end

    val new_request : ?base_url:string -> ?user_agent:string -> ?ignore_https_errors:bool -> ?extra_http_headers:NameValue.t array -> ?fail_on_status_code:bool -> ?client_certificates:Client_certificates.t array -> ?max_redirects:int -> ?http_credentials:Http_credentials.t -> ?proxy:Proxy.t -> ?storage_state:Storage_state.t -> ?traces_dir:string -> t -> APIRequestContext.t
end
and DebugController : sig
    type t [@@deriving yojson]

    val initialize : codegen_id:string -> sdk_language:SDKLanguage.t -> t -> unit
    val set_report_state_changed : enabled:bool -> t -> unit

    module rec Mode : sig type t = [
        | `Inspecting [@name "inspecting"]
        | `Recording [@name "recording"]
        | `None [@name "none"]
    ] [@@deriving yojson]
    end

    val set_recorder_mode : mode:Mode.t -> ?test_id_attribute_name:string -> ?generate_auto_expect:bool -> t -> unit
    val highlight : ?selector:string -> ?aria_template:string -> t -> unit
    val hide_highlight : t -> unit
    val resume : t -> unit
    val kill : t -> unit
end
and SocksSupport : sig
    type t [@@deriving yojson]

    val socks_connected : uid:string -> host:string -> port:int -> t -> unit
    val socks_failed : uid:string -> error_code:string -> t -> unit
    val socks_data : uid:string -> data:string -> t -> unit
    val socks_error : uid:string -> error:string -> t -> unit
    val socks_end : uid:string -> t -> unit
end
and BrowserType : sig
    module rec Wrap : sig type t = {
        executable_path : string [@key "executablePath"];
        name : string [@key "name"];
    __internal_obj : internal_obj;
    } [@@deriving yojson]

    end
    type t = Wrap.t [@@deriving yojson]



    module rec Proxy : sig type t = {
        server : string [@key "server"];
        bypass : string option [@key "bypass"] [@default None];
        username : string option [@key "username"] [@default None];
        password : string option [@key "password"] [@default None];
    } [@@deriving yojson]
    end

    val launch : ?channel:string -> ?executable_path:string -> ?args:string array -> ?ignore_all_default_args:bool -> ?ignore_default_args:string array -> ?handle_sigint:bool -> ?handle_sigterm:bool -> ?handle_sighup:bool -> timeout:float -> ?env:NameValue.t array -> ?headless:bool -> ?proxy:Proxy.t -> ?downloads_path:string -> ?traces_dir:string -> ?artifacts_dir:string -> ?chromium_sandbox:bool -> ?firefox_user_prefs:json -> ?cdp_port:int -> ?slow_mo:float -> t -> Browser.t

    module rec LaunchPersistentContextResult : sig type t = {
        browser : Browser.t [@key "browser"];
        context : BrowserContext.t [@key "context"];
    } [@@deriving yojson {strict = false}]
    end

    and Service_workers : sig type t = [
        | `Allow [@name "allow"]
        | `Block [@name "block"]
    ] [@@deriving yojson]
    end

    and Record_video : sig type t = {
        dir : string option [@key "dir"] [@default None];
        size : Size.t option [@key "size"] [@default None];
        show_actions : ShowActions.t option [@key "showActions"] [@default None];
    } [@@deriving yojson]
    end

    and ShowActions : sig type t = {
        duration : float option [@key "duration"] [@default None];
        position : Position.t option [@key "position"] [@default None];
        font_size : int option [@key "fontSize"] [@default None];
    } [@@deriving yojson]
    end

    and Position : sig type t = [
        | `Top_left [@name "top-left"]
        | `Top [@name "top"]
        | `Top_right [@name "top-right"]
        | `Bottom_left [@name "bottom-left"]
        | `Bottom [@name "bottom"]
        | `Bottom_right [@name "bottom-right"]
    ] [@@deriving yojson]
    end

    and Size : sig type t = {
        width : int [@key "width"];
        height : int [@key "height"];
    } [@@deriving yojson]
    end

    and Contrast : sig type t = [
        | `No_preference [@name "no-preference"]
        | `More [@name "more"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]
    end

    and Accept_downloads : sig type t = [
        | `Accept [@name "accept"]
        | `Deny [@name "deny"]
        | `Internal_browser_default [@name "internal-browser-default"]
    ] [@@deriving yojson]
    end

    and Forced_colors : sig type t = [
        | `Active [@name "active"]
        | `None [@name "none"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]
    end

    and Reduced_motion : sig type t = [
        | `Reduce [@name "reduce"]
        | `No_preference [@name "no-preference"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]
    end

    and Color_scheme : sig type t = [
        | `Dark [@name "dark"]
        | `Light [@name "light"]
        | `No_preference [@name "no-preference"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]
    end

    and Http_credentials : sig type t = {
        username : string [@key "username"];
        password : string [@key "password"];
        origin : string option [@key "origin"] [@default None];
        send : Send.t option [@key "send"] [@default None];
    } [@@deriving yojson]
    end

    and Send : sig type t = [
        | `Always [@name "always"]
        | `Unauthorized [@name "unauthorized"]
    ] [@@deriving yojson]
    end

    and Geolocation : sig type t = {
        longitude : float [@key "longitude"];
        latitude : float [@key "latitude"];
        accuracy : float option [@key "accuracy"] [@default None];
    } [@@deriving yojson]
    end

    and Client_certificates : sig type t = {
        origin : string [@key "origin"];
        cert : string option [@key "cert"] [@default None];
        key : string option [@key "key"] [@default None];
        passphrase : string option [@key "passphrase"] [@default None];
        pfx : string option [@key "pfx"] [@default None];
    } [@@deriving yojson]
    end

    and Screen : sig type t = {
        width : int [@key "width"];
        height : int [@key "height"];
    } [@@deriving yojson]
    end

    and Viewport : sig type t = {
        width : int [@key "width"];
        height : int [@key "height"];
    } [@@deriving yojson]
    end

    val launch_persistent_context : ?channel:string -> ?executable_path:string -> ?args:string array -> ?ignore_all_default_args:bool -> ?ignore_default_args:string array -> ?handle_sigint:bool -> ?handle_sigterm:bool -> ?handle_sighup:bool -> timeout:float -> ?env:NameValue.t array -> ?headless:bool -> ?proxy:Proxy.t -> ?downloads_path:string -> ?traces_dir:string -> ?artifacts_dir:string -> ?chromium_sandbox:bool -> ?firefox_user_prefs:json -> ?cdp_port:int -> ?no_default_viewport:bool -> ?viewport:Viewport.t -> ?screen:Screen.t -> ?ignore_https_errors:bool -> ?client_certificates:Client_certificates.t array -> ?java_script_enabled:bool -> ?bypass_csp:bool -> ?user_agent:string -> ?locale:string -> ?timezone_id:string -> ?geolocation:Geolocation.t -> ?permissions:string array -> ?extra_http_headers:NameValue.t array -> ?offline:bool -> ?http_credentials:Http_credentials.t -> ?device_scale_factor:float -> ?is_mobile:bool -> ?has_touch:bool -> ?color_scheme:Color_scheme.t -> ?reduced_motion:Reduced_motion.t -> ?forced_colors:Forced_colors.t -> ?accept_downloads:Accept_downloads.t -> ?contrast:Contrast.t -> ?base_url:string -> ?record_video:Record_video.t -> ?strict_selectors:bool -> ?service_workers:Service_workers.t -> ?selector_engines:SelectorEngine.t array -> ?test_id_attribute_name:string -> user_data_dir:string -> ?slow_mo:float -> t -> LaunchPersistentContextResult.t

    module rec ConnectOverCDPResult : sig type t = {
        browser : Browser.t [@key "browser"];
        default_context : BrowserContext.t option [@key "defaultContext"] [@default None];
    } [@@deriving yojson {strict = false}]
    end

    val connect_over_cdp : endpoint_url:string -> ?headers:NameValue.t array -> ?slow_mo:float -> timeout:float -> ?is_local:bool -> ?no_defaults:bool -> t -> ConnectOverCDPResult.t
    val connect_to_worker : endpoint:string -> timeout:float -> t -> Worker.t
end
and Browser : sig
    module rec Wrap : sig type t = {
        version : string [@key "version"];
        name : string [@key "name"];
        browser_name : BrowserName.t [@key "browserName"];
    __internal_obj : internal_obj;
    } [@@deriving yojson]

    end

    and BrowserName : sig type t = [
        | `Chromium [@name "chromium"]
        | `Firefox [@name "firefox"]
        | `Webkit [@name "webkit"]
    ] [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]


    val start_server : title:string -> ?workspace_dir:string -> ?metadata:json -> ?host:string -> ?port:int -> t -> string
    val stop_server : t -> unit
    val close : ?reason:string -> t -> unit
    val kill_for_tests : t -> unit
    val default_user_agent_for_test : t -> string

    module rec Storage_state : sig type t = {
        cookies : SetNetworkCookie.t array option [@key "cookies"] [@default None];
        origins : SetOriginStorage.t array option [@key "origins"] [@default None];
    } [@@deriving yojson]
    end

    and Proxy : sig type t = {
        server : string [@key "server"];
        bypass : string option [@key "bypass"] [@default None];
        username : string option [@key "username"] [@default None];
        password : string option [@key "password"] [@default None];
    } [@@deriving yojson]
    end

    and Service_workers : sig type t = [
        | `Allow [@name "allow"]
        | `Block [@name "block"]
    ] [@@deriving yojson]
    end

    and Record_video : sig type t = {
        dir : string option [@key "dir"] [@default None];
        size : Size.t option [@key "size"] [@default None];
        show_actions : ShowActions.t option [@key "showActions"] [@default None];
    } [@@deriving yojson]
    end

    and ShowActions : sig type t = {
        duration : float option [@key "duration"] [@default None];
        position : Position.t option [@key "position"] [@default None];
        font_size : int option [@key "fontSize"] [@default None];
    } [@@deriving yojson]
    end

    and Position : sig type t = [
        | `Top_left [@name "top-left"]
        | `Top [@name "top"]
        | `Top_right [@name "top-right"]
        | `Bottom_left [@name "bottom-left"]
        | `Bottom [@name "bottom"]
        | `Bottom_right [@name "bottom-right"]
    ] [@@deriving yojson]
    end

    and Size : sig type t = {
        width : int [@key "width"];
        height : int [@key "height"];
    } [@@deriving yojson]
    end

    and Contrast : sig type t = [
        | `No_preference [@name "no-preference"]
        | `More [@name "more"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]
    end

    and Accept_downloads : sig type t = [
        | `Accept [@name "accept"]
        | `Deny [@name "deny"]
        | `Internal_browser_default [@name "internal-browser-default"]
    ] [@@deriving yojson]
    end

    and Forced_colors : sig type t = [
        | `Active [@name "active"]
        | `None [@name "none"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]
    end

    and Reduced_motion : sig type t = [
        | `Reduce [@name "reduce"]
        | `No_preference [@name "no-preference"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]
    end

    and Color_scheme : sig type t = [
        | `Dark [@name "dark"]
        | `Light [@name "light"]
        | `No_preference [@name "no-preference"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]
    end

    and Http_credentials : sig type t = {
        username : string [@key "username"];
        password : string [@key "password"];
        origin : string option [@key "origin"] [@default None];
        send : Send.t option [@key "send"] [@default None];
    } [@@deriving yojson]
    end

    and Send : sig type t = [
        | `Always [@name "always"]
        | `Unauthorized [@name "unauthorized"]
    ] [@@deriving yojson]
    end

    and Geolocation : sig type t = {
        longitude : float [@key "longitude"];
        latitude : float [@key "latitude"];
        accuracy : float option [@key "accuracy"] [@default None];
    } [@@deriving yojson]
    end

    and Client_certificates : sig type t = {
        origin : string [@key "origin"];
        cert : string option [@key "cert"] [@default None];
        key : string option [@key "key"] [@default None];
        passphrase : string option [@key "passphrase"] [@default None];
        pfx : string option [@key "pfx"] [@default None];
    } [@@deriving yojson]
    end

    and Screen : sig type t = {
        width : int [@key "width"];
        height : int [@key "height"];
    } [@@deriving yojson]
    end

    and Viewport : sig type t = {
        width : int [@key "width"];
        height : int [@key "height"];
    } [@@deriving yojson]
    end

    val new_context : ?no_default_viewport:bool -> ?viewport:Viewport.t -> ?screen:Screen.t -> ?ignore_https_errors:bool -> ?client_certificates:Client_certificates.t array -> ?java_script_enabled:bool -> ?bypass_csp:bool -> ?user_agent:string -> ?locale:string -> ?timezone_id:string -> ?geolocation:Geolocation.t -> ?permissions:string array -> ?extra_http_headers:NameValue.t array -> ?offline:bool -> ?http_credentials:Http_credentials.t -> ?device_scale_factor:float -> ?is_mobile:bool -> ?has_touch:bool -> ?color_scheme:Color_scheme.t -> ?reduced_motion:Reduced_motion.t -> ?forced_colors:Forced_colors.t -> ?accept_downloads:Accept_downloads.t -> ?contrast:Contrast.t -> ?base_url:string -> ?record_video:Record_video.t -> ?strict_selectors:bool -> ?service_workers:Service_workers.t -> ?selector_engines:SelectorEngine.t array -> ?test_id_attribute_name:string -> ?proxy:Proxy.t -> ?storage_state:Storage_state.t -> t -> BrowserContext.t
    val new_context_for_reuse : ?no_default_viewport:bool -> ?viewport:Viewport.t -> ?screen:Screen.t -> ?ignore_https_errors:bool -> ?client_certificates:Client_certificates.t array -> ?java_script_enabled:bool -> ?bypass_csp:bool -> ?user_agent:string -> ?locale:string -> ?timezone_id:string -> ?geolocation:Geolocation.t -> ?permissions:string array -> ?extra_http_headers:NameValue.t array -> ?offline:bool -> ?http_credentials:Http_credentials.t -> ?device_scale_factor:float -> ?is_mobile:bool -> ?has_touch:bool -> ?color_scheme:Color_scheme.t -> ?reduced_motion:Reduced_motion.t -> ?forced_colors:Forced_colors.t -> ?accept_downloads:Accept_downloads.t -> ?contrast:Contrast.t -> ?base_url:string -> ?record_video:Record_video.t -> ?strict_selectors:bool -> ?service_workers:Service_workers.t -> ?selector_engines:SelectorEngine.t array -> ?test_id_attribute_name:string -> ?proxy:Proxy.t -> ?storage_state:Storage_state.t -> t -> BrowserContext.t
    val disconnect_from_reused_context : reason:string -> t -> unit
    val new_browser_cdp_session : t -> CDPSession.t
    val start_tracing : ?page:Page.t -> ?screenshots:bool -> ?categories:string array -> t -> unit
    val stop_tracing : t -> Artifact.t
end
and EventTarget : sig
    type t [@@deriving yojson]


    module rec Info : sig type t = {
        wait_id : string [@key "waitId"];
        phase : Phase.t [@key "phase"];
        event : string option [@key "event"] [@default None];
        message : string option [@key "message"] [@default None];
        error : string option [@key "error"] [@default None];
    } [@@deriving yojson]
    end

    and Phase : sig type t = [
        | `Before [@name "before"]
        | `After [@name "after"]
        | `Log [@name "log"]
    ] [@@deriving yojson]
    end

    val wait_for_event_info : info:Info.t -> t -> unit
end
and BrowserContext : sig
    module rec Wrap : sig type t = {
        debugger : Debugger.t [@key "debugger"];
        request_context : APIRequestContext.t [@key "requestContext"];
        tracing : Tracing.t [@key "tracing"];
        options : Options.t [@key "options"];
    __internal_obj : internal_obj;
    } [@@deriving yojson]

    end

    and Options : sig type t = {
        no_default_viewport : bool option [@key "noDefaultViewport"] [@default None];
        viewport : Viewport.t option [@key "viewport"] [@default None];
        screen : Screen.t option [@key "screen"] [@default None];
        ignore_https_errors : bool option [@key "ignoreHTTPSErrors"] [@default None];
        client_certificates : ClientCertificates.t array option [@key "clientCertificates"] [@default None];
        java_script_enabled : bool option [@key "javaScriptEnabled"] [@default None];
        bypass_csp : bool option [@key "bypassCSP"] [@default None];
        user_agent : string option [@key "userAgent"] [@default None];
        locale : string option [@key "locale"] [@default None];
        timezone_id : string option [@key "timezoneId"] [@default None];
        geolocation : Geolocation.t option [@key "geolocation"] [@default None];
        permissions : string array option [@key "permissions"] [@default None];
        extra_http_headers : NameValue.t array option [@key "extraHTTPHeaders"] [@default None];
        offline : bool option [@key "offline"] [@default None];
        http_credentials : HttpCredentials.t option [@key "httpCredentials"] [@default None];
        device_scale_factor : float option [@key "deviceScaleFactor"] [@default None];
        is_mobile : bool option [@key "isMobile"] [@default None];
        has_touch : bool option [@key "hasTouch"] [@default None];
        color_scheme : ColorScheme.t option [@key "colorScheme"] [@default None];
        reduced_motion : ReducedMotion.t option [@key "reducedMotion"] [@default None];
        forced_colors : ForcedColors.t option [@key "forcedColors"] [@default None];
        accept_downloads : AcceptDownloads.t option [@key "acceptDownloads"] [@default None];
        contrast : Contrast.t option [@key "contrast"] [@default None];
        base_url : string option [@key "baseURL"] [@default None];
        record_video : RecordVideo.t option [@key "recordVideo"] [@default None];
        strict_selectors : bool option [@key "strictSelectors"] [@default None];
        service_workers : ServiceWorkers.t option [@key "serviceWorkers"] [@default None];
        selector_engines : SelectorEngine.t array option [@key "selectorEngines"] [@default None];
        test_id_attribute_name : string option [@key "testIdAttributeName"] [@default None];
    } [@@deriving yojson]
    end

    and ServiceWorkers : sig type t = [
        | `Allow [@name "allow"]
        | `Block [@name "block"]
    ] [@@deriving yojson]
    end

    and RecordVideo : sig type t = {
        dir : string option [@key "dir"] [@default None];
        size : Size.t option [@key "size"] [@default None];
        show_actions : ShowActions.t option [@key "showActions"] [@default None];
    } [@@deriving yojson]
    end

    and ShowActions : sig type t = {
        duration : float option [@key "duration"] [@default None];
        position : Position.t option [@key "position"] [@default None];
        font_size : int option [@key "fontSize"] [@default None];
    } [@@deriving yojson]
    end

    and Position : sig type t = [
        | `Top_left [@name "top-left"]
        | `Top [@name "top"]
        | `Top_right [@name "top-right"]
        | `Bottom_left [@name "bottom-left"]
        | `Bottom [@name "bottom"]
        | `Bottom_right [@name "bottom-right"]
    ] [@@deriving yojson]
    end

    and Size : sig type t = {
        width : int [@key "width"];
        height : int [@key "height"];
    } [@@deriving yojson]
    end

    and Contrast : sig type t = [
        | `No_preference [@name "no-preference"]
        | `More [@name "more"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]
    end

    and AcceptDownloads : sig type t = [
        | `Accept [@name "accept"]
        | `Deny [@name "deny"]
        | `Internal_browser_default [@name "internal-browser-default"]
    ] [@@deriving yojson]
    end

    and ForcedColors : sig type t = [
        | `Active [@name "active"]
        | `None [@name "none"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]
    end

    and ReducedMotion : sig type t = [
        | `Reduce [@name "reduce"]
        | `No_preference [@name "no-preference"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]
    end

    and ColorScheme : sig type t = [
        | `Dark [@name "dark"]
        | `Light [@name "light"]
        | `No_preference [@name "no-preference"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]
    end

    and HttpCredentials : sig type t = {
        username : string [@key "username"];
        password : string [@key "password"];
        origin : string option [@key "origin"] [@default None];
        send : Send.t option [@key "send"] [@default None];
    } [@@deriving yojson]
    end

    and Send : sig type t = [
        | `Always [@name "always"]
        | `Unauthorized [@name "unauthorized"]
    ] [@@deriving yojson]
    end

    and Geolocation : sig type t = {
        longitude : float [@key "longitude"];
        latitude : float [@key "latitude"];
        accuracy : float option [@key "accuracy"] [@default None];
    } [@@deriving yojson]
    end

    and ClientCertificates : sig type t = {
        origin : string [@key "origin"];
        cert : string option [@key "cert"] [@default None];
        key : string option [@key "key"] [@default None];
        passphrase : string option [@key "passphrase"] [@default None];
        pfx : string option [@key "pfx"] [@default None];
    } [@@deriving yojson]
    end

    and Screen : sig type t = {
        width : int [@key "width"];
        height : int [@key "height"];
    } [@@deriving yojson]
    end

    and Viewport : sig type t = {
        width : int [@key "width"];
        height : int [@key "height"];
    } [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]



    module rec Info : sig type t = {
        wait_id : string [@key "waitId"];
        phase : Phase.t [@key "phase"];
        event : string option [@key "event"] [@default None];
        message : string option [@key "message"] [@default None];
        error : string option [@key "error"] [@default None];
    } [@@deriving yojson]
    end

    and Phase : sig type t = [
        | `Before [@name "before"]
        | `After [@name "after"]
        | `Log [@name "log"]
    ] [@@deriving yojson]
    end

    val wait_for_event_info : info:Info.t -> t -> unit
    val add_cookies : cookies:SetNetworkCookie.t array -> t -> unit
    val add_init_script : source:string -> t -> Disposable.t
    val clear_cookies : ?name:string -> ?name_regex_source:string -> ?name_regex_flags:string -> ?domain:string -> ?domain_regex_source:string -> ?domain_regex_flags:string -> ?path:string -> ?path_regex_source:string -> ?path_regex_flags:string -> t -> unit
    val clear_permissions : t -> unit
    val close : ?reason:string -> t -> unit
    val cookies : urls:string array -> t -> NetworkCookie.t array
    val expose_binding : name:string -> t -> Disposable.t
    val grant_permissions : permissions:string array -> ?origin:string -> t -> unit
    val new_page : t -> Page.t
    val register_selector_engine : selector_engine:SelectorEngine.t -> t -> unit
    val set_test_id_attribute_name : test_id_attribute_name:string -> t -> unit
    val set_extra_http_headers : headers:NameValue.t array -> t -> unit
    val set_geolocation : ?geolocation:Geolocation.t -> t -> unit

    module rec Http_credentials : sig type t = {
        username : string [@key "username"];
        password : string [@key "password"];
        origin : string option [@key "origin"] [@default None];
    } [@@deriving yojson]
    end

    val set_http_credentials : ?http_credentials:Http_credentials.t -> t -> unit

    module rec Patterns : sig type t = {
        glob : string option [@key "glob"] [@default None];
        regex_source : string option [@key "regexSource"] [@default None];
        regex_flags : string option [@key "regexFlags"] [@default None];
        url_pattern : URLPattern.t option [@key "urlPattern"] [@default None];
    } [@@deriving yojson]
    end

    val set_network_interception_patterns : patterns:Patterns.t array -> t -> unit
    val set_web_socket_interception_patterns : patterns:Patterns.t array -> t -> unit
    val set_offline : offline:bool -> t -> unit

    module rec StorageStateResult : sig type t = {
        cookies : NetworkCookie.t array [@key "cookies"];
        origins : OriginStorage.t array [@key "origins"];
    } [@@deriving yojson {strict = false}]
    end

    val storage_state : ?indexed_db:bool -> t -> StorageStateResult.t

    module rec Storage_state : sig type t = {
        cookies : SetNetworkCookie.t array option [@key "cookies"] [@default None];
        origins : SetOriginStorage.t array option [@key "origins"] [@default None];
    } [@@deriving yojson]
    end

    val set_storage_state : ?storage_state:Storage_state.t -> t -> unit
    val pause : t -> unit

    module rec Recorder_mode : sig type t = [
        | `Default [@name "default"]
        | `Api [@name "api"]
    ] [@@deriving yojson]
    end

    and Mode : sig type t = [
        | `Inspecting [@name "inspecting"]
        | `Recording [@name "recording"]
    ] [@@deriving yojson]
    end

    val enable_recorder : ?language:string -> ?mode:Mode.t -> ?recorder_mode:Recorder_mode.t -> ?pause_on_next_statement:bool -> ?test_id_attribute_name:string -> ?launch_options:json -> ?context_options:json -> ?device:string -> ?save_storage:string -> ?output_file:string -> ?handle_sigint:bool -> ?omit_call_tracking:bool -> t -> unit
    val disable_recorder : t -> unit
    val expose_console_api : t -> unit
    val new_cdp_session : ?page:Page.t -> ?frame:Frame.t -> t -> CDPSession.t

    module rec CreateTempFilesResult : sig type t = {
        root_dir : WritableStream.t option [@key "rootDir"] [@default None];
        writable_streams : WritableStream.t array [@key "writableStreams"];
    } [@@deriving yojson {strict = false}]
    end

    and Items : sig type t = {
        name : string [@key "name"];
        last_modified_ms : float option [@key "lastModifiedMs"] [@default None];
    } [@@deriving yojson]
    end

    val create_temp_files : ?root_dir_name:string -> items:Items.t array -> t -> CreateTempFilesResult.t

    module rec Event : sig type t = [
        | `Console [@name "console"]
        | `Dialog [@name "dialog"]
        | `Request [@name "request"]
        | `Response [@name "response"]
        | `Request_finished [@name "requestFinished"]
        | `Request_failed [@name "requestFailed"]
    ] [@@deriving yojson]
    end

    val update_subscription : event:Event.t -> enabled:bool -> t -> unit
    val clock_fast_forward : ?ticks_number:float -> ?ticks_string:string -> t -> unit
    val clock_install : ?time_number:float -> ?time_string:string -> t -> unit
    val clock_pause_at : ?time_number:float -> ?time_string:string -> t -> unit
    val clock_resume : t -> unit
    val clock_run_for : ?ticks_number:float -> ?ticks_string:string -> t -> unit
    val clock_set_fixed_time : ?time_number:float -> ?time_string:string -> t -> unit
    val clock_set_system_time : ?time_number:float -> ?time_string:string -> t -> unit
end
and Page : sig
    module rec Wrap : sig type t = {
        main_frame : Frame.t [@key "mainFrame"];
        viewport_size : ViewportSize.t option [@key "viewportSize"] [@default None];
        is_closed : bool [@key "isClosed"];
        opener : Page.t option [@key "opener"] [@default None];
        video : Artifact.t option [@key "video"] [@default None];
    __internal_obj : internal_obj;
    } [@@deriving yojson]

    end

    and ViewportSize : sig type t = {
        width : int [@key "width"];
        height : int [@key "height"];
    } [@@deriving yojson]
    end
    type t = Wrap.t [@@deriving yojson]



    module rec Info : sig type t = {
        wait_id : string [@key "waitId"];
        phase : Phase.t [@key "phase"];
        event : string option [@key "event"] [@default None];
        message : string option [@key "message"] [@default None];
        error : string option [@key "error"] [@default None];
    } [@@deriving yojson]
    end

    and Phase : sig type t = [
        | `Before [@name "before"]
        | `After [@name "after"]
        | `Log [@name "log"]
    ] [@@deriving yojson]
    end

    val wait_for_event_info : info:Info.t -> t -> unit
    val add_init_script : source:string -> t -> Disposable.t
    val close : ?run_before_unload:bool -> ?reason:string -> t -> unit
    val clear_console_messages : t -> unit

    module rec Messages : sig type t = {
        type_ : string [@key "type"];
        text : string [@key "text"];
        args : JSHandle.t array [@key "args"];
        location : Location.t [@key "location"];
        timestamp : float [@key "timestamp"];
    } [@@deriving yojson]
    end

    and Location : sig type t = {
        url : string [@key "url"];
        line_number : int [@key "lineNumber"];
        column_number : int [@key "columnNumber"];
    } [@@deriving yojson]
    end

    val console_messages : ?filter:ConsoleMessagesFilter.t -> t -> Messages.t array

    module rec Contrast : sig type t = [
        | `No_preference [@name "no-preference"]
        | `More [@name "more"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]
    end

    and Forced_colors : sig type t = [
        | `Active [@name "active"]
        | `None [@name "none"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]
    end

    and Reduced_motion : sig type t = [
        | `Reduce [@name "reduce"]
        | `No_preference [@name "no-preference"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]
    end

    and Color_scheme : sig type t = [
        | `Dark [@name "dark"]
        | `Light [@name "light"]
        | `No_preference [@name "no-preference"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]
    end

    and Media : sig type t = [
        | `Screen [@name "screen"]
        | `Print [@name "print"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]
    end

    val emulate_media : ?media:Media.t -> ?color_scheme:Color_scheme.t -> ?reduced_motion:Reduced_motion.t -> ?forced_colors:Forced_colors.t -> ?contrast:Contrast.t -> t -> unit
    val expose_binding : name:string -> t -> Disposable.t
    val go_back : timeout:float -> ?wait_until:LifecycleEvent.t -> t -> Response.t option
    val go_forward : timeout:float -> ?wait_until:LifecycleEvent.t -> t -> Response.t option
    val request_gc : t -> unit
    val register_locator_handler : selector:string -> ?no_wait_after:bool -> t -> int
    val resolve_locator_handler_no_reply : uid:int -> ?remove:bool -> t -> unit
    val unregister_locator_handler : uid:int -> t -> unit
    val reload : timeout:float -> ?wait_until:LifecycleEvent.t -> t -> Response.t option

    module rec ExpectScreenshotResult : sig type t = {
        diff : string option [@key "diff"] [@default None];
        error_message : string option [@key "errorMessage"] [@default None];
        actual : string option [@key "actual"] [@default None];
        previous : string option [@key "previous"] [@default None];
        timed_out : bool option [@key "timedOut"] [@default None];
        log : string array option [@key "log"] [@default None];
    } [@@deriving yojson {strict = false}]
    end

    and Mask : sig type t = {
        frame : Frame.t [@key "frame"];
        selector : string [@key "selector"];
    } [@@deriving yojson]
    end

    and Scale : sig type t = [
        | `Css [@name "css"]
        | `Device [@name "device"]
    ] [@@deriving yojson]
    end

    and Animations : sig type t = [
        | `Disabled [@name "disabled"]
        | `Allow [@name "allow"]
    ] [@@deriving yojson]
    end

    and Caret : sig type t = [
        | `Hide [@name "hide"]
        | `Initial [@name "initial"]
    ] [@@deriving yojson]
    end

    and Locator : sig type t = {
        frame : Frame.t [@key "frame"];
        selector : string [@key "selector"];
    } [@@deriving yojson]
    end

    val expect_screenshot : ?expected:string -> timeout:float -> is_not:bool -> ?locator:Locator.t -> ?comparator:string -> ?max_diff_pixels:int -> ?max_diff_pixel_ratio:float -> ?threshold:float -> ?full_page:bool -> ?clip:Rect.t -> ?omit_background:bool -> ?caret:Caret.t -> ?animations:Animations.t -> ?scale:Scale.t -> ?mask:Mask.t array -> ?mask_color:string -> ?style:string -> t -> ExpectScreenshotResult.t

    module rec Type_ : sig type t = [
        | `Png [@name "png"]
        | `Jpeg [@name "jpeg"]
    ] [@@deriving yojson]
    end

    val screenshot : timeout:float -> ?type_:Type_.t -> ?quality:int -> ?full_page:bool -> ?clip:Rect.t -> ?omit_background:bool -> ?caret:Caret.t -> ?animations:Animations.t -> ?scale:Scale.t -> ?mask:Mask.t array -> ?mask_color:string -> ?style:string -> t -> string
    val set_extra_http_headers : headers:NameValue.t array -> t -> unit

    module rec Patterns : sig type t = {
        glob : string option [@key "glob"] [@default None];
        regex_source : string option [@key "regexSource"] [@default None];
        regex_flags : string option [@key "regexFlags"] [@default None];
        url_pattern : URLPattern.t option [@key "urlPattern"] [@default None];
    } [@@deriving yojson]
    end

    val set_network_interception_patterns : patterns:Patterns.t array -> t -> unit
    val set_web_socket_interception_patterns : patterns:Patterns.t array -> t -> unit

    module rec Viewport_size : sig type t = {
        width : int [@key "width"];
        height : int [@key "height"];
    } [@@deriving yojson]
    end

    val set_viewport_size : viewport_size:Viewport_size.t -> t -> unit
    val keyboard_down : key:string -> t -> unit
    val keyboard_up : key:string -> t -> unit
    val keyboard_insert_text : text:string -> t -> unit
    val keyboard_type : text:string -> ?delay:float -> t -> unit
    val keyboard_press : key:string -> ?delay:float -> t -> unit
    val mouse_move : x:float -> y:float -> ?steps:int -> t -> unit

    module rec Button : sig type t = [
        | `Left [@name "left"]
        | `Right [@name "right"]
        | `Middle [@name "middle"]
    ] [@@deriving yojson]
    end

    val mouse_down : ?button:Button.t -> ?click_count:int -> t -> unit
    val mouse_up : ?button:Button.t -> ?click_count:int -> t -> unit
    val mouse_click : x:float -> y:float -> ?delay:float -> ?button:Button.t -> ?click_count:int -> t -> unit
    val mouse_wheel : delta_x:float -> delta_y:float -> t -> unit
    val touchscreen_tap : x:float -> y:float -> t -> unit
    val clear_page_errors : t -> unit
    val page_errors : ?filter:ConsoleMessagesFilter.t -> t -> SerializedError.t array

    module rec Margin : sig type t = {
        top : string option [@key "top"] [@default None];
        bottom : string option [@key "bottom"] [@default None];
        left : string option [@key "left"] [@default None];
        right : string option [@key "right"] [@default None];
    } [@@deriving yojson]
    end

    val pdf : ?scale:float -> ?display_header_footer:bool -> ?header_template:string -> ?footer_template:string -> ?print_background:bool -> ?landscape:bool -> ?page_ranges:string -> ?format:string -> ?width:string -> ?height:string -> ?prefer_css_page_size:bool -> ?margin:Margin.t -> ?tagged:bool -> ?outline:bool -> t -> string
    val requests : t -> Request.t array
    val start_js_coverage : ?reset_on_navigation:bool -> ?report_anonymous_scripts:bool -> t -> unit

    module rec Entries : sig type t = {
        url : string [@key "url"];
        script_id : string [@key "scriptId"];
        source : string option [@key "source"] [@default None];
        functions : Functions.t array [@key "functions"];
    } [@@deriving yojson]
    end

    and Functions : sig type t = {
        function_name : string [@key "functionName"];
        is_block_coverage : bool [@key "isBlockCoverage"];
        ranges : Ranges.t array [@key "ranges"];
    } [@@deriving yojson]
    end

    and Ranges : sig type t = {
        start_offset : int [@key "startOffset"];
        end_offset : int [@key "endOffset"];
        count : int [@key "count"];
    } [@@deriving yojson]
    end

    val stop_js_coverage : t -> Entries.t array
    val start_css_coverage : ?reset_on_navigation:bool -> t -> unit
    val stop_css_coverage : t -> Entries.t array
    val bring_to_front : t -> unit
    val pick_locator : t -> string
    val cancel_pick_locator : t -> unit
    val hide_highlight : t -> unit
    val screencast_show_overlay : html:string -> ?duration:float -> t -> string
    val screencast_remove_overlay : id:string -> t -> unit
    val screencast_chapter : title:string -> ?description:string -> ?duration:float -> t -> unit
    val screencast_set_overlay_visible : visible:bool -> t -> unit

    module rec Position : sig type t = [
        | `Top_left [@name "top-left"]
        | `Top [@name "top"]
        | `Top_right [@name "top-right"]
        | `Bottom_left [@name "bottom-left"]
        | `Bottom [@name "bottom"]
        | `Bottom_right [@name "bottom-right"]
    ] [@@deriving yojson]
    end

    val screencast_show_actions : ?duration:float -> ?position:Position.t -> ?font_size:int -> t -> unit
    val screencast_hide_actions : t -> unit

    module rec Size : sig type t = {
        width : int [@key "width"];
        height : int [@key "height"];
    } [@@deriving yojson]
    end

    val screencast_start : ?size:Size.t -> ?quality:int -> ?send_frames:bool -> ?record:bool -> t -> Artifact.t option
    val screencast_stop : t -> unit

    module rec Event : sig type t = [
        | `Console [@name "console"]
        | `Dialog [@name "dialog"]
        | `File_chooser [@name "fileChooser"]
        | `Request [@name "request"]
        | `Response [@name "response"]
        | `Request_finished [@name "requestFinished"]
        | `Request_failed [@name "requestFailed"]
    ] [@@deriving yojson]
    end

    val update_subscription : event:Event.t -> enabled:bool -> t -> unit
    val set_dock_tile : image:string -> t -> unit
end
and Frame : sig
    module rec Wrap : sig type t = {
        url : string [@key "url"];
        name : string [@key "name"];
        parent_frame : Frame.t option [@key "parentFrame"] [@default None];
        load_states : LifecycleEvent.t array [@key "loadStates"];
    __internal_obj : internal_obj;
    } [@@deriving yojson]

    end
    type t = Wrap.t [@@deriving yojson]


    val eval_on_selector : selector:string -> ?strict:bool -> expression:string -> ?is_function:bool -> arg:SerializedArgument.t -> t -> SerializedValue.t
    val eval_on_selector_all : selector:string -> expression:string -> ?is_function:bool -> arg:SerializedArgument.t -> t -> SerializedValue.t
    val add_script_tag : ?url:string -> ?content:string -> ?type_:string -> t -> ElementHandle.t
    val add_style_tag : ?url:string -> ?content:string -> t -> ElementHandle.t
    val aria_ref : selector:string -> timeout:float -> t -> string option

    module rec Mode : sig type t = [
        | `Ai [@name "ai"]
        | `Default [@name "default"]
    ] [@@deriving yojson]
    end

    val aria_snapshot : ?mode:Mode.t -> ?track:string -> ?selector:string -> ?depth:int -> ?boxes:bool -> timeout:float -> t -> string
    val blur : selector:string -> ?strict:bool -> timeout:float -> t -> unit
    val check : selector:string -> ?strict:bool -> ?force:bool -> ?position:Point.t -> timeout:float -> ?trial:bool -> t -> unit

    module rec Button : sig type t = [
        | `Left [@name "left"]
        | `Right [@name "right"]
        | `Middle [@name "middle"]
    ] [@@deriving yojson]
    end

    and Modifiers : sig type t = [
        | `Alt [@name "Alt"]
        | `Control [@name "Control"]
        | `Control_or_meta [@name "ControlOrMeta"]
        | `Meta [@name "Meta"]
        | `Shift [@name "Shift"]
    ] [@@deriving yojson]
    end

    val click : selector:string -> ?strict:bool -> ?force:bool -> ?no_wait_after:bool -> ?modifiers:Modifiers.t array -> ?position:Point.t -> ?delay:float -> ?button:Button.t -> ?click_count:int -> timeout:float -> ?trial:bool -> ?steps:int -> t -> unit
    val content : t -> string
    val drag_and_drop : source:string -> target:string -> ?force:bool -> timeout:float -> ?trial:bool -> ?source_position:Point.t -> ?target_position:Point.t -> ?strict:bool -> ?steps:int -> t -> unit

    module rec Data : sig type t = {
        mime_type : string [@key "mimeType"];
        value : string [@key "value"];
    } [@@deriving yojson]
    end

    and Payloads : sig type t = {
        name : string [@key "name"];
        mime_type : string option [@key "mimeType"] [@default None];
        buffer : string [@key "buffer"];
    } [@@deriving yojson]
    end

    val drop : selector:string -> ?strict:bool -> ?position:Point.t -> ?payloads:Payloads.t array -> ?local_paths:string array -> ?streams:WritableStream.t array -> ?data:Data.t array -> timeout:float -> t -> unit
    val dblclick : selector:string -> ?strict:bool -> ?force:bool -> ?modifiers:Modifiers.t array -> ?position:Point.t -> ?delay:float -> ?button:Button.t -> timeout:float -> ?trial:bool -> ?steps:int -> t -> unit
    val dispatch_event : selector:string -> ?strict:bool -> type_:string -> event_init:SerializedArgument.t -> timeout:float -> t -> unit
    val evaluate_expression : expression:string -> ?is_function:bool -> arg:SerializedArgument.t -> t -> SerializedValue.t
    val evaluate_expression_handle : expression:string -> ?is_function:bool -> arg:SerializedArgument.t -> t -> JSHandle.t
    val fill : selector:string -> ?strict:bool -> value:string -> ?force:bool -> timeout:float -> t -> unit
    val focus : selector:string -> ?strict:bool -> timeout:float -> t -> unit
    val frame_element : t -> ElementHandle.t
    val resolve_selector : selector:string -> t -> string
    val highlight : selector:string -> ?style:string -> t -> unit
    val hide_highlight : selector:string -> t -> unit
    val get_attribute : selector:string -> ?strict:bool -> name:string -> timeout:float -> t -> string option
    val goto : url:string -> timeout:float -> ?wait_until:LifecycleEvent.t -> ?referer:string -> t -> Response.t option
    val hover : selector:string -> ?strict:bool -> ?force:bool -> ?modifiers:Modifiers.t array -> ?position:Point.t -> timeout:float -> ?trial:bool -> t -> unit
    val inner_html : selector:string -> ?strict:bool -> timeout:float -> t -> string
    val inner_text : selector:string -> ?strict:bool -> timeout:float -> t -> string
    val input_value : selector:string -> ?strict:bool -> timeout:float -> t -> string
    val is_checked : selector:string -> ?strict:bool -> timeout:float -> t -> bool
    val is_disabled : selector:string -> ?strict:bool -> timeout:float -> t -> bool
    val is_enabled : selector:string -> ?strict:bool -> timeout:float -> t -> bool
    val is_hidden : selector:string -> ?strict:bool -> t -> bool
    val is_visible : selector:string -> ?strict:bool -> t -> bool
    val is_editable : selector:string -> ?strict:bool -> timeout:float -> t -> bool
    val press : selector:string -> ?strict:bool -> key:string -> ?delay:float -> ?no_wait_after:bool -> timeout:float -> t -> unit
    val query_selector : selector:string -> ?strict:bool -> t -> ElementHandle.t option
    val query_selector_all : selector:string -> t -> ElementHandle.t array
    val query_count : selector:string -> t -> int

    module rec Options : sig type t = {
        value_or_label : string option [@key "valueOrLabel"] [@default None];
        value : string option [@key "value"] [@default None];
        label : string option [@key "label"] [@default None];
        index : int option [@key "index"] [@default None];
    } [@@deriving yojson]
    end

    val select_option : selector:string -> ?strict:bool -> ?elements:ElementHandle.t array -> ?options:Options.t array -> ?force:bool -> timeout:float -> t -> string array
    val set_content : html:string -> timeout:float -> ?wait_until:LifecycleEvent.t -> t -> unit
    val set_input_files : selector:string -> ?strict:bool -> ?payloads:Payloads.t array -> ?local_directory:string -> ?directory_stream:WritableStream.t -> ?local_paths:string array -> ?streams:WritableStream.t array -> timeout:float -> t -> unit
    val tap : selector:string -> ?strict:bool -> ?force:bool -> ?modifiers:Modifiers.t array -> ?position:Point.t -> timeout:float -> ?trial:bool -> t -> unit
    val text_content : selector:string -> ?strict:bool -> timeout:float -> t -> string option
    val title : t -> string
    val type_ : selector:string -> ?strict:bool -> text:string -> ?delay:float -> timeout:float -> t -> unit
    val uncheck : selector:string -> ?strict:bool -> ?force:bool -> ?position:Point.t -> timeout:float -> ?trial:bool -> t -> unit
    val wait_for_timeout : wait_timeout:float -> t -> unit
    val wait_for_function : expression:string -> ?is_function:bool -> arg:SerializedArgument.t -> timeout:float -> ?polling_interval:float -> t -> JSHandle.t

    module rec State : sig type t = [
        | `Attached [@name "attached"]
        | `Detached [@name "detached"]
        | `Visible [@name "visible"]
        | `Hidden [@name "hidden"]
    ] [@@deriving yojson]
    end

    val wait_for_selector : selector:string -> ?strict:bool -> timeout:float -> ?state:State.t -> ?omit_return_value:bool -> t -> ElementHandle.t option

    module rec ExpectResult : sig type t = {
        matches : bool [@key "matches"];
        received : Received.t option [@key "received"] [@default None];
        timed_out : bool option [@key "timedOut"] [@default None];
        error_message : string option [@key "errorMessage"] [@default None];
        log : string array option [@key "log"] [@default None];
    } [@@deriving yojson {strict = false}]
    end

    and Received : sig type t = {
        value : SerializedValue.t option [@key "value"] [@default None];
        aria_snapshot : string option [@key "ariaSnapshot"] [@default None];
    } [@@deriving yojson]
    end

    and Pseudo : sig type t = [
        | `Before [@name "before"]
        | `After [@name "after"]
    ] [@@deriving yojson]
    end

    val expect : ?selector:string -> expression:string -> ?expression_arg:json -> ?pseudo:Pseudo.t -> ?expected_text:ExpectedTextValue.t array -> ?expected_number:float -> ?expected_value:SerializedArgument.t -> ?use_inner_text:bool -> is_not:bool -> timeout:float -> t -> ExpectResult.t
end
and Worker : sig
    module rec Wrap : sig type t = {
        url : string [@key "url"];
    __internal_obj : internal_obj;
    } [@@deriving yojson]

    end
    type t = Wrap.t [@@deriving yojson]



    module rec Info : sig type t = {
        wait_id : string [@key "waitId"];
        phase : Phase.t [@key "phase"];
        event : string option [@key "event"] [@default None];
        message : string option [@key "message"] [@default None];
        error : string option [@key "error"] [@default None];
    } [@@deriving yojson]
    end

    and Phase : sig type t = [
        | `Before [@name "before"]
        | `After [@name "after"]
        | `Log [@name "log"]
    ] [@@deriving yojson]
    end

    val wait_for_event_info : info:Info.t -> t -> unit
    val disconnect : ?reason:string -> t -> unit
    val evaluate_expression : expression:string -> ?is_function:bool -> arg:SerializedArgument.t -> t -> SerializedValue.t
    val evaluate_expression_handle : expression:string -> ?is_function:bool -> arg:SerializedArgument.t -> t -> JSHandle.t

    module rec Event : sig type t = [
        | `Console [@name "console"]
    ] [@@deriving yojson]
    end

    val update_subscription : event:Event.t -> enabled:bool -> t -> unit
end
and Disposable : sig
    type t [@@deriving yojson]

    val dispose : t -> unit
end
and JSHandle : sig
    module rec Wrap : sig type t = {
        preview : string [@key "preview"];
    __internal_obj : internal_obj;
    } [@@deriving yojson]

    end
    type t = Wrap.t [@@deriving yojson]


    val dispose : t -> unit
    val evaluate_expression : expression:string -> ?is_function:bool -> arg:SerializedArgument.t -> t -> SerializedValue.t
    val evaluate_expression_handle : expression:string -> ?is_function:bool -> arg:SerializedArgument.t -> t -> JSHandle.t

    module rec Properties : sig type t = {
        name : string [@key "name"];
        value : JSHandle.t [@key "value"];
    } [@@deriving yojson]
    end

    val get_property_list : t -> Properties.t array
    val get_property : name:string -> t -> JSHandle.t
    val json_value : t -> SerializedValue.t
end
and ElementHandle : sig
    type t [@@deriving yojson]

    val dispose : t -> unit
    val evaluate_expression : expression:string -> ?is_function:bool -> arg:SerializedArgument.t -> t -> SerializedValue.t
    val evaluate_expression_handle : expression:string -> ?is_function:bool -> arg:SerializedArgument.t -> t -> JSHandle.t

    module rec Properties : sig type t = {
        name : string [@key "name"];
        value : JSHandle.t [@key "value"];
    } [@@deriving yojson]
    end

    val get_property_list : t -> Properties.t array
    val get_property : name:string -> t -> JSHandle.t
    val json_value : t -> SerializedValue.t
    val eval_on_selector : selector:string -> ?strict:bool -> expression:string -> ?is_function:bool -> arg:SerializedArgument.t -> t -> SerializedValue.t
    val eval_on_selector_all : selector:string -> expression:string -> ?is_function:bool -> arg:SerializedArgument.t -> t -> SerializedValue.t
    val bounding_box : t -> Rect.t option
    val check : ?force:bool -> ?position:Point.t -> timeout:float -> ?trial:bool -> t -> unit

    module rec Button : sig type t = [
        | `Left [@name "left"]
        | `Right [@name "right"]
        | `Middle [@name "middle"]
    ] [@@deriving yojson]
    end

    and Modifiers : sig type t = [
        | `Alt [@name "Alt"]
        | `Control [@name "Control"]
        | `Control_or_meta [@name "ControlOrMeta"]
        | `Meta [@name "Meta"]
        | `Shift [@name "Shift"]
    ] [@@deriving yojson]
    end

    val click : ?force:bool -> ?no_wait_after:bool -> ?modifiers:Modifiers.t array -> ?position:Point.t -> ?delay:float -> ?button:Button.t -> ?click_count:int -> timeout:float -> ?trial:bool -> ?steps:int -> t -> unit
    val content_frame : t -> Frame.t option
    val dblclick : ?force:bool -> ?modifiers:Modifiers.t array -> ?position:Point.t -> ?delay:float -> ?button:Button.t -> timeout:float -> ?trial:bool -> ?steps:int -> t -> unit
    val dispatch_event : type_:string -> event_init:SerializedArgument.t -> t -> unit
    val fill : value:string -> ?force:bool -> timeout:float -> t -> unit
    val focus : t -> unit
    val get_attribute : name:string -> t -> string option
    val hover : ?force:bool -> ?modifiers:Modifiers.t array -> ?position:Point.t -> timeout:float -> ?trial:bool -> t -> unit
    val inner_html : t -> string
    val inner_text : t -> string
    val input_value : t -> string
    val is_checked : t -> bool
    val is_disabled : t -> bool
    val is_editable : t -> bool
    val is_enabled : t -> bool
    val is_hidden : t -> bool
    val is_visible : t -> bool
    val owner_frame : t -> Frame.t option
    val press : key:string -> ?delay:float -> timeout:float -> ?no_wait_after:bool -> t -> unit
    val query_selector : selector:string -> ?strict:bool -> t -> ElementHandle.t option
    val query_selector_all : selector:string -> t -> ElementHandle.t array

    module rec Mask : sig type t = {
        frame : Frame.t [@key "frame"];
        selector : string [@key "selector"];
    } [@@deriving yojson]
    end

    and Scale : sig type t = [
        | `Css [@name "css"]
        | `Device [@name "device"]
    ] [@@deriving yojson]
    end

    and Animations : sig type t = [
        | `Disabled [@name "disabled"]
        | `Allow [@name "allow"]
    ] [@@deriving yojson]
    end

    and Caret : sig type t = [
        | `Hide [@name "hide"]
        | `Initial [@name "initial"]
    ] [@@deriving yojson]
    end

    and Type_ : sig type t = [
        | `Png [@name "png"]
        | `Jpeg [@name "jpeg"]
    ] [@@deriving yojson]
    end

    val screenshot : timeout:float -> ?type_:Type_.t -> ?quality:int -> ?omit_background:bool -> ?caret:Caret.t -> ?animations:Animations.t -> ?scale:Scale.t -> ?mask:Mask.t array -> ?mask_color:string -> ?style:string -> t -> string
    val scroll_into_view_if_needed : timeout:float -> t -> unit

    module rec Options : sig type t = {
        value_or_label : string option [@key "valueOrLabel"] [@default None];
        value : string option [@key "value"] [@default None];
        label : string option [@key "label"] [@default None];
        index : int option [@key "index"] [@default None];
    } [@@deriving yojson]
    end

    val select_option : ?elements:ElementHandle.t array -> ?options:Options.t array -> ?force:bool -> timeout:float -> t -> string array
    val select_text : ?force:bool -> timeout:float -> t -> unit

    module rec Payloads : sig type t = {
        name : string [@key "name"];
        mime_type : string option [@key "mimeType"] [@default None];
        buffer : string [@key "buffer"];
    } [@@deriving yojson]
    end

    val set_input_files : ?payloads:Payloads.t array -> ?local_directory:string -> ?directory_stream:WritableStream.t -> ?local_paths:string array -> ?streams:WritableStream.t array -> timeout:float -> t -> unit
    val tap : ?force:bool -> ?modifiers:Modifiers.t array -> ?position:Point.t -> timeout:float -> ?trial:bool -> t -> unit
    val text_content : t -> string option
    val type_ : text:string -> ?delay:float -> timeout:float -> t -> unit
    val uncheck : ?force:bool -> ?position:Point.t -> timeout:float -> ?trial:bool -> t -> unit

    module rec State : sig type t = [
        | `Visible [@name "visible"]
        | `Hidden [@name "hidden"]
        | `Stable [@name "stable"]
        | `Enabled [@name "enabled"]
        | `Disabled [@name "disabled"]
        | `Editable [@name "editable"]
    ] [@@deriving yojson]
    end

    val wait_for_element_state : state:State.t -> timeout:float -> t -> unit
    val wait_for_selector : selector:string -> ?strict:bool -> timeout:float -> ?state:State.t -> t -> ElementHandle.t option
end
and Request : sig
    module rec Wrap : sig type t = {
        frame : Frame.t option [@key "frame"] [@default None];
        service_worker : Worker.t option [@key "serviceWorker"] [@default None];
        url : string [@key "url"];
        resource_type : string [@key "resourceType"];
        method_ : string [@key "method"];
        post_data : string option [@key "postData"] [@default None];
        headers : NameValue.t array [@key "headers"];
        is_navigation_request : bool [@key "isNavigationRequest"];
        redirected_from : Request.t option [@key "redirectedFrom"] [@default None];
    __internal_obj : internal_obj;
    } [@@deriving yojson]

    end
    type t = Wrap.t [@@deriving yojson]


    val response : t -> Response.t option
    val raw_request_headers : t -> NameValue.t array
end
and Route : sig
    module rec Wrap : sig type t = {
        request : Request.t [@key "request"];
    __internal_obj : internal_obj;
    } [@@deriving yojson]

    end
    type t = Wrap.t [@@deriving yojson]


    val redirect_navigation_request : url:string -> t -> unit
    val abort : ?error_code:string -> t -> unit
    val continue : ?url:string -> ?method_:string -> ?headers:NameValue.t array -> ?post_data:string -> is_fallback:bool -> t -> unit
    val fulfill : ?status:int -> ?headers:NameValue.t array -> ?body:string -> ?is_base64:bool -> ?fetch_response_uid:string -> t -> unit
end
and WebSocketRoute : sig
    module rec Wrap : sig type t = {
        url : string [@key "url"];
        protocols : string array [@key "protocols"];
    __internal_obj : internal_obj;
    } [@@deriving yojson]

    end
    type t = Wrap.t [@@deriving yojson]


    val connect : t -> unit
    val ensure_opened : t -> unit
    val send_to_page : message:string -> is_base64:bool -> t -> unit
    val send_to_server : message:string -> is_base64:bool -> t -> unit
    val close_page : ?code:int -> ?reason:string -> was_clean:bool -> t -> unit
    val close_server : ?code:int -> ?reason:string -> was_clean:bool -> t -> unit
end
and Response : sig
    module rec Wrap : sig type t = {
        request : Request.t [@key "request"];
        url : string [@key "url"];
        status : int [@key "status"];
        status_text : string [@key "statusText"];
        headers : NameValue.t array [@key "headers"];
        timing : ResourceTiming.t [@key "timing"];
        from_service_worker : bool [@key "fromServiceWorker"];
    __internal_obj : internal_obj;
    } [@@deriving yojson]

    end
    type t = Wrap.t [@@deriving yojson]


    val body : t -> string
    val security_details : t -> SecurityDetails.t option
    val server_addr : t -> RemoteAddr.t option
    val raw_response_headers : t -> NameValue.t array
    val http_version : t -> string
    val sizes : t -> RequestSizes.t
end
and WebSocket : sig
    module rec Wrap : sig type t = {
        url : string [@key "url"];
    __internal_obj : internal_obj;
    } [@@deriving yojson]

    end
    type t = Wrap.t [@@deriving yojson]



    module rec Info : sig type t = {
        wait_id : string [@key "waitId"];
        phase : Phase.t [@key "phase"];
        event : string option [@key "event"] [@default None];
        message : string option [@key "message"] [@default None];
        error : string option [@key "error"] [@default None];
    } [@@deriving yojson]
    end

    and Phase : sig type t = [
        | `Before [@name "before"]
        | `After [@name "after"]
        | `Log [@name "log"]
    ] [@@deriving yojson]
    end

    val wait_for_event_info : info:Info.t -> t -> unit
end
and BindingCall : sig
    module rec Wrap : sig type t = {
        frame : Frame.t [@key "frame"];
        name : string [@key "name"];
        args : SerializedValue.t array [@key "args"];
    __internal_obj : internal_obj;
    } [@@deriving yojson]

    end
    type t = Wrap.t [@@deriving yojson]


    val reject : error:SerializedError.t -> t -> unit
    val resolve : result:SerializedArgument.t -> t -> unit
end
and Debugger : sig
    type t [@@deriving yojson]


    module rec Info : sig type t = {
        wait_id : string [@key "waitId"];
        phase : Phase.t [@key "phase"];
        event : string option [@key "event"] [@default None];
        message : string option [@key "message"] [@default None];
        error : string option [@key "error"] [@default None];
    } [@@deriving yojson]
    end

    and Phase : sig type t = [
        | `Before [@name "before"]
        | `After [@name "after"]
        | `Log [@name "log"]
    ] [@@deriving yojson]
    end

    val wait_for_event_info : info:Info.t -> t -> unit
    val request_pause : t -> unit
    val resume : t -> unit
    val next : t -> unit

    module rec Location : sig type t = {
        file : string [@key "file"];
        line : int option [@key "line"] [@default None];
        column : int option [@key "column"] [@default None];
    } [@@deriving yojson]
    end

    val run_to : location:Location.t -> t -> unit
end
and Dialog : sig
    module rec Wrap : sig type t = {
        page : Page.t option [@key "page"] [@default None];
        type_ : string [@key "type"];
        message : string [@key "message"];
        default_value : string [@key "defaultValue"];
    __internal_obj : internal_obj;
    } [@@deriving yojson]

    end
    type t = Wrap.t [@@deriving yojson]


    val accept : ?prompt_text:string -> t -> unit
    val dismiss : t -> unit
end
and Tracing : sig
    type t [@@deriving yojson]

    val tracing_start : ?name:string -> ?snapshots:bool -> ?screenshots:bool -> ?live:bool -> t -> unit
    val tracing_start_chunk : ?name:string -> ?title:string -> t -> string

    module rec Location : sig type t = {
        file : string [@key "file"];
        line : int option [@key "line"] [@default None];
        column : int option [@key "column"] [@default None];
    } [@@deriving yojson]
    end

    val tracing_group : name:string -> ?location:Location.t -> t -> unit
    val tracing_group_end : t -> unit

    module rec TracingStopChunkResult : sig type t = {
        artifact : Artifact.t option [@key "artifact"] [@default None];
        entries : NameValue.t array option [@key "entries"] [@default None];
    } [@@deriving yojson {strict = false}]
    end

    and Mode : sig type t = [
        | `Archive [@name "archive"]
        | `Discard [@name "discard"]
        | `Entries [@name "entries"]
    ] [@@deriving yojson]
    end

    val tracing_stop_chunk : mode:Mode.t -> t -> TracingStopChunkResult.t
    val tracing_stop : t -> unit
    val har_start : ?page:Page.t -> options:RecordHarOptions.t -> t -> string
    val har_export : ?har_id:string -> t -> Artifact.t
end
and Artifact : sig
    module rec Wrap : sig type t = {
        absolute_path : string [@key "absolutePath"];
    __internal_obj : internal_obj;
    } [@@deriving yojson]

    end
    type t = Wrap.t [@@deriving yojson]


    val path_after_finished : t -> string
    val save_as : path:string -> t -> unit
    val save_as_stream : t -> Stream.t
    val failure : t -> string option
    val stream : t -> Stream.t
    val cancel : t -> unit
    val delete : t -> unit
end
and Stream : sig
    type t [@@deriving yojson]

    val read : ?size:int -> t -> string
    val close : t -> unit
end
and WritableStream : sig
    type t [@@deriving yojson]

    val write : binary:string -> t -> unit
    val close : t -> unit
end
and CDPSession : sig
    type t [@@deriving yojson]

    val send : method_:string -> ?params:json -> t -> json
    val detach : t -> unit
end
and Android : sig
    type t [@@deriving yojson]

    val devices : ?host:string -> ?port:int -> ?omit_driver_install:bool -> t -> AndroidDevice.t array
end
and AndroidSocket : sig
    type t [@@deriving yojson]

    val write : data:string -> t -> unit
    val close : t -> unit
end
and AndroidDevice : sig
    module rec Wrap : sig type t = {
        model : string [@key "model"];
        serial : string [@key "serial"];
    __internal_obj : internal_obj;
    } [@@deriving yojson]

    end
    type t = Wrap.t [@@deriving yojson]



    module rec Info : sig type t = {
        wait_id : string [@key "waitId"];
        phase : Phase.t [@key "phase"];
        event : string option [@key "event"] [@default None];
        message : string option [@key "message"] [@default None];
        error : string option [@key "error"] [@default None];
    } [@@deriving yojson]
    end

    and Phase : sig type t = [
        | `Before [@name "before"]
        | `After [@name "after"]
        | `Log [@name "log"]
    ] [@@deriving yojson]
    end

    val wait_for_event_info : info:Info.t -> t -> unit

    module rec State : sig type t = [
        | `Gone [@name "gone"]
    ] [@@deriving yojson]
    end

    val wait : android_selector:AndroidSelector.t -> ?state:State.t -> timeout:float -> t -> unit
    val fill : android_selector:AndroidSelector.t -> text:string -> timeout:float -> t -> unit
    val tap : android_selector:AndroidSelector.t -> ?duration:float -> timeout:float -> t -> unit
    val drag : android_selector:AndroidSelector.t -> dest:Point.t -> ?speed:float -> timeout:float -> t -> unit

    module rec Direction : sig type t = [
        | `Up [@name "up"]
        | `Down [@name "down"]
        | `Left [@name "left"]
        | `Right [@name "right"]
    ] [@@deriving yojson]
    end

    val fling : android_selector:AndroidSelector.t -> direction:Direction.t -> ?speed:float -> timeout:float -> t -> unit
    val long_tap : android_selector:AndroidSelector.t -> timeout:float -> t -> unit
    val pinch_close : android_selector:AndroidSelector.t -> percent:float -> ?speed:float -> timeout:float -> t -> unit
    val pinch_open : android_selector:AndroidSelector.t -> percent:float -> ?speed:float -> timeout:float -> t -> unit
    val scroll : android_selector:AndroidSelector.t -> direction:Direction.t -> percent:float -> ?speed:float -> timeout:float -> t -> unit
    val swipe : android_selector:AndroidSelector.t -> direction:Direction.t -> percent:float -> ?speed:float -> timeout:float -> t -> unit
    val info : android_selector:AndroidSelector.t -> t -> AndroidElementInfo.t
    val screenshot : t -> string
    val input_type : text:string -> t -> unit
    val input_press : key:string -> t -> unit
    val input_tap : point:Point.t -> t -> unit
    val input_swipe : segments:Point.t array -> steps:int -> t -> unit
    val input_drag : from:Point.t -> to_:Point.t -> steps:int -> t -> unit

    module rec Proxy : sig type t = {
        server : string [@key "server"];
        bypass : string option [@key "bypass"] [@default None];
        username : string option [@key "username"] [@default None];
        password : string option [@key "password"] [@default None];
    } [@@deriving yojson]
    end

    and Service_workers : sig type t = [
        | `Allow [@name "allow"]
        | `Block [@name "block"]
    ] [@@deriving yojson]
    end

    and Record_video : sig type t = {
        dir : string option [@key "dir"] [@default None];
        size : Size.t option [@key "size"] [@default None];
        show_actions : ShowActions.t option [@key "showActions"] [@default None];
    } [@@deriving yojson]
    end

    and ShowActions : sig type t = {
        duration : float option [@key "duration"] [@default None];
        position : Position.t option [@key "position"] [@default None];
        font_size : int option [@key "fontSize"] [@default None];
    } [@@deriving yojson]
    end

    and Position : sig type t = [
        | `Top_left [@name "top-left"]
        | `Top [@name "top"]
        | `Top_right [@name "top-right"]
        | `Bottom_left [@name "bottom-left"]
        | `Bottom [@name "bottom"]
        | `Bottom_right [@name "bottom-right"]
    ] [@@deriving yojson]
    end

    and Size : sig type t = {
        width : int [@key "width"];
        height : int [@key "height"];
    } [@@deriving yojson]
    end

    and Contrast : sig type t = [
        | `No_preference [@name "no-preference"]
        | `More [@name "more"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]
    end

    and Accept_downloads : sig type t = [
        | `Accept [@name "accept"]
        | `Deny [@name "deny"]
        | `Internal_browser_default [@name "internal-browser-default"]
    ] [@@deriving yojson]
    end

    and Forced_colors : sig type t = [
        | `Active [@name "active"]
        | `None [@name "none"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]
    end

    and Reduced_motion : sig type t = [
        | `Reduce [@name "reduce"]
        | `No_preference [@name "no-preference"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]
    end

    and Color_scheme : sig type t = [
        | `Dark [@name "dark"]
        | `Light [@name "light"]
        | `No_preference [@name "no-preference"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]
    end

    and Http_credentials : sig type t = {
        username : string [@key "username"];
        password : string [@key "password"];
        origin : string option [@key "origin"] [@default None];
        send : Send.t option [@key "send"] [@default None];
    } [@@deriving yojson]
    end

    and Send : sig type t = [
        | `Always [@name "always"]
        | `Unauthorized [@name "unauthorized"]
    ] [@@deriving yojson]
    end

    and Geolocation : sig type t = {
        longitude : float [@key "longitude"];
        latitude : float [@key "latitude"];
        accuracy : float option [@key "accuracy"] [@default None];
    } [@@deriving yojson]
    end

    and Client_certificates : sig type t = {
        origin : string [@key "origin"];
        cert : string option [@key "cert"] [@default None];
        key : string option [@key "key"] [@default None];
        passphrase : string option [@key "passphrase"] [@default None];
        pfx : string option [@key "pfx"] [@default None];
    } [@@deriving yojson]
    end

    and Screen : sig type t = {
        width : int [@key "width"];
        height : int [@key "height"];
    } [@@deriving yojson]
    end

    and Viewport : sig type t = {
        width : int [@key "width"];
        height : int [@key "height"];
    } [@@deriving yojson]
    end

    val launch_browser : ?no_default_viewport:bool -> ?viewport:Viewport.t -> ?screen:Screen.t -> ?ignore_https_errors:bool -> ?client_certificates:Client_certificates.t array -> ?java_script_enabled:bool -> ?bypass_csp:bool -> ?user_agent:string -> ?locale:string -> ?timezone_id:string -> ?geolocation:Geolocation.t -> ?permissions:string array -> ?extra_http_headers:NameValue.t array -> ?offline:bool -> ?http_credentials:Http_credentials.t -> ?device_scale_factor:float -> ?is_mobile:bool -> ?has_touch:bool -> ?color_scheme:Color_scheme.t -> ?reduced_motion:Reduced_motion.t -> ?forced_colors:Forced_colors.t -> ?accept_downloads:Accept_downloads.t -> ?contrast:Contrast.t -> ?base_url:string -> ?record_video:Record_video.t -> ?strict_selectors:bool -> ?service_workers:Service_workers.t -> ?selector_engines:SelectorEngine.t array -> ?test_id_attribute_name:string -> ?pkg:string -> ?args:string array -> ?proxy:Proxy.t -> t -> BrowserContext.t
    val open_ : command:string -> t -> AndroidSocket.t
    val shell : command:string -> t -> string
    val install_apk : file:string -> ?args:string array -> t -> unit
    val push : file:string -> path:string -> ?mode:int -> t -> unit
    val connect_to_web_view : socket_name:string -> t -> BrowserContext.t
    val close : t -> unit
end
and JsonPipe : sig
    type t [@@deriving yojson]

    val send : message:json -> t -> unit
    val close : t -> unit
end
