(* Private Windows transport. One reader and one writer per session, just as for
   Eio pipes. Kernel I/O uses C-owned buffers, so cancelling a fiber never leaves
   Windows holding a pointer into the OCaml heap. *)
type raw

external spawn_raw : string -> raw = "playwright_windows_spawn"
external read_raw : raw -> int -> string option = "playwright_windows_read"
external write_start : raw -> string -> unit = "playwright_windows_write_start"
external write_poll : raw -> int option = "playwright_windows_write_poll"
external poll_exit : raw -> int option = "playwright_windows_poll_exit"
external kill_raw : raw -> unit = "playwright_windows_kill"
external close_input_raw : raw -> unit = "playwright_windows_close_input"
external close_output_raw : raw -> unit = "playwright_windows_close_output"
external close_raw : raw -> unit = "playwright_windows_close"

type t = {
    raw : raw;
    mutable input_closed : bool;
    mutable output_closed : bool;
    mutable status : Eio.Process.exit_status option;
}

(* CreateProcess uses CRT argument quoting, not cmd.exe/shell quoting. *)
let quote_arg arg =
    if String.contains arg '\000' then invalid_arg "NUL in driver argument";
    let out = Buffer.create (String.length arg + 2) in
    let slashes = ref 0 in
    let flush n = Buffer.add_string out (String.make n '\\'); slashes := 0 in
    Buffer.add_char out '"';
    String.iter (function
        | '\\' -> incr slashes
        | '"' -> flush (2 * !slashes + 1); Buffer.add_char out '"'
        | c -> flush !slashes; Buffer.add_char out c) arg;
    flush (2 * !slashes);
    Buffer.add_char out '"';
    Buffer.contents out

let rec await t =
    match t.status with
    | Some status -> status
    | None ->
        match poll_exit t.raw with
        | Some code ->
            let status = `Exited code in
            t.status <- Some status;
            status
        | None -> Eio_unix.sleep 0.005; await t

let kill t = kill_raw t.raw

let close_input t =
    if not t.input_closed then begin
        t.input_closed <- true;
        Eio.Cancel.protect (fun () ->
            Eio_unix.run_in_systhread (fun () -> close_input_raw t.raw))
    end

let close_output t =
    if not t.output_closed then begin
        t.output_closed <- true;
        Eio.Cancel.protect (fun () ->
            Eio_unix.run_in_systhread (fun () -> close_output_raw t.raw))
    end

module Source = struct
    type nonrec t = t
    let read_methods = []
    let rec single_read t buffer =
        Eio.Fiber.check ();
        if t.output_closed then invalid_arg "Playwright stdout is closed";
        match read_raw t.raw (Cstruct.length buffer) with
        | Some "" -> raise End_of_file
        | Some data ->
            Cstruct.blit_from_string data 0 buffer 0 (String.length data);
            String.length data
        | None -> Eio_unix.sleep 0.001; single_read t buffer
end

module Sink = struct
    type nonrec t = t
    let check t =
        Eio.Fiber.check ();
        if t.input_closed then invalid_arg "Playwright stdin is closed"
    let rec finish t =
        check t;
        match write_poll t.raw with
        | Some n -> n
        | None -> Eio_unix.sleep 0.001; finish t
    let single_write t buffers =
        check t;
        match List.find_opt (fun b -> Cstruct.length b > 0) buffers with
        | None -> 0
        | Some buffer ->
            write_start t.raw (Cstruct.to_string ~len:(min 65536 (Cstruct.length buffer)) buffer);
            finish t
    let copy t ~src = Eio.Flow.Pi.simple_copy ~single_write t ~src
end

let source_handler =
    Eio.Resource.handler [
        Eio.Resource.H (Eio.Flow.Pi.Source, (module Source));
        Eio.Resource.H (Eio.Resource.Close, close_output);
    ]

let sink_handler =
    Eio.Resource.handler [
        Eio.Resource.H (Eio.Flow.Pi.Sink, (module Sink));
        Eio.Resource.H (Eio.Resource.Close, close_input);
    ]

let stdout t : [Eio.Flow.source_ty | Eio.Resource.close_ty] Eio.Resource.t =
    Eio.Resource.T (t, source_handler)

let stdin t : [Eio.Flow.sink_ty | Eio.Resource.close_ty] Eio.Resource.t =
    Eio.Resource.T (t, sink_handler)

let spawn ~sw ~cli =
    Eio.Switch.check sw;
    Eio.Cancel.protect (fun () ->
        let command = String.concat " " (List.map quote_arg ["node.exe"; cli; "run-driver"]) in
        let raw = Eio_unix.run_in_systhread (fun () -> spawn_raw command) in
        let t = { raw; input_closed = false; output_closed = false; status = None } in
        Eio.Switch.on_release sw (fun () ->
            (* The job also contains any browsers left behind after Node exits. *)
            Fun.protect
                ~finally:(fun () ->
                    t.input_closed <- true;
                    t.output_closed <- true;
                    Eio_unix.run_in_systhread (fun () -> close_raw raw))
                (fun () -> kill t; ignore (await t)));
        t)
