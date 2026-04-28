
let yml = File.read "deps/playwright/packages/protocol/src/protocol.yml" () |> Result.get_ok
let protocol = Yaml.of_string_exn yml
let root = match protocol with `O obj -> obj | _ -> failwith "no"
let prop_types = ref []

let rec visit_type (name:string) (v:Yaml.value) =
  match v with
  | `O o ->
      let t = match List.assoc_opt "type" o with Some (`String s) -> s | _ -> "" in
      if t <> "" then prop_types := t :: !prop_types;
      List.iter (fun (k, v2) -> visit_type k v2) o
  | `A l -> List.iter (visit_type name) l
  | _ -> ()

let () =
  List.iter (fun (k,v) -> visit_type k v) root;
  let uniq = List.sort_uniq String.compare !prop_types in
  Printf.printf "Prop types: %s\n" (String.concat ", " uniq)
