[@@@ocaml.warning "-30-39-32"]

type obj = { conn: Connection.t; guid: string }
type any = Yojson.Safe.t
type json = Yojson.Safe.t

module Channel : sig type t = { guid: string } [@@deriving yojson] end
module StackFrame : sig
    type t = {
        file : string;
        line : int;
        column : int;
        function_ : string option;
    }
    [@@deriving yojson {strict = false}]
    
end

module Metadata : sig
    type t = {
        location : location_t option;
        title : string option;
        internal : bool option;
        step_id : string option;
    }
    [@@deriving yojson {strict = false}]
    
    and location_t = {
        file : string;
        line : int option;
        column : int option;
    }
end

module ClientSideCallMetadata : sig
    type t = {
        id : int;
        stack : StackFrame.t array option;
    }
    [@@deriving yojson {strict = false}]
    
end

module Point : sig
    type t = {
        x : float;
        y : float;
    }
    [@@deriving yojson {strict = false}]
    
end

module Rect : sig
    type t = {
        x : float;
        y : float;
        width : float;
        height : float;
    }
    [@@deriving yojson {strict = false}]
    
end

module SerializedValue : sig
    type t = {
        n : float option;
        b : bool option;
        s : string option;
        v : v_t option;
        d : string option;
        u : string option;
        bi : string option;
        ta : ta_t option;
        e : e_t option;
        r : r_t option;
        a : t array option;
        o : o_t array option;
        h : int option;
        id : int option;
        ref : int option;
    }
    [@@deriving yojson {strict = false}]
    
    and o_t = {
        k : string;
        v : t;
    }
    and r_t = {
        p : string;
        f : string;
    }
    and e_t = {
        m : string;
        n : string;
        s : string;
    }
    and ta_t = {
        b : string;
        k : k_t;
    }
    and k_t = [
        | `I8
        | `Ui8
        | `Ui8c
        | `I16
        | `Ui16
        | `I32
        | `Ui32
        | `F32
        | `F64
        | `Bi64
        | `Bui64
    ]

    and v_t = [
        | `Null
        | `Undefined
        | `Nan
        | `Inf
        | `Minus_inf
        | `Minus_zero
    ]

end

module SerializedArgument : sig
    type t = {
        value : SerializedValue.t;
        handles : Channel.t array;
    }
    [@@deriving yojson {strict = false}]
    
end

module ExpectedTextValue : sig
    type t = {
        string : string option;
        regex_source : string option;
        regex_flags : string option;
        match_substring : bool option;
        ignore_case : bool option;
        normalize_white_space : bool option;
    }
    [@@deriving yojson {strict = false}]
    
end

module SelectorEngine : sig
    type t = {
        name : string;
        source : string;
        content_script : bool option;
    }
    [@@deriving yojson {strict = false}]
    
end

module URLPattern : sig
    type t = {
        hash : string;
        hostname : string;
        password : string;
        pathname : string;
        port : string;
        protocol : string;
        search : string;
        username : string;
    }
    [@@deriving yojson {strict = false}]
    
end

module SetNetworkCookie : sig
    type t = {
        name : string;
        value : string;
        url : string option;
        domain : string option;
        path : string option;
        expires : float option;
        http_only : bool option;
        secure : bool option;
        same_site : same_site_t option;
        partition_key : string option;
        cr_has_cross_site_ancestor : bool option;
    }
    [@@deriving yojson {strict = false}]
    
    and same_site_t = [
        | `Strict
        | `Lax
        | `None
    ]

end

module NetworkCookie : sig
    type t = {
        name : string;
        value : string;
        domain : string;
        path : string;
        expires : float;
        http_only : bool;
        secure : bool;
        same_site : same_site_t;
        partition_key : string option;
        cr_has_cross_site_ancestor : bool option;
    }
    [@@deriving yojson {strict = false}]
    
    and same_site_t = [
        | `Strict
        | `Lax
        | `None
    ]

end

module NameValue : sig
    type t = {
        name : string;
        value : string;
    }
    [@@deriving yojson {strict = false}]
    
end

module IndexedDBDatabase : sig
    type t = {
        name : string;
        version : int;
        stores : stores_t array;
    }
    [@@deriving yojson {strict = false}]
    
    and stores_t = {
        name : string;
        auto_increment : bool;
        key_path : string option;
        key_path_array : string array option;
        records : records_t array;
        indexes : indexes_t array;
    }
    and indexes_t = {
        name : string;
        key_path : string option;
        key_path_array : string array option;
        multi_entry : bool;
        unique : bool;
    }
    and records_t = {
        key : json option;
        key_encoded : json option;
        value : json option;
        value_encoded : json option;
    }
end

module SetOriginStorage : sig
    type t = {
        origin : string;
        local_storage : NameValue.t array;
        indexed_db : IndexedDBDatabase.t array option;
    }
    [@@deriving yojson {strict = false}]
    
end

module OriginStorage : sig
    type t = {
        origin : string;
        local_storage : NameValue.t array;
        indexed_db : IndexedDBDatabase.t array option;
    }
    [@@deriving yojson {strict = false}]
    
end

module SerializedError : sig
    type t = {
        error : error_t option;
        value : SerializedValue.t option;
    }
    [@@deriving yojson {strict = false}]
    
    and error_t = {
        message : string;
        name : string;
        stack : string option;
    }
end

module RecordHarOptions : sig
    type t = {
        zip : bool option;
        content : content_t option;
        mode : mode_t option;
        url_glob : string option;
        url_regex_source : string option;
        url_regex_flags : string option;
    }
    [@@deriving yojson {strict = false}]
    
    and mode_t = [
        | `Full
        | `Minimal
    ]

    and content_t = [
        | `Embed
        | `Attach
        | `Omit
    ]

end

module FormField : sig
    type t = {
        name : string;
        value : string option;
        file : file_t option;
    }
    [@@deriving yojson {strict = false}]
    
    and file_t = {
        name : string;
        mime_type : string option;
        buffer : string;
    }
end

module SDKLanguage : sig
    type t = [
        `Javascript
        |         `Python
        |         `Java
        |         `Csharp
    ]
    [@@deriving yojson {strict = false}]
    
end

module APIResponse : sig
    type t = {
        fetch_uid : string;
        url : string;
        status : int;
        status_text : string;
        headers : NameValue.t array;
    }
    [@@deriving yojson {strict = false}]
    
end

module LifecycleEvent : sig
    type t = [
        `Load
        |         `Domcontentloaded
        |         `Networkidle
        |         `Commit
    ]
    [@@deriving yojson {strict = false}]
    
end

module ConsoleMessagesFilter : sig
    type t = [
        `All
        |         `Since_navigation
    ]
    [@@deriving yojson {strict = false}]
    
end

module RecorderSource : sig
    type t = {
        is_recorded : bool;
        id : string;
        label : string;
        text : string;
        language : string;
        highlight : highlight_t array;
        reveal_line : int option;
        group : string option;
    }
    [@@deriving yojson {strict = false}]
    
    and highlight_t = {
        line : int;
        type_ : string;
    }
end

module ResourceTiming : sig
    type t = {
        start_time : float;
        domain_lookup_start : float;
        domain_lookup_end : float;
        connect_start : float;
        secure_connection_start : float;
        connect_end : float;
        request_start : float;
        response_start : float;
    }
    [@@deriving yojson {strict = false}]
    
end

module SecurityDetails : sig
    type t = {
        issuer : string option;
        protocol : string option;
        subject_name : string option;
        valid_from : float option;
        valid_to : float option;
    }
    [@@deriving yojson {strict = false}]
    
end

module RequestSizes : sig
    type t = {
        request_body_size : int;
        request_headers_size : int;
        response_body_size : int;
        response_headers_size : int;
    }
    [@@deriving yojson {strict = false}]
    
end

module RemoteAddr : sig
    type t = {
        ip_address : string;
        port : int;
    }
    [@@deriving yojson {strict = false}]
    
end

module AndroidWebView : sig
    type t = {
        pid : int;
        pkg : string;
        socket_name : string;
    }
    [@@deriving yojson {strict = false}]
    
end

module AndroidSelector : sig
    type t = {
        checkable : bool option;
        checked : bool option;
        clazz : string option;
        clickable : bool option;
        depth : int option;
        desc : string option;
        enabled : bool option;
        focusable : bool option;
        focused : bool option;
        has_child : has_child_t option;
        has_descendant : has_descendant_t option;
        long_clickable : bool option;
        pkg : string option;
        res : string option;
        scrollable : bool option;
        selected : bool option;
        text : string option;
    }
    [@@deriving yojson {strict = false}]
    
    and has_descendant_t = {
        android_selector : t;
        max_depth : int option;
    }
    and has_child_t = {
        android_selector : t;
    }
end

module AndroidElementInfo : sig
    type t = {
        children : t array option;
        clazz : string;
        desc : string;
        res : string;
        pkg : string;
        text : string;
        bounds : Rect.t;
        checkable : bool;
        checked : bool;
        clickable : bool;
        enabled : bool;
        focusable : bool;
        focused : bool;
        long_clickable : bool;
        scrollable : bool;
        selected : bool;
    }
    [@@deriving yojson {strict = false}]
    
end

module rec APIRequestContext : sig
    type t = {
        tracing : Tracing.t;
        __internal_obj : obj
    }
    [@@deriving yojson {strict = false}]



    val fetch : url:string -> ?encoded_params:string -> ?params:NameValue.t array -> ?method_:string -> ?headers:NameValue.t array -> ?post_data:string -> ?json_data:string -> ?form_data:NameValue.t array -> ?multipart_data:FormField.t array -> timeout:float -> ?fail_on_status_code:bool -> ?ignore_https_errors:bool -> ?max_redirects:int -> ?max_retries:int -> t -> APIResponse.t
    val fetch_response_body : fetch_uid:string -> t -> string option
    val fetch_log : fetch_uid:string -> t -> string array

    type storage_state_res_t = {
        cookies : NetworkCookie.t array;
        origins : OriginStorage.t array;
    }

    val storage_state : ?indexed_db:bool -> t -> storage_state_res_t
    val dispose_api_response : fetch_uid:string -> t -> unit
    val dispose : ?reason:string -> t -> unit
end
and LocalUtils : sig
    type t = {
        device_descriptors : device_descriptors_t array;
        __internal_obj : obj
    }
    [@@deriving yojson {strict = false}]


    and device_descriptors_t = {
        name : string;
        descriptor : descriptor_t;
    }
    and descriptor_t = {
        user_agent : string;
        viewport : viewport_t;
        screen : screen_t option;
        device_scale_factor : float;
        is_mobile : bool;
        has_touch : bool;
        default_browser_type : default_browser_type_t;
    }
    and default_browser_type_t = [
        | `Chromium
        | `Firefox
        | `Webkit
    ]

    and screen_t = {
        width : int;
        height : int;
    }
    and viewport_t = {
        width : int;
        height : int;
    }


    type mode_t = [
        | `Write
        | `Append
    ]


    val zip : zip_file:string -> entries:NameValue.t array -> ?stacks_id:string -> mode:mode_t -> include_sources:bool -> ?additional_sources:string array -> t -> unit

    type har_open_res_t = {
        har_id : string option;
        error : string option;
    }

    val har_open : file:string -> t -> har_open_res_t

    type har_lookup_res_t = {
        action : action_t;
        message : string option;
        redirect_url : string option;
        status : int option;
        headers : NameValue.t array option;
        body : string option;
    }

    and action_t = [
        | `Error
        | `Redirect
        | `Fulfill
        | `Noentry
    ]


    val har_lookup : har_id:string -> url:string -> method_:string -> headers:NameValue.t array -> ?post_data:string -> is_navigation_request:bool -> t -> har_lookup_res_t
    val har_close : har_id:string -> t -> unit
    val har_unzip : zip_file:string -> har_file:string -> t -> unit

    type connect_res_t = {
        pipe : JsonPipe.t;
        headers : NameValue.t array;
    }

    val connect : endpoint:string -> ?headers:json -> ?expose_network:string -> ?slow_mo:float -> timeout:float -> ?socks_proxy_redirect_port_for_test:int -> t -> connect_res_t
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
    type t = {
        chromium : BrowserType.t;
        firefox : BrowserType.t;
        webkit : BrowserType.t;
        android : Android.t;
        utils : LocalUtils.t option;
        pre_launched_browser : Browser.t option;
        pre_connected_android_device : AndroidDevice.t option;
        socks_support : SocksSupport.t option;
        __internal_obj : obj
    }
    [@@deriving yojson {strict = false}]




    type storage_state_t = {
        cookies : NetworkCookie.t array option;
        origins : SetOriginStorage.t array option;
    }

    and proxy_t = {
        server : string;
        bypass : string option;
        username : string option;
        password : string option;
    }

    and http_credentials_t = {
        username : string;
        password : string;
        origin : string option;
        send : send_t option;
    }

    and send_t = [
        | `Always
        | `Unauthorized
    ]


    and client_certificates_t = {
        origin : string;
        cert : string option;
        key : string option;
        passphrase : string option;
        pfx : string option;
    }

    val new_request : ?base_url:string -> ?user_agent:string -> ?ignore_https_errors:bool -> ?extra_http_headers:NameValue.t array -> ?fail_on_status_code:bool -> ?client_certificates:client_certificates_t array -> ?max_redirects:int -> ?http_credentials:http_credentials_t -> ?proxy:proxy_t -> ?storage_state:storage_state_t -> ?traces_dir:string -> t -> APIRequestContext.t
end
and DebugController : sig
    type t [@@deriving yojson]

    val initialize : codegen_id:string -> sdk_language:SDKLanguage.t -> t -> unit
    val set_report_state_changed : enabled:bool -> t -> unit

    type mode_t = [
        | `Inspecting
        | `Recording
        | `None
    ]


    val set_recorder_mode : mode:mode_t -> ?test_id_attribute_name:string -> ?generate_auto_expect:bool -> t -> unit
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
    type t = {
        executable_path : string;
        name : string;
        __internal_obj : obj
    }
    [@@deriving yojson {strict = false}]




    type proxy_t = {
        server : string;
        bypass : string option;
        username : string option;
        password : string option;
    }

    val launch : ?channel:string -> ?executable_path:string -> ?args:string array -> ?ignore_all_default_args:bool -> ?ignore_default_args:string array -> ?handle_sigint:bool -> ?handle_sigterm:bool -> ?handle_sighup:bool -> timeout:float -> ?env:NameValue.t array -> ?headless:bool -> ?proxy:proxy_t -> ?downloads_path:string -> ?traces_dir:string -> ?artifacts_dir:string -> ?chromium_sandbox:bool -> ?firefox_user_prefs:json -> ?cdp_port:int -> ?slow_mo:float -> t -> Browser.t

    type launch_persistent_context_res_t = {
        browser : Browser.t;
        context : BrowserContext.t;
    }

    and service_workers_t = [
        | `Allow
        | `Block
    ]


    and record_video_t = {
        dir : string option;
        size : size_t option;
        show_actions : show_actions_t option;
    }

    and show_actions_t = {
        duration : float option;
        position : position_t option;
        font_size : int option;
    }

    and position_t = [
        | `Top_left
        | `Top
        | `Top_right
        | `Bottom_left
        | `Bottom
        | `Bottom_right
    ]


    and size_t = {
        width : int;
        height : int;
    }

    and contrast_t = [
        | `No_preference
        | `More
        | `No_override
    ]


    and accept_downloads_t = [
        | `Accept
        | `Deny
        | `Internal_browser_default
    ]


    and forced_colors_t = [
        | `Active
        | `None
        | `No_override
    ]


    and reduced_motion_t = [
        | `Reduce
        | `No_preference
        | `No_override
    ]


    and color_scheme_t = [
        | `Dark
        | `Light
        | `No_preference
        | `No_override
    ]


    and http_credentials_t = {
        username : string;
        password : string;
        origin : string option;
        send : send_t option;
    }

    and send_t = [
        | `Always
        | `Unauthorized
    ]


    and geolocation_t = {
        longitude : float;
        latitude : float;
        accuracy : float option;
    }

    and client_certificates_t = {
        origin : string;
        cert : string option;
        key : string option;
        passphrase : string option;
        pfx : string option;
    }

    and screen_t = {
        width : int;
        height : int;
    }

    and viewport_t = {
        width : int;
        height : int;
    }

    val launch_persistent_context : ?channel:string -> ?executable_path:string -> ?args:string array -> ?ignore_all_default_args:bool -> ?ignore_default_args:string array -> ?handle_sigint:bool -> ?handle_sigterm:bool -> ?handle_sighup:bool -> timeout:float -> ?env:NameValue.t array -> ?headless:bool -> ?proxy:proxy_t -> ?downloads_path:string -> ?traces_dir:string -> ?artifacts_dir:string -> ?chromium_sandbox:bool -> ?firefox_user_prefs:json -> ?cdp_port:int -> ?no_default_viewport:bool -> ?viewport:viewport_t -> ?screen:screen_t -> ?ignore_https_errors:bool -> ?client_certificates:client_certificates_t array -> ?java_script_enabled:bool -> ?bypass_csp:bool -> ?user_agent:string -> ?locale:string -> ?timezone_id:string -> ?geolocation:geolocation_t -> ?permissions:string array -> ?extra_http_headers:NameValue.t array -> ?offline:bool -> ?http_credentials:http_credentials_t -> ?device_scale_factor:float -> ?is_mobile:bool -> ?has_touch:bool -> ?color_scheme:color_scheme_t -> ?reduced_motion:reduced_motion_t -> ?forced_colors:forced_colors_t -> ?accept_downloads:accept_downloads_t -> ?contrast:contrast_t -> ?base_url:string -> ?record_video:record_video_t -> ?strict_selectors:bool -> ?service_workers:service_workers_t -> ?selector_engines:SelectorEngine.t array -> ?test_id_attribute_name:string -> user_data_dir:string -> ?slow_mo:float -> t -> launch_persistent_context_res_t

    type connect_over_cdp_res_t = {
        browser : Browser.t;
        default_context : BrowserContext.t option;
    }

    val connect_over_cdp : endpoint_url:string -> ?headers:NameValue.t array -> ?slow_mo:float -> timeout:float -> ?is_local:bool -> ?no_defaults:bool -> t -> connect_over_cdp_res_t
    val connect_to_worker : endpoint:string -> timeout:float -> t -> Worker.t
end
and Browser : sig
    type t = {
        version : string;
        name : string;
        browser_name : browser_name_t;
        __internal_obj : obj
    }
    [@@deriving yojson {strict = false}]


    and browser_name_t = [
        | `Chromium
        | `Firefox
        | `Webkit
    ]


    val start_server : title:string -> ?workspace_dir:string -> ?metadata:json -> ?host:string -> ?port:int -> t -> string
    val stop_server : t -> unit
    val close : ?reason:string -> t -> unit
    val kill_for_tests : t -> unit
    val default_user_agent_for_test : t -> string

    type storage_state_t = {
        cookies : SetNetworkCookie.t array option;
        origins : SetOriginStorage.t array option;
    }

    and proxy_t = {
        server : string;
        bypass : string option;
        username : string option;
        password : string option;
    }

    and service_workers_t = [
        | `Allow
        | `Block
    ]


    and record_video_t = {
        dir : string option;
        size : size_t option;
        show_actions : show_actions_t option;
    }

    and show_actions_t = {
        duration : float option;
        position : position_t option;
        font_size : int option;
    }

    and position_t = [
        | `Top_left
        | `Top
        | `Top_right
        | `Bottom_left
        | `Bottom
        | `Bottom_right
    ]


    and size_t = {
        width : int;
        height : int;
    }

    and contrast_t = [
        | `No_preference
        | `More
        | `No_override
    ]


    and accept_downloads_t = [
        | `Accept
        | `Deny
        | `Internal_browser_default
    ]


    and forced_colors_t = [
        | `Active
        | `None
        | `No_override
    ]


    and reduced_motion_t = [
        | `Reduce
        | `No_preference
        | `No_override
    ]


    and color_scheme_t = [
        | `Dark
        | `Light
        | `No_preference
        | `No_override
    ]


    and http_credentials_t = {
        username : string;
        password : string;
        origin : string option;
        send : send_t option;
    }

    and send_t = [
        | `Always
        | `Unauthorized
    ]


    and geolocation_t = {
        longitude : float;
        latitude : float;
        accuracy : float option;
    }

    and client_certificates_t = {
        origin : string;
        cert : string option;
        key : string option;
        passphrase : string option;
        pfx : string option;
    }

    and screen_t = {
        width : int;
        height : int;
    }

    and viewport_t = {
        width : int;
        height : int;
    }

    val new_context : ?no_default_viewport:bool -> ?viewport:viewport_t -> ?screen:screen_t -> ?ignore_https_errors:bool -> ?client_certificates:client_certificates_t array -> ?java_script_enabled:bool -> ?bypass_csp:bool -> ?user_agent:string -> ?locale:string -> ?timezone_id:string -> ?geolocation:geolocation_t -> ?permissions:string array -> ?extra_http_headers:NameValue.t array -> ?offline:bool -> ?http_credentials:http_credentials_t -> ?device_scale_factor:float -> ?is_mobile:bool -> ?has_touch:bool -> ?color_scheme:color_scheme_t -> ?reduced_motion:reduced_motion_t -> ?forced_colors:forced_colors_t -> ?accept_downloads:accept_downloads_t -> ?contrast:contrast_t -> ?base_url:string -> ?record_video:record_video_t -> ?strict_selectors:bool -> ?service_workers:service_workers_t -> ?selector_engines:SelectorEngine.t array -> ?test_id_attribute_name:string -> ?proxy:proxy_t -> ?storage_state:storage_state_t -> t -> BrowserContext.t
    val new_context_for_reuse : ?no_default_viewport:bool -> ?viewport:viewport_t -> ?screen:screen_t -> ?ignore_https_errors:bool -> ?client_certificates:client_certificates_t array -> ?java_script_enabled:bool -> ?bypass_csp:bool -> ?user_agent:string -> ?locale:string -> ?timezone_id:string -> ?geolocation:geolocation_t -> ?permissions:string array -> ?extra_http_headers:NameValue.t array -> ?offline:bool -> ?http_credentials:http_credentials_t -> ?device_scale_factor:float -> ?is_mobile:bool -> ?has_touch:bool -> ?color_scheme:color_scheme_t -> ?reduced_motion:reduced_motion_t -> ?forced_colors:forced_colors_t -> ?accept_downloads:accept_downloads_t -> ?contrast:contrast_t -> ?base_url:string -> ?record_video:record_video_t -> ?strict_selectors:bool -> ?service_workers:service_workers_t -> ?selector_engines:SelectorEngine.t array -> ?test_id_attribute_name:string -> ?proxy:proxy_t -> ?storage_state:storage_state_t -> t -> BrowserContext.t
    val disconnect_from_reused_context : reason:string -> t -> unit
    val new_browser_cdp_session : t -> CDPSession.t
    val start_tracing : ?page:Page.t -> ?screenshots:bool -> ?categories:string array -> t -> unit
    val stop_tracing : t -> Artifact.t
end
and EventTarget : sig
    type t [@@deriving yojson]


    type info_t = {
        wait_id : string;
        phase : phase_t;
        event : string option;
        message : string option;
        error : string option;
    }

    and phase_t = [
        | `Before
        | `After
        | `Log
    ]


    val wait_for_event_info : info:info_t -> t -> unit
end
and BrowserContext : sig
    type t = {
        debugger : Debugger.t;
        request_context : APIRequestContext.t;
        tracing : Tracing.t;
        options : options_t;
        __internal_obj : obj
    }
    [@@deriving yojson {strict = false}]


    and options_t = {
        no_default_viewport : bool option;
        viewport : viewport_t option;
        screen : screen_t option;
        ignore_https_errors : bool option;
        client_certificates : client_certificates_t array option;
        java_script_enabled : bool option;
        bypass_csp : bool option;
        user_agent : string option;
        locale : string option;
        timezone_id : string option;
        geolocation : geolocation_t option;
        permissions : string array option;
        extra_http_headers : NameValue.t array option;
        offline : bool option;
        http_credentials : http_credentials_t option;
        device_scale_factor : float option;
        is_mobile : bool option;
        has_touch : bool option;
        color_scheme : color_scheme_t option;
        reduced_motion : reduced_motion_t option;
        forced_colors : forced_colors_t option;
        accept_downloads : accept_downloads_t option;
        contrast : contrast_t option;
        base_url : string option;
        record_video : record_video_t option;
        strict_selectors : bool option;
        service_workers : service_workers_t option;
        selector_engines : SelectorEngine.t array option;
        test_id_attribute_name : string option;
    }
    and service_workers_t = [
        | `Allow
        | `Block
    ]

    and record_video_t = {
        dir : string option;
        size : size_t option;
        show_actions : show_actions_t option;
    }
    and show_actions_t = {
        duration : float option;
        position : position_t option;
        font_size : int option;
    }
    and position_t = [
        | `Top_left
        | `Top
        | `Top_right
        | `Bottom_left
        | `Bottom
        | `Bottom_right
    ]

    and size_t = {
        width : int;
        height : int;
    }
    and contrast_t = [
        | `No_preference
        | `More
        | `No_override
    ]

    and accept_downloads_t = [
        | `Accept
        | `Deny
        | `Internal_browser_default
    ]

    and forced_colors_t = [
        | `Active
        | `None
        | `No_override
    ]

    and reduced_motion_t = [
        | `Reduce
        | `No_preference
        | `No_override
    ]

    and color_scheme_t = [
        | `Dark
        | `Light
        | `No_preference
        | `No_override
    ]

    and http_credentials_t = {
        username : string;
        password : string;
        origin : string option;
        send : send_t option;
    }
    and send_t = [
        | `Always
        | `Unauthorized
    ]

    and geolocation_t = {
        longitude : float;
        latitude : float;
        accuracy : float option;
    }
    and client_certificates_t = {
        origin : string;
        cert : string option;
        key : string option;
        passphrase : string option;
        pfx : string option;
    }
    and screen_t = {
        width : int;
        height : int;
    }
    and viewport_t = {
        width : int;
        height : int;
    }


    type info_t = {
        wait_id : string;
        phase : phase_t;
        event : string option;
        message : string option;
        error : string option;
    }

    and phase_t = [
        | `Before
        | `After
        | `Log
    ]


    val wait_for_event_info : info:info_t -> t -> unit
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
    val set_geolocation : ?geolocation:geolocation_t -> t -> unit
    val set_http_credentials : ?http_credentials:http_credentials_t -> t -> unit

    type patterns_t = {
        glob : string option;
        regex_source : string option;
        regex_flags : string option;
        url_pattern : URLPattern.t option;
    }

    val set_network_interception_patterns : patterns:patterns_t array -> t -> unit
    val set_web_socket_interception_patterns : patterns:patterns_t array -> t -> unit
    val set_offline : offline:bool -> t -> unit

    type storage_state_res_t = {
        cookies : NetworkCookie.t array;
        origins : OriginStorage.t array;
    }

    val storage_state : ?indexed_db:bool -> t -> storage_state_res_t

    type storage_state_t = {
        cookies : SetNetworkCookie.t array option;
        origins : SetOriginStorage.t array option;
    }

    val set_storage_state : ?storage_state:storage_state_t -> t -> unit
    val pause : t -> unit

    type recorder_mode_t = [
        | `Default
        | `Api
    ]


    and mode_t = [
        | `Inspecting
        | `Recording
    ]


    val enable_recorder : ?language:string -> ?mode:mode_t -> ?recorder_mode:recorder_mode_t -> ?pause_on_next_statement:bool -> ?test_id_attribute_name:string -> ?launch_options:json -> ?context_options:json -> ?device:string -> ?save_storage:string -> ?output_file:string -> ?handle_sigint:bool -> ?omit_call_tracking:bool -> t -> unit
    val disable_recorder : t -> unit
    val expose_console_api : t -> unit
    val new_cdp_session : ?page:Page.t -> ?frame:Frame.t -> t -> CDPSession.t

    type create_temp_files_res_t = {
        root_dir : WritableStream.t option;
        writable_streams : WritableStream.t array;
    }

    and items_t = {
        name : string;
        last_modified_ms : float option;
    }

    val create_temp_files : ?root_dir_name:string -> items:items_t array -> t -> create_temp_files_res_t

    type event_t = [
        | `Console
        | `Dialog
        | `Request
        | `Response
        | `Request_finished
        | `Request_failed
    ]


    val update_subscription : event:event_t -> enabled:bool -> t -> unit
    val clock_fast_forward : ?ticks_number:float -> ?ticks_string:string -> t -> unit
    val clock_install : ?time_number:float -> ?time_string:string -> t -> unit
    val clock_pause_at : ?time_number:float -> ?time_string:string -> t -> unit
    val clock_resume : t -> unit
    val clock_run_for : ?ticks_number:float -> ?ticks_string:string -> t -> unit
    val clock_set_fixed_time : ?time_number:float -> ?time_string:string -> t -> unit
    val clock_set_system_time : ?time_number:float -> ?time_string:string -> t -> unit
end
and Page : sig
    type t = {
        main_frame : Frame.t;
        viewport_size : viewport_size_t option;
        is_closed : bool;
        opener : Page.t option;
        video : Artifact.t option;
        __internal_obj : obj
    }
    [@@deriving yojson {strict = false}]


    and viewport_size_t = {
        width : int;
        height : int;
    }


    type info_t = {
        wait_id : string;
        phase : phase_t;
        event : string option;
        message : string option;
        error : string option;
    }

    and phase_t = [
        | `Before
        | `After
        | `Log
    ]


    val wait_for_event_info : info:info_t -> t -> unit
    val add_init_script : source:string -> t -> Disposable.t
    val close : ?run_before_unload:bool -> ?reason:string -> t -> unit
    val clear_console_messages : t -> unit

    type messages_t = {
        type_ : string;
        text : string;
        args : JSHandle.t array;
        location : location_t;
        timestamp : float;
    }

    and location_t = {
        url : string;
        line_number : int;
        column_number : int;
    }

    val console_messages : ?filter:ConsoleMessagesFilter.t -> t -> messages_t array

    type contrast_t = [
        | `No_preference
        | `More
        | `No_override
    ]


    and forced_colors_t = [
        | `Active
        | `None
        | `No_override
    ]


    and reduced_motion_t = [
        | `Reduce
        | `No_preference
        | `No_override
    ]


    and color_scheme_t = [
        | `Dark
        | `Light
        | `No_preference
        | `No_override
    ]


    and media_t = [
        | `Screen
        | `Print
        | `No_override
    ]


    val emulate_media : ?media:media_t -> ?color_scheme:color_scheme_t -> ?reduced_motion:reduced_motion_t -> ?forced_colors:forced_colors_t -> ?contrast:contrast_t -> t -> unit
    val expose_binding : name:string -> t -> Disposable.t
    val go_back : timeout:float -> ?wait_until:LifecycleEvent.t -> t -> Response.t option
    val go_forward : timeout:float -> ?wait_until:LifecycleEvent.t -> t -> Response.t option
    val request_gc : t -> unit
    val register_locator_handler : selector:string -> ?no_wait_after:bool -> t -> int
    val resolve_locator_handler_no_reply : uid:int -> ?remove:bool -> t -> unit
    val unregister_locator_handler : uid:int -> t -> unit
    val reload : timeout:float -> ?wait_until:LifecycleEvent.t -> t -> Response.t option

    type expect_screenshot_res_t = {
        diff : string option;
        error_message : string option;
        actual : string option;
        previous : string option;
        timed_out : bool option;
        log : string array option;
    }

    and mask_t = {
        frame : Frame.t;
        selector : string;
    }

    and scale_t = [
        | `Css
        | `Device
    ]


    and animations_t = [
        | `Disabled
        | `Allow
    ]


    and caret_t = [
        | `Hide
        | `Initial
    ]


    and locator_t = {
        frame : Frame.t;
        selector : string;
    }

    val expect_screenshot : ?expected:string -> timeout:float -> is_not:bool -> ?locator:locator_t -> ?comparator:string -> ?max_diff_pixels:int -> ?max_diff_pixel_ratio:float -> ?threshold:float -> ?full_page:bool -> ?clip:Rect.t -> ?omit_background:bool -> ?caret:caret_t -> ?animations:animations_t -> ?scale:scale_t -> ?mask:mask_t array -> ?mask_color:string -> ?style:string -> t -> expect_screenshot_res_t

    type type__t = [
        | `Png
        | `Jpeg
    ]


    val screenshot : timeout:float -> ?type_:type__t -> ?quality:int -> ?full_page:bool -> ?clip:Rect.t -> ?omit_background:bool -> ?caret:caret_t -> ?animations:animations_t -> ?scale:scale_t -> ?mask:mask_t array -> ?mask_color:string -> ?style:string -> t -> string
    val set_extra_http_headers : headers:NameValue.t array -> t -> unit

    type patterns_t = {
        glob : string option;
        regex_source : string option;
        regex_flags : string option;
        url_pattern : URLPattern.t option;
    }

    val set_network_interception_patterns : patterns:patterns_t array -> t -> unit
    val set_web_socket_interception_patterns : patterns:patterns_t array -> t -> unit
    val set_viewport_size : viewport_size:viewport_size_t -> t -> unit
    val keyboard_down : key:string -> t -> unit
    val keyboard_up : key:string -> t -> unit
    val keyboard_insert_text : text:string -> t -> unit
    val keyboard_type : text:string -> ?delay:float -> t -> unit
    val keyboard_press : key:string -> ?delay:float -> t -> unit
    val mouse_move : x:float -> y:float -> ?steps:int -> t -> unit

    type button_t = [
        | `Left
        | `Right
        | `Middle
    ]


    val mouse_down : ?button:button_t -> ?click_count:int -> t -> unit
    val mouse_up : ?button:button_t -> ?click_count:int -> t -> unit
    val mouse_click : x:float -> y:float -> ?delay:float -> ?button:button_t -> ?click_count:int -> t -> unit
    val mouse_wheel : delta_x:float -> delta_y:float -> t -> unit
    val touchscreen_tap : x:float -> y:float -> t -> unit
    val clear_page_errors : t -> unit
    val page_errors : ?filter:ConsoleMessagesFilter.t -> t -> SerializedError.t array

    type margin_t = {
        top : string option;
        bottom : string option;
        left : string option;
        right : string option;
    }

    val pdf : ?scale:float -> ?display_header_footer:bool -> ?header_template:string -> ?footer_template:string -> ?print_background:bool -> ?landscape:bool -> ?page_ranges:string -> ?format:string -> ?width:string -> ?height:string -> ?prefer_css_page_size:bool -> ?margin:margin_t -> ?tagged:bool -> ?outline:bool -> t -> string
    val requests : t -> Request.t array
    val start_js_coverage : ?reset_on_navigation:bool -> ?report_anonymous_scripts:bool -> t -> unit

    type entries_t = {
        url : string;
        script_id : string;
        source : string option;
        functions : functions_t array;
    }

    and functions_t = {
        function_name : string;
        is_block_coverage : bool;
        ranges : ranges_t array;
    }

    and ranges_t = {
        start_offset : int;
        end_offset : int;
        count : int;
    }

    val stop_js_coverage : t -> entries_t array
    val start_css_coverage : ?reset_on_navigation:bool -> t -> unit
    val stop_css_coverage : t -> entries_t array
    val bring_to_front : t -> unit
    val pick_locator : t -> string
    val cancel_pick_locator : t -> unit
    val hide_highlight : t -> unit
    val screencast_show_overlay : html:string -> ?duration:float -> t -> string
    val screencast_remove_overlay : id:string -> t -> unit
    val screencast_chapter : title:string -> ?description:string -> ?duration:float -> t -> unit
    val screencast_set_overlay_visible : visible:bool -> t -> unit

    type position_t = [
        | `Top_left
        | `Top
        | `Top_right
        | `Bottom_left
        | `Bottom
        | `Bottom_right
    ]


    val screencast_show_actions : ?duration:float -> ?position:position_t -> ?font_size:int -> t -> unit
    val screencast_hide_actions : t -> unit

    type size_t = {
        width : int;
        height : int;
    }

    val screencast_start : ?size:size_t -> ?quality:int -> ?send_frames:bool -> ?record:bool -> t -> Artifact.t option
    val screencast_stop : t -> unit

    type event_t = [
        | `Console
        | `Dialog
        | `File_chooser
        | `Request
        | `Response
        | `Request_finished
        | `Request_failed
    ]


    val update_subscription : event:event_t -> enabled:bool -> t -> unit
    val set_dock_tile : image:string -> t -> unit
end
and Frame : sig
    type t = {
        url : string;
        name : string;
        parent_frame : Frame.t option;
        load_states : LifecycleEvent.t array;
        __internal_obj : obj
    }
    [@@deriving yojson {strict = false}]



    val eval_on_selector : selector:string -> ?strict:bool -> expression:string -> ?is_function:bool -> arg:SerializedArgument.t -> t -> SerializedValue.t
    val eval_on_selector_all : selector:string -> expression:string -> ?is_function:bool -> arg:SerializedArgument.t -> t -> SerializedValue.t
    val add_script_tag : ?url:string -> ?content:string -> ?type_:string -> t -> ElementHandle.t
    val add_style_tag : ?url:string -> ?content:string -> t -> ElementHandle.t
    val aria_ref : selector:string -> timeout:float -> t -> string option

    type mode_t = [
        | `Ai
        | `Default
    ]


    val aria_snapshot : ?mode:mode_t -> ?track:string -> ?selector:string -> ?depth:int -> ?boxes:bool -> timeout:float -> t -> string
    val blur : selector:string -> ?strict:bool -> timeout:float -> t -> unit
    val check : selector:string -> ?strict:bool -> ?force:bool -> ?position:Point.t -> timeout:float -> ?trial:bool -> t -> unit

    type button_t = [
        | `Left
        | `Right
        | `Middle
    ]


    and modifiers_t = [
        | `Alt
        | `Control
        | `Control_or_meta
        | `Meta
        | `Shift
    ]


    val click : selector:string -> ?strict:bool -> ?force:bool -> ?no_wait_after:bool -> ?modifiers:modifiers_t array -> ?position:Point.t -> ?delay:float -> ?button:button_t -> ?click_count:int -> timeout:float -> ?trial:bool -> ?steps:int -> t -> unit
    val content : t -> string
    val drag_and_drop : source:string -> target:string -> ?force:bool -> timeout:float -> ?trial:bool -> ?source_position:Point.t -> ?target_position:Point.t -> ?strict:bool -> ?steps:int -> t -> unit

    type data_t = {
        mime_type : string;
        value : string;
    }

    and payloads_t = {
        name : string;
        mime_type : string option;
        buffer : string;
    }

    val drop : selector:string -> ?strict:bool -> ?position:Point.t -> ?payloads:payloads_t array -> ?local_paths:string array -> ?streams:WritableStream.t array -> ?data:data_t array -> timeout:float -> t -> unit
    val dblclick : selector:string -> ?strict:bool -> ?force:bool -> ?modifiers:modifiers_t array -> ?position:Point.t -> ?delay:float -> ?button:button_t -> timeout:float -> ?trial:bool -> ?steps:int -> t -> unit
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
    val hover : selector:string -> ?strict:bool -> ?force:bool -> ?modifiers:modifiers_t array -> ?position:Point.t -> timeout:float -> ?trial:bool -> t -> unit
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

    type options_t = {
        value_or_label : string option;
        value : string option;
        label : string option;
        index : int option;
    }

    val select_option : selector:string -> ?strict:bool -> ?elements:ElementHandle.t array -> ?options:options_t array -> ?force:bool -> timeout:float -> t -> string array
    val set_content : html:string -> timeout:float -> ?wait_until:LifecycleEvent.t -> t -> unit
    val set_input_files : selector:string -> ?strict:bool -> ?payloads:payloads_t array -> ?local_directory:string -> ?directory_stream:WritableStream.t -> ?local_paths:string array -> ?streams:WritableStream.t array -> timeout:float -> t -> unit
    val tap : selector:string -> ?strict:bool -> ?force:bool -> ?modifiers:modifiers_t array -> ?position:Point.t -> timeout:float -> ?trial:bool -> t -> unit
    val text_content : selector:string -> ?strict:bool -> timeout:float -> t -> string option
    val title : t -> string
    val type_ : selector:string -> ?strict:bool -> text:string -> ?delay:float -> timeout:float -> t -> unit
    val uncheck : selector:string -> ?strict:bool -> ?force:bool -> ?position:Point.t -> timeout:float -> ?trial:bool -> t -> unit
    val wait_for_timeout : wait_timeout:float -> t -> unit
    val wait_for_function : expression:string -> ?is_function:bool -> arg:SerializedArgument.t -> timeout:float -> ?polling_interval:float -> t -> JSHandle.t

    type state_t = [
        | `Attached
        | `Detached
        | `Visible
        | `Hidden
    ]


    val wait_for_selector : selector:string -> ?strict:bool -> timeout:float -> ?state:state_t -> ?omit_return_value:bool -> t -> ElementHandle.t option

    type expect_res_t = {
        matches : bool;
        received : received_t option;
        timed_out : bool option;
        error_message : string option;
        log : string array option;
    }

    and received_t = {
        value : SerializedValue.t option;
        aria_snapshot : string option;
    }

    and pseudo_t = [
        | `Before
        | `After
    ]


    val expect : ?selector:string -> expression:string -> ?expression_arg:json -> ?pseudo:pseudo_t -> ?expected_text:ExpectedTextValue.t array -> ?expected_number:float -> ?expected_value:SerializedArgument.t -> ?use_inner_text:bool -> is_not:bool -> timeout:float -> t -> expect_res_t
end
and Worker : sig
    type t = {
        url : string;
        __internal_obj : obj
    }
    [@@deriving yojson {strict = false}]




    type info_t = {
        wait_id : string;
        phase : phase_t;
        event : string option;
        message : string option;
        error : string option;
    }

    and phase_t = [
        | `Before
        | `After
        | `Log
    ]


    val wait_for_event_info : info:info_t -> t -> unit
    val disconnect : ?reason:string -> t -> unit
    val evaluate_expression : expression:string -> ?is_function:bool -> arg:SerializedArgument.t -> t -> SerializedValue.t
    val evaluate_expression_handle : expression:string -> ?is_function:bool -> arg:SerializedArgument.t -> t -> JSHandle.t

    type event_t = [
        | `Console
    ]


    val update_subscription : event:event_t -> enabled:bool -> t -> unit
end
and Disposable : sig
    type t [@@deriving yojson]

    val dispose : t -> unit
end
and JSHandle : sig
    type t = {
        preview : string;
        __internal_obj : obj
    }
    [@@deriving yojson {strict = false}]



    val dispose : t -> unit
    val evaluate_expression : expression:string -> ?is_function:bool -> arg:SerializedArgument.t -> t -> SerializedValue.t
    val evaluate_expression_handle : expression:string -> ?is_function:bool -> arg:SerializedArgument.t -> t -> JSHandle.t

    type properties_t = {
        name : string;
        value : JSHandle.t;
    }

    val get_property_list : t -> properties_t array
    val get_property : name:string -> t -> JSHandle.t
    val json_value : t -> SerializedValue.t
end
and ElementHandle : sig
    type t [@@deriving yojson]

    val dispose : t -> unit
    val evaluate_expression : expression:string -> ?is_function:bool -> arg:SerializedArgument.t -> t -> SerializedValue.t
    val evaluate_expression_handle : expression:string -> ?is_function:bool -> arg:SerializedArgument.t -> t -> JSHandle.t

    type properties_t = {
        name : string;
        value : JSHandle.t;
    }

    val get_property_list : t -> properties_t array
    val get_property : name:string -> t -> JSHandle.t
    val json_value : t -> SerializedValue.t
    val eval_on_selector : selector:string -> ?strict:bool -> expression:string -> ?is_function:bool -> arg:SerializedArgument.t -> t -> SerializedValue.t
    val eval_on_selector_all : selector:string -> expression:string -> ?is_function:bool -> arg:SerializedArgument.t -> t -> SerializedValue.t
    val bounding_box : t -> Rect.t option
    val check : ?force:bool -> ?position:Point.t -> timeout:float -> ?trial:bool -> t -> unit

    type button_t = [
        | `Left
        | `Right
        | `Middle
    ]


    and modifiers_t = [
        | `Alt
        | `Control
        | `Control_or_meta
        | `Meta
        | `Shift
    ]


    val click : ?force:bool -> ?no_wait_after:bool -> ?modifiers:modifiers_t array -> ?position:Point.t -> ?delay:float -> ?button:button_t -> ?click_count:int -> timeout:float -> ?trial:bool -> ?steps:int -> t -> unit
    val content_frame : t -> Frame.t option
    val dblclick : ?force:bool -> ?modifiers:modifiers_t array -> ?position:Point.t -> ?delay:float -> ?button:button_t -> timeout:float -> ?trial:bool -> ?steps:int -> t -> unit
    val dispatch_event : type_:string -> event_init:SerializedArgument.t -> t -> unit
    val fill : value:string -> ?force:bool -> timeout:float -> t -> unit
    val focus : t -> unit
    val get_attribute : name:string -> t -> string option
    val hover : ?force:bool -> ?modifiers:modifiers_t array -> ?position:Point.t -> timeout:float -> ?trial:bool -> t -> unit
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

    type mask_t = {
        frame : Frame.t;
        selector : string;
    }

    and scale_t = [
        | `Css
        | `Device
    ]


    and animations_t = [
        | `Disabled
        | `Allow
    ]


    and caret_t = [
        | `Hide
        | `Initial
    ]


    and type__t = [
        | `Png
        | `Jpeg
    ]


    val screenshot : timeout:float -> ?type_:type__t -> ?quality:int -> ?omit_background:bool -> ?caret:caret_t -> ?animations:animations_t -> ?scale:scale_t -> ?mask:mask_t array -> ?mask_color:string -> ?style:string -> t -> string
    val scroll_into_view_if_needed : timeout:float -> t -> unit

    type options_t = {
        value_or_label : string option;
        value : string option;
        label : string option;
        index : int option;
    }

    val select_option : ?elements:ElementHandle.t array -> ?options:options_t array -> ?force:bool -> timeout:float -> t -> string array
    val select_text : ?force:bool -> timeout:float -> t -> unit

    type payloads_t = {
        name : string;
        mime_type : string option;
        buffer : string;
    }

    val set_input_files : ?payloads:payloads_t array -> ?local_directory:string -> ?directory_stream:WritableStream.t -> ?local_paths:string array -> ?streams:WritableStream.t array -> timeout:float -> t -> unit
    val tap : ?force:bool -> ?modifiers:modifiers_t array -> ?position:Point.t -> timeout:float -> ?trial:bool -> t -> unit
    val text_content : t -> string option
    val type_ : text:string -> ?delay:float -> timeout:float -> t -> unit
    val uncheck : ?force:bool -> ?position:Point.t -> timeout:float -> ?trial:bool -> t -> unit

    type state_t = [
        | `Visible
        | `Hidden
        | `Stable
        | `Enabled
        | `Disabled
        | `Editable
    ]


    val wait_for_element_state : state:state_t -> timeout:float -> t -> unit
    val wait_for_selector : selector:string -> ?strict:bool -> timeout:float -> ?state:state_t -> t -> ElementHandle.t option
end
and Request : sig
    type t = {
        frame : Frame.t option;
        service_worker : Worker.t option;
        url : string;
        resource_type : string;
        method_ : string;
        post_data : string option;
        headers : NameValue.t array;
        is_navigation_request : bool;
        redirected_from : Request.t option;
        __internal_obj : obj
    }
    [@@deriving yojson {strict = false}]



    val response : t -> Response.t option
    val raw_request_headers : t -> NameValue.t array
end
and Route : sig
    type t = {
        request : Request.t;
        __internal_obj : obj
    }
    [@@deriving yojson {strict = false}]



    val redirect_navigation_request : url:string -> t -> unit
    val abort : ?error_code:string -> t -> unit
    val continue : ?url:string -> ?method_:string -> ?headers:NameValue.t array -> ?post_data:string -> is_fallback:bool -> t -> unit
    val fulfill : ?status:int -> ?headers:NameValue.t array -> ?body:string -> ?is_base64:bool -> ?fetch_response_uid:string -> t -> unit
end
and WebSocketRoute : sig
    type t = {
        url : string;
        protocols : string array;
        __internal_obj : obj
    }
    [@@deriving yojson {strict = false}]



    val connect : t -> unit
    val ensure_opened : t -> unit
    val send_to_page : message:string -> is_base64:bool -> t -> unit
    val send_to_server : message:string -> is_base64:bool -> t -> unit
    val close_page : ?code:int -> ?reason:string -> was_clean:bool -> t -> unit
    val close_server : ?code:int -> ?reason:string -> was_clean:bool -> t -> unit
end
and Response : sig
    type t = {
        request : Request.t;
        url : string;
        status : int;
        status_text : string;
        headers : NameValue.t array;
        timing : ResourceTiming.t;
        from_service_worker : bool;
        __internal_obj : obj
    }
    [@@deriving yojson {strict = false}]



    val body : t -> string
    val security_details : t -> SecurityDetails.t option
    val server_addr : t -> RemoteAddr.t option
    val raw_response_headers : t -> NameValue.t array
    val http_version : t -> string
    val sizes : t -> RequestSizes.t
end
and WebSocket : sig
    type t = {
        url : string;
        __internal_obj : obj
    }
    [@@deriving yojson {strict = false}]




    type info_t = {
        wait_id : string;
        phase : phase_t;
        event : string option;
        message : string option;
        error : string option;
    }

    and phase_t = [
        | `Before
        | `After
        | `Log
    ]


    val wait_for_event_info : info:info_t -> t -> unit
end
and BindingCall : sig
    type t = {
        frame : Frame.t;
        name : string;
        args : SerializedValue.t array;
        __internal_obj : obj
    }
    [@@deriving yojson {strict = false}]



    val reject : error:SerializedError.t -> t -> unit
    val resolve : result:SerializedArgument.t -> t -> unit
end
and Debugger : sig
    type t [@@deriving yojson]


    type info_t = {
        wait_id : string;
        phase : phase_t;
        event : string option;
        message : string option;
        error : string option;
    }

    and phase_t = [
        | `Before
        | `After
        | `Log
    ]


    val wait_for_event_info : info:info_t -> t -> unit
    val request_pause : t -> unit
    val resume : t -> unit
    val next : t -> unit

    type location_t = {
        file : string;
        line : int option;
        column : int option;
    }

    val run_to : location:location_t -> t -> unit
end
and Dialog : sig
    type t = {
        page : Page.t option;
        type_ : string;
        message : string;
        default_value : string;
        __internal_obj : obj
    }
    [@@deriving yojson {strict = false}]



    val accept : ?prompt_text:string -> t -> unit
    val dismiss : t -> unit
end
and Tracing : sig
    type t [@@deriving yojson]

    val tracing_start : ?name:string -> ?snapshots:bool -> ?screenshots:bool -> ?live:bool -> t -> unit
    val tracing_start_chunk : ?name:string -> ?title:string -> t -> string

    type location_t = {
        file : string;
        line : int option;
        column : int option;
    }

    val tracing_group : name:string -> ?location:location_t -> t -> unit
    val tracing_group_end : t -> unit

    type tracing_stop_chunk_res_t = {
        artifact : Artifact.t option;
        entries : NameValue.t array option;
    }

    and mode_t = [
        | `Archive
        | `Discard
        | `Entries
    ]


    val tracing_stop_chunk : mode:mode_t -> t -> tracing_stop_chunk_res_t
    val tracing_stop : t -> unit
    val har_start : ?page:Page.t -> options:RecordHarOptions.t -> t -> string
    val har_export : ?har_id:string -> t -> Artifact.t
end
and Artifact : sig
    type t = {
        absolute_path : string;
        __internal_obj : obj
    }
    [@@deriving yojson {strict = false}]



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
    type t = {
        model : string;
        serial : string;
        __internal_obj : obj
    }
    [@@deriving yojson {strict = false}]




    type info_t = {
        wait_id : string;
        phase : phase_t;
        event : string option;
        message : string option;
        error : string option;
    }

    and phase_t = [
        | `Before
        | `After
        | `Log
    ]


    val wait_for_event_info : info:info_t -> t -> unit

    type state_t = [
        | `Gone
    ]


    val wait : android_selector:AndroidSelector.t -> ?state:state_t -> timeout:float -> t -> unit
    val fill : android_selector:AndroidSelector.t -> text:string -> timeout:float -> t -> unit
    val tap : android_selector:AndroidSelector.t -> ?duration:float -> timeout:float -> t -> unit
    val drag : android_selector:AndroidSelector.t -> dest:Point.t -> ?speed:float -> timeout:float -> t -> unit

    type direction_t = [
        | `Up
        | `Down
        | `Left
        | `Right
    ]


    val fling : android_selector:AndroidSelector.t -> direction:direction_t -> ?speed:float -> timeout:float -> t -> unit
    val long_tap : android_selector:AndroidSelector.t -> timeout:float -> t -> unit
    val pinch_close : android_selector:AndroidSelector.t -> percent:float -> ?speed:float -> timeout:float -> t -> unit
    val pinch_open : android_selector:AndroidSelector.t -> percent:float -> ?speed:float -> timeout:float -> t -> unit
    val scroll : android_selector:AndroidSelector.t -> direction:direction_t -> percent:float -> ?speed:float -> timeout:float -> t -> unit
    val swipe : android_selector:AndroidSelector.t -> direction:direction_t -> percent:float -> ?speed:float -> timeout:float -> t -> unit
    val info : android_selector:AndroidSelector.t -> t -> AndroidElementInfo.t
    val screenshot : t -> string
    val input_type : text:string -> t -> unit
    val input_press : key:string -> t -> unit
    val input_tap : point:Point.t -> t -> unit
    val input_swipe : segments:Point.t array -> steps:int -> t -> unit
    val input_drag : from:Point.t -> to_:Point.t -> steps:int -> t -> unit

    type proxy_t = {
        server : string;
        bypass : string option;
        username : string option;
        password : string option;
    }

    and service_workers_t = [
        | `Allow
        | `Block
    ]


    and record_video_t = {
        dir : string option;
        size : size_t option;
        show_actions : show_actions_t option;
    }

    and show_actions_t = {
        duration : float option;
        position : position_t option;
        font_size : int option;
    }

    and position_t = [
        | `Top_left
        | `Top
        | `Top_right
        | `Bottom_left
        | `Bottom
        | `Bottom_right
    ]


    and size_t = {
        width : int;
        height : int;
    }

    and contrast_t = [
        | `No_preference
        | `More
        | `No_override
    ]


    and accept_downloads_t = [
        | `Accept
        | `Deny
        | `Internal_browser_default
    ]


    and forced_colors_t = [
        | `Active
        | `None
        | `No_override
    ]


    and reduced_motion_t = [
        | `Reduce
        | `No_preference
        | `No_override
    ]


    and color_scheme_t = [
        | `Dark
        | `Light
        | `No_preference
        | `No_override
    ]


    and http_credentials_t = {
        username : string;
        password : string;
        origin : string option;
        send : send_t option;
    }

    and send_t = [
        | `Always
        | `Unauthorized
    ]


    and geolocation_t = {
        longitude : float;
        latitude : float;
        accuracy : float option;
    }

    and client_certificates_t = {
        origin : string;
        cert : string option;
        key : string option;
        passphrase : string option;
        pfx : string option;
    }

    and screen_t = {
        width : int;
        height : int;
    }

    and viewport_t = {
        width : int;
        height : int;
    }

    val launch_browser : ?no_default_viewport:bool -> ?viewport:viewport_t -> ?screen:screen_t -> ?ignore_https_errors:bool -> ?client_certificates:client_certificates_t array -> ?java_script_enabled:bool -> ?bypass_csp:bool -> ?user_agent:string -> ?locale:string -> ?timezone_id:string -> ?geolocation:geolocation_t -> ?permissions:string array -> ?extra_http_headers:NameValue.t array -> ?offline:bool -> ?http_credentials:http_credentials_t -> ?device_scale_factor:float -> ?is_mobile:bool -> ?has_touch:bool -> ?color_scheme:color_scheme_t -> ?reduced_motion:reduced_motion_t -> ?forced_colors:forced_colors_t -> ?accept_downloads:accept_downloads_t -> ?contrast:contrast_t -> ?base_url:string -> ?record_video:record_video_t -> ?strict_selectors:bool -> ?service_workers:service_workers_t -> ?selector_engines:SelectorEngine.t array -> ?test_id_attribute_name:string -> ?pkg:string -> ?args:string array -> ?proxy:proxy_t -> t -> BrowserContext.t
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
