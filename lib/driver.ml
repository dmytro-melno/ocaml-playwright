(* Locating and installing the Playwright driver.

   The driver is the [playwright-core] npm package, run by Node.js.  The exact version this
   library speaks to is pinned in [protocol/manifest.json].  Installing it is a step of its own,
   which the [ocaml-playwright] program and [Playwright.Driver] make: the package is downloaded
   into a per-user cache and verified against the pinned SHA-512 digest.  Node.js does the
   download and the extraction, so the library needs no HTTP, TLS or archive code of its own.
   Starting Playwright only looks for the driver. *)

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

(* Where the driver is installed: in the user's cache, one directory per version. *)
let installed_dir () =
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
    base / "ocaml-playwright" / ("driver-" ^ version)

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

let with_file path flags f =
    let fd = Unix.openfile path (Unix.O_CLOEXEC :: flags) 0o644 in
    Fun.protect ~finally:(fun () -> Unix.close fd) (fun () -> f fd)

let rec wait_for pid =
    match Unix.waitpid [] pid with
    | _, Unix.WEXITED code -> code
    | _, (WSIGNALED signal | WSTOPPED signal) -> 128 + abs signal
    | exception Unix.Unix_error (Unix.EINTR, _, _) -> wait_for pid

(* Runs a program to its end and returns its exit code.  Nothing else runs meanwhile. *)
let run_process ?(env = Unix.environment ()) ?(stdin = Unix.stdin) ?(stdout = Unix.stdout) ?(stderr = Unix.stderr) program args =
    match Unix.create_process_env program (Array.of_list (program :: args)) env stdin stdout stderr with
    | pid -> wait_for pid
    | exception Unix.Unix_error (code, _, _) -> Error.raise_ "Could not run %s: %s" program (Unix.error_message code)

(* Downloads the pinned driver into [target].  The package is unpacked into a scratch directory
   and renamed into place, so concurrent installations and interrupted ones are both harmless. *)
let download ~node target =
    let scratch = Printf.sprintf "%s.tmp-%d-%06x" target (Unix.getpid ()) (Random.State.bits (Random.State.make_self_init ()) land 0xFFFFFF) in
    mkdir_p scratch;
    Fun.protect
        ~finally:(fun () -> rm_rf scratch)
        (fun () ->
            let script = scratch / "install.js" in
            let log = scratch / "install.log" in
            let unpacked = scratch / "unpacked" in
            Out_channel.with_open_bin script (fun oc -> output_string oc install_script);
            let code =
                with_file (if Sys.win32 then "NUL" else "/dev/null") [ O_RDONLY ] @@ fun null ->
                with_file log [ O_WRONLY; O_CREAT; O_TRUNC ] @@ fun out ->
                let env = Array.append (Unix.environment ()) [| "NODE_USE_ENV_PROXY=1" |] in
                run_process ~env ~stdin:null ~stdout:out ~stderr:out node [ script; Protocol.driver_tarball; Protocol.driver_integrity; unpacked ]
            in
            if code <> 0 || cli_in unpacked = None then
                Error.raise_
                    "Could not install the Playwright %s driver: %s\n\
                     Check the network connection, or unpack the playwright-core %s npm package yourself and point \
                     PLAYWRIGHT_OCAML_DRIVER to it."
                    version (String.trim (read_file log)) version;
            try Unix.rename unpacked target
            with Unix.Unix_error _ when cli_in target <> None -> () (* another process installed it meanwhile *))

(* The driver's command line tool, if the driver is there. *)
let find_cli () =
    match getenv "PLAYWRIGHT_OCAML_DRIVER" with
    | None -> cli_in (installed_dir ())
    | Some dir ->
        (match cli_in dir with
        | None -> Error.raise_ "PLAYWRIGHT_OCAML_DRIVER points to %S, which does not contain the playwright-core package" dir
        | found -> found)

(* Finds the driver, which has to be installed. *)
let locate () =
    let node = find_node () in
    match find_cli () with
    | Some cli -> { node; cli }
    | None ->
        Error.raise_
            "The Playwright %s driver is not installed in %S. Run `ocaml-playwright install chromium`, which downloads the \
             driver and that browser, or call `Playwright.Driver.install ()` for the driver alone."
            version (installed_dir ())

(* Installs the driver unless it is there already, which blocks until it has been downloaded. *)
let install () =
    let node = find_node () in
    if find_cli () = None then download ~node (installed_dir ())

(* The command that runs the driver's own command line tool with [args]. *)
let command args =
    let driver = locate () in
    driver.node :: driver.cli :: args

(* Runs that tool to its end, on the standard streams of this process, and returns its exit code.
   The driver is installed first where it is missing. *)
let run_command args =
    install ();
    let driver = locate () in
    run_process driver.node (driver.cli :: args)
