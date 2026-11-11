(* JavaScript values: what [evaluate] takes as its argument and returns as its result. *)

type t = Types.js =
    | Undefined
    | Null
    | Bool of bool
    | Number of float
    | String of string
    | Bigint of string
    | Date of string
    | Url of string
    | Regexp of { source : string; flags : string }
    | Error of { name : string; message : string; stack : string }
    | Array of t list
    | Object of (string * t) list
    | Typed_array of { kind : Types.typed_array_kind; bytes : string }
    | Handle of Types.js_handle

type typed_array_kind = Types.typed_array_kind

let typed_array_kinds =
    [ `I8, "i8"; `Ui8, "ui8"; `Ui8c, "ui8c"; `I16, "i16"; `Ui16, "ui16"; `I32, "i32"; `Ui32, "ui32"; `F32, "f32"; `F64, "f64";
      `Bi64, "bi64"; `Bui64, "bui64" ]

(* {1 Wire format} *)

let special literal : Json.t = `Assoc [ "v", `String literal ]

(* Encodes a value as a [SerializedValue], collecting the handles it refers to. *)
let rec encode handles (value : t) : Json.t =
    match value with
    | Undefined -> special "undefined"
    | Null -> special "null"
    | Bool b -> `Assoc [ "b", `Bool b ]
    | Number f when Float.is_nan f -> special "NaN"
    | Number f when f = Float.infinity -> special "Infinity"
    | Number f when f = Float.neg_infinity -> special "-Infinity"
    | Number f when f = 0. && Float.sign_bit f -> special "-0"
    | Number f -> `Assoc [ "n", `Float f ]
    | String s -> `Assoc [ "s", `String s ]
    | Bigint s -> `Assoc [ "bi", `String s ]
    | Date s -> `Assoc [ "d", `String s ]
    | Url s -> `Assoc [ "u", `String s ]
    | Regexp { source; flags } -> `Assoc [ "r", `Assoc [ "p", `String source; "f", `String flags ] ]
    | Error { name; message; stack } -> `Assoc [ "e", `Assoc [ "n", `String name; "m", `String message; "s", `String stack ] ]
    | Array items -> `Assoc [ "a", `List (List.map (encode handles) items) ]
    | Object fields ->
        `Assoc [ "o", `List (List.map (fun (key, value) -> `Assoc [ "k", `String key; "v", encode handles value ]) fields) ]
    | Typed_array { kind; bytes } ->
        `Assoc [ "ta", `Assoc [ "b", Json.binary bytes; "k", `String (List.assoc kind typed_array_kinds) ] ]
    | Handle handle ->
        let index = List.length !handles in
        handles := Channel.any handle.h_channel :: !handles;
        `Assoc [ "h", `Int index ]

let to_argument (value : t) : Protocol.Serialized_argument.t =
    let handles = ref [] in
    let value = encode handles value in
    { value; handles = List.rev !handles }

(* Decodes a [SerializedValue].  An object that the page reached twice is shared; a reference
   back to an object that is still being decoded (a cycle) becomes [Undefined]. *)
let of_wire (json : Json.t) : t =
    let module D = Json.Decode in
    let seen = Hashtbl.create 8 in
    let rec decode (json : Json.t) : t =
        let fields = match json with `Assoc fields -> fields | j -> D.expected "a serialized value" j in
        let remember value =
            (match List.assoc_opt "id" fields with Some (`Int id) -> Hashtbl.replace seen id value | _ -> ());
            value
        in
        match List.find_opt (fun (key, _) -> key <> "id") fields with
        | None -> Undefined
        | Some ("n", n) -> Number (D.float n)
        | Some ("b", b) -> Bool (D.bool b)
        | Some ("s", s) -> String (D.string s)
        | Some ("v", `String "null") -> Null
        | Some ("v", `String "undefined") -> Undefined
        | Some ("v", `String "NaN") -> Number Float.nan
        | Some ("v", `String "Infinity") -> Number Float.infinity
        | Some ("v", `String "-Infinity") -> Number Float.neg_infinity
        | Some ("v", `String "-0") -> Number (-0.)
        | Some ("d", d) -> Date (D.string d)
        | Some ("u", u) -> Url (D.string u)
        | Some ("bi", bi) -> Bigint (D.string bi)
        | Some ("r", r) -> Regexp { source = D.req "p" D.string r; flags = D.req "f" D.string r }
        | Some ("e", e) -> Error { name = D.req "n" D.string e; message = D.req "m" D.string e; stack = D.req "s" D.string e }
        | Some ("ta", ta) ->
            let kind = D.req "k" (D.enum (List.map (fun (kind, literal) -> literal, kind) typed_array_kinds)) ta in
            Typed_array { kind; bytes = D.req "b" D.binary ta }
        | Some ("a", items) -> remember (Array (D.list decode items))
        | Some ("o", entries) ->
            remember (Object (D.list (fun entry -> D.req "k" D.string entry, decode (D.req "v" D.any entry)) entries))
        | Some ("ref", `Int id) -> Option.value (Hashtbl.find_opt seen id) ~default:Undefined
        | Some (key, _) -> Json.decode_error "unsupported serialized value %S" key
    in
    decode json

(* {1 Building values} *)

let undefined = Undefined
let null = Null
let bool b = Bool b
let int i = Number (float_of_int i)
let float f = Number f
let string s = String s
let list f items = Array (List.map f items)
let obj fields = Object fields
let option f = function Some value -> f value | None -> Null

let rec of_json : Yojson.Safe.t -> t = function
    | `Null -> Null
    | `Bool b -> Bool b
    | `Int i -> Number (float_of_int i)
    | `Intlit s -> Bigint s
    | `Float f -> Number f
    | `String s -> String s
    | `List items -> Array (List.map of_json items)
    | `Assoc fields -> Object (List.map (fun (key, value) -> key, of_json value) fields)

(* {1 Reading values} *)

let max_safe_integer = 9007199254740991.

(* The JSON that [JSON.stringify] would produce, with integral numbers as [`Int]. *)
let rec to_json : t -> Yojson.Safe.t = function
    | Undefined | Null | Handle _ -> `Null
    | Bool b -> `Bool b
    | Number f when not (Float.is_finite f) -> `Null
    | Number f when Float.is_integer f && Float.abs f <= max_safe_integer -> `Int (int_of_float f)
    | Number f -> `Float f
    | String s | Date s | Url s -> `String s
    | Bigint s -> `Intlit s
    | Regexp { source; flags } -> `String (Printf.sprintf "/%s/%s" source flags)
    | Error { name; message; stack } -> `Assoc [ "name", `String name; "message", `String message; "stack", `String stack ]
    | Array items -> `List (List.map to_json items)
    | Object fields -> `Assoc (List.map (fun (key, value) -> key, to_json value) fields)
    | Typed_array { bytes; _ } -> `String (Base64.encode_string bytes)

let rec show : t -> string = function
    | Undefined -> "undefined"
    | Null -> "null"
    | Bool b -> string_of_bool b
    | Number f when Float.is_nan f -> "NaN"
    | Number f when Float.is_integer f && Float.abs f <= max_safe_integer -> Printf.sprintf "%.0f" f
    | Number f when f = Float.infinity -> "Infinity"
    | Number f when f = Float.neg_infinity -> "-Infinity"
    | Number f -> Printf.sprintf "%.17g" f
    | String s -> Yojson.Safe.to_string (`String s)
    | Bigint s -> s ^ "n"
    | Date s -> Printf.sprintf "Date(%s)" s
    | Url s -> Printf.sprintf "URL(%s)" s
    | Regexp { source; flags } -> Printf.sprintf "/%s/%s" source flags
    | Error { name; message; _ } -> Printf.sprintf "%s: %s" name message
    | Array items -> "[" ^ String.concat ", " (List.map show items) ^ "]"
    | Object fields -> "{" ^ String.concat ", " (List.map (fun (key, value) -> key ^ ": " ^ show value) fields) ^ "}"
    | Typed_array { kind; bytes } -> Printf.sprintf "TypedArray(%s, %d bytes)" (List.assoc kind typed_array_kinds) (String.length bytes)
    | Handle handle -> handle.preview

let kind : t -> string = function
    | Undefined -> "undefined"
    | Null -> "null"
    | Bool _ -> "a boolean"
    | Number _ -> "a number"
    | String _ -> "a string"
    | Bigint _ -> "a bigint"
    | Date _ -> "a date"
    | Url _ -> "a URL"
    | Regexp _ -> "a regular expression"
    | Error _ -> "an error"
    | Array _ -> "an array"
    | Object _ -> "an object"
    | Typed_array _ -> "a typed array"
    | Handle _ -> "a handle"

let expected what value = Error.raise_ "Expected the JavaScript value to be %s, but it is %s" what (kind value)

let to_string = function String s | Date s | Url s -> s | value -> expected "a string" value
let to_bool = function Bool b -> b | value -> expected "a boolean" value
let to_float = function Number f -> f | value -> expected "a number" value

let to_int = function
    | Number f when Float.is_integer f && Float.abs f <= max_safe_integer -> int_of_float f
    | value -> expected "an integer" value

let to_list f = function Array items -> List.map f items | value -> expected "an array" value
let to_assoc = function Object fields -> fields | value -> expected "an object" value
let to_option f = function Undefined | Null -> None | value -> Some (f value)
let is_nullish = function Undefined | Null -> true | _ -> false

let member name = function
    | Object fields -> Option.value (List.assoc_opt name fields) ~default:Undefined
    | value -> expected "an object" value

let pp ppf value = Format.pp_print_string ppf (show value)
