
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
  
  let root = { Playwright.Hl.conn = conn; guid = "" } in
  
  let _result = Playwright.Hl.Root.initialize ~sdk_language:`Javascript root in
  
  Eio.Time.sleep (Eio.Stdenv.clock env) 1.0;
  
  let pw_obj_opt = Hashtbl.find_opt conn.objects "Playwright" in
  (match pw_obj_opt with
  | Some o -> 
      let chromium_guid = Yojson.Safe.Util.(member "chromium" o.initializer_ |> member "guid" |> to_string) in
      let chromium = { Playwright.Hl.conn = conn; guid = chromium_guid } in
      
      (try
         let browser = Playwright.Hl.Browser_type.launch ~executable_path:"/usr/bin/chromium" ~headless:true ~timeout:0.0 chromium in
         let ctx = Playwright.Hl.Browser.new_context browser in
         
         Playwright.Hl.Browser_context.on_page ctx (fun ev ->
           Printf.printf "Intercepted page event! New page GUID: %s\n%!" ev.Playwright.Protocol.browser_context_page_event_page.guid
         );
         
         let page = Playwright.Hl.Browser_context.new_page ctx in
         let page_obj_opt = Hashtbl.find_opt conn.objects page.guid in
         (match page_obj_opt with
          | Some page_obj ->
              let main_frame_guid = Yojson.Safe.Util.(member "mainFrame" page_obj.initializer_ |> member "guid" |> to_string) in
              let main_frame = { Playwright.Hl.conn = conn; guid = main_frame_guid } in
              
              (try
                 let _resp = Playwright.Hl.Frame.goto ~url:"https://example.com" ~timeout:10000.0 main_frame in
                 Printf.printf "Navigated to example.com!\n%!"
               with Playwright.Hl.Error err -> Printf.printf "Failed to goto: %s\n%!" err)

          | None -> Printf.printf "Page object not found in registry!\n");
       with Playwright.Hl.Error err -> Printf.printf "Failed operation: %s\n%!" err)

  | None -> Printf.printf "Playwright object not found!\n");
  
  Eio.Flow.close p1_w;
  ignore (Eio.Process.await p)
