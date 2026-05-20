
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

  let input = Page.get_by_placeholder "What needs to be done?" page in
  Locator.fill ~value:"Learn OCaml" input;
  Locator.press ~key:"Enter" input;

  let list_items = Page.locator ~selector:".todo-list li" page in
  let first_item = Locator.first list_items in
  
  let toggle = Locator.get_by_role "checkbox" first_item in
  Locator.click toggle;
  
  destroy playwright
