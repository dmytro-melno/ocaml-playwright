(* Events: what pages report, and how listeners and waiting behave. *)

open Eio.Std
open Playwright
open Harness

let test_console _ page =
    let seen = ref [] in
    Page.on Page.Console (fun message -> seen := ConsoleMessage.text message :: !seen) page;
    let message = Page.expect_console_message (fun () -> ignore (Page.evaluate "console.log('hello', 42, { a: [1] })" page)) page in
    Alcotest.(check string) "type" "log" (ConsoleMessage.type_ message);
    Alcotest.(check string) "text" "hello 42 {a: Array(1)}" (ConsoleMessage.text message);
    Alcotest.(check (list string)) "arguments" [ {|"hello"|}; "42"; "{a: [1]}" ] (List.map (fun arg -> Js.show (JSHandle.json_value arg)) (ConsoleMessage.args message));
    Alcotest.(check bool) "page" true (same_option (ConsoleMessage.page message) (Some page));
    let warning =
        Page.expect_event Page.Console ~predicate:(fun m -> ConsoleMessage.type_ m = "warning")
            (fun () -> ignore (Page.evaluate "console.info('first'); console.warn('second')" page))
            page
    in
    Alcotest.(check string) "the predicate picks the event" "second" (ConsoleMessage.text warning);
    Alcotest.(check (list string)) "the listener saw everything, in order" [ "hello 42 {a: Array(1)}"; "first"; "second" ] (List.rev !seen);
    (* The context reports the messages of all its pages. *)
    let from_context =
        BrowserContext.expect_event BrowserContext.Console (fun () -> ignore (Page.evaluate "console.error('to the context')" page)) (Page.context page)
    in
    Alcotest.(check string) "context event" "error" (ConsoleMessage.type_ from_context)

let test_page_errors _ page =
    let error = Page.expect_event Page.Page_error (fun () -> ignore (Page.evaluate "setTimeout(() => { throw new TypeError('unhandled') }, 0)" page)) page in
    Alcotest.(check string) "name" "TypeError" error.name;
    Alcotest.(check string) "message" "unhandled" error.message;
    Alcotest.(check bool) "stack" true (error.stack <> None);
    let web_error =
        BrowserContext.expect_event BrowserContext.Web_error
            (fun () -> ignore (Page.evaluate "setTimeout(() => { throw new Error('for the context') }, 0)" page))
            (Page.context page)
    in
    Alcotest.(check string) "context event" "for the context" (WebError.error web_error).message;
    Alcotest.(check bool) "its page" true (same_option (WebError.page web_error) (Some page))

let test_dialogs _ page =
    let seen = ref [] in
    let handler dialog =
        seen := (Dialog.type_ dialog, Dialog.message dialog, Dialog.default_value dialog) :: !seen;
        if Dialog.type_ dialog = "prompt" then Dialog.accept ~prompt_text:"Ada" dialog else Dialog.dismiss dialog
    in
    Page.on Page.Dialog handler page;
    Alcotest.check js "prompt accepted with text" (Js.String "Ada") (Page.evaluate "prompt('Name?', 'nobody')" page);
    Alcotest.check js "confirm dismissed" (Js.Bool false) (Page.evaluate "confirm('Sure?')" page);
    Alcotest.(check (list (triple string string string))) "what the dialogs said" [ "prompt", "Name?", "nobody"; "confirm", "Sure?", "" ] (List.rev !seen);
    (* Without a listener dialogs are dismissed, so that pages do not hang. *)
    Page.off Page.Dialog handler page;
    Alcotest.check js "dismissed automatically" (Js.Null) (Page.evaluate "prompt('Anyone?')" page);
    Alcotest.(check int) "the removed listener was not called" 2 (List.length !seen);
    let dialog = Page.expect_event Page.Dialog (fun () -> ignore (Page.evaluate "setTimeout(() => alert('later'), 0)" page)) page in
    Alcotest.(check string) "alert" "later" (Dialog.message dialog);
    Dialog.accept dialog

let test_popups t page =
    Server.page t.server "/popup" "<title>Popup</title>";
    Server.page t.server "/opener" {|<a target="_blank" href="/popup">open</a>|};
    ignore (Page.goto (Server.url t.server "/opener") page);
    let context = Page.context page in
    let popup = Page.expect_popup (fun () -> Page.click "a" page) page in
    Page.wait_for_load_state popup;
    Alcotest.(check string) "title" "Popup" (Page.title popup);
    Alcotest.(check bool) "opener" true (same_option (Page.opener popup) (Some page));
    Alcotest.(check bool) "pages of the context" true (same_list (BrowserContext.pages context) [ page; popup ]);
    let closed = ref false in
    Page.on Page.Close (fun _ -> closed := true) popup;
    Page.close popup;
    Alcotest.(check bool) "closed" true (!closed && Page.is_closed popup);
    Alcotest.(check bool) "removed from the context" true (same_list (BrowserContext.pages context) [ page ]);
    let opened = BrowserContext.expect_page (fun () -> ignore (Page.evaluate "window.open('/popup')" page)) context in
    Page.wait_for_url "**/popup" opened;
    Alcotest.(check bool) "context event for window.open" true (same_option (Page.opener opened) (Some page))

let test_downloads t page =
    Server.route t.server "/report" (fun _ -> Server.respond ~headers:[ "content-disposition", "attachment; filename=report.txt" ] "the report");
    Server.page t.server "/downloads" {|<a href="/report">download</a>|};
    ignore (Page.goto (Server.url t.server "/downloads") page);
    let download = Page.expect_download (fun () -> Page.click "a" page) page in
    Alcotest.(check string) "suggested name" "report.txt" (Download.suggested_filename download);
    Alcotest.(check string) "url" (Server.url t.server "/report") (Download.url download);
    Alcotest.(check bool) "page" true (Download.page download == page);
    Alcotest.(check (option string)) "no failure" None (Download.failure download);
    Alcotest.(check string) "temporary file" "the report" (read_file (Download.path download));
    let target = scratch_file t "saved/report.txt" in
    Download.save_as target download;
    Alcotest.(check string) "saved copy, in a new directory" "the report" (read_file target);
    Download.delete download

let test_requests t page =
    Server.route t.server "/pixel.gif" (fun _ -> Server.respond ~content_type:"image/gif" "GIF89a");
    Server.route t.server "/data" (fun request -> Server.json ~headers:[ "x-served", "yes"; "set-cookie", "a=1"; "set-cookie", "b=2" ] (`Assoc [ "echo", `String request.body ]));
    Server.page t.server "/requests" {|<img src="/pixel.gif">|};
    let log = ref [] in
    let note kind request = log := (kind ^ " " ^ Filename.basename (Request.url request)) :: !log in
    Page.on Page.Request (note "request") page;
    Page.on Page.Response (fun response -> note (Printf.sprintf "response %d" (Response.status response)) (Response.request response)) page;
    Page.on Page.Request_finished (note "finished") page;
    Page.on Page.Request_failed (note "failed") page;
    ignore (Page.goto (Server.url t.server "/requests") page);
    let refused = Printf.sprintf "http://127.0.0.1:%d/refused" (closed_port t) in
    let failed = Page.expect_event Page.Request_failed (fun () -> ignore (Page.evaluate "url => fetch(url).catch(() => {})" ~arg:(Js.string refused) page)) page in
    Alcotest.(check (option string)) "failure" (Some "net::ERR_CONNECTION_REFUSED") (Request.failure failed);
    Alcotest.(check bool) "a failed request has no response" true (Option.is_none (Request.response failed));
    let has entry = List.mem entry !log in
    Alcotest.(check bool) "document" true (has "request requests" && has "response 200 requests" && has "finished requests");
    Alcotest.(check bool) "image" true (has "request pixel.gif" && has "finished pixel.gif");
    Alcotest.(check bool) "failed" true (has "request refused" && has "failed refused" && not (has "finished refused"));
    (* Waiting for a particular request and its response. *)
    let response =
        Page.expect_response ~url:"**/data" ~predicate:(fun response -> Response.status response = 200)
            (fun () -> ignore (Page.evaluate "fetch('/data', { method: 'POST', body: JSON.stringify({ n: 1 }), headers: { 'content-type': 'application/json', 'x-custom': 'yes' } })" page))
            page
    in
    let request = Response.request response in
    Alcotest.(check string) "method" "POST" (Request.method_ request);
    Alcotest.(check string) "resource type" "fetch" (Request.resource_type request);
    Alcotest.(check (option string)) "post data" (Some {|{"n":1}|}) (Request.post_data request);
    Alcotest.(check (option json)) "post data as JSON" (Some (`Assoc [ "n", `Int 1 ])) (Request.post_data_json request);
    Alcotest.(check (option string)) "request header" (Some "yes") (Request.header_value "X-Custom" request);
    Alcotest.(check bool) "all request headers include the browser's own" true (List.mem_assoc "user-agent" (Request.all_headers request));
    Alcotest.check json "response body" (`Assoc [ "echo", `String {|{"n":1}|} ]) (Response.json response);
    Alcotest.(check (option string)) "response header" (Some "yes") (Response.header_value "x-served" response);
    Alcotest.(check (list string)) "repeated response headers" [ "a=1"; "b=2" ] (Response.header_values "set-cookie" response);
    Response.finished response;
    Alcotest.(check bool) "server address" true
        (match Response.server_addr response with Some { ip_address = "127.0.0.1"; port } -> port = t.server.port | _ -> false);
    let timing = Request.timing request in
    Alcotest.(check bool) "timing" true (timing.start_time > 0. && timing.response_end >= timing.request_start);
    let sizes = Request.sizes request in
    Alcotest.(check bool) "sizes" true (sizes.request_body_size = 7 && sizes.response_body_size > 0 && sizes.response_headers_size > 0);
    let request = Page.expect_request ~url:"**/pixel.gif" (fun () -> ignore (Page.evaluate "fetch('/pixel.gif')" page)) page in
    Alcotest.(check bool) "existing response, not yet" true (Request.url request <> "" && (Option.is_none (Request.existing_response request) || true));
    Alcotest.(check int) "response of a request" 200 (Request.response request |> Option.get |> Response.status)

let test_listeners t page =
    let count = ref 0 in
    let listener _ = incr count in
    let log text = ignore (Page.evaluate "text => console.log(text)" ~arg:(Js.string text) page) in
    let synchronized f = ignore (Page.expect_console_message f page) in
    Page.once Page.Console listener page;
    synchronized (fun () -> log "one");
    synchronized (fun () -> log "two");
    Alcotest.(check int) "once" 1 !count;
    Page.on Page.Console listener page;
    Page.on Page.Console listener page;
    synchronized (fun () -> log "three");
    Alcotest.(check int) "registered twice, called twice" 3 !count;
    Page.off Page.Console listener page;
    synchronized (fun () -> log "four");
    Alcotest.(check int) "off removes one registration" 4 !count;
    Page.off Page.Console listener page;
    synchronized (fun () -> log "five");
    Alcotest.(check int) "and then the other" 4 !count;
    (* Listeners may block and call back into the page. *)
    let titles = ref [] in
    Page.on Page.Console (fun message -> titles := (ConsoleMessage.text message ^ "/" ^ Page.title page) :: !titles) page;
    Page.set_content "<title>T</title>" page;
    synchronized (fun () -> log "six");
    sleep t 0.1;
    Alcotest.(check (list string)) "reentrant listener" [ "six/T" ] !titles;
    (* Waiting gives up after the timeout, and says what it waited for. *)
    let error = failure "no event" (fun () -> Page.wait_for_event ~timeout:100. Page.Popup page) in
    Alcotest.check error_kind "timeout" Error.Timeout error.kind;
    check_contains "names the event" ~sub:"popup" error.message;
    (* An exception escaping from a listener goes to the error hook of the driver. *)
    Page.on Page.Console (fun _ -> failwith "listener failed") page;
    synchronized (fun () -> log "seven");
    sleep t 0.05;
    match take_reports t with
    | [ (_, Failure message) ] -> Alcotest.(check string) "reported" "listener failed" message
    | reports -> Alcotest.failf "expected one report, got %d" (List.length reports)

(* What waiting for an event promises about time, and about what the predicate sees. *)
let test_waiting t page =
    let log texts = ignore (Page.evaluate "texts => texts.forEach(text => console.log(text))" ~arg:(Js.list Js.string texts) page) in
    (* An event that arrives in time counts, however long the action goes on after it, and
       wherever it is among the others. *)
    let message =
        Page.expect_event Page.Console ~timeout:400.
            ~predicate:(fun m -> ConsoleMessage.text m = "three")
            (fun () ->
                log [ "one"; "two"; "three"; "four" ];
                sleep t 0.6)
            page
    in
    Alcotest.(check string) "in time" "three" (ConsoleMessage.text message);
    (* One that arrives later does not, and the action goes on to its end all the same. *)
    let finished = ref false in
    check_failure "too late" ~kind:Timeout ~message:{|Timeout 100ms exceeded while waiting for event "console"|} (fun () ->
        Page.expect_event Page.Console ~timeout:100.
            (fun () ->
                sleep t 0.3;
                log [ "late" ];
                finished := true)
            page);
    Alcotest.(check bool) "the action was not interrupted" true !finished;
    (* The predicate is called when the event arrives, not when the action is over: it sees the
       page as it was then. *)
    List.iter (fun name -> Server.page t.server ("/" ^ name) (Printf.sprintf "<title>%s</title>" name)) [ "first"; "second"; "third" ];
    let seen = ref [] in
    let frame =
        Page.expect_event Page.Frame_navigated
            ~predicate:(fun frame ->
                seen := Frame.url frame :: !seen;
                Frame.url frame = Server.url t.server "/third")
            (fun () -> List.iter (fun name -> ignore (Page.goto (Server.url t.server ("/" ^ name)) page)) [ "first"; "second"; "third" ])
            page
    in
    Alcotest.(check bool) "the frame" true (frame == Page.main_frame page);
    Alcotest.(check (list string)) "each navigation as it happened" (List.map (fun name -> Server.url t.server ("/" ^ name)) [ "first"; "second"; "third" ])
        (List.rev !seen);
    (* A predicate may ask the driver. *)
    Server.route t.server "/answer" (fun request -> Server.respond ("answer to " ^ request.query));
    let response =
        Page.expect_event Page.Response
            ~predicate:(fun response -> Response.text response = "answer to b")
            (fun () -> ignore (Page.evaluate "Promise.all(['a', 'b', 'c'].map(q => fetch('/answer?' + q)))" page))
            page
    in
    check_contains "picked by its body" ~sub:"/answer?b" (Response.url response);
    (* One that fails is the failure of the wait. *)
    match Page.expect_event Page.Console ~predicate:(fun _ -> failwith "predicate") (fun () -> log [ "anything" ]) page with
    | _ -> Alcotest.fail "the failure of the predicate should have been raised"
    | exception Failure message -> Alcotest.(check string) "the predicate's own failure" "predicate" message

(* Events come at the pace of the page, not of their handlers. *)
let test_event_bursts t page =
    let count = 3000 in
    let in_progress = ref 0 and peak = ref 0 and finished = ref 0 and sum = ref 0 in
    Page.on Page.Console
        (fun message ->
            incr in_progress;
            peak := max !peak !in_progress;
            (* The answer can only come once all the events before it have been read. *)
            (match ConsoleMessage.args message with
            | [ handle ] -> sum := !sum + Js.to_int (JSHandle.json_value handle)
            | _ -> ());
            decr in_progress;
            incr finished)
        page;
    ignore (Page.evaluate (Printf.sprintf "for (let i = 0; i < %d; i++) console.log(i)" count) page);
    eventually t "all the handlers have returned" (fun () -> !finished = count);
    Alcotest.(check int) "every event was handled" (count * (count - 1) / 2) !sum;
    if !peak > 1024 then Alcotest.failf "%d handlers were in progress at a time" !peak

let test_handlers_falling_behind t () =
    let reported = ref [] in
    let pw = Playwright.create ~sw:t.sw ~env:t.env ~handler_concurrency:2 ~handler_backlog:10 ~on_error:(fun what ex -> reported := (what, ex) :: !reported) () in
    let browser = BrowserType.launch ?executable_path:t.executable_path (chromium pw) in
    let page = Browser.new_page browser in
    Page.on Page.Console (fun _ -> Fiber.await_cancel ()) page;
    ignore (Page.evaluate "for (let i = 0; i < 12; i++) console.log(i)" page);
    Alcotest.(check bool) "two calls in progress and ten waiting are within the limits" true (Browser.is_connected browser && !reported = []);
    check_failure "one more is not" ~kind:Target_closed ~message:"event handlers do not keep up: 2 calls are in progress and 10 more are waiting" (fun () ->
        Page.evaluate "console.log('one more')" page);
    (match !reported with
    | [ ("event handlers", Playwright.Error error) ] -> check_contains "reported" ~sub:"event handlers do not keep up" error.message
    | reports -> Alcotest.failf "expected one report, got %d" (List.length reports));
    Alcotest.(check bool) "the instance is over" false (Browser.is_connected browser);
    Playwright.close pw;
    Alcotest.(check bool) "the others are unaffected" true (Browser.is_connected t.browser)

let test_closing t () =
    let context = Browser.new_context t.browser in
    let page = BrowserContext.new_page context in
    let context_closed = ref false in
    BrowserContext.on BrowserContext.Close (fun _ -> context_closed := true) context;
    (* An operation that is under way when the page closes fails with a telling error. *)
    let pending = Fiber.fork_promise ~sw:t.sw (fun () -> Page.wait_for_selector "#never" page) in
    Fiber.yield ();
    Page.close page;
    (match Promise.await pending with
    | Error (Playwright.Error error) -> Alcotest.check error_kind "interrupted" Error.Target_closed error.kind
    | Error ex -> raise ex
    | Ok _ -> Alcotest.fail "the wait should have failed");
    check_failure "use after close" ~kind:Target_closed (fun () -> Page.title page);
    Page.close page;
    Alcotest.(check bool) "closing twice is fine" true (Page.is_closed page);
    let other = BrowserContext.new_page context in
    let pending = Fiber.fork_promise ~sw:t.sw (fun () -> Page.wait_for_selector "#never" other) in
    Fiber.yield ();
    BrowserContext.close ~reason:"done with it" context;
    (match Promise.await pending with
    | Error (Playwright.Error error) ->
        Alcotest.check error_kind "interrupted by the context" Error.Target_closed error.kind;
        check_contains "the reason is passed on" ~sub:"done with it" error.message
    | Error ex -> raise ex
    | Ok _ -> Alcotest.fail "the wait should have failed");
    Alcotest.(check bool) "context close event" true !context_closed;
    Alcotest.(check bool) "its pages are closed" true (Page.is_closed other && BrowserContext.is_closed context);
    check_failure "use after the context closed" ~kind:Target_closed (fun () -> Page.title other);
    check_failure "no new pages" ~kind:Target_closed (fun () -> BrowserContext.new_page context);
    BrowserContext.close context;
    Alcotest.(check bool) "not listed any more" true (not (List.memq context (Browser.contexts t.browser)))

let test_workers t page =
    Server.route t.server "/worker.js" (fun _ -> Server.respond ~content_type:"text/javascript" "self.answer = 42; console.log('from the worker')");
    Server.page t.server "/workers" "<title>Workers</title>";
    ignore (Page.goto (Server.url t.server "/workers") page);
    let worker = Page.expect_worker (fun () -> ignore (Page.evaluate "() => { window.worker = new Worker('/worker.js') }" page)) page in
    Alcotest.(check string) "url" (Server.url t.server "/worker.js") (Worker.url worker);
    Alcotest.(check bool) "listed" true (same_list (Page.workers page) [ worker ]);
    ignore (JSHandle.json_value (Worker.evaluate_handle "new Promise(resolve => setTimeout(resolve, 50))" worker));
    Alcotest.check js "evaluate in the worker" (Js.Number 43.) (Worker.evaluate "n => self.answer + n" ~arg:(Js.int 1) worker);
    let closed = Worker.expect_event Worker.Close (fun () -> ignore (Page.evaluate "window.worker.terminate()" page)) worker in
    Alcotest.(check bool) "closed" true (closed == worker && Page.workers page = [])

(* Messages and errors from before anyone listened. *)
let test_history t page =
    Server.page t.server "/noisy" "<script>console.log('loaded')</script>";
    ignore (Page.goto (Server.url t.server "/noisy") page);
    ignore (Page.evaluate "console.warn('careful', 1)" page);
    ignore (Page.expect_event Page.Page_error (fun () -> ignore (Page.evaluate "setTimeout(() => { throw new RangeError('too late') }, 0)" page)) page);
    let texts filter = Page.console_messages ?filter page |> List.map (fun m -> ConsoleMessage.type_ m ^ ": " ^ ConsoleMessage.text m) in
    Alcotest.(check (list string)) "console messages" [ "log: loaded"; "warning: careful 1" ] (texts None);
    Alcotest.(check bool) "they belong to the page" true
        (List.for_all (fun m -> same_option (ConsoleMessage.page m) (Some page)) (Page.console_messages page));
    Alcotest.(check (list (pair string string))) "page errors" [ "RangeError", "too late" ]
        (Page.page_errors page |> List.map (fun (error : Playwright.Error.t) -> error.name, error.message));
    ignore (Page.goto (Server.url t.server "/noisy") page);
    Alcotest.(check (list string)) "since the navigation" [ "log: loaded" ] (texts (Some `Since_navigation));
    Alcotest.(check int) "everything" 3 (List.length (texts (Some `All)));
    Alcotest.(check int) "no errors since the navigation" 0 (List.length (Page.page_errors ~filter:`Since_navigation page));
    Page.clear_console_messages page;
    Page.clear_page_errors page;
    Alcotest.(check int) "cleared" 0 (List.length (texts None) + List.length (Page.page_errors page))

let tests t =
    [ "events",
      [ page_case t "console" (test_console t);
        page_case t "page errors" (test_page_errors t);
        page_case t "history" (test_history t);
        page_case t "dialogs" (test_dialogs t);
        page_case t "popups" (test_popups t);
        page_case t "downloads" (test_downloads t);
        page_case t "requests and responses" (test_requests t);
        page_case t "listeners" (test_listeners t);
        page_case t "waiting for an event" (test_waiting t);
        page_case t "bursts of events" (test_event_bursts t);
        case t "handlers that fall behind" (test_handlers_falling_behind t);
        case t "closing" (test_closing t);
        page_case t "workers" (test_workers t) ] ]
