(* Matching URLs against globs and predicates on the client.

   Globs are resolved against the context's base URL and turned into regular expressions by the
   driver, so that they behave exactly as in every other Playwright client. *)

open Types

let cache_limit = 1024

let local_utils (session : session) =
    match session.local_utils with
    | Some channel -> channel
    | None -> Error.raise_ "The driver does not provide local utilities"

let of_glob (session : session) ?base_url ?(web_socket = false) glob : string -> bool =
    if glob = "" then fun _ -> true
    else begin
        let key = String.concat "\000" [ Option.value base_url ~default:""; (if web_socket then "ws" else ""); glob ] in
        match Hashtbl.find_opt session.url_matchers key with
        | Some matches -> matches
        | None ->
            let pattern = Protocol.Local_utils.glob_to_regex ~glob ?base_url ~web_socket_url:web_socket (local_utils session) in
            let regex =
                try Url_regex.parse pattern
                with Url_regex.Unsupported _ -> Error.raise_ "Cannot match URLs against the glob %S (resolved to /%s/)" glob pattern
            in
            let matches = Url_regex.matches regex in
            if Hashtbl.length session.url_matchers >= cache_limit then Hashtbl.reset session.url_matchers;
            Hashtbl.replace session.url_matchers key matches;
            matches
    end

let compile session ?base_url ?web_socket (matcher : url_matcher) : string -> bool =
    match matcher with
    | Glob glob -> of_glob session ?base_url ?web_socket glob
    | Predicate predicate -> predicate

(* The patterns the driver should intercept for a set of handlers.  A predicate cannot be sent
   over, so its presence makes the driver intercept everything. *)
let interception_patterns (matchers : url_matcher list) : string list =
    if List.exists (function Predicate _ -> true | Glob _ -> false) matchers then [ "**/*" ]
    else List.filter_map (function Glob glob -> Some glob | Predicate _ -> None) matchers
