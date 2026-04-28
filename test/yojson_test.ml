
type literal_enum = Load | Domcontentloaded | Networkidle | Commit

let literal_enum_to_yojson = function
  | Load -> `String "load"
  | Domcontentloaded -> `String "domcontentloaded"
  | Networkidle -> `String "networkidle"
  | Commit -> `String "commit"

let literal_enum_of_yojson = function
  | `String "load" -> Ok Load
  | `String "domcontentloaded" -> Ok Domcontentloaded
  | `String "networkidle" -> Ok Networkidle
  | `String "commit" -> Ok Commit
  | _ -> Error "literal_enum"

let () =
  let enum_json = literal_enum_to_yojson Load in
  Printf.printf "Enum json: %s\n" (Yojson.Safe.to_string enum_json);
  let v = literal_enum_of_yojson (`String "load") in
  match v with
  | Ok Load -> Printf.printf "Parsed successfully!\n"
  | _ -> Printf.printf "Failed to parse\n"
