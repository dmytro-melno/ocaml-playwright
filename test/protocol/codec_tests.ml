open Playwright

let check name condition = if not condition then failwith ("ASSERTION FAILED: " ^ name)
let test name f = f (); Printf.printf "PASS protocol %s\n%!" name
let get = function Ok x -> x | Error e -> failwith e
let error = function Result.Error _ -> true | Ok _ -> false
let edges = [""; "\000"; "\255\128\000Hello\r\n"; String.init 256 Char.chr]
let wire bytes = `String (Base64.encode_exn bytes)
let packet bytes : Fixture.Packet.t =
    { text = "SGVsbG8="; data = bytes; maybe = Some bytes;
      nested = {entries = [|{data = bytes; text = "ordinary string"}|]} }
let packet_json bytes =
    `Assoc ["text", `String "SGVsbG8="; "data", wire bytes; "maybe", wire bytes;
        "nested", `Assoc ["entries", `List [`Assoc ["data", wire bytes; "text", `String "ordinary string"]]]]

(* These annotations are deliberately compiled, not inferred from one collided type. *)
let _subscription : BrowserContext.UpdateSubscriptionParams_Event.t = `Console
let _recorder : BrowserContext.EnableRecorderParams_Mode.t = `Recording
let _attached : ElementHandle.WaitForSelectorParams_State.t = `Attached
let _detached : ElementHandle.WaitForSelectorParams_State.t = `Detached
let _enabled : ElementHandle.WaitForElementStateParams_State.t = `Enabled
let _css : Page.StopCSSCoverageResult_Entries_Ranges.t = {start=0;end_=4}
let _js : Page.StopJSCoverageResult_Entries_Functions_Ranges.t = {start_offset=0;end_offset=4;count=1}
let _alpha : Fixture.Root.AlphaParams_Options_Entries.t = {data="\255"; state=`One}
let _beta : Fixture.Root.BetaParams_Options_Entries.t = {data="plain"; state=`Three}
let _alpha_result : Fixture.Root.AlphaResult_Options_Entries_Ranges.t = {start=0;end_=1}
let _beta_result : Fixture.Root.BetaResult_Options_Entries_Ranges.t = {offset=0.;count=1}
let _identical_a : Fixture.Root.IdenticalAParams_Options.t = {state=`Same}
let _identical_b : Fixture.Root.IdenticalBParams_Options.t = {state=`Same}

let pure () =
    test "binary leaf exact bytes, canonical errors and raw string alias" (fun () ->
        List.iter (fun bytes ->
            check "encode" (Binary.to_yojson bytes = wire bytes);
            check "decode" (get (Binary.of_yojson (wire bytes)) = bytes)) edges;
        List.iter (fun encoded -> check ("invalid " ^ encoded) (error (Binary.of_yojson (`String encoded))))
            ["!"; "Zg"; "Zg="; "Zg==="; "Zg==junk"; "Zh=="; " Zg=="; "Zg==\n"; "____"];
        check "wrong JSON type" (error (Binary.of_yojson (`Int 1))));
    test "recursive records, optionals, arrays, events and initializers" (fun () ->
        List.iter (fun bytes ->
            let p = packet bytes in
            check "recursive encode" (Fixture.Packet.to_yojson p = packet_json bytes);
            check "recursive decode" (get (Fixture.Packet.of_yojson (packet_json bytes)) = p);
            let init = `Assoc ["data",wire bytes;"packet",packet_json bytes;"entries",`List [wire "";wire bytes]] in
            let decoded = get (Fixture.Root.Initializer.of_yojson init) in
            check "initializer" (decoded.data = bytes && decoded.maybe = None && decoded.packet = p && decoded.entries = [|"";bytes|]);
            let encoded = Fixture.Root.Initializer.to_yojson decoded in
            check "initializer re-encode" (Yojson.Safe.Util.member "data" encoded = wire bytes &&
                Yojson.Safe.Util.member "entries" encoded = `List [wire "";wire bytes]);
            let event = get (Fixture.Root.SampleEvent.of_yojson (`Assoc [
                "data",wire bytes;"packet",packet_json bytes;"options",`Assoc ["data",wire bytes]])) in
            check "event binary" (event.data = bytes && event.packet = p && event.options.data = Some bytes);
            let encoded = Fixture.Root.SampleEvent.to_yojson event in
            check "event re-encode" (Yojson.Safe.Util.member "data" encoded = wire bytes &&
                Yojson.Safe.Util.member "packet" encoded = packet_json bytes);
            let result = get (Page.ExpectScreenshotResult.of_yojson (`Assoc ["actual",wire bytes;"diff",wire bytes])) in
            check "multi result" (result.actual = Some bytes && result.diff = Some bytes && result.previous = None);
            let upload : FormField.File.t = {name="file";mime_type=None;buffer=bytes} in
            check "multipart leaf" (Yojson.Safe.Util.member "buffer" (FormField.File.to_yojson upload) = wire bytes)
        ) edges;
        check "invalid nested optional" (error (Fixture.Packet.of_yojson (`Assoc [
            "text",`String "plain";"data",wire "";"maybe",`String "@@";"nested",`Assoc ["entries",`List []]])));
        let invalid_packet = `Assoc ["text",`String "plain";"data",wire "";
            "nested",`Assoc ["entries",`List [`Assoc ["data",`String "@@";"text",`String "ok"]]]] in
        check "invalid array element" (error (Fixture.Packet.of_yojson invalid_packet));
        check "invalid event" (error (Fixture.Root.SampleEvent.of_yojson (`Assoc [
            "data",wire "";"packet",packet_json "";"options",`Assoc ["data",`String "@@"]]))));
    test "exact enum encoding/decoding and incompatible values rejected" (fun () ->
        List.iter (fun (tag,literal) ->
            check literal (SerializedValue.V.to_yojson tag = `String literal);
            check literal (get (SerializedValue.V.of_yojson (`String literal)) = tag);
            let value = get (SerializedValue.of_yojson (`Assoc ["v",`String literal])) in
            check "wire round trip" (Yojson.Safe.Util.member "v" (SerializedValue.to_yojson value) = `String literal))
            [`Nan,"NaN";`Infinity,"Infinity";`Minus_infinity,"-Infinity";`Minus_zero,"-0";`Null,"null";`Undefined,"undefined"];
        List.iter (fun literal -> check "old spelling rejected" (error (SerializedValue.V.of_yojson (`String literal)))) ["nan";"inf";"-inf"];
        check "no actionAdded subscription" (error (BrowserContext.UpdateSubscriptionParams_Event.of_yojson (`String "actionAdded")));
        check "no enabled selector state" (error (ElementHandle.WaitForSelectorParams_State.of_yojson (`String "enabled")));
        check "attached" (get (ElementHandle.WaitForSelectorParams_State.of_yojson (`String "attached")) = `Attached);
        check "detached" (get (ElementHandle.WaitForSelectorParams_State.of_yojson (`String "detached")) = `Detached))

let wire_call result call =
    Eio.Switch.run (fun sw ->
        let output = Buffer.create 128 in
        let conn = Connection.create (Eio.Flow.string_source "") (Eio.Flow.buffer_sink output) in
        Fun.protect ~finally:(fun () -> Connection.close conn "fixture finished") (fun () ->
            let pending = Eio.Fiber.fork_promise ~sw (fun () -> call (Fixture.Internal.create_root conn)) in
            while Hashtbl.length conn.callbacks = 0 do Eio.Fiber.yield () done;
            Connection.dispatch conn (`Assoc ["id",`Int conn.last_id;"result",result]);
            let response = Eio.Promise.await_exn pending in
            let sent = Transport.read_message (Eio.Flow.string_source (Buffer.contents output)) |> Option.get |> Yojson.Safe.from_string in
            response, Yojson.Safe.Util.member "params" sent))

let commands () =
    test "generated direct/optional/array parameters and multi-result codecs on wire" (fun () ->
        List.iter (fun bytes ->
            let p = packet bytes in
            let reply = `Assoc ["data",wire bytes;"maybe",wire bytes;"entries",`List [wire "";`Null;wire bytes];"packet",packet_json bytes] in
            let result, params = wire_call reply (Fixture.Root.echo ~data:bytes ~maybe:bytes ~entries:[|Some "";None;Some bytes|] ~packet:p) in
            check "parameter recursion" (params = reply);
            check "multi result recursion" (result.data = bytes && result.maybe = Some bytes && result.entries = [|Some "";None;Some bytes|] && result.packet = p);
            let reply = `Assoc ["data",wire bytes;"entries",`List [];"packet",packet_json bytes] in
            let result, params = wire_call reply (Fixture.Root.echo ~data:bytes ~entries:[||] ~packet:p) in
            check "absent optional omitted" (params = reply && result.maybe = None);
            let result, _ = wire_call (`Assoc ["entries",`List [wire bytes;`Null;wire ""]]) Fixture.Root.single in
            check "single optional array of optional binary" (result = Some [|Some bytes;None;Some ""|]);
            let result, _ = wire_call (`Assoc []) Fixture.Root.single in
            check "missing optional result" (result = None)
        ) edges);
    test "invalid wire binary result fails observably" (fun () ->
        match wire_call (`Assoc ["entries",`List [`String "@@"]]) Fixture.Root.single with
        | _ -> failwith "invalid Base64 was accepted"
        | exception Failure message -> check "binary diagnostic" (String.starts_with ~prefix:"binary:" message))

let () =
    pure ();
    Eio_main.run (fun env ->
        Eio.Time.with_timeout_exn (Eio.Stdenv.clock env) 5. commands)
