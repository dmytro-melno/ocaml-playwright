[@@@ocaml.warning "-39-32-34-30"]

type channel = { guid: string } [@@deriving yojson { strict = false }]

type any = Yojson.Safe.t [@@deriving yojson]

type json = Yojson.Safe.t [@@deriving yojson]

type serialized_value_r =
  {
    p: string [@key "p"];
    f: string [@key "f"];
  } [@@deriving yojson { strict = false }]

type serialized_value_e =
  {
    m: string [@key "m"];
    n: string [@key "n"];
    s: string [@key "s"];
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
  ]

let serialized_value_ta_k_to_yojson = function
  | `I8 -> `String "i8"
  | `Ui8 -> `String "ui8"
  | `Ui8c -> `String "ui8c"
  | `I16 -> `String "i16"
  | `Ui16 -> `String "ui16"
  | `I32 -> `String "i32"
  | `Ui32 -> `String "ui32"
  | `F32 -> `String "f32"
  | `F64 -> `String "f64"
  | `Bi64 -> `String "bi64"
  | `Bui64 -> `String "bui64"

let serialized_value_ta_k_of_yojson = function
  | `String "i8" -> Ok `I8
  | `String "ui8" -> Ok `Ui8
  | `String "ui8c" -> Ok `Ui8c
  | `String "i16" -> Ok `I16
  | `String "ui16" -> Ok `Ui16
  | `String "i32" -> Ok `I32
  | `String "ui32" -> Ok `Ui32
  | `String "f32" -> Ok `F32
  | `String "f64" -> Ok `F64
  | `String "bi64" -> Ok `Bi64
  | `String "bui64" -> Ok `Bui64
  | _ -> Error "Invalid enum serialized_value_ta_k"

type serialized_value_ta =
  {
    b: string [@key "b"];
    k: serialized_value_ta_k [@key "k"];
  } [@@deriving yojson { strict = false }]

type serialized_value_v =
  [
  | `Null
  | `Undefined
  | `Nan
  | `Inf
  | `Minus_inf
  | `Minus_zero
  ]

let serialized_value_v_to_yojson = function
  | `Null -> `String "null"
  | `Undefined -> `String "undefined"
  | `Nan -> `String "nan"
  | `Inf -> `String "inf"
  | `Minus_inf -> `String "-inf"
  | `Minus_zero -> `String "-0"

let serialized_value_v_of_yojson = function
  | `String "null" -> Ok `Null
  | `String "undefined" -> Ok `Undefined
  | `String "nan" -> Ok `Nan
  | `String "inf" -> Ok `Inf
  | `String "-inf" -> Ok `Minus_inf
  | `String "-0" -> Ok `Minus_zero
  | _ -> Error "Invalid enum serialized_value_v"

type serialized_value =
  {
    n: float option [@key "n"] [@default None];
    b: bool option [@key "b"] [@default None];
    s: string option [@key "s"] [@default None];
    v: serialized_value_v option [@key "v"] [@default None];
    d: string option [@key "d"] [@default None];
    u: string option [@key "u"] [@default None];
    bi: string option [@key "bi"] [@default None];
    ta: serialized_value_ta option [@key "ta"] [@default None];
    e: serialized_value_e option [@key "e"] [@default None];
    r: serialized_value_r option [@key "r"] [@default None];
    a: serialized_value list option [@key "a"] [@default None];
    o: serialized_value_o_item list option [@key "o"] [@default None];
    h: int option [@key "h"] [@default None];
    id: int option [@key "id"] [@default None];
    ref: int option [@key "ref"] [@default None];
  } [@@deriving yojson { strict = false }]

and serialized_value_o_item =
  {
    k: string [@key "k"];
    v: serialized_value [@key "v"];
  } [@@deriving yojson { strict = false }]

type serialized_argument =
  {
    value: serialized_value [@key "value"];
    handles: channel list [@key "handles"];
  } [@@deriving yojson { strict = false }]

type frame_wait_for_function_args =
  {
    expression: string [@key "expression"];
    is_function: bool option [@key "isFunction"] [@default None];
    arg: serialized_argument [@key "arg"];
    timeout: float [@key "timeout"];
    polling_interval: float option [@key "pollingInterval"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_mouse_down_args_button =
  [
  | `Left
  | `Right
  | `Middle
  ]

let page_mouse_down_args_button_to_yojson = function
  | `Left -> `String "left"
  | `Right -> `String "right"
  | `Middle -> `String "middle"

let page_mouse_down_args_button_of_yojson = function
  | `String "left" -> Ok `Left
  | `String "right" -> Ok `Right
  | `String "middle" -> Ok `Middle
  | _ -> Error "Invalid enum page_mouse_down_args_button"

type page_stop_js_coverage_returns_entries_item_functions_item_ranges_item =
  {
    start_offset: int [@key "startOffset"];
    end_offset: int [@key "endOffset"];
    count: int [@key "count"];
  } [@@deriving yojson { strict = false }]

type page_stop_js_coverage_returns_entries_item_functions_item =
  {
    function_name: string [@key "functionName"];
    is_block_coverage: bool [@key "isBlockCoverage"];
    ranges: page_stop_js_coverage_returns_entries_item_functions_item_ranges_item list [@key "ranges"];
  } [@@deriving yojson { strict = false }]

type playwright_new_request_args_http_credentials_send =
  [
  | `Always
  | `Unauthorized
  ]

let playwright_new_request_args_http_credentials_send_to_yojson = function
  | `Always -> `String "always"
  | `Unauthorized -> `String "unauthorized"

let playwright_new_request_args_http_credentials_send_of_yojson = function
  | `String "always" -> Ok `Always
  | `String "unauthorized" -> Ok `Unauthorized
  | _ -> Error "Invalid enum playwright_new_request_args_http_credentials_send"

type playwright_new_request_args_http_credentials =
  {
    username: string [@key "username"];
    password: string [@key "password"];
    origin: string option [@key "origin"] [@default None];
    send: playwright_new_request_args_http_credentials_send option [@key "send"] [@default None];
  } [@@deriving yojson { strict = false }]

type indexed_db_database_stores_item_indexes_item =
  {
    name: string [@key "name"];
    key_path: string option [@key "keyPath"] [@default None];
    key_path_array: string list option [@key "keyPathArray"] [@default None];
    multi_entry: bool [@key "multiEntry"];
    unique: bool [@key "unique"];
  } [@@deriving yojson { strict = false }]

type indexed_db_database_stores_item_records_item =
  {
    key: json option [@key "key"] [@default None];
    key_encoded: json option [@key "keyEncoded"] [@default None];
    value: json option [@key "value"] [@default None];
    value_encoded: json option [@key "valueEncoded"] [@default None];
  } [@@deriving yojson { strict = false }]

type indexed_db_database_stores_item =
  {
    name: string [@key "name"];
    auto_increment: bool [@key "autoIncrement"];
    key_path: string option [@key "keyPath"] [@default None];
    key_path_array: string list option [@key "keyPathArray"] [@default None];
    records: indexed_db_database_stores_item_records_item list [@key "records"];
    indexes: indexed_db_database_stores_item_indexes_item list [@key "indexes"];
  } [@@deriving yojson { strict = false }]

type indexed_db_database =
  {
    name: string [@key "name"];
    version: int [@key "version"];
    stores: indexed_db_database_stores_item list [@key "stores"];
  } [@@deriving yojson { strict = false }]

type name_value =
  {
    name: string [@key "name"];
    value: string [@key "value"];
  } [@@deriving yojson { strict = false }]

type set_origin_storage =
  {
    origin: string [@key "origin"];
    local_storage: name_value list [@key "localStorage"];
    indexed_db: indexed_db_database list option [@key "indexedDB"] [@default None];
  } [@@deriving yojson { strict = false }]

type set_network_cookie_same_site =
  [
  | `Strict
  | `Lax
  | `None
  ]

let set_network_cookie_same_site_to_yojson = function
  | `Strict -> `String "Strict"
  | `Lax -> `String "Lax"
  | `None -> `String "None"

let set_network_cookie_same_site_of_yojson = function
  | `String "Strict" -> Ok `Strict
  | `String "Lax" -> Ok `Lax
  | `String "None" -> Ok `None
  | _ -> Error "Invalid enum set_network_cookie_same_site"

type set_network_cookie =
  {
    name: string [@key "name"];
    value: string [@key "value"];
    url: string option [@key "url"] [@default None];
    domain: string option [@key "domain"] [@default None];
    path: string option [@key "path"] [@default None];
    expires: float option [@key "expires"] [@default None];
    http_only: bool option [@key "httpOnly"] [@default None];
    secure: bool option [@key "secure"] [@default None];
    same_site: set_network_cookie_same_site option [@key "sameSite"] [@default None];
    partition_key: string option [@key "partitionKey"] [@default None];
    cr_has_cross_site_ancestor: bool option [@key "_crHasCrossSiteAncestor"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_set_storage_state_args_storage_state =
  {
    cookies: set_network_cookie list option [@key "cookies"] [@default None];
    origins: set_origin_storage list option [@key "origins"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_set_storage_state_args =
  {
    storage_state: browser_context_set_storage_state_args_storage_state option [@key "storageState"] [@default None];
  } [@@deriving yojson { strict = false }]

type tracing_tracing_stop_chunk_args_mode =
  [
  | `Archive
  | `Discard
  | `Entries
  ]

let tracing_tracing_stop_chunk_args_mode_to_yojson = function
  | `Archive -> `String "archive"
  | `Discard -> `String "discard"
  | `Entries -> `String "entries"

let tracing_tracing_stop_chunk_args_mode_of_yojson = function
  | `String "archive" -> Ok `Archive
  | `String "discard" -> Ok `Discard
  | `String "entries" -> Ok `Entries
  | _ -> Error "Invalid enum tracing_tracing_stop_chunk_args_mode"

type tracing_tracing_stop_chunk_args =
  {
    mode: tracing_tracing_stop_chunk_args_mode [@key "mode"];
  } [@@deriving yojson { strict = false }]

type page_resolve_locator_handler_no_reply_args =
  {
    uid: int [@key "uid"];
    remove: bool option [@key "remove"] [@default None];
  } [@@deriving yojson { strict = false }]

type context_options_reduced_motion =
  [
  | `Reduce
  | `No_preference
  | `No_override
  ]

let context_options_reduced_motion_to_yojson = function
  | `Reduce -> `String "reduce"
  | `No_preference -> `String "no-preference"
  | `No_override -> `String "no-override"

let context_options_reduced_motion_of_yojson = function
  | `String "reduce" -> Ok `Reduce
  | `String "no-preference" -> Ok `No_preference
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum context_options_reduced_motion"

type common_screenshot_options_caret =
  [
  | `Hide
  | `Initial
  ]

let common_screenshot_options_caret_to_yojson = function
  | `Hide -> `String "hide"
  | `Initial -> `String "initial"

let common_screenshot_options_caret_of_yojson = function
  | `String "hide" -> Ok `Hide
  | `String "initial" -> Ok `Initial
  | _ -> Error "Invalid enum common_screenshot_options_caret"

type lifecycle_event =
  [
  | `Load
  | `Domcontentloaded
  | `Networkidle
  | `Commit
  ]

let lifecycle_event_to_yojson = function
  | `Load -> `String "load"
  | `Domcontentloaded -> `String "domcontentloaded"
  | `Networkidle -> `String "networkidle"
  | `Commit -> `String "commit"

let lifecycle_event_of_yojson = function
  | `String "load" -> Ok `Load
  | `String "domcontentloaded" -> Ok `Domcontentloaded
  | `String "networkidle" -> Ok `Networkidle
  | `String "commit" -> Ok `Commit
  | _ -> Error "Invalid enum lifecycle_event"

type page_go_forward_args =
  {
    timeout: float [@key "timeout"];
    wait_until: lifecycle_event option [@key "waitUntil"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_type_launch_persistent_context_args_reduced_motion =
  [
  | `Reduce
  | `No_preference
  | `No_override
  ]

let browser_type_launch_persistent_context_args_reduced_motion_to_yojson = function
  | `Reduce -> `String "reduce"
  | `No_preference -> `String "no-preference"
  | `No_override -> `String "no-override"

let browser_type_launch_persistent_context_args_reduced_motion_of_yojson = function
  | `String "reduce" -> Ok `Reduce
  | `String "no-preference" -> Ok `No_preference
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum browser_type_launch_persistent_context_args_reduced_motion"

type context_options_geolocation =
  {
    longitude: float [@key "longitude"];
    latitude: float [@key "latitude"];
    accuracy: float option [@key "accuracy"] [@default None];
  } [@@deriving yojson { strict = false }]

type socks_support_socks_failed_args =
  {
    uid: string [@key "uid"];
    error_code: string [@key "errorCode"];
  } [@@deriving yojson { strict = false }]

type page_keyboard_up_args =
  {
    key: string [@key "key"];
  } [@@deriving yojson { strict = false }]

type browser_new_context_args_storage_state =
  {
    cookies: set_network_cookie list option [@key "cookies"] [@default None];
    origins: set_origin_storage list option [@key "origins"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_is_hidden_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
  } [@@deriving yojson { strict = false }]

type json_pipe_send_args =
  {
    message: json [@key "message"];
  } [@@deriving yojson { strict = false }]

type browser_context_set_test_id_attribute_name_args =
  {
    test_id_attribute_name: string [@key "testIdAttributeName"];
  } [@@deriving yojson { strict = false }]

type serialized_error_error =
  {
    message: string [@key "message"];
    name: string [@key "name"];
    stack: string option [@key "stack"] [@default None];
  } [@@deriving yojson { strict = false }]

type serialized_error =
  {
    error: serialized_error_error option [@key "error"] [@default None];
    value: serialized_value option [@key "value"] [@default None];
  } [@@deriving yojson { strict = false }]

type binding_call_reject_args =
  {
    error: serialized_error [@key "error"];
  } [@@deriving yojson { strict = false }]

type page_mouse_up_args_button =
  [
  | `Left
  | `Right
  | `Middle
  ]

let page_mouse_up_args_button_to_yojson = function
  | `Left -> `String "left"
  | `Right -> `String "right"
  | `Middle -> `String "middle"

let page_mouse_up_args_button_of_yojson = function
  | `String "left" -> Ok `Left
  | `String "right" -> Ok `Right
  | `String "middle" -> Ok `Middle
  | _ -> Error "Invalid enum page_mouse_up_args_button"

type page_mouse_up_args =
  {
    button: page_mouse_up_args_button option [@key "button"] [@default None];
    click_count: int option [@key "clickCount"] [@default None];
  } [@@deriving yojson { strict = false }]

type local_utils_har_lookup_returns_action =
  [
  | `Error
  | `Redirect
  | `Fulfill
  | `Noentry
  ]

let local_utils_har_lookup_returns_action_to_yojson = function
  | `Error -> `String "error"
  | `Redirect -> `String "redirect"
  | `Fulfill -> `String "fulfill"
  | `Noentry -> `String "noentry"

let local_utils_har_lookup_returns_action_of_yojson = function
  | `String "error" -> Ok `Error
  | `String "redirect" -> Ok `Redirect
  | `String "fulfill" -> Ok `Fulfill
  | `String "noentry" -> Ok `Noentry
  | _ -> Error "Invalid enum local_utils_har_lookup_returns_action"

type local_utils_har_lookup_returns =
  {
    action: local_utils_har_lookup_returns_action [@key "action"];
    message: string option [@key "message"] [@default None];
    redirect_url: string option [@key "redirectURL"] [@default None];
    status: int option [@key "status"] [@default None];
    headers: name_value list option [@key "headers"] [@default None];
    body: string option [@key "body"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_new_context_for_reuse_args_record_video_show_actions_position =
  [
  | `Top_left
  | `Top
  | `Top_right
  | `Bottom_left
  | `Bottom
  | `Bottom_right
  ]

let browser_new_context_for_reuse_args_record_video_show_actions_position_to_yojson = function
  | `Top_left -> `String "top-left"
  | `Top -> `String "top"
  | `Top_right -> `String "top-right"
  | `Bottom_left -> `String "bottom-left"
  | `Bottom -> `String "bottom"
  | `Bottom_right -> `String "bottom-right"

let browser_new_context_for_reuse_args_record_video_show_actions_position_of_yojson = function
  | `String "top-left" -> Ok `Top_left
  | `String "top" -> Ok `Top
  | `String "top-right" -> Ok `Top_right
  | `String "bottom-left" -> Ok `Bottom_left
  | `String "bottom" -> Ok `Bottom
  | `String "bottom-right" -> Ok `Bottom_right
  | _ -> Error "Invalid enum browser_new_context_for_reuse_args_record_video_show_actions_position"

type frame_aria_snapshot_returns =
  {
    snapshot: string [@key "snapshot"];
  } [@@deriving yojson { strict = false }]

type browser_type_launch_persistent_context_args_record_video_show_actions_position =
  [
  | `Top_left
  | `Top
  | `Top_right
  | `Bottom_left
  | `Bottom
  | `Bottom_right
  ]

let browser_type_launch_persistent_context_args_record_video_show_actions_position_to_yojson = function
  | `Top_left -> `String "top-left"
  | `Top -> `String "top"
  | `Top_right -> `String "top-right"
  | `Bottom_left -> `String "bottom-left"
  | `Bottom -> `String "bottom"
  | `Bottom_right -> `String "bottom-right"

let browser_type_launch_persistent_context_args_record_video_show_actions_position_of_yojson = function
  | `String "top-left" -> Ok `Top_left
  | `String "top" -> Ok `Top
  | `String "top-right" -> Ok `Top_right
  | `String "bottom-left" -> Ok `Bottom_left
  | `String "bottom" -> Ok `Bottom
  | `String "bottom-right" -> Ok `Bottom_right
  | _ -> Error "Invalid enum browser_type_launch_persistent_context_args_record_video_show_actions_position"

type browser_context_storage_state_args =
  {
    indexed_db: bool option [@key "indexedDB"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_wait_for_selector_args_state =
  [
  | `Attached
  | `Detached
  | `Visible
  | `Hidden
  ]

let frame_wait_for_selector_args_state_to_yojson = function
  | `Attached -> `String "attached"
  | `Detached -> `String "detached"
  | `Visible -> `String "visible"
  | `Hidden -> `String "hidden"

let frame_wait_for_selector_args_state_of_yojson = function
  | `String "attached" -> Ok `Attached
  | `String "detached" -> Ok `Detached
  | `String "visible" -> Ok `Visible
  | `String "hidden" -> Ok `Hidden
  | _ -> Error "Invalid enum frame_wait_for_selector_args_state"

type frame_wait_for_selector_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
    timeout: float [@key "timeout"];
    state: frame_wait_for_selector_args_state option [@key "state"] [@default None];
    omit_return_value: bool option [@key "omitReturnValue"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_screencast_chapter_args =
  {
    title: string [@key "title"];
    description: string option [@key "description"] [@default None];
    duration: float option [@key "duration"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_select_option_returns =
  {
    values: string list [@key "values"];
  } [@@deriving yojson { strict = false }]

type socks_support_socks_data_event =
  {
    uid: string [@key "uid"];
    data: string [@key "data"];
  } [@@deriving yojson { strict = false }]

type browser_new_context_for_reuse_args_service_workers =
  [
  | `Allow
  | `Block
  ]

let browser_new_context_for_reuse_args_service_workers_to_yojson = function
  | `Allow -> `String "allow"
  | `Block -> `String "block"

let browser_new_context_for_reuse_args_service_workers_of_yojson = function
  | `String "allow" -> Ok `Allow
  | `String "block" -> Ok `Block
  | _ -> Error "Invalid enum browser_new_context_for_reuse_args_service_workers"

type artifact_path_after_finished_returns =
  {
    value: string [@key "value"];
  } [@@deriving yojson { strict = false }]

type binding_call_initializer =
  {
    frame: channel [@key "frame"];
    name: string [@key "name"];
    args: serialized_value list [@key "args"];
  } [@@deriving yojson { strict = false }]

type web_socket_route_close_page_args =
  {
    code: int option [@key "code"] [@default None];
    reason: string option [@key "reason"] [@default None];
    was_clean: bool [@key "wasClean"];
  } [@@deriving yojson { strict = false }]

type browser_new_context_args_client_certificates_item =
  {
    origin: string [@key "origin"];
    cert: string option [@key "cert"] [@default None];
    key: string option [@key "key"] [@default None];
    passphrase: string option [@key "passphrase"] [@default None];
    pfx: string option [@key "pfx"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_device_launch_browser_args_contrast =
  [
  | `No_preference
  | `More
  | `No_override
  ]

let android_device_launch_browser_args_contrast_to_yojson = function
  | `No_preference -> `String "no-preference"
  | `More -> `String "more"
  | `No_override -> `String "no-override"

let android_device_launch_browser_args_contrast_of_yojson = function
  | `String "no-preference" -> Ok `No_preference
  | `String "more" -> Ok `More
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum android_device_launch_browser_args_contrast"

type element_handle_dblclick_args_button =
  [
  | `Left
  | `Right
  | `Middle
  ]

let element_handle_dblclick_args_button_to_yojson = function
  | `Left -> `String "left"
  | `Right -> `String "right"
  | `Middle -> `String "middle"

let element_handle_dblclick_args_button_of_yojson = function
  | `String "left" -> Ok `Left
  | `String "right" -> Ok `Right
  | `String "middle" -> Ok `Middle
  | _ -> Error "Invalid enum element_handle_dblclick_args_button"

type point =
  {
    x: float [@key "x"];
    y: float [@key "y"];
  } [@@deriving yojson { strict = false }]

type element_handle_dblclick_args_modifiers_item =
  [
  | `Alt
  | `Control
  | `Control_or_meta
  | `Meta
  | `Shift
  ]

let element_handle_dblclick_args_modifiers_item_to_yojson = function
  | `Alt -> `String "Alt"
  | `Control -> `String "Control"
  | `Control_or_meta -> `String "ControlOrMeta"
  | `Meta -> `String "Meta"
  | `Shift -> `String "Shift"

let element_handle_dblclick_args_modifiers_item_of_yojson = function
  | `String "Alt" -> Ok `Alt
  | `String "Control" -> Ok `Control
  | `String "ControlOrMeta" -> Ok `Control_or_meta
  | `String "Meta" -> Ok `Meta
  | `String "Shift" -> Ok `Shift
  | _ -> Error "Invalid enum element_handle_dblclick_args_modifiers_item"

type element_handle_dblclick_args =
  {
    force: bool option [@key "force"] [@default None];
    modifiers: element_handle_dblclick_args_modifiers_item list option [@key "modifiers"] [@default None];
    position: point option [@key "position"] [@default None];
    delay: float option [@key "delay"] [@default None];
    button: element_handle_dblclick_args_button option [@key "button"] [@default None];
    timeout: float [@key "timeout"];
    trial: bool option [@key "trial"] [@default None];
    steps: int option [@key "steps"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_device_swipe_args_direction =
  [
  | `Up
  | `Down
  | `Left
  | `Right
  ]

let android_device_swipe_args_direction_to_yojson = function
  | `Up -> `String "up"
  | `Down -> `String "down"
  | `Left -> `String "left"
  | `Right -> `String "right"

let android_device_swipe_args_direction_of_yojson = function
  | `String "up" -> Ok `Up
  | `String "down" -> Ok `Down
  | `String "left" -> Ok `Left
  | `String "right" -> Ok `Right
  | _ -> Error "Invalid enum android_device_swipe_args_direction"

type android_selector =
  {
    checkable: bool option [@key "checkable"] [@default None];
    checked: bool option [@key "checked"] [@default None];
    clazz: string option [@key "clazz"] [@default None];
    clickable: bool option [@key "clickable"] [@default None];
    depth: int option [@key "depth"] [@default None];
    desc: string option [@key "desc"] [@default None];
    enabled: bool option [@key "enabled"] [@default None];
    focusable: bool option [@key "focusable"] [@default None];
    focused: bool option [@key "focused"] [@default None];
    has_child: android_selector_has_child option [@key "hasChild"] [@default None];
    has_descendant: android_selector_has_descendant option [@key "hasDescendant"] [@default None];
    long_clickable: bool option [@key "longClickable"] [@default None];
    pkg: string option [@key "pkg"] [@default None];
    res: string option [@key "res"] [@default None];
    scrollable: bool option [@key "scrollable"] [@default None];
    selected: bool option [@key "selected"] [@default None];
    text: string option [@key "text"] [@default None];
  } [@@deriving yojson { strict = false }]

and android_selector_has_descendant =
  {
    android_selector: android_selector [@key "androidSelector"];
    max_depth: int option [@key "maxDepth"] [@default None];
  } [@@deriving yojson { strict = false }]

and android_selector_has_child =
  {
    android_selector: android_selector [@key "androidSelector"];
  } [@@deriving yojson { strict = false }]

type android_device_swipe_args =
  {
    android_selector: android_selector [@key "androidSelector"];
    direction: android_device_swipe_args_direction [@key "direction"];
    percent: float [@key "percent"];
    speed: float option [@key "speed"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type page_initializer_viewport_size =
  {
    width: int [@key "width"];
    height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type frame_drag_and_drop_args =
  {
    source: string [@key "source"];
    target: string [@key "target"];
    force: bool option [@key "force"] [@default None];
    timeout: float [@key "timeout"];
    trial: bool option [@key "trial"] [@default None];
    source_position: point option [@key "sourcePosition"] [@default None];
    target_position: point option [@key "targetPosition"] [@default None];
    strict: bool option [@key "strict"] [@default None];
    steps: int option [@key "steps"] [@default None];
  } [@@deriving yojson { strict = false }]

type context_options_color_scheme =
  [
  | `Dark
  | `Light
  | `No_preference
  | `No_override
  ]

let context_options_color_scheme_to_yojson = function
  | `Dark -> `String "dark"
  | `Light -> `String "light"
  | `No_preference -> `String "no-preference"
  | `No_override -> `String "no-override"

let context_options_color_scheme_of_yojson = function
  | `String "dark" -> Ok `Dark
  | `String "light" -> Ok `Light
  | `String "no-preference" -> Ok `No_preference
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum context_options_color_scheme"

type context_options_client_certificates_item =
  {
    origin: string [@key "origin"];
    cert: string option [@key "cert"] [@default None];
    key: string option [@key "key"] [@default None];
    passphrase: string option [@key "passphrase"] [@default None];
    pfx: string option [@key "pfx"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_reload_args =
  {
    timeout: float [@key "timeout"];
    wait_until: lifecycle_event option [@key "waitUntil"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_set_dock_tile_args =
  {
    image: string [@key "image"];
  } [@@deriving yojson { strict = false }]

type page_worker_event =
  {
    worker: channel [@key "worker"];
  } [@@deriving yojson { strict = false }]

type browser_context_set_geolocation_args_geolocation =
  {
    longitude: float [@key "longitude"];
    latitude: float [@key "latitude"];
    accuracy: float option [@key "accuracy"] [@default None];
  } [@@deriving yojson { strict = false }]

type local_utils_initializer_device_descriptors_item_descriptor_default_browser_type =
  [
  | `Chromium
  | `Firefox
  | `Webkit
  ]

let local_utils_initializer_device_descriptors_item_descriptor_default_browser_type_to_yojson = function
  | `Chromium -> `String "chromium"
  | `Firefox -> `String "firefox"
  | `Webkit -> `String "webkit"

let local_utils_initializer_device_descriptors_item_descriptor_default_browser_type_of_yojson = function
  | `String "chromium" -> Ok `Chromium
  | `String "firefox" -> Ok `Firefox
  | `String "webkit" -> Ok `Webkit
  | _ -> Error "Invalid enum local_utils_initializer_device_descriptors_item_descriptor_default_browser_type"

type local_utils_initializer_device_descriptors_item_descriptor_screen =
  {
    width: int [@key "width"];
    height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type local_utils_initializer_device_descriptors_item_descriptor_viewport =
  {
    width: int [@key "width"];
    height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type local_utils_initializer_device_descriptors_item_descriptor =
  {
    user_agent: string [@key "userAgent"];
    viewport: local_utils_initializer_device_descriptors_item_descriptor_viewport [@key "viewport"];
    screen: local_utils_initializer_device_descriptors_item_descriptor_screen option [@key "screen"] [@default None];
    device_scale_factor: float [@key "deviceScaleFactor"];
    is_mobile: bool [@key "isMobile"];
    has_touch: bool [@key "hasTouch"];
    default_browser_type: local_utils_initializer_device_descriptors_item_descriptor_default_browser_type [@key "defaultBrowserType"];
  } [@@deriving yojson { strict = false }]

type local_utils_initializer_device_descriptors_item =
  {
    name: string [@key "name"];
    descriptor: local_utils_initializer_device_descriptors_item_descriptor [@key "descriptor"];
  } [@@deriving yojson { strict = false }]

type page_close_args =
  {
    run_before_unload: bool option [@key "runBeforeUnload"] [@default None];
    reason: string option [@key "reason"] [@default None];
  } [@@deriving yojson { strict = false }]

type local_utils_har_open_args =
  {
    file: string [@key "file"];
  } [@@deriving yojson { strict = false }]

type tracing_tracing_start_args =
  {
    name: string option [@key "name"] [@default None];
    snapshots: bool option [@key "snapshots"] [@default None];
    screenshots: bool option [@key "screenshots"] [@default None];
    live: bool option [@key "live"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_screencast_show_overlay_args =
  {
    html: string [@key "html"];
    duration: float option [@key "duration"] [@default None];
  } [@@deriving yojson { strict = false }]

type remote_addr =
  {
    ip_address: string [@key "ipAddress"];
    port: int [@key "port"];
  } [@@deriving yojson { strict = false }]

type response_server_addr_returns =
  {
    value: remote_addr option [@key "value"] [@default None];
  } [@@deriving yojson { strict = false }]

type api_request_context_fetch_log_args =
  {
    fetch_uid: string [@key "fetchUid"];
  } [@@deriving yojson { strict = false }]

type android_socket_write_args =
  {
    data: string [@key "data"];
  } [@@deriving yojson { strict = false }]

type web_socket_route_close_server_args =
  {
    code: int option [@key "code"] [@default None];
    reason: string option [@key "reason"] [@default None];
    was_clean: bool [@key "wasClean"];
  } [@@deriving yojson { strict = false }]

type element_handle_set_input_files_args_payloads_item =
  {
    name: string [@key "name"];
    mime_type: string option [@key "mimeType"] [@default None];
    buffer: string [@key "buffer"];
  } [@@deriving yojson { strict = false }]

type element_handle_inner_htm_l_returns =
  {
    value: string [@key "value"];
  } [@@deriving yojson { strict = false }]

type local_utils_trace_discarded_args =
  {
    stacks_id: string [@key "stacksId"];
  } [@@deriving yojson { strict = false }]

type element_handle_eval_on_selector_all_returns =
  {
    value: serialized_value [@key "value"];
  } [@@deriving yojson { strict = false }]

type selector_engine =
  {
    name: string [@key "name"];
    source: string [@key "source"];
    content_script: bool option [@key "contentScript"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_type_launch_persistent_context_args_service_workers =
  [
  | `Allow
  | `Block
  ]

let browser_type_launch_persistent_context_args_service_workers_to_yojson = function
  | `Allow -> `String "allow"
  | `Block -> `String "block"

let browser_type_launch_persistent_context_args_service_workers_of_yojson = function
  | `String "allow" -> Ok `Allow
  | `String "block" -> Ok `Block
  | _ -> Error "Invalid enum browser_type_launch_persistent_context_args_service_workers"

type browser_type_launch_persistent_context_args_record_video_show_actions =
  {
    duration: float option [@key "duration"] [@default None];
    position: browser_type_launch_persistent_context_args_record_video_show_actions_position option [@key "position"] [@default None];
    font_size: int option [@key "fontSize"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_type_launch_persistent_context_args_record_video_size =
  {
    width: int [@key "width"];
    height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type browser_type_launch_persistent_context_args_record_video =
  {
    dir: string option [@key "dir"] [@default None];
    size: browser_type_launch_persistent_context_args_record_video_size option [@key "size"] [@default None];
    show_actions: browser_type_launch_persistent_context_args_record_video_show_actions option [@key "showActions"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_type_launch_persistent_context_args_contrast =
  [
  | `No_preference
  | `More
  | `No_override
  ]

let browser_type_launch_persistent_context_args_contrast_to_yojson = function
  | `No_preference -> `String "no-preference"
  | `More -> `String "more"
  | `No_override -> `String "no-override"

let browser_type_launch_persistent_context_args_contrast_of_yojson = function
  | `String "no-preference" -> Ok `No_preference
  | `String "more" -> Ok `More
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum browser_type_launch_persistent_context_args_contrast"

type browser_type_launch_persistent_context_args_accept_downloads =
  [
  | `Accept
  | `Deny
  | `Internal_browser_default
  ]

let browser_type_launch_persistent_context_args_accept_downloads_to_yojson = function
  | `Accept -> `String "accept"
  | `Deny -> `String "deny"
  | `Internal_browser_default -> `String "internal-browser-default"

let browser_type_launch_persistent_context_args_accept_downloads_of_yojson = function
  | `String "accept" -> Ok `Accept
  | `String "deny" -> Ok `Deny
  | `String "internal-browser-default" -> Ok `Internal_browser_default
  | _ -> Error "Invalid enum browser_type_launch_persistent_context_args_accept_downloads"

type browser_type_launch_persistent_context_args_forced_colors =
  [
  | `Active
  | `None
  | `No_override
  ]

let browser_type_launch_persistent_context_args_forced_colors_to_yojson = function
  | `Active -> `String "active"
  | `None -> `String "none"
  | `No_override -> `String "no-override"

let browser_type_launch_persistent_context_args_forced_colors_of_yojson = function
  | `String "active" -> Ok `Active
  | `String "none" -> Ok `None
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum browser_type_launch_persistent_context_args_forced_colors"

type browser_type_launch_persistent_context_args_color_scheme =
  [
  | `Dark
  | `Light
  | `No_preference
  | `No_override
  ]

let browser_type_launch_persistent_context_args_color_scheme_to_yojson = function
  | `Dark -> `String "dark"
  | `Light -> `String "light"
  | `No_preference -> `String "no-preference"
  | `No_override -> `String "no-override"

let browser_type_launch_persistent_context_args_color_scheme_of_yojson = function
  | `String "dark" -> Ok `Dark
  | `String "light" -> Ok `Light
  | `String "no-preference" -> Ok `No_preference
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum browser_type_launch_persistent_context_args_color_scheme"

type browser_type_launch_persistent_context_args_http_credentials_send =
  [
  | `Always
  | `Unauthorized
  ]

let browser_type_launch_persistent_context_args_http_credentials_send_to_yojson = function
  | `Always -> `String "always"
  | `Unauthorized -> `String "unauthorized"

let browser_type_launch_persistent_context_args_http_credentials_send_of_yojson = function
  | `String "always" -> Ok `Always
  | `String "unauthorized" -> Ok `Unauthorized
  | _ -> Error "Invalid enum browser_type_launch_persistent_context_args_http_credentials_send"

type browser_type_launch_persistent_context_args_http_credentials =
  {
    username: string [@key "username"];
    password: string [@key "password"];
    origin: string option [@key "origin"] [@default None];
    send: browser_type_launch_persistent_context_args_http_credentials_send option [@key "send"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_type_launch_persistent_context_args_geolocation =
  {
    longitude: float [@key "longitude"];
    latitude: float [@key "latitude"];
    accuracy: float option [@key "accuracy"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_type_launch_persistent_context_args_client_certificates_item =
  {
    origin: string [@key "origin"];
    cert: string option [@key "cert"] [@default None];
    key: string option [@key "key"] [@default None];
    passphrase: string option [@key "passphrase"] [@default None];
    pfx: string option [@key "pfx"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_type_launch_persistent_context_args_screen =
  {
    width: int [@key "width"];
    height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type browser_type_launch_persistent_context_args_viewport =
  {
    width: int [@key "width"];
    height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type browser_type_launch_persistent_context_args_proxy =
  {
    server: string [@key "server"];
    bypass: string option [@key "bypass"] [@default None];
    username: string option [@key "username"] [@default None];
    password: string option [@key "password"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_type_launch_persistent_context_args =
  {
    channel: string option [@key "channel"] [@default None];
    executable_path: string option [@key "executablePath"] [@default None];
    args: string list option [@key "args"] [@default None];
    ignore_all_default_args: bool option [@key "ignoreAllDefaultArgs"] [@default None];
    ignore_default_args: string list option [@key "ignoreDefaultArgs"] [@default None];
    handle_sigint: bool option [@key "handleSIGINT"] [@default None];
    handle_sigterm: bool option [@key "handleSIGTERM"] [@default None];
    handle_sighup: bool option [@key "handleSIGHUP"] [@default None];
    timeout: float [@key "timeout"];
    env: name_value list option [@key "env"] [@default None];
    headless: bool option [@key "headless"] [@default None];
    proxy: browser_type_launch_persistent_context_args_proxy option [@key "proxy"] [@default None];
    downloads_path: string option [@key "downloadsPath"] [@default None];
    traces_dir: string option [@key "tracesDir"] [@default None];
    artifacts_dir: string option [@key "artifactsDir"] [@default None];
    chromium_sandbox: bool option [@key "chromiumSandbox"] [@default None];
    firefox_user_prefs: json option [@key "firefoxUserPrefs"] [@default None];
    cdp_port: int option [@key "cdpPort"] [@default None];
    no_default_viewport: bool option [@key "noDefaultViewport"] [@default None];
    viewport: browser_type_launch_persistent_context_args_viewport option [@key "viewport"] [@default None];
    screen: browser_type_launch_persistent_context_args_screen option [@key "screen"] [@default None];
    ignore_https_errors: bool option [@key "ignoreHTTPSErrors"] [@default None];
    client_certificates: browser_type_launch_persistent_context_args_client_certificates_item list option [@key "clientCertificates"] [@default None];
    java_script_enabled: bool option [@key "javaScriptEnabled"] [@default None];
    bypass_csp: bool option [@key "bypassCSP"] [@default None];
    user_agent: string option [@key "userAgent"] [@default None];
    locale: string option [@key "locale"] [@default None];
    timezone_id: string option [@key "timezoneId"] [@default None];
    geolocation: browser_type_launch_persistent_context_args_geolocation option [@key "geolocation"] [@default None];
    permissions: string list option [@key "permissions"] [@default None];
    extra_http_headers: name_value list option [@key "extraHTTPHeaders"] [@default None];
    offline: bool option [@key "offline"] [@default None];
    http_credentials: browser_type_launch_persistent_context_args_http_credentials option [@key "httpCredentials"] [@default None];
    device_scale_factor: float option [@key "deviceScaleFactor"] [@default None];
    is_mobile: bool option [@key "isMobile"] [@default None];
    has_touch: bool option [@key "hasTouch"] [@default None];
    color_scheme: browser_type_launch_persistent_context_args_color_scheme option [@key "colorScheme"] [@default None];
    reduced_motion: browser_type_launch_persistent_context_args_reduced_motion option [@key "reducedMotion"] [@default None];
    forced_colors: browser_type_launch_persistent_context_args_forced_colors option [@key "forcedColors"] [@default None];
    accept_downloads: browser_type_launch_persistent_context_args_accept_downloads option [@key "acceptDownloads"] [@default None];
    contrast: browser_type_launch_persistent_context_args_contrast option [@key "contrast"] [@default None];
    base_url: string option [@key "baseURL"] [@default None];
    record_video: browser_type_launch_persistent_context_args_record_video option [@key "recordVideo"] [@default None];
    strict_selectors: bool option [@key "strictSelectors"] [@default None];
    service_workers: browser_type_launch_persistent_context_args_service_workers option [@key "serviceWorkers"] [@default None];
    selector_engines: selector_engine list option [@key "selectorEngines"] [@default None];
    test_id_attribute_name: string option [@key "testIdAttributeName"] [@default None];
    user_data_dir: string [@key "userDataDir"];
    slow_mo: float option [@key "slowMo"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_expect_args_pseudo =
  [
  | `Before
  | `After
  ]

let frame_expect_args_pseudo_to_yojson = function
  | `Before -> `String "before"
  | `After -> `String "after"

let frame_expect_args_pseudo_of_yojson = function
  | `String "before" -> Ok `Before
  | `String "after" -> Ok `After
  | _ -> Error "Invalid enum frame_expect_args_pseudo"

type frame_uncheck_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
    force: bool option [@key "force"] [@default None];
    position: point option [@key "position"] [@default None];
    timeout: float [@key "timeout"];
    trial: bool option [@key "trial"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_device_wait_args_state =
  [
  | `Gone
  ]

let android_device_wait_args_state_to_yojson = function
  | `Gone -> `String "gone"

let android_device_wait_args_state_of_yojson = function
  | `String "gone" -> Ok `Gone
  | _ -> Error "Invalid enum android_device_wait_args_state"

type android_device_wait_args =
  {
    android_selector: android_selector [@key "androidSelector"];
    state: android_device_wait_args_state option [@key "state"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type stack_frame =
  {
    file: string [@key "file"];
    line: int [@key "line"];
    column: int [@key "column"];
    function_: string option [@key "function"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_device_screenshot_returns =
  {
    binary: string [@key "binary"];
  } [@@deriving yojson { strict = false }]

type element_handle_wait_for_element_state_args_state =
  [
  | `Visible
  | `Hidden
  | `Stable
  | `Enabled
  | `Disabled
  | `Editable
  ]

let element_handle_wait_for_element_state_args_state_to_yojson = function
  | `Visible -> `String "visible"
  | `Hidden -> `String "hidden"
  | `Stable -> `String "stable"
  | `Enabled -> `String "enabled"
  | `Disabled -> `String "disabled"
  | `Editable -> `String "editable"

let element_handle_wait_for_element_state_args_state_of_yojson = function
  | `String "visible" -> Ok `Visible
  | `String "hidden" -> Ok `Hidden
  | `String "stable" -> Ok `Stable
  | `String "enabled" -> Ok `Enabled
  | `String "disabled" -> Ok `Disabled
  | `String "editable" -> Ok `Editable
  | _ -> Error "Invalid enum element_handle_wait_for_element_state_args_state"

type browser_context_initializer_options_service_workers =
  [
  | `Allow
  | `Block
  ]

let browser_context_initializer_options_service_workers_to_yojson = function
  | `Allow -> `String "allow"
  | `Block -> `String "block"

let browser_context_initializer_options_service_workers_of_yojson = function
  | `String "allow" -> Ok `Allow
  | `String "block" -> Ok `Block
  | _ -> Error "Invalid enum browser_context_initializer_options_service_workers"

type tracing_tracing_start_chunk_returns =
  {
    trace_name: string [@key "traceName"];
  } [@@deriving yojson { strict = false }]

type context_options_forced_colors =
  [
  | `Active
  | `None
  | `No_override
  ]

let context_options_forced_colors_to_yojson = function
  | `Active -> `String "active"
  | `None -> `String "none"
  | `No_override -> `String "no-override"

let context_options_forced_colors_of_yojson = function
  | `String "active" -> Ok `Active
  | `String "none" -> Ok `None
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum context_options_forced_colors"

type page_pdf_args_margin =
  {
    top: string option [@key "top"] [@default None];
    bottom: string option [@key "bottom"] [@default None];
    left: string option [@key "left"] [@default None];
    right: string option [@key "right"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_pdf_args =
  {
    scale: float option [@key "scale"] [@default None];
    display_header_footer: bool option [@key "displayHeaderFooter"] [@default None];
    header_template: string option [@key "headerTemplate"] [@default None];
    footer_template: string option [@key "footerTemplate"] [@default None];
    print_background: bool option [@key "printBackground"] [@default None];
    landscape: bool option [@key "landscape"] [@default None];
    page_ranges: string option [@key "pageRanges"] [@default None];
    format: string option [@key "format"] [@default None];
    width: string option [@key "width"] [@default None];
    height: string option [@key "height"] [@default None];
    prefer_css_page_size: bool option [@key "preferCSSPageSize"] [@default None];
    margin: page_pdf_args_margin option [@key "margin"] [@default None];
    tagged: bool option [@key "tagged"] [@default None];
    outline: bool option [@key "outline"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_is_checked_returns =
  {
    value: bool [@key "value"];
  } [@@deriving yojson { strict = false }]

type android_device_web_view_removed_event =
  {
    socket_name: string [@key "socketName"];
  } [@@deriving yojson { strict = false }]

type android_socket_data_event =
  {
    data: string [@key "data"];
  } [@@deriving yojson { strict = false }]

type frame_press_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
    key: string [@key "key"];
    delay: float option [@key "delay"] [@default None];
    no_wait_after: bool option [@key "noWaitAfter"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type android_device_push_args =
  {
    file: string [@key "file"];
    path: string [@key "path"];
    mode: int option [@key "mode"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_is_editable_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type form_field_file =
  {
    name: string [@key "name"];
    mime_type: string option [@key "mimeType"] [@default None];
    buffer: string [@key "buffer"];
  } [@@deriving yojson { strict = false }]

type form_field =
  {
    name: string [@key "name"];
    value: string option [@key "value"] [@default None];
    file: form_field_file option [@key "file"] [@default None];
  } [@@deriving yojson { strict = false }]

type debugger_paused_state_changed_event_paused_details_location =
  {
    file: string [@key "file"];
    line: int option [@key "line"] [@default None];
    column: int option [@key "column"] [@default None];
  } [@@deriving yojson { strict = false }]

type debugger_paused_state_changed_event_paused_details =
  {
    location: debugger_paused_state_changed_event_paused_details_location [@key "location"];
    title: string [@key "title"];
    stack: string option [@key "stack"] [@default None];
  } [@@deriving yojson { strict = false }]

type debugger_paused_state_changed_event =
  {
    paused_details: debugger_paused_state_changed_event_paused_details option [@key "pausedDetails"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_type_launch_returns =
  {
    browser: channel [@key "browser"];
  } [@@deriving yojson { strict = false }]

type resource_timing =
  {
    start_time: float [@key "startTime"];
    domain_lookup_start: float [@key "domainLookupStart"];
    domain_lookup_end: float [@key "domainLookupEnd"];
    connect_start: float [@key "connectStart"];
    secure_connection_start: float [@key "secureConnectionStart"];
    connect_end: float [@key "connectEnd"];
    request_start: float [@key "requestStart"];
    response_start: float [@key "responseStart"];
  } [@@deriving yojson { strict = false }]

type response_initializer =
  {
    request: channel [@key "request"];
    url: string [@key "url"];
    status: int [@key "status"];
    status_text: string [@key "statusText"];
    headers: name_value list [@key "headers"];
    timing: resource_timing [@key "timing"];
    from_service_worker: bool [@key "fromServiceWorker"];
  } [@@deriving yojson { strict = false }]

type page_screencast_start_args_size =
  {
    width: int [@key "width"];
    height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type browser_new_context_args_http_credentials_send =
  [
  | `Always
  | `Unauthorized
  ]

let browser_new_context_args_http_credentials_send_to_yojson = function
  | `Always -> `String "always"
  | `Unauthorized -> `String "unauthorized"

let browser_new_context_args_http_credentials_send_of_yojson = function
  | `String "always" -> Ok `Always
  | `String "unauthorized" -> Ok `Unauthorized
  | _ -> Error "Invalid enum browser_new_context_args_http_credentials_send"

type socks_support_socks_error_args =
  {
    uid: string [@key "uid"];
    error: string [@key "error"];
  } [@@deriving yojson { strict = false }]

type browser_context_console_event_location =
  {
    url: string [@key "url"];
    line_number: int [@key "lineNumber"];
    column_number: int [@key "columnNumber"];
  } [@@deriving yojson { strict = false }]

type frame_hover_args_modifiers_item =
  [
  | `Alt
  | `Control
  | `Control_or_meta
  | `Meta
  | `Shift
  ]

let frame_hover_args_modifiers_item_to_yojson = function
  | `Alt -> `String "Alt"
  | `Control -> `String "Control"
  | `Control_or_meta -> `String "ControlOrMeta"
  | `Meta -> `String "Meta"
  | `Shift -> `String "Shift"

let frame_hover_args_modifiers_item_of_yojson = function
  | `String "Alt" -> Ok `Alt
  | `String "Control" -> Ok `Control
  | `String "ControlOrMeta" -> Ok `Control_or_meta
  | `String "Meta" -> Ok `Meta
  | `String "Shift" -> Ok `Shift
  | _ -> Error "Invalid enum frame_hover_args_modifiers_item"

type page_download_event =
  {
    url: string [@key "url"];
    suggested_filename: string [@key "suggestedFilename"];
    artifact: channel [@key "artifact"];
  } [@@deriving yojson { strict = false }]

type frame_is_disabled_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type frame_add_script_tag_args =
  {
    url: string option [@key "url"] [@default None];
    content: string option [@key "content"] [@default None];
    type_: string option [@key "type"] [@default None];
  } [@@deriving yojson { strict = false }]

type origin_storage =
  {
    origin: string [@key "origin"];
    local_storage: name_value list [@key "localStorage"];
    indexed_db: indexed_db_database list option [@key "indexedDB"] [@default None];
  } [@@deriving yojson { strict = false }]

type network_cookie_same_site =
  [
  | `Strict
  | `Lax
  | `None
  ]

let network_cookie_same_site_to_yojson = function
  | `Strict -> `String "Strict"
  | `Lax -> `String "Lax"
  | `None -> `String "None"

let network_cookie_same_site_of_yojson = function
  | `String "Strict" -> Ok `Strict
  | `String "Lax" -> Ok `Lax
  | `String "None" -> Ok `None
  | _ -> Error "Invalid enum network_cookie_same_site"

type network_cookie =
  {
    name: string [@key "name"];
    value: string [@key "value"];
    domain: string [@key "domain"];
    path: string [@key "path"];
    expires: float [@key "expires"];
    http_only: bool [@key "httpOnly"];
    secure: bool [@key "secure"];
    same_site: network_cookie_same_site [@key "sameSite"];
    partition_key: string option [@key "partitionKey"] [@default None];
    cr_has_cross_site_ancestor: bool option [@key "_crHasCrossSiteAncestor"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_storage_state_returns =
  {
    cookies: network_cookie list [@key "cookies"];
    origins: origin_storage list [@key "origins"];
  } [@@deriving yojson { strict = false }]

type launch_options_proxy =
  {
    server: string [@key "server"];
    bypass: string option [@key "bypass"] [@default None];
    username: string option [@key "username"] [@default None];
    password: string option [@key "password"] [@default None];
  } [@@deriving yojson { strict = false }]

type launch_options =
  {
    channel: string option [@key "channel"] [@default None];
    executable_path: string option [@key "executablePath"] [@default None];
    args: string list option [@key "args"] [@default None];
    ignore_all_default_args: bool option [@key "ignoreAllDefaultArgs"] [@default None];
    ignore_default_args: string list option [@key "ignoreDefaultArgs"] [@default None];
    handle_sigint: bool option [@key "handleSIGINT"] [@default None];
    handle_sigterm: bool option [@key "handleSIGTERM"] [@default None];
    handle_sighup: bool option [@key "handleSIGHUP"] [@default None];
    timeout: float [@key "timeout"];
    env: name_value list option [@key "env"] [@default None];
    headless: bool option [@key "headless"] [@default None];
    proxy: launch_options_proxy option [@key "proxy"] [@default None];
    downloads_path: string option [@key "downloadsPath"] [@default None];
    traces_dir: string option [@key "tracesDir"] [@default None];
    artifacts_dir: string option [@key "artifactsDir"] [@default None];
    chromium_sandbox: bool option [@key "chromiumSandbox"] [@default None];
    firefox_user_prefs: json option [@key "firefoxUserPrefs"] [@default None];
    cdp_port: int option [@key "cdpPort"] [@default None];
  } [@@deriving yojson { strict = false }]

type playwright_new_request_args_client_certificates_item =
  {
    origin: string [@key "origin"];
    cert: string option [@key "cert"] [@default None];
    key: string option [@key "key"] [@default None];
    passphrase: string option [@key "passphrase"] [@default None];
    pfx: string option [@key "pfx"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_query_selector_all_returns =
  {
    elements: channel list [@key "elements"];
  } [@@deriving yojson { strict = false }]

type element_handle_owner_frame_returns =
  {
    frame: channel option [@key "frame"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_create_temp_files_args_items_item =
  {
    name: string [@key "name"];
    last_modified_ms: float option [@key "lastModifiedMs"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_create_temp_files_args =
  {
    root_dir_name: string option [@key "rootDirName"] [@default None];
    items: browser_context_create_temp_files_args_items_item list [@key "items"];
  } [@@deriving yojson { strict = false }]

type context_options_http_credentials_send =
  [
  | `Always
  | `Unauthorized
  ]

let context_options_http_credentials_send_to_yojson = function
  | `Always -> `String "always"
  | `Unauthorized -> `String "unauthorized"

let context_options_http_credentials_send_of_yojson = function
  | `String "always" -> Ok `Always
  | `String "unauthorized" -> Ok `Unauthorized
  | _ -> Error "Invalid enum context_options_http_credentials_send"

type context_options_http_credentials =
  {
    username: string [@key "username"];
    password: string [@key "password"];
    origin: string option [@key "origin"] [@default None];
    send: context_options_http_credentials_send option [@key "send"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_select_option_args_options_item =
  {
    value_or_label: string option [@key "valueOrLabel"] [@default None];
    value: string option [@key "value"] [@default None];
    label: string option [@key "label"] [@default None];
    index: int option [@key "index"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_select_option_args =
  {
    elements: channel list option [@key "elements"] [@default None];
    options: element_handle_select_option_args_options_item list option [@key "options"] [@default None];
    force: bool option [@key "force"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type browser_type_launch_args_proxy =
  {
    server: string [@key "server"];
    bypass: string option [@key "bypass"] [@default None];
    username: string option [@key "username"] [@default None];
    password: string option [@key "password"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_eval_on_selector_returns =
  {
    value: serialized_value [@key "value"];
  } [@@deriving yojson { strict = false }]

type browser_new_context_for_reuse_args_accept_downloads =
  [
  | `Accept
  | `Deny
  | `Internal_browser_default
  ]

let browser_new_context_for_reuse_args_accept_downloads_to_yojson = function
  | `Accept -> `String "accept"
  | `Deny -> `String "deny"
  | `Internal_browser_default -> `String "internal-browser-default"

let browser_new_context_for_reuse_args_accept_downloads_of_yojson = function
  | `String "accept" -> Ok `Accept
  | `String "deny" -> Ok `Deny
  | `String "internal-browser-default" -> Ok `Internal_browser_default
  | _ -> Error "Invalid enum browser_new_context_for_reuse_args_accept_downloads"

type frame_resolve_selector_returns =
  {
    resolved_selector: string [@key "resolvedSelector"];
  } [@@deriving yojson { strict = false }]

type frame_set_content_args =
  {
    html: string [@key "html"];
    timeout: float [@key "timeout"];
    wait_until: lifecycle_event option [@key "waitUntil"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_web_socket_route_event =
  {
    web_socket_route: channel [@key "webSocketRoute"];
  } [@@deriving yojson { strict = false }]

type page_emulate_media_args_contrast =
  [
  | `No_preference
  | `More
  | `No_override
  ]

let page_emulate_media_args_contrast_to_yojson = function
  | `No_preference -> `String "no-preference"
  | `More -> `String "more"
  | `No_override -> `String "no-override"

let page_emulate_media_args_contrast_of_yojson = function
  | `String "no-preference" -> Ok `No_preference
  | `String "more" -> Ok `More
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum page_emulate_media_args_contrast"

type page_emulate_media_args_forced_colors =
  [
  | `Active
  | `None
  | `No_override
  ]

let page_emulate_media_args_forced_colors_to_yojson = function
  | `Active -> `String "active"
  | `None -> `String "none"
  | `No_override -> `String "no-override"

let page_emulate_media_args_forced_colors_of_yojson = function
  | `String "active" -> Ok `Active
  | `String "none" -> Ok `None
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum page_emulate_media_args_forced_colors"

type page_emulate_media_args_reduced_motion =
  [
  | `Reduce
  | `No_preference
  | `No_override
  ]

let page_emulate_media_args_reduced_motion_to_yojson = function
  | `Reduce -> `String "reduce"
  | `No_preference -> `String "no-preference"
  | `No_override -> `String "no-override"

let page_emulate_media_args_reduced_motion_of_yojson = function
  | `String "reduce" -> Ok `Reduce
  | `String "no-preference" -> Ok `No_preference
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum page_emulate_media_args_reduced_motion"

type page_emulate_media_args_color_scheme =
  [
  | `Dark
  | `Light
  | `No_preference
  | `No_override
  ]

let page_emulate_media_args_color_scheme_to_yojson = function
  | `Dark -> `String "dark"
  | `Light -> `String "light"
  | `No_preference -> `String "no-preference"
  | `No_override -> `String "no-override"

let page_emulate_media_args_color_scheme_of_yojson = function
  | `String "dark" -> Ok `Dark
  | `String "light" -> Ok `Light
  | `String "no-preference" -> Ok `No_preference
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum page_emulate_media_args_color_scheme"

type page_emulate_media_args_media =
  [
  | `Screen
  | `Print
  | `No_override
  ]

let page_emulate_media_args_media_to_yojson = function
  | `Screen -> `String "screen"
  | `Print -> `String "print"
  | `No_override -> `String "no-override"

let page_emulate_media_args_media_of_yojson = function
  | `String "screen" -> Ok `Screen
  | `String "print" -> Ok `Print
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum page_emulate_media_args_media"

type page_emulate_media_args =
  {
    media: page_emulate_media_args_media option [@key "media"] [@default None];
    color_scheme: page_emulate_media_args_color_scheme option [@key "colorScheme"] [@default None];
    reduced_motion: page_emulate_media_args_reduced_motion option [@key "reducedMotion"] [@default None];
    forced_colors: page_emulate_media_args_forced_colors option [@key "forcedColors"] [@default None];
    contrast: page_emulate_media_args_contrast option [@key "contrast"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_set_http_credentials_args_http_credentials =
  {
    username: string [@key "username"];
    password: string [@key "password"];
    origin: string option [@key "origin"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_device_shell_args =
  {
    command: string [@key "command"];
  } [@@deriving yojson { strict = false }]

type browser_context_recorder_event_event_event =
  [
  | `Action_added
  | `Action_updated
  | `Signal_added
  ]

let browser_context_recorder_event_event_event_to_yojson = function
  | `Action_added -> `String "actionAdded"
  | `Action_updated -> `String "actionUpdated"
  | `Signal_added -> `String "signalAdded"

let browser_context_recorder_event_event_event_of_yojson = function
  | `String "actionAdded" -> Ok `Action_added
  | `String "actionUpdated" -> Ok `Action_updated
  | `String "signalAdded" -> Ok `Signal_added
  | _ -> Error "Invalid enum browser_context_recorder_event_event_event"

type browser_context_recorder_event_event =
  {
    event: browser_context_recorder_event_event_event [@key "event"];
    data: json [@key "data"];
    page: channel [@key "page"];
    code: string [@key "code"];
  } [@@deriving yojson { strict = false }]

type browser_new_context_args_forced_colors =
  [
  | `Active
  | `None
  | `No_override
  ]

let browser_new_context_args_forced_colors_to_yojson = function
  | `Active -> `String "active"
  | `None -> `String "none"
  | `No_override -> `String "no-override"

let browser_new_context_args_forced_colors_of_yojson = function
  | `String "active" -> Ok `Active
  | `String "none" -> Ok `None
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum browser_new_context_args_forced_colors"

type page_screencast_start_args =
  {
    size: page_screencast_start_args_size option [@key "size"] [@default None];
    quality: int option [@key "quality"] [@default None];
    send_frames: bool option [@key "sendFrames"] [@default None];
    record: bool option [@key "record"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_page_event =
  {
    page: channel [@key "page"];
  } [@@deriving yojson { strict = false }]

type browser_context_dialog_event =
  {
    dialog: channel [@key "dialog"];
  } [@@deriving yojson { strict = false }]

type android_device_pinch_close_args =
  {
    android_selector: android_selector [@key "androidSelector"];
    percent: float [@key "percent"];
    speed: float option [@key "speed"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type worker_evaluate_expression_args =
  {
    expression: string [@key "expression"];
    is_function: bool option [@key "isFunction"] [@default None];
    arg: serialized_argument [@key "arg"];
  } [@@deriving yojson { strict = false }]

type frame_input_value_returns =
  {
    value: string [@key "value"];
  } [@@deriving yojson { strict = false }]

type android_device_launch_browser_args_client_certificates_item =
  {
    origin: string [@key "origin"];
    cert: string option [@key "cert"] [@default None];
    key: string option [@key "key"] [@default None];
    passphrase: string option [@key "passphrase"] [@default None];
    pfx: string option [@key "pfx"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_inner_htm_l_returns =
  {
    value: string [@key "value"];
  } [@@deriving yojson { strict = false }]

type debug_controller_set_report_state_changed_args =
  {
    enabled: bool [@key "enabled"];
  } [@@deriving yojson { strict = false }]

type debugger_run_to_args_location =
  {
    file: string [@key "file"];
    line: int option [@key "line"] [@default None];
    column: int option [@key "column"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_device_input_swipe_args =
  {
    segments: point list [@key "segments"];
    steps: int [@key "steps"];
  } [@@deriving yojson { strict = false }]

type browser_new_context_args_accept_downloads =
  [
  | `Accept
  | `Deny
  | `Internal_browser_default
  ]

let browser_new_context_args_accept_downloads_to_yojson = function
  | `Accept -> `String "accept"
  | `Deny -> `String "deny"
  | `Internal_browser_default -> `String "internal-browser-default"

let browser_new_context_args_accept_downloads_of_yojson = function
  | `String "accept" -> Ok `Accept
  | `String "deny" -> Ok `Deny
  | `String "internal-browser-default" -> Ok `Internal_browser_default
  | _ -> Error "Invalid enum browser_new_context_args_accept_downloads"

type frame_add_script_tag_returns =
  {
    element: channel [@key "element"];
  } [@@deriving yojson { strict = false }]

type page_expect_screenshot_args_scale =
  [
  | `Css
  | `Device
  ]

let page_expect_screenshot_args_scale_to_yojson = function
  | `Css -> `String "css"
  | `Device -> `String "device"

let page_expect_screenshot_args_scale_of_yojson = function
  | `String "css" -> Ok `Css
  | `String "device" -> Ok `Device
  | _ -> Error "Invalid enum page_expect_screenshot_args_scale"

type browser_context_enable_recorder_args_recorder_mode =
  [
  | `Default
  | `Api
  ]

let browser_context_enable_recorder_args_recorder_mode_to_yojson = function
  | `Default -> `String "default"
  | `Api -> `String "api"

let browser_context_enable_recorder_args_recorder_mode_of_yojson = function
  | `String "default" -> Ok `Default
  | `String "api" -> Ok `Api
  | _ -> Error "Invalid enum browser_context_enable_recorder_args_recorder_mode"

type browser_context_enable_recorder_args_mode =
  [
  | `Inspecting
  | `Recording
  ]

let browser_context_enable_recorder_args_mode_to_yojson = function
  | `Inspecting -> `String "inspecting"
  | `Recording -> `String "recording"

let browser_context_enable_recorder_args_mode_of_yojson = function
  | `String "inspecting" -> Ok `Inspecting
  | `String "recording" -> Ok `Recording
  | _ -> Error "Invalid enum browser_context_enable_recorder_args_mode"

type browser_context_enable_recorder_args =
  {
    language: string option [@key "language"] [@default None];
    mode: browser_context_enable_recorder_args_mode option [@key "mode"] [@default None];
    recorder_mode: browser_context_enable_recorder_args_recorder_mode option [@key "recorderMode"] [@default None];
    pause_on_next_statement: bool option [@key "pauseOnNextStatement"] [@default None];
    test_id_attribute_name: string option [@key "testIdAttributeName"] [@default None];
    launch_options: json option [@key "launchOptions"] [@default None];
    context_options: json option [@key "contextOptions"] [@default None];
    device: string option [@key "device"] [@default None];
    save_storage: string option [@key "saveStorage"] [@default None];
    output_file: string option [@key "outputFile"] [@default None];
    handle_sigint: bool option [@key "handleSIGINT"] [@default None];
    omit_call_tracking: bool option [@key "omitCallTracking"] [@default None];
  } [@@deriving yojson { strict = false }]

type route_redirect_navigation_request_args =
  {
    url: string [@key "url"];
  } [@@deriving yojson { strict = false }]

type page_mouse_click_args_button =
  [
  | `Left
  | `Right
  | `Middle
  ]

let page_mouse_click_args_button_to_yojson = function
  | `Left -> `String "left"
  | `Right -> `String "right"
  | `Middle -> `String "middle"

let page_mouse_click_args_button_of_yojson = function
  | `String "left" -> Ok `Left
  | `String "right" -> Ok `Right
  | `String "middle" -> Ok `Middle
  | _ -> Error "Invalid enum page_mouse_click_args_button"

type artifact_save_as_stream_returns =
  {
    stream: channel [@key "stream"];
  } [@@deriving yojson { strict = false }]

type context_options_record_video_show_actions_position =
  [
  | `Top_left
  | `Top
  | `Top_right
  | `Bottom_left
  | `Bottom
  | `Bottom_right
  ]

let context_options_record_video_show_actions_position_to_yojson = function
  | `Top_left -> `String "top-left"
  | `Top -> `String "top"
  | `Top_right -> `String "top-right"
  | `Bottom_left -> `String "bottom-left"
  | `Bottom -> `String "bottom"
  | `Bottom_right -> `String "bottom-right"

let context_options_record_video_show_actions_position_of_yojson = function
  | `String "top-left" -> Ok `Top_left
  | `String "top" -> Ok `Top
  | `String "top-right" -> Ok `Top_right
  | `String "bottom-left" -> Ok `Bottom_left
  | `String "bottom" -> Ok `Bottom
  | `String "bottom-right" -> Ok `Bottom_right
  | _ -> Error "Invalid enum context_options_record_video_show_actions_position"

type browser_context_clock_run_for_args =
  {
    ticks_number: float option [@key "ticksNumber"] [@default None];
    ticks_string: string option [@key "ticksString"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_title_returns =
  {
    value: string [@key "value"];
  } [@@deriving yojson { strict = false }]

type page_viewport_size_changed_event_viewport_size =
  {
    width: int [@key "width"];
    height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type browser_new_context_for_reuse_args_viewport =
  {
    width: int [@key "width"];
    height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type web_socket_route_message_from_server_event =
  {
    message: string [@key "message"];
    is_base64: bool [@key "isBase64"];
  } [@@deriving yojson { strict = false }]

type json_pipe_message_event =
  {
    message: json [@key "message"];
  } [@@deriving yojson { strict = false }]

type artifact_failure_returns =
  {
    error: string option [@key "error"] [@default None];
  } [@@deriving yojson { strict = false }]

type sdk_language =
  [
  | `Javascript
  | `Python
  | `Java
  | `Csharp
  ]

let sdk_language_to_yojson = function
  | `Javascript -> `String "javascript"
  | `Python -> `String "python"
  | `Java -> `String "java"
  | `Csharp -> `String "csharp"

let sdk_language_of_yojson = function
  | `String "javascript" -> Ok `Javascript
  | `String "python" -> Ok `Python
  | `String "java" -> Ok `Java
  | `String "csharp" -> Ok `Csharp
  | _ -> Error "Invalid enum sdk_language"

type debug_controller_initialize_args =
  {
    codegen_id: string [@key "codegenId"];
    sdk_language: sdk_language [@key "sdkLanguage"];
  } [@@deriving yojson { strict = false }]

type context_options_accept_downloads =
  [
  | `Accept
  | `Deny
  | `Internal_browser_default
  ]

let context_options_accept_downloads_to_yojson = function
  | `Accept -> `String "accept"
  | `Deny -> `String "deny"
  | `Internal_browser_default -> `String "internal-browser-default"

let context_options_accept_downloads_of_yojson = function
  | `String "accept" -> Ok `Accept
  | `String "deny" -> Ok `Deny
  | `String "internal-browser-default" -> Ok `Internal_browser_default
  | _ -> Error "Invalid enum context_options_accept_downloads"

type frame_evaluate_expression_handle_returns =
  {
    handle: channel [@key "handle"];
  } [@@deriving yojson { strict = false }]

type android_device_launch_browser_args_screen =
  {
    width: int [@key "width"];
    height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type browser_context_create_temp_files_returns =
  {
    root_dir: channel option [@key "rootDir"] [@default None];
    writable_streams: channel list [@key "writableStreams"];
  } [@@deriving yojson { strict = false }]

type js_handle_get_property_list_returns_properties_item =
  {
    name: string [@key "name"];
    value: channel [@key "value"];
  } [@@deriving yojson { strict = false }]

type js_handle_get_property_list_returns =
  {
    properties: js_handle_get_property_list_returns_properties_item list [@key "properties"];
  } [@@deriving yojson { strict = false }]

type element_handle_click_args_modifiers_item =
  [
  | `Alt
  | `Control
  | `Control_or_meta
  | `Meta
  | `Shift
  ]

let element_handle_click_args_modifiers_item_to_yojson = function
  | `Alt -> `String "Alt"
  | `Control -> `String "Control"
  | `Control_or_meta -> `String "ControlOrMeta"
  | `Meta -> `String "Meta"
  | `Shift -> `String "Shift"

let element_handle_click_args_modifiers_item_of_yojson = function
  | `String "Alt" -> Ok `Alt
  | `String "Control" -> Ok `Control
  | `String "ControlOrMeta" -> Ok `Control_or_meta
  | `String "Meta" -> Ok `Meta
  | `String "Shift" -> Ok `Shift
  | _ -> Error "Invalid enum element_handle_click_args_modifiers_item"

type browser_new_context_for_reuse_args_storage_state =
  {
    cookies: set_network_cookie list option [@key "cookies"] [@default None];
    origins: set_origin_storage list option [@key "origins"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_console_messages_returns_messages_item_location =
  {
    url: string [@key "url"];
    line_number: int [@key "lineNumber"];
    column_number: int [@key "columnNumber"];
  } [@@deriving yojson { strict = false }]

type page_console_messages_returns_messages_item =
  {
    type_: string [@key "type"];
    text: string [@key "text"];
    args: channel list [@key "args"];
    location: page_console_messages_returns_messages_item_location [@key "location"];
    timestamp: float [@key "timestamp"];
  } [@@deriving yojson { strict = false }]

type page_console_messages_returns =
  {
    messages: page_console_messages_returns_messages_item list [@key "messages"];
  } [@@deriving yojson { strict = false }]

type browser_new_context_for_reuse_args_http_credentials_send =
  [
  | `Always
  | `Unauthorized
  ]

let browser_new_context_for_reuse_args_http_credentials_send_to_yojson = function
  | `Always -> `String "always"
  | `Unauthorized -> `String "unauthorized"

let browser_new_context_for_reuse_args_http_credentials_send_of_yojson = function
  | `String "always" -> Ok `Always
  | `String "unauthorized" -> Ok `Unauthorized
  | _ -> Error "Invalid enum browser_new_context_for_reuse_args_http_credentials_send"

type web_socket_socket_error_event =
  {
    error: string [@key "error"];
  } [@@deriving yojson { strict = false }]

type android_device_fill_args =
  {
    android_selector: android_selector [@key "androidSelector"];
    text: string [@key "text"];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type worker_initializer =
  {
    url: string [@key "url"];
  } [@@deriving yojson { strict = false }]

type browser_start_server_args =
  {
    title: string [@key "title"];
    workspace_dir: string option [@key "workspaceDir"] [@default None];
    metadata: json option [@key "metadata"] [@default None];
    host: string option [@key "host"] [@default None];
    port: int option [@key "port"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_navigated_event_new_document =
  {
    request: channel option [@key "request"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_navigated_event =
  {
    url: string [@key "url"];
    name: string [@key "name"];
    new_document: frame_navigated_event_new_document option [@key "newDocument"] [@default None];
    error: string option [@key "error"] [@default None];
  } [@@deriving yojson { strict = false }]

type context_options_screen =
  {
    width: int [@key "width"];
    height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type element_handle_input_value_returns =
  {
    value: string [@key "value"];
  } [@@deriving yojson { strict = false }]

type page_set_extra_http_headers_args =
  {
    headers: name_value list [@key "headers"];
  } [@@deriving yojson { strict = false }]

type android_device_launch_browser_args_reduced_motion =
  [
  | `Reduce
  | `No_preference
  | `No_override
  ]

let android_device_launch_browser_args_reduced_motion_to_yojson = function
  | `Reduce -> `String "reduce"
  | `No_preference -> `String "no-preference"
  | `No_override -> `String "no-override"

let android_device_launch_browser_args_reduced_motion_of_yojson = function
  | `String "reduce" -> Ok `Reduce
  | `String "no-preference" -> Ok `No_preference
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum android_device_launch_browser_args_reduced_motion"

type browser_new_context_for_reuse_args_reduced_motion =
  [
  | `Reduce
  | `No_preference
  | `No_override
  ]

let browser_new_context_for_reuse_args_reduced_motion_to_yojson = function
  | `Reduce -> `String "reduce"
  | `No_preference -> `String "no-preference"
  | `No_override -> `String "no-override"

let browser_new_context_for_reuse_args_reduced_motion_of_yojson = function
  | `String "reduce" -> Ok `Reduce
  | `String "no-preference" -> Ok `No_preference
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum browser_new_context_for_reuse_args_reduced_motion"

type android_device_launch_browser_args_record_video_show_actions_position =
  [
  | `Top_left
  | `Top
  | `Top_right
  | `Bottom_left
  | `Bottom
  | `Bottom_right
  ]

let android_device_launch_browser_args_record_video_show_actions_position_to_yojson = function
  | `Top_left -> `String "top-left"
  | `Top -> `String "top"
  | `Top_right -> `String "top-right"
  | `Bottom_left -> `String "bottom-left"
  | `Bottom -> `String "bottom"
  | `Bottom_right -> `String "bottom-right"

let android_device_launch_browser_args_record_video_show_actions_position_of_yojson = function
  | `String "top-left" -> Ok `Top_left
  | `String "top" -> Ok `Top
  | `String "top-right" -> Ok `Top_right
  | `String "bottom-left" -> Ok `Bottom_left
  | `String "bottom" -> Ok `Bottom
  | `String "bottom-right" -> Ok `Bottom_right
  | _ -> Error "Invalid enum android_device_launch_browser_args_record_video_show_actions_position"

type android_device_launch_browser_args_record_video_show_actions =
  {
    duration: float option [@key "duration"] [@default None];
    position: android_device_launch_browser_args_record_video_show_actions_position option [@key "position"] [@default None];
    font_size: int option [@key "fontSize"] [@default None];
  } [@@deriving yojson { strict = false }]

type root_initialize_args =
  {
    sdk_language: sdk_language [@key "sdkLanguage"];
  } [@@deriving yojson { strict = false }]

type element_handle_screenshot_args_scale =
  [
  | `Css
  | `Device
  ]

let element_handle_screenshot_args_scale_to_yojson = function
  | `Css -> `String "css"
  | `Device -> `String "device"

let element_handle_screenshot_args_scale_of_yojson = function
  | `String "css" -> Ok `Css
  | `String "device" -> Ok `Device
  | _ -> Error "Invalid enum element_handle_screenshot_args_scale"

type browser_new_context_for_reuse_args_proxy =
  {
    server: string [@key "server"];
    bypass: string option [@key "bypass"] [@default None];
    username: string option [@key "username"] [@default None];
    password: string option [@key "password"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_request_event =
  {
    request: channel [@key "request"];
    page: channel option [@key "page"] [@default None];
  } [@@deriving yojson { strict = false }]

type local_utils_tracing_started_returns =
  {
    stacks_id: string [@key "stacksId"];
  } [@@deriving yojson { strict = false }]

type element_handle_content_frame_returns =
  {
    frame: channel option [@key "frame"] [@default None];
  } [@@deriving yojson { strict = false }]

type dialog_initializer =
  {
    page: channel option [@key "page"] [@default None];
    type_: string [@key "type"];
    message: string [@key "message"];
    default_value: string [@key "defaultValue"];
  } [@@deriving yojson { strict = false }]

type api_request_context_dispose_api_response_args =
  {
    fetch_uid: string [@key "fetchUid"];
  } [@@deriving yojson { strict = false }]

type android_devices_args =
  {
    host: string option [@key "host"] [@default None];
    port: int option [@key "port"] [@default None];
    omit_driver_install: bool option [@key "omitDriverInstall"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_new_cdp_session_returns =
  {
    session: channel [@key "session"];
  } [@@deriving yojson { strict = false }]

type page_screencast_show_actions_args_position =
  [
  | `Top_left
  | `Top
  | `Top_right
  | `Bottom_left
  | `Bottom
  | `Bottom_right
  ]

let page_screencast_show_actions_args_position_to_yojson = function
  | `Top_left -> `String "top-left"
  | `Top -> `String "top"
  | `Top_right -> `String "top-right"
  | `Bottom_left -> `String "bottom-left"
  | `Bottom -> `String "bottom"
  | `Bottom_right -> `String "bottom-right"

let page_screencast_show_actions_args_position_of_yojson = function
  | `String "top-left" -> Ok `Top_left
  | `String "top" -> Ok `Top
  | `String "top-right" -> Ok `Top_right
  | `String "bottom-left" -> Ok `Bottom_left
  | `String "bottom" -> Ok `Bottom
  | `String "bottom-right" -> Ok `Bottom_right
  | _ -> Error "Invalid enum page_screencast_show_actions_args_position"

type page_screencast_show_actions_args =
  {
    duration: float option [@key "duration"] [@default None];
    position: page_screencast_show_actions_args_position option [@key "position"] [@default None];
    font_size: int option [@key "fontSize"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_new_context_args_viewport =
  {
    width: int [@key "width"];
    height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type context_options_viewport =
  {
    width: int [@key "width"];
    height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type android_device_open_returns =
  {
    socket: channel [@key "socket"];
  } [@@deriving yojson { strict = false }]

type frame_resolve_selector_args =
  {
    selector: string [@key "selector"];
  } [@@deriving yojson { strict = false }]

type frame_focus_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type browser_context_close_args =
  {
    reason: string option [@key "reason"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_screenshot_args_mask_item =
  {
    frame: channel [@key "frame"];
    selector: string [@key "selector"];
  } [@@deriving yojson { strict = false }]

type element_handle_screenshot_args_animations =
  [
  | `Disabled
  | `Allow
  ]

let element_handle_screenshot_args_animations_to_yojson = function
  | `Disabled -> `String "disabled"
  | `Allow -> `String "allow"

let element_handle_screenshot_args_animations_of_yojson = function
  | `String "disabled" -> Ok `Disabled
  | `String "allow" -> Ok `Allow
  | _ -> Error "Invalid enum element_handle_screenshot_args_animations"

type element_handle_screenshot_args_caret =
  [
  | `Hide
  | `Initial
  ]

let element_handle_screenshot_args_caret_to_yojson = function
  | `Hide -> `String "hide"
  | `Initial -> `String "initial"

let element_handle_screenshot_args_caret_of_yojson = function
  | `String "hide" -> Ok `Hide
  | `String "initial" -> Ok `Initial
  | _ -> Error "Invalid enum element_handle_screenshot_args_caret"

type element_handle_screenshot_args_type =
  [
  | `Png
  | `Jpeg
  ]

let element_handle_screenshot_args_type_to_yojson = function
  | `Png -> `String "png"
  | `Jpeg -> `String "jpeg"

let element_handle_screenshot_args_type_of_yojson = function
  | `String "png" -> Ok `Png
  | `String "jpeg" -> Ok `Jpeg
  | _ -> Error "Invalid enum element_handle_screenshot_args_type"

type element_handle_screenshot_args =
  {
    timeout: float [@key "timeout"];
    type_: element_handle_screenshot_args_type option [@key "type"] [@default None];
    quality: int option [@key "quality"] [@default None];
    omit_background: bool option [@key "omitBackground"] [@default None];
    caret: element_handle_screenshot_args_caret option [@key "caret"] [@default None];
    animations: element_handle_screenshot_args_animations option [@key "animations"] [@default None];
    scale: element_handle_screenshot_args_scale option [@key "scale"] [@default None];
    mask: element_handle_screenshot_args_mask_item list option [@key "mask"] [@default None];
    mask_color: string option [@key "maskColor"] [@default None];
    style: string option [@key "style"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_device_launch_browser_args_service_workers =
  [
  | `Allow
  | `Block
  ]

let android_device_launch_browser_args_service_workers_to_yojson = function
  | `Allow -> `String "allow"
  | `Block -> `String "block"

let android_device_launch_browser_args_service_workers_of_yojson = function
  | `String "allow" -> Ok `Allow
  | `String "block" -> Ok `Block
  | _ -> Error "Invalid enum android_device_launch_browser_args_service_workers"

type browser_context_page_error_event_location =
  {
    url: string [@key "url"];
    line: int [@key "line"];
    column: int [@key "column"];
  } [@@deriving yojson { strict = false }]

type page_stop_css_coverage_returns_entries_item_ranges_item =
  {
    start: int [@key "start"];
    end_: int [@key "end"];
  } [@@deriving yojson { strict = false }]

type page_stop_css_coverage_returns_entries_item =
  {
    url: string [@key "url"];
    text: string option [@key "text"] [@default None];
    ranges: page_stop_css_coverage_returns_entries_item_ranges_item list [@key "ranges"];
  } [@@deriving yojson { strict = false }]

type page_stop_css_coverage_returns =
  {
    entries: page_stop_css_coverage_returns_entries_item list [@key "entries"];
  } [@@deriving yojson { strict = false }]

type browser_type_connect_to_worker_returns =
  {
    worker: channel [@key "worker"];
  } [@@deriving yojson { strict = false }]

type frame_highlight_args =
  {
    selector: string [@key "selector"];
    style: string option [@key "style"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_add_style_tag_returns =
  {
    element: channel [@key "element"];
  } [@@deriving yojson { strict = false }]

type browser_new_context_args_http_credentials =
  {
    username: string [@key "username"];
    password: string [@key "password"];
    origin: string option [@key "origin"] [@default None];
    send: browser_new_context_args_http_credentials_send option [@key "send"] [@default None];
  } [@@deriving yojson { strict = false }]

type metadata_location =
  {
    file: string [@key "file"];
    line: int option [@key "line"] [@default None];
    column: int option [@key "column"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_initializer_options_record_video_show_actions_position =
  [
  | `Top_left
  | `Top
  | `Top_right
  | `Bottom_left
  | `Bottom
  | `Bottom_right
  ]

let browser_context_initializer_options_record_video_show_actions_position_to_yojson = function
  | `Top_left -> `String "top-left"
  | `Top -> `String "top"
  | `Top_right -> `String "top-right"
  | `Bottom_left -> `String "bottom-left"
  | `Bottom -> `String "bottom"
  | `Bottom_right -> `String "bottom-right"

let browser_context_initializer_options_record_video_show_actions_position_of_yojson = function
  | `String "top-left" -> Ok `Top_left
  | `String "top" -> Ok `Top
  | `String "top-right" -> Ok `Top_right
  | `String "bottom-left" -> Ok `Bottom_left
  | `String "bottom" -> Ok `Bottom
  | `String "bottom-right" -> Ok `Bottom_right
  | _ -> Error "Invalid enum browser_context_initializer_options_record_video_show_actions_position"

type browser_context_initializer_options_record_video_show_actions =
  {
    duration: float option [@key "duration"] [@default None];
    position: browser_context_initializer_options_record_video_show_actions_position option [@key "position"] [@default None];
    font_size: int option [@key "fontSize"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_initializer_options_record_video_size =
  {
    width: int [@key "width"];
    height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type browser_context_initializer_options_record_video =
  {
    dir: string option [@key "dir"] [@default None];
    size: browser_context_initializer_options_record_video_size option [@key "size"] [@default None];
    show_actions: browser_context_initializer_options_record_video_show_actions option [@key "showActions"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_initializer_options_contrast =
  [
  | `No_preference
  | `More
  | `No_override
  ]

let browser_context_initializer_options_contrast_to_yojson = function
  | `No_preference -> `String "no-preference"
  | `More -> `String "more"
  | `No_override -> `String "no-override"

let browser_context_initializer_options_contrast_of_yojson = function
  | `String "no-preference" -> Ok `No_preference
  | `String "more" -> Ok `More
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum browser_context_initializer_options_contrast"

type browser_context_initializer_options_accept_downloads =
  [
  | `Accept
  | `Deny
  | `Internal_browser_default
  ]

let browser_context_initializer_options_accept_downloads_to_yojson = function
  | `Accept -> `String "accept"
  | `Deny -> `String "deny"
  | `Internal_browser_default -> `String "internal-browser-default"

let browser_context_initializer_options_accept_downloads_of_yojson = function
  | `String "accept" -> Ok `Accept
  | `String "deny" -> Ok `Deny
  | `String "internal-browser-default" -> Ok `Internal_browser_default
  | _ -> Error "Invalid enum browser_context_initializer_options_accept_downloads"

type browser_context_initializer_options_forced_colors =
  [
  | `Active
  | `None
  | `No_override
  ]

let browser_context_initializer_options_forced_colors_to_yojson = function
  | `Active -> `String "active"
  | `None -> `String "none"
  | `No_override -> `String "no-override"

let browser_context_initializer_options_forced_colors_of_yojson = function
  | `String "active" -> Ok `Active
  | `String "none" -> Ok `None
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum browser_context_initializer_options_forced_colors"

type browser_context_initializer_options_reduced_motion =
  [
  | `Reduce
  | `No_preference
  | `No_override
  ]

let browser_context_initializer_options_reduced_motion_to_yojson = function
  | `Reduce -> `String "reduce"
  | `No_preference -> `String "no-preference"
  | `No_override -> `String "no-override"

let browser_context_initializer_options_reduced_motion_of_yojson = function
  | `String "reduce" -> Ok `Reduce
  | `String "no-preference" -> Ok `No_preference
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum browser_context_initializer_options_reduced_motion"

type browser_context_initializer_options_color_scheme =
  [
  | `Dark
  | `Light
  | `No_preference
  | `No_override
  ]

let browser_context_initializer_options_color_scheme_to_yojson = function
  | `Dark -> `String "dark"
  | `Light -> `String "light"
  | `No_preference -> `String "no-preference"
  | `No_override -> `String "no-override"

let browser_context_initializer_options_color_scheme_of_yojson = function
  | `String "dark" -> Ok `Dark
  | `String "light" -> Ok `Light
  | `String "no-preference" -> Ok `No_preference
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum browser_context_initializer_options_color_scheme"

type browser_context_initializer_options_http_credentials_send =
  [
  | `Always
  | `Unauthorized
  ]

let browser_context_initializer_options_http_credentials_send_to_yojson = function
  | `Always -> `String "always"
  | `Unauthorized -> `String "unauthorized"

let browser_context_initializer_options_http_credentials_send_of_yojson = function
  | `String "always" -> Ok `Always
  | `String "unauthorized" -> Ok `Unauthorized
  | _ -> Error "Invalid enum browser_context_initializer_options_http_credentials_send"

type browser_context_initializer_options_http_credentials =
  {
    username: string [@key "username"];
    password: string [@key "password"];
    origin: string option [@key "origin"] [@default None];
    send: browser_context_initializer_options_http_credentials_send option [@key "send"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_initializer_options_geolocation =
  {
    longitude: float [@key "longitude"];
    latitude: float [@key "latitude"];
    accuracy: float option [@key "accuracy"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_initializer_options_client_certificates_item =
  {
    origin: string [@key "origin"];
    cert: string option [@key "cert"] [@default None];
    key: string option [@key "key"] [@default None];
    passphrase: string option [@key "passphrase"] [@default None];
    pfx: string option [@key "pfx"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_initializer_options_screen =
  {
    width: int [@key "width"];
    height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type browser_context_initializer_options_viewport =
  {
    width: int [@key "width"];
    height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type browser_context_initializer_options =
  {
    no_default_viewport: bool option [@key "noDefaultViewport"] [@default None];
    viewport: browser_context_initializer_options_viewport option [@key "viewport"] [@default None];
    screen: browser_context_initializer_options_screen option [@key "screen"] [@default None];
    ignore_https_errors: bool option [@key "ignoreHTTPSErrors"] [@default None];
    client_certificates: browser_context_initializer_options_client_certificates_item list option [@key "clientCertificates"] [@default None];
    java_script_enabled: bool option [@key "javaScriptEnabled"] [@default None];
    bypass_csp: bool option [@key "bypassCSP"] [@default None];
    user_agent: string option [@key "userAgent"] [@default None];
    locale: string option [@key "locale"] [@default None];
    timezone_id: string option [@key "timezoneId"] [@default None];
    geolocation: browser_context_initializer_options_geolocation option [@key "geolocation"] [@default None];
    permissions: string list option [@key "permissions"] [@default None];
    extra_http_headers: name_value list option [@key "extraHTTPHeaders"] [@default None];
    offline: bool option [@key "offline"] [@default None];
    http_credentials: browser_context_initializer_options_http_credentials option [@key "httpCredentials"] [@default None];
    device_scale_factor: float option [@key "deviceScaleFactor"] [@default None];
    is_mobile: bool option [@key "isMobile"] [@default None];
    has_touch: bool option [@key "hasTouch"] [@default None];
    color_scheme: browser_context_initializer_options_color_scheme option [@key "colorScheme"] [@default None];
    reduced_motion: browser_context_initializer_options_reduced_motion option [@key "reducedMotion"] [@default None];
    forced_colors: browser_context_initializer_options_forced_colors option [@key "forcedColors"] [@default None];
    accept_downloads: browser_context_initializer_options_accept_downloads option [@key "acceptDownloads"] [@default None];
    contrast: browser_context_initializer_options_contrast option [@key "contrast"] [@default None];
    base_url: string option [@key "baseURL"] [@default None];
    record_video: browser_context_initializer_options_record_video option [@key "recordVideo"] [@default None];
    strict_selectors: bool option [@key "strictSelectors"] [@default None];
    service_workers: browser_context_initializer_options_service_workers option [@key "serviceWorkers"] [@default None];
    selector_engines: selector_engine list option [@key "selectorEngines"] [@default None];
    test_id_attribute_name: string option [@key "testIdAttributeName"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_expose_binding_returns =
  {
    disposable: channel [@key "disposable"];
  } [@@deriving yojson { strict = false }]

type page_go_back_args =
  {
    timeout: float [@key "timeout"];
    wait_until: lifecycle_event option [@key "waitUntil"] [@default None];
  } [@@deriving yojson { strict = false }]

type web_socket_route_message_from_page_event =
  {
    message: string [@key "message"];
    is_base64: bool [@key "isBase64"];
  } [@@deriving yojson { strict = false }]

type browser_close_args =
  {
    reason: string option [@key "reason"] [@default None];
  } [@@deriving yojson { strict = false }]

type url_pattern =
  {
    hash: string [@key "hash"];
    hostname: string [@key "hostname"];
    password: string [@key "password"];
    pathname: string [@key "pathname"];
    port: string [@key "port"];
    protocol: string [@key "protocol"];
    search: string [@key "search"];
    username: string [@key "username"];
  } [@@deriving yojson { strict = false }]

type page_set_network_interception_patterns_args_patterns_item =
  {
    glob: string option [@key "glob"] [@default None];
    regex_source: string option [@key "regexSource"] [@default None];
    regex_flags: string option [@key "regexFlags"] [@default None];
    url_pattern: url_pattern option [@key "urlPattern"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_set_network_interception_patterns_args =
  {
    patterns: page_set_network_interception_patterns_args_patterns_item list [@key "patterns"];
  } [@@deriving yojson { strict = false }]

type page_expect_screenshot_args_mask_item =
  {
    frame: channel [@key "frame"];
    selector: string [@key "selector"];
  } [@@deriving yojson { strict = false }]

type page_expect_screenshot_args_animations =
  [
  | `Disabled
  | `Allow
  ]

let page_expect_screenshot_args_animations_to_yojson = function
  | `Disabled -> `String "disabled"
  | `Allow -> `String "allow"

let page_expect_screenshot_args_animations_of_yojson = function
  | `String "disabled" -> Ok `Disabled
  | `String "allow" -> Ok `Allow
  | _ -> Error "Invalid enum page_expect_screenshot_args_animations"

type page_expect_screenshot_args_caret =
  [
  | `Hide
  | `Initial
  ]

let page_expect_screenshot_args_caret_to_yojson = function
  | `Hide -> `String "hide"
  | `Initial -> `String "initial"

let page_expect_screenshot_args_caret_of_yojson = function
  | `String "hide" -> Ok `Hide
  | `String "initial" -> Ok `Initial
  | _ -> Error "Invalid enum page_expect_screenshot_args_caret"

type rect =
  {
    x: float [@key "x"];
    y: float [@key "y"];
    width: float [@key "width"];
    height: float [@key "height"];
  } [@@deriving yojson { strict = false }]

type page_expect_screenshot_args_locator =
  {
    frame: channel [@key "frame"];
    selector: string [@key "selector"];
  } [@@deriving yojson { strict = false }]

type page_expect_screenshot_args =
  {
    expected: string option [@key "expected"] [@default None];
    timeout: float [@key "timeout"];
    is_not: bool [@key "isNot"];
    locator: page_expect_screenshot_args_locator option [@key "locator"] [@default None];
    comparator: string option [@key "comparator"] [@default None];
    max_diff_pixels: int option [@key "maxDiffPixels"] [@default None];
    max_diff_pixel_ratio: float option [@key "maxDiffPixelRatio"] [@default None];
    threshold: float option [@key "threshold"] [@default None];
    full_page: bool option [@key "fullPage"] [@default None];
    clip: rect option [@key "clip"] [@default None];
    omit_background: bool option [@key "omitBackground"] [@default None];
    caret: page_expect_screenshot_args_caret option [@key "caret"] [@default None];
    animations: page_expect_screenshot_args_animations option [@key "animations"] [@default None];
    scale: page_expect_screenshot_args_scale option [@key "scale"] [@default None];
    mask: page_expect_screenshot_args_mask_item list option [@key "mask"] [@default None];
    mask_color: string option [@key "maskColor"] [@default None];
    style: string option [@key "style"] [@default None];
  } [@@deriving yojson { strict = false }]

type local_utils_connect_args =
  {
    endpoint: string [@key "endpoint"];
    headers: json option [@key "headers"] [@default None];
    expose_network: string option [@key "exposeNetwork"] [@default None];
    slow_mo: float option [@key "slowMo"] [@default None];
    timeout: float [@key "timeout"];
    socks_proxy_redirect_port_for_test: int option [@key "socksProxyRedirectPortForTest"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_route_event =
  {
    route: channel [@key "route"];
  } [@@deriving yojson { strict = false }]

type page_page_errors_returns =
  {
    errors: serialized_error list [@key "errors"];
  } [@@deriving yojson { strict = false }]

type dialog_accept_args =
  {
    prompt_text: string option [@key "promptText"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_new_context_for_reuse_args_http_credentials =
  {
    username: string [@key "username"];
    password: string [@key "password"];
    origin: string option [@key "origin"] [@default None];
    send: browser_new_context_for_reuse_args_http_credentials_send option [@key "send"] [@default None];
  } [@@deriving yojson { strict = false }]

type playwright_new_request_args_proxy =
  {
    server: string [@key "server"];
    bypass: string option [@key "bypass"] [@default None];
    username: string option [@key "username"] [@default None];
    password: string option [@key "password"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_aria_ref_args =
  {
    selector: string [@key "selector"];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type browser_context_request_failed_event =
  {
    request: channel [@key "request"];
    failure_text: string option [@key "failureText"] [@default None];
    response_end_timing: float [@key "responseEndTiming"];
    page: channel option [@key "page"] [@default None];
  } [@@deriving yojson { strict = false }]

type worker_update_subscription_args_event =
  [
  | `Console
  ]

let worker_update_subscription_args_event_to_yojson = function
  | `Console -> `String "console"

let worker_update_subscription_args_event_of_yojson = function
  | `String "console" -> Ok `Console
  | _ -> Error "Invalid enum worker_update_subscription_args_event"

type worker_update_subscription_args =
  {
    event: worker_update_subscription_args_event [@key "event"];
    enabled: bool [@key "enabled"];
  } [@@deriving yojson { strict = false }]

type frame_evaluate_expression_returns =
  {
    value: serialized_value [@key "value"];
  } [@@deriving yojson { strict = false }]

type record_har_options_mode =
  [
  | `Full
  | `Minimal
  ]

let record_har_options_mode_to_yojson = function
  | `Full -> `String "full"
  | `Minimal -> `String "minimal"

let record_har_options_mode_of_yojson = function
  | `String "full" -> Ok `Full
  | `String "minimal" -> Ok `Minimal
  | _ -> Error "Invalid enum record_har_options_mode"

type element_handle_is_checked_returns =
  {
    value: bool [@key "value"];
  } [@@deriving yojson { strict = false }]

type element_handle_dispatch_event_args =
  {
    type_: string [@key "type"];
    event_init: serialized_argument [@key "eventInit"];
  } [@@deriving yojson { strict = false }]

type element_handle_hover_args_modifiers_item =
  [
  | `Alt
  | `Control
  | `Control_or_meta
  | `Meta
  | `Shift
  ]

let element_handle_hover_args_modifiers_item_to_yojson = function
  | `Alt -> `String "Alt"
  | `Control -> `String "Control"
  | `Control_or_meta -> `String "ControlOrMeta"
  | `Meta -> `String "Meta"
  | `Shift -> `String "Shift"

let element_handle_hover_args_modifiers_item_of_yojson = function
  | `String "Alt" -> Ok `Alt
  | `String "Control" -> Ok `Control
  | `String "ControlOrMeta" -> Ok `Control_or_meta
  | `String "Meta" -> Ok `Meta
  | `String "Shift" -> Ok `Shift
  | _ -> Error "Invalid enum element_handle_hover_args_modifiers_item"

type element_handle_tap_args_modifiers_item =
  [
  | `Alt
  | `Control
  | `Control_or_meta
  | `Meta
  | `Shift
  ]

let element_handle_tap_args_modifiers_item_to_yojson = function
  | `Alt -> `String "Alt"
  | `Control -> `String "Control"
  | `Control_or_meta -> `String "ControlOrMeta"
  | `Meta -> `String "Meta"
  | `Shift -> `String "Shift"

let element_handle_tap_args_modifiers_item_of_yojson = function
  | `String "Alt" -> Ok `Alt
  | `String "Control" -> Ok `Control
  | `String "ControlOrMeta" -> Ok `Control_or_meta
  | `String "Meta" -> Ok `Meta
  | `String "Shift" -> Ok `Shift
  | _ -> Error "Invalid enum element_handle_tap_args_modifiers_item"

type element_handle_tap_args =
  {
    force: bool option [@key "force"] [@default None];
    modifiers: element_handle_tap_args_modifiers_item list option [@key "modifiers"] [@default None];
    position: point option [@key "position"] [@default None];
    timeout: float [@key "timeout"];
    trial: bool option [@key "trial"] [@default None];
  } [@@deriving yojson { strict = false }]

type socks_support_socks_connected_args =
  {
    uid: string [@key "uid"];
    host: string [@key "host"];
    port: int [@key "port"];
  } [@@deriving yojson { strict = false }]

type context_options_record_video_size =
  {
    width: int [@key "width"];
    height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type js_handle_evaluate_expression_handle_returns =
  {
    handle: channel [@key "handle"];
  } [@@deriving yojson { strict = false }]

type android_device_launch_browser_args_http_credentials_send =
  [
  | `Always
  | `Unauthorized
  ]

let android_device_launch_browser_args_http_credentials_send_to_yojson = function
  | `Always -> `String "always"
  | `Unauthorized -> `String "unauthorized"

let android_device_launch_browser_args_http_credentials_send_of_yojson = function
  | `String "always" -> Ok `Always
  | `String "unauthorized" -> Ok `Unauthorized
  | _ -> Error "Invalid enum android_device_launch_browser_args_http_credentials_send"

type android_device_launch_browser_args_http_credentials =
  {
    username: string [@key "username"];
    password: string [@key "password"];
    origin: string option [@key "origin"] [@default None];
    send: android_device_launch_browser_args_http_credentials_send option [@key "send"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_request_finished_event =
  {
    request: channel [@key "request"];
    response: channel option [@key "response"] [@default None];
    response_end_timing: float [@key "responseEndTiming"];
    page: channel option [@key "page"] [@default None];
  } [@@deriving yojson { strict = false }]

type console_messages_filter =
  [
  | `All
  | `Since_navigation
  ]

let console_messages_filter_to_yojson = function
  | `All -> `String "all"
  | `Since_navigation -> `String "since-navigation"

let console_messages_filter_of_yojson = function
  | `String "all" -> Ok `All
  | `String "since-navigation" -> Ok `Since_navigation
  | _ -> Error "Invalid enum console_messages_filter"

type page_console_messages_args =
  {
    filter: console_messages_filter option [@key "filter"] [@default None];
  } [@@deriving yojson { strict = false }]

type security_details =
  {
    issuer: string option [@key "issuer"] [@default None];
    protocol: string option [@key "protocol"] [@default None];
    subject_name: string option [@key "subjectName"] [@default None];
    valid_from: float option [@key "validFrom"] [@default None];
    valid_to: float option [@key "validTo"] [@default None];
  } [@@deriving yojson { strict = false }]

type expected_text_value =
  {
    string: string option [@key "string"] [@default None];
    regex_source: string option [@key "regexSource"] [@default None];
    regex_flags: string option [@key "regexFlags"] [@default None];
    match_substring: bool option [@key "matchSubstring"] [@default None];
    ignore_case: bool option [@key "ignoreCase"] [@default None];
    normalize_white_space: bool option [@key "normalizeWhiteSpace"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_select_option_args_options_item =
  {
    value_or_label: string option [@key "valueOrLabel"] [@default None];
    value: string option [@key "value"] [@default None];
    label: string option [@key "label"] [@default None];
    index: int option [@key "index"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_new_context_for_reuse_args_record_video_show_actions =
  {
    duration: float option [@key "duration"] [@default None];
    position: browser_new_context_for_reuse_args_record_video_show_actions_position option [@key "position"] [@default None];
    font_size: int option [@key "fontSize"] [@default None];
  } [@@deriving yojson { strict = false }]

type tracing_tracing_start_chunk_args =
  {
    name: string option [@key "name"] [@default None];
    title: string option [@key "title"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_web_socket_route_event =
  {
    web_socket_route: channel [@key "webSocketRoute"];
  } [@@deriving yojson { strict = false }]

type browser_new_context_args_record_video_show_actions_position =
  [
  | `Top_left
  | `Top
  | `Top_right
  | `Bottom_left
  | `Bottom
  | `Bottom_right
  ]

let browser_new_context_args_record_video_show_actions_position_to_yojson = function
  | `Top_left -> `String "top-left"
  | `Top -> `String "top"
  | `Top_right -> `String "top-right"
  | `Bottom_left -> `String "bottom-left"
  | `Bottom -> `String "bottom"
  | `Bottom_right -> `String "bottom-right"

let browser_new_context_args_record_video_show_actions_position_of_yojson = function
  | `String "top-left" -> Ok `Top_left
  | `String "top" -> Ok `Top
  | `String "top-right" -> Ok `Top_right
  | `String "bottom-left" -> Ok `Bottom_left
  | `String "bottom" -> Ok `Bottom
  | `String "bottom-right" -> Ok `Bottom_right
  | _ -> Error "Invalid enum browser_new_context_args_record_video_show_actions_position"

type browser_context_register_selector_engine_args =
  {
    selector_engine: selector_engine [@key "selectorEngine"];
  } [@@deriving yojson { strict = false }]

type web_socket_route_close_server_event =
  {
    code: int option [@key "code"] [@default None];
    reason: string option [@key "reason"] [@default None];
    was_clean: bool [@key "wasClean"];
  } [@@deriving yojson { strict = false }]

type page_screenshot_args_scale =
  [
  | `Css
  | `Device
  ]

let page_screenshot_args_scale_to_yojson = function
  | `Css -> `String "css"
  | `Device -> `String "device"

let page_screenshot_args_scale_of_yojson = function
  | `String "css" -> Ok `Css
  | `String "device" -> Ok `Device
  | _ -> Error "Invalid enum page_screenshot_args_scale"

type page_mouse_move_args =
  {
    x: float [@key "x"];
    y: float [@key "y"];
    steps: int option [@key "steps"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_route_event =
  {
    route: channel [@key "route"];
  } [@@deriving yojson { strict = false }]

type frame_goto_args =
  {
    url: string [@key "url"];
    timeout: float [@key "timeout"];
    wait_until: lifecycle_event option [@key "waitUntil"] [@default None];
    referer: string option [@key "referer"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_evaluate_expression_args =
  {
    expression: string [@key "expression"];
    is_function: bool option [@key "isFunction"] [@default None];
    arg: serialized_argument [@key "arg"];
  } [@@deriving yojson { strict = false }]

type browser_new_context_args_proxy =
  {
    server: string [@key "server"];
    bypass: string option [@key "bypass"] [@default None];
    username: string option [@key "username"] [@default None];
    password: string option [@key "password"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_device_shell_returns =
  {
    result: string [@key "result"];
  } [@@deriving yojson { strict = false }]

type frame_inner_text_returns =
  {
    value: string [@key "value"];
  } [@@deriving yojson { strict = false }]

type browser_new_context_args_screen =
  {
    width: int [@key "width"];
    height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type root_initialize_returns =
  {
    playwright: channel [@key "playwright"];
  } [@@deriving yojson { strict = false }]

type json_pipe_closed_event =
  {
    reason: string option [@key "reason"] [@default None];
  } [@@deriving yojson { strict = false }]

type writable_stream_write_args =
  {
    binary: string [@key "binary"];
  } [@@deriving yojson { strict = false }]

type page_screencast_set_overlay_visible_args =
  {
    visible: bool [@key "visible"];
  } [@@deriving yojson { strict = false }]

type playwright_initializer =
  {
    chromium: channel [@key "chromium"];
    firefox: channel [@key "firefox"];
    webkit: channel [@key "webkit"];
    android: channel [@key "android"];
    utils: channel option [@key "utils"] [@default None];
    pre_launched_browser: channel option [@key "preLaunchedBrowser"] [@default None];
    pre_connected_android_device: channel option [@key "preConnectedAndroidDevice"] [@default None];
    socks_support: channel option [@key "socksSupport"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_hover_args =
  {
    force: bool option [@key "force"] [@default None];
    modifiers: element_handle_hover_args_modifiers_item list option [@key "modifiers"] [@default None];
    position: point option [@key "position"] [@default None];
    timeout: float [@key "timeout"];
    trial: bool option [@key "trial"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_device_pinch_open_args =
  {
    android_selector: android_selector [@key "androidSelector"];
    percent: float [@key "percent"];
    speed: float option [@key "speed"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type android_device_launch_browser_args_forced_colors =
  [
  | `Active
  | `None
  | `No_override
  ]

let android_device_launch_browser_args_forced_colors_to_yojson = function
  | `Active -> `String "active"
  | `None -> `String "none"
  | `No_override -> `String "no-override"

let android_device_launch_browser_args_forced_colors_of_yojson = function
  | `String "active" -> Ok `Active
  | `String "none" -> Ok `None
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum android_device_launch_browser_args_forced_colors"

type tracing_tracing_group_args_location =
  {
    file: string [@key "file"];
    line: int option [@key "line"] [@default None];
    column: int option [@key "column"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_stop_js_coverage_returns_entries_item =
  {
    url: string [@key "url"];
    script_id: string [@key "scriptId"];
    source: string option [@key "source"] [@default None];
    functions: page_stop_js_coverage_returns_entries_item_functions_item list [@key "functions"];
  } [@@deriving yojson { strict = false }]

type context_options_service_workers =
  [
  | `Allow
  | `Block
  ]

let context_options_service_workers_to_yojson = function
  | `Allow -> `String "allow"
  | `Block -> `String "block"

let context_options_service_workers_of_yojson = function
  | `String "allow" -> Ok `Allow
  | `String "block" -> Ok `Block
  | _ -> Error "Invalid enum context_options_service_workers"

type context_options_record_video_show_actions =
  {
    duration: float option [@key "duration"] [@default None];
    position: context_options_record_video_show_actions_position option [@key "position"] [@default None];
    font_size: int option [@key "fontSize"] [@default None];
  } [@@deriving yojson { strict = false }]

type context_options_record_video =
  {
    dir: string option [@key "dir"] [@default None];
    size: context_options_record_video_size option [@key "size"] [@default None];
    show_actions: context_options_record_video_show_actions option [@key "showActions"] [@default None];
  } [@@deriving yojson { strict = false }]

type context_options_contrast =
  [
  | `No_preference
  | `More
  | `No_override
  ]

let context_options_contrast_to_yojson = function
  | `No_preference -> `String "no-preference"
  | `More -> `String "more"
  | `No_override -> `String "no-override"

let context_options_contrast_of_yojson = function
  | `String "no-preference" -> Ok `No_preference
  | `String "more" -> Ok `More
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum context_options_contrast"

type context_options =
  {
    no_default_viewport: bool option [@key "noDefaultViewport"] [@default None];
    viewport: context_options_viewport option [@key "viewport"] [@default None];
    screen: context_options_screen option [@key "screen"] [@default None];
    ignore_https_errors: bool option [@key "ignoreHTTPSErrors"] [@default None];
    client_certificates: context_options_client_certificates_item list option [@key "clientCertificates"] [@default None];
    java_script_enabled: bool option [@key "javaScriptEnabled"] [@default None];
    bypass_csp: bool option [@key "bypassCSP"] [@default None];
    user_agent: string option [@key "userAgent"] [@default None];
    locale: string option [@key "locale"] [@default None];
    timezone_id: string option [@key "timezoneId"] [@default None];
    geolocation: context_options_geolocation option [@key "geolocation"] [@default None];
    permissions: string list option [@key "permissions"] [@default None];
    extra_http_headers: name_value list option [@key "extraHTTPHeaders"] [@default None];
    offline: bool option [@key "offline"] [@default None];
    http_credentials: context_options_http_credentials option [@key "httpCredentials"] [@default None];
    device_scale_factor: float option [@key "deviceScaleFactor"] [@default None];
    is_mobile: bool option [@key "isMobile"] [@default None];
    has_touch: bool option [@key "hasTouch"] [@default None];
    color_scheme: context_options_color_scheme option [@key "colorScheme"] [@default None];
    reduced_motion: context_options_reduced_motion option [@key "reducedMotion"] [@default None];
    forced_colors: context_options_forced_colors option [@key "forcedColors"] [@default None];
    accept_downloads: context_options_accept_downloads option [@key "acceptDownloads"] [@default None];
    contrast: context_options_contrast option [@key "contrast"] [@default None];
    base_url: string option [@key "baseURL"] [@default None];
    record_video: context_options_record_video option [@key "recordVideo"] [@default None];
    strict_selectors: bool option [@key "strictSelectors"] [@default None];
    service_workers: context_options_service_workers option [@key "serviceWorkers"] [@default None];
    selector_engines: selector_engine list option [@key "selectorEngines"] [@default None];
    test_id_attribute_name: string option [@key "testIdAttributeName"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_inner_text_returns =
  {
    value: string [@key "value"];
  } [@@deriving yojson { strict = false }]

type web_socket_initializer =
  {
    url: string [@key "url"];
  } [@@deriving yojson { strict = false }]

type frame_is_enabled_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type page_mouse_click_args =
  {
    x: float [@key "x"];
    y: float [@key "y"];
    delay: float option [@key "delay"] [@default None];
    button: page_mouse_click_args_button option [@key "button"] [@default None];
    click_count: int option [@key "clickCount"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_fill_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
    value: string [@key "value"];
    force: bool option [@key "force"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type socks_support_socks_end_args =
  {
    uid: string [@key "uid"];
  } [@@deriving yojson { strict = false }]

type frame_drop_args_payloads_item =
  {
    name: string [@key "name"];
    mime_type: string option [@key "mimeType"] [@default None];
    buffer: string [@key "buffer"];
  } [@@deriving yojson { strict = false }]

type frame_click_args_modifiers_item =
  [
  | `Alt
  | `Control
  | `Control_or_meta
  | `Meta
  | `Shift
  ]

let frame_click_args_modifiers_item_to_yojson = function
  | `Alt -> `String "Alt"
  | `Control -> `String "Control"
  | `Control_or_meta -> `String "ControlOrMeta"
  | `Meta -> `String "Meta"
  | `Shift -> `String "Shift"

let frame_click_args_modifiers_item_of_yojson = function
  | `String "Alt" -> Ok `Alt
  | `String "Control" -> Ok `Control
  | `String "ControlOrMeta" -> Ok `Control_or_meta
  | `String "Meta" -> Ok `Meta
  | `String "Shift" -> Ok `Shift
  | _ -> Error "Invalid enum frame_click_args_modifiers_item"

type socks_support_socks_data_args =
  {
    uid: string [@key "uid"];
    data: string [@key "data"];
  } [@@deriving yojson { strict = false }]

type frame_type_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
    text: string [@key "text"];
    delay: float option [@key "delay"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type console_message_location =
  {
    url: string [@key "url"];
    line_number: int [@key "lineNumber"];
    column_number: int [@key "columnNumber"];
  } [@@deriving yojson { strict = false }]

type console_message =
  {
    type_: string [@key "type"];
    text: string [@key "text"];
    args: channel list [@key "args"];
    location: console_message_location [@key "location"];
    timestamp: float [@key "timestamp"];
  } [@@deriving yojson { strict = false }]

type frame_dblclick_args_button =
  [
  | `Left
  | `Right
  | `Middle
  ]

let frame_dblclick_args_button_to_yojson = function
  | `Left -> `String "left"
  | `Right -> `String "right"
  | `Middle -> `String "middle"

let frame_dblclick_args_button_of_yojson = function
  | `String "left" -> Ok `Left
  | `String "right" -> Ok `Right
  | `String "middle" -> Ok `Middle
  | _ -> Error "Invalid enum frame_dblclick_args_button"

type element_handle_check_args =
  {
    force: bool option [@key "force"] [@default None];
    position: point option [@key "position"] [@default None];
    timeout: float [@key "timeout"];
    trial: bool option [@key "trial"] [@default None];
  } [@@deriving yojson { strict = false }]

type response_security_details_returns =
  {
    value: security_details option [@key "value"] [@default None];
  } [@@deriving yojson { strict = false }]

type debug_controller_inspect_requested_event =
  {
    selector: string [@key "selector"];
    locator: string [@key "locator"];
    aria_snapshot: string [@key "ariaSnapshot"];
  } [@@deriving yojson { strict = false }]

type browser_context_console_event =
  {
    type_: string [@key "type"];
    text: string [@key "text"];
    args: channel list [@key "args"];
    location: browser_context_console_event_location [@key "location"];
    timestamp: float [@key "timestamp"];
    page: channel option [@key "page"] [@default None];
    worker: channel option [@key "worker"] [@default None];
  } [@@deriving yojson { strict = false }]

type client_side_call_metadata =
  {
    id: int [@key "id"];
    stack: stack_frame list option [@key "stack"] [@default None];
  } [@@deriving yojson { strict = false }]

type local_utils_add_stack_to_tracing_no_reply_args =
  {
    call_data: client_side_call_metadata [@key "callData"];
  } [@@deriving yojson { strict = false }]

type frame_frame_element_returns =
  {
    element: channel [@key "element"];
  } [@@deriving yojson { strict = false }]

type browser_context_response_event =
  {
    response: channel [@key "response"];
    page: channel option [@key "page"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_pick_locator_returns =
  {
    selector: string [@key "selector"];
  } [@@deriving yojson { strict = false }]

type worker_console_event_location =
  {
    url: string [@key "url"];
    line_number: int [@key "lineNumber"];
    column_number: int [@key "columnNumber"];
  } [@@deriving yojson { strict = false }]

type android_device_scroll_args_direction =
  [
  | `Up
  | `Down
  | `Left
  | `Right
  ]

let android_device_scroll_args_direction_to_yojson = function
  | `Up -> `String "up"
  | `Down -> `String "down"
  | `Left -> `String "left"
  | `Right -> `String "right"

let android_device_scroll_args_direction_of_yojson = function
  | `String "up" -> Ok `Up
  | `String "down" -> Ok `Down
  | `String "left" -> Ok `Left
  | `String "right" -> Ok `Right
  | _ -> Error "Invalid enum android_device_scroll_args_direction"

type android_device_scroll_args =
  {
    android_selector: android_selector [@key "androidSelector"];
    direction: android_device_scroll_args_direction [@key "direction"];
    percent: float [@key "percent"];
    speed: float option [@key "speed"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type page_keyboard_down_args =
  {
    key: string [@key "key"];
  } [@@deriving yojson { strict = false }]

type browser_default_user_agent_for_test_returns =
  {
    user_agent: string [@key "userAgent"];
  } [@@deriving yojson { strict = false }]

type android_device_input_drag_args =
  {
    from: point [@key "from"];
    to_: point [@key "to"];
    steps: int [@key "steps"];
  } [@@deriving yojson { strict = false }]

type stream_read_returns =
  {
    binary: string [@key "binary"];
  } [@@deriving yojson { strict = false }]

type browser_context_set_web_socket_interception_patterns_args_patterns_item =
  {
    glob: string option [@key "glob"] [@default None];
    regex_source: string option [@key "regexSource"] [@default None];
    regex_flags: string option [@key "regexFlags"] [@default None];
    url_pattern: url_pattern option [@key "urlPattern"] [@default None];
  } [@@deriving yojson { strict = false }]

type local_utils_har_lookup_args =
  {
    har_id: string [@key "harId"];
    url: string [@key "url"];
    method_: string [@key "method"];
    headers: name_value list [@key "headers"];
    post_data: string option [@key "postData"] [@default None];
    is_navigation_request: bool [@key "isNavigationRequest"];
  } [@@deriving yojson { strict = false }]

type common_screenshot_options_animations =
  [
  | `Disabled
  | `Allow
  ]

let common_screenshot_options_animations_to_yojson = function
  | `Disabled -> `String "disabled"
  | `Allow -> `String "allow"

let common_screenshot_options_animations_of_yojson = function
  | `String "disabled" -> Ok `Disabled
  | `String "allow" -> Ok `Allow
  | _ -> Error "Invalid enum common_screenshot_options_animations"

type frame_hide_highlight_args =
  {
    selector: string [@key "selector"];
  } [@@deriving yojson { strict = false }]

type frame_get_attribute_returns =
  {
    value: string option [@key "value"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_get_attribute_returns =
  {
    value: string option [@key "value"] [@default None];
  } [@@deriving yojson { strict = false }]

type local_utils_glob_to_regex_args =
  {
    glob: string [@key "glob"];
    base_url: string option [@key "baseURL"] [@default None];
    web_socket_url: bool option [@key "webSocketUrl"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_inner_htm_l_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type frame_aria_ref_returns =
  {
    ref: string option [@key "ref"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_cookies_args =
  {
    urls: string list [@key "urls"];
  } [@@deriving yojson { strict = false }]

type frame_select_option_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
    elements: channel list option [@key "elements"] [@default None];
    options: frame_select_option_args_options_item list option [@key "options"] [@default None];
    force: bool option [@key "force"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type page_add_init_script_returns =
  {
    disposable: channel [@key "disposable"];
  } [@@deriving yojson { strict = false }]

type page_add_init_script_args =
  {
    source: string [@key "source"];
  } [@@deriving yojson { strict = false }]

type android_device_info_args =
  {
    android_selector: android_selector [@key "androidSelector"];
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
  ]

let page_update_subscription_args_event_to_yojson = function
  | `Console -> `String "console"
  | `Dialog -> `String "dialog"
  | `File_chooser -> `String "fileChooser"
  | `Request -> `String "request"
  | `Response -> `String "response"
  | `Request_finished -> `String "requestFinished"
  | `Request_failed -> `String "requestFailed"

let page_update_subscription_args_event_of_yojson = function
  | `String "console" -> Ok `Console
  | `String "dialog" -> Ok `Dialog
  | `String "fileChooser" -> Ok `File_chooser
  | `String "request" -> Ok `Request
  | `String "response" -> Ok `Response
  | `String "requestFinished" -> Ok `Request_finished
  | `String "requestFailed" -> Ok `Request_failed
  | _ -> Error "Invalid enum page_update_subscription_args_event"

type page_update_subscription_args =
  {
    event: page_update_subscription_args_event [@key "event"];
    enabled: bool [@key "enabled"];
  } [@@deriving yojson { strict = false }]

type cdp_session_send_returns =
  {
    result: json [@key "result"];
  } [@@deriving yojson { strict = false }]

type request_raw_request_headers_returns =
  {
    headers: name_value list [@key "headers"];
  } [@@deriving yojson { strict = false }]

type page_start_css_coverage_args =
  {
    reset_on_navigation: bool option [@key "resetOnNavigation"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_register_locator_handler_returns =
  {
    uid: int [@key "uid"];
  } [@@deriving yojson { strict = false }]

type frame_initializer =
  {
    url: string [@key "url"];
    name: string [@key "name"];
    parent_frame: channel option [@key "parentFrame"] [@default None];
    load_states: lifecycle_event list [@key "loadStates"];
  } [@@deriving yojson { strict = false }]

type page_viewport_size_changed_event =
  {
    viewport_size: page_viewport_size_changed_event_viewport_size option [@key "viewportSize"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_event =
  {
    context: channel [@key "context"];
  } [@@deriving yojson { strict = false }]

type element_handle_text_content_returns =
  {
    value: string option [@key "value"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_new_context_for_reuse_args_screen =
  {
    width: int [@key "width"];
    height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type api_request_context_storage_state_args =
  {
    indexed_db: bool option [@key "indexedDB"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_device_launch_browser_args_proxy =
  {
    server: string [@key "server"];
    bypass: string option [@key "bypass"] [@default None];
    username: string option [@key "username"] [@default None];
    password: string option [@key "password"] [@default None];
  } [@@deriving yojson { strict = false }]

type event_target_wait_for_event_info_args_info_phase =
  [
  | `Before
  | `After
  | `Log
  ]

let event_target_wait_for_event_info_args_info_phase_to_yojson = function
  | `Before -> `String "before"
  | `After -> `String "after"
  | `Log -> `String "log"

let event_target_wait_for_event_info_args_info_phase_of_yojson = function
  | `String "before" -> Ok `Before
  | `String "after" -> Ok `After
  | `String "log" -> Ok `Log
  | _ -> Error "Invalid enum event_target_wait_for_event_info_args_info_phase"

type response_body_returns =
  {
    binary: string [@key "binary"];
  } [@@deriving yojson { strict = false }]

type frame_query_selector_all_args =
  {
    selector: string [@key "selector"];
  } [@@deriving yojson { strict = false }]

type android_devices_returns =
  {
    devices: channel list [@key "devices"];
  } [@@deriving yojson { strict = false }]

type page_initializer =
  {
    main_frame: channel [@key "mainFrame"];
    viewport_size: page_initializer_viewport_size option [@key "viewportSize"] [@default None];
    is_closed: bool [@key "isClosed"];
    opener: channel option [@key "opener"] [@default None];
    video: channel option [@key "video"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_new_cdp_session_args =
  {
    page: channel option [@key "page"] [@default None];
    frame: channel option [@key "frame"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_set_viewport_size_args_viewport_size =
  {
    width: int [@key "width"];
    height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type page_set_viewport_size_args =
  {
    viewport_size: page_set_viewport_size_args_viewport_size [@key "viewportSize"];
  } [@@deriving yojson { strict = false }]

type request_sizes =
  {
    request_body_size: int [@key "requestBodySize"];
    request_headers_size: int [@key "requestHeadersSize"];
    response_body_size: int [@key "responseBodySize"];
    response_headers_size: int [@key "responseHeadersSize"];
  } [@@deriving yojson { strict = false }]

type response_sizes_returns =
  {
    sizes: request_sizes [@key "sizes"];
  } [@@deriving yojson { strict = false }]

type frame_is_visible_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
  } [@@deriving yojson { strict = false }]

type debug_controller_set_recorder_mode_args_mode =
  [
  | `Inspecting
  | `Recording
  | `None
  ]

let debug_controller_set_recorder_mode_args_mode_to_yojson = function
  | `Inspecting -> `String "inspecting"
  | `Recording -> `String "recording"
  | `None -> `String "none"

let debug_controller_set_recorder_mode_args_mode_of_yojson = function
  | `String "inspecting" -> Ok `Inspecting
  | `String "recording" -> Ok `Recording
  | `String "none" -> Ok `None
  | _ -> Error "Invalid enum debug_controller_set_recorder_mode_args_mode"

type debug_controller_set_recorder_mode_args =
  {
    mode: debug_controller_set_recorder_mode_args_mode [@key "mode"];
    test_id_attribute_name: string option [@key "testIdAttributeName"] [@default None];
    generate_auto_expect: bool option [@key "generateAutoExpect"] [@default None];
  } [@@deriving yojson { strict = false }]

type debug_controller_set_mode_requested_event =
  {
    mode: string [@key "mode"];
  } [@@deriving yojson { strict = false }]

type page_stop_js_coverage_returns =
  {
    entries: page_stop_js_coverage_returns_entries_item list [@key "entries"];
  } [@@deriving yojson { strict = false }]

type web_socket_route_send_to_page_args =
  {
    message: string [@key "message"];
    is_base64: bool [@key "isBase64"];
  } [@@deriving yojson { strict = false }]

type browser_context_set_extra_http_headers_args =
  {
    headers: name_value list [@key "headers"];
  } [@@deriving yojson { strict = false }]

type element_handle_is_enabled_returns =
  {
    value: bool [@key "value"];
  } [@@deriving yojson { strict = false }]

type browser_new_context_for_reuse_args_color_scheme =
  [
  | `Dark
  | `Light
  | `No_preference
  | `No_override
  ]

let browser_new_context_for_reuse_args_color_scheme_to_yojson = function
  | `Dark -> `String "dark"
  | `Light -> `String "light"
  | `No_preference -> `String "no-preference"
  | `No_override -> `String "no-override"

let browser_new_context_for_reuse_args_color_scheme_of_yojson = function
  | `String "dark" -> Ok `Dark
  | `String "light" -> Ok `Light
  | `String "no-preference" -> Ok `No_preference
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum browser_new_context_for_reuse_args_color_scheme"

type page_pdf_returns =
  {
    pdf: string [@key "pdf"];
  } [@@deriving yojson { strict = false }]

type frame_is_enabled_returns =
  {
    value: bool [@key "value"];
  } [@@deriving yojson { strict = false }]

type browser_context_set_web_socket_interception_patterns_args =
  {
    patterns: browser_context_set_web_socket_interception_patterns_args_patterns_item list [@key "patterns"];
  } [@@deriving yojson { strict = false }]

type browser_start_tracing_args =
  {
    page: channel option [@key "page"] [@default None];
    screenshots: bool option [@key "screenshots"] [@default None];
    categories: string list option [@key "categories"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_web_view =
  {
    pid: int [@key "pid"];
    pkg: string [@key "pkg"];
    socket_name: string [@key "socketName"];
  } [@@deriving yojson { strict = false }]

type android_device_web_view_added_event =
  {
    web_view: android_web_view [@key "webView"];
  } [@@deriving yojson { strict = false }]

type browser_context_clock_set_fixed_time_args =
  {
    time_number: float option [@key "timeNumber"] [@default None];
    time_string: string option [@key "timeString"] [@default None];
  } [@@deriving yojson { strict = false }]

type event_target_wait_for_event_info_args_info =
  {
    wait_id: string [@key "waitId"];
    phase: event_target_wait_for_event_info_args_info_phase [@key "phase"];
    event: string option [@key "event"] [@default None];
    message: string option [@key "message"] [@default None];
    error: string option [@key "error"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_is_checked_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type binding_call_resolve_args =
  {
    result: serialized_argument [@key "result"];
  } [@@deriving yojson { strict = false }]

type js_handle_json_value_returns =
  {
    value: serialized_value [@key "value"];
  } [@@deriving yojson { strict = false }]

type browser_new_context_args_reduced_motion =
  [
  | `Reduce
  | `No_preference
  | `No_override
  ]

let browser_new_context_args_reduced_motion_to_yojson = function
  | `Reduce -> `String "reduce"
  | `No_preference -> `String "no-preference"
  | `No_override -> `String "no-override"

let browser_new_context_args_reduced_motion_of_yojson = function
  | `String "reduce" -> Ok `Reduce
  | `String "no-preference" -> Ok `No_preference
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum browser_new_context_args_reduced_motion"

type element_handle_fill_args =
  {
    value: string [@key "value"];
    force: bool option [@key "force"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type browser_context_expose_binding_args =
  {
    name: string [@key "name"];
  } [@@deriving yojson { strict = false }]

type frame_dispatch_event_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
    type_: string [@key "type"];
    event_init: serialized_argument [@key "eventInit"];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type frame_expect_returns_received =
  {
    value: serialized_value option [@key "value"] [@default None];
    aria_snapshot: string option [@key "ariaSnapshot"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_expect_returns =
  {
    matches: bool [@key "matches"];
    received: frame_expect_returns_received option [@key "received"] [@default None];
    timed_out: bool option [@key "timedOut"] [@default None];
    error_message: string option [@key "errorMessage"] [@default None];
    log: string list option [@key "log"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_page_errors_args =
  {
    filter: console_messages_filter option [@key "filter"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_new_context_args_service_workers =
  [
  | `Allow
  | `Block
  ]

let browser_new_context_args_service_workers_to_yojson = function
  | `Allow -> `String "allow"
  | `Block -> `String "block"

let browser_new_context_args_service_workers_of_yojson = function
  | `String "allow" -> Ok `Allow
  | `String "block" -> Ok `Block
  | _ -> Error "Invalid enum browser_new_context_args_service_workers"

type request_initializer =
  {
    frame: channel option [@key "frame"] [@default None];
    service_worker: channel option [@key "serviceWorker"] [@default None];
    url: string [@key "url"];
    resource_type: string [@key "resourceType"];
    method_: string [@key "method"];
    post_data: string option [@key "postData"] [@default None];
    headers: name_value list [@key "headers"];
    is_navigation_request: bool [@key "isNavigationRequest"];
    redirected_from: channel option [@key "redirectedFrom"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_set_web_socket_interception_patterns_args_patterns_item =
  {
    glob: string option [@key "glob"] [@default None];
    regex_source: string option [@key "regexSource"] [@default None];
    regex_flags: string option [@key "regexFlags"] [@default None];
    url_pattern: url_pattern option [@key "urlPattern"] [@default None];
  } [@@deriving yojson { strict = false }]

type js_handle_evaluate_expression_returns =
  {
    value: serialized_value [@key "value"];
  } [@@deriving yojson { strict = false }]

type browser_new_context_for_reuse_args_record_video_size =
  {
    width: int [@key "width"];
    height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type browser_new_context_for_reuse_args_record_video =
  {
    dir: string option [@key "dir"] [@default None];
    size: browser_new_context_for_reuse_args_record_video_size option [@key "size"] [@default None];
    show_actions: browser_new_context_for_reuse_args_record_video_show_actions option [@key "showActions"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_new_context_for_reuse_args_contrast =
  [
  | `No_preference
  | `More
  | `No_override
  ]

let browser_new_context_for_reuse_args_contrast_to_yojson = function
  | `No_preference -> `String "no-preference"
  | `More -> `String "more"
  | `No_override -> `String "no-override"

let browser_new_context_for_reuse_args_contrast_of_yojson = function
  | `String "no-preference" -> Ok `No_preference
  | `String "more" -> Ok `More
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum browser_new_context_for_reuse_args_contrast"

type browser_new_context_for_reuse_args_forced_colors =
  [
  | `Active
  | `None
  | `No_override
  ]

let browser_new_context_for_reuse_args_forced_colors_to_yojson = function
  | `Active -> `String "active"
  | `None -> `String "none"
  | `No_override -> `String "no-override"

let browser_new_context_for_reuse_args_forced_colors_of_yojson = function
  | `String "active" -> Ok `Active
  | `String "none" -> Ok `None
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum browser_new_context_for_reuse_args_forced_colors"

type browser_new_context_for_reuse_args_geolocation =
  {
    longitude: float [@key "longitude"];
    latitude: float [@key "latitude"];
    accuracy: float option [@key "accuracy"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_new_context_for_reuse_args_client_certificates_item =
  {
    origin: string [@key "origin"];
    cert: string option [@key "cert"] [@default None];
    key: string option [@key "key"] [@default None];
    passphrase: string option [@key "passphrase"] [@default None];
    pfx: string option [@key "pfx"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_new_context_for_reuse_args =
  {
    no_default_viewport: bool option [@key "noDefaultViewport"] [@default None];
    viewport: browser_new_context_for_reuse_args_viewport option [@key "viewport"] [@default None];
    screen: browser_new_context_for_reuse_args_screen option [@key "screen"] [@default None];
    ignore_https_errors: bool option [@key "ignoreHTTPSErrors"] [@default None];
    client_certificates: browser_new_context_for_reuse_args_client_certificates_item list option [@key "clientCertificates"] [@default None];
    java_script_enabled: bool option [@key "javaScriptEnabled"] [@default None];
    bypass_csp: bool option [@key "bypassCSP"] [@default None];
    user_agent: string option [@key "userAgent"] [@default None];
    locale: string option [@key "locale"] [@default None];
    timezone_id: string option [@key "timezoneId"] [@default None];
    geolocation: browser_new_context_for_reuse_args_geolocation option [@key "geolocation"] [@default None];
    permissions: string list option [@key "permissions"] [@default None];
    extra_http_headers: name_value list option [@key "extraHTTPHeaders"] [@default None];
    offline: bool option [@key "offline"] [@default None];
    http_credentials: browser_new_context_for_reuse_args_http_credentials option [@key "httpCredentials"] [@default None];
    device_scale_factor: float option [@key "deviceScaleFactor"] [@default None];
    is_mobile: bool option [@key "isMobile"] [@default None];
    has_touch: bool option [@key "hasTouch"] [@default None];
    color_scheme: browser_new_context_for_reuse_args_color_scheme option [@key "colorScheme"] [@default None];
    reduced_motion: browser_new_context_for_reuse_args_reduced_motion option [@key "reducedMotion"] [@default None];
    forced_colors: browser_new_context_for_reuse_args_forced_colors option [@key "forcedColors"] [@default None];
    accept_downloads: browser_new_context_for_reuse_args_accept_downloads option [@key "acceptDownloads"] [@default None];
    contrast: browser_new_context_for_reuse_args_contrast option [@key "contrast"] [@default None];
    base_url: string option [@key "baseURL"] [@default None];
    record_video: browser_new_context_for_reuse_args_record_video option [@key "recordVideo"] [@default None];
    strict_selectors: bool option [@key "strictSelectors"] [@default None];
    service_workers: browser_new_context_for_reuse_args_service_workers option [@key "serviceWorkers"] [@default None];
    selector_engines: selector_engine list option [@key "selectorEngines"] [@default None];
    test_id_attribute_name: string option [@key "testIdAttributeName"] [@default None];
    proxy: browser_new_context_for_reuse_args_proxy option [@key "proxy"] [@default None];
    storage_state: browser_new_context_for_reuse_args_storage_state option [@key "storageState"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_wait_for_selector_args_state =
  [
  | `Attached
  | `Detached
  | `Visible
  | `Hidden
  ]

let element_handle_wait_for_selector_args_state_to_yojson = function
  | `Attached -> `String "attached"
  | `Detached -> `String "detached"
  | `Visible -> `String "visible"
  | `Hidden -> `String "hidden"

let element_handle_wait_for_selector_args_state_of_yojson = function
  | `String "attached" -> Ok `Attached
  | `String "detached" -> Ok `Detached
  | `String "visible" -> Ok `Visible
  | `String "hidden" -> Ok `Hidden
  | _ -> Error "Invalid enum element_handle_wait_for_selector_args_state"

type api_request_context_fetch_response_body_returns =
  {
    binary: string option [@key "binary"] [@default None];
  } [@@deriving yojson { strict = false }]

type local_utils_glob_to_regex_returns =
  {
    regex: string [@key "regex"];
  } [@@deriving yojson { strict = false }]

type element_handle_query_selector_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_service_worker_event =
  {
    worker: channel [@key "worker"];
  } [@@deriving yojson { strict = false }]

type browser_context_update_subscription_args_event =
  [
  | `Console
  | `Dialog
  | `Request
  | `Response
  | `Request_finished
  | `Request_failed
  ]

let browser_context_update_subscription_args_event_to_yojson = function
  | `Console -> `String "console"
  | `Dialog -> `String "dialog"
  | `Request -> `String "request"
  | `Response -> `String "response"
  | `Request_finished -> `String "requestFinished"
  | `Request_failed -> `String "requestFailed"

let browser_context_update_subscription_args_event_of_yojson = function
  | `String "console" -> Ok `Console
  | `String "dialog" -> Ok `Dialog
  | `String "request" -> Ok `Request
  | `String "response" -> Ok `Response
  | `String "requestFinished" -> Ok `Request_finished
  | `String "requestFailed" -> Ok `Request_failed
  | _ -> Error "Invalid enum browser_context_update_subscription_args_event"

type browser_context_update_subscription_args =
  {
    event: browser_context_update_subscription_args_event [@key "event"];
    enabled: bool [@key "enabled"];
  } [@@deriving yojson { strict = false }]

type local_utils_connect_returns =
  {
    pipe: channel [@key "pipe"];
    headers: name_value list [@key "headers"];
  } [@@deriving yojson { strict = false }]

type page_start_js_coverage_args =
  {
    reset_on_navigation: bool option [@key "resetOnNavigation"] [@default None];
    report_anonymous_scripts: bool option [@key "reportAnonymousScripts"] [@default None];
  } [@@deriving yojson { strict = false }]

type cdp_session_event_event =
  {
    method_: string [@key "method"];
    params: json option [@key "params"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_select_text_args =
  {
    force: bool option [@key "force"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type frame_aria_snapshot_args_mode =
  [
  | `Ai
  | `Default
  ]

let frame_aria_snapshot_args_mode_to_yojson = function
  | `Ai -> `String "ai"
  | `Default -> `String "default"

let frame_aria_snapshot_args_mode_of_yojson = function
  | `String "ai" -> Ok `Ai
  | `String "default" -> Ok `Default
  | _ -> Error "Invalid enum frame_aria_snapshot_args_mode"

type browser_type_connect_to_worker_args =
  {
    endpoint: string [@key "endpoint"];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type browser_type_connect_over_cd_p_args =
  {
    endpoint_url: string [@key "endpointURL"];
    headers: name_value list option [@key "headers"] [@default None];
    slow_mo: float option [@key "slowMo"] [@default None];
    timeout: float [@key "timeout"];
    is_local: bool option [@key "isLocal"] [@default None];
    no_defaults: bool option [@key "noDefaults"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_type_launch_args =
  {
    channel: string option [@key "channel"] [@default None];
    executable_path: string option [@key "executablePath"] [@default None];
    args: string list option [@key "args"] [@default None];
    ignore_all_default_args: bool option [@key "ignoreAllDefaultArgs"] [@default None];
    ignore_default_args: string list option [@key "ignoreDefaultArgs"] [@default None];
    handle_sigint: bool option [@key "handleSIGINT"] [@default None];
    handle_sigterm: bool option [@key "handleSIGTERM"] [@default None];
    handle_sighup: bool option [@key "handleSIGHUP"] [@default None];
    timeout: float [@key "timeout"];
    env: name_value list option [@key "env"] [@default None];
    headless: bool option [@key "headless"] [@default None];
    proxy: browser_type_launch_args_proxy option [@key "proxy"] [@default None];
    downloads_path: string option [@key "downloadsPath"] [@default None];
    traces_dir: string option [@key "tracesDir"] [@default None];
    artifacts_dir: string option [@key "artifactsDir"] [@default None];
    chromium_sandbox: bool option [@key "chromiumSandbox"] [@default None];
    firefox_user_prefs: json option [@key "firefoxUserPrefs"] [@default None];
    cdp_port: int option [@key "cdpPort"] [@default None];
    slow_mo: float option [@key "slowMo"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_uncheck_args =
  {
    force: bool option [@key "force"] [@default None];
    position: point option [@key "position"] [@default None];
    timeout: float [@key "timeout"];
    trial: bool option [@key "trial"] [@default None];
  } [@@deriving yojson { strict = false }]

type tracing_tracing_stop_chunk_returns =
  {
    artifact: channel option [@key "artifact"] [@default None];
    entries: name_value list option [@key "entries"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_set_geolocation_args =
  {
    geolocation: browser_context_set_geolocation_args_geolocation option [@key "geolocation"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_is_visible_returns =
  {
    value: bool [@key "value"];
  } [@@deriving yojson { strict = false }]

type js_handle_evaluate_expression_args =
  {
    expression: string [@key "expression"];
    is_function: bool option [@key "isFunction"] [@default None];
    arg: serialized_argument [@key "arg"];
  } [@@deriving yojson { strict = false }]

type browser_context_page_error_event =
  {
    error: serialized_error [@key "error"];
    page: channel [@key "page"];
    location: browser_context_page_error_event_location [@key "location"];
  } [@@deriving yojson { strict = false }]

type js_handle_get_property_args =
  {
    name: string [@key "name"];
  } [@@deriving yojson { strict = false }]

type frame_is_hidden_returns =
  {
    value: bool [@key "value"];
  } [@@deriving yojson { strict = false }]

type event_target_wait_for_event_info_args =
  {
    info: event_target_wait_for_event_info_args_info [@key "info"];
  } [@@deriving yojson { strict = false }]

type frame_query_selector_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_touchscreen_tap_args =
  {
    x: float [@key "x"];
    y: float [@key "y"];
  } [@@deriving yojson { strict = false }]

type frame_is_disabled_returns =
  {
    value: bool [@key "value"];
  } [@@deriving yojson { strict = false }]

type frame_wait_for_function_returns =
  {
    handle: channel [@key "handle"];
  } [@@deriving yojson { strict = false }]

type web_socket_frame_received_event =
  {
    opcode: int [@key "opcode"];
    data: string [@key "data"];
  } [@@deriving yojson { strict = false }]

type frame_query_selector_all_returns =
  {
    elements: channel list [@key "elements"];
  } [@@deriving yojson { strict = false }]

type page_screenshot_args_animations =
  [
  | `Disabled
  | `Allow
  ]

let page_screenshot_args_animations_to_yojson = function
  | `Disabled -> `String "disabled"
  | `Allow -> `String "allow"

let page_screenshot_args_animations_of_yojson = function
  | `String "disabled" -> Ok `Disabled
  | `String "allow" -> Ok `Allow
  | _ -> Error "Invalid enum page_screenshot_args_animations"

type browser_type_initializer =
  {
    executable_path: string [@key "executablePath"];
    name: string [@key "name"];
  } [@@deriving yojson { strict = false }]

type element_handle_is_disabled_returns =
  {
    value: bool [@key "value"];
  } [@@deriving yojson { strict = false }]

type browser_context_grant_permissions_args =
  {
    permissions: string list [@key "permissions"];
    origin: string option [@key "origin"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_input_value_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type record_har_options_content =
  [
  | `Embed
  | `Attach
  | `Omit
  ]

let record_har_options_content_to_yojson = function
  | `Embed -> `String "embed"
  | `Attach -> `String "attach"
  | `Omit -> `String "omit"

let record_har_options_content_of_yojson = function
  | `String "embed" -> Ok `Embed
  | `String "attach" -> Ok `Attach
  | `String "omit" -> Ok `Omit
  | _ -> Error "Invalid enum record_har_options_content"

type browser_new_context_args_color_scheme =
  [
  | `Dark
  | `Light
  | `No_preference
  | `No_override
  ]

let browser_new_context_args_color_scheme_to_yojson = function
  | `Dark -> `String "dark"
  | `Light -> `String "light"
  | `No_preference -> `String "no-preference"
  | `No_override -> `String "no-override"

let browser_new_context_args_color_scheme_of_yojson = function
  | `String "dark" -> Ok `Dark
  | `String "light" -> Ok `Light
  | `String "no-preference" -> Ok `No_preference
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum browser_new_context_args_color_scheme"

type show_actions_options_position =
  [
  | `Top_left
  | `Top
  | `Top_right
  | `Bottom_left
  | `Bottom
  | `Bottom_right
  ]

let show_actions_options_position_to_yojson = function
  | `Top_left -> `String "top-left"
  | `Top -> `String "top"
  | `Top_right -> `String "top-right"
  | `Bottom_left -> `String "bottom-left"
  | `Bottom -> `String "bottom"
  | `Bottom_right -> `String "bottom-right"

let show_actions_options_position_of_yojson = function
  | `String "top-left" -> Ok `Top_left
  | `String "top" -> Ok `Top
  | `String "top-right" -> Ok `Top_right
  | `String "bottom-left" -> Ok `Bottom_left
  | `String "bottom" -> Ok `Bottom
  | `String "bottom-right" -> Ok `Bottom_right
  | _ -> Error "Invalid enum show_actions_options_position"

type show_actions_options =
  {
    duration: float option [@key "duration"] [@default None];
    position: show_actions_options_position option [@key "position"] [@default None];
    font_size: int option [@key "fontSize"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_content_returns =
  {
    value: string [@key "value"];
  } [@@deriving yojson { strict = false }]

type frame_loadstate_event =
  {
    add: lifecycle_event option [@key "add"] [@default None];
    remove: lifecycle_event option [@key "remove"] [@default None];
  } [@@deriving yojson { strict = false }]

type js_handle_get_property_returns =
  {
    handle: channel [@key "handle"];
  } [@@deriving yojson { strict = false }]

type page_set_web_socket_interception_patterns_args =
  {
    patterns: page_set_web_socket_interception_patterns_args_patterns_item list [@key "patterns"];
  } [@@deriving yojson { strict = false }]

type debugger_run_to_args =
  {
    location: debugger_run_to_args_location [@key "location"];
  } [@@deriving yojson { strict = false }]

type browser_new_context_for_reuse_returns =
  {
    context: channel [@key "context"];
  } [@@deriving yojson { strict = false }]

type element_handle_scroll_into_view_if_needed_args =
  {
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type frame_tap_args_modifiers_item =
  [
  | `Alt
  | `Control
  | `Control_or_meta
  | `Meta
  | `Shift
  ]

let frame_tap_args_modifiers_item_to_yojson = function
  | `Alt -> `String "Alt"
  | `Control -> `String "Control"
  | `Control_or_meta -> `String "ControlOrMeta"
  | `Meta -> `String "Meta"
  | `Shift -> `String "Shift"

let frame_tap_args_modifiers_item_of_yojson = function
  | `String "Alt" -> Ok `Alt
  | `String "Control" -> Ok `Control
  | `String "ControlOrMeta" -> Ok `Control_or_meta
  | `String "Meta" -> Ok `Meta
  | `String "Shift" -> Ok `Shift
  | _ -> Error "Invalid enum frame_tap_args_modifiers_item"

type page_keyboard_press_args =
  {
    key: string [@key "key"];
    delay: float option [@key "delay"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_set_input_files_args =
  {
    payloads: element_handle_set_input_files_args_payloads_item list option [@key "payloads"] [@default None];
    local_directory: string option [@key "localDirectory"] [@default None];
    directory_stream: channel option [@key "directoryStream"] [@default None];
    local_paths: string list option [@key "localPaths"] [@default None];
    streams: channel list option [@key "streams"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type element_handle_eval_on_selector_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
    expression: string [@key "expression"];
    is_function: bool option [@key "isFunction"] [@default None];
    arg: serialized_argument [@key "arg"];
  } [@@deriving yojson { strict = false }]

type worker_console_event =
  {
    type_: string [@key "type"];
    text: string [@key "text"];
    args: channel list [@key "args"];
    location: worker_console_event_location [@key "location"];
    timestamp: float [@key "timestamp"];
  } [@@deriving yojson { strict = false }]

type page_screenshot_args_type =
  [
  | `Png
  | `Jpeg
  ]

let page_screenshot_args_type_to_yojson = function
  | `Png -> `String "png"
  | `Jpeg -> `String "jpeg"

let page_screenshot_args_type_of_yojson = function
  | `String "png" -> Ok `Png
  | `String "jpeg" -> Ok `Jpeg
  | _ -> Error "Invalid enum page_screenshot_args_type"

type browser_context_clear_cookies_args =
  {
    name: string option [@key "name"] [@default None];
    name_regex_source: string option [@key "nameRegexSource"] [@default None];
    name_regex_flags: string option [@key "nameRegexFlags"] [@default None];
    domain: string option [@key "domain"] [@default None];
    domain_regex_source: string option [@key "domainRegexSource"] [@default None];
    domain_regex_flags: string option [@key "domainRegexFlags"] [@default None];
    path: string option [@key "path"] [@default None];
    path_regex_source: string option [@key "pathRegexSource"] [@default None];
    path_regex_flags: string option [@key "pathRegexFlags"] [@default None];
  } [@@deriving yojson { strict = false }]

type recorder_source_highlight_item =
  {
    line: int [@key "line"];
    type_: string [@key "type"];
  } [@@deriving yojson { strict = false }]

type page_screenshot_args_mask_item =
  {
    frame: channel [@key "frame"];
    selector: string [@key "selector"];
  } [@@deriving yojson { strict = false }]

type page_screenshot_args_caret =
  [
  | `Hide
  | `Initial
  ]

let page_screenshot_args_caret_to_yojson = function
  | `Hide -> `String "hide"
  | `Initial -> `String "initial"

let page_screenshot_args_caret_of_yojson = function
  | `String "hide" -> Ok `Hide
  | `String "initial" -> Ok `Initial
  | _ -> Error "Invalid enum page_screenshot_args_caret"

type page_screenshot_args =
  {
    timeout: float [@key "timeout"];
    type_: page_screenshot_args_type option [@key "type"] [@default None];
    quality: int option [@key "quality"] [@default None];
    full_page: bool option [@key "fullPage"] [@default None];
    clip: rect option [@key "clip"] [@default None];
    omit_background: bool option [@key "omitBackground"] [@default None];
    caret: page_screenshot_args_caret option [@key "caret"] [@default None];
    animations: page_screenshot_args_animations option [@key "animations"] [@default None];
    scale: page_screenshot_args_scale option [@key "scale"] [@default None];
    mask: page_screenshot_args_mask_item list option [@key "mask"] [@default None];
    mask_color: string option [@key "maskColor"] [@default None];
    style: string option [@key "style"] [@default None];
  } [@@deriving yojson { strict = false }]

type artifact_stream_returns =
  {
    stream: channel [@key "stream"];
  } [@@deriving yojson { strict = false }]

type page_expose_binding_returns =
  {
    disposable: channel [@key "disposable"];
  } [@@deriving yojson { strict = false }]

type browser_context_clock_pause_at_args =
  {
    time_number: float option [@key "timeNumber"] [@default None];
    time_string: string option [@key "timeString"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_set_input_files_args_payloads_item =
  {
    name: string [@key "name"];
    mime_type: string option [@key "mimeType"] [@default None];
    buffer: string [@key "buffer"];
  } [@@deriving yojson { strict = false }]

type frame_set_input_files_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
    payloads: frame_set_input_files_args_payloads_item list option [@key "payloads"] [@default None];
    local_directory: string option [@key "localDirectory"] [@default None];
    directory_stream: channel option [@key "directoryStream"] [@default None];
    local_paths: string list option [@key "localPaths"] [@default None];
    streams: channel list option [@key "streams"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type browser_new_browser_cdp_session_returns =
  {
    session: channel [@key "session"];
  } [@@deriving yojson { strict = false }]

type browser_new_context_args_geolocation =
  {
    longitude: float [@key "longitude"];
    latitude: float [@key "latitude"];
    accuracy: float option [@key "accuracy"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_device_launch_browser_args_record_video_size =
  {
    width: int [@key "width"];
    height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type android_device_launch_browser_args_record_video =
  {
    dir: string option [@key "dir"] [@default None];
    size: android_device_launch_browser_args_record_video_size option [@key "size"] [@default None];
    show_actions: android_device_launch_browser_args_record_video_show_actions option [@key "showActions"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_start_server_returns =
  {
    endpoint: string [@key "endpoint"];
  } [@@deriving yojson { strict = false }]

type frame_click_args_button =
  [
  | `Left
  | `Right
  | `Middle
  ]

let frame_click_args_button_to_yojson = function
  | `Left -> `String "left"
  | `Right -> `String "right"
  | `Middle -> `String "middle"

let frame_click_args_button_of_yojson = function
  | `String "left" -> Ok `Left
  | `String "right" -> Ok `Right
  | `String "middle" -> Ok `Middle
  | _ -> Error "Invalid enum frame_click_args_button"

type page_unregister_locator_handler_args =
  {
    uid: int [@key "uid"];
  } [@@deriving yojson { strict = false }]

type android_device_input_press_args =
  {
    key: string [@key "key"];
  } [@@deriving yojson { strict = false }]

type local_utils_zip_args_mode =
  [
  | `Write
  | `Append
  ]

let local_utils_zip_args_mode_to_yojson = function
  | `Write -> `String "write"
  | `Append -> `String "append"

let local_utils_zip_args_mode_of_yojson = function
  | `String "write" -> Ok `Write
  | `String "append" -> Ok `Append
  | _ -> Error "Invalid enum local_utils_zip_args_mode"

type local_utils_zip_args =
  {
    zip_file: string [@key "zipFile"];
    entries: name_value list [@key "entries"];
    stacks_id: string option [@key "stacksId"] [@default None];
    mode: local_utils_zip_args_mode [@key "mode"];
    include_sources: bool [@key "includeSources"];
    additional_sources: string list option [@key "additionalSources"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_frame_detached_event =
  {
    frame: channel [@key "frame"];
  } [@@deriving yojson { strict = false }]

type element_handle_is_editable_returns =
  {
    value: bool [@key "value"];
  } [@@deriving yojson { strict = false }]

type browser_context_clock_install_args =
  {
    time_number: float option [@key "timeNumber"] [@default None];
    time_string: string option [@key "timeString"] [@default None];
  } [@@deriving yojson { strict = false }]

type record_har_options =
  {
    zip: bool option [@key "zip"] [@default None];
    content: record_har_options_content option [@key "content"] [@default None];
    mode: record_har_options_mode option [@key "mode"] [@default None];
    url_glob: string option [@key "urlGlob"] [@default None];
    url_regex_source: string option [@key "urlRegexSource"] [@default None];
    url_regex_flags: string option [@key "urlRegexFlags"] [@default None];
  } [@@deriving yojson { strict = false }]

type tracing_har_start_args =
  {
    page: channel option [@key "page"] [@default None];
    options: record_har_options [@key "options"];
  } [@@deriving yojson { strict = false }]

type debug_controller_source_changed_event =
  {
    text: string [@key "text"];
    header: string option [@key "header"] [@default None];
    footer: string option [@key "footer"] [@default None];
    actions: string list option [@key "actions"] [@default None];
  } [@@deriving yojson { strict = false }]

type api_response =
  {
    fetch_uid: string [@key "fetchUid"];
    url: string [@key "url"];
    status: int [@key "status"];
    status_text: string [@key "statusText"];
    headers: name_value list [@key "headers"];
  } [@@deriving yojson { strict = false }]

type playwright_new_request_args_storage_state =
  {
    cookies: network_cookie list option [@key "cookies"] [@default None];
    origins: set_origin_storage list option [@key "origins"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_device_launch_browser_args_geolocation =
  {
    longitude: float [@key "longitude"];
    latitude: float [@key "latitude"];
    accuracy: float option [@key "accuracy"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_device_launch_browser_args_accept_downloads =
  [
  | `Accept
  | `Deny
  | `Internal_browser_default
  ]

let android_device_launch_browser_args_accept_downloads_to_yojson = function
  | `Accept -> `String "accept"
  | `Deny -> `String "deny"
  | `Internal_browser_default -> `String "internal-browser-default"

let android_device_launch_browser_args_accept_downloads_of_yojson = function
  | `String "accept" -> Ok `Accept
  | `String "deny" -> Ok `Deny
  | `String "internal-browser-default" -> Ok `Internal_browser_default
  | _ -> Error "Invalid enum android_device_launch_browser_args_accept_downloads"

type android_device_launch_browser_args_color_scheme =
  [
  | `Dark
  | `Light
  | `No_preference
  | `No_override
  ]

let android_device_launch_browser_args_color_scheme_to_yojson = function
  | `Dark -> `String "dark"
  | `Light -> `String "light"
  | `No_preference -> `String "no-preference"
  | `No_override -> `String "no-override"

let android_device_launch_browser_args_color_scheme_of_yojson = function
  | `String "dark" -> Ok `Dark
  | `String "light" -> Ok `Light
  | `String "no-preference" -> Ok `No_preference
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum android_device_launch_browser_args_color_scheme"

type android_device_launch_browser_args_viewport =
  {
    width: int [@key "width"];
    height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type android_device_launch_browser_args =
  {
    no_default_viewport: bool option [@key "noDefaultViewport"] [@default None];
    viewport: android_device_launch_browser_args_viewport option [@key "viewport"] [@default None];
    screen: android_device_launch_browser_args_screen option [@key "screen"] [@default None];
    ignore_https_errors: bool option [@key "ignoreHTTPSErrors"] [@default None];
    client_certificates: android_device_launch_browser_args_client_certificates_item list option [@key "clientCertificates"] [@default None];
    java_script_enabled: bool option [@key "javaScriptEnabled"] [@default None];
    bypass_csp: bool option [@key "bypassCSP"] [@default None];
    user_agent: string option [@key "userAgent"] [@default None];
    locale: string option [@key "locale"] [@default None];
    timezone_id: string option [@key "timezoneId"] [@default None];
    geolocation: android_device_launch_browser_args_geolocation option [@key "geolocation"] [@default None];
    permissions: string list option [@key "permissions"] [@default None];
    extra_http_headers: name_value list option [@key "extraHTTPHeaders"] [@default None];
    offline: bool option [@key "offline"] [@default None];
    http_credentials: android_device_launch_browser_args_http_credentials option [@key "httpCredentials"] [@default None];
    device_scale_factor: float option [@key "deviceScaleFactor"] [@default None];
    is_mobile: bool option [@key "isMobile"] [@default None];
    has_touch: bool option [@key "hasTouch"] [@default None];
    color_scheme: android_device_launch_browser_args_color_scheme option [@key "colorScheme"] [@default None];
    reduced_motion: android_device_launch_browser_args_reduced_motion option [@key "reducedMotion"] [@default None];
    forced_colors: android_device_launch_browser_args_forced_colors option [@key "forcedColors"] [@default None];
    accept_downloads: android_device_launch_browser_args_accept_downloads option [@key "acceptDownloads"] [@default None];
    contrast: android_device_launch_browser_args_contrast option [@key "contrast"] [@default None];
    base_url: string option [@key "baseURL"] [@default None];
    record_video: android_device_launch_browser_args_record_video option [@key "recordVideo"] [@default None];
    strict_selectors: bool option [@key "strictSelectors"] [@default None];
    service_workers: android_device_launch_browser_args_service_workers option [@key "serviceWorkers"] [@default None];
    selector_engines: selector_engine list option [@key "selectorEngines"] [@default None];
    test_id_attribute_name: string option [@key "testIdAttributeName"] [@default None];
    pkg: string option [@key "pkg"] [@default None];
    args: string list option [@key "args"] [@default None];
    proxy: android_device_launch_browser_args_proxy option [@key "proxy"] [@default None];
  } [@@deriving yojson { strict = false }]

type response_http_version_returns =
  {
    value: string [@key "value"];
  } [@@deriving yojson { strict = false }]

type frame_blur_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type api_request_context_fetch_log_returns =
  {
    log: string list [@key "log"];
  } [@@deriving yojson { strict = false }]

type frame_query_count_args =
  {
    selector: string [@key "selector"];
  } [@@deriving yojson { strict = false }]

type socks_support_socks_closed_event =
  {
    uid: string [@key "uid"];
  } [@@deriving yojson { strict = false }]

type frame_eval_on_selector_all_returns =
  {
    value: serialized_value [@key "value"];
  } [@@deriving yojson { strict = false }]

type api_request_context_initializer =
  {
    tracing: channel [@key "tracing"];
  } [@@deriving yojson { strict = false }]

type page_screencast_frame_event =
  {
    data: string [@key "data"];
  } [@@deriving yojson { strict = false }]

type browser_initializer_browser_name =
  [
  | `Chromium
  | `Firefox
  | `Webkit
  ]

let browser_initializer_browser_name_to_yojson = function
  | `Chromium -> `String "chromium"
  | `Firefox -> `String "firefox"
  | `Webkit -> `String "webkit"

let browser_initializer_browser_name_of_yojson = function
  | `String "chromium" -> Ok `Chromium
  | `String "firefox" -> Ok `Firefox
  | `String "webkit" -> Ok `Webkit
  | _ -> Error "Invalid enum browser_initializer_browser_name"

type browser_initializer =
  {
    version: string [@key "version"];
    name: string [@key "name"];
    browser_name: browser_initializer_browser_name [@key "browserName"];
  } [@@deriving yojson { strict = false }]

type element_handle_click_args_button =
  [
  | `Left
  | `Right
  | `Middle
  ]

let element_handle_click_args_button_to_yojson = function
  | `Left -> `String "left"
  | `Right -> `String "right"
  | `Middle -> `String "middle"

let element_handle_click_args_button_of_yojson = function
  | `String "left" -> Ok `Left
  | `String "right" -> Ok `Right
  | `String "middle" -> Ok `Middle
  | _ -> Error "Invalid enum element_handle_click_args_button"

type element_handle_click_args =
  {
    force: bool option [@key "force"] [@default None];
    no_wait_after: bool option [@key "noWaitAfter"] [@default None];
    modifiers: element_handle_click_args_modifiers_item list option [@key "modifiers"] [@default None];
    position: point option [@key "position"] [@default None];
    delay: float option [@key "delay"] [@default None];
    button: element_handle_click_args_button option [@key "button"] [@default None];
    click_count: int option [@key "clickCount"] [@default None];
    timeout: float [@key "timeout"];
    trial: bool option [@key "trial"] [@default None];
    steps: int option [@key "steps"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_new_context_args_record_video_size =
  {
    width: int [@key "width"];
    height: int [@key "height"];
  } [@@deriving yojson { strict = false }]

type android_device_input_tap_args =
  {
    point: point [@key "point"];
  } [@@deriving yojson { strict = false }]

type tracing_har_start_returns =
  {
    har_id: string [@key "harId"];
  } [@@deriving yojson { strict = false }]

type page_register_locator_handler_args =
  {
    selector: string [@key "selector"];
    no_wait_after: bool option [@key "noWaitAfter"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_new_context_returns =
  {
    context: channel [@key "context"];
  } [@@deriving yojson { strict = false }]

type page_go_back_returns =
  {
    response: channel option [@key "response"] [@default None];
  } [@@deriving yojson { strict = false }]

type route_abort_args =
  {
    error_code: string option [@key "errorCode"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_click_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
    force: bool option [@key "force"] [@default None];
    no_wait_after: bool option [@key "noWaitAfter"] [@default None];
    modifiers: frame_click_args_modifiers_item list option [@key "modifiers"] [@default None];
    position: point option [@key "position"] [@default None];
    delay: float option [@key "delay"] [@default None];
    button: frame_click_args_button option [@key "button"] [@default None];
    click_count: int option [@key "clickCount"] [@default None];
    timeout: float [@key "timeout"];
    trial: bool option [@key "trial"] [@default None];
    steps: int option [@key "steps"] [@default None];
  } [@@deriving yojson { strict = false }]

type request_response_returns =
  {
    response: channel option [@key "response"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_press_args =
  {
    key: string [@key "key"];
    delay: float option [@key "delay"] [@default None];
    timeout: float [@key "timeout"];
    no_wait_after: bool option [@key "noWaitAfter"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_clock_fast_forward_args =
  {
    ticks_number: float option [@key "ticksNumber"] [@default None];
    ticks_string: string option [@key "ticksString"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_type_connect_over_cd_p_returns =
  {
    browser: channel [@key "browser"];
    default_context: channel option [@key "defaultContext"] [@default None];
  } [@@deriving yojson { strict = false }]

type route_fulfill_args =
  {
    status: int option [@key "status"] [@default None];
    headers: name_value list option [@key "headers"] [@default None];
    body: string option [@key "body"] [@default None];
    is_base64: bool option [@key "isBase64"] [@default None];
    fetch_response_uid: string option [@key "fetchResponseUid"] [@default None];
  } [@@deriving yojson { strict = false }]

type js_handle_initializer =
  {
    preview: string [@key "preview"];
  } [@@deriving yojson { strict = false }]

type browser_context_binding_call_event =
  {
    binding: channel [@key "binding"];
  } [@@deriving yojson { strict = false }]

type common_screenshot_options_scale =
  [
  | `Css
  | `Device
  ]

let common_screenshot_options_scale_to_yojson = function
  | `Css -> `String "css"
  | `Device -> `String "device"

let common_screenshot_options_scale_of_yojson = function
  | `String "css" -> Ok `Css
  | `String "device" -> Ok `Device
  | _ -> Error "Invalid enum common_screenshot_options_scale"

type api_request_context_fetch_returns =
  {
    response: api_response [@key "response"];
  } [@@deriving yojson { strict = false }]

type android_device_connect_to_web_view_args =
  {
    socket_name: string [@key "socketName"];
  } [@@deriving yojson { strict = false }]

type android_device_install_apk_args =
  {
    file: string [@key "file"];
    args: string list option [@key "args"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_set_offline_args =
  {
    offline: bool [@key "offline"];
  } [@@deriving yojson { strict = false }]

type browser_context_new_page_returns =
  {
    page: channel [@key "page"];
  } [@@deriving yojson { strict = false }]

type debug_controller_highlight_args =
  {
    selector: string option [@key "selector"] [@default None];
    aria_template: string option [@key "ariaTemplate"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_wait_for_selector_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
    timeout: float [@key "timeout"];
    state: element_handle_wait_for_selector_args_state option [@key "state"] [@default None];
  } [@@deriving yojson { strict = false }]

type route_initializer =
  {
    request: channel [@key "request"];
  } [@@deriving yojson { strict = false }]

type frame_dblclick_args_modifiers_item =
  [
  | `Alt
  | `Control
  | `Control_or_meta
  | `Meta
  | `Shift
  ]

let frame_dblclick_args_modifiers_item_to_yojson = function
  | `Alt -> `String "Alt"
  | `Control -> `String "Control"
  | `Control_or_meta -> `String "ControlOrMeta"
  | `Meta -> `String "Meta"
  | `Shift -> `String "Shift"

let frame_dblclick_args_modifiers_item_of_yojson = function
  | `String "Alt" -> Ok `Alt
  | `String "Control" -> Ok `Control
  | `String "ControlOrMeta" -> Ok `Control_or_meta
  | `String "Meta" -> Ok `Meta
  | `String "Shift" -> Ok `Shift
  | _ -> Error "Invalid enum frame_dblclick_args_modifiers_item"

type frame_dblclick_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
    force: bool option [@key "force"] [@default None];
    modifiers: frame_dblclick_args_modifiers_item list option [@key "modifiers"] [@default None];
    position: point option [@key "position"] [@default None];
    delay: float option [@key "delay"] [@default None];
    button: frame_dblclick_args_button option [@key "button"] [@default None];
    timeout: float [@key "timeout"];
    trial: bool option [@key "trial"] [@default None];
    steps: int option [@key "steps"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_reload_returns =
  {
    response: channel option [@key "response"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_initializer =
  {
    debugger: channel [@key "debugger"];
    request_context: channel [@key "requestContext"];
    tracing: channel [@key "tracing"];
    options: browser_context_initializer_options [@key "options"];
  } [@@deriving yojson { strict = false }]

type response_raw_response_headers_returns =
  {
    headers: name_value list [@key "headers"];
  } [@@deriving yojson { strict = false }]

type android_device_initializer =
  {
    model: string [@key "model"];
    serial: string [@key "serial"];
  } [@@deriving yojson { strict = false }]

type browser_new_context_args_record_video_show_actions =
  {
    duration: float option [@key "duration"] [@default None];
    position: browser_new_context_args_record_video_show_actions_position option [@key "position"] [@default None];
    font_size: int option [@key "fontSize"] [@default None];
  } [@@deriving yojson { strict = false }]

type web_socket_frame_sent_event =
  {
    opcode: int [@key "opcode"];
    data: string [@key "data"];
  } [@@deriving yojson { strict = false }]

type page_expect_screenshot_returns =
  {
    diff: string option [@key "diff"] [@default None];
    error_message: string option [@key "errorMessage"] [@default None];
    actual: string option [@key "actual"] [@default None];
    previous: string option [@key "previous"] [@default None];
    timed_out: bool option [@key "timedOut"] [@default None];
    log: string list option [@key "log"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_screenshot_returns =
  {
    binary: string [@key "binary"];
  } [@@deriving yojson { strict = false }]

type frame_hover_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
    force: bool option [@key "force"] [@default None];
    modifiers: frame_hover_args_modifiers_item list option [@key "modifiers"] [@default None];
    position: point option [@key "position"] [@default None];
    timeout: float [@key "timeout"];
    trial: bool option [@key "trial"] [@default None];
  } [@@deriving yojson { strict = false }]

type worker_evaluate_expression_handle_returns =
  {
    handle: channel [@key "handle"];
  } [@@deriving yojson { strict = false }]

type frame_tap_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
    force: bool option [@key "force"] [@default None];
    modifiers: frame_tap_args_modifiers_item list option [@key "modifiers"] [@default None];
    position: point option [@key "position"] [@default None];
    timeout: float [@key "timeout"];
    trial: bool option [@key "trial"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_check_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
    force: bool option [@key "force"] [@default None];
    position: point option [@key "position"] [@default None];
    timeout: float [@key "timeout"];
    trial: bool option [@key "trial"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_binding_call_event =
  {
    binding: channel [@key "binding"];
  } [@@deriving yojson { strict = false }]

type element_handle_wait_for_element_state_args =
  {
    state: element_handle_wait_for_element_state_args_state [@key "state"];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type android_device_launch_browser_returns =
  {
    context: channel [@key "context"];
  } [@@deriving yojson { strict = false }]

type artifact_initializer =
  {
    absolute_path: string [@key "absolutePath"];
  } [@@deriving yojson { strict = false }]

type tracing_har_export_returns =
  {
    artifact: channel [@key "artifact"];
  } [@@deriving yojson { strict = false }]

type frame_text_content_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type page_screencast_remove_overlay_args =
  {
    id: string [@key "id"];
  } [@@deriving yojson { strict = false }]

type android_device_open_args =
  {
    command: string [@key "command"];
  } [@@deriving yojson { strict = false }]

type worker_evaluate_expression_handle_args =
  {
    expression: string [@key "expression"];
    is_function: bool option [@key "isFunction"] [@default None];
    arg: serialized_argument [@key "arg"];
  } [@@deriving yojson { strict = false }]

type browser_context_add_init_script_args =
  {
    source: string [@key "source"];
  } [@@deriving yojson { strict = false }]

type page_screencast_show_overlay_returns =
  {
    id: string [@key "id"];
  } [@@deriving yojson { strict = false }]

type page_file_chooser_event =
  {
    element: channel [@key "element"];
    is_multiple: bool [@key "isMultiple"];
  } [@@deriving yojson { strict = false }]

type js_handle_evaluate_expression_handle_args =
  {
    expression: string [@key "expression"];
    is_function: bool option [@key "isFunction"] [@default None];
    arg: serialized_argument [@key "arg"];
  } [@@deriving yojson { strict = false }]

type element_handle_is_hidden_returns =
  {
    value: bool [@key "value"];
  } [@@deriving yojson { strict = false }]

type worker_evaluate_expression_returns =
  {
    value: serialized_value [@key "value"];
  } [@@deriving yojson { strict = false }]

type local_utils_initializer =
  {
    device_descriptors: local_utils_initializer_device_descriptors_item list [@key "deviceDescriptors"];
  } [@@deriving yojson { strict = false }]

type frame_expect_args =
  {
    selector: string option [@key "selector"] [@default None];
    expression: string [@key "expression"];
    expression_arg: json option [@key "expressionArg"] [@default None];
    pseudo: frame_expect_args_pseudo option [@key "pseudo"] [@default None];
    expected_text: expected_text_value list option [@key "expectedText"] [@default None];
    expected_number: float option [@key "expectedNumber"] [@default None];
    expected_value: serialized_argument option [@key "expectedValue"] [@default None];
    use_inner_text: bool option [@key "useInnerText"] [@default None];
    is_not: bool [@key "isNot"];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type local_utils_har_open_returns =
  {
    har_id: string option [@key "harId"] [@default None];
    error: string option [@key "error"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_device_drag_args =
  {
    android_selector: android_selector [@key "androidSelector"];
    dest: point [@key "dest"];
    speed: float option [@key "speed"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type element_handle_query_selector_all_args =
  {
    selector: string [@key "selector"];
  } [@@deriving yojson { strict = false }]

type frame_goto_returns =
  {
    response: channel option [@key "response"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_select_option_returns =
  {
    values: string list [@key "values"];
  } [@@deriving yojson { strict = false }]

type frame_eval_on_selector_all_args =
  {
    selector: string [@key "selector"];
    expression: string [@key "expression"];
    is_function: bool option [@key "isFunction"] [@default None];
    arg: serialized_argument [@key "arg"];
  } [@@deriving yojson { strict = false }]

type android_device_fling_args_direction =
  [
  | `Up
  | `Down
  | `Left
  | `Right
  ]

let android_device_fling_args_direction_to_yojson = function
  | `Up -> `String "up"
  | `Down -> `String "down"
  | `Left -> `String "left"
  | `Right -> `String "right"

let android_device_fling_args_direction_of_yojson = function
  | `String "up" -> Ok `Up
  | `String "down" -> Ok `Down
  | `String "left" -> Ok `Left
  | `String "right" -> Ok `Right
  | _ -> Error "Invalid enum android_device_fling_args_direction"

type android_device_fling_args =
  {
    android_selector: android_selector [@key "androidSelector"];
    direction: android_device_fling_args_direction [@key "direction"];
    speed: float option [@key "speed"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type frame_query_selector_returns =
  {
    element: channel option [@key "element"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_requests_returns =
  {
    requests: channel list [@key "requests"];
  } [@@deriving yojson { strict = false }]

type api_request_context_storage_state_returns =
  {
    cookies: network_cookie list [@key "cookies"];
    origins: origin_storage list [@key "origins"];
  } [@@deriving yojson { strict = false }]

type browser_context_add_init_script_returns =
  {
    disposable: channel [@key "disposable"];
  } [@@deriving yojson { strict = false }]

type debug_controller_paused_event =
  {
    paused: bool [@key "paused"];
  } [@@deriving yojson { strict = false }]

type page_screencast_start_returns =
  {
    artifact: channel option [@key "artifact"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_new_context_args_contrast =
  [
  | `No_preference
  | `More
  | `No_override
  ]

let browser_new_context_args_contrast_to_yojson = function
  | `No_preference -> `String "no-preference"
  | `More -> `String "more"
  | `No_override -> `String "no-override"

let browser_new_context_args_contrast_of_yojson = function
  | `String "no-preference" -> Ok `No_preference
  | `String "more" -> Ok `More
  | `String "no-override" -> Ok `No_override
  | _ -> Error "Invalid enum browser_new_context_args_contrast"

type frame_drop_args_data_item =
  {
    mime_type: string [@key "mimeType"];
    value: string [@key "value"];
  } [@@deriving yojson { strict = false }]

type frame_drop_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
    position: point option [@key "position"] [@default None];
    payloads: frame_drop_args_payloads_item list option [@key "payloads"] [@default None];
    local_paths: string list option [@key "localPaths"] [@default None];
    streams: channel list option [@key "streams"] [@default None];
    data: frame_drop_args_data_item list option [@key "data"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type android_device_input_type_args =
  {
    text: string [@key "text"];
  } [@@deriving yojson { strict = false }]

type browser_disconnect_from_reused_context_args =
  {
    reason: string [@key "reason"];
  } [@@deriving yojson { strict = false }]

type recorder_source =
  {
    is_recorded: bool [@key "isRecorded"];
    id: string [@key "id"];
    label: string [@key "label"];
    text: string [@key "text"];
    language: string [@key "language"];
    highlight: recorder_source_highlight_item list [@key "highlight"];
    reveal_line: int option [@key "revealLine"] [@default None];
    group: string option [@key "group"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_query_selector_returns =
  {
    element: channel option [@key "element"] [@default None];
  } [@@deriving yojson { strict = false }]

type worker_disconnect_args =
  {
    reason: string option [@key "reason"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_wait_for_selector_returns =
  {
    element: channel option [@key "element"] [@default None];
  } [@@deriving yojson { strict = false }]

type common_screenshot_options_mask_item =
  {
    frame: channel [@key "frame"];
    selector: string [@key "selector"];
  } [@@deriving yojson { strict = false }]

type web_socket_route_send_to_server_args =
  {
    message: string [@key "message"];
    is_base64: bool [@key "isBase64"];
  } [@@deriving yojson { strict = false }]

type tracing_har_export_args =
  {
    har_id: string option [@key "harId"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_is_visible_returns =
  {
    value: bool [@key "value"];
  } [@@deriving yojson { strict = false }]

type artifact_save_as_args =
  {
    path: string [@key "path"];
  } [@@deriving yojson { strict = false }]

type browser_context_cookies_returns =
  {
    cookies: network_cookie list [@key "cookies"];
  } [@@deriving yojson { strict = false }]

type route_continue_args =
  {
    url: string option [@key "url"] [@default None];
    method_: string option [@key "method"] [@default None];
    headers: name_value list option [@key "headers"] [@default None];
    post_data: string option [@key "postData"] [@default None];
    is_fallback: bool [@key "isFallback"];
  } [@@deriving yojson { strict = false }]

type frame_inner_text_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type api_request_context_fetch_response_body_args =
  {
    fetch_uid: string [@key "fetchUid"];
  } [@@deriving yojson { strict = false }]

type debug_controller_state_changed_event =
  {
    page_count: int [@key "pageCount"];
  } [@@deriving yojson { strict = false }]

type page_frame_attached_event =
  {
    frame: channel [@key "frame"];
  } [@@deriving yojson { strict = false }]

type api_request_context_dispose_args =
  {
    reason: string option [@key "reason"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_element_info =
  {
    children: android_element_info list option [@key "children"] [@default None];
    clazz: string [@key "clazz"];
    desc: string [@key "desc"];
    res: string [@key "res"];
    pkg: string [@key "pkg"];
    text: string [@key "text"];
    bounds: rect [@key "bounds"];
    checkable: bool [@key "checkable"];
    checked: bool [@key "checked"];
    clickable: bool [@key "clickable"];
    enabled: bool [@key "enabled"];
    focusable: bool [@key "focusable"];
    focused: bool [@key "focused"];
    long_clickable: bool [@key "longClickable"];
    scrollable: bool [@key "scrollable"];
    selected: bool [@key "selected"];
  } [@@deriving yojson { strict = false }]

type element_handle_type_args =
  {
    text: string [@key "text"];
    delay: float option [@key "delay"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type web_socket_route_initializer =
  {
    url: string [@key "url"];
    protocols: string list [@key "protocols"];
  } [@@deriving yojson { strict = false }]

type local_utils_tracing_started_args =
  {
    traces_dir: string option [@key "tracesDir"] [@default None];
    trace_name: string [@key "traceName"];
    live: bool option [@key "live"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_locator_handler_triggered_event =
  {
    uid: int [@key "uid"];
  } [@@deriving yojson { strict = false }]

type android_device_long_tap_args =
  {
    android_selector: android_selector [@key "androidSelector"];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type browser_context_add_cookies_args =
  {
    cookies: set_network_cookie list [@key "cookies"];
  } [@@deriving yojson { strict = false }]

type frame_text_content_returns =
  {
    value: string option [@key "value"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_device_connect_to_web_view_returns =
  {
    context: channel [@key "context"];
  } [@@deriving yojson { strict = false }]

type browser_new_context_args_record_video =
  {
    dir: string option [@key "dir"] [@default None];
    size: browser_new_context_args_record_video_size option [@key "size"] [@default None];
    show_actions: browser_new_context_args_record_video_show_actions option [@key "showActions"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_new_context_args =
  {
    no_default_viewport: bool option [@key "noDefaultViewport"] [@default None];
    viewport: browser_new_context_args_viewport option [@key "viewport"] [@default None];
    screen: browser_new_context_args_screen option [@key "screen"] [@default None];
    ignore_https_errors: bool option [@key "ignoreHTTPSErrors"] [@default None];
    client_certificates: browser_new_context_args_client_certificates_item list option [@key "clientCertificates"] [@default None];
    java_script_enabled: bool option [@key "javaScriptEnabled"] [@default None];
    bypass_csp: bool option [@key "bypassCSP"] [@default None];
    user_agent: string option [@key "userAgent"] [@default None];
    locale: string option [@key "locale"] [@default None];
    timezone_id: string option [@key "timezoneId"] [@default None];
    geolocation: browser_new_context_args_geolocation option [@key "geolocation"] [@default None];
    permissions: string list option [@key "permissions"] [@default None];
    extra_http_headers: name_value list option [@key "extraHTTPHeaders"] [@default None];
    offline: bool option [@key "offline"] [@default None];
    http_credentials: browser_new_context_args_http_credentials option [@key "httpCredentials"] [@default None];
    device_scale_factor: float option [@key "deviceScaleFactor"] [@default None];
    is_mobile: bool option [@key "isMobile"] [@default None];
    has_touch: bool option [@key "hasTouch"] [@default None];
    color_scheme: browser_new_context_args_color_scheme option [@key "colorScheme"] [@default None];
    reduced_motion: browser_new_context_args_reduced_motion option [@key "reducedMotion"] [@default None];
    forced_colors: browser_new_context_args_forced_colors option [@key "forcedColors"] [@default None];
    accept_downloads: browser_new_context_args_accept_downloads option [@key "acceptDownloads"] [@default None];
    contrast: browser_new_context_args_contrast option [@key "contrast"] [@default None];
    base_url: string option [@key "baseURL"] [@default None];
    record_video: browser_new_context_args_record_video option [@key "recordVideo"] [@default None];
    strict_selectors: bool option [@key "strictSelectors"] [@default None];
    service_workers: browser_new_context_args_service_workers option [@key "serviceWorkers"] [@default None];
    selector_engines: selector_engine list option [@key "selectorEngines"] [@default None];
    test_id_attribute_name: string option [@key "testIdAttributeName"] [@default None];
    proxy: browser_new_context_args_proxy option [@key "proxy"] [@default None];
    storage_state: browser_new_context_args_storage_state option [@key "storageState"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_web_socket_event =
  {
    web_socket: channel [@key "webSocket"];
  } [@@deriving yojson { strict = false }]

type page_keyboard_insert_text_args =
  {
    text: string [@key "text"];
  } [@@deriving yojson { strict = false }]

type page_expose_binding_args =
  {
    name: string [@key "name"];
  } [@@deriving yojson { strict = false }]

type android_device_tap_args =
  {
    android_selector: android_selector [@key "androidSelector"];
    duration: float option [@key "duration"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type frame_query_count_returns =
  {
    value: int [@key "value"];
  } [@@deriving yojson { strict = false }]

type frame_is_editable_returns =
  {
    value: bool [@key "value"];
  } [@@deriving yojson { strict = false }]

type page_mouse_down_args =
  {
    button: page_mouse_down_args_button option [@key "button"] [@default None];
    click_count: int option [@key "clickCount"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_set_network_interception_patterns_args_patterns_item =
  {
    glob: string option [@key "glob"] [@default None];
    regex_source: string option [@key "regexSource"] [@default None];
    regex_flags: string option [@key "regexFlags"] [@default None];
    url_pattern: url_pattern option [@key "urlPattern"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_context_set_http_credentials_args =
  {
    http_credentials: browser_context_set_http_credentials_args_http_credentials option [@key "httpCredentials"] [@default None];
  } [@@deriving yojson { strict = false }]

type stream_read_args =
  {
    size: int option [@key "size"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_eval_on_selector_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
    expression: string [@key "expression"];
    is_function: bool option [@key "isFunction"] [@default None];
    arg: serialized_argument [@key "arg"];
  } [@@deriving yojson { strict = false }]

type frame_eval_on_selector_returns =
  {
    value: serialized_value [@key "value"];
  } [@@deriving yojson { strict = false }]

type frame_wait_for_timeout_args =
  {
    wait_timeout: float [@key "waitTimeout"];
  } [@@deriving yojson { strict = false }]

type socks_support_socks_requested_event =
  {
    uid: string [@key "uid"];
    host: string [@key "host"];
    port: int [@key "port"];
  } [@@deriving yojson { strict = false }]

type playwright_new_request_returns =
  {
    request: channel [@key "request"];
  } [@@deriving yojson { strict = false }]

type element_handle_eval_on_selector_all_args =
  {
    selector: string [@key "selector"];
    expression: string [@key "expression"];
    is_function: bool option [@key "isFunction"] [@default None];
    arg: serialized_argument [@key "arg"];
  } [@@deriving yojson { strict = false }]

type tracing_tracing_group_args =
  {
    name: string [@key "name"];
    location: tracing_tracing_group_args_location option [@key "location"] [@default None];
  } [@@deriving yojson { strict = false }]

type element_handle_wait_for_selector_returns =
  {
    element: channel option [@key "element"] [@default None];
  } [@@deriving yojson { strict = false }]

type frame_aria_snapshot_args =
  {
    mode: frame_aria_snapshot_args_mode option [@key "mode"] [@default None];
    track: string option [@key "track"] [@default None];
    selector: string option [@key "selector"] [@default None];
    depth: int option [@key "depth"] [@default None];
    boxes: bool option [@key "boxes"] [@default None];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type browser_context_clock_set_system_time_args =
  {
    time_number: float option [@key "timeNumber"] [@default None];
    time_string: string option [@key "timeString"] [@default None];
  } [@@deriving yojson { strict = false }]

type web_socket_route_close_page_event =
  {
    code: int option [@key "code"] [@default None];
    reason: string option [@key "reason"] [@default None];
    was_clean: bool [@key "wasClean"];
  } [@@deriving yojson { strict = false }]

type playwright_new_request_args =
  {
    base_url: string option [@key "baseURL"] [@default None];
    user_agent: string option [@key "userAgent"] [@default None];
    ignore_https_errors: bool option [@key "ignoreHTTPSErrors"] [@default None];
    extra_http_headers: name_value list option [@key "extraHTTPHeaders"] [@default None];
    fail_on_status_code: bool option [@key "failOnStatusCode"] [@default None];
    client_certificates: playwright_new_request_args_client_certificates_item list option [@key "clientCertificates"] [@default None];
    max_redirects: int option [@key "maxRedirects"] [@default None];
    http_credentials: playwright_new_request_args_http_credentials option [@key "httpCredentials"] [@default None];
    proxy: playwright_new_request_args_proxy option [@key "proxy"] [@default None];
    storage_state: playwright_new_request_args_storage_state option [@key "storageState"] [@default None];
    traces_dir: string option [@key "tracesDir"] [@default None];
  } [@@deriving yojson { strict = false }]

type browser_stop_tracing_returns =
  {
    artifact: channel [@key "artifact"];
  } [@@deriving yojson { strict = false }]

type element_handle_bounding_box_returns =
  {
    value: rect option [@key "value"] [@default None];
  } [@@deriving yojson { strict = false }]

type api_request_context_fetch_args =
  {
    url: string [@key "url"];
    encoded_params: string option [@key "encodedParams"] [@default None];
    params: name_value list option [@key "params"] [@default None];
    method_: string option [@key "method"] [@default None];
    headers: name_value list option [@key "headers"] [@default None];
    post_data: string option [@key "postData"] [@default None];
    json_data: string option [@key "jsonData"] [@default None];
    form_data: name_value list option [@key "formData"] [@default None];
    multipart_data: form_field list option [@key "multipartData"] [@default None];
    timeout: float [@key "timeout"];
    fail_on_status_code: bool option [@key "failOnStatusCode"] [@default None];
    ignore_https_errors: bool option [@key "ignoreHTTPSErrors"] [@default None];
    max_redirects: int option [@key "maxRedirects"] [@default None];
    max_retries: int option [@key "maxRetries"] [@default None];
  } [@@deriving yojson { strict = false }]

type local_utils_har_unzip_args =
  {
    zip_file: string [@key "zipFile"];
    har_file: string [@key "harFile"];
  } [@@deriving yojson { strict = false }]

type frame_add_style_tag_args =
  {
    url: string option [@key "url"] [@default None];
    content: string option [@key "content"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_go_forward_returns =
  {
    response: channel option [@key "response"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_mouse_wheel_args =
  {
    delta_x: float [@key "deltaX"];
    delta_y: float [@key "deltaY"];
  } [@@deriving yojson { strict = false }]

type page_keyboard_type_args =
  {
    text: string [@key "text"];
    delay: float option [@key "delay"] [@default None];
  } [@@deriving yojson { strict = false }]

type local_utils_har_close_args =
  {
    har_id: string [@key "harId"];
  } [@@deriving yojson { strict = false }]

type cdp_session_send_args =
  {
    method_: string [@key "method"];
    params: json option [@key "params"] [@default None];
  } [@@deriving yojson { strict = false }]

type page_screenshot_returns =
  {
    binary: string [@key "binary"];
  } [@@deriving yojson { strict = false }]

type element_handle_get_attribute_args =
  {
    name: string [@key "name"];
  } [@@deriving yojson { strict = false }]

type js_handle_preview_updated_event =
  {
    preview: string [@key "preview"];
  } [@@deriving yojson { strict = false }]

type frame_get_attribute_args =
  {
    selector: string [@key "selector"];
    strict: bool option [@key "strict"] [@default None];
    name: string [@key "name"];
    timeout: float [@key "timeout"];
  } [@@deriving yojson { strict = false }]

type browser_context_set_network_interception_patterns_args =
  {
    patterns: browser_context_set_network_interception_patterns_args_patterns_item list [@key "patterns"];
  } [@@deriving yojson { strict = false }]

type browser_type_launch_persistent_context_returns =
  {
    browser: channel [@key "browser"];
    context: channel [@key "context"];
  } [@@deriving yojson { strict = false }]

type common_screenshot_options =
  {
    omit_background: bool option [@key "omitBackground"] [@default None];
    caret: common_screenshot_options_caret option [@key "caret"] [@default None];
    animations: common_screenshot_options_animations option [@key "animations"] [@default None];
    scale: common_screenshot_options_scale option [@key "scale"] [@default None];
    mask: common_screenshot_options_mask_item list option [@key "mask"] [@default None];
    mask_color: string option [@key "maskColor"] [@default None];
    style: string option [@key "style"] [@default None];
  } [@@deriving yojson { strict = false }]

type android_device_info_returns =
  {
    info: android_element_info [@key "info"];
  } [@@deriving yojson { strict = false }]

type frame_evaluate_expression_handle_args =
  {
    expression: string [@key "expression"];
    is_function: bool option [@key "isFunction"] [@default None];
    arg: serialized_argument [@key "arg"];
  } [@@deriving yojson { strict = false }]

type metadata =
  {
    location: metadata_location option [@key "location"] [@default None];
    title: string option [@key "title"] [@default None];
    internal: bool option [@key "internal"] [@default None];
    step_id: string option [@key "stepId"] [@default None];
  } [@@deriving yojson { strict = false }]

