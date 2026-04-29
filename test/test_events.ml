
let () =
  Eio_main.run @@ fun env ->
  Playwright.with_playwright ~env @@ fun playwright ->
  let chromium = Playwright.Playwright.chromium playwright in

  try
    let browser = Playwright.Browser_type.launch ~executable_path:"/usr/bin/chromium" ~headless:true ~timeout:0.0 chromium in
    let ctx = Playwright.Browser.new_context browser in

    Playwright.Browser_context.on_page ctx (fun ev ->
      Printf.printf "Intercepted page event! New page GUID: %s\n%!" ev.Playwright.Protocol.page.guid
    );

    let _page = Playwright.Browser_context.new_page ctx in

    Eio.Time.sleep (Eio.Stdenv.clock env) 1.0;

  with Playwright.Error err -> Printf.printf "Failed operation: %s\n%!" err

