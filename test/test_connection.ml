
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
    Playwright.Protocol.sdk_language = `Javascript 
  } in
  
  Eio.Time.sleep (Eio.Stdenv.clock env) 1.0;
  
  let pw_obj_opt = Hashtbl.find_opt conn.objects "Playwright" in
  (match pw_obj_opt with
  | Some o -> 
      let chromium_guid = Yojson.Safe.Util.(member "chromium" o.initializer_ |> member "guid" |> to_string) in
      Printf.printf "Chromium GUID: %s\n%!" chromium_guid;
      
      let launch_args : Playwright.Protocol.browser_type_launch_args = {
          Playwright.Protocol.channel = None;
          Playwright.Protocol.executable_path = Some "/usr/bin/chromium";
          Playwright.Protocol.args = None;
          Playwright.Protocol.ignore_all_default_args = None;
          Playwright.Protocol.ignore_default_args = None;
          Playwright.Protocol.handle_sigint = None;
          Playwright.Protocol.handle_sigterm = None;
          Playwright.Protocol.handle_sighup = None;
          Playwright.Protocol.timeout = 0.0;
          Playwright.Protocol.env = None;
          Playwright.Protocol.headless = Some true;
          Playwright.Protocol.proxy = None;
          Playwright.Protocol.downloads_path = None;
          Playwright.Protocol.traces_dir = None;
          Playwright.Protocol.artifacts_dir = None;
          Playwright.Protocol.chromium_sandbox = None;
          Playwright.Protocol.firefox_user_prefs = None;
          Playwright.Protocol.cdp_port = None;
          Playwright.Protocol.slow_mo = None;
      } in
      
      Printf.printf "Launching browser...\n%!";
      (match Playwright.Api.Browser_type.launch conn chromium_guid launch_args with
       | Ok res -> 
           let browser_guid = res.Playwright.Protocol.browser.guid in
           Printf.printf "Browser launched! GUID: %s\n%!" browser_guid;
           
           Printf.printf "Creating new context...\n%!";
           let ctx_args : Playwright.Protocol.browser_new_context_args = {
             Playwright.Protocol.no_default_viewport = None;
             Playwright.Protocol.viewport = None;
             Playwright.Protocol.screen = None;
             Playwright.Protocol.ignore_https_errors = None;
             Playwright.Protocol.client_certificates = None;
             Playwright.Protocol.java_script_enabled = None;
             Playwright.Protocol.bypass_csp = None;
             Playwright.Protocol.user_agent = None;
             Playwright.Protocol.locale = None;
             Playwright.Protocol.timezone_id = None;
             Playwright.Protocol.geolocation = None;
             Playwright.Protocol.permissions = None;
             Playwright.Protocol.extra_http_headers = None;
             Playwright.Protocol.offline = None;
             Playwright.Protocol.http_credentials = None;
             Playwright.Protocol.device_scale_factor = None;
             Playwright.Protocol.is_mobile = None;
             Playwright.Protocol.has_touch = None;
             Playwright.Protocol.color_scheme = None;
             Playwright.Protocol.reduced_motion = None;
             Playwright.Protocol.forced_colors = None;
             Playwright.Protocol.accept_downloads = None;
             Playwright.Protocol.contrast = None;
             Playwright.Protocol.base_url = None;
             Playwright.Protocol.record_video = None;
             Playwright.Protocol.strict_selectors = None;
             Playwright.Protocol.service_workers = None;
             Playwright.Protocol.selector_engines = None;
             Playwright.Protocol.test_id_attribute_name = None;
             Playwright.Protocol.proxy = None;
             Playwright.Protocol.storage_state = None;
           } in
           (match Playwright.Api.Browser.new_context conn browser_guid ctx_args with
            | Ok ctx_res ->
                let context_guid = ctx_res.Playwright.Protocol.context.guid in
                Printf.printf "Context created! GUID: %s\n%!" context_guid;
                
                Printf.printf "Creating new page...\n%!";
                (match Playwright.Api.Browser_context.new_page conn context_guid () with
                 | Ok page_res ->
                     let page_guid = page_res.Playwright.Protocol.page.guid in
                     Printf.printf "Page created! GUID: %s\n%!" page_guid;
                     
                     let page_obj_opt = Hashtbl.find_opt conn.objects page_guid in
                     (match page_obj_opt with
                      | Some page_obj ->
                          let main_frame_guid = Yojson.Safe.Util.(member "mainFrame" page_obj.initializer_ |> member "guid" |> to_string) in
                          Printf.printf "Main frame GUID: %s\n%!" main_frame_guid;
                          
                          Printf.printf "Navigating to example.com...\n%!";
                          let goto_args : Playwright.Protocol.frame_goto_args = {
                            Playwright.Protocol.url = "https://example.com";
                            Playwright.Protocol.timeout = 10000.0;
                            Playwright.Protocol.wait_until = None;
                            Playwright.Protocol.referer = None;
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
