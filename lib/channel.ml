(* The vocabulary used by the generated protocol layer. *)

type t = Connection.channel
type conn = Connection.t

let conn (t : t) = t.conn
let guid (t : t) = t.guid
let to_json (t : t) : Json.t = `Assoc [ "guid", `String t.guid ]

let of_json conn (j : Json.t) : t =
    let guid = Json.Decode.(req "guid" string j) in
    match Connection.find conn guid with
    | Some channel -> channel
    | None -> Error.raise_ "Protocol error: object %S is not bound in the connection" guid

let call = Connection.call

(* Gives back what a cancelled command made: see {!Connection.call}.  Nobody is there to hear
   that it could not be done. *)
let release ?(params : Json.t = `Assoc []) method_ (t : t) = try Connection.call t method_ params ignore with Error.E _ -> ()
