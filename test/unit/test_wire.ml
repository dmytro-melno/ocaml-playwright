(* JSON helpers, message framing and the connection. *)

open Eio.Std
open Internal

(* {1 JSON} *)

let test_json_encoding () =
    Alcotest.check json "optional members are omitted"
        (`Assoc [ "a", `Int 1; "c", `List [ `String "x" ] ])
        (Json.obj [ Json.req "a" Json.int 1; Json.opt "b" Json.string None; Json.opt "c" (Json.list Json.string) (Some [ "x" ]) ]);
    Alcotest.check json "binary is base64" (`String "AAH/") (Json.binary "\000\001\255");
    Alcotest.check json "enum" (`String "left") (Json.enum [ `Left, "left"; `Right, "right" ] `Left)

let test_json_decoding () =
    let module D = Json.Decode in
    let doc = Json.of_string {|{"n": 3, "f": 1.5, "s": "x", "b": "AAH/", "l": [1, 2], "e": "right", "null": null}|} in
    Alcotest.(check int) "int" 3 (D.req "n" D.int doc);
    Alcotest.(check (float 0.)) "int as float" 3. (D.req "n" D.float doc);
    Alcotest.(check (float 0.)) "float" 1.5 (D.req "f" D.float doc);
    Alcotest.(check string) "binary" "\000\001\255" (D.req "b" D.binary doc);
    Alcotest.(check (list int)) "list" [ 1; 2 ] (D.req "l" (D.list D.int) doc);
    Alcotest.(check bool) "enum" true (D.req "e" (D.enum [ "left", `Left; "right", `Right ]) doc = `Right);
    Alcotest.(check (option string)) "missing optional" None (D.opt "missing" D.string doc);
    Alcotest.(check (option string)) "null optional" None (D.opt "null" D.string doc);
    let fails what f =
        match f () with
        | _ -> Alcotest.failf "%s: expected Decode_error" what
        | exception Json.Decode_error message -> message
    in
    check_contains "missing member names the field" ~sub:"missing" (fails "missing" (fun () -> D.req "missing" D.string doc));
    check_contains "type mismatch names the field" ~sub:"s: expected an integer" (fails "mismatch" (fun () -> D.req "s" D.int doc));
    ignore (fails "fractional int" (fun () -> D.req "f" D.int doc));
    ignore (fails "unknown enum literal" (fun () -> D.req "s" (D.enum [ "left", `Left ]) doc));
    ignore (fails "invalid JSON" (fun () -> Json.of_string "{"))

(* {1 Framing} *)

let frame text =
    let header = Bytes.create 4 in
    Bytes.set_int32_le header 0 (Int32.of_int (String.length text));
    Bytes.to_string header ^ text

(* A source that hands out its content in pieces of the given sizes, then one byte at a time. *)
module Chunked = struct
    type t = { content : string; mutable pos : int; mutable sizes : int list }

    let read_methods = []

    let single_read t dst =
        if t.pos >= String.length t.content then raise End_of_file;
        let size =
            match t.sizes with
            | size :: rest ->
                t.sizes <- rest;
                size
            | [] -> 1
        in
        let n = min (min size (Cstruct.length dst)) (String.length t.content - t.pos) in
        Cstruct.blit_from_string t.content t.pos dst 0 n;
        t.pos <- t.pos + n;
        n
end

let chunked_source content sizes = Eio.Resource.T ({ Chunked.content; pos = 0; sizes }, Eio.Flow.Pi.source (module Chunked))
let null_sink () = Eio.Flow.buffer_sink (Buffer.create 0)

let receive_all (transport : Transport.t) =
    let rec go acc = match transport.receive () with Some message -> go (message :: acc) | None -> List.rev acc in
    go []

let test_framing_roundtrip () =
    let big = `String (String.make 200_000 'x') in
    let messages = [ `Assoc [ "id", `Int 1 ]; big; `Assoc [ "text", `String "snowman \xE2\x98\x83" ]; `List [] ] in
    let buffer = Buffer.create 1024 in
    let writer = Transport.of_flows (Eio.Flow.string_source "") (Eio.Flow.buffer_sink buffer) in
    List.iter writer.send messages;
    let wire = Buffer.contents buffer in
    Alcotest.(check string) "length prefix is little-endian" (frame {|{"id":1}|}) (String.sub wire 0 12);
    let whole = Transport.of_flows (Eio.Flow.string_source wire) (null_sink ()) in
    Alcotest.(check (list json)) "in one piece" messages (receive_all whole);
    (* Headers and bodies split at awkward places. *)
    let pieces = Transport.of_flows (chunked_source wire [ 1; 2; 5; 70_000; 3; 100_000; 1; 1; 7 ]) (null_sink ()) in
    Alcotest.(check (list json)) "in pieces" messages (receive_all pieces)

let test_framing_violations () =
    let reader wire = Transport.of_flows (Eio.Flow.string_source wire) (null_sink ()) in
    let violation what wire =
        match (reader wire).receive () with
        | _ -> Alcotest.failf "%s: expected a violation" what
        | exception Transport.Violation _ -> ()
    in
    Alcotest.(check bool) "clean end of stream" true ((reader "").receive () = None);
    violation "truncated header" "\005\000";
    violation "truncated body" (String.sub (frame {|{"id":1}|}) 0 8);
    violation "oversized message" "\255\255\255\255";
    violation "malformed JSON" (frame "{nope")

(* {1 Connection} *)

type peer = {
    sw : Switch.t;
    conn : Connection.t;
    sent : Json.t Eio.Stream.t;  (* what the client sent *)
    deliver : Json.t -> unit;  (* a message from the driver *)
    hang_up : unit -> unit;
    reported : (string * exn) list ref;
}

(* Runs [f] against a connection whose other end is the test. *)
let with_peer f =
    Eio_main.run @@ fun env ->
    Switch.run @@ fun sw ->
    let sent = Eio.Stream.create max_int in
    let inbox = Eio.Stream.create max_int in
    let reported = ref [] in
    let transport : Transport.t = { send = Eio.Stream.add sent; receive = (fun () -> Eio.Stream.take inbox) } in
    let conn =
        Connection.create ~clock:(Eio.Stdenv.clock env)
            ~report:(fun what ex _ -> reported := (what, ex) :: !reported)
            ~render_value:Yojson.Safe.to_string transport
    in
    Fiber.fork_daemon ~sw (fun () ->
        Connection.run conn;
        `Stop_daemon);
    let deliver message =
        Eio.Stream.add inbox (Some message);
        Fiber.yield ()
    in
    let hang_up () =
        Eio.Stream.add inbox None;
        Fiber.yield ()
    in
    f { sw; conn; sent; deliver; hang_up; reported }

let member name (message : Json.t) = match message with `Assoc fields -> List.assoc_opt name fields | _ -> None
let string_member name message = match member name message with Some (`String s) -> s | _ -> Alcotest.failf "no string member %S" name

let create peer ?(parent = "") ~type_ ~guid init =
    peer.deliver
        (`Assoc [ "guid", `String parent; "method", `String "__create__";
                  "params", `Assoc [ "type", `String type_; "guid", `String guid; "initializer", init ] ])

let channel peer guid = match Connection.find peer.conn guid with Some channel -> channel | None -> Alcotest.failf "no object %S" guid

(* Starts a call in a fiber of its own and returns what the client sent for it. *)
let start_call peer channel method_ =
    let reply = Fiber.fork_promise ~sw:peer.sw (fun () -> Connection.call channel method_ (`Assoc [])) in
    let request = Eio.Stream.take peer.sent in
    reply, string_member "id" request

let closed_error what reply =
    match Promise.await reply with
    | Error (Error.E error) ->
        Alcotest.check error_kind (what ^ ": kind") Error.Target_closed error.kind;
        error
    | Error ex -> raise ex
    | Ok _ -> Alcotest.failf "%s: the call should have failed" what

let test_call_and_reply () =
    with_peer @@ fun peer ->
    create peer ~type_:"Page" ~guid:"page@1" (`Assoc []);
    let page = channel peer "page@1" in
    let reply = Fiber.fork_promise ~sw:peer.sw (fun () -> Connection.call ~timeout:1500. page "goto" (`Assoc [ "url", `String "about:blank" ])) in
    let request = Eio.Stream.take peer.sent in
    Alcotest.(check string) "guid" "page@1" (string_member "guid" request);
    Alcotest.(check string) "method" "goto" (string_member "method" request);
    Alcotest.(check (option json)) "params" (Some (`Assoc [ "url", `String "about:blank" ])) (member "params" request);
    Alcotest.(check (option json)) "the timeout travels in the metadata" (Some (`Assoc [ "timeout", `Float 1500. ])) (member "metadata" request);
    peer.deliver (`Assoc [ "id", `String (string_member "id" request); "result", `Assoc [ "ok", `Bool true ] ]);
    Alcotest.check json "result" (`Assoc [ "ok", `Bool true ]) (Promise.await_exn reply);
    (* Ids are unique, and a reply without a result is an empty object. *)
    let second = Fiber.fork_promise ~sw:peer.sw (fun () -> Connection.call page "title" (`Assoc [])) in
    let request' = Eio.Stream.take peer.sent in
    Alcotest.(check bool) "fresh id" true (string_member "id" request <> string_member "id" request');
    Alcotest.(check (option json)) "no timeout, empty metadata" (Some (`Assoc [])) (member "metadata" request');
    peer.deliver (`Assoc [ "id", `String (string_member "id" request') ]);
    Alcotest.check json "empty result" (`Assoc []) (Promise.await_exn second)

let test_error_replies () =
    with_peer @@ fun peer ->
    let root = Connection.root peer.conn in
    let call_failing error extra =
        let reply, id = start_call peer root "m" in
        peer.deliver (`Assoc ([ "id", `String id; "error", error ] @ extra));
        match Promise.await reply with
        | Error (Error.E error) -> error
        | Error ex -> raise ex
        | Ok _ -> Alcotest.fail "expected an error"
    in
    let named name message = `Assoc [ "error", `Assoc [ "name", `String name; "message", `String message; "stack", `String "at x" ] ] in
    let timeout = call_failing (named "TimeoutError" "Timeout 5ms exceeded.") [ "log", `List [ `String "waiting for locator"; `String "  retrying" ] ] in
    Alcotest.check error_kind "timeout kind" Error.Timeout timeout.kind;
    Alcotest.(check (list string)) "log" [ "waiting for locator"; "  retrying" ] timeout.log;
    Alcotest.(check string) "message with call log" "Timeout 5ms exceeded.\nCall log:\nwaiting for locator\n  retrying" timeout.message;
    Alcotest.(check (option string)) "stack" (Some "at x") timeout.stack;
    let closed = call_failing (named "TargetClosedError" "Target page, context or browser has been closed") [] in
    Alcotest.check error_kind "target closed kind" Error.Target_closed closed.kind;
    let other = call_failing (named "Error" "strict mode violation") [ "errorDetails", `Assoc [ "x", `Int 1 ] ] in
    Alcotest.check error_kind "other kind" Error.Other other.kind;
    Alcotest.check json "details" (`Assoc [ "x", `Int 1 ]) other.details;
    (* A page may throw any value, not only errors. *)
    let thrown = call_failing (`Assoc [ "value", `Assoc [ "n", `Int 42 ] ]) [] in
    Alcotest.(check string) "thrown value is rendered" {|{"n":42}|} thrown.message

(* Stands for a client object: what the factory made of an initializer. *)
type Connection.impl += Test_object of string

let test_object_tree () =
    with_peer @@ fun peer ->
    let created = ref [] in
    peer.conn.factory <-
        (fun channel ->
            created := channel.guid :: !created;
            if channel.type_ = "Page" then channel.impl <- Test_object (Yojson.Safe.to_string channel.initializer_));
    create peer ~type_:"Browser" ~guid:"browser@1" (`Assoc [ "name", `String "chromium" ]);
    create peer ~parent:"browser@1" ~type_:"BrowserContext" ~guid:"context@1" (`Assoc []);
    create peer ~parent:"context@1" ~type_:"Page" ~guid:"page@1" (`Assoc [ "title", `String "t" ]);
    create peer ~parent:"page@1" ~type_:"Frame" ~guid:"frame@1" (`Assoc []);
    Alcotest.(check (list string)) "factory sees every object, in order" [ "browser@1"; "context@1"; "page@1"; "frame@1" ] (List.rev !created);
    let browser = channel peer "browser@1" in
    Alcotest.(check string) "type" "Browser" browser.type_;
    Alcotest.check json "initializer" (`Assoc [ "name", `String "chromium" ]) browser.initializer_;
    let page = channel peer "page@1" in
    (match page.impl with
    | Test_object seen -> Alcotest.(check string) "the factory sees the initializer" {|{"title":"t"}|} seen
    | _ -> Alcotest.fail "the client object is kept with its channel");
    Alcotest.check json "which is not kept once a client object has been built from it" `Null page.initializer_;
    let frame = channel peer "frame@1" in
    Alcotest.(check (option string)) "ancestor by type" (Some "context@1")
        (Option.map (fun (c : Connection.channel) -> c.guid) (Connection.parent_of_type frame "BrowserContext"));
    (* Events reach the handler of their object. *)
    let events = ref [] in
    frame.on_event <- (fun name params -> events := (name, params) :: !events);
    peer.deliver (`Assoc [ "guid", `String "frame@1"; "method", `String "navigated"; "params", `Assoc [ "url", `String "x" ] ]);
    Alcotest.(check (list (pair string json))) "event" [ "navigated", `Assoc [ "url", `String "x" ] ] !events;
    (* Adoption moves an object, so that disposing of its old parent spares it. *)
    peer.deliver (`Assoc [ "guid", `String "browser@1"; "method", `String "__adopt__"; "params", `Assoc [ "guid", `String "frame@1" ] ]);
    peer.deliver (`Assoc [ "guid", `String "context@1"; "method", `String "__dispose__"; "params", `Assoc [] ]);
    Alcotest.(check bool) "context is gone" true (Connection.find peer.conn "context@1" = None);
    Alcotest.(check bool) "its page is gone" true (Connection.find peer.conn "page@1" = None);
    Alcotest.(check bool) "the adopted frame stays" true (Connection.find peer.conn "frame@1" <> None);
    Alcotest.(check bool) "the browser stays" true (Connection.find peer.conn "browser@1" <> None);
    (* Objects that the driver collected refuse further calls with an explanation. *)
    peer.deliver (`Assoc [ "guid", `String "frame@1"; "method", `String "__dispose__"; "params", `Assoc [ "reason", `String "gc" ] ]);
    let error = failure "call on a collected object" (fun () -> Connection.call frame "title" (`Assoc [])) in
    check_contains "collected" ~sub:"collected" error.message;
    Alcotest.(check int) "nothing reported" 0 (List.length !(peer.reported));
    Alcotest.(check bool) "still open" false (Connection.is_closed peer.conn)

let test_cancellation_aborts () =
    with_peer @@ fun peer ->
    let root = Connection.root peer.conn in
    Fiber.first
        (fun () -> ignore (Connection.call root "slow" (`Assoc [])))
        (fun () -> ignore (Eio.Stream.take peer.sent : Json.t));
    let request_id = Printf.sprintf "%s@1" peer.conn.id_prefix in
    let abort = Eio.Stream.take peer.sent in
    Alcotest.(check string) "abort" "__abort__" (string_member "method" abort);
    Alcotest.(check (option json)) "names the call" (Some (`String request_id)) (Option.bind (member "params" abort) (member "id"));
    (* The late reply to the cancelled call is dropped silently. *)
    peer.deliver (`Assoc [ "id", `String request_id; "result", `Assoc [] ]);
    Alcotest.(check int) "nothing reported" 0 (List.length !(peer.reported));
    Alcotest.(check bool) "still open" false (Connection.is_closed peer.conn)

let test_closing () =
    with_peer @@ fun peer ->
    let root = Connection.root peer.conn in
    let pending, _ = start_call peer root "wait" in
    peer.hang_up ();
    ignore (closed_error "pending call" pending : Error.t);
    Alcotest.(check bool) "closed" true (Connection.is_closed peer.conn);
    Promise.await (Connection.stopped peer.conn);
    let error = failure "call after close" (fun () -> Connection.call root "more" (`Assoc [])) in
    Alcotest.check error_kind "later calls fail at once" Error.Target_closed error.kind;
    Alcotest.(check bool) "nothing more is sent" true (Eio.Stream.take_nonblocking peer.sent = None)

(* What cannot be understood ends the connection, and with it every call in flight: client and
   driver no longer agree, and nobody may be left waiting for a reply that was thrown away. *)
let test_protocol_failures () =
    let ends_connection what break =
        with_peer @@ fun peer ->
        create peer ~type_:"Page" ~guid:"page@1" (`Assoc []);
        let page = channel peer "page@1" in
        let first, first_id = start_call peer page "first" in
        let second, _ = start_call peer page "second" in
        break peer page first_id;
        let error = closed_error (what ^ ": first call") first in
        check_contains (what ^ ": the error tells why") ~sub:"protocol error" error.message;
        ignore (closed_error (what ^ ": second call") second : Error.t);
        Alcotest.(check bool) (what ^ ": closed") true (Connection.is_closed peer.conn);
        Alcotest.(check int) (what ^ ": reported once") 1 (List.length !(peer.reported));
        Promise.await (Connection.stopped peer.conn)
    in
    ends_connection "malformed error reply" (fun peer _ id ->
        peer.deliver (`Assoc [ "id", `String id; "error", `Assoc [ "error", `Assoc [ "message", `String "boom" ] ]; "log", `String "not a list" ]));
    ends_connection "message without an object" (fun peer _ _ -> peer.deliver (`Assoc [ "method", `String "close" ]));
    ends_connection "message for an unknown object" (fun peer _ _ ->
        peer.deliver (`Assoc [ "guid", `String "nobody@1"; "method", `String "boo"; "params", `Assoc [] ]));
    ends_connection "adoption of an unknown object" (fun peer _ _ ->
        peer.deliver (`Assoc [ "guid", `String "page@1"; "method", `String "__adopt__"; "params", `Assoc [ "guid", `String "nobody@1" ] ]));
    ends_connection "event that its object cannot decode" (fun peer page _ ->
        page.on_event <- (fun _ params -> ignore (Json.Decode.(req "url" string) params : string));
        peer.deliver (`Assoc [ "guid", `String "page@1"; "method", `String "navigated"; "params", `Assoc [] ]));
    ends_connection "object that cannot be built" (fun peer _ _ ->
        peer.conn.factory <- (fun channel -> ignore (Json.Decode.(req "name" string) channel.initializer_ : string));
        create peer ~type_:"Browser" ~guid:"browser@1" (`Assoc []))

(* A transport that fails is the end of the connection as well. *)
let test_transport_failure () =
    Eio_main.run @@ fun env ->
    Switch.run @@ fun sw ->
    let reported = ref 0 in
    let transport : Transport.t = { send = ignore; receive = (fun () -> raise (Transport.Violation "stream ended inside a message")) } in
    let conn = Connection.create ~clock:(Eio.Stdenv.clock env) ~report:(fun _ _ _ -> incr reported) ~render_value:Yojson.Safe.to_string transport in
    let root = Connection.root conn in
    Fiber.fork_daemon ~sw (fun () ->
        Connection.run conn;
        `Stop_daemon);
    Promise.await (Connection.stopped conn);
    let error = failure "call after the failure" (fun () -> Connection.call root "m" (`Assoc [])) in
    Alcotest.check error_kind "kind" Error.Target_closed error.kind;
    check_contains "the error tells why" ~sub:"stream ended inside a message" error.message

(* When the connection ends, every object that still exists is told so, children first, and
   nothing is kept. *)
let test_objects_are_told () =
    with_peer @@ fun peer ->
    let lost = ref [] in
    peer.conn.factory <- (fun channel -> channel.on_lost <- (fun error -> lost := (channel.guid, error.message) :: !lost));
    create peer ~type_:"Browser" ~guid:"browser@1" (`Assoc []);
    create peer ~parent:"browser@1" ~type_:"BrowserContext" ~guid:"context@1" (`Assoc []);
    create peer ~parent:"context@1" ~type_:"Page" ~guid:"page@1" (`Assoc []);
    create peer ~parent:"page@1" ~type_:"Frame" ~guid:"frame@1" (`Assoc []);
    create peer ~parent:"context@1" ~type_:"Page" ~guid:"page@2" (`Assoc []);
    create peer ~parent:"page@2" ~type_:"Frame" ~guid:"frame@2" (`Assoc []);
    create peer ~parent:"page@1" ~type_:"Worker" ~guid:"worker@1" (`Assoc []);
    create peer ~parent:"browser@1" ~type_:"BrowserContext" ~guid:"context@2" (`Assoc []);
    create peer ~parent:"context@1" ~type_:"Page" ~guid:"page@3" (`Assoc []);
    peer.deliver (`Assoc [ "guid", `String "page@3"; "method", `String "__dispose__"; "params", `Assoc [] ]);
    let page = channel peer "page@1" in
    let browser = channel peer "browser@1" in
    Connection.close peer.conn (Error.target_closed ~message:"over" ());
    Alcotest.(check (list string)) "bottom up, in order of creation; not the objects that were disposed of before"
        [ "frame@1"; "worker@1"; "page@1"; "frame@2"; "page@2"; "context@1"; "context@2"; "browser@1" ]
        (List.rev_map fst !lost);
    Alcotest.(check bool) "with the reason" true (List.for_all (fun (_, message) -> message = "over") !lost);
    Alcotest.(check bool) "objects are forgotten" true (Connection.find peer.conn "page@1" = None && Connection.find peer.conn "" = None);
    Alcotest.(check int) "all of them" 0 (Hashtbl.length peer.conn.objects);
    Alcotest.(check bool) "and marked" true (page.disposed && browser.disposed);
    Alcotest.(check int) "and let go of their children" 0 (Hashtbl.length browser.children);
    (* Closing again changes nothing. *)
    Connection.close peer.conn (Error.target_closed ~message:"again" ());
    Alcotest.(check int) "told once" 8 (List.length !lost);
    let error = failure "call after close" (fun () -> Connection.call page "title" (`Assoc [])) in
    Alcotest.(check string) "the first reason stays" "over" error.message

(* Handlers run in the scope of the connection: they start in order, and end with it. *)
let test_handler_scope () =
    with_peer @@ fun peer ->
    let log = ref [] in
    let note what = log := what :: !log in
    let handler name =
        Connection.fork peer.conn "handler" (fun () ->
            note (name ^ " starts");
            try Fiber.await_cancel () with ex -> note (name ^ " is cancelled"); raise ex)
    in
    handler "a";
    handler "b";
    Connection.fork peer.conn "handler" (fun () -> failwith "broken handler");
    Alcotest.(check (list string)) "handlers start at once, in order" [ "a starts"; "b starts" ] (List.rev !log);
    (match !(peer.reported) with
    | [ ("handler", Failure message) ] -> Alcotest.(check string) "a failing handler is reported" "broken handler" message
    | _ -> Alcotest.fail "the failure of a handler should have been reported, once");
    Alcotest.(check bool) "and does not end the connection" false (Connection.is_closed peer.conn);
    (* An object that is lost may start handlers: they are the last ones. *)
    create peer ~type_:"Page" ~guid:"page@1" (`Assoc []);
    (channel peer "page@1").on_lost <-
        (fun _ ->
            Connection.fork peer.conn "handler" (fun () ->
                note "close handler starts";
                try Fiber.await_cancel () with ex -> note "close handler is cancelled"; raise ex));
    log := [];
    Connection.close peer.conn (Error.target_closed ());
    Alcotest.(check (list string)) "started while closing" [ "close handler starts" ] !log;
    Promise.await (Connection.stopped peer.conn);
    Alcotest.(check (list string)) "all handlers are over once the connection has stopped"
        [ "a is cancelled"; "b is cancelled"; "close handler is cancelled"; "close handler starts" ]
        (List.sort compare !log);
    Connection.fork peer.conn "handler" (fun () -> note "too late");
    Alcotest.(check bool) "nothing is started afterwards" false (List.mem "too late" !log)

(* A handler may close the connection that it runs for, and wait for that. *)
let test_closing_from_a_handler () =
    with_peer @@ fun peer ->
    let outcome = ref "pending" in
    Connection.fork peer.conn "handler" (fun () ->
        Fiber.yield ();
        Connection.close peer.conn (Error.target_closed ());
        match Promise.await (Connection.stopped peer.conn) with
        | () -> outcome := "returned"
        | exception (Eio.Cancel.Cancelled _ as ex) ->
            outcome := "cancelled";
            raise ex);
    Promise.await (Connection.stopped peer.conn);
    Alcotest.(check string) "the handler is cancelled where it waits" "cancelled" !outcome;
    Alcotest.(check int) "nothing reported" 0 (List.length !(peer.reported))

(* A connection that is relayed by another one lives in the scope of that one. *)
let test_relayed_connection () =
    with_peer @@ fun peer ->
    let inbox = Eio.Stream.create max_int in
    let relayed = Connection.create_relayed peer.conn { send = ignore; receive = (fun () -> Eio.Stream.take inbox) } in
    Connection.fork peer.conn "relayed connection" (fun () -> Connection.run relayed);
    let log = ref [] in
    Connection.fork relayed "handler" (fun () ->
        log := "starts" :: !log;
        try Fiber.await_cancel () with ex -> log := "cancelled" :: !log; raise ex);
    (* Its end is not the end of the scope. *)
    Eio.Stream.add inbox None;
    Promise.await (Connection.stopped relayed);
    Alcotest.(check bool) "closed" true (Connection.is_closed relayed);
    Alcotest.(check (list string)) "its handlers go on" [ "starts" ] !log;
    Connection.close peer.conn (Error.target_closed ());
    Promise.await (Connection.stopped peer.conn);
    Alcotest.(check (list string)) "until the connection that relays it ends" [ "cancelled"; "starts" ] !log

let test_with_timeout () =
    with_peer @@ fun peer ->
    Alcotest.(check int) "in time" 1 (Connection.with_timeout peer.conn ~timeout:1000. ~message:(fun () -> "late") (fun () -> 1));
    Alcotest.(check int) "zero means no timeout" 2 (Connection.with_timeout peer.conn ~timeout:0. ~message:(fun () -> "late") (fun () -> 2));
    let error =
        failure "timeout" (fun () ->
            Connection.with_timeout peer.conn ~timeout:20. ~message:(fun () -> "too late") (fun () -> Fiber.await_cancel ()))
    in
    Alcotest.check error_kind "kind" Error.Timeout error.kind;
    Alcotest.(check string) "message" "too late" error.message

let tests =
    [ "json", [ Alcotest.test_case "encoding" `Quick test_json_encoding; Alcotest.test_case "decoding" `Quick test_json_decoding ];
      "transport",
      [ Alcotest.test_case "framing roundtrip" `Quick test_framing_roundtrip; Alcotest.test_case "violations" `Quick test_framing_violations ];
      "connection",
      [ Alcotest.test_case "call and reply" `Quick test_call_and_reply;
        Alcotest.test_case "error replies" `Quick test_error_replies;
        Alcotest.test_case "object tree" `Quick test_object_tree;
        Alcotest.test_case "cancellation aborts the call" `Quick test_cancellation_aborts;
        Alcotest.test_case "closing" `Quick test_closing;
        Alcotest.test_case "protocol failures" `Quick test_protocol_failures;
        Alcotest.test_case "transport failure" `Quick test_transport_failure;
        Alcotest.test_case "objects are told of the end" `Quick test_objects_are_told;
        Alcotest.test_case "handler scope" `Quick test_handler_scope;
        Alcotest.test_case "closing from a handler" `Quick test_closing_from_a_handler;
        Alcotest.test_case "relayed connection" `Quick test_relayed_connection;
        Alcotest.test_case "with_timeout" `Quick test_with_timeout ] ]
