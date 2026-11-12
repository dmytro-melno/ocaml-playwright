(* JSON helpers shared by the generated protocol layer and the hand-written client. *)

type t = Yojson.Safe.t

exception Decode_error of string

let decode_error fmt = Printf.ksprintf (fun message -> raise (Decode_error message)) fmt

let to_string (j : t) = Yojson.Safe.to_string j

let of_string s : t =
    try Yojson.Safe.from_string s with Yojson.Json_error message -> decode_error "invalid JSON: %s" message

(* {1 Encoding} *)

let obj fields : t = `Assoc (List.filter_map Fun.id fields)
let req name encode value = Some (name, encode value)
let opt name encode = function None -> None | Some value -> Some (name, encode value)

let string s : t = `String s
let int i : t = `Int i
let bool b : t = `Bool b
let any (j : t) = j
let binary bytes : t = `String (Base64.encode_string bytes)
let list encode values : t = `List (List.map encode values)

(* JSON has no representation for NaN and the infinities, and the driver parses strictly. *)
let float f : t =
    if Float.is_finite f then `Float f else invalid_arg (Printf.sprintf "Playwright: %h is not a finite number" f)

(* {1 Decoding} *)

module Decode = struct
    let kind : t -> string = function
        | `Null -> "null"
        | `Bool _ -> "a boolean"
        | `Int _ | `Intlit _ | `Float _ -> "a number"
        | `String _ -> "a string"
        | `Assoc _ -> "an object"
        | `List _ -> "an array"

    let expected what j = decode_error "expected %s, got %s" what (kind j)

    let string : t -> string = function `String s -> s | j -> expected "a string" j
    let bool : t -> bool = function `Bool b -> b | j -> expected "a boolean" j
    let any (j : t) = j

    let float : t -> float = function
        | `Float f -> f
        | `Int i -> float_of_int i
        | `Intlit s -> float_of_string s
        | j -> expected "a number" j

    let int : t -> int = function
        | `Int i -> i
        | `Float f when Float.is_integer f && Float.abs f <= 4503599627370496. -> int_of_float f
        | j -> expected "an integer" j

    let binary : t -> string = function
        | `String s -> (match Base64.decode s with Ok bytes -> bytes | Error (`Msg m) -> decode_error "invalid Base64: %s" m)
        | j -> expected "a Base64 string" j

    let list decode : t -> 'a list = function `List l -> List.map decode l | j -> expected "an array" j

    let enum table : t -> 'a = function
        | `String literal as j ->
            (match List.assoc_opt literal table with Some value -> value | None -> decode_error "unexpected enum literal %s" (to_string j))
        | j -> expected "an enum literal" j

    let member name : t -> t option = function
        | `Assoc fields -> (match List.assoc_opt name fields with Some `Null | None -> None | some -> some)
        | j -> expected "an object" j

    let in_field name decode j = try decode j with Decode_error message -> decode_error "%s: %s" name message

    let req name decode j =
        match member name j with Some v -> in_field name decode v | None -> decode_error "%s: missing required field" name

    let opt name decode j = Option.map (in_field name decode) (member name j)
end
