(* Which URLs are meant: a glob or a predicate.

   A glob is not read here.  The driver makes a regular expression of it
   ([LocalUtils.globToRegex]), resolving it against the base URL on the way, with the code by
   which it decides for itself which requests to hand over; so the two cannot disagree.  [Re]
   then runs the expression, in time that is linear in the length of the URL.  The expressions
   come from a small vocabulary - literals, [.], [[^/]], groups, alternatives, [*], [+] and
   anchors - and nothing else is given to [Re]: the regular expressions that users write are
   JavaScript's, and go to the driver or to the page.

   Asking the driver suspends the fibre.  So a matcher is made where a route is registered or a
   wait is set up, and never where an event is handled. *)

open Types

let of_glob (session : session) ?base_url ?(web_socket = false) glob : string -> bool =
    if glob = "" then Fun.const true
    else begin
        let source = Protocol.Local_utils.glob_to_regex ~glob ?base_url ~web_socket_url:web_socket (Local_utils.of_session session) in
        match Re.compile (Re.Perl.re source) with
        | regex -> Re.execp regex
        | exception (Re.Perl.Parse_error | Re.Perl.Not_supported) ->
            Error.raise_ "Cannot match URLs against the glob %S, which the driver reads as /%s/" glob source
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
