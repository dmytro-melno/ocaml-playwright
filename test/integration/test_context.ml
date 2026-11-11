(* Browser contexts: state, emulation and recordings. *)

open Playwright
open Harness

let visit t page =
    Server.page t.server "/blank" "<title>Blank</title>";
    ignore (Page.goto (Server.url t.server "/blank") page)

let test_cookies t page =
    visit t page;
    let context = Page.context page in
    let origin = Server.origin t.server in
    let expires = Float.round (Unix.time ()) +. 86_400. in
    BrowserContext.add_cookies
        [ Cookie.make ~url:origin "plain" ~value:"1";
          Cookie.make ~domain:"127.0.0.1" ~path:"/private" ~http_only:true ~same_site:`Strict ~expires "guarded" ~value:"2" ]
        context;
    Alcotest.(check string) "visible to the page" "plain=1" (eval_string "document.cookie" page);
    let cookies = BrowserContext.cookies context |> List.sort compare in
    Alcotest.(check (list string)) "all cookies" [ "guarded"; "plain" ] (List.map (fun (c : Cookie.t) -> c.name) cookies);
    let guarded = List.hd cookies in
    Alcotest.(check (list string)) "attributes" [ "2"; "127.0.0.1"; "/private"; "true"; "false"; "Strict"; Printf.sprintf "%.0f" expires ]
        [ guarded.value; guarded.domain; guarded.path; string_of_bool guarded.http_only; string_of_bool guarded.secure;
          (match guarded.same_site with `Strict -> "Strict" | `Lax -> "Lax" | `None -> "None"); Printf.sprintf "%.0f" guarded.expires ];
    Alcotest.(check (list string)) "for a URL" [ "plain" ] (List.map (fun (c : Cookie.t) -> c.name) (BrowserContext.cookies ~urls:[ origin ^ "/other" ] context));
    (* A cookie read from one context can be set in another. *)
    let other = Browser.new_context t.browser in
    Alcotest.(check int) "contexts are isolated" 0 (List.length (BrowserContext.cookies other));
    BrowserContext.add_cookies (List.map Cookie.to_init cookies) other;
    Alcotest.(check int) "copied" 2 (List.length (BrowserContext.cookies other));
    BrowserContext.close other;
    BrowserContext.clear_cookies ~name:"plain" context;
    Alcotest.(check (list string)) "cleared by name" [ "guarded" ] (List.map (fun (c : Cookie.t) -> c.name) (BrowserContext.cookies context));
    BrowserContext.clear_cookies context;
    Alcotest.(check int) "cleared" 0 (List.length (BrowserContext.cookies context));
    check_failure "a cookie needs a URL or a domain" (fun () -> BrowserContext.add_cookies [ Cookie.make "orphan" ~value:"1" ] context)

let test_storage_state t page =
    visit t page;
    let context = Page.context page in
    BrowserContext.add_cookies [ Cookie.make ~url:(Server.origin t.server) "session" ~value:"abc" ] context;
    ignore (Page.evaluate "localStorage.setItem('theme', 'dark')" page);
    let file = scratch_file t "state.json" in
    let state = BrowserContext.storage_state ~path:file context in
    Alcotest.check json "also written to the file" state (Yojson.Safe.from_string (read_file file));
    let restored_from make =
        let context = make t.browser in
        let page = BrowserContext.new_page context in
        visit t page;
        let result = eval_string "localStorage.getItem('theme') + '/' + document.cookie" page in
        BrowserContext.close context;
        result
    in
    Alcotest.(check string) "restored from the value" "dark/session=abc" (restored_from (Browser.new_context ~storage_state:state));
    Alcotest.(check string) "restored from the file" "dark/session=abc" (restored_from (Browser.new_context ~storage_state_path:file));
    Alcotest.(check string) "a fresh context has neither" "null/" (restored_from Browser.new_context);
    Alcotest.(check string) "set in a context that exists already" "dark/session=abc"
        (restored_from (fun browser ->
             let context = Browser.new_context browser in
             BrowserContext.set_storage_state state context;
             context))

let test_web_storage t page =
    visit t page;
    let local = Page.local_storage page and session = Page.session_storage page in
    WebStorage.set_item "a" ~value:"1" local;
    WebStorage.set_item "b" ~value:"2" local;
    WebStorage.set_item "s" ~value:"x" session;
    Alcotest.(check (list (pair string string))) "items" [ "a", "1"; "b", "2" ] (List.sort compare (WebStorage.items local));
    Alcotest.(check (option string)) "an item" (Some "1") (WebStorage.get_item "a" local);
    Alcotest.(check (option string)) "no such item" None (WebStorage.get_item "s" local);
    Alcotest.(check string) "the page sees them" "1/x" (eval_string "localStorage.getItem('a') + '/' + sessionStorage.getItem('s')" page);
    ignore (Page.evaluate "localStorage.setItem('c', '3')" page);
    WebStorage.remove_item "a" local;
    Alcotest.(check (list (pair string string))) "after a removal and a change by the page" [ "b", "2"; "c", "3" ] (List.sort compare (WebStorage.items local));
    WebStorage.clear local;
    Alcotest.(check int) "cleared" 0 (List.length (WebStorage.items local));
    Alcotest.(check (list (pair string string))) "the session storage is separate" [ "s", "x" ] (WebStorage.items session)

let test_emulation t () =
    let context =
        Browser.new_context ~viewport:(400, 300) ~device_scale_factor:2. ~locale:"de-DE" ~timezone_id:"Asia/Tokyo" ~color_scheme:`Dark
            ~has_touch:true ~user_agent:"Emulated/1.0" t.browser
    in
    let page = BrowserContext.new_page context in
    visit t page;
    let check what expected expression = Alcotest.(check string) what expected (Page.evaluate ("String(" ^ expression ^ ")") page |> Js.to_string) in
    check "viewport" "400x300" "innerWidth + 'x' + innerHeight";
    Alcotest.(check (option (pair int int))) "viewport size" (Some (400, 300)) (Page.viewport_size page);
    check "scale factor" "2" "devicePixelRatio";
    check "locale" "de-DE" "navigator.language";
    check "number format follows the locale" "1.234,5" "(1234.5).toLocaleString()";
    check "time zone" "Asia/Tokyo" "Intl.DateTimeFormat().resolvedOptions().timeZone";
    check "colour scheme" "true" "matchMedia('(prefers-color-scheme: dark)').matches";
    check "touch" "true" "'ontouchstart' in window";
    check "user agent" "Emulated/1.0" "navigator.userAgent";
    Page.set_viewport_size (640, 480) page;
    check "resized" "640x480" "innerWidth + 'x' + innerHeight";
    Page.emulate_media ~media:`Print ~color_scheme:`Light page;
    check "print media" "true" "matchMedia('print').matches";
    check "light scheme" "false" "matchMedia('(prefers-color-scheme: dark)').matches";
    BrowserContext.close context;
    (* A device descriptor sets several of these at once; explicit options win. *)
    let device = Playwright.device "iPhone 13" t.pw |> Option.get in
    Alcotest.(check bool) "descriptor" true (Device.is_mobile device && Device.has_touch device && Device.default_browser_type device = `Webkit);
    let context = Browser.new_context ~device ~locale:"fr-FR" t.browser in
    let page = BrowserContext.new_page context in
    visit t page;
    let width, height = Device.viewport device in
    Alcotest.(check (option (pair int int))) "device viewport" (Some (width, height)) (Page.viewport_size page);
    Alcotest.(check string) "device user agent" (Device.user_agent device) (eval_string "navigator.userAgent" page);
    Alcotest.(check string) "explicit option" "fr-FR" (eval_string "navigator.language" page);
    BrowserContext.close context;
    Alcotest.(check bool) "no such device" true (Option.is_none (Playwright.device "Nokia 3310" t.pw));
    Alcotest.(check bool) "many devices" true (List.length (Playwright.devices t.pw) > 50)

let test_geolocation_and_permissions t () =
    let context =
        Browser.new_context ~geolocation:(Geolocation.make ~latitude:52.52 ~longitude:13.405 ()) ~permissions:[ "geolocation" ] t.browser
    in
    let page = BrowserContext.new_page context in
    visit t page;
    let position () =
        Page.evaluate "new Promise((resolve, reject) => navigator.geolocation.getCurrentPosition(p => resolve([p.coords.latitude, p.coords.longitude]), e => reject(new Error(e.message))))" page
        |> Js.to_list Js.to_float
    in
    Alcotest.(check (list (float 1e-6))) "position" [ 52.52; 13.405 ] (position ());
    BrowserContext.set_geolocation (Some (Geolocation.make ~latitude:48.8566 ~longitude:2.3522 ())) context;
    Alcotest.(check (list (float 1e-6))) "moved" [ 48.8566; 2.3522 ] (position ());
    let permission () = eval_string "navigator.permissions.query({ name: 'geolocation' }).then(status => status.state)" page in
    Alcotest.(check string) "granted" "granted" (permission ());
    BrowserContext.clear_permissions context;
    Alcotest.(check bool) "no longer granted" true (permission () <> "granted");
    BrowserContext.grant_permissions ~origin:(Server.origin t.server) [ "geolocation" ] context;
    Alcotest.(check string) "granted to the origin" "granted" (permission ());
    BrowserContext.close context

let test_clock t page =
    let context = Page.context page in
    let start = 1_700_000_000_000. in
    Clock.install ~time:start context;
    visit t page;
    Clock.pause_at (start +. 1000.) context;
    Alcotest.(check (float 0.)) "paused at a point in time" (start +. 1000.) (Page.evaluate "Date.now()" page |> Js.to_float);
    ignore (Page.evaluate "() => { window.fired = []; setTimeout(() => window.fired.push('timeout'), 60000); setInterval(() => window.fired.push('tick'), 25000) }" page);
    Clock.run_for 60_000. context;
    Alcotest.(check (list string)) "timers fire in order while the clock runs" [ "tick"; "tick"; "timeout" ] (Page.evaluate "window.fired" page |> Js.to_list Js.to_string);
    Alcotest.(check (float 0.)) "time advanced" (start +. 61_000.) (Page.evaluate "Date.now()" page |> Js.to_float);
    Clock.fast_forward 3_600_000. context;
    Alcotest.(check int) "a jump fires each due timer once" 4 (eval_int "window.fired.length" page);
    Clock.set_fixed_time 86_400_000. context;
    Alcotest.(check string) "fixed time" "1970-01-02T00:00:00.000Z" (eval_string "new Date().toISOString()" page)

let test_context_scripting t () =
    let context = Browser.new_context t.browser in
    BrowserContext.expose_function "double" (function [ n ] -> Js.float (2. *. Js.to_float n) | _ -> Js.undefined) context |> ignore;
    BrowserContext.expose_binding "origin" (fun source _ -> Js.string (if BrowserContext.pages source.context = [] then "?" else Page.url source.page)) context |> ignore;
    let created = ref [] in
    BrowserContext.on BrowserContext.Page (fun page -> created := page :: !created) context |> ignore;
    let first = BrowserContext.new_page context and second = BrowserContext.new_page context in
    Alcotest.(check bool) "page events" true (List.equal Page.equal (List.rev !created) [ first; second ]);
    visit t second;
    Alcotest.check js "in the first page" (Js.Number 4.) (Page.evaluate "window.double(2)" first);
    Alcotest.check js "in the second page" (Js.Number 42.) (Page.evaluate "window.double(21)" second);
    Alcotest.check js "the caller is known" (Js.String (Server.url t.server "/blank")) (Page.evaluate "window.origin()" second);
    let request = BrowserContext.expect_event BrowserContext.Request (fun () -> ignore (Page.evaluate "fetch('/blank')" second)) context in
    Alcotest.(check bool) "requests of all pages" true (Frame.equal (Request.frame request) (Page.main_frame second));
    BrowserContext.set_default_navigation_timeout 150. context;
    Server.route t.server "/slow" (fun _ ->
        sleep t 1.;
        Server.html "late");
    check_failure "navigation timeout of the context" ~kind:Timeout ~message:"150ms" (fun () -> Page.goto (Server.url t.server "/slow") first);
    Alcotest.(check bool) "its browser" true (Option.equal Browser.equal (BrowserContext.browser context) (Some t.browser));
    BrowserContext.close context

let test_browser t () =
    Alcotest.(check string) "name" "chromium" (Browser.name t.browser);
    Alcotest.(check bool) "version" true (String.length (Browser.version t.browser) > 3 && Browser.is_connected t.browser);
    Alcotest.(check bool) "type" true (BrowserType.equal (Browser.browser_type t.browser) (chromium t.pw) && BrowserType.name (chromium t.pw) = "chromium");
    let before = List.length (Browser.contexts t.browser) in
    let page = Browser.new_page ~viewport:(300, 200) t.browser in
    Alcotest.(check int) "a page with a context of its own" (before + 1) (List.length (Browser.contexts t.browser));
    Alcotest.(check (option (pair int int))) "takes context options" (Some (300, 200)) (Page.viewport_size page);
    Page.close page;
    Alcotest.(check int) "which goes away with the page" before (List.length (Browser.contexts t.browser));
    Alcotest.(check bool) "driver version" true (String.length Playwright.version >= 5 && Playwright.version.[1] = '.')

let test_tracing t page =
    let tracing = BrowserContext.tracing (Page.context page) in
    Tracing.start ~screenshots:true ~snapshots:true ~title:"A trace" tracing;
    visit t page;
    Tracing.group "interaction" tracing;
    Page.set_content "<button>Press</button>" page;
    Page.get_by_role `Button page |> Locator.click;
    Tracing.group_end tracing;
    let first = scratch_file t "first.zip" in
    Tracing.stop_chunk ~path:first tracing;
    Tracing.start_chunk tracing;
    ignore (Page.evaluate "1 + 1" page);
    let second = scratch_file t "nested/second.zip" in
    Tracing.stop ~path:second tracing;
    let is_zip path = String.sub (read_file path) 0 2 = "PK" in
    Alcotest.(check bool) "archives" true (is_zip first && is_zip second);
    Alcotest.(check bool) "the first part holds the page and its screenshots" true ((Unix.stat first).st_size > 2000)

let test_har_recording t () =
    Server.page t.server "/blank" "<title>Blank</title>";
    let har = scratch_file t "network.har" in
    let context = Browser.new_context ~record_har_path:har ~record_har_url_filter:"**/blank" t.browser in
    let page = BrowserContext.new_page context in
    ignore (Page.goto (Server.url t.server "/blank") page);
    ignore (Page.evaluate "fetch('/filtered-out').catch(() => {})" page);
    BrowserContext.close context;
    let entries = Yojson.Safe.from_string (read_file har) |> Yojson.Safe.Util.member "log" |> Yojson.Safe.Util.member "entries" |> Yojson.Safe.Util.to_list in
    Alcotest.(check (list string)) "recorded requests" [ Server.url t.server "/blank" ]
        (List.map (fun entry -> Yojson.Safe.Util.(member "request" entry |> member "url" |> to_string)) entries)

(* A page is recorded into a HAR file, and then served from that file alone. *)
let test_har_replay t () =
    let visits = ref 0 in
    Server.route t.server "/recorded" (fun _ ->
        incr visits;
        Server.html ~headers:[ "set-cookie", "a=1"; "set-cookie", "b=2" ] (Printf.sprintf "<title>Visit %d</title><script src='/recorded.js'></script>" !visits));
    Server.route t.server "/recorded.js" (fun _ -> Server.respond ~content_type:"text/javascript" "window.fromScript = 'original'");
    Server.page t.server "/live" "<title>Live</title>";
    let har = scratch_file t "replay.har" in
    let recording = Browser.new_context t.browser in
    BrowserContext.route_from_har ~update:true ~url:"**/recorded*" har recording;
    let page = BrowserContext.new_page recording in
    ignore (Page.goto (Server.url t.server "/recorded") page);
    ignore (Page.goto (Server.url t.server "/live") page);
    BrowserContext.close recording;
    Alcotest.(check bool) "written when the context closes" true (Sys.file_exists har);
    let visits_recorded = !visits in
    (* For the whole context: what is not in the file is aborted. *)
    let context = Browser.new_context t.browser in
    BrowserContext.route_from_har har context;
    let page = BrowserContext.new_page context in
    ignore (Page.goto (Server.url t.server "/recorded") page);
    Alcotest.(check string) "the page comes from the file" "Visit 1" (Page.title page);
    Alcotest.(check string) "and so do its resources" "original" (eval_string "window.fromScript" page);
    Alcotest.(check int) "the server was not asked" visits_recorded !visits;
    Alcotest.(check (list string)) "every Set-Cookie header was replayed" [ "a"; "b" ]
        (BrowserContext.cookies context |> List.map (fun (c : Cookie.t) -> c.name) |> List.sort compare);
    check_failure "anything else is aborted" (fun () -> Page.goto (Server.url t.server "/live") page);
    BrowserContext.close context;
    (* For one page, with the network as the fallback. *)
    let context = Browser.new_context t.browser in
    let page = BrowserContext.new_page context in
    Page.route_from_har ~not_found:`Fallback har page;
    ignore (Page.goto (Server.url t.server "/recorded") page);
    Alcotest.(check string) "from the file" "Visit 1" (Page.title page);
    ignore (Page.goto (Server.url t.server "/live") page);
    Alcotest.(check string) "from the network" "Live" (Page.title page);
    let other = BrowserContext.new_page context in
    ignore (Page.goto (Server.url t.server "/recorded") other);
    Alcotest.(check string) "other pages are not affected" (Printf.sprintf "Visit %d" (visits_recorded + 1)) (Page.title other);
    BrowserContext.close context;
    let context = Browser.new_context t.browser in
    check_failure "a file that does not exist" (fun () -> BrowserContext.route_from_har (scratch_file t "missing.har") context);
    BrowserContext.close context

let test_video t () =
    let dir = scratch_file t "videos" in
    let context = Browser.new_context ~record_video_dir:dir ~record_video_size:(320, 240) t.browser in
    match BrowserContext.new_page context with
    | exception Playwright.Error error when contains ~sub:"ffmpeg" error.message ->
        (* Recording needs the ffmpeg build that comes with Playwright's own browsers. *)
        BrowserContext.close context;
        Alcotest.skip ()
    | page ->
        Page.set_content "<h1>Recorded</h1>" page;
        sleep t 0.3;
        let video = Page.video page |> Option.get in
        BrowserContext.close context;
        let path = Video.path video in
        Alcotest.(check bool) "recorded into the directory" true (Filename.dirname path = dir && (Unix.stat path).st_size > 0);
        let copy = scratch_file t "copy.webm" in
        Video.save_as copy video;
        Alcotest.(check bool) "copied" true ((Unix.stat copy).st_size > 0)

let tests t =
    [ "context",
      [ page_case t "cookies" (test_cookies t);
        page_case t "storage state" (test_storage_state t);
        page_case t "web storage" (test_web_storage t);
        case t "emulation and devices" (test_emulation t);
        case t "geolocation and permissions" (test_geolocation_and_permissions t);
        page_case t "clock" (test_clock t);
        case t "functions, events and timeouts" (test_context_scripting t);
        case t "browser" (test_browser t) ];
      "recording", [ page_case t "tracing" (test_tracing t); case t "HAR" (test_har_recording t); case t "HAR replay" (test_har_replay t);
        case t "video" (test_video t) ] ]
