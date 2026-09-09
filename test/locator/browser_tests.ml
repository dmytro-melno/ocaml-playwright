open Playwright
open Eio.Std

let check name condition = if not condition then failwith ("ASSERTION FAILED: " ^ name)
let test name f = f (); Printf.printf "PASS %s\n%!" name
let contains haystack needle =
  let n = String.length needle in
  let rec loop i = i + n <= String.length haystack &&
    (String.sub haystack i n = needle || loop (i + 1)) in
  loop 0
let error needle f =
  match f () with
  | _ -> failwith ("expected Playwright.Error containing " ^ needle)
  | exception Error message -> check ("error must contain " ^ needle ^ ": " ^ message) (contains message needle)
let incompatible f =
  match f () with
  | _ -> failwith "expected frame/session rejection"
  | exception Invalid_argument message -> check "frame/session diagnostic" (contains message "same frame and session")
let bounded env seconds f = Eio.Time.with_timeout_exn (Eio.Stdenv.clock env) seconds f
let until env f = bounded env 4. (fun () -> while not (f ()) do Eio_unix.sleep 0.005 done)
let conn = Internal.connection
let handles page = Hashtbl.fold (fun _ o n ->
  if o.Connection.obj_type = "ElementHandle" then n + 1 else n) (conn page).Connection.objects 0
let no_pending page = check "no pending requests" (Hashtbl.length (conn page).Connection.callbacks = 0)
let loc page selector = Page.locator ~selector page
let eval page expression = Page.evaluate ~expression page
let special = "Quote \" slash \\ newline\n tab\t carriage\r Ω雪"
let fixture page =
  let expression = In_channel.with_open_text "fixture.js" In_channel.input_all in
  ignore (Page.evaluate ~expression ~is_function:true page)
let frame page =
  let handle = Option.get (Locator.element_handle ~timeout:1000. (loc page "iframe")) in
  Fun.protect ~finally:(fun () -> ElementHandle.dispose handle) (fun () ->
    Option.get (ElementHandle.content_frame handle))
let launch pw =
  BrowserType.launch ~headless:true ~executable_path:"/usr/bin/chromium" (Playwright.chromium pw)
let with_page env f =
  Switch.run (fun sw ->
    let pw = create ~env ~sw () in
    Fun.protect ~finally:(fun () -> destroy pw) (fun () ->
      let browser = launch pw in
      let context = Browser.new_context ~has_touch:true browser in
      let page = BrowserContext.new_page context in
      fixture page;
      f sw pw browser context page;
      if Connection.closed_reason (conn browser) = None then Browser.close browser))

let strict env =
  with_page env (fun _ _ _ _ page ->
    let button = loc page "#buttons button" and input = loc page ".text"
    and checkbox = loc page ".check" and select = loc page "select" and file = loc page ".file" in
    let timeout = 700. in
    let unit_result f () = ignore (f ()) in
    let probes = [
      "click", (fun () -> Locator.click ~timeout button);
      "fill", (fun () -> Locator.fill ~timeout ~value:"wrong" input);
      "press", (fun () -> Locator.press ~timeout ~key:"A" input);
      "get_attribute", unit_result (fun () -> Locator.get_attribute ~timeout ~name:"id" button);
      "text_content", unit_result (fun () -> Locator.text_content ~timeout button);
      "inner_text", unit_result (fun () -> Locator.inner_text ~timeout button);
      "inner_html", unit_result (fun () -> Locator.inner_html ~timeout button);
      "check", (fun () -> Locator.check ~timeout checkbox);
      "uncheck", (fun () -> Locator.uncheck ~timeout checkbox);
      "dblclick", (fun () -> Locator.dblclick ~timeout button);
      "blur", (fun () -> Locator.blur ~timeout input);
      "focus", (fun () -> Locator.focus ~timeout input);
      "hover", (fun () -> Locator.hover ~timeout button);
      "input_value", unit_result (fun () -> Locator.input_value ~timeout input);
      "select_option", unit_result (fun () -> Locator.select_option ~timeout ~options:[||] select);
      "set_input_files", (fun () -> Locator.set_input_files ~timeout ~local_paths:[||] file);
      "tap", (fun () -> Locator.tap ~timeout button);
      "type", (fun () -> Locator.type_ ~timeout ~text:"wrong" input);
      "dispatch_event", (fun () -> Locator.dispatch_event ~timeout ~type_:"click" button);
      "is_checked", unit_result (fun () -> Locator.is_checked ~timeout checkbox);
      "is_disabled", unit_result (fun () -> Locator.is_disabled ~timeout input);
      "is_enabled", unit_result (fun () -> Locator.is_enabled ~timeout input);
      "is_hidden", unit_result (fun () -> Locator.is_hidden button);
      "is_visible", unit_result (fun () -> Locator.is_visible button);
      "is_editable", unit_result (fun () -> Locator.is_editable ~timeout input);
      "drag source", (fun () -> Locator.drag_to ~timeout ~target:(Locator.first button) button);
      "drag target", (fun () -> Locator.drag_to ~timeout ~target:button (Locator.first button));
      "clear", (fun () -> Locator.clear ~timeout input);
      "wait attached", (fun () -> Locator.wait_for ~timeout ~state:`Attached button);
      "wait visible", (fun () -> Locator.wait_for ~timeout ~state:`Visible button);
      "wait hidden", (fun () -> Locator.wait_for ~timeout ~state:`Hidden button);
      "wait detached", (fun () -> Locator.wait_for ~timeout ~state:`Detached button);
      "evaluate", unit_result (fun () -> Locator.evaluate ~timeout ~expression:"el => el.id" button);
      "element_handle", unit_result (fun () -> Locator.element_handle ~timeout button);
      "bounding_box", unit_result (fun () -> Locator.bounding_box ~timeout button);
      "scroll", (fun () -> Locator.scroll_into_view_if_needed ~timeout button);
      "screenshot", unit_result (fun () -> Locator.screenshot ~timeout button);
    ] in
    let baseline = handles page in
    List.iter (fun (name, f) -> test ("strict " ^ name) (fun () -> error "strict mode violation" f)) probes;
    test "raw expect result reports ambiguity, not a first-element success" (fun () ->
      let result = Locator.expect ~timeout ~expression:"to.be.visible" ~is_not:false button in
      check "expect did not match" (not result.matches);
      check "strict error_message" (Option.fold ~none:false ~some:(fun s -> contains s "strict mode violation") result.error_message));
    check "no silent wrong-target action" (eval page "window.clicked" = `Null);
    check "strict failures do not allocate handles" (handles page = baseline);
    test "first nth last and strict:false extension; raw selectors stay non-strict" (fun () ->
      Locator.click (Locator.first button); check "first" (eval page "window.clicked" = `String "one");
      Locator.click (Locator.nth 1 button); check "nth" (eval page "window.clicked" = `String "two");
      check "last" (Locator.inner_text (Locator.last button) = "Cancel");
      check "explicit extension" (Locator.inner_text ~strict:false button = "Save");
      check "raw Frame default" (Frame.inner_text ~selector:"#buttons button" (Page.main_frame page) = "Save");
      check "raw Page default" (Page.inner_text ~selector:"#buttons button" page = "Save"));
    test "plural methods and plural expect" (fun () ->
      check "count" (Locator.count button = 2);
      check "evaluate_all" (Locator.evaluate_all ~expression:"els => els.length" button = `Float 2.);
      check "all" (List.length (Locator.all button) = 2);
      check "inner texts" (Locator.all_inner_texts button = ["Save"; "Cancel"]);
      check "text contents" (Locator.all_text_contents button = ["Save"; "Cancel"]);
      let all = Locator.element_handles button in
      check "handles" (Array.length all = 2);
      Array.iter ElementHandle.dispose all;
      Locator.highlight button;
      check "count expect" (Locator.expect ~expression:"to.have.count" ~expected_number:2. ~is_not:false button).matches);
    no_pending page)

let selectors env =
  with_page env (fun sw _ browser context page ->
    let main = Page.main_frame page and article = loc page "#article" in
    let assert_one name l = check name (Locator.count l = 1) in
    test "test-ID default Page Frame nested" (fun () ->
      assert_one "Page" (Page.get_by_test_id special page);
      assert_one "Frame" (Frame.get_by_test_id special main);
      assert_one "Locator" (Locator.get_by_test_id special article));
    test "configured test-ID setter and creation option are context-local" (fun () ->
      (* Remove the default so a hard-coded helper cannot accidentally pass. *)
      ignore (eval page "document.querySelector('#special').removeAttribute('data-testid')");
      BrowserContext.set_test_id_attribute_name ~test_id_attribute_name:"data-qa" context;
      assert_one "configured Page" (Page.get_by_test_id special page);
      assert_one "configured Frame" (Frame.get_by_test_id special main);
      assert_one "configured nested" (Locator.get_by_test_id special article);
      let other = Browser.new_context ~test_id_attribute_name:"data-next" browser in
      let p = BrowserContext.new_page other in fixture p;
      ignore (eval p "document.querySelector('#special').removeAttribute('data-testid')");
      assert_one "creation configuration" (Page.get_by_test_id special p);
      BrowserContext.set_test_id_attribute_name ~test_id_attribute_name:"data-missing" other;
      check "no cross-context contamination" (Locator.count (Page.get_by_test_id special p) = 0);
      assert_one "first context still configured" (Page.get_by_test_id special page);
      BrowserContext.close other);
    test "substring, case and normalized whitespace text filters" (fun () ->
      let articles = loc page "article" in
      List.iter (fun text -> assert_one text (Locator.filter ~has_text:text articles))
        ["Alpha"; "ALPHA"; "pha b"; "alpha \n\t\r beta"; special];
      check "non-substring" (Locator.count (Locator.filter ~has_text:"AlphaBeta" articles) = 0);
      assert_one "text exact normalization" (Page.get_by_text ~exact:true " Alpha\n Beta " page));
    test "encodings: quotes backslashes LF TAB CR and Unicode" (fun () ->
      check "text matches both text nodes" (Locator.count (Page.get_by_text ~exact:true special page) = 2);
      List.iter (fun (name, l) -> assert_one name l) [
        "label", Page.get_by_label ~exact:true special page;
        "placeholder", Page.get_by_placeholder ~exact:true special page;
        "role name", Page.get_by_role ~name:special ~exact:true "textbox" page;
        "alt", Page.get_by_alt_text ~exact:true special page;
        "title", Page.get_by_title ~exact:true special page;
        "nested text", Locator.get_by_text ~exact:true special article;
      ];
      check "attribute exact is case-sensitive"
        (Locator.count (Page.get_by_title ~exact:true (String.lowercase_ascii special) page) = 0);
      assert_one "attribute nonexact case-insensitive" (Page.get_by_title "QUOTE" page));
    test "mixed engines, chained union, intersection, has, nested controls" (fun () ->
      let a = Page.get_by_role ~name:"Save" "button" page and b = Page.get_by_text ~exact:true "Cancel" page in
      check "mixed union" (Locator.count (Locator.or_ a b) = 2);
      error "strict mode violation" (fun () -> Locator.click ~timeout:500. (Locator.or_ a b));
      assert_one "union disambiguation" (Locator.first (Locator.or_ a b));
      check "chained union" (Locator.count (Locator.or_ (loc page "#buttons >> #one") (loc page "#buttons >> #two")) = 2);
      assert_one "intersection" (Locator.and_ a (loc page "#one"));
      let raw = "internal:attr=[title=\"" ^
        (String.concat "\\\"" (String.split_on_char '"' (String.concat "\\\\" (String.split_on_char '\\' special)))) ^ "\"s]" in
      assert_one "nested raw controls union" (Locator.or_ (loc page "#missing") (loc page raw));
      assert_one "nested raw controls intersection" (Locator.and_ (loc page "img") (loc page raw));
      assert_one "nested raw controls has" (Locator.filter ~has:(loc page raw) (loc page "body"));
      assert_one "has composed selector" (Locator.filter ~has:(Locator.or_ a b) (loc page "section"));
      assert_one "has text matcher" (Locator.filter ~has:(Page.get_by_text ~exact:true special page) (loc page "article")));
    test "same-frame equivalent wrapper; reject cross-frame and cross-session" (fun () ->
      let equivalent = Fiber.with_binding Connection.current_connection_key (conn page) (fun () ->
        match Frame.of_yojson (Frame.to_yojson main) with Ok f -> f | Error e -> failwith e) in
      let a = loc page "#one" and same = Frame.locator ~selector:"#one" equivalent in
      assert_one "equivalent wrapper and" (Locator.and_ a same);
      assert_one "equivalent wrapper or" (Locator.or_ a same);
      assert_one "equivalent wrapper has" (Locator.filter ~has:same (loc page "section"));
      Locator.drag_to ~trial:true ~timeout:1000. ~target:same a;
      let child = frame page in
      Frame.set_content ~html:"<button id='one' data-qa='child'>child</button>" child;
      assert_one "iframe inherits configuration" (Frame.get_by_test_id "child" child);
      let foreign = Frame.locator ~selector:"#one" child in
      let reject other =
        incompatible (fun () -> Locator.and_ a other);
        incompatible (fun () -> Locator.or_ a other);
        incompatible (fun () -> Locator.filter ~has:other a);
        incompatible (fun () -> Locator.drag_to ~timeout:300. ~target:other a)
      in
      reject foreign;
      let other = create ~env ~sw () in
      Fun.protect ~finally:(fun () -> destroy other) (fun () ->
        let b = launch other in
        let p = BrowserContext.new_page (Browser.new_context b) in
        Page.set_content ~html:"<button id='one'>other session</button>" p;
        reject (loc p "#one");
        Browser.close b));
    no_pending page)

let helpers env =
  with_page env (fun sw _ browser _ page ->
    let hidden = loc page "#hidden" and visible = loc page "#one" in
    let baseline = handles page in
    let clean () = check "temporary handles released" (handles page = baseline); no_pending page in
    test "immediate visibility and genuine errors (without handles)" (fun () ->
      (* A zero timeout would hang if interpreted as wait-unlimited. *)
      bounded env 1. (fun () ->
        check "hidden false" (not (Locator.is_visible ~timeout:0. hidden));
        check "missing false" (not (Locator.is_visible ~timeout:30000. (loc page "#missing")));
        check "hidden true" (Locator.is_hidden hidden);
        check "missing hidden" (Locator.is_hidden (loc page "#missing")));
      check "visible true" (Locator.is_visible visible);
      error "parsing css selector" (fun () -> Locator.is_visible (loc page "["));
      error "parsing css selector" (fun () -> Locator.is_hidden (loc page "["));
      clean ());
    test "actual bounding boxes hidden and iframe top-level coordinates" (fun () ->
      check "hidden None" (Locator.bounding_box hidden = None);
      let child = frame page in
      Frame.set_content ~html:"<style>body{margin:0}</style><div id='box' style='position:absolute;left:12px;top:15px;width:30px;height:20px'></div>" child;
      let box = Option.get (Locator.bounding_box (Frame.locator ~selector:"#box" child)) in
      check "top-level box" (box.x = 112. && box.y = 215. && box.width = 30. && box.height = 20.);
      clean ());
    test "evaluate waits for delayed insertion; acquisition timeout only" (fun () ->
      let pending = Fiber.fork_promise ~sw (fun () ->
        Locator.evaluate ~timeout:1500. ~expression:"el => el.id" (loc page "#late")) in
      until env (fun () -> Hashtbl.length (conn page).Connection.callbacks > 0);
      check "not resolved before insertion" (not (Promise.is_resolved pending));
      ignore (eval page "document.body.insertAdjacentHTML('beforeend', '<div id=\"late\"></div>')");
      check "delayed result" (Promise.await_exn pending = `String "late");
      let pending = Fiber.fork_promise ~sw (fun () ->
        Locator.evaluate ~timeout:150. ~expression:"el => new Promise(resolve => { window.releaseEval = () => resolve(el.id); })" visible) in
      until env (fun () -> eval page "typeof window.releaseEval" = `String "function");
      Eio_unix.sleep 0.2;
      check "JS execution not bounded by acquisition timeout" (not (Promise.is_resolved pending));
      ignore (eval page "window.releaseEval()");
      check "same element result" (Promise.await_exn pending = `String "one");
      clean ());
    test "real scroll actionability and screenshots on success and failure" (fun () ->
      Locator.scroll_into_view_if_needed ~timeout:1200. (loc page "#offscreen");
      check "actually scrolled" (eval page "window.scrollY > 0" = `Bool true);
      error "TimeoutError:" (fun () -> Locator.scroll_into_view_if_needed ~timeout:250. hidden);
      let png = Locator.screenshot ~timeout:1500. visible in
      check "PNG bytes" (String.starts_with ~prefix:"\x89PNG\r\n\x1a\n" png);
      error "TimeoutError:" (fun () -> Locator.screenshot ~timeout:250. hidden);
      error "quality is unsupported for the png screenshots" (fun () -> Locator.screenshot ~timeout:1000. ~quality:80 visible);
      clean ());
    test "temporary cleanup on evaluation exception, repeated successes and missing target" (fun () ->
      for _ = 1 to 8 do
        ignore (Locator.evaluate ~expression:"el => el.id" visible);
        ignore (Locator.bounding_box hidden);
        Locator.scroll_into_view_if_needed visible
      done;
      error "owned-operation-error" (fun () -> Locator.evaluate ~expression:"() => { throw Error('owned-operation-error') }" visible);
      error "TimeoutError:" (fun () -> Locator.evaluate ~timeout:170. ~expression:"el => el.id" (loc page "#never"));
      clean ());
    test "caller-owned element_handle and element_handles remain usable" (fun () ->
      let h = Option.get (Locator.element_handle visible) in
      let hs = Locator.element_handles (loc page "#buttons button") in
      ignore (Locator.bounding_box visible);
      check "caller handles not disposed" (handles page = baseline + 3);
      check "caller handle evaluation" (ElementHandle.evaluate ~expression:"el => el.id" h = `String "one");
      Array.iter (fun h -> check "caller plural handle" (ElementHandle.bounding_box h <> None)) hs;
      ElementHandle.dispose h; Array.iter ElementHandle.dispose hs;
      clean ());
    test "cancellation during acquisition and JavaScript operation" (fun () ->
      let cancel_operation ?(after_cancel = fun () -> ()) operation started =
        let cc_p, cc_u = Promise.create () in
        let p = Fiber.fork_promise ~sw (fun () ->
          try Eio.Cancel.sub (fun cc -> Promise.resolve cc_u cc; operation ()); false
          with Eio.Cancel.Cancelled _ -> true) in
        let cc = Promise.await cc_p in started ();
        Eio.Cancel.cancel cc Exit;
        after_cancel ();
        check "cancellation propagated" (bounded env 2. (fun () -> Promise.await_exn p));
        clean ()
      in
      (* A finite remote absence wait settles naturally during cancellation
         recovery. An unlimited one cannot be individually aborted by 1.59.1. *)
      cancel_operation
        (fun () -> ignore (Locator.evaluate ~timeout:300. ~expression:"el => el.id" (loc page "#never")))
        (fun () -> until env (fun () -> Hashtbl.length (conn page).Connection.callbacks > 0));
      cancel_operation
        ~after_cancel:(fun () -> ignore (eval page
          "document.body.insertAdjacentHTML('beforeend', '<div id=\"canceled-late\"></div>')"))
        (fun () -> ignore (Locator.evaluate ~timeout:0. ~expression:"el => el.id" (loc page "#canceled-late")))
        (fun () -> until env (fun () -> Hashtbl.length (conn page).Connection.callbacks > 0));
      cancel_operation
        (fun () -> ignore (Locator.evaluate ~expression:"el => { window.evalStarted = true; return new Promise(() => {}); }" visible))
        (fun () -> until env (fun () -> eval page "window.evalStarted === true" = `Bool true));
      check "connection remains usable" (Locator.is_visible visible));
    test "target and connection closure remain errors, cleanup terminates" (fun () ->
      let p = BrowserContext.new_page (Browser.new_context browser) in
      Page.set_content ~html:"<div>target</div>" p;
      let target = loc p "div" in
      let pending = Fiber.fork_promise ~sw (fun () ->
        error "Target" (fun () -> Locator.evaluate ~expression:"el => { window.started = true; return new Promise(() => {}); }" target)) in
      until env (fun () -> eval p "window.started === true" = `Bool true);
      Page.close p;
      bounded env 2. (fun () -> Promise.await_exn pending);
      error "Target" (fun () -> Locator.is_visible target);
      error "Target" (fun () -> Locator.is_hidden target);
      clean ();
      let c = conn page in
      let pending = Fiber.fork_promise ~sw (fun () ->
        error "locator-test-close" (fun () -> Locator.evaluate ~expression:"el => { window.closing = true; return new Promise(() => {}); }" visible)) in
      until env (fun () -> eval page "window.closing === true" = `Bool true);
      Connection.close c "locator-test-close";
      bounded env 2. (fun () -> Promise.await_exn pending);
      error "locator-test-close" (fun () -> Locator.is_visible visible);
      error "locator-test-close" (fun () -> Locator.is_hidden visible);
      check "closed connection has no objects or requests" (Hashtbl.length c.objects = 0 && Hashtbl.length c.callbacks = 0)))

let latency env =
  with_page env (fun sw _ _ context page ->
    let data = In_channel.with_open_text "latency-fixture.json" In_channel.input_all |> Yojson.Safe.from_string in
    let text key = Yojson.Safe.Util.member key data |> Yojson.Safe.Util.to_string in
    BrowserContext.register_selector_engine
      ~selector_engine:SelectorEngine.Wrap.{ name = "slow"; source = text "slowEngine"; content_script = Some false } context;
    let baseline = handles page in
    let clean () = check "latency case has no leaked handles" (handles page = baseline); no_pending page in
    test "slow selector finishes once per acquisition, across every handle helper" (fun () ->
      let target = loc page "slow=#one" in
      let operations = [
        (fun () -> check "evaluation result" (Locator.evaluate ~timeout:1600. ~expression:"el => el.id" target = `String "one"));
        (fun () -> check "box" (Locator.bounding_box ~timeout:1600. target <> None));
        (fun () -> Locator.scroll_into_view_if_needed ~timeout:1600. target);
        (fun () -> check "screenshot"
          (String.starts_with ~prefix:"\x89PNG" (Locator.screenshot ~timeout:1600. target)));
        (fun () ->
          let h = Option.get (Locator.element_handle ~timeout:1600. target) in
          check "caller handle" (ElementHandle.evaluate ~expression:"el => el.id" h = `String "one");
          ElementHandle.dispose h);
        (fun () -> check "unlimited acquisition result"
          (Locator.evaluate ~timeout:0. ~expression:"el => el.id" target = `String "one"));
      ] in
      List.iteri (fun i operation ->
        bounded env 4. operation;
        (* Exact count and a follow-up round trip catch queued duplicate work,
           not just a lucky success inside a broad timing threshold. *)
        check "one selector invocation per acquisition" (eval page "window.slowQueries" = `Float (float (i + 1)));
        clean ()) operations);
    test "busy page queries wait without closing a responsive session" (fun () ->
      Page.update_subscription ~event:`Console ~enabled:true page;
      List.iter (fun plural ->
        let started, start_u = Promise.create () in
        BrowserContext.on_console context (fun _ ->
          if not (Promise.is_resolved started) then Promise.resolve start_u ());
        ignore (eval page (text "busyPage"));
        bounded env 3. (fun () -> Promise.await started);
        let pending = Fiber.fork_promise ~sw (fun () ->
          if plural then Locator.element_handles (loc page "#one")
          else [|Option.get (Locator.element_handle ~timeout:5000. (loc page "#one"))|]) in
        until env (fun () -> Hashtbl.length (conn page).Connection.callbacks > 0);
        bounded env 1. (fun () -> ignore (BrowserContext.cookies ~urls:[||] context));
        check "context RPC completes while target is busy" (not (Promise.is_resolved pending));
        let hs = bounded env 5. (fun () -> Promise.await_exn pending) in
        check "target returned" (Array.length hs = 1 &&
          ElementHandle.evaluate ~expression:"el => el.id" hs.(0) = `String "one");
        Array.iter ElementHandle.dispose hs;
        check "same session still open" (Connection.closed_reason (conn page) = None);
        ignore (BrowserContext.cookies ~urls:[||] context); clean ())
        [true; false]);
    test "unlimited canceled absence has bounded post-cancellation recovery" (fun () ->
      (* Separate session: no per-request remote abort exists in this protocol.
         This explicitly tests the exceptional recovery policy, not latency. *)
      Switch.run (fun own ->
        let pw = create ~env ~sw:own () in
        Fun.protect ~finally:(fun () -> destroy pw) (fun () ->
          let b = launch pw in
          let p = BrowserContext.new_page (Browser.new_context b) in
          let c = conn p in
          let cc_p, cc_u = Promise.create () in
          let result = Fiber.fork_promise ~sw (fun () ->
            try Eio.Cancel.sub (fun cc ->
              Promise.resolve cc_u cc;
              ignore (Locator.element_handle ~timeout:0. (loc p "#never")));
              false
            with Eio.Cancel.Cancelled _ -> true) in
          let cc = Promise.await cc_p in
          until env (fun () -> Hashtbl.length c.Connection.callbacks > 0);
          Eio.Cancel.cancel cc Exit;
          check "original cancellation" (bounded env 3. (fun () -> Promise.await_exn result));
          check "explicit canceled response diagnostic"
            (Option.fold ~none:false ~some:(fun reason -> contains reason "canceled waitForSelector response") (Connection.closed_reason c));
          check "recovery closes and clears only its session"
            (Hashtbl.length c.objects = 0 && Hashtbl.length c.callbacks = 0 &&
             Connection.closed_reason (conn page) = None)));
      check "unrelated caller remains usable" (Locator.is_visible (loc page "#one"));
      clean ()))

let () =
  Printexc.record_backtrace true;
  Eio_main.run (fun env ->
    match Sys.argv.(1) with
    | "strict" -> strict env
    | "selectors" -> selectors env
    | "helpers" -> helpers env
    | "latency" -> latency env
    | mode -> invalid_arg mode)
