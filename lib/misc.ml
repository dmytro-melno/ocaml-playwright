(* Plain values delivered with events. *)

open Types

module Console_message = struct
    type t = console_message


    type location = { url : string; line_number : int; column_number : int }

    let type_ (m : t) = m.cm_type
    let text (m : t) = m.cm_text
    let args (m : t) = m.cm_args
    let page (m : t) = m.cm_page
    let worker (m : t) = m.cm_worker
    let timestamp (m : t) = m.cm_timestamp

    let location (m : t) =
        { url = m.cm_location.url; line_number = m.cm_location.line_number; column_number = m.cm_location.column_number }
end

module Download = struct
    type t = download

    let equal (a : t) (b : t) = Channel.equal a.dl_artifact b.dl_artifact
    let compare (a : t) (b : t) = Channel.compare a.dl_artifact b.dl_artifact
    let hash (t : t) = Channel.hash t.dl_artifact

    let session (d : t) = d.dl_page.main_frame.f_session
    let page (d : t) = d.dl_page
    let url (d : t) = d.dl_url
    let suggested_filename (d : t) = d.suggested_filename

    (* Waits for the download to finish and returns where the browser stored it. *)
    let path (d : t) = Artifact.path_after_finished d.dl_artifact

    let save_as (d : t) path = Artifact.save_as d.dl_artifact path
    let failure (d : t) = Artifact.failure d.dl_artifact
    let cancel (d : t) = Artifact.cancel d.dl_artifact
    let delete (d : t) = Artifact.delete d.dl_artifact
end

module File_chooser = struct
    type t = file_chooser

    let equal (a : t) (b : t) = Channel.equal a.fc_element.e_channel b.fc_element.e_channel
    let compare (a : t) (b : t) = Channel.compare a.fc_element.e_channel b.fc_element.e_channel
    let hash (chooser : t) = Channel.hash chooser.fc_element.e_channel

    let page (c : t) = c.fc_page
    let element (c : t) = c.fc_element
    let is_multiple (c : t) = c.is_multiple

    let set ?timeout files (c : t) =
        let converted = Frame.convert_input_files files in
        let payloads =
            Option.map
                (List.map (fun (p : Protocol.Frame.Set_input_files_payloads.t) : Protocol.Element_handle.Set_input_files_payloads.t ->
                     { name = p.name; mime_type = p.mime_type; buffer = p.buffer }))
                converted.payloads
        in
        Protocol.Element_handle.set_input_files ~timeout:(Timeouts.action ?timeout c.fc_page.p_timeouts) ?payloads
            ?local_directory:converted.local_directory ?local_paths:converted.local_paths c.fc_element.e_channel

    let set_files ?timeout (c : t) paths = set ?timeout (Frame.Paths paths) c
    let set_payloads ?timeout (c : t) payloads = set ?timeout (Frame.Payloads payloads) c
end

module Web_error = struct
    type t = web_error


    let page (e : t) = e.we_page
    let error (e : t) = e.we_error

    let location (e : t) : Console_message.location =
        { url = e.we_location.url; line_number = e.we_location.line; column_number = e.we_location.column }
end

module Selectors = struct
    (* Makes a custom selector engine available to every context, present and future. *)
    let register ?content_script (session : session) name ~script =
        let selectors = session.selectors in
        if List.exists (fun (engine : Protocol.Selector_engine.t) -> engine.name = name) selectors.selector_engines then
            Error.raise_ "\"%s\" selector engine has been already registered" name;
        let selector_engine : Protocol.Selector_engine.t = { name; source = script; content_script } in
        List.iter
            (fun (context : browser_context) ->
                try Protocol.Browser_context.register_selector_engine ~selector_engine context.c_channel with Error.E { kind = Target_closed; _ } -> ())
            selectors.all_contexts;
        selectors.selector_engines <- selectors.selector_engines @ [ selector_engine ]

    (* Changes the attribute that [get_by_test_id] looks at. *)
    let set_test_id_attribute (session : session) name =
        session.selectors.test_id_attribute <- name;
        List.iter
            (fun (context : browser_context) ->
                try Protocol.Browser_context.set_test_id_attribute_name ~test_id_attribute_name:name context.c_channel with Error.E _ -> ())
            session.selectors.all_contexts
end
