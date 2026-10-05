(* Findlib can silently fall back to the host compiler for an unknown toolchain.
   A directory called default.windows must not contain Linux artifacts. *)
let () =
    match Array.to_list Sys.argv with
    | [_; context; os_type] ->
        if Filename.check_suffix context ".windows" && os_type <> "Win32" then begin
            Printf.eprintf
                "The windows target resolved to a %s OCaml compiler.\n\
                 Configure the Windows findlib toolchain and its target dependencies,\n\
                 or use --workspace dune-workspace.native for a host-only build.\n%!"
                os_type;
            exit 1
        end
    | _ -> invalid_arg "check_toolchain CONTEXT OS_TYPE"
