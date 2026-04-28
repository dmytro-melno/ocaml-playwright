
type enum = [ `A | `B ]

let enum_to_yojson = function
  | `A -> `String "A"
  | `B -> `String "B"

let enum_of_yojson = function
  | `String "A" -> Ok `A
  | `String "B" -> Ok `B
  | _ -> Error "invalid"

type rec1 = { e : enum } [@@deriving yojson]
