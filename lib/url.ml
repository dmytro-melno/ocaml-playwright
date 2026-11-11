(* The URL Standard's parser (https://url.spec.whatwg.org/#concept-basic-url-parser), written as
   functions over the parts of a URL instead of as the standard's state machine.  The comments
   name the states of the standard that each function stands for. *)

type path = Opaque of string | Segments of string list

type t = {
    scheme : string;
    username : string;
    password : string;
    host : string option;  (* in its serialised form; [None] for URLs without an authority *)
    port : int option;  (* [None] also for the default port of the scheme *)
    path : path;
    query : string option;
    fragment : string option;
}

exception Invalid

let is_alpha = function 'a' .. 'z' | 'A' .. 'Z' -> true | _ -> false
let is_digit = function '0' .. '9' -> true | _ -> false
let hex_digit = function '0' .. '9' as c -> Char.code c - 48 | 'a' .. 'f' as c -> Char.code c - 87 | 'A' .. 'F' as c -> Char.code c - 55 | _ -> 99
let is_special = function "http" | "https" | "ws" | "wss" | "ftp" | "file" -> true | _ -> false
let default_port = function "http" | "ws" -> Some 80 | "https" | "wss" -> Some 443 | "ftp" -> Some 21 | _ -> None
let from s i = String.sub s i (String.length s - i)

(* {1 Percent-encoding}

   A set is given by the characters that it encodes.  The input is UTF-8, so encoding it byte by
   byte is encoding it as the standard says. *)

let c0_set c = c < ' ' || c > '~'
let fragment_set c = c0_set c || String.contains " \"<>`" c
let query_set c = c0_set c || String.contains " \"#<>" c
let special_query_set c = query_set c || c = '\''
let path_set c = query_set c || String.contains "?^`{}" c
let userinfo_set c = path_set c || String.contains "/:;=@[\\]|" c

let encode set s =
    if not (String.exists set s) then s
    else begin
        let b = Buffer.create (String.length s + 8) in
        String.iter (fun c -> if set c then Printf.bprintf b "%%%02X" (Char.code c) else Buffer.add_char b c) s;
        Buffer.contents b
    end

let percent_decode s =
    if not (String.contains s '%') then s
    else begin
        let n = String.length s in
        let b = Buffer.create n in
        let rec go i =
            if i < n then
                if s.[i] = '%' && i + 2 < n && hex_digit s.[i + 1] < 16 && hex_digit s.[i + 2] < 16 then begin
                    Buffer.add_char b (Char.chr ((hex_digit s.[i + 1] * 16) + hex_digit s.[i + 2]));
                    go (i + 3)
                end
                else begin
                    Buffer.add_char b s.[i];
                    go (i + 1)
                end
        in
        go 0;
        Buffer.contents b
    end

(* {1 Hosts} *)

(* The Punycode form of a label (RFC 3492, section 6.3), without its "xn--" prefix. *)
let punycode (label : int array) =
    let base = 36 and tmin = 1 and tmax = 26 in
    let b = Buffer.create 32 in
    Array.iter (fun c -> if c < 0x80 then Buffer.add_char b (Char.chr c)) label;
    let basic = Buffer.length b in
    if basic > 0 then Buffer.add_char b '-';
    let digit d = Char.chr (if d < 26 then d + 97 else d + 22) in
    let adapt delta points ~first =
        let delta = if first then delta / 700 else delta / 2 in
        let rec go delta k = if delta > (base - tmin) * tmax / 2 then go (delta / (base - tmin)) (k + base) else k + ((base - tmin + 1) * delta / (delta + 38)) in
        go (delta + (delta / points)) 0
    in
    let rec digits q k bias =
        let t = if k <= bias then tmin else if k >= bias + tmax then tmax else k - bias in
        if q < t then Buffer.add_char b (digit q)
        else begin
            Buffer.add_char b (digit (t + ((q - t) mod (base - t))));
            digits ((q - t) / (base - t)) (k + base) bias
        end
    in
    let n = ref 0x80 and delta = ref 0 and bias = ref 72 and handled = ref basic in
    while !handled < Array.length label do
        let next = Array.fold_left (fun next c -> if c >= !n && c < next then c else next) max_int label in
        delta := !delta + ((next - !n) * (!handled + 1));
        n := next;
        Array.iter
            (fun c ->
                if c < !n then incr delta
                else if c = !n then begin
                    digits !delta base !bias;
                    bias := adapt !delta (!handled + 1) ~first:(!handled = basic);
                    delta := 0;
                    incr handled
                end)
            label;
        incr delta;
        incr n
    done;
    Buffer.contents b

let code_points s =
    let rec go i acc =
        if i >= String.length s then List.rev acc
        else begin
            let decoded = String.get_utf_8_uchar s i in
            if not (Uchar.utf_decode_is_valid decoded) then raise Invalid;
            go (i + Uchar.utf_decode_length decoded) (Uchar.to_int (Uchar.utf_decode_uchar decoded) :: acc)
        end
    in
    Array.of_list (go 0 [])

(* Domain to ASCII, without the mapping and the validation of UTS 46. *)
let domain_to_ascii domain =
    String.split_on_char '.' (String.lowercase_ascii domain)
    |> List.map (fun label -> if String.for_all (fun c -> c < '\x80') label then label else "xn--" ^ punycode (code_points label))
    |> String.concat "."

(* The IPv4 number parser.  Numbers too large for any address all come out as one large number. *)
let ipv4_number s =
    let n = String.length s in
    if n = 0 then None
    else begin
        let radix, digits = if n >= 2 && s.[0] = '0' && (s.[1] = 'x' || s.[1] = 'X') then 16, from s 2 else if n >= 2 && s.[0] = '0' then 8, from s 1 else 10, s in
        String.fold_left (fun acc c -> match acc with Some number when hex_digit c < radix -> Some (min ((number * radix) + hex_digit c) (1 lsl 40)) | _ -> None) (Some 0) digits
    end

let without_trailing_dot labels = match List.rev labels with "" :: (_ :: _ as rest) -> List.rev rest | _ -> labels

let ends_in_number host =
    match List.rev (without_trailing_dot (String.split_on_char '.' host)) with
    | last :: _ -> (last <> "" && String.for_all is_digit last) || ipv4_number last <> None
    | [] -> false

let ipv4 host =
    let parts = without_trailing_dot (String.split_on_char '.' host) in
    let count = List.length parts in
    if count > 4 then raise Invalid;
    let add (i, address) part =
        let number = match ipv4_number part with Some number -> number | None -> raise Invalid in
        if i < count - 1 then begin
            if number > 255 then raise Invalid;
            i + 1, address + (number lsl (8 * (3 - i)))
        end
        else begin
            if number >= 1 lsl (8 * (5 - count)) then raise Invalid;
            i + 1, address + number
        end
    in
    let _, address = List.fold_left add (0, 0) parts in
    Printf.sprintf "%d.%d.%d.%d" (address lsr 24) ((address lsr 16) land 255) ((address lsr 8) land 255) (address land 255)

(* The IPv6 parser and serialiser, for the text between the brackets. *)
let ipv6 input =
    let n = String.length input in
    let address = Array.make 8 0 in
    let piece = ref 0 and compress = ref (-1) and pointer = ref 0 in
    let is c = !pointer < n && input.[!pointer] = c in
    if is ':' then begin
        if not (n > 1 && input.[1] = ':') then raise Invalid;
        pointer := 2;
        incr piece;
        compress := !piece
    end;
    while !pointer < n do
        if !piece = 8 then raise Invalid;
        if is ':' then begin
            if !compress >= 0 then raise Invalid;
            incr pointer;
            incr piece;
            compress := !piece
        end
        else begin
            let value = ref 0 and length = ref 0 in
            while !length < 4 && !pointer < n && hex_digit input.[!pointer] < 16 do
                value := (!value * 16) + hex_digit input.[!pointer];
                incr pointer;
                incr length
            done;
            if is '.' then begin
                (* An IPv4 address in the last two pieces. *)
                if !length = 0 || !piece > 6 then raise Invalid;
                pointer := !pointer - !length;
                let seen = ref 0 in
                while !pointer < n do
                    if !seen > 0 then if is '.' && !seen < 4 then incr pointer else raise Invalid;
                    if not (!pointer < n && is_digit input.[!pointer]) then raise Invalid;
                    let number = ref (-1) in
                    while !pointer < n && is_digit input.[!pointer] do
                        let digit = Char.code input.[!pointer] - 48 in
                        if !number = 0 then raise Invalid;
                        number := if !number < 0 then digit else (!number * 10) + digit;
                        if !number > 255 then raise Invalid;
                        incr pointer
                    done;
                    address.(!piece) <- (address.(!piece) * 0x100) + !number;
                    incr seen;
                    if !seen = 2 || !seen = 4 then incr piece
                done;
                if !seen <> 4 then raise Invalid
            end
            else begin
                if is ':' then begin
                    incr pointer;
                    if !pointer >= n then raise Invalid
                end
                else if !pointer < n then raise Invalid;
                address.(!piece) <- !value;
                incr piece
            end
        end
    done;
    if !compress >= 0 then begin
        let swaps = ref (!piece - !compress) in
        piece := 7;
        while !piece <> 0 && !swaps > 0 do
            let other = !compress + !swaps - 1 in
            let value = address.(!piece) in
            address.(!piece) <- address.(other);
            address.(other) <- value;
            decr piece;
            decr swaps
        done
    end
    else if !piece <> 8 then raise Invalid;
    (* The first of the longest runs of zeros, if longer than one piece, is written as "::". *)
    let run_from i =
        let rec go j = if j < 8 && address.(j) = 0 then go (j + 1) else j - i in
        go i
    in
    let start, _ = List.fold_left (fun (start, longest) i -> if run_from i > longest then i, run_from i else start, longest) (-1, 1) [ 0; 1; 2; 3; 4; 5; 6; 7 ] in
    let b = Buffer.create 40 in
    let in_run = ref false in
    Array.iteri
        (fun i value ->
            if not (!in_run && value = 0) then begin
                in_run := false;
                if i = start then begin
                    Buffer.add_string b (if i = 0 then "::" else ":");
                    in_run := true
                end
                else begin
                    Printf.bprintf b "%x" value;
                    if i <> 7 then Buffer.add_char b ':'
                end
            end)
        address;
    Buffer.contents b

let forbidden_in_host c = String.contains "\000\t\n\r #/:<>?@[\\]^|" c
let forbidden_in_domain c = forbidden_in_host c || c <= '\x1f' || c = '%' || c = '\x7f'

(* The host parser.  A host that is not of a special scheme is opaque: kept as it is written. *)
let parse_host ~special input =
    let n = String.length input in
    if n > 0 && input.[0] = '[' then begin
        if n < 2 || input.[n - 1] <> ']' then raise Invalid;
        "[" ^ ipv6 (String.sub input 1 (n - 2)) ^ "]"
    end
    else if not special then begin
        if String.exists forbidden_in_host input then raise Invalid;
        encode c0_set input
    end
    else begin
        let domain = domain_to_ascii (percent_decode input) in
        if domain = "" || String.exists forbidden_in_domain domain then raise Invalid;
        if ends_in_number domain then ipv4 domain else domain
    end

(* {1 Paths} *)

let is_drive_letter s = String.length s = 2 && is_alpha s.[0] && (s.[1] = ':' || s.[1] = '|')
let is_normalized_drive_letter s = is_drive_letter s && s.[1] = ':'
let starts_with_drive_letter s = String.length s >= 2 && is_drive_letter (String.sub s 0 2) && (String.length s = 2 || String.contains "/\\?#" s.[2])
let is_single_dot s = s = "." || String.lowercase_ascii s = "%2e"
let is_double_dot s = match String.lowercase_ascii s with ".." | ".%2e" | "%2e." | "%2e%2e" -> true | _ -> false
let is_slash ~special c = c = '/' || (special && c = '\\')

let split ~special s =
    let rec go i start acc =
        if i = String.length s then List.rev (String.sub s start (i - start) :: acc)
        else if is_slash ~special s.[i] then go (i + 1) (i + 1) (String.sub s start (i - start) :: acc)
        else go (i + 1) start acc
    in
    go 0 0 []

(* Paths are built in reverse: the last segment first. *)
let shorten ~scheme = function
    | [ drive ] when scheme = "file" && is_normalized_drive_letter drive -> [ drive ]
    | _ :: rest -> rest
    | [] -> []

(* The path state: the segments of [input] follow those of [initial], which is in reverse. *)
let parse_path ~scheme initial input =
    let rec go path = function
        | [] -> path
        | segment :: rest ->
            let last = rest = [] in
            let path =
                if is_double_dot segment then if last then "" :: shorten ~scheme path else shorten ~scheme path
                else if is_single_dot segment then if last then "" :: path else path
                else if scheme = "file" && path = [] && is_drive_letter segment then (String.sub segment 0 1 ^ ":") :: path
                else encode path_set segment :: path
            in
            go path rest
    in
    List.rev (go initial (split ~special:(is_special scheme) input))

(* The path start state: what follows an authority. *)
let path_after_authority ~scheme rest =
    if is_special scheme then parse_path ~scheme [] (if rest = "" then rest else from rest 1) else if rest = "" then [] else parse_path ~scheme [] (from rest 1)

(* {1 Authorities} *)

let authority_end ~special s =
    let rec go i = if i < String.length s && not (is_slash ~special s.[i]) then go (i + 1) else i in
    go 0

(* The authority, host and port states.  [s] is what follows the slashes; the result ends with
   what follows the authority. *)
let parse_authority ~scheme s =
    let special = is_special scheme in
    let stop = authority_end ~special s in
    let authority = String.sub s 0 stop in
    let credentials, host_and_port =
        match String.rindex_opt authority '@' with
        | Some at -> Some (String.sub authority 0 at), from authority (at + 1)
        | None -> None, authority
    in
    if credentials <> None && host_and_port = "" then raise Invalid;
    let username, password =
        match credentials with
        | None -> "", ""
        | Some credentials -> (
            match String.index_opt credentials ':' with
            | Some colon -> encode userinfo_set (String.sub credentials 0 colon), encode userinfo_set (from credentials (colon + 1))
            | None -> encode userinfo_set credentials, "")
    in
    (* The port follows the first colon that is not inside the brackets of an IPv6 address. *)
    let colon =
        let rec go i inside =
            if i >= String.length host_and_port then None
            else
                match host_and_port.[i] with
                | '[' -> go (i + 1) true
                | ']' -> go (i + 1) false
                | ':' when not inside -> Some i
                | _ -> go (i + 1) inside
        in
        go 0 false
    in
    let host, port =
        match colon with
        | None -> host_and_port, None
        | Some colon ->
            let digits = from host_and_port (colon + 1) in
            if colon = 0 || not (String.for_all is_digit digits) then raise Invalid;
            let port = if digits = "" then None else Some (String.fold_left (fun port c -> min ((port * 10) + Char.code c - 48) 65536) 0 digits) in
            if port = Some 65536 then raise Invalid;
            String.sub host_and_port 0 colon, if port = default_port scheme then None else port
    in
    if special && host = "" then raise Invalid;
    username, password, parse_host ~special host, port, from s stop

(* {1 URLs} *)

(* Without the spaces and control characters around it, and without tabs and newlines. *)
let clean s =
    let n = String.length s in
    let rec first i = if i < n && s.[i] <= ' ' then first (i + 1) else i in
    let rec last j = if j > 0 && s.[j - 1] <= ' ' then last (j - 1) else j in
    let start = first 0 in
    let s = String.sub s start (max start (last n) - start) in
    if String.exists (fun c -> c = '\t' || c = '\n' || c = '\r') s then String.concat "" (String.split_on_char '\t' s |> List.concat_map (String.split_on_char '\n') |> List.concat_map (String.split_on_char '\r'))
    else s

(* The scheme state: the scheme in lower case and what follows its colon. *)
let split_scheme s =
    let n = String.length s in
    let rec go i =
        if i >= n then None
        else
            match s.[i] with
            | ':' -> Some (String.lowercase_ascii (String.sub s 0 i), from s (i + 1))
            | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '+' | '-' | '.' -> go (i + 1)
            | _ -> None
    in
    if n > 0 && is_alpha s.[0] then go 1 else None

let cut c s = match String.index_opt s c with Some i -> String.sub s 0 i, Some (from s (i + 1)) | None -> s, None
let segments (t : t) = match t.path with Segments segments -> segments | Opaque _ -> []

let parse_relative_to (base : t option) input =
    let input = clean input in
    let given_scheme, rest = match split_scheme input with Some (scheme, rest) -> Some scheme, rest | None -> None, input in
    let scheme = match given_scheme, base with Some scheme, _ -> scheme | None, Some base -> base.scheme | None, None -> raise Invalid in
    let special = is_special scheme in
    (* Every state ends at the first "#", and every state before the query at the first "?". *)
    let rest, fragment = cut '#' rest in
    let rest, query = cut '?' rest in
    let query = Option.map (encode (if special then special_query_set else query_set)) query in
    let fragment = Option.map (encode fragment_set) fragment in
    let starts_with_slash s = s <> "" && is_slash ~special s.[0] in
    let rec without_slashes s = if s <> "" && (s.[0] = '/' || s.[0] = '\\') then without_slashes (from s 1) else s in
    let make ?(username = "") ?(password = "") ?host ?port path = { scheme; username; password; host; port; path; query; fragment } in
    let with_authority s =
        let username, password, host, port, rest = parse_authority ~scheme s in
        make ~username ~password ~host ?port (Segments (path_after_authority ~scheme rest))
    in
    (* A reference that is nothing but a query or a fragment keeps the rest of the base. *)
    let same_document (base : t) = { base with query = (if query = None then base.query else query); fragment } in
    (* The relative and relative slash states. *)
    let relative (base : t) =
        if starts_with_slash rest then begin
            let after = from rest 1 in
            if special && starts_with_slash after then with_authority (without_slashes after)
            else if (not special) && after <> "" && after.[0] = '/' then with_authority (from after 1)
            else { base with path = Segments (parse_path ~scheme [] after); query; fragment }
        end
        else if rest = "" then same_document base
        else { base with path = Segments (parse_path ~scheme (shorten ~scheme (List.rev (segments base))) rest); query; fragment }
    in
    (* The file, file slash and file host states. *)
    let file () =
        let base = match base with Some base when base.scheme = "file" -> Some base | _ -> None in
        if starts_with_slash rest then begin
            let after = from rest 1 in
            if starts_with_slash after then begin
                let after = from after 1 in
                let stop = authority_end ~special after in
                let host = String.sub after 0 stop in
                if is_drive_letter host then make ~host:"" (Segments (parse_path ~scheme [] after))
                else begin
                    let host = if host = "" then "" else parse_host ~special host in
                    make ~host:(if host = "localhost" then "" else host) (Segments (path_after_authority ~scheme (from after stop)))
                end
            end
            else begin
                let host, drive =
                    match base with
                    | Some base -> (
                        ( Option.value base.host ~default:"",
                          match segments base with drive :: _ when is_normalized_drive_letter drive && not (starts_with_drive_letter after) -> [ drive ] | _ -> [] ))
                    | None -> "", []
                in
                make ~host (Segments (parse_path ~scheme drive after))
            end
        end
        else
            match base with
            | Some base when rest = "" -> same_document base
            | Some base ->
                let directory = if starts_with_drive_letter rest then [] else shorten ~scheme (List.rev (segments base)) in
                { base with path = Segments (parse_path ~scheme directory rest); query; fragment }
            | None -> make ~host:"" (Segments (parse_path ~scheme [] rest))
    in
    match given_scheme, base with
    | Some "file", _ -> file ()
    | Some _, Some base when special && base.scheme = scheme && not (String.starts_with ~prefix:"//" rest) -> relative base
    | Some _, _ when special -> with_authority (without_slashes rest)
    | Some _, _ ->
        if String.starts_with ~prefix:"//" rest then with_authority (from rest 2)
        else if String.starts_with ~prefix:"/" rest then make (Segments (parse_path ~scheme [] (from rest 1)))
        else begin
            (* The opaque path state.  A space cannot end the path, since it would be lost when the
               URL is read again. *)
            let before_tail = String.ends_with ~suffix:" " rest && (query <> None || fragment <> None) in
            make (Opaque (encode c0_set (if before_tail then String.sub rest 0 (String.length rest - 1) ^ "%20" else rest)))
        end
    | None, None -> raise Invalid
    | None, Some ({ path = Opaque _; _ } as base) -> if rest = "" && query = None && fragment <> None then { base with fragment } else raise Invalid
    | None, Some base -> if scheme = "file" then file () else relative base

let parse ?base reference =
    match parse_relative_to (Option.map (parse_relative_to None) base) reference with
    | url -> Some url
    | exception Invalid -> None

let to_string (t : t) =
    let b = Buffer.create 64 in
    Buffer.add_string b t.scheme;
    Buffer.add_char b ':';
    (match t.host, t.path with
    | Some host, _ ->
        Buffer.add_string b "//";
        if t.username <> "" || t.password <> "" then begin
            Buffer.add_string b t.username;
            if t.password <> "" then Buffer.add_string b (":" ^ t.password);
            Buffer.add_char b '@'
        end;
        Buffer.add_string b host;
        Option.iter (Printf.bprintf b ":%d") t.port
    | None, Segments ("" :: _ :: _) -> Buffer.add_string b "/."  (* so that the path is not read as an authority *)
    | None, _ -> ());
    (match t.path with Opaque path -> Buffer.add_string b path | Segments segments -> List.iter (fun segment -> Buffer.add_string b ("/" ^ segment)) segments);
    Option.iter (fun query -> Buffer.add_string b ("?" ^ query)) t.query;
    Option.iter (fun fragment -> Buffer.add_string b ("#" ^ fragment)) t.fragment;
    Buffer.contents b

let rec origin (t : t) =
    match t.scheme, t.host, t.path with
    | ("http" | "https" | "ws" | "wss" | "ftp"), Some host, _ -> Printf.sprintf "%s://%s%s" t.scheme host (Option.fold ~none:"" ~some:(Printf.sprintf ":%d") t.port)
    | "blob", _, Opaque inner -> (
        (* The origin of a blob URL is that of the URL it wraps. *)
        match parse inner with
        | Some ({ scheme = "http" | "https"; _ } as inner) -> origin inner
        | _ -> "null")
    | _ -> "null"

let resolve ?base reference = match parse ?base reference with Some url -> to_string url | None -> reference
