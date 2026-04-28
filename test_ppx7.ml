
type a =
  | Javascript [@name "javascript"]
  | Python [@name "python"]
[@@deriving yojson]

let _ = Printf.printf "Output: %s\n" (Yojson.Safe.to_string (a_to_yojson Javascript))
