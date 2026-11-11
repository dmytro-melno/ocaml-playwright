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
    Alcotest.check js "of_json"
        (Js.Object [ "a", Js.Array [ Js.Number 1.; Js.Number 2.5; Js.Null; Js.Bool true ]; "b", Js.String "x" ])
        (Js.of_json (Json.of_string {|{"a":[1,2.5,null,true],"b":"x"}|}));
    Alcotest.check json "to_json"
        (Json.of_string {|{"int":2,"float":2.5,"undefined":null,"nan":null,"date":"2020-01-01T00:00:00.000Z","list":[null,"s"]}|})
        (Js.to_json
             (Js.Object
                  [ "int", Js.Number 2.; "float", Js.Number 2.5; "undefined", Js.Undefined; "nan", Js.Number Float.nan;
                    "date", Js.Date "2020-01-01T00:00:00.000Z"; "list", Js.Array [ Js.Null; Js.String "s" ] ]))

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
    Alcotest.(check (pair string string)) "regex literal" ("a/b", "gi") (Selector.parse_regex "/a/b/gi");
    match Selector.parse_regex "no slashes" with
    | _ -> Alcotest.fail "a string that is no regex literal must be rejected"
    | exception Invalid_argument _ -> ()

(* {1 URL patterns}

   Globs are translated to regular expressions by the driver; these are the shapes it produces. *)

let test_url_regex () =
    let matches source url = Url_regex.matches (Url_regex.parse source) url in
    let images = {|^((.+/)|)([^/]*)\.(png|jpg)$|} in
    Alcotest.(check bool) "**/*.{png,jpg} matches" true (matches images "https://example.com/static/logo.png");
    Alcotest.(check bool) "at the root" true (matches images "logo.jpg");
    Alcotest.(check bool) "other extension" false (matches images "https://example.com/static/logo.gif");
    Alcotest.(check bool) "extension must end the URL" false (matches images "https://example.com/logo.png?x=1");
    let api = {|^https://example\.com/api/([^/]*)$|} in
    Alcotest.(check bool) "one segment" true (matches api "https://example.com/api/users");
    Alcotest.(check bool) "not two segments" false (matches api "https://example.com/api/users/1");
    Alcotest.(check bool) "dot is literal" false (matches api "https://exampleXcom/api/users");
    let anything = {|^https://example\.com/(.*)$|} in
    Alcotest.(check bool) "** crosses segments" true (matches anything "https://example.com/a/b/c?d=e#f");
    Alcotest.(check bool) "empty rest" true (matches anything "https://example.com/");
    Alcotest.(check bool) "escaped metacharacters" true (matches {|^a\?b\+c\$\(\)\[\]\{\}\|\\$|} {|a?b+c$()[]{}|\|});
    Alcotest.(check bool) "anchored at both ends" false (matches {|^b$|} "abc");
    (* Backtracking over nested repetition terminates quickly on a non-match. *)
    Alcotest.(check bool) "no blow-up" false (matches {|^((.+/)|)([^/]*)\.zip$|} (String.concat "/" (List.init 200 (fun _ -> "segment")) ^ ".tar"));
    match Url_regex.parse {|^[a-z]+\d$|} with
    | _ -> Alcotest.fail "unsupported syntax must be refused rather than misinterpreted"
    | exception Url_regex.Unsupported _ -> ()

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
    check "a query replaces the query" "http://localhost:8080/app?page=2" ~base:"http://localhost:8080/app?page=1#top" "?page=2";
    check "a fragment replaces the fragment" "http://localhost:8080/app?page=1#end" ~base:"http://localhost:8080/app?page=1#top" "#end";
    check "the scheme is inherited" "http://cdn.test/x.js" ~base:"http://localhost:8080/app" "//cdn.test/x.js";
    check "nothing gives the base" "http://localhost:8080/app?page=1" ~base:"http://localhost:8080/app?page=1#top" "";
    check "without a base, a relative URL is kept" "/checkout" "/checkout"

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
      "url", [ Alcotest.test_case "regular expressions from globs" `Quick test_url_regex ];
      "expect", [ Alcotest.test_case "unindent" `Quick test_unindent; Alcotest.test_case "URLs" `Quick test_resolve_url ] ]
