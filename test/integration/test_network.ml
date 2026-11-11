(* Request interception, HTTP requests without a page, and WebSocket routing. *)

open Eio.Std
open Playwright
open Harness

(* A server route that describes the request it received. *)
let echo (request : Server.request) =
    Server.json
        (`Assoc
             [ "method", `String request.method_; "query", `String request.query; "body", `String request.body;
               "headers", `Assoc (List.map (fun (name, value) -> name, `String value) request.headers) ])

let start t page =
    Server.route t.server "/echo" echo;
    Server.page t.server "/blank" "<title>Blank</title>";
    ignore (Page.goto (Server.url t.server "/blank") page)

(* Fetches in the page and describes the outcome. *)
let fetch ?(init = "{}") path page =
    Page.evaluate
        (Printf.sprintf
             "fetch(%S, %s).then(async r => ({ status: r.status, type: r.headers.get('content-type'), test: r.headers.get('x-test'), body: await r.text() }), e => ({ failed: true }))"
             path init)
        page

let field name value = Js.member name value
let body value = field "body" value |> Js.to_string

let test_fulfill t page =
    start t page;
    Page.route "**/api/user" (Route.fulfill ~json:(`Assoc [ "name", `String "Ada" ])) page |> ignore;
    let response = fetch "/api/user" page in
    Alcotest.(check string) "json body" {|{"name":"Ada"}|} (body response);
    Alcotest.(check string) "json content type" "application/json" (field "type" response |> Js.to_string);
    Alcotest.(check int) "default status" 200 (field "status" response |> Js.to_int);
    Page.route "**/api/created" (Route.fulfill ~status:201 ~headers:[ "x-test", "yes" ] ~content_type:"text/plain" ~body:"created") page |> ignore;
    let response = fetch "/api/created" page in
    Alcotest.(check (triple int string string)) "status, header and body" (201, "yes", "created")
        (field "status" response |> Js.to_int, field "test" response |> Js.to_string, body response);
    let file = scratch_file t "page.html" in
    write_file file "<title>From a file</title>";
    Page.route "**/from-file" (Route.fulfill ~path:file) page |> ignore;
    ignore (Page.goto (Server.url t.server "/from-file") page);
    Alcotest.(check string) "a file as the response, with its type" "From a file" (Page.title page);
    Alcotest.(check int) "none of this reached the server" 0
        (List.length (List.concat_map (Server.requests_for t.server) [ "/api/user"; "/api/created"; "/from-file" ]))

let test_abort_and_continue t page =
    start t page;
    Page.route "**/*.png" Route.abort page |> ignore;
    Alcotest.check js "aborted" (Js.Bool true) (fetch "/logo.png" page |> field "failed");
    let failed = Page.expect_event Page.Request_failed (fun () -> ignore (fetch "/other.png" page)) page in
    Alcotest.(check (option string)) "failure text" (Some "net::ERR_FAILED") (Request.failure failed);
    Page.route "**/denied" (Route.abort ~error_code:"accessdenied") page |> ignore;
    let failed = Page.expect_event Page.Request_failed (fun () -> ignore (fetch "/denied" page)) page in
    Alcotest.(check (option string)) "error code" (Some "net::ERR_ACCESS_DENIED") (Request.failure failed);
    Page.route "**/echo?*"
        (fun route ->
            let request = Route.request route in
            Route.continue ~method_:"POST" ~post_data:"changed" ~headers:(("x-added", "by the route") :: Request.headers request) route)
        page
    |> ignore;
    let seen = Yojson.Safe.from_string (body (fetch "/echo?q=1" page)) in
    let member name = Yojson.Safe.Util.member name seen in
    Alcotest.(check string) "method changed" "POST" (member "method" |> Yojson.Safe.Util.to_string);
    Alcotest.(check string) "body changed" "changed" (member "body" |> Yojson.Safe.Util.to_string);
    Alcotest.(check string) "header added" "by the route" (member "headers" |> Yojson.Safe.Util.member "x-added" |> Yojson.Safe.Util.to_string);
    Alcotest.(check string) "query kept" "q=1" (member "query" |> Yojson.Safe.Util.to_string)

let test_handler_order t page =
    start t page;
    let context = Page.context page in
    let order = ref [] in
    let passing name route =
        order := name :: !order;
        Route.fallback route
    in
    BrowserContext.route "**/chain" (fun route ->
        order := "context" :: !order;
        Route.fulfill ~body:"from the context" route)
        context
    |> ignore;
    Page.route "**/chain" (passing "page, first") page |> ignore;
    Page.route "**/chain" (passing "page, second") page |> ignore;
    Page.route_matching (fun url -> contains ~sub:"/chain" url) (passing "page, predicate") page |> ignore;
    Alcotest.(check string) "the first handler registered answers last" "from the context" (body (fetch "/chain" page));
    Alcotest.(check (list string)) "newest first, page before context" [ "page, predicate"; "page, second"; "page, first"; "context" ] (List.rev !order);
    (* A handler limited to a number of requests. *)
    Page.route ~times:1 "**/echo" (Route.fulfill ~body:"mocked once") page |> ignore;
    Alcotest.(check string) "first request" "mocked once" (body (fetch "/echo" page));
    Alcotest.(check bool) "second request reaches the server" true (contains ~sub:{|"method":"GET"|} (body (fetch "/echo" page)));
    (* Removing handlers. *)
    Page.route "**/echo" (Route.fulfill ~body:"mocked") page |> ignore;
    Alcotest.(check string) "mocked" "mocked" (body (fetch "/echo" page));
    Page.unroute "**/echo" page;
    Alcotest.(check bool) "unrouted" true (contains ~sub:{|"method":"GET"|} (body (fetch "/echo" page)));
    (* What registering returns removes that handler alone, however it was registered. *)
    let by_glob = Page.route "**/echo" (Route.fulfill ~body:"by glob") page in
    let by_predicate = Page.route_matching (contains ~sub:"/echo") (Route.fulfill ~body:"by predicate") page in
    Alcotest.(check string) "the newest handler" "by predicate" (body (fetch "/echo" page));
    Disposable.dispose by_predicate;
    Alcotest.(check string) "the one that remains" "by glob" (body (fetch "/echo" page));
    Disposable.dispose by_glob;
    Disposable.dispose by_glob;
    Alcotest.(check bool) "none" true (contains ~sub:{|"method":"GET"|} (body (fetch "/echo" page)));
    Page.unroute_all page;
    BrowserContext.unroute_all context;
    Alcotest.(check int) "nothing intercepts any more" 404 (fetch "/chain" page |> field "status" |> Js.to_int)

let test_modifying_responses t page =
    start t page;
    Server.route t.server "/api/items" (fun _ -> Server.json ~headers:[ "x-test", "from the server" ] (`Assoc [ "items", `List [ `Int 1; `Int 2 ] ]));
    Page.route "**/api/items"
        (fun route ->
            let response = Route.fetch route in
            Alcotest.(check int) "fetched" 200 (APIResponse.status response);
            let items = APIResponse.json response |> Yojson.Safe.Util.member "items" |> Yojson.Safe.Util.to_list in
            Route.fulfill ~response ~json:(`Assoc [ "items", `List (items @ [ `Int 3 ]) ]) route)
        page
    |> ignore;
    let response = fetch "/api/items" page in
    Alcotest.(check string) "modified body" {|{"items":[1,2,3]}|} (body response);
    Alcotest.(check string) "other parts of the response are kept" "from the server" (field "test" response |> Js.to_string)

let test_failing_handler t page =
    start t page;
    let one_report what expected =
        match take_reports t with
        | [ (_, Failure message) ] -> Alcotest.(check string) what expected message
        | reports -> Alcotest.failf "%s: expected one report, got %d" what (List.length reports)
    in
    (* A handler that fails has not let the request through: what it was there to block stays blocked. *)
    Page.route "**/echo" (fun _ -> failwith "handler failed") page |> ignore;
    let failed = Page.expect_event Page.Request_failed (fun () -> ignore (fetch "/echo" page)) page in
    Alcotest.(check (option string)) "the request fails" (Some "net::ERR_FAILED") (Request.failure failed);
    one_report "reported" "handler failed";
    (* Failing after the route was settled changes nothing about the request. *)
    Page.unroute_all page;
    Page.route "**/echo" (fun route -> Route.fulfill ~body:"settled" route; failwith "failed afterwards") page |> ignore;
    Alcotest.(check string) "the answer stands" "settled" (body (fetch "/echo" page));
    one_report "reported all the same" "failed afterwards";
    (* Concluding a route twice is a programming error that is pointed out. *)
    Page.unroute_all page;
    Page.route "**/echo"
        (fun route ->
            Route.fulfill ~body:"once" route;
            check_failure "handled twice" ~message:"already handled" (fun () -> Route.continue route))
        page
    |> ignore;
    Alcotest.(check string) "first conclusion counts" "once" (body (fetch "/echo" page))

(* Removing handlers while they are at work. *)
let test_unrouting_at_work t page =
    start t page;
    (* [`Wait] returns when they are done. *)
    let entered, enter = Promise.create () in
    let finished = ref false in
    Page.route "**/echo"
        (fun route ->
            Promise.resolve enter ();
            sleep t 0.2;
            finished := true;
            Route.fulfill ~body:"slowly" route)
        page
    |> ignore;
    let request = Fiber.fork_promise ~sw:t.sw (fun () -> body (fetch "/echo" page)) in
    Promise.await entered;
    Page.unroute_all ~behavior:`Wait page;
    Alcotest.(check bool) "waited for the handler" true !finished;
    Alcotest.(check string) "which answered" "slowly" (Promise.await_exn request);
    (* [`Ignore_errors] silences them, and their requests go on. *)
    let entered, enter = Promise.create () in
    let removed, remove = Promise.create () in
    Page.route "**/echo"
        (fun _ ->
            Promise.resolve enter ();
            Promise.await removed;
            failwith "failed after its removal")
        page
    |> ignore;
    let request = Fiber.fork_promise ~sw:t.sw (fun () -> body (fetch "/echo" page)) in
    Promise.await entered;
    Page.unroute_all ~behavior:`Ignore_errors page;
    Promise.resolve remove ();
    Alcotest.(check bool) "the request reaches the server" true (contains ~sub:{|"method":"GET"|} (Promise.await_exn request));
    Alcotest.(check int) "and nothing is reported" 0 (List.length (take_reports t))

let test_context_network_settings t () =
    Server.route t.server "/echo" echo;
    Server.route t.server "/secret" (fun request ->
        match List.assoc_opt "authorization" request.headers with
        | Some "Basic YWRhOmxvdmVsYWNl" -> Server.html "<title>Welcome</title>"
        | _ -> Server.respond ~status:401 ~headers:[ "www-authenticate", {|Basic realm="test"|} ] "who are you?");
    let context =
        Browser.new_context ~extra_http_headers:[ "x-context", "c" ] ~user_agent:"TestAgent/1.0"
            ~http_credentials:(Http_credentials.make ~username:"ada" ~password:"lovelace" ())
            t.browser
    in
    let page = BrowserContext.new_page context in
    Alcotest.(check int) "credentials" 200 (Page.goto (Server.url t.server "/secret") page |> Option.get |> Response.status);
    let headers () =
        ignore (Page.goto (Server.url t.server "/echo") page);
        Yojson.Safe.from_string (Page.inner_text "body" page) |> Yojson.Safe.Util.member "headers"
    in
    let header name = Yojson.Safe.Util.member name (headers ()) in
    Alcotest.check json "context header" (`String "c") (header "x-context");
    Alcotest.check json "user agent" (`String "TestAgent/1.0") (header "user-agent");
    Page.set_extra_http_headers [ "x-page", "p" ] page;
    Alcotest.check json "page header" (`String "p") (header "x-page");
    BrowserContext.set_offline true context;
    check_failure "offline" ~message:"ERR_INTERNET_DISCONNECTED" (fun () -> Page.goto (Server.url t.server "/echo") page);
    BrowserContext.set_offline false context;
    Alcotest.check json "online again" (`String "c") (header "x-context");
    BrowserContext.close context

let test_api_requests t page =
    start t page;
    let request = Page.request page in
    let described response = APIResponse.json response in
    let member name value = Yojson.Safe.Util.member name value in
    let url = Server.url t.server "/echo" in
    let response = APIRequestContext.get url ~params:[ "q", "a b"; "n", "1" ] ~headers:[ "x-custom", "yes" ] request in
    Alcotest.(check bool) "ok" true (APIResponse.ok response && APIResponse.status response = 200 && APIResponse.status_text response = "OK");
    Alcotest.(check string) "url" (url ^ "?q=a+b&n=1") (APIResponse.url response);
    Alcotest.(check (option string)) "response header" (Some "application/json") (APIResponse.header_value "Content-Type" response);
    Alcotest.check json "query" (`String "q=a+b&n=1") (member "query" (described response));
    Alcotest.check json "header" (`String "yes") (member "headers" (described response) |> member "x-custom");
    let posted = APIRequestContext.post url ~json:(`Assoc [ "n", `Int 1 ]) request |> described in
    Alcotest.check json "json body" (`String {|{"n":1}|}) (member "body" posted);
    Alcotest.check json "json content type" (`String "application/json") (member "headers" posted |> member "content-type");
    let form = APIRequestContext.post url ~form:[ "name", "Ada Lovelace"; "lang", "ml" ] request |> described in
    Alcotest.check json "form body" (`String "name=Ada+Lovelace&lang=ml") (member "body" form);
    let multipart =
        APIRequestContext.post url request
            ~multipart:[ "field", `Text "value"; "upload", `File { name = "notes.txt"; mime_type = Some "text/plain"; buffer = "file content" } ]
        |> described
    in
    check_contains "multipart content type" ~sub:"multipart/form-data; boundary=" (member "headers" multipart |> member "content-type" |> Yojson.Safe.Util.to_string);
    check_contains "multipart file" ~sub:{|filename="notes.txt"|} (member "body" multipart |> Yojson.Safe.Util.to_string);
    check_contains "multipart file content" ~sub:"file content" (member "body" multipart |> Yojson.Safe.Util.to_string);
    let methods =
        [ APIRequestContext.put url ~data:"raw" request; APIRequestContext.patch url request; APIRequestContext.delete url request;
          APIRequestContext.fetch ~method_:"OPTIONS" url request ]
    in
    Alcotest.(check (list string)) "methods" [ "PUT"; "PATCH"; "DELETE"; "OPTIONS" ]
        (List.map (fun response -> member "method" (described response) |> Yojson.Safe.Util.to_string) methods);
    Alcotest.(check string) "HEAD has no body" "" (APIRequestContext.head url request |> APIResponse.text);
    (* Status codes are results, unless asked otherwise. *)
    let missing = APIRequestContext.get (Server.url t.server "/nothing-here") request in
    Alcotest.(check bool) "404" true (APIResponse.status missing = 404 && not (APIResponse.ok missing));
    check_failure "to_be_ok" ~kind:Assertion_failed ~message:"404" (fun () -> Expect.to_be_ok missing);
    Expect.Not.to_be_ok missing;
    check_failure "fail_on_status_code" ~message:"404" (fun () -> APIRequestContext.get ~fail_on_status_code:true (Server.url t.server "/nothing-here") request);
    Server.route t.server "/slow-api" (fun _ ->
        sleep t 1.;
        Server.respond "late");
    check_failure "timeout" ~message:"200ms" (fun () -> APIRequestContext.get ~timeout:200. (Server.url t.server "/slow-api") request);
    (* Cookies are shared with the browser context, both ways. *)
    Server.route t.server "/login" (fun _ -> Server.respond ~headers:[ "set-cookie", "session=abc; Path=/" ] "logged in");
    ignore (APIRequestContext.get (Server.url t.server "/login") request);
    Alcotest.(check (list string)) "cookie from an API response" [ "session" ] (List.map (fun (c : Cookie.t) -> c.name) (BrowserContext.cookies (Page.context page)));
    Alcotest.(check string) "sent by the page" "session=abc" (eval_string "document.cookie" page);
    ignore (Page.evaluate "document.cookie = 'theme=dark'" page);
    check_contains "cookie from the page" ~sub:"theme=dark"
        (APIRequestContext.get url request |> described |> member "headers" |> member "cookie" |> Yojson.Safe.Util.to_string);
    Alcotest.(check (list string)) "the cookies of the request context" [ "session"; "theme" ]
        (APIRequestContext.cookies request |> List.map (fun (c : Cookie.t) -> c.name) |> List.sort compare);
    APIRequestContext.clear_cookies ~name:"theme" request;
    APIRequestContext.add_cookies [ Cookie.make ~url:(Server.origin t.server) "added" ~value:"1" ] request;
    Alcotest.(check string) "changed through the request context" "added=1; session=abc"
        (eval_string "document.cookie.split('; ').sort().join('; ')" page);
    APIResponse.dispose response;
    check_failure "disposed response" ~message:"disposed" (fun () -> APIResponse.body response)

let test_standalone_api_requests t () =
    Server.route t.server "/echo" echo;
    let request = APIRequest.new_context ~base_url:(Server.origin t.server) ~extra_http_headers:[ "x-client", "tests" ] ~user_agent:"ApiAgent" t.pw in
    let seen = APIRequestContext.get "/echo" request |> APIResponse.json |> Yojson.Safe.Util.member "headers" in
    Alcotest.check json "default header" (`String "tests") (Yojson.Safe.Util.member "x-client" seen);
    Alcotest.check json "user agent" (`String "ApiAgent") (Yojson.Safe.Util.member "user-agent" seen);
    Server.route t.server "/login" (fun _ -> Server.respond ~headers:[ "set-cookie", "session=abc; Path=/" ] "logged in");
    ignore (APIRequestContext.post "/login" request);
    let state = APIRequestContext.storage_state request in
    Alcotest.(check (list string)) "storage state" [ "session" ]
        (Yojson.Safe.Util.member "cookies" state |> Yojson.Safe.Util.to_list |> List.map (fun c -> Yojson.Safe.Util.member "name" c |> Yojson.Safe.Util.to_string));
    (* The state carries over to a browser context. *)
    let context = Browser.new_context ~storage_state:state t.browser in
    Alcotest.(check int) "cookies restored in a browser" 1 (List.length (BrowserContext.cookies context));
    BrowserContext.close context;
    APIRequestContext.dispose request;
    check_failure "disposed" ~kind:Target_closed (fun () -> APIRequestContext.get "/echo" request);
    APIRequestContext.dispose request

let test_web_socket_routes t page =
    start t page;
    Page.route_web_socket "ws://mock.test/chat"
        (fun socket ->
            Alcotest.(check string) "url" "ws://mock.test/chat" (WebSocketRoute.url socket);
            WebSocketRoute.on_message
                (fun message ->
                    match message with
                    | Text "bye" -> WebSocketRoute.close ~code:4000 ~reason:"goodbye" socket
                    | Text text -> WebSocketRoute.send (Text ("echo: " ^ text)) socket
                    | Binary bytes -> WebSocketRoute.send (Binary (String.uppercase_ascii bytes)) socket)
                socket)
        page
    |> ignore;
    let conversation =
        Page.evaluate
            {|() => new Promise(resolve => {
                const log = [];
                const socket = new WebSocket('ws://mock.test/chat');
                socket.binaryType = 'arraybuffer';
                socket.onopen = () => { socket.send('hello'); socket.send(new TextEncoder().encode('bin')); socket.send('bye'); };
                socket.onmessage = event => log.push(typeof event.data === 'string' ? event.data : 'binary ' + new TextDecoder().decode(event.data));
                socket.onclose = event => resolve([...log, `closed ${event.code} ${event.reason}`]);
            })|}
            page
    in
    Alcotest.(check (list string)) "a mocked server" [ "echo: hello"; "binary BIN"; "closed 4000 goodbye" ] (Js.to_list Js.to_string conversation);
    (* What a socket comes to: opened, or closed without having been. *)
    let fate url =
        Page.evaluate
            {|url => new Promise(resolve => {
                const socket = new WebSocket(url);
                socket.onopen = () => resolve('opened');
                socket.onclose = event => resolve('closed, ' + (event.wasClean ? 'cleanly' : 'not cleanly'));
            })|}
            ~arg:(Js.string url) page
        |> Js.to_string
    in
    (* A handler that fails serves nobody; the page is told, rather than left waiting. *)
    Page.route_web_socket "ws://mock.test/broken" (fun _ -> failwith "socket handler failed") page |> ignore;
    Alcotest.(check string) "the socket is closed" "closed, not cleanly" (fate "ws://mock.test/broken");
    (match take_reports t with
    | [ (_, Failure message) ] -> Alcotest.(check string) "reported" "socket handler failed" message
    | reports -> Alcotest.failf "expected one report, got %d" (List.length reports));
    (* Nothing listens on port 1, so this socket only opens for as long as it is mocked. *)
    let mocked = Page.route_web_socket "ws://127.0.0.1:1/" (fun _ -> ()) page in
    Alcotest.(check string) "mocked" "opened" (fate "ws://127.0.0.1:1/");
    Disposable.dispose mocked;
    Alcotest.(check string) "no longer mocked" "closed, not cleanly" (fate "ws://127.0.0.1:1/")

let tests t =
    [ "routing",
      [ page_case t "fulfill" (test_fulfill t);
        page_case t "abort and continue" (test_abort_and_continue t);
        page_case t "handler order, limits and removal" (test_handler_order t);
        page_case t "modifying responses" (test_modifying_responses t);
        page_case t "failing handlers" (test_failing_handler t);
        page_case t "removing handlers that are at work" (test_unrouting_at_work t);
        page_case t "WebSocket routes" (test_web_socket_routes t) ];
      "network",
      [ case t "context settings" (test_context_network_settings t);
        page_case t "API requests" (test_api_requests t);
        case t "standalone API requests" (test_standalone_api_requests t) ] ]
