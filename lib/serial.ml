(* Numbers that tell the objects of this process apart, handed out in the order of their creation.

   A guid identifies an object within its connection only, and a program may have several connections. *)

type t = int

let last = Atomic.make 0
let next () : t = Atomic.fetch_and_add last 1 + 1
