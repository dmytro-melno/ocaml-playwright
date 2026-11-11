(* How far the closing of an object has got.

   Closing an object can take several steps that wait for the driver.  They are carried out in
   the scope of the instance, not by the fiber that asked for them (see {!Connection.start}), so:
   - a caller that is cancelled stops waiting, and the object is closed all the same;
   - callers that ask while the object is being closed wait for that to be over, and all see how
     it ended;
   - a close that failed leaves the object open, to be closed again. *)

open Eio.Std

type state = Open | Closing of unit Connection.outcome Promise.t | Closed
type t = { mutable state : state }

let create () = { state = Open }
let is_open t = match t.state with Open -> true | Closing _ | Closed -> false
let is_closed t = match t.state with Closed -> true | Open | Closing _ -> false

(* The object is gone, whoever closed it.  Tells whether that is news. *)
let set_closed t =
    match t.state with
    | Closed -> false
    | Open | Closing _ ->
        t.state <- Closed;
        true

(* Closes the object with [work], unless it is closed, and waits until it is.  An object whose
   connection, browser or context went away first counts as closed. *)
let close conn t work =
    let wait outcome = try Connection.join outcome with Error.E { kind = Target_closed; _ } -> () in
    match t.state with
    | Closed -> ()
    | Closing outcome -> wait outcome
    | Open ->
        let outcome, resolver = Promise.create () in
        t.state <- Closing outcome;
        Connection.run_detached conn work (fun result ->
            (* Whether an object that could not be closed is gone is for the object to find out:
               see [set_closed]. *)
            (match result, t.state with
            | Ok (), _ -> t.state <- Closed
            | Error _, Closing _ -> t.state <- Open
            | Error _, (Open | Closed) -> ());
            Promise.resolve resolver result);
        wait outcome
