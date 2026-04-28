
type a =
  [
  | `Javascript
  | `Python
  ]

let a_to_yojson : a -> Yojson.Safe.t = function
  | `Javascript -> `String "javascript"
  | `Python -> `String "python"

let a_of_yojson : Yojson.Safe.t -> a = function
  | `String "javascript" -> `Javascript
  | `String "python" -> `Python
  | _ -> failwith "Invalid enum"

let _ = a_of_yojson
let _ = Printf.printf "Output: %s\n" (Yojson.Safe.to_string (a_to_yojson `Javascript))
