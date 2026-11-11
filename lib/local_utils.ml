(* The utilities of the local driver: work on local files (archives, HAR files, traces) that the
   client leaves to its own driver, also when the browser it drives is a remote one. *)

open Types

let of_session (session : session) =
    match session.local_utils with
    | Some channel -> channel
    | None -> Error.raise_ "The driver does not provide local utilities"
