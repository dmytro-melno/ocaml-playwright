open Types

type t = dialog

let create (channel : Protocol.Dialog.t) : t =
    let init = Protocol.Dialog.initializer_ channel in
    { d_channel = channel; d_page = Option.map Types.page init.page; d_type = init.type_; d_message = init.message; d_default_value = init.default_value }

let type_ (dialog : t) = dialog.d_type
let message (dialog : t) = dialog.d_message
let default_value (dialog : t) = dialog.d_default_value
let page (dialog : t) = dialog.d_page
let accept ?prompt_text (dialog : t) = Protocol.Dialog.accept ?prompt_text dialog.d_channel
let dismiss (dialog : t) = Protocol.Dialog.dismiss dialog.d_channel
