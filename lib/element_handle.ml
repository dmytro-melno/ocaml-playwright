open Types

type t = js_handle

let equal (a : t) (b : t) = Channel.equal a.h_channel b.h_channel
let compare (a : t) (b : t) = Channel.compare a.h_channel b.h_channel
let hash (t : t) = Channel.hash t.h_channel
let as_js_handle (handle : t) : js_handle = handle
let owner_frame (handle : t) = Protocol.Element_handle.owner_frame (element_channel handle) |> Option.map Types.frame
let content_frame (handle : t) = Protocol.Element_handle.content_frame (element_channel handle) |> Option.map Types.frame
let evaluate = Js_handle.evaluate
let evaluate_handle = Js_handle.evaluate_handle
let dispose = Js_handle.dispose
