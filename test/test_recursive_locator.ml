
open Playwright

let () =
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let playwright = create ~env ~sw () in
  let chromium = Playwright.chromium playwright in
  let browser = BrowserType.launch ~executable_path:"/usr/bin/chromium" ~headless:true chromium in
  let ctx = Browser.new_context browser in
  let page = BrowserContext.new_page ctx in

  Printf.printf "Navigating to TodoMVC...\n%!";
  let _ = Page.goto ~url:"https://todomvc.com/examples/react/dist/" page in

  (* Test Page.locator directly returning Locator.t *)
  let main_body : Locator.t = Page.locator ~selector:"body" page in
  Printf.printf "Successfully retrieved page body locator as Locator.t\n%!";

  (* Test Locator.locator returning Locator.t *)
  let new_todo : Locator.t = Locator.locator ~selector:".new-todo" main_body in
  Printf.printf "Successfully resolved child locator '.new-todo' on body\n%!";

  Locator.fill ~value:"Recursive Locator Item 1" new_todo;
  Locator.press ~key:"Enter" new_todo;

  Locator.fill ~value:"Recursive Locator Item 2" new_todo;
  Locator.press ~key:"Enter" new_todo;

  let todo_items : Locator.t = Page.locator ~selector:".todo-list li" page in
  let count = Locator.count todo_items in
  Printf.printf "Found %d todo items\n%!" count;
  assert (count = 2);

  (* Test filter, nth, first, last which return Locator.t *)
  let first_item : Locator.t = Locator.first todo_items in
  let first_text = Locator.text_content first_item in
  (match first_text with
   | Some t -> Printf.printf "First item text: %s\n%!" t; assert (t = "Recursive Locator Item 1")
   | None -> failwith "Failed to get text content of the first item");

  let second_item : Locator.t = Locator.nth 1 todo_items in
  let second_text = Locator.text_content second_item in
  (match second_text with
   | Some t -> Printf.printf "Second item text: %s\n%!" t; assert (t = "Recursive Locator Item 2")
   | None -> failwith "Failed to get text content of the second item");

  Printf.printf "Recursive locator integration test passed successfully!\n%!";
  destroy playwright
