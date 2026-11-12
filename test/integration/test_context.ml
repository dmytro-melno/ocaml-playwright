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
    let state = BrowserContext.storage_state context in
    Yojson.Safe.to_file file state;
    let restored_from ?(expression = "localStorage.getItem('theme') + '/' + document.cookie") make =
        let context = make t.browser in
        let page = BrowserContext.new_page context in
        visit t page;
        let result = eval_string expression page in
        BrowserContext.close context;
        result
    in
    Alcotest.(check string) "restored from the value" "dark/session=abc" (restored_from (Browser.new_context ~storage_state:state));
    Alcotest.(check string) "restored from the file" "dark/session=abc" (restored_from (Browser.new_context ~storage_state:(Yojson.Safe.from_file file)));
    Alcotest.(check string) "a fresh context has neither" "null/" (restored_from Browser.new_context);
    Alcotest.(check string) "set in a context that exists already" "dark/session=abc"
        (restored_from (fun browser ->
             let context = Browser.new_context browser in
             BrowserContext.set_storage_state state context;
             context));
    (* The files that an origin keeps are part of the state on request. *)
    ignore
        (Page.evaluate
           {|async () => {
               const directory = await navigator.storage.getDirectory();
               const writable = await (await directory.getFileHandle('note.txt', { create: true })).createWritable();
               await writable.write('remember');
               await writable.close();
           }|}
           page);
    let note =
        {|async () => {
            const directory = await navigator.storage.getDirectory();
            try { return await (await (await directory.getFileHandle('note.txt')).getFile()).text(); } catch (error) { return error.name; }
        }|}
    in
    Alcotest.(check string) "files are left out" "NotFoundError" (restored_from ~expression:note (Browser.new_context ~storage_state:(BrowserContext.storage_state context)));
    Alcotest.(check string) "unless asked for" "remember"
        (restored_from ~expression:note (Browser.new_context ~storage_state:(BrowserContext.storage_state ~indexed_db:true ~opfs:true ~credentials:true context)))

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

(* What the pages of a context do is also told to the listeners of the context. *)
let test_page_events_of_context t () =
    Server.route t.server "/attachment" (fun _ -> Server.respond ~headers:[ "content-disposition", "attachment; filename=a.txt" ] "attached");
    let context = Browser.new_context t.browser in
    let log = ref [] in
    let on event describe = BrowserContext.on event (fun subject -> log := describe subject :: !log) context |> ignore in
    let of_frame what frame = Printf.sprintf "%s %s" what (if Option.is_none (Frame.parent_frame frame) then "the main frame" else "a child frame") in
    let of_page what page = Printf.sprintf "%s %s" what (Filename.basename (Page.url page)) in
    on BrowserContext.Frame_attached (of_frame "attached");
    on BrowserContext.Frame_detached (of_frame "detached");
    on BrowserContext.Frame_navigated (of_frame "navigated");
    on BrowserContext.Page_load (of_page "loaded");
    on BrowserContext.Page_close (of_page "closed");
    on BrowserContext.Dialog_closed (fun dialog -> "answered " ^ Dialog.message dialog);
    on BrowserContext.Download (fun download -> "downloaded " ^ Download.suggested_filename download);
    let page = BrowserContext.new_page context in
    visit t page;
    let seen () = List.sort compare !log in
    let expect what events =
        eventually t what (fun () -> List.length !log >= List.length events);
        Alcotest.(check (list string)) what (List.sort compare events) (seen ());
        log := []
    in
    expect "a navigation" [ "navigated the main frame"; "loaded blank" ];
    ignore (Page.evaluate "() => { const frame = document.createElement('iframe'); frame.srcdoc = 'inner'; document.body.append(frame); }" page);
    Expect.to_have_text "inner" (Page.frame_locator "iframe" page |> FrameLocator.locator "body");
    expect "a frame of its own" [ "attached a child frame"; "navigated a child frame" ];
    ignore (Page.evaluate "document.querySelector('iframe').remove()" page);
    expect "which goes away" [ "detached a child frame" ];
    Page.on Page.Dialog Dialog.accept page |> ignore;
    ignore (Page.evaluate "alert('Read me')" page);
    expect "a dialog" [ "answered Read me" ];
    Page.set_content {|<a href="/attachment">download</a>|} page;
    expect "new content" [ "loaded blank" ];
    let download = Page.expect_download (fun () -> Page.click "a" page) page in
    Download.delete download;
    expect "a download" [ "downloaded a.txt" ];
    Page.close page;
    expect "the end of the page" [ "closed blank" ];
    BrowserContext.close context

let test_browser t () =
    Alcotest.(check string) "name" "chromium" (Browser.name t.browser);
    Alcotest.(check bool) "version" true (String.length (Browser.version t.browser) > 3 && Browser.is_connected t.browser);
    Alcotest.(check bool) "type" true (BrowserType.equal (Browser.browser_type t.browser) (chromium t.pw) && BrowserType.name (chromium t.pw) = "chromium");
    let before = List.length (Browser.contexts t.browser) in
    let created = ref [] in
    let listening = Browser.on_context (fun context -> created := context :: !created) t.browser in
    let page = Browser.new_page ~viewport:(300, 200) t.browser in
    eventually t "the context is announced" (fun () -> List.equal BrowserContext.equal !created [ Page.context page ]);
    Disposable.dispose listening;
    Alcotest.(check int) "a page with a context of its own" (before + 1) (List.length (Browser.contexts t.browser));
    Alcotest.(check (option (pair int int))) "takes context options" (Some (300, 200)) (Page.viewport_size page);
    Page.close page;
    Alcotest.(check int) "which goes away with the page" before (List.length (Browser.contexts t.browser));
    Alcotest.(check bool) "driver version" true (String.length Playwright.version >= 5 && Playwright.version.[1] = '.')

let test_tracing t page =
    let tracing = BrowserContext.tracing (Page.context page) in
    Tracing.start ~screenshots:true ~snapshots:true ~title:"A trace" tracing;
    visit t page;
    Tracing.group ~location:__POS__ "interaction" tracing;
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
        case t "events of its pages" (test_page_events_of_context t);
        case t "browser" (test_browser t) ];
      "recording", [ page_case t "tracing" (test_tracing t); case t "video" (test_video t) ] ]
