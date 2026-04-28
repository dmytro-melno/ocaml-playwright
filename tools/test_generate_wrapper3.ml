
[@@@ocaml.warning "-32-33-39"]
open Yaml
open Printf

let yml_str = (
  let ic = open_in "deps/playwright/packages/protocol/src/protocol.yml" in
  let s = really_input_string ic (in_channel_length ic) in
  close_in ic; s
)

let root = match Yaml.of_string_exn yml_str with `O o -> o | _ -> failwith "no root"

let get_properties o =
  let props = List.filter (fun (k, _) -> k <> "$mixin" && k <> "$mixin1" && k <> "$mixin2") o in
  let mixins = List.filter_map (fun mixin_key ->
    match List.assoc_opt mixin_key o with
    | Some (`String s) -> (
        match List.assoc_opt s root with
        | Some (`O m) -> 
            (match List.assoc_opt "properties" m with Some (`O p) -> Some p | _ -> None)
        | _ -> None
      )
    | _ -> None
  ) ["$mixin"; "$mixin1"; "$mixin2"] in
  props @ List.concat mixins

let () =
  match List.assoc_opt "BrowserType" root with
  | Some (`O o) ->
      (match List.assoc_opt "commands" o with
       | Some (`O cmds) ->
           (match List.assoc_opt "launch" cmds with
            | Some (`O cmd) ->
                (match List.assoc_opt "parameters" cmd with
                 | Some (`O p) ->
                     let props = get_properties p in
                     Printf.printf "launch params:\n";
                     List.iter (fun (k, _) -> Printf.printf "  %s\n" k) props
                 | _ -> ())
            | _ -> ())
       | _ -> ())
  | _ -> ()

let () =
  match List.assoc_opt "APIRequestContext" root with
  | Some (`O o) ->
      (match List.assoc_opt "commands" o with
       | Some (`O cmds) ->
           (match List.assoc_opt "fetch" cmds with
            | Some (`O cmd) ->
                (match List.assoc_opt "parameters" cmd with
                 | Some (`O p) ->
                     let props = get_properties p in
                     Printf.printf "fetch params:\n";
                     List.iter (fun (k, _) -> Printf.printf "  %s\n" k) props
                 | _ -> ())
            | _ -> ())
       | _ -> ())
  | _ -> ()
