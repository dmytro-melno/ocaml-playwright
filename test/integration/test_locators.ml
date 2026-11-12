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
    Page.set_content page form;
    let text locator = Locator.inner_text locator in
    Alcotest.(check string) "by role and name" "Submit" (Page.get_by_role page `Button ~name:"Submit" |> text);
    Alcotest.(check string) "by role and name regex" "Submit" (Page.get_by_role page `Button ~name_regex:"/^sub/i" |> text);
    Alcotest.(check int) "disabled buttons" 1 (Page.get_by_role page `Button ~disabled:true |> Locator.count);
    Alcotest.(check int) "name is a substring match" 0 (Page.get_by_role page `Button ~name:"Sub" ~exact:true |> Locator.count);
    Alcotest.(check string) "heading level" "Sign up" (Page.get_by_role page `Heading ~level:1 |> text);
    Alcotest.(check string) "by label, for=" "name" (Page.get_by_label page "Name" |> Locator.get_attribute "id" |> Option.get);
    Alcotest.(check string) "by label, wrapping" "email" (Page.get_by_label page "Email" |> Locator.get_attribute "type" |> Option.get);
    Alcotest.(check string) "by aria-label" "TEXTAREA" (Page.get_by_label page "Comment" |> Locator.evaluate "e => e.tagName" |> Js.to_string);
    Alcotest.(check int) "by placeholder" 1 (Page.get_by_placeholder page "Your name" |> Locator.count);
    Alcotest.(check int) "by title regex" 1 (Page.get_by_title_regex page "/email/i" |> Locator.count);
    Alcotest.(check int) "by alt text" 1 (Page.get_by_alt_text page "logo" |> Locator.count);
    Alcotest.(check int) "by alt text, exact" 0 (Page.get_by_alt_text page ~exact:true "logo" |> Locator.count);
    Alcotest.(check int) "by test id" 1 (Page.get_by_test_id page "name-input" |> Locator.count);
    Alcotest.(check string) "by text" "Banana ripe" (Page.get_by_text page "banana" |> text);
    Alcotest.(check int) "by exact text" 0 (Page.get_by_text page ~exact:true "banana" |> Locator.count);
    Alcotest.(check string) "by text regex" "Cherry" (Page.get_by_text_regex page "/^ch.rry$/i" |> text);
    let items = Page.get_by_role page `Listitem in
    Alcotest.(check int) "count" 3 (Locator.count items);
    Alcotest.(check (list string)) "all texts" [ "Apple"; "Banana ripe"; "Cherry" ] (Locator.all_inner_texts items);
    Alcotest.(check (list string)) "all" [ "Apple"; "Banana ripe"; "Cherry" ] (List.map text (Locator.all items));
    Alcotest.(check string) "first" "Apple" (Locator.first items |> text);
    Alcotest.(check string) "last" "Cherry" (Locator.last items |> text);
    Alcotest.(check string) "nth" "Banana ripe" (Locator.nth 1 items |> text);
    Alcotest.(check string) "nth from the end" "Banana ripe" (Locator.nth (-2) items |> text);
    Alcotest.(check string) "filter by text" "Cherry" (Locator.filter ~has_text:"err" items |> text);
    Alcotest.(check (list string)) "filter by absent text" [ "Apple"; "Cherry" ] (Locator.filter ~has_not_text:"Banana" items |> Locator.all_inner_texts);
    Alcotest.(check string) "filter by descendant" "Banana ripe" (Locator.filter ~has:(Page.locator page "b") items |> text);
    Alcotest.(check int) "filter by absent descendant" 2 (Locator.filter ~has_not:(Page.locator page "b") items |> Locator.count);
    Alcotest.(check string) "nested" "ripe" (Locator.locator "b" items |> text);
    Alcotest.(check string) "nested query" "ripe" (Page.locator page "ul" |> Locator.get_by_text "ripe" ~exact:true |> text);
    Alcotest.(check string) "and" "Submit" (Locator.and_ (Page.get_by_text page "Submit") (Page.get_by_role page `Button) |> text);
    Alcotest.(check int) "or" 2 (Locator.or_ (Page.get_by_role page `Heading) (Page.locator page "#name") |> Locator.count);
    Alcotest.(check int) "visible only" 0 (Page.locator page "#hidden" |> Locator.visible |> Locator.count);
    Alcotest.(check int) "locator options" 1 (Page.locator page "li" ~has_text_regex:"/^apple$/i" |> Locator.count);
    Alcotest.(check bool) "equal" true (Locator.equal (Page.locator page "li") (Page.locator page "li"));
    (* The conditions given all have to hold. *)
    Alcotest.(check (list string)) "text and pattern" [ "Banana ripe" ] (Page.locator page "li" ~has_text:"a" ~has_text_regex:"/^b/i" |> Locator.all_inner_texts);
    Alcotest.(check (list string)) "neither text nor pattern" [ "Cherry" ]
        (Locator.filter ~has_not_text:"apple" ~has_not_text_regex:"/^b/i" items |> Locator.all_inner_texts)

let test_reading _ page =
    Page.set_content page form;
    let name = Page.locator page "#name" in
    Alcotest.(check (option string)) "attribute" (Some "Your name") (Locator.get_attribute "placeholder" name);
    Alcotest.(check (option string)) "absent attribute" None (Locator.get_attribute "nope" name);
    Alcotest.(check (option string)) "text content includes hidden text" (Some "Hidden text") (Page.locator page "#hidden" |> Locator.text_content);
    Alcotest.(check string) "inner html" "Banana <b>ripe</b>" (Page.locator page "li" |> Locator.nth 1 |> Locator.inner_html);
    Alcotest.(check bool) "visible" true (Locator.is_visible name);
    Alcotest.(check bool) "hidden" true (Page.locator page "#hidden" |> Locator.is_hidden);
    Alcotest.(check bool) "a missing element is hidden, not an error" true (Page.locator page "#missing" |> Locator.is_hidden);
    Alcotest.(check bool) "enabled" true (Locator.is_enabled name && Locator.is_editable name);
    Alcotest.(check bool) "disabled" true (Page.get_by_role page `Button ~name:"Disabled" |> Locator.is_disabled);
    Alcotest.(check bool) "checked" true (Page.locator page "[value=free]" |> Locator.is_checked);
    (match Locator.bounding_box name with
    | Some box -> Alcotest.(check bool) "bounding box" true (box.width > 10. && box.height > 5. && box.x >= 0.)
    | None -> Alcotest.fail "no bounding box");
    Alcotest.(check bool) "no box for hidden elements" true (Page.locator page "#hidden" |> Locator.bounding_box = None);
    Alcotest.check js "evaluate_all" (Js.Number 3.) (Page.locator page "li" |> Locator.evaluate_all "items => items.length");
    Alcotest.(check string) "selector text" "#name" (Locator.to_string name |> fun s -> String.sub s (String.length s - 5) 5);
    Alcotest.(check bool) "its page" true (Page.equal (Locator.page name) page)

let test_actions _ page =
    Page.set_content page form;
    let name = Page.get_by_label page "Name" in
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
    Page.get_by_role page `Button ~name:"Submit" |> Locator.click;
    Alcotest.(check string) "click" "submitted Grace" (Page.locator page "#out" |> Locator.inner_text);
    let terms = Page.get_by_label page "Accept terms" in
    Locator.check terms;
    Alcotest.(check bool) "check" true (Locator.is_checked terms);
    Locator.uncheck terms;
    Locator.set_checked true terms;
    Alcotest.(check bool) "set_checked" true (Locator.is_checked terms);
    Page.get_by_label page "Pro" |> Locator.check;
    Alcotest.(check string) "radio" "pro" (eval_string "document.querySelector('[name=plan]:checked').value" page);
    let colour = Page.locator page "#colour" in
    Alcotest.(check (list string)) "select by value and label" [ "r"; "b" ] (Locator.select_option [ `Value "r"; `Label "Blue" ] colour);
    Alcotest.(check (list string)) "select by index" [ "g" ] (Locator.select_option [ `Index 1 ] colour);
    let comment = Page.get_by_label page "Comment" in
    Locator.focus comment;
    Alcotest.(check string) "focus" "TEXTAREA" (eval_string "document.activeElement.tagName" page);
    Locator.blur comment;
    Alcotest.(check string) "blur" "BODY" (eval_string "document.activeElement.tagName" page);
    Locator.fill "some text" comment;
    Locator.select_text comment;
    Alcotest.(check string) "select_text" "some text" (eval_string "getSelection().toString()" page);
    ignore (Page.evaluate page "document.querySelector('h1').addEventListener('click', e => { window.clicked = e.clientX })");
    Page.get_by_role page `Heading |> Locator.dispatch_event "click" ~event_init:(Js.obj [ "clientX", Js.int 7 ]);
    Alcotest.(check int) "dispatch_event" 7 (eval_int "window.clicked" page)

let test_mouse_actions _ page =
    Page.set_content page
        {|<style>div { width: 100px; height: 100px; margin: 20px; background: silver }</style>
          <div id="a" draggable="true" ondragstart="event.dataTransfer.setData('text', 'a')">A</div>
          <div id="b" ondragover="event.preventDefault()" ondrop="this.textContent = 'dropped ' + event.dataTransfer.getData('text')">B</div>
          <div id="c">C</div>
          <script>
            window.log = [];
            const c = document.querySelector('#c');
            for (const type of ['mouseenter', 'click', 'dblclick', 'contextmenu'])
              c.addEventListener(type, e => { e.preventDefault(); window.log.push(type + (e.shiftKey ? '+shift' : '') + '@' + e.offsetX + ',' + e.offsetY) });
          </script>|};
    let c = Page.locator page "#c" in
    Locator.hover c;
    Locator.click ~position:(10., 20.) ~modifiers:[ `Shift ] c;
    Locator.click ~button:`Right c;
    Locator.dblclick ~position:(1., 1.) c;
    Alcotest.(check (list string)) "events"
        [ "mouseenter@50,50"; "click+shift@10,20"; "contextmenu@50,50"; "click@1,1"; "click@1,1"; "dblclick@1,1" ]
        (Page.evaluate page "window.log" |> Js.to_list Js.to_string);
    Locator.drag_to ~target:(Page.locator page "#b") (Page.locator page "#a");
    Alcotest.(check string) "drag and drop" "dropped a" (Page.locator page "#b" |> Locator.inner_text);
    Locator.click ~trial:true c;
    Alcotest.(check int) "a trial run does not click" 3 (eval_int "window.log.filter(entry => entry.startsWith('click')).length" page);
    (* What is out of sight is scrolled to, unless that is declined. *)
    Page.set_content page {|<div style="height: 3000px"></div><button onclick="window.pressed = (window.pressed || 0) + 1">Far down</button>|};
    let button = Page.get_by_role page `Button in
    let error = failure "not scrolling" (fun () -> Locator.click ~scroll:`None ~timeout:300. button) in
    Alcotest.check error_kind "is to wait for somebody else to" Error.Timeout error.kind;
    check_contains "and says so" ~sub:"element is outside of the viewport" error.message;
    Locator.click button;
    Locator.click ~scroll:`None button;
    Alcotest.(check int) "within the viewport there is nothing to scroll" 2 (eval_int "window.pressed" page)

let test_waiting_and_strictness _ page =
    Page.set_content page {|<button>One</button><button>Two</button><div id="late" style="display: none">Late</div>|};
    let error = failure "two matches" (fun () -> Page.get_by_role page `Button |> Locator.click) in
    check_contains "strict mode violation" ~sub:"strict mode violation" error.message;
    check_contains "which names the candidates" ~sub:"get_by_role(\"button\", name=\"One\")" error.message;
    (* Actions wait for the element to become actionable. *)
    ignore (Page.evaluate page "setTimeout(() => { document.querySelector('#late').style.display = 'block' }, 150)");
    let late = Page.locator page "#late" in
    Locator.click late;
    ignore (Page.evaluate page "setTimeout(() => document.querySelector('#late').remove(), 100)");
    Locator.wait_for ~state:`Detached late;
    let error = failure "never appears" (fun () -> Locator.click ~timeout:250. late) in
    Alcotest.check error_kind "timeout" Error.Timeout error.kind;
    check_contains "what was waited for" ~sub:"waiting for locator(\"#late\")" error.message;
    check_failure "wait_for times out too" ~kind:Timeout (fun () -> Locator.wait_for ~timeout:100. late);
    (* Default timeouts: the page's overrides the context's. *)
    BrowserContext.set_default_timeout (Page.context page) 150.;
    check_failure "context default" ~message:"Timeout 150ms" (fun () -> Locator.click late);
    Page.set_default_timeout page 100.;
    check_failure "page default" ~message:"Timeout 100ms" (fun () -> Locator.click late)

(* An overlay that gets in the way of an action is cleared away by a handler. *)
let test_locator_handlers _ page =
    Page.set_content page
        {|<button id="target" onclick="window.clicks = (window.clicks || 0) + 1">Target</button>
          <div id="overlay" style="position: fixed; inset: 0; background: white"><button onclick="this.parentElement.style.display = 'none'">Dismiss</button></div>|};
    let target = Page.locator page "#target" in
    let cover () = ignore (Page.evaluate page "document.querySelector('#overlay').style.display = 'block'") in
    let calls = ref 0 in
    let dismiss overlay =
        incr calls;
        Locator.click (Locator.get_by_role `Button overlay)
    in
    let handling = Page.add_locator_handler page (Page.locator page "#overlay") dismiss in
    Locator.click target;
    Alcotest.(check (pair int int)) "the handler cleared the way" (1, 1) (!calls, eval_int "window.clicks" page);
    cover ();
    Locator.click target;
    Alcotest.(check (pair int int)) "each time" (2, 2) (!calls, eval_int "window.clicks" page);
    Disposable.dispose handling;
    Disposable.dispose handling;
    cover ();
    check_failure "without the handler the overlay is in the way" ~kind:Timeout (fun () -> Locator.click ~timeout:300. target);
    Alcotest.(check int) "and the handler is not called" 2 !calls;
    let handling = Page.add_locator_handler page ~times:1 (Page.locator page "#overlay") dismiss in
    Locator.click target;
    cover ();
    check_failure "a handler for one time is gone after it" ~kind:Timeout (fun () -> Locator.click ~timeout:300. target);
    Alcotest.(check (pair int int)) "it was called once" (3, 3) (!calls, eval_int "window.clicks" page);
    Disposable.dispose handling;
    Page.set_content page {|<iframe srcdoc="<p>inner</p>"></iframe>|};
    let frame = List.nth (Page.frames page) 1 in
    Alcotest.check_raises "the locator must be of the main frame" (Invalid_argument "Playwright: the locator must belong to the main frame of this page")
        (fun () -> ignore (Page.add_locator_handler page (Frame.locator frame "p") ignore))

(* A handle is for what locators cannot do: passing the element to JavaScript, and finding its frame. *)
let test_element_handles _ page =
    Page.set_content page form;
    let element = Locator.element_handle (Page.locator page "#name") in
    Alcotest.check js "as an argument" (Js.String "name") (Page.evaluate page "element => element.id" ~arg:(Js.Handle (ElementHandle.as_js_handle element)));
    Alcotest.check js "evaluated on" (Js.String "INPUT") (ElementHandle.evaluate element "element => element.tagName");
    Alcotest.(check bool) "owner frame" true (Option.equal Frame.equal (ElementHandle.owner_frame element) (Some (Page.main_frame page)));
    Alcotest.(check bool) "an input holds no frame" true (Option.is_none (ElementHandle.content_frame element));
    ElementHandle.dispose element;
    check_failure "disposed" (fun () -> ElementHandle.evaluate element "element => element.id");
    check_failure "several elements" ~message:"strict mode violation" (fun () -> Locator.element_handle (Page.locator page "li"));
    check_failure "no element" ~kind:Timeout (fun () -> Locator.element_handle ~timeout:100. (Page.locator page "#missing"))

(* What came with Playwright 1.6x: references into snapshots, normalized locators, and so on. *)
let test_references _ page =
    Page.set_content page
        {|<table><tr><td>a1</td><td>b1</td><td>c1</td></tr><tr><td>a2</td><td>b2</td><td>c2</td></tr></table>
          <button>Submit</button> <input aria-label="Amount" value="12">|};
    let third = Page.get_by_role page `Cell |> Locator.nth 2 |> Locator.within ~outer:(Page.get_by_role page `Row) in
    Alcotest.(check (list string)) "the third cell of every row" [ "c1"; "c2" ] (Locator.all_inner_texts third);
    let button = Page.get_by_role page `Button in
    let name = {|The "submit" >> internal:describe="button"|} in
    Alcotest.(check (option string)) "not described" None (Locator.description button);
    Alcotest.(check (option string)) "described" (Some name) (Locator.description (Locator.describe name button));
    Alcotest.(check (option string)) "the description of the last part only" None (Locator.description (Locator.describe name button |> Locator.first));
    Alcotest.(check string) "a described locator still works" "Submit" (Locator.inner_text (Locator.describe name button));
    (* A snapshot for machines gives every element a reference, which finds the element again. *)
    let snapshot = Page.aria_snapshot page ~mode:`Ai in
    let reference =
        let line = List.find (contains ~sub:{|button "Submit"|}) (String.split_on_char '\n' snapshot) in
        let start = Option.get (String.index_opt line '=') + 1 in
        String.sub line start (String.index_from line start ']' - start)
    in
    let by_reference = Page.get_by_ref page reference in
    Alcotest.(check string) "by reference" "Submit" (Locator.inner_text by_reference);
    Alcotest.(check string) "normalized" (Locator.to_string (Page.get_by_role page `Button ~name:"Submit")) (Locator.to_string (Locator.normalize by_reference));
    check_failure "nothing to normalize" ~message:"No element matching" (fun () -> Locator.normalize (Page.locator page "#absent"));
    let rec roles : Yojson.Safe.t -> string list = function
        | `Assoc fields ->
            (match List.assoc_opt "role" fields with Some (`String role) -> [ role ] | _ -> [])
            @ (match List.assoc_opt "children" fields with Some (`List children) -> List.concat_map roles children | _ -> [])
        | `List items -> List.concat_map roles items
        | _ -> []
    in
    Alcotest.(check bool) "the snapshot as JSON" true (List.mem "button" (roles (Page.aria_snapshot_json page)));
    Alcotest.(check (list string)) "of an element" [ "button" ] (roles (Locator.aria_snapshot_json button));
    (* Waiting for something about an element. *)
    let input = Page.get_by_label page "Amount" in
    ignore (Page.evaluate page "setTimeout(() => document.querySelector('input').value = '1234', 50)");
    Locator.wait_for_function "(input, length) => input.value.length >= length" ~arg:(Js.int 4) input;
    Alcotest.(check string) "waited for the element" "1234" (Locator.input_value input);
    check_failure "which may not come" ~kind:Timeout (fun () -> Locator.wait_for_function ~timeout:100. "input => input.value === 'never'" input);
    (* Marks are put on elements and taken off again. *)
    let mark = Locator.highlight button in
    Page.hide_highlight page;
    Disposable.dispose mark

let test_drop t page =
    Page.set_content page
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
          </script>|};
    let zone = Page.locator page "#zone" in
    let dropped () =
        ignore (Page.wait_for_function page "window.dropped");
        let value = Page.evaluate page "(() => { const d = window.dropped; window.dropped = undefined; return d })()" in
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
    Page.set_content page {|<input type="file" id="one"><input type="file" id="many" multiple>|};
    let describe id =
        Page.evaluate page
            (Printf.sprintf
                 "Promise.all([...document.querySelector('#%s').files].map(async f => f.name + ':' + f.type + ':' + await f.text())).then(l => l.join('|'))" id)
        |> Js.to_string
    in
    let a = scratch_file t "a.txt" and b = scratch_file t "b.json" in
    write_file a "alpha";
    write_file b "{}";
    Page.locator page "#one" |> Locator.set_input_files [ a ];
    Alcotest.(check string) "a file from disk" (Filename.basename a ^ ":text/plain:alpha") (describe "one");
    Page.locator page "#many" |> Locator.set_input_files [ a; b ];
    Alcotest.(check string) "several files" (Printf.sprintf "%s:text/plain:alpha|%s:application/json:{}" (Filename.basename a) (Filename.basename b)) (describe "many");
    Page.locator page "#one" |> Locator.set_input_payloads [ { name = "memo.csv"; mime_type = Some "text/csv"; buffer = "x,y\n1,2" } ];
    Alcotest.(check string) "a file from memory" "memo.csv:text/csv:x,y\n1,2" (describe "one");
    Page.locator page "#one" |> Locator.set_input_files [];
    Alcotest.(check string) "cleared" "" (describe "one");
    check_failure "several files for a single input" ~message:"Non-multiple file input" (fun () -> Page.locator page "#one" |> Locator.set_input_files [ a; b ]);
    let chooser = Page.expect_event page Page.File_chooser (fun () -> Locator.click (Page.locator page "#many")) in
    Alcotest.(check bool) "multiple" true (FileChooser.is_multiple chooser);
    Alcotest.(check bool) "its page" true (Page.equal (FileChooser.page chooser) page);
    FileChooser.set_files chooser [ b ];
    Alcotest.(check string) "through the file chooser" (Filename.basename b ^ ":application/json:{}") (describe "many")

let test_expect _ page =
    Page.set_content page form;
    let heading = Page.get_by_role page `Heading and name = Page.locator page "#name" and terms = Page.locator page "#terms" in
    Expect.to_be_visible heading;
    Expect.to_be_hidden (Page.locator page "#hidden");
    Expect.to_be_attached (Page.locator page "#hidden");
    Expect.Not.to_be_attached (Page.locator page "#missing");
    Expect.to_have_text "Sign up" heading;
    Expect.to_have_text ~ignore_case:true "sign   UP" heading;
    Expect.to_have_text_regex "/^sign/i" heading;
    Expect.to_contain_text "up" heading;
    Expect.Not.to_have_text "Sign" heading;
    Expect.to_have_texts [ "Apple"; "Banana ripe"; "Cherry" ] (Page.locator page "li");
    Expect.to_contain_texts [ "App"; "Ban"; "Che" ] (Page.locator page "li");
    Expect.to_have_count 3 (Page.locator page "li");
    Expect.to_be_enabled name;
    Expect.to_be_editable name;
    Expect.to_be_empty name;
    Expect.to_be_disabled (Page.get_by_text page "Disabled");
    Expect.to_have_attribute "placeholder" ~value:"Your name" name;
    Expect.to_have_attribute_regex "placeholder" ~value:"/name$/" name;
    Expect.to_have_attribute_present "data-testid" name;
    Expect.Not.to_have_attribute_present "disabled" name;
    Expect.to_have_id "name" name;
    Expect.to_have_role `Textbox name;
    Expect.to_have_accessible_name "Name" name;
    Expect.Not.to_have_accessible_error_message "A name is required" name;
    let complain =
        {|input => {
            document.body.insertAdjacentHTML('beforeend', '<span id="complaint">A name  is required</span>');
            input.setAttribute('aria-invalid', 'true');
            input.setAttribute('aria-errormessage', 'complaint');
        }|}
    in
    ignore (Locator.evaluate complain name);
    Expect.to_have_accessible_error_message "A name is required" name;
    Expect.to_have_accessible_error_message_regex "/required$/" name;
    ignore (Locator.evaluate "input => { input.removeAttribute('aria-invalid'); document.querySelector('#complaint').remove(); }" name);
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
    ignore (Locator.select_option [ `Value "r"; `Value "g" ] (Page.locator page "#colour"));
    Expect.to_have_values [ "r"; "g" ] (Page.locator page "#colour");
    Expect.to_have_css "display" ~value:"none" (Page.locator page "#hidden");
    Expect.to_be_in_viewport heading;
    Expect.to_have_title page "Form";
    Expect.to_have_title_regex page "/^F/";
    Expect.to_have_url page "about:blank";
    Expect.Not.to_have_url page "**/other";
    Expect.to_match_aria_snapshot
        {|
          - list:
            - listitem: Apple
            - listitem: /Banana/
            - listitem: Cherry
        |}
        (Page.locator page "ul")

let test_expect_waits_and_fails t page =
    Page.set_content page {|<p id="status">loading</p><ul><li>one</li></ul>|};
    ignore (Page.evaluate page "setTimeout(() => { document.querySelector('#status').textContent = 'ready' }, 150)");
    let status = Page.locator page "#status" in
    Expect.to_have_text "ready" status;
    let error = failure "wrong text" (fun () -> Expect.to_have_text ~timeout:200. "done" status) in
    Alcotest.check error_kind "kind" Error.Assertion_failed error.kind;
    check_contains "expectation" ~sub:{|expected to have text "done"|} error.message;
    check_contains "what was found" ~sub:{|Received: "ready"|} error.message;
    check_contains "call log" ~sub:"Call log:" error.message;
    let error = failure "negated" (fun () -> Expect.Not.to_be_visible ~timeout:100. status) in
    check_contains "negated expectation" ~sub:"expected not to be visible" error.message;
    let error = failure "missing element" (fun () -> Expect.to_be_visible ~timeout:100. (Page.locator page "#nowhere")) in
    Alcotest.check error_kind "a missing element is an assertion failure too" Error.Assertion_failed error.kind;
    let error = failure "count" (fun () -> Expect.to_have_count ~timeout:100. 2 (Page.locator page "li")) in
    check_contains "count received" ~sub:"Received: 1" error.message;
    let error = failure "snapshot" (fun () -> Expect.to_match_aria_snapshot ~timeout:100. "- list:\n  - listitem: two" (Page.locator page "ul")) in
    check_contains "snapshot received" ~sub:"- listitem: one" error.message;
    (* The default timeout is a setting. *)
    Expect.set_default_timeout t.pw 100.;
    Fun.protect
        ~finally:(fun () -> Expect.set_default_timeout t.pw 5000.)
        (fun () -> check_failure "default timeout" ~kind:Assertion_failed ~message:"100ms" (fun () -> Expect.to_have_text "never" status))

let tests t =
    [ "locators",
      [ page_case t "queries" (test_queries t);
        page_case t "reading" (test_reading t);
        page_case t "actions" (test_actions t);
        page_case t "mouse actions" (test_mouse_actions t);
        page_case t "waiting and strictness" (test_waiting_and_strictness t);
        page_case t "locator handlers" (test_locator_handlers t);
        page_case t "element handles" (test_element_handles t);
        page_case t "references, descriptions and snapshots" (test_references t);
        page_case t "uploads" (test_uploads t);
        page_case t "drop" (test_drop t) ];
      "expect", [ page_case t "assertions" (test_expect t); page_case t "waiting and failing" (test_expect_waits_and_fails t) ] ]
