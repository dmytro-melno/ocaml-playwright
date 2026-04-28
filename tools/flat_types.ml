
open Yaml

let parse_file f =
  let ic = open_in f in
  let s = really_input_string ic (in_channel_length ic) in
  close_in ic;
  Yaml.of_string_exn s

let yml = parse_file "deps/playwright/packages/protocol/src/protocol.yml"
let root = match yml with `O o -> o | _ -> failwith "no"

let is_upper c = c >= 'A' && c <= 'Z'
let to_lower c = Char.lowercase_ascii c
let capitalize s = String.capitalize_ascii s

let ocaml_name ?(is_type=false) s =
  let buf = Buffer.create (String.length s * 2) in
  String.iteri (fun i c ->
    if is_upper c then (
      if i > 0 && s.[i-1] <> '_' && s.[i-1] <> '-' && 
         not (is_upper s.[i-1] && (i+1 = String.length s || is_upper s.[i+1])) then
        Buffer.add_char buf '_';
      Buffer.add_char buf (to_lower c)
    ) else if c = '-' || c = '$' then Buffer.add_char buf '_'
    else Buffer.add_char buf c
  ) s;
  let res = Buffer.contents buf in
  let res = if is_type && String.length res > 0 && res.[0] >= 'A' && res.[0] <= 'Z' then
    String.lowercase_ascii (String.sub res 0 1) ^ String.sub res 1 (String.length res - 1)
  else res in
  match res with
  | "type" | "object" | "class" | "end" | "begin" | "in" | "let" | "match" | "with" | "open" | "include"
  | "function" | "method" | "val" | "virtual" | "constraint" | "exception" | "module" | "sig" | "struct"
  | "fun" | "rec" | "mutable" | "private" | "new" | "to" | "downto" | "lazy" | "assert" | "and" | "if"
  | "then" | "else" | "do" | "done" | "while" | "for" | "try" | "as" | "when" -> res ^ "_"
  | _ -> res

let extract_type v =
  match v with
  | `O o -> (match List.assoc_opt "type" o with Some (`String s) -> s | _ -> "")
  | _ -> ""

let rec collect_types path v acc =
  match v with
  | `O o ->
      let t = extract_type v in
      if t = "object" || t = "enum" || t = "mixin" then
        (path, v) :: acc
      else
        List.fold_left (fun acc (k, v2) -> collect_types (path ^ "_" ^ k) v2 acc) acc o
  | `A l -> List.fold_left (fun acc v2 -> collect_types path v2 acc) acc l
  | _ -> acc

let types = List.fold_left (fun acc (k, v) -> collect_types k v acc) [] root
let () = Printf.printf "Found %d types to generate\n" (List.length types)
