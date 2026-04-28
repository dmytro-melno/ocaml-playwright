
open Eio.Std

type callback = (Yojson.Safe.t, string) result Promise.u

type t = {
  objects : (string, channel_owner) Hashtbl.t;
  callbacks : (int, callback) Hashtbl.t;
  mutable last_id : int;
  transport_r : Eio.Flow.source_ty Eio.Resource.t;
  transport_w : Eio.Flow.sink_ty Eio.Resource.t;
}

and channel_owner = {
  guid : string;
  connection : t;
  obj_type : string;
  mutable parent : channel_owner option;
  initializer_ : Yojson.Safe.t;
  events : (string, (Yojson.Safe.t -> unit) list) Hashtbl.t;
}

let create transport_r transport_w =
  {
    objects = Hashtbl.create 100;
    callbacks = Hashtbl.create 100;
    last_id = 0;
    transport_r = (transport_r :> Eio.Flow.source_ty Eio.Resource.t);
    transport_w = (transport_w :> Eio.Flow.sink_ty Eio.Resource.t);
  }

let send_message (t : t) ~(guid: string) ~(method_: string) ~(params: Yojson.Safe.t) : (Yojson.Safe.t, string) result =
  t.last_id <- t.last_id + 1;
  let id = t.last_id in
  let promise, resolver = Promise.create () in
  Hashtbl.add t.callbacks id resolver;
  let msg = `Assoc [
    ("id", `Int id);
    ("guid", `String guid);
    ("method", `String method_);
    ("params", params);
    ("metadata", `Assoc []);
  ] in
  Transport.write_message t.transport_w (Yojson.Safe.to_string msg);
  Promise.await promise

let dispatch (t : t) (msg : Yojson.Safe.t) =
  let open Yojson.Safe.Util in
  let id = member "id" msg |> to_int_option in
  match id with
  | Some id ->
    (match Hashtbl.find_opt t.callbacks id with
     | Some resolver ->
       Hashtbl.remove t.callbacks id;
       let error = member "error" msg in
       if error <> `Null then
         let error_msg = member "message" (member "error" error) |> to_string_option |> Option.value ~default:"Unknown error" in
         Promise.resolve resolver (Error error_msg)
       else
         let result = member "result" msg in
         Promise.resolve resolver (Ok result)
     | None -> Printf.eprintf "Received response for unknown id %d\n%!" id)
  | None ->
    let method_ = member "method" msg |> to_string_option in
    let guid = member "guid" msg |> to_string_option in
    match method_, guid with
    | Some "__create__", Some _guid ->
      let params = member "params" msg in
      let type_ = member "type" params |> to_string in
      let guid_new = member "guid" params |> to_string in
      let initializer_ = member "initializer" params in
      let obj = { guid = guid_new; connection = t; obj_type = type_; parent = None; initializer_; events = Hashtbl.create 5 } in
      Hashtbl.add t.objects guid_new obj;
      Printf.printf "Created object %s of type %s\n%!" guid_new type_
    | Some "__dispose__", Some guid ->
      Hashtbl.remove t.objects guid;
      Printf.printf "Disposed object %s\n%!" guid
    | Some method_, Some guid ->
      (match Hashtbl.find_opt t.objects guid with
       | Some obj ->
         (match Hashtbl.find_opt obj.events method_ with
          | Some cbs ->
            let params = member "params" msg in
            List.iter (fun cb -> try cb params with _ -> ()) cbs
          | None -> ())
       | None -> Printf.printf "Received event %s for unknown object %s\n%!" method_ guid)
    | _ ->
      Printf.eprintf "Received unknown message: %s\n%!" (Yojson.Safe.to_string msg)

let run_loop (t : t) =
  try
    while true do
      match Transport.read_message t.transport_r with
      | Some msg_str ->
        (try
           let msg = Yojson.Safe.from_string msg_str in
           dispatch t msg
         with exn ->
           Printf.eprintf "Error parsing or dispatching message: %s\n%!" (Printexc.to_string exn))
      | None ->
        raise Exit
    done
  with Exit -> ()

let on (obj : channel_owner) event_name cb =
  let cbs = match Hashtbl.find_opt obj.events event_name with
    | Some cbs -> cbs
    | None -> []
  in
  Hashtbl.replace obj.events event_name (cbs @ [cb])
