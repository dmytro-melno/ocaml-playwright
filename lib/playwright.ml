module Transport  = Transport
module Driver     = Driver
module Connection = Connection
module Internal   = Api.Internal
include (Api : module type of Api with module Internal := Api.Internal)

module Value = struct
    let rec parse_serialized_value (v : SerializedValue.t) : Yojson.Safe.t =
        match v with
        | { n = Some n; _ } -> `Float n
        | { b = Some b; _ } -> `Bool b
        | { s = Some s; _ } -> `String s
        | { v = Some (`Null | `Undefined); _ } -> `Null
        | { v = Some `Nan; _ } -> `String "NaN"
        | { v = Some `Inf; _ } -> `String "Infinity"
        | { v = Some `Minus_inf; _ } -> `String "-Infinity"
        | { v = Some `Minus_zero; _ } -> `Float (-0.0)
        | { d = Some d; _ } -> `String d
        | { u = Some u; _ } -> `String u
        | { bi = Some bi; _ } -> `String bi
        | { e = Some e; _ } -> `Assoc ["message", `String e.m; "name", `String e.n; "stack", `String e.s]
        | { r = Some r; _ } -> `Assoc ["pattern", `String r.p; "flags", `String r.f]
        | { a = Some a; _ } -> `List (a |> Array.to_list |> List.map parse_serialized_value)
        | { o = Some o; _ } -> `Assoc (o |> Array.to_list |> List.map (fun (x : SerializedValue.O.t) -> x.k, parse_serialized_value x.v))
        | _ -> `Null

    let rec build_serialized_value (j : Yojson.Safe.t) : SerializedValue.t =
        let empty = SerializedValue.Wrap.{
            n = None; b = None; s = None; v = None; d = None; u = None; bi = None;
            ta = None; e = None; r = None; a = None; o = None; h = None; id = None; ref = None
        } in
        match j with
        | `Null -> { empty with v = Some `Null }
        | `Bool b -> { empty with b = Some b }
        | `Int i -> { empty with n = Some (float_of_int i) }
        | `Intlit s -> { empty with n = Some (float_of_string s) }
        | `Float f -> { empty with n = Some f }
        | `String s -> { empty with s = Some s }
        | `List items -> { empty with a = Some (items |> List.map build_serialized_value |> Array.of_list) }
        | `Assoc fields ->
            let o = fields |> List.map (fun (k, v) -> SerializedValue.O.{ k; v = build_serialized_value v }) |> Array.of_list in
            { empty with o = Some o }

    let parse_serialized_argument (a : SerializedArgument.t) : Yojson.Safe.t =
        parse_serialized_value a.value

    let build_serialized_argument (j : Yojson.Safe.t) : SerializedArgument.t =
        SerializedArgument.Wrap.{ value = build_serialized_value j; handles = [||] }
end

module BrowserContext = struct
    include Api.BrowserContext

    let set_test_id_attribute_name ~test_id_attribute_name t =
        Api.BrowserContext.set_test_id_attribute_name ~test_id_attribute_name t;
        let conn = Internal.connection t in
        Option.iter (fun obj -> obj.Connection.test_id_attribute_name <- Some test_id_attribute_name)
            (Hashtbl.find_opt conn.Connection.objects (Internal.guid t))
end

module Locator_utils = struct
    (* Nested selectors and text matchers are JSON; attribute matchers have
       their own grammar, which preserves literal control characters. 1.59.1:
       locatorUtils.js and stringUtils.js. *)
    let escape_for_selector s = Yojson.Safe.to_string (`String s)
    let text_matcher ~exact s = escape_for_selector s ^ if exact then "s" else "i"

    let attribute_matcher ~exact s =
        let buf = Buffer.create (String.length s + 3) in
        Buffer.add_char buf '"';
        String.iter (function
            | '"' -> Buffer.add_string buf "\\\""
            | '\\' -> Buffer.add_string buf "\\\\"
            | c -> Buffer.add_char buf c) s;
        Buffer.add_string buf (if exact then "\"s" else "\"i");
        Buffer.contents buf

    let get_by_text ?(exact = false) text = "internal:text=" ^ text_matcher ~exact text
    let get_by_label ?(exact = false) text = "internal:label=" ^ text_matcher ~exact text

    let get_by_role ?name ?(exact = false) role =
        "internal:role=" ^ role ^
        match name with None -> "" | Some name -> "[name=" ^ attribute_matcher ~exact name ^ "]"

    let by_attribute ?(exact = false) attribute text =
        "internal:attr=[" ^ attribute ^ "=" ^ attribute_matcher ~exact text ^ "]"

    let get_by_placeholder ?exact text = by_attribute ?exact "placeholder" text
    let get_by_alt_text ?exact text = by_attribute ?exact "alt" text
    let get_by_title ?exact text = by_attribute ?exact "title" text

    let test_id_attribute frame =
        let conn = Internal.connection frame in
        (match Connection.closed_reason conn with Some reason -> raise (Error reason) | None -> ());
        let context =
            Option.bind (Hashtbl.find_opt conn.Connection.objects (Internal.guid frame))
                (fun obj -> Option.bind obj.Connection.context_guid (Hashtbl.find_opt conn.objects))
        in
        Option.value ~default:"data-testid"
            (Option.bind context (fun obj -> obj.Connection.test_id_attribute_name))

    let get_by_test_id ?(attribute = "data-testid") id =
        "internal:testid=[" ^ attribute ^ "=" ^ attribute_matcher ~exact:true id ^ "]"
end

(* Private implementation shared by handle-based Locator operations.
   Acquisition is one ordinary RPC, not a series of short selector attempts.
   Only cancellation after transmission enters bounded response recovery. *)
module Locator_element = struct
    let now () = Mtime.Span.to_float_ns (Mtime_clock.elapsed ()) /. 1_000_000.
    let deadline ?(timeout = 30000.) () =
        if not (Float.is_finite timeout) || timeout < 0. then
            invalid_arg "Locator timeout must be finite and nonnegative (milliseconds)";
        if timeout = 0. then None else Some (now () +. timeout)

    let remaining = function
        | None -> 0.
        | Some deadline ->
            let timeout = deadline -. now () in
            if timeout <= 0. then raise (Error "TimeoutError: Locator deadline exceeded");
            timeout

    (* This bounds recovery/cleanup, never an uncanceled acquisition. There is
       no per-request remote cancel in 1.59.1: if a canceled, transmitted
       resource-producing request cannot settle, close rather than orphan it. *)
    let recover conn operation f =
        Eio.Cancel.protect (fun () ->
            Eio.Fiber.first f (fun () ->
                Eio_unix.sleep 1.;
                let reason = "Locator " ^ operation ^ " did not settle within the 1s ownership recovery deadline" in
                Connection.close conn reason;
                raise (Error reason)))

    let dispose handle =
        let conn = Internal.connection handle in
        if Connection.closed_reason conn = None then
            try recover conn "handle disposal" (fun () -> Api.ElementHandle.dispose handle) with
            | Error message when String.starts_with ~prefix:"TargetClosedError:" message ->
                (* C04 does not recursively remove children on target closure. *)
                Hashtbl.remove conn.Connection.objects (Internal.guid handle)
            | ex ->
                Connection.close conn ("Locator handle disposal failed: " ^ Printexc.to_string ex);
                raise ex

    let release_after_error handle =
        try dispose handle with ex ->
            Printf.eprintf "Playwright Locator cleanup: %s\n%!" (Printexc.to_string ex)

    let request frame ~method_ ~params =
        Eio.Fiber.check ();
        let conn = Internal.connection frame in
        try
            match Connection.send_message conn ~guid:(Internal.guid frame) ~method_ ~params
                ~on_cancel:(recover conn ("canceled " ^ method_ ^ " response")) with
            | Ok result -> result
            | Error reason -> raise (Error reason)
        with ex ->
            let bt = Printexc.get_raw_backtrace () in
            (* A remote/cleanup error must not replace the caller cancellation
               that started recovery. Successful replies are decoded below
               before checking cancellation, to retain handle ownership. *)
            Eio.Fiber.check ();
            Printexc.raise_with_backtrace ex bt

    let decode_handles frame decode result =
        let conn = Internal.connection frame in
        try Eio.Fiber.with_binding Connection.current_connection_key conn (fun () ->
            let handle value =
                match Api.ElementHandle.of_yojson value with
                | Ok handle -> handle
                | Error reason -> failwith reason
            in
            decode handle result)
        with ex ->
            (* Malformed resource-bearing replies leave ownership unknowable.
               A closed session owns no live handles. No broad codec rewrite. *)
            let bt = Printexc.get_raw_backtrace () in
            Connection.close conn ("Locator handle response decoding failed: " ^ Printexc.to_string ex);
            Eio.Fiber.check ();
            Printexc.raise_with_backtrace ex bt

    let acquire ~deadline ~selector frame =
        (* The two narrow wire calls here reuse the generated handle decoder.
           They need Connection's explicit response-ownership hook; raw Frame
           calls keep their original local-cancellation contract. *)
        let result = request frame ~method_:"waitForSelector" ~params:(`Assoc [
            "selector", `String selector; "strict", `Bool true;
            "state", `String "attached"; "timeout", `Float (remaining deadline);
        ]) in
        let handle = decode_handles frame (fun decode result ->
            match Yojson.Safe.Util.member "element" result with
            | `Null -> None
            | value -> Some (decode value)) result in
        match handle with
        | Some handle ->
            (try Eio.Fiber.check (); handle with ex ->
                let bt = Printexc.get_raw_backtrace () in
                release_after_error handle;
                Printexc.raise_with_backtrace ex bt)
        | None ->
            Eio.Fiber.check ();
            raise (Error ("Could not resolve " ^ selector ^ " to DOM Element"))

    let acquire_all ~selector frame =
        let result = request frame ~method_:"querySelectorAll"
            ~params:(`Assoc ["selector", `String selector]) in
        let handles = decode_handles frame (fun decode result ->
            Yojson.Safe.Util.member "elements" result |> Yojson.Safe.Util.to_list
            |> List.map decode |> Array.of_list) result in
        try Eio.Fiber.check (); handles with ex ->
            let bt = Printexc.get_raw_backtrace () in
            Array.iter release_after_error handles;
            Printexc.raise_with_backtrace ex bt

    let with_element ?timeout ~selector frame task =
        let deadline = deadline ?timeout () in
        let handle = acquire ~deadline ~selector frame in
        match task handle (fun () -> remaining deadline) with
        | value ->
            (try dispose handle with ex ->
                let bt = Printexc.get_raw_backtrace () in
                if Eio.Fiber.is_cancelled () then begin
                    Printf.eprintf "Playwright Locator cleanup: %s\n%!" (Printexc.to_string ex);
                    Eio.Fiber.check ()
                end;
                Printexc.raise_with_backtrace ex bt);
            Eio.Fiber.check ();
            value
        | exception ex ->
            let bt = Printexc.get_raw_backtrace () in
            release_after_error handle;
            Printexc.raise_with_backtrace ex bt
end

module rec Frame : sig
    include module type of Api.Frame
    val locator : selector:string -> t -> Locator.t
    val get_by_text : ?exact:bool -> string -> t -> Locator.t
    val get_by_role : ?name:string -> ?exact:bool -> string -> t -> Locator.t
    val get_by_label : ?exact:bool -> string -> t -> Locator.t
    val get_by_placeholder : ?exact:bool -> string -> t -> Locator.t
    val get_by_alt_text : ?exact:bool -> string -> t -> Locator.t
    val get_by_title : ?exact:bool -> string -> t -> Locator.t
    val get_by_test_id : string -> t -> Locator.t

    val evaluate : expression:string -> ?is_function:bool -> ?arg:Yojson.Safe.t -> t -> Yojson.Safe.t
    val evaluate_handle : expression:string -> ?is_function:bool -> ?arg:Yojson.Safe.t -> t -> Api.JSHandle.t
    val eval_on_selector : selector:string -> ?strict:bool -> expression:string -> ?is_function:bool -> ?arg:Yojson.Safe.t -> t -> Yojson.Safe.t
    val eval_on_selector_all : selector:string -> expression:string -> ?is_function:bool -> ?arg:Yojson.Safe.t -> t -> Yojson.Safe.t
    val wait_for_function : expression:string -> ?is_function:bool -> ?arg:Yojson.Safe.t -> ?timeout:float -> ?polling_interval:float -> t -> Api.JSHandle.t
    val dispatch_event : selector:string -> ?strict:bool -> type_:string -> ?event_init:Yojson.Safe.t -> ?timeout:float -> t -> unit
    val expect : ?selector:string -> expression:string -> ?expression_arg:Yojson.Safe.t -> ?pseudo:Pseudo.t -> ?expected_text:Api.ExpectedTextValue.t array -> ?expected_number:float -> ?expected_value:Yojson.Safe.t -> ?use_inner_text:bool -> is_not:bool -> ?timeout:float -> t -> ExpectResult.t
end = struct
    include Api.Frame
    let locator ~selector t = Locator.create ~selector t

    let get_by_text ?exact text t        = locator ~selector:(Locator_utils.get_by_text ?exact text) t
    let get_by_role ?name ?exact role t  = locator ~selector:(Locator_utils.get_by_role ?name ?exact role) t
    let get_by_label ?exact text t       = locator ~selector:(Locator_utils.get_by_label ?exact text) t
    let get_by_placeholder ?exact text t = locator ~selector:(Locator_utils.get_by_placeholder ?exact text) t
    let get_by_alt_text ?exact text t    = locator ~selector:(Locator_utils.get_by_alt_text ?exact text) t
    let get_by_title ?exact text t       = locator ~selector:(Locator_utils.get_by_title ?exact text) t
    let get_by_test_id id t              = locator ~selector:(Locator_utils.get_by_test_id ~attribute:(Locator_utils.test_id_attribute t) id) t

    let evaluate ~expression ?is_function ?(arg = `Null) t =
        evaluate_expression_raw ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t |> Value.parse_serialized_value

    let evaluate_handle ~expression ?is_function ?(arg = `Null) t =
        evaluate_expression_handle_raw ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t

    let eval_on_selector ~selector ?strict ~expression ?is_function ?(arg = `Null) t =
        eval_on_selector_raw ~selector ?strict ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t |> Value.parse_serialized_value

    let eval_on_selector_all ~selector ~expression ?is_function ?(arg = `Null) t =
        eval_on_selector_all_raw ~selector ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t |> Value.parse_serialized_value

    let wait_for_function ~expression ?is_function ?(arg = `Null) ?timeout ?polling_interval t =
        wait_for_function_raw ~expression ?is_function ~arg:(Value.build_serialized_argument arg) ?timeout ?polling_interval t

    let dispatch_event ~selector ?strict ~type_ ?(event_init = `Null) ?timeout t =
        dispatch_event_raw ~selector ?strict ~type_ ~event_init:(Value.build_serialized_argument event_init) ?timeout t

    let expect ?selector ~expression ?expression_arg ?pseudo ?expected_text ?expected_number ?(expected_value = `Null) ?use_inner_text ~is_not ?timeout t =
        let expected_value_arg = if expected_value = `Null then None else Some (Value.build_serialized_argument expected_value) in
        expect_raw ?selector ~expression ?expression_arg ?pseudo ?expected_text ?expected_number ?expected_value:expected_value_arg ?use_inner_text ~is_not ?timeout t
end

and Page : sig
    include module type of Api.Page with module Locator := Api.Page.Locator
    val locator : selector:string -> t -> Locator.t
    val get_by_text : ?exact:bool -> string -> t -> Locator.t
    val get_by_role : ?name:string -> ?exact:bool -> string -> t -> Locator.t
    val get_by_label : ?exact:bool -> string -> t -> Locator.t
    val get_by_placeholder : ?exact:bool -> string -> t -> Locator.t
    val get_by_alt_text : ?exact:bool -> string -> t -> Locator.t
    val get_by_title : ?exact:bool -> string -> t -> Locator.t
    val get_by_test_id : string -> t -> Locator.t

    val evaluate : expression:string -> ?is_function:bool -> ?arg:Yojson.Safe.t -> t -> Yojson.Safe.t
    val evaluate_handle : expression:string -> ?is_function:bool -> ?arg:Yojson.Safe.t -> t -> Api.JSHandle.t
    val eval_on_selector : selector:string -> ?strict:bool -> expression:string -> ?is_function:bool -> ?arg:Yojson.Safe.t -> t -> Yojson.Safe.t
    val eval_on_selector_all : selector:string -> expression:string -> ?is_function:bool -> ?arg:Yojson.Safe.t -> t -> Yojson.Safe.t
    val wait_for_function : expression:string -> ?is_function:bool -> ?arg:Yojson.Safe.t -> ?timeout:float -> ?polling_interval:float -> t -> Api.JSHandle.t
    val dispatch_event : selector:string -> ?strict:bool -> type_:string -> ?event_init:Yojson.Safe.t -> ?timeout:float -> t -> unit
    val expect : ?selector:string -> expression:string -> ?expression_arg:Yojson.Safe.t -> ?pseudo:Frame.Pseudo.t -> ?expected_text:Api.ExpectedTextValue.t array -> ?expected_number:float -> ?expected_value:Yojson.Safe.t -> ?use_inner_text:bool -> is_not:bool -> ?timeout:float -> t -> Frame.ExpectResult.t
end = struct
    module Top_Locator = Locator
    include (Api.Page : module type of Api.Page with module Locator := Api.Page.Locator)
    let locator ~selector t = Top_Locator.create ~selector (main_frame t)

    let get_by_text ?exact text t        = locator ~selector:(Locator_utils.get_by_text ?exact text) t
    let get_by_role ?name ?exact role t  = locator ~selector:(Locator_utils.get_by_role ?name ?exact role) t
    let get_by_label ?exact text t       = locator ~selector:(Locator_utils.get_by_label ?exact text) t
    let get_by_placeholder ?exact text t = locator ~selector:(Locator_utils.get_by_placeholder ?exact text) t
    let get_by_alt_text ?exact text t    = locator ~selector:(Locator_utils.get_by_alt_text ?exact text) t
    let get_by_title ?exact text t       = locator ~selector:(Locator_utils.get_by_title ?exact text) t
    let get_by_test_id id t              = locator ~selector:(Locator_utils.get_by_test_id ~attribute:(Locator_utils.test_id_attribute (main_frame t)) id) t

    let evaluate ~expression ?is_function ?(arg = `Null) t =
        evaluate_expression_raw ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t |> Value.parse_serialized_value

    let evaluate_handle ~expression ?is_function ?(arg = `Null) t =
        evaluate_expression_handle_raw ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t

    let eval_on_selector ~selector ?strict ~expression ?is_function ?(arg = `Null) t =
        eval_on_selector_raw ~selector ?strict ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t |> Value.parse_serialized_value

    let eval_on_selector_all ~selector ~expression ?is_function ?(arg = `Null) t =
        eval_on_selector_all_raw ~selector ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t |> Value.parse_serialized_value

    let wait_for_function ~expression ?is_function ?(arg = `Null) ?timeout ?polling_interval t =
        wait_for_function_raw ~expression ?is_function ~arg:(Value.build_serialized_argument arg) ?timeout ?polling_interval t

    let dispatch_event ~selector ?strict ~type_ ?(event_init = `Null) ?timeout t =
        dispatch_event_raw ~selector ?strict ~type_ ~event_init:(Value.build_serialized_argument event_init) ?timeout t

    let expect ?selector ~expression ?expression_arg ?pseudo ?expected_text ?expected_number ?(expected_value = `Null) ?use_inner_text ~is_not ?timeout t =
        Frame.expect ?selector ~expression ?expression_arg ?pseudo ?expected_text ?expected_number ~expected_value ?use_inner_text ~is_not ?timeout (main_frame t)
end

and Locator : sig
    type t = {
        frame : Api.Frame.t;
        selector : string;
    }
    val create : selector:string -> Api.Frame.t -> t
    val locator : selector:string -> t -> t
    val click : ?strict:bool -> ?force:bool -> ?no_wait_after:bool -> ?modifiers:Frame.Modifiers.t array -> ?position:Api.Point.t -> ?delay:float -> ?button:Frame.Button.t -> ?click_count:int -> ?timeout:float -> ?trial:bool -> ?steps:int -> t -> unit
    val fill : ?strict:bool -> ?force:bool -> ?timeout:float -> value:string -> t -> unit
    val press : ?strict:bool -> ?delay:float -> ?no_wait_after:bool -> ?timeout:float -> key:string -> t -> unit
    val get_attribute : ?strict:bool -> ?timeout:float -> name:string -> t -> string option
    val text_content : ?strict:bool -> ?timeout:float -> t -> string option
    val inner_text : ?strict:bool -> ?timeout:float -> t -> string
    val inner_html : ?strict:bool -> ?timeout:float -> t -> string
    val count : t -> int
    val evaluate : expression:string -> ?is_function:bool -> ?arg:Yojson.Safe.t -> ?timeout:float -> t -> Yojson.Safe.t
    val evaluate_all : expression:string -> ?is_function:bool -> ?arg:Yojson.Safe.t -> t -> Yojson.Safe.t
    val wait_for : ?state:Frame.State.t -> ?timeout:float -> t -> unit
    val is_visible : ?timeout:float -> t -> bool
    val check : ?strict:bool -> ?force:bool -> ?position:Api.Point.t -> ?timeout:float -> ?trial:bool -> t -> unit
    val uncheck : ?strict:bool -> ?force:bool -> ?position:Api.Point.t -> ?timeout:float -> ?trial:bool -> t -> unit
    val dblclick : ?strict:bool -> ?force:bool -> ?modifiers:Frame.Modifiers.t array -> ?position:Api.Point.t -> ?delay:float -> ?button:Frame.Button.t -> ?timeout:float -> ?trial:bool -> ?steps:int -> t -> unit
    val get_by_text : ?exact:bool -> string -> t -> t
    val get_by_role : ?name:string -> ?exact:bool -> string -> t -> t
    val get_by_label : ?exact:bool -> string -> t -> t
    val get_by_placeholder : ?exact:bool -> string -> t -> t
    val get_by_alt_text : ?exact:bool -> string -> t -> t
    val get_by_title : ?exact:bool -> string -> t -> t
    val get_by_test_id : string -> t -> t
    val nth : int -> t -> t
    val first : t -> t
    val last : t -> t
    val filter : ?has_text:string -> ?has:t -> t -> t
    val and_ : t -> t -> t
    val or_ : t -> t -> t
    val blur : ?strict:bool -> ?timeout:float -> t -> unit
    val focus : ?strict:bool -> ?timeout:float -> t -> unit
    val hover : ?strict:bool -> ?force:bool -> ?modifiers:Frame.Modifiers.t array -> ?position:Api.Point.t -> ?timeout:float -> ?trial:bool -> t -> unit
    val input_value : ?strict:bool -> ?timeout:float -> t -> string
    val select_option : ?strict:bool -> ?elements:Api.ElementHandle.t array -> ?options:Frame.Options.t array -> ?force:bool -> ?timeout:float -> t -> string array
    val set_input_files : ?strict:bool -> ?payloads:Frame.Payloads.t array -> ?local_directory:string -> ?directory_stream:Api.WritableStream.t -> ?local_paths:string array -> ?streams:Api.WritableStream.t array -> ?timeout:float -> t -> unit
    val tap : ?strict:bool -> ?force:bool -> ?modifiers:Frame.Modifiers.t array -> ?position:Api.Point.t -> ?timeout:float -> ?trial:bool -> t -> unit
    val type_ : ?strict:bool -> ?delay:float -> ?timeout:float -> text:string -> t -> unit
    val dispatch_event : ?strict:bool -> ?timeout:float -> type_:string -> ?event_init:Yojson.Safe.t -> t -> unit
    val is_checked : ?strict:bool -> ?timeout:float -> t -> bool
    val is_disabled : ?strict:bool -> ?timeout:float -> t -> bool
    val is_enabled : ?strict:bool -> ?timeout:float -> t -> bool
    val is_hidden : ?strict:bool -> t -> bool
    val is_editable : ?strict:bool -> ?timeout:float -> t -> bool
    val drag_to : ?force:bool -> ?timeout:float -> ?trial:bool -> ?source_position:Api.Point.t -> ?target_position:Api.Point.t -> ?strict:bool -> ?steps:int -> target:t -> t -> unit
    val all : t -> t list
    val all_inner_texts : t -> string list
    val all_text_contents : t -> string list
    val highlight : ?style:string -> t -> unit
    val bounding_box : ?timeout:float -> t -> Api.Rect.Wrap.t option
    val scroll_into_view_if_needed : ?timeout:float -> t -> unit
    val element_handle : ?timeout:float -> t -> Api.ElementHandle.t option
    val element_handles : t -> Api.ElementHandle.t array
    val screenshot : ?timeout:float -> ?type_:Api.ElementHandle.Type_.t -> ?quality:int -> ?omit_background:bool -> ?caret:Api.ElementHandle.Caret.t -> ?animations:Api.ElementHandle.Animations.t -> ?scale:Api.ElementHandle.Scale.t -> ?mask:Api.ElementHandle.Mask.t array -> ?mask_color:string -> ?style:string -> t -> string
    val expect : expression:string -> ?expression_arg:Yojson.Safe.t -> ?pseudo:Frame.Pseudo.t -> ?expected_text:Api.ExpectedTextValue.t array -> ?expected_number:float -> ?expected_value:Yojson.Safe.t -> ?use_inner_text:bool -> is_not:bool -> ?timeout:float -> t -> Frame.ExpectResult.t
    val clear : ?strict:bool -> ?force:bool -> ?timeout:float -> t -> unit
end = struct
    type t = {
        frame : Api.Frame.t;
        selector : string;
    }

    let create ~selector frame = { frame; selector }

    let locator ~selector t = { t with selector = t.selector ^ " >> " ^ selector }

    let click ?(strict = true) ?force ?no_wait_after ?modifiers ?position ?delay ?button ?click_count ?timeout ?trial ?steps t =
        Frame.click ~selector:t.selector ~strict ?force ?no_wait_after ?modifiers ?position ?delay ?button ?click_count ?timeout ?trial ?steps t.frame

    let fill ?(strict = true) ?force ?timeout ~value t =
        Frame.fill ~selector:t.selector ~strict ~value ?force ?timeout t.frame

    let press ?(strict = true) ?delay ?no_wait_after ?timeout ~key t =
        Frame.press ~selector:t.selector ~strict ~key ?delay ?no_wait_after ?timeout t.frame

    let get_attribute ?(strict = true) ?timeout ~name t =
        Frame.get_attribute ~selector:t.selector ~strict ~name ?timeout t.frame

    let text_content ?(strict = true) ?timeout t =
        Frame.text_content ~selector:t.selector ~strict ?timeout t.frame

    let inner_text ?(strict = true) ?timeout t =
        Frame.inner_text ~selector:t.selector ~strict ?timeout t.frame

    let inner_html ?(strict = true) ?timeout t =
        Frame.inner_html ~selector:t.selector ~strict ?timeout t.frame

    let count t =
        match Frame.eval_on_selector_all ~selector:t.selector ~expression:"els => els.length" ~arg:`Null t.frame with
        | `Float f -> int_of_float f
        | `Int i -> i
        | _ -> 0

    let evaluate ~expression ?is_function ?(arg = `Null) ?timeout t =
        Locator_element.with_element ?timeout ~selector:t.selector t.frame (fun handle _ ->
            Api.ElementHandle.evaluate_expression_raw ~expression ?is_function
                ~arg:(Value.build_serialized_argument arg) handle |> Value.parse_serialized_value)

    let evaluate_all ~expression ?is_function ?(arg = `Null) t =
        Frame.eval_on_selector_all ~selector:t.selector ~expression ?is_function ~arg t.frame

    let wait_for ?state ?timeout t =
        Frame.wait_for_selector ~selector:t.selector ~strict:true ?timeout ?state ~omit_return_value:true t.frame |> ignore

    let is_visible ?timeout:(_ : float option) t =
        Frame.is_visible ~selector:t.selector ~strict:true t.frame

    let check ?(strict = true) ?force ?position ?timeout ?trial t =
        Frame.check ~selector:t.selector ~strict ?force ?position ?timeout ?trial t.frame

    let uncheck ?(strict = true) ?force ?position ?timeout ?trial t =
        Frame.uncheck ~selector:t.selector ~strict ?force ?position ?timeout ?trial t.frame

    let dblclick ?(strict = true) ?force ?modifiers ?position ?delay ?button ?timeout ?trial ?steps t =
        Frame.dblclick ~selector:t.selector ~strict ?force ?modifiers ?position ?delay ?button ?timeout ?trial ?steps t.frame

    let get_by_text ?exact text t        = locator ~selector:(Locator_utils.get_by_text ?exact text) t
    let get_by_role ?name ?exact role t  = locator ~selector:(Locator_utils.get_by_role ?name ?exact role) t
    let get_by_label ?exact text t       = locator ~selector:(Locator_utils.get_by_label ?exact text) t
    let get_by_placeholder ?exact text t = locator ~selector:(Locator_utils.get_by_placeholder ?exact text) t
    let get_by_alt_text ?exact text t    = locator ~selector:(Locator_utils.get_by_alt_text ?exact text) t
    let get_by_title ?exact text t       = locator ~selector:(Locator_utils.get_by_title ?exact text) t
    let get_by_test_id id t              = locator ~selector:(Locator_utils.get_by_test_id ~attribute:(Locator_utils.test_id_attribute t.frame) id) t

    let nth n t = locator ~selector:("nth=" ^ string_of_int n) t
    let first t = nth 0 t
    let last t  = nth (-1) t

    let same_frame operation l1 l2 =
        if Internal.connection l1.frame != Internal.connection l2.frame ||
           Internal.guid l1.frame <> Internal.guid l2.frame then
            invalid_arg ("Locator." ^ operation ^ ": locators must belong to the same frame and session")

    let filter ?has_text ?has t =
        Option.iter (same_frame "filter ~has" t) has;
        let open Option.Syntax in
        let text_selector = has_text |?> ((fun text -> " >> internal:has-text=" ^ Locator_utils.text_matcher ~exact:false text), "") in
        let has_selector  = has |?> ((fun locator -> " >> internal:has=" ^ Locator_utils.escape_for_selector locator.selector), "") in
        { t with selector = t.selector ^ text_selector ^ has_selector }

    let and_ l1 l2 =
        same_frame "and_" l1 l2;
        locator ~selector:("internal:and=" ^ Locator_utils.escape_for_selector l2.selector) l1

    let or_ l1 l2 =
        same_frame "or_" l1 l2;
        locator ~selector:("internal:or=" ^ Locator_utils.escape_for_selector l2.selector) l1

    let blur ?(strict = true) ?timeout t                                                                               = Frame.blur ~selector:t.selector ~strict ?timeout t.frame
    let focus ?(strict = true) ?timeout t                                                                              = Frame.focus ~selector:t.selector ~strict ?timeout t.frame
    let hover ?(strict = true) ?force ?modifiers ?position ?timeout ?trial t                                           = Frame.hover ~selector:t.selector ~strict ?force ?modifiers ?position ?timeout ?trial t.frame
    let input_value ?(strict = true) ?timeout t                                                                        = Frame.input_value ~selector:t.selector ~strict ?timeout t.frame
    let select_option ?(strict = true) ?elements ?options ?force ?timeout t                                            = Frame.select_option ~selector:t.selector ~strict ?elements ?options ?force ?timeout t.frame
    let set_input_files ?(strict = true) ?payloads ?local_directory ?directory_stream ?local_paths ?streams ?timeout t = Frame.set_input_files ~selector:t.selector ~strict ?payloads ?local_directory ?directory_stream ?local_paths ?streams ?timeout t.frame
    let tap ?(strict = true) ?force ?modifiers ?position ?timeout ?trial t                                             = Frame.tap ~selector:t.selector ~strict ?force ?modifiers ?position ?timeout ?trial t.frame
    let type_ ?(strict = true) ?delay ?timeout ~text t                                                                 = Frame.type_ ~selector:t.selector ~strict ~text ?delay ?timeout t.frame
    let dispatch_event ?(strict = true) ?timeout ~type_ ?(event_init = `Null) t                                        = Frame.dispatch_event ~selector:t.selector ~strict ~type_ ~event_init ?timeout t.frame

    let is_checked ?(strict = true) ?timeout t  = Frame.is_checked ~selector:t.selector ~strict ?timeout t.frame
    let is_disabled ?(strict = true) ?timeout t = Frame.is_disabled ~selector:t.selector ~strict ?timeout t.frame
    let is_enabled ?(strict = true) ?timeout t  = Frame.is_enabled ~selector:t.selector ~strict ?timeout t.frame
    let is_hidden ?(strict = true) t            = Frame.is_hidden ~selector:t.selector ~strict t.frame
    let is_editable ?(strict = true) ?timeout t = Frame.is_editable ~selector:t.selector ~strict ?timeout t.frame

    let drag_to ?force ?timeout ?trial ?source_position ?target_position ?(strict = true) ?steps ~target t =
        (* Deliberately safer than 1.59.1 dragTo, which only uses target._selector. *)
        same_frame "drag_to" t target;
        Frame.drag_and_drop ~source:t.selector ~target:target.selector ?force ?timeout ?trial ?source_position ?target_position ~strict ?steps t.frame

    let all t = List.init (count t) (fun i -> nth i t)

    let all_inner_texts t =
        match Frame.eval_on_selector_all ~selector:t.selector ~expression:"els => els.map(el => el.innerText)" ~arg:`Null t.frame with
        | `List l -> List.filter_map (function `String s -> Some s | _ -> None) l
        | _ -> []

    let all_text_contents t =
        match Frame.eval_on_selector_all ~selector:t.selector ~expression:"els => els.map(el => el.textContent || '')" ~arg:`Null t.frame with
        | `List l -> List.filter_map (function `String s -> Some s | _ -> None) l
        | _ -> []

    let highlight ?style t = Frame.highlight ~selector:t.selector ?style t.frame

    let bounding_box ?timeout t =
        Locator_element.with_element ?timeout ~selector:t.selector t.frame
            (fun handle _ -> Api.ElementHandle.bounding_box handle)

    let scroll_into_view_if_needed ?timeout t =
        Locator_element.with_element ?timeout ~selector:t.selector t.frame
            (fun handle remaining -> Api.ElementHandle.scroll_into_view_if_needed ~timeout:(remaining ()) handle)

    let element_handle ?timeout t =
        Some (Locator_element.acquire ~deadline:(Locator_element.deadline ?timeout ())
            ~selector:t.selector t.frame)

    let element_handles t =
        Locator_element.acquire_all ~selector:t.selector t.frame

    let screenshot ?timeout ?type_ ?quality ?omit_background ?caret ?animations ?scale ?mask ?mask_color ?style t =
        Locator_element.with_element ?timeout ~selector:t.selector t.frame (fun handle remaining ->
            Api.ElementHandle.screenshot ~timeout:(remaining ()) ?type_ ?quality ?omit_background
                ?caret ?animations ?scale ?mask ?mask_color ?style handle)

    let expect ~expression ?expression_arg ?pseudo ?expected_text ?expected_number ?expected_value ?use_inner_text ~is_not ?timeout t =
        Frame.expect ~selector:t.selector ~expression ?expression_arg ?pseudo ?expected_text ?expected_number ?expected_value ?use_inner_text ~is_not ?timeout t.frame

    let clear ?(strict = true) ?force ?timeout t = fill ~strict ?force ?timeout ~value:"" t
end

module JSHandle = struct
    include Api.JSHandle

    let evaluate ~expression ?is_function ?(arg = `Null) t =
        evaluate_expression_raw ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t |> Value.parse_serialized_value

    let evaluate_handle ~expression ?is_function ?(arg = `Null) t =
        evaluate_expression_handle_raw ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t

    let json_value t =
        json_value_raw t |> Value.parse_serialized_value
end

module ElementHandle = struct
    include Api.ElementHandle

    let evaluate ~expression ?is_function ?(arg = `Null) t =
        evaluate_expression_raw ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t |> Value.parse_serialized_value

    let evaluate_handle ~expression ?is_function ?(arg = `Null) t =
        evaluate_expression_handle_raw ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t

    let eval_on_selector ~selector ?strict ~expression ?is_function ?(arg = `Null) t =
        eval_on_selector_raw ~selector ?strict ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t |> Value.parse_serialized_value

    let eval_on_selector_all ~selector ~expression ?is_function ?(arg = `Null) t =
        eval_on_selector_all_raw ~selector ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t |> Value.parse_serialized_value

    let json_value t =
        json_value_raw t |> Value.parse_serialized_value

    let dispatch_event ~type_ ?(event_init = `Null) t =
        dispatch_event_raw ~type_ ~event_init:(Value.build_serialized_argument event_init) t
end

module Worker = struct
    include Api.Worker

    let evaluate ~expression ?is_function ?(arg = `Null) t =
        evaluate_expression_raw ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t |> Value.parse_serialized_value

    let evaluate_handle ~expression ?is_function ?(arg = `Null) t =
        evaluate_expression_handle_raw ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t
end

module BindingCall = struct
    include Api.BindingCall

    let resolve ~result t =
        resolve_raw ~result:(Value.build_serialized_argument result) t

    let reject ~error t =
        reject_raw ~error t
end

(* Each handle owns its exact connection. No process-global session registry. *)
let create ~(env : Eio_unix.Stdenv.base) ~(sw : Eio.Switch.t) ?(init_timeout = 30.) ?(shutdown_timeout = 1.) ?max_event_tasks ?on_event_error () =
    if not (Float.is_finite init_timeout && init_timeout > 0. && Float.is_finite shutdown_timeout && shutdown_timeout > 0.) then
        invalid_arg "Playwright lifecycle timeouts must be finite and positive";
    Option.iter (fun limit -> if limit < 1 then invalid_arg "max_event_tasks must be positive") max_event_tasks;
    Eio.Switch.check sw;
    (* D01: the existing cold downloader is blocking and outside this deadline. *)
    let dir = Driver.download () in
    Eio.Switch.check sw;
    let process_mgr        = Eio.Stdenv.process_mgr env in
    let clock              = Eio.Stdenv.clock env in
    let ready, ready_u     = Eio.Promise.create () in
    let stopped, stopped_u = Eio.Promise.create () in
    let stop, stop_u       = Eio.Promise.create () in
    let connection         = ref None in
    let finish_ready value =
        if not (Eio.Promise.is_resolved ready) then Eio.Promise.resolve ready_u value
    in
    let close reason = Option.iter (fun conn -> Connection.close conn reason) !connection in
    let diagnose operation f =
        try f () with ex -> Printf.eprintf "Playwright cleanup (%s): %s\n%!" operation (Printexc.to_string ex)
    in
    let run_session resources () =
        let driver_stdin, stdin   = Eio.Process.pipe ~sw:resources process_mgr in
        let stdout, driver_stdout = Eio.Process.pipe ~sw:resources process_mgr in
        let process               = Driver.run ~sw:resources ~process_mgr ~dir ~stdin:driver_stdin ~stdout:driver_stdout () in
        let cleanup () =
            close "Playwright session scope closed";
            Eio.Cancel.protect (fun () ->
                diagnose "stdin" (fun () -> Eio.Flow.close stdin);
                (* Keep stdout open and drain late replies while the driver exits.
                   Closing it first causes EPIPE or a full pipe can prevent graceful termination. *)
                diagnose "driver" (fun () ->
                    Eio.Fiber.first
                        (fun () -> Driver.shutdown ~clock ~timeout:shutdown_timeout process)
                        (fun () ->
                            (try
                                let buffer = Cstruct.create 4096 in
                                while true do
                                    ignore (Eio.Flow.single_read stdout buffer)
                                done
                            with End_of_file -> ());
                            Eio.Fiber.await_cancel ()));
                diagnose "stdout" (fun () -> Eio.Flow.close stdout))
        in
        Fun.protect ~finally:cleanup (fun () ->
            Eio.Flow.close driver_stdin;
            Eio.Flow.close driver_stdout;
            let conn = Connection.create ?max_event_tasks ?on_event_error stdout stdin in
            connection := Some conn;
            conn.await_cleanup <- Some (fun () -> Eio.Promise.await stopped);
            finish_ready (Ok conn);
            Eio.Fiber.first
                (fun () -> Connection.run_loop conn)
                (fun () ->
                    let status      = Eio.Process.await process in
                    let description = match status with `Exited n -> Printf.sprintf "exit %d" n | `Signaled n -> Printf.sprintf "signal %d" n in
                    Connection.close conn ("Playwright driver stopped: " ^ description)))
    in
    let started = ref false in
    let start () =
        Eio.Switch.check sw;
        started := true;
        Eio.Fiber.fork_daemon ~sw (fun () ->
            Fun.protect
                ~finally:(fun () ->
                    Option.iter (fun conn -> conn.Connection.await_cleanup <- None) !connection;
                    Eio.Promise.resolve stopped_u ())
                (fun () ->
                    try
                        Eio.Switch.run (fun resources ->
                            Eio.Fiber.first
                                (run_session resources)
                                (fun () ->
                                    Eio.Promise.await stop;
                                    close "Playwright initialization stopped"));
                        finish_ready (Error (Failure "Playwright session stopped during initialization", Printexc.get_callstack 10))
                    with ex ->
                        let bt = Printexc.get_raw_backtrace () in
                        close ("Playwright session failed: " ^ Printexc.to_string ex);
                        finish_ready (Error (ex, bt));
                        if Eio.Fiber.is_cancelled () then Printexc.raise_with_backtrace ex bt;
                        Printf.eprintf "Playwright session failed: %s\n%s%!" (Printexc.to_string ex) (Printexc.raw_backtrace_to_string bt));
            `Stop_daemon)
    in
    try
        Eio.Time.with_timeout_exn clock init_timeout (fun () ->
            start ();
            let conn = match Eio.Promise.await ready with Ok conn -> conn | Error (ex, bt) -> Printexc.raise_with_backtrace ex bt in
            let root = Api.Internal.create_root conn in
            Root.initialize ~sdk_language:`Javascript root)
    with ex ->
        let bt = Printexc.get_raw_backtrace () in
        close ("Playwright initialization failed: " ^ Printexc.to_string ex);
        Eio.Promise.resolve stop_u ();
        if !started then Eio.Cancel.protect (fun () -> Eio.Promise.await stopped);
        Printexc.raise_with_backtrace ex bt

let destroy (main : Api.Playwright.t) =
    Connection.destroy (Api.Internal.connection main)
