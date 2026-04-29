
let () =
  Eio_main.run @@ fun env ->
  Playwright.with_playwright ~env @@ fun playwright ->
  let chromium = Playwright.Playwright.chromium playwright in

  try
    let browser = Playwright.Browser_type.launch ~executable_path:"/usr/bin/chromium" ~headless:true ~timeout:0.0 chromium in
    let ctx = Playwright.Browser.new_context browser in
    let page = Playwright.Browser_context.new_page ctx in
    let main_frame = Playwright.Page.main_frame page in

    let _resp = Playwright.Frame.goto ~url:"https://example.com" ~timeout:10000.0 main_frame in
    Printf.printf "Navigated to example.com successfully using Playwright.with_playwright API!\n%!"
  with Playwright.Error err ->
    Printf.printf "Failed operation: %s\n%!" err

