
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
  let res = Str.global_replace (Str.regexp "_+") "_" res in
  let res = Str.global_replace (Str.regexp "^_+") "" res in
  let res = Str.global_replace (Str.regexp "_+$") "" res in
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

let out = open_out "lib/api.ml"
let pf fmt = fprintf out fmt

let () =
  pf "[@@@ocaml.warning \"-39-32-34\"]\n\n";
  pf "open Protocol\n\n";
  List.iter (fun (k, (v: Yaml.value)) ->
    let kind = match v with
      | `O o -> (match List.assoc_opt "type" o with Some (`String s) -> s | _ -> "")
      | _ -> ""
    in
    if kind = "interface" then begin
      let module_name = String.capitalize_ascii (ocaml_name k) in
      pf "module %s = struct\n" module_name;
      match v with
      | `O o ->
          (match List.assoc_opt "commands" o with
           | Some (`O commands) ->
               List.iter (fun (cmd_k, (cmd_v: Yaml.value)) ->
                 match cmd_v with
                 | `O cmd_o ->
                     let fn_name = ocaml_name cmd_k in
                     let args_t = 
                       match List.assoc_opt "parameters" cmd_o with
                       | Some (`O _) -> Some (ocaml_type_name (k ^ "_" ^ cmd_k ^ "_args"))
                       | _ -> None
                     in
                     let ret_t = 
                       match List.assoc_opt "returns" cmd_o with
                       | Some (`O _) -> Some (ocaml_type_name (k ^ "_" ^ cmd_k ^ "_returns"))
                       | _ -> None
                     in
                     
                     let args_str = match args_t with
                       | Some t -> sprintf " (args : %s)" t
                       | None -> " ()"
                     in
                     let ret_str = match ret_t with
                       | Some t -> sprintf "%s" t
                       | None -> "unit"
                     in
                     pf "  let %s (conn : Connection.t) (guid : string)%s : (%s, string) result =\n" fn_name args_str ret_str;
                     let params_str = match args_t with
                       | Some t -> sprintf "%s_to_yojson args" t
                       | None -> "`Assoc []"
                     in
                     pf "    match Connection.send_message conn ~guid ~method_:\"%s\" ~params:(%s) with\n" cmd_k params_str;
                     (match ret_t with
                      | Some t ->
                          pf "    | Ok res -> %s_of_yojson res\n" t
                      | None ->
                          pf "    | Ok _res -> Ok ()\n");
                     pf "    | Error e -> Error e\n\n"
                 | _ -> ()
               ) commands
           | _ -> ());
          pf "end\n\n"
      | _ -> pf "end\n\n"
    end
  ) root;
  close_out out;
  Printf.printf "Generated lib/api.ml\n"
