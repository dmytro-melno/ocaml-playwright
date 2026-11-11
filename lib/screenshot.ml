(* Options shared by every way of taking a screenshot. *)

open Types

let image_type ?type_ ?path () =
    match type_, path with
    | Some type_, _ -> Some type_
    | None, None -> None
    | None, Some path ->
        (match String.lowercase_ascii (Filename.extension path) with
        | ".png" -> Some `Png
        | ".jpg" | ".jpeg" -> Some `Jpeg
        | ".webp" -> Some `Webp
        | extension -> Error.raise_ "path: unsupported screenshot file type %S, expected .png, .jpeg or .webp" extension)

let mask (locators : locator list) : Protocol.Common_screenshot_options_mask.t list =
    List.map (fun (locator : locator) -> { Protocol.Common_screenshot_options_mask.frame = locator.l_frame.f_channel; selector = locator.selector }) locators

let save ?path image =
    Option.iter (fun path -> Files.write path image) path;
    image
