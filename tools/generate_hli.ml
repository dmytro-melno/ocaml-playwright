
open Printf

let yml_str = (
  let ic = open_in "deps/playwright/packages/protocol/src/protocol.yml" in
  let s = really_input_string ic (in_channel_length ic) in
  close_in ic; s
)

let root = match Yaml.of_string_exn yml_str with `O o -> o | _ -> failwith "no root"

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


let interfaces = Hashtbl.create 10

let () =
  List.iter (fun (k, v) ->
    let kind = match v with `O o -> (match List.assoc_opt "type" o with Some (`String s) -> s | _ -> "") | _ -> "" in
    if kind = "interface" then Hashtbl.add interfaces k true
  ) root

let rec get_properties path p =
  let props = List.filter (fun (k, _) -> k <> "$mixin" && k <> "$mixin1" && k <> "$mixin2") p in
  let mixins = List.filter_map (fun mixin_key ->
    match List.assoc_opt mixin_key p with
    | Some (`String s) -> (
        match List.assoc_opt s root with
        | Some (`O m) -> (
            match List.assoc_opt "properties" m with
            | Some (`O m_p) -> Some (get_properties path m_p)
            | _ -> None
          )
        | _ -> None
      )
    | _ -> None
  ) ["$mixin"; "$mixin1"; "$mixin2"] in
  props @ List.concat mixins

let flatten_props props =
  let aux props acc =
    List.fold_left (fun acc p ->
      let k = fst p in
      if not (List.exists (fun (k', _) -> k = k') acc) then p :: acc else acc
    ) acc props
  in
  aux props []

let is_optional pv =
  let type_str = match pv with
    | `O po -> (match List.assoc_opt "type" po with Some (`String s) -> s | _ -> "")
    | `String s -> s | _ -> ""
  in
  String.ends_with ~suffix:"?" type_str


let out = open_out "lib/hl.mli"
let pf fmt = fprintf out fmt

let () =
  pf "[@@@ocaml.warning \"-39-32-34-27-26-33\"]\n\n";
  pf "open Protocol\n\n";
  pf "exception Error of string\n\n";
  pf "\n";

  List.iter (fun (k, (v: Yaml.value)) ->
    if Hashtbl.mem interfaces k then begin
      let module_name = String.capitalize_ascii (ocaml_name k) in
      pf "module %s : sig\n" module_name;
      pf "  type t\n\n";
      match v with
      | `O o ->
          (match List.assoc_opt "initializer" o with
           | Some (`O init_props) ->
               List.iter (fun (_prop_k, prop_v) ->
                 let type_str_ret = match prop_v with
                   | `O ro -> (match List.assoc_opt "type" ro with Some (`String s) -> s | _ -> "")
                   | `String s -> s | _ -> ""
                 in
                 let is_opt = is_optional prop_v in
                 let type_str_base = if is_opt then String.sub type_str_ret 0 (String.length type_str_ret - 1) else type_str_ret in

                 if Hashtbl.mem interfaces type_str_base then begin
                   ()
                 end
               ) init_props
           | _ -> ());

          (match List.assoc_opt "commands" o with
           | Some (`O commands) ->
               commands |> List.iter (fun (cmd_k, cmd_v) ->
                 match cmd_v with
                 | `O cmd_o ->
                     let fn_name = ocaml_name cmd_k in

                     let props = match List.assoc_opt "parameters" cmd_o with
                       | Some (`O p) -> flatten_props (get_properties "" p)
                       | _ -> []
                     in
                     let rets = match List.assoc_opt "returns" cmd_o with
                       | Some (`O p) -> flatten_props (get_properties "" p)
                       | _ -> []
                     in

                    let args_sig =
                      props |> List.rev |> List.map (fun (pk, pv) ->
                        let ocaml_pk = ocaml_name pk in
                        let typename_, is_opt = parse_type pk pv in
                        let typename_ = ocaml_type_string typename_ in
                        if is_opt then
                          sprintf "?%s:%s" ocaml_pk typename_
                        else
                          sprintf "%s:%s" ocaml_pk typename_
                      )
                      |> String.concat " -> "
                    in

                     let ret_ty =
                        if List.length rets = 1 then begin
                          let (_rk, rv) = List.hd rets in
                          let type_str_ret = match rv with
                            | `O ro -> (match List.assoc_opt "type" ro with Some (`String s) -> s | _ -> "")
                            | `String s -> s | _ -> ""
                          in
                          type_str_ret
                        end else "unit"
                     in

                     pf "  val %s : %s -> t -> %s\n" fn_name args_sig ret_ty;
                 | _ -> ()
               )
           | _ -> ());

          (match List.assoc_opt "events" o with
           | Some (`O events) ->
               List.iter (fun (ev_k, ev_v) ->
                  match ev_v with
                  | `O ev_o ->
                      let fn_name = "on_" ^ ocaml_name ev_k in
                      let raw_event_t = k ^ "_" ^ ev_k ^ "_event" in

                      let has_params = match List.assoc_opt "parameters" ev_o with
                        | Some (`O _) -> true
                        | _ -> false
                      in

                      if has_params then begin
                        pf "  val %s : (%s -> unit) -> t -> unit\n" fn_name (ocaml_type_name raw_event_t);
                        pf "  val wait_for_%s : ?predicate:(%s -> bool) -> t -> %s\n" (ocaml_name ev_k) (ocaml_type_name raw_event_t) (ocaml_type_name raw_event_t);
                      end else begin
                        pf "  val %s : (%s -> unit) -> t -> unit\n" fn_name (ocaml_type_name raw_event_t);
                        pf "  val wait_for_%s : t -> %s\n" (ocaml_name ev_k) (ocaml_type_name raw_event_t);
                     end
                  | _ -> ()
               ) events
           | _ -> ());

          pf "and\n\n"
      | _ -> pf "end\n\n"
    end
  ) root;
  close_out out;
  Printf.printf "Generated lib/hl.mli\n"
