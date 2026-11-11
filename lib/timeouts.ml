(* Default timeouts, in milliseconds.  A page inherits from its context; [0.] disables a timeout. *)

type t = {
    parent : t option;
    mutable default : float option;
    mutable default_navigation : float option;
}

let default_timeout = 30_000.
let default_launch_timeout = 180_000.

let create ?parent () = { parent; default = None; default_navigation = None }
let set_default t timeout = t.default <- Some timeout
let set_default_navigation t timeout = t.default_navigation <- Some timeout

(* Runs [f] with no timeouts by default. *)
let suspended t f =
    let default, default_navigation = t.default, t.default_navigation in
    t.default <- Some 0.;
    t.default_navigation <- Some 0.;
    Fun.protect f ~finally:(fun () ->
        t.default <- default;
        t.default_navigation <- default_navigation)

(* PWDEBUG opens the inspector and lets the user step through the script at their own pace. *)
let debugging =
    lazy (match Sys.getenv_opt "PWDEBUG" with None | Some ("" | "0" | "false" | "console") -> false | Some _ -> true)

let rec action ?timeout t =
    match timeout, t.default, t.parent with
    | Some timeout, _, _ -> timeout
    | None, _, _ when Lazy.force debugging -> 0.
    | None, Some timeout, _ -> timeout
    | None, None, Some parent -> action parent
    | None, None, None -> default_timeout

let rec navigation ?timeout t =
    match timeout, t.default_navigation, t.default, t.parent with
    | Some timeout, _, _, _ -> timeout
    | None, Some timeout, _, _ -> timeout
    | None, None, _, _ when Lazy.force debugging -> 0.
    | None, None, Some timeout, _ -> timeout
    | None, None, None, Some parent -> navigation parent
    | None, None, None, None -> default_timeout

let launch ?timeout () =
    match timeout with
    | Some timeout -> timeout
    | None -> if Lazy.force debugging then 0. else default_launch_timeout
