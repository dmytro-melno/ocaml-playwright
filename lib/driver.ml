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

let rec mkdir_p dir =
  if dir = "" || dir = Filename.current_dir_name then
    ()
  else if Sys.file_exists dir then
    if Sys.is_directory dir then
      ()
    else
      failwith (Printf.sprintf "%s exists and is not a directory" dir)
  else begin
    let parent = Filename.dirname dir in
    if parent <> dir then mkdir_p parent;
    try Unix.mkdir dir 0o755 with
    | Unix.Unix_error (Unix.EEXIST, _, _) ->
      if not (Sys.is_directory dir) then
        failwith (Printf.sprintf "%s exists and is not a directory" dir)
  end

let remove_file_if_exists path =
  if Sys.file_exists path then Sys.remove path

let path_of_segments root segments =
  List.fold_left Filename.concat root segments

let zip_entry_segments filename =
  let invalid () =
    failwith (Printf.sprintf "Unsafe path in Playwright driver ZIP: %S" filename)
  in
  if filename = "" || filename.[0] = '/' || filename.[0] = '\\' then invalid ();
  let segments =
    filename
    |> String.split_on_char '/'
    |> List.filter (fun segment -> segment <> "")
  in
  if segments = [] then invalid ();
  List.iter
    (fun segment ->
      if segment = "." || segment = ".." ||
         String.contains segment '\\' ||
         String.contains segment ':'
      then
        invalid ())
    segments;
  segments

let make_executable_if_exists path =
  if Sys.file_exists path && Sys.os_type <> "Win32" then
    Unix.chmod path 0o755

let make_driver_executables dir =
  make_executable_if_exists (Filename.concat dir "node");
  make_executable_if_exists
    (path_of_segments dir ["package"; "lib"; "utilsBundleImpl"; "xdg-open"])

let extract_zip ~zip_path ~dst_dir =
  let zip = Zip.open_in zip_path in
  Fun.protect
    ~finally:(fun () -> Zip.close_in zip)
    (fun () ->
      Zip.entries zip
      |> List.iter (fun entry ->
        let target = path_of_segments dst_dir (zip_entry_segments entry.Zip.filename) in
        if entry.Zip.is_directory then
          mkdir_p target
        else begin
          mkdir_p (Filename.dirname target);
          Zip.copy_entry_to_file zip entry target
        end));
  make_driver_executables dst_dir

let download () =
  let dir = driver_dir () in
  if not (Sys.file_exists dir) then begin
    mkdir_p dir;
    let zip_name = get_zip_name () in
    let url = Printf.sprintf "https://cdn.playwright.dev/builds/driver/playwright-%s-%s.zip" version zip_name in
    let zip_path = Filename.concat dir "driver.zip" in
    Printf.printf "Downloading Playwright driver %s to %s...\n%!" version dir;
    let res = Sys.command (Printf.sprintf "curl -sL %s -o %s" (Filename.quote url) (Filename.quote zip_path)) in
    if res <> 0 then failwith "Failed to download Playwright driver";
    extract_zip ~zip_path ~dst_dir:dir;
    remove_file_if_exists zip_path;
    Printf.printf "Driver downloaded successfully.\n%!";
  end;
  dir

let run ~sw ~process_mgr ?env ?stdin ?stdout ?stderr () =
  let dir = download () in
  let cli_path = path_of_segments dir ["package"; "cli.js"] in
  let node_path = Filename.concat dir "node" in
  let node_path = if Sys.file_exists node_path then node_path else Filename.concat dir "node.exe" in
  let cmd = [ node_path; cli_path; "run-driver" ] in
  Eio.Process.spawn ~sw process_mgr ?env ?stdin ?stdout ?stderr ~executable:node_path cmd
