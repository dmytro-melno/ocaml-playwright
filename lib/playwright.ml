module Transport = Transport
module Driver = Driver
module Connection = Connection
include Api

module Value = struct
  let rec parse_serialized_value (v : SerializedValue.t) : Yojson.Safe.t =
    match v.n with
    | Some n -> `Float n
    | None ->
    match v.b with
    | Some b -> `Bool b
    | None ->
    match v.s with
    | Some s -> `String s
    | None ->
    match v.v with
    | Some `Null -> `Null
    | Some `Undefined -> `Null
    | Some `Nan -> `String "NaN"
    | Some `Inf -> `String "Infinity"
    | Some `Minus_inf -> `String "-Infinity"
    | Some `Minus_zero -> `Float (-0.0)
    | None ->
    match v.d with
    | Some d -> `String d
    | None ->
    match v.u with
    | Some u -> `String u
    | None ->
    match v.bi with
    | Some bi -> `String bi
    | None ->
    match v.e with
    | Some e -> `Assoc ["message", `String e.m; "name", `String e.n; "stack", `String e.s]
    | None ->
    match v.r with
    | Some r -> `Assoc ["pattern", `String r.p; "flags", `String r.f]
    | None ->
    match v.a with
    | Some a -> `List (Array.to_list a |> List.map parse_serialized_value)
    | None ->
    match v.o with
    | Some o -> `Assoc (Array.to_list o |> List.map (fun (x : SerializedValue.O.t) -> (x.k, parse_serialized_value x.v)))
    | None -> `Null

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
    | `List l -> { empty with a = Some (Array.of_list (List.map build_serialized_value l)) }
    | `Assoc l ->
        let o = l |> List.map (fun (k, v) -> SerializedValue.O.{ k; v = build_serialized_value v }) |> Array.of_list in
        { empty with o = Some o }
    
  let parse_serialized_argument (a : SerializedArgument.t) : Yojson.Safe.t =
    parse_serialized_value a.value
    
  let build_serialized_argument (j : Yojson.Safe.t) : SerializedArgument.t =
    SerializedArgument.Wrap.{ value = build_serialized_value j; handles = [||] }
end

module Frame = struct
  include Api.Frame

  let evaluate ~expression ?is_function ?(arg=`Null) t =
    evaluate_expression_raw ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t |> Value.parse_serialized_value

  let evaluate_handle ~expression ?is_function ?(arg=`Null) t =
    evaluate_expression_handle_raw ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t

  let eval_on_selector ~selector ?strict ~expression ?is_function ?(arg=`Null) t =
    eval_on_selector_raw ~selector ?strict ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t |> Value.parse_serialized_value

  let eval_on_selector_all ~selector ~expression ?is_function ?(arg=`Null) t =
    eval_on_selector_all_raw ~selector ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t |> Value.parse_serialized_value

  let wait_for_function ~expression ?is_function ?(arg=`Null) ?timeout ?polling_interval t =
    wait_for_function_raw ~expression ?is_function ~arg:(Value.build_serialized_argument arg) ?timeout ?polling_interval t

  let dispatch_event ~selector ?strict ~type_ ?(event_init=`Null) ?timeout t =
    dispatch_event_raw ~selector ?strict ~type_ ~event_init:(Value.build_serialized_argument event_init) ?timeout t

  let expect ?selector ~expression ?expression_arg ?pseudo ?expected_text ?expected_number ?(expected_value=`Null) ?use_inner_text ~is_not ?timeout t =
    let expected_value_arg = if expected_value = `Null then None else Some (Value.build_serialized_argument expected_value) in
    expect_raw ?selector ~expression ?expression_arg ?pseudo ?expected_text ?expected_number ?expected_value:expected_value_arg ?use_inner_text ~is_not ?timeout t
end

module Page = struct
  include Api.Page

  let evaluate ~expression ?is_function ?(arg=`Null) t =
    evaluate_expression_raw ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t |> Value.parse_serialized_value

  let evaluate_handle ~expression ?is_function ?(arg=`Null) t =
    evaluate_expression_handle_raw ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t

  let eval_on_selector ~selector ?strict ~expression ?is_function ?(arg=`Null) t =
    eval_on_selector_raw ~selector ?strict ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t |> Value.parse_serialized_value

  let eval_on_selector_all ~selector ~expression ?is_function ?(arg=`Null) t =
    eval_on_selector_all_raw ~selector ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t |> Value.parse_serialized_value

  let wait_for_function ~expression ?is_function ?(arg=`Null) ?timeout ?polling_interval t =
    wait_for_function_raw ~expression ?is_function ~arg:(Value.build_serialized_argument arg) ?timeout ?polling_interval t

  let dispatch_event ~selector ?strict ~type_ ?(event_init=`Null) ?timeout t =
    dispatch_event_raw ~selector ?strict ~type_ ~event_init:(Value.build_serialized_argument event_init) ?timeout t

  let expect ?selector ~expression ?expression_arg ?pseudo ?expected_text ?expected_number ?(expected_value=`Null) ?use_inner_text ~is_not ?timeout t =
    Frame.expect ?selector ~expression ?expression_arg ?pseudo ?expected_text ?expected_number ~expected_value ?use_inner_text ~is_not ?timeout (main_frame t)
end

module JSHandle = struct
  include Api.JSHandle

  let evaluate ~expression ?is_function ?(arg=`Null) t =
    evaluate_expression_raw ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t |> Value.parse_serialized_value

  let evaluate_handle ~expression ?is_function ?(arg=`Null) t =
    evaluate_expression_handle_raw ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t

  let json_value t =
    json_value_raw t |> Value.parse_serialized_value
end

module ElementHandle = struct
  include Api.ElementHandle

  let evaluate ~expression ?is_function ?(arg=`Null) t =
    evaluate_expression_raw ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t |> Value.parse_serialized_value

  let evaluate_handle ~expression ?is_function ?(arg=`Null) t =
    evaluate_expression_handle_raw ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t

  let eval_on_selector ~selector ?strict ~expression ?is_function ?(arg=`Null) t =
    eval_on_selector_raw ~selector ?strict ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t |> Value.parse_serialized_value

  let eval_on_selector_all ~selector ~expression ?is_function ?(arg=`Null) t =
    eval_on_selector_all_raw ~selector ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t |> Value.parse_serialized_value

  let json_value t =
    json_value_raw t |> Value.parse_serialized_value

  let dispatch_event ~type_ ?(event_init=`Null) t =
    dispatch_event_raw ~type_ ~event_init:(Value.build_serialized_argument event_init) t
end

module Worker = struct
  include Api.Worker

  let evaluate ~expression ?is_function ?(arg=`Null) t =
    evaluate_expression_raw ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t |> Value.parse_serialized_value

  let evaluate_handle ~expression ?is_function ?(arg=`Null) t =
    evaluate_expression_handle_raw ~expression ?is_function ~arg:(Value.build_serialized_argument arg) t
end


module BindingCall = struct
  include Api.BindingCall

  let resolve ~result t =
    resolve_raw ~result:(Value.build_serialized_argument result) t

  let reject ~error t =
    reject_raw ~error t
end

let instances = Hashtbl.create 1

let create ~(env : Eio_unix.Stdenv.base) ~(sw : Eio.Switch.t) () =
  let process_mgr = Eio.Stdenv.process_mgr env in
  let p1_r, p1_w = Eio.Process.pipe ~sw process_mgr in
  let p2_r, p2_w = Eio.Process.pipe ~sw process_mgr in

  let p = Driver.run ~sw ~process_mgr ~stdin:p1_r ~stdout:p2_w () in
  Eio.Flow.close p1_r;
  Eio.Flow.close p2_w;

  let conn = Connection.create (p2_r :> Eio.Flow.source_ty Eio.Resource.t) (p1_w :> Eio.Flow.sink_ty Eio.Resource.t) in
  Eio.Fiber.fork ~sw (fun () -> Connection.run_loop conn);

  let root = { conn; guid = "" } in
  let main = Root.initialize ~sdk_language:`Javascript root in

  let close () =
    Eio.Flow.close p1_w;
    Eio.Flow.close p2_r;
    ignore (Eio.Process.await p)
  in
  Hashtbl.add instances main.guid close;
  main

let destroy (main : Api.Playwright.t) =
  match Hashtbl.find_opt instances main.guid with
  | Some close ->
      close ();
      Hashtbl.remove instances main.guid
  | None -> ()
