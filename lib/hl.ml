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

  let fetch ?max_retries ?max_redirects ?ignore_https_errors ?fail_on_status_code ~timeout ?multipart_data ?form_data ?json_data ?post_data ?headers ?method_ ?params ?encoded_params ~url (t : t) =
    let args : Protocol.api_request_context_fetch_args = {
      Protocol.max_retries = max_retries;
      Protocol.max_redirects = max_redirects;
      Protocol.ignore_https_errors = ignore_https_errors;
      Protocol.fail_on_status_code = fail_on_status_code;
      Protocol.timeout = timeout;
      Protocol.multipart_data = multipart_data;
      Protocol.form_data = form_data;
      Protocol.json_data = json_data;
      Protocol.post_data = Option.map Base64.encode_exn post_data;
      Protocol.headers = headers;
      Protocol.method_ = method_;
      Protocol.params = params;
      Protocol.encoded_params = encoded_params;
      Protocol.url = url;
    } in
    match Api.Api_request_context.fetch t.conn t.guid args with
    | Ok res -> res.Protocol.response
    | Error e -> raise (Error e)

  let fetch_response_body ~fetch_uid (t : t) =
    let args : Protocol.api_request_context_fetch_response_body_args = {
      Protocol.fetch_uid = fetch_uid;
    } in
    match Api.Api_request_context.fetch_response_body t.conn t.guid args with
    | Ok res -> Option.map Base64.decode_exn res.Protocol.binary
    | Error e -> raise (Error e)

  let fetch_log ~fetch_uid (t : t) =
    let args : Protocol.api_request_context_fetch_log_args = {
      Protocol.fetch_uid = fetch_uid;
    } in
    match Api.Api_request_context.fetch_log t.conn t.guid args with
    | Ok res -> res.Protocol.log
    | Error e -> raise (Error e)

  let storage_state ?indexed_db (t : t) =
    let args : Protocol.api_request_context_storage_state_args = {
      Protocol.indexed_db = indexed_db;
    } in
    match Api.Api_request_context.storage_state t.conn t.guid args with
    | Ok res -> res
    | Error e -> raise (Error e)

  let dispose_api_response ~fetch_uid (t : t) =
    let args : Protocol.api_request_context_dispose_api_response_args = {
      Protocol.fetch_uid = fetch_uid;
    } in
    match Api.Api_request_context.dispose_api_response t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let dispose ?reason (t : t) =
    let args : Protocol.api_request_context_dispose_args = {
      Protocol.reason = reason;
    } in
    match Api.Api_request_context.dispose t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

end

module Local_utils = struct
  type t = local_utils_type obj

  let zip ?additional_sources ~include_sources ~mode ?stacks_id ~entries ~zip_file (t : t) =
    let args : Protocol.local_utils_zip_args = {
      Protocol.additional_sources = additional_sources;
      Protocol.include_sources = include_sources;
      Protocol.mode = mode;
      Protocol.stacks_id = stacks_id;
      Protocol.entries = entries;
      Protocol.zip_file = zip_file;
    } in
    match Api.Local_utils.zip t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let har_open ~file (t : t) =
    let args : Protocol.local_utils_har_open_args = {
      Protocol.file = file;
    } in
    match Api.Local_utils.har_open t.conn t.guid args with
    | Ok res -> res
    | Error e -> raise (Error e)

  let har_lookup ~is_navigation_request ?post_data ~headers ~method_ ~url ~har_id (t : t) =
    let args : Protocol.local_utils_har_lookup_args = {
      Protocol.is_navigation_request = is_navigation_request;
      Protocol.post_data = Option.map Base64.encode_exn post_data;
      Protocol.headers = headers;
      Protocol.method_ = method_;
      Protocol.url = url;
      Protocol.har_id = har_id;
    } in
    match Api.Local_utils.har_lookup t.conn t.guid args with
    | Ok res -> res
    | Error e -> raise (Error e)

  let har_close ~har_id (t : t) =
    let args : Protocol.local_utils_har_close_args = {
      Protocol.har_id = har_id;
    } in
    match Api.Local_utils.har_close t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let har_unzip ~har_file ~zip_file (t : t) =
    let args : Protocol.local_utils_har_unzip_args = {
      Protocol.har_file = har_file;
      Protocol.zip_file = zip_file;
    } in
    match Api.Local_utils.har_unzip t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let connect ?socks_proxy_redirect_port_for_test ~timeout ?slow_mo ?expose_network ?headers ~endpoint (t : t) =
    let args : Protocol.local_utils_connect_args = {
      Protocol.socks_proxy_redirect_port_for_test = socks_proxy_redirect_port_for_test;
      Protocol.timeout = timeout;
      Protocol.slow_mo = slow_mo;
      Protocol.expose_network = expose_network;
      Protocol.headers = headers;
      Protocol.endpoint = endpoint;
    } in
    match Api.Local_utils.connect t.conn t.guid args with
    | Ok res -> res
    | Error e -> raise (Error e)

  let tracing_started ?live ~trace_name ?traces_dir (t : t) =
    let args : Protocol.local_utils_tracing_started_args = {
      Protocol.live = live;
      Protocol.trace_name = trace_name;
      Protocol.traces_dir = traces_dir;
    } in
    match Api.Local_utils.tracing_started t.conn t.guid args with
    | Ok res -> res.Protocol.stacks_id
    | Error e -> raise (Error e)

  let add_stack_to_tracing_no_reply ~call_data (t : t) =
    let args : Protocol.local_utils_add_stack_to_tracing_no_reply_args = {
      Protocol.call_data = call_data;
    } in
    match Api.Local_utils.add_stack_to_tracing_no_reply t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let trace_discarded ~stacks_id (t : t) =
    let args : Protocol.local_utils_trace_discarded_args = {
      Protocol.stacks_id = stacks_id;
    } in
    match Api.Local_utils.trace_discarded t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let glob_to_regex ?web_socket_url ?base_url ~glob (t : t) =
    let args : Protocol.local_utils_glob_to_regex_args = {
      Protocol.web_socket_url = web_socket_url;
      Protocol.base_url = base_url;
      Protocol.glob = glob;
    } in
    match Api.Local_utils.glob_to_regex t.conn t.guid args with
    | Ok res -> res.Protocol.regex
    | Error e -> raise (Error e)

end

module Root = struct
  type t = root_type obj

  let initialize ~sdk_language (t : t) =
    let args : Protocol.root_initialize_args = {
      Protocol.sdk_language = sdk_language;
    } in
    match Api.Root.initialize t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.playwright.guid } : playwright_type obj)
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

  let new_request ?traces_dir ?storage_state ?proxy ?http_credentials ?max_redirects ?client_certificates ?fail_on_status_code ?extra_http_headers ?ignore_https_errors ?user_agent ?base_url (t : t) =
    let args : Protocol.playwright_new_request_args = {
      Protocol.traces_dir = traces_dir;
      Protocol.storage_state = storage_state;
      Protocol.proxy = proxy;
      Protocol.http_credentials = http_credentials;
      Protocol.max_redirects = max_redirects;
      Protocol.client_certificates = client_certificates;
      Protocol.fail_on_status_code = fail_on_status_code;
      Protocol.extra_http_headers = extra_http_headers;
      Protocol.ignore_https_errors = ignore_https_errors;
      Protocol.user_agent = user_agent;
      Protocol.base_url = base_url;
    } in
    match Api.Playwright.new_request t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.request.guid } : api_request_context_type obj)
    | Error e -> raise (Error e)

end

module Debug_controller = struct
  type t = debug_controller_type obj

  let initialize ~sdk_language ~codegen_id (t : t) =
    let args : Protocol.debug_controller_initialize_args = {
      Protocol.sdk_language = sdk_language;
      Protocol.codegen_id = codegen_id;
    } in
    match Api.Debug_controller.initialize t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_report_state_changed ~enabled (t : t) =
    let args : Protocol.debug_controller_set_report_state_changed_args = {
      Protocol.enabled = enabled;
    } in
    match Api.Debug_controller.set_report_state_changed t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_recorder_mode ?generate_auto_expect ?test_id_attribute_name ~mode (t : t) =
    let args : Protocol.debug_controller_set_recorder_mode_args = {
      Protocol.generate_auto_expect = generate_auto_expect;
      Protocol.test_id_attribute_name = test_id_attribute_name;
      Protocol.mode = mode;
    } in
    match Api.Debug_controller.set_recorder_mode t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let highlight ?aria_template ?selector (t : t) =
    let args : Protocol.debug_controller_highlight_args = {
      Protocol.aria_template = aria_template;
      Protocol.selector = selector;
    } in
    match Api.Debug_controller.highlight t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let hide_highlight (t : t) =
    match Api.Debug_controller.hide_highlight t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let resume (t : t) =
    match Api.Debug_controller.resume t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let kill (t : t) =
    match Api.Debug_controller.kill t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let on_inspect_requested (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "inspectRequested" (fun msg ->
      match Protocol.debug_controller_inspect_requested_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_inspect_requested ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "inspectRequested" (fun msg ->
      match Protocol.debug_controller_inspect_requested_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "inspectRequested" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_set_mode_requested (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "setModeRequested" (fun msg ->
      match Protocol.debug_controller_set_mode_requested_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_set_mode_requested ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "setModeRequested" (fun msg ->
      match Protocol.debug_controller_set_mode_requested_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "setModeRequested" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_state_changed (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "stateChanged" (fun msg ->
      match Protocol.debug_controller_state_changed_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_state_changed ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "stateChanged" (fun msg ->
      match Protocol.debug_controller_state_changed_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "stateChanged" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_source_changed (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "sourceChanged" (fun msg ->
      match Protocol.debug_controller_source_changed_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_source_changed ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "sourceChanged" (fun msg ->
      match Protocol.debug_controller_source_changed_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "sourceChanged" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_paused (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "paused" (fun msg ->
      match Protocol.debug_controller_paused_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_paused ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "paused" (fun msg ->
      match Protocol.debug_controller_paused_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "paused" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

end

module Socks_support = struct
  type t = socks_support_type obj

  let socks_connected ~port ~host ~uid (t : t) =
    let args : Protocol.socks_support_socks_connected_args = {
      Protocol.port = port;
      Protocol.host = host;
      Protocol.uid = uid;
    } in
    match Api.Socks_support.socks_connected t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let socks_failed ~error_code ~uid (t : t) =
    let args : Protocol.socks_support_socks_failed_args = {
      Protocol.error_code = error_code;
      Protocol.uid = uid;
    } in
    match Api.Socks_support.socks_failed t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let socks_data ~data ~uid (t : t) =
    let args : Protocol.socks_support_socks_data_args = {
      Protocol.data = Base64.encode_exn data;
      Protocol.uid = uid;
    } in
    match Api.Socks_support.socks_data t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let socks_error ~error ~uid (t : t) =
    let args : Protocol.socks_support_socks_error_args = {
      Protocol.error = error;
      Protocol.uid = uid;
    } in
    match Api.Socks_support.socks_error t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let socks_end ~uid (t : t) =
    let args : Protocol.socks_support_socks_end_args = {
      Protocol.uid = uid;
    } in
    match Api.Socks_support.socks_end t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let on_socks_requested (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "socksRequested" (fun msg ->
      match Protocol.socks_support_socks_requested_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_socks_requested ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "socksRequested" (fun msg ->
      match Protocol.socks_support_socks_requested_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "socksRequested" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_socks_data (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "socksData" (fun msg ->
      match Protocol.socks_support_socks_data_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_socks_data ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "socksData" (fun msg ->
      match Protocol.socks_support_socks_data_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "socksData" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_socks_closed (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "socksClosed" (fun msg ->
      match Protocol.socks_support_socks_closed_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_socks_closed ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "socksClosed" (fun msg ->
      match Protocol.socks_support_socks_closed_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "socksClosed" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

end

module Browser_type = struct
  type t = browser_type_type obj

  let launch ?cdp_port ?firefox_user_prefs ?chromium_sandbox ?artifacts_dir ?traces_dir ?downloads_path ?proxy ?headless ?env ~timeout ?handle_sighup ?handle_sigterm ?handle_sigint ?ignore_default_args ?ignore_all_default_args ?args ?executable_path ?channel ?slow_mo (t : t) =
    let args : Protocol.browser_type_launch_args = {
      Protocol.cdp_port = cdp_port;
      Protocol.firefox_user_prefs = firefox_user_prefs;
      Protocol.chromium_sandbox = chromium_sandbox;
      Protocol.artifacts_dir = artifacts_dir;
      Protocol.traces_dir = traces_dir;
      Protocol.downloads_path = downloads_path;
      Protocol.proxy = proxy;
      Protocol.headless = headless;
      Protocol.env = env;
      Protocol.timeout = timeout;
      Protocol.handle_sighup = handle_sighup;
      Protocol.handle_sigterm = handle_sigterm;
      Protocol.handle_sigint = handle_sigint;
      Protocol.ignore_default_args = ignore_default_args;
      Protocol.ignore_all_default_args = ignore_all_default_args;
      Protocol.args = args;
      Protocol.executable_path = executable_path;
      Protocol.channel = channel;
      Protocol.slow_mo = slow_mo;
    } in
    match Api.Browser_type.launch t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.browser.guid } : browser_type obj)
    | Error e -> raise (Error e)

  let launch_persistent_context ?test_id_attribute_name ?selector_engines ?service_workers ?strict_selectors ?record_video ?base_url ?contrast ?accept_downloads ?forced_colors ?reduced_motion ?color_scheme ?has_touch ?is_mobile ?device_scale_factor ?http_credentials ?offline ?extra_http_headers ?permissions ?geolocation ?timezone_id ?locale ?user_agent ?bypass_csp ?java_script_enabled ?client_certificates ?ignore_https_errors ?screen ?viewport ?no_default_viewport ?cdp_port ?firefox_user_prefs ?chromium_sandbox ?artifacts_dir ?traces_dir ?downloads_path ?proxy ?headless ?env ~timeout ?handle_sighup ?handle_sigterm ?handle_sigint ?ignore_default_args ?ignore_all_default_args ?args ?executable_path ?channel ?slow_mo ~user_data_dir (t : t) =
    let args : Protocol.browser_type_launch_persistent_context_args = {
      Protocol.test_id_attribute_name = test_id_attribute_name;
      Protocol.selector_engines = selector_engines;
      Protocol.service_workers = service_workers;
      Protocol.strict_selectors = strict_selectors;
      Protocol.record_video = record_video;
      Protocol.base_url = base_url;
      Protocol.contrast = contrast;
      Protocol.accept_downloads = accept_downloads;
      Protocol.forced_colors = forced_colors;
      Protocol.reduced_motion = reduced_motion;
      Protocol.color_scheme = color_scheme;
      Protocol.has_touch = has_touch;
      Protocol.is_mobile = is_mobile;
      Protocol.device_scale_factor = device_scale_factor;
      Protocol.http_credentials = http_credentials;
      Protocol.offline = offline;
      Protocol.extra_http_headers = extra_http_headers;
      Protocol.permissions = permissions;
      Protocol.geolocation = geolocation;
      Protocol.timezone_id = timezone_id;
      Protocol.locale = locale;
      Protocol.user_agent = user_agent;
      Protocol.bypass_csp = bypass_csp;
      Protocol.java_script_enabled = java_script_enabled;
      Protocol.client_certificates = client_certificates;
      Protocol.ignore_https_errors = ignore_https_errors;
      Protocol.screen = screen;
      Protocol.viewport = viewport;
      Protocol.no_default_viewport = no_default_viewport;
      Protocol.cdp_port = cdp_port;
      Protocol.firefox_user_prefs = firefox_user_prefs;
      Protocol.chromium_sandbox = chromium_sandbox;
      Protocol.artifacts_dir = artifacts_dir;
      Protocol.traces_dir = traces_dir;
      Protocol.downloads_path = downloads_path;
      Protocol.proxy = proxy;
      Protocol.headless = headless;
      Protocol.env = env;
      Protocol.timeout = timeout;
      Protocol.handle_sighup = handle_sighup;
      Protocol.handle_sigterm = handle_sigterm;
      Protocol.handle_sigint = handle_sigint;
      Protocol.ignore_default_args = ignore_default_args;
      Protocol.ignore_all_default_args = ignore_all_default_args;
      Protocol.args = args;
      Protocol.executable_path = executable_path;
      Protocol.channel = channel;
      Protocol.slow_mo = slow_mo;
      Protocol.user_data_dir = user_data_dir;
    } in
    match Api.Browser_type.launch_persistent_context t.conn t.guid args with
    | Ok res -> res
    | Error e -> raise (Error e)

  let connect_over_cdp ?no_defaults ?is_local ~timeout ?slow_mo ?headers ~endpoint_url (t : t) =
    let args : Protocol.browser_type_connect_over_cd_p_args = {
      Protocol.no_defaults = no_defaults;
      Protocol.is_local = is_local;
      Protocol.timeout = timeout;
      Protocol.slow_mo = slow_mo;
      Protocol.headers = headers;
      Protocol.endpoint_url = endpoint_url;
    } in
    match Api.Browser_type.connect_over_cdp t.conn t.guid args with
    | Ok res -> res
    | Error e -> raise (Error e)

  let connect_to_worker ~timeout ~endpoint (t : t) =
    let args : Protocol.browser_type_connect_to_worker_args = {
      Protocol.timeout = timeout;
      Protocol.endpoint = endpoint;
    } in
    match Api.Browser_type.connect_to_worker t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.worker.guid } : worker_type obj)
    | Error e -> raise (Error e)

end

module Browser = struct
  type t = browser_type obj

  let start_server ?port ?host ?metadata ?workspace_dir ~title (t : t) =
    let args : Protocol.browser_start_server_args = {
      Protocol.port = port;
      Protocol.host = host;
      Protocol.metadata = metadata;
      Protocol.workspace_dir = workspace_dir;
      Protocol.title = title;
    } in
    match Api.Browser.start_server t.conn t.guid args with
    | Ok res -> res.Protocol.endpoint
    | Error e -> raise (Error e)

  let stop_server (t : t) =
    match Api.Browser.stop_server t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let close ?reason (t : t) =
    let args : Protocol.browser_close_args = {
      Protocol.reason = reason;
    } in
    match Api.Browser.close t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let kill_for_tests (t : t) =
    match Api.Browser.kill_for_tests t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let default_user_agent_for_test (t : t) =
    match Api.Browser.default_user_agent_for_test t.conn t.guid () with
    | Ok res -> res.Protocol.user_agent
    | Error e -> raise (Error e)

  let new_context ?test_id_attribute_name ?selector_engines ?service_workers ?strict_selectors ?record_video ?base_url ?contrast ?accept_downloads ?forced_colors ?reduced_motion ?color_scheme ?has_touch ?is_mobile ?device_scale_factor ?http_credentials ?offline ?extra_http_headers ?permissions ?geolocation ?timezone_id ?locale ?user_agent ?bypass_csp ?java_script_enabled ?client_certificates ?ignore_https_errors ?screen ?viewport ?no_default_viewport ?storage_state ?proxy (t : t) =
    let args : Protocol.browser_new_context_args = {
      Protocol.test_id_attribute_name = test_id_attribute_name;
      Protocol.selector_engines = selector_engines;
      Protocol.service_workers = service_workers;
      Protocol.strict_selectors = strict_selectors;
      Protocol.record_video = record_video;
      Protocol.base_url = base_url;
      Protocol.contrast = contrast;
      Protocol.accept_downloads = accept_downloads;
      Protocol.forced_colors = forced_colors;
      Protocol.reduced_motion = reduced_motion;
      Protocol.color_scheme = color_scheme;
      Protocol.has_touch = has_touch;
      Protocol.is_mobile = is_mobile;
      Protocol.device_scale_factor = device_scale_factor;
      Protocol.http_credentials = http_credentials;
      Protocol.offline = offline;
      Protocol.extra_http_headers = extra_http_headers;
      Protocol.permissions = permissions;
      Protocol.geolocation = geolocation;
      Protocol.timezone_id = timezone_id;
      Protocol.locale = locale;
      Protocol.user_agent = user_agent;
      Protocol.bypass_csp = bypass_csp;
      Protocol.java_script_enabled = java_script_enabled;
      Protocol.client_certificates = client_certificates;
      Protocol.ignore_https_errors = ignore_https_errors;
      Protocol.screen = screen;
      Protocol.viewport = viewport;
      Protocol.no_default_viewport = no_default_viewport;
      Protocol.storage_state = storage_state;
      Protocol.proxy = proxy;
    } in
    match Api.Browser.new_context t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.context.guid } : browser_context_type obj)
    | Error e -> raise (Error e)

  let new_context_for_reuse ?test_id_attribute_name ?selector_engines ?service_workers ?strict_selectors ?record_video ?base_url ?contrast ?accept_downloads ?forced_colors ?reduced_motion ?color_scheme ?has_touch ?is_mobile ?device_scale_factor ?http_credentials ?offline ?extra_http_headers ?permissions ?geolocation ?timezone_id ?locale ?user_agent ?bypass_csp ?java_script_enabled ?client_certificates ?ignore_https_errors ?screen ?viewport ?no_default_viewport ?storage_state ?proxy (t : t) =
    let args : Protocol.browser_new_context_for_reuse_args = {
      Protocol.test_id_attribute_name = test_id_attribute_name;
      Protocol.selector_engines = selector_engines;
      Protocol.service_workers = service_workers;
      Protocol.strict_selectors = strict_selectors;
      Protocol.record_video = record_video;
      Protocol.base_url = base_url;
      Protocol.contrast = contrast;
      Protocol.accept_downloads = accept_downloads;
      Protocol.forced_colors = forced_colors;
      Protocol.reduced_motion = reduced_motion;
      Protocol.color_scheme = color_scheme;
      Protocol.has_touch = has_touch;
      Protocol.is_mobile = is_mobile;
      Protocol.device_scale_factor = device_scale_factor;
      Protocol.http_credentials = http_credentials;
      Protocol.offline = offline;
      Protocol.extra_http_headers = extra_http_headers;
      Protocol.permissions = permissions;
      Protocol.geolocation = geolocation;
      Protocol.timezone_id = timezone_id;
      Protocol.locale = locale;
      Protocol.user_agent = user_agent;
      Protocol.bypass_csp = bypass_csp;
      Protocol.java_script_enabled = java_script_enabled;
      Protocol.client_certificates = client_certificates;
      Protocol.ignore_https_errors = ignore_https_errors;
      Protocol.screen = screen;
      Protocol.viewport = viewport;
      Protocol.no_default_viewport = no_default_viewport;
      Protocol.storage_state = storage_state;
      Protocol.proxy = proxy;
    } in
    match Api.Browser.new_context_for_reuse t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.context.guid } : browser_context_type obj)
    | Error e -> raise (Error e)

  let disconnect_from_reused_context ~reason (t : t) =
    let args : Protocol.browser_disconnect_from_reused_context_args = {
      Protocol.reason = reason;
    } in
    match Api.Browser.disconnect_from_reused_context t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let new_browser_cdp_session (t : t) =
    match Api.Browser.new_browser_cdp_session t.conn t.guid () with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.session.guid } : cdp_session_type obj)
    | Error e -> raise (Error e)

  let start_tracing ?categories ?screenshots ?page (t : t) =
    let args : Protocol.browser_start_tracing_args = {
      Protocol.categories = categories;
      Protocol.screenshots = screenshots;
      Protocol.page = page;
    } in
    match Api.Browser.start_tracing t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let stop_tracing (t : t) =
    match Api.Browser.stop_tracing t.conn t.guid () with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.artifact.guid } : artifact_type obj)
    | Error e -> raise (Error e)

  let on_context (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "context" (fun msg ->
      match Protocol.browser_context_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_context ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "context" (fun msg ->
      match Protocol.browser_context_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "context" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

end

module Event_target = struct
  type t = event_target_type obj

  let wait_for_event_info ~info (t : t) =
    let args : Protocol.event_target_wait_for_event_info_args = {
      Protocol.info = info;
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

  let add_cookies ~cookies (t : t) =
    let args : Protocol.browser_context_add_cookies_args = {
      Protocol.cookies = cookies;
    } in
    match Api.Browser_context.add_cookies t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let add_init_script ~source (t : t) =
    let args : Protocol.browser_context_add_init_script_args = {
      Protocol.source = source;
    } in
    match Api.Browser_context.add_init_script t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.disposable.guid } : disposable_type obj)
    | Error e -> raise (Error e)

  let clear_cookies ?path_regex_flags ?path_regex_source ?path ?domain_regex_flags ?domain_regex_source ?domain ?name_regex_flags ?name_regex_source ?name (t : t) =
    let args : Protocol.browser_context_clear_cookies_args = {
      Protocol.path_regex_flags = path_regex_flags;
      Protocol.path_regex_source = path_regex_source;
      Protocol.path = path;
      Protocol.domain_regex_flags = domain_regex_flags;
      Protocol.domain_regex_source = domain_regex_source;
      Protocol.domain = domain;
      Protocol.name_regex_flags = name_regex_flags;
      Protocol.name_regex_source = name_regex_source;
      Protocol.name = name;
    } in
    match Api.Browser_context.clear_cookies t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let clear_permissions (t : t) =
    match Api.Browser_context.clear_permissions t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let close ?reason (t : t) =
    let args : Protocol.browser_context_close_args = {
      Protocol.reason = reason;
    } in
    match Api.Browser_context.close t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let cookies ~urls (t : t) =
    let args : Protocol.browser_context_cookies_args = {
      Protocol.urls = urls;
    } in
    match Api.Browser_context.cookies t.conn t.guid args with
    | Ok res -> res.Protocol.cookies
    | Error e -> raise (Error e)

  let expose_binding ~name (t : t) =
    let args : Protocol.browser_context_expose_binding_args = {
      Protocol.name = name;
    } in
    match Api.Browser_context.expose_binding t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.disposable.guid } : disposable_type obj)
    | Error e -> raise (Error e)

  let grant_permissions ?origin ~permissions (t : t) =
    let args : Protocol.browser_context_grant_permissions_args = {
      Protocol.origin = origin;
      Protocol.permissions = permissions;
    } in
    match Api.Browser_context.grant_permissions t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let new_page (t : t) =
    match Api.Browser_context.new_page t.conn t.guid () with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.page.guid } : page_type obj)
    | Error e -> raise (Error e)

  let register_selector_engine ~selector_engine (t : t) =
    let args : Protocol.browser_context_register_selector_engine_args = {
      Protocol.selector_engine = selector_engine;
    } in
    match Api.Browser_context.register_selector_engine t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_test_id_attribute_name ~test_id_attribute_name (t : t) =
    let args : Protocol.browser_context_set_test_id_attribute_name_args = {
      Protocol.test_id_attribute_name = test_id_attribute_name;
    } in
    match Api.Browser_context.set_test_id_attribute_name t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_extra_http_headers ~headers (t : t) =
    let args : Protocol.browser_context_set_extra_http_headers_args = {
      Protocol.headers = headers;
    } in
    match Api.Browser_context.set_extra_http_headers t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_geolocation ?geolocation (t : t) =
    let args : Protocol.browser_context_set_geolocation_args = {
      Protocol.geolocation = geolocation;
    } in
    match Api.Browser_context.set_geolocation t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_http_credentials ?http_credentials (t : t) =
    let args : Protocol.browser_context_set_http_credentials_args = {
      Protocol.http_credentials = http_credentials;
    } in
    match Api.Browser_context.set_http_credentials t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_network_interception_patterns ~patterns (t : t) =
    let args : Protocol.browser_context_set_network_interception_patterns_args = {
      Protocol.patterns = patterns;
    } in
    match Api.Browser_context.set_network_interception_patterns t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_web_socket_interception_patterns ~patterns (t : t) =
    let args : Protocol.browser_context_set_web_socket_interception_patterns_args = {
      Protocol.patterns = patterns;
    } in
    match Api.Browser_context.set_web_socket_interception_patterns t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_offline ~offline (t : t) =
    let args : Protocol.browser_context_set_offline_args = {
      Protocol.offline = offline;
    } in
    match Api.Browser_context.set_offline t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let storage_state ?indexed_db (t : t) =
    let args : Protocol.browser_context_storage_state_args = {
      Protocol.indexed_db = indexed_db;
    } in
    match Api.Browser_context.storage_state t.conn t.guid args with
    | Ok res -> res
    | Error e -> raise (Error e)

  let set_storage_state ?storage_state (t : t) =
    let args : Protocol.browser_context_set_storage_state_args = {
      Protocol.storage_state = storage_state;
    } in
    match Api.Browser_context.set_storage_state t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let pause (t : t) =
    match Api.Browser_context.pause t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let enable_recorder ?omit_call_tracking ?handle_sigint ?output_file ?save_storage ?device ?context_options ?launch_options ?test_id_attribute_name ?pause_on_next_statement ?recorder_mode ?mode ?language (t : t) =
    let args : Protocol.browser_context_enable_recorder_args = {
      Protocol.omit_call_tracking = omit_call_tracking;
      Protocol.handle_sigint = handle_sigint;
      Protocol.output_file = output_file;
      Protocol.save_storage = save_storage;
      Protocol.device = device;
      Protocol.context_options = context_options;
      Protocol.launch_options = launch_options;
      Protocol.test_id_attribute_name = test_id_attribute_name;
      Protocol.pause_on_next_statement = pause_on_next_statement;
      Protocol.recorder_mode = recorder_mode;
      Protocol.mode = mode;
      Protocol.language = language;
    } in
    match Api.Browser_context.enable_recorder t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let disable_recorder (t : t) =
    match Api.Browser_context.disable_recorder t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let expose_console_api (t : t) =
    match Api.Browser_context.expose_console_api t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let new_cdp_session ?frame ?page (t : t) =
    let args : Protocol.browser_context_new_cdp_session_args = {
      Protocol.frame = frame;
      Protocol.page = page;
    } in
    match Api.Browser_context.new_cdp_session t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.session.guid } : cdp_session_type obj)
    | Error e -> raise (Error e)

  let create_temp_files ~items ?root_dir_name (t : t) =
    let args : Protocol.browser_context_create_temp_files_args = {
      Protocol.items = items;
      Protocol.root_dir_name = root_dir_name;
    } in
    match Api.Browser_context.create_temp_files t.conn t.guid args with
    | Ok res -> res
    | Error e -> raise (Error e)

  let update_subscription ~enabled ~event (t : t) =
    let args : Protocol.browser_context_update_subscription_args = {
      Protocol.enabled = enabled;
      Protocol.event = event;
    } in
    match Api.Browser_context.update_subscription t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let clock_fast_forward ?ticks_string ?ticks_number (t : t) =
    let args : Protocol.browser_context_clock_fast_forward_args = {
      Protocol.ticks_string = ticks_string;
      Protocol.ticks_number = ticks_number;
    } in
    match Api.Browser_context.clock_fast_forward t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let clock_install ?time_string ?time_number (t : t) =
    let args : Protocol.browser_context_clock_install_args = {
      Protocol.time_string = time_string;
      Protocol.time_number = time_number;
    } in
    match Api.Browser_context.clock_install t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let clock_pause_at ?time_string ?time_number (t : t) =
    let args : Protocol.browser_context_clock_pause_at_args = {
      Protocol.time_string = time_string;
      Protocol.time_number = time_number;
    } in
    match Api.Browser_context.clock_pause_at t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let clock_resume (t : t) =
    match Api.Browser_context.clock_resume t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let clock_run_for ?ticks_string ?ticks_number (t : t) =
    let args : Protocol.browser_context_clock_run_for_args = {
      Protocol.ticks_string = ticks_string;
      Protocol.ticks_number = ticks_number;
    } in
    match Api.Browser_context.clock_run_for t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let clock_set_fixed_time ?time_string ?time_number (t : t) =
    let args : Protocol.browser_context_clock_set_fixed_time_args = {
      Protocol.time_string = time_string;
      Protocol.time_number = time_number;
    } in
    match Api.Browser_context.clock_set_fixed_time t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let clock_set_system_time ?time_string ?time_number (t : t) =
    let args : Protocol.browser_context_clock_set_system_time_args = {
      Protocol.time_string = time_string;
      Protocol.time_number = time_number;
    } in
    match Api.Browser_context.clock_set_system_time t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let on_binding_call (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "bindingCall" (fun msg ->
      match Protocol.browser_context_binding_call_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_binding_call ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "bindingCall" (fun msg ->
      match Protocol.browser_context_binding_call_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "bindingCall" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_console (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "console" (fun msg ->
      match Protocol.browser_context_console_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_console ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "console" (fun msg ->
      match Protocol.browser_context_console_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "console" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_dialog (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "dialog" (fun msg ->
      match Protocol.browser_context_dialog_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_dialog ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "dialog" (fun msg ->
      match Protocol.browser_context_dialog_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "dialog" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_page (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "page" (fun msg ->
      match Protocol.browser_context_page_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_page ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "page" (fun msg ->
      match Protocol.browser_context_page_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "page" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_page_error (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "pageError" (fun msg ->
      match Protocol.browser_context_page_error_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_page_error ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "pageError" (fun msg ->
      match Protocol.browser_context_page_error_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "pageError" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_route (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "route" (fun msg ->
      match Protocol.browser_context_route_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_route ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "route" (fun msg ->
      match Protocol.browser_context_route_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "route" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_web_socket_route (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "webSocketRoute" (fun msg ->
      match Protocol.browser_context_web_socket_route_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_web_socket_route ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "webSocketRoute" (fun msg ->
      match Protocol.browser_context_web_socket_route_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "webSocketRoute" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_service_worker (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "serviceWorker" (fun msg ->
      match Protocol.browser_context_service_worker_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_service_worker ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "serviceWorker" (fun msg ->
      match Protocol.browser_context_service_worker_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "serviceWorker" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_request (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "request" (fun msg ->
      match Protocol.browser_context_request_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_request ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "request" (fun msg ->
      match Protocol.browser_context_request_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "request" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_request_failed (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "requestFailed" (fun msg ->
      match Protocol.browser_context_request_failed_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_request_failed ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "requestFailed" (fun msg ->
      match Protocol.browser_context_request_failed_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "requestFailed" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_request_finished (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "requestFinished" (fun msg ->
      match Protocol.browser_context_request_finished_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_request_finished ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "requestFinished" (fun msg ->
      match Protocol.browser_context_request_finished_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "requestFinished" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_response (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "response" (fun msg ->
      match Protocol.browser_context_response_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_response ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "response" (fun msg ->
      match Protocol.browser_context_response_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "response" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_recorder_event (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "recorderEvent" (fun msg ->
      match Protocol.browser_context_recorder_event_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_recorder_event ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "recorderEvent" (fun msg ->
      match Protocol.browser_context_recorder_event_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "recorderEvent" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

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

  let add_init_script ~source (t : t) =
    let args : Protocol.page_add_init_script_args = {
      Protocol.source = source;
    } in
    match Api.Page.add_init_script t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.disposable.guid } : disposable_type obj)
    | Error e -> raise (Error e)

  let close ?reason ?run_before_unload (t : t) =
    let args : Protocol.page_close_args = {
      Protocol.reason = reason;
      Protocol.run_before_unload = run_before_unload;
    } in
    match Api.Page.close t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let clear_console_messages (t : t) =
    match Api.Page.clear_console_messages t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let console_messages ?filter (t : t) =
    let args : Protocol.page_console_messages_args = {
      Protocol.filter = filter;
    } in
    match Api.Page.console_messages t.conn t.guid args with
    | Ok res -> res.Protocol.messages
    | Error e -> raise (Error e)

  let emulate_media ?contrast ?forced_colors ?reduced_motion ?color_scheme ?media (t : t) =
    let args : Protocol.page_emulate_media_args = {
      Protocol.contrast = contrast;
      Protocol.forced_colors = forced_colors;
      Protocol.reduced_motion = reduced_motion;
      Protocol.color_scheme = color_scheme;
      Protocol.media = media;
    } in
    match Api.Page.emulate_media t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let expose_binding ~name (t : t) =
    let args : Protocol.page_expose_binding_args = {
      Protocol.name = name;
    } in
    match Api.Page.expose_binding t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.disposable.guid } : disposable_type obj)
    | Error e -> raise (Error e)

  let go_back ?wait_until ~timeout (t : t) =
    let args : Protocol.page_go_back_args = {
      Protocol.wait_until = wait_until;
      Protocol.timeout = timeout;
    } in
    match Api.Page.go_back t.conn t.guid args with
    | Ok res -> res.Protocol.response
    | Error e -> raise (Error e)

  let go_forward ?wait_until ~timeout (t : t) =
    let args : Protocol.page_go_forward_args = {
      Protocol.wait_until = wait_until;
      Protocol.timeout = timeout;
    } in
    match Api.Page.go_forward t.conn t.guid args with
    | Ok res -> res.Protocol.response
    | Error e -> raise (Error e)

  let request_gc (t : t) =
    match Api.Page.request_gc t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let register_locator_handler ?no_wait_after ~selector (t : t) =
    let args : Protocol.page_register_locator_handler_args = {
      Protocol.no_wait_after = no_wait_after;
      Protocol.selector = selector;
    } in
    match Api.Page.register_locator_handler t.conn t.guid args with
    | Ok res -> res.Protocol.uid
    | Error e -> raise (Error e)

  let resolve_locator_handler_no_reply ?remove ~uid (t : t) =
    let args : Protocol.page_resolve_locator_handler_no_reply_args = {
      Protocol.remove = remove;
      Protocol.uid = uid;
    } in
    match Api.Page.resolve_locator_handler_no_reply t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let unregister_locator_handler ~uid (t : t) =
    let args : Protocol.page_unregister_locator_handler_args = {
      Protocol.uid = uid;
    } in
    match Api.Page.unregister_locator_handler t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let reload ?wait_until ~timeout (t : t) =
    let args : Protocol.page_reload_args = {
      Protocol.wait_until = wait_until;
      Protocol.timeout = timeout;
    } in
    match Api.Page.reload t.conn t.guid args with
    | Ok res -> res.Protocol.response
    | Error e -> raise (Error e)

  let expect_screenshot ?style ?mask_color ?mask ?scale ?animations ?caret ?omit_background ?clip ?full_page ?threshold ?max_diff_pixel_ratio ?max_diff_pixels ?comparator ?locator ~is_not ~timeout ?expected (t : t) =
    let args : Protocol.page_expect_screenshot_args = {
      Protocol.style = style;
      Protocol.mask_color = mask_color;
      Protocol.mask = mask;
      Protocol.scale = scale;
      Protocol.animations = animations;
      Protocol.caret = caret;
      Protocol.omit_background = omit_background;
      Protocol.clip = clip;
      Protocol.full_page = full_page;
      Protocol.threshold = threshold;
      Protocol.max_diff_pixel_ratio = max_diff_pixel_ratio;
      Protocol.max_diff_pixels = max_diff_pixels;
      Protocol.comparator = comparator;
      Protocol.locator = locator;
      Protocol.is_not = is_not;
      Protocol.timeout = timeout;
      Protocol.expected = Option.map Base64.encode_exn expected;
    } in
    match Api.Page.expect_screenshot t.conn t.guid args with
    | Ok res -> res
    | Error e -> raise (Error e)

  let screenshot ?style ?mask_color ?mask ?scale ?animations ?caret ?omit_background ?clip ?full_page ?quality ?type_ ~timeout (t : t) =
    let args : Protocol.page_screenshot_args = {
      Protocol.style = style;
      Protocol.mask_color = mask_color;
      Protocol.mask = mask;
      Protocol.scale = scale;
      Protocol.animations = animations;
      Protocol.caret = caret;
      Protocol.omit_background = omit_background;
      Protocol.clip = clip;
      Protocol.full_page = full_page;
      Protocol.quality = quality;
      Protocol.type_ = type_;
      Protocol.timeout = timeout;
    } in
    match Api.Page.screenshot t.conn t.guid args with
    | Ok res -> Base64.decode_exn res.Protocol.binary
    | Error e -> raise (Error e)

  let set_extra_http_headers ~headers (t : t) =
    let args : Protocol.page_set_extra_http_headers_args = {
      Protocol.headers = headers;
    } in
    match Api.Page.set_extra_http_headers t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_network_interception_patterns ~patterns (t : t) =
    let args : Protocol.page_set_network_interception_patterns_args = {
      Protocol.patterns = patterns;
    } in
    match Api.Page.set_network_interception_patterns t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_web_socket_interception_patterns ~patterns (t : t) =
    let args : Protocol.page_set_web_socket_interception_patterns_args = {
      Protocol.patterns = patterns;
    } in
    match Api.Page.set_web_socket_interception_patterns t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_viewport_size ~viewport_size (t : t) =
    let args : Protocol.page_set_viewport_size_args = {
      Protocol.viewport_size = viewport_size;
    } in
    match Api.Page.set_viewport_size t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let keyboard_down ~key (t : t) =
    let args : Protocol.page_keyboard_down_args = {
      Protocol.key = key;
    } in
    match Api.Page.keyboard_down t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let keyboard_up ~key (t : t) =
    let args : Protocol.page_keyboard_up_args = {
      Protocol.key = key;
    } in
    match Api.Page.keyboard_up t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let keyboard_insert_text ~text (t : t) =
    let args : Protocol.page_keyboard_insert_text_args = {
      Protocol.text = text;
    } in
    match Api.Page.keyboard_insert_text t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let keyboard_type ?delay ~text (t : t) =
    let args : Protocol.page_keyboard_type_args = {
      Protocol.delay = delay;
      Protocol.text = text;
    } in
    match Api.Page.keyboard_type t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let keyboard_press ?delay ~key (t : t) =
    let args : Protocol.page_keyboard_press_args = {
      Protocol.delay = delay;
      Protocol.key = key;
    } in
    match Api.Page.keyboard_press t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let mouse_move ?steps ~y ~x (t : t) =
    let args : Protocol.page_mouse_move_args = {
      Protocol.steps = steps;
      Protocol.y = y;
      Protocol.x = x;
    } in
    match Api.Page.mouse_move t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let mouse_down ?click_count ?button (t : t) =
    let args : Protocol.page_mouse_down_args = {
      Protocol.click_count = click_count;
      Protocol.button = button;
    } in
    match Api.Page.mouse_down t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let mouse_up ?click_count ?button (t : t) =
    let args : Protocol.page_mouse_up_args = {
      Protocol.click_count = click_count;
      Protocol.button = button;
    } in
    match Api.Page.mouse_up t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let mouse_click ?click_count ?button ?delay ~y ~x (t : t) =
    let args : Protocol.page_mouse_click_args = {
      Protocol.click_count = click_count;
      Protocol.button = button;
      Protocol.delay = delay;
      Protocol.y = y;
      Protocol.x = x;
    } in
    match Api.Page.mouse_click t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let mouse_wheel ~delta_y ~delta_x (t : t) =
    let args : Protocol.page_mouse_wheel_args = {
      Protocol.delta_y = delta_y;
      Protocol.delta_x = delta_x;
    } in
    match Api.Page.mouse_wheel t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let touchscreen_tap ~y ~x (t : t) =
    let args : Protocol.page_touchscreen_tap_args = {
      Protocol.y = y;
      Protocol.x = x;
    } in
    match Api.Page.touchscreen_tap t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let clear_page_errors (t : t) =
    match Api.Page.clear_page_errors t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let page_errors ?filter (t : t) =
    let args : Protocol.page_page_errors_args = {
      Protocol.filter = filter;
    } in
    match Api.Page.page_errors t.conn t.guid args with
    | Ok res -> res.Protocol.errors
    | Error e -> raise (Error e)

  let pdf ?outline ?tagged ?margin ?prefer_css_page_size ?height ?width ?format ?page_ranges ?landscape ?print_background ?footer_template ?header_template ?display_header_footer ?scale (t : t) =
    let args : Protocol.page_pdf_args = {
      Protocol.outline = outline;
      Protocol.tagged = tagged;
      Protocol.margin = margin;
      Protocol.prefer_css_page_size = prefer_css_page_size;
      Protocol.height = height;
      Protocol.width = width;
      Protocol.format = format;
      Protocol.page_ranges = page_ranges;
      Protocol.landscape = landscape;
      Protocol.print_background = print_background;
      Protocol.footer_template = footer_template;
      Protocol.header_template = header_template;
      Protocol.display_header_footer = display_header_footer;
      Protocol.scale = scale;
    } in
    match Api.Page.pdf t.conn t.guid args with
    | Ok res -> Base64.decode_exn res.Protocol.pdf
    | Error e -> raise (Error e)

  let requests (t : t) =
    match Api.Page.requests t.conn t.guid () with
    | Ok res -> res.Protocol.requests
    | Error e -> raise (Error e)

  let start_js_coverage ?report_anonymous_scripts ?reset_on_navigation (t : t) =
    let args : Protocol.page_start_js_coverage_args = {
      Protocol.report_anonymous_scripts = report_anonymous_scripts;
      Protocol.reset_on_navigation = reset_on_navigation;
    } in
    match Api.Page.start_js_coverage t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let stop_js_coverage (t : t) =
    match Api.Page.stop_js_coverage t.conn t.guid () with
    | Ok res -> res.Protocol.entries
    | Error e -> raise (Error e)

  let start_css_coverage ?reset_on_navigation (t : t) =
    let args : Protocol.page_start_css_coverage_args = {
      Protocol.reset_on_navigation = reset_on_navigation;
    } in
    match Api.Page.start_css_coverage t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let stop_css_coverage (t : t) =
    match Api.Page.stop_css_coverage t.conn t.guid () with
    | Ok res -> res.Protocol.entries
    | Error e -> raise (Error e)

  let bring_to_front (t : t) =
    match Api.Page.bring_to_front t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let pick_locator (t : t) =
    match Api.Page.pick_locator t.conn t.guid () with
    | Ok res -> res.Protocol.selector
    | Error e -> raise (Error e)

  let cancel_pick_locator (t : t) =
    match Api.Page.cancel_pick_locator t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let hide_highlight (t : t) =
    match Api.Page.hide_highlight t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let screencast_show_overlay ?duration ~html (t : t) =
    let args : Protocol.page_screencast_show_overlay_args = {
      Protocol.duration = duration;
      Protocol.html = html;
    } in
    match Api.Page.screencast_show_overlay t.conn t.guid args with
    | Ok res -> res.Protocol.id
    | Error e -> raise (Error e)

  let screencast_remove_overlay ~id (t : t) =
    let args : Protocol.page_screencast_remove_overlay_args = {
      Protocol.id = id;
    } in
    match Api.Page.screencast_remove_overlay t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let screencast_chapter ?duration ?description ~title (t : t) =
    let args : Protocol.page_screencast_chapter_args = {
      Protocol.duration = duration;
      Protocol.description = description;
      Protocol.title = title;
    } in
    match Api.Page.screencast_chapter t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let screencast_set_overlay_visible ~visible (t : t) =
    let args : Protocol.page_screencast_set_overlay_visible_args = {
      Protocol.visible = visible;
    } in
    match Api.Page.screencast_set_overlay_visible t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let screencast_show_actions ?font_size ?position ?duration (t : t) =
    let args : Protocol.page_screencast_show_actions_args = {
      Protocol.font_size = font_size;
      Protocol.position = position;
      Protocol.duration = duration;
    } in
    match Api.Page.screencast_show_actions t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let screencast_hide_actions (t : t) =
    match Api.Page.screencast_hide_actions t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let screencast_start ?record ?send_frames ?quality ?size (t : t) =
    let args : Protocol.page_screencast_start_args = {
      Protocol.record = record;
      Protocol.send_frames = send_frames;
      Protocol.quality = quality;
      Protocol.size = size;
    } in
    match Api.Page.screencast_start t.conn t.guid args with
    | Ok res -> res.Protocol.artifact
    | Error e -> raise (Error e)

  let screencast_stop (t : t) =
    match Api.Page.screencast_stop t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let update_subscription ~enabled ~event (t : t) =
    let args : Protocol.page_update_subscription_args = {
      Protocol.enabled = enabled;
      Protocol.event = event;
    } in
    match Api.Page.update_subscription t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_dock_tile ~image (t : t) =
    let args : Protocol.page_set_dock_tile_args = {
      Protocol.image = Base64.encode_exn image;
    } in
    match Api.Page.set_dock_tile t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let on_binding_call (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "bindingCall" (fun msg ->
      match Protocol.page_binding_call_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_binding_call ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "bindingCall" (fun msg ->
      match Protocol.page_binding_call_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "bindingCall" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_download (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "download" (fun msg ->
      match Protocol.page_download_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_download ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "download" (fun msg ->
      match Protocol.page_download_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "download" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_viewport_size_changed (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "viewportSizeChanged" (fun msg ->
      match Protocol.page_viewport_size_changed_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_viewport_size_changed ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "viewportSizeChanged" (fun msg ->
      match Protocol.page_viewport_size_changed_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "viewportSizeChanged" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_file_chooser (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "fileChooser" (fun msg ->
      match Protocol.page_file_chooser_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_file_chooser ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "fileChooser" (fun msg ->
      match Protocol.page_file_chooser_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "fileChooser" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_frame_attached (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "frameAttached" (fun msg ->
      match Protocol.page_frame_attached_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_frame_attached ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "frameAttached" (fun msg ->
      match Protocol.page_frame_attached_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "frameAttached" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_frame_detached (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "frameDetached" (fun msg ->
      match Protocol.page_frame_detached_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_frame_detached ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "frameDetached" (fun msg ->
      match Protocol.page_frame_detached_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "frameDetached" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_locator_handler_triggered (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "locatorHandlerTriggered" (fun msg ->
      match Protocol.page_locator_handler_triggered_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_locator_handler_triggered ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "locatorHandlerTriggered" (fun msg ->
      match Protocol.page_locator_handler_triggered_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "locatorHandlerTriggered" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_route (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "route" (fun msg ->
      match Protocol.page_route_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_route ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "route" (fun msg ->
      match Protocol.page_route_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "route" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_screencast_frame (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "screencastFrame" (fun msg ->
      match Protocol.page_screencast_frame_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_screencast_frame ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "screencastFrame" (fun msg ->
      match Protocol.page_screencast_frame_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "screencastFrame" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_web_socket_route (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "webSocketRoute" (fun msg ->
      match Protocol.page_web_socket_route_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_web_socket_route ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "webSocketRoute" (fun msg ->
      match Protocol.page_web_socket_route_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "webSocketRoute" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_web_socket (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "webSocket" (fun msg ->
      match Protocol.page_web_socket_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_web_socket ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "webSocket" (fun msg ->
      match Protocol.page_web_socket_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "webSocket" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_worker (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "worker" (fun msg ->
      match Protocol.page_worker_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_worker ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "worker" (fun msg ->
      match Protocol.page_worker_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "worker" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

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

  let eval_on_selector ~arg ?is_function ~expression ?strict ~selector (t : t) =
    let args : Protocol.frame_eval_on_selector_args = {
      Protocol.arg = arg;
      Protocol.is_function = is_function;
      Protocol.expression = expression;
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.eval_on_selector t.conn t.guid args with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let eval_on_selector_all ~arg ?is_function ~expression ~selector (t : t) =
    let args : Protocol.frame_eval_on_selector_all_args = {
      Protocol.arg = arg;
      Protocol.is_function = is_function;
      Protocol.expression = expression;
      Protocol.selector = selector;
    } in
    match Api.Frame.eval_on_selector_all t.conn t.guid args with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let add_script_tag ?type_ ?content ?url (t : t) =
    let args : Protocol.frame_add_script_tag_args = {
      Protocol.type_ = type_;
      Protocol.content = content;
      Protocol.url = url;
    } in
    match Api.Frame.add_script_tag t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.element.guid } : element_handle_type obj)
    | Error e -> raise (Error e)

  let add_style_tag ?content ?url (t : t) =
    let args : Protocol.frame_add_style_tag_args = {
      Protocol.content = content;
      Protocol.url = url;
    } in
    match Api.Frame.add_style_tag t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.element.guid } : element_handle_type obj)
    | Error e -> raise (Error e)

  let aria_ref ~timeout ~selector (t : t) =
    let args : Protocol.frame_aria_ref_args = {
      Protocol.timeout = timeout;
      Protocol.selector = selector;
    } in
    match Api.Frame.aria_ref t.conn t.guid args with
    | Ok res -> res.Protocol.ref
    | Error e -> raise (Error e)

  let aria_snapshot ~timeout ?boxes ?depth ?selector ?track ?mode (t : t) =
    let args : Protocol.frame_aria_snapshot_args = {
      Protocol.timeout = timeout;
      Protocol.boxes = boxes;
      Protocol.depth = depth;
      Protocol.selector = selector;
      Protocol.track = track;
      Protocol.mode = mode;
    } in
    match Api.Frame.aria_snapshot t.conn t.guid args with
    | Ok res -> res.Protocol.snapshot
    | Error e -> raise (Error e)

  let blur ~timeout ?strict ~selector (t : t) =
    let args : Protocol.frame_blur_args = {
      Protocol.timeout = timeout;
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.blur t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let check ?trial ~timeout ?position ?force ?strict ~selector (t : t) =
    let args : Protocol.frame_check_args = {
      Protocol.trial = trial;
      Protocol.timeout = timeout;
      Protocol.position = position;
      Protocol.force = force;
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.check t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let click ?steps ?trial ~timeout ?click_count ?button ?delay ?position ?modifiers ?no_wait_after ?force ?strict ~selector (t : t) =
    let args : Protocol.frame_click_args = {
      Protocol.steps = steps;
      Protocol.trial = trial;
      Protocol.timeout = timeout;
      Protocol.click_count = click_count;
      Protocol.button = button;
      Protocol.delay = delay;
      Protocol.position = position;
      Protocol.modifiers = modifiers;
      Protocol.no_wait_after = no_wait_after;
      Protocol.force = force;
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.click t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let content (t : t) =
    match Api.Frame.content t.conn t.guid () with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let drag_and_drop ?steps ?strict ?target_position ?source_position ?trial ~timeout ?force ~target ~source (t : t) =
    let args : Protocol.frame_drag_and_drop_args = {
      Protocol.steps = steps;
      Protocol.strict = strict;
      Protocol.target_position = target_position;
      Protocol.source_position = source_position;
      Protocol.trial = trial;
      Protocol.timeout = timeout;
      Protocol.force = force;
      Protocol.target = target;
      Protocol.source = source;
    } in
    match Api.Frame.drag_and_drop t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let drop ~timeout ?data ?streams ?local_paths ?payloads ?position ?strict ~selector (t : t) =
    let args : Protocol.frame_drop_args = {
      Protocol.timeout = timeout;
      Protocol.data = data;
      Protocol.streams = streams;
      Protocol.local_paths = local_paths;
      Protocol.payloads = payloads;
      Protocol.position = position;
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.drop t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let dblclick ?steps ?trial ~timeout ?button ?delay ?position ?modifiers ?force ?strict ~selector (t : t) =
    let args : Protocol.frame_dblclick_args = {
      Protocol.steps = steps;
      Protocol.trial = trial;
      Protocol.timeout = timeout;
      Protocol.button = button;
      Protocol.delay = delay;
      Protocol.position = position;
      Protocol.modifiers = modifiers;
      Protocol.force = force;
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.dblclick t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let dispatch_event ~timeout ~event_init ~type_ ?strict ~selector (t : t) =
    let args : Protocol.frame_dispatch_event_args = {
      Protocol.timeout = timeout;
      Protocol.event_init = event_init;
      Protocol.type_ = type_;
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.dispatch_event t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let evaluate_expression ~arg ?is_function ~expression (t : t) =
    let args : Protocol.frame_evaluate_expression_args = {
      Protocol.arg = arg;
      Protocol.is_function = is_function;
      Protocol.expression = expression;
    } in
    match Api.Frame.evaluate_expression t.conn t.guid args with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let evaluate_expression_handle ~arg ?is_function ~expression (t : t) =
    let args : Protocol.frame_evaluate_expression_handle_args = {
      Protocol.arg = arg;
      Protocol.is_function = is_function;
      Protocol.expression = expression;
    } in
    match Api.Frame.evaluate_expression_handle t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.handle.guid } : js_handle_type obj)
    | Error e -> raise (Error e)

  let fill ~timeout ?force ~value ?strict ~selector (t : t) =
    let args : Protocol.frame_fill_args = {
      Protocol.timeout = timeout;
      Protocol.force = force;
      Protocol.value = value;
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.fill t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let focus ~timeout ?strict ~selector (t : t) =
    let args : Protocol.frame_focus_args = {
      Protocol.timeout = timeout;
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.focus t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let frame_element (t : t) =
    match Api.Frame.frame_element t.conn t.guid () with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.element.guid } : element_handle_type obj)
    | Error e -> raise (Error e)

  let resolve_selector ~selector (t : t) =
    let args : Protocol.frame_resolve_selector_args = {
      Protocol.selector = selector;
    } in
    match Api.Frame.resolve_selector t.conn t.guid args with
    | Ok res -> res.Protocol.resolved_selector
    | Error e -> raise (Error e)

  let highlight ?style ~selector (t : t) =
    let args : Protocol.frame_highlight_args = {
      Protocol.style = style;
      Protocol.selector = selector;
    } in
    match Api.Frame.highlight t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let hide_highlight ~selector (t : t) =
    let args : Protocol.frame_hide_highlight_args = {
      Protocol.selector = selector;
    } in
    match Api.Frame.hide_highlight t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let get_attribute ~timeout ~name ?strict ~selector (t : t) =
    let args : Protocol.frame_get_attribute_args = {
      Protocol.timeout = timeout;
      Protocol.name = name;
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.get_attribute t.conn t.guid args with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let goto ?referer ?wait_until ~timeout ~url (t : t) =
    let args : Protocol.frame_goto_args = {
      Protocol.referer = referer;
      Protocol.wait_until = wait_until;
      Protocol.timeout = timeout;
      Protocol.url = url;
    } in
    match Api.Frame.goto t.conn t.guid args with
    | Ok res -> res.Protocol.response
    | Error e -> raise (Error e)

  let hover ?trial ~timeout ?position ?modifiers ?force ?strict ~selector (t : t) =
    let args : Protocol.frame_hover_args = {
      Protocol.trial = trial;
      Protocol.timeout = timeout;
      Protocol.position = position;
      Protocol.modifiers = modifiers;
      Protocol.force = force;
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.hover t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let inner_html ~timeout ?strict ~selector (t : t) =
    let args : Protocol.frame_inner_htm_l_args = {
      Protocol.timeout = timeout;
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.inner_html t.conn t.guid args with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let inner_text ~timeout ?strict ~selector (t : t) =
    let args : Protocol.frame_inner_text_args = {
      Protocol.timeout = timeout;
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.inner_text t.conn t.guid args with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let input_value ~timeout ?strict ~selector (t : t) =
    let args : Protocol.frame_input_value_args = {
      Protocol.timeout = timeout;
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.input_value t.conn t.guid args with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let is_checked ~timeout ?strict ~selector (t : t) =
    let args : Protocol.frame_is_checked_args = {
      Protocol.timeout = timeout;
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.is_checked t.conn t.guid args with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let is_disabled ~timeout ?strict ~selector (t : t) =
    let args : Protocol.frame_is_disabled_args = {
      Protocol.timeout = timeout;
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.is_disabled t.conn t.guid args with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let is_enabled ~timeout ?strict ~selector (t : t) =
    let args : Protocol.frame_is_enabled_args = {
      Protocol.timeout = timeout;
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.is_enabled t.conn t.guid args with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let is_hidden ?strict ~selector (t : t) =
    let args : Protocol.frame_is_hidden_args = {
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.is_hidden t.conn t.guid args with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let is_visible ?strict ~selector (t : t) =
    let args : Protocol.frame_is_visible_args = {
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.is_visible t.conn t.guid args with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let is_editable ~timeout ?strict ~selector (t : t) =
    let args : Protocol.frame_is_editable_args = {
      Protocol.timeout = timeout;
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.is_editable t.conn t.guid args with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let press ~timeout ?no_wait_after ?delay ~key ?strict ~selector (t : t) =
    let args : Protocol.frame_press_args = {
      Protocol.timeout = timeout;
      Protocol.no_wait_after = no_wait_after;
      Protocol.delay = delay;
      Protocol.key = key;
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.press t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let query_selector ?strict ~selector (t : t) =
    let args : Protocol.frame_query_selector_args = {
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.query_selector t.conn t.guid args with
    | Ok res -> res.Protocol.element
    | Error e -> raise (Error e)

  let query_selector_all ~selector (t : t) =
    let args : Protocol.frame_query_selector_all_args = {
      Protocol.selector = selector;
    } in
    match Api.Frame.query_selector_all t.conn t.guid args with
    | Ok res -> res.Protocol.elements
    | Error e -> raise (Error e)

  let query_count ~selector (t : t) =
    let args : Protocol.frame_query_count_args = {
      Protocol.selector = selector;
    } in
    match Api.Frame.query_count t.conn t.guid args with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let select_option ~timeout ?force ?options ?elements ?strict ~selector (t : t) =
    let args : Protocol.frame_select_option_args = {
      Protocol.timeout = timeout;
      Protocol.force = force;
      Protocol.options = options;
      Protocol.elements = elements;
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.select_option t.conn t.guid args with
    | Ok res -> res.Protocol.values
    | Error e -> raise (Error e)

  let set_content ?wait_until ~timeout ~html (t : t) =
    let args : Protocol.frame_set_content_args = {
      Protocol.wait_until = wait_until;
      Protocol.timeout = timeout;
      Protocol.html = html;
    } in
    match Api.Frame.set_content t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_input_files ~timeout ?streams ?local_paths ?directory_stream ?local_directory ?payloads ?strict ~selector (t : t) =
    let args : Protocol.frame_set_input_files_args = {
      Protocol.timeout = timeout;
      Protocol.streams = streams;
      Protocol.local_paths = local_paths;
      Protocol.directory_stream = directory_stream;
      Protocol.local_directory = local_directory;
      Protocol.payloads = payloads;
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.set_input_files t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let tap ?trial ~timeout ?position ?modifiers ?force ?strict ~selector (t : t) =
    let args : Protocol.frame_tap_args = {
      Protocol.trial = trial;
      Protocol.timeout = timeout;
      Protocol.position = position;
      Protocol.modifiers = modifiers;
      Protocol.force = force;
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.tap t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let text_content ~timeout ?strict ~selector (t : t) =
    let args : Protocol.frame_text_content_args = {
      Protocol.timeout = timeout;
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.text_content t.conn t.guid args with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let title (t : t) =
    match Api.Frame.title t.conn t.guid () with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let type_ ~timeout ?delay ~text ?strict ~selector (t : t) =
    let args : Protocol.frame_type_args = {
      Protocol.timeout = timeout;
      Protocol.delay = delay;
      Protocol.text = text;
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.type_ t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let uncheck ?trial ~timeout ?position ?force ?strict ~selector (t : t) =
    let args : Protocol.frame_uncheck_args = {
      Protocol.trial = trial;
      Protocol.timeout = timeout;
      Protocol.position = position;
      Protocol.force = force;
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.uncheck t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let wait_for_timeout ~wait_timeout (t : t) =
    let args : Protocol.frame_wait_for_timeout_args = {
      Protocol.wait_timeout = wait_timeout;
    } in
    match Api.Frame.wait_for_timeout t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let wait_for_function ?polling_interval ~timeout ~arg ?is_function ~expression (t : t) =
    let args : Protocol.frame_wait_for_function_args = {
      Protocol.polling_interval = polling_interval;
      Protocol.timeout = timeout;
      Protocol.arg = arg;
      Protocol.is_function = is_function;
      Protocol.expression = expression;
    } in
    match Api.Frame.wait_for_function t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.handle.guid } : js_handle_type obj)
    | Error e -> raise (Error e)

  let wait_for_selector ?omit_return_value ?state ~timeout ?strict ~selector (t : t) =
    let args : Protocol.frame_wait_for_selector_args = {
      Protocol.omit_return_value = omit_return_value;
      Protocol.state = state;
      Protocol.timeout = timeout;
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Frame.wait_for_selector t.conn t.guid args with
    | Ok res -> res.Protocol.element
    | Error e -> raise (Error e)

  let expect ~timeout ~is_not ?use_inner_text ?expected_value ?expected_number ?expected_text ?pseudo ?expression_arg ~expression ?selector (t : t) =
    let args : Protocol.frame_expect_args = {
      Protocol.timeout = timeout;
      Protocol.is_not = is_not;
      Protocol.use_inner_text = use_inner_text;
      Protocol.expected_value = expected_value;
      Protocol.expected_number = expected_number;
      Protocol.expected_text = expected_text;
      Protocol.pseudo = pseudo;
      Protocol.expression_arg = expression_arg;
      Protocol.expression = expression;
      Protocol.selector = selector;
    } in
    match Api.Frame.expect t.conn t.guid args with
    | Ok res -> res
    | Error e -> raise (Error e)

  let on_loadstate (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "loadstate" (fun msg ->
      match Protocol.frame_loadstate_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_loadstate ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "loadstate" (fun msg ->
      match Protocol.frame_loadstate_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "loadstate" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_navigated (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "navigated" (fun msg ->
      match Protocol.frame_navigated_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_navigated ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "navigated" (fun msg ->
      match Protocol.frame_navigated_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "navigated" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

end

module Worker = struct
  type t = worker_type obj

  let disconnect ?reason (t : t) =
    let args : Protocol.worker_disconnect_args = {
      Protocol.reason = reason;
    } in
    match Api.Worker.disconnect t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let evaluate_expression ~arg ?is_function ~expression (t : t) =
    let args : Protocol.worker_evaluate_expression_args = {
      Protocol.arg = arg;
      Protocol.is_function = is_function;
      Protocol.expression = expression;
    } in
    match Api.Worker.evaluate_expression t.conn t.guid args with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let evaluate_expression_handle ~arg ?is_function ~expression (t : t) =
    let args : Protocol.worker_evaluate_expression_handle_args = {
      Protocol.arg = arg;
      Protocol.is_function = is_function;
      Protocol.expression = expression;
    } in
    match Api.Worker.evaluate_expression_handle t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.handle.guid } : js_handle_type obj)
    | Error e -> raise (Error e)

  let update_subscription ~enabled ~event (t : t) =
    let args : Protocol.worker_update_subscription_args = {
      Protocol.enabled = enabled;
      Protocol.event = event;
    } in
    match Api.Worker.update_subscription t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let on_console (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "console" (fun msg ->
      match Protocol.worker_console_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_console ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "console" (fun msg ->
      match Protocol.worker_console_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "console" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

end

module Disposable = struct
  type t = disposable_type obj

  let dispose (t : t) =
    match Api.Disposable.dispose t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

end

module Js_handle = struct
  type t = js_handle_type obj

  let dispose (t : t) =
    match Api.Js_handle.dispose t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let evaluate_expression ~arg ?is_function ~expression (t : t) =
    let args : Protocol.js_handle_evaluate_expression_args = {
      Protocol.arg = arg;
      Protocol.is_function = is_function;
      Protocol.expression = expression;
    } in
    match Api.Js_handle.evaluate_expression t.conn t.guid args with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let evaluate_expression_handle ~arg ?is_function ~expression (t : t) =
    let args : Protocol.js_handle_evaluate_expression_handle_args = {
      Protocol.arg = arg;
      Protocol.is_function = is_function;
      Protocol.expression = expression;
    } in
    match Api.Js_handle.evaluate_expression_handle t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.handle.guid } : js_handle_type obj)
    | Error e -> raise (Error e)

  let get_property_list (t : t) =
    match Api.Js_handle.get_property_list t.conn t.guid () with
    | Ok res -> res.Protocol.properties
    | Error e -> raise (Error e)

  let get_property ~name (t : t) =
    let args : Protocol.js_handle_get_property_args = {
      Protocol.name = name;
    } in
    match Api.Js_handle.get_property t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.handle.guid } : js_handle_type obj)
    | Error e -> raise (Error e)

  let json_value (t : t) =
    match Api.Js_handle.json_value t.conn t.guid () with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let on_preview_updated (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "previewUpdated" (fun msg ->
      match Protocol.js_handle_preview_updated_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_preview_updated ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "previewUpdated" (fun msg ->
      match Protocol.js_handle_preview_updated_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "previewUpdated" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

end

module Element_handle = struct
  type t = element_handle_type obj

  let eval_on_selector ~arg ?is_function ~expression ?strict ~selector (t : t) =
    let args : Protocol.element_handle_eval_on_selector_args = {
      Protocol.arg = arg;
      Protocol.is_function = is_function;
      Protocol.expression = expression;
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Element_handle.eval_on_selector t.conn t.guid args with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let eval_on_selector_all ~arg ?is_function ~expression ~selector (t : t) =
    let args : Protocol.element_handle_eval_on_selector_all_args = {
      Protocol.arg = arg;
      Protocol.is_function = is_function;
      Protocol.expression = expression;
      Protocol.selector = selector;
    } in
    match Api.Element_handle.eval_on_selector_all t.conn t.guid args with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let bounding_box (t : t) =
    match Api.Element_handle.bounding_box t.conn t.guid () with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let check ?trial ~timeout ?position ?force (t : t) =
    let args : Protocol.element_handle_check_args = {
      Protocol.trial = trial;
      Protocol.timeout = timeout;
      Protocol.position = position;
      Protocol.force = force;
    } in
    match Api.Element_handle.check t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let click ?steps ?trial ~timeout ?click_count ?button ?delay ?position ?modifiers ?no_wait_after ?force (t : t) =
    let args : Protocol.element_handle_click_args = {
      Protocol.steps = steps;
      Protocol.trial = trial;
      Protocol.timeout = timeout;
      Protocol.click_count = click_count;
      Protocol.button = button;
      Protocol.delay = delay;
      Protocol.position = position;
      Protocol.modifiers = modifiers;
      Protocol.no_wait_after = no_wait_after;
      Protocol.force = force;
    } in
    match Api.Element_handle.click t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let content_frame (t : t) =
    match Api.Element_handle.content_frame t.conn t.guid () with
    | Ok res -> res.Protocol.frame
    | Error e -> raise (Error e)

  let dblclick ?steps ?trial ~timeout ?button ?delay ?position ?modifiers ?force (t : t) =
    let args : Protocol.element_handle_dblclick_args = {
      Protocol.steps = steps;
      Protocol.trial = trial;
      Protocol.timeout = timeout;
      Protocol.button = button;
      Protocol.delay = delay;
      Protocol.position = position;
      Protocol.modifiers = modifiers;
      Protocol.force = force;
    } in
    match Api.Element_handle.dblclick t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let dispatch_event ~event_init ~type_ (t : t) =
    let args : Protocol.element_handle_dispatch_event_args = {
      Protocol.event_init = event_init;
      Protocol.type_ = type_;
    } in
    match Api.Element_handle.dispatch_event t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let fill ~timeout ?force ~value (t : t) =
    let args : Protocol.element_handle_fill_args = {
      Protocol.timeout = timeout;
      Protocol.force = force;
      Protocol.value = value;
    } in
    match Api.Element_handle.fill t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let focus (t : t) =
    match Api.Element_handle.focus t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let get_attribute ~name (t : t) =
    let args : Protocol.element_handle_get_attribute_args = {
      Protocol.name = name;
    } in
    match Api.Element_handle.get_attribute t.conn t.guid args with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let hover ?trial ~timeout ?position ?modifiers ?force (t : t) =
    let args : Protocol.element_handle_hover_args = {
      Protocol.trial = trial;
      Protocol.timeout = timeout;
      Protocol.position = position;
      Protocol.modifiers = modifiers;
      Protocol.force = force;
    } in
    match Api.Element_handle.hover t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let inner_html (t : t) =
    match Api.Element_handle.inner_html t.conn t.guid () with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let inner_text (t : t) =
    match Api.Element_handle.inner_text t.conn t.guid () with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let input_value (t : t) =
    match Api.Element_handle.input_value t.conn t.guid () with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let is_checked (t : t) =
    match Api.Element_handle.is_checked t.conn t.guid () with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let is_disabled (t : t) =
    match Api.Element_handle.is_disabled t.conn t.guid () with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let is_editable (t : t) =
    match Api.Element_handle.is_editable t.conn t.guid () with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let is_enabled (t : t) =
    match Api.Element_handle.is_enabled t.conn t.guid () with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let is_hidden (t : t) =
    match Api.Element_handle.is_hidden t.conn t.guid () with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let is_visible (t : t) =
    match Api.Element_handle.is_visible t.conn t.guid () with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let owner_frame (t : t) =
    match Api.Element_handle.owner_frame t.conn t.guid () with
    | Ok res -> res.Protocol.frame
    | Error e -> raise (Error e)

  let press ?no_wait_after ~timeout ?delay ~key (t : t) =
    let args : Protocol.element_handle_press_args = {
      Protocol.no_wait_after = no_wait_after;
      Protocol.timeout = timeout;
      Protocol.delay = delay;
      Protocol.key = key;
    } in
    match Api.Element_handle.press t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let query_selector ?strict ~selector (t : t) =
    let args : Protocol.element_handle_query_selector_args = {
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Element_handle.query_selector t.conn t.guid args with
    | Ok res -> res.Protocol.element
    | Error e -> raise (Error e)

  let query_selector_all ~selector (t : t) =
    let args : Protocol.element_handle_query_selector_all_args = {
      Protocol.selector = selector;
    } in
    match Api.Element_handle.query_selector_all t.conn t.guid args with
    | Ok res -> res.Protocol.elements
    | Error e -> raise (Error e)

  let screenshot ?style ?mask_color ?mask ?scale ?animations ?caret ?omit_background ?quality ?type_ ~timeout (t : t) =
    let args : Protocol.element_handle_screenshot_args = {
      Protocol.style = style;
      Protocol.mask_color = mask_color;
      Protocol.mask = mask;
      Protocol.scale = scale;
      Protocol.animations = animations;
      Protocol.caret = caret;
      Protocol.omit_background = omit_background;
      Protocol.quality = quality;
      Protocol.type_ = type_;
      Protocol.timeout = timeout;
    } in
    match Api.Element_handle.screenshot t.conn t.guid args with
    | Ok res -> Base64.decode_exn res.Protocol.binary
    | Error e -> raise (Error e)

  let scroll_into_view_if_needed ~timeout (t : t) =
    let args : Protocol.element_handle_scroll_into_view_if_needed_args = {
      Protocol.timeout = timeout;
    } in
    match Api.Element_handle.scroll_into_view_if_needed t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let select_option ~timeout ?force ?options ?elements (t : t) =
    let args : Protocol.element_handle_select_option_args = {
      Protocol.timeout = timeout;
      Protocol.force = force;
      Protocol.options = options;
      Protocol.elements = elements;
    } in
    match Api.Element_handle.select_option t.conn t.guid args with
    | Ok res -> res.Protocol.values
    | Error e -> raise (Error e)

  let select_text ~timeout ?force (t : t) =
    let args : Protocol.element_handle_select_text_args = {
      Protocol.timeout = timeout;
      Protocol.force = force;
    } in
    match Api.Element_handle.select_text t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let set_input_files ~timeout ?streams ?local_paths ?directory_stream ?local_directory ?payloads (t : t) =
    let args : Protocol.element_handle_set_input_files_args = {
      Protocol.timeout = timeout;
      Protocol.streams = streams;
      Protocol.local_paths = local_paths;
      Protocol.directory_stream = directory_stream;
      Protocol.local_directory = local_directory;
      Protocol.payloads = payloads;
    } in
    match Api.Element_handle.set_input_files t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let tap ?trial ~timeout ?position ?modifiers ?force (t : t) =
    let args : Protocol.element_handle_tap_args = {
      Protocol.trial = trial;
      Protocol.timeout = timeout;
      Protocol.position = position;
      Protocol.modifiers = modifiers;
      Protocol.force = force;
    } in
    match Api.Element_handle.tap t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let text_content (t : t) =
    match Api.Element_handle.text_content t.conn t.guid () with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let type_ ~timeout ?delay ~text (t : t) =
    let args : Protocol.element_handle_type_args = {
      Protocol.timeout = timeout;
      Protocol.delay = delay;
      Protocol.text = text;
    } in
    match Api.Element_handle.type_ t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let uncheck ?trial ~timeout ?position ?force (t : t) =
    let args : Protocol.element_handle_uncheck_args = {
      Protocol.trial = trial;
      Protocol.timeout = timeout;
      Protocol.position = position;
      Protocol.force = force;
    } in
    match Api.Element_handle.uncheck t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let wait_for_element_state ~timeout ~state (t : t) =
    let args : Protocol.element_handle_wait_for_element_state_args = {
      Protocol.timeout = timeout;
      Protocol.state = state;
    } in
    match Api.Element_handle.wait_for_element_state t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let wait_for_selector ?state ~timeout ?strict ~selector (t : t) =
    let args : Protocol.element_handle_wait_for_selector_args = {
      Protocol.state = state;
      Protocol.timeout = timeout;
      Protocol.strict = strict;
      Protocol.selector = selector;
    } in
    match Api.Element_handle.wait_for_selector t.conn t.guid args with
    | Ok res -> res.Protocol.element
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

  let response (t : t) =
    match Api.Request.response t.conn t.guid () with
    | Ok res -> res.Protocol.response
    | Error e -> raise (Error e)

  let raw_request_headers (t : t) =
    match Api.Request.raw_request_headers t.conn t.guid () with
    | Ok res -> res.Protocol.headers
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

  let redirect_navigation_request ~url (t : t) =
    let args : Protocol.route_redirect_navigation_request_args = {
      Protocol.url = url;
    } in
    match Api.Route.redirect_navigation_request t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let abort ?error_code (t : t) =
    let args : Protocol.route_abort_args = {
      Protocol.error_code = error_code;
    } in
    match Api.Route.abort t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let continue ~is_fallback ?post_data ?headers ?method_ ?url (t : t) =
    let args : Protocol.route_continue_args = {
      Protocol.is_fallback = is_fallback;
      Protocol.post_data = Option.map Base64.encode_exn post_data;
      Protocol.headers = headers;
      Protocol.method_ = method_;
      Protocol.url = url;
    } in
    match Api.Route.continue t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let fulfill ?fetch_response_uid ?is_base64 ?body ?headers ?status (t : t) =
    let args : Protocol.route_fulfill_args = {
      Protocol.fetch_response_uid = fetch_response_uid;
      Protocol.is_base64 = is_base64;
      Protocol.body = body;
      Protocol.headers = headers;
      Protocol.status = status;
    } in
    match Api.Route.fulfill t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

end

module Web_socket_route = struct
  type t = web_socket_route_type obj

  let connect (t : t) =
    match Api.Web_socket_route.connect t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let ensure_opened (t : t) =
    match Api.Web_socket_route.ensure_opened t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let send_to_page ~is_base64 ~message (t : t) =
    let args : Protocol.web_socket_route_send_to_page_args = {
      Protocol.is_base64 = is_base64;
      Protocol.message = message;
    } in
    match Api.Web_socket_route.send_to_page t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let send_to_server ~is_base64 ~message (t : t) =
    let args : Protocol.web_socket_route_send_to_server_args = {
      Protocol.is_base64 = is_base64;
      Protocol.message = message;
    } in
    match Api.Web_socket_route.send_to_server t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let close_page ~was_clean ?reason ?code (t : t) =
    let args : Protocol.web_socket_route_close_page_args = {
      Protocol.was_clean = was_clean;
      Protocol.reason = reason;
      Protocol.code = code;
    } in
    match Api.Web_socket_route.close_page t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let close_server ~was_clean ?reason ?code (t : t) =
    let args : Protocol.web_socket_route_close_server_args = {
      Protocol.was_clean = was_clean;
      Protocol.reason = reason;
      Protocol.code = code;
    } in
    match Api.Web_socket_route.close_server t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let on_message_from_page (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "messageFromPage" (fun msg ->
      match Protocol.web_socket_route_message_from_page_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_message_from_page ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "messageFromPage" (fun msg ->
      match Protocol.web_socket_route_message_from_page_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "messageFromPage" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_message_from_server (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "messageFromServer" (fun msg ->
      match Protocol.web_socket_route_message_from_server_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_message_from_server ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "messageFromServer" (fun msg ->
      match Protocol.web_socket_route_message_from_server_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "messageFromServer" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_close_page (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "closePage" (fun msg ->
      match Protocol.web_socket_route_close_page_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_close_page ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "closePage" (fun msg ->
      match Protocol.web_socket_route_close_page_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "closePage" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_close_server (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "closeServer" (fun msg ->
      match Protocol.web_socket_route_close_server_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_close_server ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "closeServer" (fun msg ->
      match Protocol.web_socket_route_close_server_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "closeServer" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

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

  let body (t : t) =
    match Api.Response.body t.conn t.guid () with
    | Ok res -> Base64.decode_exn res.Protocol.binary
    | Error e -> raise (Error e)

  let security_details (t : t) =
    match Api.Response.security_details t.conn t.guid () with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let server_addr (t : t) =
    match Api.Response.server_addr t.conn t.guid () with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let raw_response_headers (t : t) =
    match Api.Response.raw_response_headers t.conn t.guid () with
    | Ok res -> res.Protocol.headers
    | Error e -> raise (Error e)

  let http_version (t : t) =
    match Api.Response.http_version t.conn t.guid () with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let sizes (t : t) =
    match Api.Response.sizes t.conn t.guid () with
    | Ok res -> res.Protocol.sizes
    | Error e -> raise (Error e)

end

module Web_socket = struct
  type t = web_socket_type obj

  let on_frame_sent (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "frameSent" (fun msg ->
      match Protocol.web_socket_frame_sent_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_frame_sent ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "frameSent" (fun msg ->
      match Protocol.web_socket_frame_sent_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "frameSent" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_frame_received (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "frameReceived" (fun msg ->
      match Protocol.web_socket_frame_received_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_frame_received ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "frameReceived" (fun msg ->
      match Protocol.web_socket_frame_received_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "frameReceived" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_socket_error (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "socketError" (fun msg ->
      match Protocol.web_socket_socket_error_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_socket_error ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "socketError" (fun msg ->
      match Protocol.web_socket_socket_error_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "socketError" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

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

  let reject ~error (t : t) =
    let args : Protocol.binding_call_reject_args = {
      Protocol.error = error;
    } in
    match Api.Binding_call.reject t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let resolve ~result (t : t) =
    let args : Protocol.binding_call_resolve_args = {
      Protocol.result = result;
    } in
    match Api.Binding_call.resolve t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

end

module Debugger = struct
  type t = debugger_type obj

  let request_pause (t : t) =
    match Api.Debugger.request_pause t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let resume (t : t) =
    match Api.Debugger.resume t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let next (t : t) =
    match Api.Debugger.next t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let run_to ~location (t : t) =
    let args : Protocol.debugger_run_to_args = {
      Protocol.location = location;
    } in
    match Api.Debugger.run_to t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let on_paused_state_changed (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "pausedStateChanged" (fun msg ->
      match Protocol.debugger_paused_state_changed_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_paused_state_changed ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "pausedStateChanged" (fun msg ->
      match Protocol.debugger_paused_state_changed_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "pausedStateChanged" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

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

  let accept ?prompt_text (t : t) =
    let args : Protocol.dialog_accept_args = {
      Protocol.prompt_text = prompt_text;
    } in
    match Api.Dialog.accept t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let dismiss (t : t) =
    match Api.Dialog.dismiss t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

end

module Tracing = struct
  type t = tracing_type obj

  let tracing_start ?live ?screenshots ?snapshots ?name (t : t) =
    let args : Protocol.tracing_tracing_start_args = {
      Protocol.live = live;
      Protocol.screenshots = screenshots;
      Protocol.snapshots = snapshots;
      Protocol.name = name;
    } in
    match Api.Tracing.tracing_start t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let tracing_start_chunk ?title ?name (t : t) =
    let args : Protocol.tracing_tracing_start_chunk_args = {
      Protocol.title = title;
      Protocol.name = name;
    } in
    match Api.Tracing.tracing_start_chunk t.conn t.guid args with
    | Ok res -> res.Protocol.trace_name
    | Error e -> raise (Error e)

  let tracing_group ?location ~name (t : t) =
    let args : Protocol.tracing_tracing_group_args = {
      Protocol.location = location;
      Protocol.name = name;
    } in
    match Api.Tracing.tracing_group t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let tracing_group_end (t : t) =
    match Api.Tracing.tracing_group_end t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let tracing_stop_chunk ~mode (t : t) =
    let args : Protocol.tracing_tracing_stop_chunk_args = {
      Protocol.mode = mode;
    } in
    match Api.Tracing.tracing_stop_chunk t.conn t.guid args with
    | Ok res -> res
    | Error e -> raise (Error e)

  let tracing_stop (t : t) =
    match Api.Tracing.tracing_stop t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let har_start ~options ?page (t : t) =
    let args : Protocol.tracing_har_start_args = {
      Protocol.options = options;
      Protocol.page = page;
    } in
    match Api.Tracing.har_start t.conn t.guid args with
    | Ok res -> res.Protocol.har_id
    | Error e -> raise (Error e)

  let har_export ?har_id (t : t) =
    let args : Protocol.tracing_har_export_args = {
      Protocol.har_id = har_id;
    } in
    match Api.Tracing.har_export t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.artifact.guid } : artifact_type obj)
    | Error e -> raise (Error e)

end

module Artifact = struct
  type t = artifact_type obj

  let path_after_finished (t : t) =
    match Api.Artifact.path_after_finished t.conn t.guid () with
    | Ok res -> res.Protocol.value
    | Error e -> raise (Error e)

  let save_as ~path (t : t) =
    let args : Protocol.artifact_save_as_args = {
      Protocol.path = path;
    } in
    match Api.Artifact.save_as t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let save_as_stream (t : t) =
    match Api.Artifact.save_as_stream t.conn t.guid () with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.stream.guid } : stream_type obj)
    | Error e -> raise (Error e)

  let failure (t : t) =
    match Api.Artifact.failure t.conn t.guid () with
    | Ok res -> res.Protocol.error
    | Error e -> raise (Error e)

  let stream (t : t) =
    match Api.Artifact.stream t.conn t.guid () with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.stream.guid } : stream_type obj)
    | Error e -> raise (Error e)

  let cancel (t : t) =
    match Api.Artifact.cancel t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let delete (t : t) =
    match Api.Artifact.delete t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

end

module Stream = struct
  type t = stream_type obj

  let read ?size (t : t) =
    let args : Protocol.stream_read_args = {
      Protocol.size = size;
    } in
    match Api.Stream.read t.conn t.guid args with
    | Ok res -> Base64.decode_exn res.Protocol.binary
    | Error e -> raise (Error e)

  let close (t : t) =
    match Api.Stream.close t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

end

module Writable_stream = struct
  type t = writable_stream_type obj

  let write ~binary (t : t) =
    let args : Protocol.writable_stream_write_args = {
      Protocol.binary = Base64.encode_exn binary;
    } in
    match Api.Writable_stream.write t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let close (t : t) =
    match Api.Writable_stream.close t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

end

module Cdp_session = struct
  type t = cdp_session_type obj

  let send ?params ~method_ (t : t) =
    let args : Protocol.cdp_session_send_args = {
      Protocol.params = params;
      Protocol.method_ = method_;
    } in
    match Api.Cdp_session.send t.conn t.guid args with
    | Ok res -> res.Protocol.result
    | Error e -> raise (Error e)

  let detach (t : t) =
    match Api.Cdp_session.detach t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let on_event (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "event" (fun msg ->
      match Protocol.cdp_session_event_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_event ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "event" (fun msg ->
      match Protocol.cdp_session_event_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "event" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

end

module Android = struct
  type t = android_type obj

  let devices ?omit_driver_install ?port ?host (t : t) =
    let args : Protocol.android_devices_args = {
      Protocol.omit_driver_install = omit_driver_install;
      Protocol.port = port;
      Protocol.host = host;
    } in
    match Api.Android.devices t.conn t.guid args with
    | Ok res -> res.Protocol.devices
    | Error e -> raise (Error e)

end

module Android_socket = struct
  type t = android_socket_type obj

  let write ~data (t : t) =
    let args : Protocol.android_socket_write_args = {
      Protocol.data = Base64.encode_exn data;
    } in
    match Api.Android_socket.write t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let close (t : t) =
    match Api.Android_socket.close t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let on_data (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "data" (fun msg ->
      match Protocol.android_socket_data_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_data ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "data" (fun msg ->
      match Protocol.android_socket_data_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "data" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

end

module Android_device = struct
  type t = android_device_type obj

  let wait ~timeout ?state ~android_selector (t : t) =
    let args : Protocol.android_device_wait_args = {
      Protocol.timeout = timeout;
      Protocol.state = state;
      Protocol.android_selector = android_selector;
    } in
    match Api.Android_device.wait t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let fill ~timeout ~text ~android_selector (t : t) =
    let args : Protocol.android_device_fill_args = {
      Protocol.timeout = timeout;
      Protocol.text = text;
      Protocol.android_selector = android_selector;
    } in
    match Api.Android_device.fill t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let tap ~timeout ?duration ~android_selector (t : t) =
    let args : Protocol.android_device_tap_args = {
      Protocol.timeout = timeout;
      Protocol.duration = duration;
      Protocol.android_selector = android_selector;
    } in
    match Api.Android_device.tap t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let drag ~timeout ?speed ~dest ~android_selector (t : t) =
    let args : Protocol.android_device_drag_args = {
      Protocol.timeout = timeout;
      Protocol.speed = speed;
      Protocol.dest = dest;
      Protocol.android_selector = android_selector;
    } in
    match Api.Android_device.drag t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let fling ~timeout ?speed ~direction ~android_selector (t : t) =
    let args : Protocol.android_device_fling_args = {
      Protocol.timeout = timeout;
      Protocol.speed = speed;
      Protocol.direction = direction;
      Protocol.android_selector = android_selector;
    } in
    match Api.Android_device.fling t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let long_tap ~timeout ~android_selector (t : t) =
    let args : Protocol.android_device_long_tap_args = {
      Protocol.timeout = timeout;
      Protocol.android_selector = android_selector;
    } in
    match Api.Android_device.long_tap t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let pinch_close ~timeout ?speed ~percent ~android_selector (t : t) =
    let args : Protocol.android_device_pinch_close_args = {
      Protocol.timeout = timeout;
      Protocol.speed = speed;
      Protocol.percent = percent;
      Protocol.android_selector = android_selector;
    } in
    match Api.Android_device.pinch_close t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let pinch_open ~timeout ?speed ~percent ~android_selector (t : t) =
    let args : Protocol.android_device_pinch_open_args = {
      Protocol.timeout = timeout;
      Protocol.speed = speed;
      Protocol.percent = percent;
      Protocol.android_selector = android_selector;
    } in
    match Api.Android_device.pinch_open t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let scroll ~timeout ?speed ~percent ~direction ~android_selector (t : t) =
    let args : Protocol.android_device_scroll_args = {
      Protocol.timeout = timeout;
      Protocol.speed = speed;
      Protocol.percent = percent;
      Protocol.direction = direction;
      Protocol.android_selector = android_selector;
    } in
    match Api.Android_device.scroll t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let swipe ~timeout ?speed ~percent ~direction ~android_selector (t : t) =
    let args : Protocol.android_device_swipe_args = {
      Protocol.timeout = timeout;
      Protocol.speed = speed;
      Protocol.percent = percent;
      Protocol.direction = direction;
      Protocol.android_selector = android_selector;
    } in
    match Api.Android_device.swipe t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let info ~android_selector (t : t) =
    let args : Protocol.android_device_info_args = {
      Protocol.android_selector = android_selector;
    } in
    match Api.Android_device.info t.conn t.guid args with
    | Ok res -> res.Protocol.info
    | Error e -> raise (Error e)

  let screenshot (t : t) =
    match Api.Android_device.screenshot t.conn t.guid () with
    | Ok res -> Base64.decode_exn res.Protocol.binary
    | Error e -> raise (Error e)

  let input_type ~text (t : t) =
    let args : Protocol.android_device_input_type_args = {
      Protocol.text = text;
    } in
    match Api.Android_device.input_type t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let input_press ~key (t : t) =
    let args : Protocol.android_device_input_press_args = {
      Protocol.key = key;
    } in
    match Api.Android_device.input_press t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let input_tap ~point (t : t) =
    let args : Protocol.android_device_input_tap_args = {
      Protocol.point = point;
    } in
    match Api.Android_device.input_tap t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let input_swipe ~steps ~segments (t : t) =
    let args : Protocol.android_device_input_swipe_args = {
      Protocol.steps = steps;
      Protocol.segments = segments;
    } in
    match Api.Android_device.input_swipe t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let input_drag ~steps ~to_ ~from (t : t) =
    let args : Protocol.android_device_input_drag_args = {
      Protocol.steps = steps;
      Protocol.to_ = to_;
      Protocol.from = from;
    } in
    match Api.Android_device.input_drag t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let launch_browser ?test_id_attribute_name ?selector_engines ?service_workers ?strict_selectors ?record_video ?base_url ?contrast ?accept_downloads ?forced_colors ?reduced_motion ?color_scheme ?has_touch ?is_mobile ?device_scale_factor ?http_credentials ?offline ?extra_http_headers ?permissions ?geolocation ?timezone_id ?locale ?user_agent ?bypass_csp ?java_script_enabled ?client_certificates ?ignore_https_errors ?screen ?viewport ?no_default_viewport ?proxy ?args ?pkg (t : t) =
    let args : Protocol.android_device_launch_browser_args = {
      Protocol.test_id_attribute_name = test_id_attribute_name;
      Protocol.selector_engines = selector_engines;
      Protocol.service_workers = service_workers;
      Protocol.strict_selectors = strict_selectors;
      Protocol.record_video = record_video;
      Protocol.base_url = base_url;
      Protocol.contrast = contrast;
      Protocol.accept_downloads = accept_downloads;
      Protocol.forced_colors = forced_colors;
      Protocol.reduced_motion = reduced_motion;
      Protocol.color_scheme = color_scheme;
      Protocol.has_touch = has_touch;
      Protocol.is_mobile = is_mobile;
      Protocol.device_scale_factor = device_scale_factor;
      Protocol.http_credentials = http_credentials;
      Protocol.offline = offline;
      Protocol.extra_http_headers = extra_http_headers;
      Protocol.permissions = permissions;
      Protocol.geolocation = geolocation;
      Protocol.timezone_id = timezone_id;
      Protocol.locale = locale;
      Protocol.user_agent = user_agent;
      Protocol.bypass_csp = bypass_csp;
      Protocol.java_script_enabled = java_script_enabled;
      Protocol.client_certificates = client_certificates;
      Protocol.ignore_https_errors = ignore_https_errors;
      Protocol.screen = screen;
      Protocol.viewport = viewport;
      Protocol.no_default_viewport = no_default_viewport;
      Protocol.proxy = proxy;
      Protocol.args = args;
      Protocol.pkg = pkg;
    } in
    match Api.Android_device.launch_browser t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.context.guid } : browser_context_type obj)
    | Error e -> raise (Error e)

  let open_ ~command (t : t) =
    let args : Protocol.android_device_open_args = {
      Protocol.command = command;
    } in
    match Api.Android_device.open_ t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.socket.guid } : android_socket_type obj)
    | Error e -> raise (Error e)

  let shell ~command (t : t) =
    let args : Protocol.android_device_shell_args = {
      Protocol.command = command;
    } in
    match Api.Android_device.shell t.conn t.guid args with
    | Ok res -> Base64.decode_exn res.Protocol.result
    | Error e -> raise (Error e)

  let install_apk ?args ~file (t : t) =
    let args : Protocol.android_device_install_apk_args = {
      Protocol.args = args;
      Protocol.file = Base64.encode_exn file;
    } in
    match Api.Android_device.install_apk t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let push ?mode ~path ~file (t : t) =
    let args : Protocol.android_device_push_args = {
      Protocol.mode = mode;
      Protocol.path = path;
      Protocol.file = Base64.encode_exn file;
    } in
    match Api.Android_device.push t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let connect_to_web_view ~socket_name (t : t) =
    let args : Protocol.android_device_connect_to_web_view_args = {
      Protocol.socket_name = socket_name;
    } in
    match Api.Android_device.connect_to_web_view t.conn t.guid args with
    | Ok res -> ({ conn = t.conn; guid = res.Protocol.context.guid } : browser_context_type obj)
    | Error e -> raise (Error e)

  let close (t : t) =
    match Api.Android_device.close t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let on_web_view_added (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "webViewAdded" (fun msg ->
      match Protocol.android_device_web_view_added_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_web_view_added ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "webViewAdded" (fun msg ->
      match Protocol.android_device_web_view_added_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "webViewAdded" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_web_view_removed (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "webViewRemoved" (fun msg ->
      match Protocol.android_device_web_view_removed_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_web_view_removed ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "webViewRemoved" (fun msg ->
      match Protocol.android_device_web_view_removed_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "webViewRemoved" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

end

module Json_pipe = struct
  type t = json_pipe_type obj

  let send ~message (t : t) =
    let args : Protocol.json_pipe_send_args = {
      Protocol.message = message;
    } in
    match Api.Json_pipe.send t.conn t.guid args with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let close (t : t) =
    match Api.Json_pipe.close t.conn t.guid () with
    | Ok _res -> ()
    | Error e -> raise (Error e)

  let on_message (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "message" (fun msg ->
      match Protocol.json_pipe_message_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_message ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "message" (fun msg ->
      match Protocol.json_pipe_message_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "message" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

  let on_closed (t : t) cb =
    let _id = Connection.add_listener t.conn t.guid "closed" (fun msg ->
      match Protocol.json_pipe_closed_event_of_yojson msg with
      | Ok ev -> cb ev
      | Error _ -> ()
    ) in ()

  let wait_for_closed ?predicate (t : t) =
    let p, r = Eio.Promise.create () in
    let id = ref (-1) in
    id := Connection.add_listener t.conn t.guid "closed" (fun msg ->
      match Protocol.json_pipe_closed_event_of_yojson msg with
      | Ok ev ->
          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in
          if is_match then begin
            Connection.remove_listener t.conn t.guid "closed" !id;
            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev
          end
      | Error _ -> ()
    );
    Eio.Promise.await p

end

