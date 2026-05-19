open Playwright

let () =
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let playwright = create ~env ~sw () in
  let chromium = Playwright.chromium playwright in
  let browser = BrowserType.launch ~executable_path:"/usr/bin/chromium" ~headless:true chromium in
  let ctx = Browser.new_context browser in
  let page = BrowserContext.new_page ctx in

  let res = Page.evaluate ~expression:"(a) => a.x + a.y" ~arg:(`Assoc ["x", `Int 5; "y", `Int 3]) page in
  (match res with
  | `Float f -> Printf.printf "Result: %f\n" f
  | _ -> Printf.printf "Unexpected result\n");

  destroy playwright
