
let () =
  let content = In_channel.with_open_text "deps/playwright/packages/protocol/src/protocol.yml" In_channel.input_all in
  let yaml = Yaml.of_string_exn content in
  let dict = match yaml with `O d -> d | _ -> [] in
  match List.assoc_opt "APIResponse" dict with
  | Some (`O d) ->
    (match List.assoc_opt "type" d with
     | Some (`String s) -> Printf.printf "APIResponse type: %s\n" s
     | _ -> Printf.printf "No type for APIResponse\n")
  | _ -> Printf.printf "APIResponse not found\n"
