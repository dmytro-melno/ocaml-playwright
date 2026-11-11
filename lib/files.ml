(* Local file access on behalf of API calls that take or produce files.

   A file can be large, and can live on a slow disk or on a file system across a network: reading
   or writing it in place would hold up every fiber of the domain for as long.  What touches the
   contents of files or walks directories is therefore done in a system thread, while the
   calling fiber waits ({!blocking}). *)

let chunk_size = 1 lsl 20
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

(* [with_output path f] creates the file and calls [f] with the function that appends to it. *)
let with_output path f =
    let oc =
        blocking ~action:"write" (fun () ->
            mkdir_p (Filename.dirname (absolute path));
            Out_channel.open_bin path)
    in
    (* A thread is not to be had by a fiber that has been cancelled, so the channel is closed in
       place when things go wrong. *)
    Fun.protect
        ~finally:(fun () -> Out_channel.close_noerr oc)
        (fun () ->
            let result = f (fun chunk -> blocking ~action:"write" (fun () -> Out_channel.output_string oc chunk)) in
            blocking ~action:"write" (fun () -> Out_channel.close oc);
            result)

(* [with_input path f] calls [f] with the function that returns the next part of the file, of
   {!chunk_size} bytes at most, and [""] after the last one. *)
let with_input path f =
    let ic = blocking ~action:"read" (fun () -> In_channel.open_bin path) in
    Fun.protect
        ~finally:(fun () -> In_channel.close_noerr ic)
        (fun () ->
            let buffer = Bytes.create chunk_size in
            (* A channel hands out no more than its own buffer holds at a time, which is less. *)
            let rec fill filled =
                if filled = chunk_size then filled
                else
                    match In_channel.input ic buffer filled (chunk_size - filled) with
                    | 0 -> filled
                    | n -> fill (filled + n)
            in
            f (fun () -> blocking ~action:"read" (fun () -> Bytes.sub_string buffer 0 (fill 0))))

(* {1 Uploads} *)

type upload = { name : string; path : string; modified_ms : float }

(* The files below [directory], as paths relative to it. *)
let rec below directory =
    Sys.readdir directory |> Array.to_list |> List.sort String.compare
    |> List.concat_map (fun name ->
        let path = Filename.concat directory name in
        if is_directory path then List.map (fun below -> name ^ "/" ^ below) (below path) else [ name ])

(* The files to send for an upload: those below [directory], or else [files] themselves. *)
let to_upload ?directory files =
    blocking ~action:"read" (fun () ->
        let named =
            match directory with
            | Some directory -> List.map (fun name -> name, Filename.concat directory name) (below directory)
            | None -> List.map (fun path -> Filename.basename path, path) files
        in
        List.map (fun (name, path) -> { name; path; modified_ms = (Unix.stat path).st_mtime *. 1000. }) named)

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
