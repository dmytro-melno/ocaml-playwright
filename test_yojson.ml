
type a = { x: int } [@@deriving yojson]
type b = { 
  a: a; [@yojson.inline]
  y: int 
} [@@deriving yojson]
