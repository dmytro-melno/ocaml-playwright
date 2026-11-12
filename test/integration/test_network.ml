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
    ignore (Page.goto page (Server.url t.server "/blank"))

(* Fetches in the page and describes the outcome. *)
let fetch ?(init = "{}") path page =
    Page.evaluate page
        (Printf.sprintf
             "fetch(%S, %s).then(async r => ({ status: r.status, type: r.headers.get('content-type'), test: r.headers.get('x-test'), body: await r.text() }), e => ({ failed: true }))"
             path init)

let field name value = Js.member name value
let body value = field "body" value |> Js.to_string

let test_fulfill t page =
    start t page;
    Page.route page "**/api/user" (Route.fulfill ~json:(`Assoc [ "name", `String "Ada" ])) |> ignore;
    let response = fetch "/api/user" page in
    Alcotest.(check string) "json body" {|{"name":"Ada"}|} (body response);
    Alcotest.(check string) "json content type" "application/json" (field "type" response |> Js.to_string);
    Alcotest.(check int) "default status" 200 (field "status" response |> Js.to_int);
    Page.route page "**/api/created" (Route.fulfill ~status:201 ~headers:[ "x-test", "yes" ] ~content_type:"text/plain" ~body:"created") |> ignore;
    let response = fetch "/api/created" page in
    Alcotest.(check (triple int string string)) "status, header and body" (201, "yes", "created")
        (field "status" response |> Js.to_int, field "test" response |> Js.to_string, body response);
    Page.route page "**/a-page" (Route.fulfill ~content_type:"text/html" ~body:"<title>Made up</title>") |> ignore;
    ignore (Page.goto page (Server.url t.server "/a-page"));
    Alcotest.(check string) "a document" "Made up" (Page.title page);
    Alcotest.(check int) "none of this reached the server" 0
        (List.length (List.concat_map (Server.requests_for t.server) [ "/api/user"; "/api/created"; "/a-page" ]))

let test_abort_and_continue t page =
    start t page;
    Page.route page "**/*.png" Route.abort |> ignore;
    Alcotest.check js "aborted" (Js.Bool true) (fetch "/logo.png" page |> field "failed");
    let failed = Page.expect_event page Page.Request_failed (fun () -> ignore (fetch "/other.png" page)) in
    Alcotest.(check (option string)) "failure text" (Some "net::ERR_FAILED") (Request.failure failed);
    (* The driver knows every code that the interface offers: it would refuse another one in the handler, and leave
       the request waiting. *)
    List.iter
        (fun (error_code, text) ->
            let aborting = Page.route page "**/denied" (Route.abort ~error_code) in
            let failed = Page.expect_event page Page.Request_failed (fun () -> ignore (fetch "/denied" page)) in
            let failure = Option.value (Request.failure failed) ~default:"no failure" in
            Alcotest.(check bool) (Printf.sprintf "net::ERR_%s is how the request fails: %s" text failure) true
                (String.starts_with ~prefix:("net::ERR_" ^ text) failure);
            Disposable.dispose aborting)
        [ `Aborted, "ABORTED"; `Accessdenied, "ACCESS_DENIED"; `Addressunreachable, "ADDRESS_UNREACHABLE"; `Blockedbyclient, "BLOCKED_BY_CLIENT";
          `Blockedbyresponse, "BLOCKED_BY_RESPONSE"; `Connectionaborted, "CONNECTION_ABORTED"; `Connectionclosed, "CONNECTION_CLOSED";
          `Connectionfailed, "CONNECTION_FAILED"; `Connectionrefused, "CONNECTION_REFUSED"; `Connectionreset, "CONNECTION_RESET";
          `Internetdisconnected, "INTERNET_DISCONNECTED"; `Namenotresolved, "NAME_NOT_RESOLVED"; `Timedout, "TIMED_OUT"; `Failed, "FAILED" ];
    Page.route page "**/echo?*"
        (fun route ->
            let request = Route.request route in
            Route.continue route ~method_:"POST" ~post_data:"changed" ~headers:(("x-added", "by the route") :: Request.headers request))
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
    BrowserContext.route context "**/chain" (fun route ->
        order := "context" :: !order;
        Route.fulfill route ~body:"from the context")
    |> ignore;
    Page.route page "**/chain" (passing "page, first") |> ignore;
    Page.route page "**/chain" (passing "page, second") |> ignore;
    Page.route_matching page (fun url -> contains ~sub:"/chain" url) (passing "page, predicate") |> ignore;
    Alcotest.(check string) "the first handler registered answers last" "from the context" (body (fetch "/chain" page));
    Alcotest.(check (list string)) "newest first, page before context" [ "page, predicate"; "page, second"; "page, first"; "context" ] (List.rev !order);
    (* A handler limited to a number of requests. *)
    Page.route page ~times:1 "**/echo" (Route.fulfill ~body:"mocked once") |> ignore;
    Alcotest.(check string) "first request" "mocked once" (body (fetch "/echo" page));
    Alcotest.(check bool) "second request reaches the server" true (contains ~sub:{|"method":"GET"|} (body (fetch "/echo" page)));
    (* Removing handlers. *)
    (* What registering returns removes that handler alone, however it was registered. *)
    let by_glob = Page.route page "**/echo" (Route.fulfill ~body:"by glob") in
    let by_predicate = Page.route_matching page (contains ~sub:"/echo") (Route.fulfill ~body:"by predicate") in
    Alcotest.(check string) "the newest handler" "by predicate" (body (fetch "/echo" page));
    Disposable.dispose by_predicate;
    Alcotest.(check string) "the one that remains" "by glob" (body (fetch "/echo" page));
    Disposable.dispose by_glob;
    Disposable.dispose by_glob;
    Alcotest.(check bool) "none" true (contains ~sub:{|"method":"GET"|} (body (fetch "/echo" page)));
    (* A glob that cannot be read is refused where it is given, and registers nothing. *)
    check_failure "a malformed glob" ~message:"Invalid glob pattern" (fun () -> Page.route page "**/{echo" (Route.fulfill ~body:"never"));
    check_failure "a malformed glob for a wait" ~message:"Invalid glob pattern" (fun () -> Page.wait_for_url page ~timeout:100. "{a,{b}}");
    Alcotest.(check bool) "still none" true (contains ~sub:{|"method":"GET"|} (body (fetch "/echo" page)));
    Page.unroute_all page;
    BrowserContext.unroute_all context;
    Alcotest.(check int) "nothing intercepts any more" 404 (fetch "/chain" page |> field "status" |> Js.to_int)

let test_modifying_responses t page =
    start t page;
    Server.route t.server "/api/items" (fun _ -> Server.json ~headers:[ "x-test", "from the server" ] (`Assoc [ "items", `List [ `Int 1; `Int 2 ] ]));
    Page.route page "**/api/items"
        (fun route ->
            let response = Route.fetch route in
            Alcotest.(check int) "fetched" 200 (APIResponse.status response);
            let items = APIResponse.json response |> Yojson.Safe.Util.member "items" |> Yojson.Safe.Util.to_list in
            Route.fulfill route ~response ~json:(`Assoc [ "items", `List (items @ [ `Int 3 ]) ]))
    |> ignore;
    let response = fetch "/api/items" page in
    Alcotest.(check string) "modified body" {|{"items":[1,2,3]}|} (body response);
    Alcotest.(check string) "other parts of the response are kept" "from the server" (field "test" response |> Js.to_string);
    (* A response that is passed on as it is has its body replayed by the driver. *)
    Page.route page "**/api/items" (fun route -> Route.fulfill route ~response:(Route.fetch route) ~headers:[ "x-test", "replayed" ]) |> ignore;
    let response = fetch "/api/items" page in
    Alcotest.(check string) "the body of the response" {|{"items":[1,2]}|} (body response);
    Alcotest.(check string) "with headers of our own" "replayed" (field "test" response |> Js.to_string)

let test_failing_handler t page =
    start t page;
    let one_report what expected =
        match take_reports t with
        | [ (_, Failure message) ] -> Alcotest.(check string) what expected message
        | reports -> Alcotest.failf "%s: expected one report, got %d" what (List.length reports)
    in
    (* A handler that fails has not let the request through: what it was there to block stays blocked. *)
    Page.route page "**/echo" (fun _ -> failwith "handler failed") |> ignore;
    let failed = Page.expect_event page Page.Request_failed (fun () -> ignore (fetch "/echo" page)) in
    Alcotest.(check (option string)) "the request fails" (Some "net::ERR_FAILED") (Request.failure failed);
    one_report "reported" "handler failed";
    (* Failing after the route was settled changes nothing about the request. *)
    Page.unroute_all page;
    Page.route page "**/echo" (fun route -> Route.fulfill route ~body:"settled"; failwith "failed afterwards") |> ignore;
    Alcotest.(check string) "the answer stands" "settled" (body (fetch "/echo" page));
    one_report "reported all the same" "failed afterwards";
    (* Concluding a route twice is a programming error that is pointed out. *)
    Page.unroute_all page;
    Page.route page "**/echo"
        (fun route ->
            Route.fulfill route ~body:"once";
            check_failure "handled twice" ~message:"already handled" (fun () -> Route.continue route))
    |> ignore;
    Alcotest.(check string) "first conclusion counts" "once" (body (fetch "/echo" page))

(* Removing handlers while they are at work. *)
let test_unrouting_at_work t page =
    start t page;
    (* [`Wait] returns when they are done. *)
    let entered, enter = Promise.create () in
    let finished = ref false in
    Page.route page "**/echo"
        (fun route ->
            Promise.resolve enter ();
            sleep t 0.2;
            finished := true;
            Route.fulfill route ~body:"slowly")
    |> ignore;
    let request = Fiber.fork_promise ~sw:t.sw (fun () -> body (fetch "/echo" page)) in
    Promise.await entered;
    Page.unroute_all page ~behavior:`Wait;
    Alcotest.(check bool) "waited for the handler" true !finished;
    Alcotest.(check string) "which answered" "slowly" (Promise.await_exn request);
    (* [`Ignore_errors] silences them, and their requests go on. *)
    let entered, enter = Promise.create () in
    let removed, remove = Promise.create () in
    Page.route page "**/echo"
        (fun _ ->
            Promise.resolve enter ();
            Promise.await removed;
            failwith "failed after its removal")
    |> ignore;
    let request = Fiber.fork_promise ~sw:t.sw (fun () -> body (fetch "/echo" page)) in
    Promise.await entered;
    Page.unroute_all page ~behavior:`Ignore_errors;
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
        Browser.new_context t.browser ~extra_http_headers:[ "x-context", "c" ] ~user_agent:"TestAgent/1.0"
            ~http_credentials:
              [ Http_credentials.make ~origin:"https://elsewhere.test" ~username:"eve" ~password:"guess" ();
                Http_credentials.make ~origin:(Server.origin t.server) ~username:"ada" ~password:"lovelace" () ]
    in
    let page = BrowserContext.new_page context in
    Alcotest.(check int) "credentials" 200 (Page.goto page (Server.url t.server "/secret") |> Option.get |> Response.status);
    let headers () =
        ignore (Page.goto page (Server.url t.server "/echo"));
        Yojson.Safe.from_string (Locator.inner_text (Page.locator page "body")) |> Yojson.Safe.Util.member "headers"
    in
    let header name = Yojson.Safe.Util.member name (headers ()) in
    Alcotest.check json "context header" (`String "c") (header "x-context");
    Alcotest.check json "user agent" (`String "TestAgent/1.0") (header "user-agent");
    Page.set_extra_http_headers page [ "x-page", "p" ];
    Alcotest.check json "page header" (`String "p") (header "x-page");
    BrowserContext.set_offline context true;
    check_failure "offline" ~message:"ERR_INTERNET_DISCONNECTED" (fun () -> Page.goto page (Server.url t.server "/echo"));
    BrowserContext.set_offline context false;
    Alcotest.check json "online again" (`String "c") (header "x-context");
    BrowserContext.close context

let test_api_requests t page =
    start t page;
    let request = Page.request page in
    let described response = APIResponse.json response in
    let member name value = Yojson.Safe.Util.member name value in
    let url = Server.url t.server "/echo" in
    let response = APIRequestContext.get request url ~params:[ "q", "a b"; "n", "1" ] ~headers:[ "x-custom", "yes" ] in
    Alcotest.(check bool) "ok" true (APIResponse.ok response && APIResponse.status response = 200 && APIResponse.status_text response = "OK");
    Alcotest.(check string) "url" (url ^ "?q=a+b&n=1") (APIResponse.url response);
    Alcotest.(check (option string)) "response header" (Some "application/json") (List.assoc_opt "content-type" (APIResponse.headers response));
    Alcotest.check json "query" (`String "q=a+b&n=1") (member "query" (described response));
    let address = Option.get (APIResponse.server_addr response) in
    Alcotest.(check bool) "the server's address" true (address.ip_address = "127.0.0.1" && Server.origin t.server = Printf.sprintf "http://127.0.0.1:%d" address.port);
    Alcotest.(check bool) "no certificate over HTTP" true (APIResponse.security_details response = None);
    let timing = APIResponse.timing response in
    Alcotest.(check bool) "timing" true (timing.start_time > 0. && timing.response_end >= timing.response_start && timing.response_start >= 0.);
    Alcotest.check json "header" (`String "yes") (member "headers" (described response) |> member "x-custom");
    let posted = APIRequestContext.post request url ~json:(`Assoc [ "n", `Int 1 ]) |> described in
    Alcotest.check json "json body" (`String {|{"n":1}|}) (member "body" posted);
    Alcotest.check json "json content type" (`String "application/json") (member "headers" posted |> member "content-type");
    let form = APIRequestContext.post request url ~form:[ "name", "Ada Lovelace"; "lang", "ml" ] |> described in
    Alcotest.check json "form body" (`String "name=Ada+Lovelace&lang=ml") (member "body" form);
    (* Data are bytes: what the headers call them does not change them. *)
    List.iter
        (fun content_type ->
            let raw = APIRequestContext.post request url ~headers:[ "content-type", content_type ] ~data:"not-json" |> described in
            Alcotest.check json ("data as it is, called " ^ content_type) (`String "not-json") (member "body" raw))
        [ "application/json"; "application/json; charset=utf-8"; "text/plain" ];
    let multipart =
        APIRequestContext.post request url
            ~multipart:[ "field", `Text "value"; "upload", `File { name = "notes.txt"; mime_type = Some "text/plain"; buffer = "file content" } ]
        |> described
    in
    check_contains "multipart content type" ~sub:"multipart/form-data; boundary=" (member "headers" multipart |> member "content-type" |> Yojson.Safe.Util.to_string);
    check_contains "multipart file" ~sub:{|filename="notes.txt"|} (member "body" multipart |> Yojson.Safe.Util.to_string);
    check_contains "multipart file content" ~sub:"file content" (member "body" multipart |> Yojson.Safe.Util.to_string);
    let methods =
        [ APIRequestContext.put request url ~data:"raw"; APIRequestContext.patch request url; APIRequestContext.delete request url;
          APIRequestContext.fetch request ~method_:"OPTIONS" url ]
    in
    Alcotest.(check (list string)) "methods" [ "PUT"; "PATCH"; "DELETE"; "OPTIONS" ]
        (List.map (fun response -> member "method" (described response) |> Yojson.Safe.Util.to_string) methods);
    Alcotest.(check string) "HEAD has no body" "" (APIRequestContext.head request url |> APIResponse.body);
    (* Status codes are results, unless asked otherwise. *)
    let missing = APIRequestContext.get request (Server.url t.server "/nothing-here") in
    Alcotest.(check bool) "404" true (APIResponse.status missing = 404 && not (APIResponse.ok missing));
    check_failure "to_be_ok" ~kind:Assertion_failed ~message:"404" (fun () -> Expect.to_be_ok missing);
    Expect.Not.to_be_ok missing;
    check_failure "fail_on_status_code" ~message:"404" (fun () -> APIRequestContext.get request ~fail_on_status_code:true (Server.url t.server "/nothing-here"));
    Server.route t.server "/slow-api" (fun _ ->
        sleep t 1.;
        Server.respond "late");
    check_failure "timeout" ~message:"200ms" (fun () -> APIRequestContext.get request ~timeout:200. (Server.url t.server "/slow-api"));
    (* Cookies are shared with the browser context, both ways. *)
    Server.route t.server "/login" (fun _ -> Server.respond ~headers:[ "set-cookie", "session=abc; Path=/" ] "logged in");
    ignore (APIRequestContext.get request (Server.url t.server "/login"));
    Alcotest.(check (list string)) "cookie from an API response" [ "session" ] (List.map (fun (c : Cookie.t) -> c.name) (BrowserContext.cookies (Page.context page)));
    Alcotest.(check string) "sent by the page" "session=abc" (eval_string "document.cookie" page);
    ignore (Page.evaluate page "document.cookie = 'theme=dark'");
    check_contains "cookie from the page" ~sub:"theme=dark"
        (APIRequestContext.get request url |> described |> member "headers" |> member "cookie" |> Yojson.Safe.Util.to_string);
    Alcotest.(check (list string)) "the cookies of the request context" [ "session"; "theme" ]
        (APIRequestContext.cookies request |> List.map (fun (c : Cookie.t) -> c.name) |> List.sort compare);
    APIRequestContext.clear_cookies request ~name:"theme";
    APIRequestContext.add_cookies request [ Cookie.make ~url:(Server.origin t.server) "added" ~value:"1" ];
    Alcotest.(check string) "changed through the request context" "added=1; session=abc"
        (eval_string "document.cookie.split('; ').sort().join('; ')" page);
    APIResponse.dispose response;
    check_failure "disposed response" ~message:"disposed" (fun () -> APIResponse.body response)

let test_standalone_api_requests t () =
    Server.route t.server "/echo" echo;
    let request = APIRequest.new_context t.pw ~base_url:(Server.origin t.server) ~extra_http_headers:[ "x-client", "tests" ] ~user_agent:"ApiAgent" in
    let tracing = APIRequestContext.tracing request in
    Tracing.start tracing;
    let seen = APIRequestContext.get request "/echo" |> APIResponse.json |> Yojson.Safe.Util.member "headers" in
    let trace = scratch_file t "requests.zip" in
    Tracing.stop tracing ~path:trace;
    Alcotest.(check string) "a trace of the requests" "PK" (String.sub (read_file trace) 0 2);
    Alcotest.check json "default header" (`String "tests") (Yojson.Safe.Util.member "x-client" seen);
    Alcotest.check json "user agent" (`String "ApiAgent") (Yojson.Safe.Util.member "user-agent" seen);
    Server.route t.server "/login" (fun _ -> Server.respond ~headers:[ "set-cookie", "session=abc; Path=/" ] "logged in");
    ignore (APIRequestContext.post request "/login");
    let state = APIRequestContext.storage_state request in
    Alcotest.(check (list string)) "storage state" [ "session" ]
        (Yojson.Safe.Util.member "cookies" state |> Yojson.Safe.Util.to_list |> List.map (fun c -> Yojson.Safe.Util.member "name" c |> Yojson.Safe.Util.to_string));
    (* The state carries over to a browser context. *)
    let context = Browser.new_context t.browser ~storage_state:state in
    Alcotest.(check int) "cookies restored in a browser" 1 (List.length (BrowserContext.cookies context));
    BrowserContext.close context;
    APIRequestContext.dispose request;
    check_failure "disposed" ~kind:Target_closed (fun () -> APIRequestContext.get request "/echo");
    APIRequestContext.dispose request;
    (* Credentials wait for a server to ask for them, unless they are to be sent at once. *)
    let authorization send =
        let request = APIRequest.new_context t.pw ~http_credentials:[ Http_credentials.make ?send ~username:"ada" ~password:"lovelace" () ] in
        let seen = APIRequestContext.get request (Server.url t.server "/echo") |> APIResponse.json |> Yojson.Safe.Util.member "headers" in
        APIRequestContext.dispose request;
        Yojson.Safe.Util.member "authorization" seen
    in
    Alcotest.check json "credentials nobody asked for" `Null (authorization None);
    Alcotest.check json "sent regardless" (`String "Basic YWRhOmxvdmVsYWNl") (authorization (Some `Always))

(* Playwright lets the request context of a browser context be disposed of, and such a context is gone for good.
   What needs it afterwards says so, rather than that a page has been closed, and the pages are as they were. *)
let test_disposed_request_context t page =
    Server.route t.server "/echo" echo;
    let context = Page.context page in
    let request = BrowserContext.request context in
    let url = Server.url t.server "/echo" in
    Alcotest.(check int) "before" 200 (APIRequestContext.get request url |> APIResponse.status);
    APIRequestContext.dispose request;
    let disposed what f = check_failure what ~kind:Target_closed ~message:"Request context disposed" f in
    disposed "a request" (fun () -> APIRequestContext.get (BrowserContext.request context) url);
    disposed "a request of the page" (fun () -> APIRequestContext.get (Page.request page) url);
    disposed "its cookies" (fun () -> APIRequestContext.cookies request);
    disposed "its state" (fun () -> APIRequestContext.storage_state request);
    let fetching = Page.route page "**/echo" (fun route -> Route.fulfill route ~response:(Route.fetch route)) in
    check_failure "a page whose route fetches" ~message:"net::ERR_FAILED" (fun () -> Page.goto page url);
    (match take_reports t with
    | [ (_, Playwright.Error { kind = Target_closed; message; _ }) ] -> check_contains "what the handler is told" ~sub:"Request context disposed" message
    | reports -> Alcotest.failf "expected one report, of the handler, and got %d" (List.length reports));
    Disposable.dispose fetching;
    ignore (Page.goto page url);
    check_contains "the page loads as before" ~sub:{|"method":"GET"|} (Locator.inner_text (Page.locator page "body"));
    APIRequestContext.dispose request ~reason:"once more";
    disposed "after another call" (fun () -> APIRequestContext.get request url)

(* A server that asks for a certificate is shown the one for its origin. *)
let test_client_certificates t () =
    let cert = scratch_file t "cert.pem" and key = scratch_file t "key.pem" in
    write_file cert Tls_server.certificate;
    write_file key Tls_server.private_key;
    Tls_server.run t.env ~cert ~key @@ fun origin ->
    let shown certificates =
        let context = Browser.new_context t.browser ~ignore_https_errors:true ~client_certificates:certificates in
        Fun.protect
            ~finally:(fun () -> BrowserContext.close context)
            (fun () ->
                let page = BrowserContext.new_page context in
                ignore (Page.goto page origin);
                Locator.inner_text (Page.locator page "body"))
    in
    let known = "client: " ^ Tls_server.common_name in
    let cert = Tls_server.certificate and key = Tls_server.private_key in
    let certificate = Client_certificate.pem ~origin ~cert ~key () in
    Alcotest.(check string) "without a certificate" "client: nobody" (shown []);
    Alcotest.(check string) "a certificate and its key" known (shown [ certificate ]);
    Alcotest.(check string) "an archive" known (shown [ Client_certificate.pfx ~passphrase:Tls_server.archive_passphrase ~origin Tls_server.archive ]);
    Alcotest.(check string) "of another origin" "client: nobody" (shown [ Client_certificate.pem ~origin:"https://elsewhere.test" ~cert ~key () ]);
    let request = APIRequest.new_context t.pw ~ignore_https_errors:true ~client_certificates:[ certificate ] in
    Alcotest.(check string) "a request context" known (APIRequestContext.get request origin |> APIResponse.body);
    APIRequestContext.dispose request;
    check_failure "what is no key" ~message:"Failed to load client certificate" (fun () -> shown [ Client_certificate.pem ~origin ~cert ~key:"nonsense" () ])

let test_web_socket_routes t page =
    start t page;
    Page.route_web_socket page "ws://mock.test/chat"
        (fun socket ->
            Alcotest.(check string) "url" "ws://mock.test/chat" (WebSocketRoute.url socket);
            WebSocketRoute.on_message socket
                (fun message ->
                    match message with
                    | Text "bye" -> WebSocketRoute.close socket ~code:4000 ~reason:"goodbye"
                    | Text text -> WebSocketRoute.send socket (Text ("echo: " ^ text))
                    | Binary bytes -> WebSocketRoute.send socket (Binary (String.uppercase_ascii bytes))))
    |> ignore;
    let conversation =
        Page.evaluate page
            {|() => new Promise(resolve => {
                const log = [];
                const socket = new WebSocket('ws://mock.test/chat');
                socket.binaryType = 'arraybuffer';
                socket.onopen = () => { socket.send('hello'); socket.send(new TextEncoder().encode('bin')); socket.send('bye'); };
                socket.onmessage = event => log.push(typeof event.data === 'string' ? event.data : 'binary ' + new TextDecoder().decode(event.data));
                socket.onclose = event => resolve([...log, `closed ${event.code} ${event.reason}`]);
            })|}
    in
    Alcotest.(check (list string)) "a mocked server" [ "echo: hello"; "binary BIN"; "closed 4000 goodbye" ] (Js.to_list Js.to_string conversation);
    (* What a socket comes to: opened, or closed without having been. *)
    let fate url =
        Page.evaluate page
            {|url => new Promise(resolve => {
                const socket = new WebSocket(url);
                socket.onopen = () => resolve('opened');
                socket.onclose = event => resolve('closed, ' + (event.wasClean ? 'cleanly' : 'not cleanly'));
            })|}
            ~arg:(Js.string url)
        |> Js.to_string
    in
    (* A handler that fails serves nobody; the page is told, rather than left waiting. *)
    Page.route_web_socket page "ws://mock.test/broken" (fun _ -> failwith "socket handler failed") |> ignore;
    Alcotest.(check string) "the socket is closed" "closed, not cleanly" (fate "ws://mock.test/broken");
    (match take_reports t with
    | [ (_, Failure message) ] -> Alcotest.(check string) "reported" "socket handler failed" message
    | reports -> Alcotest.failf "expected one report, got %d" (List.length reports));
    (* Nothing listens on port 1, so this socket only opens for as long as it is mocked. *)
    let mocked = Page.route_web_socket page "ws://127.0.0.1:1/" (fun _ -> ()) in
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
        case t "standalone API requests" (test_standalone_api_requests t);
        page_case t "a disposed request context" (test_disposed_request_context t);
        case t "client certificates" (test_client_certificates t) ] ]
