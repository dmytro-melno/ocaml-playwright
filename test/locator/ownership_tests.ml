(* Deterministic wire-level tests. No browser timing thresholds: the test owns
   each response, including cancellation/late-acquisition and disposal races. *)
open Playwright
open Eio.Std

let check name condition = if not condition then failwith ("ASSERTION FAILED: " ^ name)
let test name f = f (); Printf.printf "PASS ownership %s\n%!" name
let member = Yojson.Safe.Util.member
let str s = `String s
let obj fields = `Assoc fields
let contains s needle =
  let n = String.length needle in
  let rec loop i = i + n <= String.length s && (String.sub s i n = needle || loop (i + 1)) in
  loop 0
let error needle = function
  | Error s -> check ("expected " ^ needle ^ ", got " ^ s) (contains s needle)
  | ex -> raise ex
let outcome f = try Ok (f ()) with ex -> Error ex
let get_error = function Ok _ -> failwith "expected error" | Error ex -> ex
let timeout = function Error s -> String.starts_with ~prefix:"TimeoutError:" s | _ -> false
let cancelled = function Eio.Cancel.Cancelled _ -> true | _ -> false
let until env f =
  Eio.Time.with_timeout_exn (Eio.Stdenv.clock env) 3. (fun () ->
    while not (f ()) do Fiber.yield () done)

module Partial_sink = struct
  type t = unit Promise.u
  let single_write started _ =
    (* Once inside a transport write, even cancellation before a known complete
       frame is conservatively a stream-corruption risk. *)
    Promise.resolve started ();
    Fiber.await_cancel ()
  let copy started ~src = Eio.Flow.Pi.simple_copy ~single_write started ~src
end

type peer = { c : Connection.t; wire : Buffer.t; mutable offset : int }
let create p ~parent ~kind guid init =
  Connection.dispatch p.c (obj ["guid", str parent; "method", str "__create__"; "params",
    obj ["guid", str guid; "type", str kind; "initializer", init]])
let peer () =
  let wire = Buffer.create 1024 in
  let c = Connection.create (Eio.Flow.string_source "") (Eio.Flow.buffer_sink wire) in
  let p = { c; wire; offset = 0 } in
  create p ~parent:"" ~kind:"Frame" "frame" (obj ["name", str ""; "url", str "about:blank"; "loadStates", `List []]);
  p
let locator p =
  let frame = Fiber.with_binding Connection.current_connection_key p.c (fun () ->
    match Frame.of_yojson (obj ["guid", str "frame"]) with Ok f -> f | Error e -> failwith e) in
  Frame.locator ~selector:"#target" frame
let next env p method_ =
  until env (fun () -> Buffer.length p.wire >= p.offset + 4);
  let data = Buffer.contents p.wire in
  let len = Int32.to_int (String.get_int32_le data p.offset) in
  until env (fun () -> Buffer.length p.wire >= p.offset + 4 + len);
  let request = Yojson.Safe.from_string (Buffer.sub p.wire (p.offset + 4) len) in
  p.offset <- p.offset + 4 + len;
  check ("method " ^ method_ ^ ": " ^ Yojson.Safe.to_string request) (member "method" request = str method_);
  request
let reply p req result = Connection.dispatch p.c (obj ["id", member "id" req; "result", result])
let fail p req name message = Connection.dispatch p.c (obj ["id", member "id" req; "error",
  obj ["error", obj ["name", str name; "message", str message]]])
let return_handle p req =
  create p ~parent:"frame" ~kind:"ElementHandle" "handle" (obj ["preview", str "JSHandle@node"]);
  reply p req (obj ["element", obj ["guid", str "handle"]])
let disposed env p =
  let req = next env p "dispose" in
  check "disposes exactly acquired handle" (member "guid" req = str "handle");
  Connection.dispatch p.c (obj ["guid", str "handle"; "method", str "__dispose__"; "params", obj []]);
  reply p req (obj [])
let clean p =
  check "no pending requests" (Hashtbl.length p.c.callbacks = 0);
  check "no orphan handle" (not (Hashtbl.mem p.c.objects "handle"))
let numeric = function `Float f -> f | `Int i -> float i | j -> failwith (Yojson.Safe.to_string j)
let request_timeout req = member "params" req |> member "timeout" |> numeric
let spawn ~sw f = Fiber.fork_promise ~sw (fun () -> outcome f)
let cancelable ~sw f =
  let cc_p, cc_u = Promise.create () in
  let p = spawn ~sw (fun () -> Eio.Cancel.sub (fun cc -> Promise.resolve cc_u cc; f ())) in
  p, Promise.await cc_p

let tests env =
  Switch.run (fun sw ->
    test "different sessions with identical frame GUIDs are rejected locally" (fun () ->
      let p = peer () and q = peer () in
      let a = locator p and b = locator q in
      List.iter (fun f ->
        match f () with
        | _ -> failwith "cross-session composition succeeded"
        | exception Invalid_argument s -> check "diagnostic" (contains s "same frame and session"))
        [(fun () -> ignore (Locator.and_ a b)); (fun () -> ignore (Locator.or_ a b));
         (fun () -> ignore (Locator.filter ~has:b a)); (fun () -> Locator.drag_to ~target:b a)];
      check "no messages sent" (Buffer.length p.wire = 0 && Buffer.length q.wire = 0));
    test "immediate visibility uses strict frame queries without handles or timeout" (fun () ->
      List.iter (fun (operation, method_, value) ->
        let p = peer () in
        let pending = spawn ~sw (fun () -> operation (locator p)) in
        let req = next env p method_ in
        check "frame not element operation" (member "guid" req = str "frame");
        check "strict" (member "strict" (member "params" req) = `Bool true);
        check "no wait timeout" (member "timeout" (member "params" req) = `Null);
        reply p req (obj ["value", `Bool value]);
        check "value" (Promise.await_exn pending = Ok value);
        clean p)
        [(fun l -> Locator.is_visible ~timeout:0. l), "isVisible", false;
         (fun l -> Locator.is_hidden l), "isHidden", true]);
    test "pre-canceled acquisition sends no request" (fun () ->
      let p = peer () in
      List.iter (fun operation ->
        let result = outcome (fun () ->
          Eio.Cancel.sub (fun cc ->
            Eio.Cancel.cancel cc Exit;
            operation (locator p))) in
        check "canceled" (cancelled (get_error result));
        check "no wire writes" (Buffer.length p.wire = 0); clean p)
        [(fun l -> ignore (Locator.element_handle l)); (fun l -> ignore (Locator.element_handles l))]);
    test "same handle, shrinking scroll/screenshot budget, zero stays unlimited" (fun () ->
      List.iter (fun (timeout_ms, operation, method_) ->
        let p = peer () in
        let pending = spawn ~sw (fun () -> operation timeout_ms (locator p)) in
        let req = next env p "waitForSelector" in
        check "strict attached" (member "strict" (member "params" req) = `Bool true &&
          member "state" (member "params" req) = str "attached");
        if timeout_ms = 0. then check "unlimited acquisition" (request_timeout req = 0.)
        else check "one full acquisition budget"
          (request_timeout req > timeout_ms -. 100. && request_timeout req <= timeout_ms);
        (* Deterministic response hold accounts for time already spent acquiring. *)
        Eio_unix.sleep 0.12;
        return_handle p req;
        let op = next env p method_ in
        check "uses acquired handle, not selector" (member "guid" op = str "handle" && member "selector" (member "params" op) = `Null);
        if timeout_ms = 0. then check "unlimited operation" (request_timeout op = 0.)
        else check "shared deadline" (request_timeout op > 0. && request_timeout op < timeout_ms -. 100.);
        let result = if method_ = "screenshot" then obj ["binary", str "aGk="] else obj [] in
        reply p op result; disposed env p;
        (match Promise.await_exn pending with Ok () -> () | Error ex -> raise ex);
        clean p)
        [800., (fun timeout l -> Locator.scroll_into_view_if_needed ~timeout l), "scrollIntoViewIfNeeded";
         800., (fun timeout l -> ignore (Locator.screenshot ~timeout l)), "screenshot";
         0., (fun timeout l -> Locator.scroll_into_view_if_needed ~timeout l), "scrollIntoViewIfNeeded";
         0., (fun timeout l -> ignore (Locator.screenshot ~timeout l)), "screenshot"]);
    test "expired acquisition budget is never sent as unlimited operation" (fun () ->
      let p = peer () in
      let pending = spawn ~sw (fun () -> Locator.scroll_into_view_if_needed ~timeout:20. (locator p)) in
      let req = next env p "waitForSelector" in
      Eio_unix.sleep 0.04; return_handle p req;
      disposed env p;
      check "deadline error" (timeout (get_error (Promise.await_exn pending)));
      clean p);
    test "evaluation and bounding box have acquisition-only deadlines" (fun () ->
      List.iter (fun (operation, method_, result) ->
        let p = peer () in
        let pending = spawn ~sw (fun () -> operation (locator p)) in
        let req = next env p "waitForSelector" in
        Eio_unix.sleep 0.04; return_handle p req;
        let op = next env p method_ in
        check "same handle" (member "guid" op = str "handle");
        check "no blanket execution timeout" (member "timeout" (member "params" op) = `Null);
        reply p op result; disposed env p;
        (match Promise.await_exn pending with Ok () -> () | Error ex -> raise ex); clean p)
        [(fun l -> ignore (Locator.evaluate ~timeout:20. ~expression:"el => el" l)), "evaluateExpression", obj ["value", obj ["s", str "ok"]];
         (fun l -> ignore (Locator.bounding_box ~timeout:20. l)), "boundingBox", obj []]);
    test "single request gets the budget; server timeout is not retried" (fun () ->
      List.iter (fun timeout_ms ->
        let p = peer () in
        let pending = spawn ~sw (fun () -> Locator.element_handle ~timeout:timeout_ms (locator p)) in
        let req = next env p "waitForSelector" in
        if timeout_ms = 0. then check "zero forwarded unchanged" (request_timeout req = 0.)
        else check "no 100ms slicing" (request_timeout req > 100.);
        fail p req "TimeoutError" "ORIGINAL-SELECTOR-TIMEOUT";
        error "ORIGINAL-SELECTOR-TIMEOUT" (get_error (Promise.await_exn pending));
        check "no repeated selector work" (p.offset = Buffer.length p.wire);
        check "server timeout leaves session open" (Connection.closed_reason p.c = None);
        clean p)
        [1600.; 0.]);
    test "cancellation before acquisition returns a late handle to its owner" (fun () ->
      for order = 1 to 12 do
        let p = peer () in
        let pending, cc = cancelable ~sw (fun () -> Locator.element_handle ~timeout:0. (locator p)) in
        let req = next env p "waitForSelector" in
        if order mod 2 = 0 then begin
          Eio.Cancel.cancel cc Exit;
          (* The pending response retains an owner during cancellation recovery. *)
          check "ownership request retained until bounded resolution" (Hashtbl.length p.c.callbacks = 1);
          return_handle p req
        end else begin
          return_handle p req;
          Eio.Cancel.cancel cc Exit
        end;
        disposed env p;
        check "canceled not returned to caller" (cancelled (get_error (Promise.await_exn pending)));
        clean p
      done);
    test "plural handles are cleaned only when canceled before transfer" (fun () ->
      let p = peer () in
      let pending, cc = cancelable ~sw (fun () -> Locator.element_handles (locator p)) in
      let req = next env p "querySelectorAll" in
      check "plural remains non-strict" (member "strict" (member "params" req) = `Null);
      Eio.Cancel.cancel cc Exit;
      create p ~parent:"frame" ~kind:"ElementHandle" "handle" (obj ["preview", str "node"]);
      reply p req (obj ["elements", `List [obj ["guid", str "handle"]]]);
      disposed env p;
      check "canceled before transfer" (cancelled (get_error (Promise.await_exn pending)));
      clean p);
    test "cancellation after acquisition, during RPC, and during disposal" (fun () ->
      List.iter (fun stage ->
        let p = peer () in
        let pending, cc = cancelable ~sw (fun () -> Locator.evaluate ~expression:"el => el" (locator p)) in
        let req = next env p "waitForSelector" in return_handle p req;
        let op = next env p "evaluateExpression" in
        if stage = "operation" then Eio.Cancel.cancel cc Exit
        else reply p op (obj ["value", obj ["s", str "ok"]]);
        let dispose_req = next env p "dispose" in
        if stage = "disposal" then Eio.Cancel.cancel cc Exit;
        if stage = "disposal-failure" then begin
          Eio.Cancel.cancel cc Exit;
          fail p dispose_req "Error" "SECONDARY-DISPOSAL"
        end else begin
          Connection.dispatch p.c (obj ["guid", str "handle"; "method", str "__dispose__"; "params", obj []]);
          reply p dispose_req (obj [])
        end;
        check "cancellation propagated even if cleanup fails" (cancelled (get_error (Promise.await_exn pending)));
        (* Late operation response must neither leak requests nor re-own the handle. *)
        reply p op (obj ["value", obj ["s", str "late"]]); clean p)
        ["operation"; "disposal"; "disposal-failure"]);
    test "scroll and screenshot cancellation release the owned handle" (fun () ->
      List.iter (fun (operation, method_) ->
        let p = peer () in
        let pending, cc = cancelable ~sw (fun () -> operation (locator p)) in
        let req = next env p "waitForSelector" in return_handle p req;
        let op = next env p method_ in
        Eio.Cancel.cancel cc Exit;
        disposed env p;
        check "canceled" (cancelled (get_error (Promise.await_exn pending)));
        reply p op (obj ["binary", str "aGk="]); clean p)
        [(fun l -> Locator.scroll_into_view_if_needed l), "scrollIntoViewIfNeeded";
         (fun l -> ignore (Locator.screenshot l)), "screenshot"]);
    test "primary error survives cleanup failure; unsafe session is closed" (fun () ->
      let p = peer () in
      let pending = spawn ~sw (fun () -> Locator.evaluate ~expression:"el => el" (locator p)) in
      let req = next env p "waitForSelector" in return_handle p req;
      let op = next env p "evaluateExpression" in fail p op "Error" "PRIMARY";
      let req = next env p "dispose" in fail p req "Error" "SECONDARY";
      error "PRIMARY" (get_error (Promise.await_exn pending));
      check "closed on unsuccessful disposal" (Connection.closed_reason p.c <> None); clean p);
    test "target closed during disposal removes temporary metadata" (fun () ->
      let p = peer () in
      let pending = spawn ~sw (fun () -> Locator.bounding_box (locator p)) in
      let req = next env p "waitForSelector" in return_handle p req;
      let op = next env p "boundingBox" in reply p op (obj []);
      let req = next env p "dispose" in fail p req "TargetClosedError" "Target closed";
      check "target closure cleanup is idempotent" (Promise.await_exn pending = Ok None);
      check "session survives target close" (Connection.closed_reason p.c = None); clean p);
    test "connection closure in acquisition/operation/disposal never strands ownership" (fun () ->
      List.iter (fun stage ->
        let p = peer () in
        let pending = spawn ~sw (fun () -> Locator.evaluate ~expression:"el => el" (locator p)) in
        let req = next env p "waitForSelector" in
        if stage <> "acquisition" then begin
          return_handle p req;
          let op = next env p "evaluateExpression" in
          if stage = "disposal" then begin
            reply p op (obj ["value", obj ["s", str "ok"]]);
            ignore (next env p "dispose")
          end
        end;
        Connection.close p.c "TEST-CLOSE";
        error "TEST-CLOSE" (get_error (Promise.await_exn pending)); clean p)
        ["acquisition"; "operation"; "disposal"]);
    test "stalled canceled response/disposal bounded by ownership recovery" (fun () ->
      List.iter (fun (stage, cancel) ->
        let p = peer () and unrelated = peer () in
        let pending, cc = cancelable ~sw (fun () ->
          if stage = "plural" then ignore (Locator.element_handles (locator p))
          else ignore (Locator.bounding_box (locator p))) in
        let req = next env p (if stage = "plural" then "querySelectorAll" else "waitForSelector") in
        if stage = "disposal" then begin
          return_handle p req;
          let op = next env p "boundingBox" in reply p op (obj []);
          ignore (next env p "dispose")
        end;
        if cancel then Eio.Cancel.cancel cc Exit;
        let ex = get_error (Promise.await_exn pending) in
        if cancel then check "recovery preserves cancellation" (cancelled ex)
        else error "handle disposal did not settle" ex;
        check "recovery closes only its session"
          (Connection.closed_reason p.c <> None && Connection.closed_reason unrelated.c = None);
        clean p)
        ["acquisition", true; "plural", true; "disposal", false; "disposal", true]);
    test "ordinary slow responses never start a recovery deadline" (fun () ->
      List.iter (fun plural ->
        let p = peer () in
        let pending = spawn ~sw (fun () ->
          if plural then Locator.element_handles (locator p)
          else [|Option.get (Locator.element_handle ~timeout:0. (locator p))|]) in
        let req = next env p (if plural then "querySelectorAll" else "waitForSelector") in
        Eio_unix.sleep 1.2;
        check "uncanceled query still waiting" (not (Promise.is_resolved pending));
        check "ordinary latency leaves session open" (Connection.closed_reason p.c = None);
        create p ~parent:"frame" ~kind:"ElementHandle" "handle" (obj ["preview", str "node"]);
        reply p req (if plural then obj ["elements", `List [obj ["guid", str "handle"]]]
          else obj ["element", obj ["guid", str "handle"]]);
        let hs = match Promise.await_exn pending with Ok hs -> hs | Error ex -> raise ex in
        check "caller owns result" (Array.length hs = 1 && Hashtbl.mem p.c.objects "handle");
        let cleanup = spawn ~sw (fun () -> ElementHandle.dispose hs.(0)) in
        disposed env p; check "caller disposal" (Promise.await_exn cleanup = Ok ());
        clean p) [false; true]);
    test "write-lock latency is not remote ownership failure" (fun () ->
      List.iter (fun plural ->
        let p = peer () in
        Eio.Mutex.lock p.c.write_lock;
        let pending = spawn ~sw (fun () ->
          if plural then Locator.element_handles (locator p)
          else [|Option.get (Locator.element_handle ~timeout:5000. (locator p))|]) in
        until env (fun () -> Hashtbl.length p.c.callbacks = 1);
        Eio_unix.sleep 1.3;
        check "no bytes before lock released" (Buffer.length p.wire = 0);
        check "queued request still waiting" (not (Promise.is_resolved pending));
        check "healthy session not closed" (Connection.closed_reason p.c = None);
        Eio.Mutex.unlock p.c.write_lock;
        let req = next env p (if plural then "querySelectorAll" else "waitForSelector") in
        create p ~parent:"frame" ~kind:"ElementHandle" "handle" (obj ["preview", str "node"]);
        reply p req (if plural then obj ["elements", `List [obj ["guid", str "handle"]]]
          else obj ["element", obj ["guid", str "handle"]]);
        let hs = match Promise.await_exn pending with Ok hs -> hs | Error ex -> raise ex in
        let cleanup = spawn ~sw (fun () -> ElementHandle.dispose hs.(0)) in
        disposed env p; check "caller disposal" (Promise.await_exn cleanup = Ok ());
        clean p) [false; true]);
    test "interrupted handle-request writes retain the transport close invariant" (fun () ->
      let started, start_u = Promise.create () in
      let sink = Eio.Resource.T (start_u, Eio.Flow.Pi.sink (module Partial_sink)) in
      let p = { c = Connection.create (Eio.Flow.string_source "") sink; wire = Buffer.create 0; offset = 0 } in
      create p ~parent:"" ~kind:"Frame" "frame" (obj ["name", str ""; "url", str ""; "loadStates", `List []]);
      let pending, cc = cancelable ~sw (fun () -> Locator.element_handle (locator p)) in
      Promise.await started; Eio.Cancel.cancel cc Exit;
      check "write cancellation preserved" (cancelled (get_error (Promise.await_exn pending)));
      check "transport diagnostic, not acquisition latency"
        (Option.fold ~none:false ~some:(fun reason -> contains reason "transport write failed") (Connection.closed_reason p.c));
      clean p);
    test "malformed resource replies close safely instead of losing decoded handles" (fun () ->
      let p = peer () in
      let pending = spawn ~sw (fun () -> Locator.element_handles (locator p)) in
      let req = next env p "querySelectorAll" in
      create p ~parent:"frame" ~kind:"ElementHandle" "handle" (obj ["preview", str "node"]);
      reply p req (obj ["elements", `List [obj ["guid", str "handle"]; `Null]]);
      ignore (get_error (Promise.await_exn pending));
      check "specific decode failure closes its session"
        (Option.fold ~none:false ~some:(fun reason -> contains reason "handle response decoding failed") (Connection.closed_reason p.c));
      clean p);
    test "pre-write cancellation neither sends nor enters ownership recovery" (fun () ->
      List.iter (fun plural ->
        let p = peer () in
        Eio.Mutex.lock p.c.write_lock;
        let pending, cc = cancelable ~sw (fun () ->
          if plural then ignore (Locator.element_handles (locator p))
          else ignore (Locator.element_handle ~timeout:0. (locator p))) in
        until env (fun () -> Hashtbl.length p.c.callbacks = 1);
        Eio.Cancel.cancel cc Exit;
        check "pre-write cancellation" (cancelled (get_error (Promise.await_exn pending)));
        check "no transmitted request" (Buffer.length p.wire = 0);
        check "session open" (Connection.closed_reason p.c = None); clean p;
        Eio.Mutex.unlock p.c.write_lock;
        (* Another caller can still use this exact connection. *)
        let visible = spawn ~sw (fun () -> Locator.is_visible (locator p)) in
        let req = next env p "isVisible" in reply p req (obj ["value", `Bool true]);
        check "subsequent request works" (Promise.await_exn visible = Ok true); clean p)
        [false; true]))


let () =
  Printexc.record_backtrace true;
  Eio_main.run tests
