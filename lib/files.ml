(* Local file access on behalf of API calls that take or produce files. *)

let absolute path = if Filename.is_relative path then Filename.concat (Sys.getcwd ()) path else path

let read path =
    try In_channel.with_open_bin path In_channel.input_all with Sys_error message -> Error.raise_ "Cannot read file: %s" message

let rec mkdir_p path =
    if not (Sys.file_exists path) then begin
        mkdir_p (Filename.dirname path);
        try Unix.mkdir path 0o755 with Unix.Unix_error (Unix.EEXIST, _, _) -> ()
    end

let write path contents =
    try
        mkdir_p (Filename.dirname (absolute path));
        Out_channel.with_open_bin path (fun oc -> output_string oc contents)
    with Sys_error message | Unix.Unix_error (_, _, message) -> Error.raise_ "Cannot write file %s: %s" path message

let is_directory path = try Sys.is_directory path with Sys_error _ -> false
