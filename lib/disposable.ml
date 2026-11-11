(* What a registration returns, to take it back with: an event listener, a route, an init
   script, an exposed function. *)

type t = { mutable undo : (unit -> unit) option }

let make undo = { undo = Some undo }

(* Does nothing the second time.  What went away with its page or context need not be taken
   back, so that is no failure. *)
let dispose t =
    match t.undo with
    | None -> ()
    | Some undo -> (
        t.undo <- None;
        try undo () with Error.E { kind = Target_closed; _ } -> ())

(* A registration that the driver keeps. *)
let of_channel (channel : Protocol.Disposable.t) = make (fun () -> Protocol.Disposable.dispose channel)
