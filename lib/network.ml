(* Requests, responses and WebSockets as observed in a page. *)

open Eio.Std
open Types

let pairs (headers : Protocol.Name_value.t list) = List.map (fun (header : Protocol.Name_value.t) -> header.name, header.value) headers
let name_values headers = List.map (fun (name, value) : Protocol.Name_value.t -> { name; value }) headers

(* Merges headers the way the Fetch API presents them: names in lower case, repeated values
   joined. *)
let merge_headers headers =
    let lower = List.map (fun (name, value) -> String.lowercase_ascii name, value) headers in
    let names = List.fold_left (fun names (name, _) -> if List.mem name names then names else name :: names) [] lower |> List.rev in
    List.map
        (fun name ->
            let values = List.filter_map (fun (n, value) -> if n = name then Some value else None) lower in
            name, String.concat (if name = "set-cookie" then "\n" else ", ") values)
        names

let header_value headers name = List.assoc_opt (String.lowercase_ascii name) (merge_headers headers)

let header_values headers name =
    let name = String.lowercase_ascii name in
    List.filter_map (fun (n, value) -> if String.lowercase_ascii n = name then Some value else None) headers

let url_decode s =
    let buffer = Buffer.create (String.length s) in
    let n = String.length s in
    let hex c = match c with '0' .. '9' -> Some (Char.code c - 48) | 'a' .. 'f' -> Some (Char.code c - 87) | 'A' .. 'F' -> Some (Char.code c - 55) | _ -> None in
    let rec go i =
        if i < n then
            match s.[i] with
            | '+' -> Buffer.add_char buffer ' '; go (i + 1)
            | '%' when i + 2 < n && Option.is_some (hex s.[i + 1]) && Option.is_some (hex s.[i + 2]) ->
                Buffer.add_char buffer (Char.chr ((Option.get (hex s.[i + 1]) * 16) + Option.get (hex s.[i + 2])));
                go (i + 3)
            | c -> Buffer.add_char buffer c; go (i + 1)
    in
    go 0;
    Buffer.contents buffer

module Request = struct
    type t = request

    let equal (a : t) (b : t) = Channel.equal a.r_channel b.r_channel
    let compare (a : t) (b : t) = Channel.compare a.r_channel b.r_channel
    let hash (t : t) = Channel.hash t.r_channel

    let unknown_timing =
        { start_time = 0.; domain_lookup_start = -1.; domain_lookup_end = -1.; connect_start = -1.; secure_connection_start = -1.;
          connect_end = -1.; request_start = -1.; response_start = -1.; response_end = -1. }

    let no_overrides = { o_url = None; o_method = None; o_headers = None; o_post_data = None }

    let create (channel : Protocol.Request.t) : t =
        let init = Protocol.Request.initializer_ channel in
        let redirected_from = Option.map Types.request init.redirected_from in
        let request =
            { r_channel = channel; r_init = init; redirected_from; redirected_to = None; failure = None; r_response = None;
              timing = unknown_timing; raw_headers = None; overrides = no_overrides }
        in
        Option.iter (fun (previous : t) -> previous.redirected_to <- Some request) redirected_from;
        request

    let url (r : t) = Option.value r.overrides.o_url ~default:r.r_init.url
    let resource_type (r : t) = r.r_init.resource_type
    let method_ (r : t) = Option.value r.overrides.o_method ~default:r.r_init.method_
    let post_data (r : t) = match r.overrides.o_post_data with Some _ as data -> data | None -> r.r_init.post_data

    let provisional_headers (r : t) = match r.overrides.o_headers with Some headers -> headers | None -> pairs r.r_init.headers
    let headers (r : t) = merge_headers (provisional_headers r)

    (* The headers as sent over the network, which the browser only knows once the request is
       under way. *)
    let headers_array (r : t) =
        match r.overrides.o_headers, r.raw_headers with
        | Some headers, _ -> headers
        | None, Some headers -> headers
        | None, None ->
            let headers = pairs (Protocol.Request.raw_request_headers r.r_channel) in
            r.raw_headers <- Some headers;
            headers

    let all_headers r = merge_headers (headers_array r)
    let header_value name r = header_value (headers_array r) name

    let post_data_json (r : t) : Yojson.Safe.t option =
        match post_data r with
        | None | Some "" -> None
        | Some data ->
            let content_type = Option.value (List.assoc_opt "content-type" (headers r)) ~default:"" in
            let contains s sub =
                let n = String.length s and m = String.length sub in
                let rec at i = i + m <= n && (String.sub s i m = sub || at (i + 1)) in
                at 0
            in
            if contains content_type "application/x-www-form-urlencoded" then
                Some
                    (`Assoc
                        (String.split_on_char '&' data
                        |> List.filter (fun field -> field <> "")
                        |> List.map (fun field ->
                               match String.index_opt field '=' with
                               | Some i -> url_decode (String.sub field 0 i), `String (url_decode (String.sub field (i + 1) (String.length field - i - 1)))
                               | None -> url_decode field, `String "")))
            else
                try Some (Yojson.Safe.from_string data)
                with Yojson.Json_error _ -> Error.raise_ "POST data is not a valid JSON object: %s" data

    let response (r : t) = Protocol.Request.response r.r_channel |> Option.map Types.response
    let existing_response (r : t) = r.r_response
    let safe_page (r : t) = Option.bind r.r_init.frame (fun channel -> (Types.frame channel).page)
    let service_worker (r : t) = Option.map Types.worker r.r_init.service_worker

    let frame (r : t) =
        match r.r_init.frame with
        | None -> Error.raise_ "Service Worker requests do not have an associated frame."
        | Some channel ->
            let frame = Types.frame channel in
            if frame.page = None then
                Error.raise_
                    "Frame for this navigation request is not available, because the request was issued before the frame is created. \
                     You can check whether the request is a navigation request by calling Request.is_navigation_request.";
            frame

    let is_navigation_request (r : t) = r.r_init.is_navigation_request
    let redirected_from (r : t) = r.redirected_from
    let redirected_to (r : t) = r.redirected_to
    let failure (r : t) = r.failure
    let timing (r : t) = r.timing

    let sizes (r : t) =
        match response r with
        | Some response -> Protocol.Response.sizes response.rs_channel
        | None -> Error.raise_ "Unable to fetch sizes for failed request"

    let set_response_end (r : t) response_end =
        let response_start = if r.timing.response_start = -1. then response_end else r.timing.response_start in
        r.timing <- { r.timing with response_end; response_start }

    (* What a route handler has the request sent with, in place of what the page asked for. *)
    let override (r : t) ?url ?method_ ?headers ?post_data () =
        let keep fresh old = match fresh with Some _ -> fresh | None -> old in
        r.overrides <-
            { o_url = keep url r.overrides.o_url; o_method = keep method_ r.overrides.o_method; o_headers = keep headers r.overrides.o_headers;
              o_post_data = keep post_data r.overrides.o_post_data }

    let did_fail (r : t) ~failure_text ~response_end =
        r.failure <- Some (Option.value failure_text ~default:"");
        set_response_end r response_end

    (* The promise that resolves when whatever issued the request (a page or a worker) is gone. *)
    let target_gone (r : t) : Error.t Promise.t option =
        match service_worker r, safe_page r with
        | Some worker, _ -> Some worker.w_gone
        | None, Some page -> Some page.p_gone
        | None, None -> None

    let is_target_gone r = match target_gone r with Some gone -> Promise.is_resolved gone | None -> false
end

module Response = struct
    type t = response

    let equal (a : t) (b : t) = Channel.equal a.rs_channel b.rs_channel
    let compare (a : t) (b : t) = Channel.compare a.rs_channel b.rs_channel
    let hash (t : t) = Channel.hash t.rs_channel

    let create (channel : Protocol.Response.t) : t =
        let init = Protocol.Response.initializer_ channel in
        let request = Types.request init.request in
        let rs_finished, rs_finished_resolver = Promise.create () in
        let response = { rs_channel = channel; rs_init = init; rs_request = request; rs_raw_headers = None; rs_finished; rs_finished_resolver } in
        request.r_response <- Some response;
        Channel.on_lost channel (fun error -> if not (Promise.is_resolved rs_finished) then Promise.resolve rs_finished_resolver (Error error));
        let t = init.timing in
        request.timing <-
            { request.timing with start_time = t.start_time; domain_lookup_start = t.domain_lookup_start; domain_lookup_end = t.domain_lookup_end;
              connect_start = t.connect_start; secure_connection_start = t.secure_connection_start; connect_end = t.connect_end;
              request_start = t.request_start; response_start = t.response_start };
        response

    (* The request of the response is over, which leaves nothing more of it to arrive. *)
    let did_finish (r : t) = if not (Promise.is_resolved r.rs_finished) then Promise.resolve r.rs_finished_resolver (Ok ())

    let url (r : t) = r.rs_init.url
    let status (r : t) = r.rs_init.status
    let status_text (r : t) = r.rs_init.status_text

    (* Status 0 is what file:// URLs produce. *)
    let ok (r : t) = r.rs_init.status = 0 || (r.rs_init.status >= 200 && r.rs_init.status <= 299)

    let from_service_worker (r : t) = r.rs_init.from_service_worker
    let headers (r : t) = merge_headers (pairs r.rs_init.headers)

    let headers_array (r : t) =
        match r.rs_raw_headers with
        | Some headers -> headers
        | None ->
            let headers = pairs (Protocol.Response.raw_response_headers r.rs_channel) in
            r.rs_raw_headers <- Some headers;
            headers

    let all_headers r = merge_headers (headers_array r)
    let header_value name r = header_value (headers_array r) name
    let header_values name r = header_values (headers_array r) name
    let request (r : t) = r.rs_request
    let frame (r : t) = Request.frame r.rs_request
    let body (r : t) = Protocol.Response.body r.rs_channel
    let text = body

    let json r : Yojson.Safe.t =
        try Yojson.Safe.from_string (body r) with Yojson.Json_error message -> Error.raise_ "The response body is not valid JSON: %s" message

    let server_addr (r : t) = Protocol.Response.server_addr r.rs_channel
    let security_details (r : t) = Protocol.Response.security_details r.rs_channel
    let http_version (r : t) = Protocol.Response.http_version r.rs_channel

    (* Waits until the body has been received in full. *)
    let finished (r : t) =
        let finished () = match Promise.await r.rs_finished with Ok () -> () | Error error -> raise (Error.E error) in
        match Request.target_gone r.rs_request with
        | None -> finished ()
        | Some gone -> Fibers.first finished (fun () -> raise (Error.E (Promise.await gone)))
end

module Web_socket = struct
    type t = web_socket

    let equal (a : t) (b : t) = Channel.equal a.ws_channel b.ws_channel
    let compare (a : t) (b : t) = Channel.compare a.ws_channel b.ws_channel
    let hash (t : t) = Channel.hash t.ws_channel

    let emit (socket : t) emitter value = ignore (Emitter.emit (Channel.conn socket.ws_channel) emitter value)

    let payload ~opcode data =
        match opcode with
        | 1 -> Some (Text data)
        | 2 -> Some (Binary (Json.Decode.binary (`String data)))
        | _ -> None

    let did_close (socket : t) =
        if not socket.ws_closed then begin
            socket.ws_closed <- true;
            emit socket socket.wse_close socket
        end

    let handle_event (socket : t) : Protocol.Web_socket.event -> unit = function
        | Frame_sent { opcode; data } -> Option.iter (emit socket socket.wse_frame_sent) (payload ~opcode data)
        | Frame_received { opcode; data } -> Option.iter (emit socket socket.wse_frame_received) (payload ~opcode data)
        | Socket_error { error } -> emit socket socket.wse_socket_error error
        | Close -> did_close socket
        | Open -> ()

    let create (channel : Protocol.Web_socket.t) : t =
        let init = Protocol.Web_socket.initializer_ channel in
        let ws_page = Option.map Types.page (Channel.parent Protocol.Page.kind channel) in
        let socket =
            { ws_channel = channel; ws_url = init.url; ws_page; ws_closed = false; wse_close = Emitter.create ();
              wse_frame_sent = Emitter.create (); wse_frame_received = Emitter.create (); wse_socket_error = Emitter.create () }
        in
        Protocol.Web_socket.listen channel (handle_event socket);
        Channel.on_lost channel (fun _ -> did_close socket);
        socket

    let url (socket : t) = socket.ws_url
    let is_closed (socket : t) = socket.ws_closed

    type _ event =
        | Close : web_socket event
        | Frame_sent : ws_payload event
        | Frame_received : ws_payload event
        | Socket_error : string event

    let emitter : type a. t -> a event -> a Emitter.t =
        fun socket -> function
        | Close -> socket.wse_close
        | Frame_sent -> socket.wse_frame_sent
        | Frame_received -> socket.wse_frame_received
        | Socket_error -> socket.wse_socket_error

    let event_name : type a. a event -> string = function
        | Close -> "close"
        | Frame_sent -> "framesent"
        | Frame_received -> "framereceived"
        | Socket_error -> "socketerror"

    let on event listener (socket : t) = Disposable.listener (Emitter.on (emitter socket event) listener)
    let once event listener (socket : t) = Disposable.listener (Emitter.once (emitter socket event) listener)

    let expect_event (type a) ?timeout ?predicate (event : a event) action (socket : t) : a =
        let timeouts = match socket.ws_page with Some page -> page.p_timeouts | None -> Timeouts.create () in
        let rejections waiter =
            (match event with
            | Socket_error -> ()
            | _ -> Waiter.reject_on waiter socket.wse_socket_error (fun _ -> Some (Error.make "Socket error")));
            (match event with
            | Close -> ()
            | _ -> Waiter.reject_on waiter socket.wse_close (fun _ -> Some (Error.make "Socket closed")));
            Option.iter (fun (page : page) -> Waiter.reject_on waiter page.pe_close (fun _ -> Some (Error.target_closed ?message:page.p_close_reason ()))) socket.ws_page
        in
        Events.expect (Channel.conn socket.ws_channel) ~timeout:(Timeouts.action ?timeout timeouts) ~name:(event_name event) ?predicate ~rejections
            (emitter socket event) action

    let wait_for_event ?timeout ?predicate event socket = expect_event ?timeout ?predicate event ignore socket
end
