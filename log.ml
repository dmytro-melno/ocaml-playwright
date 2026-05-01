[@@@ocaml.warning "-30-39-32"]

type obj = { conn: Connection.t; guid: string }
let obj_to_yojson _ = `Null
let obj_of_yojson _ = Ok { conn = Obj.magic (); guid = "" }
type any = Yojson.Safe.t
let any_to_yojson (x: any) = x
let any_of_yojson (x: any) = Ok x
type json = Yojson.Safe.t
let json_to_yojson (x: json) = x
let json_of_yojson (x: json) = Ok x

module Channel = struct type t = { guid: string } [@@deriving yojson] end
module StackFrame = struct
    type t = {
        file : string [@key "file"];
        line : int [@key "line"];
        column : int [@key "column"];
        function_ : string option [@key "function"] [@default None];
    }
    [@@deriving yojson {strict = false}]
    
end

module Metadata = struct
    type t = {
        location : location_t option [@key "location"] [@default None];
        title : string option [@key "title"] [@default None];
        internal : bool option [@key "internal"] [@default None];
        step_id : string option [@key "stepId"] [@default None];
    }
    [@@deriving yojson {strict = false}]
    
    and location_t = {
        file : string [@key "file"];
        line : int option [@key "line"] [@default None];
        column : int option [@key "column"] [@default None];
    }
end

module ClientSideCallMetadata = struct
    type t = {
        id : int [@key "id"];
        stack : StackFrame.t array option [@key "stack"] [@default None];
    }
    [@@deriving yojson {strict = false}]
    
end

module Point = struct
    type t = {
        x : float [@key "x"];
        y : float [@key "y"];
    }
    [@@deriving yojson {strict = false}]
    
end

module Rect = struct
    type t = {
        x : float [@key "x"];
        y : float [@key "y"];
        width : float [@key "width"];
        height : float [@key "height"];
    }
    [@@deriving yojson {strict = false}]
    
end

module SerializedValue = struct
    type t = {
        n : float option [@key "n"] [@default None];
        b : bool option [@key "b"] [@default None];
        s : string option [@key "s"] [@default None];
        v : v_t option [@key "v"] [@default None];
        d : string option [@key "d"] [@default None];
        u : string option [@key "u"] [@default None];
        bi : string option [@key "bi"] [@default None];
        ta : ta_t option [@key "ta"] [@default None];
        e : e_t option [@key "e"] [@default None];
        r : r_t option [@key "r"] [@default None];
        a : t array option [@key "a"] [@default None];
        o : o_t array option [@key "o"] [@default None];
        h : int option [@key "h"] [@default None];
        id : int option [@key "id"] [@default None];
        ref : int option [@key "ref"] [@default None];
    }
    [@@deriving yojson {strict = false}]
    
    and o_t = {
        k : string [@key "k"];
        v : t [@key "v"];
    }
    and r_t = {
        p : string [@key "p"];
        f : string [@key "f"];
    }
    and e_t = {
        m : string [@key "m"];
        n : string [@key "n"];
        s : string [@key "s"];
    }
    and ta_t = {
        b : string [@key "b"];
        k : k_t [@key "k"];
    }
    and k_t = [
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

    and v_t = [
        | `Null [@name "null"]
        | `Undefined [@name "undefined"]
        | `Nan [@name "nan"]
        | `Inf [@name "inf"]
        | `Minus_inf [@name "-inf"]
        | `Minus_zero [@name "-0"]
    ] [@@deriving yojson]

end

module SerializedArgument = struct
    type t = {
        value : SerializedValue.t [@key "value"];
        handles : Channel.t array [@key "handles"];
    }
    [@@deriving yojson {strict = false}]
    
end

module ExpectedTextValue = struct
    type t = {
        string : string option [@key "string"] [@default None];
        regex_source : string option [@key "regexSource"] [@default None];
        regex_flags : string option [@key "regexFlags"] [@default None];
        match_substring : bool option [@key "matchSubstring"] [@default None];
        ignore_case : bool option [@key "ignoreCase"] [@default None];
        normalize_white_space : bool option [@key "normalizeWhiteSpace"] [@default None];
    }
    [@@deriving yojson {strict = false}]
    
end

module SelectorEngine = struct
    type t = {
        name : string [@key "name"];
        source : string [@key "source"];
        content_script : bool option [@key "contentScript"] [@default None];
    }
    [@@deriving yojson {strict = false}]
    
end

module URLPattern = struct
    type t = {
        hash : string [@key "hash"];
        hostname : string [@key "hostname"];
        password : string [@key "password"];
        pathname : string [@key "pathname"];
        port : string [@key "port"];
        protocol : string [@key "protocol"];
        search : string [@key "search"];
        username : string [@key "username"];
    }
    [@@deriving yojson {strict = false}]
    
end

module SetNetworkCookie = struct
    type t = {
        name : string [@key "name"];
        value : string [@key "value"];
        url : string option [@key "url"] [@default None];
        domain : string option [@key "domain"] [@default None];
        path : string option [@key "path"] [@default None];
        expires : float option [@key "expires"] [@default None];
        http_only : bool option [@key "httpOnly"] [@default None];
        secure : bool option [@key "secure"] [@default None];
        same_site : same_site_t option [@key "sameSite"] [@default None];
        partition_key : string option [@key "partitionKey"] [@default None];
        cr_has_cross_site_ancestor : bool option [@key "_crHasCrossSiteAncestor"] [@default None];
    }
    [@@deriving yojson {strict = false}]
    
    and same_site_t = [
        | `Strict [@name "Strict"]
        | `Lax [@name "Lax"]
        | `None [@name "None"]
    ] [@@deriving yojson]

end

module NetworkCookie = struct
    type t = {
        name : string [@key "name"];
        value : string [@key "value"];
        domain : string [@key "domain"];
        path : string [@key "path"];
        expires : float [@key "expires"];
        http_only : bool [@key "httpOnly"];
        secure : bool [@key "secure"];
        same_site : same_site_t [@key "sameSite"];
        partition_key : string option [@key "partitionKey"] [@default None];
        cr_has_cross_site_ancestor : bool option [@key "_crHasCrossSiteAncestor"] [@default None];
    }
    [@@deriving yojson {strict = false}]
    
    and same_site_t = [
        | `Strict [@name "Strict"]
        | `Lax [@name "Lax"]
        | `None [@name "None"]
    ] [@@deriving yojson]

end

module NameValue = struct
    type t = {
        name : string [@key "name"];
        value : string [@key "value"];
    }
    [@@deriving yojson {strict = false}]
    
end

module IndexedDBDatabase = struct
    type t = {
        name : string [@key "name"];
        version : int [@key "version"];
        stores : stores_t array [@key "stores"];
    }
    [@@deriving yojson {strict = false}]
    
    and stores_t = {
        name : string [@key "name"];
        auto_increment : bool [@key "autoIncrement"];
        key_path : string option [@key "keyPath"] [@default None];
        key_path_array : string array option [@key "keyPathArray"] [@default None];
        records : records_t array [@key "records"];
        indexes : indexes_t array [@key "indexes"];
    }
    and indexes_t = {
        name : string [@key "name"];
        key_path : string option [@key "keyPath"] [@default None];
        key_path_array : string array option [@key "keyPathArray"] [@default None];
        multi_entry : bool [@key "multiEntry"];
        unique : bool [@key "unique"];
    }
    and records_t = {
        key : json option [@key "key"] [@default None];
        key_encoded : json option [@key "keyEncoded"] [@default None];
        value : json option [@key "value"] [@default None];
        value_encoded : json option [@key "valueEncoded"] [@default None];
    }
end

module SetOriginStorage = struct
    type t = {
        origin : string [@key "origin"];
        local_storage : NameValue.t array [@key "localStorage"];
        indexed_db : IndexedDBDatabase.t array option [@key "indexedDB"] [@default None];
    }
    [@@deriving yojson {strict = false}]
    
end

module OriginStorage = struct
    type t = {
        origin : string [@key "origin"];
        local_storage : NameValue.t array [@key "localStorage"];
        indexed_db : IndexedDBDatabase.t array option [@key "indexedDB"] [@default None];
    }
    [@@deriving yojson {strict = false}]
    
end

module SerializedError = struct
    type t = {
        error : error_t option [@key "error"] [@default None];
        value : SerializedValue.t option [@key "value"] [@default None];
    }
    [@@deriving yojson {strict = false}]
    
    and error_t = {
        message : string [@key "message"];
        name : string [@key "name"];
        stack : string option [@key "stack"] [@default None];
    }
end

module RecordHarOptions = struct
    type t = {
        zip : bool option [@key "zip"] [@default None];
        content : content_t option [@key "content"] [@default None];
        mode : mode_t option [@key "mode"] [@default None];
        url_glob : string option [@key "urlGlob"] [@default None];
        url_regex_source : string option [@key "urlRegexSource"] [@default None];
        url_regex_flags : string option [@key "urlRegexFlags"] [@default None];
    }
    [@@deriving yojson {strict = false}]
    
    and mode_t = [
        | `Full [@name "full"]
        | `Minimal [@name "minimal"]
    ] [@@deriving yojson]

    and content_t = [
        | `Embed [@name "embed"]
        | `Attach [@name "attach"]
        | `Omit [@name "omit"]
    ] [@@deriving yojson]

end

module FormField = struct
    type t = {
        name : string [@key "name"];
        value : string option [@key "value"] [@default None];
        file : file_t option [@key "file"] [@default None];
    }
    [@@deriving yojson {strict = false}]
    
    and file_t = {
        name : string [@key "name"];
        mime_type : string option [@key "mimeType"] [@default None];
        buffer : string [@key "buffer"];
    }
end

module SDKLanguage = struct
    type t = [
        | `Javascript [@name "javascript"]
        | `Python [@name "python"]
        | `Java [@name "java"]
        | `Csharp [@name "csharp"]
    ]
    [@@deriving yojson {strict = false}]
    
end

module APIResponse = struct
    type t = {
        fetch_uid : string [@key "fetchUid"];
        url : string [@key "url"];
        status : int [@key "status"];
        status_text : string [@key "statusText"];
        headers : NameValue.t array [@key "headers"];
    }
    [@@deriving yojson {strict = false}]
    
end

module LifecycleEvent = struct
    type t = [
        | `Load [@name "load"]
        | `Domcontentloaded [@name "domcontentloaded"]
        | `Networkidle [@name "networkidle"]
        | `Commit [@name "commit"]
    ]
    [@@deriving yojson {strict = false}]
    
end

module ConsoleMessagesFilter = struct
    type t = [
        | `All [@name "all"]
        | `Since_navigation [@name "since-navigation"]
    ]
    [@@deriving yojson {strict = false}]
    
end

module RecorderSource = struct
    type t = {
        is_recorded : bool [@key "isRecorded"];
        id : string [@key "id"];
        label : string [@key "label"];
        text : string [@key "text"];
        language : string [@key "language"];
        highlight : highlight_t array [@key "highlight"];
        reveal_line : int option [@key "revealLine"] [@default None];
        group : string option [@key "group"] [@default None];
    }
    [@@deriving yojson {strict = false}]
    
    and highlight_t = {
        line : int [@key "line"];
        type_ : string [@key "type"];
    }
end

module ResourceTiming = struct
    type t = {
        start_time : float [@key "startTime"];
        domain_lookup_start : float [@key "domainLookupStart"];
        domain_lookup_end : float [@key "domainLookupEnd"];
        connect_start : float [@key "connectStart"];
        secure_connection_start : float [@key "secureConnectionStart"];
        connect_end : float [@key "connectEnd"];
        request_start : float [@key "requestStart"];
        response_start : float [@key "responseStart"];
    }
    [@@deriving yojson {strict = false}]
    
end

module SecurityDetails = struct
    type t = {
        issuer : string option [@key "issuer"] [@default None];
        protocol : string option [@key "protocol"] [@default None];
        subject_name : string option [@key "subjectName"] [@default None];
        valid_from : float option [@key "validFrom"] [@default None];
        valid_to : float option [@key "validTo"] [@default None];
    }
    [@@deriving yojson {strict = false}]
    
end

module RequestSizes = struct
    type t = {
        request_body_size : int [@key "requestBodySize"];
        request_headers_size : int [@key "requestHeadersSize"];
        response_body_size : int [@key "responseBodySize"];
        response_headers_size : int [@key "responseHeadersSize"];
    }
    [@@deriving yojson {strict = false}]
    
end

module RemoteAddr = struct
    type t = {
        ip_address : string [@key "ipAddress"];
        port : int [@key "port"];
    }
    [@@deriving yojson {strict = false}]
    
end

module AndroidWebView = struct
    type t = {
        pid : int [@key "pid"];
        pkg : string [@key "pkg"];
        socket_name : string [@key "socketName"];
    }
    [@@deriving yojson {strict = false}]
    
end

module AndroidSelector = struct
    type t = {
        checkable : bool option [@key "checkable"] [@default None];
        checked : bool option [@key "checked"] [@default None];
        clazz : string option [@key "clazz"] [@default None];
        clickable : bool option [@key "clickable"] [@default None];
        depth : int option [@key "depth"] [@default None];
        desc : string option [@key "desc"] [@default None];
        enabled : bool option [@key "enabled"] [@default None];
        focusable : bool option [@key "focusable"] [@default None];
        focused : bool option [@key "focused"] [@default None];
        has_child : has_child_t option [@key "hasChild"] [@default None];
        has_descendant : has_descendant_t option [@key "hasDescendant"] [@default None];
        long_clickable : bool option [@key "longClickable"] [@default None];
        pkg : string option [@key "pkg"] [@default None];
        res : string option [@key "res"] [@default None];
        scrollable : bool option [@key "scrollable"] [@default None];
        selected : bool option [@key "selected"] [@default None];
        text : string option [@key "text"] [@default None];
    }
    [@@deriving yojson {strict = false}]
    
    and has_descendant_t = {
        android_selector : t [@key "androidSelector"];
        max_depth : int option [@key "maxDepth"] [@default None];
    }
    and has_child_t = {
        android_selector : t [@key "androidSelector"];
    }
end

module AndroidElementInfo = struct
    type t = {
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
end = struct
    type t = {
        tracing : Tracing.t [@key "tracing"];
        __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}]
    } [@@deriving yojson {strict = false}]

    let fetch ~url ?encoded_params ?params ?method_ ?headers ?post_data ?json_data ?form_data ?multipart_data ~timeout ?fail_on_status_code ?ignore_https_errors ?max_redirects ?max_retries (t:t) : (APIResponse.t, string) result =
        let params = `Assoc (List.concat [
        ["url", (fun s -> `String s) url];
        (match encoded_params with | Some v -> [("encodedParams", (fun s -> `String s) v)] | None -> []);
        (match params with | Some v -> [("params", ((fun l -> `List (List.map (NameValue.to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match method_ with | Some v -> [("method", (fun s -> `String s) v)] | None -> []);
        (match headers with | Some v -> [("headers", ((fun l -> `List (List.map (NameValue.to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match post_data with | Some v -> [("postData", (fun s -> `String (Base64.encode_exn s)) v)] | None -> []);
        (match json_data with | Some v -> [("jsonData", (fun s -> `String s) v)] | None -> []);
        (match form_data with | Some v -> [("formData", ((fun l -> `List (List.map (NameValue.to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match multipart_data with | Some v -> [("multipartData", ((fun l -> `List (List.map (FormField.to_yojson) (Array.to_list l)))) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
        (match fail_on_status_code with | Some v -> [("failOnStatusCode", (fun b -> `Bool b) v)] | None -> []);
        (match ignore_https_errors with | Some v -> [("ignoreHTTPSErrors", (fun b -> `Bool b) v)] | None -> []);
        (match max_redirects with | Some v -> [("maxRedirects", (fun i -> `Int i) v)] | None -> []);
        (match max_retries with | Some v -> [("maxRetries", (fun i -> `Int i) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"fetch" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "response" res with | `Null -> Error "response is null" | v -> (APIResponse.of_yojson) v)
        | Error e -> Error e
    let fetch_response_body ~fetch_uid (t:t) : (string option, string) result =
        let params = `Assoc (List.concat [
        ["fetchUid", (fun s -> `String s) fetch_uid];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"fetchResponseBody" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "binary" res with | `Null -> Ok None | v -> match (fun v -> Ok (Base64.decode_exn (Yojson.Safe.Util.to_string v))) v with Ok r -> Ok (Some r) | Error e -> Error e)
        | Error e -> Error e
    let fetch_log ~fetch_uid (t:t) : (string array, string) result =
        let params = `Assoc (List.concat [
        ["fetchUid", (fun s -> `String s) fetch_uid];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"fetchLog" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "log" res with | `Null -> Error "log is null" | v -> ((fun v -> try Ok (Array.of_list (List.map (fun item -> match (fun v -> Ok (Yojson.Safe.Util.to_string v)) item with Ok r -> r | Error e -> failwith e) (Yojson.Safe.Util.to_list v))) with Failure e -> Error e)) v)
        | Error e -> Error e

    type storage_state_res_t = {
        cookies : NetworkCookie.t array [@key "cookies"];
        origins : OriginStorage.t array [@key "origins"];
    } [@@deriving yojson {strict = false}]

    let storage_state ?indexed_db (t:t) : (storage_state_res_t, string) result =
        let params = `Assoc (List.concat [
        (match indexed_db with | Some v -> [("indexedDB", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"storageState" ~params with
        | Ok res -> storage_state_res_t_of_yojson res
        | Error e -> Error e
    let dispose_api_response ~fetch_uid (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["fetchUid", (fun s -> `String s) fetch_uid];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"disposeAPIResponse" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let dispose ?reason (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match reason with | Some v -> [("reason", (fun s -> `String s) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"dispose" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
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
end = struct
    type t = {
        device_descriptors : device_descriptors_t array [@key "deviceDescriptors"];
        __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}]
    } [@@deriving yojson {strict = false}]
    and device_descriptors_t = {
        name : string [@key "name"];
        descriptor : descriptor_t [@key "descriptor"];
    }

    and descriptor_t = {
        user_agent : string [@key "userAgent"];
        viewport : viewport_t [@key "viewport"];
        screen : screen_t option [@key "screen"] [@default None];
        device_scale_factor : float [@key "deviceScaleFactor"];
        is_mobile : bool [@key "isMobile"];
        has_touch : bool [@key "hasTouch"];
        default_browser_type : default_browser_type_t [@key "defaultBrowserType"];
    }

    and default_browser_type_t = [
        | `Chromium [@name "chromium"]
        | `Firefox [@name "firefox"]
        | `Webkit [@name "webkit"]
    ] [@@deriving yojson]


    and screen_t = {
        width : int [@key "width"];
        height : int [@key "height"];
    }

    and viewport_t = {
        width : int [@key "width"];
        height : int [@key "height"];
    }



    type mode_t = [
        | `Write [@name "write"]
        | `Append [@name "append"]
    ] [@@deriving yojson]


    let zip ~zip_file ~entries ?stacks_id ~mode ~include_sources ?additional_sources (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["zipFile", (fun s -> `String s) zip_file];
        ["entries", ((fun l -> `List (List.map (NameValue.to_yojson) (Array.to_list l)))) entries];
        (match stacks_id with | Some v -> [("stacksId", (fun s -> `String s) v)] | None -> []);
        ["mode", (mode_t_to_yojson) mode];
        ["includeSources", (fun b -> `Bool b) include_sources];
        (match additional_sources with | Some v -> [("additionalSources", ((fun l -> `List (List.map (fun s -> `String s) (Array.to_list l)))) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"zip" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e

    type har_open_res_t = {
        har_id : string option [@key "harId"] [@default None];
        error : string option [@key "error"] [@default None];
    } [@@deriving yojson {strict = false}]

    let har_open ~file (t:t) : (har_open_res_t, string) result =
        let params = `Assoc (List.concat [
        ["file", (fun s -> `String s) file];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"harOpen" ~params with
        | Ok res -> har_open_res_t_of_yojson res
        | Error e -> Error e

    type har_lookup_res_t = {
        action : action_t [@key "action"];
        message : string option [@key "message"] [@default None];
        redirect_url : string option [@key "redirectURL"] [@default None];
        status : int option [@key "status"] [@default None];
        headers : NameValue.t array option [@key "headers"] [@default None];
        body : string option [@key "body"] [@default None];
    } [@@deriving yojson {strict = false}]

    and action_t = [
        | `Error [@name "error"]
        | `Redirect [@name "redirect"]
        | `Fulfill [@name "fulfill"]
        | `Noentry [@name "noentry"]
    ] [@@deriving yojson]


    let har_lookup ~har_id ~url ~method_ ~headers ?post_data ~is_navigation_request (t:t) : (har_lookup_res_t, string) result =
        let params = `Assoc (List.concat [
        ["harId", (fun s -> `String s) har_id];
        ["url", (fun s -> `String s) url];
        ["method", (fun s -> `String s) method_];
        ["headers", ((fun l -> `List (List.map (NameValue.to_yojson) (Array.to_list l)))) headers];
        (match post_data with | Some v -> [("postData", (fun s -> `String (Base64.encode_exn s)) v)] | None -> []);
        ["isNavigationRequest", (fun b -> `Bool b) is_navigation_request];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"harLookup" ~params with
        | Ok res -> har_lookup_res_t_of_yojson res
        | Error e -> Error e
    let har_close ~har_id (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["harId", (fun s -> `String s) har_id];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"harClose" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let har_unzip ~zip_file ~har_file (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["zipFile", (fun s -> `String s) zip_file];
        ["harFile", (fun s -> `String s) har_file];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"harUnzip" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e

    type connect_res_t = {
        pipe : JsonPipe.t [@key "pipe"];
        headers : NameValue.t array [@key "headers"];
    } [@@deriving yojson {strict = false}]

    let connect ~endpoint ?headers ?expose_network ?slow_mo ~timeout ?socks_proxy_redirect_port_for_test (t:t) : (connect_res_t, string) result =
        let params = `Assoc (List.concat [
        ["endpoint", (fun s -> `String s) endpoint];
        (match headers with | Some v -> [("headers", (json_to_yojson) v)] | None -> []);
        (match expose_network with | Some v -> [("exposeNetwork", (fun s -> `String s) v)] | None -> []);
        (match slow_mo with | Some v -> [("slowMo", (fun f -> `Float f) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
        (match socks_proxy_redirect_port_for_test with | Some v -> [("socksProxyRedirectPortForTest", (fun i -> `Int i) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"connect" ~params with
        | Ok res -> connect_res_t_of_yojson res
        | Error e -> Error e
    let tracing_started ?traces_dir ~trace_name ?live (t:t) : (string, string) result =
        let params = `Assoc (List.concat [
        (match traces_dir with | Some v -> [("tracesDir", (fun s -> `String s) v)] | None -> []);
        ["traceName", (fun s -> `String s) trace_name];
        (match live with | Some v -> [("live", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"tracingStarted" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "stacksId" res with | `Null -> Error "stacksId is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_string v)) v)
        | Error e -> Error e
    let add_stack_to_tracing_no_reply ~call_data (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["callData", (ClientSideCallMetadata.to_yojson) call_data];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"addStackToTracingNoReply" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let trace_discarded ~stacks_id (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["stacksId", (fun s -> `String s) stacks_id];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"traceDiscarded" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let glob_to_regex ~glob ?base_url ?web_socket_url (t:t) : (string, string) result =
        let params = `Assoc (List.concat [
        ["glob", (fun s -> `String s) glob];
        (match base_url with | Some v -> [("baseURL", (fun s -> `String s) v)] | None -> []);
        (match web_socket_url with | Some v -> [("webSocketUrl", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"globToRegex" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "regex" res with | `Null -> Error "regex is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_string v)) v)
        | Error e -> Error e
end
and Root : sig
    type t [@@deriving yojson]

    val initialize : sdk_language:SDKLanguage.t -> t -> Playwright.t
end = struct
    type t = { __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}] } [@@deriving yojson {strict = false}]

    let initialize ~sdk_language (t:t) : (Playwright.t, string) result =
        let params = `Assoc (List.concat [
        ["sdkLanguage", (SDKLanguage.to_yojson) sdk_language];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"initialize" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "playwright" res with | `Null -> Error "playwright is null" | v -> (Playwright.of_yojson) v)
        | Error e -> Error e
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
end = struct
    type t = {
        chromium : BrowserType.t [@key "chromium"];
        firefox : BrowserType.t [@key "firefox"];
        webkit : BrowserType.t [@key "webkit"];
        android : Android.t [@key "android"];
        utils : LocalUtils.t option [@key "utils"] [@default None];
        pre_launched_browser : Browser.t option [@key "preLaunchedBrowser"] [@default None];
        pre_connected_android_device : AndroidDevice.t option [@key "preConnectedAndroidDevice"] [@default None];
        socks_support : SocksSupport.t option [@key "socksSupport"] [@default None];
        __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}]
    } [@@deriving yojson {strict = false}]


    type storage_state_t = {
        cookies : NetworkCookie.t array option [@key "cookies"] [@default None];
        origins : SetOriginStorage.t array option [@key "origins"] [@default None];
    }

    and proxy_t = {
        server : string [@key "server"];
        bypass : string option [@key "bypass"] [@default None];
        username : string option [@key "username"] [@default None];
        password : string option [@key "password"] [@default None];
    }

    and http_credentials_t = {
        username : string [@key "username"];
        password : string [@key "password"];
        origin : string option [@key "origin"] [@default None];
        send : send_t option [@key "send"] [@default None];
    }

    and send_t = [
        | `Always [@name "always"]
        | `Unauthorized [@name "unauthorized"]
    ] [@@deriving yojson]


    and client_certificates_t = {
        origin : string [@key "origin"];
        cert : string option [@key "cert"] [@default None];
        key : string option [@key "key"] [@default None];
        passphrase : string option [@key "passphrase"] [@default None];
        pfx : string option [@key "pfx"] [@default None];
    }

    let new_request ?base_url ?user_agent ?ignore_https_errors ?extra_http_headers ?fail_on_status_code ?client_certificates ?max_redirects ?http_credentials ?proxy ?storage_state ?traces_dir (t:t) : (APIRequestContext.t, string) result =
        let params = `Assoc (List.concat [
        (match base_url with | Some v -> [("baseURL", (fun s -> `String s) v)] | None -> []);
        (match user_agent with | Some v -> [("userAgent", (fun s -> `String s) v)] | None -> []);
        (match ignore_https_errors with | Some v -> [("ignoreHTTPSErrors", (fun b -> `Bool b) v)] | None -> []);
        (match extra_http_headers with | Some v -> [("extraHTTPHeaders", ((fun l -> `List (List.map (NameValue.to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match fail_on_status_code with | Some v -> [("failOnStatusCode", (fun b -> `Bool b) v)] | None -> []);
        (match client_certificates with | Some v -> [("clientCertificates", ((fun l -> `List (List.map (client_certificates_t_to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match max_redirects with | Some v -> [("maxRedirects", (fun i -> `Int i) v)] | None -> []);
        (match http_credentials with | Some v -> [("httpCredentials", (http_credentials_t_to_yojson) v)] | None -> []);
        (match proxy with | Some v -> [("proxy", (proxy_t_to_yojson) v)] | None -> []);
        (match storage_state with | Some v -> [("storageState", (storage_state_t_to_yojson) v)] | None -> []);
        (match traces_dir with | Some v -> [("tracesDir", (fun s -> `String s) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"newRequest" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "request" res with | `Null -> Error "request is null" | v -> (APIRequestContext.of_yojson) v)
        | Error e -> Error e
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
end = struct
    type t = { __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}] } [@@deriving yojson {strict = false}]

    let initialize ~codegen_id ~sdk_language (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["codegenId", (fun s -> `String s) codegen_id];
        ["sdkLanguage", (SDKLanguage.to_yojson) sdk_language];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"initialize" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let set_report_state_changed ~enabled (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["enabled", (fun b -> `Bool b) enabled];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"setReportStateChanged" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e

    type mode_t = [
        | `Inspecting [@name "inspecting"]
        | `Recording [@name "recording"]
        | `None [@name "none"]
    ] [@@deriving yojson]


    let set_recorder_mode ~mode ?test_id_attribute_name ?generate_auto_expect (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["mode", (mode_t_to_yojson) mode];
        (match test_id_attribute_name with | Some v -> [("testIdAttributeName", (fun s -> `String s) v)] | None -> []);
        (match generate_auto_expect with | Some v -> [("generateAutoExpect", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"setRecorderMode" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let highlight ?selector ?aria_template (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match selector with | Some v -> [("selector", (fun s -> `String s) v)] | None -> []);
        (match aria_template with | Some v -> [("ariaTemplate", (fun s -> `String s) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"highlight" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let hide_highlight (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"hideHighlight" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let resume (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"resume" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let kill (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"kill" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
end
and SocksSupport : sig
    type t [@@deriving yojson]

    val socks_connected : uid:string -> host:string -> port:int -> t -> unit
    val socks_failed : uid:string -> error_code:string -> t -> unit
    val socks_data : uid:string -> data:string -> t -> unit
    val socks_error : uid:string -> error:string -> t -> unit
    val socks_end : uid:string -> t -> unit
end = struct
    type t = { __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}] } [@@deriving yojson {strict = false}]

    let socks_connected ~uid ~host ~port (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["uid", (fun s -> `String s) uid];
        ["host", (fun s -> `String s) host];
        ["port", (fun i -> `Int i) port];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"socksConnected" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let socks_failed ~uid ~error_code (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["uid", (fun s -> `String s) uid];
        ["errorCode", (fun s -> `String s) error_code];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"socksFailed" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let socks_data ~uid ~data (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["uid", (fun s -> `String s) uid];
        ["data", (fun s -> `String (Base64.encode_exn s)) data];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"socksData" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let socks_error ~uid ~error (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["uid", (fun s -> `String s) uid];
        ["error", (fun s -> `String s) error];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"socksError" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let socks_end ~uid (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["uid", (fun s -> `String s) uid];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"socksEnd" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
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
end = struct
    type t = {
        executable_path : string [@key "executablePath"];
        name : string [@key "name"];
        __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}]
    } [@@deriving yojson {strict = false}]


    type proxy_t = {
        server : string [@key "server"];
        bypass : string option [@key "bypass"] [@default None];
        username : string option [@key "username"] [@default None];
        password : string option [@key "password"] [@default None];
    }

    let launch ?channel ?executable_path ?args ?ignore_all_default_args ?ignore_default_args ?handle_sigint ?handle_sigterm ?handle_sighup ~timeout ?env ?headless ?proxy ?downloads_path ?traces_dir ?artifacts_dir ?chromium_sandbox ?firefox_user_prefs ?cdp_port ?slow_mo (t:t) : (Browser.t, string) result =
        let params = `Assoc (List.concat [
        (match channel with | Some v -> [("channel", (fun s -> `String s) v)] | None -> []);
        (match executable_path with | Some v -> [("executablePath", (fun s -> `String s) v)] | None -> []);
        (match args with | Some v -> [("args", ((fun l -> `List (List.map (fun s -> `String s) (Array.to_list l)))) v)] | None -> []);
        (match ignore_all_default_args with | Some v -> [("ignoreAllDefaultArgs", (fun b -> `Bool b) v)] | None -> []);
        (match ignore_default_args with | Some v -> [("ignoreDefaultArgs", ((fun l -> `List (List.map (fun s -> `String s) (Array.to_list l)))) v)] | None -> []);
        (match handle_sigint with | Some v -> [("handleSIGINT", (fun b -> `Bool b) v)] | None -> []);
        (match handle_sigterm with | Some v -> [("handleSIGTERM", (fun b -> `Bool b) v)] | None -> []);
        (match handle_sighup with | Some v -> [("handleSIGHUP", (fun b -> `Bool b) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
        (match env with | Some v -> [("env", ((fun l -> `List (List.map (NameValue.to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match headless with | Some v -> [("headless", (fun b -> `Bool b) v)] | None -> []);
        (match proxy with | Some v -> [("proxy", (proxy_t_to_yojson) v)] | None -> []);
        (match downloads_path with | Some v -> [("downloadsPath", (fun s -> `String s) v)] | None -> []);
        (match traces_dir with | Some v -> [("tracesDir", (fun s -> `String s) v)] | None -> []);
        (match artifacts_dir with | Some v -> [("artifactsDir", (fun s -> `String s) v)] | None -> []);
        (match chromium_sandbox with | Some v -> [("chromiumSandbox", (fun b -> `Bool b) v)] | None -> []);
        (match firefox_user_prefs with | Some v -> [("firefoxUserPrefs", (json_to_yojson) v)] | None -> []);
        (match cdp_port with | Some v -> [("cdpPort", (fun i -> `Int i) v)] | None -> []);
        (match slow_mo with | Some v -> [("slowMo", (fun f -> `Float f) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"launch" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "browser" res with | `Null -> Error "browser is null" | v -> (Browser.of_yojson) v)
        | Error e -> Error e

    type launch_persistent_context_res_t = {
        browser : Browser.t [@key "browser"];
        context : BrowserContext.t [@key "context"];
    } [@@deriving yojson {strict = false}]

    and service_workers_t = [
        | `Allow [@name "allow"]
        | `Block [@name "block"]
    ] [@@deriving yojson]


    and record_video_t = {
        dir : string option [@key "dir"] [@default None];
        size : size_t option [@key "size"] [@default None];
        show_actions : show_actions_t option [@key "showActions"] [@default None];
    }

    and show_actions_t = {
        duration : float option [@key "duration"] [@default None];
        position : position_t option [@key "position"] [@default None];
        font_size : int option [@key "fontSize"] [@default None];
    }

    and position_t = [
        | `Top_left [@name "top-left"]
        | `Top [@name "top"]
        | `Top_right [@name "top-right"]
        | `Bottom_left [@name "bottom-left"]
        | `Bottom [@name "bottom"]
        | `Bottom_right [@name "bottom-right"]
    ] [@@deriving yojson]


    and size_t = {
        width : int [@key "width"];
        height : int [@key "height"];
    }

    and contrast_t = [
        | `No_preference [@name "no-preference"]
        | `More [@name "more"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]


    and accept_downloads_t = [
        | `Accept [@name "accept"]
        | `Deny [@name "deny"]
        | `Internal_browser_default [@name "internal-browser-default"]
    ] [@@deriving yojson]


    and forced_colors_t = [
        | `Active [@name "active"]
        | `None [@name "none"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]


    and reduced_motion_t = [
        | `Reduce [@name "reduce"]
        | `No_preference [@name "no-preference"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]


    and color_scheme_t = [
        | `Dark [@name "dark"]
        | `Light [@name "light"]
        | `No_preference [@name "no-preference"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]


    and http_credentials_t = {
        username : string [@key "username"];
        password : string [@key "password"];
        origin : string option [@key "origin"] [@default None];
        send : send_t option [@key "send"] [@default None];
    }

    and send_t = [
        | `Always [@name "always"]
        | `Unauthorized [@name "unauthorized"]
    ] [@@deriving yojson]


    and geolocation_t = {
        longitude : float [@key "longitude"];
        latitude : float [@key "latitude"];
        accuracy : float option [@key "accuracy"] [@default None];
    }

    and client_certificates_t = {
        origin : string [@key "origin"];
        cert : string option [@key "cert"] [@default None];
        key : string option [@key "key"] [@default None];
        passphrase : string option [@key "passphrase"] [@default None];
        pfx : string option [@key "pfx"] [@default None];
    }

    and screen_t = {
        width : int [@key "width"];
        height : int [@key "height"];
    }

    and viewport_t = {
        width : int [@key "width"];
        height : int [@key "height"];
    }

    let launch_persistent_context ?channel ?executable_path ?args ?ignore_all_default_args ?ignore_default_args ?handle_sigint ?handle_sigterm ?handle_sighup ~timeout ?env ?headless ?proxy ?downloads_path ?traces_dir ?artifacts_dir ?chromium_sandbox ?firefox_user_prefs ?cdp_port ?no_default_viewport ?viewport ?screen ?ignore_https_errors ?client_certificates ?java_script_enabled ?bypass_csp ?user_agent ?locale ?timezone_id ?geolocation ?permissions ?extra_http_headers ?offline ?http_credentials ?device_scale_factor ?is_mobile ?has_touch ?color_scheme ?reduced_motion ?forced_colors ?accept_downloads ?contrast ?base_url ?record_video ?strict_selectors ?service_workers ?selector_engines ?test_id_attribute_name ~user_data_dir ?slow_mo (t:t) : (launch_persistent_context_res_t, string) result =
        let params = `Assoc (List.concat [
        (match channel with | Some v -> [("channel", (fun s -> `String s) v)] | None -> []);
        (match executable_path with | Some v -> [("executablePath", (fun s -> `String s) v)] | None -> []);
        (match args with | Some v -> [("args", ((fun l -> `List (List.map (fun s -> `String s) (Array.to_list l)))) v)] | None -> []);
        (match ignore_all_default_args with | Some v -> [("ignoreAllDefaultArgs", (fun b -> `Bool b) v)] | None -> []);
        (match ignore_default_args with | Some v -> [("ignoreDefaultArgs", ((fun l -> `List (List.map (fun s -> `String s) (Array.to_list l)))) v)] | None -> []);
        (match handle_sigint with | Some v -> [("handleSIGINT", (fun b -> `Bool b) v)] | None -> []);
        (match handle_sigterm with | Some v -> [("handleSIGTERM", (fun b -> `Bool b) v)] | None -> []);
        (match handle_sighup with | Some v -> [("handleSIGHUP", (fun b -> `Bool b) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
        (match env with | Some v -> [("env", ((fun l -> `List (List.map (NameValue.to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match headless with | Some v -> [("headless", (fun b -> `Bool b) v)] | None -> []);
        (match proxy with | Some v -> [("proxy", (proxy_t_to_yojson) v)] | None -> []);
        (match downloads_path with | Some v -> [("downloadsPath", (fun s -> `String s) v)] | None -> []);
        (match traces_dir with | Some v -> [("tracesDir", (fun s -> `String s) v)] | None -> []);
        (match artifacts_dir with | Some v -> [("artifactsDir", (fun s -> `String s) v)] | None -> []);
        (match chromium_sandbox with | Some v -> [("chromiumSandbox", (fun b -> `Bool b) v)] | None -> []);
        (match firefox_user_prefs with | Some v -> [("firefoxUserPrefs", (json_to_yojson) v)] | None -> []);
        (match cdp_port with | Some v -> [("cdpPort", (fun i -> `Int i) v)] | None -> []);
        (match no_default_viewport with | Some v -> [("noDefaultViewport", (fun b -> `Bool b) v)] | None -> []);
        (match viewport with | Some v -> [("viewport", (viewport_t_to_yojson) v)] | None -> []);
        (match screen with | Some v -> [("screen", (screen_t_to_yojson) v)] | None -> []);
        (match ignore_https_errors with | Some v -> [("ignoreHTTPSErrors", (fun b -> `Bool b) v)] | None -> []);
        (match client_certificates with | Some v -> [("clientCertificates", ((fun l -> `List (List.map (client_certificates_t_to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match java_script_enabled with | Some v -> [("javaScriptEnabled", (fun b -> `Bool b) v)] | None -> []);
        (match bypass_csp with | Some v -> [("bypassCSP", (fun b -> `Bool b) v)] | None -> []);
        (match user_agent with | Some v -> [("userAgent", (fun s -> `String s) v)] | None -> []);
        (match locale with | Some v -> [("locale", (fun s -> `String s) v)] | None -> []);
        (match timezone_id with | Some v -> [("timezoneId", (fun s -> `String s) v)] | None -> []);
        (match geolocation with | Some v -> [("geolocation", (geolocation_t_to_yojson) v)] | None -> []);
        (match permissions with | Some v -> [("permissions", ((fun l -> `List (List.map (fun s -> `String s) (Array.to_list l)))) v)] | None -> []);
        (match extra_http_headers with | Some v -> [("extraHTTPHeaders", ((fun l -> `List (List.map (NameValue.to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match offline with | Some v -> [("offline", (fun b -> `Bool b) v)] | None -> []);
        (match http_credentials with | Some v -> [("httpCredentials", (http_credentials_t_to_yojson) v)] | None -> []);
        (match device_scale_factor with | Some v -> [("deviceScaleFactor", (fun f -> `Float f) v)] | None -> []);
        (match is_mobile with | Some v -> [("isMobile", (fun b -> `Bool b) v)] | None -> []);
        (match has_touch with | Some v -> [("hasTouch", (fun b -> `Bool b) v)] | None -> []);
        (match color_scheme with | Some v -> [("colorScheme", (color_scheme_t_to_yojson) v)] | None -> []);
        (match reduced_motion with | Some v -> [("reducedMotion", (reduced_motion_t_to_yojson) v)] | None -> []);
        (match forced_colors with | Some v -> [("forcedColors", (forced_colors_t_to_yojson) v)] | None -> []);
        (match accept_downloads with | Some v -> [("acceptDownloads", (accept_downloads_t_to_yojson) v)] | None -> []);
        (match contrast with | Some v -> [("contrast", (contrast_t_to_yojson) v)] | None -> []);
        (match base_url with | Some v -> [("baseURL", (fun s -> `String s) v)] | None -> []);
        (match record_video with | Some v -> [("recordVideo", (record_video_t_to_yojson) v)] | None -> []);
        (match strict_selectors with | Some v -> [("strictSelectors", (fun b -> `Bool b) v)] | None -> []);
        (match service_workers with | Some v -> [("serviceWorkers", (service_workers_t_to_yojson) v)] | None -> []);
        (match selector_engines with | Some v -> [("selectorEngines", ((fun l -> `List (List.map (SelectorEngine.to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match test_id_attribute_name with | Some v -> [("testIdAttributeName", (fun s -> `String s) v)] | None -> []);
        ["userDataDir", (fun s -> `String s) user_data_dir];
        (match slow_mo with | Some v -> [("slowMo", (fun f -> `Float f) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"launchPersistentContext" ~params with
        | Ok res -> launch_persistent_context_res_t_of_yojson res
        | Error e -> Error e

    type connect_over_cdp_res_t = {
        browser : Browser.t [@key "browser"];
        default_context : BrowserContext.t option [@key "defaultContext"] [@default None];
    } [@@deriving yojson {strict = false}]

    let connect_over_cdp ~endpoint_url ?headers ?slow_mo ~timeout ?is_local ?no_defaults (t:t) : (connect_over_cdp_res_t, string) result =
        let params = `Assoc (List.concat [
        ["endpointURL", (fun s -> `String s) endpoint_url];
        (match headers with | Some v -> [("headers", ((fun l -> `List (List.map (NameValue.to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match slow_mo with | Some v -> [("slowMo", (fun f -> `Float f) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
        (match is_local with | Some v -> [("isLocal", (fun b -> `Bool b) v)] | None -> []);
        (match no_defaults with | Some v -> [("noDefaults", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"connectOverCDP" ~params with
        | Ok res -> connect_over_cdp_res_t_of_yojson res
        | Error e -> Error e
    let connect_to_worker ~endpoint ~timeout (t:t) : (Worker.t, string) result =
        let params = `Assoc (List.concat [
        ["endpoint", (fun s -> `String s) endpoint];
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"connectToWorker" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "worker" res with | `Null -> Error "worker is null" | v -> (Worker.of_yojson) v)
        | Error e -> Error e
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
end = struct
    type t = {
        version : string [@key "version"];
        name : string [@key "name"];
        browser_name : browser_name_t [@key "browserName"];
        __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}]
    } [@@deriving yojson {strict = false}]
    and browser_name_t = [
        | `Chromium [@name "chromium"]
        | `Firefox [@name "firefox"]
        | `Webkit [@name "webkit"]
    ] [@@deriving yojson]



    let start_server ~title ?workspace_dir ?metadata ?host ?port (t:t) : (string, string) result =
        let params = `Assoc (List.concat [
        ["title", (fun s -> `String s) title];
        (match workspace_dir with | Some v -> [("workspaceDir", (fun s -> `String s) v)] | None -> []);
        (match metadata with | Some v -> [("metadata", (json_to_yojson) v)] | None -> []);
        (match host with | Some v -> [("host", (fun s -> `String s) v)] | None -> []);
        (match port with | Some v -> [("port", (fun i -> `Int i) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"startServer" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "endpoint" res with | `Null -> Error "endpoint is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_string v)) v)
        | Error e -> Error e
    let stop_server (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"stopServer" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let close ?reason (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match reason with | Some v -> [("reason", (fun s -> `String s) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"close" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let kill_for_tests (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"killForTests" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let default_user_agent_for_test (t:t) : (string, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"defaultUserAgentForTest" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "userAgent" res with | `Null -> Error "userAgent is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_string v)) v)
        | Error e -> Error e

    type storage_state_t = {
        cookies : SetNetworkCookie.t array option [@key "cookies"] [@default None];
        origins : SetOriginStorage.t array option [@key "origins"] [@default None];
    }

    and proxy_t = {
        server : string [@key "server"];
        bypass : string option [@key "bypass"] [@default None];
        username : string option [@key "username"] [@default None];
        password : string option [@key "password"] [@default None];
    }

    and service_workers_t = [
        | `Allow [@name "allow"]
        | `Block [@name "block"]
    ] [@@deriving yojson]


    and record_video_t = {
        dir : string option [@key "dir"] [@default None];
        size : size_t option [@key "size"] [@default None];
        show_actions : show_actions_t option [@key "showActions"] [@default None];
    }

    and show_actions_t = {
        duration : float option [@key "duration"] [@default None];
        position : position_t option [@key "position"] [@default None];
        font_size : int option [@key "fontSize"] [@default None];
    }

    and position_t = [
        | `Top_left [@name "top-left"]
        | `Top [@name "top"]
        | `Top_right [@name "top-right"]
        | `Bottom_left [@name "bottom-left"]
        | `Bottom [@name "bottom"]
        | `Bottom_right [@name "bottom-right"]
    ] [@@deriving yojson]


    and size_t = {
        width : int [@key "width"];
        height : int [@key "height"];
    }

    and contrast_t = [
        | `No_preference [@name "no-preference"]
        | `More [@name "more"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]


    and accept_downloads_t = [
        | `Accept [@name "accept"]
        | `Deny [@name "deny"]
        | `Internal_browser_default [@name "internal-browser-default"]
    ] [@@deriving yojson]


    and forced_colors_t = [
        | `Active [@name "active"]
        | `None [@name "none"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]


    and reduced_motion_t = [
        | `Reduce [@name "reduce"]
        | `No_preference [@name "no-preference"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]


    and color_scheme_t = [
        | `Dark [@name "dark"]
        | `Light [@name "light"]
        | `No_preference [@name "no-preference"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]


    and http_credentials_t = {
        username : string [@key "username"];
        password : string [@key "password"];
        origin : string option [@key "origin"] [@default None];
        send : send_t option [@key "send"] [@default None];
    }

    and send_t = [
        | `Always [@name "always"]
        | `Unauthorized [@name "unauthorized"]
    ] [@@deriving yojson]


    and geolocation_t = {
        longitude : float [@key "longitude"];
        latitude : float [@key "latitude"];
        accuracy : float option [@key "accuracy"] [@default None];
    }

    and client_certificates_t = {
        origin : string [@key "origin"];
        cert : string option [@key "cert"] [@default None];
        key : string option [@key "key"] [@default None];
        passphrase : string option [@key "passphrase"] [@default None];
        pfx : string option [@key "pfx"] [@default None];
    }

    and screen_t = {
        width : int [@key "width"];
        height : int [@key "height"];
    }

    and viewport_t = {
        width : int [@key "width"];
        height : int [@key "height"];
    }

    let new_context ?no_default_viewport ?viewport ?screen ?ignore_https_errors ?client_certificates ?java_script_enabled ?bypass_csp ?user_agent ?locale ?timezone_id ?geolocation ?permissions ?extra_http_headers ?offline ?http_credentials ?device_scale_factor ?is_mobile ?has_touch ?color_scheme ?reduced_motion ?forced_colors ?accept_downloads ?contrast ?base_url ?record_video ?strict_selectors ?service_workers ?selector_engines ?test_id_attribute_name ?proxy ?storage_state (t:t) : (BrowserContext.t, string) result =
        let params = `Assoc (List.concat [
        (match no_default_viewport with | Some v -> [("noDefaultViewport", (fun b -> `Bool b) v)] | None -> []);
        (match viewport with | Some v -> [("viewport", (viewport_t_to_yojson) v)] | None -> []);
        (match screen with | Some v -> [("screen", (screen_t_to_yojson) v)] | None -> []);
        (match ignore_https_errors with | Some v -> [("ignoreHTTPSErrors", (fun b -> `Bool b) v)] | None -> []);
        (match client_certificates with | Some v -> [("clientCertificates", ((fun l -> `List (List.map (client_certificates_t_to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match java_script_enabled with | Some v -> [("javaScriptEnabled", (fun b -> `Bool b) v)] | None -> []);
        (match bypass_csp with | Some v -> [("bypassCSP", (fun b -> `Bool b) v)] | None -> []);
        (match user_agent with | Some v -> [("userAgent", (fun s -> `String s) v)] | None -> []);
        (match locale with | Some v -> [("locale", (fun s -> `String s) v)] | None -> []);
        (match timezone_id with | Some v -> [("timezoneId", (fun s -> `String s) v)] | None -> []);
        (match geolocation with | Some v -> [("geolocation", (geolocation_t_to_yojson) v)] | None -> []);
        (match permissions with | Some v -> [("permissions", ((fun l -> `List (List.map (fun s -> `String s) (Array.to_list l)))) v)] | None -> []);
        (match extra_http_headers with | Some v -> [("extraHTTPHeaders", ((fun l -> `List (List.map (NameValue.to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match offline with | Some v -> [("offline", (fun b -> `Bool b) v)] | None -> []);
        (match http_credentials with | Some v -> [("httpCredentials", (http_credentials_t_to_yojson) v)] | None -> []);
        (match device_scale_factor with | Some v -> [("deviceScaleFactor", (fun f -> `Float f) v)] | None -> []);
        (match is_mobile with | Some v -> [("isMobile", (fun b -> `Bool b) v)] | None -> []);
        (match has_touch with | Some v -> [("hasTouch", (fun b -> `Bool b) v)] | None -> []);
        (match color_scheme with | Some v -> [("colorScheme", (color_scheme_t_to_yojson) v)] | None -> []);
        (match reduced_motion with | Some v -> [("reducedMotion", (reduced_motion_t_to_yojson) v)] | None -> []);
        (match forced_colors with | Some v -> [("forcedColors", (forced_colors_t_to_yojson) v)] | None -> []);
        (match accept_downloads with | Some v -> [("acceptDownloads", (accept_downloads_t_to_yojson) v)] | None -> []);
        (match contrast with | Some v -> [("contrast", (contrast_t_to_yojson) v)] | None -> []);
        (match base_url with | Some v -> [("baseURL", (fun s -> `String s) v)] | None -> []);
        (match record_video with | Some v -> [("recordVideo", (record_video_t_to_yojson) v)] | None -> []);
        (match strict_selectors with | Some v -> [("strictSelectors", (fun b -> `Bool b) v)] | None -> []);
        (match service_workers with | Some v -> [("serviceWorkers", (service_workers_t_to_yojson) v)] | None -> []);
        (match selector_engines with | Some v -> [("selectorEngines", ((fun l -> `List (List.map (SelectorEngine.to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match test_id_attribute_name with | Some v -> [("testIdAttributeName", (fun s -> `String s) v)] | None -> []);
        (match proxy with | Some v -> [("proxy", (proxy_t_to_yojson) v)] | None -> []);
        (match storage_state with | Some v -> [("storageState", (storage_state_t_to_yojson) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"newContext" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "context" res with | `Null -> Error "context is null" | v -> (BrowserContext.of_yojson) v)
        | Error e -> Error e
    let new_context_for_reuse ?no_default_viewport ?viewport ?screen ?ignore_https_errors ?client_certificates ?java_script_enabled ?bypass_csp ?user_agent ?locale ?timezone_id ?geolocation ?permissions ?extra_http_headers ?offline ?http_credentials ?device_scale_factor ?is_mobile ?has_touch ?color_scheme ?reduced_motion ?forced_colors ?accept_downloads ?contrast ?base_url ?record_video ?strict_selectors ?service_workers ?selector_engines ?test_id_attribute_name ?proxy ?storage_state (t:t) : (BrowserContext.t, string) result =
        let params = `Assoc (List.concat [
        (match no_default_viewport with | Some v -> [("noDefaultViewport", (fun b -> `Bool b) v)] | None -> []);
        (match viewport with | Some v -> [("viewport", (viewport_t_to_yojson) v)] | None -> []);
        (match screen with | Some v -> [("screen", (screen_t_to_yojson) v)] | None -> []);
        (match ignore_https_errors with | Some v -> [("ignoreHTTPSErrors", (fun b -> `Bool b) v)] | None -> []);
        (match client_certificates with | Some v -> [("clientCertificates", ((fun l -> `List (List.map (client_certificates_t_to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match java_script_enabled with | Some v -> [("javaScriptEnabled", (fun b -> `Bool b) v)] | None -> []);
        (match bypass_csp with | Some v -> [("bypassCSP", (fun b -> `Bool b) v)] | None -> []);
        (match user_agent with | Some v -> [("userAgent", (fun s -> `String s) v)] | None -> []);
        (match locale with | Some v -> [("locale", (fun s -> `String s) v)] | None -> []);
        (match timezone_id with | Some v -> [("timezoneId", (fun s -> `String s) v)] | None -> []);
        (match geolocation with | Some v -> [("geolocation", (geolocation_t_to_yojson) v)] | None -> []);
        (match permissions with | Some v -> [("permissions", ((fun l -> `List (List.map (fun s -> `String s) (Array.to_list l)))) v)] | None -> []);
        (match extra_http_headers with | Some v -> [("extraHTTPHeaders", ((fun l -> `List (List.map (NameValue.to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match offline with | Some v -> [("offline", (fun b -> `Bool b) v)] | None -> []);
        (match http_credentials with | Some v -> [("httpCredentials", (http_credentials_t_to_yojson) v)] | None -> []);
        (match device_scale_factor with | Some v -> [("deviceScaleFactor", (fun f -> `Float f) v)] | None -> []);
        (match is_mobile with | Some v -> [("isMobile", (fun b -> `Bool b) v)] | None -> []);
        (match has_touch with | Some v -> [("hasTouch", (fun b -> `Bool b) v)] | None -> []);
        (match color_scheme with | Some v -> [("colorScheme", (color_scheme_t_to_yojson) v)] | None -> []);
        (match reduced_motion with | Some v -> [("reducedMotion", (reduced_motion_t_to_yojson) v)] | None -> []);
        (match forced_colors with | Some v -> [("forcedColors", (forced_colors_t_to_yojson) v)] | None -> []);
        (match accept_downloads with | Some v -> [("acceptDownloads", (accept_downloads_t_to_yojson) v)] | None -> []);
        (match contrast with | Some v -> [("contrast", (contrast_t_to_yojson) v)] | None -> []);
        (match base_url with | Some v -> [("baseURL", (fun s -> `String s) v)] | None -> []);
        (match record_video with | Some v -> [("recordVideo", (record_video_t_to_yojson) v)] | None -> []);
        (match strict_selectors with | Some v -> [("strictSelectors", (fun b -> `Bool b) v)] | None -> []);
        (match service_workers with | Some v -> [("serviceWorkers", (service_workers_t_to_yojson) v)] | None -> []);
        (match selector_engines with | Some v -> [("selectorEngines", ((fun l -> `List (List.map (SelectorEngine.to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match test_id_attribute_name with | Some v -> [("testIdAttributeName", (fun s -> `String s) v)] | None -> []);
        (match proxy with | Some v -> [("proxy", (proxy_t_to_yojson) v)] | None -> []);
        (match storage_state with | Some v -> [("storageState", (storage_state_t_to_yojson) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"newContextForReuse" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "context" res with | `Null -> Error "context is null" | v -> (BrowserContext.of_yojson) v)
        | Error e -> Error e
    let disconnect_from_reused_context ~reason (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["reason", (fun s -> `String s) reason];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"disconnectFromReusedContext" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let new_browser_cdp_session (t:t) : (CDPSession.t, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"newBrowserCDPSession" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "session" res with | `Null -> Error "session is null" | v -> (CDPSession.of_yojson) v)
        | Error e -> Error e
    let start_tracing ?page ?screenshots ?categories (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match page with | Some v -> [("page", (Page.to_yojson) v)] | None -> []);
        (match screenshots with | Some v -> [("screenshots", (fun b -> `Bool b) v)] | None -> []);
        (match categories with | Some v -> [("categories", ((fun l -> `List (List.map (fun s -> `String s) (Array.to_list l)))) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"startTracing" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let stop_tracing (t:t) : (Artifact.t, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"stopTracing" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "artifact" res with | `Null -> Error "artifact is null" | v -> (Artifact.of_yojson) v)
        | Error e -> Error e
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
end = struct
    type t = { __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}] } [@@deriving yojson {strict = false}]


    type info_t = {
        wait_id : string [@key "waitId"];
        phase : phase_t [@key "phase"];
        event : string option [@key "event"] [@default None];
        message : string option [@key "message"] [@default None];
        error : string option [@key "error"] [@default None];
    }

    and phase_t = [
        | `Before [@name "before"]
        | `After [@name "after"]
        | `Log [@name "log"]
    ] [@@deriving yojson]


    let wait_for_event_info ~info (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["info", (info_t_to_yojson) info];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"waitForEventInfo" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
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
end = struct
    type t = {
        debugger : Debugger.t [@key "debugger"];
        request_context : APIRequestContext.t [@key "requestContext"];
        tracing : Tracing.t [@key "tracing"];
        options : options_t [@key "options"];
        __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}]
    } [@@deriving yojson {strict = false}]
    and options_t = {
        no_default_viewport : bool option [@key "noDefaultViewport"] [@default None];
        viewport : viewport_t option [@key "viewport"] [@default None];
        screen : screen_t option [@key "screen"] [@default None];
        ignore_https_errors : bool option [@key "ignoreHTTPSErrors"] [@default None];
        client_certificates : client_certificates_t array option [@key "clientCertificates"] [@default None];
        java_script_enabled : bool option [@key "javaScriptEnabled"] [@default None];
        bypass_csp : bool option [@key "bypassCSP"] [@default None];
        user_agent : string option [@key "userAgent"] [@default None];
        locale : string option [@key "locale"] [@default None];
        timezone_id : string option [@key "timezoneId"] [@default None];
        geolocation : geolocation_t option [@key "geolocation"] [@default None];
        permissions : string array option [@key "permissions"] [@default None];
        extra_http_headers : NameValue.t array option [@key "extraHTTPHeaders"] [@default None];
        offline : bool option [@key "offline"] [@default None];
        http_credentials : http_credentials_t option [@key "httpCredentials"] [@default None];
        device_scale_factor : float option [@key "deviceScaleFactor"] [@default None];
        is_mobile : bool option [@key "isMobile"] [@default None];
        has_touch : bool option [@key "hasTouch"] [@default None];
        color_scheme : color_scheme_t option [@key "colorScheme"] [@default None];
        reduced_motion : reduced_motion_t option [@key "reducedMotion"] [@default None];
        forced_colors : forced_colors_t option [@key "forcedColors"] [@default None];
        accept_downloads : accept_downloads_t option [@key "acceptDownloads"] [@default None];
        contrast : contrast_t option [@key "contrast"] [@default None];
        base_url : string option [@key "baseURL"] [@default None];
        record_video : record_video_t option [@key "recordVideo"] [@default None];
        strict_selectors : bool option [@key "strictSelectors"] [@default None];
        service_workers : service_workers_t option [@key "serviceWorkers"] [@default None];
        selector_engines : SelectorEngine.t array option [@key "selectorEngines"] [@default None];
        test_id_attribute_name : string option [@key "testIdAttributeName"] [@default None];
    }

    and service_workers_t = [
        | `Allow [@name "allow"]
        | `Block [@name "block"]
    ] [@@deriving yojson]


    and record_video_t = {
        dir : string option [@key "dir"] [@default None];
        size : size_t option [@key "size"] [@default None];
        show_actions : show_actions_t option [@key "showActions"] [@default None];
    }

    and show_actions_t = {
        duration : float option [@key "duration"] [@default None];
        position : position_t option [@key "position"] [@default None];
        font_size : int option [@key "fontSize"] [@default None];
    }

    and position_t = [
        | `Top_left [@name "top-left"]
        | `Top [@name "top"]
        | `Top_right [@name "top-right"]
        | `Bottom_left [@name "bottom-left"]
        | `Bottom [@name "bottom"]
        | `Bottom_right [@name "bottom-right"]
    ] [@@deriving yojson]


    and size_t = {
        width : int [@key "width"];
        height : int [@key "height"];
    }

    and contrast_t = [
        | `No_preference [@name "no-preference"]
        | `More [@name "more"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]


    and accept_downloads_t = [
        | `Accept [@name "accept"]
        | `Deny [@name "deny"]
        | `Internal_browser_default [@name "internal-browser-default"]
    ] [@@deriving yojson]


    and forced_colors_t = [
        | `Active [@name "active"]
        | `None [@name "none"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]


    and reduced_motion_t = [
        | `Reduce [@name "reduce"]
        | `No_preference [@name "no-preference"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]


    and color_scheme_t = [
        | `Dark [@name "dark"]
        | `Light [@name "light"]
        | `No_preference [@name "no-preference"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]


    and http_credentials_t = {
        username : string [@key "username"];
        password : string [@key "password"];
        origin : string option [@key "origin"] [@default None];
        send : send_t option [@key "send"] [@default None];
    }

    and send_t = [
        | `Always [@name "always"]
        | `Unauthorized [@name "unauthorized"]
    ] [@@deriving yojson]


    and geolocation_t = {
        longitude : float [@key "longitude"];
        latitude : float [@key "latitude"];
        accuracy : float option [@key "accuracy"] [@default None];
    }

    and client_certificates_t = {
        origin : string [@key "origin"];
        cert : string option [@key "cert"] [@default None];
        key : string option [@key "key"] [@default None];
        passphrase : string option [@key "passphrase"] [@default None];
        pfx : string option [@key "pfx"] [@default None];
    }

    and screen_t = {
        width : int [@key "width"];
        height : int [@key "height"];
    }

    and viewport_t = {
        width : int [@key "width"];
        height : int [@key "height"];
    }



    type info_t = {
        wait_id : string [@key "waitId"];
        phase : phase_t [@key "phase"];
        event : string option [@key "event"] [@default None];
        message : string option [@key "message"] [@default None];
        error : string option [@key "error"] [@default None];
    }

    and phase_t = [
        | `Before [@name "before"]
        | `After [@name "after"]
        | `Log [@name "log"]
    ] [@@deriving yojson]


    let wait_for_event_info ~info (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["info", (info_t_to_yojson) info];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"waitForEventInfo" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let add_cookies ~cookies (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["cookies", ((fun l -> `List (List.map (SetNetworkCookie.to_yojson) (Array.to_list l)))) cookies];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"addCookies" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let add_init_script ~source (t:t) : (Disposable.t, string) result =
        let params = `Assoc (List.concat [
        ["source", (fun s -> `String s) source];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"addInitScript" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "disposable" res with | `Null -> Error "disposable is null" | v -> (Disposable.of_yojson) v)
        | Error e -> Error e
    let clear_cookies ?name ?name_regex_source ?name_regex_flags ?domain ?domain_regex_source ?domain_regex_flags ?path ?path_regex_source ?path_regex_flags (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match name with | Some v -> [("name", (fun s -> `String s) v)] | None -> []);
        (match name_regex_source with | Some v -> [("nameRegexSource", (fun s -> `String s) v)] | None -> []);
        (match name_regex_flags with | Some v -> [("nameRegexFlags", (fun s -> `String s) v)] | None -> []);
        (match domain with | Some v -> [("domain", (fun s -> `String s) v)] | None -> []);
        (match domain_regex_source with | Some v -> [("domainRegexSource", (fun s -> `String s) v)] | None -> []);
        (match domain_regex_flags with | Some v -> [("domainRegexFlags", (fun s -> `String s) v)] | None -> []);
        (match path with | Some v -> [("path", (fun s -> `String s) v)] | None -> []);
        (match path_regex_source with | Some v -> [("pathRegexSource", (fun s -> `String s) v)] | None -> []);
        (match path_regex_flags with | Some v -> [("pathRegexFlags", (fun s -> `String s) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"clearCookies" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let clear_permissions (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"clearPermissions" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let close ?reason (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match reason with | Some v -> [("reason", (fun s -> `String s) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"close" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let cookies ~urls (t:t) : (NetworkCookie.t array, string) result =
        let params = `Assoc (List.concat [
        ["urls", ((fun l -> `List (List.map (fun s -> `String s) (Array.to_list l)))) urls];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"cookies" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "cookies" res with | `Null -> Error "cookies is null" | v -> ((fun v -> try Ok (Array.of_list (List.map (fun item -> match (NetworkCookie.of_yojson) item with Ok r -> r | Error e -> failwith e) (Yojson.Safe.Util.to_list v))) with Failure e -> Error e)) v)
        | Error e -> Error e
    let expose_binding ~name (t:t) : (Disposable.t, string) result =
        let params = `Assoc (List.concat [
        ["name", (fun s -> `String s) name];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"exposeBinding" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "disposable" res with | `Null -> Error "disposable is null" | v -> (Disposable.of_yojson) v)
        | Error e -> Error e
    let grant_permissions ~permissions ?origin (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["permissions", ((fun l -> `List (List.map (fun s -> `String s) (Array.to_list l)))) permissions];
        (match origin with | Some v -> [("origin", (fun s -> `String s) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"grantPermissions" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let new_page (t:t) : (Page.t, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"newPage" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "page" res with | `Null -> Error "page is null" | v -> (Page.of_yojson) v)
        | Error e -> Error e
    let register_selector_engine ~selector_engine (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["selectorEngine", (SelectorEngine.to_yojson) selector_engine];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"registerSelectorEngine" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let set_test_id_attribute_name ~test_id_attribute_name (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["testIdAttributeName", (fun s -> `String s) test_id_attribute_name];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"setTestIdAttributeName" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let set_extra_http_headers ~headers (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["headers", ((fun l -> `List (List.map (NameValue.to_yojson) (Array.to_list l)))) headers];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"setExtraHTTPHeaders" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let set_geolocation ?geolocation (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match geolocation with | Some v -> [("geolocation", (geolocation_t_to_yojson) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"setGeolocation" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let set_http_credentials ?http_credentials (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match http_credentials with | Some v -> [("httpCredentials", (http_credentials_t_to_yojson) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"setHTTPCredentials" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e

    type patterns_t = {
        glob : string option [@key "glob"] [@default None];
        regex_source : string option [@key "regexSource"] [@default None];
        regex_flags : string option [@key "regexFlags"] [@default None];
        url_pattern : URLPattern.t option [@key "urlPattern"] [@default None];
    }

    let set_network_interception_patterns ~patterns (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["patterns", ((fun l -> `List (List.map (patterns_t_to_yojson) (Array.to_list l)))) patterns];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"setNetworkInterceptionPatterns" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let set_web_socket_interception_patterns ~patterns (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["patterns", ((fun l -> `List (List.map (patterns_t_to_yojson) (Array.to_list l)))) patterns];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"setWebSocketInterceptionPatterns" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let set_offline ~offline (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["offline", (fun b -> `Bool b) offline];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"setOffline" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e

    type storage_state_res_t = {
        cookies : NetworkCookie.t array [@key "cookies"];
        origins : OriginStorage.t array [@key "origins"];
    } [@@deriving yojson {strict = false}]

    let storage_state ?indexed_db (t:t) : (storage_state_res_t, string) result =
        let params = `Assoc (List.concat [
        (match indexed_db with | Some v -> [("indexedDB", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"storageState" ~params with
        | Ok res -> storage_state_res_t_of_yojson res
        | Error e -> Error e

    type storage_state_t = {
        cookies : SetNetworkCookie.t array option [@key "cookies"] [@default None];
        origins : SetOriginStorage.t array option [@key "origins"] [@default None];
    }

    let set_storage_state ?storage_state (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match storage_state with | Some v -> [("storageState", (storage_state_t_to_yojson) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"setStorageState" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let pause (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"pause" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e

    type recorder_mode_t = [
        | `Default [@name "default"]
        | `Api [@name "api"]
    ] [@@deriving yojson]


    and mode_t = [
        | `Inspecting [@name "inspecting"]
        | `Recording [@name "recording"]
    ] [@@deriving yojson]


    let enable_recorder ?language ?mode ?recorder_mode ?pause_on_next_statement ?test_id_attribute_name ?launch_options ?context_options ?device ?save_storage ?output_file ?handle_sigint ?omit_call_tracking (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match language with | Some v -> [("language", (fun s -> `String s) v)] | None -> []);
        (match mode with | Some v -> [("mode", (mode_t_to_yojson) v)] | None -> []);
        (match recorder_mode with | Some v -> [("recorderMode", (recorder_mode_t_to_yojson) v)] | None -> []);
        (match pause_on_next_statement with | Some v -> [("pauseOnNextStatement", (fun b -> `Bool b) v)] | None -> []);
        (match test_id_attribute_name with | Some v -> [("testIdAttributeName", (fun s -> `String s) v)] | None -> []);
        (match launch_options with | Some v -> [("launchOptions", (json_to_yojson) v)] | None -> []);
        (match context_options with | Some v -> [("contextOptions", (json_to_yojson) v)] | None -> []);
        (match device with | Some v -> [("device", (fun s -> `String s) v)] | None -> []);
        (match save_storage with | Some v -> [("saveStorage", (fun s -> `String s) v)] | None -> []);
        (match output_file with | Some v -> [("outputFile", (fun s -> `String s) v)] | None -> []);
        (match handle_sigint with | Some v -> [("handleSIGINT", (fun b -> `Bool b) v)] | None -> []);
        (match omit_call_tracking with | Some v -> [("omitCallTracking", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"enableRecorder" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let disable_recorder (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"disableRecorder" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let expose_console_api (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"exposeConsoleApi" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let new_cdp_session ?page ?frame (t:t) : (CDPSession.t, string) result =
        let params = `Assoc (List.concat [
        (match page with | Some v -> [("page", (Page.to_yojson) v)] | None -> []);
        (match frame with | Some v -> [("frame", (Frame.to_yojson) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"newCDPSession" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "session" res with | `Null -> Error "session is null" | v -> (CDPSession.of_yojson) v)
        | Error e -> Error e

    type create_temp_files_res_t = {
        root_dir : WritableStream.t option [@key "rootDir"] [@default None];
        writable_streams : WritableStream.t array [@key "writableStreams"];
    } [@@deriving yojson {strict = false}]

    and items_t = {
        name : string [@key "name"];
        last_modified_ms : float option [@key "lastModifiedMs"] [@default None];
    }

    let create_temp_files ?root_dir_name ~items (t:t) : (create_temp_files_res_t, string) result =
        let params = `Assoc (List.concat [
        (match root_dir_name with | Some v -> [("rootDirName", (fun s -> `String s) v)] | None -> []);
        ["items", ((fun l -> `List (List.map (items_t_to_yojson) (Array.to_list l)))) items];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"createTempFiles" ~params with
        | Ok res -> create_temp_files_res_t_of_yojson res
        | Error e -> Error e

    type event_t = [
        | `Console [@name "console"]
        | `Dialog [@name "dialog"]
        | `Request [@name "request"]
        | `Response [@name "response"]
        | `Request_finished [@name "requestFinished"]
        | `Request_failed [@name "requestFailed"]
    ] [@@deriving yojson]


    let update_subscription ~event ~enabled (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["event", (event_t_to_yojson) event];
        ["enabled", (fun b -> `Bool b) enabled];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"updateSubscription" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let clock_fast_forward ?ticks_number ?ticks_string (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match ticks_number with | Some v -> [("ticksNumber", (fun f -> `Float f) v)] | None -> []);
        (match ticks_string with | Some v -> [("ticksString", (fun s -> `String s) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"clockFastForward" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let clock_install ?time_number ?time_string (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match time_number with | Some v -> [("timeNumber", (fun f -> `Float f) v)] | None -> []);
        (match time_string with | Some v -> [("timeString", (fun s -> `String s) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"clockInstall" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let clock_pause_at ?time_number ?time_string (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match time_number with | Some v -> [("timeNumber", (fun f -> `Float f) v)] | None -> []);
        (match time_string with | Some v -> [("timeString", (fun s -> `String s) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"clockPauseAt" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let clock_resume (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"clockResume" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let clock_run_for ?ticks_number ?ticks_string (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match ticks_number with | Some v -> [("ticksNumber", (fun f -> `Float f) v)] | None -> []);
        (match ticks_string with | Some v -> [("ticksString", (fun s -> `String s) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"clockRunFor" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let clock_set_fixed_time ?time_number ?time_string (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match time_number with | Some v -> [("timeNumber", (fun f -> `Float f) v)] | None -> []);
        (match time_string with | Some v -> [("timeString", (fun s -> `String s) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"clockSetFixedTime" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let clock_set_system_time ?time_number ?time_string (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match time_number with | Some v -> [("timeNumber", (fun f -> `Float f) v)] | None -> []);
        (match time_string with | Some v -> [("timeString", (fun s -> `String s) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"clockSetSystemTime" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
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
end = struct
    type t = {
        main_frame : Frame.t [@key "mainFrame"];
        viewport_size : viewport_size_t option [@key "viewportSize"] [@default None];
        is_closed : bool [@key "isClosed"];
        opener : Page.t option [@key "opener"] [@default None];
        video : Artifact.t option [@key "video"] [@default None];
        __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}]
    } [@@deriving yojson {strict = false}]
    and viewport_size_t = {
        width : int [@key "width"];
        height : int [@key "height"];
    }



    type info_t = {
        wait_id : string [@key "waitId"];
        phase : phase_t [@key "phase"];
        event : string option [@key "event"] [@default None];
        message : string option [@key "message"] [@default None];
        error : string option [@key "error"] [@default None];
    }

    and phase_t = [
        | `Before [@name "before"]
        | `After [@name "after"]
        | `Log [@name "log"]
    ] [@@deriving yojson]


    let wait_for_event_info ~info (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["info", (info_t_to_yojson) info];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"waitForEventInfo" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let add_init_script ~source (t:t) : (Disposable.t, string) result =
        let params = `Assoc (List.concat [
        ["source", (fun s -> `String s) source];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"addInitScript" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "disposable" res with | `Null -> Error "disposable is null" | v -> (Disposable.of_yojson) v)
        | Error e -> Error e
    let close ?run_before_unload ?reason (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match run_before_unload with | Some v -> [("runBeforeUnload", (fun b -> `Bool b) v)] | None -> []);
        (match reason with | Some v -> [("reason", (fun s -> `String s) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"close" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let clear_console_messages (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"clearConsoleMessages" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e

    type messages_t = {
        type_ : string [@key "type"];
        text : string [@key "text"];
        args : JSHandle.t array [@key "args"];
        location : location_t [@key "location"];
        timestamp : float [@key "timestamp"];
    }

    and location_t = {
        url : string [@key "url"];
        line_number : int [@key "lineNumber"];
        column_number : int [@key "columnNumber"];
    }

    let console_messages ?filter (t:t) : (messages_t array, string) result =
        let params = `Assoc (List.concat [
        (match filter with | Some v -> [("filter", (ConsoleMessagesFilter.to_yojson) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"consoleMessages" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "messages" res with | `Null -> Error "messages is null" | v -> ((fun v -> try Ok (Array.of_list (List.map (fun item -> match (messages_t_of_yojson) item with Ok r -> r | Error e -> failwith e) (Yojson.Safe.Util.to_list v))) with Failure e -> Error e)) v)
        | Error e -> Error e

    type contrast_t = [
        | `No_preference [@name "no-preference"]
        | `More [@name "more"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]


    and forced_colors_t = [
        | `Active [@name "active"]
        | `None [@name "none"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]


    and reduced_motion_t = [
        | `Reduce [@name "reduce"]
        | `No_preference [@name "no-preference"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]


    and color_scheme_t = [
        | `Dark [@name "dark"]
        | `Light [@name "light"]
        | `No_preference [@name "no-preference"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]


    and media_t = [
        | `Screen [@name "screen"]
        | `Print [@name "print"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]


    let emulate_media ?media ?color_scheme ?reduced_motion ?forced_colors ?contrast (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match media with | Some v -> [("media", (media_t_to_yojson) v)] | None -> []);
        (match color_scheme with | Some v -> [("colorScheme", (color_scheme_t_to_yojson) v)] | None -> []);
        (match reduced_motion with | Some v -> [("reducedMotion", (reduced_motion_t_to_yojson) v)] | None -> []);
        (match forced_colors with | Some v -> [("forcedColors", (forced_colors_t_to_yojson) v)] | None -> []);
        (match contrast with | Some v -> [("contrast", (contrast_t_to_yojson) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"emulateMedia" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let expose_binding ~name (t:t) : (Disposable.t, string) result =
        let params = `Assoc (List.concat [
        ["name", (fun s -> `String s) name];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"exposeBinding" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "disposable" res with | `Null -> Error "disposable is null" | v -> (Disposable.of_yojson) v)
        | Error e -> Error e
    let go_back ~timeout ?wait_until (t:t) : (Response.t option, string) result =
        let params = `Assoc (List.concat [
        ["timeout", (fun f -> `Float f) timeout];
        (match wait_until with | Some v -> [("waitUntil", (LifecycleEvent.to_yojson) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"goBack" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "response" res with | `Null -> Ok None | v -> match (Response.of_yojson) v with Ok r -> Ok (Some r) | Error e -> Error e)
        | Error e -> Error e
    let go_forward ~timeout ?wait_until (t:t) : (Response.t option, string) result =
        let params = `Assoc (List.concat [
        ["timeout", (fun f -> `Float f) timeout];
        (match wait_until with | Some v -> [("waitUntil", (LifecycleEvent.to_yojson) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"goForward" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "response" res with | `Null -> Ok None | v -> match (Response.of_yojson) v with Ok r -> Ok (Some r) | Error e -> Error e)
        | Error e -> Error e
    let request_gc (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"requestGC" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let register_locator_handler ~selector ?no_wait_after (t:t) : (int, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match no_wait_after with | Some v -> [("noWaitAfter", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"registerLocatorHandler" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "uid" res with | `Null -> Error "uid is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_int v)) v)
        | Error e -> Error e
    let resolve_locator_handler_no_reply ~uid ?remove (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["uid", (fun i -> `Int i) uid];
        (match remove with | Some v -> [("remove", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"resolveLocatorHandlerNoReply" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let unregister_locator_handler ~uid (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["uid", (fun i -> `Int i) uid];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"unregisterLocatorHandler" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let reload ~timeout ?wait_until (t:t) : (Response.t option, string) result =
        let params = `Assoc (List.concat [
        ["timeout", (fun f -> `Float f) timeout];
        (match wait_until with | Some v -> [("waitUntil", (LifecycleEvent.to_yojson) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"reload" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "response" res with | `Null -> Ok None | v -> match (Response.of_yojson) v with Ok r -> Ok (Some r) | Error e -> Error e)
        | Error e -> Error e

    type expect_screenshot_res_t = {
        diff : string option [@key "diff"] [@default None];
        error_message : string option [@key "errorMessage"] [@default None];
        actual : string option [@key "actual"] [@default None];
        previous : string option [@key "previous"] [@default None];
        timed_out : bool option [@key "timedOut"] [@default None];
        log : string array option [@key "log"] [@default None];
    } [@@deriving yojson {strict = false}]

    and mask_t = {
        frame : Frame.t [@key "frame"];
        selector : string [@key "selector"];
    }

    and scale_t = [
        | `Css [@name "css"]
        | `Device [@name "device"]
    ] [@@deriving yojson]


    and animations_t = [
        | `Disabled [@name "disabled"]
        | `Allow [@name "allow"]
    ] [@@deriving yojson]


    and caret_t = [
        | `Hide [@name "hide"]
        | `Initial [@name "initial"]
    ] [@@deriving yojson]


    and locator_t = {
        frame : Frame.t [@key "frame"];
        selector : string [@key "selector"];
    }

    let expect_screenshot ?expected ~timeout ~is_not ?locator ?comparator ?max_diff_pixels ?max_diff_pixel_ratio ?threshold ?full_page ?clip ?omit_background ?caret ?animations ?scale ?mask ?mask_color ?style (t:t) : (expect_screenshot_res_t, string) result =
        let params = `Assoc (List.concat [
        (match expected with | Some v -> [("expected", (fun s -> `String (Base64.encode_exn s)) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
        ["isNot", (fun b -> `Bool b) is_not];
        (match locator with | Some v -> [("locator", (locator_t_to_yojson) v)] | None -> []);
        (match comparator with | Some v -> [("comparator", (fun s -> `String s) v)] | None -> []);
        (match max_diff_pixels with | Some v -> [("maxDiffPixels", (fun i -> `Int i) v)] | None -> []);
        (match max_diff_pixel_ratio with | Some v -> [("maxDiffPixelRatio", (fun f -> `Float f) v)] | None -> []);
        (match threshold with | Some v -> [("threshold", (fun f -> `Float f) v)] | None -> []);
        (match full_page with | Some v -> [("fullPage", (fun b -> `Bool b) v)] | None -> []);
        (match clip with | Some v -> [("clip", (Rect.to_yojson) v)] | None -> []);
        (match omit_background with | Some v -> [("omitBackground", (fun b -> `Bool b) v)] | None -> []);
        (match caret with | Some v -> [("caret", (caret_t_to_yojson) v)] | None -> []);
        (match animations with | Some v -> [("animations", (animations_t_to_yojson) v)] | None -> []);
        (match scale with | Some v -> [("scale", (scale_t_to_yojson) v)] | None -> []);
        (match mask with | Some v -> [("mask", ((fun l -> `List (List.map (mask_t_to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match mask_color with | Some v -> [("maskColor", (fun s -> `String s) v)] | None -> []);
        (match style with | Some v -> [("style", (fun s -> `String s) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"expectScreenshot" ~params with
        | Ok res -> expect_screenshot_res_t_of_yojson res
        | Error e -> Error e

    type type__t = [
        | `Png [@name "png"]
        | `Jpeg [@name "jpeg"]
    ] [@@deriving yojson]


    let screenshot ~timeout ?type_ ?quality ?full_page ?clip ?omit_background ?caret ?animations ?scale ?mask ?mask_color ?style (t:t) : (string, string) result =
        let params = `Assoc (List.concat [
        ["timeout", (fun f -> `Float f) timeout];
        (match type_ with | Some v -> [("type", (type__t_to_yojson) v)] | None -> []);
        (match quality with | Some v -> [("quality", (fun i -> `Int i) v)] | None -> []);
        (match full_page with | Some v -> [("fullPage", (fun b -> `Bool b) v)] | None -> []);
        (match clip with | Some v -> [("clip", (Rect.to_yojson) v)] | None -> []);
        (match omit_background with | Some v -> [("omitBackground", (fun b -> `Bool b) v)] | None -> []);
        (match caret with | Some v -> [("caret", (caret_t_to_yojson) v)] | None -> []);
        (match animations with | Some v -> [("animations", (animations_t_to_yojson) v)] | None -> []);
        (match scale with | Some v -> [("scale", (scale_t_to_yojson) v)] | None -> []);
        (match mask with | Some v -> [("mask", ((fun l -> `List (List.map (mask_t_to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match mask_color with | Some v -> [("maskColor", (fun s -> `String s) v)] | None -> []);
        (match style with | Some v -> [("style", (fun s -> `String s) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"screenshot" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "binary" res with | `Null -> Error "binary is null" | v -> (fun v -> Ok (Base64.decode_exn (Yojson.Safe.Util.to_string v))) v)
        | Error e -> Error e
    let set_extra_http_headers ~headers (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["headers", ((fun l -> `List (List.map (NameValue.to_yojson) (Array.to_list l)))) headers];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"setExtraHTTPHeaders" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e

    type patterns_t = {
        glob : string option [@key "glob"] [@default None];
        regex_source : string option [@key "regexSource"] [@default None];
        regex_flags : string option [@key "regexFlags"] [@default None];
        url_pattern : URLPattern.t option [@key "urlPattern"] [@default None];
    }

    let set_network_interception_patterns ~patterns (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["patterns", ((fun l -> `List (List.map (patterns_t_to_yojson) (Array.to_list l)))) patterns];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"setNetworkInterceptionPatterns" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let set_web_socket_interception_patterns ~patterns (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["patterns", ((fun l -> `List (List.map (patterns_t_to_yojson) (Array.to_list l)))) patterns];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"setWebSocketInterceptionPatterns" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let set_viewport_size ~viewport_size (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["viewportSize", (viewport_size_t_to_yojson) viewport_size];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"setViewportSize" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let keyboard_down ~key (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["key", (fun s -> `String s) key];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"keyboardDown" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let keyboard_up ~key (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["key", (fun s -> `String s) key];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"keyboardUp" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let keyboard_insert_text ~text (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["text", (fun s -> `String s) text];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"keyboardInsertText" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let keyboard_type ~text ?delay (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["text", (fun s -> `String s) text];
        (match delay with | Some v -> [("delay", (fun f -> `Float f) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"keyboardType" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let keyboard_press ~key ?delay (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["key", (fun s -> `String s) key];
        (match delay with | Some v -> [("delay", (fun f -> `Float f) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"keyboardPress" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let mouse_move ~x ~y ?steps (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["x", (fun f -> `Float f) x];
        ["y", (fun f -> `Float f) y];
        (match steps with | Some v -> [("steps", (fun i -> `Int i) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"mouseMove" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e

    type button_t = [
        | `Left [@name "left"]
        | `Right [@name "right"]
        | `Middle [@name "middle"]
    ] [@@deriving yojson]


    let mouse_down ?button ?click_count (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match button with | Some v -> [("button", (button_t_to_yojson) v)] | None -> []);
        (match click_count with | Some v -> [("clickCount", (fun i -> `Int i) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"mouseDown" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let mouse_up ?button ?click_count (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match button with | Some v -> [("button", (button_t_to_yojson) v)] | None -> []);
        (match click_count with | Some v -> [("clickCount", (fun i -> `Int i) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"mouseUp" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let mouse_click ~x ~y ?delay ?button ?click_count (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["x", (fun f -> `Float f) x];
        ["y", (fun f -> `Float f) y];
        (match delay with | Some v -> [("delay", (fun f -> `Float f) v)] | None -> []);
        (match button with | Some v -> [("button", (button_t_to_yojson) v)] | None -> []);
        (match click_count with | Some v -> [("clickCount", (fun i -> `Int i) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"mouseClick" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let mouse_wheel ~delta_x ~delta_y (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["deltaX", (fun f -> `Float f) delta_x];
        ["deltaY", (fun f -> `Float f) delta_y];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"mouseWheel" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let touchscreen_tap ~x ~y (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["x", (fun f -> `Float f) x];
        ["y", (fun f -> `Float f) y];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"touchscreenTap" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let clear_page_errors (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"clearPageErrors" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let page_errors ?filter (t:t) : (SerializedError.t array, string) result =
        let params = `Assoc (List.concat [
        (match filter with | Some v -> [("filter", (ConsoleMessagesFilter.to_yojson) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"pageErrors" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "errors" res with | `Null -> Error "errors is null" | v -> ((fun v -> try Ok (Array.of_list (List.map (fun item -> match (SerializedError.of_yojson) item with Ok r -> r | Error e -> failwith e) (Yojson.Safe.Util.to_list v))) with Failure e -> Error e)) v)
        | Error e -> Error e

    type margin_t = {
        top : string option [@key "top"] [@default None];
        bottom : string option [@key "bottom"] [@default None];
        left : string option [@key "left"] [@default None];
        right : string option [@key "right"] [@default None];
    }

    let pdf ?scale ?display_header_footer ?header_template ?footer_template ?print_background ?landscape ?page_ranges ?format ?width ?height ?prefer_css_page_size ?margin ?tagged ?outline (t:t) : (string, string) result =
        let params = `Assoc (List.concat [
        (match scale with | Some v -> [("scale", (fun f -> `Float f) v)] | None -> []);
        (match display_header_footer with | Some v -> [("displayHeaderFooter", (fun b -> `Bool b) v)] | None -> []);
        (match header_template with | Some v -> [("headerTemplate", (fun s -> `String s) v)] | None -> []);
        (match footer_template with | Some v -> [("footerTemplate", (fun s -> `String s) v)] | None -> []);
        (match print_background with | Some v -> [("printBackground", (fun b -> `Bool b) v)] | None -> []);
        (match landscape with | Some v -> [("landscape", (fun b -> `Bool b) v)] | None -> []);
        (match page_ranges with | Some v -> [("pageRanges", (fun s -> `String s) v)] | None -> []);
        (match format with | Some v -> [("format", (fun s -> `String s) v)] | None -> []);
        (match width with | Some v -> [("width", (fun s -> `String s) v)] | None -> []);
        (match height with | Some v -> [("height", (fun s -> `String s) v)] | None -> []);
        (match prefer_css_page_size with | Some v -> [("preferCSSPageSize", (fun b -> `Bool b) v)] | None -> []);
        (match margin with | Some v -> [("margin", (margin_t_to_yojson) v)] | None -> []);
        (match tagged with | Some v -> [("tagged", (fun b -> `Bool b) v)] | None -> []);
        (match outline with | Some v -> [("outline", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"pdf" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "pdf" res with | `Null -> Error "pdf is null" | v -> (fun v -> Ok (Base64.decode_exn (Yojson.Safe.Util.to_string v))) v)
        | Error e -> Error e
    let requests (t:t) : (Request.t array, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"requests" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "requests" res with | `Null -> Error "requests is null" | v -> ((fun v -> try Ok (Array.of_list (List.map (fun item -> match (Request.of_yojson) item with Ok r -> r | Error e -> failwith e) (Yojson.Safe.Util.to_list v))) with Failure e -> Error e)) v)
        | Error e -> Error e
    let start_js_coverage ?reset_on_navigation ?report_anonymous_scripts (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match reset_on_navigation with | Some v -> [("resetOnNavigation", (fun b -> `Bool b) v)] | None -> []);
        (match report_anonymous_scripts with | Some v -> [("reportAnonymousScripts", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"startJSCoverage" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e

    type entries_t = {
        url : string [@key "url"];
        script_id : string [@key "scriptId"];
        source : string option [@key "source"] [@default None];
        functions : functions_t array [@key "functions"];
    }

    and functions_t = {
        function_name : string [@key "functionName"];
        is_block_coverage : bool [@key "isBlockCoverage"];
        ranges : ranges_t array [@key "ranges"];
    }

    and ranges_t = {
        start_offset : int [@key "startOffset"];
        end_offset : int [@key "endOffset"];
        count : int [@key "count"];
    }

    let stop_js_coverage (t:t) : (entries_t array, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"stopJSCoverage" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "entries" res with | `Null -> Error "entries is null" | v -> ((fun v -> try Ok (Array.of_list (List.map (fun item -> match (entries_t_of_yojson) item with Ok r -> r | Error e -> failwith e) (Yojson.Safe.Util.to_list v))) with Failure e -> Error e)) v)
        | Error e -> Error e
    let start_css_coverage ?reset_on_navigation (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match reset_on_navigation with | Some v -> [("resetOnNavigation", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"startCSSCoverage" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let stop_css_coverage (t:t) : (entries_t array, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"stopCSSCoverage" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "entries" res with | `Null -> Error "entries is null" | v -> ((fun v -> try Ok (Array.of_list (List.map (fun item -> match (entries_t_of_yojson) item with Ok r -> r | Error e -> failwith e) (Yojson.Safe.Util.to_list v))) with Failure e -> Error e)) v)
        | Error e -> Error e
    let bring_to_front (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"bringToFront" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let pick_locator (t:t) : (string, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"pickLocator" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "selector" res with | `Null -> Error "selector is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_string v)) v)
        | Error e -> Error e
    let cancel_pick_locator (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"cancelPickLocator" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let hide_highlight (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"hideHighlight" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let screencast_show_overlay ~html ?duration (t:t) : (string, string) result =
        let params = `Assoc (List.concat [
        ["html", (fun s -> `String s) html];
        (match duration with | Some v -> [("duration", (fun f -> `Float f) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"screencastShowOverlay" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "id" res with | `Null -> Error "id is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_string v)) v)
        | Error e -> Error e
    let screencast_remove_overlay ~id (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["id", (fun s -> `String s) id];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"screencastRemoveOverlay" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let screencast_chapter ~title ?description ?duration (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["title", (fun s -> `String s) title];
        (match description with | Some v -> [("description", (fun s -> `String s) v)] | None -> []);
        (match duration with | Some v -> [("duration", (fun f -> `Float f) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"screencastChapter" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let screencast_set_overlay_visible ~visible (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["visible", (fun b -> `Bool b) visible];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"screencastSetOverlayVisible" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e

    type position_t = [
        | `Top_left [@name "top-left"]
        | `Top [@name "top"]
        | `Top_right [@name "top-right"]
        | `Bottom_left [@name "bottom-left"]
        | `Bottom [@name "bottom"]
        | `Bottom_right [@name "bottom-right"]
    ] [@@deriving yojson]


    let screencast_show_actions ?duration ?position ?font_size (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match duration with | Some v -> [("duration", (fun f -> `Float f) v)] | None -> []);
        (match position with | Some v -> [("position", (position_t_to_yojson) v)] | None -> []);
        (match font_size with | Some v -> [("fontSize", (fun i -> `Int i) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"screencastShowActions" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let screencast_hide_actions (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"screencastHideActions" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e

    type size_t = {
        width : int [@key "width"];
        height : int [@key "height"];
    }

    let screencast_start ?size ?quality ?send_frames ?record (t:t) : (Artifact.t option, string) result =
        let params = `Assoc (List.concat [
        (match size with | Some v -> [("size", (size_t_to_yojson) v)] | None -> []);
        (match quality with | Some v -> [("quality", (fun i -> `Int i) v)] | None -> []);
        (match send_frames with | Some v -> [("sendFrames", (fun b -> `Bool b) v)] | None -> []);
        (match record with | Some v -> [("record", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"screencastStart" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "artifact" res with | `Null -> Ok None | v -> match (Artifact.of_yojson) v with Ok r -> Ok (Some r) | Error e -> Error e)
        | Error e -> Error e
    let screencast_stop (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"screencastStop" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e

    type event_t = [
        | `Console [@name "console"]
        | `Dialog [@name "dialog"]
        | `File_chooser [@name "fileChooser"]
        | `Request [@name "request"]
        | `Response [@name "response"]
        | `Request_finished [@name "requestFinished"]
        | `Request_failed [@name "requestFailed"]
    ] [@@deriving yojson]


    let update_subscription ~event ~enabled (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["event", (event_t_to_yojson) event];
        ["enabled", (fun b -> `Bool b) enabled];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"updateSubscription" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let set_dock_tile ~image (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["image", (fun s -> `String (Base64.encode_exn s)) image];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"setDockTile" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
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
end = struct
    type t = {
        url : string [@key "url"];
        name : string [@key "name"];
        parent_frame : Frame.t option [@key "parentFrame"] [@default None];
        load_states : LifecycleEvent.t array [@key "loadStates"];
        __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}]
    } [@@deriving yojson {strict = false}]

    let eval_on_selector ~selector ?strict ~expression ?is_function ~arg (t:t) : (SerializedValue.t, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        ["expression", (fun s -> `String s) expression];
        (match is_function with | Some v -> [("isFunction", (fun b -> `Bool b) v)] | None -> []);
        ["arg", (SerializedArgument.to_yojson) arg];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"evalOnSelector" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (SerializedValue.of_yojson) v)
        | Error e -> Error e
    let eval_on_selector_all ~selector ~expression ?is_function ~arg (t:t) : (SerializedValue.t, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        ["expression", (fun s -> `String s) expression];
        (match is_function with | Some v -> [("isFunction", (fun b -> `Bool b) v)] | None -> []);
        ["arg", (SerializedArgument.to_yojson) arg];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"evalOnSelectorAll" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (SerializedValue.of_yojson) v)
        | Error e -> Error e
    let add_script_tag ?url ?content ?type_ (t:t) : (ElementHandle.t, string) result =
        let params = `Assoc (List.concat [
        (match url with | Some v -> [("url", (fun s -> `String s) v)] | None -> []);
        (match content with | Some v -> [("content", (fun s -> `String s) v)] | None -> []);
        (match type_ with | Some v -> [("type", (fun s -> `String s) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"addScriptTag" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "element" res with | `Null -> Error "element is null" | v -> (ElementHandle.of_yojson) v)
        | Error e -> Error e
    let add_style_tag ?url ?content (t:t) : (ElementHandle.t, string) result =
        let params = `Assoc (List.concat [
        (match url with | Some v -> [("url", (fun s -> `String s) v)] | None -> []);
        (match content with | Some v -> [("content", (fun s -> `String s) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"addStyleTag" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "element" res with | `Null -> Error "element is null" | v -> (ElementHandle.of_yojson) v)
        | Error e -> Error e
    let aria_ref ~selector ~timeout (t:t) : (string option, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"ariaRef" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "ref" res with | `Null -> Ok None | v -> match (fun v -> Ok (Yojson.Safe.Util.to_string v)) v with Ok r -> Ok (Some r) | Error e -> Error e)
        | Error e -> Error e

    type mode_t = [
        | `Ai [@name "ai"]
        | `Default [@name "default"]
    ] [@@deriving yojson]


    let aria_snapshot ?mode ?track ?selector ?depth ?boxes ~timeout (t:t) : (string, string) result =
        let params = `Assoc (List.concat [
        (match mode with | Some v -> [("mode", (mode_t_to_yojson) v)] | None -> []);
        (match track with | Some v -> [("track", (fun s -> `String s) v)] | None -> []);
        (match selector with | Some v -> [("selector", (fun s -> `String s) v)] | None -> []);
        (match depth with | Some v -> [("depth", (fun i -> `Int i) v)] | None -> []);
        (match boxes with | Some v -> [("boxes", (fun b -> `Bool b) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"ariaSnapshot" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "snapshot" res with | `Null -> Error "snapshot is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_string v)) v)
        | Error e -> Error e
    let blur ~selector ?strict ~timeout (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"blur" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let check ~selector ?strict ?force ?position ~timeout ?trial (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        (match force with | Some v -> [("force", (fun b -> `Bool b) v)] | None -> []);
        (match position with | Some v -> [("position", (Point.to_yojson) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
        (match trial with | Some v -> [("trial", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"check" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e

    type button_t = [
        | `Left [@name "left"]
        | `Right [@name "right"]
        | `Middle [@name "middle"]
    ] [@@deriving yojson]


    and modifiers_t = [
        | `Alt [@name "Alt"]
        | `Control [@name "Control"]
        | `Control_or_meta [@name "ControlOrMeta"]
        | `Meta [@name "Meta"]
        | `Shift [@name "Shift"]
    ] [@@deriving yojson]


    let click ~selector ?strict ?force ?no_wait_after ?modifiers ?position ?delay ?button ?click_count ~timeout ?trial ?steps (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        (match force with | Some v -> [("force", (fun b -> `Bool b) v)] | None -> []);
        (match no_wait_after with | Some v -> [("noWaitAfter", (fun b -> `Bool b) v)] | None -> []);
        (match modifiers with | Some v -> [("modifiers", ((fun l -> `List (List.map (modifiers_t_to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match position with | Some v -> [("position", (Point.to_yojson) v)] | None -> []);
        (match delay with | Some v -> [("delay", (fun f -> `Float f) v)] | None -> []);
        (match button with | Some v -> [("button", (button_t_to_yojson) v)] | None -> []);
        (match click_count with | Some v -> [("clickCount", (fun i -> `Int i) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
        (match trial with | Some v -> [("trial", (fun b -> `Bool b) v)] | None -> []);
        (match steps with | Some v -> [("steps", (fun i -> `Int i) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"click" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let content (t:t) : (string, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"content" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_string v)) v)
        | Error e -> Error e
    let drag_and_drop ~source ~target ?force ~timeout ?trial ?source_position ?target_position ?strict ?steps (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["source", (fun s -> `String s) source];
        ["target", (fun s -> `String s) target];
        (match force with | Some v -> [("force", (fun b -> `Bool b) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
        (match trial with | Some v -> [("trial", (fun b -> `Bool b) v)] | None -> []);
        (match source_position with | Some v -> [("sourcePosition", (Point.to_yojson) v)] | None -> []);
        (match target_position with | Some v -> [("targetPosition", (Point.to_yojson) v)] | None -> []);
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        (match steps with | Some v -> [("steps", (fun i -> `Int i) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"dragAndDrop" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e

    type data_t = {
        mime_type : string [@key "mimeType"];
        value : string [@key "value"];
    }

    and payloads_t = {
        name : string [@key "name"];
        mime_type : string option [@key "mimeType"] [@default None];
        buffer : string [@key "buffer"];
    }

    let drop ~selector ?strict ?position ?payloads ?local_paths ?streams ?data ~timeout (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        (match position with | Some v -> [("position", (Point.to_yojson) v)] | None -> []);
        (match payloads with | Some v -> [("payloads", ((fun l -> `List (List.map (payloads_t_to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match local_paths with | Some v -> [("localPaths", ((fun l -> `List (List.map (fun s -> `String s) (Array.to_list l)))) v)] | None -> []);
        (match streams with | Some v -> [("streams", ((fun l -> `List (List.map (WritableStream.to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match data with | Some v -> [("data", ((fun l -> `List (List.map (data_t_to_yojson) (Array.to_list l)))) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"drop" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let dblclick ~selector ?strict ?force ?modifiers ?position ?delay ?button ~timeout ?trial ?steps (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        (match force with | Some v -> [("force", (fun b -> `Bool b) v)] | None -> []);
        (match modifiers with | Some v -> [("modifiers", ((fun l -> `List (List.map (modifiers_t_to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match position with | Some v -> [("position", (Point.to_yojson) v)] | None -> []);
        (match delay with | Some v -> [("delay", (fun f -> `Float f) v)] | None -> []);
        (match button with | Some v -> [("button", (button_t_to_yojson) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
        (match trial with | Some v -> [("trial", (fun b -> `Bool b) v)] | None -> []);
        (match steps with | Some v -> [("steps", (fun i -> `Int i) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"dblclick" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let dispatch_event ~selector ?strict ~type_ ~event_init ~timeout (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        ["type", (fun s -> `String s) type_];
        ["eventInit", (SerializedArgument.to_yojson) event_init];
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"dispatchEvent" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let evaluate_expression ~expression ?is_function ~arg (t:t) : (SerializedValue.t, string) result =
        let params = `Assoc (List.concat [
        ["expression", (fun s -> `String s) expression];
        (match is_function with | Some v -> [("isFunction", (fun b -> `Bool b) v)] | None -> []);
        ["arg", (SerializedArgument.to_yojson) arg];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"evaluateExpression" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (SerializedValue.of_yojson) v)
        | Error e -> Error e
    let evaluate_expression_handle ~expression ?is_function ~arg (t:t) : (JSHandle.t, string) result =
        let params = `Assoc (List.concat [
        ["expression", (fun s -> `String s) expression];
        (match is_function with | Some v -> [("isFunction", (fun b -> `Bool b) v)] | None -> []);
        ["arg", (SerializedArgument.to_yojson) arg];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"evaluateExpressionHandle" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "handle" res with | `Null -> Error "handle is null" | v -> (JSHandle.of_yojson) v)
        | Error e -> Error e
    let fill ~selector ?strict ~value ?force ~timeout (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        ["value", (fun s -> `String s) value];
        (match force with | Some v -> [("force", (fun b -> `Bool b) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"fill" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let focus ~selector ?strict ~timeout (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"focus" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let frame_element (t:t) : (ElementHandle.t, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"frameElement" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "element" res with | `Null -> Error "element is null" | v -> (ElementHandle.of_yojson) v)
        | Error e -> Error e
    let resolve_selector ~selector (t:t) : (string, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"resolveSelector" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "resolvedSelector" res with | `Null -> Error "resolvedSelector is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_string v)) v)
        | Error e -> Error e
    let highlight ~selector ?style (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match style with | Some v -> [("style", (fun s -> `String s) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"highlight" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let hide_highlight ~selector (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"hideHighlight" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let get_attribute ~selector ?strict ~name ~timeout (t:t) : (string option, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        ["name", (fun s -> `String s) name];
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"getAttribute" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Ok None | v -> match (fun v -> Ok (Yojson.Safe.Util.to_string v)) v with Ok r -> Ok (Some r) | Error e -> Error e)
        | Error e -> Error e
    let goto ~url ~timeout ?wait_until ?referer (t:t) : (Response.t option, string) result =
        let params = `Assoc (List.concat [
        ["url", (fun s -> `String s) url];
        ["timeout", (fun f -> `Float f) timeout];
        (match wait_until with | Some v -> [("waitUntil", (LifecycleEvent.to_yojson) v)] | None -> []);
        (match referer with | Some v -> [("referer", (fun s -> `String s) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"goto" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "response" res with | `Null -> Ok None | v -> match (Response.of_yojson) v with Ok r -> Ok (Some r) | Error e -> Error e)
        | Error e -> Error e
    let hover ~selector ?strict ?force ?modifiers ?position ~timeout ?trial (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        (match force with | Some v -> [("force", (fun b -> `Bool b) v)] | None -> []);
        (match modifiers with | Some v -> [("modifiers", ((fun l -> `List (List.map (modifiers_t_to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match position with | Some v -> [("position", (Point.to_yojson) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
        (match trial with | Some v -> [("trial", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"hover" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let inner_html ~selector ?strict ~timeout (t:t) : (string, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"innerHTML" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_string v)) v)
        | Error e -> Error e
    let inner_text ~selector ?strict ~timeout (t:t) : (string, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"innerText" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_string v)) v)
        | Error e -> Error e
    let input_value ~selector ?strict ~timeout (t:t) : (string, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"inputValue" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_string v)) v)
        | Error e -> Error e
    let is_checked ~selector ?strict ~timeout (t:t) : (bool, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"isChecked" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_bool v)) v)
        | Error e -> Error e
    let is_disabled ~selector ?strict ~timeout (t:t) : (bool, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"isDisabled" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_bool v)) v)
        | Error e -> Error e
    let is_enabled ~selector ?strict ~timeout (t:t) : (bool, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"isEnabled" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_bool v)) v)
        | Error e -> Error e
    let is_hidden ~selector ?strict (t:t) : (bool, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"isHidden" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_bool v)) v)
        | Error e -> Error e
    let is_visible ~selector ?strict (t:t) : (bool, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"isVisible" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_bool v)) v)
        | Error e -> Error e
    let is_editable ~selector ?strict ~timeout (t:t) : (bool, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"isEditable" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_bool v)) v)
        | Error e -> Error e
    let press ~selector ?strict ~key ?delay ?no_wait_after ~timeout (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        ["key", (fun s -> `String s) key];
        (match delay with | Some v -> [("delay", (fun f -> `Float f) v)] | None -> []);
        (match no_wait_after with | Some v -> [("noWaitAfter", (fun b -> `Bool b) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"press" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let query_selector ~selector ?strict (t:t) : (ElementHandle.t option, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"querySelector" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "element" res with | `Null -> Ok None | v -> match (ElementHandle.of_yojson) v with Ok r -> Ok (Some r) | Error e -> Error e)
        | Error e -> Error e
    let query_selector_all ~selector (t:t) : (ElementHandle.t array, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"querySelectorAll" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "elements" res with | `Null -> Error "elements is null" | v -> ((fun v -> try Ok (Array.of_list (List.map (fun item -> match (ElementHandle.of_yojson) item with Ok r -> r | Error e -> failwith e) (Yojson.Safe.Util.to_list v))) with Failure e -> Error e)) v)
        | Error e -> Error e
    let query_count ~selector (t:t) : (int, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"queryCount" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_int v)) v)
        | Error e -> Error e

    type options_t = {
        value_or_label : string option [@key "valueOrLabel"] [@default None];
        value : string option [@key "value"] [@default None];
        label : string option [@key "label"] [@default None];
        index : int option [@key "index"] [@default None];
    }

    let select_option ~selector ?strict ?elements ?options ?force ~timeout (t:t) : (string array, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        (match elements with | Some v -> [("elements", ((fun l -> `List (List.map (ElementHandle.to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match options with | Some v -> [("options", ((fun l -> `List (List.map (options_t_to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match force with | Some v -> [("force", (fun b -> `Bool b) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"selectOption" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "values" res with | `Null -> Error "values is null" | v -> ((fun v -> try Ok (Array.of_list (List.map (fun item -> match (fun v -> Ok (Yojson.Safe.Util.to_string v)) item with Ok r -> r | Error e -> failwith e) (Yojson.Safe.Util.to_list v))) with Failure e -> Error e)) v)
        | Error e -> Error e
    let set_content ~html ~timeout ?wait_until (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["html", (fun s -> `String s) html];
        ["timeout", (fun f -> `Float f) timeout];
        (match wait_until with | Some v -> [("waitUntil", (LifecycleEvent.to_yojson) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"setContent" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let set_input_files ~selector ?strict ?payloads ?local_directory ?directory_stream ?local_paths ?streams ~timeout (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        (match payloads with | Some v -> [("payloads", ((fun l -> `List (List.map (payloads_t_to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match local_directory with | Some v -> [("localDirectory", (fun s -> `String s) v)] | None -> []);
        (match directory_stream with | Some v -> [("directoryStream", (WritableStream.to_yojson) v)] | None -> []);
        (match local_paths with | Some v -> [("localPaths", ((fun l -> `List (List.map (fun s -> `String s) (Array.to_list l)))) v)] | None -> []);
        (match streams with | Some v -> [("streams", ((fun l -> `List (List.map (WritableStream.to_yojson) (Array.to_list l)))) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"setInputFiles" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let tap ~selector ?strict ?force ?modifiers ?position ~timeout ?trial (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        (match force with | Some v -> [("force", (fun b -> `Bool b) v)] | None -> []);
        (match modifiers with | Some v -> [("modifiers", ((fun l -> `List (List.map (modifiers_t_to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match position with | Some v -> [("position", (Point.to_yojson) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
        (match trial with | Some v -> [("trial", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"tap" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let text_content ~selector ?strict ~timeout (t:t) : (string option, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"textContent" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Ok None | v -> match (fun v -> Ok (Yojson.Safe.Util.to_string v)) v with Ok r -> Ok (Some r) | Error e -> Error e)
        | Error e -> Error e
    let title (t:t) : (string, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"title" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_string v)) v)
        | Error e -> Error e
    let type_ ~selector ?strict ~text ?delay ~timeout (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        ["text", (fun s -> `String s) text];
        (match delay with | Some v -> [("delay", (fun f -> `Float f) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"type" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let uncheck ~selector ?strict ?force ?position ~timeout ?trial (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        (match force with | Some v -> [("force", (fun b -> `Bool b) v)] | None -> []);
        (match position with | Some v -> [("position", (Point.to_yojson) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
        (match trial with | Some v -> [("trial", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"uncheck" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let wait_for_timeout ~wait_timeout (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["waitTimeout", (fun f -> `Float f) wait_timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"waitForTimeout" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let wait_for_function ~expression ?is_function ~arg ~timeout ?polling_interval (t:t) : (JSHandle.t, string) result =
        let params = `Assoc (List.concat [
        ["expression", (fun s -> `String s) expression];
        (match is_function with | Some v -> [("isFunction", (fun b -> `Bool b) v)] | None -> []);
        ["arg", (SerializedArgument.to_yojson) arg];
        ["timeout", (fun f -> `Float f) timeout];
        (match polling_interval with | Some v -> [("pollingInterval", (fun f -> `Float f) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"waitForFunction" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "handle" res with | `Null -> Error "handle is null" | v -> (JSHandle.of_yojson) v)
        | Error e -> Error e

    type state_t = [
        | `Attached [@name "attached"]
        | `Detached [@name "detached"]
        | `Visible [@name "visible"]
        | `Hidden [@name "hidden"]
    ] [@@deriving yojson]


    let wait_for_selector ~selector ?strict ~timeout ?state ?omit_return_value (t:t) : (ElementHandle.t option, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
        (match state with | Some v -> [("state", (state_t_to_yojson) v)] | None -> []);
        (match omit_return_value with | Some v -> [("omitReturnValue", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"waitForSelector" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "element" res with | `Null -> Ok None | v -> match (ElementHandle.of_yojson) v with Ok r -> Ok (Some r) | Error e -> Error e)
        | Error e -> Error e

    type expect_res_t = {
        matches : bool [@key "matches"];
        received : received_t option [@key "received"] [@default None];
        timed_out : bool option [@key "timedOut"] [@default None];
        error_message : string option [@key "errorMessage"] [@default None];
        log : string array option [@key "log"] [@default None];
    } [@@deriving yojson {strict = false}]

    and received_t = {
        value : SerializedValue.t option [@key "value"] [@default None];
        aria_snapshot : string option [@key "ariaSnapshot"] [@default None];
    }

    and pseudo_t = [
        | `Before [@name "before"]
        | `After [@name "after"]
    ] [@@deriving yojson]


    let expect ?selector ~expression ?expression_arg ?pseudo ?expected_text ?expected_number ?expected_value ?use_inner_text ~is_not ~timeout (t:t) : (expect_res_t, string) result =
        let params = `Assoc (List.concat [
        (match selector with | Some v -> [("selector", (fun s -> `String s) v)] | None -> []);
        ["expression", (fun s -> `String s) expression];
        (match expression_arg with | Some v -> [("expressionArg", (json_to_yojson) v)] | None -> []);
        (match pseudo with | Some v -> [("pseudo", (pseudo_t_to_yojson) v)] | None -> []);
        (match expected_text with | Some v -> [("expectedText", ((fun l -> `List (List.map (ExpectedTextValue.to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match expected_number with | Some v -> [("expectedNumber", (fun f -> `Float f) v)] | None -> []);
        (match expected_value with | Some v -> [("expectedValue", (SerializedArgument.to_yojson) v)] | None -> []);
        (match use_inner_text with | Some v -> [("useInnerText", (fun b -> `Bool b) v)] | None -> []);
        ["isNot", (fun b -> `Bool b) is_not];
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"expect" ~params with
        | Ok res -> expect_res_t_of_yojson res
        | Error e -> Error e
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
end = struct
    type t = {
        url : string [@key "url"];
        __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}]
    } [@@deriving yojson {strict = false}]


    type info_t = {
        wait_id : string [@key "waitId"];
        phase : phase_t [@key "phase"];
        event : string option [@key "event"] [@default None];
        message : string option [@key "message"] [@default None];
        error : string option [@key "error"] [@default None];
    }

    and phase_t = [
        | `Before [@name "before"]
        | `After [@name "after"]
        | `Log [@name "log"]
    ] [@@deriving yojson]


    let wait_for_event_info ~info (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["info", (info_t_to_yojson) info];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"waitForEventInfo" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let disconnect ?reason (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match reason with | Some v -> [("reason", (fun s -> `String s) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"disconnect" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let evaluate_expression ~expression ?is_function ~arg (t:t) : (SerializedValue.t, string) result =
        let params = `Assoc (List.concat [
        ["expression", (fun s -> `String s) expression];
        (match is_function with | Some v -> [("isFunction", (fun b -> `Bool b) v)] | None -> []);
        ["arg", (SerializedArgument.to_yojson) arg];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"evaluateExpression" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (SerializedValue.of_yojson) v)
        | Error e -> Error e
    let evaluate_expression_handle ~expression ?is_function ~arg (t:t) : (JSHandle.t, string) result =
        let params = `Assoc (List.concat [
        ["expression", (fun s -> `String s) expression];
        (match is_function with | Some v -> [("isFunction", (fun b -> `Bool b) v)] | None -> []);
        ["arg", (SerializedArgument.to_yojson) arg];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"evaluateExpressionHandle" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "handle" res with | `Null -> Error "handle is null" | v -> (JSHandle.of_yojson) v)
        | Error e -> Error e

    type event_t = [
        | `Console [@name "console"]
    ] [@@deriving yojson]


    let update_subscription ~event ~enabled (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["event", (event_t_to_yojson) event];
        ["enabled", (fun b -> `Bool b) enabled];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"updateSubscription" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
end
and Disposable : sig
    type t [@@deriving yojson]

    val dispose : t -> unit
end = struct
    type t = { __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}] } [@@deriving yojson {strict = false}]

    let dispose (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"dispose" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
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
end = struct
    type t = {
        preview : string [@key "preview"];
        __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}]
    } [@@deriving yojson {strict = false}]

    let dispose (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"dispose" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let evaluate_expression ~expression ?is_function ~arg (t:t) : (SerializedValue.t, string) result =
        let params = `Assoc (List.concat [
        ["expression", (fun s -> `String s) expression];
        (match is_function with | Some v -> [("isFunction", (fun b -> `Bool b) v)] | None -> []);
        ["arg", (SerializedArgument.to_yojson) arg];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"evaluateExpression" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (SerializedValue.of_yojson) v)
        | Error e -> Error e
    let evaluate_expression_handle ~expression ?is_function ~arg (t:t) : (JSHandle.t, string) result =
        let params = `Assoc (List.concat [
        ["expression", (fun s -> `String s) expression];
        (match is_function with | Some v -> [("isFunction", (fun b -> `Bool b) v)] | None -> []);
        ["arg", (SerializedArgument.to_yojson) arg];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"evaluateExpressionHandle" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "handle" res with | `Null -> Error "handle is null" | v -> (JSHandle.of_yojson) v)
        | Error e -> Error e

    type properties_t = {
        name : string [@key "name"];
        value : JSHandle.t [@key "value"];
    }

    let get_property_list (t:t) : (properties_t array, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"getPropertyList" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "properties" res with | `Null -> Error "properties is null" | v -> ((fun v -> try Ok (Array.of_list (List.map (fun item -> match (properties_t_of_yojson) item with Ok r -> r | Error e -> failwith e) (Yojson.Safe.Util.to_list v))) with Failure e -> Error e)) v)
        | Error e -> Error e
    let get_property ~name (t:t) : (JSHandle.t, string) result =
        let params = `Assoc (List.concat [
        ["name", (fun s -> `String s) name];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"getProperty" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "handle" res with | `Null -> Error "handle is null" | v -> (JSHandle.of_yojson) v)
        | Error e -> Error e
    let json_value (t:t) : (SerializedValue.t, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"jsonValue" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (SerializedValue.of_yojson) v)
        | Error e -> Error e
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
end = struct
    type t = { __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}] } [@@deriving yojson {strict = false}]

    let dispose (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"dispose" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let evaluate_expression ~expression ?is_function ~arg (t:t) : (SerializedValue.t, string) result =
        let params = `Assoc (List.concat [
        ["expression", (fun s -> `String s) expression];
        (match is_function with | Some v -> [("isFunction", (fun b -> `Bool b) v)] | None -> []);
        ["arg", (SerializedArgument.to_yojson) arg];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"evaluateExpression" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (SerializedValue.of_yojson) v)
        | Error e -> Error e
    let evaluate_expression_handle ~expression ?is_function ~arg (t:t) : (JSHandle.t, string) result =
        let params = `Assoc (List.concat [
        ["expression", (fun s -> `String s) expression];
        (match is_function with | Some v -> [("isFunction", (fun b -> `Bool b) v)] | None -> []);
        ["arg", (SerializedArgument.to_yojson) arg];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"evaluateExpressionHandle" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "handle" res with | `Null -> Error "handle is null" | v -> (JSHandle.of_yojson) v)
        | Error e -> Error e

    type properties_t = {
        name : string [@key "name"];
        value : JSHandle.t [@key "value"];
    }

    let get_property_list (t:t) : (properties_t array, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"getPropertyList" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "properties" res with | `Null -> Error "properties is null" | v -> ((fun v -> try Ok (Array.of_list (List.map (fun item -> match (properties_t_of_yojson) item with Ok r -> r | Error e -> failwith e) (Yojson.Safe.Util.to_list v))) with Failure e -> Error e)) v)
        | Error e -> Error e
    let get_property ~name (t:t) : (JSHandle.t, string) result =
        let params = `Assoc (List.concat [
        ["name", (fun s -> `String s) name];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"getProperty" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "handle" res with | `Null -> Error "handle is null" | v -> (JSHandle.of_yojson) v)
        | Error e -> Error e
    let json_value (t:t) : (SerializedValue.t, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"jsonValue" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (SerializedValue.of_yojson) v)
        | Error e -> Error e
    let eval_on_selector ~selector ?strict ~expression ?is_function ~arg (t:t) : (SerializedValue.t, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        ["expression", (fun s -> `String s) expression];
        (match is_function with | Some v -> [("isFunction", (fun b -> `Bool b) v)] | None -> []);
        ["arg", (SerializedArgument.to_yojson) arg];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"evalOnSelector" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (SerializedValue.of_yojson) v)
        | Error e -> Error e
    let eval_on_selector_all ~selector ~expression ?is_function ~arg (t:t) : (SerializedValue.t, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        ["expression", (fun s -> `String s) expression];
        (match is_function with | Some v -> [("isFunction", (fun b -> `Bool b) v)] | None -> []);
        ["arg", (SerializedArgument.to_yojson) arg];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"evalOnSelectorAll" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (SerializedValue.of_yojson) v)
        | Error e -> Error e
    let bounding_box (t:t) : (Rect.t option, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"boundingBox" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Ok None | v -> match (Rect.of_yojson) v with Ok r -> Ok (Some r) | Error e -> Error e)
        | Error e -> Error e
    let check ?force ?position ~timeout ?trial (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match force with | Some v -> [("force", (fun b -> `Bool b) v)] | None -> []);
        (match position with | Some v -> [("position", (Point.to_yojson) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
        (match trial with | Some v -> [("trial", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"check" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e

    type button_t = [
        | `Left [@name "left"]
        | `Right [@name "right"]
        | `Middle [@name "middle"]
    ] [@@deriving yojson]


    and modifiers_t = [
        | `Alt [@name "Alt"]
        | `Control [@name "Control"]
        | `Control_or_meta [@name "ControlOrMeta"]
        | `Meta [@name "Meta"]
        | `Shift [@name "Shift"]
    ] [@@deriving yojson]


    let click ?force ?no_wait_after ?modifiers ?position ?delay ?button ?click_count ~timeout ?trial ?steps (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match force with | Some v -> [("force", (fun b -> `Bool b) v)] | None -> []);
        (match no_wait_after with | Some v -> [("noWaitAfter", (fun b -> `Bool b) v)] | None -> []);
        (match modifiers with | Some v -> [("modifiers", ((fun l -> `List (List.map (modifiers_t_to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match position with | Some v -> [("position", (Point.to_yojson) v)] | None -> []);
        (match delay with | Some v -> [("delay", (fun f -> `Float f) v)] | None -> []);
        (match button with | Some v -> [("button", (button_t_to_yojson) v)] | None -> []);
        (match click_count with | Some v -> [("clickCount", (fun i -> `Int i) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
        (match trial with | Some v -> [("trial", (fun b -> `Bool b) v)] | None -> []);
        (match steps with | Some v -> [("steps", (fun i -> `Int i) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"click" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let content_frame (t:t) : (Frame.t option, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"contentFrame" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "frame" res with | `Null -> Ok None | v -> match (Frame.of_yojson) v with Ok r -> Ok (Some r) | Error e -> Error e)
        | Error e -> Error e
    let dblclick ?force ?modifiers ?position ?delay ?button ~timeout ?trial ?steps (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match force with | Some v -> [("force", (fun b -> `Bool b) v)] | None -> []);
        (match modifiers with | Some v -> [("modifiers", ((fun l -> `List (List.map (modifiers_t_to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match position with | Some v -> [("position", (Point.to_yojson) v)] | None -> []);
        (match delay with | Some v -> [("delay", (fun f -> `Float f) v)] | None -> []);
        (match button with | Some v -> [("button", (button_t_to_yojson) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
        (match trial with | Some v -> [("trial", (fun b -> `Bool b) v)] | None -> []);
        (match steps with | Some v -> [("steps", (fun i -> `Int i) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"dblclick" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let dispatch_event ~type_ ~event_init (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["type", (fun s -> `String s) type_];
        ["eventInit", (SerializedArgument.to_yojson) event_init];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"dispatchEvent" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let fill ~value ?force ~timeout (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["value", (fun s -> `String s) value];
        (match force with | Some v -> [("force", (fun b -> `Bool b) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"fill" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let focus (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"focus" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let get_attribute ~name (t:t) : (string option, string) result =
        let params = `Assoc (List.concat [
        ["name", (fun s -> `String s) name];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"getAttribute" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Ok None | v -> match (fun v -> Ok (Yojson.Safe.Util.to_string v)) v with Ok r -> Ok (Some r) | Error e -> Error e)
        | Error e -> Error e
    let hover ?force ?modifiers ?position ~timeout ?trial (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match force with | Some v -> [("force", (fun b -> `Bool b) v)] | None -> []);
        (match modifiers with | Some v -> [("modifiers", ((fun l -> `List (List.map (modifiers_t_to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match position with | Some v -> [("position", (Point.to_yojson) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
        (match trial with | Some v -> [("trial", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"hover" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let inner_html (t:t) : (string, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"innerHTML" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_string v)) v)
        | Error e -> Error e
    let inner_text (t:t) : (string, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"innerText" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_string v)) v)
        | Error e -> Error e
    let input_value (t:t) : (string, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"inputValue" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_string v)) v)
        | Error e -> Error e
    let is_checked (t:t) : (bool, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"isChecked" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_bool v)) v)
        | Error e -> Error e
    let is_disabled (t:t) : (bool, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"isDisabled" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_bool v)) v)
        | Error e -> Error e
    let is_editable (t:t) : (bool, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"isEditable" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_bool v)) v)
        | Error e -> Error e
    let is_enabled (t:t) : (bool, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"isEnabled" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_bool v)) v)
        | Error e -> Error e
    let is_hidden (t:t) : (bool, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"isHidden" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_bool v)) v)
        | Error e -> Error e
    let is_visible (t:t) : (bool, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"isVisible" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_bool v)) v)
        | Error e -> Error e
    let owner_frame (t:t) : (Frame.t option, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"ownerFrame" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "frame" res with | `Null -> Ok None | v -> match (Frame.of_yojson) v with Ok r -> Ok (Some r) | Error e -> Error e)
        | Error e -> Error e
    let press ~key ?delay ~timeout ?no_wait_after (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["key", (fun s -> `String s) key];
        (match delay with | Some v -> [("delay", (fun f -> `Float f) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
        (match no_wait_after with | Some v -> [("noWaitAfter", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"press" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let query_selector ~selector ?strict (t:t) : (ElementHandle.t option, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"querySelector" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "element" res with | `Null -> Ok None | v -> match (ElementHandle.of_yojson) v with Ok r -> Ok (Some r) | Error e -> Error e)
        | Error e -> Error e
    let query_selector_all ~selector (t:t) : (ElementHandle.t array, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"querySelectorAll" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "elements" res with | `Null -> Error "elements is null" | v -> ((fun v -> try Ok (Array.of_list (List.map (fun item -> match (ElementHandle.of_yojson) item with Ok r -> r | Error e -> failwith e) (Yojson.Safe.Util.to_list v))) with Failure e -> Error e)) v)
        | Error e -> Error e

    type mask_t = {
        frame : Frame.t [@key "frame"];
        selector : string [@key "selector"];
    }

    and scale_t = [
        | `Css [@name "css"]
        | `Device [@name "device"]
    ] [@@deriving yojson]


    and animations_t = [
        | `Disabled [@name "disabled"]
        | `Allow [@name "allow"]
    ] [@@deriving yojson]


    and caret_t = [
        | `Hide [@name "hide"]
        | `Initial [@name "initial"]
    ] [@@deriving yojson]


    and type__t = [
        | `Png [@name "png"]
        | `Jpeg [@name "jpeg"]
    ] [@@deriving yojson]


    let screenshot ~timeout ?type_ ?quality ?omit_background ?caret ?animations ?scale ?mask ?mask_color ?style (t:t) : (string, string) result =
        let params = `Assoc (List.concat [
        ["timeout", (fun f -> `Float f) timeout];
        (match type_ with | Some v -> [("type", (type__t_to_yojson) v)] | None -> []);
        (match quality with | Some v -> [("quality", (fun i -> `Int i) v)] | None -> []);
        (match omit_background with | Some v -> [("omitBackground", (fun b -> `Bool b) v)] | None -> []);
        (match caret with | Some v -> [("caret", (caret_t_to_yojson) v)] | None -> []);
        (match animations with | Some v -> [("animations", (animations_t_to_yojson) v)] | None -> []);
        (match scale with | Some v -> [("scale", (scale_t_to_yojson) v)] | None -> []);
        (match mask with | Some v -> [("mask", ((fun l -> `List (List.map (mask_t_to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match mask_color with | Some v -> [("maskColor", (fun s -> `String s) v)] | None -> []);
        (match style with | Some v -> [("style", (fun s -> `String s) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"screenshot" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "binary" res with | `Null -> Error "binary is null" | v -> (fun v -> Ok (Base64.decode_exn (Yojson.Safe.Util.to_string v))) v)
        | Error e -> Error e
    let scroll_into_view_if_needed ~timeout (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"scrollIntoViewIfNeeded" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e

    type options_t = {
        value_or_label : string option [@key "valueOrLabel"] [@default None];
        value : string option [@key "value"] [@default None];
        label : string option [@key "label"] [@default None];
        index : int option [@key "index"] [@default None];
    }

    let select_option ?elements ?options ?force ~timeout (t:t) : (string array, string) result =
        let params = `Assoc (List.concat [
        (match elements with | Some v -> [("elements", ((fun l -> `List (List.map (ElementHandle.to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match options with | Some v -> [("options", ((fun l -> `List (List.map (options_t_to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match force with | Some v -> [("force", (fun b -> `Bool b) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"selectOption" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "values" res with | `Null -> Error "values is null" | v -> ((fun v -> try Ok (Array.of_list (List.map (fun item -> match (fun v -> Ok (Yojson.Safe.Util.to_string v)) item with Ok r -> r | Error e -> failwith e) (Yojson.Safe.Util.to_list v))) with Failure e -> Error e)) v)
        | Error e -> Error e
    let select_text ?force ~timeout (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match force with | Some v -> [("force", (fun b -> `Bool b) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"selectText" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e

    type payloads_t = {
        name : string [@key "name"];
        mime_type : string option [@key "mimeType"] [@default None];
        buffer : string [@key "buffer"];
    }

    let set_input_files ?payloads ?local_directory ?directory_stream ?local_paths ?streams ~timeout (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match payloads with | Some v -> [("payloads", ((fun l -> `List (List.map (payloads_t_to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match local_directory with | Some v -> [("localDirectory", (fun s -> `String s) v)] | None -> []);
        (match directory_stream with | Some v -> [("directoryStream", (WritableStream.to_yojson) v)] | None -> []);
        (match local_paths with | Some v -> [("localPaths", ((fun l -> `List (List.map (fun s -> `String s) (Array.to_list l)))) v)] | None -> []);
        (match streams with | Some v -> [("streams", ((fun l -> `List (List.map (WritableStream.to_yojson) (Array.to_list l)))) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"setInputFiles" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let tap ?force ?modifiers ?position ~timeout ?trial (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match force with | Some v -> [("force", (fun b -> `Bool b) v)] | None -> []);
        (match modifiers with | Some v -> [("modifiers", ((fun l -> `List (List.map (modifiers_t_to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match position with | Some v -> [("position", (Point.to_yojson) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
        (match trial with | Some v -> [("trial", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"tap" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let text_content (t:t) : (string option, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"textContent" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Ok None | v -> match (fun v -> Ok (Yojson.Safe.Util.to_string v)) v with Ok r -> Ok (Some r) | Error e -> Error e)
        | Error e -> Error e
    let type_ ~text ?delay ~timeout (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["text", (fun s -> `String s) text];
        (match delay with | Some v -> [("delay", (fun f -> `Float f) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"type" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let uncheck ?force ?position ~timeout ?trial (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match force with | Some v -> [("force", (fun b -> `Bool b) v)] | None -> []);
        (match position with | Some v -> [("position", (Point.to_yojson) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
        (match trial with | Some v -> [("trial", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"uncheck" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e

    type state_t = [
        | `Visible [@name "visible"]
        | `Hidden [@name "hidden"]
        | `Stable [@name "stable"]
        | `Enabled [@name "enabled"]
        | `Disabled [@name "disabled"]
        | `Editable [@name "editable"]
    ] [@@deriving yojson]


    let wait_for_element_state ~state ~timeout (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["state", (state_t_to_yojson) state];
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"waitForElementState" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let wait_for_selector ~selector ?strict ~timeout ?state (t:t) : (ElementHandle.t option, string) result =
        let params = `Assoc (List.concat [
        ["selector", (fun s -> `String s) selector];
        (match strict with | Some v -> [("strict", (fun b -> `Bool b) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
        (match state with | Some v -> [("state", (state_t_to_yojson) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"waitForSelector" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "element" res with | `Null -> Ok None | v -> match (ElementHandle.of_yojson) v with Ok r -> Ok (Some r) | Error e -> Error e)
        | Error e -> Error e
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
end = struct
    type t = {
        frame : Frame.t option [@key "frame"] [@default None];
        service_worker : Worker.t option [@key "serviceWorker"] [@default None];
        url : string [@key "url"];
        resource_type : string [@key "resourceType"];
        method_ : string [@key "method"];
        post_data : string option [@key "postData"] [@default None];
        headers : NameValue.t array [@key "headers"];
        is_navigation_request : bool [@key "isNavigationRequest"];
        redirected_from : Request.t option [@key "redirectedFrom"] [@default None];
        __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}]
    } [@@deriving yojson {strict = false}]

    let response (t:t) : (Response.t option, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"response" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "response" res with | `Null -> Ok None | v -> match (Response.of_yojson) v with Ok r -> Ok (Some r) | Error e -> Error e)
        | Error e -> Error e
    let raw_request_headers (t:t) : (NameValue.t array, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"rawRequestHeaders" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "headers" res with | `Null -> Error "headers is null" | v -> ((fun v -> try Ok (Array.of_list (List.map (fun item -> match (NameValue.of_yojson) item with Ok r -> r | Error e -> failwith e) (Yojson.Safe.Util.to_list v))) with Failure e -> Error e)) v)
        | Error e -> Error e
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
end = struct
    type t = {
        request : Request.t [@key "request"];
        __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}]
    } [@@deriving yojson {strict = false}]

    let redirect_navigation_request ~url (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["url", (fun s -> `String s) url];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"redirectNavigationRequest" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let abort ?error_code (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match error_code with | Some v -> [("errorCode", (fun s -> `String s) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"abort" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let continue ?url ?method_ ?headers ?post_data ~is_fallback (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match url with | Some v -> [("url", (fun s -> `String s) v)] | None -> []);
        (match method_ with | Some v -> [("method", (fun s -> `String s) v)] | None -> []);
        (match headers with | Some v -> [("headers", ((fun l -> `List (List.map (NameValue.to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match post_data with | Some v -> [("postData", (fun s -> `String (Base64.encode_exn s)) v)] | None -> []);
        ["isFallback", (fun b -> `Bool b) is_fallback];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"continue" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let fulfill ?status ?headers ?body ?is_base64 ?fetch_response_uid (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match status with | Some v -> [("status", (fun i -> `Int i) v)] | None -> []);
        (match headers with | Some v -> [("headers", ((fun l -> `List (List.map (NameValue.to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match body with | Some v -> [("body", (fun s -> `String s) v)] | None -> []);
        (match is_base64 with | Some v -> [("isBase64", (fun b -> `Bool b) v)] | None -> []);
        (match fetch_response_uid with | Some v -> [("fetchResponseUid", (fun s -> `String s) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"fulfill" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
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
end = struct
    type t = {
        url : string [@key "url"];
        protocols : string array [@key "protocols"];
        __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}]
    } [@@deriving yojson {strict = false}]

    let connect (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"connect" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let ensure_opened (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"ensureOpened" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let send_to_page ~message ~is_base64 (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["message", (fun s -> `String s) message];
        ["isBase64", (fun b -> `Bool b) is_base64];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"sendToPage" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let send_to_server ~message ~is_base64 (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["message", (fun s -> `String s) message];
        ["isBase64", (fun b -> `Bool b) is_base64];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"sendToServer" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let close_page ?code ?reason ~was_clean (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match code with | Some v -> [("code", (fun i -> `Int i) v)] | None -> []);
        (match reason with | Some v -> [("reason", (fun s -> `String s) v)] | None -> []);
        ["wasClean", (fun b -> `Bool b) was_clean];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"closePage" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let close_server ?code ?reason ~was_clean (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match code with | Some v -> [("code", (fun i -> `Int i) v)] | None -> []);
        (match reason with | Some v -> [("reason", (fun s -> `String s) v)] | None -> []);
        ["wasClean", (fun b -> `Bool b) was_clean];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"closeServer" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
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
end = struct
    type t = {
        request : Request.t [@key "request"];
        url : string [@key "url"];
        status : int [@key "status"];
        status_text : string [@key "statusText"];
        headers : NameValue.t array [@key "headers"];
        timing : ResourceTiming.t [@key "timing"];
        from_service_worker : bool [@key "fromServiceWorker"];
        __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}]
    } [@@deriving yojson {strict = false}]

    let body (t:t) : (string, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"body" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "binary" res with | `Null -> Error "binary is null" | v -> (fun v -> Ok (Base64.decode_exn (Yojson.Safe.Util.to_string v))) v)
        | Error e -> Error e
    let security_details (t:t) : (SecurityDetails.t option, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"securityDetails" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Ok None | v -> match (SecurityDetails.of_yojson) v with Ok r -> Ok (Some r) | Error e -> Error e)
        | Error e -> Error e
    let server_addr (t:t) : (RemoteAddr.t option, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"serverAddr" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Ok None | v -> match (RemoteAddr.of_yojson) v with Ok r -> Ok (Some r) | Error e -> Error e)
        | Error e -> Error e
    let raw_response_headers (t:t) : (NameValue.t array, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"rawResponseHeaders" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "headers" res with | `Null -> Error "headers is null" | v -> ((fun v -> try Ok (Array.of_list (List.map (fun item -> match (NameValue.of_yojson) item with Ok r -> r | Error e -> failwith e) (Yojson.Safe.Util.to_list v))) with Failure e -> Error e)) v)
        | Error e -> Error e
    let http_version (t:t) : (string, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"httpVersion" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_string v)) v)
        | Error e -> Error e
    let sizes (t:t) : (RequestSizes.t, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"sizes" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "sizes" res with | `Null -> Error "sizes is null" | v -> (RequestSizes.of_yojson) v)
        | Error e -> Error e
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
end = struct
    type t = {
        url : string [@key "url"];
        __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}]
    } [@@deriving yojson {strict = false}]


    type info_t = {
        wait_id : string [@key "waitId"];
        phase : phase_t [@key "phase"];
        event : string option [@key "event"] [@default None];
        message : string option [@key "message"] [@default None];
        error : string option [@key "error"] [@default None];
    }

    and phase_t = [
        | `Before [@name "before"]
        | `After [@name "after"]
        | `Log [@name "log"]
    ] [@@deriving yojson]


    let wait_for_event_info ~info (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["info", (info_t_to_yojson) info];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"waitForEventInfo" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
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
end = struct
    type t = {
        frame : Frame.t [@key "frame"];
        name : string [@key "name"];
        args : SerializedValue.t array [@key "args"];
        __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}]
    } [@@deriving yojson {strict = false}]

    let reject ~error (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["error", (SerializedError.to_yojson) error];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"reject" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let resolve ~result (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["result", (SerializedArgument.to_yojson) result];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"resolve" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
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
end = struct
    type t = { __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}] } [@@deriving yojson {strict = false}]


    type info_t = {
        wait_id : string [@key "waitId"];
        phase : phase_t [@key "phase"];
        event : string option [@key "event"] [@default None];
        message : string option [@key "message"] [@default None];
        error : string option [@key "error"] [@default None];
    }

    and phase_t = [
        | `Before [@name "before"]
        | `After [@name "after"]
        | `Log [@name "log"]
    ] [@@deriving yojson]


    let wait_for_event_info ~info (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["info", (info_t_to_yojson) info];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"waitForEventInfo" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let request_pause (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"requestPause" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let resume (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"resume" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let next (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"next" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e

    type location_t = {
        file : string [@key "file"];
        line : int option [@key "line"] [@default None];
        column : int option [@key "column"] [@default None];
    }

    let run_to ~location (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["location", (location_t_to_yojson) location];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"runTo" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
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
end = struct
    type t = {
        page : Page.t option [@key "page"] [@default None];
        type_ : string [@key "type"];
        message : string [@key "message"];
        default_value : string [@key "defaultValue"];
        __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}]
    } [@@deriving yojson {strict = false}]

    let accept ?prompt_text (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match prompt_text with | Some v -> [("promptText", (fun s -> `String s) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"accept" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let dismiss (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"dismiss" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
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
end = struct
    type t = { __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}] } [@@deriving yojson {strict = false}]

    let tracing_start ?name ?snapshots ?screenshots ?live (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        (match name with | Some v -> [("name", (fun s -> `String s) v)] | None -> []);
        (match snapshots with | Some v -> [("snapshots", (fun b -> `Bool b) v)] | None -> []);
        (match screenshots with | Some v -> [("screenshots", (fun b -> `Bool b) v)] | None -> []);
        (match live with | Some v -> [("live", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"tracingStart" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let tracing_start_chunk ?name ?title (t:t) : (string, string) result =
        let params = `Assoc (List.concat [
        (match name with | Some v -> [("name", (fun s -> `String s) v)] | None -> []);
        (match title with | Some v -> [("title", (fun s -> `String s) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"tracingStartChunk" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "traceName" res with | `Null -> Error "traceName is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_string v)) v)
        | Error e -> Error e

    type location_t = {
        file : string [@key "file"];
        line : int option [@key "line"] [@default None];
        column : int option [@key "column"] [@default None];
    }

    let tracing_group ~name ?location (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["name", (fun s -> `String s) name];
        (match location with | Some v -> [("location", (location_t_to_yojson) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"tracingGroup" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let tracing_group_end (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"tracingGroupEnd" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e

    type tracing_stop_chunk_res_t = {
        artifact : Artifact.t option [@key "artifact"] [@default None];
        entries : NameValue.t array option [@key "entries"] [@default None];
    } [@@deriving yojson {strict = false}]

    and mode_t = [
        | `Archive [@name "archive"]
        | `Discard [@name "discard"]
        | `Entries [@name "entries"]
    ] [@@deriving yojson]


    let tracing_stop_chunk ~mode (t:t) : (tracing_stop_chunk_res_t, string) result =
        let params = `Assoc (List.concat [
        ["mode", (mode_t_to_yojson) mode];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"tracingStopChunk" ~params with
        | Ok res -> tracing_stop_chunk_res_t_of_yojson res
        | Error e -> Error e
    let tracing_stop (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"tracingStop" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let har_start ?page ~options (t:t) : (string, string) result =
        let params = `Assoc (List.concat [
        (match page with | Some v -> [("page", (Page.to_yojson) v)] | None -> []);
        ["options", (RecordHarOptions.to_yojson) options];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"harStart" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "harId" res with | `Null -> Error "harId is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_string v)) v)
        | Error e -> Error e
    let har_export ?har_id (t:t) : (Artifact.t, string) result =
        let params = `Assoc (List.concat [
        (match har_id with | Some v -> [("harId", (fun s -> `String s) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"harExport" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "artifact" res with | `Null -> Error "artifact is null" | v -> (Artifact.of_yojson) v)
        | Error e -> Error e
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
end = struct
    type t = {
        absolute_path : string [@key "absolutePath"];
        __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}]
    } [@@deriving yojson {strict = false}]

    let path_after_finished (t:t) : (string, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"pathAfterFinished" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "value" res with | `Null -> Error "value is null" | v -> (fun v -> Ok (Yojson.Safe.Util.to_string v)) v)
        | Error e -> Error e
    let save_as ~path (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["path", (fun s -> `String s) path];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"saveAs" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let save_as_stream (t:t) : (Stream.t, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"saveAsStream" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "stream" res with | `Null -> Error "stream is null" | v -> (Stream.of_yojson) v)
        | Error e -> Error e
    let failure (t:t) : (string option, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"failure" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "error" res with | `Null -> Ok None | v -> match (fun v -> Ok (Yojson.Safe.Util.to_string v)) v with Ok r -> Ok (Some r) | Error e -> Error e)
        | Error e -> Error e
    let stream (t:t) : (Stream.t, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"stream" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "stream" res with | `Null -> Error "stream is null" | v -> (Stream.of_yojson) v)
        | Error e -> Error e
    let cancel (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"cancel" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let delete (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"delete" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
end
and Stream : sig
    type t [@@deriving yojson]

    val read : ?size:int -> t -> string
    val close : t -> unit
end = struct
    type t = { __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}] } [@@deriving yojson {strict = false}]

    let read ?size (t:t) : (string, string) result =
        let params = `Assoc (List.concat [
        (match size with | Some v -> [("size", (fun i -> `Int i) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"read" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "binary" res with | `Null -> Error "binary is null" | v -> (fun v -> Ok (Base64.decode_exn (Yojson.Safe.Util.to_string v))) v)
        | Error e -> Error e
    let close (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"close" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
end
and WritableStream : sig
    type t [@@deriving yojson]

    val write : binary:string -> t -> unit
    val close : t -> unit
end = struct
    type t = { __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}] } [@@deriving yojson {strict = false}]

    let write ~binary (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["binary", (fun s -> `String (Base64.encode_exn s)) binary];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"write" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let close (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"close" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
end
and CDPSession : sig
    type t [@@deriving yojson]

    val send : method_:string -> ?params:json -> t -> json
    val detach : t -> unit
end = struct
    type t = { __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}] } [@@deriving yojson {strict = false}]

    let send ~method_ ?params (t:t) : (json, string) result =
        let params = `Assoc (List.concat [
        ["method", (fun s -> `String s) method_];
        (match params with | Some v -> [("params", (json_to_yojson) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"send" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "result" res with | `Null -> Error "result is null" | v -> (json_of_yojson) v)
        | Error e -> Error e
    let detach (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"detach" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
end
and Android : sig
    type t [@@deriving yojson]

    val devices : ?host:string -> ?port:int -> ?omit_driver_install:bool -> t -> AndroidDevice.t array
end = struct
    type t = { __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}] } [@@deriving yojson {strict = false}]

    let devices ?host ?port ?omit_driver_install (t:t) : (AndroidDevice.t array, string) result =
        let params = `Assoc (List.concat [
        (match host with | Some v -> [("host", (fun s -> `String s) v)] | None -> []);
        (match port with | Some v -> [("port", (fun i -> `Int i) v)] | None -> []);
        (match omit_driver_install with | Some v -> [("omitDriverInstall", (fun b -> `Bool b) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"devices" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "devices" res with | `Null -> Error "devices is null" | v -> ((fun v -> try Ok (Array.of_list (List.map (fun item -> match (AndroidDevice.of_yojson) item with Ok r -> r | Error e -> failwith e) (Yojson.Safe.Util.to_list v))) with Failure e -> Error e)) v)
        | Error e -> Error e
end
and AndroidSocket : sig
    type t [@@deriving yojson]

    val write : data:string -> t -> unit
    val close : t -> unit
end = struct
    type t = { __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}] } [@@deriving yojson {strict = false}]

    let write ~data (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["data", (fun s -> `String (Base64.encode_exn s)) data];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"write" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let close (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"close" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
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
end = struct
    type t = {
        model : string [@key "model"];
        serial : string [@key "serial"];
        __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}]
    } [@@deriving yojson {strict = false}]


    type info_t = {
        wait_id : string [@key "waitId"];
        phase : phase_t [@key "phase"];
        event : string option [@key "event"] [@default None];
        message : string option [@key "message"] [@default None];
        error : string option [@key "error"] [@default None];
    }

    and phase_t = [
        | `Before [@name "before"]
        | `After [@name "after"]
        | `Log [@name "log"]
    ] [@@deriving yojson]


    let wait_for_event_info ~info (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["info", (info_t_to_yojson) info];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"waitForEventInfo" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e

    type state_t = [
        | `Gone [@name "gone"]
    ] [@@deriving yojson]


    let wait ~android_selector ?state ~timeout (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["androidSelector", (AndroidSelector.to_yojson) android_selector];
        (match state with | Some v -> [("state", (state_t_to_yojson) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"wait" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let fill ~android_selector ~text ~timeout (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["androidSelector", (AndroidSelector.to_yojson) android_selector];
        ["text", (fun s -> `String s) text];
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"fill" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let tap ~android_selector ?duration ~timeout (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["androidSelector", (AndroidSelector.to_yojson) android_selector];
        (match duration with | Some v -> [("duration", (fun f -> `Float f) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"tap" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let drag ~android_selector ~dest ?speed ~timeout (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["androidSelector", (AndroidSelector.to_yojson) android_selector];
        ["dest", (Point.to_yojson) dest];
        (match speed with | Some v -> [("speed", (fun f -> `Float f) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"drag" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e

    type direction_t = [
        | `Up [@name "up"]
        | `Down [@name "down"]
        | `Left [@name "left"]
        | `Right [@name "right"]
    ] [@@deriving yojson]


    let fling ~android_selector ~direction ?speed ~timeout (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["androidSelector", (AndroidSelector.to_yojson) android_selector];
        ["direction", (direction_t_to_yojson) direction];
        (match speed with | Some v -> [("speed", (fun f -> `Float f) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"fling" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let long_tap ~android_selector ~timeout (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["androidSelector", (AndroidSelector.to_yojson) android_selector];
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"longTap" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let pinch_close ~android_selector ~percent ?speed ~timeout (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["androidSelector", (AndroidSelector.to_yojson) android_selector];
        ["percent", (fun f -> `Float f) percent];
        (match speed with | Some v -> [("speed", (fun f -> `Float f) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"pinchClose" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let pinch_open ~android_selector ~percent ?speed ~timeout (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["androidSelector", (AndroidSelector.to_yojson) android_selector];
        ["percent", (fun f -> `Float f) percent];
        (match speed with | Some v -> [("speed", (fun f -> `Float f) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"pinchOpen" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let scroll ~android_selector ~direction ~percent ?speed ~timeout (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["androidSelector", (AndroidSelector.to_yojson) android_selector];
        ["direction", (direction_t_to_yojson) direction];
        ["percent", (fun f -> `Float f) percent];
        (match speed with | Some v -> [("speed", (fun f -> `Float f) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"scroll" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let swipe ~android_selector ~direction ~percent ?speed ~timeout (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["androidSelector", (AndroidSelector.to_yojson) android_selector];
        ["direction", (direction_t_to_yojson) direction];
        ["percent", (fun f -> `Float f) percent];
        (match speed with | Some v -> [("speed", (fun f -> `Float f) v)] | None -> []);
        ["timeout", (fun f -> `Float f) timeout];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"swipe" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let info ~android_selector (t:t) : (AndroidElementInfo.t, string) result =
        let params = `Assoc (List.concat [
        ["androidSelector", (AndroidSelector.to_yojson) android_selector];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"info" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "info" res with | `Null -> Error "info is null" | v -> (AndroidElementInfo.of_yojson) v)
        | Error e -> Error e
    let screenshot (t:t) : (string, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"screenshot" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "binary" res with | `Null -> Error "binary is null" | v -> (fun v -> Ok (Base64.decode_exn (Yojson.Safe.Util.to_string v))) v)
        | Error e -> Error e
    let input_type ~text (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["text", (fun s -> `String s) text];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"inputType" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let input_press ~key (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["key", (fun s -> `String s) key];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"inputPress" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let input_tap ~point (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["point", (Point.to_yojson) point];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"inputTap" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let input_swipe ~segments ~steps (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["segments", ((fun l -> `List (List.map (Point.to_yojson) (Array.to_list l)))) segments];
        ["steps", (fun i -> `Int i) steps];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"inputSwipe" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let input_drag ~from ~to_ ~steps (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["from", (Point.to_yojson) from];
        ["to", (Point.to_yojson) to_];
        ["steps", (fun i -> `Int i) steps];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"inputDrag" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e

    type proxy_t = {
        server : string [@key "server"];
        bypass : string option [@key "bypass"] [@default None];
        username : string option [@key "username"] [@default None];
        password : string option [@key "password"] [@default None];
    }

    and service_workers_t = [
        | `Allow [@name "allow"]
        | `Block [@name "block"]
    ] [@@deriving yojson]


    and record_video_t = {
        dir : string option [@key "dir"] [@default None];
        size : size_t option [@key "size"] [@default None];
        show_actions : show_actions_t option [@key "showActions"] [@default None];
    }

    and show_actions_t = {
        duration : float option [@key "duration"] [@default None];
        position : position_t option [@key "position"] [@default None];
        font_size : int option [@key "fontSize"] [@default None];
    }

    and position_t = [
        | `Top_left [@name "top-left"]
        | `Top [@name "top"]
        | `Top_right [@name "top-right"]
        | `Bottom_left [@name "bottom-left"]
        | `Bottom [@name "bottom"]
        | `Bottom_right [@name "bottom-right"]
    ] [@@deriving yojson]


    and size_t = {
        width : int [@key "width"];
        height : int [@key "height"];
    }

    and contrast_t = [
        | `No_preference [@name "no-preference"]
        | `More [@name "more"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]


    and accept_downloads_t = [
        | `Accept [@name "accept"]
        | `Deny [@name "deny"]
        | `Internal_browser_default [@name "internal-browser-default"]
    ] [@@deriving yojson]


    and forced_colors_t = [
        | `Active [@name "active"]
        | `None [@name "none"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]


    and reduced_motion_t = [
        | `Reduce [@name "reduce"]
        | `No_preference [@name "no-preference"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]


    and color_scheme_t = [
        | `Dark [@name "dark"]
        | `Light [@name "light"]
        | `No_preference [@name "no-preference"]
        | `No_override [@name "no-override"]
    ] [@@deriving yojson]


    and http_credentials_t = {
        username : string [@key "username"];
        password : string [@key "password"];
        origin : string option [@key "origin"] [@default None];
        send : send_t option [@key "send"] [@default None];
    }

    and send_t = [
        | `Always [@name "always"]
        | `Unauthorized [@name "unauthorized"]
    ] [@@deriving yojson]


    and geolocation_t = {
        longitude : float [@key "longitude"];
        latitude : float [@key "latitude"];
        accuracy : float option [@key "accuracy"] [@default None];
    }

    and client_certificates_t = {
        origin : string [@key "origin"];
        cert : string option [@key "cert"] [@default None];
        key : string option [@key "key"] [@default None];
        passphrase : string option [@key "passphrase"] [@default None];
        pfx : string option [@key "pfx"] [@default None];
    }

    and screen_t = {
        width : int [@key "width"];
        height : int [@key "height"];
    }

    and viewport_t = {
        width : int [@key "width"];
        height : int [@key "height"];
    }

    let launch_browser ?no_default_viewport ?viewport ?screen ?ignore_https_errors ?client_certificates ?java_script_enabled ?bypass_csp ?user_agent ?locale ?timezone_id ?geolocation ?permissions ?extra_http_headers ?offline ?http_credentials ?device_scale_factor ?is_mobile ?has_touch ?color_scheme ?reduced_motion ?forced_colors ?accept_downloads ?contrast ?base_url ?record_video ?strict_selectors ?service_workers ?selector_engines ?test_id_attribute_name ?pkg ?args ?proxy (t:t) : (BrowserContext.t, string) result =
        let params = `Assoc (List.concat [
        (match no_default_viewport with | Some v -> [("noDefaultViewport", (fun b -> `Bool b) v)] | None -> []);
        (match viewport with | Some v -> [("viewport", (viewport_t_to_yojson) v)] | None -> []);
        (match screen with | Some v -> [("screen", (screen_t_to_yojson) v)] | None -> []);
        (match ignore_https_errors with | Some v -> [("ignoreHTTPSErrors", (fun b -> `Bool b) v)] | None -> []);
        (match client_certificates with | Some v -> [("clientCertificates", ((fun l -> `List (List.map (client_certificates_t_to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match java_script_enabled with | Some v -> [("javaScriptEnabled", (fun b -> `Bool b) v)] | None -> []);
        (match bypass_csp with | Some v -> [("bypassCSP", (fun b -> `Bool b) v)] | None -> []);
        (match user_agent with | Some v -> [("userAgent", (fun s -> `String s) v)] | None -> []);
        (match locale with | Some v -> [("locale", (fun s -> `String s) v)] | None -> []);
        (match timezone_id with | Some v -> [("timezoneId", (fun s -> `String s) v)] | None -> []);
        (match geolocation with | Some v -> [("geolocation", (geolocation_t_to_yojson) v)] | None -> []);
        (match permissions with | Some v -> [("permissions", ((fun l -> `List (List.map (fun s -> `String s) (Array.to_list l)))) v)] | None -> []);
        (match extra_http_headers with | Some v -> [("extraHTTPHeaders", ((fun l -> `List (List.map (NameValue.to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match offline with | Some v -> [("offline", (fun b -> `Bool b) v)] | None -> []);
        (match http_credentials with | Some v -> [("httpCredentials", (http_credentials_t_to_yojson) v)] | None -> []);
        (match device_scale_factor with | Some v -> [("deviceScaleFactor", (fun f -> `Float f) v)] | None -> []);
        (match is_mobile with | Some v -> [("isMobile", (fun b -> `Bool b) v)] | None -> []);
        (match has_touch with | Some v -> [("hasTouch", (fun b -> `Bool b) v)] | None -> []);
        (match color_scheme with | Some v -> [("colorScheme", (color_scheme_t_to_yojson) v)] | None -> []);
        (match reduced_motion with | Some v -> [("reducedMotion", (reduced_motion_t_to_yojson) v)] | None -> []);
        (match forced_colors with | Some v -> [("forcedColors", (forced_colors_t_to_yojson) v)] | None -> []);
        (match accept_downloads with | Some v -> [("acceptDownloads", (accept_downloads_t_to_yojson) v)] | None -> []);
        (match contrast with | Some v -> [("contrast", (contrast_t_to_yojson) v)] | None -> []);
        (match base_url with | Some v -> [("baseURL", (fun s -> `String s) v)] | None -> []);
        (match record_video with | Some v -> [("recordVideo", (record_video_t_to_yojson) v)] | None -> []);
        (match strict_selectors with | Some v -> [("strictSelectors", (fun b -> `Bool b) v)] | None -> []);
        (match service_workers with | Some v -> [("serviceWorkers", (service_workers_t_to_yojson) v)] | None -> []);
        (match selector_engines with | Some v -> [("selectorEngines", ((fun l -> `List (List.map (SelectorEngine.to_yojson) (Array.to_list l)))) v)] | None -> []);
        (match test_id_attribute_name with | Some v -> [("testIdAttributeName", (fun s -> `String s) v)] | None -> []);
        (match pkg with | Some v -> [("pkg", (fun s -> `String s) v)] | None -> []);
        (match args with | Some v -> [("args", ((fun l -> `List (List.map (fun s -> `String s) (Array.to_list l)))) v)] | None -> []);
        (match proxy with | Some v -> [("proxy", (proxy_t_to_yojson) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"launchBrowser" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "context" res with | `Null -> Error "context is null" | v -> (BrowserContext.of_yojson) v)
        | Error e -> Error e
    let open_ ~command (t:t) : (AndroidSocket.t, string) result =
        let params = `Assoc (List.concat [
        ["command", (fun s -> `String s) command];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"open" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "socket" res with | `Null -> Error "socket is null" | v -> (AndroidSocket.of_yojson) v)
        | Error e -> Error e
    let shell ~command (t:t) : (string, string) result =
        let params = `Assoc (List.concat [
        ["command", (fun s -> `String s) command];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"shell" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "result" res with | `Null -> Error "result is null" | v -> (fun v -> Ok (Base64.decode_exn (Yojson.Safe.Util.to_string v))) v)
        | Error e -> Error e
    let install_apk ~file ?args (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["file", (fun s -> `String (Base64.encode_exn s)) file];
        (match args with | Some v -> [("args", ((fun l -> `List (List.map (fun s -> `String s) (Array.to_list l)))) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"installApk" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let push ~file ~path ?mode (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["file", (fun s -> `String (Base64.encode_exn s)) file];
        ["path", (fun s -> `String s) path];
        (match mode with | Some v -> [("mode", (fun i -> `Int i) v)] | None -> []);
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"push" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let connect_to_web_view ~socket_name (t:t) : (BrowserContext.t, string) result =
        let params = `Assoc (List.concat [
        ["socketName", (fun s -> `String s) socket_name];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"connectToWebView" ~params with
        | Ok res -> (match Yojson.Safe.Util.member "context" res with | `Null -> Error "context is null" | v -> (BrowserContext.of_yojson) v)
        | Error e -> Error e
    let close (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"close" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
end
and JsonPipe : sig
    type t [@@deriving yojson]

    val send : message:json -> t -> unit
    val close : t -> unit
end = struct
    type t = { __internal_obj : obj [@default {conn = Obj.magic (); guid = ""}] } [@@deriving yojson {strict = false}]

    let send ~message (t:t) : (unit, string) result =
        let params = `Assoc (List.concat [
        ["message", (json_to_yojson) message];
    ]) in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"send" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
    let close (t:t) : (unit, string) result =
        let params = `Assoc [] in
        match Connection.send_message t.__internal_obj.conn ~guid:t.__internal_obj.guid ~method_:"close" ~params with
        | Ok res -> Ok ()
        | Error e -> Error e
end
