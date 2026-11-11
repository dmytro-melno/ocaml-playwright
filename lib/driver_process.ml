(* The driver as a child process, talking over its standard input and output. *)

open Eio.Std

type t = {
    transport : Transport.t;
    stop : unit -> unit;
}

(* How long the driver gets to close its browsers and exit once its input is closed. *)
let grace_period = 10.

let spawn ~sw ~(env : Eio_unix.Stdenv.base) (driver : Driver.t) =
    let mgr = Eio.Stdenv.process_mgr env in
    let clock = Eio.Stdenv.clock env in
    let child_stdin, stdin = Eio.Process.pipe ~sw mgr in
    let stdout, child_stdout = Eio.Process.pipe ~sw mgr in
    let process =
        Fun.protect
            ~finally:(fun () ->
                Eio.Flow.close child_stdin;
                Eio.Flow.close child_stdout)
            (fun () ->
                try Eio.Process.spawn ~sw mgr ~stdin:child_stdin ~stdout:child_stdout ~executable:driver.node [ driver.node; driver.cli; "run-driver" ]
                with Eio.Io _ as ex -> Error.raise_ "Could not start the Playwright driver (%s): %s" driver.node (Printexc.to_string ex))
    in
    let stopped = ref false in
    (* Closing its input asks the driver to close every browser and exit.  Its remaining output
       is discarded so that it cannot block on a full pipe meanwhile. *)
    let stop () =
        if not !stopped then begin
            stopped := true;
            (try Eio.Flow.close stdin with Eio.Io _ -> ());
            let drain () =
                let buffer = Cstruct.create 65536 in
                try
                    while true do
                        ignore (Eio.Flow.single_read stdout buffer)
                    done
                with End_of_file | Eio.Io _ -> ()
            in
            let exited () =
                Fiber.both drain (fun () -> ignore (Eio.Process.await process));
                Ok ()
            in
            (match Eio.Time.with_timeout clock grace_period exited with
            | Ok () -> ()
            | Error `Timeout ->
                (try Eio.Process.signal process Sys.sigkill with Eio.Io _ | Invalid_argument _ -> ());
                ignore (Eio.Process.await process));
            try Eio.Flow.close stdout with Eio.Io _ -> ()
        end
    in
    { transport = Transport.of_flows stdout stdin; stop }
