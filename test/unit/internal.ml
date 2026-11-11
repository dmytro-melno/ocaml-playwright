(* The internal modules of the library under their own names. *)

module Json = Playwright__Json
module Error = Playwright__Error
module Transport = Playwright__Transport
module Connection = Playwright__Connection
module Closing = Playwright__Closing
module Protocol = Playwright__Protocol
module Emitter = Playwright__Emitter
module Waiter = Playwright__Waiter
module Timeouts = Playwright__Timeouts
module Url_regex = Playwright__Url_regex
module Selector = Playwright__Selector
module Js = Playwright__Js
module Driver = Playwright__Driver
module Driver_process = Playwright__Driver_process
module Expect = Playwright__Expect

(* JSON documents, compared the way a JavaScript peer sees them: 7 and 7.0 are the same number. *)
let json =
    let rec normalize : Yojson.Safe.t -> Yojson.Safe.t = function
        | `Int n -> `Float (float_of_int n)
        | `List items -> `List (List.map normalize items)
        | `Assoc fields -> `Assoc (List.map (fun (name, value) -> name, normalize value) fields)
        | other -> other
    in
    Alcotest.testable (fun ppf j -> Format.pp_print_string ppf (Yojson.Safe.to_string j)) (fun a b -> Yojson.Safe.equal (normalize a) (normalize b))

let error_kind =
    Alcotest.testable
        (fun ppf (kind : Error.kind) ->
            Format.pp_print_string ppf
                (match kind with Timeout -> "Timeout" | Target_closed -> "Target_closed" | Assertion_failed -> "Assertion_failed" | Other -> "Other"))
        ( = )

(* Runs [f] and returns the Playwright error that it raises. *)
let failure what f =
    match f () with
    | _ -> Alcotest.failf "%s: expected a Playwright error" what
    | exception Error.E error -> error

let contains ~sub s =
    let n = String.length sub in
    let rec go i = i + n <= String.length s && (String.sub s i n = sub || go (i + 1)) in
    go 0

let check_contains what ~sub s = if not (contains ~sub s) then Alcotest.failf "%s: %S does not contain %S" what s sub
