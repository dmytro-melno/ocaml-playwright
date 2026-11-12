(* Takes a screenshot of a page the way a device shows it.

     dune exec examples/screenshot.exe -- https://ocaml.org ocaml.png "iPhone 15"

   Without a device name the page is rendered in a desktop-sized window.  CHROMIUM_PATH selects
   the browser as in quickstart.ml. *)

open Playwright

let () =
    let url, path, device_name =
        match Array.to_list Sys.argv with
        | [ _; url; path ] -> url, path, None
        | [ _; url; path; device ] -> url, path, Some device
        | _ ->
            prerr_endline "usage: screenshot URL FILE [DEVICE]";
            exit 2
    in
    let type_ = match String.lowercase_ascii (Filename.extension path) with ".jpg" | ".jpeg" -> Some `Jpeg | ".webp" -> Some `Webp | _ -> None in
    Eio_main.run @@ fun env ->
    Playwright.run ~env @@ fun pw ->
    let device =
        Option.map
            (fun name ->
                match Playwright.device pw name with
                | Some device -> device
                | None ->
                    Printf.eprintf "unknown device %S; some that exist:\n" name;
                    List.iteri (fun i device -> if i < 10 then prerr_endline ("  " ^ Device.name device)) (Playwright.devices pw);
                    exit 2)
            device_name
    in
    let browser = BrowserType.launch (chromium pw) ?executable_path:(Sys.getenv_opt "CHROMIUM_PATH") in
    let context = match device with Some device -> Browser.new_context browser ~device | None -> Browser.new_context browser ~viewport:(1280, 800) in
    let page = BrowserContext.new_page context in
    (match Page.goto page ~wait_until:`Networkidle url with
    | Some response -> Printf.printf "%d %s\n" (Response.status response) (Page.url page)
    | None -> ());
    let image = Page.screenshot page ~full_page:true ?type_ in
    Eio.Path.(save ~create:(`Or_truncate 0o644) (Eio.Stdenv.fs env / path) image);
    Printf.printf "%s: %d bytes\n" path (String.length image);
    Browser.close browser
