(* Rendering, raw input, tools, and the life cycle of browsers and drivers. *)

open Eio.Std
open Playwright
open Harness

let launch t = BrowserType.launch ?executable_path:t.executable_path (chromium t.pw)

(* {1 Rendering} *)

let png_size image =
    if String.length image < 24 || String.sub image 1 3 <> "PNG" then Alcotest.fail "not a PNG image";
    Int32.to_int (String.get_int32_be image 16), Int32.to_int (String.get_int32_be image 20)

let test_screenshots t () =
    let context = Browser.new_context ~viewport:(500, 400) t.browser in
    let page = BrowserContext.new_page context in
    Page.set_content page {|<body style="margin: 0"><div id="box" style="width: 120px; height: 80px; background: teal"></div><div style="height: 2000px"></div></body>|};
    Alcotest.(check (pair int int)) "viewport" (500, 400) (png_size (Page.screenshot page));
    Alcotest.(check (pair int int)) "full page" (500, 2080) (png_size (Page.screenshot ~full_page:true page));
    Alcotest.(check (pair int int)) "clip" (50, 60) (png_size (Page.screenshot ~clip:{ x = 10.; y = 10.; width = 50.; height = 60. } page));
    Alcotest.(check (pair int int)) "element" (120, 80) (png_size (Page.locator page "#box" |> Locator.screenshot));
    let jpeg = Page.screenshot ~type_:`Jpeg ~quality:50 page in
    Alcotest.(check string) "jpeg" "\xFF\xD8\xFF" (String.sub jpeg 0 3);
    Alcotest.(check (pair int int)) "masked" (500, 400) (png_size (Page.screenshot ~mask:[ Page.locator page "#box" ] ~mask_color:"black" page));
    check_failure "quality is not for PNG" ~message:"quality" (fun () -> Page.screenshot ~quality:50 page);
    BrowserContext.close context

let test_pdf_and_aria page =
    Page.set_content page {|<title>Doc</title><h1>Report</h1><ul><li>One</li><li><a href="/two">Two</a></li></ul><button disabled>Print</button>|};
    let pdf = Page.pdf ~format:"A5" ~landscape:true ~margin_top:"1cm" page in
    Alcotest.(check string) "pdf" "%PDF-" (String.sub pdf 0 5);
    let snapshot = Page.aria_snapshot page in
    List.iter
        (fun line -> check_contains "page snapshot" ~sub:line snapshot)
        [ {|- heading "Report" [level=1]|}; "- listitem: One"; {|- link "Two"|}; {|- button "Print" [disabled]|} ];
    Alcotest.(check string) "element snapshot" {|- link "Two":
  - /url: /two|} (Page.get_by_role page `Link |> Locator.aria_snapshot)

(* {1 Raw input} *)

let test_keyboard_and_mouse _ page =
    Page.set_content page
        {|<body style="margin: 0; height: 3000px">
            <input id="field" style="position: absolute; left: 20px; top: 20px; width: 200px; height: 30px">
            <div id="pad" style="position: absolute; left: 20px; top: 100px; width: 200px; height: 100px; background: silver"></div>
            <script>
              window.log = [];
              const pad = document.querySelector('#pad');
              for (const type of ['mousedown', 'mousemove', 'mouseup', 'click', 'dblclick'])
                pad.addEventListener(type, e => window.log.push(`${type} ${e.clientX},${e.clientY} ${e.button}`));
            </script>
          </body>|};
    let keyboard = Page.keyboard page and mouse = Page.mouse page in
    Mouse.click ~x:30. ~y:30. mouse;
    Alcotest.(check string) "a click focuses" "field" (eval_string "document.activeElement.id" page);
    Keyboard.type_ keyboard "hello";
    Keyboard.down keyboard "Shift";
    Keyboard.press keyboard "KeyW";
    Keyboard.up keyboard "Shift";
    Keyboard.insert_text keyboard "\xC3\xB6rld";
    Alcotest.(check string) "typed" "helloW\xC3\xB6rld" (Locator.input_value (Page.locator page "#field"));
    Keyboard.press keyboard "ControlOrMeta+A";
    Keyboard.press keyboard "Backspace";
    Alcotest.(check string) "select all and delete" "" (Locator.input_value (Page.locator page "#field"));
    Mouse.move ~x:50. ~y:120. mouse;
    Mouse.down mouse;
    Mouse.move ~steps:2 ~x:70. ~y:140. mouse;
    Mouse.up mouse;
    Mouse.click ~button:`Middle ~x:100. ~y:150. mouse;
    Mouse.dblclick ~x:30. ~y:110. mouse;
    Alcotest.(check (list string)) "mouse events"
        [ "mousemove 50,120 0"; "mousedown 50,120 0"; "mousemove 60,130 0"; "mousemove 70,140 0"; "mouseup 70,140 0"; "click 70,140 0";
          "mousemove 100,150 0"; "mousedown 100,150 1"; "mouseup 100,150 1"; "mousemove 30,110 0"; "mousedown 30,110 0"; "mouseup 30,110 0";
          "click 30,110 0"; "mousedown 30,110 0"; "mouseup 30,110 0"; "click 30,110 0"; "dblclick 30,110 0" ]
        (Page.evaluate page "window.log" |> Js.to_list Js.to_string);
    Mouse.wheel ~delta_x:0. ~delta_y:500. mouse;
    ignore (Page.wait_for_function page "window.scrollY === 500")

let test_touch t () =
    let context = Browser.new_context ~has_touch:true t.browser in
    let page = BrowserContext.new_page context in
    Page.set_content page {|<button style="width: 100px; height: 100px" ontouchstart="this.textContent = 'touched'">Tap</button>|};
    Touchscreen.tap ~x:50. ~y:50. (Page.touchscreen page);
    Expect.to_have_text "touched" (Page.locator page "button");
    Page.set_content page {|<button ontouchstart="this.textContent = 'tapped'">Tap</button>|};
    Page.locator page "button" |> Locator.tap;
    Expect.to_have_text "tapped" (Page.locator page "button");
    BrowserContext.close context

(* {1 Tools} *)

let test_cdp _ page =
    let session = BrowserContext.new_cdp_session (Page.context page) page in
    let result = CDPSession.send session "Runtime.evaluate" ~params:(`Assoc [ "expression", `String "6 * 7" ]) in
    Alcotest.check json "result" (`Int 42) Yojson.Safe.Util.(member "result" result |> member "value");
    let events = ref [] in
    let listener name params = events := (name, Yojson.Safe.Util.(member "type" params |> to_string_option)) :: !events in
    let listening = CDPSession.on_event session listener in
    ignore (CDPSession.send session "Runtime.enable");
    ignore (Page.expect_event page Page.Console (fun () -> ignore (Page.evaluate page "console.warn('via CDP')")));
    ignore (CDPSession.send session "Runtime.evaluate" ~params:(`Assoc [ "expression", `String "1" ]));
    Alcotest.(check bool) "events" true (List.mem ("Runtime.consoleAPICalled", Some "warning") !events);
    Disposable.dispose listening;
    let seen = List.length !events in
    ignore (Page.expect_event page Page.Console (fun () -> ignore (Page.evaluate page "console.warn('again')")));
    ignore (CDPSession.send session "Runtime.evaluate" ~params:(`Assoc [ "expression", `String "1" ]));
    Alcotest.(check int) "no events after off" seen (List.length !events);
    check_failure "unknown method" ~message:"wasn't found" (fun () -> CDPSession.send session "No.suchMethod");
    CDPSession.detach session;
    check_failure "detached" (fun () -> CDPSession.send session "Runtime.evaluate" ~params:(`Assoc [ "expression", `String "1" ]))

let test_picking t page =
    Page.set_content page {|<button style="position: absolute; left: 20px; top: 20px; width: 100px; height: 40px">Pick me</button>|};
    (* The person who points at an element is played by the mouse of the page. *)
    let picking = Fiber.fork_promise ~sw:t.sw (fun () -> Page.pick_locator page) in
    eventually t "picked" (fun () ->
        if not (Promise.is_resolved picking) then Mouse.click ~x:60. ~y:40. (Page.mouse page);
        Promise.is_resolved picking);
    let locator = Promise.await_exn picking in
    Alcotest.(check string) "the element that was clicked" "Pick me" (Locator.inner_text locator);
    Alcotest.(check string) "as Playwright would locate it" (Locator.selector (Page.get_by_role page `Button ~name:"Pick me")) (Locator.selector locator);
    let picking = Fiber.fork_promise ~sw:t.sw (fun () -> Page.pick_locator page) in
    eventually t "no longer picking" (fun () ->
        Page.cancel_pick_locator page;
        Promise.is_resolved picking);
    match Promise.await picking with
    | Error (Playwright.Error error) -> check_contains "picking was cancelled" ~sub:"cancelled" error.message
    | Error ex -> raise ex
    | Ok locator -> Alcotest.failf "picked %s after all" (Locator.to_string locator)

let test_selectors t () =
    let engine =
        {|({
            query(root, selector) { return root.querySelector(selector.toUpperCase()); },
            queryAll(root, selector) { return [...root.querySelectorAll(selector.toUpperCase())]; },
          })|}
    in
    let existing = Browser.new_context t.browser in
    let before = BrowserContext.new_page existing in
    Selectors.register t.pw "shout" ~script:engine;
    Selectors.set_test_id_attribute t.pw "data-qa";
    Fun.protect
        ~finally:(fun () -> Selectors.set_test_id_attribute t.pw "data-testid")
        (fun () ->
            let content = {|<ul><li data-qa="first">One</li><li data-testid="second">Two</li></ul>|} in
            let check page =
                Page.set_content page content;
                Alcotest.(check int) "custom engine" 2 (Page.locator page "shout=li" |> Locator.count);
                Alcotest.(check string) "test id attribute" "One" (Page.get_by_test_id page "first" |> Locator.inner_text);
                Alcotest.(check int) "the default attribute is no longer used" 0 (Page.get_by_test_id page "second" |> Locator.count)
            in
            check before;
            let context = Browser.new_context t.browser in
            check (BrowserContext.new_page context);
            BrowserContext.close context;
            check_failure "registered twice" ~message:"already registered" (fun () -> Selectors.register t.pw "shout" ~script:engine));
    BrowserContext.close existing

(* {1 Fibers} *)

let test_concurrency t () =
    Server.route t.server "/number" (fun request ->
        sleep t 0.05;
        Server.html (Printf.sprintf "<title>%s</title>" request.query));
    let context = Browser.new_context t.browser in
    let results =
        Fiber.List.map
            (fun n ->
                let page = BrowserContext.new_page context in
                ignore (Page.goto page (Server.url t.server (Printf.sprintf "/number?%d" n)));
                let title = Page.title page in
                let sum = Page.evaluate page "([a, b]) => new Promise(resolve => setTimeout(() => resolve(a + b), 20))" ~arg:(Js.list Js.int [ n; n ]) |> Js.to_int in
                Page.close page;
                title, sum)
            (List.init 12 Fun.id)
    in
    Alcotest.(check (list (pair string int))) "every fiber got its own answers" (List.init 12 (fun n -> string_of_int n, 2 * n)) results;
    BrowserContext.close context

let test_cancellation t page =
    Page.set_content page "<p>here</p>";
    let started = Unix.gettimeofday () in
    Fiber.first (fun () -> ignore (Locator.wait_for (Page.locator page "#never"))) (fun () -> sleep t 0.1);
    Alcotest.(check bool) "returns when the other fiber is done" true (Unix.gettimeofday () -. started < 2.);
    (match Eio.Time.with_timeout (Eio.Stdenv.clock t.env) 0.1 (fun () -> Ok (Locator.click (Page.locator page "#never"))) with
    | Error `Timeout -> ()
    | Ok () -> Alcotest.fail "the click cannot have happened");
    (* The page is none the worse for it. *)
    Alcotest.(check string) "still usable" "here" (Locator.inner_text (Page.locator page "p"));
    ignore (Page.evaluate page "new Promise(resolve => setTimeout(resolve, 50))")

(* {1 Browsers and drivers} *)

let test_launch_failures t () =
    let error = failure "no such executable" (fun () -> BrowserType.launch ~executable_path:"/no/such/browser" (chromium t.pw)) in
    check_contains "names the path" ~sub:"/no/such/browser" error.message;
    if not (Sys.file_exists (BrowserType.executable_path (firefox t.pw))) then
        check_failure "a browser that is not installed" ~message:"playwright install" (fun () -> BrowserType.launch (firefox t.pw));
    check_failure "an executable that is no browser" (fun () -> BrowserType.launch ~timeout:5000. ~executable_path:"/bin/false" (chromium t.pw))

let test_browser_closing t () =
    let browser = launch t in
    let disconnected = ref 0 in
    let listener _ = incr disconnected in
    Browser.on browser Browser.Disconnected listener |> ignore;
    let page = BrowserContext.new_page (Browser.new_context browser) in
    let pending = Fiber.fork_promise ~sw:t.sw (fun () -> Locator.wait_for (Page.locator page "#never")) in
    Fiber.yield ();
    let gone = Browser.expect_event browser Browser.Disconnected (fun () -> Browser.close ~reason:"the test is over" browser) in
    Alcotest.(check bool) "the event carries the browser" true (Browser.equal gone browser);
    (match Promise.await pending with
    | Error (Playwright.Error error) ->
        Alcotest.check error_kind "interrupted" Error.Target_closed error.kind;
        check_contains "reason" ~sub:"the test is over" error.message
    | Error ex -> raise ex
    | Ok _ -> Alcotest.fail "the wait should have failed");
    Alcotest.(check bool) "disconnected" true ((not (Browser.is_connected browser)) && !disconnected = 1);
    Alcotest.(check bool) "everything in it is closed" true (Page.is_closed page && Browser.contexts browser = []);
    check_failure "use after close" ~kind:Target_closed (fun () -> Browser.new_context browser);
    Browser.close browser;
    Alcotest.(check int) "closing twice does nothing" 1 !disconnected;
    (* A browser that dies on its own is noticed as well. *)
    let browser = launch t in
    let page = BrowserContext.new_page (Browser.new_context browser) in
    let session = Browser.new_browser_cdp_session browser in
    let crash () = try ignore (CDPSession.send session "Browser.crash") with Playwright.Error _ -> () in
    check_failure "a wait for a context ends with the browser" ~kind:Target_closed (fun () -> Browser.expect_event browser Browser.Context crash);
    Alcotest.(check bool) "crashed" true (not (Browser.is_connected browser));
    check_failure "its pages are gone" ~kind:Target_closed (fun () -> Page.title page)

let test_persistent_context t () =
    Server.page t.server "/blank" "<title>Blank</title>";
    let profile = scratch_file t "profile" in
    let visit () =
        let context = BrowserType.launch_persistent_context (chromium t.pw) ?executable_path:t.executable_path profile ~viewport:(320, 240) in
        let page = match BrowserContext.pages context with page :: _ -> page | [] -> BrowserContext.new_page context in
        ignore (Page.goto page (Server.url t.server "/blank"));
        let before = eval_string "String(localStorage.getItem('visits'))" page in
        ignore (Page.evaluate page "localStorage.setItem('visits', 'yes')");
        Alcotest.(check (option (pair int int))) "context options" (Some (320, 240)) (Page.viewport_size page);
        BrowserContext.close context;
        before
    in
    Alcotest.(check string) "first visit" "null" (visit ());
    Alcotest.(check string) "the profile is kept" "yes" (visit ())

let test_artifacts_dir t () =
    Server.route t.server "/artifact" (fun _ -> Server.respond ~headers:[ "content-disposition", "attachment; filename=artifact.txt" ] "kept");
    let dir = scratch_file t "artifacts" in
    let browser = BrowserType.launch ?executable_path:t.executable_path ~artifacts_dir:dir (chromium t.pw) in
    let page = BrowserContext.new_page (Browser.new_context browser) in
    Page.set_content page (Printf.sprintf {|<a href="%s">download</a>|} (Server.url t.server "/artifact"));
    let download = Page.expect_event page Page.Download (fun () -> Locator.click (Page.locator page "a")) in
    let path = Download.path download in
    Alcotest.(check bool) "downloads go there" true (String.starts_with ~prefix:dir path);
    Browser.close browser;
    Alcotest.(check string) "and are still there when the browser is closed" "kept" (read_file path)

let test_connect_over_cdp t () =
    let port = closed_port t in
    let browser = BrowserType.launch ?executable_path:t.executable_path ~args:[ Printf.sprintf "--remote-debugging-port=%d" port ] (chromium t.pw) in
    let original = BrowserContext.new_page (Browser.new_context browser) in
    Page.set_content original "<title>Original</title>";
    let attached = BrowserType.connect_over_cdp (chromium t.pw) ~is_local:true ~no_defaults:true (Printf.sprintf "http://127.0.0.1:%d" port) in
    let pages = List.concat_map BrowserContext.pages (Browser.contexts attached) in
    Alcotest.(check (list string)) "sees the pages that are open" [ "Original" ] (List.map Page.title pages);
    Alcotest.check js "and can drive them" (Js.Number 2.) (Page.evaluate (List.hd pages) "1 + 1");
    Browser.close attached;
    Alcotest.(check string) "detaching leaves the browser running" "Original" (Page.title original);
    Browser.close browser

(* What must hold when a Playwright instance ends, however that comes about: its objects say
   that they are gone, their last events are delivered, the handlers that are still at work are
   cancelled, and no fiber is left waiting.  [obtain] gets the browser; [end_] ends the instance. *)
let check_instance_end t what ~create ~obtain end_ =
    Server.page t.server "/blank" "<title>Blank</title>";
    Server.route t.server "/stalled" (fun _ -> Server.respond ~complete:false "the beginning");
    let reported = ref [] in
    let pw : Playwright.t = create ~on_error:(fun what ex -> reported := (what, ex) :: !reported) in
    let browser = obtain pw in
    let context = Browser.new_context browser in
    let page = BrowserContext.new_page context in
    ignore (Page.goto page (Server.url t.server "/blank"));
    let events = ref [] in
    let note event _ = events := event :: !events in
    Page.on page Page.Close (note "page") |> ignore;
    BrowserContext.on context BrowserContext.Close (note "context") |> ignore;
    Browser.on browser Browser.Disconnected (note "browser") |> ignore;
    (* A handler that is at work. *)
    let handler = ref "idle" in
    let working, started = Promise.create () in
    Page.on page Page.Console
        (fun _ ->
            if !handler = "idle" then begin
                handler := "working";
                Promise.resolve started ();
                try Fiber.await_cancel ()
                with ex ->
                    handler := "cancelled";
                    raise ex
            end)
    |> ignore;
    ignore (Page.evaluate page "console.log('to the handler')");
    Promise.await working;
    (* Fibers that wait, in the ways there are to wait. *)
    let response = Page.expect_response page ~url:"**/stalled" (fun () -> ignore (Page.evaluate page "void fetch('/stalled')")) in
    let waiting =
        List.map
            (fun (name, wait) -> name, Fiber.fork_promise ~sw:t.sw wait)
            [ "a call", (fun () -> ignore (Page.evaluate page "new Promise(() => {})"));
              "an event", (fun () -> ignore (Page.expect_event page ~timeout:0. Page.Popup ignore));
              "an element", (fun () -> ignore (Locator.wait_for ~timeout:0. (Page.locator page "#never")));
              "the body of a response", (fun () -> Response.finished response);
              "an assertion", (fun () -> Expect.to_have_title page ~timeout:0. "Never") ]
    in
    Fiber.yield ();
    Eio.Time.with_timeout_exn (Eio.Stdenv.clock t.env) 30. (fun () ->
        end_ pw page;
        List.iter
            (fun (name, (outcome : (unit, exn) result Promise.t)) ->
                match Promise.await outcome with
                | Error (Playwright.Error error) -> Alcotest.check error_kind (Printf.sprintf "%s: waiting for %s" what name) Error.Target_closed error.kind
                | Error ex -> raise ex
                | Ok () -> Alcotest.failf "%s: waiting for %s should have failed" what name)
            waiting;
        Playwright.close pw);
    Alcotest.(check (list string)) (what ^ ": the last events, each once, the page first") [ "page"; "context"; "browser" ] (List.rev !events);
    Alcotest.(check bool) (what ^ ": everything is closed") true
        (Page.is_closed page && (not (Browser.is_connected browser)) && Browser.contexts browser = [] && BrowserContext.pages context = []);
    Alcotest.(check string) (what ^ ": a handler at work") "cancelled" !handler;
    check_failure (what ^ ": later calls") ~kind:Target_closed (fun () -> Page.title page);
    check_failure (what ^ ": also on the instance") ~kind:Target_closed (fun () -> BrowserType.launch (chromium pw));
    Alcotest.(check (list string)) (what ^ ": nothing goes to the error hook") []
        (List.map (fun (what, ex) -> Printf.sprintf "%s: %s" what (Printexc.to_string ex)) !reported)

(* Starts an instance whose driver can be killed: returns the process identifier with it. *)
let create_with_driver_pid t ~on_error =
    let node = List.hd (Driver.command []) in
    let pid_file = scratch_file t "driver.pid" in
    let wrapper = scratch_file t "node.sh" in
    write_file wrapper (Printf.sprintf "#!/bin/sh\necho $$ > %s\nexec %s \"$@\"\n" (Filename.quote pid_file) (Filename.quote node));
    Unix.chmod wrapper 0o755;
    let variable = "PLAYWRIGHT_NODEJS_PATH" in
    let previous = Option.value (Sys.getenv_opt variable) ~default:"" in
    Unix.putenv variable wrapper;
    let pw = Fun.protect ~finally:(fun () -> Unix.putenv variable previous) (fun () -> Playwright.create ~sw:t.sw ~env:t.env ~on_error ()) in
    pw, int_of_string (String.trim (read_file pid_file))

let test_instance_end t () =
    let create ~on_error = Playwright.create ~sw:t.sw ~env:t.env ~on_error () in
    let launch pw = BrowserType.launch ?executable_path:t.executable_path (chromium pw) in
    check_instance_end t "closed" ~create ~obtain:launch (fun pw _ -> Playwright.close pw);
    check_instance_end t "closed by one of its handlers" ~create ~obtain:launch (fun pw page ->
        Page.on page Page.Request (fun _ -> Playwright.close pw) |> ignore;
        try ignore (Page.evaluate page "fetch('/blank').then(() => 1)") with Playwright.Error { kind = Target_closed; _ } -> ());
    if not Sys.win32 then begin
        let driver = ref 0 in
        let create ~on_error =
            let pw, pid = create_with_driver_pid t ~on_error in
            driver := pid;
            pw
        in
        check_instance_end t "driver killed" ~create ~obtain:launch (fun _ _ -> Unix.kill !driver Sys.sigkill)
    end

(* Runs [f] with standard error going to a file, and returns what was written there. *)
let capturing_stderr t f =
    let path = scratch_file t "stderr.txt" in
    let file = Unix.openfile path [ O_WRONLY; O_CREAT; O_TRUNC; O_CLOEXEC ] 0o600 in
    let saved = Unix.dup ~cloexec:true Unix.stderr in
    flush stderr;
    Unix.dup2 file Unix.stderr;
    Unix.close file;
    Fun.protect f ~finally:(fun () ->
        flush stderr;
        Unix.dup2 saved Unix.stderr;
        Unix.close saved);
    read_file path

(* The error hook is told what failed where there was nobody to raise it in, with the backtrace
   at hand.  When the hook fails as well, both failures go to standard error and the instance
   carries on. *)
let test_error_hook t () =
    Server.page t.server "/blank" "<title>Blank</title>";
    let calls = ref [] in
    let on_error what ex =
        calls := (what, Printexc.to_string ex, Printexc.raw_backtrace_to_string (Printexc.get_raw_backtrace ())) :: !calls;
        failwith "the hook fails as well"
    in
    let recording = Printexc.backtrace_status () in
    Printexc.record_backtrace true;
    let pw = Playwright.create ~sw:t.sw ~env:t.env ~on_error () in
    let output =
        Fun.protect
            ~finally:(fun () ->
                Printexc.record_backtrace recording;
                Playwright.close pw)
            (fun () ->
                let browser = BrowserType.launch ?executable_path:t.executable_path (chromium pw) in
                let page = BrowserContext.new_page (Browser.new_context browser) in
                (* Not in tail position, or there would be no trace of this file. *)
                Page.on page Page.Console (fun _ -> ignore (failwith "the listener fails" : int)) |> ignore;
                let output =
                    capturing_stderr t (fun () ->
                        ignore (Page.evaluate page "console.log('one'); console.log('two')");
                        eventually t "both failures reach the hook" (fun () -> List.length !calls = 2))
                in
                ignore (Page.goto page (Server.url t.server "/blank"));
                Alcotest.(check string) "the instance carries on" "Blank" (Page.title page);
                output)
    in
    List.iter
        (fun (what, ex, backtrace) ->
            Alcotest.(check string) "where it comes from" "event listener" what;
            check_contains "what it is" ~sub:"the listener fails" ex;
            check_contains "its backtrace" ~sub:"test_misc.ml" backtrace)
        !calls;
    check_contains "the failure of the hook is printed" ~sub:"the hook fails as well" output;
    check_contains "with the failure it was called for" ~sub:"the listener fails" output

let test_second_driver t () =
    Server.page t.server "/blank" "<title>Blank</title>";
    let title =
        Playwright.run ~env:t.env (fun pw ->
            let browser = BrowserType.launch ?executable_path:t.executable_path (chromium pw) in
            let page = BrowserContext.new_page (Browser.new_context browser) in
            ignore (Page.goto page (Server.url t.server "/blank"));
            (* Left open on purpose: stopping the driver closes it. *)
            Page.title page)
    in
    Alcotest.(check string) "an independent driver" "Blank" title;
    let pw = Playwright.create ~sw:t.sw ~env:t.env () in
    let browser = BrowserType.launch ?executable_path:t.executable_path (chromium pw) in
    let page = BrowserContext.new_page (Browser.new_context browser) in
    Alcotest.(check bool) "the objects of two drivers are different ones" false (BrowserType.equal (chromium pw) (chromium t.pw));
    (* A response that the other driver fetched is not known to this one: its body is sent over. *)
    Server.route t.server "/fetched-elsewhere" (fun _ -> Server.respond ~headers:[ "x-origin", "elsewhere" ] "fetched by the other driver");
    let request = APIRequest.new_context t.pw in
    let response = APIRequestContext.get request (Server.url t.server "/fetched-elsewhere") in
    ignore (Page.goto page (Server.url t.server "/blank"));
    Page.route page "**/replayed" (Route.fulfill ~response) |> ignore;
    Alcotest.(check string) "a response of another driver" "fetched by the other driver, elsewhere"
        (eval_string "fetch('/replayed').then(async r => (await r.text()) + ', ' + r.headers.get('x-origin'))" page);
    APIRequestContext.dispose request;
    (* A setting of one driver is not one of the other. *)
    Expect.set_default_timeout pw 150.;
    check_failure "the assertions of this driver" ~kind:Assertion_failed ~message:"150ms" (fun () -> Expect.to_be_visible (Page.locator page "#never"));
    let other = BrowserContext.new_page (Browser.new_context t.browser) in
    ignore (Page.evaluate other "setTimeout(() => document.title = 'late', 500)");
    Expect.to_have_title other "late";
    BrowserContext.close (Page.context other);
    Playwright.close pw;
    check_failure "everything fails once the driver is stopped" ~kind:Target_closed (fun () -> Page.title page);
    check_failure "also launching" ~kind:Target_closed (fun () -> BrowserType.launch (chromium pw));
    Playwright.close pw;
    Alcotest.(check bool) "the first driver is unaffected" true (Browser.is_connected t.browser)

(* Objects are compared with the functions of their modules, which also make these modules arguments for the
   functors of the standard library. *)
let test_identity t page =
    Server.page t.server "/identity" {|<title>Identity</title><ul><li>One</li><li>Two</li></ul>|};
    ignore (Page.goto page (Server.url t.server "/identity"));
    let other = BrowserContext.new_page (Page.context page) in
    let again = Frame.page (Page.main_frame page) in
    Alcotest.(check bool) "a page is itself, however it was reached" true (Page.equal page again);
    Alcotest.(check bool) "and no other" false (Page.equal page other);
    Alcotest.(check bool) "the order agrees" true
        (Page.compare page again = 0 && Page.compare page other <> 0 && Page.compare page other = -Page.compare other page);
    Alcotest.(check int) "so does the hash" (Page.hash page) (Page.hash again);
    let module Pages = Set.Make (Page) in
    Alcotest.(check int) "a set of pages" 2 (Pages.cardinal (Pages.of_list [ page; other; again ]));
    let module Names = Hashtbl.Make (Frame) in
    let names = Names.create 2 in
    Names.replace names (Page.main_frame page) "first";
    Names.replace names (Page.main_frame other) "second";
    Names.replace names (Page.main_frame again) "first again";
    Alcotest.(check (list string)) "a table with frames as keys" [ "first again"; "second" ]
        (List.sort String.compare (List.of_seq (Names.to_seq_values names)));
    (* A locator is what it looks for, and where. *)
    let items = Page.locator page "li" in
    Alcotest.(check bool) "locators" true (Locator.equal items (Page.locator page "li") && Locator.hash items = Locator.hash (Page.locator page "li"));
    Alcotest.(check bool) "another selector" false (Locator.equal items (Page.locator page "ul"));
    Alcotest.(check bool) "another page" false (Locator.equal items (Page.locator other "li") || Locator.compare items (Page.locator other "li") = 0);
    (* A handle is one object, whatever it is seen as; two handles are two objects, whatever they refer to. *)
    let element = Locator.element_handle (Locator.first (Page.locator page "li")) in
    Alcotest.(check bool) "an element as a handle" true
        (Option.equal ElementHandle.equal (JSHandle.as_element (ElementHandle.as_js_handle element)) (Some element));
    Alcotest.(check bool) "two handles to one element" false (ElementHandle.equal element (Locator.element_handle (Locator.first (Page.locator page "li"))));
    JSHandle.dispose (ElementHandle.as_js_handle element)

let tests t =
    [ "rendering", [ case t "screenshots" (test_screenshots t); page_case t "PDF and ARIA snapshots" test_pdf_and_aria ];
      "input", [ page_case t "keyboard and mouse" (test_keyboard_and_mouse t); case t "touch" (test_touch t) ];
      "tools", [ page_case t "CDP sessions" (test_cdp t); case t "selector engines and test ids" (test_selectors t); page_case t "picking a locator" (test_picking t) ];
      "objects", [ page_case t "identity" (test_identity t) ];
      "fibers", [ case t "concurrent pages" (test_concurrency t); page_case t "cancellation" (test_cancellation t) ];
      "lifecycle",
      [ case t "launch failures" (test_launch_failures t);
        case t "closing and crashing browsers" (test_browser_closing t);
        case t "persistent context" (test_persistent_context t);
        case t "a directory for artifacts" (test_artifacts_dir t);
        case t "connect over CDP" (test_connect_over_cdp t);
        case t "several drivers" (test_second_driver t);
        case t "a failing error hook" (test_error_hook t);
        case t "the end of an instance" (test_instance_end t) ] ]
