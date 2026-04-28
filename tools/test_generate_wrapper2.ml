
[@@@ocaml.warning "-32-33-39"]
open Yaml
open Printf

let yml_str = (
  let ic = open_in "deps/playwright/packages/protocol/src/protocol.yml" in
  let s = really_input_string ic (in_channel_length ic) in
  close_in ic; s
)

let root = match Yaml.of_string_exn yml_str with `O o -> o | _ -> failwith "no root"

let interfaces = Hashtbl.create 10

let () =
  List.iter (fun (k, v) ->
    let kind = match v with `O o -> (match List.assoc_opt "type" o with Some (`String s) -> s | _ -> "") | _ -> "" in
    if kind = "interface" then Hashtbl.add interfaces k true
  ) root

let get_returns cmd_o =
  match List.assoc_opt "returns" cmd_o with
  | Some (`O p) -> p
  | _ -> []

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
                     let rets = get_returns cmd_o in
                     if List.length rets > 0 then begin
                       Printf.printf "%s.%s returns:\n" k cmd_k;
                       List.iter (fun (rk, rv) ->
                         let type_str = match rv with 
                           | `O ro -> (match List.assoc_opt "type" ro with Some (`String s) -> s | _ -> "") 
                           | `String s -> s 
                           | _ -> "" 
                         in
                         Printf.printf "  %s : %s\n" rk type_str
                       ) rets
                     end
                 | _ -> ()
               ) commands
           | _ -> ())
      | _ -> ()
    end
  ) root
