
let version = "1.59.1"

let cache_dir () =
  let home =
    match Sys.getenv_opt "HOME" with
    | Some h -> h
    | None ->
      match Sys.getenv_opt "USERPROFILE" with
      | Some h -> h
      | None -> failwith "Could not determine home directory"
  in
  Filename.concat home ".cache/playwright-ocaml-driver"

let driver_dir () =
  Filename.concat (cache_dir ()) version

let get_zip_name () =
  let os = Sys.os_type in
  if os = "Win32" || os = "Cygwin" then
    "win32_x64" (* TODO: detect arm64 *)
  else
    let uname_s =
      let ic = Unix.open_process_in "uname -s" in
      let res = input_line ic in
      close_in ic;
      String.trim res
    in
    let uname_m =
      let ic = Unix.open_process_in "uname -m" in
      let res = input_line ic in
      close_in ic;
      String.trim res
    in
    match uname_s, uname_m with
    | "Darwin", "arm64" -> "mac-arm64"
    | "Darwin", ("x86_64" | "amd64") -> "mac"
    | "Linux", ("x86_64" | "amd64") -> "linux"
    | "Linux", ("aarch64" | "arm64") -> "linux-arm64"
    | _ ->
      failwith
        (Printf.sprintf
           "Unsupported platform for bundled Playwright driver: %s/%s"
           uname_s
           uname_m)

let download () =
  let dir = driver_dir () in
  if not (Sys.file_exists dir) then begin
    let _ = Sys.command (Printf.sprintf "mkdir -p %s" dir) in
    let zip_name = get_zip_name () in
    let url = Printf.sprintf "https://cdn.playwright.dev/builds/driver/playwright-%s-%s.zip" version zip_name in
    let zip_path = Filename.concat dir "driver.zip" in
    Printf.printf "Downloading Playwright driver %s to %s...\n%!" version dir;
    let res = Sys.command (Printf.sprintf "curl -sL %s -o %s" (Filename.quote url) (Filename.quote zip_path)) in
    if res <> 0 then failwith "Failed to download Playwright driver";
    let res = Sys.command (Printf.sprintf "cd %s && unzip -q driver.zip && rm driver.zip" (Filename.quote dir)) in
    if res <> 0 then failwith "Failed to unzip Playwright driver";
    Printf.printf "Driver downloaded successfully.\n%!";
  end;
  dir

let run ~sw ~process_mgr ?env ?stdin ?stdout ?stderr () =
  let dir = download () in
  let cli_path = Filename.concat dir "package/cli.js" in
  let node_path = Filename.concat dir "node" in
  let node_path = if Sys.file_exists node_path then node_path else Filename.concat dir "node.exe" in
  let cmd = [ node_path; cli_path; "run-driver" ] in
  Eio.Process.spawn ~sw process_mgr ?env ?stdin ?stdout ?stderr ~executable:node_path cmd
