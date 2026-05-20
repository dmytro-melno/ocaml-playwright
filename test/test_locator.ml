
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
  let new_todo = Page.locator ~selector:".new-todo" page in
  Locator.fill ~value:"First item" new_todo;
  Locator.press ~key:"Enter" new_todo;
  
  Locator.fill ~value:"Second item" new_todo;
  Locator.press ~key:"Enter" new_todo;

  let todo_list = Page.locator ~selector:".todo-list li" page in
  let count = Locator.count todo_list in
  Printf.printf "Count of items: %d\n%!" count;

  Printf.printf "Clicking checkbox...\n%!";
  let first_checkbox = Locator.locator ~selector:".toggle" (Page.locator ~selector:".todo-list li:first-child" page) in
  Locator.click first_checkbox;

  let first_li = Page.locator ~selector:".todo-list li:first-child" page in
  let class_attr = Locator.get_attribute ~name:"class" first_li in
  (match class_attr with
   | Some c -> Printf.printf "First item class: %s\n%!" c
   | None -> Printf.printf "No class attribute\n%!");

  Printf.printf "All tests passed!\n%!";
  destroy playwright
