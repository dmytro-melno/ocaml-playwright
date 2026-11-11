(* Errors reported by the driver, the browser or the client itself. *)

type kind =
    | Timeout
    | Target_closed
    | Assertion_failed
    | Other

type t = {
    kind : kind;
    name : string;
    message : string;
    stack : string option;
    log : string list;
    details : Json.t;  (* command-specific [errorDetails]; [`Null] when absent *)
}

exception E of t

let make ?(kind = Other) ?name ?stack ?(log = []) ?(details = `Null) message =
    let name =
        match name, kind with
        | Some name, _ -> name
        | None, Timeout -> "TimeoutError"
        | None, Target_closed -> "TargetClosedError"
        | None, Assertion_failed -> "AssertionError"
        | None, Other -> "Error"
    in
    { kind; name; message; stack; log; details }

let raise_ ?kind fmt = Printf.ksprintf (fun message -> raise (E (make ?kind message))) fmt
let timeout fmt = raise_ ~kind:Timeout fmt

let target_closed_message = "Target page, context or browser has been closed"
let target_closed ?(message = target_closed_message) () = make ~kind:Target_closed message

let kind_of_name = function
    | "TimeoutError" -> Timeout
    | "TargetClosedError" -> Target_closed
    | _ -> Other

let call_log log =
    if List.for_all (fun line -> line = "") log then "" else "\nCall log:\n" ^ String.concat "\n" log

(* Decodes the [error] member of a response: either a serialized JavaScript [Error] or, when the
   page threw something else, an arbitrary serialized value. *)
let of_wire ?(log = []) ?(details = `Null) ~render_value (j : Json.t) : t =
    let module D = Json.Decode in
    match D.member "error" j with
    | Some e ->
        let name = Option.value (D.opt "name" D.string e) ~default:"Error" in
        let message = Option.value (D.opt "message" D.string e) ~default:"" in
        { kind = kind_of_name name; name; message = message ^ call_log log; stack = D.opt "stack" D.string e; log; details }
    | None ->
        let message = match D.member "value" j with Some v -> render_value v | None -> Json.to_string j in
        { kind = Other; name = "Error"; message = message ^ call_log log; stack = None; log; details }

let to_string e = if e.name = "Error" then e.message else e.name ^ ": " ^ e.message
let pp ppf e = Format.pp_print_string ppf (to_string e)

let () =
    Printexc.register_printer (function
        | E e -> Some ("Playwright.Error: " ^ to_string e)
        | Json.Decode_error message -> Some ("Playwright protocol decoding error: " ^ message)
        | _ -> None)
