
module SCC = struct
  type node = {
    id: string;
    mutable index: int;
    mutable lowlink: int;
    mutable on_stack: bool;
    deps: string list;
  }

  let scc (nodes : (string * string list) list) =
    let index = ref 0 in
    let stack = Stack.create () in
    let map = Hashtbl.create (List.length nodes) in
    List.iter (fun (id, deps) ->
      Hashtbl.add map id { id; index = -1; lowlink = -1; on_stack = false; deps }
    ) nodes;
    let sccs = ref [] in
    let rec strongconnect v =
      v.index <- !index;
      v.lowlink <- !index;
      incr index;
      Stack.push v stack;
      v.on_stack <- true;
      List.iter (fun w_id ->
        match Hashtbl.find_opt map w_id with
        | Some w ->
            if w.index = -1 then begin
              strongconnect w;
              v.lowlink <- min v.lowlink w.lowlink
            end else if w.on_stack then
              v.lowlink <- min v.lowlink w.index
        | None -> ()
      ) v.deps;
      if v.lowlink = v.index then begin
        let scc = ref [] in
        let rec pop_scc () =
          let w = Stack.pop stack in
          w.on_stack <- false;
          scc := w.id :: !scc;
          if w.id <> v.id then pop_scc ()
        in
        pop_scc ();
        sccs := !scc :: !sccs
      end
    in
    Hashtbl.iter (fun _ v ->
      if v.index = -1 then strongconnect v
    ) map;
    List.rev !sccs
end

open Printf

let yml = (
  let ic = open_in "deps/playwright/packages/protocol/src/protocol.yml" in
  let s = really_input_string ic (in_channel_length ic) in
  close_in ic; s
)

let root = match Yaml.of_string_exn yml with `O o -> o | _ -> failwith "no root"

let is_upper c = c >= 'A' && c <= 'Z'
let to_lower c = Char.lowercase_ascii c

let ocaml_name ?(is_type=false) s =
  let buf = Buffer.create (String.length s * 2) in
  String.iteri (fun i c ->
    if is_upper c then (
      if i > 0 && s.[i-1] <> '_' && s.[i-1] <> '-' && 
         not (is_upper s.[i-1] && (i+1 = String.length s || is_upper s.[i+1])) then
        Buffer.add_char buf '_';
      Buffer.add_char buf (to_lower c)
    ) else if c = '-' || c = '$' || c = '.' || c = '@' || c = '{' || c = '}' || c = '|' || c = '"' || c = ' ' then Buffer.add_char buf '_'
    else Buffer.add_char buf c
  ) s;
  let res = Buffer.contents buf in
  let res = Re.replace_string (Re.Pcre.regexp "_+") ~by:"_" res in
  let res = Re.replace_string (Re.Pcre.regexp "^_+") ~by:"" res in
  let res = Re.replace_string (Re.Pcre.regexp "_+$") ~by:"" res in
  let res = if is_type && String.length res > 0 && res.[0] >= 'A' && res.[0] <= 'Z' then
    String.lowercase_ascii (String.sub res 0 1) ^ String.sub res 1 (String.length res - 1)
  else res in
  match res with
  | "type" | "object" | "class" | "end" | "begin" | "in" | "let" | "match" | "with" | "open" | "include"
  | "function" | "method" | "val" | "virtual" | "constraint" | "exception" | "module" | "sig" | "struct"
  | "fun" | "rec" | "mutable" | "private" | "new" | "to" | "downto" | "lazy" | "assert" | "and" | "if"
  | "then" | "else" | "do" | "done" | "while" | "for" | "try" | "as" | "when" -> res ^ "_"
  | _ -> res

let ocaml_type_name s =
  let s = ocaml_name ~is_type:true s in
  if s = "" then "t" else s

let ocaml_field_name _parent_t k = 
  let s = ocaml_name ~is_type:false k in
  let s = if s = "" then "field" else s in
  (* Prevent record field conflicts by prefixing with type name if needed *)
  let s = if String.length s > 0 && s.[0] >= '0' && s.[0] <= '9' then "f_" ^ s else s in
  s

let ocaml_variant_name s = 
  if s = "-inf" then "Minus_inf" else
  if s = "-0" then "Minus_zero" else
  let s = ocaml_name ~is_type:false s in
  if s = "" then "Empty" else
  if s.[0] >= '0' && s.[0] <= '9' then "V_" ^ s else
  String.capitalize_ascii s

type type_desc =
  | TString
  | TInt
  | TFloat
  | TBool
  | TBinary
  | TJson
  | TAny
  | TRef of string
  | TArray of type_desc
  | TObject of (string * type_desc * bool) list
  | TEnum of string list

let flattened_types = Hashtbl.create 100
let queue = Queue.create ()


let rec flatten_props root props_v =
  List.fold_left (fun acc (k, v) ->
    if String.starts_with ~prefix:"$mixin" k then
      match v with
      | `String mixin_name ->
          (match List.assoc_opt mixin_name root with
           | Some (`O m) ->
               let mixin_props = match List.assoc_opt "properties" m with Some (`O p) -> p | _ -> [] in
               acc @ (flatten_props root mixin_props)
           | _ -> acc)
      | _ -> acc
    else
      acc @ [(k, v)]
  ) [] props_v

let rec parse_type path v =
  match v with
  | `String s ->
      let opt = String.ends_with ~suffix:"?" s in
      let s = if opt then String.sub s 0 (String.length s - 1) else s in
      let base_t = match s with
        | "string" -> TString
        | "int" -> TInt
        | "float" -> TFloat
        | "boolean" -> TBool
        | "binary" -> TBinary
        | "json" -> TJson
        | "any" -> TAny
        | _ -> TRef s
      in
      (base_t, opt)
  | `O o ->
      let t_str_v = match List.assoc_opt "type" o with Some (`String s) -> s | _ -> "" in
      let opt = String.ends_with ~suffix:"?" t_str_v in
      let t_str = if opt then String.sub t_str_v 0 (String.length t_str_v - 1) else t_str_v in
      
      if t_str = "object" || t_str = "mixin" || (t_str = "" && List.mem_assoc "properties" o) then begin
        let props_v = match List.assoc_opt "properties" o with Some (`O p) -> p | _ -> [] in
        let props_v = flatten_props root props_v in
        let props = List.map (fun (k, v) ->
          let t, is_opt = parse_type (path ^ "_" ^ k) v in
          (k, t, is_opt)
        ) props_v in
        let t_name = ocaml_type_name path in
        if not (Hashtbl.mem flattened_types t_name) then (
          Hashtbl.add flattened_types t_name (TObject props);
          Queue.push (t_name, TObject props) queue
        );
        (TRef t_name, opt)
      end else if t_str = "array" then begin
        match List.assoc_opt "items" o with
        | Some items_v ->
            let item_t, _ = parse_type (path ^ "_item") items_v in
            (TArray item_t, opt)
        | None -> (TArray TJson, opt)
      end else if t_str = "enum" then begin
        match List.assoc_opt "literals" o with
        | Some (`A l) ->
            let literals = List.map (function `String s -> s | `Null -> "null" | `Float f -> string_of_float f | _ -> "unknown") l in
            let t_name = ocaml_type_name path in
            if not (Hashtbl.mem flattened_types t_name) then (
              Hashtbl.add flattened_types t_name (TEnum literals);
              Queue.push (t_name, TEnum literals) queue
            );
            (TRef t_name, opt)
        | _ -> (TString, opt)
      end else if List.mem_assoc "$mixin" o then begin
        (TRef (match List.assoc_opt "$mixin" o with Some (`String s) -> s | _ -> "json"), opt)
      end else if List.mem_assoc "$mixin1" o then begin
        (TRef (match List.assoc_opt "$mixin1" o with Some (`String s) -> s | _ -> "json"), opt)
      end else begin
        (TAny, opt)
      end
  | _ -> (TAny, false)

let rec extract_deps t acc =
  match t with
  | TRef s ->
      let n = ocaml_type_name s in
      if Hashtbl.mem flattened_types n && not (List.mem n acc) then n :: acc else acc
  | TArray t2 -> extract_deps t2 acc
  | TObject props -> List.fold_left (fun acc (_, pt, _) -> extract_deps pt acc) acc props
  | _ -> acc

let () =
  List.iter (fun (k, v) ->
    let kind = match v with
      | `O o -> (match List.assoc_opt "type" o with Some (`String s) -> s | _ -> "")
      | _ -> ""
    in
    if kind = "object" || kind = "mixin" || kind = "enum" then begin
      ignore (parse_type k v)
    end else if kind = "interface" then begin
      match v with
      | `O o ->
          (match List.assoc_opt "initializer" o with
           | Some (`O props) ->
               ignore (parse_type (k ^ "_initializer") (`O [("type", `String "object"); ("properties", `O props)]))
           | _ -> ());
          (match List.assoc_opt "events" o with
           | Some (`O events) ->
               List.iter (fun (ev_k, ev_v) ->
                 match ev_v with
                 | `O ev_o ->
                     (match List.assoc_opt "parameters" ev_o with
                      | Some (`O props) ->
                          ignore (parse_type (k ^ "_" ^ ev_k ^ "_event") (`O [("type", `String "object"); ("properties", `O props)]))
                      | _ -> ())
                 | _ -> ()
               ) events
           | _ -> ());
          (match List.assoc_opt "commands" o with
           | Some (`O commands) ->
               List.iter (fun (cmd_k, cmd_v) ->
                 match cmd_v with
                 | `O cmd_o ->
                     (match List.assoc_opt "parameters" cmd_o with
                      | Some (`O props) ->
                          ignore (parse_type (k ^ "_" ^ cmd_k ^ "_args") (`O [("type", `String "object"); ("properties", `O props)]))
                      | _ -> ());
                     (match List.assoc_opt "returns" cmd_o with
                      | Some (`O props) ->
                          ignore (parse_type (k ^ "_" ^ cmd_k ^ "_returns") (`O [("type", `String "object"); ("properties", `O props)]))
                      | _ -> ())
                 | _ -> ()
               ) commands
           | _ -> ())
      | _ -> ()
    end
  ) root;

  let nodes = ref [] in
  Hashtbl.iter (fun name t ->
    let deps = extract_deps t [] in
    nodes := (name, deps) :: !nodes
  ) flattened_types;

  let sccs = SCC.scc !nodes in

  let out = open_out "lib/protocol.ml" in
  let pf fmt = fprintf out fmt in
  pf "[@@@ocaml.warning \"-39-32-34\"]\n\n";
  pf "type channel = { guid: string } [@@deriving yojson { strict = false }]\n\n";
  pf "type any = Yojson.Safe.t [@@deriving yojson]\n\n";
  pf "type json = Yojson.Safe.t [@@deriving yojson]\n\n";
  
  let rec ocaml_type_string t =
    match t with
    | TString -> "string"
    | TInt -> "int"
    | TFloat -> "float"
    | TBool -> "bool"
    | TBinary -> "string"
    | TJson -> "json"
    | TAny -> "any"
    | TRef s ->
        let n = ocaml_type_name s in
        if Hashtbl.mem flattened_types n then n
        else "channel"
    | TArray t2 -> ocaml_type_string t2 ^ " list"
    | _ -> "any"
  in

  let generated = Hashtbl.create 100 in
  
  let gen_type prefix name t =
    if not (Hashtbl.mem generated name) then begin
      Hashtbl.add generated name ();
      match t with
      | TEnum literals ->
          pf "%s %s =\n" prefix name;
          pf "  [\n";
          List.iter (fun lit ->
            let variant = ocaml_variant_name lit in
            pf "  | `%s\n" variant
          ) literals;
          pf "  ]\n\n";
          
          let to_yojson = sprintf "%s_to_yojson" name in
          let of_yojson = sprintf "%s_of_yojson" name in
          
          pf "let %s = function\n" to_yojson;
          List.iter (fun lit ->
            let variant = ocaml_variant_name lit in
            pf "  | `%s -> `String \"%s\"\n" variant lit
          ) literals;
          pf "\n";
          
          pf "let %s = function\n" of_yojson;
          List.iter (fun lit ->
            let variant = ocaml_variant_name lit in
            pf "  | `String \"%s\" -> Ok `%s\n" lit variant
          ) literals;
          pf "  | _ -> Error \"Invalid enum %s\"\n\n" name;
      | TObject props ->
          pf "%s %s =\n" prefix name;
          if props = [] then
            pf "  unit [@@deriving yojson]\n\n"
          else begin
            pf "  {\n";
            List.iter (fun (k, pt, opt) ->
              (* Prefix fields with their type to avoid duplicate definition errors *)
              let base_field = ocaml_field_name name k in
              let field = name ^ "_" ^ base_field in
              let t_str = ocaml_type_string pt in
              let final_t_str = if opt then t_str ^ " option" else t_str in
              let default_attr = if opt then " [@default None]" else "" in
              pf "    %s: %s [@key \"%s\"]%s;\n" field final_t_str k default_attr
            ) props;
            pf "  } [@@deriving yojson { strict = false }]\n\n"
          end
      | _ -> ()
    end
  in

  List.iter (fun scc ->
    let first = ref true in
    List.iter (fun name ->
      match Hashtbl.find_opt flattened_types name with
      | Some t ->
          let prefix = if !first then "type" else "and" in
          first := false;
          gen_type prefix name t
      | None -> ()
    ) scc;
  ) sccs;

  close_out out;
  Printf.eprintf "Generated lib/protocol.ml with %d SCCs.\n" (List.length sccs)
