
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
  
  let root = { Playwright.conn = conn; guid = "" } in
  
  let _result = Playwright.Root.initialize ~sdk_language:`Javascript root in
  
  Eio.Time.sleep (Eio.Stdenv.clock env) 1.0;
  
  let pw_obj_opt = Hashtbl.find_opt conn.objects "Playwright" in
  (match pw_obj_opt with
  | Some o -> 
      let chromium_guid = Yojson.Safe.Util.(member "chromium" o.initializer_ |> member "guid" |> to_string) in
      Printf.printf "Chromium GUID: %s\n%!" chromium_guid;
      
      let chromium = { Playwright.conn = conn; guid = chromium_guid } in
      
      Printf.printf "Launching browser...\n%!";
      (try
         let browser = Playwright.Browser_type.launch ~executable_path:"/usr/bin/chromium" ~headless:true ~timeout:0.0 chromium in
         Printf.printf "Browser launched! GUID: %s\n%!" browser.guid;
         
         Printf.printf "Creating new context...\n%!";
         let ctx = Playwright.Browser.new_context browser in
         Printf.printf "Context created! GUID: %s\n%!" ctx.guid;
         
         Printf.printf "Creating new page...\n%!";
         let page = Playwright.Browser_context.new_page ctx in
         Printf.printf "Page created! GUID: %s\n%!" page.guid;
         
         let page_obj_opt = Hashtbl.find_opt conn.objects page.guid in
         (match page_obj_opt with
          | Some page_obj ->
              let main_frame_guid = Yojson.Safe.Util.(member "mainFrame" page_obj.initializer_ |> member "guid" |> to_string) in
              Printf.printf "Main frame GUID: %s\n%!" main_frame_guid;
              
              let main_frame = { Playwright.conn = conn; guid = main_frame_guid } in
              
              Printf.printf "Navigating to example.com...\n%!";
              (try
                 let _resp = Playwright.Frame.goto ~url:"https://example.com" ~timeout:10000.0 main_frame in
                 Printf.printf "Navigated to example.com!\n%!"
               with Playwright.Error err -> Printf.printf "Failed to goto: %s\n%!" err)

          | None -> Printf.printf "Page object not found in registry!\n");
       with Playwright.Error err -> Printf.printf "Failed operation: %s\n%!" err)

  | None -> Printf.printf "Playwright object not found!\n");
  
  Eio.Flow.close p1_w;
  ignore (Eio.Process.await p)
