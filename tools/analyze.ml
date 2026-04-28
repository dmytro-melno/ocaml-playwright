
let yaml = Yaml.of_string_exn (
  let ic = open_in "deps/playwright/packages/protocol/src/protocol.yml" in
  let s = really_input_string ic (in_channel_length ic) in
  close_in ic; s
)

let root = match yaml with `O o -> o | _ -> failwith "no root"

let prop_types = Hashtbl.create 10

let rec visit path v =
  match v with
  | `String s -> Hashtbl.replace prop_types s ()
  | `O o -> 
      (match List.assoc_opt "type" o with
      | Some (`String s) -> Hashtbl.replace prop_types s ()
      | _ -> ());
      List.iter (fun (k,v) -> visit (path ^ "." ^ k) v) o
  | `A l -> List.iter (visit path) l
  | _ -> ()

let () =
  List.iter (fun (k,v) -> visit k v) root;
  let seq = Hashtbl.fold (fun k _ acc -> k :: acc) prop_types [] |> List.sort_uniq String.compare in
  Printf.printf "Types: %s\n" (String.concat ", " seq)
