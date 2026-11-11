(* Opens a page, reads from it and takes a screenshot.

     dune exec examples/quickstart.exe

   The browser is the Chromium that [ocaml-playwright install chromium] installs.  To use one that
   is on the machine already, set CHROMIUM_PATH to its executable. *)

open Playwright

let () =
    Eio_main.run @@ fun env ->
    Playwright.run ~env @@ fun pw ->
    let browser = BrowserType.launch ?executable_path:(Sys.getenv_opt "CHROMIUM_PATH") (chromium pw) in
    let page = Browser.new_page browser in
    ignore (Page.goto "https://example.com" page);
    Printf.printf "title: %s\n" (Page.title page);
    Printf.printf "text:  %s\n" (Page.locator "p" page |> Locator.first |> Locator.inner_text);
    let link = Page.get_by_role `Link page |> Locator.first in
    Printf.printf "link:  %s -> %s\n" (Locator.inner_text link) (Option.value (Locator.get_attribute "href" link) ~default:"?");
    ignore (Page.screenshot ~path:"example.png" page);
    print_endline "saved example.png";
    Browser.close browser
