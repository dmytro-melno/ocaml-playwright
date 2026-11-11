(* Typed event sources.

   Events are emitted by the connection's reader, as part of bringing the client's state up to
   date.  Public listeners are user code and may block, so each call of one is a handler call of
   its own (see {!Connection.handle}); calls start in emission order.  Internal listeners added
   with {!subscribe} run inline and must not block.

   Registering a listener, removing one and emitting to one each take constant time, the last
   two on average. *)

type 'a listener = {
    fn : 'a -> unit;
    once : bool;
    inline : bool;
    mutable listening : bool;  (* registered: not removed, nor called if [once] *)
    mutable cancelled : bool;  (* removed by whoever registered it: calls that have not started are not made *)
}

type 'a t = {
    mutable listeners : 'a listener list;  (* in registration order, those of [recent] excepted *)
    mutable recent : 'a listener list;  (* registered since the last emission, newest first *)
    mutable count : int;  (* those that are listening *)
    mutable stale : int;  (* those in the lists that no longer are *)
    mutable watch : bool -> unit;  (* told when the first listener arrives and the last one leaves *)
}

let create () = { listeners = []; recent = []; count = 0; stale = 0; watch = ignore }

(* Has [watch] called with [true] when the emitter gains its first listener and with [false]
   when it loses its last one.  Used to subscribe to driver events lazily. *)
let set_watch t watch = t.watch <- watch

let has_listeners t = t.count > 0

let add t listener =
    t.recent <- listener :: t.recent;
    t.count <- t.count + 1;
    if t.count = 1 then t.watch true

(* An emission that is under way holds the list that it started with, and passes over what is
   no longer [listening].  So can the lists: they are swept when those that left outnumber those
   that stay, which keeps leaving cheap and what is held in proportion to what is in use. *)
let unregister t listener =
    if listener.listening then begin
        listener.listening <- false;
        t.count <- t.count - 1;
        t.stale <- t.stale + 1;
        if t.stale > t.count then begin
            t.listeners <- List.filter (fun l -> l.listening) t.listeners;
            t.recent <- List.filter (fun l -> l.listening) t.recent;
            t.stale <- 0
        end;
        if t.count = 0 then t.watch false
    end

let remove t listener =
    listener.cancelled <- true;
    unregister t listener

let register t ~once ~inline fn =
    let listener = { fn; once; inline; listening = true; cancelled = false } in
    add t listener;
    fun () -> remove t listener

(* These return the function that removes the listener; it may be called more than once. *)
let on t fn = register t ~once:false ~inline:false fn
let once t fn = register t ~once:true ~inline:false fn

(* Adds an internal listener. *)
let subscribe t fn = register t ~once:false ~inline:true fn

(* Returns whether there was a listener to deliver the event to.  Listeners added during the
   emission are not called for it. *)
let emit (conn : Connection.t) t value =
    if t.recent <> [] then begin
        t.listeners <- t.listeners @ List.rev t.recent;
        t.recent <- []
    end;
    List.fold_left
        (fun handled listener ->
            (* Removed by an earlier listener, or taken by an emission that one of them caused. *)
            if not listener.listening then handled
            else begin
                if listener.once then unregister t listener;
                if listener.inline then
                    try listener.fn value
                    with ex when not (Fibers.is_cancellation ex) -> conn.report "internal event listener" ex (Printexc.get_raw_backtrace ())
                else Connection.handle conn "event listener" (fun () -> if not listener.cancelled then listener.fn value);
                true
            end)
        false t.listeners
