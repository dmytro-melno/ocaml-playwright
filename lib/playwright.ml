
module Transport = Transport
module Driver = Driver
module Connection = Connection
module Protocol = Protocol
module Api = Api
include Hl

let with_playwright ~env f =
  Eio.Switch.run @@ fun sw ->
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

  Fun.protect (fun () -> f main)
    ~finally:(fun () ->
      Eio.Flow.close p1_w;
      Eio.Flow.close p2_r;
      ignore (Eio.Process.await p))
