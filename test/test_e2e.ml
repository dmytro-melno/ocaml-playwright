
let () =
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let playwright = Playwright.create ~env ~sw () in
  Fun.protect ~finally:(fun () -> Playwright.destroy playwright) (fun () ->
  let chromium = Playwright.Playwright.chromium playwright in

  try
    let browser = Playwright.BrowserType.launch ~executable_path:"/usr/bin/chromium" ~headless:true chromium in
    let ctx = Playwright.Browser.new_context browser in
    let page = Playwright.BrowserContext.new_page ctx in
    let main_frame = Playwright.Page.main_frame page in

    Printf.printf "Navigating to todomvc...\n%!";
    let _ = Playwright.Frame.goto "https://todomvc.com/examples/react/dist/" main_frame in

    Printf.printf "Filling todo item...\n%!";
    Playwright.Frame.fill ".new-todo" "Buy milk" main_frame;

    Printf.printf "Pressing Enter...\n%!";
    Playwright.Frame.press ".new-todo" ~key:"Enter" main_frame;

    Printf.printf "Expecting item to be in list...\n%!";
    let res = Playwright.Frame.expect ~selector:".todo-list li" "to.have.count" ~expected_number:1.0 ~is_not:false main_frame in
    Printf.printf "Expect result: %b\n%!" res.Playwright.Frame.ExpectResult.matches;

    Printf.printf "Test passed successfully!\n%!"
  with Playwright.Error err -> Printf.printf "Caught Error:\n%s\n%!" err
)
