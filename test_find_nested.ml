
let () =
  let content = In_channel.with_open_text "deps/playwright/packages/protocol/src/protocol.yml" In_channel.input_all in
  let yaml = Yaml.of_string_exn content in
  let dict = match yaml with `O d -> d | _ -> [] in
  let mixins = dict |> List.filter_map (fun (k, v) ->
    let d = match v with `O d -> d | _ -> [] in
    match List.assoc_opt "type" d with
    | Some (`String "mixin") -> Some (k, match List.assoc_opt "properties" d with Some (`O p) -> p | _ -> [])
    | _ -> None
  ) in
  let is_interface name =
    List.exists (fun (k, v) ->
        if k = name then
            let d = match v with `O d -> d | _ -> [] in
            match List.assoc_opt "type" d with
            | Some (`String "interface") -> true
            | _ -> false
        else false
    ) dict
  in
  let rec find_interfaces_in_props path d =
    d |> List.iter (fun (k, v) ->
      match v with
      | `String s ->
        let s = String.trim s in
        let s = if String.ends_with ~suffix:"?" s then String.sub s 0 (String.length s - 1) else s in
        if is_interface s then Printf.printf "Found interface %s in %s.%s\n" s path k
      | `O o_d ->
        find_interfaces_in_props (path ^ "." ^ k) (match List.assoc_opt "properties" o_d with Some (`O p) -> p | _ -> []);
        (match List.assoc_opt "items" o_d with
         | Some i -> find_interfaces_in_props (path ^ "." ^ k ^ "[0]") [("items", i)]
         | None -> ())
      | _ -> ()
    )
  in
  dict |> List.iter (fun (k, v) ->
    let d = match v with `O d -> d | _ -> [] in
    match List.assoc_opt "type" d with
    | Some (`String "interface") ->
      (match List.assoc_opt "commands" d with
       | Some (`O cmds) ->
         cmds |> List.iter (fun (cmd_name, cmd_v) ->
           let cmd_d = match cmd_v with `O d -> d | _ -> [] in
           match List.assoc_opt "returns" cmd_d with
           | Some (`O ret_d) -> find_interfaces_in_props (k ^ "." ^ cmd_name) ret_d
           | _ -> ()
         )
       | _ -> ())
    | _ -> ()
  )
