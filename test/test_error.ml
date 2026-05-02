
let () =
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let playwright = Playwright.create ~env ~sw () in
  Fun.protect ~finally:(fun () -> Playwright.destroy playwright) (fun () ->
  let chromium = Playwright.Playwright.chromium playwright in

  try
    let browser = Playwright.BrowserType.launch ~executable_path:"/usr/bin/chromium" ~headless:true ~timeout:0.0 chromium in
    let ctx = Playwright.Browser.new_context browser in
    let page = Playwright.BrowserContext.new_page ctx in
    let main_frame = Playwright.Page.main_frame page in

    let _resp = Playwright.Frame.goto ~url:"https://this-will-fail.invalid" ~timeout:1000.0 main_frame in
    Printf.printf "Success!\n%!"
  with Playwright.Error err -> Printf.printf "Caught Error:\n%s\n%!" err

)
