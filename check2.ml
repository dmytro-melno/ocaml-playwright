
let yml = File.read "deps/playwright/packages/protocol/src/protocol.yml" () |> Result.get_ok;;
let protocol = Yaml.of_string_exn yml;;
let root = match protocol with `O obj -> obj | _ -> failwith "no";;
let find_nested () = 
  List.iter (fun (k, v) ->
    match v with
    | `O o ->
        (match List.assoc_opt "properties" o with
        | Some (`O props) ->
            List.iter (fun (pk, pv) ->
              match pv with
              | `O _ -> Printf.printf "Type %s has nested obj %s\n" k pk
              | _ -> ()
            ) props
        | _ -> ())
    | _ -> ()
  ) root
;;
find_nested ()
