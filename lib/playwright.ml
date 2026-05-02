
module Transport = Transport
module Driver = Driver
module Connection = Connection
include Api

let instances = Hashtbl.create 1

let create ~env ~sw () =
  let process_mgr = Eio.Stdenv.process_mgr env in
  let p1_r, p1_w = Eio.Process.pipe ~sw process_mgr in
  let p2_r, p2_w = Eio.Process.pipe ~sw process_mgr in

  let p = Driver.run ~sw ~process_mgr ~stdin:p1_r ~stdout:p2_w () in
  Eio.Flow.close p1_r;
  Eio.Flow.close p2_w;

  let conn = Connection.create (p2_r :> Eio.Flow.source_ty Eio.Resource.t) (p1_w :> Eio.Flow.sink_ty Eio.Resource.t) in
  Eio.Fiber.fork ~sw (fun () -> Connection.run_loop conn);

  let root = { conn; guid = "" } in
  let main = Root.initialize ~sdk_language:`Javascript root in

  let close () =
    Eio.Flow.close p1_w;
    Eio.Flow.close p2_r;
    ignore (Eio.Process.await p)
  in
  Hashtbl.add instances main.guid close;
  main

let destroy (main : Playwright.t) =
  match Hashtbl.find_opt instances main.guid with
  | Some close ->
      close ();
      Hashtbl.remove instances main.guid
  | None -> ()
