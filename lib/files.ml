(* Local file access on behalf of API calls that take or produce files.

   A file can be large, and can live on a slow disk or on a file system across a network: reading
   or writing it in place would hold up every fiber of the domain for as long.  What touches the
   contents of files or walks directories is therefore done in a system thread, while the
   calling fiber waits ({!blocking}). *)

let absolute path = if Filename.is_relative path then Filename.concat (Sys.getcwd ()) path else path
let is_directory path = try Sys.is_directory path with Sys_error _ -> false

let rec mkdir_p path =
    if not (Sys.file_exists path) then begin
        mkdir_p (Filename.dirname path);
        try Unix.mkdir path 0o755 with Unix.Unix_error (Unix.EEXIST, _, _) -> ()
    end

(* Runs [f] in a system thread, and reports what the file system refuses as a Playwright error
   that says what was being done: "read" or "write". *)
let blocking ~action f =
    Eio_unix.run_in_systhread ~label:"playwright-files" (fun () ->
        try f () with
        | Sys_error message -> Error.raise_ "Cannot %s file: %s" action message
        | Unix.Unix_error (code, _, path) -> Error.raise_ "Cannot %s file: %s: %s" action path (Unix.error_message code))

let read path = blocking ~action:"read" (fun () -> In_channel.with_open_bin path In_channel.input_all)

(* Makes the directory that [path] is to be written into, for a file that the driver writes. *)
let make_parent path = blocking ~action:"write" (fun () -> mkdir_p (Filename.dirname (absolute path)))

let write path contents =
    blocking ~action:"write" (fun () ->
        mkdir_p (Filename.dirname (absolute path));
        Out_channel.with_open_bin path (fun oc -> output_string oc contents))

(* The directories among [paths], and the others. *)
let partition_directories paths = blocking ~action:"read" (fun () -> List.partition is_directory paths)

(* {1 Media types} *)

let mime_type path =
    match String.lowercase_ascii (Filename.extension path) with
    | ".html" | ".htm" -> "text/html"
    | ".css" -> "text/css"
    | ".js" | ".mjs" -> "text/javascript"
    | ".json" -> "application/json"
    | ".txt" -> "text/plain"
    | ".csv" -> "text/csv"
    | ".xml" -> "application/xml"
    | ".png" -> "image/png"
    | ".jpg" | ".jpeg" -> "image/jpeg"
    | ".gif" -> "image/gif"
    | ".webp" -> "image/webp"
    | ".svg" -> "image/svg+xml"
    | ".ico" -> "image/x-icon"
    | ".pdf" -> "application/pdf"
    | ".zip" -> "application/zip"
    | ".wasm" -> "application/wasm"
    | ".woff" -> "font/woff"
    | ".woff2" -> "font/woff2"
    | ".ttf" -> "font/ttf"
    | ".mp4" -> "video/mp4"
    | ".webm" -> "video/webm"
    | ".mp3" -> "audio/mpeg"
    | ".wav" -> "audio/wav"
    | _ -> "application/octet-stream"
