open Types

type t = locator

type role =
    [ `Alert | `Alertdialog | `Application | `Article | `Banner | `Blockquote | `Button | `Caption | `Cell | `Checkbox | `Code
    | `Columnheader | `Combobox | `Complementary | `Contentinfo | `Definition | `Deletion | `Dialog | `Directory | `Document
    | `Emphasis | `Feed | `Figure | `Form | `Generic | `Grid | `Gridcell | `Group | `Heading | `Img | `Insertion | `Link | `List
    | `Listbox | `Listitem | `Log | `Main | `Marquee | `Math | `Meter | `Menu | `Menubar | `Menuitem | `Menuitemcheckbox
    | `Menuitemradio | `Navigation | `None | `Note | `Option | `Paragraph | `Presentation | `Progressbar | `Radio | `Radiogroup
    | `Region | `Row | `Rowgroup | `Rowheader | `Scrollbar | `Search | `Searchbox | `Separator | `Slider | `Spinbutton | `Status
    | `Strong | `Subscript | `Superscript | `Switch | `Tab | `Table | `Tablist | `Tabpanel | `Term | `Textbox | `Time | `Timer
    | `Toolbar | `Tooltip | `Tree | `Treegrid | `Treeitem ]

let role_name : role -> string = function
    | `Alert -> "alert" | `Alertdialog -> "alertdialog" | `Application -> "application" | `Article -> "article" | `Banner -> "banner"
    | `Blockquote -> "blockquote" | `Button -> "button" | `Caption -> "caption" | `Cell -> "cell" | `Checkbox -> "checkbox"
    | `Code -> "code" | `Columnheader -> "columnheader" | `Combobox -> "combobox" | `Complementary -> "complementary"
    | `Contentinfo -> "contentinfo" | `Definition -> "definition" | `Deletion -> "deletion" | `Dialog -> "dialog"
    | `Directory -> "directory" | `Document -> "document" | `Emphasis -> "emphasis" | `Feed -> "feed" | `Figure -> "figure"
    | `Form -> "form" | `Generic -> "generic" | `Grid -> "grid" | `Gridcell -> "gridcell" | `Group -> "group" | `Heading -> "heading"
    | `Img -> "img" | `Insertion -> "insertion" | `Link -> "link" | `List -> "list" | `Listbox -> "listbox" | `Listitem -> "listitem"
    | `Log -> "log" | `Main -> "main" | `Marquee -> "marquee" | `Math -> "math" | `Meter -> "meter" | `Menu -> "menu"
    | `Menubar -> "menubar" | `Menuitem -> "menuitem" | `Menuitemcheckbox -> "menuitemcheckbox" | `Menuitemradio -> "menuitemradio"
    | `Navigation -> "navigation" | `None -> "none" | `Note -> "note" | `Option -> "option" | `Paragraph -> "paragraph"
    | `Presentation -> "presentation" | `Progressbar -> "progressbar" | `Radio -> "radio" | `Radiogroup -> "radiogroup"
    | `Region -> "region" | `Row -> "row" | `Rowgroup -> "rowgroup" | `Rowheader -> "rowheader" | `Scrollbar -> "scrollbar"
    | `Search -> "search" | `Searchbox -> "searchbox" | `Separator -> "separator" | `Slider -> "slider" | `Spinbutton -> "spinbutton"
    | `Status -> "status" | `Strong -> "strong" | `Subscript -> "subscript" | `Superscript -> "superscript" | `Switch -> "switch"
    | `Tab -> "tab" | `Table -> "table" | `Tablist -> "tablist" | `Tabpanel -> "tabpanel" | `Term -> "term" | `Textbox -> "textbox"
    | `Time -> "time" | `Timer -> "timer" | `Toolbar -> "toolbar" | `Tooltip -> "tooltip" | `Tree -> "tree" | `Treegrid -> "treegrid"
    | `Treeitem -> "treeitem"

(* {1 Construction} *)

(* A text given either literally or as a regular expression, but not both ways. *)
let text_option what plain regex : Selector.text option =
    match plain, regex with
    | Some _, Some _ -> invalid_arg (Printf.sprintf "Playwright: pass either ~%s or ~%s_regex, not both" what what)
    | Some "", None | None, None -> None
    | Some text, None -> Some (Text text)
    | None, Some regex -> Some (Regex regex)

let same_frame what (frame : frame) (locator : t) =
    if locator.l_frame != frame then invalid_arg (Printf.sprintf "Playwright: %s locator must belong to the same frame" what);
    locator.selector

let make ?has_text ?has_text_regex ?has_not_text ?has_not_text_regex ?has ?has_not ?visible (frame : frame) selector : t =
    let filters =
        List.filter_map Fun.id
            [ Option.map Selector.has_text (text_option "has_text" has_text has_text_regex);
              Option.map Selector.has_not_text (text_option "has_not_text" has_not_text has_not_text_regex);
              Option.map (fun inner -> Selector.has (same_frame "the inner \"has\"" frame inner)) has;
              Option.map (fun inner -> Selector.has_not (same_frame "the inner \"has_not\"" frame inner)) has_not;
              Option.map Selector.visible visible ]
    in
    { l_frame = frame; selector = Selector.join (selector :: filters) }

(* The ways of finding elements that pages, frames, locators and frame locators all offer. *)
module Queries (T : sig
    type t

    val session : t -> session
    val find : t -> string -> locator
end) =
struct
    let get_by_text ?exact text t = T.find t (Selector.by_text ?exact (Text text))
    let get_by_text_regex regex t = T.find t (Selector.by_text (Regex regex))
    let get_by_label ?exact text t = T.find t (Selector.by_label ?exact (Text text))
    let get_by_label_regex regex t = T.find t (Selector.by_label (Regex regex))
    let get_by_placeholder ?exact text t = T.find t (Selector.by_placeholder ?exact (Text text))
    let get_by_placeholder_regex regex t = T.find t (Selector.by_placeholder (Regex regex))
    let get_by_alt_text ?exact text t = T.find t (Selector.by_alt_text ?exact (Text text))
    let get_by_alt_text_regex regex t = T.find t (Selector.by_alt_text (Regex regex))
    let get_by_title ?exact text t = T.find t (Selector.by_title ?exact (Text text))
    let get_by_title_regex regex t = T.find t (Selector.by_title (Regex regex))
    let get_by_test_id id t = T.find t (Selector.by_test_id ~attribute:(T.session t).selectors.test_id_attribute (Text id))
    let get_by_test_id_regex regex t = T.find t (Selector.by_test_id ~attribute:(T.session t).selectors.test_id_attribute (Regex regex))

    let get_by_role ?checked ?disabled ?selected ?expanded ?include_hidden ?level ?name ?name_regex ?description ?description_regex ?exact
        ?pressed (role : role) t =
        let text what plain regex : Selector.text option =
            match plain, regex with
            | Some _, Some _ -> invalid_arg (Printf.sprintf "Playwright: pass either ~%s or ~%s_regex, not both" what what)
            | Some text, None -> Some (Text text)
            | None, Some regex -> Some (Regex regex)
            | None, None -> None
        in
        T.find t
            (Selector.by_role ?checked ?disabled ?selected ?expanded ?include_hidden ?level ?name:(text "name" name name_regex)
                 ?description:(text "description" description description_regex) ?exact ?pressed (role_name role))
end

let locator ?has_text ?has_text_regex ?has_not_text ?has_not_text_regex ?has ?has_not selector (parent : t) =
    make ?has_text ?has_text_regex ?has_not_text ?has_not_text_regex ?has ?has_not parent.l_frame (Selector.join [ parent.selector; selector ])

include Queries (struct
    type t = locator

    let session (locator : t) = locator.l_frame.f_session
    let find (parent : t) selector = make parent.l_frame (Selector.join [ parent.selector; selector ])
end)

let refine (locator : t) part = { locator with selector = Selector.join [ locator.selector; part ] }

let within (outer : t) (inner : t) = refine outer (Selector.chain (same_frame "the inner" outer.l_frame inner))

let filter ?has_text ?has_text_regex ?has_not_text ?has_not_text_regex ?has ?has_not ?visible (locator : t) =
    make ?has_text ?has_text_regex ?has_not_text ?has_not_text_regex ?has ?has_not ?visible locator.l_frame locator.selector

let first locator = refine locator (Selector.nth 0)
let last locator = refine locator (Selector.nth (-1))
let nth index locator = refine locator (Selector.nth index)
let and_ (other : t) (locator : t) = refine locator (Selector.and_ (same_frame "the other" locator.l_frame other))
let or_ (other : t) (locator : t) = refine locator (Selector.or_ (same_frame "the other" locator.l_frame other))
let visible locator = refine locator (Selector.visible true)
let describe description locator = refine locator (Selector.describe description)
let frame_locator selector (locator : t) : frame_locator = { fl_frame = locator.l_frame; frame_selector = Selector.join [ locator.selector; selector ] }
let content_frame (locator : t) : frame_locator = { fl_frame = locator.l_frame; frame_selector = locator.selector }

let page (locator : t) = page_of_frame locator.l_frame
let frame (locator : t) = locator.l_frame
let selector (locator : t) = locator.selector
let to_string (locator : t) = "Locator@" ^ locator.selector
let equal (a : t) (b : t) = Frame.equal a.l_frame b.l_frame && String.equal a.selector b.selector
let compare (a : t) (b : t) = match Frame.compare a.l_frame b.l_frame with 0 -> String.compare a.selector b.selector | order -> order
let hash (locator : t) = Hashtbl.hash (Frame.hash locator.l_frame, locator.selector)

(* {1 Actions}

   Every action resolves the locator afresh and insists that it matches exactly one element. *)

let click ?timeout ?force ?no_wait_after ?modifiers ?position ?delay ?button ?click_count ?trial ?steps (l : t) =
    Frame.click ~strict:true ?timeout ?force ?no_wait_after ?modifiers ?position ?delay ?button ?click_count ?trial ?steps l.selector l.l_frame

let dblclick ?timeout ?force ?modifiers ?position ?delay ?button ?trial ?steps (l : t) =
    Frame.dblclick ~strict:true ?timeout ?force ?modifiers ?position ?delay ?button ?trial ?steps l.selector l.l_frame

let tap ?timeout ?force ?modifiers ?position ?trial (l : t) =
    Frame.tap ~strict:true ?timeout ?force ?modifiers ?position ?trial l.selector l.l_frame

let hover ?timeout ?force ?modifiers ?position ?trial (l : t) =
    Frame.hover ~strict:true ?timeout ?force ?modifiers ?position ?trial l.selector l.l_frame

let drag_to ?timeout ?force ?trial ?source_position ?target_position ?steps (target : t) (l : t) =
    Frame.drag_and_drop ~strict:true ?timeout ?force ?trial ?source_position ?target_position ?steps ~source:l.selector
        ~target:(same_frame "the target" l.l_frame target) l.l_frame

let fill ?timeout ?force value (l : t) = Frame.fill ~strict:true ?timeout ?force l.selector value l.l_frame
let clear ?timeout ?force (l : t) = fill ?timeout ?force "" l
let focus ?timeout (l : t) = Frame.focus ~strict:true ?timeout l.selector l.l_frame
let blur ?timeout (l : t) = Frame.blur ~strict:true ?timeout l.selector l.l_frame
let press ?timeout ?delay ?no_wait_after key (l : t) = Frame.press ~strict:true ?timeout ?delay ?no_wait_after l.selector key l.l_frame
let press_sequentially ?timeout ?delay text (l : t) = Frame.type_ ~strict:true ?timeout ?delay l.selector text l.l_frame
let check ?timeout ?force ?position ?trial (l : t) = Frame.check ~strict:true ?timeout ?force ?position ?trial l.selector l.l_frame
let uncheck ?timeout ?force ?position ?trial (l : t) = Frame.uncheck ~strict:true ?timeout ?force ?position ?trial l.selector l.l_frame

let set_checked ?timeout ?force ?position ?trial checked (l : t) =
    Frame.set_checked ~strict:true ?timeout ?force ?position ?trial l.selector checked l.l_frame

let select_option ?timeout ?force options (l : t) = Frame.select_option ~strict:true ?timeout ?force l.selector options l.l_frame
let set_input ?timeout files (l : t) = Frame.set_input ~strict:true ?timeout l.selector files l.l_frame
let set_input_files ?timeout paths (l : t) = set_input ?timeout (Frame.Paths paths) l
let set_input_payloads ?timeout payloads (l : t) = set_input ?timeout (Frame.Payloads payloads) l

let drop ?timeout ?position ?files ?payloads ?data (l : t) =
    let files =
        match files, payloads with
        | Some _, Some _ -> invalid_arg "Playwright: pass either ~files or ~payloads, not both"
        | Some paths, None -> Some (Frame.Paths paths)
        | None, Some payloads -> Some (Frame.Payloads payloads)
        | None, None -> None
    in
    Frame.drop ~strict:true ?timeout ?position ?files ?data l.selector l.l_frame

let dispatch_event ?timeout ?event_init type_ (l : t) = Frame.dispatch_event ~strict:true ?timeout ?event_init l.selector type_ l.l_frame

let highlight ?style (l : t) = Protocol.Frame.highlight ~selector:l.selector ?style l.l_frame.f_channel
let hide_highlight (l : t) = Protocol.Frame.hide_highlight ~selector:l.selector l.l_frame.f_channel

(* {1 Queries} *)

let get_attribute ?timeout name (l : t) = Frame.get_attribute ~strict:true ?timeout l.selector name l.l_frame
let text_content ?timeout (l : t) = Frame.text_content ~strict:true ?timeout l.selector l.l_frame
let inner_text ?timeout (l : t) = Frame.inner_text ~strict:true ?timeout l.selector l.l_frame
let inner_html ?timeout (l : t) = Frame.inner_html ~strict:true ?timeout l.selector l.l_frame
let input_value ?timeout (l : t) = Frame.input_value ~strict:true ?timeout l.selector l.l_frame
let is_checked ?timeout (l : t) = Frame.is_checked ~strict:true ?timeout l.selector l.l_frame
let is_disabled ?timeout (l : t) = Frame.is_disabled ~strict:true ?timeout l.selector l.l_frame
let is_editable ?timeout (l : t) = Frame.is_editable ~strict:true ?timeout l.selector l.l_frame
let is_enabled ?timeout (l : t) = Frame.is_enabled ~strict:true ?timeout l.selector l.l_frame
let is_hidden (l : t) = Frame.is_hidden ~strict:true l.selector l.l_frame
let is_visible (l : t) = Frame.is_visible ~strict:true l.selector l.l_frame

let count (l : t) = Protocol.Frame.query_count ~selector:l.selector l.l_frame.f_channel
let all (l : t) = List.init (count l) (fun index -> nth index l)

let all_inner_texts (l : t) =
    Frame.eval_on_selector_all l.selector "elements => elements.map(element => element.innerText)" l.l_frame |> Js.to_list Js.to_string

let all_text_contents (l : t) =
    Frame.eval_on_selector_all l.selector "elements => elements.map(element => element.textContent || '')" l.l_frame
    |> Js.to_list Js.to_string

let wait_for ?timeout ?state (l : t) =
    ignore
        (Protocol.Frame.wait_for_selector ~timeout:(Frame.action_timeout ?timeout l.l_frame) ~selector:l.selector ~strict:true ?state
             ~omit_return_value:true l.l_frame.f_channel)

let aria_snapshot ?timeout ?mode ?depth ?boxes (l : t) =
    Protocol.Frame.aria_snapshot ~timeout:(Frame.action_timeout ?timeout l.l_frame) ?mode ~selector:l.selector ?depth ?boxes l.l_frame.f_channel

let element_handle ?timeout (l : t) =
    match Frame.wait_for_selector ~strict:true ~state:`Attached ?timeout l.selector l.l_frame with
    | Some handle -> handle
    | None -> Error.raise_ "Could not resolve %s to DOM Element" l.selector

let element_handles (l : t) = Frame.query_selector_all l.selector l.l_frame

(* Resolves the locator to an element, waiting for it if needed, and gives [f] that element
   along with the time left. *)
let with_element ?timeout (l : t) f =
    let clock = l.l_frame.f_session.conn.clock in
    let timeout = Frame.action_timeout ?timeout l.l_frame in
    let started = Eio.Time.now clock in
    let handle = element_handle ~timeout l in
    Connection.protect l.l_frame.f_session.conn "disposing of an element handle"
        ~finally:(fun () -> try Js_handle.dispose handle with Error.E _ -> ())
        (fun () ->
            let remaining = if timeout > 0. then Float.max 1. (timeout -. ((Eio.Time.now clock -. started) *. 1000.)) else 0. in
            f handle remaining)

let evaluate ?timeout ?arg expression (l : t) = with_element ?timeout l (fun handle _ -> Js_handle.evaluate ?arg expression handle)
let evaluate_handle ?timeout ?arg expression (l : t) = with_element ?timeout l (fun handle _ -> Js_handle.evaluate_handle ?arg expression handle)
let evaluate_all ?arg expression (l : t) = Frame.eval_on_selector_all ?arg l.selector expression l.l_frame
let bounding_box ?timeout (l : t) = with_element ?timeout l (fun handle _ -> Element_handle.bounding_box handle)
let scroll_into_view_if_needed ?timeout (l : t) = with_element ?timeout l (fun handle timeout -> Element_handle.scroll_into_view_if_needed ~timeout handle)
let select_text ?timeout ?force (l : t) = with_element ?timeout l (fun handle timeout -> Element_handle.select_text ~timeout ?force handle)

let screenshot ?timeout ?path ?type_ ?quality ?omit_background ?caret ?animations ?scale ?mask ?mask_color ?style (l : t) =
    with_element ?timeout l (fun handle timeout ->
        Element_handle.screenshot ~timeout ?path ?type_ ?quality ?omit_background ?caret ?animations ?scale ?mask ?mask_color ?style handle)

(* Used by the assertions. *)
let expect ?expression_arg ?pseudo ?expected_text ?expected_number ?expected_value ?use_inner_text ~is_not ~timeout expression (l : t) =
    Frame.expect ~selector:l.selector ?expression_arg ?pseudo ?expected_text ?expected_number ?expected_value ?use_inner_text ~is_not ~timeout
        expression l.l_frame
