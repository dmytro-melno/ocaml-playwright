include Stdlib.Result

module Syntax = struct
    let ( let* )      = Stdlib.Result.bind
    let ( let+ ) x f  = Stdlib.Result.map f x
    let ( >>= ) x f   = Stdlib.Result.bind x f
    let ( >>| ) x f   = Stdlib.Result.map f x
    let ( >=> ) f g x = Stdlib.Result.bind (f x) g
    let ( <=< ) f g x = Stdlib.Result.bind (g x) f
    let ( <|> ) x y   = match x with Ok _ -> x | Error _ -> y

    let ( <*> ) f x =
        match f, x with
        | Ok f, Ok x -> Ok (f x)
        | Error e, _ -> Error e
        | _, Error e -> Error e

    let ( |>> ) x (f, g) =
        match x with Ok v -> Ok (f v) | Error e -> Error (g e)
end
