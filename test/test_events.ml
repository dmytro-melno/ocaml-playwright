
let () =
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let playwright = Playwright.create ~env ~sw () in
  let chromium = Playwright.Hl.Playwright.chromium playwright.main in

  try
    let browser = Playwright.Hl.Browser_type.launch ~executable_path:"/usr/bin/chromium" ~headless:true ~timeout:0.0 chromium in
    let ctx = Playwright.Hl.Browser.new_context browser in

    Playwright.Hl.Browser_context.on_page ctx (fun ev ->
      Printf.printf "Intercepted page event! New page GUID: %s\n%!" ev.Playwright.Protocol.browser_context_page_event_page.guid
    );

    let _page = Playwright.Hl.Browser_context.new_page ctx in

    Eio.Time.sleep (Eio.Stdenv.clock env) 1.0;

  with Playwright.Hl.Error err -> Printf.printf "Failed operation: %s\n%!" err

