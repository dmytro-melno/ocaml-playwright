(* What cancelling a fiber leaves behind: nothing that the browser keeps. *)

open Eio.Std
open Playwright
open Harness

let clock t = Eio.Stdenv.clock t.env

(* [f ()] in a fiber that is cancelled as soon as it waits. *)
let cancelled f = Fiber.first f (fun () -> ())

(* [f ()] in a fiber that has been cancelled already, as in the clean-up of something
   interrupted. *)
let after_cancellation t f =
    let outcome =
        Eio.Time.with_timeout (clock t) 0.01 (fun () ->
            try Fiber.await_cancel ()
            with ex ->
                (try f () with Eio.Cancel.Cancelled _ -> ());
                raise ex)
    in
    Alcotest.(check bool) "interrupted" true (outcome = Error `Timeout)

let test_closing t () =
    let listed context = List.memq context (Browser.contexts t.browser) in
    (* A close goes through although the fiber that asked for it stops waiting. *)
    let context = Browser.new_context t.browser in
    let page = BrowserContext.new_page context in
    let closes = ref 0 in
    BrowserContext.on Close (fun _ -> incr closes) context |> ignore;
    cancelled (fun () -> BrowserContext.close context);
    Alcotest.(check bool) "closing" true (BrowserContext.is_closed context);
    BrowserContext.close context;
    Alcotest.(check (pair bool bool)) "the context is closed when the second caller returns" (true, false) (Page.is_closed page, listed context);
    Alcotest.(check int) "by one close" 1 !closes;
    (* The same from a fiber that is cancelled already. *)
    let context = Browser.new_context t.browser in
    after_cancellation t (fun () -> BrowserContext.close context);
    eventually t "a context is closed from a cancelled fiber" (fun () -> not (listed context));
    let context = Browser.new_context t.browser in
    let page = BrowserContext.new_page context in
    let other = BrowserContext.new_page context in
    cancelled (fun () -> Page.close page);
    after_cancellation t (fun () -> Page.close other);
    eventually t "pages are closed" (fun () -> BrowserContext.pages context = []);
    (* What a context holds goes the same way. *)
    let request = BrowserContext.request context in
    Server.page t.server "/blank" "<title>Blank</title>";
    let response = APIRequestContext.get (Server.url t.server "/blank") request in
    cancelled (fun () -> APIResponse.dispose response);
    eventually t "a response is disposed of" (fun () ->
        match APIResponse.body response with _ -> false | exception Playwright.Error _ -> true);
    let session = BrowserContext.new_cdp_session (BrowserContext.new_page context) context in
    let detached = ref false in
    CDPSession.on_close (fun _ -> detached := true) session |> ignore;
    cancelled (fun () -> CDPSession.detach session);
    eventually t "a session is detached" (fun () -> !detached);
    BrowserContext.close context;
    (* A browser. *)
    let browser = BrowserType.launch ?executable_path:t.executable_path (chromium t.pw) in
    let context = Browser.new_context browser in
    cancelled (fun () -> Browser.close browser);
    Browser.close browser;
    Alcotest.(check (pair bool bool)) "the browser is closed when the second caller returns" (false, true)
        (Browser.is_connected browser, BrowserContext.is_closed context)

(* A time limit of Eio around an operation ends as a time limit. *)
let test_time_limits t page =
    Page.set_content "<button>Press</button>" page;
    let button = Page.locator "button" page in
    let limited what f =
        match Eio.Time.with_timeout (clock t) 0.1 (fun () -> Ok (f ())) with
        | Error `Timeout -> ()
        | Ok _ -> Alcotest.failf "%s: should have taken forever" what
    in
    limited "a script that does not return" (fun () -> ignore (Locator.evaluate "() => new Promise(() => {})" button));
    limited "an element that does not appear" (fun () -> ignore (Locator.evaluate "element => element.id" (Page.locator "#never" page)));
    limited "a function that stays false" (fun () -> ignore (Page.wait_for_function "() => false" page));
    limited "a navigation that does not happen" (fun () -> Page.wait_for_url "**/never" page);
    Server.route t.server "/stalled" (fun _ -> Server.respond ~complete:false "the beginning");
    limited "a document that does not end" (fun () -> ignore (Page.goto (Server.url t.server "/stalled") page));
    ignore (Page.goto (Server.url t.server "/blank") page);
    Page.set_content "<button>Press</button>" page;
    Alcotest.(check string) "the page is as usable as before" "Press" (Locator.inner_text button)

(* What a cancelled command made in the browser before the cancellation got there is given
   back.  When exactly a command gets cancelled is a matter of luck, so it is tried at many
   moments. *)
let test_creation t () =
    let before = Browser.contexts t.browser in
    for attempt = 0 to 29 do
        match Eio.Time.with_timeout (clock t) (float_of_int attempt *. 0.002) (fun () -> Ok (Browser.new_page t.browser)) with
        | Ok page -> Page.close page
        | Error `Timeout -> ()
    done;
    eventually t "the contexts of pages that nobody got are closed" (fun () -> List.equal BrowserContext.equal before (Browser.contexts t.browser));
    let context = Browser.new_context t.browser in
    for attempt = 0 to 19 do
        match Eio.Time.with_timeout (clock t) (float_of_int attempt *. 0.002) (fun () -> Ok (BrowserContext.new_page context)) with
        | Ok page -> Page.close page
        | Error `Timeout -> ()
    done;
    eventually t "the pages that nobody got are closed" (fun () -> BrowserContext.pages context = []);
    BrowserContext.close context

(* The failure that counts is the one of the operation, not what its clean-up ran into. *)
let test_failures t () =
    let context = Browser.new_context t.browser in
    let tracing = BrowserContext.tracing context in
    Tracing.start tracing;
    BrowserContext.close context;
    check_failure "stopping a trace of a closed context" ~kind:Target_closed (fun () -> Tracing.stop ~path:(scratch_file t "late.zip") tracing);
    let page = Browser.new_page t.browser in
    Page.set_content "<button>Press</button>" page;
    let button = Page.locator "button" page in
    check_failure "a script that fails" ~message:"no way" (fun () -> ignore (Locator.evaluate "() => { throw new Error('no way') }" button));
    Page.close page;
    check_failure "an element of a closed page" ~kind:Target_closed (fun () -> ignore (Locator.evaluate "element => element.id" button))

let tests t =
    [ "cancellation",
      [ case t "closing" (test_closing t);
        page_case t "time limits" (test_time_limits t);
        case t "creation" (test_creation t);
        case t "failures" (test_failures t) ] ]
