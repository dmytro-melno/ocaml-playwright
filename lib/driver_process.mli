(** Driver-owned binary pipes and process lifecycle, on the session's Eio domain. *)
type t

val spawn : sw:Eio.Switch.t -> env:Eio_unix.Stdenv.base -> cli:string -> t
val stdin : t -> [Eio.Flow.sink_ty | Eio.Resource.close_ty] Eio.Resource.t
val stdout : t -> [Eio.Flow.source_ty | Eio.Resource.close_ty] Eio.Resource.t
val await : t -> Eio.Process.exit_status
val terminate : t -> unit
val kill : t -> unit
