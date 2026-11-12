open Types

type t = element_handle

let equal (a : t) (b : t) = Channel.equal a.e_channel b.e_channel
let compare (a : t) (b : t) = Channel.compare a.e_channel b.e_channel
let hash (t : t) = Channel.hash t.e_channel
let as_js_handle (handle : t) = handle.e_handle
let owner_frame (handle : t) = Protocol.Element_handle.owner_frame handle.e_channel |> Option.map Types.frame
let content_frame (handle : t) = Protocol.Element_handle.content_frame handle.e_channel |> Option.map Types.frame
let evaluate ?arg (handle : t) expression = Js_handle.evaluate ?arg handle.e_handle expression
let evaluate_handle ?arg (handle : t) expression = Js_handle.evaluate_handle ?arg handle.e_handle expression
let dispose (handle : t) = Js_handle.dispose handle.e_handle
