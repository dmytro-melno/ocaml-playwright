(* An instance of Playwright: a driver process, the connection to it and what serves the two. *)

open Eio.Std

type t = Types.playwright

let version = Protocol.playwright_version

(* Where exceptions go that have nobody to be raised in and nobody else to be told to.  It does
   not raise: standard error may be closed, or full and not to be waited for. *)
let report_to_stderr what ex backtrace =
    let text = Printf.sprintf "Playwright: uncaught exception in %s: %s\n%s" what (Printexc.to_string ex) (Printexc.raw_backtrace_to_string backtrace) in
    try
        prerr_string text;
        flush stderr
    with Sys_error _ | Sys_blocked_io -> ()

(* What the connection reports to.  It is called where something has just failed, in the middle
   of things, so it must not fail in its turn: an [on_error] that raises is itself reported,
   along with what it was given.  Nor is it cancelled: what fails while things are being taken
   down is no less worth knowing.  [on_error] runs in a handler of the exception it is told
   about, which is where [Printexc.get_raw_backtrace] finds the backtrace. *)
let reporter = function
    | None -> report_to_stderr
    | Some on_error -> (
        fun what ex backtrace ->
            try Eio.Cancel.protect (fun () -> try Printexc.raise_with_backtrace ex backtrace with ex -> on_error what ex)
            with failure ->
                let failure_backtrace = Printexc.get_raw_backtrace () in
                report_to_stderr what ex backtrace;
                report_to_stderr "the on_error function" failure failure_backtrace)

(* Protocol tracing, enabled the way it is in every Playwright client: DEBUG=pw:channel. *)
let wire_trace () =
    let enabled =
        match Sys.getenv_opt "DEBUG" with
        | None -> false
        | Some value -> List.exists (fun name -> name = "pw:channel" || name = "pw:*" || name = "*") (String.split_on_char ',' value)
    in
    if not enabled then None
    else
        Some
            (fun line ->
                let limit = 4096 in
                let line = if String.length line > limit then String.sub line 0 limit ^ Printf.sprintf "... (%d bytes)" (String.length line) else line in
                prerr_endline ("pw:channel " ^ line))

let initialize_timeout = 60_000.

let create ?on_error ?handler_concurrency ?handler_backlog ~sw
        ~(env : Eio_unix.Stdenv.base) () : t =
    (* Installing the driver can take a while, during which other fibers go on. *)
    let driver = Eio_unix.run_in_systhread ~label:"playwright-driver" (fun () -> Driver.locate ()) in
    let process = Driver_process.spawn ~sw ~env driver in
    let conn =
        Connection.create ~clock:(Eio.Stdenv.clock env)
            ~report:(reporter on_error)
            ?trace:(wire_trace ())
            ?handler_concurrency ?handler_backlog
            ~render_value:(fun value -> Js.show (Js.of_wire value))
            process.transport
    in
    let session = Objects.new_session conn in
    (* The instance is served by this fiber, which also takes it down, whatever ends it: {!close},
       the driver going away or the switch finishing.  The connection goes first, which settles
       every object and cancels the handlers; then the driver, which takes its browsers with it
       and is given a bounded time to comply.  [process.stop] cannot be cancelled. *)
    let stopped, stopped_resolver = Promise.create () in
    let serving = ref false in
    Fiber.fork_daemon ~sw (fun () ->
        serving := true;
        let stop_driver () = Fun.protect ~finally:(Promise.resolve stopped_resolver) process.stop in
        (match Connection.run conn with
        | () -> stop_driver ()
        | exception ex ->
            let backtrace = Printexc.get_raw_backtrace () in
            stop_driver ();
            Printexc.raise_with_backtrace ex backtrace);
        `Stop_daemon);
    if not !serving then begin
        (* The switch is being cancelled. *)
        process.stop ();
        Promise.resolve stopped_resolver ();
        Switch.check sw
    end;
    match
        let channel =
            Connection.with_timeout conn ~timeout:initialize_timeout
                ~message:(fun () -> "Timed out waiting for the Playwright driver to start")
                (fun () -> Objects.initialize conn)
        in
        let init = Protocol.Playwright.initializer_ channel in
        { Types.session; pw_channel = channel; chromium = Types.browser_type init.chromium; firefox = Types.browser_type init.firefox;
          webkit = Types.browser_type init.webkit; stopped }
    with
    | playwright -> playwright
    | exception ex ->
        let backtrace = Printexc.get_raw_backtrace () in
        Connection.close conn (Error.target_closed ~message:"Playwright could not be started" ());
        Eio.Cancel.protect (fun () -> Promise.await stopped);
        Printexc.raise_with_backtrace ex backtrace

(* Ends the connection, which is immediate, and waits for the rest to follow.  A handler of the
   instance that closes it is itself cancelled while it waits here. *)
let close (t : t) =
    Connection.close t.session.conn (Error.target_closed ~message:"Playwright has been closed" ());
    Promise.await t.stopped

let run ?on_error ?handler_concurrency ?handler_backlog ~env f =
    Switch.run (fun sw ->
        let t = create ?on_error ?handler_concurrency ?handler_backlog ~sw ~env () in
        Fun.protect ~finally:(fun () -> Eio.Cancel.protect (fun () -> close t)) (fun () -> f t))
