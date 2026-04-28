[@@@ocaml.warning "-39-32-34"]

open Protocol

module Api_request_context = struct
  let fetch (conn : Connection.t) (guid : string) (args : api_request_context_fetch_args) : (api_request_context_fetch_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"fetch" ~params:(api_request_context_fetch_args_to_yojson args) with
    | Ok res -> api_request_context_fetch_returns_of_yojson res
    | Error e -> Error e

  let fetch_response_body (conn : Connection.t) (guid : string) (args : api_request_context_fetch_response_body_args) : (api_request_context_fetch_response_body_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"fetchResponseBody" ~params:(api_request_context_fetch_response_body_args_to_yojson args) with
    | Ok res -> api_request_context_fetch_response_body_returns_of_yojson res
    | Error e -> Error e

  let fetch_log (conn : Connection.t) (guid : string) (args : api_request_context_fetch_log_args) : (api_request_context_fetch_log_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"fetchLog" ~params:(api_request_context_fetch_log_args_to_yojson args) with
    | Ok res -> api_request_context_fetch_log_returns_of_yojson res
    | Error e -> Error e

  let storage_state (conn : Connection.t) (guid : string) (args : api_request_context_storage_state_args) : (api_request_context_storage_state_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"storageState" ~params:(api_request_context_storage_state_args_to_yojson args) with
    | Ok res -> api_request_context_storage_state_returns_of_yojson res
    | Error e -> Error e

  let dispose_api_response (conn : Connection.t) (guid : string) (args : api_request_context_dispose_api_response_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"disposeAPIResponse" ~params:(api_request_context_dispose_api_response_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let dispose (conn : Connection.t) (guid : string) (args : api_request_context_dispose_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"dispose" ~params:(api_request_context_dispose_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

end

module Local_utils = struct
  let zip (conn : Connection.t) (guid : string) (args : local_utils_zip_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"zip" ~params:(local_utils_zip_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let har_open (conn : Connection.t) (guid : string) (args : local_utils_har_open_args) : (local_utils_har_open_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"harOpen" ~params:(local_utils_har_open_args_to_yojson args) with
    | Ok res -> local_utils_har_open_returns_of_yojson res
    | Error e -> Error e

  let har_lookup (conn : Connection.t) (guid : string) (args : local_utils_har_lookup_args) : (local_utils_har_lookup_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"harLookup" ~params:(local_utils_har_lookup_args_to_yojson args) with
    | Ok res -> local_utils_har_lookup_returns_of_yojson res
    | Error e -> Error e

  let har_close (conn : Connection.t) (guid : string) (args : local_utils_har_close_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"harClose" ~params:(local_utils_har_close_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let har_unzip (conn : Connection.t) (guid : string) (args : local_utils_har_unzip_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"harUnzip" ~params:(local_utils_har_unzip_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let connect (conn : Connection.t) (guid : string) (args : local_utils_connect_args) : (local_utils_connect_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"connect" ~params:(local_utils_connect_args_to_yojson args) with
    | Ok res -> local_utils_connect_returns_of_yojson res
    | Error e -> Error e

  let tracing_started (conn : Connection.t) (guid : string) (args : local_utils_tracing_started_args) : (local_utils_tracing_started_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"tracingStarted" ~params:(local_utils_tracing_started_args_to_yojson args) with
    | Ok res -> local_utils_tracing_started_returns_of_yojson res
    | Error e -> Error e

  let add_stack_to_tracing_no_reply (conn : Connection.t) (guid : string) (args : local_utils_add_stack_to_tracing_no_reply_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"addStackToTracingNoReply" ~params:(local_utils_add_stack_to_tracing_no_reply_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let trace_discarded (conn : Connection.t) (guid : string) (args : local_utils_trace_discarded_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"traceDiscarded" ~params:(local_utils_trace_discarded_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let glob_to_regex (conn : Connection.t) (guid : string) (args : local_utils_glob_to_regex_args) : (local_utils_glob_to_regex_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"globToRegex" ~params:(local_utils_glob_to_regex_args_to_yojson args) with
    | Ok res -> local_utils_glob_to_regex_returns_of_yojson res
    | Error e -> Error e

end

module Root = struct
  let initialize (conn : Connection.t) (guid : string) (args : root_initialize_args) : (root_initialize_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"initialize" ~params:(root_initialize_args_to_yojson args) with
    | Ok res -> root_initialize_returns_of_yojson res
    | Error e -> Error e

end

module Playwright = struct
  let new_request (conn : Connection.t) (guid : string) (args : playwright_new_request_args) : (playwright_new_request_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"newRequest" ~params:(playwright_new_request_args_to_yojson args) with
    | Ok res -> playwright_new_request_returns_of_yojson res
    | Error e -> Error e

end

module Debug_controller = struct
  let initialize (conn : Connection.t) (guid : string) (args : debug_controller_initialize_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"initialize" ~params:(debug_controller_initialize_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let set_report_state_changed (conn : Connection.t) (guid : string) (args : debug_controller_set_report_state_changed_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"setReportStateChanged" ~params:(debug_controller_set_report_state_changed_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let set_recorder_mode (conn : Connection.t) (guid : string) (args : debug_controller_set_recorder_mode_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"setRecorderMode" ~params:(debug_controller_set_recorder_mode_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let highlight (conn : Connection.t) (guid : string) (args : debug_controller_highlight_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"highlight" ~params:(debug_controller_highlight_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let hide_highlight (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"hideHighlight" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let resume (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"resume" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let kill (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"kill" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

end

module Socks_support = struct
  let socks_connected (conn : Connection.t) (guid : string) (args : socks_support_socks_connected_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"socksConnected" ~params:(socks_support_socks_connected_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let socks_failed (conn : Connection.t) (guid : string) (args : socks_support_socks_failed_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"socksFailed" ~params:(socks_support_socks_failed_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let socks_data (conn : Connection.t) (guid : string) (args : socks_support_socks_data_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"socksData" ~params:(socks_support_socks_data_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let socks_error (conn : Connection.t) (guid : string) (args : socks_support_socks_error_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"socksError" ~params:(socks_support_socks_error_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let socks_end (conn : Connection.t) (guid : string) (args : socks_support_socks_end_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"socksEnd" ~params:(socks_support_socks_end_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

end

module Browser_type = struct
  let launch (conn : Connection.t) (guid : string) (args : browser_type_launch_args) : (browser_type_launch_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"launch" ~params:(browser_type_launch_args_to_yojson args) with
    | Ok res -> browser_type_launch_returns_of_yojson res
    | Error e -> Error e

  let launch_persistent_context (conn : Connection.t) (guid : string) (args : browser_type_launch_persistent_context_args) : (browser_type_launch_persistent_context_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"launchPersistentContext" ~params:(browser_type_launch_persistent_context_args_to_yojson args) with
    | Ok res -> browser_type_launch_persistent_context_returns_of_yojson res
    | Error e -> Error e

  let connect_over_cdp (conn : Connection.t) (guid : string) (args : browser_type_connect_over_cd_p_args) : (browser_type_connect_over_cd_p_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"connectOverCDP" ~params:(browser_type_connect_over_cd_p_args_to_yojson args) with
    | Ok res -> browser_type_connect_over_cd_p_returns_of_yojson res
    | Error e -> Error e

  let connect_to_worker (conn : Connection.t) (guid : string) (args : browser_type_connect_to_worker_args) : (browser_type_connect_to_worker_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"connectToWorker" ~params:(browser_type_connect_to_worker_args_to_yojson args) with
    | Ok res -> browser_type_connect_to_worker_returns_of_yojson res
    | Error e -> Error e

end

module Browser = struct
  let start_server (conn : Connection.t) (guid : string) (args : browser_start_server_args) : (browser_start_server_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"startServer" ~params:(browser_start_server_args_to_yojson args) with
    | Ok res -> browser_start_server_returns_of_yojson res
    | Error e -> Error e

  let stop_server (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"stopServer" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let close (conn : Connection.t) (guid : string) (args : browser_close_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"close" ~params:(browser_close_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let kill_for_tests (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"killForTests" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let default_user_agent_for_test (conn : Connection.t) (guid : string) () : (browser_default_user_agent_for_test_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"defaultUserAgentForTest" ~params:(`Assoc []) with
    | Ok res -> browser_default_user_agent_for_test_returns_of_yojson res
    | Error e -> Error e

  let new_context (conn : Connection.t) (guid : string) (args : browser_new_context_args) : (browser_new_context_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"newContext" ~params:(browser_new_context_args_to_yojson args) with
    | Ok res -> browser_new_context_returns_of_yojson res
    | Error e -> Error e

  let new_context_for_reuse (conn : Connection.t) (guid : string) (args : browser_new_context_for_reuse_args) : (browser_new_context_for_reuse_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"newContextForReuse" ~params:(browser_new_context_for_reuse_args_to_yojson args) with
    | Ok res -> browser_new_context_for_reuse_returns_of_yojson res
    | Error e -> Error e

  let disconnect_from_reused_context (conn : Connection.t) (guid : string) (args : browser_disconnect_from_reused_context_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"disconnectFromReusedContext" ~params:(browser_disconnect_from_reused_context_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let new_browser_cdp_session (conn : Connection.t) (guid : string) () : (browser_new_browser_cdp_session_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"newBrowserCDPSession" ~params:(`Assoc []) with
    | Ok res -> browser_new_browser_cdp_session_returns_of_yojson res
    | Error e -> Error e

  let start_tracing (conn : Connection.t) (guid : string) (args : browser_start_tracing_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"startTracing" ~params:(browser_start_tracing_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let stop_tracing (conn : Connection.t) (guid : string) () : (browser_stop_tracing_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"stopTracing" ~params:(`Assoc []) with
    | Ok res -> browser_stop_tracing_returns_of_yojson res
    | Error e -> Error e

end

module Event_target = struct
  let wait_for_event_info (conn : Connection.t) (guid : string) (args : event_target_wait_for_event_info_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"waitForEventInfo" ~params:(event_target_wait_for_event_info_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

end

module Browser_context = struct
  let add_cookies (conn : Connection.t) (guid : string) (args : browser_context_add_cookies_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"addCookies" ~params:(browser_context_add_cookies_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let add_init_script (conn : Connection.t) (guid : string) (args : browser_context_add_init_script_args) : (browser_context_add_init_script_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"addInitScript" ~params:(browser_context_add_init_script_args_to_yojson args) with
    | Ok res -> browser_context_add_init_script_returns_of_yojson res
    | Error e -> Error e

  let clear_cookies (conn : Connection.t) (guid : string) (args : browser_context_clear_cookies_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"clearCookies" ~params:(browser_context_clear_cookies_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let clear_permissions (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"clearPermissions" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let close (conn : Connection.t) (guid : string) (args : browser_context_close_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"close" ~params:(browser_context_close_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let cookies (conn : Connection.t) (guid : string) (args : browser_context_cookies_args) : (browser_context_cookies_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"cookies" ~params:(browser_context_cookies_args_to_yojson args) with
    | Ok res -> browser_context_cookies_returns_of_yojson res
    | Error e -> Error e

  let expose_binding (conn : Connection.t) (guid : string) (args : browser_context_expose_binding_args) : (browser_context_expose_binding_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"exposeBinding" ~params:(browser_context_expose_binding_args_to_yojson args) with
    | Ok res -> browser_context_expose_binding_returns_of_yojson res
    | Error e -> Error e

  let grant_permissions (conn : Connection.t) (guid : string) (args : browser_context_grant_permissions_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"grantPermissions" ~params:(browser_context_grant_permissions_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let new_page (conn : Connection.t) (guid : string) () : (browser_context_new_page_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"newPage" ~params:(`Assoc []) with
    | Ok res -> browser_context_new_page_returns_of_yojson res
    | Error e -> Error e

  let register_selector_engine (conn : Connection.t) (guid : string) (args : browser_context_register_selector_engine_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"registerSelectorEngine" ~params:(browser_context_register_selector_engine_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let set_test_id_attribute_name (conn : Connection.t) (guid : string) (args : browser_context_set_test_id_attribute_name_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"setTestIdAttributeName" ~params:(browser_context_set_test_id_attribute_name_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let set_extra_http_headers (conn : Connection.t) (guid : string) (args : browser_context_set_extra_http_headers_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"setExtraHTTPHeaders" ~params:(browser_context_set_extra_http_headers_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let set_geolocation (conn : Connection.t) (guid : string) (args : browser_context_set_geolocation_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"setGeolocation" ~params:(browser_context_set_geolocation_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let set_http_credentials (conn : Connection.t) (guid : string) (args : browser_context_set_http_credentials_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"setHTTPCredentials" ~params:(browser_context_set_http_credentials_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let set_network_interception_patterns (conn : Connection.t) (guid : string) (args : browser_context_set_network_interception_patterns_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"setNetworkInterceptionPatterns" ~params:(browser_context_set_network_interception_patterns_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let set_web_socket_interception_patterns (conn : Connection.t) (guid : string) (args : browser_context_set_web_socket_interception_patterns_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"setWebSocketInterceptionPatterns" ~params:(browser_context_set_web_socket_interception_patterns_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let set_offline (conn : Connection.t) (guid : string) (args : browser_context_set_offline_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"setOffline" ~params:(browser_context_set_offline_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let storage_state (conn : Connection.t) (guid : string) (args : browser_context_storage_state_args) : (browser_context_storage_state_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"storageState" ~params:(browser_context_storage_state_args_to_yojson args) with
    | Ok res -> browser_context_storage_state_returns_of_yojson res
    | Error e -> Error e

  let set_storage_state (conn : Connection.t) (guid : string) (args : browser_context_set_storage_state_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"setStorageState" ~params:(browser_context_set_storage_state_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let pause (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"pause" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let enable_recorder (conn : Connection.t) (guid : string) (args : browser_context_enable_recorder_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"enableRecorder" ~params:(browser_context_enable_recorder_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let disable_recorder (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"disableRecorder" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let expose_console_api (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"exposeConsoleApi" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let new_cdp_session (conn : Connection.t) (guid : string) (args : browser_context_new_cdp_session_args) : (browser_context_new_cdp_session_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"newCDPSession" ~params:(browser_context_new_cdp_session_args_to_yojson args) with
    | Ok res -> browser_context_new_cdp_session_returns_of_yojson res
    | Error e -> Error e

  let create_temp_files (conn : Connection.t) (guid : string) (args : browser_context_create_temp_files_args) : (browser_context_create_temp_files_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"createTempFiles" ~params:(browser_context_create_temp_files_args_to_yojson args) with
    | Ok res -> browser_context_create_temp_files_returns_of_yojson res
    | Error e -> Error e

  let update_subscription (conn : Connection.t) (guid : string) (args : browser_context_update_subscription_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"updateSubscription" ~params:(browser_context_update_subscription_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let clock_fast_forward (conn : Connection.t) (guid : string) (args : browser_context_clock_fast_forward_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"clockFastForward" ~params:(browser_context_clock_fast_forward_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let clock_install (conn : Connection.t) (guid : string) (args : browser_context_clock_install_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"clockInstall" ~params:(browser_context_clock_install_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let clock_pause_at (conn : Connection.t) (guid : string) (args : browser_context_clock_pause_at_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"clockPauseAt" ~params:(browser_context_clock_pause_at_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let clock_resume (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"clockResume" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let clock_run_for (conn : Connection.t) (guid : string) (args : browser_context_clock_run_for_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"clockRunFor" ~params:(browser_context_clock_run_for_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let clock_set_fixed_time (conn : Connection.t) (guid : string) (args : browser_context_clock_set_fixed_time_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"clockSetFixedTime" ~params:(browser_context_clock_set_fixed_time_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let clock_set_system_time (conn : Connection.t) (guid : string) (args : browser_context_clock_set_system_time_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"clockSetSystemTime" ~params:(browser_context_clock_set_system_time_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

end

module Page = struct
  let add_init_script (conn : Connection.t) (guid : string) (args : page_add_init_script_args) : (page_add_init_script_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"addInitScript" ~params:(page_add_init_script_args_to_yojson args) with
    | Ok res -> page_add_init_script_returns_of_yojson res
    | Error e -> Error e

  let close (conn : Connection.t) (guid : string) (args : page_close_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"close" ~params:(page_close_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let clear_console_messages (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"clearConsoleMessages" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let console_messages (conn : Connection.t) (guid : string) (args : page_console_messages_args) : (page_console_messages_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"consoleMessages" ~params:(page_console_messages_args_to_yojson args) with
    | Ok res -> page_console_messages_returns_of_yojson res
    | Error e -> Error e

  let emulate_media (conn : Connection.t) (guid : string) (args : page_emulate_media_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"emulateMedia" ~params:(page_emulate_media_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let expose_binding (conn : Connection.t) (guid : string) (args : page_expose_binding_args) : (page_expose_binding_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"exposeBinding" ~params:(page_expose_binding_args_to_yojson args) with
    | Ok res -> page_expose_binding_returns_of_yojson res
    | Error e -> Error e

  let go_back (conn : Connection.t) (guid : string) (args : page_go_back_args) : (page_go_back_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"goBack" ~params:(page_go_back_args_to_yojson args) with
    | Ok res -> page_go_back_returns_of_yojson res
    | Error e -> Error e

  let go_forward (conn : Connection.t) (guid : string) (args : page_go_forward_args) : (page_go_forward_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"goForward" ~params:(page_go_forward_args_to_yojson args) with
    | Ok res -> page_go_forward_returns_of_yojson res
    | Error e -> Error e

  let request_gc (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"requestGC" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let register_locator_handler (conn : Connection.t) (guid : string) (args : page_register_locator_handler_args) : (page_register_locator_handler_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"registerLocatorHandler" ~params:(page_register_locator_handler_args_to_yojson args) with
    | Ok res -> page_register_locator_handler_returns_of_yojson res
    | Error e -> Error e

  let resolve_locator_handler_no_reply (conn : Connection.t) (guid : string) (args : page_resolve_locator_handler_no_reply_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"resolveLocatorHandlerNoReply" ~params:(page_resolve_locator_handler_no_reply_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let unregister_locator_handler (conn : Connection.t) (guid : string) (args : page_unregister_locator_handler_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"unregisterLocatorHandler" ~params:(page_unregister_locator_handler_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let reload (conn : Connection.t) (guid : string) (args : page_reload_args) : (page_reload_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"reload" ~params:(page_reload_args_to_yojson args) with
    | Ok res -> page_reload_returns_of_yojson res
    | Error e -> Error e

  let expect_screenshot (conn : Connection.t) (guid : string) (args : page_expect_screenshot_args) : (page_expect_screenshot_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"expectScreenshot" ~params:(page_expect_screenshot_args_to_yojson args) with
    | Ok res -> page_expect_screenshot_returns_of_yojson res
    | Error e -> Error e

  let screenshot (conn : Connection.t) (guid : string) (args : page_screenshot_args) : (page_screenshot_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"screenshot" ~params:(page_screenshot_args_to_yojson args) with
    | Ok res -> page_screenshot_returns_of_yojson res
    | Error e -> Error e

  let set_extra_http_headers (conn : Connection.t) (guid : string) (args : page_set_extra_http_headers_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"setExtraHTTPHeaders" ~params:(page_set_extra_http_headers_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let set_network_interception_patterns (conn : Connection.t) (guid : string) (args : page_set_network_interception_patterns_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"setNetworkInterceptionPatterns" ~params:(page_set_network_interception_patterns_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let set_web_socket_interception_patterns (conn : Connection.t) (guid : string) (args : page_set_web_socket_interception_patterns_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"setWebSocketInterceptionPatterns" ~params:(page_set_web_socket_interception_patterns_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let set_viewport_size (conn : Connection.t) (guid : string) (args : page_set_viewport_size_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"setViewportSize" ~params:(page_set_viewport_size_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let keyboard_down (conn : Connection.t) (guid : string) (args : page_keyboard_down_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"keyboardDown" ~params:(page_keyboard_down_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let keyboard_up (conn : Connection.t) (guid : string) (args : page_keyboard_up_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"keyboardUp" ~params:(page_keyboard_up_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let keyboard_insert_text (conn : Connection.t) (guid : string) (args : page_keyboard_insert_text_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"keyboardInsertText" ~params:(page_keyboard_insert_text_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let keyboard_type (conn : Connection.t) (guid : string) (args : page_keyboard_type_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"keyboardType" ~params:(page_keyboard_type_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let keyboard_press (conn : Connection.t) (guid : string) (args : page_keyboard_press_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"keyboardPress" ~params:(page_keyboard_press_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let mouse_move (conn : Connection.t) (guid : string) (args : page_mouse_move_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"mouseMove" ~params:(page_mouse_move_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let mouse_down (conn : Connection.t) (guid : string) (args : page_mouse_down_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"mouseDown" ~params:(page_mouse_down_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let mouse_up (conn : Connection.t) (guid : string) (args : page_mouse_up_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"mouseUp" ~params:(page_mouse_up_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let mouse_click (conn : Connection.t) (guid : string) (args : page_mouse_click_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"mouseClick" ~params:(page_mouse_click_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let mouse_wheel (conn : Connection.t) (guid : string) (args : page_mouse_wheel_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"mouseWheel" ~params:(page_mouse_wheel_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let touchscreen_tap (conn : Connection.t) (guid : string) (args : page_touchscreen_tap_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"touchscreenTap" ~params:(page_touchscreen_tap_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let clear_page_errors (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"clearPageErrors" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let page_errors (conn : Connection.t) (guid : string) (args : page_page_errors_args) : (page_page_errors_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"pageErrors" ~params:(page_page_errors_args_to_yojson args) with
    | Ok res -> page_page_errors_returns_of_yojson res
    | Error e -> Error e

  let pdf (conn : Connection.t) (guid : string) (args : page_pdf_args) : (page_pdf_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"pdf" ~params:(page_pdf_args_to_yojson args) with
    | Ok res -> page_pdf_returns_of_yojson res
    | Error e -> Error e

  let requests (conn : Connection.t) (guid : string) () : (page_requests_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"requests" ~params:(`Assoc []) with
    | Ok res -> page_requests_returns_of_yojson res
    | Error e -> Error e

  let start_js_coverage (conn : Connection.t) (guid : string) (args : page_start_js_coverage_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"startJSCoverage" ~params:(page_start_js_coverage_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let stop_js_coverage (conn : Connection.t) (guid : string) () : (page_stop_js_coverage_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"stopJSCoverage" ~params:(`Assoc []) with
    | Ok res -> page_stop_js_coverage_returns_of_yojson res
    | Error e -> Error e

  let start_css_coverage (conn : Connection.t) (guid : string) (args : page_start_css_coverage_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"startCSSCoverage" ~params:(page_start_css_coverage_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let stop_css_coverage (conn : Connection.t) (guid : string) () : (page_stop_css_coverage_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"stopCSSCoverage" ~params:(`Assoc []) with
    | Ok res -> page_stop_css_coverage_returns_of_yojson res
    | Error e -> Error e

  let bring_to_front (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"bringToFront" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let pick_locator (conn : Connection.t) (guid : string) () : (page_pick_locator_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"pickLocator" ~params:(`Assoc []) with
    | Ok res -> page_pick_locator_returns_of_yojson res
    | Error e -> Error e

  let cancel_pick_locator (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"cancelPickLocator" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let hide_highlight (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"hideHighlight" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let screencast_show_overlay (conn : Connection.t) (guid : string) (args : page_screencast_show_overlay_args) : (page_screencast_show_overlay_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"screencastShowOverlay" ~params:(page_screencast_show_overlay_args_to_yojson args) with
    | Ok res -> page_screencast_show_overlay_returns_of_yojson res
    | Error e -> Error e

  let screencast_remove_overlay (conn : Connection.t) (guid : string) (args : page_screencast_remove_overlay_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"screencastRemoveOverlay" ~params:(page_screencast_remove_overlay_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let screencast_chapter (conn : Connection.t) (guid : string) (args : page_screencast_chapter_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"screencastChapter" ~params:(page_screencast_chapter_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let screencast_set_overlay_visible (conn : Connection.t) (guid : string) (args : page_screencast_set_overlay_visible_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"screencastSetOverlayVisible" ~params:(page_screencast_set_overlay_visible_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let screencast_show_actions (conn : Connection.t) (guid : string) (args : page_screencast_show_actions_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"screencastShowActions" ~params:(page_screencast_show_actions_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let screencast_hide_actions (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"screencastHideActions" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let screencast_start (conn : Connection.t) (guid : string) (args : page_screencast_start_args) : (page_screencast_start_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"screencastStart" ~params:(page_screencast_start_args_to_yojson args) with
    | Ok res -> page_screencast_start_returns_of_yojson res
    | Error e -> Error e

  let screencast_stop (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"screencastStop" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let update_subscription (conn : Connection.t) (guid : string) (args : page_update_subscription_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"updateSubscription" ~params:(page_update_subscription_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let set_dock_tile (conn : Connection.t) (guid : string) (args : page_set_dock_tile_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"setDockTile" ~params:(page_set_dock_tile_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

end

module Frame = struct
  let eval_on_selector (conn : Connection.t) (guid : string) (args : frame_eval_on_selector_args) : (frame_eval_on_selector_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"evalOnSelector" ~params:(frame_eval_on_selector_args_to_yojson args) with
    | Ok res -> frame_eval_on_selector_returns_of_yojson res
    | Error e -> Error e

  let eval_on_selector_all (conn : Connection.t) (guid : string) (args : frame_eval_on_selector_all_args) : (frame_eval_on_selector_all_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"evalOnSelectorAll" ~params:(frame_eval_on_selector_all_args_to_yojson args) with
    | Ok res -> frame_eval_on_selector_all_returns_of_yojson res
    | Error e -> Error e

  let add_script_tag (conn : Connection.t) (guid : string) (args : frame_add_script_tag_args) : (frame_add_script_tag_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"addScriptTag" ~params:(frame_add_script_tag_args_to_yojson args) with
    | Ok res -> frame_add_script_tag_returns_of_yojson res
    | Error e -> Error e

  let add_style_tag (conn : Connection.t) (guid : string) (args : frame_add_style_tag_args) : (frame_add_style_tag_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"addStyleTag" ~params:(frame_add_style_tag_args_to_yojson args) with
    | Ok res -> frame_add_style_tag_returns_of_yojson res
    | Error e -> Error e

  let aria_ref (conn : Connection.t) (guid : string) (args : frame_aria_ref_args) : (frame_aria_ref_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"ariaRef" ~params:(frame_aria_ref_args_to_yojson args) with
    | Ok res -> frame_aria_ref_returns_of_yojson res
    | Error e -> Error e

  let aria_snapshot (conn : Connection.t) (guid : string) (args : frame_aria_snapshot_args) : (frame_aria_snapshot_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"ariaSnapshot" ~params:(frame_aria_snapshot_args_to_yojson args) with
    | Ok res -> frame_aria_snapshot_returns_of_yojson res
    | Error e -> Error e

  let blur (conn : Connection.t) (guid : string) (args : frame_blur_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"blur" ~params:(frame_blur_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let check (conn : Connection.t) (guid : string) (args : frame_check_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"check" ~params:(frame_check_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let click (conn : Connection.t) (guid : string) (args : frame_click_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"click" ~params:(frame_click_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let content (conn : Connection.t) (guid : string) () : (frame_content_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"content" ~params:(`Assoc []) with
    | Ok res -> frame_content_returns_of_yojson res
    | Error e -> Error e

  let drag_and_drop (conn : Connection.t) (guid : string) (args : frame_drag_and_drop_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"dragAndDrop" ~params:(frame_drag_and_drop_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let drop (conn : Connection.t) (guid : string) (args : frame_drop_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"drop" ~params:(frame_drop_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let dblclick (conn : Connection.t) (guid : string) (args : frame_dblclick_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"dblclick" ~params:(frame_dblclick_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let dispatch_event (conn : Connection.t) (guid : string) (args : frame_dispatch_event_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"dispatchEvent" ~params:(frame_dispatch_event_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let evaluate_expression (conn : Connection.t) (guid : string) (args : frame_evaluate_expression_args) : (frame_evaluate_expression_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"evaluateExpression" ~params:(frame_evaluate_expression_args_to_yojson args) with
    | Ok res -> frame_evaluate_expression_returns_of_yojson res
    | Error e -> Error e

  let evaluate_expression_handle (conn : Connection.t) (guid : string) (args : frame_evaluate_expression_handle_args) : (frame_evaluate_expression_handle_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"evaluateExpressionHandle" ~params:(frame_evaluate_expression_handle_args_to_yojson args) with
    | Ok res -> frame_evaluate_expression_handle_returns_of_yojson res
    | Error e -> Error e

  let fill (conn : Connection.t) (guid : string) (args : frame_fill_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"fill" ~params:(frame_fill_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let focus (conn : Connection.t) (guid : string) (args : frame_focus_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"focus" ~params:(frame_focus_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let frame_element (conn : Connection.t) (guid : string) () : (frame_frame_element_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"frameElement" ~params:(`Assoc []) with
    | Ok res -> frame_frame_element_returns_of_yojson res
    | Error e -> Error e

  let resolve_selector (conn : Connection.t) (guid : string) (args : frame_resolve_selector_args) : (frame_resolve_selector_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"resolveSelector" ~params:(frame_resolve_selector_args_to_yojson args) with
    | Ok res -> frame_resolve_selector_returns_of_yojson res
    | Error e -> Error e

  let highlight (conn : Connection.t) (guid : string) (args : frame_highlight_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"highlight" ~params:(frame_highlight_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let hide_highlight (conn : Connection.t) (guid : string) (args : frame_hide_highlight_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"hideHighlight" ~params:(frame_hide_highlight_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let get_attribute (conn : Connection.t) (guid : string) (args : frame_get_attribute_args) : (frame_get_attribute_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"getAttribute" ~params:(frame_get_attribute_args_to_yojson args) with
    | Ok res -> frame_get_attribute_returns_of_yojson res
    | Error e -> Error e

  let goto (conn : Connection.t) (guid : string) (args : frame_goto_args) : (frame_goto_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"goto" ~params:(frame_goto_args_to_yojson args) with
    | Ok res -> frame_goto_returns_of_yojson res
    | Error e -> Error e

  let hover (conn : Connection.t) (guid : string) (args : frame_hover_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"hover" ~params:(frame_hover_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let inner_html (conn : Connection.t) (guid : string) (args : frame_inner_htm_l_args) : (frame_inner_htm_l_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"innerHTML" ~params:(frame_inner_htm_l_args_to_yojson args) with
    | Ok res -> frame_inner_htm_l_returns_of_yojson res
    | Error e -> Error e

  let inner_text (conn : Connection.t) (guid : string) (args : frame_inner_text_args) : (frame_inner_text_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"innerText" ~params:(frame_inner_text_args_to_yojson args) with
    | Ok res -> frame_inner_text_returns_of_yojson res
    | Error e -> Error e

  let input_value (conn : Connection.t) (guid : string) (args : frame_input_value_args) : (frame_input_value_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"inputValue" ~params:(frame_input_value_args_to_yojson args) with
    | Ok res -> frame_input_value_returns_of_yojson res
    | Error e -> Error e

  let is_checked (conn : Connection.t) (guid : string) (args : frame_is_checked_args) : (frame_is_checked_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"isChecked" ~params:(frame_is_checked_args_to_yojson args) with
    | Ok res -> frame_is_checked_returns_of_yojson res
    | Error e -> Error e

  let is_disabled (conn : Connection.t) (guid : string) (args : frame_is_disabled_args) : (frame_is_disabled_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"isDisabled" ~params:(frame_is_disabled_args_to_yojson args) with
    | Ok res -> frame_is_disabled_returns_of_yojson res
    | Error e -> Error e

  let is_enabled (conn : Connection.t) (guid : string) (args : frame_is_enabled_args) : (frame_is_enabled_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"isEnabled" ~params:(frame_is_enabled_args_to_yojson args) with
    | Ok res -> frame_is_enabled_returns_of_yojson res
    | Error e -> Error e

  let is_hidden (conn : Connection.t) (guid : string) (args : frame_is_hidden_args) : (frame_is_hidden_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"isHidden" ~params:(frame_is_hidden_args_to_yojson args) with
    | Ok res -> frame_is_hidden_returns_of_yojson res
    | Error e -> Error e

  let is_visible (conn : Connection.t) (guid : string) (args : frame_is_visible_args) : (frame_is_visible_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"isVisible" ~params:(frame_is_visible_args_to_yojson args) with
    | Ok res -> frame_is_visible_returns_of_yojson res
    | Error e -> Error e

  let is_editable (conn : Connection.t) (guid : string) (args : frame_is_editable_args) : (frame_is_editable_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"isEditable" ~params:(frame_is_editable_args_to_yojson args) with
    | Ok res -> frame_is_editable_returns_of_yojson res
    | Error e -> Error e

  let press (conn : Connection.t) (guid : string) (args : frame_press_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"press" ~params:(frame_press_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let query_selector (conn : Connection.t) (guid : string) (args : frame_query_selector_args) : (frame_query_selector_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"querySelector" ~params:(frame_query_selector_args_to_yojson args) with
    | Ok res -> frame_query_selector_returns_of_yojson res
    | Error e -> Error e

  let query_selector_all (conn : Connection.t) (guid : string) (args : frame_query_selector_all_args) : (frame_query_selector_all_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"querySelectorAll" ~params:(frame_query_selector_all_args_to_yojson args) with
    | Ok res -> frame_query_selector_all_returns_of_yojson res
    | Error e -> Error e

  let query_count (conn : Connection.t) (guid : string) (args : frame_query_count_args) : (frame_query_count_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"queryCount" ~params:(frame_query_count_args_to_yojson args) with
    | Ok res -> frame_query_count_returns_of_yojson res
    | Error e -> Error e

  let select_option (conn : Connection.t) (guid : string) (args : frame_select_option_args) : (frame_select_option_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"selectOption" ~params:(frame_select_option_args_to_yojson args) with
    | Ok res -> frame_select_option_returns_of_yojson res
    | Error e -> Error e

  let set_content (conn : Connection.t) (guid : string) (args : frame_set_content_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"setContent" ~params:(frame_set_content_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let set_input_files (conn : Connection.t) (guid : string) (args : frame_set_input_files_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"setInputFiles" ~params:(frame_set_input_files_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let tap (conn : Connection.t) (guid : string) (args : frame_tap_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"tap" ~params:(frame_tap_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let text_content (conn : Connection.t) (guid : string) (args : frame_text_content_args) : (frame_text_content_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"textContent" ~params:(frame_text_content_args_to_yojson args) with
    | Ok res -> frame_text_content_returns_of_yojson res
    | Error e -> Error e

  let title (conn : Connection.t) (guid : string) () : (frame_title_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"title" ~params:(`Assoc []) with
    | Ok res -> frame_title_returns_of_yojson res
    | Error e -> Error e

  let type_ (conn : Connection.t) (guid : string) (args : frame_type_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"type" ~params:(frame_type_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let uncheck (conn : Connection.t) (guid : string) (args : frame_uncheck_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"uncheck" ~params:(frame_uncheck_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let wait_for_timeout (conn : Connection.t) (guid : string) (args : frame_wait_for_timeout_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"waitForTimeout" ~params:(frame_wait_for_timeout_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let wait_for_function (conn : Connection.t) (guid : string) (args : frame_wait_for_function_args) : (frame_wait_for_function_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"waitForFunction" ~params:(frame_wait_for_function_args_to_yojson args) with
    | Ok res -> frame_wait_for_function_returns_of_yojson res
    | Error e -> Error e

  let wait_for_selector (conn : Connection.t) (guid : string) (args : frame_wait_for_selector_args) : (frame_wait_for_selector_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"waitForSelector" ~params:(frame_wait_for_selector_args_to_yojson args) with
    | Ok res -> frame_wait_for_selector_returns_of_yojson res
    | Error e -> Error e

  let expect (conn : Connection.t) (guid : string) (args : frame_expect_args) : (frame_expect_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"expect" ~params:(frame_expect_args_to_yojson args) with
    | Ok res -> frame_expect_returns_of_yojson res
    | Error e -> Error e

end

module Worker = struct
  let disconnect (conn : Connection.t) (guid : string) (args : worker_disconnect_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"disconnect" ~params:(worker_disconnect_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let evaluate_expression (conn : Connection.t) (guid : string) (args : worker_evaluate_expression_args) : (worker_evaluate_expression_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"evaluateExpression" ~params:(worker_evaluate_expression_args_to_yojson args) with
    | Ok res -> worker_evaluate_expression_returns_of_yojson res
    | Error e -> Error e

  let evaluate_expression_handle (conn : Connection.t) (guid : string) (args : worker_evaluate_expression_handle_args) : (worker_evaluate_expression_handle_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"evaluateExpressionHandle" ~params:(worker_evaluate_expression_handle_args_to_yojson args) with
    | Ok res -> worker_evaluate_expression_handle_returns_of_yojson res
    | Error e -> Error e

  let update_subscription (conn : Connection.t) (guid : string) (args : worker_update_subscription_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"updateSubscription" ~params:(worker_update_subscription_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

end

module Disposable = struct
  let dispose (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"dispose" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

end

module Js_handle = struct
  let dispose (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"dispose" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let evaluate_expression (conn : Connection.t) (guid : string) (args : js_handle_evaluate_expression_args) : (js_handle_evaluate_expression_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"evaluateExpression" ~params:(js_handle_evaluate_expression_args_to_yojson args) with
    | Ok res -> js_handle_evaluate_expression_returns_of_yojson res
    | Error e -> Error e

  let evaluate_expression_handle (conn : Connection.t) (guid : string) (args : js_handle_evaluate_expression_handle_args) : (js_handle_evaluate_expression_handle_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"evaluateExpressionHandle" ~params:(js_handle_evaluate_expression_handle_args_to_yojson args) with
    | Ok res -> js_handle_evaluate_expression_handle_returns_of_yojson res
    | Error e -> Error e

  let get_property_list (conn : Connection.t) (guid : string) () : (js_handle_get_property_list_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"getPropertyList" ~params:(`Assoc []) with
    | Ok res -> js_handle_get_property_list_returns_of_yojson res
    | Error e -> Error e

  let get_property (conn : Connection.t) (guid : string) (args : js_handle_get_property_args) : (js_handle_get_property_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"getProperty" ~params:(js_handle_get_property_args_to_yojson args) with
    | Ok res -> js_handle_get_property_returns_of_yojson res
    | Error e -> Error e

  let json_value (conn : Connection.t) (guid : string) () : (js_handle_json_value_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"jsonValue" ~params:(`Assoc []) with
    | Ok res -> js_handle_json_value_returns_of_yojson res
    | Error e -> Error e

end

module Element_handle = struct
  let eval_on_selector (conn : Connection.t) (guid : string) (args : element_handle_eval_on_selector_args) : (element_handle_eval_on_selector_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"evalOnSelector" ~params:(element_handle_eval_on_selector_args_to_yojson args) with
    | Ok res -> element_handle_eval_on_selector_returns_of_yojson res
    | Error e -> Error e

  let eval_on_selector_all (conn : Connection.t) (guid : string) (args : element_handle_eval_on_selector_all_args) : (element_handle_eval_on_selector_all_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"evalOnSelectorAll" ~params:(element_handle_eval_on_selector_all_args_to_yojson args) with
    | Ok res -> element_handle_eval_on_selector_all_returns_of_yojson res
    | Error e -> Error e

  let bounding_box (conn : Connection.t) (guid : string) () : (element_handle_bounding_box_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"boundingBox" ~params:(`Assoc []) with
    | Ok res -> element_handle_bounding_box_returns_of_yojson res
    | Error e -> Error e

  let check (conn : Connection.t) (guid : string) (args : element_handle_check_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"check" ~params:(element_handle_check_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let click (conn : Connection.t) (guid : string) (args : element_handle_click_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"click" ~params:(element_handle_click_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let content_frame (conn : Connection.t) (guid : string) () : (element_handle_content_frame_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"contentFrame" ~params:(`Assoc []) with
    | Ok res -> element_handle_content_frame_returns_of_yojson res
    | Error e -> Error e

  let dblclick (conn : Connection.t) (guid : string) (args : element_handle_dblclick_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"dblclick" ~params:(element_handle_dblclick_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let dispatch_event (conn : Connection.t) (guid : string) (args : element_handle_dispatch_event_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"dispatchEvent" ~params:(element_handle_dispatch_event_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let fill (conn : Connection.t) (guid : string) (args : element_handle_fill_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"fill" ~params:(element_handle_fill_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let focus (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"focus" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let get_attribute (conn : Connection.t) (guid : string) (args : element_handle_get_attribute_args) : (element_handle_get_attribute_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"getAttribute" ~params:(element_handle_get_attribute_args_to_yojson args) with
    | Ok res -> element_handle_get_attribute_returns_of_yojson res
    | Error e -> Error e

  let hover (conn : Connection.t) (guid : string) (args : element_handle_hover_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"hover" ~params:(element_handle_hover_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let inner_html (conn : Connection.t) (guid : string) () : (element_handle_inner_htm_l_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"innerHTML" ~params:(`Assoc []) with
    | Ok res -> element_handle_inner_htm_l_returns_of_yojson res
    | Error e -> Error e

  let inner_text (conn : Connection.t) (guid : string) () : (element_handle_inner_text_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"innerText" ~params:(`Assoc []) with
    | Ok res -> element_handle_inner_text_returns_of_yojson res
    | Error e -> Error e

  let input_value (conn : Connection.t) (guid : string) () : (element_handle_input_value_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"inputValue" ~params:(`Assoc []) with
    | Ok res -> element_handle_input_value_returns_of_yojson res
    | Error e -> Error e

  let is_checked (conn : Connection.t) (guid : string) () : (element_handle_is_checked_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"isChecked" ~params:(`Assoc []) with
    | Ok res -> element_handle_is_checked_returns_of_yojson res
    | Error e -> Error e

  let is_disabled (conn : Connection.t) (guid : string) () : (element_handle_is_disabled_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"isDisabled" ~params:(`Assoc []) with
    | Ok res -> element_handle_is_disabled_returns_of_yojson res
    | Error e -> Error e

  let is_editable (conn : Connection.t) (guid : string) () : (element_handle_is_editable_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"isEditable" ~params:(`Assoc []) with
    | Ok res -> element_handle_is_editable_returns_of_yojson res
    | Error e -> Error e

  let is_enabled (conn : Connection.t) (guid : string) () : (element_handle_is_enabled_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"isEnabled" ~params:(`Assoc []) with
    | Ok res -> element_handle_is_enabled_returns_of_yojson res
    | Error e -> Error e

  let is_hidden (conn : Connection.t) (guid : string) () : (element_handle_is_hidden_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"isHidden" ~params:(`Assoc []) with
    | Ok res -> element_handle_is_hidden_returns_of_yojson res
    | Error e -> Error e

  let is_visible (conn : Connection.t) (guid : string) () : (element_handle_is_visible_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"isVisible" ~params:(`Assoc []) with
    | Ok res -> element_handle_is_visible_returns_of_yojson res
    | Error e -> Error e

  let owner_frame (conn : Connection.t) (guid : string) () : (element_handle_owner_frame_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"ownerFrame" ~params:(`Assoc []) with
    | Ok res -> element_handle_owner_frame_returns_of_yojson res
    | Error e -> Error e

  let press (conn : Connection.t) (guid : string) (args : element_handle_press_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"press" ~params:(element_handle_press_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let query_selector (conn : Connection.t) (guid : string) (args : element_handle_query_selector_args) : (element_handle_query_selector_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"querySelector" ~params:(element_handle_query_selector_args_to_yojson args) with
    | Ok res -> element_handle_query_selector_returns_of_yojson res
    | Error e -> Error e

  let query_selector_all (conn : Connection.t) (guid : string) (args : element_handle_query_selector_all_args) : (element_handle_query_selector_all_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"querySelectorAll" ~params:(element_handle_query_selector_all_args_to_yojson args) with
    | Ok res -> element_handle_query_selector_all_returns_of_yojson res
    | Error e -> Error e

  let screenshot (conn : Connection.t) (guid : string) (args : element_handle_screenshot_args) : (element_handle_screenshot_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"screenshot" ~params:(element_handle_screenshot_args_to_yojson args) with
    | Ok res -> element_handle_screenshot_returns_of_yojson res
    | Error e -> Error e

  let scroll_into_view_if_needed (conn : Connection.t) (guid : string) (args : element_handle_scroll_into_view_if_needed_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"scrollIntoViewIfNeeded" ~params:(element_handle_scroll_into_view_if_needed_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let select_option (conn : Connection.t) (guid : string) (args : element_handle_select_option_args) : (element_handle_select_option_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"selectOption" ~params:(element_handle_select_option_args_to_yojson args) with
    | Ok res -> element_handle_select_option_returns_of_yojson res
    | Error e -> Error e

  let select_text (conn : Connection.t) (guid : string) (args : element_handle_select_text_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"selectText" ~params:(element_handle_select_text_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let set_input_files (conn : Connection.t) (guid : string) (args : element_handle_set_input_files_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"setInputFiles" ~params:(element_handle_set_input_files_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let tap (conn : Connection.t) (guid : string) (args : element_handle_tap_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"tap" ~params:(element_handle_tap_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let text_content (conn : Connection.t) (guid : string) () : (element_handle_text_content_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"textContent" ~params:(`Assoc []) with
    | Ok res -> element_handle_text_content_returns_of_yojson res
    | Error e -> Error e

  let type_ (conn : Connection.t) (guid : string) (args : element_handle_type_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"type" ~params:(element_handle_type_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let uncheck (conn : Connection.t) (guid : string) (args : element_handle_uncheck_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"uncheck" ~params:(element_handle_uncheck_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let wait_for_element_state (conn : Connection.t) (guid : string) (args : element_handle_wait_for_element_state_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"waitForElementState" ~params:(element_handle_wait_for_element_state_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let wait_for_selector (conn : Connection.t) (guid : string) (args : element_handle_wait_for_selector_args) : (element_handle_wait_for_selector_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"waitForSelector" ~params:(element_handle_wait_for_selector_args_to_yojson args) with
    | Ok res -> element_handle_wait_for_selector_returns_of_yojson res
    | Error e -> Error e

end

module Request = struct
  let response (conn : Connection.t) (guid : string) () : (request_response_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"response" ~params:(`Assoc []) with
    | Ok res -> request_response_returns_of_yojson res
    | Error e -> Error e

  let raw_request_headers (conn : Connection.t) (guid : string) () : (request_raw_request_headers_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"rawRequestHeaders" ~params:(`Assoc []) with
    | Ok res -> request_raw_request_headers_returns_of_yojson res
    | Error e -> Error e

end

module Route = struct
  let redirect_navigation_request (conn : Connection.t) (guid : string) (args : route_redirect_navigation_request_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"redirectNavigationRequest" ~params:(route_redirect_navigation_request_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let abort (conn : Connection.t) (guid : string) (args : route_abort_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"abort" ~params:(route_abort_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let continue (conn : Connection.t) (guid : string) (args : route_continue_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"continue" ~params:(route_continue_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let fulfill (conn : Connection.t) (guid : string) (args : route_fulfill_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"fulfill" ~params:(route_fulfill_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

end

module Web_socket_route = struct
  let connect (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"connect" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let ensure_opened (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"ensureOpened" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let send_to_page (conn : Connection.t) (guid : string) (args : web_socket_route_send_to_page_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"sendToPage" ~params:(web_socket_route_send_to_page_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let send_to_server (conn : Connection.t) (guid : string) (args : web_socket_route_send_to_server_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"sendToServer" ~params:(web_socket_route_send_to_server_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let close_page (conn : Connection.t) (guid : string) (args : web_socket_route_close_page_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"closePage" ~params:(web_socket_route_close_page_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let close_server (conn : Connection.t) (guid : string) (args : web_socket_route_close_server_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"closeServer" ~params:(web_socket_route_close_server_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

end

module Response = struct
  let body (conn : Connection.t) (guid : string) () : (response_body_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"body" ~params:(`Assoc []) with
    | Ok res -> response_body_returns_of_yojson res
    | Error e -> Error e

  let security_details (conn : Connection.t) (guid : string) () : (response_security_details_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"securityDetails" ~params:(`Assoc []) with
    | Ok res -> response_security_details_returns_of_yojson res
    | Error e -> Error e

  let server_addr (conn : Connection.t) (guid : string) () : (response_server_addr_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"serverAddr" ~params:(`Assoc []) with
    | Ok res -> response_server_addr_returns_of_yojson res
    | Error e -> Error e

  let raw_response_headers (conn : Connection.t) (guid : string) () : (response_raw_response_headers_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"rawResponseHeaders" ~params:(`Assoc []) with
    | Ok res -> response_raw_response_headers_returns_of_yojson res
    | Error e -> Error e

  let http_version (conn : Connection.t) (guid : string) () : (response_http_version_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"httpVersion" ~params:(`Assoc []) with
    | Ok res -> response_http_version_returns_of_yojson res
    | Error e -> Error e

  let sizes (conn : Connection.t) (guid : string) () : (response_sizes_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"sizes" ~params:(`Assoc []) with
    | Ok res -> response_sizes_returns_of_yojson res
    | Error e -> Error e

end

module Web_socket = struct
end

module Binding_call = struct
  let reject (conn : Connection.t) (guid : string) (args : binding_call_reject_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"reject" ~params:(binding_call_reject_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let resolve (conn : Connection.t) (guid : string) (args : binding_call_resolve_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"resolve" ~params:(binding_call_resolve_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

end

module Debugger = struct
  let request_pause (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"requestPause" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let resume (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"resume" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let next (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"next" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let run_to (conn : Connection.t) (guid : string) (args : debugger_run_to_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"runTo" ~params:(debugger_run_to_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

end

module Dialog = struct
  let accept (conn : Connection.t) (guid : string) (args : dialog_accept_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"accept" ~params:(dialog_accept_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let dismiss (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"dismiss" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

end

module Tracing = struct
  let tracing_start (conn : Connection.t) (guid : string) (args : tracing_tracing_start_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"tracingStart" ~params:(tracing_tracing_start_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let tracing_start_chunk (conn : Connection.t) (guid : string) (args : tracing_tracing_start_chunk_args) : (tracing_tracing_start_chunk_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"tracingStartChunk" ~params:(tracing_tracing_start_chunk_args_to_yojson args) with
    | Ok res -> tracing_tracing_start_chunk_returns_of_yojson res
    | Error e -> Error e

  let tracing_group (conn : Connection.t) (guid : string) (args : tracing_tracing_group_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"tracingGroup" ~params:(tracing_tracing_group_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let tracing_group_end (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"tracingGroupEnd" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let tracing_stop_chunk (conn : Connection.t) (guid : string) (args : tracing_tracing_stop_chunk_args) : (tracing_tracing_stop_chunk_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"tracingStopChunk" ~params:(tracing_tracing_stop_chunk_args_to_yojson args) with
    | Ok res -> tracing_tracing_stop_chunk_returns_of_yojson res
    | Error e -> Error e

  let tracing_stop (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"tracingStop" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let har_start (conn : Connection.t) (guid : string) (args : tracing_har_start_args) : (tracing_har_start_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"harStart" ~params:(tracing_har_start_args_to_yojson args) with
    | Ok res -> tracing_har_start_returns_of_yojson res
    | Error e -> Error e

  let har_export (conn : Connection.t) (guid : string) (args : tracing_har_export_args) : (tracing_har_export_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"harExport" ~params:(tracing_har_export_args_to_yojson args) with
    | Ok res -> tracing_har_export_returns_of_yojson res
    | Error e -> Error e

end

module Artifact = struct
  let path_after_finished (conn : Connection.t) (guid : string) () : (artifact_path_after_finished_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"pathAfterFinished" ~params:(`Assoc []) with
    | Ok res -> artifact_path_after_finished_returns_of_yojson res
    | Error e -> Error e

  let save_as (conn : Connection.t) (guid : string) (args : artifact_save_as_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"saveAs" ~params:(artifact_save_as_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let save_as_stream (conn : Connection.t) (guid : string) () : (artifact_save_as_stream_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"saveAsStream" ~params:(`Assoc []) with
    | Ok res -> artifact_save_as_stream_returns_of_yojson res
    | Error e -> Error e

  let failure (conn : Connection.t) (guid : string) () : (artifact_failure_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"failure" ~params:(`Assoc []) with
    | Ok res -> artifact_failure_returns_of_yojson res
    | Error e -> Error e

  let stream (conn : Connection.t) (guid : string) () : (artifact_stream_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"stream" ~params:(`Assoc []) with
    | Ok res -> artifact_stream_returns_of_yojson res
    | Error e -> Error e

  let cancel (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"cancel" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let delete (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"delete" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

end

module Stream = struct
  let read (conn : Connection.t) (guid : string) (args : stream_read_args) : (stream_read_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"read" ~params:(stream_read_args_to_yojson args) with
    | Ok res -> stream_read_returns_of_yojson res
    | Error e -> Error e

  let close (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"close" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

end

module Writable_stream = struct
  let write (conn : Connection.t) (guid : string) (args : writable_stream_write_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"write" ~params:(writable_stream_write_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let close (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"close" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

end

module Cdp_session = struct
  let send (conn : Connection.t) (guid : string) (args : cdp_session_send_args) : (cdp_session_send_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"send" ~params:(cdp_session_send_args_to_yojson args) with
    | Ok res -> cdp_session_send_returns_of_yojson res
    | Error e -> Error e

  let detach (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"detach" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

end

module Android = struct
  let devices (conn : Connection.t) (guid : string) (args : android_devices_args) : (android_devices_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"devices" ~params:(android_devices_args_to_yojson args) with
    | Ok res -> android_devices_returns_of_yojson res
    | Error e -> Error e

end

module Android_socket = struct
  let write (conn : Connection.t) (guid : string) (args : android_socket_write_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"write" ~params:(android_socket_write_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let close (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"close" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

end

module Android_device = struct
  let wait (conn : Connection.t) (guid : string) (args : android_device_wait_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"wait" ~params:(android_device_wait_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let fill (conn : Connection.t) (guid : string) (args : android_device_fill_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"fill" ~params:(android_device_fill_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let tap (conn : Connection.t) (guid : string) (args : android_device_tap_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"tap" ~params:(android_device_tap_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let drag (conn : Connection.t) (guid : string) (args : android_device_drag_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"drag" ~params:(android_device_drag_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let fling (conn : Connection.t) (guid : string) (args : android_device_fling_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"fling" ~params:(android_device_fling_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let long_tap (conn : Connection.t) (guid : string) (args : android_device_long_tap_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"longTap" ~params:(android_device_long_tap_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let pinch_close (conn : Connection.t) (guid : string) (args : android_device_pinch_close_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"pinchClose" ~params:(android_device_pinch_close_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let pinch_open (conn : Connection.t) (guid : string) (args : android_device_pinch_open_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"pinchOpen" ~params:(android_device_pinch_open_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let scroll (conn : Connection.t) (guid : string) (args : android_device_scroll_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"scroll" ~params:(android_device_scroll_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let swipe (conn : Connection.t) (guid : string) (args : android_device_swipe_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"swipe" ~params:(android_device_swipe_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let info (conn : Connection.t) (guid : string) (args : android_device_info_args) : (android_device_info_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"info" ~params:(android_device_info_args_to_yojson args) with
    | Ok res -> android_device_info_returns_of_yojson res
    | Error e -> Error e

  let screenshot (conn : Connection.t) (guid : string) () : (android_device_screenshot_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"screenshot" ~params:(`Assoc []) with
    | Ok res -> android_device_screenshot_returns_of_yojson res
    | Error e -> Error e

  let input_type (conn : Connection.t) (guid : string) (args : android_device_input_type_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"inputType" ~params:(android_device_input_type_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let input_press (conn : Connection.t) (guid : string) (args : android_device_input_press_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"inputPress" ~params:(android_device_input_press_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let input_tap (conn : Connection.t) (guid : string) (args : android_device_input_tap_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"inputTap" ~params:(android_device_input_tap_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let input_swipe (conn : Connection.t) (guid : string) (args : android_device_input_swipe_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"inputSwipe" ~params:(android_device_input_swipe_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let input_drag (conn : Connection.t) (guid : string) (args : android_device_input_drag_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"inputDrag" ~params:(android_device_input_drag_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let launch_browser (conn : Connection.t) (guid : string) (args : android_device_launch_browser_args) : (android_device_launch_browser_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"launchBrowser" ~params:(android_device_launch_browser_args_to_yojson args) with
    | Ok res -> android_device_launch_browser_returns_of_yojson res
    | Error e -> Error e

  let open_ (conn : Connection.t) (guid : string) (args : android_device_open_args) : (android_device_open_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"open" ~params:(android_device_open_args_to_yojson args) with
    | Ok res -> android_device_open_returns_of_yojson res
    | Error e -> Error e

  let shell (conn : Connection.t) (guid : string) (args : android_device_shell_args) : (android_device_shell_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"shell" ~params:(android_device_shell_args_to_yojson args) with
    | Ok res -> android_device_shell_returns_of_yojson res
    | Error e -> Error e

  let install_apk (conn : Connection.t) (guid : string) (args : android_device_install_apk_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"installApk" ~params:(android_device_install_apk_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let push (conn : Connection.t) (guid : string) (args : android_device_push_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"push" ~params:(android_device_push_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let connect_to_web_view (conn : Connection.t) (guid : string) (args : android_device_connect_to_web_view_args) : (android_device_connect_to_web_view_returns, string) result =
    match Connection.send_message conn ~guid ~method_:"connectToWebView" ~params:(android_device_connect_to_web_view_args_to_yojson args) with
    | Ok res -> android_device_connect_to_web_view_returns_of_yojson res
    | Error e -> Error e

  let close (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"close" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

end

module Json_pipe = struct
  let send (conn : Connection.t) (guid : string) (args : json_pipe_send_args) : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"send" ~params:(json_pipe_send_args_to_yojson args) with
    | Ok _res -> Ok ()
    | Error e -> Error e

  let close (conn : Connection.t) (guid : string) () : (unit, string) result =
    match Connection.send_message conn ~guid ~method_:"close" ~params:(`Assoc []) with
    | Ok _res -> Ok ()
    | Error e -> Error e

end

