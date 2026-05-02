
let () =
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let playwright = Playwright.create ~env ~sw () in
  Fun.protect ~finally:(fun () -> Playwright.destroy playwright) (fun () ->
  let chromium = Playwright.Playwright.chromium playwright in

  try
    let browser = Playwright.BrowserType.launch ~executable_path:"/usr/bin/chromium" ~headless:true ~timeout:0.0 chromium in
    let ctx = Playwright.Browser.new_context browser in

    Eio.Fiber.both
      (fun () ->
          Printf.printf "Waiting for page event...\n%!";
          let ev = Playwright.BrowserContext.wait_for_page ctx in
          Printf.printf "Page created with GUID: %s\n%!" ev.page.guid
      )
      (fun () ->
          Eio.Time.sleep (Eio.Stdenv.clock env) 0.5;
          Printf.printf "Creating new page...\n%!";
          let _page = Playwright.BrowserContext.new_page ctx in
          ()
      )

  with Playwright.Error err -> Printf.printf "Failed operation: %s\n%!" err

)
