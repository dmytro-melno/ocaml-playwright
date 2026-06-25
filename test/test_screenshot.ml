
open Eio.Std

let () =
  Eio_main.run @@ fun env ->
  Switch.run @@ fun sw ->
  let playwright = Playwright.create ~env ~sw () in
  Fun.protect ~finally:(fun () -> Playwright.destroy playwright) (fun () ->
    let chromium = Playwright.Playwright.chromium playwright in

    let browser = Playwright.BrowserType.launch ~executable_path:"/usr/bin/chromium" ~headless:true ~timeout:0.0 chromium in
    let ctx = Playwright.Browser.new_context browser in
    let page = Playwright.BrowserContext.new_page ctx in
    let main_frame = Playwright.Page.main_frame page in

    let _resp = Playwright.Frame.goto ~url:"https://example.com" ~timeout:10000.0 main_frame in

    let screenshot_resp = Playwright.Page.screenshot ~timeout:10000.0 page in
    Printf.printf "Screenshot string length: %d\n" (String.length screenshot_resp);
    Printf.printf "Screenshot prefix: %s\n" (String.sub screenshot_resp 0 20))
