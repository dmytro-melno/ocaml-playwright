(* Works with several pages at the same time, one fiber each.

     dune exec examples/parallel.exe -- https://ocaml.org https://example.com https://playwright.dev

   Every page gets a browser context of its own, so that the pages share nothing: neither
   cookies nor cache. *)

open Playwright

let () =
    let urls = match List.tl (Array.to_list Sys.argv) with [] -> [ "https://example.com"; "https://ocaml.org"; "https://playwright.dev" ] | urls -> urls in
    Eio_main.run @@ fun env ->
    Playwright.run ~env @@ fun pw ->
    let browser = BrowserType.launch ?executable_path:(Sys.getenv_opt "CHROMIUM_PATH") (chromium pw) in
    let started = Unix.gettimeofday () in
    let visit url =
        let context = Browser.new_context browser in
        Fun.protect
            ~finally:(fun () -> BrowserContext.close context)
            (fun () ->
                let page = BrowserContext.new_page context in
                match Page.goto page ~timeout:20_000. url with
                | response ->
                    let status = Option.fold ~none:"-" ~some:(fun r -> string_of_int (Response.status r)) response in
                    Printf.sprintf "%s %-28s %s (%d links)" status url (Page.title page) (Page.locator page "a" |> Locator.count)
                | exception Playwright.Error error -> Printf.sprintf "ERR %-28s %s" url (List.hd (String.split_on_char '\n' error.message)))
    in
    (* At most four pages are loading at any time. *)
    Eio.Fiber.List.map ~max_fibers:4 visit urls |> List.iter print_endline;
    Printf.printf "%d pages in %.1f s\n" (List.length urls) (Unix.gettimeofday () -. started);
    Browser.close browser
