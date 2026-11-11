open Types

type t = frame_locator

let equal (a : t) (b : t) = Frame.equal a.fl_frame b.fl_frame && String.equal a.frame_selector b.frame_selector
let compare (a : t) (b : t) = match Frame.compare a.fl_frame b.fl_frame with 0 -> String.compare a.frame_selector b.frame_selector | order -> order
let hash (t : t) = Hashtbl.hash (Frame.hash t.fl_frame, t.frame_selector)

let child_selector (t : t) selector = Selector.join [ t.frame_selector; Selector.enter_frame; selector ]

let locator ?has_text ?has_text_regex ?has_not_text ?has_not_text_regex ?has ?has_not selector (t : t) =
    Locator.make ?has_text ?has_text_regex ?has_not_text ?has_not_text_regex ?has ?has_not t.fl_frame (child_selector t selector)

include Locator.Queries (struct
    type t = frame_locator

    let session (t : t) = t.fl_frame.f_session
    let find (t : t) selector = Locator.make t.fl_frame (child_selector t selector)
end)

let frame_locator selector (t : t) : t = { t with frame_selector = child_selector t selector }
let owner (t : t) : locator = { l_frame = t.fl_frame; selector = t.frame_selector }
let first (t : t) : t = { t with frame_selector = Selector.join [ t.frame_selector; Selector.nth 0 ] }
let last (t : t) : t = { t with frame_selector = Selector.join [ t.frame_selector; Selector.nth (-1) ] }
let nth index (t : t) : t = { t with frame_selector = Selector.join [ t.frame_selector; Selector.nth index ] }
