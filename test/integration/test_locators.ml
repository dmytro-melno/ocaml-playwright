(* Locators, actions and assertions. *)

open Playwright
open Harness

let form =
    {|<title>Form</title>
      <h1>Sign up</h1>
      <form>
        <label for="name">Name</label> <input id="name" placeholder="Your name" data-testid="name-input">
        <label>Email <input type="email" title="Email address"></label>
        <label><input type="checkbox" id="terms"> Accept terms</label>
        <label><input type="radio" name="plan" value="free" checked> Free</label>
        <label><input type="radio" name="plan" value="pro"> Pro</label>
        <select id="colour" multiple><option value="r">Red</option><option value="g">Green</option><option value="b">Blue</option></select>
        <textarea aria-label="Comment"></textarea>
        <button type="button" onclick="document.querySelector('#out').textContent = 'submitted ' + document.querySelector('#name').value">Submit</button>
        <button type="button" disabled>Disabled</button>
      </form>
      <img alt="Company logo" src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==">
      <ul><li>Apple</li><li>Banana <b>ripe</b></li><li>Cherry</li></ul>
      <p id="out"></p>
      <p style="display: none" id="hidden">Hidden text</p>|}

let test_queries _ page =
    Page.set_content form page;
    let text locator = Locator.inner_text locator in
    Alcotest.(check string) "by role and name" "Submit" (Page.get_by_role `Button ~name:"Submit" page |> text);
    Alcotest.(check string) "by role and name regex" "Submit" (Page.get_by_role `Button ~name_regex:"/^sub/i" page |> text);
    Alcotest.(check int) "disabled buttons" 1 (Page.get_by_role `Button ~disabled:true page |> Locator.count);
    Alcotest.(check int) "name is a substring match" 0 (Page.get_by_role `Button ~name:"Sub" ~exact:true page |> Locator.count);
    Alcotest.(check string) "heading level" "Sign up" (Page.get_by_role `Heading ~level:1 page |> text);
    Alcotest.(check string) "by label, for=" "name" (Page.get_by_label "Name" page |> Locator.get_attribute "id" |> Option.get);
    Alcotest.(check string) "by label, wrapping" "email" (Page.get_by_label "Email" page |> Locator.get_attribute "type" |> Option.get);
    Alcotest.(check string) "by aria-label" "TEXTAREA" (Page.get_by_label "Comment" page |> Locator.evaluate "e => e.tagName" |> Js.to_string);
    Alcotest.(check int) "by placeholder" 1 (Page.get_by_placeholder "Your name" page |> Locator.count);
    Alcotest.(check int) "by title regex" 1 (Page.get_by_title_regex "/email/i" page |> Locator.count);
    Alcotest.(check int) "by alt text" 1 (Page.get_by_alt_text "logo" page |> Locator.count);
    Alcotest.(check int) "by alt text, exact" 0 (Page.get_by_alt_text ~exact:true "logo" page |> Locator.count);
    Alcotest.(check int) "by test id" 1 (Page.get_by_test_id "name-input" page |> Locator.count);
    Alcotest.(check string) "by text" "Banana ripe" (Page.get_by_text "banana" page |> text);
    Alcotest.(check int) "by exact text" 0 (Page.get_by_text ~exact:true "banana" page |> Locator.count);
    Alcotest.(check string) "by text regex" "Cherry" (Page.get_by_text_regex "/^ch.rry$/i" page |> text);
    let items = Page.get_by_role `Listitem page in
    Alcotest.(check int) "count" 3 (Locator.count items);
    Alcotest.(check (list string)) "all texts" [ "Apple"; "Banana ripe"; "Cherry" ] (Locator.all_inner_texts items);
    Alcotest.(check (list string)) "all" [ "Apple"; "Banana ripe"; "Cherry" ] (List.map text (Locator.all items));
    Alcotest.(check string) "first" "Apple" (Locator.first items |> text);
    Alcotest.(check string) "last" "Cherry" (Locator.last items |> text);
    Alcotest.(check string) "nth" "Banana ripe" (Locator.nth 1 items |> text);
    Alcotest.(check string) "nth from the end" "Banana ripe" (Locator.nth (-2) items |> text);
    Alcotest.(check string) "filter by text" "Cherry" (Locator.filter ~has_text:"err" items |> text);
    Alcotest.(check (list string)) "filter by absent text" [ "Apple"; "Cherry" ] (Locator.filter ~has_not_text:"Banana" items |> Locator.all_inner_texts);
    Alcotest.(check string) "filter by descendant" "Banana ripe" (Locator.filter ~has:(Page.locator "b" page) items |> text);
    Alcotest.(check int) "filter by absent descendant" 2 (Locator.filter ~has_not:(Page.locator "b" page) items |> Locator.count);
    Alcotest.(check string) "nested" "ripe" (Locator.locator "b" items |> text);
    Alcotest.(check string) "nested query" "ripe" (Page.locator "ul" page |> Locator.get_by_text "ripe" ~exact:true |> text);
    Alcotest.(check string) "and" "Submit" (Locator.and_ (Page.get_by_text "Submit" page) (Page.get_by_role `Button page) |> text);
    Alcotest.(check int) "or" 2 (Locator.or_ (Page.get_by_role `Heading page) (Page.locator "#name" page) |> Locator.count);
    Alcotest.(check int) "visible only" 0 (Page.locator "#hidden" page |> Locator.visible |> Locator.count);
    Alcotest.(check int) "locator options" 1 (Page.locator "li" ~has_text_regex:"/^apple$/i" page |> Locator.count);
    Alcotest.(check bool) "equal" true (Locator.equal (Page.locator "li" page) (Page.locator "li" page));
    Alcotest.check_raises "text and regex together" (Invalid_argument "Playwright: pass either ~has_text or ~has_text_regex, not both") (fun () ->
        ignore (Page.locator "li" ~has_text:"a" ~has_text_regex:"/a/" page))

let test_reading _ page =
    Page.set_content form page;
    let name = Page.locator "#name" page in
    Alcotest.(check (option string)) "attribute" (Some "Your name") (Locator.get_attribute "placeholder" name);
    Alcotest.(check (option string)) "absent attribute" None (Locator.get_attribute "nope" name);
    Alcotest.(check (option string)) "text content includes hidden text" (Some "Hidden text") (Page.locator "#hidden" page |> Locator.text_content);
    Alcotest.(check string) "inner html" "Banana <b>ripe</b>" (Page.locator "li" page |> Locator.nth 1 |> Locator.inner_html);
    Alcotest.(check bool) "visible" true (Locator.is_visible name);
    Alcotest.(check bool) "hidden" true (Page.locator "#hidden" page |> Locator.is_hidden);
    Alcotest.(check bool) "a missing element is hidden, not an error" true (Page.locator "#missing" page |> Locator.is_hidden);
    Alcotest.(check bool) "enabled" true (Locator.is_enabled name && Locator.is_editable name);
    Alcotest.(check bool) "disabled" true (Page.get_by_role `Button ~name:"Disabled" page |> Locator.is_disabled);
    Alcotest.(check bool) "checked" true (Page.locator "[value=free]" page |> Locator.is_checked);
    (match Locator.bounding_box name with
    | Some box -> Alcotest.(check bool) "bounding box" true (box.width > 10. && box.height > 5. && box.x >= 0.)
    | None -> Alcotest.fail "no bounding box");
    Alcotest.(check bool) "no box for hidden elements" true (Page.locator "#hidden" page |> Locator.bounding_box = None);
    Alcotest.check js "evaluate_all" (Js.Number 3.) (Page.locator "li" page |> Locator.evaluate_all "items => items.length");
    Alcotest.(check string) "selector text" "#name" (Locator.to_string name |> fun s -> String.sub s (String.length s - 5) 5);
    Alcotest.(check bool) "its page" true (Page.equal (Locator.page name) page)

let test_actions _ page =
    Page.set_content form page;
    let name = Page.get_by_label "Name" page in
    Locator.fill "Ada" name;
    Alcotest.(check string) "fill" "Ada" (Locator.input_value name);
    Locator.press_sequentially " Lovelace" name;
    Locator.press "Shift+Home" name;
    Alcotest.(check string) "keyboard selection" "Ada Lovelace" (eval_string "getSelection().toString()" page);
    Locator.press "End" name;
    Locator.press "Backspace" name;
    Alcotest.(check string) "typing and keys" "Ada Lovelac" (Locator.input_value name);
    Locator.clear name;
    Alcotest.(check string) "clear" "" (Locator.input_value name);
    Locator.fill "Grace" name;
    Page.get_by_role `Button ~name:"Submit" page |> Locator.click;
    Alcotest.(check string) "click" "submitted Grace" (Page.locator "#out" page |> Locator.inner_text);
    let terms = Page.get_by_label "Accept terms" page in
    Locator.check terms;
    Alcotest.(check bool) "check" true (Locator.is_checked terms);
    Locator.uncheck terms;
    Locator.set_checked true terms;
    Alcotest.(check bool) "set_checked" true (Locator.is_checked terms);
    Page.get_by_label "Pro" page |> Locator.check;
    Alcotest.(check string) "radio" "pro" (eval_string "document.querySelector('[name=plan]:checked').value" page);
    let colour = Page.locator "#colour" page in
    Alcotest.(check (list string)) "select by value and label" [ "r"; "b" ] (Locator.select_option [ `Value "r"; `Label "Blue" ] colour);
    Alcotest.(check (list string)) "select by index" [ "g" ] (Locator.select_option [ `Index 1 ] colour);
    let comment = Page.get_by_label "Comment" page in
    Locator.focus comment;
    Alcotest.(check string) "focus" "TEXTAREA" (eval_string "document.activeElement.tagName" page);
    Locator.blur comment;
    Alcotest.(check string) "blur" "BODY" (eval_string "document.activeElement.tagName" page);
    Locator.fill "some text" comment;
    Locator.select_text comment;
    Alcotest.(check string) "select_text" "some text" (eval_string "getSelection().toString()" page);
    ignore (Page.evaluate "document.querySelector('h1').addEventListener('click', e => { window.clicked = e.clientX })" page);
    Page.get_by_role `Heading page |> Locator.dispatch_event "click" ~event_init:(Js.obj [ "clientX", Js.int 7 ]);
    Alcotest.(check int) "dispatch_event" 7 (eval_int "window.clicked" page)

let test_mouse_actions _ page =
    Page.set_content
        {|<style>div { width: 100px; height: 100px; margin: 20px; background: silver }</style>
          <div id="a" draggable="true" ondragstart="event.dataTransfer.setData('text', 'a')">A</div>
          <div id="b" ondragover="event.preventDefault()" ondrop="this.textContent = 'dropped ' + event.dataTransfer.getData('text')">B</div>
          <div id="c">C</div>
          <script>
            window.log = [];
            const c = document.querySelector('#c');
            for (const type of ['mouseenter', 'click', 'dblclick', 'contextmenu'])
              c.addEventListener(type, e => { e.preventDefault(); window.log.push(type + (e.shiftKey ? '+shift' : '') + '@' + e.offsetX + ',' + e.offsetY) });
          </script>|}
        page;
    let c = Page.locator "#c" page in
    Locator.hover c;
    Locator.click ~position:(10., 20.) ~modifiers:[ `Shift ] c;
    Locator.click ~button:`Right c;
    Locator.dblclick ~position:(1., 1.) c;
    Alcotest.(check (list string)) "events"
        [ "mouseenter@50,50"; "click+shift@10,20"; "contextmenu@50,50"; "click@1,1"; "click@1,1"; "dblclick@1,1" ]
        (Page.evaluate "window.log" page |> Js.to_list Js.to_string);
    Locator.drag_to (Page.locator "#b" page) (Page.locator "#a" page);
    Alcotest.(check string) "drag and drop" "dropped a" (Page.locator "#b" page |> Locator.inner_text);
    Locator.click ~trial:true c;
    Alcotest.(check int) "a trial run does not click" 3 (eval_int "window.log.filter(entry => entry.startsWith('click')).length" page)

let test_waiting_and_strictness _ page =
    Page.set_content {|<button>One</button><button>Two</button><div id="late" style="display: none">Late</div>|} page;
    let error = failure "two matches" (fun () -> Page.get_by_role `Button page |> Locator.click) in
    check_contains "strict mode violation" ~sub:"strict mode violation" error.message;
    check_contains "which names the candidates" ~sub:"get_by_role(\"button\", name=\"One\")" error.message;
    (* Actions wait for the element to become actionable. *)
    ignore (Page.evaluate "setTimeout(() => { document.querySelector('#late').style.display = 'block' }, 150)" page);
    let late = Page.locator "#late" page in
    Locator.click late;
    ignore (Page.evaluate "setTimeout(() => document.querySelector('#late').remove(), 100)" page);
    Locator.wait_for ~state:`Detached late;
    let error = failure "never appears" (fun () -> Locator.click ~timeout:250. late) in
    Alcotest.check error_kind "timeout" Error.Timeout error.kind;
    check_contains "what was waited for" ~sub:"waiting for locator(\"#late\")" error.message;
    check_failure "wait_for times out too" ~kind:Timeout (fun () -> Locator.wait_for ~timeout:100. late);
    (* Default timeouts: the page's overrides the context's. *)
    BrowserContext.set_default_timeout 150. (Page.context page);
    check_failure "context default" ~message:"Timeout 150ms" (fun () -> Locator.click late);
    Page.set_default_timeout 100. page;
    check_failure "page default" ~message:"Timeout 100ms" (fun () -> Locator.click late)

let test_selector_operations _ page =
    Page.set_content form page;
    Page.fill "#name" "Ada" page;
    Page.click "text=Submit" page;
    Alcotest.(check string) "fill and click" "submitted Ada" (Page.inner_text "#out" page);
    Alcotest.(check (option string)) "text content" (Some "Sign up") (Page.text_content "h1" page);
    Alcotest.(check (option string)) "attribute" (Some "Your name") (Page.get_attribute "#name" "placeholder" page);
    Alcotest.(check string) "input value" "Ada" (Page.input_value "#name" page);
    Page.check "#terms" page;
    Alcotest.(check bool) "checked" true (Page.is_checked "#terms" page);
    Alcotest.(check bool) "states" true (Page.is_visible "h1" page && Page.is_hidden "#hidden" page && Page.is_disabled "text=Disabled" page);
    Alcotest.(check (list string)) "select" [ "g" ] (Page.select_option "#colour" [ `Value "g" ] page);
    Alcotest.check js "eval on selector" (Js.String "Apple!") (Page.eval_on_selector "li" "(li, suffix) => li.textContent + suffix" ~arg:(Js.string "!") page);
    Alcotest.check js "eval on all" (Js.Number 3.) (Page.eval_on_selector_all "li" "items => items.length" page);
    Alcotest.(check int) "query all" 3 (List.length (Page.query_selector_all "li" page));
    Alcotest.(check bool) "query nothing" true (Option.is_none (Page.query_selector "#missing" page));
    let element = Page.wait_for_selector "#name" page |> Option.get in
    ElementHandle.fill "Grace" element;
    ElementHandle.press "Tab" element;
    Alcotest.(check string) "element handle" "Grace" (ElementHandle.input_value element);
    Alcotest.(check bool) "element state" true (ElementHandle.is_visible element && ElementHandle.is_enabled element);
    Alcotest.(check (option string)) "element attribute" (Some "name") (ElementHandle.get_attribute "id" element);
    Alcotest.(check bool) "owner frame" true (Option.equal Frame.equal (ElementHandle.owner_frame element) (Some (Page.main_frame page)));
    Alcotest.(check bool) "waiting for hidden yields nothing" true (Option.is_none (Page.wait_for_selector ~state:`Hidden "#hidden" page));
    check_failure "strict selector" ~message:"strict mode violation" (fun () -> Page.click ~strict:true "li" page)

let test_drop t page =
    Page.set_content
        {|<div id="zone" style="width: 200px; height: 100px; background: silver">Drop here</div>
          <script>
            const zone = document.querySelector('#zone');
            zone.addEventListener('dragover', event => event.preventDefault());
            zone.addEventListener('drop', async event => {
              event.preventDefault();
              const text = event.dataTransfer.getData('text/plain');
              const files = await Promise.all([...event.dataTransfer.files].map(async file => file.name + '=' + await file.text()));
              window.dropped = { text, files };
            });
          </script>|}
        page;
    let zone = Page.locator "#zone" page in
    let dropped () =
        ignore (Page.wait_for_function "window.dropped" page);
        let value = Page.evaluate "(() => { const d = window.dropped; window.dropped = undefined; return d })()" page in
        Js.to_string (Js.member "text" value), Js.to_list Js.to_string (Js.member "files" value)
    in
    Locator.drop ~data:[ "text/plain", "hello" ] zone;
    Alcotest.(check (pair string (list string))) "data" ("hello", []) (dropped ());
    let file = scratch_file t "dropped.txt" in
    write_file file "from disk";
    Locator.drop ~files:[ file ] zone;
    Alcotest.(check (pair string (list string))) "a file" ("", [ Filename.basename file ^ "=from disk" ]) (dropped ());
    Locator.drop ~payloads:[ { name = "memo.txt"; mime_type = Some "text/plain"; buffer = "from memory" } ] ~data:[ "text/plain", "both" ] zone;
    Alcotest.(check (pair string (list string))) "an in-memory file with data" ("both", [ "memo.txt=from memory" ]) (dropped ());
    match Locator.drop ~files:[ file ] ~payloads:[] zone with
    | () -> Alcotest.fail "files and payloads together"
    | exception Invalid_argument _ -> ()

let test_uploads t page =
    Page.set_content {|<input type="file" id="one"><input type="file" id="many" multiple>|} page;
    let describe id =
        Page.evaluate
            (Printf.sprintf
                 "Promise.all([...document.querySelector('#%s').files].map(async f => f.name + ':' + f.type + ':' + await f.text())).then(l => l.join('|'))" id)
            page
        |> Js.to_string
    in
    let a = scratch_file t "a.txt" and b = scratch_file t "b.json" in
    write_file a "alpha";
    write_file b "{}";
    Page.locator "#one" page |> Locator.set_input_files [ a ];
    Alcotest.(check string) "a file from disk" (Filename.basename a ^ ":text/plain:alpha") (describe "one");
    Page.locator "#many" page |> Locator.set_input_files [ a; b ];
    Alcotest.(check string) "several files" (Printf.sprintf "%s:text/plain:alpha|%s:application/json:{}" (Filename.basename a) (Filename.basename b)) (describe "many");
    Page.locator "#one" page |> Locator.set_input_payloads [ { name = "memo.csv"; mime_type = Some "text/csv"; buffer = "x,y\n1,2" } ];
    Alcotest.(check string) "a file from memory" "memo.csv:text/csv:x,y\n1,2" (describe "one");
    Page.locator "#one" page |> Locator.set_input_files [];
    Alcotest.(check string) "cleared" "" (describe "one");
    check_failure "several files for a single input" ~message:"Non-multiple file input" (fun () -> Page.locator "#one" page |> Locator.set_input_files [ a; b ]);
    let chooser = Page.expect_file_chooser (fun () -> Page.click "#many" page) page in
    Alcotest.(check bool) "multiple" true (FileChooser.is_multiple chooser);
    Alcotest.(check bool) "its page" true (Page.equal (FileChooser.page chooser) page);
    FileChooser.set_files [ b ] chooser;
    Alcotest.(check string) "through the file chooser" (Filename.basename b ^ ":application/json:{}") (describe "many")

let test_expect _ page =
    Page.set_content form page;
    let heading = Page.get_by_role `Heading page and name = Page.locator "#name" page and terms = Page.locator "#terms" page in
    Expect.to_be_visible heading;
    Expect.to_be_hidden (Page.locator "#hidden" page);
    Expect.to_be_attached (Page.locator "#hidden" page);
    Expect.Not.to_be_attached (Page.locator "#missing" page);
    Expect.to_have_text "Sign up" heading;
    Expect.to_have_text ~ignore_case:true "sign   UP" heading;
    Expect.to_have_text_regex "/^sign/i" heading;
    Expect.to_contain_text "up" heading;
    Expect.Not.to_have_text "Sign" heading;
    Expect.to_have_texts [ "Apple"; "Banana ripe"; "Cherry" ] (Page.locator "li" page);
    Expect.to_contain_texts [ "App"; "Ban"; "Che" ] (Page.locator "li" page);
    Expect.to_have_count 3 (Page.locator "li" page);
    Expect.to_be_enabled name;
    Expect.to_be_editable name;
    Expect.to_be_empty name;
    Expect.to_be_disabled (Page.get_by_text "Disabled" page);
    Expect.to_have_attribute "placeholder" "Your name" name;
    Expect.to_have_attribute_regex "placeholder" "/name$/" name;
    Expect.to_have_attribute_present "data-testid" name;
    Expect.Not.to_have_attribute_present "disabled" name;
    Expect.to_have_id "name" name;
    Expect.to_have_role `Textbox name;
    Expect.to_have_accessible_name "Name" name;
    Expect.Not.to_be_checked terms;
    Locator.check terms;
    Expect.to_be_checked terms;
    Expect.to_be_checked ~checked:true terms;
    Locator.fill "Ada" name;
    Expect.to_have_value "Ada" name;
    Expect.to_have_value_regex "/^A/" name;
    Expect.to_have_js_property "value" (Js.string "Ada") name;
    Locator.focus name;
    Expect.to_be_focused name;
    ignore (Locator.select_option [ `Value "r"; `Value "g" ] (Page.locator "#colour" page));
    Expect.to_have_values [ "r"; "g" ] (Page.locator "#colour" page);
    Expect.to_have_css "display" "none" (Page.locator "#hidden" page);
    Expect.to_be_in_viewport heading;
    Expect.to_have_title "Form" page;
    Expect.to_have_title_regex "/^F/" page;
    Expect.to_have_url "about:blank" page;
    Expect.Not.to_have_url "**/other" page;
    Expect.to_match_aria_snapshot
        {|
          - list:
            - listitem: Apple
            - listitem: /Banana/
            - listitem: Cherry
        |}
        (Page.locator "ul" page)

let test_expect_waits_and_fails _ page =
    Page.set_content {|<p id="status">loading</p><ul><li>one</li></ul>|} page;
    ignore (Page.evaluate "setTimeout(() => { document.querySelector('#status').textContent = 'ready' }, 150)" page);
    let status = Page.locator "#status" page in
    Expect.to_have_text "ready" status;
    let error = failure "wrong text" (fun () -> Expect.to_have_text ~timeout:200. "done" status) in
    Alcotest.check error_kind "kind" Error.Assertion_failed error.kind;
    check_contains "expectation" ~sub:{|expected to have text "done"|} error.message;
    check_contains "what was found" ~sub:{|Received: "ready"|} error.message;
    check_contains "call log" ~sub:"Call log:" error.message;
    let error = failure "negated" (fun () -> Expect.Not.to_be_visible ~timeout:100. status) in
    check_contains "negated expectation" ~sub:"expected not to be visible" error.message;
    let error = failure "missing element" (fun () -> Expect.to_be_visible ~timeout:100. (Page.locator "#nowhere" page)) in
    Alcotest.check error_kind "a missing element is an assertion failure too" Error.Assertion_failed error.kind;
    let error = failure "count" (fun () -> Expect.to_have_count ~timeout:100. 2 (Page.locator "li" page)) in
    check_contains "count received" ~sub:"Received: 1" error.message;
    let error = failure "snapshot" (fun () -> Expect.to_match_aria_snapshot ~timeout:100. "- list:\n  - listitem: two" (Page.locator "ul" page)) in
    check_contains "snapshot received" ~sub:"- listitem: one" error.message;
    (* The default timeout is a setting. *)
    Expect.set_default_timeout 100.;
    Fun.protect
        ~finally:(fun () -> Expect.set_default_timeout 5000.)
        (fun () -> check_failure "default timeout" ~kind:Assertion_failed ~message:"100ms" (fun () -> Expect.to_have_text "never" status))

let tests t =
    [ "locators",
      [ page_case t "queries" (test_queries t);
        page_case t "reading" (test_reading t);
        page_case t "actions" (test_actions t);
        page_case t "mouse actions" (test_mouse_actions t);
        page_case t "waiting and strictness" (test_waiting_and_strictness t);
        page_case t "selector operations and element handles" (test_selector_operations t);
        page_case t "uploads" (test_uploads t);
        page_case t "drop" (test_drop t) ];
      "expect", [ page_case t "assertions" (test_expect t); page_case t "waiting and failing" (test_expect_waits_and_fails t) ] ]
