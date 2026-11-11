(* Typed event sources.

   Events are emitted from the connection's reader fiber.  Public listeners may block (they
   typically call back into the driver), so each one runs in its own fiber; fibers start in
   emission order.  Internal listeners added with {!subscribe} run inline and must not block. *)

type 'a listener = {
    fn : 'a -> unit;
    once : bool;
    inline : bool;
}

type 'a t = {
    mutable listeners : 'a listener list;  (* in registration order *)
    mutable watch : bool -> unit;  (* told when the first listener arrives and the last one leaves *)
}

let create () = { listeners = []; watch = ignore }

(* Has [watch] called with [true] when the emitter gains its first listener and with [false]
   when it loses its last one.  Used to subscribe to driver events lazily. *)
let set_watch t watch = t.watch <- watch

let has_listeners t = t.listeners <> []

let add t listener =
    let first = t.listeners = [] in
    t.listeners <- t.listeners @ [ listener ];
    if first then t.watch true

let remove t listener =
    if List.memq listener t.listeners then begin
        t.listeners <- List.filter (fun l -> l != listener) t.listeners;
        if t.listeners = [] then t.watch false
    end

let on t fn = add t { fn; once = false; inline = false }
let once t fn = add t { fn; once = true; inline = false }

(* Removes the most recently added public listener that is physically equal to [fn]. *)
let off t fn =
    match List.find_opt (fun l -> l.fn == fn && not l.inline) (List.rev t.listeners) with
    | Some listener -> remove t listener
    | None -> ()

(* Adds an internal listener and returns the function that removes it. *)
let subscribe t fn =
    let listener = { fn; once = false; inline = true } in
    add t listener;
    fun () -> remove t listener

(* Returns whether there was a listener to deliver the event to. *)
let emit conn t value =
    List.fold_left
        (fun handled listener ->
            (* A listener removed by an earlier one in this round must not run. *)
            if not (List.memq listener t.listeners) then handled
            else begin
                if listener.once then remove t listener;
                if listener.inline then
                    try listener.fn value with ex -> conn.Connection.report "internal event listener" ex (Printexc.get_raw_backtrace ())
                else Connection.fork conn "event listener" (fun () -> listener.fn value);
                true
            end)
        false t.listeners
