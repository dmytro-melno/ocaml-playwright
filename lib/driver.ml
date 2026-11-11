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
                 Node.js 18 or newer, or set PLAYWRIGHT_NODEJS_PATH to the executable.")

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

(* Runs a command to completion on a system thread, so that other fibers keep running, and
   returns its exit code and combined output. *)
let run_process ~log executable args =
    Eio_unix.run_in_systhread ~label:"playwright-install" (fun () ->
        let out = Unix.openfile log [ O_WRONLY; O_CREAT; O_TRUNC; O_CLOEXEC ] 0o644 in
        let null = Unix.openfile (if Sys.win32 then "NUL" else "/dev/null") [ O_RDONLY; O_CLOEXEC ] 0 in
        let env = Array.append (Unix.environment ()) [| "NODE_USE_ENV_PROXY=1" |] in
        let pid =
            Fun.protect
                ~finally:(fun () -> Unix.close out; Unix.close null)
                (fun () -> Unix.create_process_env executable (Array.of_list (executable :: args)) env null out out)
        in
        let rec wait () = try snd (Unix.waitpid [] pid) with Unix.Unix_error (Unix.EINTR, _, _) -> wait () in
        match wait () with Unix.WEXITED code -> code | WSIGNALED _ | WSTOPPED _ -> 255)

(* Downloads the pinned driver into [target].  The package is unpacked into a scratch directory
   and renamed into place, so concurrent installations and interrupted ones are both harmless. *)
let install ~node target =
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
            let code = run_process ~log node [ script; url; Protocol.driver_integrity; unpacked ] in
            if code <> 0 || cli_in unpacked = None then
                Error.raise_
                    "Could not install the Playwright %s driver: %s\n\
                     Check the network connection, or unpack the playwright-core %s npm package yourself and point \
                     PLAYWRIGHT_OCAML_DRIVER to it."
                    version (String.trim (read_file log)) version;
            (try Unix.rename unpacked target
             with Unix.Unix_error _ when cli_in target <> None -> () (* another process installed it meanwhile *)))

let installed_dir () = cache_dir () / ("driver-" ^ version)

(* Finds the driver, installing it first when [install_if_missing] allows. *)
let locate ?(install_if_missing = true) () =
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
                install ~node target;
                (match cli_in target with Some cli -> cli | None -> Error.raise_ "The Playwright driver vanished from %S" target)
            | None -> Error.raise_ "The Playwright %s driver is not installed in %S" version target)
    in
    { node; cli }
