
[@@@ocaml.warning "-32-33-39"]
open Yaml
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

let interfaces = Hashtbl.create 10

let () =
  List.iter (fun (k, v) ->
    let kind = match v with `O o -> (match List.assoc_opt "type" o with Some (`String s) -> s | _ -> "") | _ -> "" in
    if kind = "interface" then Hashtbl.add interfaces k true
  ) root

let rec get_properties path o =
  let props = match List.assoc_opt "properties" o with Some (`O p) -> p | _ -> [] in
  let mixins = List.filter_map (fun mixin_key ->
    match List.assoc_opt mixin_key o with
    | Some (`String s) -> (
        match List.assoc_opt s root with
        | Some (`O m) -> Some (get_properties path m)
        | _ -> None
      )
    | _ -> None
  ) ["$mixin"; "$mixin1"; "$mixin2"] in
  props @ List.concat mixins

let flatten_props props =
  let rec aux props acc =
    List.fold_left (fun acc p ->
      let k = fst p in
      if not (List.exists (fun (k', _) -> k = k') acc) then p :: acc else acc
    ) acc props
  in
  aux props []

let () =
  List.iter (fun (k, (v: Yaml.value)) ->
    if Hashtbl.mem interfaces k then begin
      match v with
      | `O o ->
          (match List.assoc_opt "commands" o with
           | Some (`O commands) ->
               List.iter (fun (cmd_k, cmd_v) ->
                 match cmd_v with
                 | `O cmd_o ->
                     let props = match List.assoc_opt "parameters" cmd_o with
                       | Some (`O p) -> flatten_props (get_properties "" p)
                       | _ -> []
                     in
                     Printf.printf "%s.%s:\n" k cmd_k;
                     List.iter (fun (pk, pv) ->
                       let type_str = match pv with `O po -> (match List.assoc_opt "type" po with Some (`String s) -> s | _ -> "") | _ -> "" in
                       let is_opt = String.ends_with ~suffix:"?" type_str || (match pv with `O po -> List.mem_assoc "properties" po | _ -> false) in
                       Printf.printf "  %s%s\n" pk (if is_opt then " (optional)" else "")
                     ) props
                 | _ -> ()
               ) commands
           | _ -> ())
      | _ -> ()
    end
  ) root
