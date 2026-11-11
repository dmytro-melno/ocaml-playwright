(* Timeouts, the driver installation and errors. *)

open Internal

(* {1 Timeouts} *)

let test_timeouts () =
    let context = Timeouts.create () in
    let page = Timeouts.create ~parent:context () in
    Alcotest.(check (float 0.)) "default" 30_000. (Timeouts.action page);
    Alcotest.(check (float 0.)) "navigation default" 30_000. (Timeouts.navigation page);
    Alcotest.(check (float 0.)) "launch default" 180_000. (Timeouts.launch ());
    context.default <- Some 5_000.;
    Alcotest.(check (float 0.)) "inherited" 5_000. (Timeouts.action page);
    Alcotest.(check (float 0.)) "navigation falls back to the general default" 5_000. (Timeouts.navigation page);
    context.default_navigation <- Some 9_000.;
    Alcotest.(check (float 0.)) "navigation default of the parent" 9_000. (Timeouts.navigation page);
    Alcotest.(check (float 0.)) "which does not affect actions" 5_000. (Timeouts.action page);
    page.default <- Some 2_000.;
    Alcotest.(check (float 0.)) "own default first" 2_000. (Timeouts.action page);
    Alcotest.(check (float 0.)) "own general default beats the parent's navigation default" 2_000. (Timeouts.navigation page);
    page.default_navigation <- Some 7_000.;
    Alcotest.(check (float 0.)) "own navigation default" 7_000. (Timeouts.navigation page);
    Alcotest.(check (float 0.)) "explicit wins" 1. (Timeouts.navigation ~timeout:1. page);
    Alcotest.(check (float 0.)) "explicit zero disables" 0. (Timeouts.action ~timeout:0. page)

(* {1 Driver} *)

let with_env bindings f =
    let saved = List.map (fun (name, _) -> name, Sys.getenv_opt name) bindings in
    List.iter (fun (name, value) -> Unix.putenv name value) bindings;
    Fun.protect f ~finally:(fun () -> List.iter (fun (name, value) -> Unix.putenv name (Option.value value ~default:"")) saved)

let with_temp_dir f =
    let dir = Filename.temp_dir "playwright-test" "" in
    Fun.protect (fun () -> f dir) ~finally:(fun () -> Driver.rm_rf dir)

let touch ?(executable = false) path =
    Driver.mkdir_p (Filename.dirname path);
    Out_channel.with_open_bin path (fun oc -> output_string oc "");
    if executable then Unix.chmod path 0o755

let test_driver_cache_dir () =
    with_env [ "PLAYWRIGHT_OCAML_CACHE_DIR", "/custom/cache"; "XDG_CACHE_HOME", "/xdg" ] (fun () ->
        Alcotest.(check string) "explicit directory" "/custom/cache" (Driver.cache_dir ()));
    if not Sys.win32 then
        with_env [ "PLAYWRIGHT_OCAML_CACHE_DIR", ""; "XDG_CACHE_HOME", "/xdg" ] (fun () ->
            Alcotest.(check string) "XDG cache" "/xdg/ocaml-playwright" (Driver.cache_dir ());
            Alcotest.(check string) "one directory per driver version" ("/xdg/ocaml-playwright/driver-" ^ Protocol.playwright_version)
                (Driver.installed_dir ()))

let test_driver_path_lookup () =
    with_temp_dir @@ fun dir ->
    let bin = Filename.concat dir "bin" in
    let tool = if Sys.win32 then "pw-test-tool.exe" else "pw-test-tool" in
    touch ~executable:true (Filename.concat bin tool);
    touch (Filename.concat bin (if Sys.win32 then "pw-test-data.exe.txt" else "pw-test-data"));
    let separator = if Sys.win32 then ";" else ":" in
    with_env [ "PATH", String.concat separator [ ""; "."; "relative/dir"; bin ] ] (fun () ->
        Alcotest.(check (option string)) "found in PATH" (Some (Filename.concat bin tool)) (Driver.find_in_path "pw-test-tool");
        if not Sys.win32 then Alcotest.(check (option string)) "not executable" None (Driver.find_in_path "pw-test-data");
        (* Neither the current directory nor relative PATH entries are searched. *)
        let cwd = Sys.getcwd () in
        Sys.chdir bin;
        Fun.protect ~finally:(fun () -> Sys.chdir cwd) (fun () ->
            with_env [ "PATH", String.concat separator [ ""; "." ] ] (fun () ->
                Alcotest.(check (option string)) "current directory is ignored" None (Driver.find_in_path "pw-test-tool"))))

let test_driver_locate () =
    with_temp_dir @@ fun dir ->
    let node = Filename.concat dir (if Sys.win32 then "node.exe" else "node") in
    touch ~executable:true node;
    let package = Filename.concat dir "driver" in
    touch (Filename.concat (Filename.concat package "package") "cli.js");
    with_env [ "PLAYWRIGHT_NODEJS_PATH", node; "PLAYWRIGHT_OCAML_DRIVER", package ] (fun () ->
        let driver = Driver.locate ~install_if_missing:false () in
        Alcotest.(check string) "node" node driver.node;
        Alcotest.(check string) "cli" (Filename.concat (Filename.concat package "package") "cli.js") driver.cli);
    with_env [ "PLAYWRIGHT_NODEJS_PATH", node; "PLAYWRIGHT_OCAML_DRIVER", Filename.concat dir "nowhere" ] (fun () ->
        check_contains "a wrong driver directory is explained" ~sub:"PLAYWRIGHT_OCAML_DRIVER"
            (failure "wrong driver" (fun () -> Driver.locate ~install_if_missing:false ())).message);
    with_env [ "PLAYWRIGHT_NODEJS_PATH", Filename.concat dir "no-node"; "PLAYWRIGHT_OCAML_DRIVER", package ] (fun () ->
        check_contains "a wrong node path is explained" ~sub:"PLAYWRIGHT_NODEJS_PATH"
            (failure "wrong node" (fun () -> Driver.locate ~install_if_missing:false ())).message);
    with_env [ "PLAYWRIGHT_NODEJS_PATH", node; "PLAYWRIGHT_OCAML_DRIVER", ""; "PLAYWRIGHT_OCAML_CACHE_DIR", Filename.concat dir "empty-cache" ] (fun () ->
        check_contains "a missing driver is not installed behind the caller's back" ~sub:"not installed"
            (failure "not installed" (fun () -> Driver.locate ~install_if_missing:false ())).message)

(* A stand-in for Node.js: a shell script, which is given what the installer is given, that is
   the installing script, the URL, the checksum and the directory to unpack into. *)
let fake_node dir body =
    let path = Filename.concat dir "node" in
    Out_channel.with_open_bin path (fun oc -> output_string oc ("#!/bin/sh\n" ^ body ^ "\n"));
    Unix.chmod path 0o755;
    path

let installing ~dir body f =
    let variables =
        [ "PLAYWRIGHT_NODEJS_PATH", fake_node dir body; "PLAYWRIGHT_OCAML_DRIVER", ""; "PLAYWRIGHT_OCAML_CACHE_DIR", Filename.concat dir "cache";
          "PLAYWRIGHT_OCAML_DRIVER_INSTALL_TIMEOUT", "" ]
    in
    with_env variables f

(* What an installation that did not succeed must leave behind: no process and no files. *)
let check_cleaned_up ~dir =
    let pid = int_of_string (String.trim (In_channel.with_open_bin (Filename.concat dir "pid") In_channel.input_all)) in
    (match Unix.kill pid 0 with
    | () -> Alcotest.fail "the installer is still running"
    | exception Unix.Unix_error (Unix.ESRCH, _, _) -> ());
    Alcotest.(check (list string)) "nothing is left in the cache" [] (Array.to_list (Sys.readdir (Filename.concat dir "cache")))

let elapsed f =
    let start = Unix.gettimeofday () in
    let result = f () in
    result, Unix.gettimeofday () -. start

let slow_installer ~dir = Printf.sprintf "echo $$ > %s; exec sleep 30" (Filename.quote (Filename.concat dir "pid"))

let test_driver_install () =
    if Sys.win32 then Alcotest.skip ();
    with_temp_dir @@ fun dir ->
    installing ~dir {|echo "no route to host" >&2; exit 1|} (fun () ->
        check_contains "the installer's complaint is passed on" ~sub:"no route to host" (failure "failed installation" (fun () -> Driver.locate ())).message);
    installing ~dir (slow_installer ~dir) (fun () ->
        let error, seconds = elapsed (fun () -> failure "slow installation" (fun () -> Driver.locate ~install_timeout:200. ())) in
        check_contains "the limit is named" ~sub:"0.2 seconds" error.message;
        Alcotest.(check bool) "and kept" true (seconds < 5.);
        check_cleaned_up ~dir;
        with_env [ "PLAYWRIGHT_OCAML_DRIVER_INSTALL_TIMEOUT", "100" ] (fun () ->
            check_contains "the limit can be set" ~sub:"0.1 seconds" (failure "slow installation" (fun () -> Driver.locate ())).message);
        with_env [ "PLAYWRIGHT_OCAML_DRIVER_INSTALL_TIMEOUT", "soon" ] (fun () ->
            check_contains "to a number only" ~sub:"not a number" (failure "wrong limit" (fun () -> Driver.locate ())).message));
    installing ~dir {|mkdir -p "$4/package" && echo > "$4/package/cli.js"|} (fun () ->
        let driver = Driver.locate () in
        Alcotest.(check string) "installed into the cache" (List.fold_left Filename.concat (Driver.installed_dir ()) [ "package"; "cli.js" ]) driver.cli;
        Alcotest.(check (list string)) "and nothing else" [ "driver-" ^ Protocol.playwright_version ] (Array.to_list (Sys.readdir (Filename.concat dir "cache"))));
    installing ~dir "exit 1" (fun () -> Alcotest.(check bool) "what is installed is not installed again" true (Sys.file_exists (Driver.locate ()).cli))

(* Starting Playwright can be given up while the driver is being installed. *)
let test_driver_install_cancelled () =
    if Sys.win32 then Alcotest.skip ();
    with_temp_dir @@ fun dir ->
    installing ~dir (slow_installer ~dir) (fun () ->
        Eio_main.run @@ fun env ->
        let outcome, seconds =
            elapsed (fun () -> Eio.Time.with_timeout (Eio.Stdenv.clock env) 0.3 (fun () -> Eio.Switch.run (fun sw -> Ok (ignore (Instance.create ~sw ~env ())))))
        in
        Alcotest.(check bool) "cancelled" true (outcome = Error `Timeout);
        Alcotest.(check bool) "at once" true (seconds < 5.);
        check_cleaned_up ~dir)

(* {1 Files} *)

let test_files () =
    with_temp_dir @@ fun dir ->
    Eio_main.run @@ fun _env ->
    let path = List.fold_left Filename.concat dir [ "made"; "on"; "the"; "way"; "file.bin" ] in
    let contents = String.init 300_000 (fun i -> Char.chr (i mod 251)) in
    Files.write path contents;
    Alcotest.(check bool) "written into directories that did not exist, and read back" true (String.equal contents (Files.read path));
    let missing = Filename.concat dir "missing.txt" in
    let error = failure "missing file" (fun () -> Files.read missing) in
    check_contains "says what was tried" ~sub:"Cannot read file" error.message;
    check_contains "and with which file" ~sub:missing error.message;
    check_contains "also for writing" ~sub:"Cannot write file" (failure "a directory in the way" (fun () -> Files.write dir "x")).message;
    (* In parts, as files travel to and from a remote driver. *)
    let large = String.init ((2 * Files.chunk_size) + 12_345) (fun i -> Char.chr (i mod 253)) in
    let copy = Filename.concat dir "copy.bin" in
    Files.write path large;
    let parts = ref [] in
    Files.with_input path (fun read ->
        Files.with_output copy (fun write ->
            let rec go () =
                match read () with
                | "" -> ()
                | part ->
                    parts := String.length part :: !parts;
                    write part;
                    go ()
            in
            go ()));
    Alcotest.(check (list int)) "the parts" [ Files.chunk_size; Files.chunk_size; 12_345 ] (List.rev !parts);
    Alcotest.(check bool) "the copy" true (String.equal large (Files.read copy));
    let uploads = Files.to_upload ~directory:(Filename.concat dir "made") [] in
    Alcotest.(check (list string)) "the files below a directory" [ "on/the/way/file.bin" ] (List.map (fun (file : Files.upload) -> file.name) uploads);
    Alcotest.(check (pair (list string) (list string))) "directories apart" ([ dir ], [ path ]) (Files.partition_directories [ dir; path ])

(* A read that takes its time: of a pipe that nobody has written to yet.  Done in place, it
   would keep the fiber from running that is to write. *)
let test_files_do_not_block () =
    if Sys.win32 then Alcotest.skip ();
    with_temp_dir @@ fun dir ->
    Eio_main.run @@ fun _env ->
    let pipe = Filename.concat dir "pipe" in
    Unix.mkfifo pipe 0o600;
    let contents = ref "" in
    Eio.Fiber.both
        (fun () -> contents := Files.read pipe)
        (fun () -> Out_channel.with_open_bin pipe (fun oc -> output_string oc "written meanwhile"));
    Alcotest.(check string) "other fibers ran during the read" "written meanwhile" !contents

(* {1 Blocking work} *)

let test_in_systhread () =
    Eio_main.run @@ fun env ->
    Alcotest.(check int) "the result" 42 (Fibers.in_systhread (fun ~cancelled:_ -> 42));
    (match Fibers.in_systhread (fun ~cancelled:_ -> failwith "from the thread") with
    | () -> Alcotest.fail "the exception must be raised in the fiber"
    | exception Failure message -> Alcotest.(check string) "the exception" "from the thread" message);
    let told = ref false in
    let work ~cancelled =
        while not (cancelled ()) do Unix.sleepf 0.005 done;
        told := true
    in
    Eio.Fiber.first (fun () -> Fibers.in_systhread work) (fun () -> Eio.Time.sleep (Eio.Stdenv.clock env) 0.05);
    Alcotest.(check bool) "the thread is told of the cancellation, and waited for" true !told

let test_error_rendering () =
    let error = Error.make ~kind:Timeout ~name:"TimeoutError" "Timeout 5ms exceeded." in
    Alcotest.(check string) "named errors show their name" "TimeoutError: Timeout 5ms exceeded." (Error.to_string error);
    Alcotest.(check string) "plain errors do not" "boom" (Error.to_string (Error.make "boom"));
    Alcotest.(check string) "registered with Printexc" "Playwright.Error: boom" (Printexc.to_string (Error.E (Error.make "boom")));
    Alcotest.(check string) "empty call logs are left out" "" (Error.call_log [ ""; "" ])

let tests =
    [ "timeouts", [ Alcotest.test_case "precedence" `Quick test_timeouts ];
      "driver",
      [ Alcotest.test_case "cache directory" `Quick test_driver_cache_dir;
        Alcotest.test_case "PATH lookup" `Quick test_driver_path_lookup;
        Alcotest.test_case "locate" `Quick test_driver_locate;
        Alcotest.test_case "installation" `Quick test_driver_install;
        Alcotest.test_case "cancelled installation" `Quick test_driver_install_cancelled ];
      "files", [ Alcotest.test_case "reading and writing" `Quick test_files; Alcotest.test_case "other fibers go on" `Quick test_files_do_not_block ];
      "blocking work", [ Alcotest.test_case "in a thread" `Quick test_in_systhread ];
      "error", [ Alcotest.test_case "rendering" `Quick test_error_rendering ] ]
