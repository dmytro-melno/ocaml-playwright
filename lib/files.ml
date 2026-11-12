(* The paths of local files that are handed to the driver.  The driver reads and writes those
   files, and makes the directories that it writes into; the library opens no file. *)

let absolute path = if Filename.is_relative path then Filename.concat (Sys.getcwd ()) path else path

(* The directories among [paths], and the others.  Asking the file system can take long, on a
   slow disk or across a network, and would hold up every fiber of the domain for as long; so it
   is done in a system thread while the calling fiber waits. *)
let partition_directories paths =
    let is_directory path = try Sys.is_directory path with Sys_error _ -> false in
    Eio_unix.run_in_systhread ~label:"playwright-files" (fun () -> List.partition is_directory paths)
