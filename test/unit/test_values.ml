(* JavaScript values, selectors and URL patterns. *)

open Internal

(* {1 JavaScript values} *)

let wire value = (Js.to_argument value).value
let js = Alcotest.testable (fun ppf value -> Format.pp_print_string ppf (Js.show value)) ( = )

let test_js_wire_format () =
    let check what expected value = Alcotest.check json what (Json.of_string expected) (wire value) in
    check "string" {|{"s":"x"}|} (Js.string "x");
    check "bool" {|{"b":true}|} (Js.bool true);
    check "int" {|{"n":7}|} (Js.int 7);
    check "float" {|{"n":1.5}|} (Js.float 1.5);
    check "null" {|{"v":"null"}|} Js.null;
    check "undefined" {|{"v":"undefined"}|} Js.undefined;
    check "NaN" {|{"v":"NaN"}|} (Js.float Float.nan);
    check "Infinity" {|{"v":"Infinity"}|} (Js.float Float.infinity);
    check "-Infinity" {|{"v":"-Infinity"}|} (Js.float Float.neg_infinity);
    check "-0" {|{"v":"-0"}|} (Js.float (-0.));
    check "date" {|{"d":"2024-02-29T12:00:00.000Z"}|} (Js.Date "2024-02-29T12:00:00.000Z");
    check "bigint" {|{"bi":"12345678901234567890"}|} (Js.Bigint "12345678901234567890");
    check "url" {|{"u":"https://example.com/"}|} (Js.Url "https://example.com/");
    check "regexp" {|{"r":{"p":"a+","f":"gi"}}|} (Js.Regexp { source = "a+"; flags = "gi" });
    check "typed array" {|{"ta":{"b":"AAH/","k":"ui8"}}|} (Js.Typed_array { kind = `Ui8; bytes = "\000\001\255" });
    let member name = function `Assoc fields -> List.assoc_opt name fields | _ -> None in
    Alcotest.(check (option json)) "array items" (Some (Json.of_string {|[{"n":1},{"n":2}]|})) (member "a" (wire (Js.list Js.int [ 1; 2 ])));
    Alcotest.(check (option json)) "object entries"
        (Some (Json.of_string {|[{"k":"k","v":{"s":"v"}}]|}))
        (member "o" (wire (Js.obj [ "k", Js.string "v" ])))

(* What a page sends back refers to an object it has serialized before by its id. *)
let test_js_references () =
    let shared = Json.of_string {|{"a":[{"o":[{"k":"x","v":{"n":1}}],"id":2},{"ref":2}],"id":1}|} in
    Alcotest.check js "an object reached twice" (Js.Array [ Js.Object [ "x", Js.Number 1. ]; Js.Object [ "x", Js.Number 1. ] ]) (Js.of_wire shared);
    let cyclic = Json.of_string {|{"o":[{"k":"self","v":{"ref":1}},{"k":"n","v":{"n":2}}],"id":1}|} in
    Alcotest.check js "a cycle is cut" (Js.Object [ "self", Js.Undefined; "n", Js.Number 2. ]) (Js.of_wire cyclic)

let test_js_roundtrip () =
    let values =
        [ Js.Undefined; Js.Null; Js.Bool false; Js.Number 0.; Js.Number (-12.25); Js.Number 9007199254740991.; Js.Number Float.infinity;
          Js.String ""; Js.String "caf\xC3\xA9 \"quoted\"\n"; Js.Bigint "-5"; Js.Date "1970-01-01T00:00:00.000Z"; Js.Url "about:blank";
          Js.Regexp { source = "^a|b$"; flags = "" }; Js.Error { name = "TypeError"; message = "boom"; stack = "TypeError: boom\n  at x" };
          Js.Array []; Js.Object [];
          Js.Object [ "list", Js.Array [ Js.Number 1.; Js.Array [ Js.Null ]; Js.Object [ "deep", Js.Bool true ] ]; "", Js.String "empty key" ];
          Js.Typed_array { kind = `F64; bytes = String.make 16 '\001' } ]
    in
    List.iter (fun value -> Alcotest.check js (Js.show value) value (Js.of_wire (wire value))) values;
    (match Js.of_wire (wire (Js.Number Float.nan)) with
    | Js.Number n -> Alcotest.(check bool) "NaN" true (Float.is_nan n)
    | other -> Alcotest.failf "NaN decoded as %s" (Js.show other));
    match Js.of_wire (wire (Js.Number (-0.))) with
    | Js.Number n -> Alcotest.(check bool) "negative zero keeps its sign" true (1. /. n = Float.neg_infinity)
    | other -> Alcotest.failf "-0 decoded as %s" (Js.show other)

let test_js_json () =
    let document = Json.of_string {|{"a":[1,2.5,null,true,-3],"b":"x","c":{},"d":[]}|} in
    let value =
        Js.Object
            [ "a", Js.Array [ Js.Number 1.; Js.Number 2.5; Js.Null; Js.Bool true; Js.Number (-3.) ]; "b", Js.String "x"; "c", Js.Object [];
              "d", Js.Array [] ]
    in
    Alcotest.check js "of_json" value (Js.of_json document);
    Alcotest.check json "to_json gives it back" document (Js.to_json value);
    Alcotest.(check bool) "an integral number is an integer" true (Js.to_json (Js.Number 2.) = `Int 2 && Js.to_json (Js.Number 2.5) = `Float 2.5);
    (* [of_json] gives every number back, which [=] cannot tell for the sign of a zero. *)
    let comes_back f = match Js.of_json (Js.to_json (Js.Number f)) with Js.Number g -> Int64.equal (Int64.bits_of_float f) (Int64.bits_of_float g) | _ -> false in
    List.iter
        (fun f -> Alcotest.(check bool) (Printf.sprintf "%h comes back" f) true (comes_back f))
        [ -0.; 0.; 1.; -1.; 0.1; -2.5; 9007199254740991.; -9007199254740991.; 9007199254740992.; 1e300; -1e300; Float.min_float; 4.9e-324; Float.max_float ];
    Alcotest.(check string) "negative zero is written with its sign" "-0.0" (Yojson.Safe.to_string (Js.to_json (Js.Number (-0.))));
    (* Nothing is turned into something else: what JSON has no notion of is refused, and the message says where it is. *)
    let refused what place value =
        Alcotest.(check string) what (Printf.sprintf "Js.to_json: %s, which JSON has no notion of" place) (failure what (fun () -> Js.to_json value)).message
    in
    refused "by itself" "value is undefined" Js.Undefined;
    refused "in an object" "value.due is a date" (Js.Object [ "ok", Js.Null; "due", Js.Date "2020-01-01T00:00:00.000Z" ]);
    refused "in an array" "value.items[1] is NaN" (Js.Object [ "items", Js.Array [ Js.Number 1.; Js.Number Float.nan ] ]);
    refused "under a key that is no identifier" {|value["a b"][0].n is a bigint|} (Js.Object [ "a b", Js.Array [ Js.Object [ "n", Js.Bigint "1" ] ] ]);
    refused "the first one" "value[0] is undefined" (Js.Array [ Js.Undefined; Js.Url "about:blank" ]);
    List.iter
        (fun (what, value) -> refused what ("value is " ^ what) value)
        [ "-Infinity", Js.Number Float.neg_infinity; "a URL", Js.Url "https://example.com/"; "a regular expression", Js.Regexp { source = "ab+c"; flags = "gi" };
          "an error", Js.Error { name = "TypeError"; message = "no"; stack = "at x" }; "a typed array", Js.Typed_array { kind = `Ui8; bytes = "\001\002\003" } ];
    (* Integers that a JavaScript number would round. *)
    let safe = 9007199254740991 in
    Alcotest.check js "the largest safe integer" (Js.Number 9007199254740991.) (Js.int safe);
    Alcotest.check js "and the smallest" (Js.Number (-9007199254740991.)) (Js.int (-safe));
    List.iter
        (fun unsafe ->
            match Js.int unsafe with
            | exception Invalid_argument message -> check_contains "says which" ~sub:(string_of_int unsafe) message
            | value -> Alcotest.failf "Js.int %d is %s" unsafe (Js.show value))
        [ safe + 1; -safe - 1; max_int ];
    Alcotest.check js "of_json, safe" (Js.Number 9007199254740991.) (Js.of_json (`Int safe));
    Alcotest.check js "of_json, beyond" (Js.Bigint "9007199254740993") (Js.of_json (`Int (safe + 2)));
    Alcotest.check js "of_json, beyond OCaml's" (Js.Bigint "12345678901234567890") (Js.of_json (`Intlit "12345678901234567890"));
    (* The value decides, not the way Yojson carries it. *)
    Alcotest.check js "of_json, a literal within" (Js.Number (-9007199254740991.)) (Js.of_json (`Intlit "-9007199254740991"));
    Alcotest.check js "of_json, a literal just beyond" (Js.Bigint "9007199254740992") (Js.of_json (`Intlit "9007199254740992"))

let test_js_accessors () =
    let value = Js.obj [ "name", Js.string "Ada"; "age", Js.int 36; "tags", Js.list Js.string [ "a"; "b" ]; "nick", Js.null ] in
    Alcotest.(check string) "member string" "Ada" (Js.member "name" value |> Js.to_string);
    Alcotest.(check int) "member int" 36 (Js.member "age" value |> Js.to_int);
    Alcotest.(check (list string)) "list" [ "a"; "b" ] (Js.member "tags" value |> Js.to_list Js.to_string);
    Alcotest.(check (option string)) "null option" None (Js.member "nick" value |> Js.to_option Js.to_string);
    Alcotest.(check (option string)) "missing member is undefined" None (Js.member "missing" value |> Js.to_option Js.to_string);
    Alcotest.(check bool) "is_nullish" true (Js.is_nullish Js.undefined && Js.is_nullish Js.null && not (Js.is_nullish (Js.int 0)));
    Alcotest.(check (list string)) "assoc keys" [ "name"; "age"; "tags"; "nick" ] (List.map fst (Js.to_assoc value));
    let mismatch what f = check_contains what ~sub:"Expected the JavaScript value to be" (failure what f).message in
    mismatch "string as int" (fun () -> Js.to_int (Js.string "1"));
    mismatch "fraction as int" (fun () -> Js.to_int (Js.float 1.5));
    mismatch "number as string" (fun () -> Js.to_string (Js.int 1));
    mismatch "member of a non-object" (fun () -> Js.member "x" (Js.int 1));
    Alcotest.(check string) "show" {|{a: 1, b: [true, null, "x"], c: undefined}|}
        (Js.show (Js.obj [ "a", Js.int 1; "b", Js.Array [ Js.bool true; Js.null; Js.string "x" ]; "c", Js.undefined ]))

(* {1 Selectors}

   The expected strings are what the official clients produce for the same queries; the driver
   parses them, so they have to agree exactly. *)

let test_selectors_by_text () =
    let text s = Selector.Text s and regex s = Selector.Regex s in
    Alcotest.(check string) "text" {|internal:text="Hello"i|} (Selector.by_text (text "Hello"));
    Alcotest.(check string) "exact text" {|internal:text="Hello"s|} (Selector.by_text ~exact:true (text "Hello"));
    Alcotest.(check string) "text with quotes" {|internal:text="say \"hi\""i|} (Selector.by_text (text {|say "hi"|}));
    Alcotest.(check string) "regex" {|internal:text=/^Hel+o$/i|} (Selector.by_text (regex "/^Hel+o$/i"));
    Alcotest.(check string) "label" {|internal:label="Name"i|} (Selector.by_label (text "Name"));
    Alcotest.(check string) "placeholder" {|internal:attr=[placeholder="Search"i]|} (Selector.by_placeholder (text "Search"));
    Alcotest.(check string) "alt text" {|internal:attr=[alt="Logo"s]|} (Selector.by_alt_text ~exact:true (text "Logo"));
    Alcotest.(check string) "title" {|internal:attr=[title="Close"i]|} (Selector.by_title (text "Close"));
    Alcotest.(check string) "test id" {|internal:testid=[data-testid="submit"s]|} (Selector.by_test_id ~attribute:"data-testid" (text "submit"));
    Alcotest.(check string) "custom test id attribute" {|internal:testid=[data-qa="submit"s]|} (Selector.by_test_id ~attribute:"data-qa" (text "submit"))

let test_selectors_by_role () =
    let text s = Selector.Text s in
    Alcotest.(check string) "role" "internal:role=button" (Selector.by_role "button");
    Alcotest.(check string) "name" {|internal:role=button[name="Sign in"i]|} (Selector.by_role ~name:(text "Sign in") "button");
    Alcotest.(check string) "exact name" {|internal:role=button[name="Sign in"s]|} (Selector.by_role ~name:(text "Sign in") ~exact:true "button");
    Alcotest.(check string) "name regex" {|internal:role=link[name=/docs?/i]|} (Selector.by_role ~name:(Selector.Regex "/docs?/i") "link");
    Alcotest.(check string) "states" {|internal:role=checkbox[checked=true][disabled=false]|} (Selector.by_role ~checked:true ~disabled:false "checkbox");
    Alcotest.(check string) "level" {|internal:role=heading[level=2]|} (Selector.by_role ~level:2 "heading");
    Alcotest.(check string) "hidden and pressed" {|internal:role=button[include-hidden=true][pressed=true]|}
        (Selector.by_role ~include_hidden:true ~pressed:true "button")

let test_selector_combinators () =
    Alcotest.(check string) "join" {|div >> internal:text="x"i >> nth=0|} (Selector.join [ "div"; Selector.by_text (Text "x"); Selector.nth 0 ]);
    Alcotest.(check string) "last" "nth=-1" (Selector.nth (-1));
    Alcotest.(check string) "has text" {|internal:has-text="Ada"i|} (Selector.has_text (Text "Ada"));
    Alcotest.(check string) "has not text" {|internal:has-not-text=/x/|} (Selector.has_not_text (Regex "/x/"));
    Alcotest.(check string) "has" {|internal:has="li >> internal:text=\"a\"i"|} (Selector.has {|li >> internal:text="a"i|});
    Alcotest.(check string) "has not" {|internal:has-not="img"|} (Selector.has_not "img");
    Alcotest.(check string) "and" {|internal:and="button"|} (Selector.and_ "button");
    Alcotest.(check string) "or" {|internal:or="a"|} (Selector.or_ "a");
    Alcotest.(check string) "visible" "visible=true" (Selector.visible true);
    Alcotest.(check string) "frame" "internal:control=enter-frame" Selector.enter_frame;
    let described description = Selector.join [ "button"; Selector.describe description ] in
    Alcotest.(check (option string)) "description" (Some "The button") (Selector.description (described "The button"));
    Alcotest.(check (option string)) "of nothing else" (Some "x") (Selector.description (Selector.describe "x"));
    Alcotest.(check (option string)) "with what looks like one" (Some {|a >> internal:describe="b"|}) (Selector.description (described {|a >> internal:describe="b"|}));
    Alcotest.(check (option string)) "none" None (Selector.description "button");
    Alcotest.(check (option string)) "not the last part" None (Selector.description (Selector.join [ described "The button"; Selector.nth 0 ]));
    Alcotest.(check (option string)) "in the text of another part" None (Selector.description {|internal:text="a >> internal:describe=b"i|});
    Alcotest.(check (pair string string)) "regex literal" ("a/b", "gi") (Selector.parse_regex "/a/b/gi");
    match Selector.parse_regex "no slashes" with
    | _ -> Alcotest.fail "a string that is no regex literal must be rejected"
    | exception Invalid_argument _ -> ()

(* {1 Snapshot templates} *)

let test_unindent () =
    Alcotest.(check string) "common indentation and blank edges are removed" "- list:\n  - listitem: one\n\n  - listitem: two"
        (Expect.unindent "\n        - list:\n          - listitem: one\n\n          - listitem: two\n    ");
    Alcotest.(check string) "nothing to remove" "- heading" (Expect.unindent "- heading")

(* {1 URLs in assertions} *)

let test_resolve_url () =
    let check what expected ?base url = Alcotest.(check string) what expected (Expect.resolve_url ?base url) in
    check "an absolute URL is kept" "https://example.com/a?b#c" ~base:"http://other.test/" "https://example.com/a?b#c";
    check "a bare origin gets its path" "https://example.com/" "https://example.com";
    check "also before a query" "https://example.com/?q=1" "https://example.com?q=1";
    check "other schemes are kept" "about:blank" ~base:"http://localhost:8080" "about:blank";
    check "a data URL is kept" "data:text/html,<p>a/b</p>" "data:text/html,<p>a/b</p>";
    check "an absolute path replaces the path" "http://localhost:8080/checkout" ~base:"http://localhost:8080/app/index.html" "/checkout";
    check "the base may be a bare origin" "http://localhost:8080/checkout" ~base:"http://localhost:8080" "/checkout";
    check "a relative path replaces the last segment" "http://localhost:8080/app/cart" ~base:"http://localhost:8080/app/index.html?x=1" "cart";
    check "relative to a directory" "http://localhost:8080/app/cart" ~base:"http://localhost:8080/app/" "./cart";
    check "relative to a bare origin" "http://localhost:8080/cart" ~base:"http://localhost:8080" "cart";
    check "up one directory" "http://localhost:8080/a/c" ~base:"http://localhost:8080/a/b/" "../c";
    check "not above the root" "http://localhost:8080/c" ~base:"http://localhost:8080/a/b/" "../../../c";
    check "a directory stays one" "http://localhost:8080/a/" ~base:"http://localhost:8080/a/b/" "..";
    check "a query replaces the query" "http://localhost:8080/app?page=2" ~base:"http://localhost:8080/app?page=1#top" "?page=2";
    check "a fragment replaces the fragment" "http://localhost:8080/app?page=1#end" ~base:"http://localhost:8080/app?page=1#top" "#end";
    check "the scheme is inherited" "http://cdn.test/x.js" ~base:"http://localhost:8080/app" "//cdn.test/x.js";
    check "nothing gives the base" "http://localhost:8080/app?page=1" ~base:"http://localhost:8080/app?page=1#top" "";
    check "without a base, a relative URL is kept" "/checkout" "/checkout";
    (* What a browser would change beyond that is left as it was written. *)
    check "nothing is encoded or put in lower case" "HTTP://Example.com:80/a b" "HTTP://Example.com:80/a b"

let tests =
    [ "js",
      [ Alcotest.test_case "wire format" `Quick test_js_wire_format;
        Alcotest.test_case "references" `Quick test_js_references;
        Alcotest.test_case "roundtrip" `Quick test_js_roundtrip;
        Alcotest.test_case "json conversion" `Quick test_js_json;
        Alcotest.test_case "accessors" `Quick test_js_accessors ];
      "selector",
      [ Alcotest.test_case "by text and attributes" `Quick test_selectors_by_text;
        Alcotest.test_case "by role" `Quick test_selectors_by_role;
        Alcotest.test_case "combinators" `Quick test_selector_combinators ];
      "expect", [ Alcotest.test_case "unindent" `Quick test_unindent; Alcotest.test_case "URLs" `Quick test_resolve_url ] ]
