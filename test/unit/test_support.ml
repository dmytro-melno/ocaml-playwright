(* Events, waiting, timeouts and the driver installation. *)

open Eio.Std
open Internal

let with_peer = Test_wire.with_peer

(* {1 Emitter} *)

let test_emitter () =
    with_peer @@ fun peer ->
    let emitter = Emitter.create () in
    let log = ref [] in
    let note tag value = log := Printf.sprintf "%s:%d" tag value :: !log in
    let logged () = List.rev !log in
    Alcotest.(check bool) "no listener, not delivered" false (Emitter.emit peer.conn emitter 0);
    let a = note "a" and b = note "b" in
    Emitter.on emitter a;
    Emitter.once emitter (note "once");
    Emitter.on emitter b;
    Alcotest.(check bool) "delivered" true (Emitter.emit peer.conn emitter 1);
    ignore (Emitter.emit peer.conn emitter 2);
    Alcotest.(check (list string)) "registration order, once only once" [ "a:1"; "once:1"; "b:1"; "a:2"; "b:2" ] (logged ());
    Emitter.off emitter a;
    Emitter.off emitter (note "never registered");
    log := [];
    ignore (Emitter.emit peer.conn emitter 3);
    Alcotest.(check (list string)) "off removes exactly that listener" [ "b:3" ] (logged ());
    Emitter.off emitter b;
    Alcotest.(check bool) "empty again" false (Emitter.has_listeners emitter)

let test_emitter_listeners_may_block () =
    with_peer @@ fun peer ->
    let emitter = Emitter.create () in
    let gate, open_gate = Promise.create () in
    let log = ref [] in
    Emitter.on emitter (fun value ->
        if value = 1 then Promise.await gate;
        log := value :: !log);
    ignore (Emitter.emit peer.conn emitter 1);
    ignore (Emitter.emit peer.conn emitter 2);
    Alcotest.(check (list int)) "a blocked listener does not hold up later events" [ 2 ] !log;
    Promise.resolve open_gate ();
    Fiber.yield ();
    Alcotest.(check (list int)) "and finishes later" [ 1; 2 ] !log;
    (* An exception in a listener goes to the error hook instead of the reader. *)
    Emitter.on emitter (fun _ -> failwith "listener failed");
    ignore (Emitter.emit peer.conn emitter 3);
    Alcotest.(check bool) "reported" true (List.exists (fun (_, ex) -> ex = Failure "listener failed") !(peer.reported))

let test_emitter_watch () =
    with_peer @@ fun _ ->
    let emitter = Emitter.create () in
    let transitions = ref [] in
    Emitter.set_watch emitter (fun active -> transitions := active :: !transitions);
    let listener (_ : int) = () in
    Emitter.on emitter listener;
    let unsubscribe = Emitter.subscribe emitter ignore in
    Emitter.off emitter listener;
    Alcotest.(check (list bool)) "told about the first listener only" [ true ] (List.rev !transitions);
    unsubscribe ();
    Alcotest.(check (list bool)) "and about the last one leaving" [ true; false ] (List.rev !transitions)

(* {1 Waiter} *)

let test_waiter () =
    with_peer @@ fun peer ->
    let emitter = Emitter.create () in
    let closed = Emitter.create () in
    let wait ?(timeout = 1000.) action predicate =
        Waiter.using peer.conn ~timeout ~timeout_message:(fun () -> "Timeout while waiting for the event") (fun waiter ->
            Waiter.listen waiter emitter Option.some;
            Waiter.reject_on waiter closed (fun reason -> Some (Error.target_closed ~message:reason ()));
            action ();
            Waiter.next waiter (fun value -> if predicate value then Some value else None))
    in
    let emit values () = List.iter (fun value -> ignore (Emitter.emit peer.conn emitter value)) values in
    Alcotest.(check int) "an event emitted during the action is not missed" 1 (wait (emit [ 1 ]) (fun _ -> true));
    Alcotest.(check int) "the predicate selects" 4 (wait (emit [ 1; 3; 4; 6 ]) (fun value -> value mod 2 = 0));
    Alcotest.(check bool) "listeners are removed afterwards" false (Emitter.has_listeners emitter || Emitter.has_listeners closed);
    let late = failure "timeout" (fun () -> wait ~timeout:30. ignore (fun _ -> true)) in
    Alcotest.check error_kind "timeout kind" Error.Timeout late.kind;
    check_contains "timeout message" ~sub:"Timeout while waiting for the event" late.message;
    let gone = failure "rejection" (fun () -> wait (fun () -> ignore (Emitter.emit peer.conn closed "Page closed")) (fun _ -> true)) in
    Alcotest.check error_kind "rejection kind" Error.Target_closed gone.kind;
    Alcotest.(check string) "rejection message" "Page closed" gone.message;
    Alcotest.(check bool) "cleaned up after failures too" false (Emitter.has_listeners emitter || Emitter.has_listeners closed)

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

let test_error_rendering () =
    let error = Error.make ~kind:Timeout ~name:"TimeoutError" "Timeout 5ms exceeded." in
    Alcotest.(check string) "named errors show their name" "TimeoutError: Timeout 5ms exceeded." (Error.to_string error);
    Alcotest.(check string) "plain errors do not" "boom" (Error.to_string (Error.make "boom"));
    Alcotest.(check string) "registered with Printexc" "Playwright.Error: boom" (Printexc.to_string (Error.E (Error.make "boom")));
    Alcotest.(check string) "empty call logs are left out" "" (Error.call_log [ ""; "" ])

let tests =
    [ "emitter",
      [ Alcotest.test_case "listeners" `Quick test_emitter;
        Alcotest.test_case "blocking and failing listeners" `Quick test_emitter_listeners_may_block;
        Alcotest.test_case "watch" `Quick test_emitter_watch ];
      "waiter", [ Alcotest.test_case "events, timeouts and rejections" `Quick test_waiter ];
      "timeouts", [ Alcotest.test_case "precedence" `Quick test_timeouts ];
      "driver",
      [ Alcotest.test_case "cache directory" `Quick test_driver_cache_dir;
        Alcotest.test_case "PATH lookup" `Quick test_driver_path_lookup;
        Alcotest.test_case "locate" `Quick test_driver_locate ];
      "error", [ Alcotest.test_case "rendering" `Quick test_error_rendering ] ]
