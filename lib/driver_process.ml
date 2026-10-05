(* Keep OS process details out of the protocol/session implementation. In
   particular, never access env#process_mgr on Eio's Windows backend. *)
type t = {
    stdin : [Eio.Flow.sink_ty | Eio.Resource.close_ty] Eio.Resource.t;
    stdout : [Eio.Flow.source_ty | Eio.Resource.close_ty] Eio.Resource.t;
    await : unit -> Eio.Process.exit_status;
    terminate : unit -> unit;
    kill : unit -> unit;
}

let stdin t = t.stdin
let stdout t = t.stdout
let await t = t.await ()
let terminate t = t.terminate ()
let kill t = t.kill ()

let spawn ~sw ~(env : Eio_unix.Stdenv.base) ~cli =
    if Sys.win32 then begin
        let process = Driver_process_windows.spawn ~sw ~cli in
        {
            stdin = Driver_process_windows.stdin process;
            stdout = Driver_process_windows.stdout process;
            await = (fun () -> Driver_process_windows.await process);
            terminate = (fun () -> Driver_process_windows.kill process);
            kill = (fun () -> Driver_process_windows.kill process);
        }
    end else begin
        let process_mgr = Eio.Stdenv.process_mgr env in
        let child_stdin, stdin = Eio.Process.pipe ~sw process_mgr in
        let stdout, child_stdout = Eio.Process.pipe ~sw process_mgr in
        let process =
            Fun.protect
                ~finally:(fun () -> Eio.Flow.close child_stdin; Eio.Flow.close child_stdout)
                (fun () ->
                    Eio.Process.spawn ~sw process_mgr ~stdin:child_stdin ~stdout:child_stdout
                        ["node"; cli; "run-driver"])
        in
        {
            stdin; stdout;
            await = (fun () -> Eio.Process.await process);
            terminate = (fun () -> Eio.Process.signal process Sys.sigterm);
            kill = (fun () -> Eio.Process.signal process Sys.sigkill);
        }
    end
