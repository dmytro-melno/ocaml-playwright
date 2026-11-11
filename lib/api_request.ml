(* HTTP requests issued by the driver, sharing cookies with a browser context or standing alone. *)

open Types

type file_payload = Protocol.Frame.Set_input_files_payloads.t = { name : string; mime_type : string option; buffer : string }
type multipart_value = [ `Text of string | `File of file_payload ]

module Context = struct
    type t = api_request_context

    let create session (channel : Channel.t) =
        let init = Protocol.Api_request_context.Initializer.of_json channel.conn channel.initializer_ in
        channel.impl <-
            Api_request_context
                { a_channel = channel; a_session = session; a_tracing = Types.tracing init.tracing; a_timeouts = Timeouts.create ();
                  a_close_reason = None; a_close_state = Closing.create () }

    let has_json_content_type headers =
        List.exists
            (fun (name, value) -> String.lowercase_ascii name = "content-type" && String.lowercase_ascii (String.trim value) = "application/json")
            headers

    let is_json text = match Yojson.Safe.from_string text with _ -> true | exception Yojson.Json_error _ -> false

    let fetch ?timeout ?method_ ?headers ?params ?data ?json ?form ?(multipart : (string * multipart_value) list option) ?fail_on_status_code ?ignore_https_errors ?max_redirects
        ?max_retries ?(request : request option) url (t : t) : api_response =
        if not (Closing.is_open t.a_close_state) then raise (Error.E (Error.target_closed ?message:t.a_close_reason ()));
        let bodies = List.length (List.filter Fun.id [ data <> None; json <> None; form <> None; multipart <> None ]) in
        if bodies > 1 then invalid_arg "Playwright: only one of ~data, ~json, ~form and ~multipart can be specified";
        let method_ = match method_, request with Some _, _ -> method_ | None, Some request -> Some (Network.Request.method_ request) | None, None -> None in
        (* The headers of an intercepted request must not be fetched here: it is paused. *)
        let headers = match headers, request with Some _, _ -> headers | None, Some request -> Some (Network.Request.headers request) | None, None -> None in
        let post_data, json_data =
            match data, json with
            | Some data, _ when has_json_content_type (Option.value headers ~default:[]) ->
                None, Some (if is_json data then data else Yojson.Safe.to_string (`String data))
            | Some data, _ -> Some data, None
            | None, Some json -> None, Some (Yojson.Safe.to_string json)
            | None, None -> None, None
        in
        let multipart_data =
            Option.map
                (List.map (fun (name, value) : Protocol.Form_field.t ->
                     match value with
                     | `Text value -> { name; value = Some value; file = None }
                     | `File (file : file_payload) ->
                         { name; value = None; file = Some { name = file.name; mime_type = file.mime_type; buffer = file.buffer } }))
                multipart
        in
        let post_data =
            match post_data, json_data, form, multipart_data, request with
            | None, None, None, None, Some request -> Network.Request.post_data request
            | _ -> post_data
        in
        let response =
            Protocol.Api_request_context.fetch ~timeout:(Timeouts.action ?timeout t.a_timeouts) ~url ?params:(Option.map Network.name_values params)
                ?method_ ?headers:(Option.map Network.name_values headers) ?post_data ?json_data ?form_data:(Option.map Network.name_values form)
                ?multipart_data ?fail_on_status_code ?ignore_https_errors ?max_redirects ?max_retries t.a_channel
        in
        { ar_context = t; ar_init = response }

    let with_method method_ ?timeout ?headers ?params ?data ?json ?form ?multipart ?fail_on_status_code ?ignore_https_errors ?max_redirects
        ?max_retries url t =
        fetch ?timeout ~method_ ?headers ?params ?data ?json ?form ?multipart ?fail_on_status_code ?ignore_https_errors ?max_redirects
            ?max_retries url t

    let get = with_method "GET"
    let post = with_method "POST"
    let put = with_method "PUT"
    let patch = with_method "PATCH"
    let delete = with_method "DELETE"
    let head = with_method "HEAD"

    let storage_state_json ?indexed_db (t : t) : Yojson.Safe.t =
        Protocol.Api_request_context.storage_state ?indexed_db t.a_channel |> Protocol.Api_request_context.Storage_state_result.to_json

    let storage_state ?path ?indexed_db t =
        let state = storage_state_json ?indexed_db t in
        Option.iter (fun path -> Files.write path (Yojson.Safe.pretty_to_string state)) path;
        state

    let cookies ?(urls = []) (t : t) = Protocol.Api_request_context.cookies ~urls t.a_channel |> List.map Cookie.of_protocol
    let add_cookies cookies (t : t) = Protocol.Api_request_context.add_cookies ~cookies t.a_channel
    let clear_cookies ?name ?domain ?path (t : t) = Protocol.Api_request_context.clear_cookies ?name ?domain ?path t.a_channel

    (* Disposing is idempotent, and a context that is already gone counts as disposed of. *)
    let dispose ?reason (t : t) =
        if Closing.is_open t.a_close_state then t.a_close_reason <- reason;
        Closing.close t.a_session.conn t.a_close_state (fun () ->
            (try Tracing.export_all_hars t.a_tracing with Error.E { kind = Target_closed; _ } -> ());
            Protocol.Api_request_context.dispose ?reason t.a_channel)
end

module Response = struct
    type t = api_response

    let url (r : t) = r.ar_init.url
    let status (r : t) = r.ar_init.status
    let status_text (r : t) = r.ar_init.status_text
    let ok (r : t) = r.ar_init.status >= 200 && r.ar_init.status <= 299
    let headers_array (r : t) = Network.pairs r.ar_init.headers
    let headers r = Network.merge_headers (headers_array r)
    let header_value name r = Network.header_value (headers_array r) name
    let fetch_uid (r : t) = r.ar_init.fetch_uid

    let body (r : t) =
        match Protocol.Api_request_context.fetch_response_body ~fetch_uid:r.ar_init.fetch_uid r.ar_context.a_channel with
        | Some body -> body
        | None -> Error.raise_ "Response has been disposed"
        | exception Error.E { kind = Target_closed; _ } -> Error.raise_ "Response has been disposed"

    let text = body

    let json r : Yojson.Safe.t =
        try Yojson.Safe.from_string (body r) with Yojson.Json_error message -> Error.raise_ "The response body is not valid JSON: %s" message

    (* Disposing is idempotent on the side of the driver. *)
    let dispose (r : t) =
        let context = r.ar_context in
        try
            Connection.detached context.a_session.conn (fun () ->
                Protocol.Api_request_context.dispose_api_response ~fetch_uid:r.ar_init.fetch_uid context.a_channel)
        with Error.E { kind = Target_closed; _ } -> ()
end
