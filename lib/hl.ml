[@@@ocaml.warning "-39-32-34-27-26-33"]

open Protocol

exception Error of string

type 'a obj = { conn: Connection.t; guid: string }

type artifact_type
type playwright_type
type android_device_type
type web_socket_route_type
type android_socket_type
type js_handle_type
type socks_support_type
type debugger_type
type worker_type
type disposable_type
type cdp_session_type
type writable_stream_type
type browser_type
type request_type
type element_handle_type
type response_type
type root_type
type android_type
type dialog_type
type web_socket_type
type tracing_type
type route_type
type debug_controller_type
type json_pipe_type
type local_utils_type
type page_type
type event_target_type
type stream_type
type api_request_context_type
type browser_type_type
type frame_type
type binding_call_type
type browser_context_type

module Api_request_context = struct
  type t = api_request_context_type obj

  let tracing (t : t) =
    match Hashtbl.find_opt t.conn.objects t.guid with
    | Some obj ->
        let open Yojson.Safe.Util in
        (try ({ conn = t.conn; guid = member "tracing" obj.initializer_ |> member "guid" |> to_string } : tracing_type obj)
         with _ -> failwith "Missing required initializer property tracing")
    | None -> failwith "Object not found in connection"

  let fetch ?max_retries ?max_redirects ?ignore_https_errors ?fail_on_status_code ~timeout ?multipart_data ?form_data ?json_data ?post_data ?headers ?method_ ?params ?encoded_params ~url (t : t) () =
    let args : Protocol.api_request_context_fetch_args = {
      Protocol.api_request_context_fetch_args_max_retries = max_retries;
      Protocol.api_request_context_fetch_args_max_redirects = max_redirects;
      Protocol.api_request_context_fetch_args_ignore_https_errors = ignore_https_errors;
      Protocol.api_request_context_fetch_args_fail_on_status_code = fail_on_status_code;
      Protocol.api_request_context_fetch_args_timeout = timeout;
      Protocol.api_request_context_fetch_args_multipart_data = multipart_data;
      Protocol.api_request_context_fetch_args_form_data = form_data;
      Protocol.api_request_context_fetch_args_json_data = json_data;
      Protocol.api_request_context_fetch_args_post_data = post_data;
      Protocol.api_request_context_fetch_args_headers = headers;
      Protocol.api_request_context_fetch_args_method_ = method_;
      Protocol.api_request_context_fetch_args_params = params;
      Protocol.api_request_context_fetch_args_encoded_params = encoded_params;
      Protocol.api_request_context_fetch_args_url = url;
    } in
    match Api.Api_request_context.fetch t.conn t.guid args with
    | Ok res -> res.Protocol.api_request_context_fetch_returns_response
    | Error e -> raise (Error e)

  let fetch_response_body ~fetch_uid (t : t) () =
    let args : Protocol.api_request_context_fetch_response_body_args = {
      Protocol.api_request_context_fetch_response_body_args_fetch_uid = fetch_uid;
    } in
    match Api.Api_request_context.fetch_response_body t.conn t.guid args with
    | Ok res -> res.Protocol.api_request_context_fetch_response_body_returns_binary
    | Error e -> raise (Error e)

  let fetch_log ~fetch_uid (t : t) () =
    let args : Protocol.api_request_context_fetch_log_args = {
      Protocol.api_request_context_fetch_log_args_fetch_uid = fetch_uid;
    } in
    match Api.Api_request_context.fetch_log t.conn t.guid args with
    | Ok res -> res.Protocol.api_request_context_fetch_log_returns_log
    | Error e -> raise (Error e)

  let storage_state ?indexed_db (t : t) () =
    let args : Protocol.api_request_context_storage_state_args = {
      Protocol.api_request_context_storage_state_args_indexed_db = indexed_db;
    } in
    match Api.Api_request_context.storage_state t.conn t.guid args with
    | Ok res -> res
    | Error e -> raise (Error e)

  let dispose_api_response ~fetch_uid (t : t) () =
    let args : Protocol.api_request_context_dispose_api_response_args = {
      Protocol.api_request_context_dispose_api_response_args_fetch_uid = fetch_uid;
    } in
    match Api.Api_request_context.dispose_api_response t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let dispose ?reason (t : t) () =
    let args : Protocol.api_request_context_dispose_args = {
      Protocol.api_request_context_dispose_args_reason = reason;
    } in
    match Api.Api_request_context.dispose t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

end

module Local_utils = struct
  type t = local_utils_type obj

  let zip ?additional_sources ~include_sources ~mode ?stacks_id ~entries ~zip_file (t : t) () =
    let args : Protocol.local_utils_zip_args = {
      Protocol.local_utils_zip_args_additional_sources = additional_sources;
      Protocol.local_utils_zip_args_include_sources = include_sources;
      Protocol.local_utils_zip_args_mode = mode;
      Protocol.local_utils_zip_args_stacks_id = stacks_id;
      Protocol.local_utils_zip_args_entries = entries;
      Protocol.local_utils_zip_args_zip_file = zip_file;
    } in
    match Api.Local_utils.zip t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let har_open ~file (t : t) () =
    let args : Protocol.local_utils_har_open_args = {
      Protocol.local_utils_har_open_args_file = file;
    } in
    match Api.Local_utils.har_open t.conn t.guid args with
    | Ok res -> res
    | Error e -> raise (Error e)

  let har_lookup ~is_navigation_request ?post_data ~headers ~method_ ~url ~har_id (t : t) () =
    let args : Protocol.local_utils_har_lookup_args = {
      Protocol.local_utils_har_lookup_args_is_navigation_request = is_navigation_request;
      Protocol.local_utils_har_lookup_args_post_data = post_data;
      Protocol.local_utils_har_lookup_args_headers = headers;
      Protocol.local_utils_har_lookup_args_method_ = method_;
      Protocol.local_utils_har_lookup_args_url = url;
      Protocol.local_utils_har_lookup_args_har_id = har_id;
    } in
    match Api.Local_utils.har_lookup t.conn t.guid args with
    | Ok res -> res
    | Error e -> raise (Error e)

  let har_close ~har_id (t : t) () =
    let args : Protocol.local_utils_har_close_args = {
      Protocol.local_utils_har_close_args_har_id = har_id;
    } in
    match Api.Local_utils.har_close t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let har_unzip ~har_file ~zip_file (t : t) () =
    let args : Protocol.local_utils_har_unzip_args = {
      Protocol.local_utils_har_unzip_args_har_file = har_file;
      Protocol.local_utils_har_unzip_args_zip_file = zip_file;
    } in
    match Api.Local_utils.har_unzip t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let connect ?socks_proxy_redirect_port_for_test ~timeout ?slow_mo ?expose_network ?headers ~endpoint (t : t) () =
    let args : Protocol.local_utils_connect_args = {
      Protocol.local_utils_connect_args_socks_proxy_redirect_port_for_test = socks_proxy_redirect_port_for_test;
      Protocol.local_utils_connect_args_timeout = timeout;
      Protocol.local_utils_connect_args_slow_mo = slow_mo;
      Protocol.local_utils_connect_args_expose_network = expose_network;
      Protocol.local_utils_connect_args_headers = headers;
      Protocol.local_utils_connect_args_endpoint = endpoint;
    } in
    match Api.Local_utils.connect t.conn t.guid args with
    | Ok res -> res
    | Error e -> raise (Error e)

  let tracing_started ?live ~trace_name ?traces_dir (t : t) () =
    let args : Protocol.local_utils_tracing_started_args = {
      Protocol.local_utils_tracing_started_args_live = live;
      Protocol.local_utils_tracing_started_args_trace_name = trace_name;
      Protocol.local_utils_tracing_started_args_traces_dir = traces_dir;
    } in
    match Api.Local_utils.tracing_started t.conn t.guid args with
    | Ok res -> res.Protocol.local_utils_tracing_started_returns_stacks_id
    | Error e -> raise (Error e)

  let add_stack_to_tracing_no_reply ~call_data (t : t) () =
    let args : Protocol.local_utils_add_stack_to_tracing_no_reply_args = {
      Protocol.local_utils_add_stack_to_tracing_no_reply_args_call_data = call_data;
    } in
    match Api.Local_utils.add_stack_to_tracing_no_reply t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let trace_discarded ~stacks_id (t : t) () =
    let args : Protocol.local_utils_trace_discarded_args = {
      Protocol.local_utils_trace_discarded_args_stacks_id = stacks_id;
    } in
    match Api.Local_utils.trace_discarded t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let glob_to_regex ?web_socket_url ?base_url ~glob (t : t) () =
    let args : Protocol.local_utils_glob_to_regex_args = {
      Protocol.local_utils_glob_to_regex_args_web_socket_url = web_socket_url;
      Protocol.local_utils_glob_to_regex_args_base_url = base_url;
      Protocol.local_utils_glob_to_regex_args_glob = glob;
    } in
    match Api.Local_utils.glob_to_regex t.conn t.guid args with
    | Ok res -> res.Protocol.local_utils_glob_to_regex_returns_regex
    | Error e -> raise (Error e)

end

module Root = struct
  type t = root_type obj

  let initialize ~sdk_language (t : t) () =
    let args : Protocol.root_initialize_args = {
      Protocol.root_initialize_args_sdk_language = sdk_language;
    } in
    match Api.Root.initialize t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.root_initialize_returns_playwright.guid } : playwright_type obj)
    | Error e -> raise (Error e)

end

module Playwright = struct
  type t = playwright_type obj

  let chromium (t : t) =
    match Hashtbl.find_opt t.conn.objects t.guid with
    | Some obj ->
        let open Yojson.Safe.Util in
        (try ({ conn = t.conn; guid = member "chromium" obj.initializer_ |> member "guid" |> to_string } : browser_type_type obj)
         with _ -> failwith "Missing required initializer property chromium")
    | None -> failwith "Object not found in connection"

  let firefox (t : t) =
    match Hashtbl.find_opt t.conn.objects t.guid with
    | Some obj ->
        let open Yojson.Safe.Util in
        (try ({ conn = t.conn; guid = member "firefox" obj.initializer_ |> member "guid" |> to_string } : browser_type_type obj)
         with _ -> failwith "Missing required initializer property firefox")
    | None -> failwith "Object not found in connection"

  let webkit (t : t) =
    match Hashtbl.find_opt t.conn.objects t.guid with
    | Some obj ->
        let open Yojson.Safe.Util in
        (try ({ conn = t.conn; guid = member "webkit" obj.initializer_ |> member "guid" |> to_string } : browser_type_type obj)
         with _ -> failwith "Missing required initializer property webkit")
    | None -> failwith "Object not found in connection"

  let android (t : t) =
    match Hashtbl.find_opt t.conn.objects t.guid with
    | Some obj ->
        let open Yojson.Safe.Util in
        (try ({ conn = t.conn; guid = member "android" obj.initializer_ |> member "guid" |> to_string } : android_type obj)
         with _ -> failwith "Missing required initializer property android")
    | None -> failwith "Object not found in connection"

  let utils (t : t) =
    match Hashtbl.find_opt t.conn.objects t.guid with
    | Some obj ->
        let open Yojson.Safe.Util in
        (try Some ({ conn = t.conn; guid = member "utils" obj.initializer_ |> member "guid" |> to_string } : local_utils_type obj)
         with _ -> None)
    | None -> failwith "Object not found in connection"

  let pre_launched_browser (t : t) =
    match Hashtbl.find_opt t.conn.objects t.guid with
    | Some obj ->
        let open Yojson.Safe.Util in
        (try Some ({ conn = t.conn; guid = member "preLaunchedBrowser" obj.initializer_ |> member "guid" |> to_string } : browser_type obj)
         with _ -> None)
    | None -> failwith "Object not found in connection"

  let pre_connected_android_device (t : t) =
    match Hashtbl.find_opt t.conn.objects t.guid with
    | Some obj ->
        let open Yojson.Safe.Util in
        (try Some ({ conn = t.conn; guid = member "preConnectedAndroidDevice" obj.initializer_ |> member "guid" |> to_string } : android_device_type obj)
         with _ -> None)
    | None -> failwith "Object not found in connection"

  let socks_support (t : t) =
    match Hashtbl.find_opt t.conn.objects t.guid with
    | Some obj ->
        let open Yojson.Safe.Util in
        (try Some ({ conn = t.conn; guid = member "socksSupport" obj.initializer_ |> member "guid" |> to_string } : socks_support_type obj)
         with _ -> None)
    | None -> failwith "Object not found in connection"

  let new_request ?traces_dir ?storage_state ?proxy ?http_credentials ?max_redirects ?client_certificates ?fail_on_status_code ?extra_http_headers ?ignore_https_errors ?user_agent ?base_url (t : t) () =
    let args : Protocol.playwright_new_request_args = {
      Protocol.playwright_new_request_args_traces_dir = traces_dir;
      Protocol.playwright_new_request_args_storage_state = storage_state;
      Protocol.playwright_new_request_args_proxy = proxy;
      Protocol.playwright_new_request_args_http_credentials = http_credentials;
      Protocol.playwright_new_request_args_max_redirects = max_redirects;
      Protocol.playwright_new_request_args_client_certificates = client_certificates;
      Protocol.playwright_new_request_args_fail_on_status_code = fail_on_status_code;
      Protocol.playwright_new_request_args_extra_http_headers = extra_http_headers;
      Protocol.playwright_new_request_args_ignore_https_errors = ignore_https_errors;
      Protocol.playwright_new_request_args_user_agent = user_agent;
      Protocol.playwright_new_request_args_base_url = base_url;
    } in
    match Api.Playwright.new_request t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.playwright_new_request_returns_request.guid } : api_request_context_type obj)
    | Error e -> raise (Error e)

end

module Debug_controller = struct
  type t = debug_controller_type obj

  let initialize ~sdk_language ~codegen_id (t : t) () =
    let args : Protocol.debug_controller_initialize_args = {
      Protocol.debug_controller_initialize_args_sdk_language = sdk_language;
      Protocol.debug_controller_initialize_args_codegen_id = codegen_id;
    } in
    match Api.Debug_controller.initialize t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_report_state_changed ~enabled (t : t) () =
    let args : Protocol.debug_controller_set_report_state_changed_args = {
      Protocol.debug_controller_set_report_state_changed_args_enabled = enabled;
    } in
    match Api.Debug_controller.set_report_state_changed t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_recorder_mode ?generate_auto_expect ?test_id_attribute_name ~mode (t : t) () =
    let args : Protocol.debug_controller_set_recorder_mode_args = {
      Protocol.debug_controller_set_recorder_mode_args_generate_auto_expect = generate_auto_expect;
      Protocol.debug_controller_set_recorder_mode_args_test_id_attribute_name = test_id_attribute_name;
      Protocol.debug_controller_set_recorder_mode_args_mode = mode;
    } in
    match Api.Debug_controller.set_recorder_mode t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let highlight ?aria_template ?selector (t : t) () =
    let args : Protocol.debug_controller_highlight_args = {
      Protocol.debug_controller_highlight_args_aria_template = aria_template;
      Protocol.debug_controller_highlight_args_selector = selector;
    } in
    match Api.Debug_controller.highlight t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let hide_highlight (t : t) () =
    match Api.Debug_controller.hide_highlight t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let resume (t : t) () =
    match Api.Debug_controller.resume t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let kill (t : t) () =
    match Api.Debug_controller.kill t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let on_inspect_requested (t : t) cb =
    Connection.on t.conn t.guid "inspectRequested" (fun msg ->
      match Protocol.debug_controller_inspect_requested_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_set_mode_requested (t : t) cb =
    Connection.on t.conn t.guid "setModeRequested" (fun msg ->
      match Protocol.debug_controller_set_mode_requested_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_state_changed (t : t) cb =
    Connection.on t.conn t.guid "stateChanged" (fun msg ->
      match Protocol.debug_controller_state_changed_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_source_changed (t : t) cb =
    Connection.on t.conn t.guid "sourceChanged" (fun msg ->
      match Protocol.debug_controller_source_changed_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_paused (t : t) cb =
    Connection.on t.conn t.guid "paused" (fun msg ->
      match Protocol.debug_controller_paused_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

end

module Socks_support = struct
  type t = socks_support_type obj

  let socks_connected ~port ~host ~uid (t : t) () =
    let args : Protocol.socks_support_socks_connected_args = {
      Protocol.socks_support_socks_connected_args_port = port;
      Protocol.socks_support_socks_connected_args_host = host;
      Protocol.socks_support_socks_connected_args_uid = uid;
    } in
    match Api.Socks_support.socks_connected t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let socks_failed ~error_code ~uid (t : t) () =
    let args : Protocol.socks_support_socks_failed_args = {
      Protocol.socks_support_socks_failed_args_error_code = error_code;
      Protocol.socks_support_socks_failed_args_uid = uid;
    } in
    match Api.Socks_support.socks_failed t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let socks_data ~data ~uid (t : t) () =
    let args : Protocol.socks_support_socks_data_args = {
      Protocol.socks_support_socks_data_args_data = data;
      Protocol.socks_support_socks_data_args_uid = uid;
    } in
    match Api.Socks_support.socks_data t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let socks_error ~error ~uid (t : t) () =
    let args : Protocol.socks_support_socks_error_args = {
      Protocol.socks_support_socks_error_args_error = error;
      Protocol.socks_support_socks_error_args_uid = uid;
    } in
    match Api.Socks_support.socks_error t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let socks_end ~uid (t : t) () =
    let args : Protocol.socks_support_socks_end_args = {
      Protocol.socks_support_socks_end_args_uid = uid;
    } in
    match Api.Socks_support.socks_end t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let on_socks_requested (t : t) cb =
    Connection.on t.conn t.guid "socksRequested" (fun msg ->
      match Protocol.socks_support_socks_requested_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_socks_data (t : t) cb =
    Connection.on t.conn t.guid "socksData" (fun msg ->
      match Protocol.socks_support_socks_data_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_socks_closed (t : t) cb =
    Connection.on t.conn t.guid "socksClosed" (fun msg ->
      match Protocol.socks_support_socks_closed_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

end

module Browser_type = struct
  type t = browser_type_type obj

  let launch ?cdp_port ?firefox_user_prefs ?chromium_sandbox ?artifacts_dir ?traces_dir ?downloads_path ?proxy ?headless ?env ~timeout ?handle_sighup ?handle_sigterm ?handle_sigint ?ignore_default_args ?ignore_all_default_args ?args ?executable_path ?channel ?slow_mo (t : t) () =
    let args : Protocol.browser_type_launch_args = {
      Protocol.browser_type_launch_args_cdp_port = cdp_port;
      Protocol.browser_type_launch_args_firefox_user_prefs = firefox_user_prefs;
      Protocol.browser_type_launch_args_chromium_sandbox = chromium_sandbox;
      Protocol.browser_type_launch_args_artifacts_dir = artifacts_dir;
      Protocol.browser_type_launch_args_traces_dir = traces_dir;
      Protocol.browser_type_launch_args_downloads_path = downloads_path;
      Protocol.browser_type_launch_args_proxy = proxy;
      Protocol.browser_type_launch_args_headless = headless;
      Protocol.browser_type_launch_args_env = env;
      Protocol.browser_type_launch_args_timeout = timeout;
      Protocol.browser_type_launch_args_handle_sighup = handle_sighup;
      Protocol.browser_type_launch_args_handle_sigterm = handle_sigterm;
      Protocol.browser_type_launch_args_handle_sigint = handle_sigint;
      Protocol.browser_type_launch_args_ignore_default_args = ignore_default_args;
      Protocol.browser_type_launch_args_ignore_all_default_args = ignore_all_default_args;
      Protocol.browser_type_launch_args_args = args;
      Protocol.browser_type_launch_args_executable_path = executable_path;
      Protocol.browser_type_launch_args_channel = channel;
      Protocol.browser_type_launch_args_slow_mo = slow_mo;
    } in
    match Api.Browser_type.launch t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.browser_type_launch_returns_browser.guid } : browser_type obj)
    | Error e -> raise (Error e)

  let launch_persistent_context ?test_id_attribute_name ?selector_engines ?service_workers ?strict_selectors ?record_video ?base_url ?contrast ?accept_downloads ?forced_colors ?reduced_motion ?color_scheme ?has_touch ?is_mobile ?device_scale_factor ?http_credentials ?offline ?extra_http_headers ?permissions ?geolocation ?timezone_id ?locale ?user_agent ?bypass_csp ?java_script_enabled ?client_certificates ?ignore_https_errors ?screen ?viewport ?no_default_viewport ?cdp_port ?firefox_user_prefs ?chromium_sandbox ?artifacts_dir ?traces_dir ?downloads_path ?proxy ?headless ?env ~timeout ?handle_sighup ?handle_sigterm ?handle_sigint ?ignore_default_args ?ignore_all_default_args ?args ?executable_path ?channel ?slow_mo ~user_data_dir (t : t) () =
    let args : Protocol.browser_type_launch_persistent_context_args = {
      Protocol.browser_type_launch_persistent_context_args_test_id_attribute_name = test_id_attribute_name;
      Protocol.browser_type_launch_persistent_context_args_selector_engines = selector_engines;
      Protocol.browser_type_launch_persistent_context_args_service_workers = service_workers;
      Protocol.browser_type_launch_persistent_context_args_strict_selectors = strict_selectors;
      Protocol.browser_type_launch_persistent_context_args_record_video = record_video;
      Protocol.browser_type_launch_persistent_context_args_base_url = base_url;
      Protocol.browser_type_launch_persistent_context_args_contrast = contrast;
      Protocol.browser_type_launch_persistent_context_args_accept_downloads = accept_downloads;
      Protocol.browser_type_launch_persistent_context_args_forced_colors = forced_colors;
      Protocol.browser_type_launch_persistent_context_args_reduced_motion = reduced_motion;
      Protocol.browser_type_launch_persistent_context_args_color_scheme = color_scheme;
      Protocol.browser_type_launch_persistent_context_args_has_touch = has_touch;
      Protocol.browser_type_launch_persistent_context_args_is_mobile = is_mobile;
      Protocol.browser_type_launch_persistent_context_args_device_scale_factor = device_scale_factor;
      Protocol.browser_type_launch_persistent_context_args_http_credentials = http_credentials;
      Protocol.browser_type_launch_persistent_context_args_offline = offline;
      Protocol.browser_type_launch_persistent_context_args_extra_http_headers = extra_http_headers;
      Protocol.browser_type_launch_persistent_context_args_permissions = permissions;
      Protocol.browser_type_launch_persistent_context_args_geolocation = geolocation;
      Protocol.browser_type_launch_persistent_context_args_timezone_id = timezone_id;
      Protocol.browser_type_launch_persistent_context_args_locale = locale;
      Protocol.browser_type_launch_persistent_context_args_user_agent = user_agent;
      Protocol.browser_type_launch_persistent_context_args_bypass_csp = bypass_csp;
      Protocol.browser_type_launch_persistent_context_args_java_script_enabled = java_script_enabled;
      Protocol.browser_type_launch_persistent_context_args_client_certificates = client_certificates;
      Protocol.browser_type_launch_persistent_context_args_ignore_https_errors = ignore_https_errors;
      Protocol.browser_type_launch_persistent_context_args_screen = screen;
      Protocol.browser_type_launch_persistent_context_args_viewport = viewport;
      Protocol.browser_type_launch_persistent_context_args_no_default_viewport = no_default_viewport;
      Protocol.browser_type_launch_persistent_context_args_cdp_port = cdp_port;
      Protocol.browser_type_launch_persistent_context_args_firefox_user_prefs = firefox_user_prefs;
      Protocol.browser_type_launch_persistent_context_args_chromium_sandbox = chromium_sandbox;
      Protocol.browser_type_launch_persistent_context_args_artifacts_dir = artifacts_dir;
      Protocol.browser_type_launch_persistent_context_args_traces_dir = traces_dir;
      Protocol.browser_type_launch_persistent_context_args_downloads_path = downloads_path;
      Protocol.browser_type_launch_persistent_context_args_proxy = proxy;
      Protocol.browser_type_launch_persistent_context_args_headless = headless;
      Protocol.browser_type_launch_persistent_context_args_env = env;
      Protocol.browser_type_launch_persistent_context_args_timeout = timeout;
      Protocol.browser_type_launch_persistent_context_args_handle_sighup = handle_sighup;
      Protocol.browser_type_launch_persistent_context_args_handle_sigterm = handle_sigterm;
      Protocol.browser_type_launch_persistent_context_args_handle_sigint = handle_sigint;
      Protocol.browser_type_launch_persistent_context_args_ignore_default_args = ignore_default_args;
      Protocol.browser_type_launch_persistent_context_args_ignore_all_default_args = ignore_all_default_args;
      Protocol.browser_type_launch_persistent_context_args_args = args;
      Protocol.browser_type_launch_persistent_context_args_executable_path = executable_path;
      Protocol.browser_type_launch_persistent_context_args_channel = channel;
      Protocol.browser_type_launch_persistent_context_args_slow_mo = slow_mo;
      Protocol.browser_type_launch_persistent_context_args_user_data_dir = user_data_dir;
    } in
    match Api.Browser_type.launch_persistent_context t.conn t.guid args with
    | Ok res -> res
    | Error e -> raise (Error e)

  let connect_over_cdp ?no_defaults ?is_local ~timeout ?slow_mo ?headers ~endpoint_url (t : t) () =
    let args : Protocol.browser_type_connect_over_cd_p_args = {
      Protocol.browser_type_connect_over_cd_p_args_no_defaults = no_defaults;
      Protocol.browser_type_connect_over_cd_p_args_is_local = is_local;
      Protocol.browser_type_connect_over_cd_p_args_timeout = timeout;
      Protocol.browser_type_connect_over_cd_p_args_slow_mo = slow_mo;
      Protocol.browser_type_connect_over_cd_p_args_headers = headers;
      Protocol.browser_type_connect_over_cd_p_args_endpoint_url = endpoint_url;
    } in
    match Api.Browser_type.connect_over_cdp t.conn t.guid args with
    | Ok res -> res
    | Error e -> raise (Error e)

  let connect_to_worker ~timeout ~endpoint (t : t) () =
    let args : Protocol.browser_type_connect_to_worker_args = {
      Protocol.browser_type_connect_to_worker_args_timeout = timeout;
      Protocol.browser_type_connect_to_worker_args_endpoint = endpoint;
    } in
    match Api.Browser_type.connect_to_worker t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.browser_type_connect_to_worker_returns_worker.guid } : worker_type obj)
    | Error e -> raise (Error e)

end

module Browser = struct
  type t = browser_type obj

  let start_server ?port ?host ?metadata ?workspace_dir ~title (t : t) () =
    let args : Protocol.browser_start_server_args = {
      Protocol.browser_start_server_args_port = port;
      Protocol.browser_start_server_args_host = host;
      Protocol.browser_start_server_args_metadata = metadata;
      Protocol.browser_start_server_args_workspace_dir = workspace_dir;
      Protocol.browser_start_server_args_title = title;
    } in
    match Api.Browser.start_server t.conn t.guid args with
    | Ok res -> res.Protocol.browser_start_server_returns_endpoint
    | Error e -> raise (Error e)

  let stop_server (t : t) () =
    match Api.Browser.stop_server t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let close ?reason (t : t) () =
    let args : Protocol.browser_close_args = {
      Protocol.browser_close_args_reason = reason;
    } in
    match Api.Browser.close t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let kill_for_tests (t : t) () =
    match Api.Browser.kill_for_tests t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let default_user_agent_for_test (t : t) () =
    match Api.Browser.default_user_agent_for_test t.conn t.guid () with
    | Ok res -> res.Protocol.browser_default_user_agent_for_test_returns_user_agent
    | Error e -> raise (Error e)

  let new_context ?test_id_attribute_name ?selector_engines ?service_workers ?strict_selectors ?record_video ?base_url ?contrast ?accept_downloads ?forced_colors ?reduced_motion ?color_scheme ?has_touch ?is_mobile ?device_scale_factor ?http_credentials ?offline ?extra_http_headers ?permissions ?geolocation ?timezone_id ?locale ?user_agent ?bypass_csp ?java_script_enabled ?client_certificates ?ignore_https_errors ?screen ?viewport ?no_default_viewport ?storage_state ?proxy (t : t) () =
    let args : Protocol.browser_new_context_args = {
      Protocol.browser_new_context_args_test_id_attribute_name = test_id_attribute_name;
      Protocol.browser_new_context_args_selector_engines = selector_engines;
      Protocol.browser_new_context_args_service_workers = service_workers;
      Protocol.browser_new_context_args_strict_selectors = strict_selectors;
      Protocol.browser_new_context_args_record_video = record_video;
      Protocol.browser_new_context_args_base_url = base_url;
      Protocol.browser_new_context_args_contrast = contrast;
      Protocol.browser_new_context_args_accept_downloads = accept_downloads;
      Protocol.browser_new_context_args_forced_colors = forced_colors;
      Protocol.browser_new_context_args_reduced_motion = reduced_motion;
      Protocol.browser_new_context_args_color_scheme = color_scheme;
      Protocol.browser_new_context_args_has_touch = has_touch;
      Protocol.browser_new_context_args_is_mobile = is_mobile;
      Protocol.browser_new_context_args_device_scale_factor = device_scale_factor;
      Protocol.browser_new_context_args_http_credentials = http_credentials;
      Protocol.browser_new_context_args_offline = offline;
      Protocol.browser_new_context_args_extra_http_headers = extra_http_headers;
      Protocol.browser_new_context_args_permissions = permissions;
      Protocol.browser_new_context_args_geolocation = geolocation;
      Protocol.browser_new_context_args_timezone_id = timezone_id;
      Protocol.browser_new_context_args_locale = locale;
      Protocol.browser_new_context_args_user_agent = user_agent;
      Protocol.browser_new_context_args_bypass_csp = bypass_csp;
      Protocol.browser_new_context_args_java_script_enabled = java_script_enabled;
      Protocol.browser_new_context_args_client_certificates = client_certificates;
      Protocol.browser_new_context_args_ignore_https_errors = ignore_https_errors;
      Protocol.browser_new_context_args_screen = screen;
      Protocol.browser_new_context_args_viewport = viewport;
      Protocol.browser_new_context_args_no_default_viewport = no_default_viewport;
      Protocol.browser_new_context_args_storage_state = storage_state;
      Protocol.browser_new_context_args_proxy = proxy;
    } in
    match Api.Browser.new_context t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.browser_new_context_returns_context.guid } : browser_context_type obj)
    | Error e -> raise (Error e)

  let new_context_for_reuse ?test_id_attribute_name ?selector_engines ?service_workers ?strict_selectors ?record_video ?base_url ?contrast ?accept_downloads ?forced_colors ?reduced_motion ?color_scheme ?has_touch ?is_mobile ?device_scale_factor ?http_credentials ?offline ?extra_http_headers ?permissions ?geolocation ?timezone_id ?locale ?user_agent ?bypass_csp ?java_script_enabled ?client_certificates ?ignore_https_errors ?screen ?viewport ?no_default_viewport ?storage_state ?proxy (t : t) () =
    let args : Protocol.browser_new_context_for_reuse_args = {
      Protocol.browser_new_context_for_reuse_args_test_id_attribute_name = test_id_attribute_name;
      Protocol.browser_new_context_for_reuse_args_selector_engines = selector_engines;
      Protocol.browser_new_context_for_reuse_args_service_workers = service_workers;
      Protocol.browser_new_context_for_reuse_args_strict_selectors = strict_selectors;
      Protocol.browser_new_context_for_reuse_args_record_video = record_video;
      Protocol.browser_new_context_for_reuse_args_base_url = base_url;
      Protocol.browser_new_context_for_reuse_args_contrast = contrast;
      Protocol.browser_new_context_for_reuse_args_accept_downloads = accept_downloads;
      Protocol.browser_new_context_for_reuse_args_forced_colors = forced_colors;
      Protocol.browser_new_context_for_reuse_args_reduced_motion = reduced_motion;
      Protocol.browser_new_context_for_reuse_args_color_scheme = color_scheme;
      Protocol.browser_new_context_for_reuse_args_has_touch = has_touch;
      Protocol.browser_new_context_for_reuse_args_is_mobile = is_mobile;
      Protocol.browser_new_context_for_reuse_args_device_scale_factor = device_scale_factor;
      Protocol.browser_new_context_for_reuse_args_http_credentials = http_credentials;
      Protocol.browser_new_context_for_reuse_args_offline = offline;
      Protocol.browser_new_context_for_reuse_args_extra_http_headers = extra_http_headers;
      Protocol.browser_new_context_for_reuse_args_permissions = permissions;
      Protocol.browser_new_context_for_reuse_args_geolocation = geolocation;
      Protocol.browser_new_context_for_reuse_args_timezone_id = timezone_id;
      Protocol.browser_new_context_for_reuse_args_locale = locale;
      Protocol.browser_new_context_for_reuse_args_user_agent = user_agent;
      Protocol.browser_new_context_for_reuse_args_bypass_csp = bypass_csp;
      Protocol.browser_new_context_for_reuse_args_java_script_enabled = java_script_enabled;
      Protocol.browser_new_context_for_reuse_args_client_certificates = client_certificates;
      Protocol.browser_new_context_for_reuse_args_ignore_https_errors = ignore_https_errors;
      Protocol.browser_new_context_for_reuse_args_screen = screen;
      Protocol.browser_new_context_for_reuse_args_viewport = viewport;
      Protocol.browser_new_context_for_reuse_args_no_default_viewport = no_default_viewport;
      Protocol.browser_new_context_for_reuse_args_storage_state = storage_state;
      Protocol.browser_new_context_for_reuse_args_proxy = proxy;
    } in
    match Api.Browser.new_context_for_reuse t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.browser_new_context_for_reuse_returns_context.guid } : browser_context_type obj)
    | Error e -> raise (Error e)

  let disconnect_from_reused_context ~reason (t : t) () =
    let args : Protocol.browser_disconnect_from_reused_context_args = {
      Protocol.browser_disconnect_from_reused_context_args_reason = reason;
    } in
    match Api.Browser.disconnect_from_reused_context t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let new_browser_cdp_session (t : t) () =
    match Api.Browser.new_browser_cdp_session t.conn t.guid () with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.browser_new_browser_cdp_session_returns_session.guid } : cdp_session_type obj)
    | Error e -> raise (Error e)

  let start_tracing ?categories ?screenshots ?page (t : t) () =
    let args : Protocol.browser_start_tracing_args = {
      Protocol.browser_start_tracing_args_categories = categories;
      Protocol.browser_start_tracing_args_screenshots = screenshots;
      Protocol.browser_start_tracing_args_page = page;
    } in
    match Api.Browser.start_tracing t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let stop_tracing (t : t) () =
    match Api.Browser.stop_tracing t.conn t.guid () with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.browser_stop_tracing_returns_artifact.guid } : artifact_type obj)
    | Error e -> raise (Error e)

  let on_context (t : t) cb =
    Connection.on t.conn t.guid "context" (fun msg ->
      match Protocol.browser_context_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

end

module Event_target = struct
  type t = event_target_type obj

  let wait_for_event_info ~info (t : t) () =
    let args : Protocol.event_target_wait_for_event_info_args = {
      Protocol.event_target_wait_for_event_info_args_info = info;
    } in
    match Api.Event_target.wait_for_event_info t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

end

module Browser_context = struct
  type t = browser_context_type obj

  let debugger (t : t) =
    match Hashtbl.find_opt t.conn.objects t.guid with
    | Some obj ->
        let open Yojson.Safe.Util in
        (try ({ conn = t.conn; guid = member "debugger" obj.initializer_ |> member "guid" |> to_string } : debugger_type obj)
         with _ -> failwith "Missing required initializer property debugger")
    | None -> failwith "Object not found in connection"

  let request_context (t : t) =
    match Hashtbl.find_opt t.conn.objects t.guid with
    | Some obj ->
        let open Yojson.Safe.Util in
        (try ({ conn = t.conn; guid = member "requestContext" obj.initializer_ |> member "guid" |> to_string } : api_request_context_type obj)
         with _ -> failwith "Missing required initializer property requestContext")
    | None -> failwith "Object not found in connection"

  let tracing (t : t) =
    match Hashtbl.find_opt t.conn.objects t.guid with
    | Some obj ->
        let open Yojson.Safe.Util in
        (try ({ conn = t.conn; guid = member "tracing" obj.initializer_ |> member "guid" |> to_string } : tracing_type obj)
         with _ -> failwith "Missing required initializer property tracing")
    | None -> failwith "Object not found in connection"

  let add_cookies ~cookies (t : t) () =
    let args : Protocol.browser_context_add_cookies_args = {
      Protocol.browser_context_add_cookies_args_cookies = cookies;
    } in
    match Api.Browser_context.add_cookies t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let add_init_script ~source (t : t) () =
    let args : Protocol.browser_context_add_init_script_args = {
      Protocol.browser_context_add_init_script_args_source = source;
    } in
    match Api.Browser_context.add_init_script t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.browser_context_add_init_script_returns_disposable.guid } : disposable_type obj)
    | Error e -> raise (Error e)

  let clear_cookies ?path_regex_flags ?path_regex_source ?path ?domain_regex_flags ?domain_regex_source ?domain ?name_regex_flags ?name_regex_source ?name (t : t) () =
    let args : Protocol.browser_context_clear_cookies_args = {
      Protocol.browser_context_clear_cookies_args_path_regex_flags = path_regex_flags;
      Protocol.browser_context_clear_cookies_args_path_regex_source = path_regex_source;
      Protocol.browser_context_clear_cookies_args_path = path;
      Protocol.browser_context_clear_cookies_args_domain_regex_flags = domain_regex_flags;
      Protocol.browser_context_clear_cookies_args_domain_regex_source = domain_regex_source;
      Protocol.browser_context_clear_cookies_args_domain = domain;
      Protocol.browser_context_clear_cookies_args_name_regex_flags = name_regex_flags;
      Protocol.browser_context_clear_cookies_args_name_regex_source = name_regex_source;
      Protocol.browser_context_clear_cookies_args_name = name;
    } in
    match Api.Browser_context.clear_cookies t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let clear_permissions (t : t) () =
    match Api.Browser_context.clear_permissions t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let close ?reason (t : t) () =
    let args : Protocol.browser_context_close_args = {
      Protocol.browser_context_close_args_reason = reason;
    } in
    match Api.Browser_context.close t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let cookies ~urls (t : t) () =
    let args : Protocol.browser_context_cookies_args = {
      Protocol.browser_context_cookies_args_urls = urls;
    } in
    match Api.Browser_context.cookies t.conn t.guid args with
    | Ok res -> res.Protocol.browser_context_cookies_returns_cookies
    | Error e -> raise (Error e)

  let expose_binding ~name (t : t) () =
    let args : Protocol.browser_context_expose_binding_args = {
      Protocol.browser_context_expose_binding_args_name = name;
    } in
    match Api.Browser_context.expose_binding t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.browser_context_expose_binding_returns_disposable.guid } : disposable_type obj)
    | Error e -> raise (Error e)

  let grant_permissions ?origin ~permissions (t : t) () =
    let args : Protocol.browser_context_grant_permissions_args = {
      Protocol.browser_context_grant_permissions_args_origin = origin;
      Protocol.browser_context_grant_permissions_args_permissions = permissions;
    } in
    match Api.Browser_context.grant_permissions t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let new_page (t : t) () =
    match Api.Browser_context.new_page t.conn t.guid () with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.browser_context_new_page_returns_page.guid } : page_type obj)
    | Error e -> raise (Error e)

  let register_selector_engine ~selector_engine (t : t) () =
    let args : Protocol.browser_context_register_selector_engine_args = {
      Protocol.browser_context_register_selector_engine_args_selector_engine = selector_engine;
    } in
    match Api.Browser_context.register_selector_engine t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_test_id_attribute_name ~test_id_attribute_name (t : t) () =
    let args : Protocol.browser_context_set_test_id_attribute_name_args = {
      Protocol.browser_context_set_test_id_attribute_name_args_test_id_attribute_name = test_id_attribute_name;
    } in
    match Api.Browser_context.set_test_id_attribute_name t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_extra_http_headers ~headers (t : t) () =
    let args : Protocol.browser_context_set_extra_http_headers_args = {
      Protocol.browser_context_set_extra_http_headers_args_headers = headers;
    } in
    match Api.Browser_context.set_extra_http_headers t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_geolocation ?geolocation (t : t) () =
    let args : Protocol.browser_context_set_geolocation_args = {
      Protocol.browser_context_set_geolocation_args_geolocation = geolocation;
    } in
    match Api.Browser_context.set_geolocation t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_http_credentials ?http_credentials (t : t) () =
    let args : Protocol.browser_context_set_http_credentials_args = {
      Protocol.browser_context_set_http_credentials_args_http_credentials = http_credentials;
    } in
    match Api.Browser_context.set_http_credentials t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_network_interception_patterns ~patterns (t : t) () =
    let args : Protocol.browser_context_set_network_interception_patterns_args = {
      Protocol.browser_context_set_network_interception_patterns_args_patterns = patterns;
    } in
    match Api.Browser_context.set_network_interception_patterns t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_web_socket_interception_patterns ~patterns (t : t) () =
    let args : Protocol.browser_context_set_web_socket_interception_patterns_args = {
      Protocol.browser_context_set_web_socket_interception_patterns_args_patterns = patterns;
    } in
    match Api.Browser_context.set_web_socket_interception_patterns t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_offline ~offline (t : t) () =
    let args : Protocol.browser_context_set_offline_args = {
      Protocol.browser_context_set_offline_args_offline = offline;
    } in
    match Api.Browser_context.set_offline t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let storage_state ?indexed_db (t : t) () =
    let args : Protocol.browser_context_storage_state_args = {
      Protocol.browser_context_storage_state_args_indexed_db = indexed_db;
    } in
    match Api.Browser_context.storage_state t.conn t.guid args with
    | Ok res -> res
    | Error e -> raise (Error e)

  let set_storage_state ?storage_state (t : t) () =
    let args : Protocol.browser_context_set_storage_state_args = {
      Protocol.browser_context_set_storage_state_args_storage_state = storage_state;
    } in
    match Api.Browser_context.set_storage_state t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let pause (t : t) () =
    match Api.Browser_context.pause t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let enable_recorder ?omit_call_tracking ?handle_sigint ?output_file ?save_storage ?device ?context_options ?launch_options ?test_id_attribute_name ?pause_on_next_statement ?recorder_mode ?mode ?language (t : t) () =
    let args : Protocol.browser_context_enable_recorder_args = {
      Protocol.browser_context_enable_recorder_args_omit_call_tracking = omit_call_tracking;
      Protocol.browser_context_enable_recorder_args_handle_sigint = handle_sigint;
      Protocol.browser_context_enable_recorder_args_output_file = output_file;
      Protocol.browser_context_enable_recorder_args_save_storage = save_storage;
      Protocol.browser_context_enable_recorder_args_device = device;
      Protocol.browser_context_enable_recorder_args_context_options = context_options;
      Protocol.browser_context_enable_recorder_args_launch_options = launch_options;
      Protocol.browser_context_enable_recorder_args_test_id_attribute_name = test_id_attribute_name;
      Protocol.browser_context_enable_recorder_args_pause_on_next_statement = pause_on_next_statement;
      Protocol.browser_context_enable_recorder_args_recorder_mode = recorder_mode;
      Protocol.browser_context_enable_recorder_args_mode = mode;
      Protocol.browser_context_enable_recorder_args_language = language;
    } in
    match Api.Browser_context.enable_recorder t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let disable_recorder (t : t) () =
    match Api.Browser_context.disable_recorder t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let expose_console_api (t : t) () =
    match Api.Browser_context.expose_console_api t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let new_cdp_session ?frame ?page (t : t) () =
    let args : Protocol.browser_context_new_cdp_session_args = {
      Protocol.browser_context_new_cdp_session_args_frame = frame;
      Protocol.browser_context_new_cdp_session_args_page = page;
    } in
    match Api.Browser_context.new_cdp_session t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.browser_context_new_cdp_session_returns_session.guid } : cdp_session_type obj)
    | Error e -> raise (Error e)

  let create_temp_files ~items ?root_dir_name (t : t) () =
    let args : Protocol.browser_context_create_temp_files_args = {
      Protocol.browser_context_create_temp_files_args_items = items;
      Protocol.browser_context_create_temp_files_args_root_dir_name = root_dir_name;
    } in
    match Api.Browser_context.create_temp_files t.conn t.guid args with
    | Ok res -> res
    | Error e -> raise (Error e)

  let update_subscription ~enabled ~event (t : t) () =
    let args : Protocol.browser_context_update_subscription_args = {
      Protocol.browser_context_update_subscription_args_enabled = enabled;
      Protocol.browser_context_update_subscription_args_event = event;
    } in
    match Api.Browser_context.update_subscription t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let clock_fast_forward ?ticks_string ?ticks_number (t : t) () =
    let args : Protocol.browser_context_clock_fast_forward_args = {
      Protocol.browser_context_clock_fast_forward_args_ticks_string = ticks_string;
      Protocol.browser_context_clock_fast_forward_args_ticks_number = ticks_number;
    } in
    match Api.Browser_context.clock_fast_forward t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let clock_install ?time_string ?time_number (t : t) () =
    let args : Protocol.browser_context_clock_install_args = {
      Protocol.browser_context_clock_install_args_time_string = time_string;
      Protocol.browser_context_clock_install_args_time_number = time_number;
    } in
    match Api.Browser_context.clock_install t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let clock_pause_at ?time_string ?time_number (t : t) () =
    let args : Protocol.browser_context_clock_pause_at_args = {
      Protocol.browser_context_clock_pause_at_args_time_string = time_string;
      Protocol.browser_context_clock_pause_at_args_time_number = time_number;
    } in
    match Api.Browser_context.clock_pause_at t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let clock_resume (t : t) () =
    match Api.Browser_context.clock_resume t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let clock_run_for ?ticks_string ?ticks_number (t : t) () =
    let args : Protocol.browser_context_clock_run_for_args = {
      Protocol.browser_context_clock_run_for_args_ticks_string = ticks_string;
      Protocol.browser_context_clock_run_for_args_ticks_number = ticks_number;
    } in
    match Api.Browser_context.clock_run_for t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let clock_set_fixed_time ?time_string ?time_number (t : t) () =
    let args : Protocol.browser_context_clock_set_fixed_time_args = {
      Protocol.browser_context_clock_set_fixed_time_args_time_string = time_string;
      Protocol.browser_context_clock_set_fixed_time_args_time_number = time_number;
    } in
    match Api.Browser_context.clock_set_fixed_time t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let clock_set_system_time ?time_string ?time_number (t : t) () =
    let args : Protocol.browser_context_clock_set_system_time_args = {
      Protocol.browser_context_clock_set_system_time_args_time_string = time_string;
      Protocol.browser_context_clock_set_system_time_args_time_number = time_number;
    } in
    match Api.Browser_context.clock_set_system_time t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let on_binding_call (t : t) cb =
    Connection.on t.conn t.guid "bindingCall" (fun msg ->
      match Protocol.browser_context_binding_call_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_console (t : t) cb =
    Connection.on t.conn t.guid "console" (fun msg ->
      match Protocol.browser_context_console_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_dialog (t : t) cb =
    Connection.on t.conn t.guid "dialog" (fun msg ->
      match Protocol.browser_context_dialog_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_page (t : t) cb =
    Connection.on t.conn t.guid "page" (fun msg ->
      match Protocol.browser_context_page_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_page_error (t : t) cb =
    Connection.on t.conn t.guid "pageError" (fun msg ->
      match Protocol.browser_context_page_error_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_route (t : t) cb =
    Connection.on t.conn t.guid "route" (fun msg ->
      match Protocol.browser_context_route_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_web_socket_route (t : t) cb =
    Connection.on t.conn t.guid "webSocketRoute" (fun msg ->
      match Protocol.browser_context_web_socket_route_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_service_worker (t : t) cb =
    Connection.on t.conn t.guid "serviceWorker" (fun msg ->
      match Protocol.browser_context_service_worker_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_request (t : t) cb =
    Connection.on t.conn t.guid "request" (fun msg ->
      match Protocol.browser_context_request_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_request_failed (t : t) cb =
    Connection.on t.conn t.guid "requestFailed" (fun msg ->
      match Protocol.browser_context_request_failed_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_request_finished (t : t) cb =
    Connection.on t.conn t.guid "requestFinished" (fun msg ->
      match Protocol.browser_context_request_finished_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_response (t : t) cb =
    Connection.on t.conn t.guid "response" (fun msg ->
      match Protocol.browser_context_response_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_recorder_event (t : t) cb =
    Connection.on t.conn t.guid "recorderEvent" (fun msg ->
      match Protocol.browser_context_recorder_event_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

end

module Page = struct
  type t = page_type obj

  let main_frame (t : t) =
    match Hashtbl.find_opt t.conn.objects t.guid with
    | Some obj ->
        let open Yojson.Safe.Util in
        (try ({ conn = t.conn; guid = member "mainFrame" obj.initializer_ |> member "guid" |> to_string } : frame_type obj)
         with _ -> failwith "Missing required initializer property mainFrame")
    | None -> failwith "Object not found in connection"

  let opener (t : t) =
    match Hashtbl.find_opt t.conn.objects t.guid with
    | Some obj ->
        let open Yojson.Safe.Util in
        (try Some ({ conn = t.conn; guid = member "opener" obj.initializer_ |> member "guid" |> to_string } : page_type obj)
         with _ -> None)
    | None -> failwith "Object not found in connection"

  let video (t : t) =
    match Hashtbl.find_opt t.conn.objects t.guid with
    | Some obj ->
        let open Yojson.Safe.Util in
        (try Some ({ conn = t.conn; guid = member "video" obj.initializer_ |> member "guid" |> to_string } : artifact_type obj)
         with _ -> None)
    | None -> failwith "Object not found in connection"

  let add_init_script ~source (t : t) () =
    let args : Protocol.page_add_init_script_args = {
      Protocol.page_add_init_script_args_source = source;
    } in
    match Api.Page.add_init_script t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.page_add_init_script_returns_disposable.guid } : disposable_type obj)
    | Error e -> raise (Error e)

  let close ?reason ?run_before_unload (t : t) () =
    let args : Protocol.page_close_args = {
      Protocol.page_close_args_reason = reason;
      Protocol.page_close_args_run_before_unload = run_before_unload;
    } in
    match Api.Page.close t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let clear_console_messages (t : t) () =
    match Api.Page.clear_console_messages t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let console_messages ?filter (t : t) () =
    let args : Protocol.page_console_messages_args = {
      Protocol.page_console_messages_args_filter = filter;
    } in
    match Api.Page.console_messages t.conn t.guid args with
    | Ok res -> res.Protocol.page_console_messages_returns_messages
    | Error e -> raise (Error e)

  let emulate_media ?contrast ?forced_colors ?reduced_motion ?color_scheme ?media (t : t) () =
    let args : Protocol.page_emulate_media_args = {
      Protocol.page_emulate_media_args_contrast = contrast;
      Protocol.page_emulate_media_args_forced_colors = forced_colors;
      Protocol.page_emulate_media_args_reduced_motion = reduced_motion;
      Protocol.page_emulate_media_args_color_scheme = color_scheme;
      Protocol.page_emulate_media_args_media = media;
    } in
    match Api.Page.emulate_media t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let expose_binding ~name (t : t) () =
    let args : Protocol.page_expose_binding_args = {
      Protocol.page_expose_binding_args_name = name;
    } in
    match Api.Page.expose_binding t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.page_expose_binding_returns_disposable.guid } : disposable_type obj)
    | Error e -> raise (Error e)

  let go_back ?wait_until ~timeout (t : t) () =
    let args : Protocol.page_go_back_args = {
      Protocol.page_go_back_args_wait_until = wait_until;
      Protocol.page_go_back_args_timeout = timeout;
    } in
    match Api.Page.go_back t.conn t.guid args with
    | Ok res -> res.Protocol.page_go_back_returns_response
    | Error e -> raise (Error e)

  let go_forward ?wait_until ~timeout (t : t) () =
    let args : Protocol.page_go_forward_args = {
      Protocol.page_go_forward_args_wait_until = wait_until;
      Protocol.page_go_forward_args_timeout = timeout;
    } in
    match Api.Page.go_forward t.conn t.guid args with
    | Ok res -> res.Protocol.page_go_forward_returns_response
    | Error e -> raise (Error e)

  let request_gc (t : t) () =
    match Api.Page.request_gc t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let register_locator_handler ?no_wait_after ~selector (t : t) () =
    let args : Protocol.page_register_locator_handler_args = {
      Protocol.page_register_locator_handler_args_no_wait_after = no_wait_after;
      Protocol.page_register_locator_handler_args_selector = selector;
    } in
    match Api.Page.register_locator_handler t.conn t.guid args with
    | Ok res -> res.Protocol.page_register_locator_handler_returns_uid
    | Error e -> raise (Error e)

  let resolve_locator_handler_no_reply ?remove ~uid (t : t) () =
    let args : Protocol.page_resolve_locator_handler_no_reply_args = {
      Protocol.page_resolve_locator_handler_no_reply_args_remove = remove;
      Protocol.page_resolve_locator_handler_no_reply_args_uid = uid;
    } in
    match Api.Page.resolve_locator_handler_no_reply t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let unregister_locator_handler ~uid (t : t) () =
    let args : Protocol.page_unregister_locator_handler_args = {
      Protocol.page_unregister_locator_handler_args_uid = uid;
    } in
    match Api.Page.unregister_locator_handler t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let reload ?wait_until ~timeout (t : t) () =
    let args : Protocol.page_reload_args = {
      Protocol.page_reload_args_wait_until = wait_until;
      Protocol.page_reload_args_timeout = timeout;
    } in
    match Api.Page.reload t.conn t.guid args with
    | Ok res -> res.Protocol.page_reload_returns_response
    | Error e -> raise (Error e)

  let expect_screenshot ?style ?mask_color ?mask ?scale ?animations ?caret ?omit_background ?clip ?full_page ?threshold ?max_diff_pixel_ratio ?max_diff_pixels ?comparator ?locator ~is_not ~timeout ?expected (t : t) () =
    let args : Protocol.page_expect_screenshot_args = {
      Protocol.page_expect_screenshot_args_style = style;
      Protocol.page_expect_screenshot_args_mask_color = mask_color;
      Protocol.page_expect_screenshot_args_mask = mask;
      Protocol.page_expect_screenshot_args_scale = scale;
      Protocol.page_expect_screenshot_args_animations = animations;
      Protocol.page_expect_screenshot_args_caret = caret;
      Protocol.page_expect_screenshot_args_omit_background = omit_background;
      Protocol.page_expect_screenshot_args_clip = clip;
      Protocol.page_expect_screenshot_args_full_page = full_page;
      Protocol.page_expect_screenshot_args_threshold = threshold;
      Protocol.page_expect_screenshot_args_max_diff_pixel_ratio = max_diff_pixel_ratio;
      Protocol.page_expect_screenshot_args_max_diff_pixels = max_diff_pixels;
      Protocol.page_expect_screenshot_args_comparator = comparator;
      Protocol.page_expect_screenshot_args_locator = locator;
      Protocol.page_expect_screenshot_args_is_not = is_not;
      Protocol.page_expect_screenshot_args_timeout = timeout;
      Protocol.page_expect_screenshot_args_expected = expected;
    } in
    match Api.Page.expect_screenshot t.conn t.guid args with
    | Ok res -> res
    | Error e -> raise (Error e)

  let screenshot ?style ?mask_color ?mask ?scale ?animations ?caret ?omit_background ?clip ?full_page ?quality ?type_ ~timeout (t : t) () =
    let args : Protocol.page_screenshot_args = {
      Protocol.page_screenshot_args_style = style;
      Protocol.page_screenshot_args_mask_color = mask_color;
      Protocol.page_screenshot_args_mask = mask;
      Protocol.page_screenshot_args_scale = scale;
      Protocol.page_screenshot_args_animations = animations;
      Protocol.page_screenshot_args_caret = caret;
      Protocol.page_screenshot_args_omit_background = omit_background;
      Protocol.page_screenshot_args_clip = clip;
      Protocol.page_screenshot_args_full_page = full_page;
      Protocol.page_screenshot_args_quality = quality;
      Protocol.page_screenshot_args_type_ = type_;
      Protocol.page_screenshot_args_timeout = timeout;
    } in
    match Api.Page.screenshot t.conn t.guid args with
    | Ok res -> res.Protocol.page_screenshot_returns_binary
    | Error e -> raise (Error e)

  let set_extra_http_headers ~headers (t : t) () =
    let args : Protocol.page_set_extra_http_headers_args = {
      Protocol.page_set_extra_http_headers_args_headers = headers;
    } in
    match Api.Page.set_extra_http_headers t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_network_interception_patterns ~patterns (t : t) () =
    let args : Protocol.page_set_network_interception_patterns_args = {
      Protocol.page_set_network_interception_patterns_args_patterns = patterns;
    } in
    match Api.Page.set_network_interception_patterns t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_web_socket_interception_patterns ~patterns (t : t) () =
    let args : Protocol.page_set_web_socket_interception_patterns_args = {
      Protocol.page_set_web_socket_interception_patterns_args_patterns = patterns;
    } in
    match Api.Page.set_web_socket_interception_patterns t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_viewport_size ~viewport_size (t : t) () =
    let args : Protocol.page_set_viewport_size_args = {
      Protocol.page_set_viewport_size_args_viewport_size = viewport_size;
    } in
    match Api.Page.set_viewport_size t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let keyboard_down ~key (t : t) () =
    let args : Protocol.page_keyboard_down_args = {
      Protocol.page_keyboard_down_args_key = key;
    } in
    match Api.Page.keyboard_down t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let keyboard_up ~key (t : t) () =
    let args : Protocol.page_keyboard_up_args = {
      Protocol.page_keyboard_up_args_key = key;
    } in
    match Api.Page.keyboard_up t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let keyboard_insert_text ~text (t : t) () =
    let args : Protocol.page_keyboard_insert_text_args = {
      Protocol.page_keyboard_insert_text_args_text = text;
    } in
    match Api.Page.keyboard_insert_text t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let keyboard_type ?delay ~text (t : t) () =
    let args : Protocol.page_keyboard_type_args = {
      Protocol.page_keyboard_type_args_delay = delay;
      Protocol.page_keyboard_type_args_text = text;
    } in
    match Api.Page.keyboard_type t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let keyboard_press ?delay ~key (t : t) () =
    let args : Protocol.page_keyboard_press_args = {
      Protocol.page_keyboard_press_args_delay = delay;
      Protocol.page_keyboard_press_args_key = key;
    } in
    match Api.Page.keyboard_press t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let mouse_move ?steps ~y ~x (t : t) () =
    let args : Protocol.page_mouse_move_args = {
      Protocol.page_mouse_move_args_steps = steps;
      Protocol.page_mouse_move_args_y = y;
      Protocol.page_mouse_move_args_x = x;
    } in
    match Api.Page.mouse_move t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let mouse_down ?click_count ?button (t : t) () =
    let args : Protocol.page_mouse_down_args = {
      Protocol.page_mouse_down_args_click_count = click_count;
      Protocol.page_mouse_down_args_button = button;
    } in
    match Api.Page.mouse_down t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let mouse_up ?click_count ?button (t : t) () =
    let args : Protocol.page_mouse_up_args = {
      Protocol.page_mouse_up_args_click_count = click_count;
      Protocol.page_mouse_up_args_button = button;
    } in
    match Api.Page.mouse_up t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let mouse_click ?click_count ?button ?delay ~y ~x (t : t) () =
    let args : Protocol.page_mouse_click_args = {
      Protocol.page_mouse_click_args_click_count = click_count;
      Protocol.page_mouse_click_args_button = button;
      Protocol.page_mouse_click_args_delay = delay;
      Protocol.page_mouse_click_args_y = y;
      Protocol.page_mouse_click_args_x = x;
    } in
    match Api.Page.mouse_click t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let mouse_wheel ~delta_y ~delta_x (t : t) () =
    let args : Protocol.page_mouse_wheel_args = {
      Protocol.page_mouse_wheel_args_delta_y = delta_y;
      Protocol.page_mouse_wheel_args_delta_x = delta_x;
    } in
    match Api.Page.mouse_wheel t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let touchscreen_tap ~y ~x (t : t) () =
    let args : Protocol.page_touchscreen_tap_args = {
      Protocol.page_touchscreen_tap_args_y = y;
      Protocol.page_touchscreen_tap_args_x = x;
    } in
    match Api.Page.touchscreen_tap t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let clear_page_errors (t : t) () =
    match Api.Page.clear_page_errors t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let page_errors ?filter (t : t) () =
    let args : Protocol.page_page_errors_args = {
      Protocol.page_page_errors_args_filter = filter;
    } in
    match Api.Page.page_errors t.conn t.guid args with
    | Ok res -> res.Protocol.page_page_errors_returns_errors
    | Error e -> raise (Error e)

  let pdf ?outline ?tagged ?margin ?prefer_css_page_size ?height ?width ?format ?page_ranges ?landscape ?print_background ?footer_template ?header_template ?display_header_footer ?scale (t : t) () =
    let args : Protocol.page_pdf_args = {
      Protocol.page_pdf_args_outline = outline;
      Protocol.page_pdf_args_tagged = tagged;
      Protocol.page_pdf_args_margin = margin;
      Protocol.page_pdf_args_prefer_css_page_size = prefer_css_page_size;
      Protocol.page_pdf_args_height = height;
      Protocol.page_pdf_args_width = width;
      Protocol.page_pdf_args_format = format;
      Protocol.page_pdf_args_page_ranges = page_ranges;
      Protocol.page_pdf_args_landscape = landscape;
      Protocol.page_pdf_args_print_background = print_background;
      Protocol.page_pdf_args_footer_template = footer_template;
      Protocol.page_pdf_args_header_template = header_template;
      Protocol.page_pdf_args_display_header_footer = display_header_footer;
      Protocol.page_pdf_args_scale = scale;
    } in
    match Api.Page.pdf t.conn t.guid args with
    | Ok res -> res.Protocol.page_pdf_returns_pdf
    | Error e -> raise (Error e)

  let requests (t : t) () =
    match Api.Page.requests t.conn t.guid () with
    | Ok res -> res.Protocol.page_requests_returns_requests
    | Error e -> raise (Error e)

  let start_js_coverage ?report_anonymous_scripts ?reset_on_navigation (t : t) () =
    let args : Protocol.page_start_js_coverage_args = {
      Protocol.page_start_js_coverage_args_report_anonymous_scripts = report_anonymous_scripts;
      Protocol.page_start_js_coverage_args_reset_on_navigation = reset_on_navigation;
    } in
    match Api.Page.start_js_coverage t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let stop_js_coverage (t : t) () =
    match Api.Page.stop_js_coverage t.conn t.guid () with
    | Ok res -> res.Protocol.page_stop_js_coverage_returns_entries
    | Error e -> raise (Error e)

  let start_css_coverage ?reset_on_navigation (t : t) () =
    let args : Protocol.page_start_css_coverage_args = {
      Protocol.page_start_css_coverage_args_reset_on_navigation = reset_on_navigation;
    } in
    match Api.Page.start_css_coverage t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let stop_css_coverage (t : t) () =
    match Api.Page.stop_css_coverage t.conn t.guid () with
    | Ok res -> res.Protocol.page_stop_css_coverage_returns_entries
    | Error e -> raise (Error e)

  let bring_to_front (t : t) () =
    match Api.Page.bring_to_front t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let pick_locator (t : t) () =
    match Api.Page.pick_locator t.conn t.guid () with
    | Ok res -> res.Protocol.page_pick_locator_returns_selector
    | Error e -> raise (Error e)

  let cancel_pick_locator (t : t) () =
    match Api.Page.cancel_pick_locator t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let hide_highlight (t : t) () =
    match Api.Page.hide_highlight t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let screencast_show_overlay ?duration ~html (t : t) () =
    let args : Protocol.page_screencast_show_overlay_args = {
      Protocol.page_screencast_show_overlay_args_duration = duration;
      Protocol.page_screencast_show_overlay_args_html = html;
    } in
    match Api.Page.screencast_show_overlay t.conn t.guid args with
    | Ok res -> res.Protocol.page_screencast_show_overlay_returns_id
    | Error e -> raise (Error e)

  let screencast_remove_overlay ~id (t : t) () =
    let args : Protocol.page_screencast_remove_overlay_args = {
      Protocol.page_screencast_remove_overlay_args_id = id;
    } in
    match Api.Page.screencast_remove_overlay t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let screencast_chapter ?duration ?description ~title (t : t) () =
    let args : Protocol.page_screencast_chapter_args = {
      Protocol.page_screencast_chapter_args_duration = duration;
      Protocol.page_screencast_chapter_args_description = description;
      Protocol.page_screencast_chapter_args_title = title;
    } in
    match Api.Page.screencast_chapter t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let screencast_set_overlay_visible ~visible (t : t) () =
    let args : Protocol.page_screencast_set_overlay_visible_args = {
      Protocol.page_screencast_set_overlay_visible_args_visible = visible;
    } in
    match Api.Page.screencast_set_overlay_visible t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let screencast_show_actions ?font_size ?position ?duration (t : t) () =
    let args : Protocol.page_screencast_show_actions_args = {
      Protocol.page_screencast_show_actions_args_font_size = font_size;
      Protocol.page_screencast_show_actions_args_position = position;
      Protocol.page_screencast_show_actions_args_duration = duration;
    } in
    match Api.Page.screencast_show_actions t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let screencast_hide_actions (t : t) () =
    match Api.Page.screencast_hide_actions t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let screencast_start ?record ?send_frames ?quality ?size (t : t) () =
    let args : Protocol.page_screencast_start_args = {
      Protocol.page_screencast_start_args_record = record;
      Protocol.page_screencast_start_args_send_frames = send_frames;
      Protocol.page_screencast_start_args_quality = quality;
      Protocol.page_screencast_start_args_size = size;
    } in
    match Api.Page.screencast_start t.conn t.guid args with
    | Ok res -> res.Protocol.page_screencast_start_returns_artifact
    | Error e -> raise (Error e)

  let screencast_stop (t : t) () =
    match Api.Page.screencast_stop t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let update_subscription ~enabled ~event (t : t) () =
    let args : Protocol.page_update_subscription_args = {
      Protocol.page_update_subscription_args_enabled = enabled;
      Protocol.page_update_subscription_args_event = event;
    } in
    match Api.Page.update_subscription t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_dock_tile ~image (t : t) () =
    let args : Protocol.page_set_dock_tile_args = {
      Protocol.page_set_dock_tile_args_image = image;
    } in
    match Api.Page.set_dock_tile t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let on_binding_call (t : t) cb =
    Connection.on t.conn t.guid "bindingCall" (fun msg ->
      match Protocol.page_binding_call_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_download (t : t) cb =
    Connection.on t.conn t.guid "download" (fun msg ->
      match Protocol.page_download_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_viewport_size_changed (t : t) cb =
    Connection.on t.conn t.guid "viewportSizeChanged" (fun msg ->
      match Protocol.page_viewport_size_changed_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_file_chooser (t : t) cb =
    Connection.on t.conn t.guid "fileChooser" (fun msg ->
      match Protocol.page_file_chooser_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_frame_attached (t : t) cb =
    Connection.on t.conn t.guid "frameAttached" (fun msg ->
      match Protocol.page_frame_attached_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_frame_detached (t : t) cb =
    Connection.on t.conn t.guid "frameDetached" (fun msg ->
      match Protocol.page_frame_detached_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_locator_handler_triggered (t : t) cb =
    Connection.on t.conn t.guid "locatorHandlerTriggered" (fun msg ->
      match Protocol.page_locator_handler_triggered_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_route (t : t) cb =
    Connection.on t.conn t.guid "route" (fun msg ->
      match Protocol.page_route_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_screencast_frame (t : t) cb =
    Connection.on t.conn t.guid "screencastFrame" (fun msg ->
      match Protocol.page_screencast_frame_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_web_socket_route (t : t) cb =
    Connection.on t.conn t.guid "webSocketRoute" (fun msg ->
      match Protocol.page_web_socket_route_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_web_socket (t : t) cb =
    Connection.on t.conn t.guid "webSocket" (fun msg ->
      match Protocol.page_web_socket_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_worker (t : t) cb =
    Connection.on t.conn t.guid "worker" (fun msg ->
      match Protocol.page_worker_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

end

module Frame = struct
  type t = frame_type obj

  let parent_frame (t : t) =
    match Hashtbl.find_opt t.conn.objects t.guid with
    | Some obj ->
        let open Yojson.Safe.Util in
        (try Some ({ conn = t.conn; guid = member "parentFrame" obj.initializer_ |> member "guid" |> to_string } : frame_type obj)
         with _ -> None)
    | None -> failwith "Object not found in connection"

  let eval_on_selector ~arg ?is_function ~expression ?strict ~selector (t : t) () =
    let args : Protocol.frame_eval_on_selector_args = {
      Protocol.frame_eval_on_selector_args_arg = arg;
      Protocol.frame_eval_on_selector_args_is_function = is_function;
      Protocol.frame_eval_on_selector_args_expression = expression;
      Protocol.frame_eval_on_selector_args_strict = strict;
      Protocol.frame_eval_on_selector_args_selector = selector;
    } in
    match Api.Frame.eval_on_selector t.conn t.guid args with
    | Ok res -> res.Protocol.frame_eval_on_selector_returns_value
    | Error e -> raise (Error e)

  let eval_on_selector_all ~arg ?is_function ~expression ~selector (t : t) () =
    let args : Protocol.frame_eval_on_selector_all_args = {
      Protocol.frame_eval_on_selector_all_args_arg = arg;
      Protocol.frame_eval_on_selector_all_args_is_function = is_function;
      Protocol.frame_eval_on_selector_all_args_expression = expression;
      Protocol.frame_eval_on_selector_all_args_selector = selector;
    } in
    match Api.Frame.eval_on_selector_all t.conn t.guid args with
    | Ok res -> res.Protocol.frame_eval_on_selector_all_returns_value
    | Error e -> raise (Error e)

  let add_script_tag ?type_ ?content ?url (t : t) () =
    let args : Protocol.frame_add_script_tag_args = {
      Protocol.frame_add_script_tag_args_type_ = type_;
      Protocol.frame_add_script_tag_args_content = content;
      Protocol.frame_add_script_tag_args_url = url;
    } in
    match Api.Frame.add_script_tag t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.frame_add_script_tag_returns_element.guid } : element_handle_type obj)
    | Error e -> raise (Error e)

  let add_style_tag ?content ?url (t : t) () =
    let args : Protocol.frame_add_style_tag_args = {
      Protocol.frame_add_style_tag_args_content = content;
      Protocol.frame_add_style_tag_args_url = url;
    } in
    match Api.Frame.add_style_tag t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.frame_add_style_tag_returns_element.guid } : element_handle_type obj)
    | Error e -> raise (Error e)

  let aria_ref ~timeout ~selector (t : t) () =
    let args : Protocol.frame_aria_ref_args = {
      Protocol.frame_aria_ref_args_timeout = timeout;
      Protocol.frame_aria_ref_args_selector = selector;
    } in
    match Api.Frame.aria_ref t.conn t.guid args with
    | Ok res -> res.Protocol.frame_aria_ref_returns_ref
    | Error e -> raise (Error e)

  let aria_snapshot ~timeout ?boxes ?depth ?selector ?track ?mode (t : t) () =
    let args : Protocol.frame_aria_snapshot_args = {
      Protocol.frame_aria_snapshot_args_timeout = timeout;
      Protocol.frame_aria_snapshot_args_boxes = boxes;
      Protocol.frame_aria_snapshot_args_depth = depth;
      Protocol.frame_aria_snapshot_args_selector = selector;
      Protocol.frame_aria_snapshot_args_track = track;
      Protocol.frame_aria_snapshot_args_mode = mode;
    } in
    match Api.Frame.aria_snapshot t.conn t.guid args with
    | Ok res -> res.Protocol.frame_aria_snapshot_returns_snapshot
    | Error e -> raise (Error e)

  let blur ~timeout ?strict ~selector (t : t) () =
    let args : Protocol.frame_blur_args = {
      Protocol.frame_blur_args_timeout = timeout;
      Protocol.frame_blur_args_strict = strict;
      Protocol.frame_blur_args_selector = selector;
    } in
    match Api.Frame.blur t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let check ?trial ~timeout ?position ?force ?strict ~selector (t : t) () =
    let args : Protocol.frame_check_args = {
      Protocol.frame_check_args_trial = trial;
      Protocol.frame_check_args_timeout = timeout;
      Protocol.frame_check_args_position = position;
      Protocol.frame_check_args_force = force;
      Protocol.frame_check_args_strict = strict;
      Protocol.frame_check_args_selector = selector;
    } in
    match Api.Frame.check t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let click ?steps ?trial ~timeout ?click_count ?button ?delay ?position ?modifiers ?no_wait_after ?force ?strict ~selector (t : t) () =
    let args : Protocol.frame_click_args = {
      Protocol.frame_click_args_steps = steps;
      Protocol.frame_click_args_trial = trial;
      Protocol.frame_click_args_timeout = timeout;
      Protocol.frame_click_args_click_count = click_count;
      Protocol.frame_click_args_button = button;
      Protocol.frame_click_args_delay = delay;
      Protocol.frame_click_args_position = position;
      Protocol.frame_click_args_modifiers = modifiers;
      Protocol.frame_click_args_no_wait_after = no_wait_after;
      Protocol.frame_click_args_force = force;
      Protocol.frame_click_args_strict = strict;
      Protocol.frame_click_args_selector = selector;
    } in
    match Api.Frame.click t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let content (t : t) () =
    match Api.Frame.content t.conn t.guid () with
    | Ok res -> res.Protocol.frame_content_returns_value
    | Error e -> raise (Error e)

  let drag_and_drop ?steps ?strict ?target_position ?source_position ?trial ~timeout ?force ~target ~source (t : t) () =
    let args : Protocol.frame_drag_and_drop_args = {
      Protocol.frame_drag_and_drop_args_steps = steps;
      Protocol.frame_drag_and_drop_args_strict = strict;
      Protocol.frame_drag_and_drop_args_target_position = target_position;
      Protocol.frame_drag_and_drop_args_source_position = source_position;
      Protocol.frame_drag_and_drop_args_trial = trial;
      Protocol.frame_drag_and_drop_args_timeout = timeout;
      Protocol.frame_drag_and_drop_args_force = force;
      Protocol.frame_drag_and_drop_args_target = target;
      Protocol.frame_drag_and_drop_args_source = source;
    } in
    match Api.Frame.drag_and_drop t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let drop ~timeout ?data ?streams ?local_paths ?payloads ?position ?strict ~selector (t : t) () =
    let args : Protocol.frame_drop_args = {
      Protocol.frame_drop_args_timeout = timeout;
      Protocol.frame_drop_args_data = data;
      Protocol.frame_drop_args_streams = streams;
      Protocol.frame_drop_args_local_paths = local_paths;
      Protocol.frame_drop_args_payloads = payloads;
      Protocol.frame_drop_args_position = position;
      Protocol.frame_drop_args_strict = strict;
      Protocol.frame_drop_args_selector = selector;
    } in
    match Api.Frame.drop t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let dblclick ?steps ?trial ~timeout ?button ?delay ?position ?modifiers ?force ?strict ~selector (t : t) () =
    let args : Protocol.frame_dblclick_args = {
      Protocol.frame_dblclick_args_steps = steps;
      Protocol.frame_dblclick_args_trial = trial;
      Protocol.frame_dblclick_args_timeout = timeout;
      Protocol.frame_dblclick_args_button = button;
      Protocol.frame_dblclick_args_delay = delay;
      Protocol.frame_dblclick_args_position = position;
      Protocol.frame_dblclick_args_modifiers = modifiers;
      Protocol.frame_dblclick_args_force = force;
      Protocol.frame_dblclick_args_strict = strict;
      Protocol.frame_dblclick_args_selector = selector;
    } in
    match Api.Frame.dblclick t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let dispatch_event ~timeout ~event_init ~type_ ?strict ~selector (t : t) () =
    let args : Protocol.frame_dispatch_event_args = {
      Protocol.frame_dispatch_event_args_timeout = timeout;
      Protocol.frame_dispatch_event_args_event_init = event_init;
      Protocol.frame_dispatch_event_args_type_ = type_;
      Protocol.frame_dispatch_event_args_strict = strict;
      Protocol.frame_dispatch_event_args_selector = selector;
    } in
    match Api.Frame.dispatch_event t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let evaluate_expression ~arg ?is_function ~expression (t : t) () =
    let args : Protocol.frame_evaluate_expression_args = {
      Protocol.frame_evaluate_expression_args_arg = arg;
      Protocol.frame_evaluate_expression_args_is_function = is_function;
      Protocol.frame_evaluate_expression_args_expression = expression;
    } in
    match Api.Frame.evaluate_expression t.conn t.guid args with
    | Ok res -> res.Protocol.frame_evaluate_expression_returns_value
    | Error e -> raise (Error e)

  let evaluate_expression_handle ~arg ?is_function ~expression (t : t) () =
    let args : Protocol.frame_evaluate_expression_handle_args = {
      Protocol.frame_evaluate_expression_handle_args_arg = arg;
      Protocol.frame_evaluate_expression_handle_args_is_function = is_function;
      Protocol.frame_evaluate_expression_handle_args_expression = expression;
    } in
    match Api.Frame.evaluate_expression_handle t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.frame_evaluate_expression_handle_returns_handle.guid } : js_handle_type obj)
    | Error e -> raise (Error e)

  let fill ~timeout ?force ~value ?strict ~selector (t : t) () =
    let args : Protocol.frame_fill_args = {
      Protocol.frame_fill_args_timeout = timeout;
      Protocol.frame_fill_args_force = force;
      Protocol.frame_fill_args_value = value;
      Protocol.frame_fill_args_strict = strict;
      Protocol.frame_fill_args_selector = selector;
    } in
    match Api.Frame.fill t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let focus ~timeout ?strict ~selector (t : t) () =
    let args : Protocol.frame_focus_args = {
      Protocol.frame_focus_args_timeout = timeout;
      Protocol.frame_focus_args_strict = strict;
      Protocol.frame_focus_args_selector = selector;
    } in
    match Api.Frame.focus t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let frame_element (t : t) () =
    match Api.Frame.frame_element t.conn t.guid () with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.frame_frame_element_returns_element.guid } : element_handle_type obj)
    | Error e -> raise (Error e)

  let resolve_selector ~selector (t : t) () =
    let args : Protocol.frame_resolve_selector_args = {
      Protocol.frame_resolve_selector_args_selector = selector;
    } in
    match Api.Frame.resolve_selector t.conn t.guid args with
    | Ok res -> res.Protocol.frame_resolve_selector_returns_resolved_selector
    | Error e -> raise (Error e)

  let highlight ?style ~selector (t : t) () =
    let args : Protocol.frame_highlight_args = {
      Protocol.frame_highlight_args_style = style;
      Protocol.frame_highlight_args_selector = selector;
    } in
    match Api.Frame.highlight t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let hide_highlight ~selector (t : t) () =
    let args : Protocol.frame_hide_highlight_args = {
      Protocol.frame_hide_highlight_args_selector = selector;
    } in
    match Api.Frame.hide_highlight t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let get_attribute ~timeout ~name ?strict ~selector (t : t) () =
    let args : Protocol.frame_get_attribute_args = {
      Protocol.frame_get_attribute_args_timeout = timeout;
      Protocol.frame_get_attribute_args_name = name;
      Protocol.frame_get_attribute_args_strict = strict;
      Protocol.frame_get_attribute_args_selector = selector;
    } in
    match Api.Frame.get_attribute t.conn t.guid args with
    | Ok res -> res.Protocol.frame_get_attribute_returns_value
    | Error e -> raise (Error e)

  let goto ?referer ?wait_until ~timeout ~url (t : t) () =
    let args : Protocol.frame_goto_args = {
      Protocol.frame_goto_args_referer = referer;
      Protocol.frame_goto_args_wait_until = wait_until;
      Protocol.frame_goto_args_timeout = timeout;
      Protocol.frame_goto_args_url = url;
    } in
    match Api.Frame.goto t.conn t.guid args with
    | Ok res -> res.Protocol.frame_goto_returns_response
    | Error e -> raise (Error e)

  let hover ?trial ~timeout ?position ?modifiers ?force ?strict ~selector (t : t) () =
    let args : Protocol.frame_hover_args = {
      Protocol.frame_hover_args_trial = trial;
      Protocol.frame_hover_args_timeout = timeout;
      Protocol.frame_hover_args_position = position;
      Protocol.frame_hover_args_modifiers = modifiers;
      Protocol.frame_hover_args_force = force;
      Protocol.frame_hover_args_strict = strict;
      Protocol.frame_hover_args_selector = selector;
    } in
    match Api.Frame.hover t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let inner_html ~timeout ?strict ~selector (t : t) () =
    let args : Protocol.frame_inner_htm_l_args = {
      Protocol.frame_inner_htm_l_args_timeout = timeout;
      Protocol.frame_inner_htm_l_args_strict = strict;
      Protocol.frame_inner_htm_l_args_selector = selector;
    } in
    match Api.Frame.inner_html t.conn t.guid args with
    | Ok res -> res.Protocol.frame_inner_htm_l_returns_value
    | Error e -> raise (Error e)

  let inner_text ~timeout ?strict ~selector (t : t) () =
    let args : Protocol.frame_inner_text_args = {
      Protocol.frame_inner_text_args_timeout = timeout;
      Protocol.frame_inner_text_args_strict = strict;
      Protocol.frame_inner_text_args_selector = selector;
    } in
    match Api.Frame.inner_text t.conn t.guid args with
    | Ok res -> res.Protocol.frame_inner_text_returns_value
    | Error e -> raise (Error e)

  let input_value ~timeout ?strict ~selector (t : t) () =
    let args : Protocol.frame_input_value_args = {
      Protocol.frame_input_value_args_timeout = timeout;
      Protocol.frame_input_value_args_strict = strict;
      Protocol.frame_input_value_args_selector = selector;
    } in
    match Api.Frame.input_value t.conn t.guid args with
    | Ok res -> res.Protocol.frame_input_value_returns_value
    | Error e -> raise (Error e)

  let is_checked ~timeout ?strict ~selector (t : t) () =
    let args : Protocol.frame_is_checked_args = {
      Protocol.frame_is_checked_args_timeout = timeout;
      Protocol.frame_is_checked_args_strict = strict;
      Protocol.frame_is_checked_args_selector = selector;
    } in
    match Api.Frame.is_checked t.conn t.guid args with
    | Ok res -> res.Protocol.frame_is_checked_returns_value
    | Error e -> raise (Error e)

  let is_disabled ~timeout ?strict ~selector (t : t) () =
    let args : Protocol.frame_is_disabled_args = {
      Protocol.frame_is_disabled_args_timeout = timeout;
      Protocol.frame_is_disabled_args_strict = strict;
      Protocol.frame_is_disabled_args_selector = selector;
    } in
    match Api.Frame.is_disabled t.conn t.guid args with
    | Ok res -> res.Protocol.frame_is_disabled_returns_value
    | Error e -> raise (Error e)

  let is_enabled ~timeout ?strict ~selector (t : t) () =
    let args : Protocol.frame_is_enabled_args = {
      Protocol.frame_is_enabled_args_timeout = timeout;
      Protocol.frame_is_enabled_args_strict = strict;
      Protocol.frame_is_enabled_args_selector = selector;
    } in
    match Api.Frame.is_enabled t.conn t.guid args with
    | Ok res -> res.Protocol.frame_is_enabled_returns_value
    | Error e -> raise (Error e)

  let is_hidden ?strict ~selector (t : t) () =
    let args : Protocol.frame_is_hidden_args = {
      Protocol.frame_is_hidden_args_strict = strict;
      Protocol.frame_is_hidden_args_selector = selector;
    } in
    match Api.Frame.is_hidden t.conn t.guid args with
    | Ok res -> res.Protocol.frame_is_hidden_returns_value
    | Error e -> raise (Error e)

  let is_visible ?strict ~selector (t : t) () =
    let args : Protocol.frame_is_visible_args = {
      Protocol.frame_is_visible_args_strict = strict;
      Protocol.frame_is_visible_args_selector = selector;
    } in
    match Api.Frame.is_visible t.conn t.guid args with
    | Ok res -> res.Protocol.frame_is_visible_returns_value
    | Error e -> raise (Error e)

  let is_editable ~timeout ?strict ~selector (t : t) () =
    let args : Protocol.frame_is_editable_args = {
      Protocol.frame_is_editable_args_timeout = timeout;
      Protocol.frame_is_editable_args_strict = strict;
      Protocol.frame_is_editable_args_selector = selector;
    } in
    match Api.Frame.is_editable t.conn t.guid args with
    | Ok res -> res.Protocol.frame_is_editable_returns_value
    | Error e -> raise (Error e)

  let press ~timeout ?no_wait_after ?delay ~key ?strict ~selector (t : t) () =
    let args : Protocol.frame_press_args = {
      Protocol.frame_press_args_timeout = timeout;
      Protocol.frame_press_args_no_wait_after = no_wait_after;
      Protocol.frame_press_args_delay = delay;
      Protocol.frame_press_args_key = key;
      Protocol.frame_press_args_strict = strict;
      Protocol.frame_press_args_selector = selector;
    } in
    match Api.Frame.press t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let query_selector ?strict ~selector (t : t) () =
    let args : Protocol.frame_query_selector_args = {
      Protocol.frame_query_selector_args_strict = strict;
      Protocol.frame_query_selector_args_selector = selector;
    } in
    match Api.Frame.query_selector t.conn t.guid args with
    | Ok res -> res.Protocol.frame_query_selector_returns_element
    | Error e -> raise (Error e)

  let query_selector_all ~selector (t : t) () =
    let args : Protocol.frame_query_selector_all_args = {
      Protocol.frame_query_selector_all_args_selector = selector;
    } in
    match Api.Frame.query_selector_all t.conn t.guid args with
    | Ok res -> res.Protocol.frame_query_selector_all_returns_elements
    | Error e -> raise (Error e)

  let query_count ~selector (t : t) () =
    let args : Protocol.frame_query_count_args = {
      Protocol.frame_query_count_args_selector = selector;
    } in
    match Api.Frame.query_count t.conn t.guid args with
    | Ok res -> res.Protocol.frame_query_count_returns_value
    | Error e -> raise (Error e)

  let select_option ~timeout ?force ?options ?elements ?strict ~selector (t : t) () =
    let args : Protocol.frame_select_option_args = {
      Protocol.frame_select_option_args_timeout = timeout;
      Protocol.frame_select_option_args_force = force;
      Protocol.frame_select_option_args_options = options;
      Protocol.frame_select_option_args_elements = elements;
      Protocol.frame_select_option_args_strict = strict;
      Protocol.frame_select_option_args_selector = selector;
    } in
    match Api.Frame.select_option t.conn t.guid args with
    | Ok res -> res.Protocol.frame_select_option_returns_values
    | Error e -> raise (Error e)

  let set_content ?wait_until ~timeout ~html (t : t) () =
    let args : Protocol.frame_set_content_args = {
      Protocol.frame_set_content_args_wait_until = wait_until;
      Protocol.frame_set_content_args_timeout = timeout;
      Protocol.frame_set_content_args_html = html;
    } in
    match Api.Frame.set_content t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_input_files ~timeout ?streams ?local_paths ?directory_stream ?local_directory ?payloads ?strict ~selector (t : t) () =
    let args : Protocol.frame_set_input_files_args = {
      Protocol.frame_set_input_files_args_timeout = timeout;
      Protocol.frame_set_input_files_args_streams = streams;
      Protocol.frame_set_input_files_args_local_paths = local_paths;
      Protocol.frame_set_input_files_args_directory_stream = directory_stream;
      Protocol.frame_set_input_files_args_local_directory = local_directory;
      Protocol.frame_set_input_files_args_payloads = payloads;
      Protocol.frame_set_input_files_args_strict = strict;
      Protocol.frame_set_input_files_args_selector = selector;
    } in
    match Api.Frame.set_input_files t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let tap ?trial ~timeout ?position ?modifiers ?force ?strict ~selector (t : t) () =
    let args : Protocol.frame_tap_args = {
      Protocol.frame_tap_args_trial = trial;
      Protocol.frame_tap_args_timeout = timeout;
      Protocol.frame_tap_args_position = position;
      Protocol.frame_tap_args_modifiers = modifiers;
      Protocol.frame_tap_args_force = force;
      Protocol.frame_tap_args_strict = strict;
      Protocol.frame_tap_args_selector = selector;
    } in
    match Api.Frame.tap t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let text_content ~timeout ?strict ~selector (t : t) () =
    let args : Protocol.frame_text_content_args = {
      Protocol.frame_text_content_args_timeout = timeout;
      Protocol.frame_text_content_args_strict = strict;
      Protocol.frame_text_content_args_selector = selector;
    } in
    match Api.Frame.text_content t.conn t.guid args with
    | Ok res -> res.Protocol.frame_text_content_returns_value
    | Error e -> raise (Error e)

  let title (t : t) () =
    match Api.Frame.title t.conn t.guid () with
    | Ok res -> res.Protocol.frame_title_returns_value
    | Error e -> raise (Error e)

  let type_ ~timeout ?delay ~text ?strict ~selector (t : t) () =
    let args : Protocol.frame_type_args = {
      Protocol.frame_type_args_timeout = timeout;
      Protocol.frame_type_args_delay = delay;
      Protocol.frame_type_args_text = text;
      Protocol.frame_type_args_strict = strict;
      Protocol.frame_type_args_selector = selector;
    } in
    match Api.Frame.type_ t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let uncheck ?trial ~timeout ?position ?force ?strict ~selector (t : t) () =
    let args : Protocol.frame_uncheck_args = {
      Protocol.frame_uncheck_args_trial = trial;
      Protocol.frame_uncheck_args_timeout = timeout;
      Protocol.frame_uncheck_args_position = position;
      Protocol.frame_uncheck_args_force = force;
      Protocol.frame_uncheck_args_strict = strict;
      Protocol.frame_uncheck_args_selector = selector;
    } in
    match Api.Frame.uncheck t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let wait_for_timeout ~wait_timeout (t : t) () =
    let args : Protocol.frame_wait_for_timeout_args = {
      Protocol.frame_wait_for_timeout_args_wait_timeout = wait_timeout;
    } in
    match Api.Frame.wait_for_timeout t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let wait_for_function ?polling_interval ~timeout ~arg ?is_function ~expression (t : t) () =
    let args : Protocol.frame_wait_for_function_args = {
      Protocol.frame_wait_for_function_args_polling_interval = polling_interval;
      Protocol.frame_wait_for_function_args_timeout = timeout;
      Protocol.frame_wait_for_function_args_arg = arg;
      Protocol.frame_wait_for_function_args_is_function = is_function;
      Protocol.frame_wait_for_function_args_expression = expression;
    } in
    match Api.Frame.wait_for_function t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.frame_wait_for_function_returns_handle.guid } : js_handle_type obj)
    | Error e -> raise (Error e)

  let wait_for_selector ?omit_return_value ?state ~timeout ?strict ~selector (t : t) () =
    let args : Protocol.frame_wait_for_selector_args = {
      Protocol.frame_wait_for_selector_args_omit_return_value = omit_return_value;
      Protocol.frame_wait_for_selector_args_state = state;
      Protocol.frame_wait_for_selector_args_timeout = timeout;
      Protocol.frame_wait_for_selector_args_strict = strict;
      Protocol.frame_wait_for_selector_args_selector = selector;
    } in
    match Api.Frame.wait_for_selector t.conn t.guid args with
    | Ok res -> res.Protocol.frame_wait_for_selector_returns_element
    | Error e -> raise (Error e)

  let expect ~timeout ~is_not ?use_inner_text ?expected_value ?expected_number ?expected_text ?pseudo ?expression_arg ~expression ?selector (t : t) () =
    let args : Protocol.frame_expect_args = {
      Protocol.frame_expect_args_timeout = timeout;
      Protocol.frame_expect_args_is_not = is_not;
      Protocol.frame_expect_args_use_inner_text = use_inner_text;
      Protocol.frame_expect_args_expected_value = expected_value;
      Protocol.frame_expect_args_expected_number = expected_number;
      Protocol.frame_expect_args_expected_text = expected_text;
      Protocol.frame_expect_args_pseudo = pseudo;
      Protocol.frame_expect_args_expression_arg = expression_arg;
      Protocol.frame_expect_args_expression = expression;
      Protocol.frame_expect_args_selector = selector;
    } in
    match Api.Frame.expect t.conn t.guid args with
    | Ok res -> res
    | Error e -> raise (Error e)

  let on_loadstate (t : t) cb =
    Connection.on t.conn t.guid "loadstate" (fun msg ->
      match Protocol.frame_loadstate_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_navigated (t : t) cb =
    Connection.on t.conn t.guid "navigated" (fun msg ->
      match Protocol.frame_navigated_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

end

module Worker = struct
  type t = worker_type obj

  let disconnect ?reason (t : t) () =
    let args : Protocol.worker_disconnect_args = {
      Protocol.worker_disconnect_args_reason = reason;
    } in
    match Api.Worker.disconnect t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let evaluate_expression ~arg ?is_function ~expression (t : t) () =
    let args : Protocol.worker_evaluate_expression_args = {
      Protocol.worker_evaluate_expression_args_arg = arg;
      Protocol.worker_evaluate_expression_args_is_function = is_function;
      Protocol.worker_evaluate_expression_args_expression = expression;
    } in
    match Api.Worker.evaluate_expression t.conn t.guid args with
    | Ok res -> res.Protocol.worker_evaluate_expression_returns_value
    | Error e -> raise (Error e)

  let evaluate_expression_handle ~arg ?is_function ~expression (t : t) () =
    let args : Protocol.worker_evaluate_expression_handle_args = {
      Protocol.worker_evaluate_expression_handle_args_arg = arg;
      Protocol.worker_evaluate_expression_handle_args_is_function = is_function;
      Protocol.worker_evaluate_expression_handle_args_expression = expression;
    } in
    match Api.Worker.evaluate_expression_handle t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.worker_evaluate_expression_handle_returns_handle.guid } : js_handle_type obj)
    | Error e -> raise (Error e)

  let update_subscription ~enabled ~event (t : t) () =
    let args : Protocol.worker_update_subscription_args = {
      Protocol.worker_update_subscription_args_enabled = enabled;
      Protocol.worker_update_subscription_args_event = event;
    } in
    match Api.Worker.update_subscription t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let on_console (t : t) cb =
    Connection.on t.conn t.guid "console" (fun msg ->
      match Protocol.worker_console_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

end

module Disposable = struct
  type t = disposable_type obj

  let dispose (t : t) () =
    match Api.Disposable.dispose t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

end

module Js_handle = struct
  type t = js_handle_type obj

  let dispose (t : t) () =
    match Api.Js_handle.dispose t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let evaluate_expression ~arg ?is_function ~expression (t : t) () =
    let args : Protocol.js_handle_evaluate_expression_args = {
      Protocol.js_handle_evaluate_expression_args_arg = arg;
      Protocol.js_handle_evaluate_expression_args_is_function = is_function;
      Protocol.js_handle_evaluate_expression_args_expression = expression;
    } in
    match Api.Js_handle.evaluate_expression t.conn t.guid args with
    | Ok res -> res.Protocol.js_handle_evaluate_expression_returns_value
    | Error e -> raise (Error e)

  let evaluate_expression_handle ~arg ?is_function ~expression (t : t) () =
    let args : Protocol.js_handle_evaluate_expression_handle_args = {
      Protocol.js_handle_evaluate_expression_handle_args_arg = arg;
      Protocol.js_handle_evaluate_expression_handle_args_is_function = is_function;
      Protocol.js_handle_evaluate_expression_handle_args_expression = expression;
    } in
    match Api.Js_handle.evaluate_expression_handle t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.js_handle_evaluate_expression_handle_returns_handle.guid } : js_handle_type obj)
    | Error e -> raise (Error e)

  let get_property_list (t : t) () =
    match Api.Js_handle.get_property_list t.conn t.guid () with
    | Ok res -> res.Protocol.js_handle_get_property_list_returns_properties
    | Error e -> raise (Error e)

  let get_property ~name (t : t) () =
    let args : Protocol.js_handle_get_property_args = {
      Protocol.js_handle_get_property_args_name = name;
    } in
    match Api.Js_handle.get_property t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.js_handle_get_property_returns_handle.guid } : js_handle_type obj)
    | Error e -> raise (Error e)

  let json_value (t : t) () =
    match Api.Js_handle.json_value t.conn t.guid () with
    | Ok res -> res.Protocol.js_handle_json_value_returns_value
    | Error e -> raise (Error e)

  let on_preview_updated (t : t) cb =
    Connection.on t.conn t.guid "previewUpdated" (fun msg ->
      match Protocol.js_handle_preview_updated_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

end

module Element_handle = struct
  type t = element_handle_type obj

  let eval_on_selector ~arg ?is_function ~expression ?strict ~selector (t : t) () =
    let args : Protocol.element_handle_eval_on_selector_args = {
      Protocol.element_handle_eval_on_selector_args_arg = arg;
      Protocol.element_handle_eval_on_selector_args_is_function = is_function;
      Protocol.element_handle_eval_on_selector_args_expression = expression;
      Protocol.element_handle_eval_on_selector_args_strict = strict;
      Protocol.element_handle_eval_on_selector_args_selector = selector;
    } in
    match Api.Element_handle.eval_on_selector t.conn t.guid args with
    | Ok res -> res.Protocol.element_handle_eval_on_selector_returns_value
    | Error e -> raise (Error e)

  let eval_on_selector_all ~arg ?is_function ~expression ~selector (t : t) () =
    let args : Protocol.element_handle_eval_on_selector_all_args = {
      Protocol.element_handle_eval_on_selector_all_args_arg = arg;
      Protocol.element_handle_eval_on_selector_all_args_is_function = is_function;
      Protocol.element_handle_eval_on_selector_all_args_expression = expression;
      Protocol.element_handle_eval_on_selector_all_args_selector = selector;
    } in
    match Api.Element_handle.eval_on_selector_all t.conn t.guid args with
    | Ok res -> res.Protocol.element_handle_eval_on_selector_all_returns_value
    | Error e -> raise (Error e)

  let bounding_box (t : t) () =
    match Api.Element_handle.bounding_box t.conn t.guid () with
    | Ok res -> res.Protocol.element_handle_bounding_box_returns_value
    | Error e -> raise (Error e)

  let check ?trial ~timeout ?position ?force (t : t) () =
    let args : Protocol.element_handle_check_args = {
      Protocol.element_handle_check_args_trial = trial;
      Protocol.element_handle_check_args_timeout = timeout;
      Protocol.element_handle_check_args_position = position;
      Protocol.element_handle_check_args_force = force;
    } in
    match Api.Element_handle.check t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let click ?steps ?trial ~timeout ?click_count ?button ?delay ?position ?modifiers ?no_wait_after ?force (t : t) () =
    let args : Protocol.element_handle_click_args = {
      Protocol.element_handle_click_args_steps = steps;
      Protocol.element_handle_click_args_trial = trial;
      Protocol.element_handle_click_args_timeout = timeout;
      Protocol.element_handle_click_args_click_count = click_count;
      Protocol.element_handle_click_args_button = button;
      Protocol.element_handle_click_args_delay = delay;
      Protocol.element_handle_click_args_position = position;
      Protocol.element_handle_click_args_modifiers = modifiers;
      Protocol.element_handle_click_args_no_wait_after = no_wait_after;
      Protocol.element_handle_click_args_force = force;
    } in
    match Api.Element_handle.click t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let content_frame (t : t) () =
    match Api.Element_handle.content_frame t.conn t.guid () with
    | Ok res -> res.Protocol.element_handle_content_frame_returns_frame
    | Error e -> raise (Error e)

  let dblclick ?steps ?trial ~timeout ?button ?delay ?position ?modifiers ?force (t : t) () =
    let args : Protocol.element_handle_dblclick_args = {
      Protocol.element_handle_dblclick_args_steps = steps;
      Protocol.element_handle_dblclick_args_trial = trial;
      Protocol.element_handle_dblclick_args_timeout = timeout;
      Protocol.element_handle_dblclick_args_button = button;
      Protocol.element_handle_dblclick_args_delay = delay;
      Protocol.element_handle_dblclick_args_position = position;
      Protocol.element_handle_dblclick_args_modifiers = modifiers;
      Protocol.element_handle_dblclick_args_force = force;
    } in
    match Api.Element_handle.dblclick t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let dispatch_event ~event_init ~type_ (t : t) () =
    let args : Protocol.element_handle_dispatch_event_args = {
      Protocol.element_handle_dispatch_event_args_event_init = event_init;
      Protocol.element_handle_dispatch_event_args_type_ = type_;
    } in
    match Api.Element_handle.dispatch_event t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let fill ~timeout ?force ~value (t : t) () =
    let args : Protocol.element_handle_fill_args = {
      Protocol.element_handle_fill_args_timeout = timeout;
      Protocol.element_handle_fill_args_force = force;
      Protocol.element_handle_fill_args_value = value;
    } in
    match Api.Element_handle.fill t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let focus (t : t) () =
    match Api.Element_handle.focus t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let get_attribute ~name (t : t) () =
    let args : Protocol.element_handle_get_attribute_args = {
      Protocol.element_handle_get_attribute_args_name = name;
    } in
    match Api.Element_handle.get_attribute t.conn t.guid args with
    | Ok res -> res.Protocol.element_handle_get_attribute_returns_value
    | Error e -> raise (Error e)

  let hover ?trial ~timeout ?position ?modifiers ?force (t : t) () =
    let args : Protocol.element_handle_hover_args = {
      Protocol.element_handle_hover_args_trial = trial;
      Protocol.element_handle_hover_args_timeout = timeout;
      Protocol.element_handle_hover_args_position = position;
      Protocol.element_handle_hover_args_modifiers = modifiers;
      Protocol.element_handle_hover_args_force = force;
    } in
    match Api.Element_handle.hover t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let inner_html (t : t) () =
    match Api.Element_handle.inner_html t.conn t.guid () with
    | Ok res -> res.Protocol.element_handle_inner_htm_l_returns_value
    | Error e -> raise (Error e)

  let inner_text (t : t) () =
    match Api.Element_handle.inner_text t.conn t.guid () with
    | Ok res -> res.Protocol.element_handle_inner_text_returns_value
    | Error e -> raise (Error e)

  let input_value (t : t) () =
    match Api.Element_handle.input_value t.conn t.guid () with
    | Ok res -> res.Protocol.element_handle_input_value_returns_value
    | Error e -> raise (Error e)

  let is_checked (t : t) () =
    match Api.Element_handle.is_checked t.conn t.guid () with
    | Ok res -> res.Protocol.element_handle_is_checked_returns_value
    | Error e -> raise (Error e)

  let is_disabled (t : t) () =
    match Api.Element_handle.is_disabled t.conn t.guid () with
    | Ok res -> res.Protocol.element_handle_is_disabled_returns_value
    | Error e -> raise (Error e)

  let is_editable (t : t) () =
    match Api.Element_handle.is_editable t.conn t.guid () with
    | Ok res -> res.Protocol.element_handle_is_editable_returns_value
    | Error e -> raise (Error e)

  let is_enabled (t : t) () =
    match Api.Element_handle.is_enabled t.conn t.guid () with
    | Ok res -> res.Protocol.element_handle_is_enabled_returns_value
    | Error e -> raise (Error e)

  let is_hidden (t : t) () =
    match Api.Element_handle.is_hidden t.conn t.guid () with
    | Ok res -> res.Protocol.element_handle_is_hidden_returns_value
    | Error e -> raise (Error e)

  let is_visible (t : t) () =
    match Api.Element_handle.is_visible t.conn t.guid () with
    | Ok res -> res.Protocol.element_handle_is_visible_returns_value
    | Error e -> raise (Error e)

  let owner_frame (t : t) () =
    match Api.Element_handle.owner_frame t.conn t.guid () with
    | Ok res -> res.Protocol.element_handle_owner_frame_returns_frame
    | Error e -> raise (Error e)

  let press ?no_wait_after ~timeout ?delay ~key (t : t) () =
    let args : Protocol.element_handle_press_args = {
      Protocol.element_handle_press_args_no_wait_after = no_wait_after;
      Protocol.element_handle_press_args_timeout = timeout;
      Protocol.element_handle_press_args_delay = delay;
      Protocol.element_handle_press_args_key = key;
    } in
    match Api.Element_handle.press t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let query_selector ?strict ~selector (t : t) () =
    let args : Protocol.element_handle_query_selector_args = {
      Protocol.element_handle_query_selector_args_strict = strict;
      Protocol.element_handle_query_selector_args_selector = selector;
    } in
    match Api.Element_handle.query_selector t.conn t.guid args with
    | Ok res -> res.Protocol.element_handle_query_selector_returns_element
    | Error e -> raise (Error e)

  let query_selector_all ~selector (t : t) () =
    let args : Protocol.element_handle_query_selector_all_args = {
      Protocol.element_handle_query_selector_all_args_selector = selector;
    } in
    match Api.Element_handle.query_selector_all t.conn t.guid args with
    | Ok res -> res.Protocol.element_handle_query_selector_all_returns_elements
    | Error e -> raise (Error e)

  let screenshot ?style ?mask_color ?mask ?scale ?animations ?caret ?omit_background ?quality ?type_ ~timeout (t : t) () =
    let args : Protocol.element_handle_screenshot_args = {
      Protocol.element_handle_screenshot_args_style = style;
      Protocol.element_handle_screenshot_args_mask_color = mask_color;
      Protocol.element_handle_screenshot_args_mask = mask;
      Protocol.element_handle_screenshot_args_scale = scale;
      Protocol.element_handle_screenshot_args_animations = animations;
      Protocol.element_handle_screenshot_args_caret = caret;
      Protocol.element_handle_screenshot_args_omit_background = omit_background;
      Protocol.element_handle_screenshot_args_quality = quality;
      Protocol.element_handle_screenshot_args_type_ = type_;
      Protocol.element_handle_screenshot_args_timeout = timeout;
    } in
    match Api.Element_handle.screenshot t.conn t.guid args with
    | Ok res -> res.Protocol.element_handle_screenshot_returns_binary
    | Error e -> raise (Error e)

  let scroll_into_view_if_needed ~timeout (t : t) () =
    let args : Protocol.element_handle_scroll_into_view_if_needed_args = {
      Protocol.element_handle_scroll_into_view_if_needed_args_timeout = timeout;
    } in
    match Api.Element_handle.scroll_into_view_if_needed t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let select_option ~timeout ?force ?options ?elements (t : t) () =
    let args : Protocol.element_handle_select_option_args = {
      Protocol.element_handle_select_option_args_timeout = timeout;
      Protocol.element_handle_select_option_args_force = force;
      Protocol.element_handle_select_option_args_options = options;
      Protocol.element_handle_select_option_args_elements = elements;
    } in
    match Api.Element_handle.select_option t.conn t.guid args with
    | Ok res -> res.Protocol.element_handle_select_option_returns_values
    | Error e -> raise (Error e)

  let select_text ~timeout ?force (t : t) () =
    let args : Protocol.element_handle_select_text_args = {
      Protocol.element_handle_select_text_args_timeout = timeout;
      Protocol.element_handle_select_text_args_force = force;
    } in
    match Api.Element_handle.select_text t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_input_files ~timeout ?streams ?local_paths ?directory_stream ?local_directory ?payloads (t : t) () =
    let args : Protocol.element_handle_set_input_files_args = {
      Protocol.element_handle_set_input_files_args_timeout = timeout;
      Protocol.element_handle_set_input_files_args_streams = streams;
      Protocol.element_handle_set_input_files_args_local_paths = local_paths;
      Protocol.element_handle_set_input_files_args_directory_stream = directory_stream;
      Protocol.element_handle_set_input_files_args_local_directory = local_directory;
      Protocol.element_handle_set_input_files_args_payloads = payloads;
    } in
    match Api.Element_handle.set_input_files t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let tap ?trial ~timeout ?position ?modifiers ?force (t : t) () =
    let args : Protocol.element_handle_tap_args = {
      Protocol.element_handle_tap_args_trial = trial;
      Protocol.element_handle_tap_args_timeout = timeout;
      Protocol.element_handle_tap_args_position = position;
      Protocol.element_handle_tap_args_modifiers = modifiers;
      Protocol.element_handle_tap_args_force = force;
    } in
    match Api.Element_handle.tap t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let text_content (t : t) () =
    match Api.Element_handle.text_content t.conn t.guid () with
    | Ok res -> res.Protocol.element_handle_text_content_returns_value
    | Error e -> raise (Error e)

  let type_ ~timeout ?delay ~text (t : t) () =
    let args : Protocol.element_handle_type_args = {
      Protocol.element_handle_type_args_timeout = timeout;
      Protocol.element_handle_type_args_delay = delay;
      Protocol.element_handle_type_args_text = text;
    } in
    match Api.Element_handle.type_ t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let uncheck ?trial ~timeout ?position ?force (t : t) () =
    let args : Protocol.element_handle_uncheck_args = {
      Protocol.element_handle_uncheck_args_trial = trial;
      Protocol.element_handle_uncheck_args_timeout = timeout;
      Protocol.element_handle_uncheck_args_position = position;
      Protocol.element_handle_uncheck_args_force = force;
    } in
    match Api.Element_handle.uncheck t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let wait_for_element_state ~timeout ~state (t : t) () =
    let args : Protocol.element_handle_wait_for_element_state_args = {
      Protocol.element_handle_wait_for_element_state_args_timeout = timeout;
      Protocol.element_handle_wait_for_element_state_args_state = state;
    } in
    match Api.Element_handle.wait_for_element_state t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let wait_for_selector ?state ~timeout ?strict ~selector (t : t) () =
    let args : Protocol.element_handle_wait_for_selector_args = {
      Protocol.element_handle_wait_for_selector_args_state = state;
      Protocol.element_handle_wait_for_selector_args_timeout = timeout;
      Protocol.element_handle_wait_for_selector_args_strict = strict;
      Protocol.element_handle_wait_for_selector_args_selector = selector;
    } in
    match Api.Element_handle.wait_for_selector t.conn t.guid args with
    | Ok res -> res.Protocol.element_handle_wait_for_selector_returns_element
    | Error e -> raise (Error e)

end

module Request = struct
  type t = request_type obj

  let frame (t : t) =
    match Hashtbl.find_opt t.conn.objects t.guid with
    | Some obj ->
        let open Yojson.Safe.Util in
        (try Some ({ conn = t.conn; guid = member "frame" obj.initializer_ |> member "guid" |> to_string } : frame_type obj)
         with _ -> None)
    | None -> failwith "Object not found in connection"

  let service_worker (t : t) =
    match Hashtbl.find_opt t.conn.objects t.guid with
    | Some obj ->
        let open Yojson.Safe.Util in
        (try Some ({ conn = t.conn; guid = member "serviceWorker" obj.initializer_ |> member "guid" |> to_string } : worker_type obj)
         with _ -> None)
    | None -> failwith "Object not found in connection"

  let redirected_from (t : t) =
    match Hashtbl.find_opt t.conn.objects t.guid with
    | Some obj ->
        let open Yojson.Safe.Util in
        (try Some ({ conn = t.conn; guid = member "redirectedFrom" obj.initializer_ |> member "guid" |> to_string } : request_type obj)
         with _ -> None)
    | None -> failwith "Object not found in connection"

  let response (t : t) () =
    match Api.Request.response t.conn t.guid () with
    | Ok res -> res.Protocol.request_response_returns_response
    | Error e -> raise (Error e)

  let raw_request_headers (t : t) () =
    match Api.Request.raw_request_headers t.conn t.guid () with
    | Ok res -> res.Protocol.request_raw_request_headers_returns_headers
    | Error e -> raise (Error e)

end

module Route = struct
  type t = route_type obj

  let request (t : t) =
    match Hashtbl.find_opt t.conn.objects t.guid with
    | Some obj ->
        let open Yojson.Safe.Util in
        (try ({ conn = t.conn; guid = member "request" obj.initializer_ |> member "guid" |> to_string } : request_type obj)
         with _ -> failwith "Missing required initializer property request")
    | None -> failwith "Object not found in connection"

  let redirect_navigation_request ~url (t : t) () =
    let args : Protocol.route_redirect_navigation_request_args = {
      Protocol.route_redirect_navigation_request_args_url = url;
    } in
    match Api.Route.redirect_navigation_request t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let abort ?error_code (t : t) () =
    let args : Protocol.route_abort_args = {
      Protocol.route_abort_args_error_code = error_code;
    } in
    match Api.Route.abort t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let continue ~is_fallback ?post_data ?headers ?method_ ?url (t : t) () =
    let args : Protocol.route_continue_args = {
      Protocol.route_continue_args_is_fallback = is_fallback;
      Protocol.route_continue_args_post_data = post_data;
      Protocol.route_continue_args_headers = headers;
      Protocol.route_continue_args_method_ = method_;
      Protocol.route_continue_args_url = url;
    } in
    match Api.Route.continue t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let fulfill ?fetch_response_uid ?is_base64 ?body ?headers ?status (t : t) () =
    let args : Protocol.route_fulfill_args = {
      Protocol.route_fulfill_args_fetch_response_uid = fetch_response_uid;
      Protocol.route_fulfill_args_is_base64 = is_base64;
      Protocol.route_fulfill_args_body = body;
      Protocol.route_fulfill_args_headers = headers;
      Protocol.route_fulfill_args_status = status;
    } in
    match Api.Route.fulfill t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

end

module Web_socket_route = struct
  type t = web_socket_route_type obj

  let connect (t : t) () =
    match Api.Web_socket_route.connect t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let ensure_opened (t : t) () =
    match Api.Web_socket_route.ensure_opened t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let send_to_page ~is_base64 ~message (t : t) () =
    let args : Protocol.web_socket_route_send_to_page_args = {
      Protocol.web_socket_route_send_to_page_args_is_base64 = is_base64;
      Protocol.web_socket_route_send_to_page_args_message = message;
    } in
    match Api.Web_socket_route.send_to_page t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let send_to_server ~is_base64 ~message (t : t) () =
    let args : Protocol.web_socket_route_send_to_server_args = {
      Protocol.web_socket_route_send_to_server_args_is_base64 = is_base64;
      Protocol.web_socket_route_send_to_server_args_message = message;
    } in
    match Api.Web_socket_route.send_to_server t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let close_page ~was_clean ?reason ?code (t : t) () =
    let args : Protocol.web_socket_route_close_page_args = {
      Protocol.web_socket_route_close_page_args_was_clean = was_clean;
      Protocol.web_socket_route_close_page_args_reason = reason;
      Protocol.web_socket_route_close_page_args_code = code;
    } in
    match Api.Web_socket_route.close_page t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let close_server ~was_clean ?reason ?code (t : t) () =
    let args : Protocol.web_socket_route_close_server_args = {
      Protocol.web_socket_route_close_server_args_was_clean = was_clean;
      Protocol.web_socket_route_close_server_args_reason = reason;
      Protocol.web_socket_route_close_server_args_code = code;
    } in
    match Api.Web_socket_route.close_server t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let on_message_from_page (t : t) cb =
    Connection.on t.conn t.guid "messageFromPage" (fun msg ->
      match Protocol.web_socket_route_message_from_page_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_message_from_server (t : t) cb =
    Connection.on t.conn t.guid "messageFromServer" (fun msg ->
      match Protocol.web_socket_route_message_from_server_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_close_page (t : t) cb =
    Connection.on t.conn t.guid "closePage" (fun msg ->
      match Protocol.web_socket_route_close_page_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_close_server (t : t) cb =
    Connection.on t.conn t.guid "closeServer" (fun msg ->
      match Protocol.web_socket_route_close_server_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

end

module Response = struct
  type t = response_type obj

  let request (t : t) =
    match Hashtbl.find_opt t.conn.objects t.guid with
    | Some obj ->
        let open Yojson.Safe.Util in
        (try ({ conn = t.conn; guid = member "request" obj.initializer_ |> member "guid" |> to_string } : request_type obj)
         with _ -> failwith "Missing required initializer property request")
    | None -> failwith "Object not found in connection"

  let body (t : t) () =
    match Api.Response.body t.conn t.guid () with
    | Ok res -> res.Protocol.response_body_returns_binary
    | Error e -> raise (Error e)

  let security_details (t : t) () =
    match Api.Response.security_details t.conn t.guid () with
    | Ok res -> res.Protocol.response_security_details_returns_value
    | Error e -> raise (Error e)

  let server_addr (t : t) () =
    match Api.Response.server_addr t.conn t.guid () with
    | Ok res -> res.Protocol.response_server_addr_returns_value
    | Error e -> raise (Error e)

  let raw_response_headers (t : t) () =
    match Api.Response.raw_response_headers t.conn t.guid () with
    | Ok res -> res.Protocol.response_raw_response_headers_returns_headers
    | Error e -> raise (Error e)

  let http_version (t : t) () =
    match Api.Response.http_version t.conn t.guid () with
    | Ok res -> res.Protocol.response_http_version_returns_value
    | Error e -> raise (Error e)

  let sizes (t : t) () =
    match Api.Response.sizes t.conn t.guid () with
    | Ok res -> res.Protocol.response_sizes_returns_sizes
    | Error e -> raise (Error e)

end

module Web_socket = struct
  type t = web_socket_type obj

  let on_frame_sent (t : t) cb =
    Connection.on t.conn t.guid "frameSent" (fun msg ->
      match Protocol.web_socket_frame_sent_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_frame_received (t : t) cb =
    Connection.on t.conn t.guid "frameReceived" (fun msg ->
      match Protocol.web_socket_frame_received_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_socket_error (t : t) cb =
    Connection.on t.conn t.guid "socketError" (fun msg ->
      match Protocol.web_socket_socket_error_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

end

module Binding_call = struct
  type t = binding_call_type obj

  let frame (t : t) =
    match Hashtbl.find_opt t.conn.objects t.guid with
    | Some obj ->
        let open Yojson.Safe.Util in
        (try ({ conn = t.conn; guid = member "frame" obj.initializer_ |> member "guid" |> to_string } : frame_type obj)
         with _ -> failwith "Missing required initializer property frame")
    | None -> failwith "Object not found in connection"

  let reject ~error (t : t) () =
    let args : Protocol.binding_call_reject_args = {
      Protocol.binding_call_reject_args_error = error;
    } in
    match Api.Binding_call.reject t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let resolve ~result (t : t) () =
    let args : Protocol.binding_call_resolve_args = {
      Protocol.binding_call_resolve_args_result = result;
    } in
    match Api.Binding_call.resolve t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

end

module Debugger = struct
  type t = debugger_type obj

  let request_pause (t : t) () =
    match Api.Debugger.request_pause t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let resume (t : t) () =
    match Api.Debugger.resume t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let next (t : t) () =
    match Api.Debugger.next t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let run_to ~location (t : t) () =
    let args : Protocol.debugger_run_to_args = {
      Protocol.debugger_run_to_args_location = location;
    } in
    match Api.Debugger.run_to t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let on_paused_state_changed (t : t) cb =
    Connection.on t.conn t.guid "pausedStateChanged" (fun msg ->
      match Protocol.debugger_paused_state_changed_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

end

module Dialog = struct
  type t = dialog_type obj

  let page (t : t) =
    match Hashtbl.find_opt t.conn.objects t.guid with
    | Some obj ->
        let open Yojson.Safe.Util in
        (try Some ({ conn = t.conn; guid = member "page" obj.initializer_ |> member "guid" |> to_string } : page_type obj)
         with _ -> None)
    | None -> failwith "Object not found in connection"

  let accept ?prompt_text (t : t) () =
    let args : Protocol.dialog_accept_args = {
      Protocol.dialog_accept_args_prompt_text = prompt_text;
    } in
    match Api.Dialog.accept t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let dismiss (t : t) () =
    match Api.Dialog.dismiss t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

end

module Tracing = struct
  type t = tracing_type obj

  let tracing_start ?live ?screenshots ?snapshots ?name (t : t) () =
    let args : Protocol.tracing_tracing_start_args = {
      Protocol.tracing_tracing_start_args_live = live;
      Protocol.tracing_tracing_start_args_screenshots = screenshots;
      Protocol.tracing_tracing_start_args_snapshots = snapshots;
      Protocol.tracing_tracing_start_args_name = name;
    } in
    match Api.Tracing.tracing_start t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let tracing_start_chunk ?title ?name (t : t) () =
    let args : Protocol.tracing_tracing_start_chunk_args = {
      Protocol.tracing_tracing_start_chunk_args_title = title;
      Protocol.tracing_tracing_start_chunk_args_name = name;
    } in
    match Api.Tracing.tracing_start_chunk t.conn t.guid args with
    | Ok res -> res.Protocol.tracing_tracing_start_chunk_returns_trace_name
    | Error e -> raise (Error e)

  let tracing_group ?location ~name (t : t) () =
    let args : Protocol.tracing_tracing_group_args = {
      Protocol.tracing_tracing_group_args_location = location;
      Protocol.tracing_tracing_group_args_name = name;
    } in
    match Api.Tracing.tracing_group t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let tracing_group_end (t : t) () =
    match Api.Tracing.tracing_group_end t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let tracing_stop_chunk ~mode (t : t) () =
    let args : Protocol.tracing_tracing_stop_chunk_args = {
      Protocol.tracing_tracing_stop_chunk_args_mode = mode;
    } in
    match Api.Tracing.tracing_stop_chunk t.conn t.guid args with
    | Ok res -> res
    | Error e -> raise (Error e)

  let tracing_stop (t : t) () =
    match Api.Tracing.tracing_stop t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let har_start ~options ?page (t : t) () =
    let args : Protocol.tracing_har_start_args = {
      Protocol.tracing_har_start_args_options = options;
      Protocol.tracing_har_start_args_page = page;
    } in
    match Api.Tracing.har_start t.conn t.guid args with
    | Ok res -> res.Protocol.tracing_har_start_returns_har_id
    | Error e -> raise (Error e)

  let har_export ?har_id (t : t) () =
    let args : Protocol.tracing_har_export_args = {
      Protocol.tracing_har_export_args_har_id = har_id;
    } in
    match Api.Tracing.har_export t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.tracing_har_export_returns_artifact.guid } : artifact_type obj)
    | Error e -> raise (Error e)

end

module Artifact = struct
  type t = artifact_type obj

  let path_after_finished (t : t) () =
    match Api.Artifact.path_after_finished t.conn t.guid () with
    | Ok res -> res.Protocol.artifact_path_after_finished_returns_value
    | Error e -> raise (Error e)

  let save_as ~path (t : t) () =
    let args : Protocol.artifact_save_as_args = {
      Protocol.artifact_save_as_args_path = path;
    } in
    match Api.Artifact.save_as t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let save_as_stream (t : t) () =
    match Api.Artifact.save_as_stream t.conn t.guid () with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.artifact_save_as_stream_returns_stream.guid } : stream_type obj)
    | Error e -> raise (Error e)

  let failure (t : t) () =
    match Api.Artifact.failure t.conn t.guid () with
    | Ok res -> res.Protocol.artifact_failure_returns_error
    | Error e -> raise (Error e)

  let stream (t : t) () =
    match Api.Artifact.stream t.conn t.guid () with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.artifact_stream_returns_stream.guid } : stream_type obj)
    | Error e -> raise (Error e)

  let cancel (t : t) () =
    match Api.Artifact.cancel t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let delete (t : t) () =
    match Api.Artifact.delete t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

end

module Stream = struct
  type t = stream_type obj

  let read ?size (t : t) () =
    let args : Protocol.stream_read_args = {
      Protocol.stream_read_args_size = size;
    } in
    match Api.Stream.read t.conn t.guid args with
    | Ok res -> res.Protocol.stream_read_returns_binary
    | Error e -> raise (Error e)

  let close (t : t) () =
    match Api.Stream.close t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

end

module Writable_stream = struct
  type t = writable_stream_type obj

  let write ~binary (t : t) () =
    let args : Protocol.writable_stream_write_args = {
      Protocol.writable_stream_write_args_binary = binary;
    } in
    match Api.Writable_stream.write t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let close (t : t) () =
    match Api.Writable_stream.close t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

end

module Cdp_session = struct
  type t = cdp_session_type obj

  let send ?params ~method_ (t : t) () =
    let args : Protocol.cdp_session_send_args = {
      Protocol.cdp_session_send_args_params = params;
      Protocol.cdp_session_send_args_method_ = method_;
    } in
    match Api.Cdp_session.send t.conn t.guid args with
    | Ok res -> res.Protocol.cdp_session_send_returns_result
    | Error e -> raise (Error e)

  let detach (t : t) () =
    match Api.Cdp_session.detach t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let on_event (t : t) cb =
    Connection.on t.conn t.guid "event" (fun msg ->
      match Protocol.cdp_session_event_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

end

module Android = struct
  type t = android_type obj

  let devices ?omit_driver_install ?port ?host (t : t) () =
    let args : Protocol.android_devices_args = {
      Protocol.android_devices_args_omit_driver_install = omit_driver_install;
      Protocol.android_devices_args_port = port;
      Protocol.android_devices_args_host = host;
    } in
    match Api.Android.devices t.conn t.guid args with
    | Ok res -> res.Protocol.android_devices_returns_devices
    | Error e -> raise (Error e)

end

module Android_socket = struct
  type t = android_socket_type obj

  let write ~data (t : t) () =
    let args : Protocol.android_socket_write_args = {
      Protocol.android_socket_write_args_data = data;
    } in
    match Api.Android_socket.write t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let close (t : t) () =
    match Api.Android_socket.close t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let on_data (t : t) cb =
    Connection.on t.conn t.guid "data" (fun msg ->
      match Protocol.android_socket_data_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

end

module Android_device = struct
  type t = android_device_type obj

  let wait ~timeout ?state ~android_selector (t : t) () =
    let args : Protocol.android_device_wait_args = {
      Protocol.android_device_wait_args_timeout = timeout;
      Protocol.android_device_wait_args_state = state;
      Protocol.android_device_wait_args_android_selector = android_selector;
    } in
    match Api.Android_device.wait t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let fill ~timeout ~text ~android_selector (t : t) () =
    let args : Protocol.android_device_fill_args = {
      Protocol.android_device_fill_args_timeout = timeout;
      Protocol.android_device_fill_args_text = text;
      Protocol.android_device_fill_args_android_selector = android_selector;
    } in
    match Api.Android_device.fill t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let tap ~timeout ?duration ~android_selector (t : t) () =
    let args : Protocol.android_device_tap_args = {
      Protocol.android_device_tap_args_timeout = timeout;
      Protocol.android_device_tap_args_duration = duration;
      Protocol.android_device_tap_args_android_selector = android_selector;
    } in
    match Api.Android_device.tap t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let drag ~timeout ?speed ~dest ~android_selector (t : t) () =
    let args : Protocol.android_device_drag_args = {
      Protocol.android_device_drag_args_timeout = timeout;
      Protocol.android_device_drag_args_speed = speed;
      Protocol.android_device_drag_args_dest = dest;
      Protocol.android_device_drag_args_android_selector = android_selector;
    } in
    match Api.Android_device.drag t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let fling ~timeout ?speed ~direction ~android_selector (t : t) () =
    let args : Protocol.android_device_fling_args = {
      Protocol.android_device_fling_args_timeout = timeout;
      Protocol.android_device_fling_args_speed = speed;
      Protocol.android_device_fling_args_direction = direction;
      Protocol.android_device_fling_args_android_selector = android_selector;
    } in
    match Api.Android_device.fling t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let long_tap ~timeout ~android_selector (t : t) () =
    let args : Protocol.android_device_long_tap_args = {
      Protocol.android_device_long_tap_args_timeout = timeout;
      Protocol.android_device_long_tap_args_android_selector = android_selector;
    } in
    match Api.Android_device.long_tap t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let pinch_close ~timeout ?speed ~percent ~android_selector (t : t) () =
    let args : Protocol.android_device_pinch_close_args = {
      Protocol.android_device_pinch_close_args_timeout = timeout;
      Protocol.android_device_pinch_close_args_speed = speed;
      Protocol.android_device_pinch_close_args_percent = percent;
      Protocol.android_device_pinch_close_args_android_selector = android_selector;
    } in
    match Api.Android_device.pinch_close t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let pinch_open ~timeout ?speed ~percent ~android_selector (t : t) () =
    let args : Protocol.android_device_pinch_open_args = {
      Protocol.android_device_pinch_open_args_timeout = timeout;
      Protocol.android_device_pinch_open_args_speed = speed;
      Protocol.android_device_pinch_open_args_percent = percent;
      Protocol.android_device_pinch_open_args_android_selector = android_selector;
    } in
    match Api.Android_device.pinch_open t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let scroll ~timeout ?speed ~percent ~direction ~android_selector (t : t) () =
    let args : Protocol.android_device_scroll_args = {
      Protocol.android_device_scroll_args_timeout = timeout;
      Protocol.android_device_scroll_args_speed = speed;
      Protocol.android_device_scroll_args_percent = percent;
      Protocol.android_device_scroll_args_direction = direction;
      Protocol.android_device_scroll_args_android_selector = android_selector;
    } in
    match Api.Android_device.scroll t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let swipe ~timeout ?speed ~percent ~direction ~android_selector (t : t) () =
    let args : Protocol.android_device_swipe_args = {
      Protocol.android_device_swipe_args_timeout = timeout;
      Protocol.android_device_swipe_args_speed = speed;
      Protocol.android_device_swipe_args_percent = percent;
      Protocol.android_device_swipe_args_direction = direction;
      Protocol.android_device_swipe_args_android_selector = android_selector;
    } in
    match Api.Android_device.swipe t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let info ~android_selector (t : t) () =
    let args : Protocol.android_device_info_args = {
      Protocol.android_device_info_args_android_selector = android_selector;
    } in
    match Api.Android_device.info t.conn t.guid args with
    | Ok res -> res.Protocol.android_device_info_returns_info
    | Error e -> raise (Error e)

  let screenshot (t : t) () =
    match Api.Android_device.screenshot t.conn t.guid () with
    | Ok res -> res.Protocol.android_device_screenshot_returns_binary
    | Error e -> raise (Error e)

  let input_type ~text (t : t) () =
    let args : Protocol.android_device_input_type_args = {
      Protocol.android_device_input_type_args_text = text;
    } in
    match Api.Android_device.input_type t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let input_press ~key (t : t) () =
    let args : Protocol.android_device_input_press_args = {
      Protocol.android_device_input_press_args_key = key;
    } in
    match Api.Android_device.input_press t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let input_tap ~point (t : t) () =
    let args : Protocol.android_device_input_tap_args = {
      Protocol.android_device_input_tap_args_point = point;
    } in
    match Api.Android_device.input_tap t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let input_swipe ~steps ~segments (t : t) () =
    let args : Protocol.android_device_input_swipe_args = {
      Protocol.android_device_input_swipe_args_steps = steps;
      Protocol.android_device_input_swipe_args_segments = segments;
    } in
    match Api.Android_device.input_swipe t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let input_drag ~steps ~to_ ~from (t : t) () =
    let args : Protocol.android_device_input_drag_args = {
      Protocol.android_device_input_drag_args_steps = steps;
      Protocol.android_device_input_drag_args_to_ = to_;
      Protocol.android_device_input_drag_args_from = from;
    } in
    match Api.Android_device.input_drag t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let launch_browser ?test_id_attribute_name ?selector_engines ?service_workers ?strict_selectors ?record_video ?base_url ?contrast ?accept_downloads ?forced_colors ?reduced_motion ?color_scheme ?has_touch ?is_mobile ?device_scale_factor ?http_credentials ?offline ?extra_http_headers ?permissions ?geolocation ?timezone_id ?locale ?user_agent ?bypass_csp ?java_script_enabled ?client_certificates ?ignore_https_errors ?screen ?viewport ?no_default_viewport ?proxy ?args ?pkg (t : t) () =
    let args : Protocol.android_device_launch_browser_args = {
      Protocol.android_device_launch_browser_args_test_id_attribute_name = test_id_attribute_name;
      Protocol.android_device_launch_browser_args_selector_engines = selector_engines;
      Protocol.android_device_launch_browser_args_service_workers = service_workers;
      Protocol.android_device_launch_browser_args_strict_selectors = strict_selectors;
      Protocol.android_device_launch_browser_args_record_video = record_video;
      Protocol.android_device_launch_browser_args_base_url = base_url;
      Protocol.android_device_launch_browser_args_contrast = contrast;
      Protocol.android_device_launch_browser_args_accept_downloads = accept_downloads;
      Protocol.android_device_launch_browser_args_forced_colors = forced_colors;
      Protocol.android_device_launch_browser_args_reduced_motion = reduced_motion;
      Protocol.android_device_launch_browser_args_color_scheme = color_scheme;
      Protocol.android_device_launch_browser_args_has_touch = has_touch;
      Protocol.android_device_launch_browser_args_is_mobile = is_mobile;
      Protocol.android_device_launch_browser_args_device_scale_factor = device_scale_factor;
      Protocol.android_device_launch_browser_args_http_credentials = http_credentials;
      Protocol.android_device_launch_browser_args_offline = offline;
      Protocol.android_device_launch_browser_args_extra_http_headers = extra_http_headers;
      Protocol.android_device_launch_browser_args_permissions = permissions;
      Protocol.android_device_launch_browser_args_geolocation = geolocation;
      Protocol.android_device_launch_browser_args_timezone_id = timezone_id;
      Protocol.android_device_launch_browser_args_locale = locale;
      Protocol.android_device_launch_browser_args_user_agent = user_agent;
      Protocol.android_device_launch_browser_args_bypass_csp = bypass_csp;
      Protocol.android_device_launch_browser_args_java_script_enabled = java_script_enabled;
      Protocol.android_device_launch_browser_args_client_certificates = client_certificates;
      Protocol.android_device_launch_browser_args_ignore_https_errors = ignore_https_errors;
      Protocol.android_device_launch_browser_args_screen = screen;
      Protocol.android_device_launch_browser_args_viewport = viewport;
      Protocol.android_device_launch_browser_args_no_default_viewport = no_default_viewport;
      Protocol.android_device_launch_browser_args_proxy = proxy;
      Protocol.android_device_launch_browser_args_args = args;
      Protocol.android_device_launch_browser_args_pkg = pkg;
    } in
    match Api.Android_device.launch_browser t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.android_device_launch_browser_returns_context.guid } : browser_context_type obj)
    | Error e -> raise (Error e)

  let open_ ~command (t : t) () =
    let args : Protocol.android_device_open_args = {
      Protocol.android_device_open_args_command = command;
    } in
    match Api.Android_device.open_ t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.android_device_open_returns_socket.guid } : android_socket_type obj)
    | Error e -> raise (Error e)

  let shell ~command (t : t) () =
    let args : Protocol.android_device_shell_args = {
      Protocol.android_device_shell_args_command = command;
    } in
    match Api.Android_device.shell t.conn t.guid args with
    | Ok res -> res.Protocol.android_device_shell_returns_result
    | Error e -> raise (Error e)

  let install_apk ?args ~file (t : t) () =
    let args : Protocol.android_device_install_apk_args = {
      Protocol.android_device_install_apk_args_args = args;
      Protocol.android_device_install_apk_args_file = file;
    } in
    match Api.Android_device.install_apk t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let push ?mode ~path ~file (t : t) () =
    let args : Protocol.android_device_push_args = {
      Protocol.android_device_push_args_mode = mode;
      Protocol.android_device_push_args_path = path;
      Protocol.android_device_push_args_file = file;
    } in
    match Api.Android_device.push t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let connect_to_web_view ~socket_name (t : t) () =
    let args : Protocol.android_device_connect_to_web_view_args = {
      Protocol.android_device_connect_to_web_view_args_socket_name = socket_name;
    } in
    match Api.Android_device.connect_to_web_view t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.android_device_connect_to_web_view_returns_context.guid } : browser_context_type obj)
    | Error e -> raise (Error e)

  let close (t : t) () =
    match Api.Android_device.close t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let on_web_view_added (t : t) cb =
    Connection.on t.conn t.guid "webViewAdded" (fun msg ->
      match Protocol.android_device_web_view_added_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_web_view_removed (t : t) cb =
    Connection.on t.conn t.guid "webViewRemoved" (fun msg ->
      match Protocol.android_device_web_view_removed_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

end

module Json_pipe = struct
  type t = json_pipe_type obj

  let send ~message (t : t) () =
    let args : Protocol.json_pipe_send_args = {
      Protocol.json_pipe_send_args_message = message;
    } in
    match Api.Json_pipe.send t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let close (t : t) () =
    match Api.Json_pipe.close t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let on_message (t : t) cb =
    Connection.on t.conn t.guid "message" (fun msg ->
      match Protocol.json_pipe_message_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

  let on_closed (t : t) cb =
    Connection.on t.conn t.guid "closed" (fun msg ->
      match Protocol.json_pipe_closed_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    )

end

