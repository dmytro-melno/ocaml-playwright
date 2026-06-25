
let () =
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let playwright = Playwright.create ~env ~sw () in
  Fun.protect ~finally:(fun () -> Playwright.destroy playwright) (fun () ->
  let chromium = Playwright.Playwright.chromium playwright in

  try
    let browser = Playwright.BrowserType.launch ~executable_path:"/usr/bin/chromium" ~headless:true ~timeout:0.0 chromium in
    let ctx = Playwright.Browser.new_context browser in

    Playwright.BrowserContext.on_page ctx (fun _ev ->
      Printf.printf "Intercepted page event!\n%!"
    );

    let _page = Playwright.BrowserContext.new_page ctx in

    Eio.Time.sleep (Eio.Stdenv.clock env) 1.0;

  with Playwright.Error err -> Printf.printf "Failed operation: %s\n%!" err

)
