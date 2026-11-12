(* HTTP requests issued by the driver, sharing cookies with a browser context or standing alone. *)

open Types

type file_payload = Protocol.Frame.Set_input_files_payloads.t = { name : string; mime_type : string option; buffer : string }
type multipart_value = [ `Text of string | `File of file_payload ]

module Context = struct
    type t = api_request_context

    let equal (a : t) (b : t) = Channel.equal a.a_channel b.a_channel
    let compare (a : t) (b : t) = Channel.compare a.a_channel b.a_channel
    let hash (t : t) = Channel.hash t.a_channel

    let create session (channel : Protocol.Api_request_context.t) : t =
        let init = Protocol.Api_request_context.initializer_ channel in
        { a_channel = channel; a_session = session; a_tracing = Types.tracing init.tracing; a_timeouts = Timeouts.create (); a_close_reason = None;
          a_close_state = Closing.create () }

    let fetch ?timeout ?method_ ?headers ?params ?data ?json ?form ?(multipart : (string * multipart_value) list option) ?fail_on_status_code ?ignore_https_errors ?max_redirects
        ?max_retries ?(request : request option) url (t : t) : api_response =
        if not (Closing.is_open t.a_close_state) then raise (Error.E (Error.target_closed ?message:t.a_close_reason ()));
        let bodies = List.length (List.filter Fun.id [ data <> None; json <> None; form <> None; multipart <> None ]) in
        if bodies > 1 then invalid_arg "Playwright: only one of ~data, ~json, ~form and ~multipart can be specified";
        let method_ = match method_, request with Some _, _ -> method_ | None, Some request -> Some (Network.Request.method_ request) | None, None -> None in
        (* The headers of an intercepted request must not be fetched here: it is paused. *)
        let headers = match headers, request with Some _, _ -> headers | None, Some request -> Some (Network.Request.headers request) | None, None -> None in
        let post_data, json_data =
            (* [data] is bytes for the driver and stays what it is, whatever the headers call it. *)
            match data, json with
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

    let storage_state ?indexed_db ?opfs (t : t) : Yojson.Safe.t =
        Protocol.Api_request_context.storage_state ?indexed_db ?opfs t.a_channel |> Protocol.Api_request_context.Storage_state_result.to_json

    let cookies ?(urls = []) (t : t) = Protocol.Api_request_context.cookies ~urls t.a_channel |> List.map Cookie.of_protocol
    let add_cookies cookies (t : t) = Protocol.Api_request_context.add_cookies ~cookies t.a_channel
    let clear_cookies ?name ?domain ?path (t : t) = Protocol.Api_request_context.clear_cookies ?name ?domain ?path t.a_channel

    let tracing (t : t) = t.a_tracing

    (* Disposing is idempotent, and a context that is already gone counts as disposed of. *)
    let dispose ?reason (t : t) =
        if Closing.is_open t.a_close_state then t.a_close_reason <- reason;
        Closing.close t.a_session.conn t.a_close_state (fun () -> Protocol.Api_request_context.dispose ?reason t.a_channel)
end

module Response = struct
    type t = api_response

    (* A response is not an object of the driver: it is known by a name within its context. *)
    let equal (a : t) (b : t) = Channel.equal a.ar_context.a_channel b.ar_context.a_channel && String.equal a.ar_init.fetch_uid b.ar_init.fetch_uid
    
    let compare (a : t) (b : t) =
        match Channel.compare a.ar_context.a_channel b.ar_context.a_channel with 0 -> String.compare a.ar_init.fetch_uid b.ar_init.fetch_uid | order -> order
    
    let hash (response : t) = Hashtbl.hash (Channel.hash response.ar_context.a_channel, response.ar_init.fetch_uid)

    let url (r : t) = r.ar_init.url
    let status (r : t) = r.ar_init.status
    let status_text (r : t) = r.ar_init.status_text
    let ok (r : t) = r.ar_init.status >= 200 && r.ar_init.status <= 299
    let headers_array (r : t) = Network.pairs r.ar_init.headers
    let headers r = Network.merge_headers (headers_array r)
    let header_value name r = Network.header_value (headers_array r) name
    let fetch_uid (r : t) = r.ar_init.fetch_uid
    let security_details (r : t) = r.ar_init.security_details
    let server_addr (r : t) = r.ar_init.server_addr

    (* What the driver measured; [-1.] for what it did not. *)
    let timing (r : t) : timing =
        let response_end = Option.value r.ar_init.response_end_timing ~default:(-1.) in
        match r.ar_init.timing with
        | Some t ->
            { start_time = t.start_time; domain_lookup_start = t.domain_lookup_start; domain_lookup_end = t.domain_lookup_end;
              connect_start = t.connect_start; secure_connection_start = t.secure_connection_start; connect_end = t.connect_end;
              request_start = t.request_start; response_start = t.response_start; response_end }
        | None ->
            { start_time = -1.; domain_lookup_start = -1.; domain_lookup_end = -1.; connect_start = -1.; secure_connection_start = -1.;
              connect_end = -1.; request_start = -1.; response_start = -1.; response_end }

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

(* A request context that is independent of any browser. *)
let new_context ?base_url ?user_agent ?ignore_https_errors ?extra_http_headers ?fail_on_status_code ?max_redirects
    ?(http_credentials : Context_options.Http_credentials.t list option) ?(client_certificates : Context_options.Client_certificate.t list option) ?(proxy : Context_options.Proxy.t option) ?(storage_state : Yojson.Safe.t option)
    ?timeout (t : playwright) =
    let conn = t.session.conn in
    let context =
        Protocol.Playwright.new_request ?base_url ?user_agent ?ignore_https_errors ?extra_http_headers:(Option.map Network.name_values extra_http_headers)
            ?fail_on_status_code ?max_redirects
            ?http_credentials:(Context_options.Http_credentials.list http_credentials)
            ?client_certificates:
                (Context_options.Client_certificate.list client_certificates
                |> Option.map
                       (List.map (fun (c : Protocol.Context_options_client_certificates.t) : Protocol.Playwright.New_request_client_certificates.t ->
                            { origin = c.origin; cert = c.cert; key = c.key; passphrase = c.passphrase; pfx = c.pfx })))
            ?proxy:
                (Option.map
                     (fun (p : Context_options.Proxy.t) : Protocol.Playwright.New_request_proxy.t ->
                         { server = p.server; bypass = p.bypass; username = p.username; password = p.password })
                     proxy)
            ?storage_state:(Option.map (Protocol.Playwright.New_request_storage_state.of_json conn) storage_state)
            t.pw_channel
        |> Types.api_request_context
    in
    Option.iter (Timeouts.set_default context.a_timeouts) timeout;
    context
