
open Printf

let yml_str = (
  let ic = open_in "deps/playwright/packages/protocol/src/protocol.yml" in
  let s = really_input_string ic (in_channel_length ic) in
  close_in ic; s
)

let root = match Yaml.of_string_exn yml_str with `O o -> o | _ -> failwith "no root"

let () =
  match List.assoc_opt "Page" root with
  | Some (`O o) ->
      (match List.assoc_opt "events" o with
       | Some (`O events) ->
           List.iter (fun (ev_k, ev_v) ->
             Printf.printf "Event: %s\n" ev_k;
             match ev_v with
             | `O ev_o ->
                 (match List.assoc_opt "parameters" ev_o with
                  | Some (`O p) ->
                      List.iter (fun (pk, pv) ->
                        let type_str = match pv with 
                          | `O po -> (match List.assoc_opt "type" po with Some (`String s) -> s | _ -> "") 
                          | `String s -> s | _ -> "" 
                        in
                        Printf.printf "  %s : %s\n" pk type_str
                      ) p
                  | _ -> ())
             | _ -> ()
           ) events
       | _ -> ())
  | _ -> ()
