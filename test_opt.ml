
let yml_str = (
  let ic = open_in "deps/playwright/packages/protocol/src/protocol.yml" in
  let s = really_input_string ic (in_channel_length ic) in
  close_in ic; s
)

let root = match Yaml.of_string_exn yml_str with `O o -> o | _ -> failwith "no root"

let () =
  match List.assoc_opt "EventTarget" root with
  | Some (`O o) ->
      (match List.assoc_opt "commands" o with
       | Some (`O cmds) ->
           (match List.assoc_opt "waitForEventInfo" cmds with
            | Some (`O cmd) ->
                (match List.assoc_opt "parameters" cmd with
                 | Some (`O p) ->
                     List.iter (fun (k, pv) ->
                       let type_str = match pv with 
                         | `O po -> (match List.assoc_opt "type" po with Some (`String s) -> s | _ -> "") 
                         | `String s -> s | _ -> "" 
                       in
                       let has_props = match pv with `O po -> List.mem_assoc "properties" po | _ -> false in
                       Printf.printf "Key: %s, type_str: %s, has_props: %b, ends_with ?: %b\n" k type_str has_props (String.ends_with ~suffix:"?" type_str)
                     ) p
                 | _ -> ())
            | _ -> ())
       | _ -> ())
  | _ -> ()
