let version = "1.59.1"

let cache_dir () =
    let open Option.Syntax in
    let home =
        match Sys.getenv_opt "HOME" <|> Sys.getenv_opt "USERPROFILE" with
        | Some home -> home
        | None -> failwith "Could not determine home directory"
    in
    Filename.concat home ".cache/playwright-ocaml-driver"

let driver_dir () = Filename.concat (cache_dir ()) version

let rec mkdir_p dir =
    if dir = "" || dir = Filename.current_dir_name then ()
    else if Sys.file_exists dir then begin
        if not (Sys.is_directory dir) then failwith (Printf.sprintf "%s exists and is not a directory" dir)
    end else begin
        let parent = Filename.dirname dir in
        if parent <> dir then mkdir_p parent;
        try Unix.mkdir dir 0o755 with
        | Unix.Unix_error (Unix.EEXIST, _, _) ->
            if not (Sys.is_directory dir) then failwith (Printf.sprintf "%s exists and is not a directory" dir)
    end

let remove_file_if_exists path =
    if Sys.file_exists path then Sys.remove path

let cli_path dir = Filename.concat (Filename.concat dir "package") "cli.js"

let driver_is_ready dir =
    let path = cli_path dir in
    Sys.file_exists path && not (Sys.is_directory path)

let download () =
    let dir = driver_dir () in
    if not (driver_is_ready dir) then begin
        mkdir_p dir;
        let url          = Printf.sprintf "https://registry.npmjs.org/playwright-core/-/playwright-core-%s.tgz" version in
        let archive_path = Filename.concat dir "driver.tgz" in
        Printf.printf "Downloading Playwright driver %s to %s...\n%!" version dir;
        let download_status = Printf.sprintf "curl -fLsS %s -o %s" (Filename.quote url) (Filename.quote archive_path) |> Sys.command in
        if download_status <> 0 then begin
            remove_file_if_exists archive_path;
            failwith "Failed to download Playwright driver"
        end;
        let extract_status = Printf.sprintf "tar -xzf %s -C %s" (Filename.quote archive_path) (Filename.quote dir) |> Sys.command in
        remove_file_if_exists archive_path;
        if extract_status <> 0 || not (driver_is_ready dir) then failwith "Failed to extract Playwright driver";
        remove_file_if_exists (Filename.concat dir "driver.zip");
        Printf.printf "Driver downloaded successfully.\n%!"
    end;
    dir

let run ~sw ~process_mgr ?dir ?env ?stdin ?stdout ?stderr () =
    let dir = match dir with Some dir -> dir | None -> download () in
    let cmd = ["node"; cli_path dir; "run-driver"] in
    Eio.Process.spawn ~sw process_mgr ?env ?stdin ?stdout ?stderr cmd

(* Each phase is bounded. The process switch remains the final kill/reap safety
   net if the OS cannot complete a KILL within the deadline. Cold provisioning
   above is intentionally not covered by these lifecycle deadlines. *)
let shutdown ~clock ~timeout process =
    let await () =
        match Eio.Time.with_timeout_exn clock timeout (fun () -> Eio.Process.await process) with
        | _ -> true
        | exception Eio.Time.Timeout -> false
    in
    if not (await ()) then begin
        Eio.Process.signal process Sys.sigterm;
        if not (await ()) then begin
            Eio.Process.signal process Sys.sigkill;
            if not (await ()) then
                Printf.eprintf "Playwright driver did not reap after KILL; awaiting process-scope cleanup\n%!"
        end
    end
