(* Browsers behind a Playwright server.

   The server speaks the protocol of the driver, so a remote browser is reached through a second
   connection with an object tree of its own.  The local driver holds the WebSocket to the server
   and relays the messages through a {!Json_pipe}.

   The remote connection ends with the pipe: when the browser is closed here, when the server
   goes away, and when the connection to the driver ends.  Each time, the objects of the remote
   connection are told that they are lost, so the browser reports that it is disconnected and
   its contexts and pages that they are closed. *)

open Types

let connect ?(timeout = 0.) ?(headers = []) ?slow_mo ?expose_network endpoint (t : browser_type) : browser =
    let local = t.bt_session in
    let headers =
        let is_browser_header (name, _) = String.lowercase_ascii name = "x-playwright-browser" in
        if List.exists is_browser_header headers then headers else ("x-playwright-browser", t.bt_name) :: headers
    in
    let result =
        Protocol.Local_utils.connect ~timeout ~endpoint
            ~headers:(`Assoc (List.map (fun (name, value) -> name, `String value) headers))
            ?expose_network ?slow_mo (Url_match.local_utils local)
    in
    let pipe = Json_pipe.of_channel result.pipe in
    let conn = Connection.create_relayed local.conn (Json_pipe.transport pipe) in
    let ended () = Error.target_closed ?message:pipe.close_reason () in
    (* Nothing more can arrive once the driver is gone, so there is no point in waiting for the
       reader to find out. *)
    pipe.on_lost <- (fun _ -> Connection.close conn (ended ()));
    ignore (Objects.new_session ~parent:local conn);
    Connection.fork local.conn "remote connection" (fun () -> Connection.run ~end_message:(fun () -> (ended ()).message) conn);
    let disconnect () =
        Json_pipe.close pipe;
        Connection.close conn (ended ())
    in
    match
        Connection.with_timeout conn ~timeout
            ~message:(fun () -> Printf.sprintf "Timeout %gms exceeded while connecting to %s" timeout endpoint)
            (fun () ->
                let playwright = Protocol.Root.initialize ~sdk_language:`Python (Connection.root conn) in
                let init = Protocol.Playwright.Initializer.of_json conn playwright.initializer_ in
                match init.pre_launched_browser with
                | Some channel -> Types.browser channel
                | None -> Error.raise_ "Malformed endpoint. Did you use BrowserType.launchServer method?")
    with
    | connected ->
        Browser_type.adopt t connected;
        connected.disconnect <- Some disconnect;
        (* A browser that the server has closed leaves nothing to stay connected to. *)
        let (_ : unit -> unit) = Emitter.subscribe connected.e_disconnected (fun _ -> Connection.fork local.conn "disconnecting" disconnect) in
        connected
    | exception ex ->
        let backtrace = Printexc.get_raw_backtrace () in
        Connection.fork local.conn "disconnecting" disconnect;
        Printexc.raise_with_backtrace ex backtrace
