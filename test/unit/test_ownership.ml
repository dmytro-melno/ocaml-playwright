(* Who owns what when a fiber is cancelled: results that arrive late, clean-up, closing. *)

open Eio.Std
open Internal
open Test_wire

let method_ message = string_member "method" message
let guid message = string_member "guid" message
let reply peer ?(result = `Assoc []) request = peer.deliver (`Assoc [ "id", `String (string_member "id" request); "result", result ])
let nothing_sent what peer = Alcotest.(check (option json)) (what ^ ": nothing is sent") None (Eio.Stream.take_nonblocking peer.sent)
let nothing_reported peer = Alcotest.(check (list string)) "nothing reported" [] (List.map fst !(peer.reported))

let fail peer request name =
    peer.deliver (`Assoc [ "id", `String (string_member "id" request); "error", `Assoc [ "error", `Assoc [ "name", `String name; "message", `String "no" ] ] ])

let failed outcome = match Promise.await outcome with Error (Error.E { message = "no"; _ }) -> true | _ -> false

(* Runs [f] in a fiber and returns its first request along with the means to cancel it and a
   promise of how it ended. *)
let start peer f =
    let cancel = ref ignore in
    let outcome =
        Fiber.fork_promise ~sw:peer.sw (fun () ->
            match Eio.Cancel.sub (fun context -> cancel := (fun () -> Eio.Cancel.cancel context Exit); `Returned (f ())) with
            | outcome -> outcome
            | exception Eio.Cancel.Cancelled _ -> `Cancelled)
    in
    let request = Eio.Stream.take peer.sent in
    request, (fun () -> !cancel (); Fiber.yield ()), outcome

let frame peer =
    create peer ~type_:"Frame" ~guid:"frame@1" (`Assoc []);
    typed Protocol.Frame.kind peer "frame@1"

let element_reply request guid =
    `Assoc [ "id", `String (string_member "id" request); "result", `Assoc [ "element", `Assoc [ "guid", `String guid ] ] ]

(* The driver may have carried a command out before it hears that the caller is gone.  What the
   command made is then given back, because nobody else can. *)
let test_late_results () =
    with_peer @@ fun peer ->
    let frame = frame peer in
    let wait_for_selector () = Protocol.Frame.wait_for_selector ~selector:"button" frame in
    (* The reply arrives after the cancellation. *)
    let request, cancel, outcome = start peer wait_for_selector in
    cancel ();
    Alcotest.(check bool) "the caller is released at once" true (Promise.await_exn outcome = `Cancelled);
    let abort = Eio.Stream.take peer.sent in
    Alcotest.(check string) "the driver is asked to abort" "__abort__" (method_ abort);
    create peer ~parent:"frame@1" ~type_:"ElementHandle" ~guid:"handle@1" (`Assoc [ "preview", `String "button" ]);
    peer.deliver (element_reply request "handle@1");
    let dispose = Eio.Stream.take peer.sent in
    Alcotest.(check (pair string string)) "the handle is disposed of" ("handle@1", "dispose") (guid dispose, method_ dispose);
    reply peer dispose;
    Alcotest.(check int) "no call is left in flight" 0 (Hashtbl.length peer.conn.pending);
    (* The reply and the cancellation cross: the reply is read before the caller gets to run. *)
    let request, cancel, outcome = start peer wait_for_selector in
    create peer ~parent:"frame@1" ~type_:"ElementHandle" ~guid:"handle@2" (`Assoc [ "preview", `String "button" ]);
    peer.post (element_reply request "handle@2");
    cancel ();
    (match Promise.await_exn outcome with
    | `Cancelled ->
        let dispose = Eio.Stream.take peer.sent in
        Alcotest.(check (pair string string)) "crossed: the handle is disposed of" ("handle@2", "dispose") (guid dispose, method_ dispose);
        reply peer dispose
    | `Returned handle ->
        (* The reply won: the handle is the caller's. *)
        Alcotest.(check (option string)) "crossed: the caller has the handle" (Some "handle@2")
            (Option.map Channel.guid handle));
    nothing_sent "crossed" peer;
    (* An aborted command fails, and its failure is nobody's business. *)
    let request, cancel, _ = start peer wait_for_selector in
    cancel ();
    ignore (Eio.Stream.take peer.sent : Json.t);
    peer.deliver
        (`Assoc [ "id", `String (string_member "id" request);
                  "error", `Assoc [ "error", `Assoc [ "name", `String "Error"; "message", `String "aborted" ] ] ]);
    nothing_sent "aborted" peer;
    (* A result that holds nothing to give back is dropped, and the call is forgotten at once. *)
    let request, cancel, _ = start peer (fun () -> Protocol.Frame.title frame) in
    cancel ();
    ignore (Eio.Stream.take peer.sent : Json.t);
    Alcotest.(check int) "forgotten" 0 (Hashtbl.length peer.conn.pending);
    reply peer request ~result:(`Assoc [ "value", `String "late" ]);
    nothing_sent "plain result" peer;
    (* A late result that makes no sense is a protocol failure like any other. *)
    let request, cancel, _ = start peer wait_for_selector in
    cancel ();
    ignore (Eio.Stream.take peer.sent : Json.t);
    peer.deliver (element_reply request "nobody@1");
    Alcotest.(check bool) "closed" true (Connection.is_closed peer.conn);
    Alcotest.(check (list string)) "reported" [ "protocol message" ] (List.map fst !(peer.reported))

(* A result is released by its kind.  A command that makes more than handles is not aborted,
   because the driver could then leave behind what it was making. *)
let test_release_by_kind () =
    with_peer @@ fun peer ->
    create peer ~type_:"Browser" ~guid:"browser@1" (`Assoc []);
    create peer ~type_:"BrowserType" ~guid:"type@1" (`Assoc []);
    create peer ~type_:"APIRequestContext" ~guid:"request@1" (`Assoc []);
    let late what ~aborted call ~make ~result expected =
        let request, cancel, _ = start peer call in
        cancel ();
        if aborted then Alcotest.(check string) (what ^ ": aborted") "__abort__" (method_ (Eio.Stream.take peer.sent))
        else nothing_sent (what ^ ": left to finish") peer;
        List.iter (fun (type_, guid) -> create peer ~type_ ~guid (`Assoc [])) make;
        peer.deliver (`Assoc [ "id", `String (string_member "id" request); "result", result ]);
        let released =
            List.map
                (fun _ ->
                    let message = Eio.Stream.take peer.sent in
                    reply peer message;
                    guid message, method_ message, Option.value (member "params" message) ~default:`Null)
                expected
        in
        Alcotest.(check (list (triple string string json))) what expected released;
        nothing_sent what peer
    in
    let ref_ guid = `Assoc [ "guid", `String guid ] in
    late "a context is closed" ~aborted:false
        (fun () -> ignore (Protocol.Browser.new_context (typed Protocol.Browser.kind peer "browser@1") : Protocol.Browser_context.t))
        ~make:[ "BrowserContext", "context@1" ]
        ~result:(`Assoc [ "context", ref_ "context@1" ])
        [ "context@1", "close", `Assoc [] ];
    late "a browser takes its context along" ~aborted:false
        (fun () -> ignore (Protocol.Browser_type.launch_persistent_context ~user_data_dir:"" (typed Protocol.Browser_type.kind peer "type@1")))
        ~make:[ "Browser", "browser@2"; "BrowserContext", "context@2" ]
        ~result:(`Assoc [ "browser", ref_ "browser@2"; "context", ref_ "context@2" ])
        [ "browser@2", "close", `Assoc [] ];
    late "every handle of a list is disposed of" ~aborted:true
        (fun () -> ignore (Protocol.Frame.query_selector_all ~selector:"li" (frame peer) : Protocol.Element_handle.t list))
        ~make:[ "ElementHandle", "handle@1"; "ElementHandle", "handle@2" ]
        ~result:(`Assoc [ "elements", `List [ ref_ "handle@1"; ref_ "handle@2" ] ])
        [ "handle@1", "dispose", `Assoc []; "handle@2", "dispose", `Assoc [] ];
    late "a response is disposed of through its context" ~aborted:true
        (fun () -> ignore (Protocol.Api_request_context.fetch ~url:"http://localhost/" (typed Protocol.Api_request_context.kind peer "request@1")))
        ~make:[]
        ~result:
            (`Assoc
                [ "response",
                  `Assoc [ "fetchUid", `String "fetch-1"; "url", `String "http://localhost/"; "status", `Int 200; "statusText", `String "OK"; "headers", `List [] ] ])
        [ "request@1", "disposeAPIResponse", `Assoc [ "fetchUid", `String "fetch-1" ] ];
    nothing_reported peer

(* Clean-up that talks to the driver is carried out when the fiber that needs it is cancelled,
   which is when it matters, and the cancellation stays a cancellation. *)
let test_cleanup () =
    with_peer @@ fun peer ->
    let clock = peer.conn.clock in
    let root = Connection.root peer.conn in
    let call name = Connection.call root name (`Assoc []) ignore in
    let protected () = Connection.protect peer.conn "cleaning up" ~finally:(fun () -> call "release") (fun () -> call "work") in
    (* A time limit around the operation ends as one. *)
    let limited = Fiber.fork_promise ~sw:peer.sw (fun () -> Eio.Time.with_timeout clock 0.01 (fun () -> Ok (protected ()))) in
    Alcotest.(check string) "the operation" "work" (method_ (Eio.Stream.take peer.sent));
    Alcotest.(check string) "is aborted" "__abort__" (method_ (Eio.Stream.take peer.sent));
    let release = Eio.Stream.take peer.sent in
    Alcotest.(check string) "and cleaned up after" "release" (method_ release);
    Alcotest.(check bool) "the time limit is reported as such, without waiting for the clean-up" true (Promise.await_exn limited = Error `Timeout);
    reply peer release;
    (* Without cancellation, the clean-up is over when the operation returns. *)
    let request, _, outcome = start peer protected in
    reply peer request;
    let release = Eio.Stream.take peer.sent in
    Alcotest.(check bool) "still cleaning up" false (Promise.is_resolved outcome);
    reply peer release;
    Alcotest.(check bool) "returned" true (Promise.await_exn outcome = `Returned ());
    (* The failure of the operation is the one that is raised.  A failure of the clean-up is
       reported, unless it only says that there was nothing left to clean up. *)
    let failing_cleanup error_name =
        let outcome =
            Fiber.fork_promise ~sw:peer.sw (fun () ->
                Connection.protect peer.conn "cleaning up" ~finally:(fun () -> call "release") (fun () -> failwith "the operation failed"))
        in
        let release = Eio.Stream.take peer.sent in
        peer.deliver
            (`Assoc [ "id", `String (string_member "id" release); "error", `Assoc [ "error", `Assoc [ "name", `String error_name; "message", `String "no" ] ] ]);
        match Promise.await outcome with
        | Error (Failure message) -> Alcotest.(check string) "the failure of the operation" "the operation failed" message
        | _ -> Alcotest.fail "the failure of the operation should be raised"
    in
    failing_cleanup "TargetClosedError";
    nothing_reported peer;
    failing_cleanup "Error";
    Alcotest.(check (list string)) "a failed clean-up is reported" [ "cleaning up" ] (List.map fst !(peer.reported));
    peer.reported := [];
    (* Once the connection is over there is nothing to clean up, and nothing to wait for. *)
    peer.hang_up ();
    Connection.cleanup peer.conn "cleaning up" (fun () -> call "release");
    let error = failure "an operation after the end" protected in
    Alcotest.check error_kind "fails as usual" Error.Target_closed error.kind;
    nothing_reported peer

(* Closing and disposing are not undone by cancelling whoever asked for them. *)
let test_detached () =
    with_peer @@ fun peer ->
    let root = Connection.root peer.conn in
    let dispose () = Connection.detached peer.conn (fun () -> Connection.call root "dispose" (`Assoc []) ignore) in
    let request, cancel, outcome = start peer dispose in
    cancel ();
    Alcotest.(check bool) "the caller is released" true (Promise.await_exn outcome = `Cancelled);
    nothing_sent "no abort" peer;
    Alcotest.(check int) "the command stays in flight" 1 (Hashtbl.length peer.conn.pending);
    reply peer request;
    Alcotest.(check int) "until it is answered" 0 (Hashtbl.length peer.conn.pending);
    (* A caller that waits sees how it ended. *)
    let request, _, outcome = start peer dispose in
    peer.deliver
        (`Assoc [ "id", `String (string_member "id" request); "error", `Assoc [ "error", `Assoc [ "name", `String "Error"; "message", `String "cannot" ] ] ]);
    (match Promise.await outcome with
    | Error (Error.E error) -> Alcotest.(check string) "failure" "cannot" error.message
    | _ -> Alcotest.fail "the failure should reach the caller");
    (* The end of the instance ends the work, and the wait for it. *)
    let _, _, outcome = start peer dispose in
    peer.hang_up ();
    (match Promise.await outcome with
    | Error (Error.E error) -> Alcotest.check error_kind "ended" Error.Target_closed error.kind
    | _ -> Alcotest.fail "the end of the connection should reach the caller");
    let error = failure "after the end" dispose in
    Alcotest.check error_kind "nothing starts after the end" Error.Target_closed error.kind;
    nothing_reported peer

let test_closing_state () =
    with_peer @@ fun peer ->
    let root = Connection.root peer.conn in
    let closer () =
        let state = Closing.create () in
        let runs = ref 0 in
        let close () =
            Closing.close peer.conn state (fun () ->
                incr runs;
                Connection.call root "close" (`Assoc []) ignore)
        in
        state, runs, close
    in
    let fail = fail peer in
    (* A cancelled caller stops waiting, and the others wait for the one close to be over. *)
    let state, runs, close = closer () in
    let request, cancel, first = start peer close in
    let second = Fiber.fork_promise ~sw:peer.sw close in
    cancel ();
    Alcotest.(check bool) "the cancelled caller is released" true (Promise.await_exn first = `Cancelled);
    nothing_sent "one close, not aborted" peer;
    Alcotest.(check (pair bool bool)) "closing: neither open nor closed" (false, false) (Closing.is_open state, Closing.is_closed state);
    Alcotest.(check bool) "the other caller waits" false (Promise.is_resolved second);
    reply peer request;
    Promise.await_exn second;
    Alcotest.(check bool) "closed" true (Closing.is_closed state);
    close ();
    Alcotest.(check int) "closed once" 1 !runs;
    nothing_sent "closing again" peer;
    (* A close that failed is seen by everyone who waited for it, and can be tried again. *)
    let state, runs, close = closer () in
    let request, _, first = start peer close in
    let second = Fiber.fork_promise ~sw:peer.sw close in
    fail request "Error";
    Alcotest.(check (pair bool bool)) "both callers see the failure" (true, true) (failed first, failed second);
    Alcotest.(check bool) "open again" true (Closing.is_open state);
    let request, _, retry = start peer close in
    reply peer request;
    Alcotest.(check bool) "the retry closes" true (Promise.await_exn retry = `Returned () && Closing.is_closed state);
    Alcotest.(check int) "tried twice" 2 !runs;
    (* An object that is gone needs no closing, and learns that it is gone by its own means. *)
    let state, _, close = closer () in
    let request, _, outcome = start peer close in
    fail request "TargetClosedError";
    Alcotest.(check bool) "gone counts as closed for the caller" true (Promise.await_exn outcome = `Returned ());
    Alcotest.(check bool) "which is news to the object" true (Closing.set_closed state);
    Alcotest.(check bool) "once" false (Closing.set_closed state);
    close ();
    nothing_sent "closing what is gone" peer;
    (* The end of the connection is the end of the wait. *)
    let _, _, close = closer () in
    let _, _, outcome = start peer close in
    peer.hang_up ();
    Alcotest.(check bool) "released by the end" true (Promise.await_exn outcome = `Returned ());
    close ();
    nothing_reported peer

(* Taking back what the driver keeps is a close like any other.  Taking a listener back is
   done on the spot. *)
let test_disposables () =
    with_peer @@ fun peer ->
    let root = Connection.root peer.conn in
    let runs = ref 0 in
    let registration =
        Disposable.registration peer.conn (fun () ->
            incr runs;
            Connection.call root "dispose" (`Assoc []) ignore)
    in
    let dispose () = Disposable.dispose registration in
    let request, cancel, first = start peer dispose in
    let second = Fiber.fork_promise ~sw:peer.sw dispose in
    cancel ();
    Alcotest.(check bool) "the cancelled caller is released" true (Promise.await_exn first = `Cancelled);
    nothing_sent "one attempt, not aborted" peer;
    Alcotest.(check bool) "the other caller waits for it" false (Promise.is_resolved second);
    fail peer request "Error";
    Alcotest.(check bool) "and sees it fail" true (failed second);
    let request, _, retry = start peer dispose in
    reply peer request;
    Alcotest.(check bool) "what failed can be tried again" true (Promise.await_exn retry = `Returned ());
    dispose ();
    Alcotest.(check int) "tried twice, and no more once it is done" 2 !runs;
    nothing_sent "disposed of" peer;
    (* What went away with its page needs no taking back. *)
    let gone = Disposable.registration peer.conn (fun () -> Connection.call root "dispose" (`Assoc []) ignore) in
    let request, _, outcome = start peer (fun () -> Disposable.dispose gone) in
    fail peer request "TargetClosedError";
    Alcotest.(check bool) "gone is no failure" true (Promise.await_exn outcome = `Returned ());
    let removed = ref 0 in
    let listener = Disposable.listener (fun () -> incr removed) in
    Disposable.dispose listener;
    Disposable.dispose listener;
    Alcotest.(check int) "a listener is removed once" 1 !removed;
    nothing_reported peer

let tests =
    [ "ownership",
      [ Alcotest.test_case "late results" `Quick test_late_results;
        Alcotest.test_case "release by kind" `Quick test_release_by_kind;
        Alcotest.test_case "clean-up" `Quick test_cleanup;
        Alcotest.test_case "detached work" `Quick test_detached;
        Alcotest.test_case "closing" `Quick test_closing_state;
        Alcotest.test_case "registrations" `Quick test_disposables ] ]
