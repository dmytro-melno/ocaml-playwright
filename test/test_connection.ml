
open Eio.Std

let () =
  Eio_main.run @@ fun env ->
  Switch.run @@ fun sw ->
  let process_mgr = Eio.Stdenv.process_mgr env in
  let p1_r, p1_w = Eio.Process.pipe ~sw process_mgr in
  let p2_r, p2_w = Eio.Process.pipe ~sw process_mgr in
  
  let p = Playwright.Driver.run ~sw ~process_mgr ~stdin:p1_r ~stdout:p2_w () in
  Eio.Flow.close p1_r;
  Eio.Flow.close p2_w;
  
  let conn = Playwright.Connection.create p2_r p1_w in
  Eio.Fiber.fork ~sw (fun () -> Playwright.Connection.run_loop conn);
  
  let _result = Playwright.Api.Root.initialize conn "" { 
    Playwright.Protocol.root_initialize_args_sdk_language = `Javascript 
  } in
  
  Eio.Time.sleep (Eio.Stdenv.clock env) 1.0;
  
  let pw_obj_opt = Hashtbl.find_opt conn.objects "Playwright" in
  (match pw_obj_opt with
  | Some o -> 
      let chromium_guid = Yojson.Safe.Util.(member "chromium" o.initializer_ |> member "guid" |> to_string) in
      Printf.printf "Chromium GUID: %s\n%!" chromium_guid;
      
      let launch_args : Playwright.Protocol.browser_type_launch_args = {
          Playwright.Protocol.browser_type_launch_args_channel = None;
          Playwright.Protocol.browser_type_launch_args_executable_path = Some "/usr/bin/chromium";
          Playwright.Protocol.browser_type_launch_args_args = None;
          Playwright.Protocol.browser_type_launch_args_ignore_all_default_args = None;
          Playwright.Protocol.browser_type_launch_args_ignore_default_args = None;
          Playwright.Protocol.browser_type_launch_args_handle_sigint = None;
          Playwright.Protocol.browser_type_launch_args_handle_sigterm = None;
          Playwright.Protocol.browser_type_launch_args_handle_sighup = None;
          Playwright.Protocol.browser_type_launch_args_timeout = 0.0;
          Playwright.Protocol.browser_type_launch_args_env = None;
          Playwright.Protocol.browser_type_launch_args_headless = Some true;
          Playwright.Protocol.browser_type_launch_args_proxy = None;
          Playwright.Protocol.browser_type_launch_args_downloads_path = None;
          Playwright.Protocol.browser_type_launch_args_traces_dir = None;
          Playwright.Protocol.browser_type_launch_args_artifacts_dir = None;
          Playwright.Protocol.browser_type_launch_args_chromium_sandbox = None;
          Playwright.Protocol.browser_type_launch_args_firefox_user_prefs = None;
          Playwright.Protocol.browser_type_launch_args_cdp_port = None;
          Playwright.Protocol.browser_type_launch_args_slow_mo = None;
      } in
      
      Printf.printf "Launching browser...\n%!";
      (match Playwright.Api.Browser_type.launch conn chromium_guid launch_args with
       | Ok res -> 
           let browser_guid = res.Playwright.Protocol.browser_type_launch_returns_browser.guid in
           Printf.printf "Browser launched! GUID: %s\n%!" browser_guid;
           
           Printf.printf "Creating new context...\n%!";
           let ctx_args : Playwright.Protocol.browser_new_context_args = {
             Playwright.Protocol.browser_new_context_args_no_default_viewport = None;
             Playwright.Protocol.browser_new_context_args_viewport = None;
             Playwright.Protocol.browser_new_context_args_screen = None;
             Playwright.Protocol.browser_new_context_args_ignore_https_errors = None;
             Playwright.Protocol.browser_new_context_args_client_certificates = None;
             Playwright.Protocol.browser_new_context_args_java_script_enabled = None;
             Playwright.Protocol.browser_new_context_args_bypass_csp = None;
             Playwright.Protocol.browser_new_context_args_user_agent = None;
             Playwright.Protocol.browser_new_context_args_locale = None;
             Playwright.Protocol.browser_new_context_args_timezone_id = None;
             Playwright.Protocol.browser_new_context_args_geolocation = None;
             Playwright.Protocol.browser_new_context_args_permissions = None;
             Playwright.Protocol.browser_new_context_args_extra_http_headers = None;
             Playwright.Protocol.browser_new_context_args_offline = None;
             Playwright.Protocol.browser_new_context_args_http_credentials = None;
             Playwright.Protocol.browser_new_context_args_device_scale_factor = None;
             Playwright.Protocol.browser_new_context_args_is_mobile = None;
             Playwright.Protocol.browser_new_context_args_has_touch = None;
             Playwright.Protocol.browser_new_context_args_color_scheme = None;
             Playwright.Protocol.browser_new_context_args_reduced_motion = None;
             Playwright.Protocol.browser_new_context_args_forced_colors = None;
             Playwright.Protocol.browser_new_context_args_accept_downloads = None;
             Playwright.Protocol.browser_new_context_args_contrast = None;
             Playwright.Protocol.browser_new_context_args_base_url = None;
             Playwright.Protocol.browser_new_context_args_record_video = None;
             Playwright.Protocol.browser_new_context_args_strict_selectors = None;
             Playwright.Protocol.browser_new_context_args_service_workers = None;
             Playwright.Protocol.browser_new_context_args_selector_engines = None;
             Playwright.Protocol.browser_new_context_args_test_id_attribute_name = None;
             Playwright.Protocol.browser_new_context_args_proxy = None;
             Playwright.Protocol.browser_new_context_args_storage_state = None;
           } in
           (match Playwright.Api.Browser.new_context conn browser_guid ctx_args with
            | Ok ctx_res ->
                let context_guid = ctx_res.Playwright.Protocol.browser_new_context_returns_context.guid in
                Printf.printf "Context created! GUID: %s\n%!" context_guid;
                
                Printf.printf "Creating new page...\n%!";
                (match Playwright.Api.Browser_context.new_page conn context_guid () with
                 | Ok page_res ->
                     let page_guid = page_res.Playwright.Protocol.browser_context_new_page_returns_page.guid in
                     Printf.printf "Page created! GUID: %s\n%!" page_guid;
                     
                     let page_obj_opt = Hashtbl.find_opt conn.objects page_guid in
                     (match page_obj_opt with
                      | Some page_obj ->
                          let main_frame_guid = Yojson.Safe.Util.(member "mainFrame" page_obj.initializer_ |> member "guid" |> to_string) in
                          Printf.printf "Main frame GUID: %s\n%!" main_frame_guid;
                          
                          Printf.printf "Navigating to example.com...\n%!";
                          let goto_args : Playwright.Protocol.frame_goto_args = {
                            Playwright.Protocol.frame_goto_args_url = "https://example.com";
                            Playwright.Protocol.frame_goto_args_timeout = 10000.0;
                            Playwright.Protocol.frame_goto_args_wait_until = None;
                            Playwright.Protocol.frame_goto_args_referer = None;
                          } in
                          (match Playwright.Api.Frame.goto conn main_frame_guid goto_args with
                           | Ok _ -> Printf.printf "Navigated to example.com!\n%!"
                           | Error err -> Printf.printf "Failed to goto: %s\n%!" err)

                      | None -> Printf.printf "Page object not found in registry!\n");
                     
                 | Error err -> Printf.printf "Failed to create page: %s\n%!" err)
                
            | Error err -> Printf.printf "Failed to create context: %s\n%!" err)

       | Error err -> Printf.printf "Failed to launch: %s\n%!" err)

  | None -> Printf.printf "Playwright object not found!\n");
  
  Eio.Flow.close p1_w;
  ignore (Eio.Process.await p)
