(* Network interception: routes, the handlers that decide their fate, and exposed bindings. *)

open Eio.Std
open Types
open Network

type t = route

let equal (a : t) (b : t) = Channel.equal a.rt_channel b.rt_channel
let compare (a : t) (b : t) = Channel.compare a.rt_channel b.rt_channel
let hash (t : t) = Channel.hash t.rt_channel

let create (channel : Protocol.Route.t) : t =
    let init = Protocol.Route.initializer_ channel in
    { rt_channel = channel; rt_request = Types.request init.request; rt_context = None; handling = None }

(* The context that the route is offered to: its own, or that of the page that offers it. *)
let set_context (route : t) context = route.rt_context <- Some context

let request (route : t) = route.rt_request

(* Once the page that issued the request is gone the outcome no longer matters to anyone, so
   failures to deliver it are not reported. *)
let unless_target_gone (route : t) f = try f () with Error.E _ when Request.is_target_gone route.rt_request -> ()

let decide (route : t) =
    match route.handling with
    | Some resolver -> resolver
    | None -> Error.raise_ "Route is already handled!"

let report (route : t) handled =
    let resolver = decide route in
    route.handling <- None;
    Promise.resolve resolver handled

let handle (route : t) f =
    ignore (decide route);
    f ();
    report route true

let override (route : t) ?url ?method_ ?headers ?post_data () = Request.override route.rt_request ?url ?method_ ?headers ?post_data ()

let send_continue (route : t) ~is_fallback =
    let overrides = route.rt_request.overrides in
    unless_target_gone route (fun () ->
        Protocol.Route.continue ?url:overrides.o_url ?method_:overrides.o_method ?headers:(Option.map name_values overrides.o_headers)
            ?post_data:overrides.o_post_data ~is_fallback route.rt_channel)

let continue ?url ?method_ ?headers ?post_data (route : t) =
    handle route (fun () ->
        override route ?url ?method_ ?headers ?post_data ();
        send_continue route ~is_fallback:false)

(* Passes the request on to the next matching handler, or to the network if there is none. *)
let fallback ?url ?method_ ?headers ?post_data (route : t) =
    ignore (decide route);
    override route ?url ?method_ ?headers ?post_data ();
    report route false

let abort ?error_code (route : t) =
    handle route (fun () -> unless_target_gone route (fun () -> Protocol.Route.abort ?error_code route.rt_channel))

let fulfill ?status ?headers ?content_type ?body ?json ?(response : api_response option) (route : t) =
    handle route (fun () ->
        if body <> None && json <> None then invalid_arg "Playwright: pass either ~body or ~json, not both";
        let status = match status, response with Some _, _ -> status | None, Some response -> Some response.ar_init.status | None, None -> None in
        let headers = match headers, response with Some headers, _ -> headers | None, Some response -> pairs response.ar_init.headers | None, None -> [] in
        let body = match body, json with Some _, _ -> body | None, Some json -> Some (Yojson.Safe.to_string json) | None, None -> None in
        (* The driver that fetched a response still holds its body, and replays it when told which
           one it is.  Another driver knows nothing of it and is sent the body. *)
        let body, fetch_response_uid =
            match body, response with
            | None, Some response when Channel.conn response.ar_context.a_channel == Channel.conn route.rt_channel -> None, Some response.ar_init.fetch_uid
            | None, Some response -> Some (Api_request.Response.body response), None
            | _ -> body, None
        in
        let headers = List.map (fun (name, value) -> String.lowercase_ascii name, value) headers in
        let set name value headers = (name, value) :: List.remove_assoc name headers in
        let headers =
            match content_type, json with
            | Some content_type, _ -> set "content-type" content_type headers
            | None, Some _ -> set "content-type" "application/json" headers
            | None, None -> headers
        in
        let headers =
            match body with
            | Some body when body <> "" && not (List.mem_assoc "content-length" headers) ->
                headers @ [ "content-length", string_of_int (String.length body) ]
            | _ -> headers
        in
        unless_target_gone route (fun () ->
            Protocol.Route.fulfill ~status:(Option.value status ~default:200) ~headers:(name_values headers)
                ?body:(Option.map Base64.encode_string body) ~is_base64:(body <> None) ?fetch_response_uid route.rt_channel))

(* Performs the request and returns its response, so that the handler can alter it before
   fulfilling the route. *)
let fetch ?timeout ?url ?method_ ?headers ?post_data ?max_redirects ?max_retries (route : t) =
    match route.rt_context with
    | None -> Error.raise_ "The route does not belong to a browser context"
    | Some context ->
        let request = route.rt_request in
        Api_request.Context.fetch ?timeout ?method_ ?headers ?data:post_data ?max_redirects ?max_retries ~request
            (Option.value url ~default:(Request.url request)) context.request

(* {1 Handlers} *)

module Handler = struct
    let make session ?base_url ?times matcher handler : route_handler =
        { rh_matcher = matcher; rh_matches = Url_match.compile session ?base_url matcher; rh_handler = handler; rh_times = times; rh_handled = 0;
          rh_running = 0; rh_idle = Eio.Condition.create (); rh_quiet = false }

    let will_expire (handler : route_handler) = match handler.rh_times with Some times -> handler.rh_handled + 1 >= times | None -> false

    (* A handler that fails has not said what should become of the request, and letting through
       what it may have been there to block is the wrong guess.  So the request fails, and the
       exception is reported.  Two exceptions: a handler that was removed with [`Ignore_errors]
       is not heard of again and its request goes on to the next handler, and nothing is
       reported about a request whose page is gone. *)
    let failed (handler : route_handler) (route : route) resolver ex backtrace =
        let unsettled = route.handling <> None in
        route.handling <- None;
        let target_gone = match ex with Error.E { kind = Target_closed; _ } -> Request.is_target_gone route.rt_request | _ -> false in
        if handler.rh_quiet then begin if unsettled then Promise.resolve resolver false end
        else begin
            if not target_gone then (Channel.conn route.rt_channel).report "route handler" ex backtrace;
            if unsettled then begin
                (try Protocol.Route.abort route.rt_channel with Error.E _ -> ());
                Promise.resolve resolver true
            end
        end

    (* Runs one handler and waits for its verdict: [true] if it settled the route, [false] if it
       fell back. *)
    let run (handler : route_handler) (route : route) =
        handler.rh_handled <- handler.rh_handled + 1;
        handler.rh_running <- handler.rh_running + 1;
        let verdict, resolver = Promise.create () in
        route.handling <- Some resolver;
        Fun.protect
            ~finally:(fun () ->
                handler.rh_running <- handler.rh_running - 1;
                if handler.rh_running = 0 then Eio.Condition.broadcast handler.rh_idle)
            (fun () ->
                (try handler.rh_handler route with ex when not (Connection.is_cancellation ex) -> failed handler route resolver ex (Printexc.get_raw_backtrace ()));
                Promise.await verdict)

    (* What becomes of the calls of a handler that are under way when it is removed. *)
    let stop (behavior : [ `Default | `Wait | `Ignore_errors ]) (handler : route_handler) =
        match behavior with
        | `Default -> ()
        | `Ignore_errors -> handler.rh_quiet <- true
        | `Wait -> while handler.rh_running > 0 do Eio.Condition.await_no_mutex handler.rh_idle done

    (* Offers the route to [handlers ()] in order.  Returns whether one of them settled it, or
       [stalled ()] says that nobody should. *)
    let dispatch ~handlers ~remove ~stalled ~on_empty (route : route) =
        let url = Request.url route.rt_request in
        let rec offer = function
            | [] -> false
            | handler :: rest ->
                if stalled () then true
                else if (not (handler.rh_matches url)) || not (List.memq handler (handlers ())) then offer rest
                else begin
                    if will_expire handler then remove handler;
                    let settled = run handler route in
                    if handlers () = [] then on_empty ();
                    settled || offer rest
                end
        in
        offer (handlers ())

    let matcher_equal a b = match a, b with Glob a, Glob b -> a = b | Predicate a, Predicate b -> a == b | _ -> false
    let globs matchers = Url_match.interception_patterns matchers
end

(* {1 WebSocket routes} *)

module Web_socket = struct
    type t = web_socket_route

    let equal (a : t) (b : t) = Channel.equal a.wr_channel b.wr_channel
    let compare (a : t) (b : t) = Channel.compare a.wr_channel b.wr_channel
    let hash (t : t) = Channel.hash t.wr_channel

    (* The messages of a socket are passed on in the order in which they came, also when nobody
       handles them. *)
    let fork (channel : Protocol.Web_socket_route.t) f = Connection.handle (Channel.conn channel) "WebSocket route" (fun () -> try f () with Error.E _ -> ())

    let encode = function Text text -> text, false | Binary bytes -> Base64.encode_string bytes, true
    let decode message ~is_base64 = if is_base64 then Binary (Json.Decode.binary (`String message)) else Text message

    let handle_event (channel : Protocol.Web_socket_route.t) (state : ws_route_state) : Protocol.Web_socket_route.event -> unit = function
        | Message_from_page { message; is_base64 } ->
            (match state.on_page_message with
            | Some handler -> fork channel (fun () -> handler (decode message ~is_base64))
            | None -> if state.wr_connected then fork channel (fun () -> Protocol.Web_socket_route.send_to_server ~message ~is_base64 channel))
        | Message_from_server { message; is_base64 } ->
            (match state.on_server_message with
            | Some handler -> fork channel (fun () -> handler (decode message ~is_base64))
            | None -> fork channel (fun () -> Protocol.Web_socket_route.send_to_page ~message ~is_base64 channel))
        | Close_page { code; reason; was_clean } ->
            (match state.on_page_close with
            | Some handler -> fork channel (fun () -> handler code reason)
            | None -> fork channel (fun () -> Protocol.Web_socket_route.close_server ?code ?reason ~was_clean channel))
        | Close_server { code; reason; was_clean } ->
            (match state.on_server_close with
            | Some handler -> fork channel (fun () -> handler code reason)
            | None -> fork channel (fun () -> Protocol.Web_socket_route.close_page ?code ?reason ~was_clean channel))

    let create (channel : Protocol.Web_socket_route.t) : t =
        let init = Protocol.Web_socket_route.initializer_ channel in
        let state =
            { wr_url = init.url; wr_protocols = init.protocols; wr_connected = false; on_page_message = None; on_page_close = None;
              on_server_message = None; on_server_close = None }
        in
        Protocol.Web_socket_route.listen channel (handle_event channel state);
        { wr_channel = channel; wr_side = `Page; wr_state = state }

    let url (t : t) = t.wr_state.wr_url
    let protocols (t : t) = t.wr_state.wr_protocols
    let quietly f = try f () with Error.E _ -> ()

    (* Connects to the real server and returns the route's server side. *)
    let connect_to_server (t : t) : t =
        if t.wr_side = `Server then Error.raise_ "connect_to_server must be called on the page-side WebSocketRoute";
        if t.wr_state.wr_connected then Error.raise_ "Already connected to the server";
        t.wr_state.wr_connected <- true;
        quietly (fun () -> Protocol.Web_socket_route.connect t.wr_channel);
        { t with wr_side = `Server }

    let send payload (t : t) =
        let message, is_base64 = encode payload in
        quietly (fun () ->
            match t.wr_side with
            | `Page -> Protocol.Web_socket_route.send_to_page ~message ~is_base64 t.wr_channel
            | `Server -> Protocol.Web_socket_route.send_to_server ~message ~is_base64 t.wr_channel)

    let close ?code ?reason (t : t) =
        quietly (fun () ->
            match t.wr_side with
            | `Page -> Protocol.Web_socket_route.close_page ?code ?reason ~was_clean:true t.wr_channel
            | `Server -> Protocol.Web_socket_route.close_server ?code ?reason ~was_clean:true t.wr_channel)

    let on_message handler (t : t) =
        match t.wr_side with
        | `Page -> t.wr_state.on_page_message <- Some handler
        | `Server -> t.wr_state.on_server_message <- Some handler

    let on_close handler (t : t) =
        match t.wr_side with
        | `Page -> t.wr_state.on_page_close <- Some handler
        | `Server -> t.wr_state.on_server_close <- Some handler

    let make_handler session ?base_url matcher handler : ws_route_handler =
        { wh_matcher = matcher; wh_matches = Url_match.compile session ?base_url ~web_socket:true matcher; wh_handler = handler }

    (* Returns whether one of [handlers] took the route. *)
    let dispatch (handlers : ws_route_handler list) (t : t) =
        match List.find_opt (fun handler -> handler.wh_matches t.wr_state.wr_url) handlers with
        | None -> false
        | Some handler ->
            (match handler.wh_handler t with
            (* Without a server connection, make the socket look open to the page anyway. *)
            | () -> if not t.wr_state.wr_connected then quietly (fun () -> Protocol.Web_socket_route.ensure_opened t.wr_channel)
            (* Nobody is going to serve the socket: the page is told so, rather than left waiting. *)
            | exception ex when not (Connection.is_cancellation ex) ->
                (Channel.conn t.wr_channel).report "WebSocket route handler" ex (Printexc.get_raw_backtrace ());
                quietly (fun () -> Protocol.Web_socket_route.close_page ~was_clean:false t.wr_channel));
            true
end

(* {1 Bindings} *)

module Binding = struct
    (* Runs the OCaml function behind a call that the page made to an exposed binding. *)
    let call (channel : Protocol.Binding_call.t) (binding : binding) =
        let init = Protocol.Binding_call.initializer_ channel in
        match
            let frame = Types.frame init.frame in
            let page = page_of_frame frame in
            binding { bs_context = page.context; bs_page = page; bs_frame = frame } (List.map Js.of_wire init.args)
        with
        | result -> (try Protocol.Binding_call.resolve ~result:(Js.to_argument result) channel with Error.E _ -> ())
        | exception ex when not (Connection.is_cancellation ex) ->
            let message = match ex with Error.E error -> Error.to_string error | ex -> Printexc.to_string ex in
            let error : Protocol.Serialized_error.t = { error = Some { message; name = "Error"; stack = None; code = None }; value = None } in
            (try Protocol.Binding_call.reject ~error channel with Error.E _ -> ())
end
