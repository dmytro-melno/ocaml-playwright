
let () =
  Eio_main.run @@ fun env ->
  Playwright.with_playwright ~env @@ fun playwright ->
  let chromium = Playwright.Playwright.chromium playwright in

  try
    let browser = Playwright.Browser_type.launch ~executable_path:"/usr/bin/chromium" ~headless:true ~timeout:0.0 chromium in
    let ctx = Playwright.Browser.new_context browser in

    Eio.Fiber.both
      (fun () ->
          Printf.printf "Waiting for page event...\n%!";
          let ev = Playwright.Browser_context.wait_for_page ctx in
          Printf.printf "Page created with GUID: %s\n%!" ev.Playwright.Protocol.page.guid
      )
      (fun () ->
          Eio.Time.sleep (Eio.Stdenv.clock env) 0.5;
          Printf.printf "Creating new page...\n%!";
          let _page = Playwright.Browser_context.new_page ctx in
          ()
      )

  with Playwright.Error err -> Printf.printf "Failed operation: %s\n%!" err

