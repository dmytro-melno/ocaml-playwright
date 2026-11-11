(* Browsers behind a Playwright server.

   The server speaks the protocol of the driver, so a remote browser is reached through a second
   connection with an object tree of its own.  The local driver holds the WebSocket to the server
   and relays the messages through a {!Json_pipe}. *)

open Eio.Std
open Types

(* What the server would have announced, had it had the time: its pages, contexts and browser are gone. *)
let emulate_close (browser : browser) =
    let closed = `Assoc [] in
    List.iter
        (fun (context : browser_context) ->
            List.iter (fun page -> Page.handle_event page "close" closed) (Browser_context.pages context);
            Browser_context.handle_event context "close" closed)
        (Browser.contexts browser);
    if Browser.is_connected browser then Browser.handle_event browser "close" closed

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
    let browser = ref None in
    let conn =
        Connection.create ~sw:local.conn.sw ~clock:local.conn.clock ~report:local.conn.report ?trace:local.conn.trace
            ~render_value:local.conn.render_value
            (Json_pipe.transport ~on_end:(fun () -> Option.iter emulate_close !browser) pipe)
    in
    ignore (Objects.new_session ~parent:local conn);
    Fiber.fork_daemon ~sw:local.conn.sw (fun () ->
        Connection.run ~end_message:(fun () -> Option.value pipe.close_reason ~default:Error.target_closed_message) conn;
        `Stop_daemon);
    let disconnect () =
        Json_pipe.close pipe;
        Fiber.first (fun () -> Promise.await (Connection.stopped conn)) (fun () -> ignore (Promise.await (Connection.closed local.conn)))
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
        browser := Some connected;
        Browser_type.adopt t connected;
        connected.disconnect <- Some disconnect;
        (* A browser that the server has closed leaves nothing to stay connected to. *)
        let (_ : unit -> unit) =
            Emitter.subscribe connected.e_disconnected (fun _ -> Connection.fork local.conn "disconnecting" (fun () -> Json_pipe.close pipe))
        in
        connected
    | exception ex ->
        let backtrace = Printexc.get_raw_backtrace () in
        Fiber.fork_daemon ~sw:local.conn.sw (fun () ->
            disconnect ();
            `Stop_daemon);
        Printexc.raise_with_backtrace ex backtrace
