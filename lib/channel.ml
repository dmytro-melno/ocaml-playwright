type conn = Connection.t
type any = Connection.channel
type -'kind t = any
type 'kind kind = string list

let kind names = names
let is (kind : _ kind) (channel : any) = List.exists (String.equal channel.type_) kind
let of_any kind channel = if is kind channel then Some channel else None
let narrow = of_any

let any_of_json conn (j : Json.t) : any =
    let guid = Json.Decode.(req "guid" string j) in
    match Connection.find conn guid with
    | Some channel -> channel
    | None -> Error.raise_ "Protocol error: object %S is not bound in the connection" guid

let of_json kind conn j =
    let channel = any_of_json conn j in
    if is kind channel then channel else Error.raise_ "Protocol error: object %S is of type %s, not %s" channel.guid channel.type_ (List.hd kind)

let any t = t
let any_to_json (t : any) : Json.t = `Assoc [ "guid", `String t.guid ]
let to_json = any_to_json
let conn (t : any) = t.conn
let guid (t : any) = t.guid
let is_disposed (t : any) = t.disposed
let parent kind (t : any) = Option.bind t.parent (of_any kind)

let rec ancestor kind (t : any) =
    match t.parent with
    | Some parent -> if is kind parent then Some parent else ancestor kind parent
    | None -> None

let initializer_ (t : any) = t.initializer_
let listen (t : any) handle = t.on_event <- handle
let on_lost (t : any) handle = t.on_lost <- handle
let call = Connection.call
let release ?(params : Json.t = `Assoc []) method_ t = try Connection.call t method_ params ignore with Error.E _ -> ()
