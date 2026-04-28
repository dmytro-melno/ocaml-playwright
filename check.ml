
let yml = File.read "deps/playwright/packages/protocol/src/protocol.yml" () |> Result.get_ok;;
let protocol = Yaml.of_string_exn yml;;
let types = match protocol with `O obj -> obj | _ -> failwith "no";;
let get_prop_type (name, v) = 
  match v with
  | `O obj -> (match List.assoc_opt "type" obj with Some (`String s) -> Some s | _ -> None)
  | _ -> None
;;
let all_kinds = List.filter_map get_prop_type types |> List.sort_uniq String.compare;;
Printf.printf "Kinds: %s\n" (String.concat ", " all_kinds);;
