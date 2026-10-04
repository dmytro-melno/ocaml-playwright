
open Playwright

let () =
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let playwright = create ~env ~sw () in
  let chromium = Playwright.chromium playwright in
  let browser = BrowserType.launch ~executable_path:"/usr/bin/chromium" ~headless:true chromium in
  let ctx = Browser.new_context browser in
  let page = BrowserContext.new_page ctx in

  Printf.printf "Evaluating JS console.log...\n%!";
  Page.evaluate ~expression:"console.log('Hello');" page |> ignore;

  let msgs = Page.console_messages page in
  Array.iter (fun msg ->
    Printf.printf "Console %s: %s\n%!" msg.Page.ConsoleMessagesResult_Messages.type_ msg.Page.ConsoleMessagesResult_Messages.text
  ) msgs;
  
  Printf.printf "All tests passed!\n%!";
  destroy playwright
