(* The driver as a child process, talking over its standard input and output.

   There are two ways to run it.  Where Eio can spawn processes, its process manager and
   non-blocking pipes are used.  Elsewhere, which means on Windows, the Unix library's blocking
   pipes are each served by a system thread, and fibers wait for those threads in ways that can
   be cancelled: a fiber blocked on the driver must never keep its switch from finishing. *)

open Eio.Std

type t = {
    transport : Transport.t;
    stop : unit -> unit;  (* ends the driver, gracefully if it cooperates; idempotent *)
}

(* What either way of running the driver provides. *)
type process = {
    read : Cstruct.t -> int;  (* from the driver's output; raises [End_of_file] at its end *)
    write : Cstruct.t list -> unit;  (* to the driver's input *)
    close_input : unit -> unit;
    await_exit : unit -> unit;
    kill : unit -> unit;
    release : unit -> unit;  (* frees what is left, once the driver is gone *)
}

module Native = struct
    let spawn ~sw ~(env : Eio_unix.Stdenv.base) executable args =
        let mgr = Eio.Stdenv.process_mgr env in
        let quietly f = try f () with Eio.Io _ | Invalid_argument _ -> () in
        let child_stdin, stdin = Eio.Process.pipe ~sw mgr in
        let stdout, child_stdout = Eio.Process.pipe ~sw mgr in
        let process =
            Fun.protect
                ~finally:(fun () ->
                    Eio.Flow.close child_stdin;
                    Eio.Flow.close child_stdout)
                (fun () ->
                    try Eio.Process.spawn ~sw mgr ~stdin:child_stdin ~stdout:child_stdout ~executable (executable :: args)
                    with ex ->
                        quietly (fun () -> Eio.Flow.close stdin);
                        quietly (fun () -> Eio.Flow.close stdout);
                        raise ex)
        in
        { read = Eio.Flow.single_read stdout;
          write = Eio.Flow.write stdin;
          close_input = (fun () -> quietly (fun () -> Eio.Flow.close stdin));
          await_exit = (fun () -> ignore (Eio.Process.await process));
          kill = (fun () -> quietly (fun () -> Eio.Process.signal process Sys.sigkill));
          release = (fun () -> quietly (fun () -> Eio.Flow.close stdout)) }
end

module Threads = struct
    let chunk_size = 1 lsl 16

    type input = Chunk of string | End | Failed of exn

    type reader = {
        inbox : input Eio.Stream.t;
        more : Semaphore.Binary.t;  (* lets the thread read the next chunk *)
        abandoned : bool Atomic.t;
        mutable chunk : string;
        mutable offset : int;  (* of the part of [chunk] that is still unread *)
    }

    (* The reading thread stays one chunk ahead of the fiber and no more, so that a slow consumer
       holds the driver back instead of filling memory.  It owns the descriptor: closing it from
       elsewhere while a read is in progress would be a race. *)
    let read_loop fd reader =
        let buffer = Bytes.create chunk_size in
        let rec loop () =
            match Unix.read fd buffer 0 chunk_size with
            | 0 -> End
            | n ->
                Eio.Stream.add reader.inbox (Chunk (Bytes.sub_string buffer 0 n));
                Semaphore.Binary.acquire reader.more;
                if Atomic.get reader.abandoned then End else loop ()
            | exception Unix.Unix_error (Unix.EINTR, _, _) -> loop ()
            | exception Unix.Unix_error (Unix.EPIPE, _, _) -> End
            | exception ex -> Failed ex
        in
        let last = loop () in
        (try Unix.close fd with Unix.Unix_error _ -> ());
        Eio.Stream.add reader.inbox last

    let read reader dst =
        if reader.offset = String.length reader.chunk then begin
            match Eio.Stream.take reader.inbox with
            | Chunk data ->
                reader.chunk <- data;
                reader.offset <- 0;
                Semaphore.Binary.release reader.more
            | (End | Failed _) as last ->
                (* It is the thread's last word, and stays there for later reads. *)
                Eio.Stream.add reader.inbox last;
                (match last with Failed ex -> raise ex | _ -> raise End_of_file)
        end;
        let n = min (Cstruct.length dst) (String.length reader.chunk - reader.offset) in
        Cstruct.blit_from_string reader.chunk reader.offset dst 0 n;
        reader.offset <- reader.offset + n;
        n

    let abandon reader =
        Atomic.set reader.abandoned true;
        Semaphore.Binary.release reader.more

    type job = Write of string * (unit, exn) result Promise.u | Close

    type writer = {
        mutex : Mutex.t;
        pending : Condition.t;
        jobs : job Queue.t;
        mutable closed : bool;
    }

    (* The writing thread owns its descriptor too, and closes it when it gets to [Close]. *)
    let write_loop fd writer =
        let next () =
            Mutex.protect writer.mutex (fun () ->
                while Queue.is_empty writer.jobs do
                    Condition.wait writer.pending writer.mutex
                done;
                Queue.pop writer.jobs)
        in
        let rec write_all data offset =
            if offset < String.length data then
                match Unix.write_substring fd data offset (String.length data - offset) with
                | n -> write_all data (offset + n)
                | exception Unix.Unix_error (Unix.EINTR, _, _) -> write_all data offset
        in
        let rec loop () =
            match next () with
            | Write (data, resolver) ->
                Promise.resolve resolver (try Ok (write_all data 0) with ex -> Error ex);
                loop ()
            | Close -> ( try Unix.close fd with Unix.Unix_error _ -> ())
        in
        loop ()

    (* [false] when the input has been closed already. *)
    let submit writer job =
        Mutex.protect writer.mutex (fun () ->
            (not writer.closed)
            && begin
                (match job with Close -> writer.closed <- true | Write _ -> ());
                Queue.push job writer.jobs;
                Condition.signal writer.pending;
                true
            end)

    (* A fiber that is cancelled while it waits here leaves its data behind to be written all the
       same, so a message is never cut short. *)
    let write writer buffers =
        let written, resolver = Promise.create () in
        if not (submit writer (Write (Cstruct.copyv buffers, resolver))) then raise (Unix.Unix_error (Unix.EPIPE, "write", ""));
        match Promise.await written with Ok () -> () | Error ex -> raise ex

    let spawn executable args =
        let close fd = try Unix.close fd with Unix.Unix_error _ -> () in
        let child_stdin, stdin = Unix.pipe ~cloexec:true () in
        let stdout, child_stdout =
            try Unix.pipe ~cloexec:true ()
            with ex ->
                close child_stdin;
                close stdin;
                raise ex
        in
        let pid =
            Fun.protect
                ~finally:(fun () ->
                    close child_stdin;
                    close child_stdout)
                (fun () ->
                    try Unix.create_process executable (Array.of_list (executable :: args)) child_stdin child_stdout Unix.stderr
                    with ex ->
                        close stdin;
                        close stdout;
                        raise ex)
        in
        let reader = { inbox = Eio.Stream.create max_int; more = Semaphore.Binary.make false; abandoned = Atomic.make false; chunk = ""; offset = 0 } in
        let writer = { mutex = Mutex.create (); pending = Condition.create (); jobs = Queue.create (); closed = false } in
        ignore (Thread.create (read_loop stdout) reader : Thread.t);
        ignore (Thread.create (write_loop stdin) writer : Thread.t);
        (* Once the process has been waited for, its identifier must not be used again: Windows
           recycles it as soon as the handle is closed. *)
        let exited = ref false in
        let has_exited () =
            !exited
            ||
            match Unix.waitpid [ Unix.WNOHANG ] pid with
            | 0, _ -> false
            | _ ->
                exited := true;
                true
            | exception Unix.Unix_error (Unix.EINTR, _, _) -> false
            | exception Unix.Unix_error (Unix.ECHILD, _, _) ->
                exited := true;
                true
        in
        (* Only used while shutting down, when the wait is short. *)
        let rec await_exit delay =
            if not (has_exited ()) then begin
                Eio_unix.sleep delay;
                await_exit (Float.min 0.02 (delay *. 2.))
            end
        in
        { read = read reader;
          write = write writer;
          close_input = (fun () -> ignore (submit writer Close : bool));
          await_exit = (fun () -> await_exit 0.001);
          kill = (fun () -> if not (has_exited ()) then try Unix.kill pid Sys.sigkill with Unix.Unix_error _ -> ());
          release = (fun () -> abandon reader) }
end

(* Closing its input asks the driver to close every browser and exit.  Its remaining output is
   discarded meanwhile, so that it cannot block on a full pipe.  A driver that has not exited
   after [grace_period] seconds is killed. *)
let shut_down ~clock ~grace_period process =
    process.close_input ();
    let drain () =
        let buffer = Cstruct.create 65536 in
        (try
            while true do
                ignore (process.read buffer : int)
            done
        with End_of_file | Eio.Io _ | Unix.Unix_error _ -> ());
        Fiber.await_cancel ()
    in
    (match Eio.Time.with_timeout clock grace_period (fun () -> Ok (Fiber.first drain process.await_exit)) with
    | Ok () -> ()
    | Error `Timeout ->
        process.kill ();
        process.await_exit ());
    process.release ()

(* The threads implementation also works on Unix, where this setting selects it for testing. *)
let use_threads () = Sys.win32 || Sys.getenv_opt "PLAYWRIGHT_OCAML_DRIVER_IO" = Some "threads"

let spawn_command ?(threads = use_threads ()) ?(grace_period = 10.) ~sw ~(env : Eio_unix.Stdenv.base) executable args =
    let process =
        try if threads then Threads.spawn executable args else Native.spawn ~sw ~env executable args
        with (Eio.Io _ | Unix.Unix_error _) as ex -> Error.raise_ "Could not start the Playwright driver (%s): %s" executable (Printexc.to_string ex)
    in
    let clock = Eio.Stdenv.clock env in
    let stopped = ref None in
    (* Stopping takes a bounded time and is not interrupted by cancellation: a driver that is
       left running keeps its browsers running. *)
    let stop () =
        Eio.Cancel.protect (fun () ->
            match !stopped with
            | Some stopped -> Promise.await stopped
            | None ->
                let promise, resolver = Promise.create () in
                stopped := Some promise;
                Fun.protect ~finally:(Promise.resolve resolver) (fun () -> shut_down ~clock ~grace_period process))
    in
    (* Whatever happens to the session, the driver does not outlive its switch. *)
    Switch.on_release sw stop;
    { transport = Transport.of_stream ~read:process.read ~write:process.write; stop }

let spawn ~sw ~env (driver : Driver.t) = spawn_command ~sw ~env driver.node [ driver.cli; "run-driver" ]
