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

let test_driver_directory () =
    if Sys.win32 then Alcotest.skip ();
    let installed = Filename.concat "ocaml-playwright" ("driver-" ^ Protocol.playwright_version) in
    with_env [ "XDG_CACHE_HOME", "/xdg"; "HOME", "/home/user" ] (fun () ->
        Alcotest.(check string) "in the cache, one directory per driver version" (Filename.concat "/xdg" installed) (Driver.installed_dir ()));
    with_env [ "XDG_CACHE_HOME", ""; "HOME", "/home/user" ] (fun () ->
        Alcotest.(check string) "which is in the home directory by default" (Filename.concat "/home/user/.cache" installed) (Driver.installed_dir ()))

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
        let driver = Driver.locate () in
        Alcotest.(check string) "node" node driver.node;
        Alcotest.(check string) "cli" (Filename.concat (Filename.concat package "package") "cli.js") driver.cli;
        Alcotest.(check (list string)) "the command line of the tool" [ node; driver.cli; "install"; "chromium" ] (Driver.command [ "install"; "chromium" ]));
    with_env [ "PLAYWRIGHT_NODEJS_PATH", node; "PLAYWRIGHT_OCAML_DRIVER", Filename.concat dir "nowhere" ] (fun () ->
        check_contains "a wrong driver directory is explained" ~sub:"PLAYWRIGHT_OCAML_DRIVER" (failure "wrong driver" Driver.locate).message;
        check_contains "also to who installs" ~sub:"PLAYWRIGHT_OCAML_DRIVER" (failure "wrong driver" Driver.install).message);
    with_env [ "PLAYWRIGHT_NODEJS_PATH", Filename.concat dir "no-node"; "PLAYWRIGHT_OCAML_DRIVER", package ] (fun () ->
        check_contains "a wrong node path is explained" ~sub:"PLAYWRIGHT_NODEJS_PATH" (failure "wrong node" Driver.locate).message)

(* A stand-in for Node.js: a shell script, which is given what the installer is given, that is
   the installing script, the URL, the checksum and the directory to unpack into. *)
let fake_node dir body =
    let path = Filename.concat dir "node" in
    Out_channel.with_open_bin path (fun oc -> output_string oc ("#!/bin/sh\n" ^ body ^ "\n"));
    Unix.chmod path 0o755;
    path

let test_driver_install () =
    if Sys.win32 then Alcotest.skip ();
    with_temp_dir @@ fun dir ->
    let cache = Filename.concat (Filename.concat dir "cache") "ocaml-playwright" in
    let installing body f = with_env [ "PLAYWRIGHT_NODEJS_PATH", fake_node dir body; "PLAYWRIGHT_OCAML_DRIVER", ""; "XDG_CACHE_HOME", Filename.concat dir "cache" ] f in
    let unpack = {|mkdir -p "$4/package" && echo > "$4/package/cli.js"|} in
    installing unpack (fun () ->
        check_contains "a missing driver is reported with the command that installs it" ~sub:"ocaml-playwright install" (failure "not installed" Driver.locate).message;
        check_contains "also to who asks for the tool" ~sub:"not installed" (failure "not installed" (fun () -> Driver.command [])).message;
        Alcotest.(check bool) "and not installed behind the caller's back" false (Sys.file_exists cache));
    installing {|echo "no route to host" >&2; exit 1|} (fun () ->
        check_contains "the installer's complaint is passed on" ~sub:"no route to host" (failure "failed installation" Driver.install).message;
        Alcotest.(check (list string)) "and nothing is left in the cache" [] (Array.to_list (Sys.readdir cache)));
    installing "exit 0" (fun () -> check_contains "an installer that unpacks nothing has failed" ~sub:"Could not install" (failure "nothing unpacked" Driver.install).message);
    installing unpack (fun () ->
        Driver.install ();
        Alcotest.(check string) "installed into the cache" (List.fold_left Filename.concat (Driver.installed_dir ()) [ "package"; "cli.js" ]) (Driver.locate ()).cli;
        Alcotest.(check (list string)) "and nothing else" [ "driver-" ^ Protocol.playwright_version ] (Array.to_list (Sys.readdir cache)));
    installing "exit 1" (fun () ->
        Driver.install ();
        Alcotest.(check bool) "what is installed is not installed again" true (Sys.file_exists (Driver.locate ()).cli));
    (* The tool is run by the stand-in as well, which is given the tool and its arguments. *)
    installing {|test "$2" = show-trace || exit 3; exit 7|} (fun () -> Alcotest.(check int) "the tool's exit code" 7 (Driver.run_command [ "show-trace" ]));
    Driver.rm_rf cache;
    installing (Printf.sprintf {|if test "$2" = install; then exit 5; fi; %s|} unpack) (fun () ->
        Alcotest.(check int) "running the tool installs the driver first" 5 (Driver.run_command [ "install"; "chromium" ]);
        Alcotest.(check bool) "which is there afterwards" true (Sys.file_exists (Driver.locate ()).cli))

(* {1 Files} *)

let test_files () =
    with_temp_dir @@ fun dir ->
    Eio_main.run @@ fun _env ->
    let file = Filename.concat dir "file.txt" in
    Out_channel.with_open_bin file (fun oc -> output_string oc "x");
    Alcotest.(check (pair (list string) (list string))) "directories apart, and what is not there with the files" ([ dir ], [ file; Filename.concat dir "missing" ])
        (Files.partition_directories [ dir; file; Filename.concat dir "missing" ]);
    Alcotest.(check string) "an absolute path is kept" file (Files.absolute file);
    Alcotest.(check string) "a relative one is seen from the working directory" (Filename.concat (Sys.getcwd ()) "file.txt") (Files.absolute "file.txt")

let test_error_rendering () =
    let error = Error.make ~kind:Timeout ~name:"TimeoutError" "Timeout 5ms exceeded." in
    Alcotest.(check string) "named errors show their name" "TimeoutError: Timeout 5ms exceeded." (Error.to_string error);
    Alcotest.(check string) "plain errors do not" "boom" (Error.to_string (Error.make "boom"));
    Alcotest.(check string) "registered with Printexc" "Playwright.Error: boom" (Printexc.to_string (Error.E (Error.make "boom")));
    Alcotest.(check string) "empty call logs are left out" "" (Error.call_log [ ""; "" ])

let tests =
    [ "timeouts", [ Alcotest.test_case "precedence" `Quick test_timeouts ];
      "driver",
      [ Alcotest.test_case "where it is installed" `Quick test_driver_directory;
        Alcotest.test_case "PATH lookup" `Quick test_driver_path_lookup;
        Alcotest.test_case "locate" `Quick test_driver_locate;
        Alcotest.test_case "installation" `Quick test_driver_install ];
      "files", [ Alcotest.test_case "paths" `Quick test_files ];
      "error", [ Alcotest.test_case "rendering" `Quick test_error_rendering ] ]
