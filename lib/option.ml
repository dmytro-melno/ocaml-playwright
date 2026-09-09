include Stdlib.Option

module Syntax = struct
    let ( let* )      = Stdlib.Option.bind
    let ( let+ ) x f  = Stdlib.Option.map f x
    let ( >>= ) x f   = Stdlib.Option.bind x f
    let ( >>| ) x f   = Stdlib.Option.map f x
    let ( >=> ) f g x = Stdlib.Option.bind (f x) g
    let ( <=< ) f g x = Stdlib.Option.bind (g x) f
    let ( <|> ) x y   = match x with Some _ -> x | None -> y

    let ( <*> ) f x =
        match f, x with
        | Some f, Some x -> Some (f x)
        | _ -> None

    let ( |? ) x default       = Stdlib.Option.value x ~default
    let ( |?> ) x (f, default) = Stdlib.Option.value (Stdlib.Option.map f x) ~default
end
