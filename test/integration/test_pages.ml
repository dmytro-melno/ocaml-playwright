(* Navigation and JavaScript. *)

open Playwright
open Harness

let test_goto t page =
    Server.page t.server "/hello" {|<title>Hello</title><h1>Hello, world</h1>|};
    let response = Page.goto page (Server.url t.server "/hello") |> Option.get in
    Alcotest.(check int) "status" 200 (Response.status response);
    Alcotest.(check bool) "ok" true (Response.ok response);
    Alcotest.(check string) "response url" (Server.url t.server "/hello") (Response.url response);
    Alcotest.(check (option string)) "header" (Some "text/html; charset=utf-8") (List.assoc_opt "content-type" (Response.headers response));
    check_contains "body" ~sub:"<h1>Hello, world</h1>" (Response.body response);
    Alcotest.(check string) "title" "Hello" (Page.title page);
    Alcotest.(check string) "url" (Server.url t.server "/hello") (Page.url page);
    check_contains "content" ~sub:"<h1>Hello, world</h1>" (Page.content page);
    let request = Response.request response in
    Alcotest.(check string) "method" "GET" (Request.method_ request);
    Alcotest.(check string) "resource type" "document" (Request.resource_type request);
    Alcotest.(check bool) "navigation request" true (Request.is_navigation_request request);
    Alcotest.(check bool) "frame" true (Frame.equal (Request.frame request) (Page.main_frame page));
    Alcotest.(check bool) "no response for about:blank" true (Option.is_none (Page.goto page "about:blank"));
    Page.set_content page {|<div id="host"></div><script>host.attachShadow({ mode: 'open' }).innerHTML = '<p>In the ' + 'shadow</p>'</script>|};
    Alcotest.(check bool) "shadow roots are not content" false (contains ~sub:"<p>In the shadow</p>" (Page.content page));
    check_contains "unless asked for" ~sub:{|<template shadowrootmode="open"><p>In the shadow</p></template>|} (Page.content page ~include_shadow:true)

let test_http_errors_and_redirects t page =
    Server.route t.server "/missing" (fun _ -> Server.html ~status:404 "<h1>Not here</h1>");
    Server.route t.server "/old" (fun _ -> Server.redirect "/new");
    Server.page t.server "/new" "<title>New</title>";
    let missing = Page.goto page (Server.url t.server "/missing") |> Option.get in
    Alcotest.(check int) "an error status is not a failure" 404 (Response.status missing);
    Alcotest.(check bool) "not ok" false (Response.ok missing);
    let response = Page.goto page (Server.url t.server "/old") |> Option.get in
    Alcotest.(check string) "the final response" (Server.url t.server "/new") (Response.url response);
    let redirected_from = Request.redirected_from (Response.request response) |> Option.get in
    Alcotest.(check string) "the redirected request" (Server.url t.server "/old") (Request.url redirected_from);
    Alcotest.(check bool) "and back" true (Option.equal Request.equal (Request.redirected_to redirected_from) (Some (Response.request response)));
    Alcotest.(check int) "the redirect response" 302 (Request.response redirected_from |> Option.get |> Response.status)

let test_navigation_failures t page =
    check_failure "nothing listens" ~kind:Other ~message:"ERR_CONNECTION_REFUSED" (fun () ->
        Page.goto page (Printf.sprintf "http://127.0.0.1:%d/" (closed_port t)));
    Server.route t.server "/slow" (fun _ ->
        sleep t 2.;
        Server.html "late");
    let error = failure "slow server" (fun () -> Page.goto page ~timeout:200. (Server.url t.server "/slow")) in
    Alcotest.check error_kind "kind" Error.Timeout error.kind;
    check_contains "message" ~sub:"Timeout 200ms exceeded" error.message;
    check_contains "call log" ~sub:"navigating to" error.message;
    Alcotest.(check bool) "structured log" true (error.log <> []);
    (* The page is still usable; a new navigation supersedes the one that is stuck. *)
    Server.page t.server "/fine" "<title>Fine</title>";
    ignore (Page.goto page (Server.url t.server "/fine"));
    Alcotest.(check string) "title" "Fine" (Page.title page)

let test_history t page =
    Server.page t.server "/one" {|<title>One</title><a href="/two">next</a>|};
    Server.page t.server "/two" "<title>Two</title>";
    ignore (Page.goto page (Server.url t.server "/one"));
    Locator.click (Page.locator page "a");
    Page.wait_for_url page "**/two";
    Alcotest.(check string) "navigated by a click" "Two" (Page.title page);
    ignore (Page.go_back page);
    Alcotest.(check string) "back" "One" (Page.title page);
    ignore (Page.go_forward page);
    Alcotest.(check string) "forward" "Two" (Page.title page);
    Alcotest.(check int) "reload" 200 (Page.reload page |> Option.get |> Response.status);
    Page.wait_for_url page "**/two";
    Page.wait_for_url_matching page (fun url -> contains ~sub:"/two" url);
    Page.wait_for_load_state page ~state:`Networkidle;
    check_failure "wait for another URL" ~kind:Timeout (fun () -> Page.wait_for_url page ~timeout:200. "**/three")

let test_base_url t () =
    Server.page t.server "/app/index" "<title>App</title>";
    let context = Browser.new_context t.browser ~base_url:(Server.url t.server "/app/") in
    let page = BrowserContext.new_page context in
    ignore (Page.goto page "index");
    Alcotest.(check string) "relative to the base URL" (Server.url t.server "/app/index") (Page.url page);
    Expect.to_have_url page "/app/index";
    Expect.to_have_url page "index";
    Expect.to_have_url page "../app/./index";
    Page.wait_for_url page "./in*";
    Expect.to_have_url page (Server.url t.server "/app/index");
    Expect.Not.to_have_url page ~timeout:100. "/index";
    BrowserContext.close context

let test_evaluate _ page =
    Alcotest.check js "number" (Js.Number 3.) (Page.evaluate page "1 + 2");
    Alcotest.check js "promise" (Js.String "later") (Page.evaluate page "new Promise(resolve => setTimeout(() => resolve('later'), 10))");
    Alcotest.check js "function with an argument" (Js.Number 42.) (Page.evaluate page "({ a, b }) => a * b" ~arg:(Js.obj [ "a", Js.int 6; "b", Js.int 7 ]));
    Alcotest.check js "nothing" Js.Undefined (Page.evaluate page "() => {}");
    let all_kinds =
        Js.Object
            [ "null", Js.Null; "undefined", Js.Undefined; "bool", Js.Bool true; "number", Js.Number 1.5; "infinity", Js.Number Float.neg_infinity;
              "string", Js.String "h\xC3\xA9llo \xF0\x9F\x98\x80"; "bigint", Js.Bigint "123456789012345678901234567890";
              "date", Js.Date "2024-02-29T12:00:00.000Z"; "url", Js.Url "https://example.com/a?b=c";
              "regexp", Js.Regexp { source = "a+b"; flags = "gi" }; "array", Js.Array [ Js.Number 1.; Js.Array []; Js.Object [] ];
              "bytes", Js.Typed_array { kind = `Ui8; bytes = "\000\001\255" } ]
    in
    Alcotest.check js "every kind of value survives the round trip" all_kinds (Page.evaluate page "value => value" ~arg:all_kinds);
    Alcotest.(check string) "the page sees real types" "bigint,Date,URL,RegExp,Uint8Array,true"
        (Page.evaluate page
             "v => [typeof v.bigint, v.date.constructor.name, v.url.constructor.name, v.regexp.constructor.name, v.bytes.constructor.name, Object.is(v.undefined, undefined)].join()"
             ~arg:all_kinds
        |> Js.to_string);
    (match Page.evaluate page "new TypeError('boom')" with
    | Js.Error { name; message; _ } -> Alcotest.(check (pair string string)) "error value" ("TypeError", "boom") (name, message)
    | other -> Alcotest.failf "unexpected %s" (Js.show other));
    Alcotest.check js "shared references" (Js.Array [ Js.Object [ "x", Js.Number 1. ]; Js.Object [ "x", Js.Number 1. ] ])
        (Page.evaluate page "() => { const o = { x: 1 }; return [o, o]; }");
    Alcotest.check json "a result that is JSON" (Yojson.Safe.from_string {|{"n":1,"list":["x",null,2.5],"nested":{"ok":true}}|})
        (Page.evaluate page "() => ({ n: 1, list: ['x', null, 2.5], nested: { ok: true } })" |> Js.to_json);
    check_failure "a result that is not" ~message:"value.list[1] is undefined" (fun () ->
        Page.evaluate page "() => ({ n: 1, list: ['x', undefined] })" |> Js.to_json);
    check_failure "exception in the page" ~kind:Other ~message:"nope" (fun () -> Page.evaluate page "() => { throw new Error('nope') }");
    check_failure "thrown value" ~message:"42" (fun () -> Page.evaluate page "() => { throw 42 }");
    check_failure "syntax error" ~message:"SyntaxError" (fun () -> Page.evaluate page "][")

let test_handles _ page =
    Page.set_content page {|<ul><li>one</li><li>two</li></ul>|};
    let handle = Page.evaluate_handle page "({ list: document.querySelector('ul'), n: 2 })" in
    let n = JSHandle.get_property handle "n" in
    Alcotest.check js "property" (Js.Number 2.) (JSHandle.json_value n);
    let list = JSHandle.get_property handle "list" in
    let element = JSHandle.as_element list |> Option.get in
    Alcotest.(check bool) "a number is no element" true (Option.is_none (JSHandle.as_element n));
    Alcotest.(check string) "element" "onetwo" (ElementHandle.evaluate element "ul => ul.textContent" |> Js.to_string);
    Alcotest.(check (list string)) "properties" [ "list"; "n" ] (List.map fst (JSHandle.get_properties handle));
    Alcotest.check js "a handle as an argument" (Js.Number 2.) (Page.evaluate page "ul => ul.children.length" ~arg:(Js.Handle list));
    Alcotest.check js "handles inside a structure" (Js.String "LI/2")
        (Page.evaluate page "({ item, n }) => item.tagName + '/' + n"
             ~arg:(Js.obj [ "item", Js.Handle (JSHandle.evaluate_handle list "ul => ul.firstElementChild"); "n", Js.Handle n ]));
    Alcotest.check js "evaluate on a handle" (Js.Number 3.) (JSHandle.evaluate handle "(o, extra) => o.n + extra" ~arg:(Js.int 1));
    (* A handle stands for an object in the page; as data it is nothing. *)
    check_failure "no JSON for a handle" ~message:"value.list is a handle" (fun () -> Js.to_json (Js.obj [ "list", Js.Handle list ]));
    JSHandle.dispose handle;
    check_failure "disposed handle" (fun () -> JSHandle.json_value handle)

let test_wait_for_function _ page =
    Page.set_content page "<div></div>";
    ignore (Page.evaluate page "setTimeout(() => { window.ready = { answer: 42 } }, 100)");
    let handle = Page.wait_for_function page "window.ready" in
    Alcotest.check js "the truthy value" (Js.Object [ "answer", Js.Number 42. ]) (JSHandle.json_value handle);
    Alcotest.check js "with an argument and polling" (Js.Bool true)
        (Page.wait_for_function page "n => window.ready.answer === n" ~arg:(Js.int 42) ~polling:20. |> JSHandle.json_value);
    check_failure "never true" ~kind:Timeout (fun () -> Page.wait_for_function page ~timeout:200. "window.never")

let test_exposed_functions _ page =
    let calls = ref [] in
    Page.expose_function page "add" (fun args ->
        calls := args :: !calls;
        match args with [ a; b ] -> Js.float (Js.to_float a +. Js.to_float b) | _ -> failwith "add takes two arguments")
    |> ignore;
    Alcotest.check js "result" (Js.Number 5.) (Page.evaluate page "window.add(2, 3)");
    Alcotest.(check int) "called once" 1 (List.length !calls);
    Alcotest.check js "an exception rejects the promise" (Js.String "add takes two arguments")
        (Page.evaluate page "window.add(1).then(() => 'resolved', error => error.message.replace(/^.*Failure\\(\"(.*)\"\\).*$/s, '$1'))");
    Page.expose_binding page "whoami" (fun source _ -> Js.string (Frame.url source.frame ^ (if Page.equal source.page page then " same page" else " other page"))) |> ignore;
    Alcotest.check js "binding source" (Js.String "about:blank same page") (Page.evaluate page "window.whoami()");
    (* Exposed functions survive navigations and may call back into the page. *)
    let title = Page.expose_function page "title" (fun _ -> Js.string (Page.title page)) in
    Page.set_content page "<title>Callback</title>";
    Alcotest.check js "reentrant" (Js.String "Callback") (Page.evaluate page "window.title()");
    check_failure "duplicate name" ~message:"add" (fun () -> Page.expose_function page "add" (fun _ -> Js.null));
    (* Taken back, the name is free again. *)
    Disposable.dispose title;
    Disposable.dispose title;
    Alcotest.check js "no longer exposed" (Js.String "undefined") (Page.evaluate page "typeof window.title");
    Page.expose_function page "title" (fun _ -> Js.string "another") |> ignore;
    Alcotest.check js "exposed anew" (Js.String "another") (Page.evaluate page "window.title()")

let test_init_scripts t page =
    Server.page t.server "/init" "<script>window.seenByPage = window.injected</script>";
    Page.add_init_script page "window.injected = 'early'" |> ignore;
    BrowserContext.add_init_script (Page.context page) "window.forAll = 7" |> ignore;
    ignore (Page.goto page (Server.url t.server "/init"));
    Alcotest.(check string) "runs before the page's scripts" "early" (eval_string "window.seenByPage" page);
    Alcotest.(check int) "for the whole context" 7 (eval_int "window.forAll" page);
    (* Taken back, a script is not added to the documents that follow. *)
    let passing = Page.add_init_script page "window.passing = true" in
    ignore (Page.reload page);
    Alcotest.(check string) "added" "boolean" (eval_string "typeof window.passing" page);
    Disposable.dispose passing;
    ignore (Page.reload page);
    Alcotest.(check string) "not added any more" "undefined" (eval_string "typeof window.passing" page);
    Alcotest.(check string) "the others still are" "early" (eval_string "window.injected" page)

let test_script_and_style_tags t page =
    Server.route t.server "/lib.js" (fun _ -> Server.respond ~content_type:"text/javascript" "window.lib = 'loaded'");
    Server.page t.server "/tags" "<body>text</body>";
    ignore (Page.goto page (Server.url t.server "/tags"));
    ignore (Page.add_script_tag page (`Url "/lib.js"));
    ignore (Page.add_script_tag page (`Content "window.inline = 1"));
    Alcotest.(check string) "script by URL" "loaded" (eval_string "window.lib" page);
    Alcotest.(check int) "inline script" 1 (eval_int "window.inline" page);
    ignore (Page.add_style_tag page (`Content "body { color: rgb(255, 0, 0) }"));
    Alcotest.(check string) "style" "rgb(255, 0, 0)" (eval_string "getComputedStyle(document.body).color" page)

let test_frames t page =
    Server.page t.server "/child" {|<title>Child</title><button>Inside</button>|};
    Server.page t.server "/parent" {|<title>Parent</title><iframe name="inner" src="/child"></iframe>|};
    ignore (Page.goto page (Server.url t.server "/parent"));
    let main = Page.main_frame page in
    Alcotest.(check int) "frames" 2 (List.length (Page.frames page));
    let child = Page.frame page (`Name "inner") |> Option.get in
    Alcotest.(check bool) "by URL" true (Option.equal Frame.equal (Page.frame page (`Url "**/child")) (Some child));
    Alcotest.(check bool) "no such frame" true (Option.is_none (Page.frame page (`Name "other")));
    Alcotest.(check string) "name" "inner" (Frame.name child);
    Alcotest.(check string) "url" (Server.url t.server "/child") (Frame.url child);
    Alcotest.(check string) "title" "Child" (Frame.title child);
    Alcotest.(check bool) "parent" true (Option.equal Frame.equal (Frame.parent_frame child) (Some main) && Option.is_none (Frame.parent_frame main));
    Alcotest.(check bool) "children" true (List.equal Frame.equal (Frame.child_frames main) [ child ]);
    Alcotest.(check bool) "page" true (Page.equal (Frame.page child) page);
    Alcotest.(check string) "evaluate in a frame" "Inside" (Frame.evaluate child "document.querySelector('button').textContent" |> Js.to_string);
    Alcotest.(check string) "frame element" "IFRAME" (ElementHandle.evaluate (Frame.frame_element child) "e => e.tagName" |> Js.to_string);
    Page.frame_locator page "iframe" |> FrameLocator.get_by_role `Button ~name:"Inside" |> Locator.click;
    Alcotest.(check string) "locator into the frame" "Inside" (Page.locator page "iframe" |> Locator.content_frame |> FrameLocator.locator "button" |> Locator.inner_text);
    let detached = Page.expect_event page Page.Frame_detached (fun () -> ignore (Page.evaluate page "document.querySelector('iframe').remove()")) in
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
