(* Navigation and JavaScript. *)

open Playwright
open Harness

let test_goto t page =
    Server.page t.server "/hello" {|<title>Hello</title><h1>Hello, world</h1>|};
    let response = Page.goto (Server.url t.server "/hello") page |> Option.get in
    Alcotest.(check int) "status" 200 (Response.status response);
    Alcotest.(check bool) "ok" true (Response.ok response);
    Alcotest.(check string) "response url" (Server.url t.server "/hello") (Response.url response);
    Alcotest.(check (option string)) "header, any case" (Some "text/html; charset=utf-8") (Response.header_value "Content-Type" response);
    check_contains "body" ~sub:"<h1>Hello, world</h1>" (Response.text response);
    Alcotest.(check string) "title" "Hello" (Page.title page);
    Alcotest.(check string) "url" (Server.url t.server "/hello") (Page.url page);
    check_contains "content" ~sub:"<h1>Hello, world</h1>" (Page.content page);
    let request = Response.request response in
    Alcotest.(check string) "method" "GET" (Request.method_ request);
    Alcotest.(check string) "resource type" "document" (Request.resource_type request);
    Alcotest.(check bool) "navigation request" true (Request.is_navigation_request request);
    Alcotest.(check bool) "frame" true (Frame.equal (Request.frame request) (Page.main_frame page));
    Alcotest.(check bool) "no response for about:blank" true (Option.is_none (Page.goto "about:blank" page))

let test_http_errors_and_redirects t page =
    Server.route t.server "/missing" (fun _ -> Server.html ~status:404 "<h1>Not here</h1>");
    Server.route t.server "/old" (fun _ -> Server.redirect "/new");
    Server.page t.server "/new" "<title>New</title>";
    let missing = Page.goto (Server.url t.server "/missing") page |> Option.get in
    Alcotest.(check int) "an error status is not a failure" 404 (Response.status missing);
    Alcotest.(check bool) "not ok" false (Response.ok missing);
    let response = Page.goto (Server.url t.server "/old") page |> Option.get in
    Alcotest.(check string) "the final response" (Server.url t.server "/new") (Response.url response);
    let redirected_from = Request.redirected_from (Response.request response) |> Option.get in
    Alcotest.(check string) "the redirected request" (Server.url t.server "/old") (Request.url redirected_from);
    Alcotest.(check bool) "and back" true (Option.equal Request.equal (Request.redirected_to redirected_from) (Some (Response.request response)));
    Alcotest.(check int) "the redirect response" 302 (Request.response redirected_from |> Option.get |> Response.status)

let test_navigation_failures t page =
    check_failure "nothing listens" ~kind:Other ~message:"ERR_CONNECTION_REFUSED" (fun () ->
        Page.goto (Printf.sprintf "http://127.0.0.1:%d/" (closed_port t)) page);
    Server.route t.server "/slow" (fun _ ->
        sleep t 2.;
        Server.html "late");
    let error = failure "slow server" (fun () -> Page.goto ~timeout:200. (Server.url t.server "/slow") page) in
    Alcotest.check error_kind "kind" Error.Timeout error.kind;
    check_contains "message" ~sub:"Timeout 200ms exceeded" error.message;
    check_contains "call log" ~sub:"navigating to" error.message;
    Alcotest.(check bool) "structured log" true (error.log <> []);
    (* The page is still usable; a new navigation supersedes the one that is stuck. *)
    Server.page t.server "/fine" "<title>Fine</title>";
    ignore (Page.goto (Server.url t.server "/fine") page);
    Alcotest.(check string) "title" "Fine" (Page.title page)

let test_history t page =
    Server.page t.server "/one" {|<title>One</title><a href="/two">next</a>|};
    Server.page t.server "/two" "<title>Two</title>";
    ignore (Page.goto (Server.url t.server "/one") page);
    let response = Page.expect_navigation (fun () -> Page.click "a" page) page |> Option.get in
    Alcotest.(check string) "navigated by a click" (Server.url t.server "/two") (Response.url response);
    ignore (Page.go_back page);
    Alcotest.(check string) "back" "One" (Page.title page);
    ignore (Page.go_forward page);
    Alcotest.(check string) "forward" "Two" (Page.title page);
    Alcotest.(check int) "reload" 200 (Page.reload page |> Option.get |> Response.status);
    Page.wait_for_url "**/two" page;
    Page.wait_for_url_matching (fun url -> contains ~sub:"/two" url) page;
    Page.wait_for_load_state ~state:`Networkidle page;
    check_failure "wait for another URL" ~kind:Timeout (fun () -> Page.wait_for_url ~timeout:200. "**/three" page)

let test_base_url t () =
    Server.page t.server "/app/index" "<title>App</title>";
    let context = Browser.new_context ~base_url:(Server.url t.server "/app/") t.browser in
    let page = BrowserContext.new_page context in
    ignore (Page.goto "index" page);
    Alcotest.(check string) "relative to the base URL" (Server.url t.server "/app/index") (Page.url page);
    Expect.to_have_url "/app/index" page;
    Expect.to_have_url "index" page;
    Expect.to_have_url (Server.url t.server "/app/index") page;
    Expect.Not.to_have_url ~timeout:100. "/index" page;
    BrowserContext.close context

let test_evaluate _ page =
    Alcotest.check js "number" (Js.Number 3.) (Page.evaluate "1 + 2" page);
    Alcotest.check js "promise" (Js.String "later") (Page.evaluate "new Promise(resolve => setTimeout(() => resolve('later'), 10))" page);
    Alcotest.check js "function with an argument" (Js.Number 42.) (Page.evaluate "({ a, b }) => a * b" ~arg:(Js.obj [ "a", Js.int 6; "b", Js.int 7 ]) page);
    Alcotest.check js "nothing" Js.Undefined (Page.evaluate "() => {}" page);
    let all_kinds =
        Js.Object
            [ "null", Js.Null; "undefined", Js.Undefined; "bool", Js.Bool true; "number", Js.Number 1.5; "infinity", Js.Number Float.neg_infinity;
              "string", Js.String "h\xC3\xA9llo \xF0\x9F\x98\x80"; "bigint", Js.Bigint "123456789012345678901234567890";
              "date", Js.Date "2024-02-29T12:00:00.000Z"; "url", Js.Url "https://example.com/a?b=c";
              "regexp", Js.Regexp { source = "a+b"; flags = "gi" }; "array", Js.Array [ Js.Number 1.; Js.Array []; Js.Object [] ];
              "bytes", Js.Typed_array { kind = `Ui8; bytes = "\000\001\255" } ]
    in
    Alcotest.check js "every kind of value survives the round trip" all_kinds (Page.evaluate "value => value" ~arg:all_kinds page);
    Alcotest.(check string) "the page sees real types" "bigint,Date,URL,RegExp,Uint8Array,true"
        (Page.evaluate
             "v => [typeof v.bigint, v.date.constructor.name, v.url.constructor.name, v.regexp.constructor.name, v.bytes.constructor.name, Object.is(v.undefined, undefined)].join()"
             ~arg:all_kinds page
        |> Js.to_string);
    (match Page.evaluate "new TypeError('boom')" page with
    | Js.Error { name; message; _ } -> Alcotest.(check (pair string string)) "error value" ("TypeError", "boom") (name, message)
    | other -> Alcotest.failf "unexpected %s" (Js.show other));
    Alcotest.check js "shared references" (Js.Array [ Js.Object [ "x", Js.Number 1. ]; Js.Object [ "x", Js.Number 1. ] ])
        (Page.evaluate "() => { const o = { x: 1 }; return [o, o]; }" page);
    check_failure "exception in the page" ~kind:Other ~message:"nope" (fun () -> Page.evaluate "() => { throw new Error('nope') }" page);
    check_failure "thrown value" ~message:"42" (fun () -> Page.evaluate "() => { throw 42 }" page);
    check_failure "syntax error" ~message:"SyntaxError" (fun () -> Page.evaluate "][" page)

let test_handles _ page =
    Page.set_content {|<ul><li>one</li><li>two</li></ul>|} page;
    let handle = Page.evaluate_handle "({ list: document.querySelector('ul'), n: 2 })" page in
    let n = JSHandle.get_property "n" handle in
    Alcotest.check js "property" (Js.Number 2.) (JSHandle.json_value n);
    let list = JSHandle.get_property "list" handle in
    let element = JSHandle.as_element list |> Option.get in
    Alcotest.(check bool) "a number is no element" true (Option.is_none (JSHandle.as_element n));
    Alcotest.(check string) "element" "onetwo" (ElementHandle.text_content element |> Option.get);
    Alcotest.(check (list string)) "properties" [ "list"; "n" ] (List.map fst (JSHandle.get_properties handle));
    Alcotest.check js "a handle as an argument" (Js.Number 2.) (Page.evaluate "ul => ul.children.length" ~arg:(Js.Handle list) page);
    Alcotest.check js "handles inside a structure" (Js.String "LI/2")
        (Page.evaluate "({ item, n }) => item.tagName + '/' + n"
             ~arg:(Js.obj [ "item", Js.Handle (ElementHandle.as_js_handle (ElementHandle.query_selector "li" element |> Option.get)); "n", Js.Handle n ])
             page);
    Alcotest.check js "evaluate on a handle" (Js.Number 3.) (JSHandle.evaluate "(o, extra) => o.n + extra" ~arg:(Js.int 1) handle);
    JSHandle.dispose handle;
    check_failure "disposed handle" (fun () -> JSHandle.json_value handle)

let test_wait_for_function _ page =
    Page.set_content "<div></div>" page;
    ignore (Page.evaluate "setTimeout(() => { window.ready = { answer: 42 } }, 100)" page);
    let handle = Page.wait_for_function "window.ready" page in
    Alcotest.check js "the truthy value" (Js.Object [ "answer", Js.Number 42. ]) (JSHandle.json_value handle);
    Alcotest.check js "with an argument and polling" (Js.Bool true)
        (Page.wait_for_function "n => window.ready.answer === n" ~arg:(Js.int 42) ~polling:20. page |> JSHandle.json_value);
    check_failure "never true" ~kind:Timeout (fun () -> Page.wait_for_function ~timeout:200. "window.never" page)

let test_exposed_functions _ page =
    let calls = ref [] in
    Page.expose_function "add" (fun args ->
        calls := args :: !calls;
        match args with [ a; b ] -> Js.float (Js.to_float a +. Js.to_float b) | _ -> failwith "add takes two arguments")
        page;
    Alcotest.check js "result" (Js.Number 5.) (Page.evaluate "window.add(2, 3)" page);
    Alcotest.(check int) "called once" 1 (List.length !calls);
    Alcotest.check js "an exception rejects the promise" (Js.String "add takes two arguments")
        (Page.evaluate "window.add(1).then(() => 'resolved', error => error.message.replace(/^.*Failure\\(\"(.*)\"\\).*$/s, '$1'))" page);
    Page.expose_binding "whoami" (fun source _ -> Js.string (Frame.url source.frame ^ (if Page.equal source.page page then " same page" else " other page"))) page;
    Alcotest.check js "binding source" (Js.String "about:blank same page") (Page.evaluate "window.whoami()" page);
    (* Exposed functions survive navigations and may call back into the page. *)
    Page.expose_function "title" (fun _ -> Js.string (Page.title page)) page;
    Page.set_content "<title>Callback</title>" page;
    Alcotest.check js "reentrant" (Js.String "Callback") (Page.evaluate "window.title()" page);
    check_failure "duplicate name" ~message:"add" (fun () -> Page.expose_function "add" (fun _ -> Js.null) page)

let test_init_scripts t page =
    Server.page t.server "/init" "<script>window.seenByPage = window.injected</script>";
    Page.add_init_script ~script:"window.injected = 'early'" page;
    let script = scratch_file t "init.js" in
    write_file script "window.fromFile = 7";
    BrowserContext.add_init_script ~path:script (Page.context page);
    ignore (Page.goto (Server.url t.server "/init") page);
    Alcotest.(check string) "runs before the page's scripts" "early" (eval_string "window.seenByPage" page);
    Alcotest.(check int) "from a file, for the whole context" 7 (eval_int "window.fromFile" page);
    Alcotest.check_raises "neither script nor path" (Invalid_argument "Playwright: pass either ~script or ~path") (fun () -> Page.add_init_script page)

let test_script_and_style_tags t page =
    Server.route t.server "/lib.js" (fun _ -> Server.respond ~content_type:"text/javascript" "window.lib = 'loaded'");
    Server.page t.server "/tags" "<body>text</body>";
    ignore (Page.goto (Server.url t.server "/tags") page);
    ignore (Page.add_script_tag ~url:"/lib.js" page);
    ignore (Page.add_script_tag ~content:"window.inline = 1" page);
    Alcotest.(check string) "script by URL" "loaded" (eval_string "window.lib" page);
    Alcotest.(check int) "inline script" 1 (eval_int "window.inline" page);
    ignore (Page.add_style_tag ~content:"body { color: rgb(255, 0, 0) }" page);
    Alcotest.(check string) "style" "rgb(255, 0, 0)" (eval_string "getComputedStyle(document.body).color" page)

let test_frames t page =
    Server.page t.server "/child" {|<title>Child</title><button>Inside</button>|};
    Server.page t.server "/parent" {|<title>Parent</title><iframe name="inner" src="/child"></iframe>|};
    ignore (Page.goto (Server.url t.server "/parent") page);
    let main = Page.main_frame page in
    Alcotest.(check int) "frames" 2 (List.length (Page.frames page));
    let child = Page.frame ~name:"inner" page |> Option.get in
    Alcotest.(check bool) "by URL" true (Option.equal Frame.equal (Page.frame ~url:"**/child" page) (Some child));
    Alcotest.(check bool) "no such frame" true (Option.is_none (Page.frame ~name:"other" page));
    Alcotest.(check string) "name" "inner" (Frame.name child);
    Alcotest.(check string) "url" (Server.url t.server "/child") (Frame.url child);
    Alcotest.(check string) "title" "Child" (Frame.title child);
    Alcotest.(check bool) "parent" true (Option.equal Frame.equal (Frame.parent_frame child) (Some main) && Option.is_none (Frame.parent_frame main));
    Alcotest.(check bool) "children" true (List.equal Frame.equal (Frame.child_frames main) [ child ]);
    Alcotest.(check bool) "page" true (Page.equal (Frame.page child) page);
    Alcotest.(check string) "evaluate in a frame" "Inside" (Frame.evaluate "document.querySelector('button').textContent" child |> Js.to_string);
    Alcotest.(check string) "frame element" "IFRAME" (ElementHandle.evaluate "e => e.tagName" (Frame.frame_element child) |> Js.to_string);
    Page.frame_locator "iframe" page |> FrameLocator.get_by_role `Button ~name:"Inside" |> Locator.click;
    Alcotest.(check string) "locator into the frame" "Inside" (Page.locator "iframe" page |> Locator.content_frame |> FrameLocator.locator "button" |> Locator.inner_text);
    let detached = Page.expect_event Page.Frame_detached (fun () -> ignore (Page.evaluate "document.querySelector('iframe').remove()" page)) page in
    Alcotest.(check bool) "detached" true (Frame.equal detached child && Frame.is_detached child);
    Alcotest.(check int) "one frame left" 1 (List.length (Page.frames page))

let tests t =
    [ "navigation",
      [ page_case t "goto" (test_goto t);
        page_case t "HTTP errors and redirects" (test_http_errors_and_redirects t);
        page_case t "failures and timeouts" (test_navigation_failures t);
        page_case t "history and waiting for URLs" (test_history t);
        case t "base URL" (test_base_url t);
        page_case t "frames" (test_frames t) ];
      "javascript",
      [ page_case t "evaluate" (test_evaluate t);
        page_case t "handles" (test_handles t);
        page_case t "wait_for_function" (test_wait_for_function t);
        page_case t "exposed functions" (test_exposed_functions t);
        page_case t "init scripts" (test_init_scripts t);
        page_case t "script and style tags" (test_script_and_style_tags t) ] ]
