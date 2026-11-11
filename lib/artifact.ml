(* Files produced by the browser: downloads, videos, traces. *)

open Types

let chunk_size = 1024 * 1024

(* Copies a driver-side stream into a local file. *)
let save_stream (stream : Protocol.Stream.t) path =
    Files.mkdir_p (Filename.dirname (Files.absolute path));
    Connection.protect (Channel.conn stream) "closing a stream"
        ~finally:(fun () -> try Protocol.Stream.close stream with Error.E _ -> ())
        (fun () ->
            try
                Out_channel.with_open_bin path (fun oc ->
                    let rec copy () =
                        match Protocol.Stream.read ~size:chunk_size stream with
                        | "" -> ()
                        | chunk -> output_string oc chunk; copy ()
                    in
                    copy ())
            with Sys_error message -> Error.raise_ "Cannot write file %s: %s" path message)

let path_after_finished (session : session) (artifact : Protocol.Artifact.t) =
    if session.is_remote then Error.raise_ "Path is not available when connecting remotely. Use save_as to save a local copy.";
    Protocol.Artifact.path_after_finished artifact

let save_as (session : session) (artifact : Protocol.Artifact.t) path =
    if session.is_remote then save_stream (Protocol.Artifact.save_as_stream artifact) path
    else begin
        Files.mkdir_p (Filename.dirname (Files.absolute path));
        Protocol.Artifact.save_as ~path:(Files.absolute path) artifact
    end

let failure (artifact : Protocol.Artifact.t) = Protocol.Artifact.failure artifact
let cancel (artifact : Protocol.Artifact.t) = Protocol.Artifact.cancel artifact
let delete (artifact : Protocol.Artifact.t) = Protocol.Artifact.delete artifact
