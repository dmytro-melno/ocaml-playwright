
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
  let result = Playwright.Api.Root.initialize conn "" { 
    Playwright.Protocol.root_initialize_args_sdk_language = `Javascript 
  } in
  match result with
  | Ok res -> 
      Printf.printf "Initialized Playwright channel: %s\n%!" res.Playwright.Protocol.root_initialize_returns_playwright.guid
  | Error err -> Printf.printf "Error: %s\n%!" err
