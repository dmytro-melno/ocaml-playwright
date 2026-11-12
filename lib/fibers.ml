(* Fiber helpers that the client is built with. *)

open Eio.Std

let is_cancellation = function Eio.Cancel.Cancelled _ -> true | _ -> false

(* [Fiber.first] for operations that can fail: the outcome of the one that is over first counts,
   and that of [f] when both are over at once.  [Fiber.first] itself would then report the two
   failures together, as an exception that no caller expects. *)
let first f g =
    let outcome h () = try Ok (h ()) with ex when not (is_cancellation ex) -> Error (ex, Printexc.get_raw_backtrace ()) in
    match Fiber.first (outcome f) (outcome g) with
    | Ok value -> value
    | Error (ex, backtrace) -> Printexc.raise_with_backtrace ex backtrace
