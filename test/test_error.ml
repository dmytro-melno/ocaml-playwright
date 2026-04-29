
let () =
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let playwright = Playwright.create ~env ~sw () in
  let chromium = Playwright.Hl.Playwright.chromium playwright.main in

  try
    let browser = Playwright.Hl.Browser_type.launch ~executable_path:"/usr/bin/chromium" ~headless:true ~timeout:0.0 chromium in
    let ctx = Playwright.Hl.Browser.new_context browser in
    let page = Playwright.Hl.Browser_context.new_page ctx in
    let main_frame = Playwright.Hl.Page.main_frame page in

    let _resp = Playwright.Hl.Frame.goto ~url:"https://this-will-fail.invalid" ~timeout:1000.0 main_frame in
    Printf.printf "Success!\n%!"
  with Playwright.Hl.Error err -> Printf.printf "Caught Error:\n%s\n%!" err

