open Generator_test

let check name condition = if not condition then failwith ("ASSERTION FAILED: " ^ name)
let test name f = f (); Printf.printf "PASS protocol %s\n%!" name
let parse path = Parser.parse (In_channel.with_open_text path In_channel.input_all)
let render renderer root = let buffer = Buffer.create 1024 in renderer root buffer; Buffer.contents buffer
let contains text part = Re.execp (Re.compile (Re.str part)) text
let fails_with expected f =
    match f () with
    | _ -> failwith ("expected failure: " ^ expected)
    | exception Failure error -> check error (contains error expected)

let () =
    test "version authority and complete schema surface" (fun () ->
        let manifest = Yojson.Safe.from_file "../../protocol/provenance.json" in
        let open Yojson.Safe.Util in
        check "driver is pinned" (Playwright.Driver.version = "1.59.1");
        check "manifest agrees" (member "version" manifest = `String Playwright.Driver.version);
        let root = parse "../../protocol/protocol.yml" in
        let iface name = List.assoc name root.Types.interfaces in
        let command owner name = List.find (fun (c : Types.command) -> c.name = name) (iface owner).commands in
        let has owner name = List.exists (fun (c : Types.command) -> c.name = name) (iface owner).commands in
        let param owner method_ field = List.assoc field (command owner method_).parameters.properties in
        let init owner field = List.assoc field (Option.get (iface owner).initializer_).properties in
        check "all upstream interfaces" (List.length root.interfaces = 35);
        check "electron root initializer" (init "Playwright" "electron" = Types.TypeRef "Electron");
        check "electron interfaces" (has "Electron" "launch" && has "ElectronApplication" "browserWindow");
        check "HAR owner" (has "BrowserContext" "harStart" && has "BrowserContext" "harExport" && not (has "Tracing" "harStart") && not (has "Tracing" "harExport"));
        check "transport connect replacement" (has "BrowserType" "connectOverCDPTransport" && not (has "BrowserType" "connectToWorker"));
        check "assistant mode" (param "BrowserType" "launch" "assistantMode" = Types.Optional Types.BooleanType);
        check "CDP noDefaults removed" (not (List.mem_assoc "noDefaults" (command "BrowserType" "connectOverCDP").parameters.properties));
        check "binding optional args" (init "BindingCall" "args" = Types.Optional (Types.ArrayType {of_type=Types.TypeRef "SerializedValue"}));
        check "binding handle" (init "BindingCall" "handle" = Types.Optional (Types.TypeRef "JSHandle"));
        List.iter (fun owner -> check (owner ^ " needsHandle") (param owner "exposeBinding" "needsHandle" = Types.Optional Types.BooleanType)) ["Page";"BrowserContext"];
        check "received is SerializedValue" (List.assoc "received" (command "Frame" "expect").returns.properties = Types.Optional (Types.TypeRef "SerializedValue"));
        let page_error = List.find (fun (e : Types.event) -> e.name = "pageError") (iface "BrowserContext").events in
        check "page error actual fields" (page_error.parameters.properties = ["error",Types.TypeRef "SerializedError";"page",Types.TypeRef "Page"]);
        List.iter (fun (owner,method_) -> check (owner ^ "." ^ method_ ^ " absent") (not (has owner method_)))
            ["Page","hideHighlight";"Frame","ariaRef";"Frame","drop";"Frame","hideHighlight";"Worker","disconnect"];
        check "worker console removed" (not (List.exists (fun (e : Types.event) -> e.name = "console") (iface "Worker").events));
        check "websocket route protocols removed" (not (List.mem_assoc "protocols" (Option.get (iface "WebSocketRoute").initializer_).properties));
        List.iter (fun (method_,field) -> check (method_ ^ "." ^ field ^ " removed") (not (List.mem_assoc field (command "Frame" method_).parameters.properties)))
            ["ariaSnapshot","boxes";"highlight","style";"expect","pseudo"];
        check "highlight title metadata" ((command "Frame" "highlight").title = Some "Highlight element");
        check "highlight only selector" ((command "Frame" "highlight").parameters.properties = ["selector", Types.StringType]));
    test "deterministic full and synthetic implementations/signatures" (fun () ->
        List.iter (fun path ->
            let a = parse path and b = parse path in
            List.iter (fun renderer -> check ("determinism " ^ path) (render renderer a = render renderer b))
                [Render.Mod.render; Render.Sig.render]
        ) ["../../protocol/protocol.yml"; "fixture.yml"]);
    test "synthetic object/array/enum path isolation" (fun () ->
        let text = render Render.Sig.render (parse "fixture.yml") in
        List.iter (fun path -> check path (contains text path))
            ["AlphaParams_Options_Entries_State"; "BetaParams_Options_Entries_State";
             "AlphaResult_Options_Entries_Ranges"; "BetaResult_Options_Entries_Ranges";
             "IdenticalAParams_Options_State"; "IdenticalBParams_Options_State";
             "Initializer"; "SampleEvent_Options"]);
    test "structural interning rejects conflicts and accepts identical definitions" (fun () ->
        let seen = ref [] in
        let a = "Name","string","string" in
        check "first" (Render.unique_defs ~scope:"Fixture.command.field" seen [a] = [a]);
        check "identical" (Render.unique_defs ~scope:"Fixture.command.field" seen [a] = []);
        fails_with "Fixture.command.field.Name" (fun () -> Render.unique_defs ~scope:"Fixture.command.field" seen ["Name","int","int"]);
        fails_with "Incompatible" (fun () -> Render.unique_defs ~scope:"Fixture" seen ["Name","string","different codec"]));
    test "ambiguous normalized names fail with context" (fun () ->
        let render_yaml yaml = Parser.parse yaml |> render Render.Mod.render in
        fails_with "record" (fun () -> render_yaml "Root:\n  type: interface\n  initializer:\n    foo-bar: string\n    foo_bar: int\n");
        fails_with "enum literals" (fun () -> render_yaml "Root:\n  type: interface\n  initializer:\n    state:\n      type: enum\n      literals: [foo-bar, foo_bar]\n");
        fails_with "Root commands" (fun () -> render_yaml "Root:\n  type: interface\n  commands:\n    fooBar:\n    foo_bar:\n");
        fails_with "duplicate mapping key" (fun () -> render_yaml "Root:\n  type: interface\n  type: object\n");
        fails_with "protocol modules" (fun () -> render_yaml "Binary:\n  type: interface\n");
        fails_with "Wrap" (fun () -> render_yaml "Packet:\n  type: object\n  properties:\n    wrap:\n      type: enum\n      literals: [a,b]\nRoot:\n  type: interface\n");
        fails_with "Root functions" (fun () -> render_yaml "Root:\n  type: interface\n  events:\n    data:\n  commands:\n    onData:\n");
        fails_with "Packet.Binary" (fun () -> render_yaml "Packet:\n  type: object\n  properties:\n    data: binary\n    binary:\n      type: enum\n      literals: [a,b]\nRoot:\n  type: interface\n");
        fails_with "reserved outer module FooParams_Options" (fun () -> render_yaml "FooParams_Options:\n  type: enum\n  literals: [a,b]\nRoot:\n  type: interface\n  commands:\n    foo:\n      parameters:\n        options:\n          type: enum\n          literals: [a,b]\n");
        fails_with "Invalid generated identifier" (fun () -> render_yaml "Root:\n  type: interface\n  initializer:\n    1field: string\n"));
    test "lexical YAML enums include exact special values" (fun () ->
        let text = render Render.Mod.render (parse "../../protocol/protocol.yml") in
        List.iter (fun (tag,wire) -> check wire (contains text (Printf.sprintf "| `%s -> `String %S" tag wire)))
            ["Nan","NaN";"Infinity","Infinity";"Minus_infinity","-Infinity";"Minus_zero","-0"];
        let special = Parser.lexical_yaml "literals: [NaN, Infinity, -Infinity, -0, null, true, 1.0, 01]\n" in
        check "no scalar coercion" (special = `O ["literals",`A (List.map (fun x -> `String x) ["NaN";"Infinity";"-Infinity";"-0";"null";"true";"1.0";"01"])]))
