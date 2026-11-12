(* The driver as a child process, talking over its standard input and output.

   The process is started with the Unix library, and each of its two blocking pipes is served
   by a system thread.  Fibers wait for those threads in ways that can be cancelled: a fiber
   blocked on the driver must never keep its switch from finishing.  This is the one way that
   works on every system: Eio has no process manager on Windows, and its pipes cannot be read
   without blocking there. *)

open Eio.Std

type t = {
    transport : Transport.t;
    stop : unit -> unit;  (* ends the driver, gracefully if it cooperates; idempotent *)
}

(* The running driver, as {!Threads.spawn} makes it. *)
type process = {
    read : Cstruct.t -> int;  (* from the driver's output; raises [End_of_file] at its end *)
    write : Cstruct.t list -> unit;  (* to the driver's input *)
    close_input : unit -> unit;
    await_exit : unit -> unit;
    kill : unit -> unit;
    release : unit -> unit;  (* frees what is left, once the driver is gone *)
}

(* The driver's standard error is not ours.  Node makes the pipes and sockets it is given
   non-blocking, and that is a property of the open file, not of the descriptor: a driver that
   inherited our standard error would change it for us as well, and the program's own writes to
   it would fail whenever its reader is slow.  So the driver gets a pipe of its own, and what
   comes out of it is copied to our standard error for as long as anybody holds the other end.
   A system thread does that, because it has to go on while fibers are busy or being cancelled,
   and while the driver says its last words. *)
module Errors = struct
    let copy input =
        let buffer = Bytes.create 4096 in
        let rec write offset length =
            if length > 0 then
                match Unix.write Unix.stderr buffer offset length with
                | n -> write (offset + n) (length - n)
                | exception Unix.Unix_error (Unix.EINTR, _, _) -> write offset length
                | exception Unix.Unix_error ((Unix.EAGAIN | Unix.EWOULDBLOCK), _, _) ->
                    (* Somebody else has made it non-blocking. *)
                    (try ignore (Unix.select [] [ Unix.stderr ] [] 1.) with Unix.Unix_error _ -> Thread.delay 0.01);
                    write offset length
                | exception Unix.Unix_error _ -> ()  (* nobody listens, which is no reason to hold the driver back *)
        in
        let rec loop () =
            match Unix.read input buffer 0 (Bytes.length buffer) with
            | 0 -> ()
            | n ->
                write 0 n;
                loop ()
            | exception Unix.Unix_error (Unix.EINTR, _, _) -> loop ()
            | exception Unix.Unix_error _ -> ()
        in
        loop ()

    (* The descriptor to give to the driver, which the caller closes once that is done, and a
       promise that is resolved when all the driver had to say has been copied. *)
    let relay () =
        let close fd = try Unix.close fd with Unix.Unix_error _ -> () in
        let input, output = Unix.pipe ~cloexec:true () in
        let copied, resolver = Promise.create () in
        let run () =
            Fun.protect (fun () -> copy input) ~finally:(fun () ->
                close input;
                Promise.resolve resolver ())
        in
        match Thread.create run () with
        | (_ : Thread.t) -> (output, copied)
        | exception ex ->
            close input;
            close output;
            raise ex
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

    let spawn ~stderr executable args =
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
                    try Unix.create_process executable (Array.of_list (executable :: args)) child_stdin child_stdout stderr
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
   after [grace_period] seconds is killed.  What it wrote to its standard error before it went
   is in the pipe by then, and is waited for: an explanation of why it went may be among it. *)
let shut_down ~clock ~grace_period ~errors_copied process =
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
    process.release ();
    (* Not for long, though: something that outlives the driver may hold its standard error. *)
    ignore (Eio.Time.with_timeout clock 1. (fun () -> Ok (Promise.await errors_copied)) : (unit, [ `Timeout ]) result)

let spawn_command ?(grace_period = 10.) ~sw ~clock executable args =
    let process, errors_copied =
        try
            let stderr, errors_copied = Errors.relay () in
            Fun.protect
                ~finally:(fun () -> try Unix.close stderr with Unix.Unix_error _ -> ())
                (fun () -> (Threads.spawn ~stderr executable args, errors_copied))
        with (Unix.Unix_error _ | Sys_error _) as ex -> Error.raise_ "Could not start the Playwright driver (%s): %s" executable (Printexc.to_string ex)
    in
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
                Fun.protect ~finally:(Promise.resolve resolver) (fun () -> shut_down ~clock ~grace_period ~errors_copied process))
    in
    (* Whatever happens to the session, the driver does not outlive its switch. *)
    Switch.on_release sw stop;
    { transport = Transport.of_stream ~read:process.read ~write:process.write; stop }

let spawn ~sw ~clock (driver : Driver.t) = spawn_command ~sw ~clock driver.node [ driver.cli; "run-driver" ]
