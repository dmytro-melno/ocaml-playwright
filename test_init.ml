
type init_t = {
    version : string;
} [@@deriving yojson {strict=false}]

let () =
    match init_t_of_yojson (`Assoc [("version", `String "1.0")]) with
    | Ok i -> Printf.printf "version: %s\n" i.version
    | Error e -> Printf.printf "error: %s\n" e
