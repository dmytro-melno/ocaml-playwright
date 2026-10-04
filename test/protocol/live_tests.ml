open Playwright

let check name condition = if not condition then failwith ("ASSERTION FAILED: " ^ name)
let test name f = f (); Printf.printf "PASS protocol OCaml %s\n%!" name
let get = function Ok x -> x | Error e -> failwith e
let edges = [""; "\000"; "\255\128\000Hello\r\n"; String.init 256 Char.chr]
let json_bytes bytes = `List (List.init (String.length bytes) (fun i -> `Int (Char.code bytes.[i])))
let png bytes = String.starts_with ~prefix:"\137PNG\r\n\026\n" bytes
let jpeg bytes = String.starts_with ~prefix:"\255\216\255" bytes
let member = Yojson.Safe.Util.member
let await clock predicate =
    Eio.Time.with_timeout_exn clock 3. (fun () ->
        while not (predicate ()) do Eio.Time.sleep clock 0.01 done)

let run env =
    Eio.Switch.run (fun sw ->
        let clock = Eio.Stdenv.clock env in
        let pw = create ~env ~sw () in
        Fun.protect ~finally:(fun () -> destroy pw) (fun () ->
            check "driver version" (Driver.version = "1.59.1");
            let browser = BrowserType.launch ~executable_path:"/usr/bin/chromium" ~headless:true (Playwright.chromium pw) in
            let context = Browser.new_context browser in
            let page = BrowserContext.new_page context in
            let base = Sys.getenv "PROTOCOL_TEST_URL" in
            ignore (Page.goto ~url:base ~timeout:3000. page);
            test "manual context subscriptions and typed page-error/console events" (fun () ->
                let consoles = ref [] and errors = ref [] in
                BrowserContext.on_console context (fun event -> consoles := event :: !consoles);
                BrowserContext.on_page_error context (fun event -> errors := event :: !errors);
                BrowserContext.update_subscription ~event:`Console ~enabled:true context;
                ignore (Page.evaluate ~expression:"console.log('protocol-console'); setTimeout(() => { throw new Error('protocol-page-error') }, 0)" page);
                await clock (fun () -> !consoles <> [] && !errors <> []);
                let console = List.hd !consoles and error = List.hd !errors in
                check "console text" (console.text = "protocol-console");
                check "console location" (console.location.line_number >= 0 && console.location.column_number >= 0);
                check "error message" ((Option.get error.error.error).message = "protocol-page-error");
                check "event page identity" (Internal.guid error.page = Internal.guid page);
                BrowserContext.update_subscription ~event:`Console ~enabled:false context);
            test "failed expect retains actual SerializedValue" (fun () ->
                let result = Locator.expect ~expression:"to.have.count" ~expected_number:5. ~is_not:false ~timeout:100.
                    (Page.locator ~selector:"#one" page) in
                check "not matched" (not result.matches && result.timed_out = Some true);
                check "actual number" ((Option.get result.received).n = Some 1.);
                check "value parser control" (Value.parse_serialized_value (Option.get result.received) = `Float 1.));
            test "selector Attached/Detached distinct from actionability Enabled" (fun () ->
                let body = Option.get (Page.query_selector ~selector:"body" page) in
                Fun.protect ~finally:(fun () -> ElementHandle.dispose body) (fun () ->
                    let button = Option.get (ElementHandle.wait_for_selector ~selector:"#button" ~state:`Attached ~timeout:1000. body) in
                    Fun.protect ~finally:(fun () -> ElementHandle.dispose button) (fun () ->
                        ElementHandle.wait_for_element_state ~state:`Enabled ~timeout:1000. button);
                    ignore (Page.evaluate ~expression:"document.querySelector('#button').remove()" page);
                    check "detached result" (ElementHandle.wait_for_selector ~selector:"#button" ~state:`Detached ~timeout:1000. body = None)));
            test "nonempty JS coverage with typed function ranges" (fun () ->
                Page.start_js_coverage ~report_anonymous_scripts:true page;
                ignore (Page.evaluate ~expression:"(function covered(){return 42})()" page);
                let entries = Page.stop_js_coverage page in
                check "nonempty JS" (Array.length entries > 0);
                check "JS ranges" (Array.exists (fun (entry : Page.StopJSCoverageResult_Entries.t) ->
                    Array.exists (fun (fn : Page.StopJSCoverageResult_Entries_Functions.t) ->
                        Array.exists (fun (range : Page.StopJSCoverageResult_Entries_Functions_Ranges.t) ->
                            range.end_offset > range.start_offset && range.count > 0) fn.ranges) entry.functions) entries));
            test "nonempty external-stylesheet CSS coverage with CSS ranges" (fun () ->
                Page.start_css_coverage page;
                ignore (Page.goto ~url:(base ^ "/styled") ~timeout:3000. page);
                let entries = Page.stop_css_coverage page in
                check "external CSS" (Array.exists (fun (entry : Page.StopCSSCoverageResult_Entries.t) ->
                    entry.url = base ^ "/style.css" &&
                    Array.exists (fun (range : Page.StopCSSCoverageResult_Entries_Ranges.t) -> range.end_ > range.start) entry.ranges) entries));
            test "raw in-memory file upload exact edge bytes" (fun () ->
                let payloads = List.mapi (fun i buffer -> Frame.SetInputFilesParams_Payloads.{
                    name=Printf.sprintf "%d.bin" i; mime_type=Some "application/octet-stream"; buffer}) edges |> Array.of_list in
                Page.set_input_files ~selector:"#file" ~payloads ~timeout:2000. page;
                let result = Page.evaluate ~expression:"async()=>Promise.all(Array.from(document.querySelector('#file').files, async f=>Array.from(new Uint8Array(await f.arrayBuffer()))))" page in
                (* SerializedValue numbers are floats in the existing convenience parser. *)
                let expected = `List (List.map (fun bytes -> `List (List.init (String.length bytes) (fun i -> `Float (float_of_int (Char.code bytes.[i]))))) edges) in
                check "all uploaded bytes" (result = expected));
            let request = BrowserContext.request_context context in
            let fetch_body ?post_data ?multipart_data path =
                let response = APIRequestContext.fetch ~url:(base ^ path) ?post_data ?multipart_data
                    ~method_:"POST" ~timeout:3000. request in
                Fun.protect ~finally:(fun () -> APIRequestContext.dispose_api_response ~fetch_uid:response.fetch_uid request)
                    (fun () -> check "HTTP status" (response.status = 200);
                        Option.get (APIRequestContext.fetch_response_body ~fetch_uid:response.fetch_uid request)) in
            test "direct request/response binary controls exact edge bytes" (fun () ->
                List.iter (fun bytes ->
                    let echo = fetch_body ~post_data:bytes "/echo" |> Yojson.Safe.from_string in
                    check "POST bytes" (member "bodyBase64" echo = `String (Base64.encode_exn bytes))) edges;
                check "fetchResponseBody bytes" (fetch_body "/bytes" = "\000\255\128\001\r\n");
                let response = ref None in
                BrowserContext.on_response context (fun event ->
                    let conn = Internal.connection event.response in
                    let raw = (Hashtbl.find conn.objects (Internal.guid event.response)).initializer_ in
                    if member "url" raw = `String (base ^ "/bytes") then response := Some event.response);
                BrowserContext.update_subscription ~event:`Response ~enabled:true context;
                ignore (Page.evaluate ~expression:"async () => (await fetch('/bytes')).arrayBuffer()" page);
                await clock (fun () -> !response <> None);
                check "Response.body direct" (Response.body (Option.get !response) = "\000\255\128\001\r\n");
                BrowserContext.update_subscription ~event:`Response ~enabled:false context);
            test "multipart upload exact edge bytes" (fun () ->
                List.iter (fun bytes ->
                    let multipart_data = [|FormField.Wrap.{name="file";value=None;file=Some
                        FormField.File.{name="raw.bin";mime_type=Some "application/octet-stream";buffer=bytes}}|] in
                    let echo = fetch_body ~multipart_data "/echo" |> Yojson.Safe.from_string in
                    check "multipart file bytes" (member "fileBase64" echo = `String (Base64.encode_exn bytes))) edges);
            test "real request initializer optional binary decodes once" (fun () ->
                let requests = ref [] in
                BrowserContext.on_request context (fun event -> requests := event.request :: !requests);
                BrowserContext.update_subscription ~event:`Request ~enabled:true context;
                let bytes = "\000\255\128Hello" in
                ignore (Page.evaluate ~expression:"async bytes => (await fetch('/echo', {method:'POST', body:new Uint8Array(bytes)})).json()" ~arg:(json_bytes bytes) page);
                await clock (fun () -> !requests <> []);
                let request = List.hd !requests in
                let conn = Internal.connection request in
                let raw = (Hashtbl.find conn.objects (Internal.guid request)).initializer_ in
                (* Existing handle-decoding scope, not a change to G05 or raw Connection storage. *)
                let init = Eio.Fiber.with_binding Connection.current_connection_key conn (fun () -> get (Request.Initializer.of_yojson raw)) in
                check "wire stores Base64" (member "postData" raw = `String (Base64.encode_exn bytes));
                check "typed initializer raw bytes" (init.post_data = Some bytes && init.method_ = "POST");
                BrowserContext.update_subscription ~event:`Request ~enabled:false context);
            test "direct PNG/PDF and nested screenshot result signatures" (fun () ->
                check "direct PNG" (png (Page.screenshot page));
                check "direct PDF" (String.starts_with ~prefix:"%PDF-" (Page.pdf page));
                let result = Page.expect_screenshot ~is_not:false ~timeout:3000. page in
                check "nested PNG" (png (Option.get result.actual)));
            test "screencast event contains raw JPEG bytes" (fun () ->
                let frame = ref None in
                Page.on_screencast_frame page (fun event -> frame := Some event.data);
                ignore (Page.screencast_start ~send_frames:true page);
                Fun.protect ~finally:(fun () -> Page.screencast_stop page) (fun () ->
                    ignore (Page.evaluate ~expression:"document.body.style.background='green'" page);
                    await clock (fun () -> !frame <> None);
                    check "event JPEG" (jpeg (Option.get !frame))));
            test "special-value wire literals incoming and outgoing live" (fun () ->
                List.iter (fun (expression,tag,literal) ->
                    let value = Page.evaluate_expression_raw ~expression ~arg:(Value.build_serialized_argument `Null) page in
                    check "incoming tag" (value.v = Some tag);
                    check "exact re-encode" (member "v" (SerializedValue.to_yojson value) = `String literal);
                    let arg : SerializedArgument.t = {value; handles=[||]} in
                    let result = Page.evaluate_expression_raw ~expression:("x => Object.is(x, " ^ expression ^ ")") ~is_function:true ~arg page in
                    check "outgoing exact wire" (result.b = Some true)
                ) ["NaN",`Nan,"NaN";"Infinity",`Infinity,"Infinity";"-Infinity",`Minus_infinity,"-Infinity";"-0",`Minus_zero,"-0"];
                List.iter (fun expression -> check "convenience incoming" (Page.evaluate ~expression page = `String expression)) ["NaN";"Infinity";"-Infinity"];
                match Page.evaluate ~expression:"-0" page with
                | `Float x -> check "negative zero" (x = 0. && 1. /. x = neg_infinity)
                | _ -> failwith "negative zero response");
            Browser.close browser))

let () =
    Eio_main.run (fun env ->
        Eio.Time.with_timeout_exn (Eio.Stdenv.clock env) 30. (fun () -> run env))
