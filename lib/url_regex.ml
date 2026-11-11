(* A matcher for the regular expressions that Playwright derives from URL globs.

   The driver turns a glob into a regular expression ([LocalUtils.globToRegex]), resolving it
   against the base URL exactly as every other Playwright client does.  Those expressions use a
   small, fixed vocabulary - literals, [.], [[^/]], groups, alternation, [*], [+] and anchors -
   which this backtracking matcher implements, so that no regular expression library is needed. *)

type node =
    | Char of char
    | Any
    | Not_slash
    | Start
    | End
    | Star of node
    | Plus of node
    | Alt of node list list

type t = node list

exception Unsupported of string

let parse pattern : t =
    let n = String.length pattern in
    let pos = ref 0 in
    let peek () = if !pos < n then Some pattern.[!pos] else None in
    let advance () = incr pos in
    let unsupported () = raise (Unsupported pattern) in
    let rec alternatives () =
        let first = sequence [] in
        if peek () = Some '|' then begin
            advance ();
            first :: alternatives ()
        end
        else [ first ]
    and sequence acc =
        match peek () with
        | None | Some ('|' | ')') -> List.rev acc
        | Some _ ->
            let atom = atom () in
            let atom =
                match peek () with
                | Some '*' -> advance (); Star atom
                | Some '+' -> advance (); Plus atom
                | Some ('?' | '{') -> unsupported ()
                | _ -> atom
            in
            sequence (atom :: acc)
    and atom () =
        match peek () with
        | Some '\\' ->
            advance ();
            (match peek () with
            | Some c when not (Char.lowercase_ascii c >= 'a' && Char.lowercase_ascii c <= 'z') && not (c >= '0' && c <= '9') ->
                advance ();
                Char c
            | _ -> unsupported ())
        | Some '.' -> advance (); Any
        | Some '^' -> advance (); Start
        | Some '$' -> advance (); End
        | Some '(' ->
            advance ();
            let alternatives = alternatives () in
            if peek () <> Some ')' then unsupported ();
            advance ();
            Alt alternatives
        | Some '[' ->
            if !pos + 4 <= n && String.sub pattern !pos 4 = "[^/]" then begin
                pos := !pos + 4;
                Not_slash
            end
            else unsupported ()
        | Some ('*' | '+' | '?' | '{' | '}' | ']') | None -> unsupported ()
        | Some c -> advance (); Char c
    in
    let alternatives = alternatives () in
    if !pos <> n then unsupported ();
    match alternatives with [ sequence ] -> sequence | alternatives -> [ Alt alternatives ]

(* [run nodes s i k] matches [nodes] against [s] from offset [i] and calls [k] with the offset
   after each possible match, longest first, until [k] accepts one. *)
let rec run nodes s i k =
    match nodes with
    | [] -> k i
    | node :: rest -> step node s i (fun j -> run rest s j k)

and step node s i k =
    let n = String.length s in
    match node with
    | Char c -> i < n && s.[i] = c && k (i + 1)
    | Any -> i < n && s.[i] <> '\n' && k (i + 1)
    | Not_slash -> i < n && s.[i] <> '/' && k (i + 1)
    | Start -> i = 0 && k i
    | End -> i = n && k i
    | Alt alternatives -> List.exists (fun sequence -> run sequence s i k) alternatives
    | Plus node -> step node s i (fun j -> j > i && step (Star node) s j k)
    | Star ((Any | Not_slash | Char _) as node) ->
        (* The common case: consume greedily without recursion, then back off. *)
        let accepts j = match node with Any -> s.[j] <> '\n' | Not_slash -> s.[j] <> '/' | Char c -> s.[j] = c | _ -> false in
        let stop = ref i in
        while !stop < n && accepts !stop do incr stop done;
        let rec back j = j >= i && (k j || back (j - 1)) in
        back !stop
    | Star node -> step node s i (fun j -> j > i && step (Star node) s j k) || k i

(* Whether the expression matches anywhere in [s], as JavaScript's [RegExp.test] does. *)
let matches (t : t) s =
    let n = String.length s in
    match t with
    | Start :: _ -> run t s 0 (fun _ -> true)
    | _ ->
        let rec from i = i <= n && (run t s i (fun _ -> true) || from (i + 1)) in
        from 0
