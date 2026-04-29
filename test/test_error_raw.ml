
let () =
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let playwright = Playwright.create ~env ~sw () in
  let chromium = Playwright.Hl.Playwright.chromium playwright.main in

  let browser = Playwright.Hl.Browser_type.launch ~executable_path:"/usr/bin/chromium" ~headless:true ~timeout:0.0 chromium in
  let ctx = Playwright.Hl.Browser.new_context browser in
  let page = Playwright.Hl.Browser_context.new_page ctx in
  let main_frame = Playwright.Hl.Page.main_frame page in

  let conn = chromium.conn in

  let promise, resolver = Eio.Promise.create () in
  conn.last_id <- conn.last_id + 1;
  let id = conn.last_id in
  Hashtbl.add conn.callbacks id resolver;
  let params = `Assoc [ ("url", `String "https://this-will-fail.invalid"); ("timeout", `Float 1000.0) ] in
  let msg = `Assoc [
    ("id", `Int id);
    ("guid", `String main_frame.guid);
    ("method", `String "goto");
    ("params", params);
    ("metadata", `Assoc []);
  ] in

  Playwright.Transport.write_message conn.transport_w (Yojson.Safe.to_string msg);
  Playwright.Transport.write_message conn.transport_w (Yojson.Safe.to_string msg);
  let res = Eio.Promise.await promise in
  (match res with
  | Error e -> Printf.printf "Raw error parsed string: %s\n" e
  | Ok v -> Printf.printf "Raw ok: %s\n" (Yojson.Safe.to_string v));
