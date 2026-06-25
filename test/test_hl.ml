
open Eio.Std

let () =
  Eio_main.run @@ fun env ->
  Switch.run @@ fun sw ->
  let playwright = Playwright.create ~env ~sw () in
  Fun.protect ~finally:(fun () -> Playwright.destroy playwright) (fun () ->
    let chromium = Playwright.Playwright.chromium playwright in

    Printf.printf "Launching browser...\n%!";
    try
      let browser = Playwright.BrowserType.launch ~executable_path:"/usr/bin/chromium" ~headless:true ~timeout:0.0 chromium in
      Printf.printf "Browser launched!\n%!";

      Printf.printf "Creating new context...\n%!";
      let ctx = Playwright.Browser.new_context browser in
      Printf.printf "Context created!\n%!";

      Printf.printf "Creating new page...\n%!";
      let page = Playwright.BrowserContext.new_page ctx in
      Printf.printf "Page created!\n%!";

      let main_frame = Playwright.Page.main_frame page in

      Printf.printf "Navigating to example.com...\n%!";
      (try
         let _resp = Playwright.Frame.goto ~url:"https://example.com" ~timeout:10000.0 main_frame in
         Printf.printf "Navigated to example.com!\n%!"
       with Playwright.Error err -> Printf.printf "Failed to goto: %s\n%!" err)
    with Playwright.Error err -> Printf.printf "Failed operation: %s\n%!" err)
