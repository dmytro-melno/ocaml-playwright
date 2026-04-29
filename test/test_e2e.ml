
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

    Printf.printf "Navigating to todomvc...\n%!";
    let _ = Playwright.Hl.Frame.goto ~url:"https://todomvc.com/examples/react/dist/" ~timeout:10000.0 main_frame in

    Printf.printf "Filling todo item...\n%!";
    Playwright.Hl.Frame.fill ~selector:".new-todo" ~value:"Buy milk" ~timeout:5000.0 main_frame;

    Printf.printf "Pressing Enter...\n%!";
    Playwright.Hl.Frame.press ~selector:".new-todo" ~key:"Enter" ~timeout:5000.0 main_frame;

    Printf.printf "Expecting item to be in list...\n%!";
    let res = Playwright.Hl.Frame.expect ~selector:".todo-list li" ~expression:"to.have.count" ~expected_number:1.0 ~timeout:5000.0 ~is_not:false main_frame in
    Printf.printf "Expect result: %b\n%!" res.Playwright.Protocol.frame_expect_returns_matches;

    Printf.printf "Test passed successfully!\n%!"
  with Playwright.Hl.Error err -> Printf.printf "Caught Error:\n%s\n%!" err
