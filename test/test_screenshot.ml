
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
      
      let browser = Playwright.Hl.Browser_type.launch ~executable_path:"/usr/bin/chromium" ~headless:true ~timeout:0.0 chromium in
      let ctx = Playwright.Hl.Browser.new_context browser in
      let page = Playwright.Hl.Browser_context.new_page ctx in
      let main_frame = Playwright.Hl.Page.main_frame page in
      
      let _resp = Playwright.Hl.Frame.goto ~url:"https://example.com" ~timeout:10000.0 main_frame in
      
      let screenshot_resp = Playwright.Hl.Page.screenshot ~timeout:10000.0 page in
      Printf.printf "Screenshot string length: %d\n" (String.length screenshot_resp);
      Printf.printf "Screenshot prefix: %s\n" (String.sub screenshot_resp 0 20);

  | None -> ());
  
  Eio.Flow.close p1_w;
  ignore (Eio.Process.await p)
