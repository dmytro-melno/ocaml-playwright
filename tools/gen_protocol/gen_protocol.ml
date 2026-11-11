(* Generates [lib/protocol.ml] from the vendored Playwright protocol specification.

      The specification ([protocol/spec/*.yml]) is the upstream source of truth for the wire
      protocol spoken by the Playwright driver.  This tool turns it into a typed, internal OCaml
      layer: one module per protocol struct and one module per channel interface, with a function
      per command, a variant per event and a record for the initializer.  The hand-written client
      in [lib/] is built on top of that layer, so a protocol update surfaces as type errors.

      Usage: gen_protocol MANIFEST SPEC_DIR *)

let failf fmt = Printf.ksprintf failwith fmt

(* {1 Configuration} *)

(* Channels that the OCaml client does not implement.  Their commands are not generated; values
      of these types are still representable as untyped channels. *)
let excluded_interfaces =
    [ "Android"; "AndroidSocket"; "AndroidDevice"; "Electron"; "ElectronApplication"; "DebugController"; "SocksSupport" ]

(* Types that are passed through as raw JSON.  [SerializedValue] is a tagged union encoded as a
      record with one populated field; [Js] encodes and decodes it directly. *)
let opaque_types = [ "SerializedValue" ]

(* {1 Model} *)

type prim = String | Int | Float | Bool | Binary | Json

type ty =
    | Prim of prim
    | Channel
    | Def of string  (* OCaml module name of a generated record or enum module *)
    | Array of ty
    | Enum of string list

type field = { wire : string; ty : ty; optional : bool }

type def = Record of field list | Variant of string list

type command = { c_wire : string; params : field list; returns : field list }

type event = { e_wire : string; payload : field list }

type interface = {
    i_wire : string;
    mutable defs : (string * def) list;  (* local modules, in dependency order (reversed while building) *)
    mutable initializer_ : field list;
    mutable commands : command list;
    mutable events : event list;
}

(* {1 Names} *)

let keywords =
    [ "and"; "as"; "assert"; "begin"; "class"; "constraint"; "do"; "done"; "downto"; "else"; "end"; "exception";
        "external"; "false"; "for"; "fun"; "function"; "functor"; "if"; "in"; "include"; "inherit"; "initializer";
        "lazy"; "let"; "match"; "method"; "module"; "mutable"; "new"; "nonrec"; "object"; "of"; "open"; "or";
        "private"; "rec"; "sig"; "struct"; "then"; "to"; "true"; "try"; "type"; "val"; "virtual"; "when"; "while";
        "with" ]

let is_upper c = c >= 'A' && c <= 'Z'
let is_lower c = c >= 'a' && c <= 'z'
let is_digit c = c >= '0' && c <= '9'

(* camelCase / PascalCase / kebab-case to snake_case; acronyms stay together: innerHTML -> inner_html. *)
let snake s =
    let b = Buffer.create (String.length s + 4) in
    let n = String.length s in
    String.iteri
        (fun i c ->
            if is_upper c then begin
                let prev = if i > 0 then s.[i - 1] else '_' in
                let next = if i + 1 < n then s.[i + 1] else '_' in
                if i > 0 && prev <> '_' && (is_lower prev || is_digit prev || (is_upper prev && is_lower next)) then
                    Buffer.add_char b '_';
                Buffer.add_char b (Char.lowercase_ascii c)
            end
            else if is_lower c || is_digit c then Buffer.add_char b c
            else if Buffer.length b > 0 && Buffer.nth b (Buffer.length b - 1) <> '_' then Buffer.add_char b '_')
        s;
    let r = Buffer.contents b in
    let r = if String.ends_with ~suffix:"_" r then String.sub r 0 (String.length r - 1) else r in
    if r = "" then failf "cannot derive an identifier from %S" s;
    r

let ident s =
    let r = snake s in
    if List.mem r keywords then r ^ "_" else if is_digit r.[0] then "v" ^ r else r

let module_name s = String.capitalize_ascii (snake s)

let variant_name = function
    | "-0" -> "Minus_zero"
    | "-Infinity" -> "Minus_infinity"
    | "NaN" -> "Nan"
    | s ->
        let r = snake s in
        if is_digit r.[0] then "V" ^ r else String.capitalize_ascii r

let check_unique what names =
    let sorted = List.sort compare names in
    let rec go = function
        | a :: (b :: _ as rest) -> if a = b then failf "duplicate %s %S" what a else go rest
        | _ -> ()
    in
    go sorted

(* {1 YAML} *)

type yaml = Null | Scalar of string | Seq of yaml list | Map of (string * yaml) list

(* Scalars are kept as written: YAML would otherwise turn the enum literals [null], [NaN] and
      [-Infinity] into non-strings. *)
let load_yaml path =
    let rec convert : Yaml.yaml -> yaml = function
        | `Scalar s -> if s.style = `Plain && (s.value = "" || s.value = "~") then Null else Scalar s.value
        | `A s -> Seq (List.map convert s.s_members)
        | `O m ->
            Map
                (List.map
                      (fun (k, v) ->
                          match convert k with Scalar k -> (k, convert v) | _ -> failf "%s: non-scalar mapping key" path)
                      m.m_members)
        | `Alias a -> failf "%s: unsupported YAML alias %S" path a
    in
    match Yaml.yaml_of_string (In_channel.with_open_bin path In_channel.input_all) with
    | Ok y -> ( match convert y with Map m -> m | _ -> failf "%s: expected a mapping" path)
    | Error (`Msg m) -> failf "%s: %s" path m

let map_of what = function Map m -> m | Null -> [] | _ -> failf "%s: expected a mapping" what
let find k m = List.assoc_opt k m
let find_map what k m = match find k m with Some v -> map_of (what ^ "." ^ k) v | None -> []
let find_string k m = match find k m with Some (Scalar s) -> Some s | _ -> None

(* {1 Building the model} *)

type env = {
    raw : (string * (string * yaml) list) list;  (* every top-level spec entry *)
    kinds : (string, string) Hashtbl.t;  (* spec name -> interface | object | enum | mixin *)
    globals : (string, def) Hashtbl.t;  (* module name -> definition *)
    mutable global_order : string list;  (* reversed dependency order *)
    mixins : (string, field list) Hashtbl.t;
    mutable visiting : string list;
}

let split_optional s = if String.ends_with ~suffix:"?" s then (String.sub s 0 (String.length s - 1), true) else (s, false)

(* [register] adds an anonymous definition to the current scope and returns its module name. *)
let rec parse_type env ~register ~path (y : yaml) : ty * bool =
    match y with
    | Scalar s -> (
        let base, optional = split_optional (String.trim s) in
        let ty =
            match base with
            | "string" -> Prim String
            | "int" -> Prim Int
            | "float" -> Prim Float
            | "boolean" -> Prim Bool
            | "binary" -> Prim Binary
            | "json" -> Prim Json
            | "Channel" -> Channel
            | name when List.mem name opaque_types -> Prim Json
            | name -> (
                match Hashtbl.find_opt env.kinds name with
                | Some "interface" -> Channel
                | Some ("object" | "enum") ->
                    global env name;
                    Def (module_name name)
                | _ -> failf "%s: unknown type %S" path name)
        in
        (ty, optional))
    | Map m -> (
        let kind, optional = split_optional (Option.value (find_string "type" m) ~default:"object") in
        match kind with
        | "array" ->
            let item = match find "items" m with Some i -> i | None -> failf "%s: array without items" path in
            let ty, item_optional = parse_type env ~register ~path item in
            if item_optional then failf "%s: optional array items are not supported" path;
            (Array ty, optional)
        | "enum" -> (Enum (literals path m), optional)
        | "object" ->
            let fields = parse_fields env ~register ~path (find_map path "properties" m) in
            (Def (register path (Record fields)), optional)
        | k -> failf "%s: unknown type kind %S" path k)
    | _ -> failf "%s: malformed type" path

and literals path m =
    match find "literals" m with
    | Some (Seq l) -> List.map (function Scalar s -> s | Null -> "null" | _ -> failf "%s: malformed enum literal" path) l
    | _ -> failf "%s: enum without literals" path

and parse_fields env ~register ~path props : field list =
    let fields =
        List.concat_map
            (fun (name, y) ->
                if String.starts_with ~prefix:"$mixin" name then
                    match y with Scalar mixin_name -> mixin env mixin_name | _ -> failf "%s: malformed $mixin" path
                else
                    let ty, optional = parse_type env ~register ~path:(path ^ "_" ^ snake name) y in
                    [ { wire = name; ty; optional } ])
            props
    in
    check_unique ("field in " ^ path) (List.map (fun f -> ident f.wire) fields);
    fields

and register_global env path def =
    if Hashtbl.mem env.globals path then failf "duplicate global definition %s" path;
    Hashtbl.replace env.globals path def;
    env.global_order <- path :: env.global_order;
    path

(* Materialise a named struct or enum on first use, after everything it depends on. *)
and global env name =
    let m = module_name name in
    if not (Hashtbl.mem env.globals m) then begin
        if List.mem name env.visiting then failf "recursive protocol type %s is not supported" name;
        env.visiting <- name :: env.visiting;
        let spec = List.assoc name env.raw in
        let def =
            match Hashtbl.find env.kinds name with
            | "enum" -> Variant (literals name spec)
            | _ -> Record (parse_fields env ~register:(register_global env) ~path:m (find_map name "properties" spec))
        in
        env.visiting <- List.tl env.visiting;
        ignore (register_global env m def)
    end

and mixin env name =
    match Hashtbl.find_opt env.mixins name with
    | Some fields -> fields
    | None ->
        let spec = match List.assoc_opt name env.raw with Some s -> s | None -> failf "unknown mixin %S" name in
        let fields =
            parse_fields env ~register:(register_global env) ~path:(module_name name) (find_map name "properties" spec)
        in
        Hashtbl.replace env.mixins name fields;
        fields

let rec interface env name : interface =
    let spec = List.assoc name env.raw in
    let iface = { i_wire = name; defs = []; initializer_ = []; commands = []; events = [] } in
    let register path def =
        if List.mem_assoc path iface.defs then failf "%s: duplicate local definition %s" name path;
        iface.defs <- (path, def) :: iface.defs;
        path
    in
    let fields path props = parse_fields env ~register ~path props in
    (match find_string "extends" spec with
    | Some base ->
        let b = interface env base in
        iface.defs <- b.defs;
        iface.commands <- b.commands;
        iface.events <- b.events
    | None -> ());
    iface.initializer_ <- fields "Initializer" (find_map name "initializer" spec);
    if iface.initializer_ <> [] then ignore (register "Initializer" (Record iface.initializer_));
    List.iter
        (fun (c_wire, y) ->
            let c = map_of (name ^ "." ^ c_wire) y in
            let cm = module_name c_wire in
            let params = fields cm (find_map c_wire "parameters" c) in
            if List.exists (fun f -> f.wire = "timeout") params then failf "%s.%s: a 'timeout' parameter clashes with metadata" name c_wire;
            let returns = fields (cm ^ "_result") (find_map c_wire "returns" c) in
            if List.length returns > 1 then ignore (register (cm ^ "_result") (Record returns));
            (match find_map c_wire "errorDetails" c with
            | [] -> ()
            | props -> ignore (register (cm ^ "_error_details") (Record (fields (cm ^ "_error_details") props))));
            iface.commands <- iface.commands @ [ { c_wire; params; returns } ])
        (find_map name "commands" spec);
    List.iter
        (fun (e_wire, y) ->
            let e = map_of (name ^ "." ^ e_wire) y in
            let payload = fields (module_name e_wire ^ "_event") (find_map e_wire "parameters" e) in
            iface.events <- iface.events @ [ { e_wire; payload } ])
        (find_map name "events" spec);
    check_unique (name ^ " command") (List.map (fun c -> ident c.c_wire) iface.commands);
    check_unique (name ^ " event") (List.map (fun e -> variant_name e.e_wire) iface.events);
    iface

(* {1 Emission} *)

let buf = Buffer.create (1 lsl 20)
let pr fmt = Printf.bprintf buf fmt

let rec type_expr = function
    | Prim (String | Binary) -> "string"
    | Prim Int -> "int"
    | Prim Float -> "float"
    | Prim Bool -> "bool"
    | Prim Json -> "Json.t"
    | Channel -> "Channel.t"
    | Def m -> m ^ ".t"
    | Array t -> type_expr t ^ " list"
    | Enum lits -> "[ " ^ String.concat " | " (List.map (fun l -> "`" ^ variant_name l) lits) ^ " ]"

let field_type f = if f.optional then type_expr f.ty ^ " option" else type_expr f.ty

let rec encoder = function
    | Prim String -> "Json.string"
    | Prim Int -> "Json.int"
    | Prim Float -> "Json.float"
    | Prim Bool -> "Json.bool"
    | Prim Binary -> "Json.binary"
    | Prim Json -> "Json.any"
    | Channel -> "Channel.to_json"
    | Def m -> m ^ ".to_json"
    | Array t -> Printf.sprintf "(Json.list %s)" (encoder t)
    | Enum lits ->
        Printf.sprintf "(Json.enum [ %s ])"
            (String.concat "; " (List.map (fun l -> Printf.sprintf "(`%s, %S)" (variant_name l) l) lits))

let rec decoder = function
    | Prim String -> "D.string"
    | Prim Int -> "D.int"
    | Prim Float -> "D.float"
    | Prim Bool -> "D.bool"
    | Prim Binary -> "D.binary"
    | Prim Json -> "D.any"
    | Channel -> "(Channel.of_json c)"
    | Def m -> Printf.sprintf "(%s.of_json c)" m
    | Array t -> Printf.sprintf "(D.list %s)" (decoder t)
    | Enum lits ->
        Printf.sprintf "(D.enum [ %s ])"
            (String.concat "; " (List.map (fun l -> Printf.sprintf "(%S, `%s)" l (variant_name l)) lits))

let rec needs_conn = function
    | Channel | Def _ -> true
    | Array t -> needs_conn t
    | Prim _ | Enum _ -> false

let encode_field ~access f =
    Printf.sprintf "Json.%s %S %s %s" (if f.optional then "opt" else "req") f.wire (encoder f.ty) (access (ident f.wire))

let decode_field f = Printf.sprintf "D.%s %S %s j" (if f.optional then "opt" else "req") f.wire (decoder f.ty)

let emit_def ind (name, def) =
    match def with
    | Variant lits ->
        check_unique ("literal in " ^ name) (List.map variant_name lits);
        pr "%smodule %s = struct\n" ind name;
        pr "%s  type t = %s\n\n" ind (type_expr (Enum lits));
        pr "%s  let to_json : t -> Json.t = %s\n" ind (encoder (Enum lits));
        pr "%s  let of_json (_ : Channel.conn) : Json.t -> t = %s\n" ind (decoder (Enum lits));
        pr "%send\n\n" ind
    | Record fields ->
        pr "%smodule %s = struct\n" ind name;
        if fields = [] then begin
            pr "%s  type t = unit\n\n" ind;
            pr "%s  let to_json () : Json.t = `Assoc []\n" ind;
            pr "%s  let of_json (_ : Channel.conn) (_ : Json.t) : t = ()\n" ind
        end
        else begin
            pr "%s  type t = {\n" ind;
            List.iter (fun f -> pr "%s    %s : %s;\n" ind (ident f.wire) (field_type f)) fields;
            pr "%s  }\n\n" ind;
            pr "%s  let to_json (v : t) : Json.t =\n%s    Json.obj\n%s      [\n" ind ind ind;
            List.iter (fun f -> pr "%s        %s;\n" ind (encode_field ~access:(fun n -> "v." ^ n) f)) fields;
            pr "%s      ]\n\n" ind;
            pr "%s  let of_json (c : Channel.conn) (j : Json.t) : t =\n%s    {\n" ind ind;
            List.iter (fun f -> pr "%s      %s = %s;\n" ind (ident f.wire) (decode_field f)) fields;
            pr "%s    }\n" ind
        end;
        pr "%send\n\n" ind

let emit_events iface =
    if iface.events <> [] then begin
        pr "  type event =\n";
        List.iter
            (fun e ->
                match e.payload with
                | [] -> pr "    | %s\n" (variant_name e.e_wire)
                | fields ->
                    pr "    | %s of { %s }\n" (variant_name e.e_wire)
                        (String.concat "; " (List.map (fun f -> Printf.sprintf "%s : %s" (ident f.wire) (field_type f)) fields)))
            iface.events;
        pr "\n  let event_of_json (c : Channel.conn) (name : string) (j : Json.t) : event option =\n    match name with\n";
        List.iter
            (fun e ->
                match e.payload with
                | [] -> pr "    | %S -> Some %s\n" e.e_wire (variant_name e.e_wire)
                | fields ->
                    pr "    | %S ->\n      Some\n        (%s\n           {\n" e.e_wire (variant_name e.e_wire);
                    List.iter (fun f -> pr "             %s = %s;\n" (ident f.wire) (decode_field f)) fields;
                    pr "           })\n")
            iface.events;
        pr "    | _ -> None\n\n"
    end

let emit_command c =
    let args =
        List.map (fun f -> Printf.sprintf "%s%s" (if f.optional then "?" else "~") (ident f.wire)) c.params
    in
    let result_type, result =
        match c.returns with
        | [] -> ("unit", None)
        | [ f ] -> (field_type f, Some (decode_field f))
        | _ ->
            let m = module_name c.c_wire ^ "_result" in
            (m ^ ".t", Some (Printf.sprintf "%s.of_json c j" m))
    in
    pr "  let %s ?timeout %s(ch : Channel.t) : %s =\n" (ident c.c_wire)
        (String.concat "" (List.map (fun a -> a ^ " ") args))
        result_type;
    (match c.params with
    | [] -> pr "    let params = `Assoc [] in\n"
    | params ->
        pr "    let params =\n      Json.obj\n        [\n";
        List.iter (fun f -> pr "          %s;\n" (encode_field ~access:Fun.id f)) params;
        pr "        ]\n    in\n");
    match result with
    | None -> pr "    ignore (Channel.call ?timeout ch %S params)\n\n" c.c_wire
    | Some decode ->
        pr "    let j = Channel.call ?timeout ch %S params in\n" c.c_wire;
        if List.length c.returns > 1 || List.exists (fun f -> needs_conn f.ty) c.returns then pr "    let c = Channel.conn ch in\n";
        pr "    %s\n\n" decode

let emit_interface iface =
    pr "module %s = struct\n" (module_name iface.i_wire);
    pr "  let type_name = %S\n\n" iface.i_wire;
    List.iter (emit_def "  ") (List.rev iface.defs);
    emit_events iface;
    List.iter emit_command iface.commands;
    pr "end\n\n"

(* {1 Manifest} *)

let sha256_file path = Digestif.SHA256.(to_hex (digest_string (In_channel.with_open_bin path In_channel.input_all)))

let () =
    let manifest_path, spec_dir =
        match Sys.argv with [| _; m; d |] -> (m, d) | _ -> failwith "usage: gen_protocol MANIFEST SPEC_DIR"
    in
    let manifest = Yojson.Safe.from_file manifest_path in
    let open Yojson.Safe.Util in
    let version = manifest |> member "version" |> to_string in
    let driver = manifest |> member "driver" in
    let expected = manifest |> member "spec" |> to_assoc |> List.map (fun (f, h) -> (f, to_string h)) in
    let files = Sys.readdir spec_dir |> Array.to_list |> List.filter (fun f -> Filename.check_suffix f ".yml") |> List.sort compare in
    if files <> List.sort compare (List.map fst expected) then
        failf "%s does not list exactly the files in %s" manifest_path spec_dir;
    List.iter
        (fun f ->
            let actual = sha256_file (Filename.concat spec_dir f) in
            if actual <> List.assoc f expected then
                failf "%s: SHA-256 %s does not match the manifest; vendor the exact upstream file" f actual)
        files;
    let raw =
        List.concat_map (fun f -> List.map (fun (k, v) -> (k, map_of k v)) (load_yaml (Filename.concat spec_dir f))) files
    in
    check_unique "top-level definition" (List.map fst raw);
    let kinds = Hashtbl.create 64 in
    List.iter (fun (name, spec) -> Hashtbl.replace kinds name (Option.value (find_string "type" spec) ~default:"object")) raw;
    let env = { raw; kinds; globals = Hashtbl.create 64; global_order = []; mixins = Hashtbl.create 8; visiting = [] } in
    let interfaces =
        List.filter_map
            (fun (name, _) ->
                if Hashtbl.find kinds name = "interface" && not (List.mem name excluded_interfaces) then Some (interface env name)
                else None)
            raw
    in
    check_unique "module"
        (List.map (fun i -> module_name i.i_wire) interfaces @ env.global_order @ [ "Json"; "Channel"; "D" ]);
    pr "(* Generated by tools/gen_protocol from the Playwright %s protocol specification.\n   Do not edit: change protocol/ or the generator and run [dune build @gen --auto-promote]. *)\n\n" version;
    pr "[@@@ocaml.warning \"-27-32\"]\n\n";
    pr "module D = Json.Decode\n\n";
    pr "let playwright_version = %S\n" version;
    pr "let driver_tarball = %S\n" (driver |> member "tarball" |> to_string);
    pr "let driver_integrity = %S\n\n" (driver |> member "integrity" |> to_string);
    pr "(* {1 Structures} *)\n\n";
    List.iter (fun name -> emit_def "" (name, Hashtbl.find env.globals name)) (List.rev env.global_order);
    pr "(* {1 Channels} *)\n\n";
    List.iter emit_interface interfaces;
    (* The emitters above indent by two spaces; the project style is four. *)
    let widen line =
        let n = ref 0 in
        while !n < String.length line && line.[!n] = ' ' do incr n done;
        String.make !n ' ' ^ line
    in
    print_string (String.concat "\n" (List.map widen (String.split_on_char '\n' (Buffer.contents buf))))
