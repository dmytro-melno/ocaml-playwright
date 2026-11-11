(* Files produced by the browser: downloads, videos, traces. *)

open Types

(* Copies a driver-side stream into a local file. *)
let save_stream (stream : Protocol.Stream.t) path =
    Connection.protect (Channel.conn stream) "closing a stream"
        ~finally:(fun () -> try Protocol.Stream.close stream with Error.E _ -> ())
        (fun () ->
            Files.with_output path (fun write ->
                let rec copy () =
                    match Protocol.Stream.read ~size:Files.chunk_size stream with
                    | "" -> ()
                    | chunk ->
                        write chunk;
                        copy ()
                in
                copy ()))

let path_after_finished (session : session) (artifact : Protocol.Artifact.t) =
    if session.is_remote then Error.raise_ "Path is not available when connecting remotely. Use save_as to save a local copy.";
    Protocol.Artifact.path_after_finished artifact

let save_as (session : session) (artifact : Protocol.Artifact.t) path =
    if session.is_remote then save_stream (Protocol.Artifact.save_as_stream artifact) path
    else begin
        Files.make_parent path;
        Protocol.Artifact.save_as ~path:(Files.absolute path) artifact
    end

let failure (artifact : Protocol.Artifact.t) = Protocol.Artifact.failure artifact
let cancel (artifact : Protocol.Artifact.t) = Protocol.Artifact.cancel artifact
let delete (artifact : Protocol.Artifact.t) = Protocol.Artifact.delete artifact
