(* Waiting for an event of a client object, optionally around the action that causes it. *)

let timeout_message name timeout () =
    Printf.sprintf "Timeout %sms exceeded while waiting for event \"%s\"" (Waiter.format_timeout timeout) name

(* Runs [action] and returns the first event of [emitter] accepted by [predicate] that was
   emitted since just before the action started.  [rejections] registers what should make the
   wait fail early. *)
let expect conn ~timeout ~name ?(predicate = fun _ -> true) ~rejections emitter action =
    Waiter.using conn ~timeout ~timeout_message:(timeout_message name timeout) (fun waiter ->
        rejections waiter;
        Waiter.listen waiter emitter Option.some;
        action ();
        Waiter.next waiter (fun event -> if predicate event then Some event else None))

(* Asks the driver to report an event only while somebody listens for it. *)
let subscribe_on_demand conn emitter update =
    Emitter.set_watch emitter (fun enabled -> Connection.fork conn "event subscription" (fun () -> try update ~enabled with Error.E _ -> ()))
