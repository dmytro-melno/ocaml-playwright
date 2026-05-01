
[@@@ocaml.warning "-34-69"]
type obj = { conn: int; guid: string }
module rec A : sig
  type t = { a: int }
  and b = [ | `Foo [@name "foo"] ] [@@deriving yojson]
end = struct
  type t = { a: int }
  and b = [ | `Foo [@name "foo"] ] [@@deriving yojson]
end
let () = ()
