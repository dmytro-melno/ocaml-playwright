
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

let out = open_out "lib/hl.ml"
let pf fmt = fprintf out fmt

let () =
  pf "[@@@ocaml.warning \"-39-32-34-27-26-33\"]\n\n";
  pf "open Protocol\n\n";
  pf "exception Error of string\n\n";
  pf "type 'a obj = { conn: Connection.t; guid: string }\n\n";
  Hashtbl.iter (fun k _ ->
    pf "type %s_type\n" (ocaml_type_name k)
  ) interfaces;
  pf "\n";
  
  List.iter (fun (k, (v: Yaml.value)) ->
    if Hashtbl.mem interfaces k then begin
      let module_name = String.capitalize_ascii (ocaml_name k) in
      pf "module %s = struct\n" module_name;
      pf "  type t = %s_type obj\n\n" (ocaml_type_name k);
      match v with
      | `O o ->
          (match List.assoc_opt "initializer" o with
           | Some (`O init_props) ->
               List.iter (fun (prop_k, prop_v) ->
                 let type_str_ret = match prop_v with 
                   | `O ro -> (match List.assoc_opt "type" ro with Some (`String s) -> s | _ -> "") 
                   | `String s -> s | _ -> "" 
                 in
                 let is_opt = is_optional prop_v in
                 let type_str_base = if is_opt then String.sub type_str_ret 0 (String.length type_str_ret - 1) else type_str_ret in
                 
                 if Hashtbl.mem interfaces type_str_base then begin
                   pf "  let %s (t : t) =\n" (ocaml_name prop_k);
                   pf "    match Hashtbl.find_opt t.conn.objects t.guid with\n";
                   pf "    | Some obj ->\n";
                   pf "        let open Yojson.Safe.Util in\n";
                   if is_opt then begin
                     pf "        (try Some ({ conn = t.conn; guid = member \"%s\" obj.initializer_ |> member \"guid\" |> to_string } : %s_type obj)\n" prop_k (ocaml_type_name type_str_base);
                     pf "         with _ -> None)\n"
                   end else begin
                     pf "        (try ({ conn = t.conn; guid = member \"%s\" obj.initializer_ |> member \"guid\" |> to_string } : %s_type obj)\n" prop_k (ocaml_type_name type_str_base);
                     pf "         with _ -> failwith \"Missing required initializer property %s\")\n" prop_k
                   end;
                   pf "    | None -> failwith \"Object not found in connection\"\n\n"
                 end
               ) init_props
           | _ -> ());
      
          (match List.assoc_opt "commands" o with
           | Some (`O commands) ->
               List.iter (fun (cmd_k, cmd_v) ->
                 match cmd_v with
                 | `O cmd_o ->
                     let fn_name = ocaml_name cmd_k in
                     let raw_args_t = k ^ "_" ^ cmd_k ^ "_args" in
                     
                     let props = match List.assoc_opt "parameters" cmd_o with
                       | Some (`O p) -> flatten_props (get_properties "" p)
                       | _ -> []
                     in
                     let rets = match List.assoc_opt "returns" cmd_o with
                       | Some (`O p) -> flatten_props (get_properties "" p)
                       | _ -> []
                     in
                     
                     let args_sig = Buffer.create 100 in
                     List.iter (fun (pk, pv) ->
                       let is_opt = is_optional pv in
                       let ocaml_pk = ocaml_name pk in
                       if is_opt then
                         Buffer.add_string args_sig (sprintf "?%s " ocaml_pk)
                       else
                         Buffer.add_string args_sig (sprintf "~%s " ocaml_pk)
                     ) props;
                     
                     pf "  let %s %s(t : t) =\n" fn_name (Buffer.contents args_sig);
                     
                     if List.length props > 0 then begin
                       pf "    let args : Protocol.%s = {\n" (ocaml_type_name raw_args_t);
                       List.iter (fun (pk, pv) ->
                         let type_str = match pv with 
                           | `O po -> (match List.assoc_opt "type" po with Some (`String s) -> s | _ -> "") 
                           | `String s -> s | _ -> "" 
                         in
                         let is_bin = (type_str = "binary" || type_str = "binary?") in
                         let ocaml_pk = ocaml_name pk in
                         let field_name = ocaml_name pk in
                         if is_bin then begin
                           if is_optional pv then
                             pf "      Protocol.%s = Option.map Base64.encode_exn %s;\n" field_name ocaml_pk
                           else
                             pf "      Protocol.%s = Base64.encode_exn %s;\n" field_name ocaml_pk
                         end else begin
                           pf "      Protocol.%s = %s;\n" field_name ocaml_pk
                         end
                       ) props;
                       pf "    } in\n"
                     end;
                     
                     let params_str = if List.length props > 0 then "args" else "()" in
                     pf "    match Api.%s.%s t.conn t.guid %s with\n" module_name fn_name params_str;
                     
                     if List.length rets = 0 then
                       pf "    | Ok _res -> ()\n"
                     else if List.length rets = 1 then begin
                       let (rk, rv) = List.hd rets in
                       let type_str_ret = match rv with 
                         | `O ro -> (match List.assoc_opt "type" ro with Some (`String s) -> s | _ -> "") 
                         | `String s -> s | _ -> "" 
                       in
                       let is_bin = (type_str_ret = "binary" || type_str_ret = "binary?") in
                       
                       let field_name = ocaml_name rk in
                       
                       if Hashtbl.mem interfaces type_str_ret then
                         pf "    | Ok res -> ({ conn = t.conn; guid = res.Protocol.%s.guid } : %s_type obj)\n" field_name (ocaml_type_name type_str_ret)
                       else if is_bin then begin
                         if is_optional rv then
                           pf "    | Ok res -> Option.map Base64.decode_exn res.Protocol.%s\n" field_name
                         else
                           pf "    | Ok res -> Base64.decode_exn res.Protocol.%s\n" field_name
                       end else
                         pf "    | Ok res -> res.Protocol.%s\n" field_name
                     end else begin
                       pf "    | Ok res -> res\n"
                     end;
                     pf "    | Error e -> raise (Error e)\n\n"
                 | _ -> ()
               ) commands
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
                       pf "  let %s (t : t) cb =\n" fn_name;
                       pf "    let _id = Connection.add_listener t.conn t.guid \"%s\" (fun msg ->\n" ev_k;
                       pf "      match Protocol.%s_of_yojson msg with\n" (ocaml_type_name raw_event_t);
                       pf "      | Ok ev -> cb ev\n";
                       pf "      | Error _ -> ()\n";
                       pf "    ) in ()\n\n";
                       pf "  let wait_for_%s ?predicate (t : t) =\n" (ocaml_name ev_k);
                       pf "    let p, r = Eio.Promise.create () in\n";
                       pf "    let id = ref (-1) in\n";
                       pf "    id := Connection.add_listener t.conn t.guid \"%s\" (fun msg ->\n" ev_k;
                       pf "      match Protocol.%s_of_yojson msg with\n" (ocaml_type_name raw_event_t);
                       pf "      | Ok ev ->\n";
                       pf "          let is_match = match predicate with Some f -> (try f ev with _ -> false) | None -> true in\n";
                       pf "          if is_match then begin\n";
                       pf "            Connection.remove_listener t.conn t.guid \"%s\" !id;\n" ev_k;
                       pf "            if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ev\n";
                       pf "          end\n";
                       pf "      | Error _ -> ()\n";
                       pf "    );\n";
                       pf "    Eio.Promise.await p\n\n"
                     end else begin
                       pf "  let %s (t : t) cb =\n" fn_name;
                       pf "    let _id = Connection.add_listener t.conn t.guid \"%s\" (fun _msg -> cb ()) in ()\n\n" ev_k;
                       pf "  let wait_for_%s (t : t) =\n" (ocaml_name ev_k);
                       pf "    let p, r = Eio.Promise.create () in\n";
                       pf "    let id = ref (-1) in\n";
                       pf "    id := Connection.add_listener t.conn t.guid \"%s\" (fun _msg ->\n" ev_k;
                       pf "      Connection.remove_listener t.conn t.guid \"%s\" !id;\n" ev_k;
                       pf "      if not (Eio.Promise.is_resolved p) then Eio.Promise.resolve r ()\n";
                       pf "    );\n";
                       pf "    Eio.Promise.await p\n\n"
                     end
                 | _ -> ()
               ) events
           | _ -> ());
           
          pf "end\n\n"
      | _ -> pf "end\n\n"
    end
  ) root;
  close_out out;
  Printf.printf "Generated lib/hl.ml\n"
