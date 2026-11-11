(* Running the driver as a child process, with ordinary programs standing in for it.  Both ways
   of doing the input and output are tested: the one built on Eio's process manager, and the one
   built on system threads that Windows needs and that works everywhere. *)

open Eio.Std
open Internal

let program name = match Driver.find_in_path name with Some path -> path | None -> Alcotest.skip ()

let run ~threads ?grace_period executable args f =
    Eio_main.run (fun env -> Switch.run (fun sw -> f env (Driver_process.spawn_command ~threads ?grace_period ~sw ~env executable args)))

let elapsed f =
    let start = Unix.gettimeofday () in
    f ();
    Unix.gettimeofday () -. start

let scratch_file () =
    let path = Filename.temp_file "playwright-test" ".txt" in
    Sys.remove path;
    path

let rec wait_for_file ?(attempts = 500) path =
    if not (Sys.file_exists path && (Unix.stat path).st_size > 0) then
        if attempts = 0 then Alcotest.failf "%s was not written" path
        else begin
            Unix.sleepf 0.01;
            wait_for_file ~attempts:(attempts - 1) path
        end

(* [cat] sends every message back, which exercises both directions at once: with messages
   larger than a pipe holds, neither side gets anywhere unless the other makes progress too. *)
let test_echo ~threads () =
    run ~threads (program "cat") [] (fun _env (process : Driver_process.t) ->
        let messages =
            List.init 40 (fun i -> `Assoc [ "id", `Int i; "text", `String (String.make (i * 997) 'x') ])
            @ [ `String (String.make 3_000_000 'y'); `Assoc [ "last", `Bool true ] ]
        in
        let received = ref [] in
        Fiber.both
            (fun () -> List.iter process.transport.send messages)
            (fun () ->
                List.iter
                    (fun _ -> match process.transport.receive () with Some message -> received := message :: !received | None -> Alcotest.fail "the stream ended early")
                    messages);
        Alcotest.(check (list json)) "every message came back, in order" messages (List.rev !received);
        process.stop ();
        process.stop ())

(* The process is told to finish by closing its input, and [stop] waits until it has. *)
let test_graceful_stop ~threads () =
    let marker = scratch_file () in
    Fun.protect
        ~finally:(fun () -> try Sys.remove marker with Sys_error _ -> ())
        (fun () ->
            run ~threads (program "sh") [ "-c"; "cat > /dev/null; echo finished > \"$0\""; marker ] (fun _env (process : Driver_process.t) ->
                process.transport.send (`Assoc [ "hello", `Int 1 ]);
                let seconds = elapsed process.stop in
                Alcotest.(check bool) "the process ran to its end" true (Sys.file_exists marker);
                Alcotest.(check bool) (Printf.sprintf "promptly (%.2f s)" seconds) true (seconds < 5.)))

(* A process that does not finish by itself is killed once its time is up. *)
let test_forced_stop ~threads () =
    let pid_file = scratch_file () in
    Fun.protect
        ~finally:(fun () -> try Sys.remove pid_file with Sys_error _ -> ())
        (fun () ->
            run ~threads ~grace_period:0.2 (program "sh") [ "-c"; "echo $$ > \"$0\"; exec sleep 600"; pid_file ] (fun _env (process : Driver_process.t) ->
                wait_for_file pid_file;
                let pid = int_of_string (String.trim (In_channel.with_open_bin pid_file In_channel.input_all)) in
                let seconds = elapsed process.stop in
                Alcotest.(check bool) (Printf.sprintf "after the grace period (%.2f s)" seconds) true (seconds >= 0.2 && seconds < 5.);
                match Unix.kill pid 0 with
                | () -> Alcotest.fail "the process is still there"
                | exception Unix.Unix_error (Unix.ESRCH, _, _) -> ()))

(* Nothing may keep the switch from finishing: not a fiber that waits for a message, and not one
   whose message cannot be delivered because the process does not read. *)
let test_cancellation ~threads () =
    let seconds =
        elapsed (fun () ->
            run ~threads ~grace_period:0.2 (program "sleep") [ "600" ] (fun _env (process : Driver_process.t) ->
                let big = `String (String.make 1_000_000 'z') in
                Fiber.first
                    (fun () ->
                        Fiber.both
                            (fun () -> ignore (process.transport.receive ()))
                            (fun () ->
                                while true do
                                    process.transport.send big
                                done))
                    (fun () -> Eio_unix.sleep 0.05)))
    in
    Alcotest.(check bool) (Printf.sprintf "cancelled and stopped (%.2f s)" seconds) true (seconds < 5.)

let test_exit ~threads () =
    run ~threads (program "true") [] (fun _env (process : Driver_process.t) ->
        Alcotest.(check bool) "the stream ends" true (process.transport.receive () = None);
        process.stop ())

let test_missing_program () =
    let error =
        failure "spawning a missing program" (fun () ->
            run ~threads:false "/nonexistent/playwright-node" [] (fun _env (process : Driver_process.t) -> process.stop ()))
    in
    check_contains "names the program" ~sub:"/nonexistent/playwright-node" error.message

let tests =
    if Sys.win32 then []
    else
        let both name test =
            [ Alcotest.test_case (name ^ " (native)") `Quick (test ~threads:false); Alcotest.test_case (name ^ " (threads)") `Quick (test ~threads:true) ]
        in
        [ ( "driver process",
            both "echo" test_echo @ both "graceful stop" test_graceful_stop @ both "forced stop" test_forced_stop
            @ both "cancellation" test_cancellation @ both "exit" test_exit
            @ [ Alcotest.test_case "missing program" `Quick test_missing_program ] ) ]
