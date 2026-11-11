(* Locating and installing the Playwright driver.

   The driver is the [playwright-core] npm package, run by Node.js.  The exact version this
   library speaks to is pinned in [protocol/manifest.json]; it is downloaded once into a per-user
   cache and verified against the pinned SHA-512 digest.  Node.js does the download and the
   extraction, so the library needs no HTTP, TLS or archive code of its own. *)

type t = {
    node : string;  (* absolute path of the Node.js executable *)
    cli : string;  (* absolute path of the package's [cli.js] *)
}

let version = Protocol.playwright_version

let getenv name = match Sys.getenv_opt name with Some "" | None -> None | some -> some
let ( / ) = Filename.concat

let is_file path = try not (Sys.is_directory path) with Sys_error _ -> false
let is_directory path = try Sys.is_directory path with Sys_error _ -> false

let rec mkdir_p path =
    if not (is_directory path) then begin
        mkdir_p (Filename.dirname path);
        try Unix.mkdir path 0o755 with Unix.Unix_error (Unix.EEXIST, _, _) -> ()
    end

let rec rm_rf path =
    match Unix.lstat path with
    | exception Unix.Unix_error _ -> ()
    | { Unix.st_kind = S_DIR; _ } ->
        Array.iter (fun entry -> rm_rf (path / entry)) (try Sys.readdir path with Sys_error _ -> [||]);
        (try Unix.rmdir path with Unix.Unix_error _ -> ())
    | _ -> (try Unix.unlink path with Unix.Unix_error _ -> ())

let cache_dir () =
    match getenv "PLAYWRIGHT_OCAML_CACHE_DIR" with
    | Some dir -> dir
    | None ->
        let base =
            if Sys.win32 then
                match getenv "LOCALAPPDATA", getenv "USERPROFILE" with
                | Some dir, _ -> dir
                | None, Some home -> home / "AppData" / "Local"
                | None, None -> Filename.get_temp_dir_name ()
            else
                match getenv "XDG_CACHE_HOME", getenv "HOME" with
                | Some dir, _ -> dir
                | None, Some home -> home / ".cache"
                | None, None -> Filename.get_temp_dir_name ()
        in
        base / "ocaml-playwright"

(* Looks [name] up in PATH.  The current directory is never searched implicitly, also on Windows
   where the system would do so: a driver must not be picked up from an untrusted directory. *)
let find_in_path name =
    let separator = if Sys.win32 then ';' else ':' in
    let names = if Sys.win32 then [ name ^ ".exe" ] else [ name ] in
    let is_executable path =
        is_file path && (Sys.win32 || match Unix.access path [ Unix.X_OK ] with () -> true | exception Unix.Unix_error _ -> false)
    in
    String.split_on_char separator (Option.value (Sys.getenv_opt "PATH") ~default:"")
    |> List.filter (fun dir -> dir <> "" && not (Filename.is_relative dir))
    |> List.concat_map (fun dir -> List.map (fun name -> dir / name) names)
    |> List.find_opt is_executable

let find_node () =
    match getenv "PLAYWRIGHT_NODEJS_PATH" with
    | Some path when is_file path -> path
    | Some path -> Error.raise_ "PLAYWRIGHT_NODEJS_PATH points to %S, which does not exist" path
    | None ->
        (match find_in_path "node" with
        | Some path -> path
        | None ->
            Error.raise_
                "Node.js is required to run the Playwright driver, but no `node` executable was found in PATH. Install \
                 Node.js 20 or newer, or set PLAYWRIGHT_NODEJS_PATH to the executable.")

(* Accepts the package directory itself or a directory that contains it as [package/], which is
   how npm tarballs unpack. *)
let cli_in dir = List.find_opt is_file [ dir / "cli.js"; dir / "package" / "cli.js" ]

let install_script = {js|
const fs = require('fs'), path = require('path'), zlib = require('zlib'), crypto = require('crypto');
const [url, integrity, dest] = process.argv.slice(2);

function untar(archive) {
  const root = path.resolve(dest);
  let offset = 0, override = null;
  while (offset + 512 <= archive.length) {
    const header = archive.subarray(offset, offset + 512);
    offset += 512;
    if (header.every(byte => byte === 0)) break;
    const field = (start, length) => {
      const bytes = header.subarray(start, start + length);
      const end = bytes.indexOf(0);
      return bytes.subarray(0, end < 0 ? length : end).toString('utf8');
    };
    const size = parseInt(field(124, 12).trim() || '0', 8);
    if (!Number.isSafeInteger(size) || offset + size > archive.length) throw new Error('corrupt archive');
    const data = archive.subarray(offset, offset + size);
    offset += Math.ceil(size / 512) * 512;
    const type = String.fromCharCode(header[156] || 48);
    if (type === 'x') {
      const match = /(?:^|\n)\d+ path=([^\n]*)\n/.exec(data.toString('utf8'));
      if (match) override = match[1];
      continue;
    }
    if (type === 'L') { override = data.toString('utf8').replace(/\0[\s\S]*$/, ''); continue; }
    if (type === 'g') continue;
    let name = field(0, 100);
    const prefix = field(345, 155);
    if (field(257, 5) === 'ustar' && prefix) name = prefix + '/' + name;
    if (override !== null) { name = override; override = null; }
    const target = path.resolve(root, name);
    if (target !== root && !target.startsWith(root + path.sep)) throw new Error('archive entry escapes the destination: ' + name);
    if (type === '5') {
      fs.mkdirSync(target, { recursive: true });
    } else if (type === '0') {
      fs.mkdirSync(path.dirname(target), { recursive: true });
      fs.writeFileSync(target, data, { mode: (parseInt(field(100, 8).trim() || '644', 8) & 0o777) || 0o644 });
    }
  }
}

(async () => {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`HTTP ${response.status} ${response.statusText}`);
  const tarball = Buffer.from(await response.arrayBuffer());
  const [algorithm, expected] = [integrity.slice(0, integrity.indexOf('-')), integrity.slice(integrity.indexOf('-') + 1)];
  const actual = crypto.createHash(algorithm).update(tarball).digest('base64');
  if (actual !== expected) throw new Error(`integrity check failed: expected ${integrity}, got ${algorithm}-${actual}`);
  untar(zlib.gunzipSync(tarball));
})().catch(error => {
  console.error(`${url}: ${error.cause ? error.cause.message || error.cause : error.message}`);
  process.exit(1);
});
|js}

let read_file path = try In_channel.with_open_bin path In_channel.input_all with Sys_error _ -> ""

let exit_code = function Unix.WEXITED code -> code | WSIGNALED signal | WSTOPPED signal -> 128 + abs signal

let rec wait_for pid =
    match Unix.waitpid [] pid with
    | _, status -> exit_code status
    | exception Unix.Unix_error (Unix.EINTR, _, _) -> wait_for pid

let poll_interval = 0.05

(* Runs a command with its output going to the file [log], and returns its exit code.  The
   command is given up, which means killed and waited for, when it takes longer than [timeout]
   milliseconds or when [cancelled] says so; it is asked every few milliseconds. *)
let run_process ~log ~timeout ~cancelled executable args =
    let out = Unix.openfile log [ O_WRONLY; O_CREAT; O_TRUNC; O_CLOEXEC ] 0o644 in
    let null = Unix.openfile (if Sys.win32 then "NUL" else "/dev/null") [ O_RDONLY; O_CLOEXEC ] 0 in
    let env = Array.append (Unix.environment ()) [| "NODE_USE_ENV_PROXY=1" |] in
    let pid =
        Fun.protect
            ~finally:(fun () -> Unix.close out; Unix.close null)
            (fun () -> Unix.create_process_env executable (Array.of_list (executable :: args)) env null out out)
    in
    let give_up reason =
        (try Unix.kill pid Sys.sigkill with Unix.Unix_error _ -> ());
        ignore (wait_for pid);
        reason
    in
    (* The time is counted in the pauses made, which no change of the system's clock can upset. *)
    let rec poll waited =
        match Unix.waitpid [ WNOHANG ] pid with
        | 0, _ ->
            if cancelled () then give_up `Cancelled
            else if timeout > 0. && waited *. 1000. >= timeout then give_up `Timed_out
            else begin
                Unix.sleepf poll_interval;
                poll (waited +. poll_interval)
            end
        | _, status -> `Exited (exit_code status)
        | exception Unix.Unix_error (Unix.EINTR, _, _) -> poll waited
    in
    poll 0.

let default_install_timeout = 300_000.

(* How long an installation may take, in milliseconds; zero for as long as it takes. *)
let install_timeout () =
    match getenv "PLAYWRIGHT_OCAML_DRIVER_INSTALL_TIMEOUT" with
    | None -> default_install_timeout
    | Some text -> (
        match float_of_string_opt text with
        | Some timeout when timeout >= 0. -> timeout
        | _ -> Error.raise_ "PLAYWRIGHT_OCAML_DRIVER_INSTALL_TIMEOUT is %S, which is not a number of milliseconds" text)

(* Downloads the pinned driver into [target].  The package is unpacked into a scratch directory
   and renamed into place, so concurrent installations and interrupted ones are both harmless. *)
let install ~node ~timeout ~cancelled target =
    let scratch = Printf.sprintf "%s.tmp-%d-%06x" target (Unix.getpid ()) (Random.State.bits (Random.State.make_self_init ()) land 0xFFFFFF) in
    mkdir_p scratch;
    Fun.protect
        ~finally:(fun () -> rm_rf scratch)
        (fun () ->
            let script = scratch / "install.js" in
            let log = scratch / "install.log" in
            let unpacked = scratch / "unpacked" in
            Out_channel.with_open_bin script (fun oc -> output_string oc install_script);
            let url = Option.value (getenv "PLAYWRIGHT_OCAML_DRIVER_URL") ~default:Protocol.driver_tarball in
            let failed reason =
                Error.raise_
                    "Could not install the Playwright %s driver: %s\n\
                     Check the network connection, or unpack the playwright-core %s npm package yourself and point \
                     PLAYWRIGHT_OCAML_DRIVER to it."
                    version reason version
            in
            (match run_process ~log ~timeout ~cancelled node [ script; url; Protocol.driver_integrity; unpacked ] with
            | `Exited 0 when cli_in unpacked <> None -> ()
            | `Exited _ -> failed (String.trim (read_file log))
            | `Timed_out ->
                failed (Printf.sprintf "%s: not finished after %g seconds (the limit, which PLAYWRIGHT_OCAML_DRIVER_INSTALL_TIMEOUT sets in milliseconds)" url (timeout /. 1000.))
            | `Cancelled -> Error.raise_ "The installation of the Playwright %s driver was cancelled" version);
            (try Unix.rename unpacked target
             with Unix.Unix_error _ when cli_in target <> None -> () (* another process installed it meanwhile *)))

let installed_dir () = cache_dir () / ("driver-" ^ version)

(* Finds the driver, installing it first when [install_if_missing] allows.  That blocks until
   the download is complete, has taken more than [install_timeout] milliseconds, or [cancelled]
   says that the caller has lost interest; see {!run_process}. *)
let locate ?(install_if_missing = true) ?install_timeout:timeout ?(cancelled = fun () -> false) () =
    let node = find_node () in
    let cli =
        match getenv "PLAYWRIGHT_OCAML_DRIVER" with
        | Some dir ->
            (match cli_in dir with
            | Some cli -> cli
            | None -> Error.raise_ "PLAYWRIGHT_OCAML_DRIVER points to %S, which does not contain the playwright-core package" dir)
        | None ->
            let target = installed_dir () in
            (match cli_in target with
            | Some cli -> cli
            | None when install_if_missing ->
                mkdir_p (Filename.dirname target);
                install ~node ~timeout:(match timeout with Some timeout -> timeout | None -> install_timeout ()) ~cancelled target;
                (match cli_in target with Some cli -> cli | None -> Error.raise_ "The Playwright driver vanished from %S" target)
            | None -> Error.raise_ "The Playwright %s driver is not installed in %S" version target)
    in
    { node; cli }

(* The command that runs the driver's own command line tool with [args]. *)
let command args =
    let driver = locate () in
    driver.node :: driver.cli :: args

(* Runs that tool to its end, on the standard streams of this process, and returns its exit code. *)
let run_command args =
    match command args with
    | [] -> assert false
    | node :: _ as argv ->
        (match Unix.create_process node (Array.of_list argv) Unix.stdin Unix.stdout Unix.stderr with
        | pid -> wait_for pid
        | exception Unix.Unix_error (code, _, _) -> Error.raise_ "Could not run %s: %s" node (Unix.error_message code))
