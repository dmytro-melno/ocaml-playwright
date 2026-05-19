open Playwright
let () =
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let playwright = create ~env ~sw () in
  let chromium = Playwright.chromium playwright in
  let browser = BrowserType.launch ~executable_path:"/usr/bin/chromium" ~headless:true chromium in
  let browser_ctx = Browser.new_context browser in

  let page = BrowserContext.new_page browser_ctx in
  Page.on_console page (fun msg -> Printf.printf "LOG: %s\n%!" (msg.text));
  let _ = Page.goto ~url:"https://example.com" page in
  Eio.Time.sleep (Eio.Stdenv.clock env) 2.0;
  destroy playwright
