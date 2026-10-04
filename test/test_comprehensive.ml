
open Playwright

let () =
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let playwright = create ~env ~sw () in
  let chromium = Playwright.chromium playwright in
  let browser = BrowserType.launch ~executable_path:"/usr/bin/chromium" ~headless:true chromium in
  let ctx = Browser.new_context browser in
  let page = BrowserContext.new_page ctx in

  Printf.printf "Evaluating JS handle...\n%!";
  let handle = Page.evaluate_handle ~expression:"({ a: 1, b: 'hello', c: [1, 2, 3] })" page in
  
  Printf.printf "Getting properties of handle...\n%!";
  let props = JSHandle.get_property_list handle in
  Array.iter (fun prop ->
    let name = prop.JSHandle.GetPropertyListResult_Properties.name in
    let val_handle = prop.JSHandle.GetPropertyListResult_Properties.value in
    let json_val = JSHandle.json_value val_handle in
    Printf.printf "Property %s: %s\n%!" name (Yojson.Safe.to_string json_val)
  ) props;

  Printf.printf "Evaluating console logs...\n%!";
  Page.evaluate ~expression:"console.log('Test message 1'); console.error('Test error 2');" page |> ignore;
  
  Printf.printf "Fetching console messages...\n%!";
  let msgs = Page.console_messages page in
  Array.iter (fun msg ->
    Printf.printf "Console %s: %s\n%!" msg.Page.ConsoleMessagesResult_Messages.type_ msg.Page.ConsoleMessagesResult_Messages.text
  ) msgs;

  Printf.printf "All tests passed!\n%!";
  destroy playwright
