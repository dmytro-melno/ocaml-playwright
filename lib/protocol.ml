[@@@ocaml.warning "-39-32-34"]

type channel = { guid: string } [@@deriving yojson { strict = false }]

type any = Yojson.Safe.t [@@deriving yojson]

type json = Yojson.Safe.t [@@deriving yojson]

type serialized_value_r =
  {
    serialized_value_r_p: string [@key "p"];
    serialized_value_r_f: string [@key "f"];
  } [@@deriving yojson { strict = false }]

type serialized_value_e =
  {
    serialized_value_e_m: string [@key "m"];
    serialized_value_e_n: string [@key "n"];
    serialized_value_e_s: string [@key "s"];
  } [@@deriving yojson { strict = false }]

type serialized_value_ta_k =
  [
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
  ] [@@deriving yojson]

type serialized_value_ta =
  {
    serialized_value_ta_b: string [@key "b"];
    serialized_value_ta_k: serialized_value_ta_k [@key "k"];
  } [@@deriving yojson { strict = false }]

type serialized_value_v =
  [
  | `Null
  | `Undefined
  | `Nan
  | `Inf
  | `Inf
  | `V_0
  ] [@@deriving yojson]

type serialized_value =
  {
    serialized_value_n: float option [@key "n"] [@default None];
    serialized_value_b: bool option [@key "b"] [@default None];
    serialized_value_s: string option [@key "s"] [@default None];
    serialized_value_v: serialized_value_v option [@key "v"] [@default None];
    serialized_value_d: string option [@key "d"] [@default None];
    serialized_value_u: string option [@key "u"] [@default None];
    serialized_value_bi: string option [@key "bi"] [@default None];
    serialized_value_ta: serialized_value_ta option [@key "ta"] [@default None];
    serialized_value_e: serialized_value_e option [@key "e"] [@default None];
    serialized_value_r: serialized_value_r option [@key "r"] [@default None];
    serialized_value_a: serialized_value list option [@key "a"] [@default None];
    serialized_value_o: serialized_value_o_item list option [@key "o"] [@default None];
    serialized_value_h: int option [@key "h"] [@default None];
    serialized_value_id: int option [@key "id"] [@default None];
    serialized_value_ref: int option [@key "ref"] [@default None];
  } [@@deriving yojson { strict = false }]

and serialized_value_o_item =
  {
    serialized_value_o_item_k: string [@key "k"];
    serialized_value_o_item_v: serialized_value [@key "v"];
  } [@@deriving yojson { strict = false }]

type serialized_argument =
  {
    serialized_argument_value: serialized_value [@key "value"];
    serialized_argument_handles: channel list [@key "handles"];
  } [@@deriving yojson { strict = false }]

type frame_wait_for_function_args =
  {
    frame_wait_for_function_args_expression: string [@key "expression"];
    frame_wait_for_function_args_is_function: bool option [@key "isFunction"] [@default None];
    frame_wait_for_function_args_arg: serialized_argument [@key "arg"];
    frame_wait_for_function_args_timeout: float [@key "timeout"];
    frame_wait_for_function_args_polling_interval: float option [@key "pollingInterval"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_mouse_down_args_button =
  [
  | `Left
  | `Right
  | `Middle
  ] [@@deriving yojson]

type page_stop_js_coverage_returns_entries_item_functions_item_ranges_item =
  {
    page_stop_js_coverage_returns_entries_item_functions_item_ranges_item_start_offset: int [@key "startOffset"];
    page_stop_js_coverage_returns_entries_item_functions_item_ranges_item_end_offset: int [@key "endOffset"];
    page_stop_js_coverage_returns_entries_item_functions_item_ranges_item_count: int [@key "count"];
  } [@@deriving yojson { strict = false }]

type page_stop_js_coverage_returns_entries_item_functions_item =
  {
    page_stop_js_coverage_returns_entries_item_functions_item_function_name: string [@key "functionName"];
    page_stop_js_coverage_returns_entries_item_functions_item_is_block_coverage: bool [@key "isBlockCoverage"];
    page_stop_js_coverage_returns_entries_item_functions_item_ranges: page_stop_js_coverage_returns_entries_item_functions_item_ranges_item list [@key "ranges"];
  } [@@deriving yojson { strict = false }]

type playwright_new_request_args_http_credentials_send =
  [
  | `Always
  | `Unauthorized
  ] [@@deriving yojson]

type playwright_new_request_args_http_credentials =
  {
    playwright_new_request_args_http_credentials_username: string [@key "username"];
    playwright_new_request_args_http_credentials_password: string [@key "password"];
    playwright_new_request_args_http_credentials_origin: string option [@key "origin"] [@default None];
    playwright_new_request_args_http_credentials_send: playwright_new_request_args_http_credentials_send option [@key "send"] [@default None];
  } [@@deriving yojson { strict = false }]

type indexed_db_database_stores_item_indexes_item =
  {
    indexed_db_database_stores_item_indexes_item_name: string [@key "name"];
    indexed_db_database_stores_item_indexes_item_key_path: string option [@key "keyPath"] [@default None];
    indexed_db_database_stores_item_indexes_item_key_path_array: string list option [@key "keyPathArray"] [@default None];
    indexed_db_database_stores_item_indexes_item_multi_entry: bool [@key "multiEntry"];
    indexed_db_database_stores_item_indexes_item_unique: bool [@key "unique"];
  } [@@deriving yojson { strict = false }]

type indexed_db_database_stores_item_records_item =
  {
    indexed_db_database_stores_item_records_item_key: json option [@key "key"] [@default None];
    indexed_db_database_stores_item_records_item_key_encoded: json option [@key "keyEncoded"] [@default None];
    indexed_db_database_stores_item_records_item_value: json option [@key "value"] [@default None];
    indexed_db_database_stores_item_records_item_value_encoded: json option [@key "valueEncoded"] [@default None];
  } [@@deriving yojson { strict = false }]

type indexed_db_database_stores_item =
  {
    indexed_db_database_stores_item_name: string [@key "name"];
    indexed_db_database_stores_item_auto_increment: bool [@key "autoIncrement"];
    indexed_db_database_stores_item_key_path: string option [@key "keyPath"] [@default None];
    indexed_db_database_stores_item_key_path_array: string list option [@key "keyPathArray"] [@default None];
    indexed_db_database_stores_item_records: indexed_db_database_stores_item_records_item list [@key "records"];
    indexed_db_database_stores_item_indexes: indexed_db_database_stores_item_indexes_item list [@key "indexes"];
  } [@@deriving yojson { strict = false }]

type indexed_db_database =
  {
    indexed_db_database_name: string [@key "name"];
    indexed_db_database_version: int [@key "version"];
    indexed_db_database_stores: indexed_db_database_stores_item list [@key "stores"];
  } [@@deriving yojson { strict = false }]

type name_value =
  {
    name_value_name: string [@key "name"];
    name_value_value: string [@key "value"];
  } [@@deriving yojson { strict = false }]

type set_origin_storage =
  {
    set_origin_storage_origin: string [@key "origin"];
    set_origin_storage_local_storage: name_value list [@key "localStorage"];
    set_origin_storage_indexed_db: indexed_db_database list option [@key "indexedDB"] [@default None];
  } [@@deriving yojson { strict = false }]

type set_network_cookie_same_site =
  [
  | `Strict
  | `Lax
  | `None
  ] [@@deriving yojson]

type set_network_cookie =
  {
    set_network_cookie_name: string [@key "name"];
    set_network_cookie_value: string [@key "value"];
    set_network_cookie_url: string option [@key "url"] [@default None];
    set_network_cookie_domain: string option [@key "domain"] [@default None];
    set_network_cookie_path: string option [@key "path"] [@default None];
    set_network_cookie_expires: float option [@key "expires"] [@default None];
    set_network_cookie_http_only: bool option [@key "httpOnly"] [@default None];
    set_network_cookie_secure: bool option [@key "secure"] [@default None];
    set_network_cookie_same_site: set_network_cookie_same_site option [@key "sameSite"] [@default None];
    set_network_cookie_partition_key: string option [@key "partitionKey"] [@default None];
    set_network_cookie_cr_has_cross_site_ancestor: bool option [@key "_crHasCrossSiteAncestor"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_set_storage_state_args_storage_state =
  {
    browser_context_set_storage_state_args_storage_state_cookies: set_network_cookie list option [@key "cookies"] [@default None];
    browser_context_set_storage_state_args_storage_state_origins: set_origin_storage list option [@key "origins"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_set_storage_state_args =
  {
    browser_context_set_storage_state_args_storage_state: browser_context_set_storage_state_args_storage_state option [@key "storageState"] [@default None];
  } [@@deriving yojson { strict = false }]

type tracing_tracing_stop_chunk_args_mode =
  [
  | `Archive
  | `Discard
  | `Entries
  ] [@@deriving yojson]

type tracing_tracing_stop_chunk_args =
  {
    tracing_tracing_stop_chunk_args_mode: tracing_tracing_stop_chunk_args_mode [@key "mode"];
  } [@@deriving yojson { strict = false }]

type page_resolve_locator_handler_no_reply_args =
  {
    page_resolve_locator_handler_no_reply_args_uid: int [@key "uid"];
    page_resolve_locator_handler_no_reply_args_remove: bool option [@key "remove"] [@default None];
  } [@@deriving yojson { strict = false }]

type context_options_reduced_motion =
  [
  | `Reduce
  | `No_preference
  | `No_override
  ] [@@deriving yojson]

type common_screenshot_options_caret =
  [
  | `Hide
  | `Initial
  ] [@@deriving yojson]

type lifecycle_event =
  [
  | `Load
  | `Domcontentloaded
  | `Networkidle
  | `Commit
  ] [@@deriving yojson]

type page_go_forward_args =
  {
    page_go_forward_args_timeout: float [@key "timeout"];
    page_go_forward_args_wait_until: lifecycle_event option [@key "waitUntil"] [@default None];
  } [@@deriving yojson { strict = false }]

type context_options_geolocation =
  {
    context_options_geolocation_longitude: float [@key "longitude"];
    context_options_geolocation_latitude: float [@key "latitude"];
    context_options_geolocation_accuracy: float option [@key "accuracy"] [@default None];
  } [@@deriving yojson { strict = false }]

type socks_support_socks_failed_args =
  {
    socks_support_socks_failed_args_uid: string [@key "uid"];
    socks_support_socks_failed_args_error_code: string [@key "errorCode"];
  } [@@deriving yojson { strict = false }]

type page_keyboard_up_args =
  {
    page_keyboard_up_args_key: string [@key "key"];
  } [@@deriving yojson { strict = false }]

type browser_new_context_args_storage_state =
  {
    browser_new_context_args_storage_state_cookies: set_network_cookie list option [@key "cookies"] [@default None];
    browser_new_context_args_storage_state_origins: set_origin_storage list option [@key "origins"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_is_hidden_args =
  {
    frame_is_hidden_args_selector: string [@key "selector"];
    frame_is_hidden_args_strict: bool option [@key "strict"] [@default None];
  } [@@deriving yojson { strict = false }]

type json_pipe_send_args =
  {
    json_pipe_send_args_message: json [@key "message"];
  } [@@deriving yojson { strict = false }]

type browser_context_set_test_id_attribute_name_args =
  {
    browser_context_set_test_id_attribute_name_args_test_id_attribute_name: string [@key "testIdAttributeName"];
  } [@@deriving yojson { strict = false }]

type serialized_error_error =
  {
    serialized_error_error_message: string [@key "message"];
    serialized_error_error_name: string [@key "name"];
    serialized_error_error_stack: string option [@key "stack"] [@default None];
  } [@@deriving yojson { strict = false }]

type serialized_error =
  {
    serialized_error_error: serialized_error_error option [@key "error"] [@default None];
    serialized_error_value: serialized_value option [@key "value"] [@default None];
  } [@@deriving yojson { strict = false }]

type binding_call_reject_args =
  {
    binding_call_reject_args_error: serialized_error [@key "error"];
  } [@@deriving yojson { strict = false }]

type page_mouse_up_args_button =
  [
  | `Left
  | `Right
  | `Middle
  ] [@@deriving yojson]

type page_mouse_up_args =
  {
    page_mouse_up_args_button: page_mouse_up_args_button option [@key "button"] [@default None];
    page_mouse_up_args_click_count: int option [@key "clickCount"] [@default None];
  } [@@deriving yojson { strict = false }]

type local_utils_har_lookup_returns_action =
  [
  | `Error
  | `Redirect
  | `Fulfill
  | `Noentry
  ] [@@deriving yojson]

type local_utils_har_lookup_returns =
  {
    local_utils_har_lookup_returns_action: local_utils_har_lookup_returns_action [@key "action"];
    local_utils_har_lookup_returns_message: string option [@key "message"] [@default None];
    local_utils_har_lookup_returns_redirect_url: string option [@key "redirectURL"] [@default None];
    local_utils_har_lookup_returns_status: int option [@key "status"] [@default None];
    local_utils_har_lookup_returns_headers: name_value list option [@key "headers"] [@default None];
    local_utils_har_lookup_returns_body: string option [@key "body"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_aria_snapshot_returns =
  {
    frame_aria_snapshot_returns_snapshot: string [@key "snapshot"];
  } [@@deriving yojson { strict = false }]

type browser_context_storage_state_args =
  {
    browser_context_storage_state_args_indexed_db: bool option [@key "indexedDB"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_wait_for_selector_args_state =
  [
  | `Attached
  | `Detached
  | `Visible
  | `Hidden
  ] [@@deriving yojson]

type frame_wait_for_selector_args =
  {
    frame_wait_for_selector_args_selector: string [@key "selector"];
    frame_wait_for_selector_args_strict: bool option [@key "strict"] [@default None];
    frame_wait_for_selector_args_timeout: float [@key "timeout"];
    frame_wait_for_selector_args_state: frame_wait_for_selector_args_state option [@key "state"] [@default None];
    frame_wait_for_selector_args_omit_return_value: bool option [@key "omitReturnValue"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_screencast_chapter_args =
  {
    page_screencast_chapter_args_title: string [@key "title"];
    page_screencast_chapter_args_description: string option [@key "description"] [@default None];
    page_screencast_chapter_args_duration: float option [@key "duration"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_select_option_returns =
  {
    element_handle_select_option_returns_values: string list [@key "values"];
  } [@@deriving yojson { strict = false }]

type socks_support_socks_data_event =
  {
    socks_support_socks_data_event_uid: string [@key "uid"];
    socks_support_socks_data_event_data: string [@key "data"];
  } [@@deriving yojson { strict = false }]

type artifact_path_after_finished_returns =
  {
    artifact_path_after_finished_returns_value: string [@key "value"];
  } [@@deriving yojson { strict = false }]

type binding_call_initializer =
  {
    binding_call_initializer_frame: channel [@key "frame"];
    binding_call_initializer_name: string [@key "name"];
    binding_call_initializer_args: serialized_value list [@key "args"];
  } [@@deriving yojson { strict = false }]

type web_socket_route_close_page_args =
  {
    web_socket_route_close_page_args_code: int option [@key "code"] [@default None];
    web_socket_route_close_page_args_reason: string option [@key "reason"] [@default None];
    web_socket_route_close_page_args_was_clean: bool [@key "wasClean"];
  } [@@deriving yojson { strict = false }]

type element_handle_dblclick_args_button =
  [
  | `Left
  | `Right
  | `Middle
  ] [@@deriving yojson]

type point =
  {
    point_x: float [@key "x"];
    point_y: float [@key "y"];
  } [@@deriving yojson { strict = false }]

type element_handle_dblclick_args_modifiers_item =
  [
  | `Alt
  | `Control
  | `Control_or_meta
  | `Meta
  | `Shift
  ] [@@deriving yojson]

type element_handle_dblclick_args =
  {
    element_handle_dblclick_args_force: bool option [@key "force"] [@default None];
    element_handle_dblclick_args_modifiers: element_handle_dblclick_args_modifiers_item list option [@key "modifiers"] [@default None];
    element_handle_dblclick_args_position: point option [@key "position"] [@default None];
    element_handle_dblclick_args_delay: float option [@key "delay"] [@default None];
    element_handle_dblclick_args_button: element_handle_dblclick_args_button option [@key "button"] [@default None];
    element_handle_dblclick_args_timeout: float [@key "timeout"];
    element_handle_dblclick_args_trial: bool option [@key "trial"] [@default None];
    element_handle_dblclick_args_steps: int option [@key "steps"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_device_swipe_args_direction =
  [
  | `Up
  | `Down
  | `Left
  | `Right
  ] [@@deriving yojson]

type android_selector =
  {
    android_selector_checkable: bool option [@key "checkable"] [@default None];
    android_selector_checked: bool option [@key "checked"] [@default None];
    android_selector_clazz: string option [@key "clazz"] [@default None];
    android_selector_clickable: bool option [@key "clickable"] [@default None];
    android_selector_depth: int option [@key "depth"] [@default None];
    android_selector_desc: string option [@key "desc"] [@default None];
    android_selector_enabled: bool option [@key "enabled"] [@default None];
    android_selector_focusable: bool option [@key "focusable"] [@default None];
    android_selector_focused: bool option [@key "focused"] [@default None];
    android_selector_has_child: android_selector_has_child option [@key "hasChild"] [@default None];
    android_selector_has_descendant: android_selector_has_descendant option [@key "hasDescendant"] [@default None];
    android_selector_long_clickable: bool option [@key "longClickable"] [@default None];
    android_selector_pkg: string option [@key "pkg"] [@default None];
    android_selector_res: string option [@key "res"] [@default None];
    android_selector_scrollable: bool option [@key "scrollable"] [@default None];
    android_selector_selected: bool option [@key "selected"] [@default None];
    android_selector_text: string option [@key "text"] [@default None];
  } [@@deriving yojson { strict = false }]

and android_selector_has_descendant =
  {
    android_selector_has_descendant_android_selector: android_selector [@key "androidSelector"];
    android_selector_has_descendant_max_depth: int option [@key "maxDepth"] [@default None];
  } [@@deriving yojson { strict = false }]

and android_selector_has_child =
  {
    android_selector_has_child_android_selector: android_selector [@key "androidSelector"];
  } [@@deriving yojson { strict = false }]

type android_device_swipe_args =
  {
    android_device_swipe_args_android_selector: android_selector [@key "androidSelector"];
    android_device_swipe_args_direction: android_device_swipe_args_direction [@key "direction"];
    android_device_swipe_args_percent: float [@key "percent"];
    android_device_swipe_args_speed: float option [@key "speed"] [@default None];
    android_device_swipe_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type page_initializer_viewport_size =
  {
    page_initializer_viewport_size_width: int [@key "width"];
    page_initializer_viewport_size_height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type frame_drag_and_drop_args =
  {
    frame_drag_and_drop_args_source: string [@key "source"];
    frame_drag_and_drop_args_target: string [@key "target"];
    frame_drag_and_drop_args_force: bool option [@key "force"] [@default None];
    frame_drag_and_drop_args_timeout: float [@key "timeout"];
    frame_drag_and_drop_args_trial: bool option [@key "trial"] [@default None];
    frame_drag_and_drop_args_source_position: point option [@key "sourcePosition"] [@default None];
    frame_drag_and_drop_args_target_position: point option [@key "targetPosition"] [@default None];
    frame_drag_and_drop_args_strict: bool option [@key "strict"] [@default None];
    frame_drag_and_drop_args_steps: int option [@key "steps"] [@default None];
  } [@@deriving yojson { strict = false }]

type context_options_color_scheme =
  [
  | `Dark
  | `Light
  | `No_preference
  | `No_override
  ] [@@deriving yojson]

type context_options_client_certificates_item =
  {
    context_options_client_certificates_item_origin: string [@key "origin"];
    context_options_client_certificates_item_cert: string option [@key "cert"] [@default None];
    context_options_client_certificates_item_key: string option [@key "key"] [@default None];
    context_options_client_certificates_item_passphrase: string option [@key "passphrase"] [@default None];
    context_options_client_certificates_item_pfx: string option [@key "pfx"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_reload_args =
  {
    page_reload_args_timeout: float [@key "timeout"];
    page_reload_args_wait_until: lifecycle_event option [@key "waitUntil"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_set_dock_tile_args =
  {
    page_set_dock_tile_args_image: string [@key "image"];
  } [@@deriving yojson { strict = false }]

type page_worker_event =
  {
    page_worker_event_worker: channel [@key "worker"];
  } [@@deriving yojson { strict = false }]

type browser_context_set_geolocation_args_geolocation =
  {
    browser_context_set_geolocation_args_geolocation_longitude: float [@key "longitude"];
    browser_context_set_geolocation_args_geolocation_latitude: float [@key "latitude"];
    browser_context_set_geolocation_args_geolocation_accuracy: float option [@key "accuracy"] [@default None];
  } [@@deriving yojson { strict = false }]

type local_utils_initializer_device_descriptors_item_descriptor_default_browser_type =
  [
  | `Chromium
  | `Firefox
  | `Webkit
  ] [@@deriving yojson]

type local_utils_initializer_device_descriptors_item_descriptor_screen =
  {
    local_utils_initializer_device_descriptors_item_descriptor_screen_width: int [@key "width"];
    local_utils_initializer_device_descriptors_item_descriptor_screen_height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type local_utils_initializer_device_descriptors_item_descriptor_viewport =
  {
    local_utils_initializer_device_descriptors_item_descriptor_viewport_width: int [@key "width"];
    local_utils_initializer_device_descriptors_item_descriptor_viewport_height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type local_utils_initializer_device_descriptors_item_descriptor =
  {
    local_utils_initializer_device_descriptors_item_descriptor_user_agent: string [@key "userAgent"];
    local_utils_initializer_device_descriptors_item_descriptor_viewport: local_utils_initializer_device_descriptors_item_descriptor_viewport [@key "viewport"];
    local_utils_initializer_device_descriptors_item_descriptor_screen: local_utils_initializer_device_descriptors_item_descriptor_screen option [@key "screen"] [@default None];
    local_utils_initializer_device_descriptors_item_descriptor_device_scale_factor: float [@key "deviceScaleFactor"];
    local_utils_initializer_device_descriptors_item_descriptor_is_mobile: bool [@key "isMobile"];
    local_utils_initializer_device_descriptors_item_descriptor_has_touch: bool [@key "hasTouch"];
    local_utils_initializer_device_descriptors_item_descriptor_default_browser_type: local_utils_initializer_device_descriptors_item_descriptor_default_browser_type [@key "defaultBrowserType"];
  } [@@deriving yojson { strict = false }]

type local_utils_initializer_device_descriptors_item =
  {
    local_utils_initializer_device_descriptors_item_name: string [@key "name"];
    local_utils_initializer_device_descriptors_item_descriptor: local_utils_initializer_device_descriptors_item_descriptor [@key "descriptor"];
  } [@@deriving yojson { strict = false }]

type page_close_args =
  {
    page_close_args_run_before_unload: bool option [@key "runBeforeUnload"] [@default None];
    page_close_args_reason: string option [@key "reason"] [@default None];
  } [@@deriving yojson { strict = false }]

type local_utils_har_open_args =
  {
    local_utils_har_open_args_file: string [@key "file"];
  } [@@deriving yojson { strict = false }]

type tracing_tracing_start_args =
  {
    tracing_tracing_start_args_name: string option [@key "name"] [@default None];
    tracing_tracing_start_args_snapshots: bool option [@key "snapshots"] [@default None];
    tracing_tracing_start_args_screenshots: bool option [@key "screenshots"] [@default None];
    tracing_tracing_start_args_live: bool option [@key "live"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_screencast_show_overlay_args =
  {
    page_screencast_show_overlay_args_html: string [@key "html"];
    page_screencast_show_overlay_args_duration: float option [@key "duration"] [@default None];
  } [@@deriving yojson { strict = false }]

type remote_addr =
  {
    remote_addr_ip_address: string [@key "ipAddress"];
    remote_addr_port: int [@key "port"];
  } [@@deriving yojson { strict = false }]

type response_server_addr_returns =
  {
    response_server_addr_returns_value: remote_addr option [@key "value"] [@default None];
  } [@@deriving yojson { strict = false }]

type api_request_context_fetch_log_args =
  {
    api_request_context_fetch_log_args_fetch_uid: string [@key "fetchUid"];
  } [@@deriving yojson { strict = false }]

type android_socket_write_args =
  {
    android_socket_write_args_data: string [@key "data"];
  } [@@deriving yojson { strict = false }]

type web_socket_route_close_server_args =
  {
    web_socket_route_close_server_args_code: int option [@key "code"] [@default None];
    web_socket_route_close_server_args_reason: string option [@key "reason"] [@default None];
    web_socket_route_close_server_args_was_clean: bool [@key "wasClean"];
  } [@@deriving yojson { strict = false }]

type element_handle_set_input_files_args_payloads_item =
  {
    element_handle_set_input_files_args_payloads_item_name: string [@key "name"];
    element_handle_set_input_files_args_payloads_item_mime_type: string option [@key "mimeType"] [@default None];
    element_handle_set_input_files_args_payloads_item_buffer: string [@key "buffer"];
  } [@@deriving yojson { strict = false }]

type element_handle_inner_htm_l_returns =
  {
    element_handle_inner_htm_l_returns_value: string [@key "value"];
  } [@@deriving yojson { strict = false }]

type local_utils_trace_discarded_args =
  {
    local_utils_trace_discarded_args_stacks_id: string [@key "stacksId"];
  } [@@deriving yojson { strict = false }]

type element_handle_eval_on_selector_all_returns =
  {
    element_handle_eval_on_selector_all_returns_value: serialized_value [@key "value"];
  } [@@deriving yojson { strict = false }]

type selector_engine =
  {
    selector_engine_name: string [@key "name"];
    selector_engine_source: string [@key "source"];
    selector_engine_content_script: bool option [@key "contentScript"] [@default None];
  } [@@deriving yojson { strict = false }]

type context_options_service_workers =
  [
  | `Allow
  | `Block
  ] [@@deriving yojson]

type show_actions_options_position =
  [
  | `Top_left
  | `Top
  | `Top_right
  | `Bottom_left
  | `Bottom
  | `Bottom_right
  ] [@@deriving yojson]

type show_actions_options =
  {
    show_actions_options_duration: float option [@key "duration"] [@default None];
    show_actions_options_position: show_actions_options_position option [@key "position"] [@default None];
    show_actions_options_font_size: int option [@key "fontSize"] [@default None];
  } [@@deriving yojson { strict = false }]

type context_options_record_video_show_actions =
  {
    context_options_record_video_show_actions_mixin: show_actions_options [@key "$mixin"];
  } [@@deriving yojson { strict = false }]

type context_options_record_video_size =
  {
    context_options_record_video_size_width: int [@key "width"];
    context_options_record_video_size_height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type context_options_record_video =
  {
    context_options_record_video_dir: string option [@key "dir"] [@default None];
    context_options_record_video_size: context_options_record_video_size option [@key "size"] [@default None];
    context_options_record_video_show_actions: context_options_record_video_show_actions option [@key "showActions"] [@default None];
  } [@@deriving yojson { strict = false }]

type context_options_contrast =
  [
  | `No_preference
  | `More
  | `No_override
  ] [@@deriving yojson]

type context_options_accept_downloads =
  [
  | `Accept
  | `Deny
  | `Internal_browser_default
  ] [@@deriving yojson]

type context_options_forced_colors =
  [
  | `Active
  | `None
  | `No_override
  ] [@@deriving yojson]

type context_options_http_credentials_send =
  [
  | `Always
  | `Unauthorized
  ] [@@deriving yojson]

type context_options_http_credentials =
  {
    context_options_http_credentials_username: string [@key "username"];
    context_options_http_credentials_password: string [@key "password"];
    context_options_http_credentials_origin: string option [@key "origin"] [@default None];
    context_options_http_credentials_send: context_options_http_credentials_send option [@key "send"] [@default None];
  } [@@deriving yojson { strict = false }]

type context_options_screen =
  {
    context_options_screen_width: int [@key "width"];
    context_options_screen_height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type context_options_viewport =
  {
    context_options_viewport_width: int [@key "width"];
    context_options_viewport_height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type context_options =
  {
    context_options_no_default_viewport: bool option [@key "noDefaultViewport"] [@default None];
    context_options_viewport: context_options_viewport option [@key "viewport"] [@default None];
    context_options_screen: context_options_screen option [@key "screen"] [@default None];
    context_options_ignore_https_errors: bool option [@key "ignoreHTTPSErrors"] [@default None];
    context_options_client_certificates: context_options_client_certificates_item list option [@key "clientCertificates"] [@default None];
    context_options_java_script_enabled: bool option [@key "javaScriptEnabled"] [@default None];
    context_options_bypass_csp: bool option [@key "bypassCSP"] [@default None];
    context_options_user_agent: string option [@key "userAgent"] [@default None];
    context_options_locale: string option [@key "locale"] [@default None];
    context_options_timezone_id: string option [@key "timezoneId"] [@default None];
    context_options_geolocation: context_options_geolocation option [@key "geolocation"] [@default None];
    context_options_permissions: string list option [@key "permissions"] [@default None];
    context_options_extra_http_headers: name_value list option [@key "extraHTTPHeaders"] [@default None];
    context_options_offline: bool option [@key "offline"] [@default None];
    context_options_http_credentials: context_options_http_credentials option [@key "httpCredentials"] [@default None];
    context_options_device_scale_factor: float option [@key "deviceScaleFactor"] [@default None];
    context_options_is_mobile: bool option [@key "isMobile"] [@default None];
    context_options_has_touch: bool option [@key "hasTouch"] [@default None];
    context_options_color_scheme: context_options_color_scheme option [@key "colorScheme"] [@default None];
    context_options_reduced_motion: context_options_reduced_motion option [@key "reducedMotion"] [@default None];
    context_options_forced_colors: context_options_forced_colors option [@key "forcedColors"] [@default None];
    context_options_accept_downloads: context_options_accept_downloads option [@key "acceptDownloads"] [@default None];
    context_options_contrast: context_options_contrast option [@key "contrast"] [@default None];
    context_options_base_url: string option [@key "baseURL"] [@default None];
    context_options_record_video: context_options_record_video option [@key "recordVideo"] [@default None];
    context_options_strict_selectors: bool option [@key "strictSelectors"] [@default None];
    context_options_service_workers: context_options_service_workers option [@key "serviceWorkers"] [@default None];
    context_options_selector_engines: selector_engine list option [@key "selectorEngines"] [@default None];
    context_options_test_id_attribute_name: string option [@key "testIdAttributeName"] [@default None];
  } [@@deriving yojson { strict = false }]

type launch_options_proxy =
  {
    launch_options_proxy_server: string [@key "server"];
    launch_options_proxy_bypass: string option [@key "bypass"] [@default None];
    launch_options_proxy_username: string option [@key "username"] [@default None];
    launch_options_proxy_password: string option [@key "password"] [@default None];
  } [@@deriving yojson { strict = false }]

type launch_options =
  {
    launch_options_channel: string option [@key "channel"] [@default None];
    launch_options_executable_path: string option [@key "executablePath"] [@default None];
    launch_options_args: string list option [@key "args"] [@default None];
    launch_options_ignore_all_default_args: bool option [@key "ignoreAllDefaultArgs"] [@default None];
    launch_options_ignore_default_args: string list option [@key "ignoreDefaultArgs"] [@default None];
    launch_options_handle_sigint: bool option [@key "handleSIGINT"] [@default None];
    launch_options_handle_sigterm: bool option [@key "handleSIGTERM"] [@default None];
    launch_options_handle_sighup: bool option [@key "handleSIGHUP"] [@default None];
    launch_options_timeout: float [@key "timeout"];
    launch_options_env: name_value list option [@key "env"] [@default None];
    launch_options_headless: bool option [@key "headless"] [@default None];
    launch_options_proxy: launch_options_proxy option [@key "proxy"] [@default None];
    launch_options_downloads_path: string option [@key "downloadsPath"] [@default None];
    launch_options_traces_dir: string option [@key "tracesDir"] [@default None];
    launch_options_artifacts_dir: string option [@key "artifactsDir"] [@default None];
    launch_options_chromium_sandbox: bool option [@key "chromiumSandbox"] [@default None];
    launch_options_firefox_user_prefs: json option [@key "firefoxUserPrefs"] [@default None];
    launch_options_cdp_port: int option [@key "cdpPort"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_type_launch_persistent_context_args =
  {
    browser_type_launch_persistent_context_args_mixin1: launch_options [@key "$mixin1"];
    browser_type_launch_persistent_context_args_mixin2: context_options [@key "$mixin2"];
    browser_type_launch_persistent_context_args_user_data_dir: string [@key "userDataDir"];
    browser_type_launch_persistent_context_args_slow_mo: float option [@key "slowMo"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_expect_args_pseudo =
  [
  | `Before
  | `After
  ] [@@deriving yojson]

type frame_uncheck_args =
  {
    frame_uncheck_args_selector: string [@key "selector"];
    frame_uncheck_args_strict: bool option [@key "strict"] [@default None];
    frame_uncheck_args_force: bool option [@key "force"] [@default None];
    frame_uncheck_args_position: point option [@key "position"] [@default None];
    frame_uncheck_args_timeout: float [@key "timeout"];
    frame_uncheck_args_trial: bool option [@key "trial"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_device_wait_args_state =
  [
  | `Gone
  ] [@@deriving yojson]

type android_device_wait_args =
  {
    android_device_wait_args_android_selector: android_selector [@key "androidSelector"];
    android_device_wait_args_state: android_device_wait_args_state option [@key "state"] [@default None];
    android_device_wait_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type stack_frame =
  {
    stack_frame_file: string [@key "file"];
    stack_frame_line: int [@key "line"];
    stack_frame_column: int [@key "column"];
    stack_frame_function_: string option [@key "function"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_device_screenshot_returns =
  {
    android_device_screenshot_returns_binary: string [@key "binary"];
  } [@@deriving yojson { strict = false }]

type element_handle_wait_for_element_state_args_state =
  [
  | `Visible
  | `Hidden
  | `Stable
  | `Enabled
  | `Disabled
  | `Editable
  ] [@@deriving yojson]

type tracing_tracing_start_chunk_returns =
  {
    tracing_tracing_start_chunk_returns_trace_name: string [@key "traceName"];
  } [@@deriving yojson { strict = false }]

type page_pdf_args_margin =
  {
    page_pdf_args_margin_top: string option [@key "top"] [@default None];
    page_pdf_args_margin_bottom: string option [@key "bottom"] [@default None];
    page_pdf_args_margin_left: string option [@key "left"] [@default None];
    page_pdf_args_margin_right: string option [@key "right"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_pdf_args =
  {
    page_pdf_args_scale: float option [@key "scale"] [@default None];
    page_pdf_args_display_header_footer: bool option [@key "displayHeaderFooter"] [@default None];
    page_pdf_args_header_template: string option [@key "headerTemplate"] [@default None];
    page_pdf_args_footer_template: string option [@key "footerTemplate"] [@default None];
    page_pdf_args_print_background: bool option [@key "printBackground"] [@default None];
    page_pdf_args_landscape: bool option [@key "landscape"] [@default None];
    page_pdf_args_page_ranges: string option [@key "pageRanges"] [@default None];
    page_pdf_args_format: string option [@key "format"] [@default None];
    page_pdf_args_width: string option [@key "width"] [@default None];
    page_pdf_args_height: string option [@key "height"] [@default None];
    page_pdf_args_prefer_css_page_size: bool option [@key "preferCSSPageSize"] [@default None];
    page_pdf_args_margin: page_pdf_args_margin option [@key "margin"] [@default None];
    page_pdf_args_tagged: bool option [@key "tagged"] [@default None];
    page_pdf_args_outline: bool option [@key "outline"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_is_checked_returns =
  {
    frame_is_checked_returns_value: bool [@key "value"];
  } [@@deriving yojson { strict = false }]

type android_device_web_view_removed_event =
  {
    android_device_web_view_removed_event_socket_name: string [@key "socketName"];
  } [@@deriving yojson { strict = false }]

type android_socket_data_event =
  {
    android_socket_data_event_data: string [@key "data"];
  } [@@deriving yojson { strict = false }]

type frame_press_args =
  {
    frame_press_args_selector: string [@key "selector"];
    frame_press_args_strict: bool option [@key "strict"] [@default None];
    frame_press_args_key: string [@key "key"];
    frame_press_args_delay: float option [@key "delay"] [@default None];
    frame_press_args_no_wait_after: bool option [@key "noWaitAfter"] [@default None];
    frame_press_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type android_device_push_args =
  {
    android_device_push_args_file: string [@key "file"];
    android_device_push_args_path: string [@key "path"];
    android_device_push_args_mode: int option [@key "mode"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_is_editable_args =
  {
    frame_is_editable_args_selector: string [@key "selector"];
    frame_is_editable_args_strict: bool option [@key "strict"] [@default None];
    frame_is_editable_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type form_field_file =
  {
    form_field_file_name: string [@key "name"];
    form_field_file_mime_type: string option [@key "mimeType"] [@default None];
    form_field_file_buffer: string [@key "buffer"];
  } [@@deriving yojson { strict = false }]

type form_field =
  {
    form_field_name: string [@key "name"];
    form_field_value: string option [@key "value"] [@default None];
    form_field_file: form_field_file option [@key "file"] [@default None];
  } [@@deriving yojson { strict = false }]

type debugger_paused_state_changed_event_paused_details_location =
  {
    debugger_paused_state_changed_event_paused_details_location_file: string [@key "file"];
    debugger_paused_state_changed_event_paused_details_location_line: int option [@key "line"] [@default None];
    debugger_paused_state_changed_event_paused_details_location_column: int option [@key "column"] [@default None];
  } [@@deriving yojson { strict = false }]

type debugger_paused_state_changed_event_paused_details =
  {
    debugger_paused_state_changed_event_paused_details_location: debugger_paused_state_changed_event_paused_details_location [@key "location"];
    debugger_paused_state_changed_event_paused_details_title: string [@key "title"];
    debugger_paused_state_changed_event_paused_details_stack: string option [@key "stack"] [@default None];
  } [@@deriving yojson { strict = false }]

type debugger_paused_state_changed_event =
  {
    debugger_paused_state_changed_event_paused_details: debugger_paused_state_changed_event_paused_details option [@key "pausedDetails"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_type_launch_returns =
  {
    browser_type_launch_returns_browser: channel [@key "browser"];
  } [@@deriving yojson { strict = false }]

type resource_timing =
  {
    resource_timing_start_time: float [@key "startTime"];
    resource_timing_domain_lookup_start: float [@key "domainLookupStart"];
    resource_timing_domain_lookup_end: float [@key "domainLookupEnd"];
    resource_timing_connect_start: float [@key "connectStart"];
    resource_timing_secure_connection_start: float [@key "secureConnectionStart"];
    resource_timing_connect_end: float [@key "connectEnd"];
    resource_timing_request_start: float [@key "requestStart"];
    resource_timing_response_start: float [@key "responseStart"];
  } [@@deriving yojson { strict = false }]

type response_initializer =
  {
    response_initializer_request: channel [@key "request"];
    response_initializer_url: string [@key "url"];
    response_initializer_status: int [@key "status"];
    response_initializer_status_text: string [@key "statusText"];
    response_initializer_headers: name_value list [@key "headers"];
    response_initializer_timing: resource_timing [@key "timing"];
    response_initializer_from_service_worker: bool [@key "fromServiceWorker"];
  } [@@deriving yojson { strict = false }]

type page_screencast_start_args_size =
  {
    page_screencast_start_args_size_width: int [@key "width"];
    page_screencast_start_args_size_height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type socks_support_socks_error_args =
  {
    socks_support_socks_error_args_uid: string [@key "uid"];
    socks_support_socks_error_args_error: string [@key "error"];
  } [@@deriving yojson { strict = false }]

type frame_hover_args_modifiers_item =
  [
  | `Alt
  | `Control
  | `Control_or_meta
  | `Meta
  | `Shift
  ] [@@deriving yojson]

type page_download_event =
  {
    page_download_event_url: string [@key "url"];
    page_download_event_suggested_filename: string [@key "suggestedFilename"];
    page_download_event_artifact: channel [@key "artifact"];
  } [@@deriving yojson { strict = false }]

type frame_is_disabled_args =
  {
    frame_is_disabled_args_selector: string [@key "selector"];
    frame_is_disabled_args_strict: bool option [@key "strict"] [@default None];
    frame_is_disabled_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type frame_add_script_tag_args =
  {
    frame_add_script_tag_args_url: string option [@key "url"] [@default None];
    frame_add_script_tag_args_content: string option [@key "content"] [@default None];
    frame_add_script_tag_args_type_: string option [@key "type"] [@default None];
  } [@@deriving yojson { strict = false }]

type origin_storage =
  {
    origin_storage_origin: string [@key "origin"];
    origin_storage_local_storage: name_value list [@key "localStorage"];
    origin_storage_indexed_db: indexed_db_database list option [@key "indexedDB"] [@default None];
  } [@@deriving yojson { strict = false }]

type network_cookie_same_site =
  [
  | `Strict
  | `Lax
  | `None
  ] [@@deriving yojson]

type network_cookie =
  {
    network_cookie_name: string [@key "name"];
    network_cookie_value: string [@key "value"];
    network_cookie_domain: string [@key "domain"];
    network_cookie_path: string [@key "path"];
    network_cookie_expires: float [@key "expires"];
    network_cookie_http_only: bool [@key "httpOnly"];
    network_cookie_secure: bool [@key "secure"];
    network_cookie_same_site: network_cookie_same_site [@key "sameSite"];
    network_cookie_partition_key: string option [@key "partitionKey"] [@default None];
    network_cookie_cr_has_cross_site_ancestor: bool option [@key "_crHasCrossSiteAncestor"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_storage_state_returns =
  {
    browser_context_storage_state_returns_cookies: network_cookie list [@key "cookies"];
    browser_context_storage_state_returns_origins: origin_storage list [@key "origins"];
  } [@@deriving yojson { strict = false }]

type playwright_new_request_args_client_certificates_item =
  {
    playwright_new_request_args_client_certificates_item_origin: string [@key "origin"];
    playwright_new_request_args_client_certificates_item_cert: string option [@key "cert"] [@default None];
    playwright_new_request_args_client_certificates_item_key: string option [@key "key"] [@default None];
    playwright_new_request_args_client_certificates_item_passphrase: string option [@key "passphrase"] [@default None];
    playwright_new_request_args_client_certificates_item_pfx: string option [@key "pfx"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_query_selector_all_returns =
  {
    element_handle_query_selector_all_returns_elements: channel list [@key "elements"];
  } [@@deriving yojson { strict = false }]

type element_handle_owner_frame_returns =
  {
    element_handle_owner_frame_returns_frame: channel option [@key "frame"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_create_temp_files_args_items_item =
  {
    browser_context_create_temp_files_args_items_item_name: string [@key "name"];
    browser_context_create_temp_files_args_items_item_last_modified_ms: float option [@key "lastModifiedMs"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_create_temp_files_args =
  {
    browser_context_create_temp_files_args_root_dir_name: string option [@key "rootDirName"] [@default None];
    browser_context_create_temp_files_args_items: browser_context_create_temp_files_args_items_item list [@key "items"];
  } [@@deriving yojson { strict = false }]

type element_handle_select_option_args_options_item =
  {
    element_handle_select_option_args_options_item_value_or_label: string option [@key "valueOrLabel"] [@default None];
    element_handle_select_option_args_options_item_value: string option [@key "value"] [@default None];
    element_handle_select_option_args_options_item_label: string option [@key "label"] [@default None];
    element_handle_select_option_args_options_item_index: int option [@key "index"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_select_option_args =
  {
    element_handle_select_option_args_elements: channel list option [@key "elements"] [@default None];
    element_handle_select_option_args_options: element_handle_select_option_args_options_item list option [@key "options"] [@default None];
    element_handle_select_option_args_force: bool option [@key "force"] [@default None];
    element_handle_select_option_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type element_handle_eval_on_selector_returns =
  {
    element_handle_eval_on_selector_returns_value: serialized_value [@key "value"];
  } [@@deriving yojson { strict = false }]

type frame_resolve_selector_returns =
  {
    frame_resolve_selector_returns_resolved_selector: string [@key "resolvedSelector"];
  } [@@deriving yojson { strict = false }]

type frame_set_content_args =
  {
    frame_set_content_args_html: string [@key "html"];
    frame_set_content_args_timeout: float [@key "timeout"];
    frame_set_content_args_wait_until: lifecycle_event option [@key "waitUntil"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_web_socket_route_event =
  {
    browser_context_web_socket_route_event_web_socket_route: channel [@key "webSocketRoute"];
  } [@@deriving yojson { strict = false }]

type page_emulate_media_args_contrast =
  [
  | `No_preference
  | `More
  | `No_override
  ] [@@deriving yojson]

type page_emulate_media_args_forced_colors =
  [
  | `Active
  | `None
  | `No_override
  ] [@@deriving yojson]

type page_emulate_media_args_reduced_motion =
  [
  | `Reduce
  | `No_preference
  | `No_override
  ] [@@deriving yojson]

type page_emulate_media_args_color_scheme =
  [
  | `Dark
  | `Light
  | `No_preference
  | `No_override
  ] [@@deriving yojson]

type page_emulate_media_args_media =
  [
  | `Screen
  | `Print
  | `No_override
  ] [@@deriving yojson]

type page_emulate_media_args =
  {
    page_emulate_media_args_media: page_emulate_media_args_media option [@key "media"] [@default None];
    page_emulate_media_args_color_scheme: page_emulate_media_args_color_scheme option [@key "colorScheme"] [@default None];
    page_emulate_media_args_reduced_motion: page_emulate_media_args_reduced_motion option [@key "reducedMotion"] [@default None];
    page_emulate_media_args_forced_colors: page_emulate_media_args_forced_colors option [@key "forcedColors"] [@default None];
    page_emulate_media_args_contrast: page_emulate_media_args_contrast option [@key "contrast"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_set_http_credentials_args_http_credentials =
  {
    browser_context_set_http_credentials_args_http_credentials_username: string [@key "username"];
    browser_context_set_http_credentials_args_http_credentials_password: string [@key "password"];
    browser_context_set_http_credentials_args_http_credentials_origin: string option [@key "origin"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_device_shell_args =
  {
    android_device_shell_args_command: string [@key "command"];
  } [@@deriving yojson { strict = false }]

type browser_context_recorder_event_event_event =
  [
  | `Action_added
  | `Action_updated
  | `Signal_added
  ] [@@deriving yojson]

type browser_context_recorder_event_event =
  {
    browser_context_recorder_event_event_event: browser_context_recorder_event_event_event [@key "event"];
    browser_context_recorder_event_event_data: json [@key "data"];
    browser_context_recorder_event_event_page: channel [@key "page"];
    browser_context_recorder_event_event_code: string [@key "code"];
  } [@@deriving yojson { strict = false }]

type page_screencast_start_args =
  {
    page_screencast_start_args_size: page_screencast_start_args_size option [@key "size"] [@default None];
    page_screencast_start_args_quality: int option [@key "quality"] [@default None];
    page_screencast_start_args_send_frames: bool option [@key "sendFrames"] [@default None];
    page_screencast_start_args_record: bool option [@key "record"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_page_event =
  {
    browser_context_page_event_page: channel [@key "page"];
  } [@@deriving yojson { strict = false }]

type browser_context_dialog_event =
  {
    browser_context_dialog_event_dialog: channel [@key "dialog"];
  } [@@deriving yojson { strict = false }]

type android_device_pinch_close_args =
  {
    android_device_pinch_close_args_android_selector: android_selector [@key "androidSelector"];
    android_device_pinch_close_args_percent: float [@key "percent"];
    android_device_pinch_close_args_speed: float option [@key "speed"] [@default None];
    android_device_pinch_close_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type worker_evaluate_expression_args =
  {
    worker_evaluate_expression_args_expression: string [@key "expression"];
    worker_evaluate_expression_args_is_function: bool option [@key "isFunction"] [@default None];
    worker_evaluate_expression_args_arg: serialized_argument [@key "arg"];
  } [@@deriving yojson { strict = false }]

type frame_input_value_returns =
  {
    frame_input_value_returns_value: string [@key "value"];
  } [@@deriving yojson { strict = false }]

type frame_inner_htm_l_returns =
  {
    frame_inner_htm_l_returns_value: string [@key "value"];
  } [@@deriving yojson { strict = false }]

type debug_controller_set_report_state_changed_args =
  {
    debug_controller_set_report_state_changed_args_enabled: bool [@key "enabled"];
  } [@@deriving yojson { strict = false }]

type debugger_run_to_args_location =
  {
    debugger_run_to_args_location_file: string [@key "file"];
    debugger_run_to_args_location_line: int option [@key "line"] [@default None];
    debugger_run_to_args_location_column: int option [@key "column"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_device_input_swipe_args =
  {
    android_device_input_swipe_args_segments: point list [@key "segments"];
    android_device_input_swipe_args_steps: int [@key "steps"];
  } [@@deriving yojson { strict = false }]

type frame_add_script_tag_returns =
  {
    frame_add_script_tag_returns_element: channel [@key "element"];
  } [@@deriving yojson { strict = false }]

type browser_context_enable_recorder_args_recorder_mode =
  [
  | `Default
  | `Api
  ] [@@deriving yojson]

type browser_context_enable_recorder_args_mode =
  [
  | `Inspecting
  | `Recording
  ] [@@deriving yojson]

type browser_context_enable_recorder_args =
  {
    browser_context_enable_recorder_args_language: string option [@key "language"] [@default None];
    browser_context_enable_recorder_args_mode: browser_context_enable_recorder_args_mode option [@key "mode"] [@default None];
    browser_context_enable_recorder_args_recorder_mode: browser_context_enable_recorder_args_recorder_mode option [@key "recorderMode"] [@default None];
    browser_context_enable_recorder_args_pause_on_next_statement: bool option [@key "pauseOnNextStatement"] [@default None];
    browser_context_enable_recorder_args_test_id_attribute_name: string option [@key "testIdAttributeName"] [@default None];
    browser_context_enable_recorder_args_launch_options: json option [@key "launchOptions"] [@default None];
    browser_context_enable_recorder_args_context_options: json option [@key "contextOptions"] [@default None];
    browser_context_enable_recorder_args_device: string option [@key "device"] [@default None];
    browser_context_enable_recorder_args_save_storage: string option [@key "saveStorage"] [@default None];
    browser_context_enable_recorder_args_output_file: string option [@key "outputFile"] [@default None];
    browser_context_enable_recorder_args_handle_sigint: bool option [@key "handleSIGINT"] [@default None];
    browser_context_enable_recorder_args_omit_call_tracking: bool option [@key "omitCallTracking"] [@default None];
  } [@@deriving yojson { strict = false }]

type route_redirect_navigation_request_args =
  {
    route_redirect_navigation_request_args_url: string [@key "url"];
  } [@@deriving yojson { strict = false }]

type page_mouse_click_args_button =
  [
  | `Left
  | `Right
  | `Middle
  ] [@@deriving yojson]

type artifact_save_as_stream_returns =
  {
    artifact_save_as_stream_returns_stream: channel [@key "stream"];
  } [@@deriving yojson { strict = false }]

type browser_context_clock_run_for_args =
  {
    browser_context_clock_run_for_args_ticks_number: float option [@key "ticksNumber"] [@default None];
    browser_context_clock_run_for_args_ticks_string: string option [@key "ticksString"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_title_returns =
  {
    frame_title_returns_value: string [@key "value"];
  } [@@deriving yojson { strict = false }]

type page_viewport_size_changed_event_viewport_size =
  {
    page_viewport_size_changed_event_viewport_size_width: int [@key "width"];
    page_viewport_size_changed_event_viewport_size_height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type web_socket_route_message_from_server_event =
  {
    web_socket_route_message_from_server_event_message: string [@key "message"];
    web_socket_route_message_from_server_event_is_base64: bool [@key "isBase64"];
  } [@@deriving yojson { strict = false }]

type json_pipe_message_event =
  {
    json_pipe_message_event_message: json [@key "message"];
  } [@@deriving yojson { strict = false }]

type artifact_failure_returns =
  {
    artifact_failure_returns_error: string option [@key "error"] [@default None];
  } [@@deriving yojson { strict = false }]

type sdk_language =
  [
  | `Javascript
  | `Python
  | `Java
  | `Csharp
  ] [@@deriving yojson]

type debug_controller_initialize_args =
  {
    debug_controller_initialize_args_codegen_id: string [@key "codegenId"];
    debug_controller_initialize_args_sdk_language: sdk_language [@key "sdkLanguage"];
  } [@@deriving yojson { strict = false }]

type frame_evaluate_expression_handle_returns =
  {
    frame_evaluate_expression_handle_returns_handle: channel [@key "handle"];
  } [@@deriving yojson { strict = false }]

type browser_context_create_temp_files_returns =
  {
    browser_context_create_temp_files_returns_root_dir: channel option [@key "rootDir"] [@default None];
    browser_context_create_temp_files_returns_writable_streams: channel list [@key "writableStreams"];
  } [@@deriving yojson { strict = false }]

type js_handle_get_property_list_returns_properties_item =
  {
    js_handle_get_property_list_returns_properties_item_name: string [@key "name"];
    js_handle_get_property_list_returns_properties_item_value: channel [@key "value"];
  } [@@deriving yojson { strict = false }]

type js_handle_get_property_list_returns =
  {
    js_handle_get_property_list_returns_properties: js_handle_get_property_list_returns_properties_item list [@key "properties"];
  } [@@deriving yojson { strict = false }]

type element_handle_click_args_modifiers_item =
  [
  | `Alt
  | `Control
  | `Control_or_meta
  | `Meta
  | `Shift
  ] [@@deriving yojson]

type browser_new_context_for_reuse_args_storage_state =
  {
    browser_new_context_for_reuse_args_storage_state_cookies: set_network_cookie list option [@key "cookies"] [@default None];
    browser_new_context_for_reuse_args_storage_state_origins: set_origin_storage list option [@key "origins"] [@default None];
  } [@@deriving yojson { strict = false }]

type console_message_location =
  {
    console_message_location_url: string [@key "url"];
    console_message_location_line_number: int [@key "lineNumber"];
    console_message_location_column_number: int [@key "columnNumber"];
  } [@@deriving yojson { strict = false }]

type console_message =
  {
    console_message_type_: string [@key "type"];
    console_message_text: string [@key "text"];
    console_message_args: channel list [@key "args"];
    console_message_location: console_message_location [@key "location"];
    console_message_timestamp: float [@key "timestamp"];
  } [@@deriving yojson { strict = false }]

type page_console_messages_returns_messages_item =
  {
    page_console_messages_returns_messages_item_mixin: console_message [@key "$mixin"];
  } [@@deriving yojson { strict = false }]

type page_console_messages_returns =
  {
    page_console_messages_returns_messages: page_console_messages_returns_messages_item list [@key "messages"];
  } [@@deriving yojson { strict = false }]

type web_socket_socket_error_event =
  {
    web_socket_socket_error_event_error: string [@key "error"];
  } [@@deriving yojson { strict = false }]

type android_device_fill_args =
  {
    android_device_fill_args_android_selector: android_selector [@key "androidSelector"];
    android_device_fill_args_text: string [@key "text"];
    android_device_fill_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type worker_initializer =
  {
    worker_initializer_url: string [@key "url"];
  } [@@deriving yojson { strict = false }]

type browser_start_server_args =
  {
    browser_start_server_args_title: string [@key "title"];
    browser_start_server_args_workspace_dir: string option [@key "workspaceDir"] [@default None];
    browser_start_server_args_metadata: json option [@key "metadata"] [@default None];
    browser_start_server_args_host: string option [@key "host"] [@default None];
    browser_start_server_args_port: int option [@key "port"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_navigated_event_new_document =
  {
    frame_navigated_event_new_document_request: channel option [@key "request"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_navigated_event =
  {
    frame_navigated_event_url: string [@key "url"];
    frame_navigated_event_name: string [@key "name"];
    frame_navigated_event_new_document: frame_navigated_event_new_document option [@key "newDocument"] [@default None];
    frame_navigated_event_error: string option [@key "error"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_input_value_returns =
  {
    element_handle_input_value_returns_value: string [@key "value"];
  } [@@deriving yojson { strict = false }]

type page_set_extra_http_headers_args =
  {
    page_set_extra_http_headers_args_headers: name_value list [@key "headers"];
  } [@@deriving yojson { strict = false }]

type root_initialize_args =
  {
    root_initialize_args_sdk_language: sdk_language [@key "sdkLanguage"];
  } [@@deriving yojson { strict = false }]

type browser_new_context_for_reuse_args_proxy =
  {
    browser_new_context_for_reuse_args_proxy_server: string [@key "server"];
    browser_new_context_for_reuse_args_proxy_bypass: string option [@key "bypass"] [@default None];
    browser_new_context_for_reuse_args_proxy_username: string option [@key "username"] [@default None];
    browser_new_context_for_reuse_args_proxy_password: string option [@key "password"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_request_event =
  {
    browser_context_request_event_request: channel [@key "request"];
    browser_context_request_event_page: channel option [@key "page"] [@default None];
  } [@@deriving yojson { strict = false }]

type local_utils_tracing_started_returns =
  {
    local_utils_tracing_started_returns_stacks_id: string [@key "stacksId"];
  } [@@deriving yojson { strict = false }]

type element_handle_content_frame_returns =
  {
    element_handle_content_frame_returns_frame: channel option [@key "frame"] [@default None];
  } [@@deriving yojson { strict = false }]

type dialog_initializer =
  {
    dialog_initializer_page: channel option [@key "page"] [@default None];
    dialog_initializer_type_: string [@key "type"];
    dialog_initializer_message: string [@key "message"];
    dialog_initializer_default_value: string [@key "defaultValue"];
  } [@@deriving yojson { strict = false }]

type api_request_context_dispose_api_response_args =
  {
    api_request_context_dispose_api_response_args_fetch_uid: string [@key "fetchUid"];
  } [@@deriving yojson { strict = false }]

type android_devices_args =
  {
    android_devices_args_host: string option [@key "host"] [@default None];
    android_devices_args_port: int option [@key "port"] [@default None];
    android_devices_args_omit_driver_install: bool option [@key "omitDriverInstall"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_new_cdp_session_returns =
  {
    browser_context_new_cdp_session_returns_session: channel [@key "session"];
  } [@@deriving yojson { strict = false }]

type page_screencast_show_actions_args =
  {
    page_screencast_show_actions_args_mixin: show_actions_options [@key "$mixin"];
  } [@@deriving yojson { strict = false }]

type android_device_open_returns =
  {
    android_device_open_returns_socket: channel [@key "socket"];
  } [@@deriving yojson { strict = false }]

type frame_resolve_selector_args =
  {
    frame_resolve_selector_args_selector: string [@key "selector"];
  } [@@deriving yojson { strict = false }]

type frame_focus_args =
  {
    frame_focus_args_selector: string [@key "selector"];
    frame_focus_args_strict: bool option [@key "strict"] [@default None];
    frame_focus_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type browser_context_close_args =
  {
    browser_context_close_args_reason: string option [@key "reason"] [@default None];
  } [@@deriving yojson { strict = false }]

type common_screenshot_options_mask_item =
  {
    common_screenshot_options_mask_item_frame: channel [@key "frame"];
    common_screenshot_options_mask_item_selector: string [@key "selector"];
  } [@@deriving yojson { strict = false }]

type common_screenshot_options_scale =
  [
  | `Css
  | `Device
  ] [@@deriving yojson]

type common_screenshot_options_animations =
  [
  | `Disabled
  | `Allow
  ] [@@deriving yojson]

type common_screenshot_options =
  {
    common_screenshot_options_omit_background: bool option [@key "omitBackground"] [@default None];
    common_screenshot_options_caret: common_screenshot_options_caret option [@key "caret"] [@default None];
    common_screenshot_options_animations: common_screenshot_options_animations option [@key "animations"] [@default None];
    common_screenshot_options_scale: common_screenshot_options_scale option [@key "scale"] [@default None];
    common_screenshot_options_mask: common_screenshot_options_mask_item list option [@key "mask"] [@default None];
    common_screenshot_options_mask_color: string option [@key "maskColor"] [@default None];
    common_screenshot_options_style: string option [@key "style"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_screenshot_args_type =
  [
  | `Png
  | `Jpeg
  ] [@@deriving yojson]

type element_handle_screenshot_args =
  {
    element_handle_screenshot_args_timeout: float [@key "timeout"];
    element_handle_screenshot_args_type_: element_handle_screenshot_args_type option [@key "type"] [@default None];
    element_handle_screenshot_args_quality: int option [@key "quality"] [@default None];
    element_handle_screenshot_args_mixin: common_screenshot_options [@key "$mixin"];
  } [@@deriving yojson { strict = false }]

type browser_context_page_error_event_location =
  {
    browser_context_page_error_event_location_url: string [@key "url"];
    browser_context_page_error_event_location_line: int [@key "line"];
    browser_context_page_error_event_location_column: int [@key "column"];
  } [@@deriving yojson { strict = false }]

type page_stop_css_coverage_returns_entries_item_ranges_item =
  {
    page_stop_css_coverage_returns_entries_item_ranges_item_start: int [@key "start"];
    page_stop_css_coverage_returns_entries_item_ranges_item_end_: int [@key "end"];
  } [@@deriving yojson { strict = false }]

type page_stop_css_coverage_returns_entries_item =
  {
    page_stop_css_coverage_returns_entries_item_url: string [@key "url"];
    page_stop_css_coverage_returns_entries_item_text: string option [@key "text"] [@default None];
    page_stop_css_coverage_returns_entries_item_ranges: page_stop_css_coverage_returns_entries_item_ranges_item list [@key "ranges"];
  } [@@deriving yojson { strict = false }]

type page_stop_css_coverage_returns =
  {
    page_stop_css_coverage_returns_entries: page_stop_css_coverage_returns_entries_item list [@key "entries"];
  } [@@deriving yojson { strict = false }]

type browser_type_connect_to_worker_returns =
  {
    browser_type_connect_to_worker_returns_worker: channel [@key "worker"];
  } [@@deriving yojson { strict = false }]

type frame_highlight_args =
  {
    frame_highlight_args_selector: string [@key "selector"];
    frame_highlight_args_style: string option [@key "style"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_add_style_tag_returns =
  {
    frame_add_style_tag_returns_element: channel [@key "element"];
  } [@@deriving yojson { strict = false }]

type metadata_location =
  {
    metadata_location_file: string [@key "file"];
    metadata_location_line: int option [@key "line"] [@default None];
    metadata_location_column: int option [@key "column"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_initializer_options =
  {
    browser_context_initializer_options_mixin: context_options [@key "$mixin"];
  } [@@deriving yojson { strict = false }]

type browser_context_expose_binding_returns =
  {
    browser_context_expose_binding_returns_disposable: channel [@key "disposable"];
  } [@@deriving yojson { strict = false }]

type page_go_back_args =
  {
    page_go_back_args_timeout: float [@key "timeout"];
    page_go_back_args_wait_until: lifecycle_event option [@key "waitUntil"] [@default None];
  } [@@deriving yojson { strict = false }]

type web_socket_route_message_from_page_event =
  {
    web_socket_route_message_from_page_event_message: string [@key "message"];
    web_socket_route_message_from_page_event_is_base64: bool [@key "isBase64"];
  } [@@deriving yojson { strict = false }]

type browser_close_args =
  {
    browser_close_args_reason: string option [@key "reason"] [@default None];
  } [@@deriving yojson { strict = false }]

type url_pattern =
  {
    url_pattern_hash: string [@key "hash"];
    url_pattern_hostname: string [@key "hostname"];
    url_pattern_password: string [@key "password"];
    url_pattern_pathname: string [@key "pathname"];
    url_pattern_port: string [@key "port"];
    url_pattern_protocol: string [@key "protocol"];
    url_pattern_search: string [@key "search"];
    url_pattern_username: string [@key "username"];
  } [@@deriving yojson { strict = false }]

type page_set_network_interception_patterns_args_patterns_item =
  {
    page_set_network_interception_patterns_args_patterns_item_glob: string option [@key "glob"] [@default None];
    page_set_network_interception_patterns_args_patterns_item_regex_source: string option [@key "regexSource"] [@default None];
    page_set_network_interception_patterns_args_patterns_item_regex_flags: string option [@key "regexFlags"] [@default None];
    page_set_network_interception_patterns_args_patterns_item_url_pattern: url_pattern option [@key "urlPattern"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_set_network_interception_patterns_args =
  {
    page_set_network_interception_patterns_args_patterns: page_set_network_interception_patterns_args_patterns_item list [@key "patterns"];
  } [@@deriving yojson { strict = false }]

type rect =
  {
    rect_x: float [@key "x"];
    rect_y: float [@key "y"];
    rect_width: float [@key "width"];
    rect_height: float [@key "height"];
  } [@@deriving yojson { strict = false }]

type page_expect_screenshot_args_locator =
  {
    page_expect_screenshot_args_locator_frame: channel [@key "frame"];
    page_expect_screenshot_args_locator_selector: string [@key "selector"];
  } [@@deriving yojson { strict = false }]

type page_expect_screenshot_args =
  {
    page_expect_screenshot_args_expected: string option [@key "expected"] [@default None];
    page_expect_screenshot_args_timeout: float [@key "timeout"];
    page_expect_screenshot_args_is_not: bool [@key "isNot"];
    page_expect_screenshot_args_locator: page_expect_screenshot_args_locator option [@key "locator"] [@default None];
    page_expect_screenshot_args_comparator: string option [@key "comparator"] [@default None];
    page_expect_screenshot_args_max_diff_pixels: int option [@key "maxDiffPixels"] [@default None];
    page_expect_screenshot_args_max_diff_pixel_ratio: float option [@key "maxDiffPixelRatio"] [@default None];
    page_expect_screenshot_args_threshold: float option [@key "threshold"] [@default None];
    page_expect_screenshot_args_full_page: bool option [@key "fullPage"] [@default None];
    page_expect_screenshot_args_clip: rect option [@key "clip"] [@default None];
    page_expect_screenshot_args_mixin: common_screenshot_options [@key "$mixin"];
  } [@@deriving yojson { strict = false }]

type local_utils_connect_args =
  {
    local_utils_connect_args_endpoint: string [@key "endpoint"];
    local_utils_connect_args_headers: json option [@key "headers"] [@default None];
    local_utils_connect_args_expose_network: string option [@key "exposeNetwork"] [@default None];
    local_utils_connect_args_slow_mo: float option [@key "slowMo"] [@default None];
    local_utils_connect_args_timeout: float [@key "timeout"];
    local_utils_connect_args_socks_proxy_redirect_port_for_test: int option [@key "socksProxyRedirectPortForTest"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_route_event =
  {
    browser_context_route_event_route: channel [@key "route"];
  } [@@deriving yojson { strict = false }]

type page_page_errors_returns =
  {
    page_page_errors_returns_errors: serialized_error list [@key "errors"];
  } [@@deriving yojson { strict = false }]

type dialog_accept_args =
  {
    dialog_accept_args_prompt_text: string option [@key "promptText"] [@default None];
  } [@@deriving yojson { strict = false }]

type playwright_new_request_args_proxy =
  {
    playwright_new_request_args_proxy_server: string [@key "server"];
    playwright_new_request_args_proxy_bypass: string option [@key "bypass"] [@default None];
    playwright_new_request_args_proxy_username: string option [@key "username"] [@default None];
    playwright_new_request_args_proxy_password: string option [@key "password"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_aria_ref_args =
  {
    frame_aria_ref_args_selector: string [@key "selector"];
    frame_aria_ref_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type browser_context_request_failed_event =
  {
    browser_context_request_failed_event_request: channel [@key "request"];
    browser_context_request_failed_event_failure_text: string option [@key "failureText"] [@default None];
    browser_context_request_failed_event_response_end_timing: float [@key "responseEndTiming"];
    browser_context_request_failed_event_page: channel option [@key "page"] [@default None];
  } [@@deriving yojson { strict = false }]

type worker_update_subscription_args_event =
  [
  | `Console
  ] [@@deriving yojson]

type worker_update_subscription_args =
  {
    worker_update_subscription_args_event: worker_update_subscription_args_event [@key "event"];
    worker_update_subscription_args_enabled: bool [@key "enabled"];
  } [@@deriving yojson { strict = false }]

type frame_evaluate_expression_returns =
  {
    frame_evaluate_expression_returns_value: serialized_value [@key "value"];
  } [@@deriving yojson { strict = false }]

type record_har_options_mode =
  [
  | `Full
  | `Minimal
  ] [@@deriving yojson]

type element_handle_is_checked_returns =
  {
    element_handle_is_checked_returns_value: bool [@key "value"];
  } [@@deriving yojson { strict = false }]

type element_handle_dispatch_event_args =
  {
    element_handle_dispatch_event_args_type_: string [@key "type"];
    element_handle_dispatch_event_args_event_init: serialized_argument [@key "eventInit"];
  } [@@deriving yojson { strict = false }]

type element_handle_hover_args_modifiers_item =
  [
  | `Alt
  | `Control
  | `Control_or_meta
  | `Meta
  | `Shift
  ] [@@deriving yojson]

type element_handle_tap_args_modifiers_item =
  [
  | `Alt
  | `Control
  | `Control_or_meta
  | `Meta
  | `Shift
  ] [@@deriving yojson]

type element_handle_tap_args =
  {
    element_handle_tap_args_force: bool option [@key "force"] [@default None];
    element_handle_tap_args_modifiers: element_handle_tap_args_modifiers_item list option [@key "modifiers"] [@default None];
    element_handle_tap_args_position: point option [@key "position"] [@default None];
    element_handle_tap_args_timeout: float [@key "timeout"];
    element_handle_tap_args_trial: bool option [@key "trial"] [@default None];
  } [@@deriving yojson { strict = false }]

type socks_support_socks_connected_args =
  {
    socks_support_socks_connected_args_uid: string [@key "uid"];
    socks_support_socks_connected_args_host: string [@key "host"];
    socks_support_socks_connected_args_port: int [@key "port"];
  } [@@deriving yojson { strict = false }]

type js_handle_evaluate_expression_handle_returns =
  {
    js_handle_evaluate_expression_handle_returns_handle: channel [@key "handle"];
  } [@@deriving yojson { strict = false }]

type browser_context_request_finished_event =
  {
    browser_context_request_finished_event_request: channel [@key "request"];
    browser_context_request_finished_event_response: channel option [@key "response"] [@default None];
    browser_context_request_finished_event_response_end_timing: float [@key "responseEndTiming"];
    browser_context_request_finished_event_page: channel option [@key "page"] [@default None];
  } [@@deriving yojson { strict = false }]

type console_messages_filter =
  [
  | `All
  | `Since_navigation
  ] [@@deriving yojson]

type page_console_messages_args =
  {
    page_console_messages_args_filter: console_messages_filter option [@key "filter"] [@default None];
  } [@@deriving yojson { strict = false }]

type security_details =
  {
    security_details_issuer: string option [@key "issuer"] [@default None];
    security_details_protocol: string option [@key "protocol"] [@default None];
    security_details_subject_name: string option [@key "subjectName"] [@default None];
    security_details_valid_from: float option [@key "validFrom"] [@default None];
    security_details_valid_to: float option [@key "validTo"] [@default None];
  } [@@deriving yojson { strict = false }]

type expected_text_value =
  {
    expected_text_value_string: string option [@key "string"] [@default None];
    expected_text_value_regex_source: string option [@key "regexSource"] [@default None];
    expected_text_value_regex_flags: string option [@key "regexFlags"] [@default None];
    expected_text_value_match_substring: bool option [@key "matchSubstring"] [@default None];
    expected_text_value_ignore_case: bool option [@key "ignoreCase"] [@default None];
    expected_text_value_normalize_white_space: bool option [@key "normalizeWhiteSpace"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_select_option_args_options_item =
  {
    frame_select_option_args_options_item_value_or_label: string option [@key "valueOrLabel"] [@default None];
    frame_select_option_args_options_item_value: string option [@key "value"] [@default None];
    frame_select_option_args_options_item_label: string option [@key "label"] [@default None];
    frame_select_option_args_options_item_index: int option [@key "index"] [@default None];
  } [@@deriving yojson { strict = false }]

type tracing_tracing_start_chunk_args =
  {
    tracing_tracing_start_chunk_args_name: string option [@key "name"] [@default None];
    tracing_tracing_start_chunk_args_title: string option [@key "title"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_web_socket_route_event =
  {
    page_web_socket_route_event_web_socket_route: channel [@key "webSocketRoute"];
  } [@@deriving yojson { strict = false }]

type browser_context_register_selector_engine_args =
  {
    browser_context_register_selector_engine_args_selector_engine: selector_engine [@key "selectorEngine"];
  } [@@deriving yojson { strict = false }]

type web_socket_route_close_server_event =
  {
    web_socket_route_close_server_event_code: int option [@key "code"] [@default None];
    web_socket_route_close_server_event_reason: string option [@key "reason"] [@default None];
    web_socket_route_close_server_event_was_clean: bool [@key "wasClean"];
  } [@@deriving yojson { strict = false }]

type page_mouse_move_args =
  {
    page_mouse_move_args_x: float [@key "x"];
    page_mouse_move_args_y: float [@key "y"];
    page_mouse_move_args_steps: int option [@key "steps"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_route_event =
  {
    page_route_event_route: channel [@key "route"];
  } [@@deriving yojson { strict = false }]

type frame_goto_args =
  {
    frame_goto_args_url: string [@key "url"];
    frame_goto_args_timeout: float [@key "timeout"];
    frame_goto_args_wait_until: lifecycle_event option [@key "waitUntil"] [@default None];
    frame_goto_args_referer: string option [@key "referer"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_evaluate_expression_args =
  {
    frame_evaluate_expression_args_expression: string [@key "expression"];
    frame_evaluate_expression_args_is_function: bool option [@key "isFunction"] [@default None];
    frame_evaluate_expression_args_arg: serialized_argument [@key "arg"];
  } [@@deriving yojson { strict = false }]

type browser_new_context_args_proxy =
  {
    browser_new_context_args_proxy_server: string [@key "server"];
    browser_new_context_args_proxy_bypass: string option [@key "bypass"] [@default None];
    browser_new_context_args_proxy_username: string option [@key "username"] [@default None];
    browser_new_context_args_proxy_password: string option [@key "password"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_device_shell_returns =
  {
    android_device_shell_returns_result: string [@key "result"];
  } [@@deriving yojson { strict = false }]

type frame_inner_text_returns =
  {
    frame_inner_text_returns_value: string [@key "value"];
  } [@@deriving yojson { strict = false }]

type root_initialize_returns =
  {
    root_initialize_returns_playwright: channel [@key "playwright"];
  } [@@deriving yojson { strict = false }]

type json_pipe_closed_event =
  {
    json_pipe_closed_event_reason: string option [@key "reason"] [@default None];
  } [@@deriving yojson { strict = false }]

type writable_stream_write_args =
  {
    writable_stream_write_args_binary: string [@key "binary"];
  } [@@deriving yojson { strict = false }]

type page_screencast_set_overlay_visible_args =
  {
    page_screencast_set_overlay_visible_args_visible: bool [@key "visible"];
  } [@@deriving yojson { strict = false }]

type playwright_initializer =
  {
    playwright_initializer_chromium: channel [@key "chromium"];
    playwright_initializer_firefox: channel [@key "firefox"];
    playwright_initializer_webkit: channel [@key "webkit"];
    playwright_initializer_android: channel [@key "android"];
    playwright_initializer_utils: channel option [@key "utils"] [@default None];
    playwright_initializer_pre_launched_browser: channel option [@key "preLaunchedBrowser"] [@default None];
    playwright_initializer_pre_connected_android_device: channel option [@key "preConnectedAndroidDevice"] [@default None];
    playwright_initializer_socks_support: channel option [@key "socksSupport"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_hover_args =
  {
    element_handle_hover_args_force: bool option [@key "force"] [@default None];
    element_handle_hover_args_modifiers: element_handle_hover_args_modifiers_item list option [@key "modifiers"] [@default None];
    element_handle_hover_args_position: point option [@key "position"] [@default None];
    element_handle_hover_args_timeout: float [@key "timeout"];
    element_handle_hover_args_trial: bool option [@key "trial"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_device_pinch_open_args =
  {
    android_device_pinch_open_args_android_selector: android_selector [@key "androidSelector"];
    android_device_pinch_open_args_percent: float [@key "percent"];
    android_device_pinch_open_args_speed: float option [@key "speed"] [@default None];
    android_device_pinch_open_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type tracing_tracing_group_args_location =
  {
    tracing_tracing_group_args_location_file: string [@key "file"];
    tracing_tracing_group_args_location_line: int option [@key "line"] [@default None];
    tracing_tracing_group_args_location_column: int option [@key "column"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_stop_js_coverage_returns_entries_item =
  {
    page_stop_js_coverage_returns_entries_item_url: string [@key "url"];
    page_stop_js_coverage_returns_entries_item_script_id: string [@key "scriptId"];
    page_stop_js_coverage_returns_entries_item_source: string option [@key "source"] [@default None];
    page_stop_js_coverage_returns_entries_item_functions: page_stop_js_coverage_returns_entries_item_functions_item list [@key "functions"];
  } [@@deriving yojson { strict = false }]

type element_handle_inner_text_returns =
  {
    element_handle_inner_text_returns_value: string [@key "value"];
  } [@@deriving yojson { strict = false }]

type web_socket_initializer =
  {
    web_socket_initializer_url: string [@key "url"];
  } [@@deriving yojson { strict = false }]

type frame_is_enabled_args =
  {
    frame_is_enabled_args_selector: string [@key "selector"];
    frame_is_enabled_args_strict: bool option [@key "strict"] [@default None];
    frame_is_enabled_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type page_mouse_click_args =
  {
    page_mouse_click_args_x: float [@key "x"];
    page_mouse_click_args_y: float [@key "y"];
    page_mouse_click_args_delay: float option [@key "delay"] [@default None];
    page_mouse_click_args_button: page_mouse_click_args_button option [@key "button"] [@default None];
    page_mouse_click_args_click_count: int option [@key "clickCount"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_fill_args =
  {
    frame_fill_args_selector: string [@key "selector"];
    frame_fill_args_strict: bool option [@key "strict"] [@default None];
    frame_fill_args_value: string [@key "value"];
    frame_fill_args_force: bool option [@key "force"] [@default None];
    frame_fill_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type socks_support_socks_end_args =
  {
    socks_support_socks_end_args_uid: string [@key "uid"];
  } [@@deriving yojson { strict = false }]

type frame_drop_args_payloads_item =
  {
    frame_drop_args_payloads_item_name: string [@key "name"];
    frame_drop_args_payloads_item_mime_type: string option [@key "mimeType"] [@default None];
    frame_drop_args_payloads_item_buffer: string [@key "buffer"];
  } [@@deriving yojson { strict = false }]

type frame_click_args_modifiers_item =
  [
  | `Alt
  | `Control
  | `Control_or_meta
  | `Meta
  | `Shift
  ] [@@deriving yojson]

type socks_support_socks_data_args =
  {
    socks_support_socks_data_args_uid: string [@key "uid"];
    socks_support_socks_data_args_data: string [@key "data"];
  } [@@deriving yojson { strict = false }]

type frame_type_args =
  {
    frame_type_args_selector: string [@key "selector"];
    frame_type_args_strict: bool option [@key "strict"] [@default None];
    frame_type_args_text: string [@key "text"];
    frame_type_args_delay: float option [@key "delay"] [@default None];
    frame_type_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type frame_dblclick_args_button =
  [
  | `Left
  | `Right
  | `Middle
  ] [@@deriving yojson]

type element_handle_check_args =
  {
    element_handle_check_args_force: bool option [@key "force"] [@default None];
    element_handle_check_args_position: point option [@key "position"] [@default None];
    element_handle_check_args_timeout: float [@key "timeout"];
    element_handle_check_args_trial: bool option [@key "trial"] [@default None];
  } [@@deriving yojson { strict = false }]

type response_security_details_returns =
  {
    response_security_details_returns_value: security_details option [@key "value"] [@default None];
  } [@@deriving yojson { strict = false }]

type debug_controller_inspect_requested_event =
  {
    debug_controller_inspect_requested_event_selector: string [@key "selector"];
    debug_controller_inspect_requested_event_locator: string [@key "locator"];
    debug_controller_inspect_requested_event_aria_snapshot: string [@key "ariaSnapshot"];
  } [@@deriving yojson { strict = false }]

type browser_context_console_event =
  {
    browser_context_console_event_mixin: console_message [@key "$mixin"];
    browser_context_console_event_page: channel option [@key "page"] [@default None];
    browser_context_console_event_worker: channel option [@key "worker"] [@default None];
  } [@@deriving yojson { strict = false }]

type client_side_call_metadata =
  {
    client_side_call_metadata_id: int [@key "id"];
    client_side_call_metadata_stack: stack_frame list option [@key "stack"] [@default None];
  } [@@deriving yojson { strict = false }]

type local_utils_add_stack_to_tracing_no_reply_args =
  {
    local_utils_add_stack_to_tracing_no_reply_args_call_data: client_side_call_metadata [@key "callData"];
  } [@@deriving yojson { strict = false }]

type frame_frame_element_returns =
  {
    frame_frame_element_returns_element: channel [@key "element"];
  } [@@deriving yojson { strict = false }]

type browser_context_response_event =
  {
    browser_context_response_event_response: channel [@key "response"];
    browser_context_response_event_page: channel option [@key "page"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_pick_locator_returns =
  {
    page_pick_locator_returns_selector: string [@key "selector"];
  } [@@deriving yojson { strict = false }]

type android_device_scroll_args_direction =
  [
  | `Up
  | `Down
  | `Left
  | `Right
  ] [@@deriving yojson]

type android_device_scroll_args =
  {
    android_device_scroll_args_android_selector: android_selector [@key "androidSelector"];
    android_device_scroll_args_direction: android_device_scroll_args_direction [@key "direction"];
    android_device_scroll_args_percent: float [@key "percent"];
    android_device_scroll_args_speed: float option [@key "speed"] [@default None];
    android_device_scroll_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type page_keyboard_down_args =
  {
    page_keyboard_down_args_key: string [@key "key"];
  } [@@deriving yojson { strict = false }]

type browser_default_user_agent_for_test_returns =
  {
    browser_default_user_agent_for_test_returns_user_agent: string [@key "userAgent"];
  } [@@deriving yojson { strict = false }]

type android_device_input_drag_args =
  {
    android_device_input_drag_args_from: point [@key "from"];
    android_device_input_drag_args_to_: point [@key "to"];
    android_device_input_drag_args_steps: int [@key "steps"];
  } [@@deriving yojson { strict = false }]

type stream_read_returns =
  {
    stream_read_returns_binary: string [@key "binary"];
  } [@@deriving yojson { strict = false }]

type browser_context_set_web_socket_interception_patterns_args_patterns_item =
  {
    browser_context_set_web_socket_interception_patterns_args_patterns_item_glob: string option [@key "glob"] [@default None];
    browser_context_set_web_socket_interception_patterns_args_patterns_item_regex_source: string option [@key "regexSource"] [@default None];
    browser_context_set_web_socket_interception_patterns_args_patterns_item_regex_flags: string option [@key "regexFlags"] [@default None];
    browser_context_set_web_socket_interception_patterns_args_patterns_item_url_pattern: url_pattern option [@key "urlPattern"] [@default None];
  } [@@deriving yojson { strict = false }]

type local_utils_har_lookup_args =
  {
    local_utils_har_lookup_args_har_id: string [@key "harId"];
    local_utils_har_lookup_args_url: string [@key "url"];
    local_utils_har_lookup_args_method_: string [@key "method"];
    local_utils_har_lookup_args_headers: name_value list [@key "headers"];
    local_utils_har_lookup_args_post_data: string option [@key "postData"] [@default None];
    local_utils_har_lookup_args_is_navigation_request: bool [@key "isNavigationRequest"];
  } [@@deriving yojson { strict = false }]

type frame_hide_highlight_args =
  {
    frame_hide_highlight_args_selector: string [@key "selector"];
  } [@@deriving yojson { strict = false }]

type frame_get_attribute_returns =
  {
    frame_get_attribute_returns_value: string option [@key "value"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_get_attribute_returns =
  {
    element_handle_get_attribute_returns_value: string option [@key "value"] [@default None];
  } [@@deriving yojson { strict = false }]

type local_utils_glob_to_regex_args =
  {
    local_utils_glob_to_regex_args_glob: string [@key "glob"];
    local_utils_glob_to_regex_args_base_url: string option [@key "baseURL"] [@default None];
    local_utils_glob_to_regex_args_web_socket_url: bool option [@key "webSocketUrl"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_inner_htm_l_args =
  {
    frame_inner_htm_l_args_selector: string [@key "selector"];
    frame_inner_htm_l_args_strict: bool option [@key "strict"] [@default None];
    frame_inner_htm_l_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type frame_aria_ref_returns =
  {
    frame_aria_ref_returns_ref: string option [@key "ref"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_cookies_args =
  {
    browser_context_cookies_args_urls: string list [@key "urls"];
  } [@@deriving yojson { strict = false }]

type frame_select_option_args =
  {
    frame_select_option_args_selector: string [@key "selector"];
    frame_select_option_args_strict: bool option [@key "strict"] [@default None];
    frame_select_option_args_elements: channel list option [@key "elements"] [@default None];
    frame_select_option_args_options: frame_select_option_args_options_item list option [@key "options"] [@default None];
    frame_select_option_args_force: bool option [@key "force"] [@default None];
    frame_select_option_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type page_add_init_script_returns =
  {
    page_add_init_script_returns_disposable: channel [@key "disposable"];
  } [@@deriving yojson { strict = false }]

type page_add_init_script_args =
  {
    page_add_init_script_args_source: string [@key "source"];
  } [@@deriving yojson { strict = false }]

type android_device_info_args =
  {
    android_device_info_args_android_selector: android_selector [@key "androidSelector"];
  } [@@deriving yojson { strict = false }]

type page_update_subscription_args_event =
  [
  | `Console
  | `Dialog
  | `File_chooser
  | `Request
  | `Response
  | `Request_finished
  | `Request_failed
  ] [@@deriving yojson]

type page_update_subscription_args =
  {
    page_update_subscription_args_event: page_update_subscription_args_event [@key "event"];
    page_update_subscription_args_enabled: bool [@key "enabled"];
  } [@@deriving yojson { strict = false }]

type cdp_session_send_returns =
  {
    cdp_session_send_returns_result: json [@key "result"];
  } [@@deriving yojson { strict = false }]

type request_raw_request_headers_returns =
  {
    request_raw_request_headers_returns_headers: name_value list [@key "headers"];
  } [@@deriving yojson { strict = false }]

type page_start_css_coverage_args =
  {
    page_start_css_coverage_args_reset_on_navigation: bool option [@key "resetOnNavigation"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_register_locator_handler_returns =
  {
    page_register_locator_handler_returns_uid: int [@key "uid"];
  } [@@deriving yojson { strict = false }]

type frame_initializer =
  {
    frame_initializer_url: string [@key "url"];
    frame_initializer_name: string [@key "name"];
    frame_initializer_parent_frame: channel option [@key "parentFrame"] [@default None];
    frame_initializer_load_states: lifecycle_event list [@key "loadStates"];
  } [@@deriving yojson { strict = false }]

type page_viewport_size_changed_event =
  {
    page_viewport_size_changed_event_viewport_size: page_viewport_size_changed_event_viewport_size option [@key "viewportSize"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_event =
  {
    browser_context_event_context: channel [@key "context"];
  } [@@deriving yojson { strict = false }]

type element_handle_text_content_returns =
  {
    element_handle_text_content_returns_value: string option [@key "value"] [@default None];
  } [@@deriving yojson { strict = false }]

type api_request_context_storage_state_args =
  {
    api_request_context_storage_state_args_indexed_db: bool option [@key "indexedDB"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_device_launch_browser_args_proxy =
  {
    android_device_launch_browser_args_proxy_server: string [@key "server"];
    android_device_launch_browser_args_proxy_bypass: string option [@key "bypass"] [@default None];
    android_device_launch_browser_args_proxy_username: string option [@key "username"] [@default None];
    android_device_launch_browser_args_proxy_password: string option [@key "password"] [@default None];
  } [@@deriving yojson { strict = false }]

type event_target_wait_for_event_info_args_info_phase =
  [
  | `Before
  | `After
  | `Log
  ] [@@deriving yojson]

type response_body_returns =
  {
    response_body_returns_binary: string [@key "binary"];
  } [@@deriving yojson { strict = false }]

type frame_query_selector_all_args =
  {
    frame_query_selector_all_args_selector: string [@key "selector"];
  } [@@deriving yojson { strict = false }]

type android_devices_returns =
  {
    android_devices_returns_devices: channel list [@key "devices"];
  } [@@deriving yojson { strict = false }]

type page_initializer =
  {
    page_initializer_main_frame: channel [@key "mainFrame"];
    page_initializer_viewport_size: page_initializer_viewport_size option [@key "viewportSize"] [@default None];
    page_initializer_is_closed: bool [@key "isClosed"];
    page_initializer_opener: channel option [@key "opener"] [@default None];
    page_initializer_video: channel option [@key "video"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_new_cdp_session_args =
  {
    browser_context_new_cdp_session_args_page: channel option [@key "page"] [@default None];
    browser_context_new_cdp_session_args_frame: channel option [@key "frame"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_set_viewport_size_args_viewport_size =
  {
    page_set_viewport_size_args_viewport_size_width: int [@key "width"];
    page_set_viewport_size_args_viewport_size_height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type page_set_viewport_size_args =
  {
    page_set_viewport_size_args_viewport_size: page_set_viewport_size_args_viewport_size [@key "viewportSize"];
  } [@@deriving yojson { strict = false }]

type request_sizes =
  {
    request_sizes_request_body_size: int [@key "requestBodySize"];
    request_sizes_request_headers_size: int [@key "requestHeadersSize"];
    request_sizes_response_body_size: int [@key "responseBodySize"];
    request_sizes_response_headers_size: int [@key "responseHeadersSize"];
  } [@@deriving yojson { strict = false }]

type response_sizes_returns =
  {
    response_sizes_returns_sizes: request_sizes [@key "sizes"];
  } [@@deriving yojson { strict = false }]

type frame_is_visible_args =
  {
    frame_is_visible_args_selector: string [@key "selector"];
    frame_is_visible_args_strict: bool option [@key "strict"] [@default None];
  } [@@deriving yojson { strict = false }]

type debug_controller_set_recorder_mode_args_mode =
  [
  | `Inspecting
  | `Recording
  | `None
  ] [@@deriving yojson]

type debug_controller_set_recorder_mode_args =
  {
    debug_controller_set_recorder_mode_args_mode: debug_controller_set_recorder_mode_args_mode [@key "mode"];
    debug_controller_set_recorder_mode_args_test_id_attribute_name: string option [@key "testIdAttributeName"] [@default None];
    debug_controller_set_recorder_mode_args_generate_auto_expect: bool option [@key "generateAutoExpect"] [@default None];
  } [@@deriving yojson { strict = false }]

type debug_controller_set_mode_requested_event =
  {
    debug_controller_set_mode_requested_event_mode: string [@key "mode"];
  } [@@deriving yojson { strict = false }]

type page_stop_js_coverage_returns =
  {
    page_stop_js_coverage_returns_entries: page_stop_js_coverage_returns_entries_item list [@key "entries"];
  } [@@deriving yojson { strict = false }]

type web_socket_route_send_to_page_args =
  {
    web_socket_route_send_to_page_args_message: string [@key "message"];
    web_socket_route_send_to_page_args_is_base64: bool [@key "isBase64"];
  } [@@deriving yojson { strict = false }]

type browser_context_set_extra_http_headers_args =
  {
    browser_context_set_extra_http_headers_args_headers: name_value list [@key "headers"];
  } [@@deriving yojson { strict = false }]

type element_handle_is_enabled_returns =
  {
    element_handle_is_enabled_returns_value: bool [@key "value"];
  } [@@deriving yojson { strict = false }]

type page_pdf_returns =
  {
    page_pdf_returns_pdf: string [@key "pdf"];
  } [@@deriving yojson { strict = false }]

type frame_is_enabled_returns =
  {
    frame_is_enabled_returns_value: bool [@key "value"];
  } [@@deriving yojson { strict = false }]

type browser_context_set_web_socket_interception_patterns_args =
  {
    browser_context_set_web_socket_interception_patterns_args_patterns: browser_context_set_web_socket_interception_patterns_args_patterns_item list [@key "patterns"];
  } [@@deriving yojson { strict = false }]

type browser_start_tracing_args =
  {
    browser_start_tracing_args_page: channel option [@key "page"] [@default None];
    browser_start_tracing_args_screenshots: bool option [@key "screenshots"] [@default None];
    browser_start_tracing_args_categories: string list option [@key "categories"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_web_view =
  {
    android_web_view_pid: int [@key "pid"];
    android_web_view_pkg: string [@key "pkg"];
    android_web_view_socket_name: string [@key "socketName"];
  } [@@deriving yojson { strict = false }]

type android_device_web_view_added_event =
  {
    android_device_web_view_added_event_web_view: android_web_view [@key "webView"];
  } [@@deriving yojson { strict = false }]

type browser_context_clock_set_fixed_time_args =
  {
    browser_context_clock_set_fixed_time_args_time_number: float option [@key "timeNumber"] [@default None];
    browser_context_clock_set_fixed_time_args_time_string: string option [@key "timeString"] [@default None];
  } [@@deriving yojson { strict = false }]

type event_target_wait_for_event_info_args_info =
  {
    event_target_wait_for_event_info_args_info_wait_id: string [@key "waitId"];
    event_target_wait_for_event_info_args_info_phase: event_target_wait_for_event_info_args_info_phase [@key "phase"];
    event_target_wait_for_event_info_args_info_event: string option [@key "event"] [@default None];
    event_target_wait_for_event_info_args_info_message: string option [@key "message"] [@default None];
    event_target_wait_for_event_info_args_info_error: string option [@key "error"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_is_checked_args =
  {
    frame_is_checked_args_selector: string [@key "selector"];
    frame_is_checked_args_strict: bool option [@key "strict"] [@default None];
    frame_is_checked_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type binding_call_resolve_args =
  {
    binding_call_resolve_args_result: serialized_argument [@key "result"];
  } [@@deriving yojson { strict = false }]

type js_handle_json_value_returns =
  {
    js_handle_json_value_returns_value: serialized_value [@key "value"];
  } [@@deriving yojson { strict = false }]

type element_handle_fill_args =
  {
    element_handle_fill_args_value: string [@key "value"];
    element_handle_fill_args_force: bool option [@key "force"] [@default None];
    element_handle_fill_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type browser_context_expose_binding_args =
  {
    browser_context_expose_binding_args_name: string [@key "name"];
  } [@@deriving yojson { strict = false }]

type frame_dispatch_event_args =
  {
    frame_dispatch_event_args_selector: string [@key "selector"];
    frame_dispatch_event_args_strict: bool option [@key "strict"] [@default None];
    frame_dispatch_event_args_type_: string [@key "type"];
    frame_dispatch_event_args_event_init: serialized_argument [@key "eventInit"];
    frame_dispatch_event_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type frame_expect_returns_received =
  {
    frame_expect_returns_received_value: serialized_value option [@key "value"] [@default None];
    frame_expect_returns_received_aria_snapshot: string option [@key "ariaSnapshot"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_expect_returns =
  {
    frame_expect_returns_matches: bool [@key "matches"];
    frame_expect_returns_received: frame_expect_returns_received option [@key "received"] [@default None];
    frame_expect_returns_timed_out: bool option [@key "timedOut"] [@default None];
    frame_expect_returns_error_message: string option [@key "errorMessage"] [@default None];
    frame_expect_returns_log: string list option [@key "log"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_page_errors_args =
  {
    page_page_errors_args_filter: console_messages_filter option [@key "filter"] [@default None];
  } [@@deriving yojson { strict = false }]

type request_initializer =
  {
    request_initializer_frame: channel option [@key "frame"] [@default None];
    request_initializer_service_worker: channel option [@key "serviceWorker"] [@default None];
    request_initializer_url: string [@key "url"];
    request_initializer_resource_type: string [@key "resourceType"];
    request_initializer_method_: string [@key "method"];
    request_initializer_post_data: string option [@key "postData"] [@default None];
    request_initializer_headers: name_value list [@key "headers"];
    request_initializer_is_navigation_request: bool [@key "isNavigationRequest"];
    request_initializer_redirected_from: channel option [@key "redirectedFrom"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_set_web_socket_interception_patterns_args_patterns_item =
  {
    page_set_web_socket_interception_patterns_args_patterns_item_glob: string option [@key "glob"] [@default None];
    page_set_web_socket_interception_patterns_args_patterns_item_regex_source: string option [@key "regexSource"] [@default None];
    page_set_web_socket_interception_patterns_args_patterns_item_regex_flags: string option [@key "regexFlags"] [@default None];
    page_set_web_socket_interception_patterns_args_patterns_item_url_pattern: url_pattern option [@key "urlPattern"] [@default None];
  } [@@deriving yojson { strict = false }]

type js_handle_evaluate_expression_returns =
  {
    js_handle_evaluate_expression_returns_value: serialized_value [@key "value"];
  } [@@deriving yojson { strict = false }]

type browser_new_context_for_reuse_args =
  {
    browser_new_context_for_reuse_args_mixin: context_options [@key "$mixin"];
    browser_new_context_for_reuse_args_proxy: browser_new_context_for_reuse_args_proxy option [@key "proxy"] [@default None];
    browser_new_context_for_reuse_args_storage_state: browser_new_context_for_reuse_args_storage_state option [@key "storageState"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_wait_for_selector_args_state =
  [
  | `Attached
  | `Detached
  | `Visible
  | `Hidden
  ] [@@deriving yojson]

type api_request_context_fetch_response_body_returns =
  {
    api_request_context_fetch_response_body_returns_binary: string option [@key "binary"] [@default None];
  } [@@deriving yojson { strict = false }]

type local_utils_glob_to_regex_returns =
  {
    local_utils_glob_to_regex_returns_regex: string [@key "regex"];
  } [@@deriving yojson { strict = false }]

type element_handle_query_selector_args =
  {
    element_handle_query_selector_args_selector: string [@key "selector"];
    element_handle_query_selector_args_strict: bool option [@key "strict"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_service_worker_event =
  {
    browser_context_service_worker_event_worker: channel [@key "worker"];
  } [@@deriving yojson { strict = false }]

type browser_context_update_subscription_args_event =
  [
  | `Console
  | `Dialog
  | `Request
  | `Response
  | `Request_finished
  | `Request_failed
  ] [@@deriving yojson]

type browser_context_update_subscription_args =
  {
    browser_context_update_subscription_args_event: browser_context_update_subscription_args_event [@key "event"];
    browser_context_update_subscription_args_enabled: bool [@key "enabled"];
  } [@@deriving yojson { strict = false }]

type local_utils_connect_returns =
  {
    local_utils_connect_returns_pipe: channel [@key "pipe"];
    local_utils_connect_returns_headers: name_value list [@key "headers"];
  } [@@deriving yojson { strict = false }]

type page_start_js_coverage_args =
  {
    page_start_js_coverage_args_reset_on_navigation: bool option [@key "resetOnNavigation"] [@default None];
    page_start_js_coverage_args_report_anonymous_scripts: bool option [@key "reportAnonymousScripts"] [@default None];
  } [@@deriving yojson { strict = false }]

type cdp_session_event_event =
  {
    cdp_session_event_event_method_: string [@key "method"];
    cdp_session_event_event_params: json option [@key "params"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_select_text_args =
  {
    element_handle_select_text_args_force: bool option [@key "force"] [@default None];
    element_handle_select_text_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type frame_aria_snapshot_args_mode =
  [
  | `Ai
  | `Default
  ] [@@deriving yojson]

type browser_type_connect_to_worker_args =
  {
    browser_type_connect_to_worker_args_endpoint: string [@key "endpoint"];
    browser_type_connect_to_worker_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type browser_type_connect_over_cd_p_args =
  {
    browser_type_connect_over_cd_p_args_endpoint_url: string [@key "endpointURL"];
    browser_type_connect_over_cd_p_args_headers: name_value list option [@key "headers"] [@default None];
    browser_type_connect_over_cd_p_args_slow_mo: float option [@key "slowMo"] [@default None];
    browser_type_connect_over_cd_p_args_timeout: float [@key "timeout"];
    browser_type_connect_over_cd_p_args_is_local: bool option [@key "isLocal"] [@default None];
    browser_type_connect_over_cd_p_args_no_defaults: bool option [@key "noDefaults"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_type_launch_args =
  {
    browser_type_launch_args_mixin: launch_options [@key "$mixin"];
    browser_type_launch_args_slow_mo: float option [@key "slowMo"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_uncheck_args =
  {
    element_handle_uncheck_args_force: bool option [@key "force"] [@default None];
    element_handle_uncheck_args_position: point option [@key "position"] [@default None];
    element_handle_uncheck_args_timeout: float [@key "timeout"];
    element_handle_uncheck_args_trial: bool option [@key "trial"] [@default None];
  } [@@deriving yojson { strict = false }]

type tracing_tracing_stop_chunk_returns =
  {
    tracing_tracing_stop_chunk_returns_artifact: channel option [@key "artifact"] [@default None];
    tracing_tracing_stop_chunk_returns_entries: name_value list option [@key "entries"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_set_geolocation_args =
  {
    browser_context_set_geolocation_args_geolocation: browser_context_set_geolocation_args_geolocation option [@key "geolocation"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_is_visible_returns =
  {
    element_handle_is_visible_returns_value: bool [@key "value"];
  } [@@deriving yojson { strict = false }]

type js_handle_evaluate_expression_args =
  {
    js_handle_evaluate_expression_args_expression: string [@key "expression"];
    js_handle_evaluate_expression_args_is_function: bool option [@key "isFunction"] [@default None];
    js_handle_evaluate_expression_args_arg: serialized_argument [@key "arg"];
  } [@@deriving yojson { strict = false }]

type browser_context_page_error_event =
  {
    browser_context_page_error_event_error: serialized_error [@key "error"];
    browser_context_page_error_event_page: channel [@key "page"];
    browser_context_page_error_event_location: browser_context_page_error_event_location [@key "location"];
  } [@@deriving yojson { strict = false }]

type js_handle_get_property_args =
  {
    js_handle_get_property_args_name: string [@key "name"];
  } [@@deriving yojson { strict = false }]

type frame_is_hidden_returns =
  {
    frame_is_hidden_returns_value: bool [@key "value"];
  } [@@deriving yojson { strict = false }]

type event_target_wait_for_event_info_args =
  {
    event_target_wait_for_event_info_args_info: event_target_wait_for_event_info_args_info [@key "info"];
  } [@@deriving yojson { strict = false }]

type frame_query_selector_args =
  {
    frame_query_selector_args_selector: string [@key "selector"];
    frame_query_selector_args_strict: bool option [@key "strict"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_touchscreen_tap_args =
  {
    page_touchscreen_tap_args_x: float [@key "x"];
    page_touchscreen_tap_args_y: float [@key "y"];
  } [@@deriving yojson { strict = false }]

type frame_is_disabled_returns =
  {
    frame_is_disabled_returns_value: bool [@key "value"];
  } [@@deriving yojson { strict = false }]

type frame_wait_for_function_returns =
  {
    frame_wait_for_function_returns_handle: channel [@key "handle"];
  } [@@deriving yojson { strict = false }]

type web_socket_frame_received_event =
  {
    web_socket_frame_received_event_opcode: int [@key "opcode"];
    web_socket_frame_received_event_data: string [@key "data"];
  } [@@deriving yojson { strict = false }]

type frame_query_selector_all_returns =
  {
    frame_query_selector_all_returns_elements: channel list [@key "elements"];
  } [@@deriving yojson { strict = false }]

type browser_type_initializer =
  {
    browser_type_initializer_executable_path: string [@key "executablePath"];
    browser_type_initializer_name: string [@key "name"];
  } [@@deriving yojson { strict = false }]

type element_handle_is_disabled_returns =
  {
    element_handle_is_disabled_returns_value: bool [@key "value"];
  } [@@deriving yojson { strict = false }]

type browser_context_grant_permissions_args =
  {
    browser_context_grant_permissions_args_permissions: string list [@key "permissions"];
    browser_context_grant_permissions_args_origin: string option [@key "origin"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_input_value_args =
  {
    frame_input_value_args_selector: string [@key "selector"];
    frame_input_value_args_strict: bool option [@key "strict"] [@default None];
    frame_input_value_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type record_har_options_content =
  [
  | `Embed
  | `Attach
  | `Omit
  ] [@@deriving yojson]

type frame_content_returns =
  {
    frame_content_returns_value: string [@key "value"];
  } [@@deriving yojson { strict = false }]

type frame_loadstate_event =
  {
    frame_loadstate_event_add: lifecycle_event option [@key "add"] [@default None];
    frame_loadstate_event_remove: lifecycle_event option [@key "remove"] [@default None];
  } [@@deriving yojson { strict = false }]

type js_handle_get_property_returns =
  {
    js_handle_get_property_returns_handle: channel [@key "handle"];
  } [@@deriving yojson { strict = false }]

type page_set_web_socket_interception_patterns_args =
  {
    page_set_web_socket_interception_patterns_args_patterns: page_set_web_socket_interception_patterns_args_patterns_item list [@key "patterns"];
  } [@@deriving yojson { strict = false }]

type debugger_run_to_args =
  {
    debugger_run_to_args_location: debugger_run_to_args_location [@key "location"];
  } [@@deriving yojson { strict = false }]

type browser_new_context_for_reuse_returns =
  {
    browser_new_context_for_reuse_returns_context: channel [@key "context"];
  } [@@deriving yojson { strict = false }]

type element_handle_scroll_into_view_if_needed_args =
  {
    element_handle_scroll_into_view_if_needed_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type frame_tap_args_modifiers_item =
  [
  | `Alt
  | `Control
  | `Control_or_meta
  | `Meta
  | `Shift
  ] [@@deriving yojson]

type page_keyboard_press_args =
  {
    page_keyboard_press_args_key: string [@key "key"];
    page_keyboard_press_args_delay: float option [@key "delay"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_set_input_files_args =
  {
    element_handle_set_input_files_args_payloads: element_handle_set_input_files_args_payloads_item list option [@key "payloads"] [@default None];
    element_handle_set_input_files_args_local_directory: string option [@key "localDirectory"] [@default None];
    element_handle_set_input_files_args_directory_stream: channel option [@key "directoryStream"] [@default None];
    element_handle_set_input_files_args_local_paths: string list option [@key "localPaths"] [@default None];
    element_handle_set_input_files_args_streams: channel list option [@key "streams"] [@default None];
    element_handle_set_input_files_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type element_handle_eval_on_selector_args =
  {
    element_handle_eval_on_selector_args_selector: string [@key "selector"];
    element_handle_eval_on_selector_args_strict: bool option [@key "strict"] [@default None];
    element_handle_eval_on_selector_args_expression: string [@key "expression"];
    element_handle_eval_on_selector_args_is_function: bool option [@key "isFunction"] [@default None];
    element_handle_eval_on_selector_args_arg: serialized_argument [@key "arg"];
  } [@@deriving yojson { strict = false }]

type worker_console_event =
  {
    worker_console_event_mixin: console_message [@key "$mixin"];
  } [@@deriving yojson { strict = false }]

type page_screenshot_args_type =
  [
  | `Png
  | `Jpeg
  ] [@@deriving yojson]

type browser_context_clear_cookies_args =
  {
    browser_context_clear_cookies_args_name: string option [@key "name"] [@default None];
    browser_context_clear_cookies_args_name_regex_source: string option [@key "nameRegexSource"] [@default None];
    browser_context_clear_cookies_args_name_regex_flags: string option [@key "nameRegexFlags"] [@default None];
    browser_context_clear_cookies_args_domain: string option [@key "domain"] [@default None];
    browser_context_clear_cookies_args_domain_regex_source: string option [@key "domainRegexSource"] [@default None];
    browser_context_clear_cookies_args_domain_regex_flags: string option [@key "domainRegexFlags"] [@default None];
    browser_context_clear_cookies_args_path: string option [@key "path"] [@default None];
    browser_context_clear_cookies_args_path_regex_source: string option [@key "pathRegexSource"] [@default None];
    browser_context_clear_cookies_args_path_regex_flags: string option [@key "pathRegexFlags"] [@default None];
  } [@@deriving yojson { strict = false }]

type recorder_source_highlight_item =
  {
    recorder_source_highlight_item_line: int [@key "line"];
    recorder_source_highlight_item_type_: string [@key "type"];
  } [@@deriving yojson { strict = false }]

type page_screenshot_args =
  {
    page_screenshot_args_timeout: float [@key "timeout"];
    page_screenshot_args_type_: page_screenshot_args_type option [@key "type"] [@default None];
    page_screenshot_args_quality: int option [@key "quality"] [@default None];
    page_screenshot_args_full_page: bool option [@key "fullPage"] [@default None];
    page_screenshot_args_clip: rect option [@key "clip"] [@default None];
    page_screenshot_args_mixin: common_screenshot_options [@key "$mixin"];
  } [@@deriving yojson { strict = false }]

type artifact_stream_returns =
  {
    artifact_stream_returns_stream: channel [@key "stream"];
  } [@@deriving yojson { strict = false }]

type page_expose_binding_returns =
  {
    page_expose_binding_returns_disposable: channel [@key "disposable"];
  } [@@deriving yojson { strict = false }]

type browser_context_clock_pause_at_args =
  {
    browser_context_clock_pause_at_args_time_number: float option [@key "timeNumber"] [@default None];
    browser_context_clock_pause_at_args_time_string: string option [@key "timeString"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_set_input_files_args_payloads_item =
  {
    frame_set_input_files_args_payloads_item_name: string [@key "name"];
    frame_set_input_files_args_payloads_item_mime_type: string option [@key "mimeType"] [@default None];
    frame_set_input_files_args_payloads_item_buffer: string [@key "buffer"];
  } [@@deriving yojson { strict = false }]

type frame_set_input_files_args =
  {
    frame_set_input_files_args_selector: string [@key "selector"];
    frame_set_input_files_args_strict: bool option [@key "strict"] [@default None];
    frame_set_input_files_args_payloads: frame_set_input_files_args_payloads_item list option [@key "payloads"] [@default None];
    frame_set_input_files_args_local_directory: string option [@key "localDirectory"] [@default None];
    frame_set_input_files_args_directory_stream: channel option [@key "directoryStream"] [@default None];
    frame_set_input_files_args_local_paths: string list option [@key "localPaths"] [@default None];
    frame_set_input_files_args_streams: channel list option [@key "streams"] [@default None];
    frame_set_input_files_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type browser_new_browser_cdp_session_returns =
  {
    browser_new_browser_cdp_session_returns_session: channel [@key "session"];
  } [@@deriving yojson { strict = false }]

type browser_start_server_returns =
  {
    browser_start_server_returns_endpoint: string [@key "endpoint"];
  } [@@deriving yojson { strict = false }]

type frame_click_args_button =
  [
  | `Left
  | `Right
  | `Middle
  ] [@@deriving yojson]

type page_unregister_locator_handler_args =
  {
    page_unregister_locator_handler_args_uid: int [@key "uid"];
  } [@@deriving yojson { strict = false }]

type android_device_input_press_args =
  {
    android_device_input_press_args_key: string [@key "key"];
  } [@@deriving yojson { strict = false }]

type local_utils_zip_args_mode =
  [
  | `Write
  | `Append
  ] [@@deriving yojson]

type local_utils_zip_args =
  {
    local_utils_zip_args_zip_file: string [@key "zipFile"];
    local_utils_zip_args_entries: name_value list [@key "entries"];
    local_utils_zip_args_stacks_id: string option [@key "stacksId"] [@default None];
    local_utils_zip_args_mode: local_utils_zip_args_mode [@key "mode"];
    local_utils_zip_args_include_sources: bool [@key "includeSources"];
    local_utils_zip_args_additional_sources: string list option [@key "additionalSources"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_frame_detached_event =
  {
    page_frame_detached_event_frame: channel [@key "frame"];
  } [@@deriving yojson { strict = false }]

type element_handle_is_editable_returns =
  {
    element_handle_is_editable_returns_value: bool [@key "value"];
  } [@@deriving yojson { strict = false }]

type browser_context_clock_install_args =
  {
    browser_context_clock_install_args_time_number: float option [@key "timeNumber"] [@default None];
    browser_context_clock_install_args_time_string: string option [@key "timeString"] [@default None];
  } [@@deriving yojson { strict = false }]

type record_har_options =
  {
    record_har_options_zip: bool option [@key "zip"] [@default None];
    record_har_options_content: record_har_options_content option [@key "content"] [@default None];
    record_har_options_mode: record_har_options_mode option [@key "mode"] [@default None];
    record_har_options_url_glob: string option [@key "urlGlob"] [@default None];
    record_har_options_url_regex_source: string option [@key "urlRegexSource"] [@default None];
    record_har_options_url_regex_flags: string option [@key "urlRegexFlags"] [@default None];
  } [@@deriving yojson { strict = false }]

type tracing_har_start_args =
  {
    tracing_har_start_args_page: channel option [@key "page"] [@default None];
    tracing_har_start_args_options: record_har_options [@key "options"];
  } [@@deriving yojson { strict = false }]

type debug_controller_source_changed_event =
  {
    debug_controller_source_changed_event_text: string [@key "text"];
    debug_controller_source_changed_event_header: string option [@key "header"] [@default None];
    debug_controller_source_changed_event_footer: string option [@key "footer"] [@default None];
    debug_controller_source_changed_event_actions: string list option [@key "actions"] [@default None];
  } [@@deriving yojson { strict = false }]

type api_response =
  {
    api_response_fetch_uid: string [@key "fetchUid"];
    api_response_url: string [@key "url"];
    api_response_status: int [@key "status"];
    api_response_status_text: string [@key "statusText"];
    api_response_headers: name_value list [@key "headers"];
  } [@@deriving yojson { strict = false }]

type playwright_new_request_args_storage_state =
  {
    playwright_new_request_args_storage_state_cookies: network_cookie list option [@key "cookies"] [@default None];
    playwright_new_request_args_storage_state_origins: set_origin_storage list option [@key "origins"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_device_launch_browser_args =
  {
    android_device_launch_browser_args_mixin: context_options [@key "$mixin"];
    android_device_launch_browser_args_pkg: string option [@key "pkg"] [@default None];
    android_device_launch_browser_args_args: string list option [@key "args"] [@default None];
    android_device_launch_browser_args_proxy: android_device_launch_browser_args_proxy option [@key "proxy"] [@default None];
  } [@@deriving yojson { strict = false }]

type response_http_version_returns =
  {
    response_http_version_returns_value: string [@key "value"];
  } [@@deriving yojson { strict = false }]

type frame_blur_args =
  {
    frame_blur_args_selector: string [@key "selector"];
    frame_blur_args_strict: bool option [@key "strict"] [@default None];
    frame_blur_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type api_request_context_fetch_log_returns =
  {
    api_request_context_fetch_log_returns_log: string list [@key "log"];
  } [@@deriving yojson { strict = false }]

type frame_query_count_args =
  {
    frame_query_count_args_selector: string [@key "selector"];
  } [@@deriving yojson { strict = false }]

type socks_support_socks_closed_event =
  {
    socks_support_socks_closed_event_uid: string [@key "uid"];
  } [@@deriving yojson { strict = false }]

type frame_eval_on_selector_all_returns =
  {
    frame_eval_on_selector_all_returns_value: serialized_value [@key "value"];
  } [@@deriving yojson { strict = false }]

type api_request_context_initializer =
  {
    api_request_context_initializer_tracing: channel [@key "tracing"];
  } [@@deriving yojson { strict = false }]

type page_screencast_frame_event =
  {
    page_screencast_frame_event_data: string [@key "data"];
  } [@@deriving yojson { strict = false }]

type browser_initializer_browser_name =
  [
  | `Chromium
  | `Firefox
  | `Webkit
  ] [@@deriving yojson]

type browser_initializer =
  {
    browser_initializer_version: string [@key "version"];
    browser_initializer_name: string [@key "name"];
    browser_initializer_browser_name: browser_initializer_browser_name [@key "browserName"];
  } [@@deriving yojson { strict = false }]

type element_handle_click_args_button =
  [
  | `Left
  | `Right
  | `Middle
  ] [@@deriving yojson]

type element_handle_click_args =
  {
    element_handle_click_args_force: bool option [@key "force"] [@default None];
    element_handle_click_args_no_wait_after: bool option [@key "noWaitAfter"] [@default None];
    element_handle_click_args_modifiers: element_handle_click_args_modifiers_item list option [@key "modifiers"] [@default None];
    element_handle_click_args_position: point option [@key "position"] [@default None];
    element_handle_click_args_delay: float option [@key "delay"] [@default None];
    element_handle_click_args_button: element_handle_click_args_button option [@key "button"] [@default None];
    element_handle_click_args_click_count: int option [@key "clickCount"] [@default None];
    element_handle_click_args_timeout: float [@key "timeout"];
    element_handle_click_args_trial: bool option [@key "trial"] [@default None];
    element_handle_click_args_steps: int option [@key "steps"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_device_input_tap_args =
  {
    android_device_input_tap_args_point: point [@key "point"];
  } [@@deriving yojson { strict = false }]

type tracing_har_start_returns =
  {
    tracing_har_start_returns_har_id: string [@key "harId"];
  } [@@deriving yojson { strict = false }]

type page_register_locator_handler_args =
  {
    page_register_locator_handler_args_selector: string [@key "selector"];
    page_register_locator_handler_args_no_wait_after: bool option [@key "noWaitAfter"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_new_context_returns =
  {
    browser_new_context_returns_context: channel [@key "context"];
  } [@@deriving yojson { strict = false }]

type page_go_back_returns =
  {
    page_go_back_returns_response: channel option [@key "response"] [@default None];
  } [@@deriving yojson { strict = false }]

type route_abort_args =
  {
    route_abort_args_error_code: string option [@key "errorCode"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_click_args =
  {
    frame_click_args_selector: string [@key "selector"];
    frame_click_args_strict: bool option [@key "strict"] [@default None];
    frame_click_args_force: bool option [@key "force"] [@default None];
    frame_click_args_no_wait_after: bool option [@key "noWaitAfter"] [@default None];
    frame_click_args_modifiers: frame_click_args_modifiers_item list option [@key "modifiers"] [@default None];
    frame_click_args_position: point option [@key "position"] [@default None];
    frame_click_args_delay: float option [@key "delay"] [@default None];
    frame_click_args_button: frame_click_args_button option [@key "button"] [@default None];
    frame_click_args_click_count: int option [@key "clickCount"] [@default None];
    frame_click_args_timeout: float [@key "timeout"];
    frame_click_args_trial: bool option [@key "trial"] [@default None];
    frame_click_args_steps: int option [@key "steps"] [@default None];
  } [@@deriving yojson { strict = false }]

type request_response_returns =
  {
    request_response_returns_response: channel option [@key "response"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_press_args =
  {
    element_handle_press_args_key: string [@key "key"];
    element_handle_press_args_delay: float option [@key "delay"] [@default None];
    element_handle_press_args_timeout: float [@key "timeout"];
    element_handle_press_args_no_wait_after: bool option [@key "noWaitAfter"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_clock_fast_forward_args =
  {
    browser_context_clock_fast_forward_args_ticks_number: float option [@key "ticksNumber"] [@default None];
    browser_context_clock_fast_forward_args_ticks_string: string option [@key "ticksString"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_type_connect_over_cd_p_returns =
  {
    browser_type_connect_over_cd_p_returns_browser: channel [@key "browser"];
    browser_type_connect_over_cd_p_returns_default_context: channel option [@key "defaultContext"] [@default None];
  } [@@deriving yojson { strict = false }]

type route_fulfill_args =
  {
    route_fulfill_args_status: int option [@key "status"] [@default None];
    route_fulfill_args_headers: name_value list option [@key "headers"] [@default None];
    route_fulfill_args_body: string option [@key "body"] [@default None];
    route_fulfill_args_is_base64: bool option [@key "isBase64"] [@default None];
    route_fulfill_args_fetch_response_uid: string option [@key "fetchResponseUid"] [@default None];
  } [@@deriving yojson { strict = false }]

type js_handle_initializer =
  {
    js_handle_initializer_preview: string [@key "preview"];
  } [@@deriving yojson { strict = false }]

type browser_context_binding_call_event =
  {
    browser_context_binding_call_event_binding: channel [@key "binding"];
  } [@@deriving yojson { strict = false }]

type api_request_context_fetch_returns =
  {
    api_request_context_fetch_returns_response: api_response [@key "response"];
  } [@@deriving yojson { strict = false }]

type android_device_connect_to_web_view_args =
  {
    android_device_connect_to_web_view_args_socket_name: string [@key "socketName"];
  } [@@deriving yojson { strict = false }]

type android_device_install_apk_args =
  {
    android_device_install_apk_args_file: string [@key "file"];
    android_device_install_apk_args_args: string list option [@key "args"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_set_offline_args =
  {
    browser_context_set_offline_args_offline: bool [@key "offline"];
  } [@@deriving yojson { strict = false }]

type browser_context_new_page_returns =
  {
    browser_context_new_page_returns_page: channel [@key "page"];
  } [@@deriving yojson { strict = false }]

type debug_controller_highlight_args =
  {
    debug_controller_highlight_args_selector: string option [@key "selector"] [@default None];
    debug_controller_highlight_args_aria_template: string option [@key "ariaTemplate"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_wait_for_selector_args =
  {
    element_handle_wait_for_selector_args_selector: string [@key "selector"];
    element_handle_wait_for_selector_args_strict: bool option [@key "strict"] [@default None];
    element_handle_wait_for_selector_args_timeout: float [@key "timeout"];
    element_handle_wait_for_selector_args_state: element_handle_wait_for_selector_args_state option [@key "state"] [@default None];
  } [@@deriving yojson { strict = false }]

type route_initializer =
  {
    route_initializer_request: channel [@key "request"];
  } [@@deriving yojson { strict = false }]

type frame_dblclick_args_modifiers_item =
  [
  | `Alt
  | `Control
  | `Control_or_meta
  | `Meta
  | `Shift
  ] [@@deriving yojson]

type frame_dblclick_args =
  {
    frame_dblclick_args_selector: string [@key "selector"];
    frame_dblclick_args_strict: bool option [@key "strict"] [@default None];
    frame_dblclick_args_force: bool option [@key "force"] [@default None];
    frame_dblclick_args_modifiers: frame_dblclick_args_modifiers_item list option [@key "modifiers"] [@default None];
    frame_dblclick_args_position: point option [@key "position"] [@default None];
    frame_dblclick_args_delay: float option [@key "delay"] [@default None];
    frame_dblclick_args_button: frame_dblclick_args_button option [@key "button"] [@default None];
    frame_dblclick_args_timeout: float [@key "timeout"];
    frame_dblclick_args_trial: bool option [@key "trial"] [@default None];
    frame_dblclick_args_steps: int option [@key "steps"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_reload_returns =
  {
    page_reload_returns_response: channel option [@key "response"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_initializer =
  {
    browser_context_initializer_debugger: channel [@key "debugger"];
    browser_context_initializer_request_context: channel [@key "requestContext"];
    browser_context_initializer_tracing: channel [@key "tracing"];
    browser_context_initializer_options: browser_context_initializer_options [@key "options"];
  } [@@deriving yojson { strict = false }]

type response_raw_response_headers_returns =
  {
    response_raw_response_headers_returns_headers: name_value list [@key "headers"];
  } [@@deriving yojson { strict = false }]

type android_device_initializer =
  {
    android_device_initializer_model: string [@key "model"];
    android_device_initializer_serial: string [@key "serial"];
  } [@@deriving yojson { strict = false }]

type web_socket_frame_sent_event =
  {
    web_socket_frame_sent_event_opcode: int [@key "opcode"];
    web_socket_frame_sent_event_data: string [@key "data"];
  } [@@deriving yojson { strict = false }]

type page_expect_screenshot_returns =
  {
    page_expect_screenshot_returns_diff: string option [@key "diff"] [@default None];
    page_expect_screenshot_returns_error_message: string option [@key "errorMessage"] [@default None];
    page_expect_screenshot_returns_actual: string option [@key "actual"] [@default None];
    page_expect_screenshot_returns_previous: string option [@key "previous"] [@default None];
    page_expect_screenshot_returns_timed_out: bool option [@key "timedOut"] [@default None];
    page_expect_screenshot_returns_log: string list option [@key "log"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_screenshot_returns =
  {
    element_handle_screenshot_returns_binary: string [@key "binary"];
  } [@@deriving yojson { strict = false }]

type frame_hover_args =
  {
    frame_hover_args_selector: string [@key "selector"];
    frame_hover_args_strict: bool option [@key "strict"] [@default None];
    frame_hover_args_force: bool option [@key "force"] [@default None];
    frame_hover_args_modifiers: frame_hover_args_modifiers_item list option [@key "modifiers"] [@default None];
    frame_hover_args_position: point option [@key "position"] [@default None];
    frame_hover_args_timeout: float [@key "timeout"];
    frame_hover_args_trial: bool option [@key "trial"] [@default None];
  } [@@deriving yojson { strict = false }]

type worker_evaluate_expression_handle_returns =
  {
    worker_evaluate_expression_handle_returns_handle: channel [@key "handle"];
  } [@@deriving yojson { strict = false }]

type frame_tap_args =
  {
    frame_tap_args_selector: string [@key "selector"];
    frame_tap_args_strict: bool option [@key "strict"] [@default None];
    frame_tap_args_force: bool option [@key "force"] [@default None];
    frame_tap_args_modifiers: frame_tap_args_modifiers_item list option [@key "modifiers"] [@default None];
    frame_tap_args_position: point option [@key "position"] [@default None];
    frame_tap_args_timeout: float [@key "timeout"];
    frame_tap_args_trial: bool option [@key "trial"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_check_args =
  {
    frame_check_args_selector: string [@key "selector"];
    frame_check_args_strict: bool option [@key "strict"] [@default None];
    frame_check_args_force: bool option [@key "force"] [@default None];
    frame_check_args_position: point option [@key "position"] [@default None];
    frame_check_args_timeout: float [@key "timeout"];
    frame_check_args_trial: bool option [@key "trial"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_binding_call_event =
  {
    page_binding_call_event_binding: channel [@key "binding"];
  } [@@deriving yojson { strict = false }]

type element_handle_wait_for_element_state_args =
  {
    element_handle_wait_for_element_state_args_state: element_handle_wait_for_element_state_args_state [@key "state"];
    element_handle_wait_for_element_state_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type android_device_launch_browser_returns =
  {
    android_device_launch_browser_returns_context: channel [@key "context"];
  } [@@deriving yojson { strict = false }]

type artifact_initializer =
  {
    artifact_initializer_absolute_path: string [@key "absolutePath"];
  } [@@deriving yojson { strict = false }]

type tracing_har_export_returns =
  {
    tracing_har_export_returns_artifact: channel [@key "artifact"];
  } [@@deriving yojson { strict = false }]

type frame_text_content_args =
  {
    frame_text_content_args_selector: string [@key "selector"];
    frame_text_content_args_strict: bool option [@key "strict"] [@default None];
    frame_text_content_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type page_screencast_remove_overlay_args =
  {
    page_screencast_remove_overlay_args_id: string [@key "id"];
  } [@@deriving yojson { strict = false }]

type android_device_open_args =
  {
    android_device_open_args_command: string [@key "command"];
  } [@@deriving yojson { strict = false }]

type worker_evaluate_expression_handle_args =
  {
    worker_evaluate_expression_handle_args_expression: string [@key "expression"];
    worker_evaluate_expression_handle_args_is_function: bool option [@key "isFunction"] [@default None];
    worker_evaluate_expression_handle_args_arg: serialized_argument [@key "arg"];
  } [@@deriving yojson { strict = false }]

type browser_context_add_init_script_args =
  {
    browser_context_add_init_script_args_source: string [@key "source"];
  } [@@deriving yojson { strict = false }]

type page_screencast_show_overlay_returns =
  {
    page_screencast_show_overlay_returns_id: string [@key "id"];
  } [@@deriving yojson { strict = false }]

type page_file_chooser_event =
  {
    page_file_chooser_event_element: channel [@key "element"];
    page_file_chooser_event_is_multiple: bool [@key "isMultiple"];
  } [@@deriving yojson { strict = false }]

type js_handle_evaluate_expression_handle_args =
  {
    js_handle_evaluate_expression_handle_args_expression: string [@key "expression"];
    js_handle_evaluate_expression_handle_args_is_function: bool option [@key "isFunction"] [@default None];
    js_handle_evaluate_expression_handle_args_arg: serialized_argument [@key "arg"];
  } [@@deriving yojson { strict = false }]

type element_handle_is_hidden_returns =
  {
    element_handle_is_hidden_returns_value: bool [@key "value"];
  } [@@deriving yojson { strict = false }]

type worker_evaluate_expression_returns =
  {
    worker_evaluate_expression_returns_value: serialized_value [@key "value"];
  } [@@deriving yojson { strict = false }]

type local_utils_initializer =
  {
    local_utils_initializer_device_descriptors: local_utils_initializer_device_descriptors_item list [@key "deviceDescriptors"];
  } [@@deriving yojson { strict = false }]

type frame_expect_args =
  {
    frame_expect_args_selector: string option [@key "selector"] [@default None];
    frame_expect_args_expression: string [@key "expression"];
    frame_expect_args_expression_arg: json option [@key "expressionArg"] [@default None];
    frame_expect_args_pseudo: frame_expect_args_pseudo option [@key "pseudo"] [@default None];
    frame_expect_args_expected_text: expected_text_value list option [@key "expectedText"] [@default None];
    frame_expect_args_expected_number: float option [@key "expectedNumber"] [@default None];
    frame_expect_args_expected_value: serialized_argument option [@key "expectedValue"] [@default None];
    frame_expect_args_use_inner_text: bool option [@key "useInnerText"] [@default None];
    frame_expect_args_is_not: bool [@key "isNot"];
    frame_expect_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type local_utils_har_open_returns =
  {
    local_utils_har_open_returns_har_id: string option [@key "harId"] [@default None];
    local_utils_har_open_returns_error: string option [@key "error"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_device_drag_args =
  {
    android_device_drag_args_android_selector: android_selector [@key "androidSelector"];
    android_device_drag_args_dest: point [@key "dest"];
    android_device_drag_args_speed: float option [@key "speed"] [@default None];
    android_device_drag_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type element_handle_query_selector_all_args =
  {
    element_handle_query_selector_all_args_selector: string [@key "selector"];
  } [@@deriving yojson { strict = false }]

type frame_goto_returns =
  {
    frame_goto_returns_response: channel option [@key "response"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_select_option_returns =
  {
    frame_select_option_returns_values: string list [@key "values"];
  } [@@deriving yojson { strict = false }]

type frame_eval_on_selector_all_args =
  {
    frame_eval_on_selector_all_args_selector: string [@key "selector"];
    frame_eval_on_selector_all_args_expression: string [@key "expression"];
    frame_eval_on_selector_all_args_is_function: bool option [@key "isFunction"] [@default None];
    frame_eval_on_selector_all_args_arg: serialized_argument [@key "arg"];
  } [@@deriving yojson { strict = false }]

type android_device_fling_args_direction =
  [
  | `Up
  | `Down
  | `Left
  | `Right
  ] [@@deriving yojson]

type android_device_fling_args =
  {
    android_device_fling_args_android_selector: android_selector [@key "androidSelector"];
    android_device_fling_args_direction: android_device_fling_args_direction [@key "direction"];
    android_device_fling_args_speed: float option [@key "speed"] [@default None];
    android_device_fling_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type frame_query_selector_returns =
  {
    frame_query_selector_returns_element: channel option [@key "element"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_requests_returns =
  {
    page_requests_returns_requests: channel list [@key "requests"];
  } [@@deriving yojson { strict = false }]

type api_request_context_storage_state_returns =
  {
    api_request_context_storage_state_returns_cookies: network_cookie list [@key "cookies"];
    api_request_context_storage_state_returns_origins: origin_storage list [@key "origins"];
  } [@@deriving yojson { strict = false }]

type browser_context_add_init_script_returns =
  {
    browser_context_add_init_script_returns_disposable: channel [@key "disposable"];
  } [@@deriving yojson { strict = false }]

type debug_controller_paused_event =
  {
    debug_controller_paused_event_paused: bool [@key "paused"];
  } [@@deriving yojson { strict = false }]

type page_screencast_start_returns =
  {
    page_screencast_start_returns_artifact: channel option [@key "artifact"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_drop_args_data_item =
  {
    frame_drop_args_data_item_mime_type: string [@key "mimeType"];
    frame_drop_args_data_item_value: string [@key "value"];
  } [@@deriving yojson { strict = false }]

type frame_drop_args =
  {
    frame_drop_args_selector: string [@key "selector"];
    frame_drop_args_strict: bool option [@key "strict"] [@default None];
    frame_drop_args_position: point option [@key "position"] [@default None];
    frame_drop_args_payloads: frame_drop_args_payloads_item list option [@key "payloads"] [@default None];
    frame_drop_args_local_paths: string list option [@key "localPaths"] [@default None];
    frame_drop_args_streams: channel list option [@key "streams"] [@default None];
    frame_drop_args_data: frame_drop_args_data_item list option [@key "data"] [@default None];
    frame_drop_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type android_device_input_type_args =
  {
    android_device_input_type_args_text: string [@key "text"];
  } [@@deriving yojson { strict = false }]

type browser_disconnect_from_reused_context_args =
  {
    browser_disconnect_from_reused_context_args_reason: string [@key "reason"];
  } [@@deriving yojson { strict = false }]

type recorder_source =
  {
    recorder_source_is_recorded: bool [@key "isRecorded"];
    recorder_source_id: string [@key "id"];
    recorder_source_label: string [@key "label"];
    recorder_source_text: string [@key "text"];
    recorder_source_language: string [@key "language"];
    recorder_source_highlight: recorder_source_highlight_item list [@key "highlight"];
    recorder_source_reveal_line: int option [@key "revealLine"] [@default None];
    recorder_source_group: string option [@key "group"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_query_selector_returns =
  {
    element_handle_query_selector_returns_element: channel option [@key "element"] [@default None];
  } [@@deriving yojson { strict = false }]

type worker_disconnect_args =
  {
    worker_disconnect_args_reason: string option [@key "reason"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_wait_for_selector_returns =
  {
    frame_wait_for_selector_returns_element: channel option [@key "element"] [@default None];
  } [@@deriving yojson { strict = false }]

type web_socket_route_send_to_server_args =
  {
    web_socket_route_send_to_server_args_message: string [@key "message"];
    web_socket_route_send_to_server_args_is_base64: bool [@key "isBase64"];
  } [@@deriving yojson { strict = false }]

type tracing_har_export_args =
  {
    tracing_har_export_args_har_id: string option [@key "harId"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_is_visible_returns =
  {
    frame_is_visible_returns_value: bool [@key "value"];
  } [@@deriving yojson { strict = false }]

type artifact_save_as_args =
  {
    artifact_save_as_args_path: string [@key "path"];
  } [@@deriving yojson { strict = false }]

type browser_context_cookies_returns =
  {
    browser_context_cookies_returns_cookies: network_cookie list [@key "cookies"];
  } [@@deriving yojson { strict = false }]

type route_continue_args =
  {
    route_continue_args_url: string option [@key "url"] [@default None];
    route_continue_args_method_: string option [@key "method"] [@default None];
    route_continue_args_headers: name_value list option [@key "headers"] [@default None];
    route_continue_args_post_data: string option [@key "postData"] [@default None];
    route_continue_args_is_fallback: bool [@key "isFallback"];
  } [@@deriving yojson { strict = false }]

type frame_inner_text_args =
  {
    frame_inner_text_args_selector: string [@key "selector"];
    frame_inner_text_args_strict: bool option [@key "strict"] [@default None];
    frame_inner_text_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type api_request_context_fetch_response_body_args =
  {
    api_request_context_fetch_response_body_args_fetch_uid: string [@key "fetchUid"];
  } [@@deriving yojson { strict = false }]

type debug_controller_state_changed_event =
  {
    debug_controller_state_changed_event_page_count: int [@key "pageCount"];
  } [@@deriving yojson { strict = false }]

type page_frame_attached_event =
  {
    page_frame_attached_event_frame: channel [@key "frame"];
  } [@@deriving yojson { strict = false }]

type api_request_context_dispose_args =
  {
    api_request_context_dispose_args_reason: string option [@key "reason"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_element_info =
  {
    android_element_info_children: android_element_info list option [@key "children"] [@default None];
    android_element_info_clazz: string [@key "clazz"];
    android_element_info_desc: string [@key "desc"];
    android_element_info_res: string [@key "res"];
    android_element_info_pkg: string [@key "pkg"];
    android_element_info_text: string [@key "text"];
    android_element_info_bounds: rect [@key "bounds"];
    android_element_info_checkable: bool [@key "checkable"];
    android_element_info_checked: bool [@key "checked"];
    android_element_info_clickable: bool [@key "clickable"];
    android_element_info_enabled: bool [@key "enabled"];
    android_element_info_focusable: bool [@key "focusable"];
    android_element_info_focused: bool [@key "focused"];
    android_element_info_long_clickable: bool [@key "longClickable"];
    android_element_info_scrollable: bool [@key "scrollable"];
    android_element_info_selected: bool [@key "selected"];
  } [@@deriving yojson { strict = false }]

type element_handle_type_args =
  {
    element_handle_type_args_text: string [@key "text"];
    element_handle_type_args_delay: float option [@key "delay"] [@default None];
    element_handle_type_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type web_socket_route_initializer =
  {
    web_socket_route_initializer_url: string [@key "url"];
    web_socket_route_initializer_protocols: string list [@key "protocols"];
  } [@@deriving yojson { strict = false }]

type local_utils_tracing_started_args =
  {
    local_utils_tracing_started_args_traces_dir: string option [@key "tracesDir"] [@default None];
    local_utils_tracing_started_args_trace_name: string [@key "traceName"];
    local_utils_tracing_started_args_live: bool option [@key "live"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_locator_handler_triggered_event =
  {
    page_locator_handler_triggered_event_uid: int [@key "uid"];
  } [@@deriving yojson { strict = false }]

type android_device_long_tap_args =
  {
    android_device_long_tap_args_android_selector: android_selector [@key "androidSelector"];
    android_device_long_tap_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type browser_context_add_cookies_args =
  {
    browser_context_add_cookies_args_cookies: set_network_cookie list [@key "cookies"];
  } [@@deriving yojson { strict = false }]

type frame_text_content_returns =
  {
    frame_text_content_returns_value: string option [@key "value"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_device_connect_to_web_view_returns =
  {
    android_device_connect_to_web_view_returns_context: channel [@key "context"];
  } [@@deriving yojson { strict = false }]

type browser_new_context_args =
  {
    browser_new_context_args_mixin: context_options [@key "$mixin"];
    browser_new_context_args_proxy: browser_new_context_args_proxy option [@key "proxy"] [@default None];
    browser_new_context_args_storage_state: browser_new_context_args_storage_state option [@key "storageState"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_web_socket_event =
  {
    page_web_socket_event_web_socket: channel [@key "webSocket"];
  } [@@deriving yojson { strict = false }]

type page_keyboard_insert_text_args =
  {
    page_keyboard_insert_text_args_text: string [@key "text"];
  } [@@deriving yojson { strict = false }]

type page_expose_binding_args =
  {
    page_expose_binding_args_name: string [@key "name"];
  } [@@deriving yojson { strict = false }]

type android_device_tap_args =
  {
    android_device_tap_args_android_selector: android_selector [@key "androidSelector"];
    android_device_tap_args_duration: float option [@key "duration"] [@default None];
    android_device_tap_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type frame_query_count_returns =
  {
    frame_query_count_returns_value: int [@key "value"];
  } [@@deriving yojson { strict = false }]

type frame_is_editable_returns =
  {
    frame_is_editable_returns_value: bool [@key "value"];
  } [@@deriving yojson { strict = false }]

type page_mouse_down_args =
  {
    page_mouse_down_args_button: page_mouse_down_args_button option [@key "button"] [@default None];
    page_mouse_down_args_click_count: int option [@key "clickCount"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_set_network_interception_patterns_args_patterns_item =
  {
    browser_context_set_network_interception_patterns_args_patterns_item_glob: string option [@key "glob"] [@default None];
    browser_context_set_network_interception_patterns_args_patterns_item_regex_source: string option [@key "regexSource"] [@default None];
    browser_context_set_network_interception_patterns_args_patterns_item_regex_flags: string option [@key "regexFlags"] [@default None];
    browser_context_set_network_interception_patterns_args_patterns_item_url_pattern: url_pattern option [@key "urlPattern"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_set_http_credentials_args =
  {
    browser_context_set_http_credentials_args_http_credentials: browser_context_set_http_credentials_args_http_credentials option [@key "httpCredentials"] [@default None];
  } [@@deriving yojson { strict = false }]

type stream_read_args =
  {
    stream_read_args_size: int option [@key "size"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_eval_on_selector_args =
  {
    frame_eval_on_selector_args_selector: string [@key "selector"];
    frame_eval_on_selector_args_strict: bool option [@key "strict"] [@default None];
    frame_eval_on_selector_args_expression: string [@key "expression"];
    frame_eval_on_selector_args_is_function: bool option [@key "isFunction"] [@default None];
    frame_eval_on_selector_args_arg: serialized_argument [@key "arg"];
  } [@@deriving yojson { strict = false }]

type frame_eval_on_selector_returns =
  {
    frame_eval_on_selector_returns_value: serialized_value [@key "value"];
  } [@@deriving yojson { strict = false }]

type frame_wait_for_timeout_args =
  {
    frame_wait_for_timeout_args_wait_timeout: float [@key "waitTimeout"];
  } [@@deriving yojson { strict = false }]

type socks_support_socks_requested_event =
  {
    socks_support_socks_requested_event_uid: string [@key "uid"];
    socks_support_socks_requested_event_host: string [@key "host"];
    socks_support_socks_requested_event_port: int [@key "port"];
  } [@@deriving yojson { strict = false }]

type playwright_new_request_returns =
  {
    playwright_new_request_returns_request: channel [@key "request"];
  } [@@deriving yojson { strict = false }]

type element_handle_eval_on_selector_all_args =
  {
    element_handle_eval_on_selector_all_args_selector: string [@key "selector"];
    element_handle_eval_on_selector_all_args_expression: string [@key "expression"];
    element_handle_eval_on_selector_all_args_is_function: bool option [@key "isFunction"] [@default None];
    element_handle_eval_on_selector_all_args_arg: serialized_argument [@key "arg"];
  } [@@deriving yojson { strict = false }]

type tracing_tracing_group_args =
  {
    tracing_tracing_group_args_name: string [@key "name"];
    tracing_tracing_group_args_location: tracing_tracing_group_args_location option [@key "location"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_wait_for_selector_returns =
  {
    element_handle_wait_for_selector_returns_element: channel option [@key "element"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_aria_snapshot_args =
  {
    frame_aria_snapshot_args_mode: frame_aria_snapshot_args_mode option [@key "mode"] [@default None];
    frame_aria_snapshot_args_track: string option [@key "track"] [@default None];
    frame_aria_snapshot_args_selector: string option [@key "selector"] [@default None];
    frame_aria_snapshot_args_depth: int option [@key "depth"] [@default None];
    frame_aria_snapshot_args_boxes: bool option [@key "boxes"] [@default None];
    frame_aria_snapshot_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type browser_context_clock_set_system_time_args =
  {
    browser_context_clock_set_system_time_args_time_number: float option [@key "timeNumber"] [@default None];
    browser_context_clock_set_system_time_args_time_string: string option [@key "timeString"] [@default None];
  } [@@deriving yojson { strict = false }]

type web_socket_route_close_page_event =
  {
    web_socket_route_close_page_event_code: int option [@key "code"] [@default None];
    web_socket_route_close_page_event_reason: string option [@key "reason"] [@default None];
    web_socket_route_close_page_event_was_clean: bool [@key "wasClean"];
  } [@@deriving yojson { strict = false }]

type playwright_new_request_args =
  {
    playwright_new_request_args_base_url: string option [@key "baseURL"] [@default None];
    playwright_new_request_args_user_agent: string option [@key "userAgent"] [@default None];
    playwright_new_request_args_ignore_https_errors: bool option [@key "ignoreHTTPSErrors"] [@default None];
    playwright_new_request_args_extra_http_headers: name_value list option [@key "extraHTTPHeaders"] [@default None];
    playwright_new_request_args_fail_on_status_code: bool option [@key "failOnStatusCode"] [@default None];
    playwright_new_request_args_client_certificates: playwright_new_request_args_client_certificates_item list option [@key "clientCertificates"] [@default None];
    playwright_new_request_args_max_redirects: int option [@key "maxRedirects"] [@default None];
    playwright_new_request_args_http_credentials: playwright_new_request_args_http_credentials option [@key "httpCredentials"] [@default None];
    playwright_new_request_args_proxy: playwright_new_request_args_proxy option [@key "proxy"] [@default None];
    playwright_new_request_args_storage_state: playwright_new_request_args_storage_state option [@key "storageState"] [@default None];
    playwright_new_request_args_traces_dir: string option [@key "tracesDir"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_stop_tracing_returns =
  {
    browser_stop_tracing_returns_artifact: channel [@key "artifact"];
  } [@@deriving yojson { strict = false }]

type element_handle_bounding_box_returns =
  {
    element_handle_bounding_box_returns_value: rect option [@key "value"] [@default None];
  } [@@deriving yojson { strict = false }]

type api_request_context_fetch_args =
  {
    api_request_context_fetch_args_url: string [@key "url"];
    api_request_context_fetch_args_encoded_params: string option [@key "encodedParams"] [@default None];
    api_request_context_fetch_args_params: name_value list option [@key "params"] [@default None];
    api_request_context_fetch_args_method_: string option [@key "method"] [@default None];
    api_request_context_fetch_args_headers: name_value list option [@key "headers"] [@default None];
    api_request_context_fetch_args_post_data: string option [@key "postData"] [@default None];
    api_request_context_fetch_args_json_data: string option [@key "jsonData"] [@default None];
    api_request_context_fetch_args_form_data: name_value list option [@key "formData"] [@default None];
    api_request_context_fetch_args_multipart_data: form_field list option [@key "multipartData"] [@default None];
    api_request_context_fetch_args_timeout: float [@key "timeout"];
    api_request_context_fetch_args_fail_on_status_code: bool option [@key "failOnStatusCode"] [@default None];
    api_request_context_fetch_args_ignore_https_errors: bool option [@key "ignoreHTTPSErrors"] [@default None];
    api_request_context_fetch_args_max_redirects: int option [@key "maxRedirects"] [@default None];
    api_request_context_fetch_args_max_retries: int option [@key "maxRetries"] [@default None];
  } [@@deriving yojson { strict = false }]

type local_utils_har_unzip_args =
  {
    local_utils_har_unzip_args_zip_file: string [@key "zipFile"];
    local_utils_har_unzip_args_har_file: string [@key "harFile"];
  } [@@deriving yojson { strict = false }]

type frame_add_style_tag_args =
  {
    frame_add_style_tag_args_url: string option [@key "url"] [@default None];
    frame_add_style_tag_args_content: string option [@key "content"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_go_forward_returns =
  {
    page_go_forward_returns_response: channel option [@key "response"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_mouse_wheel_args =
  {
    page_mouse_wheel_args_delta_x: float [@key "deltaX"];
    page_mouse_wheel_args_delta_y: float [@key "deltaY"];
  } [@@deriving yojson { strict = false }]

type page_keyboard_type_args =
  {
    page_keyboard_type_args_text: string [@key "text"];
    page_keyboard_type_args_delay: float option [@key "delay"] [@default None];
  } [@@deriving yojson { strict = false }]

type local_utils_har_close_args =
  {
    local_utils_har_close_args_har_id: string [@key "harId"];
  } [@@deriving yojson { strict = false }]

type cdp_session_send_args =
  {
    cdp_session_send_args_method_: string [@key "method"];
    cdp_session_send_args_params: json option [@key "params"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_screenshot_returns =
  {
    page_screenshot_returns_binary: string [@key "binary"];
  } [@@deriving yojson { strict = false }]

type element_handle_get_attribute_args =
  {
    element_handle_get_attribute_args_name: string [@key "name"];
  } [@@deriving yojson { strict = false }]

type js_handle_preview_updated_event =
  {
    js_handle_preview_updated_event_preview: string [@key "preview"];
  } [@@deriving yojson { strict = false }]

type frame_get_attribute_args =
  {
    frame_get_attribute_args_selector: string [@key "selector"];
    frame_get_attribute_args_strict: bool option [@key "strict"] [@default None];
    frame_get_attribute_args_name: string [@key "name"];
    frame_get_attribute_args_timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type browser_context_set_network_interception_patterns_args =
  {
    browser_context_set_network_interception_patterns_args_patterns: browser_context_set_network_interception_patterns_args_patterns_item list [@key "patterns"];
  } [@@deriving yojson { strict = false }]

type browser_type_launch_persistent_context_returns =
  {
    browser_type_launch_persistent_context_returns_browser: channel [@key "browser"];
    browser_type_launch_persistent_context_returns_context: channel [@key "context"];
  } [@@deriving yojson { strict = false }]

type android_device_info_returns =
  {
    android_device_info_returns_info: android_element_info [@key "info"];
  } [@@deriving yojson { strict = false }]

type frame_evaluate_expression_handle_args =
  {
    frame_evaluate_expression_handle_args_expression: string [@key "expression"];
    frame_evaluate_expression_handle_args_is_function: bool option [@key "isFunction"] [@default None];
    frame_evaluate_expression_handle_args_arg: serialized_argument [@key "arg"];
  } [@@deriving yojson { strict = false }]

type metadata =
  {
    metadata_location: metadata_location option [@key "location"] [@default None];
    metadata_title: string option [@key "title"] [@default None];
    metadata_internal: bool option [@key "internal"] [@default None];
    metadata_step_id: string option [@key "stepId"] [@default None];
  } [@@deriving yojson { strict = false }]

