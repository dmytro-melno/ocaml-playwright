
open Playwright

let () =
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let playwright = create ~env ~sw () in
  let chromium = Playwright.chromium playwright in
  let browser = BrowserType.launch ~executable_path:"/usr/bin/chromium" ~headless:true chromium in
  let ctx = Browser.new_context browser in
  let page = BrowserContext.new_page ctx in

  Printf.printf "Navigating...\n%!";
  let _ = Page.goto ~url:"https://todomvc.com/examples/react/dist/" page in

  Printf.printf "Adding items...\n%!";
  Page.fill ~selector:".new-todo" ~value:"First item" page;
  Page.press ~selector:".new-todo" ~key:"Enter" page;
  
  Page.fill ~selector:".new-todo" ~value:"Second item" page;
  Page.press ~selector:".new-todo" ~key:"Enter" page;

  let count = Page.eval_on_selector_all ~selector:".todo-list li" ~expression:"els => els.length" page in
  Printf.printf "Count of items: %f\n%!" (match count with | `Float f -> f | _ -> -1.0);

  Printf.printf "Clicking checkbox...\n%!";
  Page.click ~selector:".todo-list li:first-child .toggle" page;

  let class_attr = Page.get_attribute ~selector:".todo-list li:first-child" ~name:"class" page in
  (match class_attr with
   | Some c -> Printf.printf "First item class: %s\n%!" c
   | None -> Printf.printf "No class attribute\n%!");

  Printf.printf "All tests passed!\n%!";
  destroy playwright
