open Playwright

let check name condition =
    if not condition then failwith ("ASSERTION FAILED: " ^ name)

let check_json name expected actual =
    if expected <> actual then
        failwith (Printf.sprintf "%s: expected %s, got %s" name (Yojson.Safe.to_string expected) (Yojson.Safe.to_string actual))

let test name f =
    f ();
    Printf.printf "PASS %s\n%!" name

let serialized json =
    match SerializedValue.of_yojson json with
    | Ok value -> value
    | Error message -> failwith message

let value_fields () =
    let cases = [
        "n", `Int 12, `Float 12.;
        "b", `Bool false, `Bool false;
        "s", `String "text", `String "text";
        "v", `String "null", `Null;
        "d", `String "2025-01-01T00:00:00.000Z", `String "2025-01-01T00:00:00.000Z";
        "u", `String "https://example.com/", `String "https://example.com/";
        "bi", `String "9007199254740993", `String "9007199254740993";
        "e", `Assoc ["m", `String "bad"; "n", `String "Error"; "s", `String "stack"],
            `Assoc ["message", `String "bad"; "name", `String "Error"; "stack", `String "stack"];
        "r", `Assoc ["p", `String "a+"; "f", `String "gi"], `Assoc ["pattern", `String "a+"; "flags", `String "gi"];
        "a", `List [`Assoc ["s", `String "item"]], `List [`String "item"];
        "o", `List [`Assoc ["k", `String "key"; "v", `Assoc ["b", `Bool true]]], `Assoc ["key", `Bool true];
    ] in
    List.iter (fun (key, value, expected) ->
        serialized (`Assoc [key, value]) |> Value.parse_serialized_value |> check_json ("decode " ^ key) expected) cases;
    (* If several fields are present, the first supported field still wins. *)
    let rec check_precedence = function
        | [] -> ()
        | (key, _, expected) :: rest as fields ->
            let json = `Assoc (List.map (fun (key, value, _) -> key, value) fields) in
            serialized json |> Value.parse_serialized_value |> check_json ("precedence " ^ key) expected;
            check_precedence rest
    in
    check_precedence cases

let special_values () =
    let empty = serialized (`Assoc []) in
    let cases = [
        `Null, `Null;
        `Undefined, `Null;
        `Nan, `String "NaN";
        `Inf, `String "Infinity";
        `Minus_inf, `String "-Infinity";
        `Minus_zero, `Float (-0.0);
    ] in
    List.iter (fun (special, expected) ->
        Value.parse_serialized_value { empty with v = Some special; d = Some "ignored" }
        |> check_json "special value before date" expected) cases;
    (match Value.parse_serialized_value { empty with v = Some `Minus_zero } with
    | `Float value -> check "negative zero sign" (Int64.bits_of_float value = Int64.bits_of_float (-0.0))
    | _ -> failwith "negative zero did not decode to a float");
    Value.parse_serialized_value empty |> check_json "empty serialized value" `Null;
    let unsupported = { empty with h = Some 1; id = Some 2; ref = Some 3; ta = Some SerializedValue.Ta.{ b = "AA=="; k = `Ui8 } } in
    Value.parse_serialized_value unsupported |> check_json "unsupported fields" `Null

let value_round_trips () =
    let cases = [
        `Null, `Null;
        `Bool false, `Bool false;
        `String "quotes \" and slashes \\", `String "quotes \" and slashes \\";
        `Int 42, `Float 42.;
        `Intlit "123456", `Float 123456.;
        `Float 1.25, `Float 1.25;
        `List [], `List [];
        `Assoc [], `Assoc [];
        `Assoc ["items", `List [`Int 1; `Bool true; `Null]; "nested", `Assoc ["text", `String "ok"]],
            `Assoc ["items", `List [`Float 1.; `Bool true; `Null]; "nested", `Assoc ["text", `String "ok"]];
    ] in
    List.iter (fun (input, expected) ->
        Value.build_serialized_value input |> Value.parse_serialized_value |> check_json "value round trip" expected;
        let argument = Value.build_serialized_argument input in
        check "arguments have no handles" (argument.handles = [||]);
        Value.parse_serialized_argument argument |> check_json "argument round trip" expected) cases

let selector_helpers () =
    let check_string name expected actual = check name (expected = actual) in
    check_string "empty selector" {|""|} (Locator_utils.escape_for_selector "");
    check_string "escape quotes and backslashes" {|"a\"b\\c"|} (Locator_utils.escape_for_selector {|a"b\c|});
    check_string "preserve UTF-8 and newlines" "\"café\n\"" (Locator_utils.escape_for_selector "café\n");
    check_string "text default" {|internal:text="Hello"i|} (Locator_utils.get_by_text "Hello");
    check_string "text exact" {|internal:text="Hello"s|} (Locator_utils.get_by_text ~exact:true "Hello");
    check_string "role without name" "internal:role=button" (Locator_utils.get_by_role "button");
    check_string "role name" {|internal:role=button[name="Save"i]|} (Locator_utils.get_by_role ~name:"Save" "button");
    check_string "exact role name" {|internal:role=button[name="Save"s]|} (Locator_utils.get_by_role ~name:"Save" ~exact:true "button");
    check_string "label" {|internal:label="Name"i|} (Locator_utils.get_by_label "Name");
    check_string "placeholder" {|internal:attr=[placeholder="Name"s]|} (Locator_utils.get_by_placeholder ~exact:true "Name");
    check_string "alt text" {|internal:attr=[alt="Photo"i]|} (Locator_utils.get_by_alt_text "Photo");
    check_string "title" {|internal:attr=[title="Help"s]|} (Locator_utils.get_by_title ~exact:true "Help");
    check_string "test id" {|internal:testid="a\"b\\c"|} (Locator_utils.get_by_test_id {|a"b\c|})

let locator_helpers () =
    Eio_main.run (fun env ->
        Eio.Time.with_timeout_exn (Eio.Stdenv.clock env) 20. (fun () ->
            Eio.Switch.run (fun sw ->
                let pw = create ~env ~sw () in
                Fun.protect ~finally:(fun () -> destroy pw) (fun () ->
                    let browser = BrowserType.launch ~executable_path:"/usr/bin/chromium" ~headless:true (Playwright.chromium pw) in
                    Fun.protect ~finally:(fun () -> Browser.close browser) (fun () ->
                        let context = Browser.new_context browser in
                        let page    = BrowserContext.new_page context in
                        Page.set_content ~html:{|
                            <ul><li>First</li><li>Second <span>marked</span></li></ul>
                            <div id="box" style="position:absolute;left:10.5px;top:20px;width:100.25px;height:40px"></div>
                        |} page;
                        let rows   = Page.locator ~selector:"li" page in
                        let marker = Page.locator ~selector:"span" page in
                        let box    = Page.locator ~selector:"#box" page in
                        let both   = Locator.filter ~has_text:"Second marked" ~has:marker rows in
                        check "filter without options" ((Locator.filter rows).selector = "li");
                        check "combined filter selector" (both.selector = {|li >> internal:has-text="Second marked" >> internal:has="span"|});
                        check "filter retains frame" (both.frame == rows.frame);
                        check "combined filter matches" (Locator.count both = 1);
                        check "text-only filter" (Locator.count (Locator.filter ~has_text:"First" rows) = 1);
                        check "has-only filter" (Locator.count (Locator.filter ~has:marker rows) = 1);
                        check "nested locator" ((Locator.locator ~selector:"span" rows).selector = "li >> span");
                        check "first" ((Locator.first rows).selector = "li >> nth=0");
                        check "last" ((Locator.last rows).selector = "li >> nth=-1");
                        check "all" (Locator.all rows |> List.map (fun (locator : Locator.t) -> locator.selector) = ["li >> nth=0"; "li >> nth=1"]);
                        let intersect = Locator.and_ rows marker in
                        let union     = Locator.or_ rows marker in
                        check "intersection" (intersect.selector = {|li >> internal:and="span"|} && intersect.frame == rows.frame);
                        check "union" (union.selector = "li, span" && union.frame == rows.frame);
                        Locator.wait_for ~state:`Attached ~timeout:1000. box;
                        (match Locator.bounding_box ~timeout:1000. box with
                        | Some bounds ->
                            check "bounding box" (bounds.x = 10.5 && bounds.y = 20. && bounds.width = 100.25 && bounds.height = 40.)
                        | None -> failwith "missing bounding box"))))))

let () =
    test "serialized value fields and precedence" value_fields;
    test "serialized special and unsupported values" special_values;
    test "serialized value and argument round trips" value_round_trips;
    test "selector escaping and exactness" selector_helpers;
    test "locator composition, waiting and bounding box" locator_helpers
