open Playwright
open Eio.Std

let check name condition =
  if not condition then failwith ("ASSERTION FAILED: " ^ name)

let test name f =
  f ();
  Printf.printf "PASS %s\n%!" name

let conn = Internal.connection
let clock env = Eio.Stdenv.clock env
let bounded env f = Eio.Time.with_timeout_exn (clock env) 3. f
let until env f = bounded env (fun () -> while not (f ()) do Fiber.yield () done)
let fails f =
  match f () with
  | _ -> failwith "expected failure"
  | exception ex -> ex
let is_timeout = function Eio.Time.Timeout -> true | _ -> false
let is_cancelled = function Eio.Cancel.Cancelled _ -> true | _ -> false
let is_error (result : ('a, 'b) result) = match result with Error _ -> true | Ok _ -> false
let rpc c = Connection.send_message c ~guid:"x" ~method_:"test" ~params:(`Assoc [])
let response id = `Assoc ["id", `Int id; "result", `String "reply"]
let count c = Hashtbl.length c.Connection.callbacks
let assert_clean c =
  check "closed" (Connection.closed_reason c <> None);
  check "no requests" (count c = 0);
  check "no event tasks" (c.Connection.event_tasks = 0);
  check "empty event queue" (Queue.is_empty c.event_queue);
  check "no runtime" (not c.running);
  check "no cleanup closure" (c.await_cleanup = None);
  check "no channel objects" (Hashtbl.length c.objects = 0)

let children () =
  let path = Printf.sprintf "/proc/self/task/%d/children" (Unix.getpid ()) in
  In_channel.with_open_text path In_channel.input_all
  |> String.trim |> String.split_on_char ' '
  |> List.filter_map (function "" -> None | n -> Some (int_of_string n))
let child_baseline = ref []
let fd_count () = Array.length (Sys.readdir "/proc/self/fd")
let no_children () = check "no owned child processes" (children () = !child_baseline)

module Yield_sink = struct
  type t = Buffer.t
  let single_write buffer = function
    | [] -> 0
    | first :: _ ->
      Buffer.add_string buffer (Cstruct.to_string first);
      Fiber.yield ();
      Cstruct.length first
  let copy buffer ~src = Eio.Flow.Pi.simple_copy ~single_write buffer ~src
end

module Fault_sink = struct
  type t = int ref
  let single_write count _ = incr count; failwith "injected write failure"
  let copy count ~src = Eio.Flow.Pi.simple_copy ~single_write count ~src
end

module Stuck_sink = struct
  type t = unit Promise.t
  let single_write block _ = Promise.await block; assert false
  let copy block ~src = Eio.Flow.Pi.simple_copy ~single_write block ~src
end

let capture_stderr f =
  let path = Filename.temp_file "playwright-critical-stderr-" "" in
  let saved = Unix.dup Unix.stderr in
  Fun.protect ~finally:(fun () -> Sys.remove path) (fun () ->
    let result = Fun.protect ~finally:(fun () ->
      flush stderr; Unix.dup2 saved Unix.stderr; Unix.close saved) (fun () ->
        flush stderr;
        let fd = Unix.openfile path [Unix.O_WRONLY; Unix.O_TRUNC] 0o600 in
        Unix.dup2 fd Unix.stderr; Unix.close fd;
        f ()) in
    result, In_channel.with_open_bin path In_channel.input_all)

let dummy () =
  Connection.create (Eio.Flow.string_source "") (Eio.Flow.buffer_sink (Buffer.create 100))

let pending ~sw c =
  let p = Fiber.fork_promise ~sw (fun () -> rpc c) in
  p

let internal env =
  test "request success, protocol error, cancellation, late responses and close races" (fun () ->
    Switch.run (fun sw ->
      let c = dummy () in
      let p = pending ~sw c in
      until env (fun () -> count c = 1);
      Connection.dispatch c (response c.last_id);
      check "reply" (Promise.await_exn p = Ok (`String "reply"));
      check "success cleanup" (count c = 0);
      let p = pending ~sw c in
      until env (fun () -> count c = 1);
      Connection.dispatch c (`Assoc ["id", `Int c.last_id; "error",
        `Assoc ["error", `Assoc ["name", `String "TestError"; "message", `String "bad"]]]);
      check "protocol error" (is_error (Promise.await_exn p));
      check "error cleanup" (count c = 0);
      for _ = 1 to 100 do
        let cc_p, cc_u = Promise.create () in
        let p = Fiber.fork_promise ~sw (fun () ->
          fails (fun () -> Eio.Cancel.sub (fun cc -> Promise.resolve cc_u cc; rpc c))) in
        let cc = Promise.await cc_p in
        until env (fun () -> count c = 1);
        let id = c.last_id in
        Eio.Cancel.cancel cc Exit;
        check "caller canceled" (is_cancelled (Promise.await_exn p));
        check "cancel cleanup" (count c = 0);
        check "local cancellation keeps session open" (Connection.closed_reason c = None);
        Connection.dispatch c (response id)
      done;
      for order = 0 to 199 do
        let c = dummy () in
        let p = pending ~sw c in
        until env (fun () -> count c = 1);
        let reply () = Connection.dispatch c (response c.last_id) in
        if order mod 2 = 0 then (reply (); Connection.close c "first")
        else (Connection.close c "first"; reply ());
        let result = Promise.await_exn p in
        if order mod 2 = 1 then check "closed response ignored" (result = Error "first")
        else check "response before close wins" (result = Ok (`String "reply"));
        Connection.close c "second"; reply ();
        check "first close reason" (Connection.closed_reason c = Some "first");
        assert_clean c
      done));
  test "local serialization failure does not register" (fun () ->
    let c = dummy () in
    ignore (fails (fun () ->
      Connection.send_message c ~guid:"" ~method_:"bad" ~params:(`Float nan)));
    check "serialization cleanup" (count c = 0);
    check "serialization keeps session open" (Connection.closed_reason c = None));
  test "write failure closes, rejects future writes, and clears requests" (fun () ->
    let writes = ref 0 in
    let sink = Eio.Resource.T (writes, Eio.Flow.Pi.sink (module Fault_sink)) in
    let c = Connection.create (Eio.Flow.string_source "") sink in
    check "write failed" (is_error (rpc c));
    check "no extra write" (is_error (rpc c) && !writes = 1);
    assert_clean c);
  test "close and cancellation interrupt blocked frame writes and lock waiters" (fun () ->
    Switch.run (fun sw ->
      List.iter (fun cancel_writer ->
        let block, _ = Promise.create () in
        let sink = Eio.Resource.T (block, Eio.Flow.Pi.sink (module Stuck_sink)) in
        let c = Connection.create (Eio.Flow.string_source "") sink in
        let cc_p, cc_u = Promise.create () in
        let p = Fiber.fork_promise ~sw (fun () ->
          try Ok (Eio.Cancel.sub (fun cc -> Promise.resolve cc_u cc; rpc c))
          with ex -> Error ex) in
        let cc = Promise.await cc_p in
        until env (fun () -> count c = 1);
        let q = pending ~sw c in
        until env (fun () -> count c = 2);
        if cancel_writer then Eio.Cancel.cancel cc Exit else Connection.close c "forced";
        ignore (bounded env (fun () -> Promise.await_exn p));
        check "blocked lock waiter rejects" (is_error (bounded env (fun () -> Promise.await_exn q)));
        assert_clean c) [false; true]));
  test "canceling a lock waiter does not close or interrupt the writer" (fun () ->
    Switch.run (fun sw ->
      let block, _ = Promise.create () in
      let sink = Eio.Resource.T (block, Eio.Flow.Pi.sink (module Stuck_sink)) in
      let c = Connection.create (Eio.Flow.string_source "") sink in
      let writer = pending ~sw c in
      until env (fun () -> count c = 1);
      let cc_p, cc_u = Promise.create () in
      let waiter = Fiber.fork_promise ~sw (fun () -> fails (fun () ->
        Eio.Cancel.sub (fun cc -> Promise.resolve cc_u cc; rpc c))) in
      let cc = Promise.await cc_p in
      until env (fun () -> count c = 2);
      Eio.Cancel.cancel cc Exit;
      check "lock waiter canceled" (is_cancelled (Promise.await_exn waiter));
      check "writer still registered" (count c = 1);
      check "session still open" (Connection.closed_reason c = None);
      Connection.close c "finish writer";
      check "writer closes" (is_error (Promise.await_exn writer));
      assert_clean c));
  test "concurrent RPC writes preserve complete frames" (fun () ->
    Switch.run (fun sw ->
      let bytes = Buffer.create 100 in
      let sink = Eio.Resource.T (bytes, Eio.Flow.Pi.sink (module Yield_sink)) in
      let c = Connection.create (Eio.Flow.string_source "") sink in
      let a = pending ~sw c and b = pending ~sw c in
      until env (fun () -> count c = 2);
      (* Let both complete their yielding writes before reading the buffer. *)
      for _ = 1 to 10 do Fiber.yield () done;
      let source = Eio.Flow.string_source (Buffer.contents bytes) in
      for _ = 1 to 2 do
        let msg = Option.get (Transport.read_message source) |> Yojson.Safe.from_string in
        let id = Yojson.Safe.Util.(member "id" msg |> to_int) in
        Connection.dispatch c (response id)
      done;
      check "exactly two frames" (Transport.read_message source = None);
      check "both requests complete" (Promise.await_exn a = Promise.await_exn b);
      check "empty after concurrent replies" (count c = 0)));
  test "EOF, truncated frames and malformed protocol settle requests" (fun () ->
    List.iter (fun data ->
      Switch.run (fun sw ->
        let c = Connection.create (Eio.Flow.string_source data)
            (Eio.Flow.buffer_sink (Buffer.create 100)) in
        let p = pending ~sw c in
        until env (fun () -> count c = 1);
        Connection.run_loop c;
        check "reader death rejects" (is_error (Promise.await_exn p));
        check "new RPC rejects" (is_error (rpc c));
        assert_clean c))
      [""; "\005\000\000\000ab"; "\001"; "\001\000\000\000!"])
  (* More event invariants below use the real dispatcher but synthetic protocol. *)

let add_object c guid =
  Connection.dispatch c (`Assoc ["guid", `String ""; "method", `String "__create__";
    "params", `Assoc ["guid", `String guid; "type", `String "Test"; "initializer", `Assoc []]])
let event c guid name params =
  Connection.dispatch c (`Assoc ["guid", `String guid; "method", `String name; "params", params])
let listeners c guid name =
  match Hashtbl.find_opt c.Connection.objects guid with
  | None -> 0
  | Some obj -> List.length (Option.value ~default:[] (Hashtbl.find_opt obj.events name))

let with_dispatcher env ?max_event_tasks ?on_event_error f =
  Switch.run (fun sw ->
    let reader, writer = Eio.Process.pipe ~sw (Eio.Stdenv.process_mgr env) in
    let c = Connection.create ?max_event_tasks ?on_event_error reader
        (Eio.Flow.buffer_sink (Buffer.create 100)) in
    let running = Fiber.fork_promise ~sw (fun () -> Connection.run_loop c) in
    Fun.protect ~finally:(fun () ->
      Connection.close c "test finished";
      bounded env (fun () -> Promise.await_exn running);
      Eio.Flow.close writer;
      assert_clean c)
      (fun () -> add_object c "x"; f sw c))

let internal_events env =
  test "FIFO starts, overlapping/reentrant callbacks, local errors, owned cancellation" (fun () ->
    let errors = ref [] in
    with_dispatcher env ~on_event_error:(fun e -> errors := e.exception_ :: !errors) (fun _sw c ->
      let order = ref [] in
      let entered, enter = Promise.create () in
      let canceled = ref false in
      ignore (Connection.add_listener c "x" "outer" (fun _ ->
        order := !order @ [1];
        Promise.resolve enter ();
        Fun.protect ~finally:(fun () -> canceled := true) (fun () ->
          ignore (Connection.wait_for_event c "x" "inner" ~decode:(fun _ -> ()) ()))));
      ignore (Connection.add_listener c "x" "outer" (fun _ ->
        order := !order @ [2]; event c "x" "inner" `Null));
      event c "x" "outer" `Null;
      bounded env (fun () -> Promise.await entered);
      until env (fun () -> !canceled);
      check "start order" (!order = [1; 2]);
      check "wait listener removed" (listeners c "x" "inner" = 0);
      ignore (Connection.add_listener c "x" "bad" (fun _ -> failwith "callback error"));
      ignore (Connection.add_listener c "x" "bad" (fun _ ->
        Eio.Cancel.sub (fun cc -> Eio.Cancel.cancel cc Exit; Fiber.check ())));
      event c "x" "bad" `Null;
      until env (fun () -> List.length !errors = 2);
      check "local cancellation reported" (List.exists is_cancelled !errors);
      check "callback errors do not close" (Connection.closed_reason c = None);
      let block, _ = Promise.create () in
      let cleanup = ref false in
      ignore (Connection.add_listener c "x" "slow" (fun _ ->
        Fun.protect ~finally:(fun () -> cleanup := true) (fun () -> Promise.await block)));
      event c "x" "slow" `Null;
      until env (fun () -> c.event_tasks = 1);
      Fiber.yield ();
      Connection.close c "shutdown";
      until env (fun () -> !cleanup);
      check "shutdown cancellation not reported" (List.length !errors = 2)));
  test "waiter success, predicate/decode errors, cancellation, and closure clean listeners/tasks" (fun () ->
    with_dispatcher env (fun sw c ->
      let wait decode predicate =
        Fiber.fork_promise ~sw (fun () ->
          Connection.wait_for_event c "x" "wait" ~decode ~predicate ()) in
      let p = wait (fun _ -> ()) (fun _ -> failwith "predicate error") in
      until env (fun () -> listeners c "x" "wait" = 1);
      event c "x" "wait" `Null;
      check "predicate exception propagated"
        (fails (fun () -> Promise.await_exn p) = Failure "predicate error");
      check "predicate listener removed" (listeners c "x" "wait" = 0);
      let p = wait (fun _ -> failwith "decode error") (fun _ -> true) in
      until env (fun () -> listeners c "x" "wait" = 1);
      event c "x" "wait" `Null;
      check "decode exception propagated"
        (fails (fun () -> Promise.await_exn p) = Failure "decode error");
      let cc_p, cc_u = Promise.create () in
      let block, _ = Promise.create () in
      let started = ref false and finished = ref false in
      let p = Fiber.fork_promise ~sw (fun () -> fails (fun () ->
        Eio.Cancel.sub (fun cc ->
          Promise.resolve cc_u cc;
          Connection.wait_for_event c "x" "wait" ~decode:(fun _ -> ())
            ~predicate:(fun _ ->
              started := true;
              Fun.protect ~finally:(fun () -> finished := true)
                (fun () -> Promise.await block; true)) ()))) in
      let cc = Promise.await cc_p in
      until env (fun () -> listeners c "x" "wait" = 1);
      event c "x" "wait" `Null;
      until env (fun () -> !started);
      Eio.Cancel.cancel cc Exit;
      check "wait caller canceled" (is_cancelled (Promise.await_exn p));
      until env (fun () -> !finished && c.event_tasks = 0);
      check "canceled waiter removed" (listeners c "x" "wait" = 0);
      let p = wait (fun _ -> ()) (fun _ -> true) in
      until env (fun () -> listeners c "x" "wait" = 1);
      Connection.close c "closed waiter";
      check "wait close propagated"
        (match fails (fun () -> Promise.await_exn p) with Connection.Closed "closed waiter" -> true | _ -> false)));
  test "failing callback finalizers during cancellation are observable, not swallowed" (fun () ->
    let errors = ref [] in
    with_dispatcher env ~on_event_error:(fun e -> errors := e.exception_ :: !errors) (fun sw c ->
      let cc_p, cc_u = Promise.create () in
      let started = ref false in
      let waiter = Fiber.fork_promise ~sw (fun () -> fails (fun () ->
        Eio.Cancel.sub (fun cc ->
          Promise.resolve cc_u cc;
          Connection.wait_for_event c "x" "cleanup" ~decode:Fun.id ~predicate:(fun _ ->
            started := true;
            Fun.protect ~finally:(fun () -> failwith "predicate finalizer failed")
              (fun () -> Fiber.await_cancel ())) ()))) in
      let cc = Promise.await cc_p in
      until env (fun () -> listeners c "x" "cleanup" = 1);
      event c "x" "cleanup" `Null;
      until env (fun () -> !started);
      Eio.Cancel.cancel cc Exit;
      check "original waiter cancellation" (is_cancelled (Promise.await_exn waiter));
      until env (fun () -> List.length !errors = 1 && c.event_tasks = 0);
      check "removed listener cleanup failure reported"
        (String.starts_with ~prefix:"Fun.Finally_raised" (Printexc.to_string (List.hd !errors))));
    let (), diagnostic = capture_stderr (fun () ->
      with_dispatcher env (fun _sw c ->
        let started = ref false in
        ignore (Connection.add_listener c "x" "shutdown-error" (fun _ ->
          started := true;
          Fun.protect ~finally:(fun () -> failwith "shutdown finalizer failed")
            (fun () -> Fiber.await_cancel ())));
        event c "x" "shutdown-error" `Null;
        until env (fun () -> !started);
        Connection.close c "original close reason";
        until env (fun () -> not c.running);
        check "cleanup error preserves close reason"
          (Connection.closed_reason c = Some "original close reason"))) in
    check "shutdown finalizer diagnostic" (List.exists
      (String.starts_with ~prefix:"Playwright event x.shutdown-error: ")
      (String.split_on_char '\n' diagnostic)));
  test "canceling a waiter after channel disposal still cancels its predicate" (fun () ->
    with_dispatcher env (fun sw c ->
      let started = ref false and finished = ref false in
      let cc_p, cc_u = Promise.create () in
      let waiter = Fiber.fork_promise ~sw (fun () -> fails (fun () ->
        Eio.Cancel.sub (fun cc ->
          Promise.resolve cc_u cc;
          Connection.wait_for_event c "x" "disposed" ~decode:Fun.id ~predicate:(fun _ ->
            started := true;
            Fun.protect ~finally:(fun () -> finished := true)
              (fun () -> Fiber.await_cancel ())) ()))) in
      let cc = Promise.await cc_p in
      until env (fun () -> listeners c "x" "disposed" = 1);
      event c "x" "disposed" `Null;
      until env (fun () -> !started);
      Connection.dispatch c (`Assoc [
        "guid", `String "x"; "method", `String "__dispose__"; "params", `Assoc []]);
      Eio.Cancel.cancel cc Exit;
      check "disposed wait canceled" (is_cancelled (Promise.await_exn waiter));
      until env (fun () -> !finished && c.event_tasks = 0)));
  test "overlapping predicates: first match cancels slower evaluations" (fun () ->
    with_dispatcher env (fun sw c ->
      let entered = ref false and finished = ref false in
      let block, _ = Promise.create () in
      let p = Fiber.fork_promise ~sw (fun () ->
        Connection.wait_for_event c "x" "overlap" ~decode:Fun.id ~predicate:(fun value ->
          if value = `Int 1 then begin
            entered := true;
            Fun.protect ~finally:(fun () -> finished := true) (fun () -> Promise.await block)
          end;
          true) ()) in
      until env (fun () -> listeners c "x" "overlap" = 1);
      event c "x" "overlap" (`Int 1);
      until env (fun () -> !entered);
      event c "x" "overlap" (`Int 2);
      check "second evaluation wins" (bounded env (fun () -> Promise.await_exn p) = `Int 2);
      until env (fun () -> !finished && c.event_tasks = 0);
      check "winner removes listener" (listeners c "x" "overlap" = 0);
      let p = Fiber.fork_promise ~sw (fun () -> fails (fun () ->
        Connection.wait_for_event c "x" "local-cancel" ~decode:Fun.id
          ~predicate:(fun _ -> Eio.Cancel.sub (fun cc ->
            Eio.Cancel.cancel cc Exit; Fiber.check (); true)) ())) in
      until env (fun () -> listeners c "x" "local-cancel" = 1);
      event c "x" "local-cancel" `Null;
      check "predicate local cancellation reaches waiter" (is_cancelled (Promise.await_exn p));
      check "local canceled predicate removed" (listeners c "x" "local-cancel" = 0)));
  test "queued and active events close without negative or retained task counts" (fun () ->
    for turn = 0 to 99 do
      with_dispatcher env (fun _sw c ->
        ignore (Connection.add_listener c "x" "race" (fun _ -> Fiber.await_cancel ()));
        for _ = 1 to 20 do
          event c "x" "race" `Null;
          if turn mod 2 = 0 then Fiber.yield ()
        done;
        Connection.close c "racing shutdown";
        Connection.close c "repeated shutdown")
    done);
  test "bounded event pressure closes instead of blocking or silently dropping" (fun () ->
    with_dispatcher env ~max_event_tasks:2 (fun _sw c ->
      let block, _ = Promise.create () in
      ignore (Connection.add_listener c "x" "slow" (fun _ -> Promise.await block));
      event c "x" "slow" `Null; event c "x" "slow" `Null; event c "x" "slow" `Null;
      check "overflow closes" (Connection.closed_reason c <> None)));
  test "reporter failure closes only its connection" (fun () ->
    with_dispatcher env ~on_event_error:(fun _ -> failwith "reporter failed") (fun _sw c ->
      ignore (Connection.add_listener c "x" "bad" (fun _ -> failwith "callback failed"));
      event c "x" "bad" `Null;
      until env (fun () -> Connection.closed_reason c <> None)))

let with_browser env ?on_event_error f =
  Switch.run (fun sw ->
    let pw = create ~env ~sw ?on_event_error () in
    Fun.protect ~finally:(fun () -> destroy pw; assert_clean (conn pw)) (fun () ->
      let browser = BrowserType.launch ~executable_path:"/usr/bin/chromium"
          ~headless:true (Playwright.chromium pw) in
      let context = Browser.new_context browser in
      let page = BrowserContext.new_page context in
      Page.set_content ~html:"<title>fixture</title><input id='input'><button>Go</button>" page;
      f sw pw browser context page))

let events env =
  test "public console, binding and dialog callback RPCs" (fun () ->
    with_browser env (fun _sw _pw _browser context page ->
      (* E01 is outside scope: explicitly enable valid protocol subscriptions. *)
      Page.update_subscription ~event:`Console ~enabled:true page;
      let console, console_u = Promise.create () in
      BrowserContext.on_console context (fun _ -> Promise.resolve console_u (Page.title page));
      ignore (Page.evaluate ~expression:"console.log('test')" page);
      check "console RPC" (bounded env (fun () -> Promise.await console) = "fixture");
      let binding, binding_u = Promise.create () in
      ignore (Page.expose_binding ~name:"answer" page);
      Page.on_binding_call page (fun e ->
        BindingCall.resolve ~result:(`Int 42) e.binding;
        Promise.resolve binding_u ());
      check "binding RPC" (Page.evaluate ~expression:"window.answer()" page = `Float 42.);
      bounded env (fun () -> Promise.await binding);
      Page.update_subscription ~event:`Dialog ~enabled:true page;
      let dialog, dialog_u = Promise.create () in
      BrowserContext.on_dialog context (fun e ->
        Dialog.dismiss e.dialog;
        Promise.resolve dialog_u ());
      ignore (Page.evaluate ~expression:"alert('test')" page);
      bounded env (fun () -> Promise.await dialog);
      check "unrelated RPC" (Page.title page = "fixture")));
  test "public route callback and event predicate RPCs" (fun () ->
    with_browser env (fun sw pw _browser context page ->
      let routed, routed_u = Promise.create () in
      Page.on_route page (fun e ->
        Route.fulfill ~status:200 ~body:"<title>routed</title>"
          ~headers:[|{name="content-type";value="text/html"}|]
          ~is_base64:false e.route;
        Promise.resolve routed_u ());
      Page.set_network_interception_patterns page ~patterns:[|
        Page.Patterns.{glob=Some "**/*";regex_source=None;regex_flags=None;url_pattern=None}|];
      ignore (Page.goto ~url:"http://fixture.invalid/route" page);
      bounded env (fun () -> Promise.await routed);
      Page.set_network_interception_patterns ~patterns:[||] page;
      check "route result" (Page.title page = "routed");
      Page.update_subscription ~event:`Console ~enabled:true page;
      let n = listeners (conn pw) (Internal.guid context) "console" in
      let waiter = Fiber.fork_promise ~sw (fun () ->
        BrowserContext.wait_for_console
          ~predicate:(fun e -> e.text = "predicate" && Page.title page = "routed") context) in
      until env (fun () -> listeners (conn pw) (Internal.guid context) "console" = n+1);
      ignore (Page.evaluate ~expression:"console.log('predicate')" page);
      check "RPC predicate completed" ((bounded env (fun () -> Promise.await_exn waiter)).text = "predicate");
      check "predicate listener cleanup" (listeners (conn pw) (Internal.guid context) "console" = n);
      check "subsequent RPC" (Page.title page = "routed")));
  test "public suspended, reentrant, throwing callbacks and waiter cleanup" (fun () ->
    let reported = ref [] in
    with_browser env ~on_event_error:(fun e -> reported := e :: !reported)
      (fun sw pw _browser context page ->
        Page.update_subscription ~event:`Console ~enabled:true page;
        let block, _ = Promise.create () in
        let entered = ref false and canceled = ref false in
        BrowserContext.on_console context (fun e ->
          if e.text = "slow" then begin
            entered := true;
            Fun.protect ~finally:(fun () -> canceled := true) (fun () -> Promise.await block)
          end);
        ignore (Page.evaluate ~expression:"console.log('slow')" page);
        until env (fun () -> !entered);
        check "suspended callback does not stall reader" (Page.title page = "fixture");
        let outer, outer_u = Promise.create () in
        BrowserContext.on_console context (fun e ->
          if e.text = "outer" then begin
            let next = BrowserContext.wait_for_console ~predicate:(fun e -> e.text = "inner") context in
            Promise.resolve outer_u next.text
          end);
        (* This callback must start despite the previous listener waiting. *)
        BrowserContext.on_console context (fun e ->
          if e.text = "outer" then ignore (Page.evaluate ~expression:"console.log('inner')" page));
        ignore (Page.evaluate ~expression:"console.log('outer')" page);
        check "reentrant callback" (bounded env (fun () -> Promise.await outer) = "inner");
        BrowserContext.on_console context (fun e ->
          if e.text = "throw" then failwith "observable callback error");
        let survivor = ref false in
        BrowserContext.on_console context (fun e -> if e.text = "throw" then survivor := true);
        ignore (Page.evaluate ~expression:"console.log('throw')" page);
        until env (fun () -> !survivor && List.length !reported = 1);
        check "reporter includes event" ((List.hd !reported).event = "console");
        let before = listeners (conn pw) (Internal.guid context) "console" in
        let p = Fiber.fork_promise ~sw (fun () ->
          fails (fun () -> BrowserContext.wait_for_console
            ~predicate:(fun _ -> failwith "public predicate error") context)) in
        until env (fun () -> listeners (conn pw) (Internal.guid context) "console" = before+1);
        ignore (Page.evaluate ~expression:"console.log('predicate failure')" page);
        check "public predicate throws" (Promise.await_exn p = Failure "public predicate error");
        check "public listener removed" (listeners (conn pw) (Internal.guid context) "console" = before);
        let timeout = fails (fun () -> Eio.Time.with_timeout_exn (clock env) 0.02
            (fun () -> BrowserContext.wait_for_console context)) in
        check "public wait cancellation" (is_timeout timeout);
        check "public canceled listener removed" (listeners (conn pw) (Internal.guid context) "console" = before);
        destroy pw;
        check "suspended callback canceled and joined" !canceled;
        check "no shutdown report" (List.length !reported = 1)));
  test "destroy from own callback does not join itself" (fun () ->
    with_browser env (fun _sw pw _browser context page ->
      Page.update_subscription ~event:`Console ~enabled:true page;
      let done_, done_u = Promise.create () in
      BrowserContext.on_console context (fun _ -> destroy pw; Promise.resolve done_u ());
      (* The triggering RPC may win the response race or be rejected by close. *)
      (try ignore (Page.evaluate ~expression:"console.log('destroy')" page) with Error _ -> ());
      bounded env (fun () -> Promise.await done_);
      destroy pw;
      assert_clean (conn pw)));
  test "generated callback decoder errors are reported; no-param wait cancellation cleans up" (fun () ->
    let errors = ref [] in
    with_browser env ~on_event_error:(fun e -> errors := e :: !errors)
      (fun _sw pw _browser context page ->
        let invoked = ref false in
        BrowserContext.on_console context (fun _ -> invoked := true);
        event (conn pw) (Internal.guid context) "console" (`Assoc []);
        until env (fun () -> List.length !errors = 1);
        check "invalid payload not delivered" (not !invoked);
        check "generated decoder failure observed" ((List.hd !errors).event = "console");
        let guid = Internal.guid page in
        let before = listeners (conn pw) guid "close" in
        check "no-param wait cancellation" (is_timeout (fails (fun () ->
          Eio.Time.with_timeout_exn (clock env) 0.02 (fun () -> Page.wait_for_close page))));
        check "no-param listener removed" (listeners (conn pw) guid "close" = before);
        check "decoder failure not fatal" (Page.title page = "fixture")));
  test "concurrent normal browser workflows" (fun () ->
    with_browser env (fun sw pw browser _context page ->
      let argument = `String (String.make (1024 * 1024) 'x') in
      let calls = List.init 8 (fun _ -> Fiber.fork_promise ~sw (fun () ->
        Page.evaluate ~expression:"s => s.length" ~arg:argument page)) in
      List.iter (fun p -> check "concurrent large reply" (Promise.await_exn p = `Float (float_of_int (1024*1024)))) calls;
      Page.fill ~selector:"#input" ~value:"hello" page;
      check "ordinary workflow" (Page.input_value ~selector:"#input" page = "hello");
      let context = Browser.new_context browser in
      let page2 = BrowserContext.new_page context in
      Page.set_content ~html:"<title>second</title>" page2;
      check "new context workflow" (Page.title page2 = "second");
      BrowserContext.close context;
      check "no pending RPCs" (count (conn pw) = 0)))

let usable pw =
  let browser = BrowserType.launch ~executable_path:"/usr/bin/chromium"
      ~headless:true (Playwright.chromium pw) in
  Browser.close browser

let ownership env =
  test "public instances destroyed in both orders; repeated destroy" (fun () ->
    List.iter (fun reverse ->
      Switch.run (fun sw ->
        let a = create ~env ~sw () and b = create ~env ~sw () in
        let a, b = if reverse then b, a else a, b in
        let dead_type = Playwright.chromium a in
        check "same protocol GUID" (Internal.guid a = Internal.guid b);
        check "different connection identities" (conn a != conn b);
        Fiber.both (fun () -> destroy a) (fun () -> destroy a);
        assert_clean (conn a);
        usable b;
        check "saved destroyed handle rejects"
          (match fails (fun () -> BrowserType.launch dead_type) with Error _ -> true | _ -> false);
        destroy b; destroy a; destroy b;
        assert_clean (conn b));
      no_children ()) [false; true]);
  test "nested scopes and creation with a different owning scope" (fun () ->
    Switch.run (fun outer ->
      let a = create ~env ~sw:outer () in
      let b = Switch.run (fun inner -> create ~env ~sw:inner ()) in
      assert_clean (conn b); destroy b; usable a;
      let c = Switch.run (fun _inner -> create ~env ~sw:outer ()) in
      usable c; destroy c;
      let canceled = ref None in
      check "scope cancellation" (is_cancelled (fails (fun () ->
        Eio.Cancel.sub (fun cc ->
          Switch.run (fun inner ->
            canceled := Some (create ~env ~sw:inner ());
            Eio.Cancel.cancel cc Exit;
            Fiber.check ())))));
      let b = Option.get !canceled in
      assert_clean (conn b); destroy b; usable a;
      destroy a);
    no_children ());
  test "independent concurrent switch lifetimes" (fun () ->
    let ready_a, ready_a_u = Promise.create () and ready_b, ready_b_u = Promise.create () in
    let ended, ended_u = Promise.create () in
    Fiber.both
      (fun () ->
        let a = Switch.run (fun sw ->
          let a = create ~env ~sw () in
          Promise.resolve ready_a_u ();
          Promise.await ready_b;
          a) in
        assert_clean (conn a); destroy a;
        Promise.resolve ended_u ())
      (fun () ->
        Switch.run (fun sw ->
          let b = create ~env ~sw () in
          Promise.resolve ready_b_u ();
          Promise.await ready_a; Promise.await ended;
          usable b; destroy b; assert_clean (conn b)));
    no_children ());
  test "cross-session callback destroy cannot form a cyclic cleanup join" (fun () ->
    Switch.run (fun sw ->
      let a = create ~env ~sw () and b = create ~env ~sw () in
      let entered = ref 0 in
      let release, release_u = Promise.create () in
      List.iter (fun (self, other) ->
        ignore (Connection.add_listener (conn self) (Internal.guid self) "destroy-peer" (fun _ ->
          incr entered;
          Promise.await release;
          destroy other)))
        [a, b; b, a];
      event (conn a) (Internal.guid a) "destroy-peer" `Null;
      event (conn b) (Internal.guid b) "destroy-peer" `Null;
      until env (fun () -> !entered = 2);
      Promise.resolve release_u ();
      (* Whether B's callback runs before its cancellation or not, neither
         callback can protect a join that the other callback depends on. *)
      until env (fun () -> Connection.closed_reason (conn b) <> None);
      bounded env (fun () -> destroy a; destroy b);
      assert_clean (conn a); assert_clean (conn b));
    no_children ());
  test "callback/reporter failure does not take down another public session" (fun () ->
    Switch.run (fun sw ->
      let a = create ~env ~sw ~on_event_error:(fun _ -> failwith "public reporter error") () in
      let b = create ~env ~sw () in
      ignore (Connection.add_listener (conn a) (Internal.guid a) "bad" (fun _ ->
        failwith "public callback error"));
      event (conn a) (Internal.guid a) "bad" `Null;
      until env (fun () -> Connection.closed_reason (conn a) <> None);
      usable b;
      destroy a; destroy b;
      assert_clean (conn a); assert_clean (conn b));
    no_children ());
  test "creating a session inside another session's callback does not retain its creator" (fun () ->
    Switch.run (fun sw ->
      let b, weak = (
        let a = create ~env ~sw () in
        let weak = Weak.create 1 in
        Weak.set weak 0 (Some (conn a));
        let ready, ready_u = Promise.create () in
        ignore (Connection.add_listener (conn a) (Internal.guid a) "create-peer" (fun _ ->
          Promise.resolve ready_u (create ~env ~sw ())));
        event (conn a) (Internal.guid a) "create-peer" `Null;
        let b = bounded env (fun () -> Promise.await ready) in
        destroy a;
        assert_clean (conn a);
        b, weak
      ) in
      Gc.full_major (); Gc.full_major ();
      check "live child session does not retain creator through fiber locals"
        (not (Weak.check weak 0));
      usable b;
      destroy b; assert_clean (conn b));
    no_children ());
  test "explicit cleanup releases closures and descriptors while owner switch stays alive" (fun () ->
    Switch.run (fun sw ->
      let warmup = create ~env ~sw () in
      destroy warmup;
      let before = fd_count () in
      let weak = Weak.create 12 in
      for i = 0 to 11 do
        let pw = create ~env ~sw () in
        Weak.set weak i (Some (conn pw));
        destroy pw;
        assert_clean (conn pw);
        check "session descriptors closed" (fd_count () = before);
        no_children ()
      done;
      Gc.full_major (); Gc.full_major ();
      for i = 0 to 11 do check "no closure retained by live owner switch" (not (Weak.check weak i)) done));
  test "repeated public creation/scope cleanup releases connections and children" (fun () ->
    let weak = Weak.create 16 in
    for i = 0 to 15 do
      Switch.run (fun sw ->
        let pw = create ~env ~sw () in
        Weak.set weak i (Some (conn pw));
        if i mod 2 = 0 then destroy pw);
      no_children ()
    done;
    Gc.full_major (); Gc.full_major ();
    for i = 0 to 15 do check "no retained session" (not (Weak.check weak i)) done)

let write path data = Out_channel.with_open_bin path (fun ch -> output_string ch data)
let read path = In_channel.with_open_bin path In_channel.input_all
let rec remove_tree path =
  if Sys.is_directory path then begin
    Array.iter (fun name -> remove_tree (Filename.concat path name)) (Sys.readdir path);
    Unix.rmdir path
  end else Sys.remove path

let with_fake_driver mode f =
  let before = children () in
  let home = Sys.getenv "HOME" in
  let dir = Filename.temp_file "playwright-critical-" "" in
  Sys.remove dir; Unix.mkdir dir 0o700;
  let log = Filename.concat dir "driver.log" in
  Fun.protect ~finally:(fun () ->
    Unix.putenv "HOME" home;
    Unix.putenv "CRITICAL_DRIVER_MODE" "";
    Unix.putenv "CRITICAL_DRIVER_LOG" "";
    remove_tree dir)
    (fun () ->
      Unix.putenv "HOME" dir;
      Unix.putenv "CRITICAL_DRIVER_MODE" mode;
      Unix.putenv "CRITICAL_DRIVER_LOG" log;
      let package = Filename.concat (Driver.driver_dir ()) "package" in
      Driver.mkdir_p package;
      write (Filename.concat package "cli.js") (read "fixture_driver.cjs");
      f log;
      check "fake driver children reaped" (children () = before))

let drivers env =
  test "spawn failure after pipes are allocated preserves error and closes descriptors" (fun () ->
    with_fake_driver "exit" (fun _ ->
      let path = Sys.getenv "PATH" in
      Switch.run (fun sw ->
        let before = fd_count () in
        let ex = Fun.protect ~finally:(fun () -> Unix.putenv "PATH" path) (fun () ->
          Unix.putenv "PATH" "/nonexistent-playwright-critical-path";
          fails (fun () -> create ~env ~sw ~init_timeout:2. ())) in
        check "spawn failure is not timeout" (not (is_timeout ex));
        check "partial initialization closes pipes" (fd_count () = before);
        no_children ())));
  test "immediately exiting driver fails initialization promptly" (fun () ->
    with_fake_driver "exit" (fun _ ->
      Switch.run (fun sw ->
        let start = Unix.gettimeofday () in
        let ex = fails (fun () -> create ~env ~sw ~init_timeout:2. ~shutdown_timeout:0.1 ()) in
        check "failure rather than deadline" (not (is_timeout ex));
        check "prompt exiting initialization" (Unix.gettimeofday () -. start < 1.);
        no_children ())));
  test "failed initialization preserves protocol error and releases resources" (fun () ->
    with_fake_driver "error" (fun _ ->
      Switch.run (fun sw ->
        let ex = fails (fun () -> create ~env ~sw ~shutdown_timeout:0.1 ()) in
        check "original initialization error"
          (match ex with Error s -> String.starts_with ~prefix:"FixtureError:" s | _ -> false);
        no_children ())));
  test "initialization deadline and caller cancellation reap stubborn driver" (fun () ->
    List.iter (fun cancel ->
      with_fake_driver "hang" (fun log ->
        Switch.run (fun sw ->
          let start = Unix.gettimeofday () in
          let ex = fails (fun () ->
            if cancel then Eio.Time.with_timeout_exn (clock env) 0.15 (fun () ->
              create ~env ~sw ~init_timeout:5. ~shutdown_timeout:0.05 ())
            else create ~env ~sw ~init_timeout:0.15 ~shutdown_timeout:0.05 ()) in
          check "original timeout preserved" (is_timeout ex);
          check "bounded failed startup cleanup" (Unix.gettimeofday () -. start < 1.5);
          check "fixture really started" (String.starts_with ~prefix:"pid " (read log));
          no_children ()))) [false; true]);
  test "deterministic cancellation during initialization and concurrent failure isolation" (fun () ->
    Switch.run (fun sw ->
      let survivor = create ~env ~sw () in
      let before = children () in
      with_fake_driver "hang" (fun log ->
        let cc_p, cc_u = Promise.create () in
        let init = Fiber.fork_promise ~sw (fun () -> fails (fun () ->
          Eio.Cancel.sub (fun cc ->
            Promise.resolve cc_u cc;
            create ~env ~sw ~init_timeout:5. ~shutdown_timeout:0.05 ()))) in
        let cc = Promise.await cc_p in
        until env (fun () -> Sys.file_exists log &&
          List.mem "initialize" (String.split_on_char '\n' (read log)));
        let second = Fiber.fork_promise ~sw (fun () -> fails (fun () ->
          create ~env ~sw ~init_timeout:0.15 ~shutdown_timeout:0.05 ())) in
        Eio.Cancel.cancel cc Exit;
        check "original caller cancellation preserved"
          (is_cancelled (bounded env (fun () -> Promise.await_exn init)));
        check "concurrent startup deadline" (is_timeout (Promise.await_exn second));
        check "only preexisting driver alive" (children () = before);
        usable survivor);
      destroy survivor; assert_clean (conn survivor));
    no_children ());
  test "already canceled creation and invalid options allocate no session" (fun () ->
    Switch.run (fun sw ->
      check "pre-canceled create" (is_cancelled (fails (fun () ->
        Eio.Cancel.sub (fun cc ->
          Eio.Cancel.cancel cc Exit;
          create ~env ~sw ()))));
      List.iter (fun timeout ->
        check "invalid deadline rejected" (match fails (fun () ->
          create ~env ~sw ~init_timeout:timeout ()) with Invalid_argument _ -> true | _ -> false))
        [0.; -1.; nan; infinity];
      check "invalid pressure limit" (match fails (fun () ->
        create ~env ~sw ~max_event_tasks:0 ()) with Invalid_argument _ -> true | _ -> false);
      no_children ()));
  test "process exit is observed even when stdout still has another writer" (fun () ->
    with_fake_driver "death" (fun log ->
      Switch.run (fun sw ->
        let pw = create ~env ~sw ~shutdown_timeout:0.05 () in
        let pid_line = List.hd (String.split_on_char '\n' (read log)) in
        let pid = Scanf.sscanf pid_line "pid %d" Fun.id in
        (* Hold a duplicate of the child's pipe writer. EOF cannot occur until
           we release it, so only the independent process watcher can close. *)
        let fd = Unix.openfile (Printf.sprintf "/proc/%d/fd/1" pid) [Unix.O_WRONLY; Unix.O_CLOEXEC] 0 in
        Fun.protect ~finally:(fun () -> Unix.close fd) (fun () ->
          let start = Unix.gettimeofday () in
          check "process watcher rejects" (is_error (bounded env (fun () -> rpc (conn pw))));
          check "exit observed without EOF" (Unix.gettimeofday () -. start < 1.);
          check "process failure reason"
            (match Connection.closed_reason (conn pw) with
             | Some reason -> String.starts_with ~prefix:"Playwright driver stopped:" reason
             | None -> false);
          destroy pw; assert_clean (conn pw); no_children ()))));
  test "driver EOF/death rejects pending and future RPCs with no leaks" (fun () ->
    List.iter (fun mode ->
      with_fake_driver mode (fun _ ->
        Switch.run (fun sw ->
          let pw = create ~env ~sw ~shutdown_timeout:0.05 () in
          let c = conn pw in
          let start = Unix.gettimeofday () in
          check "pending rejects" (is_error (bounded env (fun () -> rpc c)));
          check "prompt driver failure" (Unix.gettimeofday () -. start < 1.);
          check "new requests reject" (is_error (rpc c));
          destroy pw; assert_clean c; no_children ()))) ["eof"; "death"]);
  test "explicit destroy gracefully closes stdin then escalates TERM/KILL and reaps" (fun () ->
    with_fake_driver "stubborn" (fun log ->
      Switch.run (fun sw ->
        let pw = create ~env ~sw ~shutdown_timeout:0.05 () in
        let start = Unix.gettimeofday () in
        destroy pw;
        check "bounded destroy" (Unix.gettimeofday () -. start < 1.);
        let lines = String.split_on_char '\n' (read log) in
        check "graceful EOF" (List.mem "EOF" lines);
        check "TERM before KILL" (List.mem "TERM" lines);
        assert_clean (conn pw); no_children ())));
  test "real driver death rejects public pending browser RPC and reaps" (fun () ->
    with_browser env (fun sw pw _browser _context page ->
      let driver = List.filter (fun pid -> not (List.mem pid !child_baseline)) (children ()) in
      check "one owned driver" (List.length driver = 1);
      let p = Fiber.fork_promise ~sw (fun () -> fails (fun () ->
        Page.evaluate ~expression:"new Promise(() => {})" page)) in
      until env (fun () -> count (conn pw) = 1);
      Unix.kill (List.hd driver) Sys.sigkill;
      let ex = bounded env (fun () -> Promise.await_exn p) in
      check "driver failure not timeout" (not (is_timeout ex));
      check "future public RPC fails" (match fails (fun () -> Page.title page) with Error _ -> true | _ -> false);
      destroy pw; assert_clean (conn pw); no_children ()))

let () =
  Printexc.record_backtrace true;
  Eio_main.run (fun env ->
    child_baseline := children ();
    Eio.Time.with_timeout_exn (clock env) 40. (fun () ->
      match Sys.argv.(1) with
      | "internal" -> internal env; internal_events env
      | "events" -> events env
      | "ownership" -> ownership env
      | "drivers" -> drivers env
      | mode -> invalid_arg mode);
    no_children ())
