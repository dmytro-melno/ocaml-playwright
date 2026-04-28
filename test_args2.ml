
open Printf
let yml_str = (
  let ic = open_in "deps/playwright/packages/protocol/src/protocol.yml" in
  let s = really_input_string ic (in_channel_length ic) in
  close_in ic; s
)

let root = match Yaml.of_string_exn yml_str with `O o -> o | _ -> failwith "no root"

let check_cmd iface cmd_name =
  match List.assoc_opt iface root with
  | Some (`O o) ->
      (match List.assoc_opt "commands" o with
       | Some (`O cmds) ->
           (match List.assoc_opt cmd_name cmds with
            | Some (`O cmd) ->
                (match List.assoc_opt "parameters" cmd with
                 | Some (`O p) ->
                     List.iter (fun (k, pv) ->
                       let type_str = match pv with 
                         | `O po -> (match List.assoc_opt "type" po with Some (`String s) -> s | _ -> "") 
                         | `String s -> s | _ -> "" 
                       in
                       let is_opt = String.ends_with ~suffix:"?" type_str in
                       Printf.printf "%s.%s Param: %s -> %s (optional: %b)\n" iface cmd_name k type_str is_opt
                     ) p
                 | _ -> ())
            | _ -> ())
       | _ -> ())
  | _ -> ()

let () =
  check_cmd "Frame" "goto";
  check_cmd "Page" "screenshot"
