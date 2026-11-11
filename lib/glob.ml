(* URL globs, as every Playwright client reads them.

   This is a port of [packages/isomorphic/urlMatch.ts] of Playwright: a glob is resolved against
   the base URL and turned into the regular expression that Playwright would make of it, which
   {!Url_regex} then runs.  The driver matches the same globs by the same rules when it decides
   which requests to hand over, so the two must agree; test/driver checks that they do. *)

let needs_escape c = String.contains "$^+.*()|\\?{}[]" c

(* The source of the regular expression for a glob: [*] is anything but a slash, [**] anything,
   [{a,b}] a choice, and a backslash makes the next character literal.  Brackets are literal. *)
let to_regex_pattern glob =
    let n = String.length glob in
    let b = Buffer.create (n + 16) in
    let invalid reason = invalid_arg (Printf.sprintf "Invalid glob pattern %S: %s" glob reason) in
    let literal c =
        if needs_escape c then Buffer.add_char b '\\';
        Buffer.add_char b c
    in
    let rec go i ~in_group =
        if i >= n then begin
            if in_group then invalid "unmatched '{'"
        end
        else
            match glob.[i] with
            | '\\' when i + 1 < n ->
                literal glob.[i + 1];
                go (i + 2) ~in_group
            | '*' ->
                let rec after_stars j = if j < n && glob.[j] = '*' then after_stars (j + 1) else j in
                let next = after_stars i in
                if next - i = 1 then begin
                    Buffer.add_string b "([^/]*)";
                    go next ~in_group
                end
                else if next < n && glob.[next] = '/' then begin
                    (* Between slashes, "**" stands for any number of directories, also none. *)
                    Buffer.add_string b (if i > 0 && glob.[i - 1] = '/' then "((.+/)|)" else "(.*/)");
                    go (next + 1) ~in_group
                end
                else begin
                    Buffer.add_string b "(.*)";
                    go next ~in_group
                end
            | '{' ->
                if in_group then invalid "nested '{' is not supported";
                Buffer.add_char b '(';
                go (i + 1) ~in_group:true
            | '}' ->
                if not in_group then invalid "unmatched '}'";
                Buffer.add_char b ')';
                go (i + 1) ~in_group:false
            | ',' ->
                Buffer.add_string b (if in_group then "|" else "\\,");
                go (i + 1) ~in_group
            | c ->
                literal c;
                go (i + 1) ~in_group
    in
    Buffer.add_char b '^';
    go 0 ~in_group:false;
    Buffer.add_char b '$';
    Buffer.contents b

let find ~sub s =
    let n = String.length s and m = String.length sub in
    let rec go i = if i + m > n then None else if String.sub s i m = sub then Some i else go (i + 1) in
    go 0

let replace_first ~sub ~by s =
    match find ~sub s with
    | Some i -> String.sub s 0 i ^ by ^ String.sub s (i + String.length sub) (String.length s - i - String.length sub)
    | None -> s

let rec replace_all ~sub ~by s =
    match find ~sub s with
    | Some i -> String.sub s 0 i ^ by ^ replace_all ~sub ~by (String.sub s (i + String.length sub) (String.length s - i - String.length sub))
    | None -> s

(* A base URL of a page serves for its WebSockets as well. *)
let web_socket_base base =
    let lower = String.lowercase_ascii base in
    if String.starts_with ~prefix:"https://" lower then "wss" ^ String.sub base 5 (String.length base - 5)
    else if String.starts_with ~prefix:"http://" lower then "ws" ^ String.sub base 4 (String.length base - 4)
    else base

(* The glob as an absolute URL: resolved against the base URL and normalised as URLs are, with
   the parts that hold glob syntax left as they were written.  A glob that starts with a star
   matches any beginning and is not resolved. *)
let resolve ?base_url ?(web_socket = false) glob =
    if String.starts_with ~prefix:"*" glob then glob
    else begin
        (* An escaped "\\?" is the same as "?" here. *)
        let glob = replace_all ~sub:"\\\\?" ~by:"?" glob in
        if List.exists (fun prefix -> String.starts_with ~prefix glob) [ "about:"; "data:"; "chrome:"; "edge:"; "file:" ] then glob
        else begin
            (* Glob syntax would not survive the parsing of a URL, and a "?" in it would be read as
               the start of a query, so the parts with syntax travel as placeholders. *)
            let placeholders = ref [] in
            let placeholder original name =
                if original = "" then ""
                else begin
                    placeholders := (name, original) :: !placeholders;
                    name
                end
            in
            let part index part =
                if part = "." || part = ".." || part = "" then part
                else if index = 0 && String.ends_with ~suffix:":" part then
                    (* A scheme: a pattern for one is resolved as a web scheme, which puts a slash
                       after the host as the scheme it matches will. *)
                    if String.contains part '*' || String.contains part '{' then placeholder part "http:" else part
                else if not (String.exists (fun c -> String.contains "*?{}\\" c) part) then part
                else
                    match String.index_opt part '?' with
                    | None -> placeholder part (Printf.sprintf "$_%d_$" index)
                    | Some question ->
                        let before = placeholder (String.sub part 0 question) (Printf.sprintf "$_%d_$" index) in
                        before ^ placeholder (String.sub part question (String.length part - question)) (Printf.sprintf "?$_%d_$" index)
            in
            let relative = String.concat "/" (List.mapi part (String.split_on_char '/' glob)) in
            let base = if web_socket then Option.map web_socket_base base_url else base_url in
            let resolved, origin = match Url.parse ?base relative with Some url -> Url.to_string url, Some (Url.origin url) | None -> relative, None in
            (* Schemes and hosts are matched in lower case, as URLs have them. *)
            let restore resolved (name, original) =
                let in_origin = match origin with Some origin -> find ~sub:name origin <> None | None -> false in
                replace_first ~sub:name ~by:(if in_origin then String.lowercase_ascii original else original) resolved
            in
            List.fold_left restore resolved (List.rev !placeholders)
        end
    end

(* Raises [Invalid_argument] for a glob with unbalanced or nested braces. *)
let matcher ?base_url ?web_socket glob : string -> bool =
    if glob = "" then Fun.const true
    else begin
        let pattern = to_regex_pattern (resolve ?base_url ?web_socket glob) in
        match Url_regex.parse pattern with
        | regex -> Url_regex.matches regex
        | exception Url_regex.Unsupported _ -> invalid_arg (Printf.sprintf "Cannot match URLs against the glob %S (resolved to /%s/)" glob pattern)
    end
