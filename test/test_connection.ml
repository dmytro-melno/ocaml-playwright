
open Eio.Std

let () =
  Eio_main.run @@ fun env ->
  Switch.run @@ fun sw ->
  let process_mgr = Eio.Stdenv.process_mgr env in
  let p1_r, p1_w = Eio.Process.pipe ~sw process_mgr in
  let p2_r, p2_w = Eio.Process.pipe ~sw process_mgr in
  
  let _ = Playwright.Driver.run ~sw ~process_mgr ~stdin:p1_r ~stdout:p2_w () in
  
  let conn = Playwright.Connection.create p2_r p1_w in
  Eio.Fiber.fork ~sw (fun () -> Playwright.Connection.run_loop conn);
  
  Printf.printf "Sending initialize...\n%!";
  let result = Playwright.Connection.send_message conn ~guid:"" ~method_:"initialize" ~params:(`Assoc ["sdkLanguage", `String "javascript"]) in
  match result with
  | Ok res -> Printf.printf "Initialized: %s\n%!" (Yojson.Safe.to_string res)
  | Error err -> Printf.printf "Error: %s\n%!" err
