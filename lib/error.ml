
type t = {
  message : string;
  name : string;
  stack : string option;
}

exception Playwright_error of t

let to_string e =
  Printf.sprintf "%s: %s\n%s" e.name e.message (Option.value ~default:"" e.stack)
