(* Collects the OCaml code blocks of Markdown files, and the examples in the documentation
   comments of interfaces, into one OCaml source, printed to standard output, for the compiler
   to check.

   A block that starts with [open] or [let () =] is taken to be a complete program.  Every other
   block is an expression, in which [Playwright] is open and these names are bound: [env], [pw],
   [browser], [context], [page], [frame] and [locator].  Line directives make the compiler report
   errors at their place in the Markdown file.

   In Markdown, only blocks opened by exactly [```ocaml] are collected.  One that is not meant
   to compile, as it shows an old API for instance, is opened by [```ocaml skip].  In an
   interface, a block is what stands between a line that consists of the opening bracket of a
   code block and the line that starts with the closing one. *)

type block = { file : string; first_line : int; code : string list }

let blocks file =
    let opens, closes =
        if Filename.check_suffix file ".mli" then (fun line -> line = "{["), String.starts_with ~prefix:"]}"
        else (fun line -> line = "```ocaml"), fun line -> line = "```"
    in
    let rec outside number found = function
        | [] -> List.rev found
        | line :: rest when opens (String.trim line) -> inside (number + 1) [] found rest
        | _ :: rest -> outside (number + 1) found rest
    and inside first_line code found = function
        | [] -> failwith (Printf.sprintf "%s:%d: this code block is not closed" file first_line)
        | line :: rest when closes (String.trim line) ->
            outside (first_line + List.length code + 1) ({ file; first_line; code = List.rev code } :: found) rest
        | line :: rest -> inside first_line (line :: code) found rest
    in
    outside 1 [] (In_channel.with_open_text file In_channel.input_lines)

let is_program block =
    match List.find_opt (fun line -> String.trim line <> "") block.code with
    | Some line -> List.exists (fun prefix -> String.starts_with ~prefix (String.trim line)) [ "open "; "let () =" ]
    | None -> false

(* The name under which the compiler reports a file: its path from the root of the project. *)
let rec display_name file = if String.starts_with ~prefix:"../" file then display_name (String.sub file 3 (String.length file - 3)) else file

let print index block =
    let code () =
        Printf.printf "# %d %S\n" block.first_line (display_name block.file);
        List.iter print_endline block.code
    in
    if is_program block then (
        (* A functor that nothing applies: the program is checked without being run. *)
        Printf.printf "module Program_%d (Never : sig end) = struct\n" index;
        code ();
        print_endline "end\n")
    else (
        print_endline "let _ =";
        print_endline "    fun (env : Eio_unix.Stdenv.base) (pw : Playwright.t) (browser : Playwright.Browser.t) (context : Playwright.BrowserContext.t)";
        print_endline "        (page : Playwright.Page.t) (frame : Playwright.Frame.t) (locator : Playwright.Locator.t) ->";
        print_endline "    let open Playwright in";
        print_endline "    ignore (";
        code ();
        print_endline "    )\n")

let () =
    let files = List.tl (Array.to_list Sys.argv) in
    print_endline "(* Generated from the documentation by extract.ml. *)\n";
    List.concat_map blocks files |> List.iteri print
