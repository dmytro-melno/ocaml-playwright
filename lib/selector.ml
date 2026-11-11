(* Building the selectors behind locators.  Mirrors Playwright's [locatorUtils] and [stringUtils]. *)

(* What a locator matches text against. *)
type text =
    | Text of string
    | Regex of string  (* a JavaScript regular expression literal, such as [/^item \d+$/i] *)

let json_string s = Yojson.Safe.to_string (`String s)

(* Splits a regular expression literal into its source and flags. *)
let parse_regex literal =
    let invalid () =
        invalid_arg (Printf.sprintf "Playwright: %S is not a JavaScript regular expression literal such as /ab+c/i" literal)
    in
    let n = String.length literal in
    if n < 2 || literal.[0] <> '/' then invalid ();
    let last = String.rindex literal '/' in
    if last = 0 then invalid ();
    let flags = String.sub literal (last + 1) (n - last - 1) in
    String.iter (fun c -> if not (String.contains "dgimsuvy" c) then invalid ()) flags;
    String.sub literal 1 (last - 1), flags

(* Renders a regular expression the way the selector parser reads it back: slashes outside
   character classes and quotes are escaped, and [>>] cannot be mistaken for a selector chain. *)
let regex_for_selector literal =
    let source, flags = parse_regex literal in
    let unicode = String.contains flags 'u' || String.contains flags 'v' in
    let buffer = Buffer.create (String.length literal + 8) in
    let n = String.length source in
    let rec go i in_class =
        if i < n then
            match source.[i] with
            | '\\' when i + 1 < n ->
                Buffer.add_char buffer '\\';
                Buffer.add_char buffer source.[i + 1];
                go (i + 2) in_class
            | '[' -> Buffer.add_char buffer '['; go (i + 1) true
            | ']' -> Buffer.add_char buffer ']'; go (i + 1) false
            | '/' when not in_class -> Buffer.add_string buffer "\\/"; go (i + 1) in_class
            (* Unicode mode rejects identity escapes, so there quotes are left alone. *)
            | ('"' | '\'' | '`') as quote when not unicode ->
                Buffer.add_char buffer '\\';
                Buffer.add_char buffer quote;
                go (i + 1) in_class
            | '>' when i + 1 < n && source.[i + 1] = '>' && not unicode -> Buffer.add_string buffer "\\>\\>"; go (i + 2) in_class
            | c -> Buffer.add_char buffer c; go (i + 1) in_class
    in
    go 0 false;
    Printf.sprintf "/%s/%s" (Buffer.contents buffer) flags

let escape_for_text text ~exact =
    match text with
    | Regex literal -> regex_for_selector literal
    | Text text -> json_string text ^ if exact then "s" else "i"

let escape_for_attribute text ~exact =
    match text with
    | Regex literal -> regex_for_selector literal
    | Text text ->
        let buffer = Buffer.create (String.length text + 4) in
        Buffer.add_char buffer '"';
        String.iter (function '\\' -> Buffer.add_string buffer "\\\\" | '"' -> Buffer.add_string buffer "\\\"" | c -> Buffer.add_char buffer c) text;
        Buffer.add_char buffer '"';
        Buffer.add_char buffer (if exact then 's' else 'i');
        Buffer.contents buffer

let by_attribute name ?(exact = false) text = Printf.sprintf "internal:attr=[%s=%s]" name (escape_for_attribute text ~exact)

let by_test_id ~attribute text =
    let attribute = if String.contains attribute ',' then json_string attribute else attribute in
    Printf.sprintf "internal:testid=[%s=%s]" attribute (escape_for_attribute text ~exact:true)

let by_label ?(exact = false) text = "internal:label=" ^ escape_for_text text ~exact
let by_text ?(exact = false) text = "internal:text=" ^ escape_for_text text ~exact
let by_alt_text ?exact text = by_attribute "alt" ?exact text
let by_title ?exact text = by_attribute "title" ?exact text
let by_placeholder ?exact text = by_attribute "placeholder" ?exact text

let by_role ?checked ?disabled ?selected ?expanded ?include_hidden ?level ?name ?description ?(exact = false) ?pressed role =
    let flag name = Option.map (fun value -> name, string_of_bool value) in
    let props =
        List.filter_map Fun.id
            [ flag "checked" checked; flag "disabled" disabled; flag "selected" selected; flag "expanded" expanded;
              flag "include-hidden" include_hidden;
              Option.map (fun level -> "level", string_of_int level) level;
              Option.map (fun name -> "name", escape_for_attribute name ~exact) name;
              Option.map (fun description -> "description", escape_for_attribute description ~exact) description;
              flag "pressed" pressed ]
    in
    "internal:role=" ^ role ^ String.concat "" (List.map (fun (name, value) -> Printf.sprintf "[%s=%s]" name value) props)

let has_text text = "internal:has-text=" ^ escape_for_text text ~exact:false
let has_not_text text = "internal:has-not-text=" ^ escape_for_text text ~exact:false
let has selector = "internal:has=" ^ json_string selector
let has_not selector = "internal:has-not=" ^ json_string selector
let chain selector = "internal:chain=" ^ json_string selector
let and_ selector = "internal:and=" ^ json_string selector
let or_ selector = "internal:or=" ^ json_string selector
let visible visible = "visible=" ^ string_of_bool visible
let nth index = "nth=" ^ string_of_int index
let enter_frame = "internal:control=enter-frame"
let describe description = "internal:describe=" ^ json_string description

(* The description that the last part of a selector gives, if that is what the last part is.
   Looked for from the left: a description may itself contain what looks like one. *)
let description selector =
    let marker = "internal:describe=" in
    let m = String.length marker and n = String.length selector in
    let separator = " >> " in
    let s = String.length separator in
    let parsed start =
        match Yojson.Safe.from_string (String.sub selector start (n - start)) with
        | `String description -> Some description
        | _ | (exception _) -> None
    in
    let rec from i =
        if i + m > n then None
        else if String.sub selector i m = marker && (i = 0 || (i >= s && String.sub selector (i - s) s = separator)) then
            match parsed (i + m) with Some description -> Some description | None -> from (i + 1)
        else from (i + 1)
    in
    from 0

let join parts = String.concat " >> " parts
