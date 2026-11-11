(* The ways to say which URLs are meant: a glob or a predicate. *)

open Types

let compile ?base_url ?web_socket (matcher : url_matcher) : string -> bool =
    match matcher with
    | Glob glob -> Glob.matcher ?base_url ?web_socket glob
    | Predicate predicate -> predicate

(* The patterns the driver should intercept for a set of handlers.  A predicate cannot be sent
   over, so its presence makes the driver intercept everything. *)
let interception_patterns (matchers : url_matcher list) : string list =
    if List.exists (function Predicate _ -> true | Glob _ -> false) matchers then [ "**/*" ]
    else List.filter_map (function Glob glob -> Some glob | Predicate _ -> None) matchers
