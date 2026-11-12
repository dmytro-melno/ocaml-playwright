open Types

type t = js_handle

let equal (a : t) (b : t) = Channel.equal a.h_channel b.h_channel
let compare (a : t) (b : t) = Channel.compare a.h_channel b.h_channel
let hash (t : t) = Channel.hash t.h_channel

let handle_event (handle : t) : Protocol.Js_handle.event -> unit = function
    | Preview_updated { preview } -> handle.preview <- preview

let create session (channel : Protocol.Js_handle.t) : t =
    let init = Protocol.Js_handle.initializer_ channel in
    let handle = { h_channel = channel; h_session = session; preview = init.preview } in
    Protocol.Js_handle.listen channel (handle_event handle);
    handle

let evaluate ?(arg = Js.Undefined) (handle : t) expression =
    Protocol.Js_handle.evaluate_expression ~expression ~arg:(Js.to_argument arg) handle.h_channel |> Js.of_wire

let evaluate_handle ?(arg = Js.Undefined) (handle : t) expression =
    Protocol.Js_handle.evaluate_expression_handle ~expression ~arg:(Js.to_argument arg) handle.h_channel |> Types.js_handle

let get_property (handle : t) name = Protocol.Js_handle.get_property ~name handle.h_channel |> Types.js_handle

let get_properties (handle : t) =
    Protocol.Js_handle.get_property_list handle.h_channel
    |> List.map (fun (property : Protocol.Js_handle.Get_property_list_result_properties.t) -> property.name, Types.js_handle property.value)

let json_value (handle : t) = Protocol.Js_handle.json_value handle.h_channel |> Js.of_wire

let as_element (handle : t) =
    Channel.narrow Protocol.Element_handle.kind handle.h_channel |> Option.map (fun e_channel -> { e_handle = handle; e_channel })

let to_string (handle : t) = handle.preview

(* Disposing of a handle whose page or context is already gone is not an error. *)
let dispose (handle : t) =
    if not (Channel.is_disposed handle.h_channel) then
        try Connection.detached (Channel.conn handle.h_channel) (fun () -> Protocol.Js_handle.dispose handle.h_channel)
        with Error.E { kind = Target_closed; _ } -> ()
