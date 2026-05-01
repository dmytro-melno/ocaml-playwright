
type a = { a : int }
and b = [ `Foo [@name "foo"] ]
[@@deriving yojson]
let () = ()
