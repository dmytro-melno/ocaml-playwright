(* Creates the client object behind each object that the driver announces. *)

open Types

let devices (channel : Protocol.Local_utils.t) : device list =
    let init = Protocol.Local_utils.initializer_ channel in
    List.map
        (fun (device : Protocol.Local_utils.Initializer_device_descriptors.t) ->
            let d = device.descriptor in
            { device_name = device.name; device_user_agent = d.user_agent;
              device_viewport = { width = d.viewport.width; height = d.viewport.height };
              device_screen = Option.map (fun (s : Protocol.Local_utils.Initializer_device_descriptors_descriptor_screen.t) -> { width = s.width; height = s.height }) d.screen;
              device_scale_factor = d.device_scale_factor; device_is_mobile = d.is_mobile; device_has_touch = d.has_touch;
              default_browser_type = d.default_browser_type })
        init.device_descriptors

(* The match is on every interface of the protocol, so that a new one cannot go unnoticed.
   What {!Types} relies on is here: an object of an interface that has a client side gets it. *)
let create (session : session) (channel : Channel.any) : Connection.impl =
    match Protocol.Object.of_channel channel with
    | Browser_type channel -> Browser_type (Browser_type.create session channel)
    | Browser channel -> Browser (Browser.create session channel)
    | Browser_context channel -> Browser_context (Browser_context.create session channel)
    | Page channel -> Page (Page.create channel)
    | Frame channel -> Frame (Frame.create session channel)
    | Js_handle channel -> Js_handle (Js_handle.create session channel)
    | Element_handle channel -> Js_handle (Js_handle.create session (channel :> Protocol.Js_handle.t))
    | Request channel -> Request (Network.Request.create channel)
    | Response channel -> Response (Network.Response.create channel)
    | Route channel -> Route (Route.create channel)
    | Web_socket channel -> Web_socket (Network.Web_socket.create channel)
    | Web_socket_route channel -> Web_socket_route (Route.Web_socket.create channel)
    | Worker channel -> Worker (Worker.create session channel)
    | Dialog channel -> Dialog (Dialog.create channel)
    | Tracing channel -> Tracing (Tracing.create session channel)
    | Api_request_context channel -> Api_request_context (Api_request.Context.create session channel)
    | Cdp_session channel -> Cdp_session (Cdp_session.create channel)
    | Json_pipe channel -> Json_pipe.Json_pipe (Json_pipe.create channel)
    | Local_utils channel ->
        (* Local files are worked on by the local driver, also on behalf of a remote session. *)
        if session.local_utils = None then begin
            session.local_utils <- Some channel;
            session.devices <- devices channel
        end;
        Connection.No_impl
    (* These carry no state on the client side and are used through their channels. *)
    | Root _ | Playwright _ | Artifact _ | Stream _ | Writable_stream _ | Binding_call _ | Disposable _ | Debugger _ | Other _ -> Connection.No_impl

(* [parent] is the session of the local driver, for the session of a connection to a Playwright
   server that was made through it. *)
let new_session ?parent conn : session =
    let session =
        match parent with
        | Some (parent : session) -> { parent with conn; is_remote = true }
        | None ->
            { conn; is_remote = false; local_utils = None;
              selectors = { test_id_attribute = Browser.default_test_id_attribute; selector_engines = []; all_contexts = [] };
              devices = []; assertions = { assertion_timeout = 5_000. } }
    in
    conn.factory <- create session;
    session

(* The first exchange over a connection.  It gives the object that all the others are reached
   from. *)
let initialize conn : Protocol.Playwright.t =
    match Protocol.Object.of_channel (Connection.root conn) with
    | Root root -> Protocol.Root.initialize ~sdk_language:`Python root
    | _ -> Error.raise_ "Internal error: the connection has no root object"
