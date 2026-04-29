
let () =
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let playwright = Playwright.create ~env ~sw () in
  let chromium = Playwright.Hl.Playwright.chromium playwright.main in

  try
    let browser = Playwright.Hl.Browser_type.launch ~executable_path:"/usr/bin/chromium" ~headless:true ~timeout:0.0 chromium in
    let ctx = Playwright.Hl.Browser.new_context browser in

    Eio.Fiber.both
      (fun () ->
          Printf.printf "Waiting for page event...\n%!";
          let ev = Playwright.Hl.Browser_context.wait_for_page ctx in
          Printf.printf "Page created with GUID: %s\n%!" ev.Playwright.Protocol.browser_context_page_event_page.guid
      )
      (fun () ->
          Eio.Time.sleep (Eio.Stdenv.clock env) 0.5;
          Printf.printf "Creating new page...\n%!";
          let _page = Playwright.Hl.Browser_context.new_page ctx in
          ()
      )

  with Playwright.Hl.Error err -> Printf.printf "Failed operation: %s\n%!" err

