(* Fiber helpers that the client is built with. *)

open Eio.Std

let is_cancellation = function Eio.Cancel.Cancelled _ -> true | _ -> false

(* Runs [f], which blocks, in a thread of its own, as [Eio_unix.run_in_systhread] does.  A
   thread cannot be cancelled, and the fiber goes on only when [f] is over.  So [f] is given a
   function that tells whether the fiber has been cancelled, to ask now and then and to make an
   end when it has; what [f] returns then does not matter. *)
let in_systhread ?label f =
    let cancelled = Atomic.make false in
    let outcome =
        Switch.run (fun sw ->
            Fiber.fork_daemon ~sw (fun () ->
                (try Fiber.await_cancel () with ex when is_cancellation ex -> Atomic.set cancelled true);
                `Stop_daemon);
            Eio_unix.run_in_systhread ?label (fun () ->
                try Ok (f ~cancelled:(fun () -> Atomic.get cancelled)) with ex -> Error (ex, Printexc.get_raw_backtrace ())))
    in
    Fiber.check ();
    match outcome with
    | Ok value -> value
    | Error (ex, backtrace) -> Printexc.raise_with_backtrace ex backtrace

(* [Fiber.first] for operations that can fail: the outcome of the one that is over first counts,
   and that of [f] when both are over at once.  [Fiber.first] itself would then report the two
   failures together, as an exception that no caller expects. *)
let first f g =
    let outcome h () = try Ok (h ()) with ex when not (is_cancellation ex) -> Error (ex, Printexc.get_raw_backtrace ()) in
    match Fiber.first (outcome f) (outcome g) with
    | Ok value -> value
    | Error (ex, backtrace) -> Printexc.raise_with_backtrace ex backtrace
