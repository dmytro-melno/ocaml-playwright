(* What a registration returns, to take it back with: an event listener, a route, an init
   script, an exposed function.

   A listener is an entry in a table of the client: taking it back is done on the spot and
   cannot fail.  What the driver was told about is taken back by telling the driver, which is
   closing something: it is carried out in the scope of the instance, the fibers that ask for
   it meanwhile wait for the one attempt, and an attempt that failed can be repeated (see
   {!Closing}). *)

type t =
    | Listener of { mutable remove : (unit -> unit) option }
    | Registration of { conn : Connection.t; state : Closing.t; undo : unit -> unit }

let listener remove = Listener { remove = Some remove }

(* [undo] may be called again after it failed. *)
let registration conn undo = Registration { conn; state = Closing.create (); undo }

(* Does nothing the second time.  What went away with its page or context need not be taken
   back, so that is no failure. *)
let dispose = function
    | Listener l ->
        Option.iter
            (fun remove ->
                l.remove <- None;
                remove ())
            l.remove
    | Registration r -> Closing.close r.conn r.state r.undo

(* A registration that the driver keeps. *)
let of_channel (channel : Protocol.Disposable.t) = registration (Channel.conn channel) (fun () -> Protocol.Disposable.dispose channel)
