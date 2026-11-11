open Types

type t = js_handle

let equal (a : t) (b : t) = Channel.equal a.h_channel b.h_channel
let compare (a : t) (b : t) = Channel.compare a.h_channel b.h_channel
let hash (t : t) = Channel.hash t.h_channel

let frame_of (handle : t) =
    Option.map Types.frame (Channel.ancestor Protocol.Frame.kind handle.h_channel)

let action_timeout ?timeout (handle : t) =
    match frame_of handle with
    | Some frame -> Frame.action_timeout ?timeout frame
    | None -> Timeouts.action ?timeout (Timeouts.create ())

let as_js_handle (handle : t) : js_handle = handle
let owner_frame (handle : t) = Protocol.Element_handle.owner_frame (element_channel handle) |> Option.map Types.frame
let content_frame (handle : t) = Protocol.Element_handle.content_frame (element_channel handle) |> Option.map Types.frame

let get_attribute name (handle : t) = Protocol.Element_handle.get_attribute ~name (element_channel handle)
let text_content (handle : t) = Protocol.Element_handle.text_content (element_channel handle)
let inner_text (handle : t) = Protocol.Element_handle.inner_text (element_channel handle)
let inner_html (handle : t) = Protocol.Element_handle.inner_html (element_channel handle)
let input_value (handle : t) = Protocol.Element_handle.input_value (element_channel handle)
let is_checked (handle : t) = Protocol.Element_handle.is_checked (element_channel handle)
let is_disabled (handle : t) = Protocol.Element_handle.is_disabled (element_channel handle)
let is_editable (handle : t) = Protocol.Element_handle.is_editable (element_channel handle)
let is_enabled (handle : t) = Protocol.Element_handle.is_enabled (element_channel handle)
let is_hidden (handle : t) = Protocol.Element_handle.is_hidden (element_channel handle)
let is_visible (handle : t) = Protocol.Element_handle.is_visible (element_channel handle)

let bounding_box (handle : t) = Protocol.Element_handle.bounding_box (element_channel handle)

let dispatch_event ?(event_init = Js.Undefined) type_ (handle : t) =
    Protocol.Element_handle.dispatch_event ~type_ ~event_init:(Js.to_argument event_init) (element_channel handle)

let scroll_into_view_if_needed ?timeout (handle : t) =
    Protocol.Element_handle.scroll_into_view_if_needed ~timeout:(action_timeout ?timeout handle) (element_channel handle)

let click ?timeout ?force ?no_wait_after ?modifiers ?position ?delay ?button ?click_count ?trial ?steps (handle : t) =
    Protocol.Element_handle.click ~timeout:(action_timeout ?timeout handle) ?force ?no_wait_after ?modifiers
        ?position:(Option.map Frame.point position) ?delay ?button ?click_count ?trial ?steps (element_channel handle)

let dblclick ?timeout ?force ?modifiers ?position ?delay ?button ?trial ?steps (handle : t) =
    Protocol.Element_handle.dblclick ~timeout:(action_timeout ?timeout handle) ?force ?modifiers ?position:(Option.map Frame.point position)
        ?delay ?button ?trial ?steps (element_channel handle)

let tap ?timeout ?force ?modifiers ?position ?trial (handle : t) =
    Protocol.Element_handle.tap ~timeout:(action_timeout ?timeout handle) ?force ?modifiers ?position:(Option.map Frame.point position) ?trial
        (element_channel handle)

let hover ?timeout ?force ?modifiers ?position ?trial (handle : t) =
    Protocol.Element_handle.hover ~timeout:(action_timeout ?timeout handle) ?force ?modifiers ?position:(Option.map Frame.point position)
        ?trial (element_channel handle)

let fill ?timeout ?force value (handle : t) =
    Protocol.Element_handle.fill ~timeout:(action_timeout ?timeout handle) ~value ?force (element_channel handle)

let select_text ?timeout ?force (handle : t) =
    Protocol.Element_handle.select_text ~timeout:(action_timeout ?timeout handle) ?force (element_channel handle)

let focus (handle : t) = Protocol.Element_handle.focus (element_channel handle)

let press ?timeout ?delay ?no_wait_after key (handle : t) =
    Protocol.Element_handle.press ~timeout:(action_timeout ?timeout handle) ~key ?delay ?no_wait_after (element_channel handle)

let type_ ?timeout ?delay text (handle : t) =
    Protocol.Element_handle.type_ ~timeout:(action_timeout ?timeout handle) ~text ?delay (element_channel handle)

let check ?timeout ?force ?position ?trial (handle : t) =
    Protocol.Element_handle.check ~timeout:(action_timeout ?timeout handle) ?force ?position:(Option.map Frame.point position) ?trial
        (element_channel handle)

let uncheck ?timeout ?force ?position ?trial (handle : t) =
    Protocol.Element_handle.uncheck ~timeout:(action_timeout ?timeout handle) ?force ?position:(Option.map Frame.point position) ?trial
        (element_channel handle)

let set_checked ?timeout ?force ?position ?trial checked handle =
    if checked then check ?timeout ?force ?position ?trial handle else uncheck ?timeout ?force ?position ?trial handle

let select_option ?timeout ?force options (handle : t) =
    let options : Protocol.Element_handle.Select_option_options.t list =
        List.map
            (fun (o : Protocol.Frame.Select_option_options.t) : Protocol.Element_handle.Select_option_options.t ->
                { value_or_label = o.value_or_label; value = o.value; label = o.label; index = o.index })
            (Frame.select_options options)
    in
    Protocol.Element_handle.select_option ~timeout:(action_timeout ?timeout handle) ~options ?force (element_channel handle)

let set_input ?timeout files (handle : t) =
    let converted = Frame.convert_input_files (frame_of handle) files in
    let payloads =
        Option.map
            (List.map (fun (p : Protocol.Frame.Set_input_files_payloads.t) : Protocol.Element_handle.Set_input_files_payloads.t ->
                 { name = p.name; mime_type = p.mime_type; buffer = p.buffer }))
            converted.payloads
    in
    Protocol.Element_handle.set_input_files ~timeout:(action_timeout ?timeout handle) ?payloads ?local_directory:converted.local_directory
        ?directory_stream:converted.directory_stream ?local_paths:converted.local_paths ?streams:converted.streams (element_channel handle)

let set_input_files ?timeout paths handle = set_input ?timeout (Frame.Paths paths) handle
let set_input_payloads ?timeout payloads handle = set_input ?timeout (Frame.Payloads payloads) handle

let screenshot ?timeout ?path ?type_ ?quality ?omit_background ?caret ?animations ?scale ?mask ?mask_color ?style (handle : t) =
    Protocol.Element_handle.screenshot ~timeout:(action_timeout ?timeout handle) ?type_:(Screenshot.image_type ?type_ ?path ()) ?quality
        ?omit_background ?caret ?animations ?scale ?mask:(Option.map Screenshot.mask mask) ?mask_color ?style (element_channel handle)
    |> Screenshot.save ?path

let query_selector selector (handle : t) =
    Protocol.Element_handle.query_selector ~selector (element_channel handle) |> Option.map Types.element

let query_selector_all selector (handle : t) =
    Protocol.Element_handle.query_selector_all ~selector (element_channel handle) |> List.map Types.element

let eval_on_selector ?(arg = Js.Undefined) selector expression (handle : t) =
    Protocol.Element_handle.eval_on_selector ~selector ~expression ~arg:(Js.to_argument arg) (element_channel handle) |> Js.of_wire

let eval_on_selector_all ?(arg = Js.Undefined) selector expression (handle : t) =
    Protocol.Element_handle.eval_on_selector_all ~selector ~expression ~arg:(Js.to_argument arg) (element_channel handle) |> Js.of_wire

let wait_for_element_state ?timeout state (handle : t) =
    Protocol.Element_handle.wait_for_element_state ~timeout:(action_timeout ?timeout handle) ~state (element_channel handle)

let wait_for_selector ?timeout ?strict ?state selector (handle : t) =
    Protocol.Element_handle.wait_for_selector ~timeout:(action_timeout ?timeout handle) ~selector ?strict ?state (element_channel handle)
    |> Option.map Types.element

let evaluate = Js_handle.evaluate
let evaluate_handle = Js_handle.evaluate_handle
let dispose = Js_handle.dispose
