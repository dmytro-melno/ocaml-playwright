
let yml = (
  let ic = open_in "deps/playwright/packages/protocol/src/protocol.yml" in
  let s = really_input_string ic (in_channel_length ic) in
  close_in ic; s
)

let root = match Yaml.of_string_exn yml with `O o -> o | _ -> failwith "no root"

let enum_deps = ref false
let rec check_enum_deps v =
  match v with
  | `O o ->
      let kind = match List.assoc_opt "type" o with Some (`String s) -> s | _ -> "" in
      if kind = "enum" then begin
         (* does it have dependencies? No, enum definition in protocol.yml just has literals *)
         ()
      end;
      List.iter (fun (_, v2) -> check_enum_deps v2) o
  | `A l -> List.iter check_enum_deps l
  | _ -> ()

let _ = check_enum_deps root
