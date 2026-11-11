(* Hands its arguments to the command line tool of the Playwright driver. *)

let () =
    let args = List.tl (Array.to_list Sys.argv) in
    try
        (* Windows cannot replace a process by another one, so there the tool runs as a child. *)
        if Sys.win32 then exit (Playwright.Driver.run args)
        else
            match Playwright.Driver.command args with
            | program :: _ as command -> Unix.execv program (Array.of_list command)
            | [] -> assert false
    with
    | Playwright.Error error ->
        prerr_endline ("ocaml-playwright: " ^ error.message);
        exit 1
    | Unix.Unix_error (code, _, argument) ->
        prerr_endline (Printf.sprintf "ocaml-playwright: %s: %s" argument (Unix.error_message code));
        exit 1
