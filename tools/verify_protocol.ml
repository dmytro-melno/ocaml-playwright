(* Offline provenance gate. The manifest is also the driver's version authority. *)
let () =
    if Array.length Sys.argv <> 4 then
        failwith "usage: verify_protocol (check|ml) protocol.yml provenance.json";
    let content = In_channel.with_open_bin Sys.argv.(2) In_channel.input_all in
    let manifest = Yojson.Safe.from_file Sys.argv.(3) in
    let open Yojson.Safe.Util in
    let version = manifest |> member "version" |> to_string in
    let source = manifest |> member "source" |> to_string in
    let expected = manifest |> member "sha256" |> to_string in
    let source_for_version =
        "https://raw.githubusercontent.com/microsoft/playwright/v" ^ version ^
        "/packages/protocol/src/protocol.yml" in
    if source <> source_for_version then
        failwith "protocol provenance: source URL does not match version";
    let actual = Digestif.SHA256.(to_hex (digest_string content)) in
    if actual <> expected then
        failwith (Printf.sprintf "protocol provenance: SHA-256 mismatch (expected %s, got %s); vendor the exact pinned schema" expected actual);
    match Sys.argv.(1) with
    | "check" -> Printf.printf "Verified Playwright %s protocol SHA-256 %s\n" version actual
    | "ml" ->
        Printf.printf "(* Generated from protocol/provenance.json; do not edit. *)\nlet version = %S\nlet source = %S\nlet sha256 = %S\n" version source actual
    | _ -> failwith "verify_protocol: expected check or ml"
