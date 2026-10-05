let version = Protocol_version.version

let getenv name =
    match Sys.getenv_opt name with Some "" | None -> None | Some value -> Some value

let home_dir () =
    match getenv (if Sys.win32 then "USERPROFILE" else "HOME") with
    | Some home -> home
    | None -> failwith "Could not determine home directory"

let cache_dir () =
    match getenv "PLAYWRIGHT_OCAML_CACHE_DIR" with
    | Some dir -> dir
    | None ->
        let base =
            if Sys.win32 then
                match getenv "LOCALAPPDATA" with
                | Some dir -> dir
                | None -> Filename.concat (Filename.concat (home_dir ()) "AppData") "Local"
            else
                match getenv "XDG_CACHE_HOME" with
                | Some dir -> dir
                | None -> Filename.concat (home_dir ()) ".cache"
        in
        Filename.concat base "playwright-ocaml-driver"

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

let cli_path dir = Filename.concat (Filename.concat dir "package") "cli.js"

(* Continue accepting caches created by older library versions. Newly installed
   archives get the additional version validation below before publication. *)
let driver_is_ready dir =
    let path = cli_path dir in
    Sys.file_exists path && not (Sys.is_directory path)

let get_ok = function Ok value -> value | Error (`Msg message) -> failwith message

let https_client env =
    (try ignore (Mirage_crypto_rng.default_generator ()) with
    | Mirage_crypto_rng.No_default_generator -> Mirage_crypto_rng_unix.use_default ());
    let authenticator = Ca_certs.authenticator () |> get_ok in
    let config = Tls.Config.client ~authenticator () |> get_ok in
    let https uri flow =
        let host =
            match Uri.host uri with
            | Some name -> Domain_name.of_string name |> get_ok |> Domain_name.host |> get_ok
            | None -> failwith "Missing host in driver download URL"
        in
        Tls_eio.client_of_flow config ~host flow
    in
    Cohttp_eio.Client.make ~https:(Some https) (Eio.Stdenv.net env)

let fetch_archive env destination =
    let client = https_client env in
    let headers = Http.Header.of_list ["accept-encoding", "identity"] in
    let rec fetch remaining uri =
        if Uri.scheme uri <> Some "https" || Uri.userinfo uri <> None then
            failwith "Driver download requires an HTTPS URL without credentials";
        let result = Eio.Switch.run (fun sw ->
            let response, body = Cohttp_eio.Client.get client ~sw ~headers uri in
            let status = Http.Response.status response |> Http.Status.to_int in
            match status with
            | 200 ->
                Eio.Path.with_open_out ~create:(`Exclusive 0o600) destination (fun output ->
                    let buffer = Cstruct.create 65536 in
                    let total = ref 0 in
                    let rec copy () =
                        match Eio.Flow.single_read body buffer with
                        | n ->
                            total := !total + n;
                            if !total > 64 * 1024 * 1024 then failwith "Driver archive exceeds 64 MiB";
                            Eio.Flow.write output [Cstruct.sub buffer 0 n];
                            copy ()
                        | exception End_of_file -> ()
                    in
                    copy ());
                `Done
            | 301 | 302 | 303 | 307 | 308 ->
                if remaining = 0 then failwith "Too many driver download redirects";
                (match Http.Header.get (Http.Response.headers response) "location" with
                | Some location -> `Redirect (Uri.resolve "https" uri (Uri.of_string location))
                | None -> failwith "Driver download redirect has no Location")
            | _ -> failwith (Printf.sprintf "Driver download failed: HTTP %d" status))
        in
        match result with `Done -> () | `Redirect uri -> fetch (remaining - 1) uri
    in
    let url = Printf.sprintf "https://registry.npmjs.org/playwright-core/-/playwright-core-%s.tgz" version in
    fetch 5 (Uri.of_string url)

let safe_component part =
    let device = String.uppercase_ascii (String.trim (List.hd (String.split_on_char '.' part))) in
    let reserved =
        List.mem device ["CON"; "PRN"; "AUX"; "NUL"; "CONIN$"; "CONOUT$";
            "COM¹"; "COM²"; "COM³"; "LPT¹"; "LPT²"; "LPT³"] ||
        (String.length device = 4 &&
         (String.starts_with ~prefix:"COM" device || String.starts_with ~prefix:"LPT" device) &&
         device.[3] >= '0' && device.[3] <= '9')
    in
    part <> "" && part <> "." && part <> ".." && not reserved &&
    not (String.ends_with ~suffix:"." part || String.ends_with ~suffix:" " part) &&
    not (String.exists (fun c -> Char.code c < 32 || String.contains "\\:<>\"|?*" c) part)

let extract_archive ~sw archive destination =
    let entries = ref 0 in
    let expanded = ref 0L in
    let files = Hashtbl.create 512 in
    let filter (header : Tar.Header.t) =
        Eio.Fiber.check ();
        incr entries;
        expanded := Int64.add !expanded header.file_size;
        if !entries > 20000 || header.file_size < 0L ||
           header.file_size > 134217728L || !expanded > 536870912L then
            failwith "Driver archive exceeds extraction limits";
        let name =
            if header.link_indicator = Tar.Header.Link.Directory &&
               String.ends_with ~suffix:"/" header.file_name then
                String.sub header.file_name 0 (String.length header.file_name - 1)
            else header.file_name
        in
        let parts = String.split_on_char '/' name in
        if not (List.for_all safe_component parts) ||
           (match parts with "package" :: _ -> false | _ -> true) then
            failwith (Printf.sprintf "Unsafe driver archive path: %S" header.file_name);
        match header.link_indicator with
        | Tar.Header.Link.Normal ->
            let key = String.lowercase_ascii name in
            if Hashtbl.mem files key then failwith ("Duplicate driver archive path: " ^ name);
            Hashtbl.add files key ();
            let parent = List.rev (List.tl (List.rev parts)) in
            let parent = List.fold_left Eio.Path.( / ) destination parent in
            Eio.Path.mkdirs ~exists_ok:true ~perm:0o755 parent;
            true
        | Tar.Header.Link.Directory ->
            if header.file_size <> 0L then failwith "Driver directory has a non-empty body";
            true
        | _ -> failwith ("Links and special files are not allowed in the driver archive: " ^ name)
    in
    Eio.Path.with_open_out ~create:`Never archive (fun source ->
        let extraction = Tar_eio.extract ~filter ~sw destination |> Tar_gz.in_gzipped in
        match Tar_eio.run extraction (Tar_eio.flow_of_file source) with
        | Ok () -> ()
        | Error (`Fatal error) -> failwith (Format.asprintf "Invalid driver archive: %a" Tar.pp_error error)
        | Error (`Msg message | `Gz message) -> failwith ("Invalid driver archive: " ^ message)
        | Error (`Eof | `Unexpected_end_of_file) -> failwith "Truncated driver archive")

(* POSIX record locks are process-scoped. Serialize fibers/domains too, and do
   not unlink the lock file: waiters must always lock the same inode. *)
let install_mutex = Eio.Mutex.create ()

let with_install_lock cache f =
    Eio.Mutex.lock install_mutex;
    Fun.protect ~finally:(fun () -> Eio.Mutex.unlock install_mutex) (fun () ->
        let fd = Unix.openfile (Filename.concat cache ".install.lock")
            [Unix.O_CREAT; Unix.O_RDWR; Unix.O_CLOEXEC] 0o600 in
        Fun.protect ~finally:(fun () -> Unix.close fd) (fun () ->
            let rec acquire () =
                match Unix.lockf fd Unix.F_TLOCK 1 with
                | () -> ()
                | exception Unix.Unix_error ((Unix.EACCES | Unix.EAGAIN | Unix.EWOULDBLOCK), _, _) ->
                    Eio_unix.sleep 0.05;
                    acquire ()
            in
            acquire ();
            f ()))

let download ~(env : Eio_unix.Stdenv.base) ?(timeout = 120.) () =
    if not (Float.is_finite timeout && timeout > 0.) then
        invalid_arg "Playwright download timeout must be finite and positive";
    let dir = driver_dir () in
    if not (driver_is_ready dir) then
        Eio.Time.with_timeout_exn (Eio.Stdenv.clock env) timeout (fun () ->
            let cache = cache_dir () in
            let path name = Eio.Path.(Eio.Stdenv.fs env / name) in
            Eio.Path.mkdirs ~exists_ok:true ~perm:0o700 (path cache);
            with_install_lock cache (fun () ->
                if not (driver_is_ready dir) then begin
                    let random = Cstruct.create 16 in
                    Eio.Flow.read_exact (Eio.Stdenv.secure_random env) random;
                    let suffix = Cstruct.to_string random |> String.to_seq |>
                        Seq.map (fun c -> Printf.sprintf "%02x" (Char.code c)) |> List.of_seq |> String.concat "" in
                    let staging = path (Filename.concat cache (version ^ ".tmp-" ^ suffix)) in
                    Eio.Path.mkdir ~perm:0o700 staging;
                    Fun.protect
                        ~finally:(fun () ->
                            Eio.Cancel.protect (fun () ->
                                try Eio.Path.rmtree ~missing_ok:true staging with ex ->
                                    Printf.eprintf "Playwright cache cleanup: %s\n%!" (Printexc.to_string ex)))
                        (fun () ->
                            Printf.printf "Downloading Playwright driver %s to %s...\n%!" version dir;
                            let archive = Eio.Path.(staging / "driver.tgz") in
                            fetch_archive env archive;
                            Eio.Switch.run (fun sw -> extract_archive ~sw archive staging);
                            let package = Eio.Path.(staging / "package" / "package.json") |> Eio.Path.load |>
                                Yojson.Safe.from_string in
                            let package_version = Yojson.Safe.Util.(package |> member "version" |> to_string) in
                            if package_version <> version ||
                               not (Eio.Path.is_file Eio.Path.(staging / "package" / "cli.js")) then
                                failwith "Downloaded driver does not match the pinned Playwright version";
                            Eio.Path.unlink archive;
                            (* Only complete installations are visible at the versioned path. *)
                            Eio.Path.rmtree ~missing_ok:true (path dir);
                            Eio.Path.rename staging (path dir);
                            Printf.printf "Driver downloaded successfully.\n%!")
                end));
    dir

let run ~sw ~env ?dir () =
    let dir = match dir with Some dir -> dir | None -> download ~env () in
    Driver_process.spawn ~sw ~env ~cli:(cli_path dir)

let stdin = Driver_process.stdin
let stdout = Driver_process.stdout
let await = Driver_process.await

(* EOF is the graceful shutdown mechanism on every platform. Windows escalation
   terminates the job; Unix retains TERM followed by KILL. The process switch is
   the final resource cleanup safety net. *)
let shutdown ~clock ~timeout process =
    let await () =
        match Eio.Time.with_timeout_exn clock timeout (fun () -> Driver_process.await process) with
        | _ -> true
        | exception Eio.Time.Timeout -> false
    in
    if not (await ()) then begin
        Driver_process.terminate process;
        if not (await ()) then begin
            Driver_process.kill process;
            if not (await ()) then
                Printf.eprintf "Playwright driver did not stop; awaiting process-scope cleanup\n%!"
        end
    end
