(* Uses only the pre-fix public API, so these same assertions can also be run
   against the reviewed revision. Each mode is a separately bounded process. *)
open Playwright
open Eio.Std

let check label condition =
  if not condition then failwith ("ASSERTION FAILED: " ^ label)

let launch pw =
  BrowserType.launch ~executable_path:"/usr/bin/chromium" ~headless:true
    (Playwright.chromium pw)

let console env =
  Switch.run (fun sw ->
    let pw = create ~env ~sw () in
    Fun.protect ~finally:(fun () -> destroy pw) (fun () ->
      let browser = launch pw in
      let context = Browser.new_context browser in
      let page = BrowserContext.new_page context in
      Page.set_content ~html:"<title>callback</title>" page;
      (* Automatic subscriptions are a separate review finding, E01. *)
      Page.update_subscription ~event:`Console ~enabled:true page;
      let result, resolve = Promise.create () in
      BrowserContext.on_console context (fun _ -> Promise.resolve resolve (Page.title page));
      Eio.Time.with_timeout_exn (Eio.Stdenv.clock env) 2. (fun () ->
        ignore (Page.evaluate ~expression:"console.log('rpc')" page);
        check "callback title" (Promise.await result = "callback"));
      check "subsequent RPC" (Page.title page = "callback");
      Browser.close browser))

let multiple env =
  Switch.run (fun sw ->
    let a = create ~env ~sw () and b = create ~env ~sw () in
    Fun.protect ~finally:(fun () -> destroy a; destroy b) (fun () ->
      destroy a;
      let browser = launch b in
      let context = Browser.new_context browser in
      let page = BrowserContext.new_page context in
      Page.set_content ~html:"<title>survivor</title>" page;
      check "second session survives" (Page.title page = "survivor");
      Browser.close browser;
      let rejects = match launch a with
        | browser -> Browser.close browser; false
        | exception _ -> true in
      check "first session is destroyed" rejects))

let () =
  Printexc.record_backtrace true;
  Eio_main.run (fun env ->
    match Sys.argv.(1) with
    | "console" -> console env
    | "multiple" -> multiple env
    | mode -> invalid_arg mode);
  Printf.printf "PASS public regression %s\n%!" Sys.argv.(1)
