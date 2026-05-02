
let () =
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let playwright = Playwright.create ~env ~sw () in
  let chromium = Playwright.Playwright.chromium playwright in
  let browser = Playwright.BrowserType.launch ~executable_path:"/usr/bin/chromium" ~headless:true chromium in
  let ctx = Playwright.Browser.new_context browser in
  let page = Playwright.BrowserContext.new_page ctx in

  ignore (Playwright.Page.goto ~url:"https://example.com" page);

  let h1 = Playwright.Page.text_content ~selector:"h1" page in
  (match h1 with
   | Some text -> Printf.printf "H1 Content: %s\n%!" text
   | None -> Printf.printf "H1 not found\n%!");

  Playwright.destroy playwright
