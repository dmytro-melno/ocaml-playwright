(* Creates the client object behind each object that the driver announces. *)

open Types

let devices (channel : Channel.t) : device list =
    let init = Protocol.Local_utils.Initializer.of_json channel.conn channel.initializer_ in
    List.map
        (fun (device : Protocol.Local_utils.Initializer_device_descriptors.t) ->
            let d = device.descriptor in
            { device_name = device.name; device_user_agent = d.user_agent;
              device_viewport = { width = d.viewport.width; height = d.viewport.height };
              device_screen = Option.map (fun (s : Protocol.Local_utils.Initializer_device_descriptors_descriptor_screen.t) -> { width = s.width; height = s.height }) d.screen;
              device_scale_factor = d.device_scale_factor; device_is_mobile = d.is_mobile; device_has_touch = d.has_touch;
              default_browser_type = d.default_browser_type })
        init.device_descriptors

let constructors : (string * (session -> Channel.t -> unit)) list =
    [ Protocol.Browser_type.type_name, Browser_type.create;
      Protocol.Browser.type_name, Browser.create;
      Protocol.Browser_context.type_name, Browser_context.create;
      Protocol.Page.type_name, (fun _ -> Page.create);
      Protocol.Frame.type_name, Frame.create;
      Protocol.Js_handle.type_name, Js_handle.create;
      Protocol.Element_handle.type_name, Js_handle.create;
      Protocol.Request.type_name, (fun _ -> Network.Request.create);
      Protocol.Response.type_name, (fun _ -> Network.Response.create);
      Protocol.Route.type_name, (fun _ -> Route.create);
      Protocol.Web_socket.type_name, (fun _ -> Network.Web_socket.create);
      Protocol.Web_socket_route.type_name, (fun _ -> Route.Web_socket.create);
      Protocol.Worker.type_name, Worker.create;
      Protocol.Dialog.type_name, (fun _ -> Dialog.create);
      Protocol.Tracing.type_name, Tracing.create;
      Protocol.Api_request_context.type_name, Api_request.Context.create;
      Protocol.Cdp_session.type_name, (fun _ -> Cdp_session.create);
      Protocol.Json_pipe.type_name, (fun _ -> Json_pipe.create);
      ( Protocol.Local_utils.type_name,
        fun session channel ->
            (* Local files are worked on by the local driver, also on behalf of a remote session. *)
            if session.local_utils = None then begin
                session.local_utils <- Some channel;
                session.devices <- devices channel
            end ) ]

(* Objects of the remaining types (artifacts, streams, binding calls, ...) carry no client-side
   state and are used through their channels. *)
let create (session : session) (channel : Channel.t) =
    match List.assoc_opt channel.type_ constructors with
    | Some construct -> construct session channel
    | None -> ()

(* [parent] is the session of the local driver, for the session of a connection to a Playwright
   server that was made through it. *)
let new_session ?parent conn : session =
    let session =
        match parent with
        | Some (parent : session) -> { parent with conn; is_remote = true }
        | None ->
            { conn; is_remote = false; local_utils = None;
              selectors = { test_id_attribute = Browser.default_test_id_attribute; selector_engines = []; all_contexts = [] };
              url_matchers = Hashtbl.create 16; devices = [] }
    in
    conn.factory <- create session;
    session
