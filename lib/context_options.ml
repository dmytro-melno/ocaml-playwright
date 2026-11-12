(* The options of a browser context, shared by every way of creating one. *)

open Types

module Geolocation = struct
    type t = { latitude : float; longitude : float; accuracy : float option }

    let make ?accuracy ~latitude ~longitude () = { latitude; longitude; accuracy }
end

module Http_credentials = struct
    type t = { username : string; password : string; origin : string option; send : [ `Always | `Unauthorized ] option }

    let make ?origin ?send ~username ~password () = { username; password; origin; send }
    let to_protocol (c : t) : Protocol.Http_credentials.t = { username = c.username; password = c.password; origin = c.origin; send = c.send }

    (* The driver takes no credentials to mean that none were given. *)
    let list = function None | Some [] -> None | Some credentials -> Some (List.map to_protocol credentials)
end

module Client_certificate = struct
    type t = { origin : string; cert : string option; key : string option; pfx : string option; passphrase : string option }

    let pem ?passphrase ~origin ~cert ~key () = { origin; cert = Some cert; key = Some key; pfx = None; passphrase }
    let pfx ?passphrase ~origin pfx = { origin; cert = None; key = None; pfx = Some pfx; passphrase }

    let to_protocol (c : t) : Protocol.Context_options_client_certificates.t =
        { origin = c.origin; cert = c.cert; key = c.key; passphrase = c.passphrase; pfx = c.pfx }

    let list = function None | Some [] -> None | Some certificates -> Some (List.map to_protocol certificates)
end

module Proxy = struct
    type t = { server : string; bypass : string option; username : string option; password : string option }

    let make ?bypass ?username ?password server = { server; bypass; username; password }
end

type t = {
    no_default_viewport : bool option;
    viewport : Protocol.Context_options_viewport.t option;
    screen : Protocol.Context_options_screen.t option;
    ignore_https_errors : bool option;
    java_script_enabled : bool option;
    bypass_csp : bool option;
    user_agent : string option;
    locale : string option;
    timezone_id : string option;
    geolocation : Protocol.Context_options_geolocation.t option;
    permissions : string list option;
    extra_http_headers : Protocol.Name_value.t list option;
    offline : bool option;
    http_credentials : Protocol.Http_credentials.t list option;
    client_certificates : Protocol.Context_options_client_certificates.t list option;
    device_scale_factor : float option;
    is_mobile : bool option;
    has_touch : bool option;
    color_scheme : [ `Dark | `Light | `No_override | `No_preference ] option;
    reduced_motion : [ `No_override | `No_preference | `Reduce ] option;
    forced_colors : [ `Active | `No_override | `None ] option;
    contrast : [ `More | `No_override | `No_preference ] option;
    accept_downloads : [ `Accept | `Deny | `Internal_browser_default ] option;
    base_url : string option;
    record_video : Protocol.Context_options_record_video.t option;
    service_workers : [ `Allow | `Block ] option;
}

let size (width, height) : size = { width; height }

(* Gathers the options and hands them, with the object the call is made on, to [k].  Explicit
   options take precedence over what [device] prescribes. *)
let collect k ?(device : device option) ?viewport ?(no_viewport = false) ?screen ?ignore_https_errors ?java_script_enabled ?bypass_csp
    ?user_agent ?locale ?timezone_id ?(geolocation : Geolocation.t option) ?permissions ?extra_http_headers ?offline
    ?(http_credentials : Http_credentials.t list option) ?(client_certificates : Client_certificate.t list option) ?device_scale_factor ?is_mobile ?has_touch
    ?(color_scheme : [ `Dark | `Light | `No_override | `No_preference ] option)
    ?(reduced_motion : [ `No_override | `No_preference | `Reduce ] option) ?(forced_colors : [ `Active | `No_override | `None ] option)
    ?(contrast : [ `More | `No_override | `No_preference ] option) ?accept_downloads ?base_url ?record_video_dir ?record_video_size
    ?(service_workers : [ `Allow | `Block ] option) target =
    let or_device explicit from_device = match explicit with Some _ -> explicit | None -> Option.map from_device device in
    let viewport = or_device (Option.map size viewport) (fun device -> device.device_viewport) in
    let screen = match Option.map size screen with Some _ as screen -> screen | None -> Option.bind device (fun device -> device.device_screen) in
    let record_video =
        Option.map
            (fun dir : Protocol.Context_options_record_video.t ->
                let size = Option.map (fun (width, height) : Protocol.Context_options_record_video_size.t -> { width; height }) record_video_size in
                { dir = Some (Files.absolute dir); size; fps = None; show_actions = None })
            record_video_dir
    in
    if record_video = None && record_video_size <> None then invalid_arg "Playwright: ~record_video_size requires ~record_video_dir";
    let options =
        { no_default_viewport = (if no_viewport then Some true else None);
          viewport = (if no_viewport then None else Option.map (fun (s : size) : Protocol.Context_options_viewport.t -> { width = s.width; height = s.height }) viewport);
          screen = Option.map (fun (s : size) : Protocol.Context_options_screen.t -> { width = s.width; height = s.height }) screen;
          ignore_https_errors; java_script_enabled; bypass_csp;
          user_agent = or_device user_agent (fun device -> device.device_user_agent);
          locale; timezone_id;
          geolocation = Option.map (fun (g : Geolocation.t) : Protocol.Context_options_geolocation.t -> { longitude = g.longitude; latitude = g.latitude; accuracy = g.accuracy }) geolocation;
          permissions;
          extra_http_headers = Option.map Network.name_values extra_http_headers;
          offline;
          http_credentials = Http_credentials.list http_credentials;
          client_certificates = Client_certificate.list client_certificates;
          device_scale_factor = or_device device_scale_factor (fun device -> device.device_scale_factor);
          is_mobile = or_device is_mobile (fun device -> device.device_is_mobile);
          has_touch = or_device has_touch (fun device -> device.device_has_touch);
          color_scheme; reduced_motion; forced_colors; contrast;
          accept_downloads = Option.map (fun accept -> if accept then `Accept else `Deny) accept_downloads;
          base_url; record_video; service_workers }
    in
    k options target
