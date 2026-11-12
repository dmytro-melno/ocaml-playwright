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

(* The conditions on the text of an element: what it is to contain, and what it is to match. *)
let text_filters filter plain regex =
    [ (match plain with Some "" | None -> None | Some text -> Some (filter (Selector.Text text)));
      Option.map (fun regex -> filter (Selector.Regex regex)) regex ]

let same_frame what (frame : frame) (locator : t) =
    if locator.l_frame != frame then invalid_arg (Printf.sprintf "Playwright: %s locator must belong to the same frame" what);
    locator.selector

let make ?has_text ?has_text_regex ?has_not_text ?has_not_text_regex ?has ?has_not ?visible (frame : frame) selector : t =
    let filters =
        List.filter_map Fun.id
            (text_filters Selector.has_text has_text has_text_regex
            @ text_filters Selector.has_not_text has_not_text has_not_text_regex
            @ [ Option.map (fun inner -> Selector.has (same_frame "the inner \"has\"" frame inner)) has;
                Option.map (fun inner -> Selector.has_not (same_frame "the inner \"has_not\"" frame inner)) has_not;
                Option.map Selector.visible visible ])
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

(* What {!describe} gave the locator: the description is the last part of its selector. *)
let description (locator : t) = Selector.description locator.selector

let normalize (locator : t) =
    let resolved = Protocol.Frame.resolve_selector ~selector:locator.selector locator.l_frame.f_channel in
    { locator with selector = resolved.resolved_selector }
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

let channel (l : t) = l.l_frame.f_channel
let action_timeout ?timeout (l : t) = Frame.action_timeout ?timeout l.l_frame
let point = Option.map Frame.point

let click ?timeout ?force ?scroll ?no_wait_after ?modifiers ?position ?delay ?button ?click_count ?trial ?steps (l : t) =
    Protocol.Frame.click ~timeout:(action_timeout ?timeout l) ~selector:l.selector ~strict:true ?force ?scroll ?no_wait_after ?modifiers
        ?position:(point position) ?delay ?button ?click_count ?trial ?steps (channel l)

let dblclick ?timeout ?force ?scroll ?modifiers ?position ?delay ?button ?trial ?steps (l : t) =
    Protocol.Frame.dblclick ~timeout:(action_timeout ?timeout l) ~selector:l.selector ~strict:true ?force ?scroll ?modifiers
        ?position:(point position) ?delay ?button ?trial ?steps (channel l)

let tap ?timeout ?force ?scroll ?modifiers ?position ?trial (l : t) =
    Protocol.Frame.tap ~timeout:(action_timeout ?timeout l) ~selector:l.selector ~strict:true ?force ?scroll ?modifiers
        ?position:(point position) ?trial (channel l)

let hover ?timeout ?force ?scroll ?modifiers ?position ?trial (l : t) =
    Protocol.Frame.hover ~timeout:(action_timeout ?timeout l) ~selector:l.selector ~strict:true ?force ?scroll ?modifiers
        ?position:(point position) ?trial (channel l)

let drag_to ?timeout ?force ?scroll ?trial ?source_position ?target_position ?steps ~(target : t) (l : t) =
    Protocol.Frame.drag_and_drop ~timeout:(action_timeout ?timeout l) ~source:l.selector ~target:(same_frame "the target" l.l_frame target)
        ~strict:true ?force ?scroll ?trial ?source_position:(point source_position) ?target_position:(point target_position) ?steps (channel l)

let fill ?timeout ?force value (l : t) =
    Protocol.Frame.fill ~timeout:(action_timeout ?timeout l) ~selector:l.selector ~strict:true ~value ?force (channel l)

let clear ?timeout ?force (l : t) = fill ?timeout ?force "" l
let focus ?timeout (l : t) = Protocol.Frame.focus ~timeout:(action_timeout ?timeout l) ~selector:l.selector ~strict:true (channel l)
let blur ?timeout (l : t) = Protocol.Frame.blur ~timeout:(action_timeout ?timeout l) ~selector:l.selector ~strict:true (channel l)

let press ?timeout ?delay ?no_wait_after key (l : t) =
    Protocol.Frame.press ~timeout:(action_timeout ?timeout l) ~selector:l.selector ~strict:true ~key ?delay ?no_wait_after (channel l)

let press_sequentially ?timeout ?delay text (l : t) =
    Protocol.Frame.type_ ~timeout:(action_timeout ?timeout l) ~selector:l.selector ~strict:true ~text ?delay (channel l)

let check ?timeout ?force ?scroll ?position ?trial (l : t) =
    Protocol.Frame.check ~timeout:(action_timeout ?timeout l) ~selector:l.selector ~strict:true ?force ?scroll ?position:(point position) ?trial
        (channel l)

let uncheck ?timeout ?force ?scroll ?position ?trial (l : t) =
    Protocol.Frame.uncheck ~timeout:(action_timeout ?timeout l) ~selector:l.selector ~strict:true ?force ?scroll ?position:(point position) ?trial
        (channel l)

let set_checked ?timeout ?force ?scroll ?position ?trial checked (l : t) =
    if checked then check ?timeout ?force ?scroll ?position ?trial l else uncheck ?timeout ?force ?scroll ?position ?trial l

let select_option ?timeout ?force options (l : t) =
    Protocol.Frame.select_option ~timeout:(action_timeout ?timeout l) ~selector:l.selector ~strict:true ~options:(Frame.select_options options)
        ?force (channel l)

let set_input ?timeout files (l : t) =
    let converted = Frame.convert_input_files files in
    Protocol.Frame.set_input_files ~timeout:(action_timeout ?timeout l) ~selector:l.selector ~strict:true ?payloads:converted.payloads
        ?local_directory:converted.local_directory ?local_paths:converted.local_paths (channel l)

let set_input_files ?timeout paths (l : t) = set_input ?timeout (Frame.Paths paths) l
let set_input_payloads ?timeout payloads (l : t) = set_input ?timeout (Frame.Payloads payloads) l

(* Drops files, data or both onto the element, as a drag from outside the page would. *)
let drop ?timeout ?position ?files ?payloads ?(data = []) (l : t) =
    let converted =
        match files, payloads with
        | Some _, Some _ -> invalid_arg "Playwright: pass either ~files or ~payloads, not both"
        | Some paths, None -> Some (Frame.convert_input_files (Paths paths))
        | None, Some payloads -> Some (Frame.convert_input_files (Payloads payloads))
        | None, None -> None
    in
    (match converted with
    | Some { local_directory = Some _; _ } -> Error.raise_ "Dropping a directory is not supported, pass individual files."
    | _ -> ());
    let payloads =
        Option.bind converted (fun converted -> converted.payloads)
        |> Option.map
               (List.map (fun (payload : Protocol.Frame.Set_input_files_payloads.t) : Protocol.Frame.Drop_payloads.t ->
                    { name = payload.name; mime_type = payload.mime_type; buffer = payload.buffer }))
    in
    let data = List.map (fun (mime_type, value) : Protocol.Frame.Drop_data.t -> { mime_type; value }) data in
    Protocol.Frame.drop ~timeout:(action_timeout ?timeout l) ~selector:l.selector ~strict:true ?position:(point position) ?payloads
        ?local_paths:(Option.bind converted (fun converted -> converted.local_paths))
        ?data:(if data = [] then None else Some data)
        (channel l)

let dispatch_event ?timeout ?(event_init = Js.Undefined) type_ (l : t) =
    Protocol.Frame.dispatch_event ~timeout:(action_timeout ?timeout l) ~selector:l.selector ~strict:true ~type_
        ~event_init:(Js.to_argument event_init) (channel l)

let hide_highlight (l : t) = Protocol.Frame.hide_highlight ~selector:l.selector (channel l)

let highlight ?style (l : t) =
    Protocol.Frame.highlight ~selector:l.selector ?style (channel l);
    Disposable.registration l.l_frame.f_session.conn (fun () -> hide_highlight l)

(* {1 Queries} *)

let get_attribute ?timeout name (l : t) =
    Protocol.Frame.get_attribute ~timeout:(action_timeout ?timeout l) ~selector:l.selector ~strict:true ~name (channel l)

let text_content ?timeout (l : t) = Protocol.Frame.text_content ~timeout:(action_timeout ?timeout l) ~selector:l.selector ~strict:true (channel l)
let inner_text ?timeout (l : t) = Protocol.Frame.inner_text ~timeout:(action_timeout ?timeout l) ~selector:l.selector ~strict:true (channel l)
let inner_html ?timeout (l : t) = Protocol.Frame.inner_html ~timeout:(action_timeout ?timeout l) ~selector:l.selector ~strict:true (channel l)
let input_value ?timeout (l : t) = Protocol.Frame.input_value ~timeout:(action_timeout ?timeout l) ~selector:l.selector ~strict:true (channel l)
let is_checked ?timeout (l : t) = Protocol.Frame.is_checked ~timeout:(action_timeout ?timeout l) ~selector:l.selector ~strict:true (channel l)
let is_disabled ?timeout (l : t) = Protocol.Frame.is_disabled ~timeout:(action_timeout ?timeout l) ~selector:l.selector ~strict:true (channel l)
let is_editable ?timeout (l : t) = Protocol.Frame.is_editable ~timeout:(action_timeout ?timeout l) ~selector:l.selector ~strict:true (channel l)
let is_enabled ?timeout (l : t) = Protocol.Frame.is_enabled ~timeout:(action_timeout ?timeout l) ~selector:l.selector ~strict:true (channel l)
let is_hidden (l : t) = Protocol.Frame.is_hidden ~selector:l.selector ~strict:true (channel l)
let is_visible (l : t) = Protocol.Frame.is_visible ~selector:l.selector ~strict:true (channel l)

let count (l : t) = Protocol.Frame.query_count ~selector:l.selector (channel l)
let all (l : t) = List.init (count l) (fun index -> nth index l)

(* Calls the function that [expression] evaluates to with the array of all matching elements. *)
let evaluate_all ?(arg = Js.Undefined) expression (l : t) =
    Protocol.Frame.eval_on_selector_all ~selector:l.selector ~expression ~arg:(Js.to_argument arg) (channel l) |> Js.of_wire

let all_inner_texts (l : t) = evaluate_all "elements => elements.map(element => element.innerText)" l |> Js.to_list Js.to_string
let all_text_contents (l : t) = evaluate_all "elements => elements.map(element => element.textContent || '')" l |> Js.to_list Js.to_string

let wait_for ?timeout ?state (l : t) =
    ignore
        (Protocol.Frame.wait_for_selector ~timeout:(action_timeout ?timeout l) ~selector:l.selector ~strict:true ?state ~omit_return_value:true
           (channel l))

let aria_snapshot ?timeout ?mode ?depth ?boxes (l : t) =
    Protocol.Frame.aria_snapshot ~timeout:(action_timeout ?timeout l) ?mode ~selector:l.selector ?depth ?boxes (channel l)

let aria_snapshot_json ?timeout ?mode ?depth ?boxes (l : t) =
    Protocol.Frame.aria_snapshot_json ~timeout:(action_timeout ?timeout l) ?mode ~selector:l.selector ?depth ?boxes (channel l)

(* Waits until the expression, which is given the element, returns something truthy. *)
let wait_for_function ?timeout ?(arg = Js.Undefined) expression (l : t) =
    Protocol.Frame.wait_for_function ~timeout:(action_timeout ?timeout l) ~expression ~arg:(Js.to_argument arg) ~selector:l.selector
        ~strict:true (channel l)
    |> Option.iter (fun handle -> Js_handle.dispose (Types.js_handle handle))

(* {1 Operations on the element itself}

   The driver offers these for element handles only. *)

let element_handle ?timeout (l : t) =
    match
        Protocol.Frame.wait_for_selector ~timeout:(action_timeout ?timeout l) ~selector:l.selector ~strict:true ~state:`Attached (channel l)
    with
    | Some handle -> Types.element handle
    | None -> Error.raise_ "Could not resolve %s to DOM Element" l.selector

(* Resolves the locator to an element, waiting for it if needed, and gives [f] that element
   along with the time left. *)
let with_element ?timeout (l : t) f =
    let clock = l.l_frame.f_session.conn.clock in
    let timeout = action_timeout ?timeout l in
    let started = Eio.Time.now clock in
    let handle = element_handle ~timeout l in
    Connection.protect l.l_frame.f_session.conn "disposing of an element handle"
        ~finally:(fun () -> try Js_handle.dispose handle with Error.E _ -> ())
        (fun () ->
            let remaining = if timeout > 0. then Float.max 1. (timeout -. ((Eio.Time.now clock -. started) *. 1000.)) else 0. in
            f handle (element_channel handle) remaining)

let evaluate ?timeout ?arg expression (l : t) = with_element ?timeout l (fun handle _ _ -> Js_handle.evaluate ?arg expression handle)
let evaluate_handle ?timeout ?arg expression (l : t) = with_element ?timeout l (fun handle _ _ -> Js_handle.evaluate_handle ?arg expression handle)
let bounding_box ?timeout (l : t) = with_element ?timeout l (fun _ element _ -> Protocol.Element_handle.bounding_box element)

let scroll_into_view_if_needed ?timeout (l : t) =
    with_element ?timeout l (fun _ element timeout -> Protocol.Element_handle.scroll_into_view_if_needed ~timeout element)

let select_text ?timeout ?force (l : t) =
    with_element ?timeout l (fun _ element timeout -> Protocol.Element_handle.select_text ~timeout ?force element)

let screenshot ?timeout ?type_ ?quality ?omit_background ?caret ?animations ?scale ?mask ?mask_color ?style (l : t) =
    with_element ?timeout l (fun _ element timeout ->
        Protocol.Element_handle.screenshot ~timeout ?type_ ?quality ?omit_background ?caret ?animations ?scale
            ?mask:(Option.map Screenshot.mask mask) ?mask_color ?style element)

(* Used by the assertions. *)
let expect ?expression_arg ?pseudo ?expected_text ?expected_number ?expected_value ?use_inner_text ~is_not ~timeout expression (l : t) =
    Frame.expect ~selector:l.selector ?expression_arg ?pseudo ?expected_text ?expected_number ?expected_value ?use_inner_text ~is_not ~timeout
        expression l.l_frame
