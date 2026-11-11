(* Events: listeners, what their calls may cost, and waiting for an event. *)

open Eio.Std
open Internal

let with_peer = Test_wire.with_peer
let emit (peer : Test_wire.peer) emitter value = ignore (Emitter.emit peer.conn emitter value : bool)

(* What was noted since the last time this was asked. *)
let notes () =
    let log = ref [] in
    let note tag value = log := Printf.sprintf "%s:%d" tag value :: !log in
    let noted () =
        let all = List.rev !log in
        log := [];
        all
    in
    note, noted

let nothing_reported (peer : Test_wire.peer) =
    Alcotest.(check (list string)) "nothing reported" [] (List.map (fun (what, ex) -> what ^ ": " ^ Printexc.to_string ex) !(peer.reported))

(* {1 Listeners} *)

let test_listeners () =
    with_peer @@ fun peer ->
    let emitter = Emitter.create () in
    let note, noted = notes () in
    Alcotest.(check bool) "no listener, not delivered" false (Emitter.emit peer.conn emitter 0);
    let a = note "a" in
    let remove_a = Emitter.on emitter a in
    let (_ : unit -> unit) = Emitter.once emitter (note "once") in
    let remove_b = Emitter.on emitter (note "b") in
    Alcotest.(check bool) "delivered" true (Emitter.emit peer.conn emitter 1);
    emit peer emitter 2;
    Alcotest.(check (list string)) "registration order, once only once" [ "a:1"; "once:1"; "b:1"; "a:2"; "b:2" ] (noted ());
    remove_a ();
    remove_a ();
    emit peer emitter 3;
    Alcotest.(check (list string)) "what registering returns removes exactly that listener" [ "b:3" ] (noted ());
    let (_ : unit -> unit) = Emitter.on emitter a in
    let (_ : unit -> unit) = Emitter.on emitter a in
    Emitter.off emitter a;
    Emitter.off emitter (note "never registered");
    emit peer emitter 4;
    Alcotest.(check (list string)) "off removes one registration of the function" [ "b:4"; "a:4" ] (noted ());
    let remove_once = Emitter.once emitter (note "once") in
    remove_once ();
    Emitter.off emitter a;
    remove_b ();
    emit peer emitter 5;
    Alcotest.(check (list string)) "all removed" [] (noted ());
    Alcotest.(check bool) "empty again" false (Emitter.has_listeners emitter)

let test_listeners_block_and_fail () =
    with_peer @@ fun peer ->
    let emitter = Emitter.create () in
    let gate, open_gate = Promise.create () in
    let log = ref [] in
    let (_ : unit -> unit) =
        Emitter.on emitter (fun value ->
            if value = 1 then Promise.await gate;
            log := value :: !log)
    in
    emit peer emitter 1;
    emit peer emitter 2;
    Alcotest.(check (list int)) "a blocked listener does not hold up later events" [ 2 ] !log;
    Promise.resolve open_gate ();
    Fiber.yield ();
    Alcotest.(check (list int)) "and finishes later" [ 1; 2 ] !log;
    (* An exception in a listener goes to the error hook instead of the reader. *)
    let (_ : unit -> unit) = Emitter.on emitter (fun _ -> failwith "listener failed") in
    emit peer emitter 3;
    Alcotest.(check bool) "reported" true (List.exists (fun (_, ex) -> ex = Failure "listener failed") !(peer.reported));
    Alcotest.(check (list int)) "the others are called all the same" [ 3; 1; 2 ] !log

let test_changes_during_emission () =
    with_peer @@ fun peer ->
    let emitter = Emitter.create () in
    let note, noted = notes () in
    let remove_last = ref ignore and remove_self = ref ignore in
    let (_ : unit -> unit) =
        Emitter.on emitter (fun value ->
            note "first" value;
            !remove_last ();
            ignore (Emitter.on emitter (note "added") : unit -> unit))
    in
    remove_self :=
        Emitter.on emitter (fun value ->
            note "self" value;
            !remove_self ());
    remove_last := Emitter.on emitter (note "last");
    emit peer emitter 1;
    Alcotest.(check (list string)) "a listener removed before its turn is not called, one added is not called for that event"
        [ "first:1"; "self:1" ] (noted ());
    emit peer emitter 2;
    Alcotest.(check (list string)) "the changes hold for the next event" [ "first:2"; "added:2" ] (noted ());
    (* An event that a listener causes while another one is being delivered. *)
    let emitter = Emitter.create () in
    let (_ : unit -> unit) =
        Emitter.on emitter (fun value ->
            note "outer" value;
            if value = 1 then emit peer emitter 2)
    in
    let (_ : unit -> unit) = Emitter.once emitter (note "once") in
    emit peer emitter 1;
    Alcotest.(check (list string)) "once is once also then" [ "outer:1"; "outer:2"; "once:2" ] (noted ());
    nothing_reported peer

let test_watch () =
    with_peer @@ fun _ ->
    let emitter = Emitter.create () in
    let transitions = ref [] in
    Emitter.set_watch emitter (fun active -> transitions := active :: !transitions);
    let remove = Emitter.on emitter (fun (_ : int) -> ()) in
    let unsubscribe = Emitter.subscribe emitter ignore in
    remove ();
    Alcotest.(check (list bool)) "told about the first listener only" [ true ] (List.rev !transitions);
    unsubscribe ();
    Alcotest.(check (list bool)) "and about the last one leaving" [ true; false ] (List.rev !transitions)

(* Nothing here takes time that grows with the square of the number of listeners: that would
   be minutes. *)
let test_many_listeners () =
    with_peer @@ fun peer ->
    let emitter = Emitter.create () in
    let count = 50_000 in
    let calls = ref 0 in
    let started = Unix.gettimeofday () in
    let removers = List.init count (fun _ -> Emitter.on emitter (fun () -> incr calls)) in
    for _ = 1 to 10 do
        emit peer emitter ()
    done;
    Alcotest.(check int) "every listener, every time" (10 * count) !calls;
    List.iteri (fun i remove -> if i mod 2 = 0 then remove ()) removers;
    calls := 0;
    emit peer emitter ();
    Alcotest.(check int) "those that are left" (count / 2) !calls;
    (* What a waiter does, on an emitter that has many listeners. *)
    for _ = 1 to count do
        (Emitter.subscribe emitter ignore) ()
    done;
    List.iter (fun remove -> remove ()) removers;
    Alcotest.(check bool) "all gone" false (Emitter.has_listeners emitter);
    let elapsed = Unix.gettimeofday () -. started in
    if elapsed > 10. then Alcotest.failf "took %.1f s" elapsed

(* {1 Handler calls} *)

(* A listener that notes each call and waits for the test to let it return. *)
let gated count =
    let gates = Array.init count (fun _ -> Promise.create ()) in
    let started = ref [] and finished = ref [] in
    let listener i =
        started := i :: !started;
        Promise.await (fst gates.(i));
        finished := i :: !finished
    in
    let release i =
        Promise.resolve (snd gates.(i)) ();
        Fiber.yield ()
    in
    listener, release, (fun () -> List.rev !started), fun () -> List.rev !finished

let test_concurrency_limit () =
    with_peer ~handler_concurrency:2 @@ fun peer ->
    let emitter = Emitter.create () in
    let listener, release, started, finished = gated 6 in
    let (_ : unit -> unit) = Emitter.on emitter listener in
    for i = 0 to 5 do
        emit peer emitter i
    done;
    Alcotest.(check (list int)) "two at a time" [ 0; 1 ] (started ());
    release 1;
    Alcotest.(check (list int)) "the next in line starts when one returns" [ 0; 1; 2 ] (started ());
    release 2;
    release 0;
    Alcotest.(check (list int)) "in the order of the events" [ 0; 1; 2; 3; 4 ] (started ());
    List.iter release [ 3; 4 ];
    Alcotest.(check (list int)) "the last one" [ 0; 1; 2; 3; 4; 5 ] (started ());
    release 5;
    Alcotest.(check (list int)) "all were called" [ 1; 2; 0; 3; 4; 5 ] (finished ());
    Alcotest.(check bool) "the connection is unaffected" false (Connection.is_closed peer.conn);
    nothing_reported peer

(* A handler that does not block never makes another one wait, however many events there are. *)
let test_quick_handlers () =
    with_peer ~handler_concurrency:1 ~handler_backlog:0 @@ fun peer ->
    let emitter = Emitter.create () in
    let calls = ref 0 in
    let (_ : unit -> unit) = Emitter.on emitter (fun () -> incr calls) in
    for _ = 1 to 10_000 do
        emit peer emitter ()
    done;
    Alcotest.(check int) "all called" 10_000 !calls;
    nothing_reported peer

let test_backlog () =
    with_peer ~handler_concurrency:1 @@ fun peer ->
    let emitter = Emitter.create () in
    let gate, open_gate = Promise.create () in
    let seen = ref [] in
    let (_ : unit -> unit) =
        Emitter.on emitter (fun i ->
            if i = 0 then Promise.await gate;
            seen := i :: !seen)
    in
    let count = 50_000 in
    for i = 0 to count do
        emit peer emitter i
    done;
    Alcotest.(check (list int)) "they wait for the one that is in progress" [] !seen;
    Promise.resolve open_gate ();
    Fiber.yield ();
    Alcotest.(check bool) "then all are called, in order" true (List.rev !seen = List.init (count + 1) Fun.id);
    nothing_reported peer

let test_removed_while_waiting () =
    with_peer ~handler_concurrency:1 @@ fun peer ->
    let busy = Emitter.create () and emitter = Emitter.create () in
    let gate, open_gate = Promise.create () in
    let (_ : unit -> unit) = Emitter.on busy (fun () -> Promise.await gate) in
    emit peer busy ();
    let note, noted = notes () in
    let remove = Emitter.on emitter (note "removed") in
    let (_ : unit -> unit) = Emitter.on emitter (note "kept") in
    let (_ : unit -> unit) = Emitter.once emitter (note "once") in
    let remove_once = Emitter.once emitter (note "once removed") in
    emit peer emitter 1;
    remove ();
    remove_once ();
    Promise.resolve open_gate ();
    Fiber.yield ();
    Alcotest.(check (list string)) "a listener is not called once it has been removed" [ "kept:1"; "once:1" ] (noted ());
    nothing_reported peer

let test_backlog_limit () =
    with_peer ~handler_concurrency:1 ~handler_backlog:2 @@ fun peer ->
    Test_wire.create peer ~type_:"Thing" ~guid:"thing" (`Assoc []);
    let reply, _ = Test_wire.start_call peer (Test_wire.channel peer "thing") "wait" in
    let emitter = Emitter.create () in
    let (_ : unit -> unit) = Emitter.on emitter (fun () -> Fiber.await_cancel ()) in
    for _ = 1 to 3 do
        emit peer emitter ()
    done;
    Alcotest.(check bool) "one in progress and two waiting is within the limits" false (Connection.is_closed peer.conn);
    nothing_reported peer;
    emit peer emitter ();
    Alcotest.(check bool) "one more is not" true (Connection.is_closed peer.conn);
    (match !(peer.reported) with
    | [ ("event handlers", Error.E error) ] -> check_contains "what is reported" ~sub:"event handlers do not keep up" error.message
    | _ -> Alcotest.fail "the overflow should have been reported, once");
    let error = Test_wire.closed_error "a call in flight" reply in
    check_contains "what callers are told" ~sub:"event handlers do not keep up: 1 calls are in progress and 2 more are waiting" error.message

(* {1 Waiting} *)

(* A connection whose time is what the test says: [at seconds] makes it that late. *)
let with_time f =
    let clock = Eio_mock.Clock.make () in
    with_peer ~clock:(clock :> float Eio.Time.clock_ty r) ~handler_backlog:3 @@ fun peer ->
    f peer (fun seconds ->
        Eio_mock.Clock.set_time clock seconds;
        Fiber.yield ())

type 'a waiting = { emitter : 'a Emitter.t; closed : string Emitter.t; expect : ?timeout:float -> (unit -> unit) -> ('a -> bool) -> 'a }

(* Waiting for an event of [emitter] around an action, the way the library does it. *)
let waiting (peer : Test_wire.peer) =
    let emitter = Emitter.create () and closed = Emitter.create () in
    let expect ?(timeout = 100.) action predicate =
        Waiter.using peer.conn ~timeout ~timeout_message:(fun () -> "Timeout while waiting for the event") (fun waiter ->
            Waiter.listen waiter emitter Option.some;
            Waiter.reject_on waiter closed (fun reason -> Some (Error.target_closed ~message:reason ()));
            snd (Waiter.around waiter action (fun value -> if predicate value then Some value else None)))
    in
    { emitter; closed; expect }

let all_removed what w = Alcotest.(check bool) what false (Emitter.has_listeners w.emitter || Emitter.has_listeners w.closed)
let even value = value mod 2 = 0

let test_expect () =
    with_time @@ fun peer _at ->
    let w = waiting peer in
    let emit_all values () = List.iter (emit peer w.emitter) values in
    Alcotest.(check int) "an event emitted during the action is not missed" 1 (w.expect (emit_all [ 1 ]) (fun _ -> true));
    Alcotest.(check int) "the predicate selects" 4 (w.expect (emit_all [ 1; 3; 4; 6 ]) even);
    all_removed "listeners are removed afterwards" w;
    (* The predicate sees things as the event left them, not as whatever comes next does. *)
    let state = ref "before" in
    let action () =
        state := "at the event";
        emit peer w.emitter 1;
        state := "after"
    in
    Alcotest.(check int) "examined when it arrives" 1 (w.expect action (fun _ -> !state = "at the event"));
    (* The first one that matches is enough: nothing is examined, or kept, after it. *)
    let examined = ref 0 in
    let action () =
        emit_all [ 2; 4 ] ();
        Fiber.yield ();
        emit_all [ 6; 8 ] ()
    in
    let count _ =
        incr examined;
        true
    in
    Alcotest.(check int) "the first match" 2 (w.expect action count);
    Alcotest.(check int) "the only one examined" 1 !examined;
    (* Without a time limit. *)
    Alcotest.(check int) "no time limit" 2 (w.expect ~timeout:0. (emit_all [ 2 ]) even);
    nothing_reported peer

let test_time_limit () =
    with_time @@ fun peer at ->
    let w = waiting peer in
    let finished = ref false in
    let timeout what f =
        finished := false;
        let error = failure what f in
        Alcotest.check error_kind (what ^ ": kind") Error.Timeout error.kind;
        Alcotest.(check string) (what ^ ": message") "Timeout while waiting for the event" error.message;
        Alcotest.(check bool) (what ^ ": the action was not interrupted") true !finished;
        all_removed (what ^ ": cleaned up") w
    in
    (* The time limit is 0.1 s from the start. *)
    let now = ref 0. in
    let later seconds =
        now := !now +. seconds;
        at !now
    in
    timeout "nothing happens" (fun () ->
        w.expect
            (fun () ->
                later 0.2;
                finished := true)
            even);
    timeout "nothing that matches" (fun () ->
        w.expect
            (fun () ->
                emit peer w.emitter 1;
                later 0.2;
                finished := true)
            even);
    timeout "too late, though the action is still under way" (fun () ->
        w.expect
            (fun () ->
                later 0.2;
                emit peer w.emitter 2;
                later 0.2;
                finished := true)
            even);
    (* What arrived in time counts, however long the action goes on, and wherever it is among
       the others. *)
    let in_time =
        w.expect
            (fun () ->
                emit peer w.emitter 1;
                later 0.05;
                emit peer w.emitter 2;
                later 0.2;
                emit peer w.emitter 4;
                later 1.)
            even
    in
    Alcotest.(check int) "in time" 2 in_time;
    (* Also when nothing got to examine it before the time was up. *)
    let unexamined =
        Waiter.using peer.conn ~timeout:100. ~timeout_message:(fun () -> "Timeout") (fun waiter ->
            Waiter.listen waiter w.emitter Option.some;
            List.iter (emit peer w.emitter) [ 1; 3; 6 ];
            later 0.2;
            emit peer w.emitter 8;
            Waiter.next waiter (fun value -> if even value then Some value else None))
    in
    Alcotest.(check int) "in time, examined late" 6 unexamined;
    (* And when the predicate takes its time. *)
    let slow =
        w.expect
            (fun () ->
                emit peer w.emitter 2;
                later 0.2)
            (fun _ ->
                Fiber.yield ();
                Fiber.yield ();
                true)
    in
    Alcotest.(check int) "in time, examined slowly" 2 slow;
    nothing_reported peer

let test_failures () =
    with_time @@ fun peer _at ->
    let w = waiting peer in
    let finished = ref false in
    let gone =
        failure "rejection" (fun () ->
            w.expect
                (fun () ->
                    emit peer w.closed "Page closed";
                    Fiber.yield ();
                    finished := true)
                even)
    in
    Alcotest.check error_kind "rejection kind" Error.Target_closed gone.kind;
    Alcotest.(check string) "rejection message" "Page closed" gone.message;
    Alcotest.(check bool) "the action was not interrupted" true !finished;
    all_removed "cleaned up after a rejection" w;
    let before =
        w.expect
            (fun () ->
                emit peer w.emitter 2;
                emit peer w.closed "Page closed")
            even
    in
    Alcotest.(check int) "what arrived before the end counts" 2 before;
    (* The action fails: nobody waits for an event that it was to cause. *)
    (match w.expect (fun () -> raise Exit) even with
    | _ -> Alcotest.fail "the failure of the action should have been raised"
    | exception Exit -> ());
    all_removed "cleaned up after a failed action" w;
    (* The predicate fails. *)
    (match
         w.expect
             (fun () ->
                 emit peer w.emitter 1;
                 Fiber.yield ();
                 finished := true)
             (fun _ -> failwith "predicate")
     with
    | _ -> Alcotest.fail "the failure of the predicate should have been raised"
    | exception Failure message -> Alcotest.(check string) "the predicate's own failure" "predicate" message);
    all_removed "cleaned up after a failed predicate" w;
    (* The predicate does not keep up: only this wait suffers.  The limit is 3 events. *)
    let gate, open_gate = Promise.create () in
    let behind =
        failure "predicate that does not keep up" (fun () ->
            w.expect
                (fun () ->
                    List.iter (emit peer w.emitter) [ 1; 3; 5; 7; 9; 11 ];
                    Promise.resolve open_gate ())
                (fun value ->
                    Promise.await gate;
                    even value))
    in
    check_contains "explained" ~sub:"More than 3 events are waiting to be examined" behind.message;
    Alcotest.(check bool) "the connection is unaffected" false (Connection.is_closed peer.conn);
    nothing_reported peer;
    (* The connection ends. *)
    let lost = failure "connection lost" (fun () -> w.expect peer.hang_up even) in
    Alcotest.check error_kind "connection lost: kind" Error.Target_closed lost.kind;
    all_removed "cleaned up after the connection ended" w

let tests =
    [ "listeners",
      [ Alcotest.test_case "registration and removal" `Quick test_listeners;
        Alcotest.test_case "blocking and failing" `Quick test_listeners_block_and_fail;
        Alcotest.test_case "changes during an emission" `Quick test_changes_during_emission;
        Alcotest.test_case "watch" `Quick test_watch;
        Alcotest.test_case "many listeners" `Quick test_many_listeners ];
      "handler calls",
      [ Alcotest.test_case "so many at a time" `Quick test_concurrency_limit;
        Alcotest.test_case "handlers that do not block" `Quick test_quick_handlers;
        Alcotest.test_case "waiting for a turn" `Quick test_backlog;
        Alcotest.test_case "removed while waiting" `Quick test_removed_while_waiting;
        Alcotest.test_case "too many waiting" `Quick test_backlog_limit ];
      "waiting for an event",
      [ Alcotest.test_case "around an action" `Quick test_expect;
        Alcotest.test_case "the time limit" `Quick test_time_limit;
        Alcotest.test_case "failures" `Quick test_failures ] ]
