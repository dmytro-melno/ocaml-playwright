(* Files produced by the browser: downloads, videos.  The driver writes them. *)

let path_after_finished (artifact : Protocol.Artifact.t) = Protocol.Artifact.path_after_finished artifact

let save_as (artifact : Protocol.Artifact.t) path =
    Files.make_parent path;
    Protocol.Artifact.save_as ~path:(Files.absolute path) artifact

let failure (artifact : Protocol.Artifact.t) = Protocol.Artifact.failure artifact
let cancel (artifact : Protocol.Artifact.t) = Protocol.Artifact.cancel artifact
let delete (artifact : Protocol.Artifact.t) = Protocol.Artifact.delete artifact
