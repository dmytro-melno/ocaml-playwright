type t = {
    message : string;
    name : string;
    stack : string option;
}

exception Playwright_error of t

let to_string e =
    let open Option.Syntax in
    Printf.sprintf "%s: %s\n%s" e.name e.message (e.stack |? "")
