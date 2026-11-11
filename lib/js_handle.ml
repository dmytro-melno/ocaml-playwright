open Types

type t = js_handle

let handle_event (handle : t) name params =
    match Protocol.Js_handle.event_of_json handle.h_session.conn name params with
    | Some (Preview_updated { preview }) -> handle.preview <- preview
    | None -> ()

let create session (channel : Channel.t) =
    let init = Protocol.Js_handle.Initializer.of_json channel.conn channel.initializer_ in
    let handle = { h_channel = channel; h_session = session; preview = init.preview } in
    channel.impl <- Js_handle handle;
    channel.on_event <- handle_event handle

let evaluate ?(arg = Js.Undefined) expression (handle : t) =
    Protocol.Js_handle.evaluate_expression ~expression ~arg:(Js.to_argument arg) handle.h_channel |> Js.of_wire

let evaluate_handle ?(arg = Js.Undefined) expression (handle : t) =
    Protocol.Js_handle.evaluate_expression_handle ~expression ~arg:(Js.to_argument arg) handle.h_channel |> Types.js_handle

let get_property name (handle : t) = Protocol.Js_handle.get_property ~name handle.h_channel |> Types.js_handle

let get_properties (handle : t) =
    Protocol.Js_handle.get_property_list handle.h_channel
    |> List.map (fun (property : Protocol.Js_handle.Get_property_list_result_properties.t) -> property.name, Types.js_handle property.value)

let json_value (handle : t) = Protocol.Js_handle.json_value handle.h_channel |> Js.of_wire
let as_element (handle : t) = if is_element handle then Some handle else None
let to_string (handle : t) = handle.preview

(* Disposing of a handle whose page or context is already gone is not an error. *)
let dispose (handle : t) =
    if not handle.h_channel.disposed then
        try Connection.detached handle.h_channel.conn (fun () -> Protocol.Js_handle.dispose handle.h_channel)
        with Error.E { kind = Target_closed; _ } -> ()
