(* The utilities of the driver: work on local files (archives, HAR files, traces) that the client
   leaves to it. *)

open Types

let of_session (session : session) =
    match session.local_utils with
    | Some channel -> channel
    | None -> Error.raise_ "The driver does not provide local utilities"
