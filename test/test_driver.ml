
open Eio.Std

let () =
  Eio_main.run @@ fun env ->
  Switch.run @@ fun sw ->
  let process_mgr = Eio.Stdenv.process_mgr env in
  let p1_r, p1_w = Eio.Process.pipe ~sw process_mgr in
  let p2_r, p2_w = Eio.Process.pipe ~sw process_mgr in
  
  let _ = Playwright.Driver.run ~sw ~process_mgr ~stdin:p1_r ~stdout:p2_w () in
  
  Playwright.Transport.write_message p1_w "{}";
  match Playwright.Transport.read_message p2_r with
  | Some msg -> Printf.printf "Received: %s\n%!" msg
  | None -> Printf.printf "EOF\n%!"
