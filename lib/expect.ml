(* Assertions that retry until they hold or time out. *)

open Types

let timeout_setting = ref 5_000.
let set_default_timeout timeout = timeout_setting := timeout

let text_values ?match_substring ?normalize_white_space ?ignore_case (items : Selector.text list) : Protocol.Expected_text_value.t list =
    List.map
        (fun (item : Selector.text) : Protocol.Expected_text_value.t ->
            match item with
            | Text text -> { string = Some text; regex_source = None; regex_flags = None; match_substring; ignore_case; normalize_white_space }
            | Regex literal ->
                let source, flags = Selector.parse_regex literal in
                { string = None; regex_source = Some source; regex_flags = Some flags; match_substring; ignore_case; normalize_white_space })
        items

let show_text : Selector.text -> string = function Text text -> Printf.sprintf "%S" text | Regex literal -> literal
let show_texts items = "[" ^ String.concat ", " (List.map show_text items) ^ "]"

(* Raises unless the outcome is the one wanted. *)
let verdict ~is_not ~subject ~condition (outcome : Frame.expectation) =
    if outcome.matches = is_not then begin
        let received =
            match outcome.received, outcome.received_aria_snapshot with
            | Some value, _ -> Printf.sprintf "\nReceived: %s" (Js.show value)
            | None, Some snapshot -> Printf.sprintf "\nReceived:\n%s" snapshot
            | None, None -> ""
        in
        let message =
            match outcome.error_message with
            | Some message -> message
            | None -> Printf.sprintf "%s expected %s%s%s" subject (if is_not then "not " else "") condition received
        in
        raise (Error.E (Error.make ~kind:Assertion_failed ~log:outcome.log (message ^ Error.call_log outcome.log)))
    end

module Make (Polarity : sig
    val is_not : bool
end) =
struct
    let is_not = Polarity.is_not

    let locator ?timeout ?expression_arg ?pseudo ?expected_text ?expected_number ?expected_value ?use_inner_text expression ~condition (l : locator) =
        let timeout = Option.value timeout ~default:!timeout_setting in
        Locator.expect ?expression_arg ?pseudo ?expected_text ?expected_number ?expected_value ?use_inner_text ~is_not ~timeout expression l
        |> verdict ~is_not ~subject:(Locator.to_string l) ~condition

    let page ?timeout ?expected_text expression ~condition (p : page) =
        let timeout = Option.value timeout ~default:!timeout_setting in
        Frame.expect ?expected_text ~is_not ~timeout expression p.main_frame |> verdict ~is_not ~subject:"Page" ~condition

    (* {1 State} *)

    let to_be_attached ?timeout l = locator ?timeout "to.be.attached" ~condition:"to be attached" l
    let to_be_detached ?timeout l = locator ?timeout "to.be.detached" ~condition:"to be detached" l
    let to_be_visible ?timeout l = locator ?timeout "to.be.visible" ~condition:"to be visible" l
    let to_be_hidden ?timeout l = locator ?timeout "to.be.hidden" ~condition:"to be hidden" l
    let to_be_enabled ?timeout l = locator ?timeout "to.be.enabled" ~condition:"to be enabled" l
    let to_be_disabled ?timeout l = locator ?timeout "to.be.disabled" ~condition:"to be disabled" l
    let to_be_editable ?timeout l = locator ?timeout "to.be.editable" ~condition:"to be editable" l
    let to_be_read_only ?timeout l = locator ?timeout "to.be.readonly" ~condition:"to be read-only" l
    let to_be_empty ?timeout l = locator ?timeout "to.be.empty" ~condition:"to be empty" l
    let to_be_focused ?timeout l = locator ?timeout "to.be.focused" ~condition:"to be focused" l

    let to_be_checked ?timeout ?(checked = true) l =
        locator ?timeout ~expected_value:(Js.Object [ "checked", Js.Bool checked ]) "to.be.checked"
            ~condition:(if checked then "to be checked" else "to be unchecked") l

    let to_be_indeterminate ?timeout l =
        locator ?timeout ~expected_value:(Js.Object [ "indeterminate", Js.Bool true ]) "to.be.checked" ~condition:"to be indeterminate" l

    let to_be_in_viewport ?timeout ?ratio l = locator ?timeout ?expected_number:ratio "to.be.in.viewport" ~condition:"to be in viewport" l

    (* {1 Text} *)

    let have_text ?timeout ?ignore_case ?use_inner_text text l =
        locator ?timeout ~expected_text:(text_values ~normalize_white_space:true ?ignore_case [ text ]) ?use_inner_text "to.have.text"
            ~condition:("to have text " ^ show_text text) l

    let to_have_text ?timeout ?ignore_case ?use_inner_text text l = have_text ?timeout ?ignore_case ?use_inner_text (Text text) l
    let to_have_text_regex ?timeout ?use_inner_text regex l = have_text ?timeout ?use_inner_text (Regex regex) l

    let to_contain_text ?timeout ?ignore_case ?use_inner_text text l =
        locator ?timeout ~expected_text:(text_values ~match_substring:true ~normalize_white_space:true ?ignore_case [ Text text ]) ?use_inner_text
            "to.have.text" ~condition:(Printf.sprintf "to contain text %S" text) l

    (* One expected text per matching element, in order. *)
    let to_have_texts ?timeout ?ignore_case ?use_inner_text texts l =
        let texts = List.map (fun text -> Selector.Text text) texts in
        locator ?timeout ~expected_text:(text_values ~normalize_white_space:true ?ignore_case texts) ?use_inner_text "to.have.text.array"
            ~condition:("to have texts " ^ show_texts texts) l

    let to_contain_texts ?timeout ?ignore_case ?use_inner_text texts l =
        let texts = List.map (fun text -> Selector.Text text) texts in
        locator ?timeout ~expected_text:(text_values ~match_substring:true ~normalize_white_space:true ?ignore_case texts) ?use_inner_text
            "to.contain.text.array" ~condition:("to contain texts " ^ show_texts texts) l

    (* {1 Attributes and properties} *)

    let simple_text expression what ?timeout ?ignore_case ?normalize_white_space ?expression_arg text l =
        locator ?timeout ?expression_arg ~expected_text:(text_values ?ignore_case ?normalize_white_space [ text ]) expression
            ~condition:(Printf.sprintf "to have %s %s" what (show_text text)) l

    let to_have_attribute ?timeout ?ignore_case name value l =
        simple_text "to.have.attribute.value" ("attribute " ^ name) ?timeout ?ignore_case ~expression_arg:(`String name) (Text value) l

    let to_have_attribute_regex ?timeout name regex l =
        simple_text "to.have.attribute.value" ("attribute " ^ name) ?timeout ~expression_arg:(`String name) (Regex regex) l

    let to_have_attribute_present ?timeout name l =
        locator ?timeout ~expression_arg:(`String name) "to.have.attribute" ~condition:("to have attribute " ^ name) l

    let to_have_class ?timeout class_ l = simple_text "to.have.class" "class" ?timeout (Text class_) l
    let to_have_class_regex ?timeout regex l = simple_text "to.have.class" "class" ?timeout (Regex regex) l

    let to_contain_class ?timeout class_ l =
        locator ?timeout ~expected_text:(text_values [ Text class_ ]) "to.contain.class" ~condition:(Printf.sprintf "to contain class %S" class_) l

    let to_have_id ?timeout id l = simple_text "to.have.id" "id" ?timeout (Text id) l
    let to_have_role ?timeout role l = simple_text "to.have.role" "role" ?timeout (Text (Locator.role_name role)) l
    let to_have_value ?timeout value l = simple_text "to.have.value" "value" ?timeout (Text value) l
    let to_have_value_regex ?timeout regex l = simple_text "to.have.value" "value" ?timeout (Regex regex) l

    let to_have_values ?timeout values l =
        let values = List.map (fun value -> Selector.Text value) values in
        locator ?timeout ~expected_text:(text_values values) "to.have.values" ~condition:("to have values " ^ show_texts values) l

    let to_have_css ?timeout ?pseudo name value l =
        locator ?timeout ?pseudo ~expression_arg:(`String name) ~expected_text:(text_values [ Text value ]) "to.have.css"
            ~condition:(Printf.sprintf "to have CSS property %s %S" name value) l

    let to_have_js_property ?timeout name value l =
        locator ?timeout ~expression_arg:(`String name) ~expected_value:value "to.have.property"
            ~condition:(Printf.sprintf "to have JavaScript property %s %s" name (Js.show value)) l

    let to_have_count ?timeout count l =
        locator ?timeout ~expected_number:(float_of_int count) "to.have.count" ~condition:(Printf.sprintf "to have count %d" count) l

    let to_have_accessible_name ?timeout ?ignore_case name l =
        simple_text "to.have.accessible.name" "accessible name" ?timeout ?ignore_case ~normalize_white_space:true (Text name) l

    let to_have_accessible_name_regex ?timeout regex l =
        simple_text "to.have.accessible.name" "accessible name" ?timeout ~normalize_white_space:true (Regex regex) l

    let to_have_accessible_description ?timeout ?ignore_case description l =
        simple_text "to.have.accessible.description" "accessible description" ?timeout ?ignore_case ~normalize_white_space:true (Text description) l

    let to_have_accessible_description_regex ?timeout regex l =
        simple_text "to.have.accessible.description" "accessible description" ?timeout ~normalize_white_space:true (Regex regex) l

    (* {1 Pages} *)

    let to_have_title ?timeout title p =
        page ?timeout ~expected_text:(text_values ~normalize_white_space:true [ Text title ]) "to.have.title"
            ~condition:(Printf.sprintf "to have title %S" title) p

    let to_have_title_regex ?timeout regex p =
        page ?timeout ~expected_text:(text_values ~normalize_white_space:true [ Regex regex ]) "to.have.title" ~condition:("to have title " ^ regex) p

    (* A URL that is relative to the context's base URL is resolved against it. *)
    let to_have_url ?timeout ?ignore_case url (p : page) =
        let url =
            match p.context.base_url with
            | Some base when String.length url > 0 && url.[0] = '/' ->
                (* Keep the origin of the base URL: everything up to the first slash after "://". *)
                let after_scheme = match String.index_opt base ':' with Some i when i + 3 <= String.length base -> i + 3 | _ -> 0 in
                let origin_end = match String.index_from_opt base after_scheme '/' with Some i -> i | None -> String.length base in
                String.sub base 0 origin_end ^ url
            | _ -> url
        in
        page ?timeout ~expected_text:(text_values ?ignore_case [ Text url ]) "to.have.url" ~condition:(Printf.sprintf "to have URL %S" url) p

    let to_have_url_regex ?timeout regex p =
        page ?timeout ~expected_text:(text_values [ Regex regex ]) "to.have.url" ~condition:("to have URL " ^ regex) p

    (* {1 API responses} *)

    let to_be_ok (response : api_response) =
        let ok = Api_request.Response.ok response in
        if ok = is_not then begin
            let log = try Protocol.Api_request_context.fetch_log ~fetch_uid:response.ar_init.fetch_uid response.ar_context.a_channel with Error.E _ -> [] in
            let message =
                Printf.sprintf "Response expected %sto be OK\nReceived: %d %s for %s" (if is_not then "not " else "") response.ar_init.status
                    response.ar_init.status_text response.ar_init.url
            in
            raise (Error.E (Error.make ~kind:Assertion_failed ~log (message ^ Error.call_log log)))
        end
end

include Make (struct
    let is_not = false
end)

module Not = Make (struct
    let is_not = true
end)
