open Eio.Std

exception Closed of string

type event_error = {
  guid : string;
  event : string;
  exception_ : exn;
  backtrace : Printexc.raw_backtrace;
}

type callback = (Yojson.Safe.t, string) result Promise.u
type state = Open | Closed_state of string

type t = {
  objects : (string, channel_owner) Hashtbl.t;
  callbacks : (int, callback) Hashtbl.t;
  mutable last_id : int;
  transport_r : Eio.Flow.source_ty Eio.Resource.t;
  transport_w : Eio.Flow.sink_ty Eio.Resource.t;
  write_lock : Eio.Mutex.t;
  mutable state : state;
  closed : string Promise.t;
  closed_u : string Promise.u;
  event_queue : (string * string * listener * Yojson.Safe.t) Queue.t;
  event_ready : Eio.Condition.t;
  max_event_tasks : int;
  mutable event_tasks : int;
  on_event_error : event_error -> unit;
  mutable running : bool;
  mutable await_cleanup : (unit -> unit) option;
}

and channel_owner = {
  guid : string;
  connection : t;
  obj_type : string;
  mutable parent : channel_owner option;
  initializer_ : Yojson.Safe.t;
  events : (string, listener list) Hashtbl.t;
}

and listener = {
  id : int;
  mutable active : bool;
  callback : Yojson.Safe.t -> unit;
  mutable tasks : (int * Eio.Cancel.t) list;
}

let current_connection_key : t Eio.Fiber.key = Eio.Fiber.create_key ()
(* Only a marker is needed. Fiber locals are inherited: storing the connection
   here would retain A in B's supervisor if a callback in A creates session B. *)
let callback_context_key : unit Eio.Fiber.key = Eio.Fiber.create_key ()

let default_event_error (e : event_error) =
  Printf.eprintf "Playwright event %s.%s: %s\n%s%!"
    e.guid e.event (Printexc.to_string e.exception_)
    (Printexc.raw_backtrace_to_string e.backtrace)

let create ?(max_event_tasks = 1024) ?(on_event_error = default_event_error)
    transport_r transport_w =
  if max_event_tasks < 1 then invalid_arg "max_event_tasks must be positive";
  let closed, closed_u = Promise.create () in
  {
    objects = Hashtbl.create 100;
    callbacks = Hashtbl.create 100;
    last_id = 0;
    transport_r = (transport_r :> Eio.Flow.source_ty Eio.Resource.t);
    transport_w = (transport_w :> Eio.Flow.sink_ty Eio.Resource.t);
    write_lock = Eio.Mutex.create ();
    state = Open;
    closed; closed_u;
    event_queue = Queue.create ();
    event_ready = Eio.Condition.create ();
    max_event_tasks;
    event_tasks = 0;
    on_event_error;
    running = false;
    await_cleanup = None;
  }

let closed_reason t =
  match t.state with Open -> None | Closed_state reason -> Some reason

let check_open t =
  match t.state with Open -> () | Closed_state reason -> raise (Closed reason)

(* One non-suspending transition. Physical cleanup is owned by the runtime, not
   by whichever reader, caller, or callback first observes the failure. *)
let close t reason =
  match t.state with
  | Closed_state _ -> ()
  | Open ->
    t.state <- Closed_state reason;
    Hashtbl.iter (fun _ resolver -> Promise.resolve resolver (Error reason)) t.callbacks;
    Hashtbl.clear t.callbacks;
    Hashtbl.iter (fun _ obj ->
      Hashtbl.iter (fun _ listeners ->
        List.iter (fun listener -> listener.active <- false) listeners) obj.events;
      Hashtbl.clear obj.events) t.objects;
    Hashtbl.clear t.objects;
    t.event_tasks <- t.event_tasks - Queue.length t.event_queue;
    Queue.clear t.event_queue;
    Promise.resolve t.closed_u reason;
    Eio.Condition.broadcast t.event_ready

let destroy t =
  close t "Playwright instance destroyed";
  (* A callback cannot join its own scope. This also avoids cyclic joins when
     callbacks in two sessions destroy one another. In callback context, destroy
     initiates closure; an ordinary caller can subsequently join the cleanup. *)
  match Eio.Fiber.get callback_context_key with
  | Some _ -> ()
  | None ->
    Eio.Cancel.protect (fun () ->
      Option.iter (fun await -> await ()) t.await_cleanup)

let send_message t ~guid ~method_ ~params =
  match closed_reason t with
  | Some reason -> Error reason
  | None ->
    t.last_id <- t.last_id + 1;
    let id = t.last_id in
    (* Serialization can fail locally. No request has been registered yet. *)
    let message = Yojson.Safe.to_string (`Assoc [
      "id", `Int id; "guid", `String guid; "method", `String method_;
      "params", params; "metadata", `Assoc [];
    ]) in
    let promise, resolver = Promise.create () in
    Hashtbl.add t.callbacks id resolver;
    Fun.protect ~finally:(fun () -> Hashtbl.remove t.callbacks id) (fun () ->
      Fiber.first
        (fun () ->
          Eio.Mutex.lock t.write_lock;
          Fun.protect ~finally:(fun () -> Eio.Mutex.unlock t.write_lock) (fun () ->
            match closed_reason t with
            | Some _ -> ()
            | None ->
              (* Interruption during a frame can corrupt the stream. Cancellation
                 while queued for the lock, or awaiting a reply, is only local. *)
              try Transport.write_message t.transport_w message with ex ->
                let bt = Printexc.get_raw_backtrace () in
                close t ("Playwright transport write failed: " ^ Printexc.to_string ex);
                if Fiber.is_cancelled () then Printexc.raise_with_backtrace ex bt);
          Promise.await promise)
        (fun () -> Error (Promise.await t.closed)))

let register_listener conn guid event_name callback =
  check_open conn;
  match Hashtbl.find_opt conn.objects guid with
  | None -> invalid_arg ("Cannot add event listener to unknown object " ^ guid)
  | Some obj ->
    conn.last_id <- conn.last_id + 1;
    let id = conn.last_id in
    let listeners = Option.value ~default:[] (Hashtbl.find_opt obj.events event_name) in
    let listener = { id; active = true; callback; tasks = [] } in
    Hashtbl.replace obj.events event_name (listeners @ [listener]);
    listener

let add_listener conn guid event_name callback =
  (register_listener conn guid event_name callback).id

let deactivate_listener listener =
  listener.active <- false;
  List.iter (fun (_, cc) -> Eio.Cancel.cancel cc Exit) listener.tasks

let remove_listener conn guid event_name id =
  match Hashtbl.find_opt conn.objects guid with
  | None -> ()
  | Some obj ->
    let listeners = Option.value ~default:[] (Hashtbl.find_opt obj.events event_name) in
    let keep listener =
      if listener.id <> id then true
      else begin
        deactivate_listener listener;
        false
      end
    in
    let remaining = List.filter keep listeners in
    if remaining = [] then Hashtbl.remove obj.events event_name
    else Hashtbl.replace obj.events event_name remaining

(* Decode and predicate both run as owned event tasks, never in the reader.
   First successful completion wins; concurrent predicate evaluations may overlap. *)
let wait_for_event conn guid event_name ~decode ?(predicate = fun _ -> true) () =
  let result, resolve = Promise.create () in
  let settled = ref false in
  let settle value =
    if not !settled then begin settled := true; Promise.resolve resolve value end
  in
  let listener = register_listener conn guid event_name (fun params ->
    try
      let value = decode params in
      if predicate value then settle (Ok value)
    with ex ->
      let bt = Printexc.get_raw_backtrace () in
      if Fiber.is_cancelled () then Printexc.raise_with_backtrace ex bt;
      settle (Error (ex, bt))) in
  Fun.protect ~finally:(fun () ->
    (* Retain the listener itself: __dispose__ may have removed its owner from
       the object table while an already-started predicate was suspended. *)
    deactivate_listener listener;
    remove_listener conn guid event_name listener.id) (fun () ->
    match Fiber.first
      (fun () -> Promise.await result)
      (fun () ->
        let reason = Promise.await conn.closed in
        Error (Closed reason, Printexc.get_callstack 10))
    with
    | Ok value -> value
    | Error (ex, bt) -> Printexc.raise_with_backtrace ex bt)

let protocol_error error =
  let open Yojson.Safe.Util in
  match member "error" error with
  | `Assoc fields ->
    (match List.assoc_opt "name" fields, List.assoc_opt "message" fields with
     | Some (`String name), Some (`String message) ->
       let stack = match List.assoc_opt "stack" fields with
         | Some (`String stack) -> stack | _ -> "" in
       Printf.sprintf "%s: %s\n%s" name message stack
     | _ -> Yojson.Safe.to_string error)
  | _ -> Yojson.Safe.to_string error

let dispatch t msg =
  if t.state = Open then begin
    let open Yojson.Safe.Util in
    match member "id" msg |> to_int_option with
    | Some id ->
      (match Hashtbl.find_opt t.callbacks id with
       | None -> ()                    (* canceled request or late response *)
       | Some resolver ->
         let error = member "error" msg in
         let result =
           if error = `Null then Ok (member "result" msg)
           else Error (protocol_error error) in
         Hashtbl.remove t.callbacks id;
         Promise.resolve resolver result)
    | None ->
      match member "method" msg |> to_string_option,
            member "guid" msg |> to_string_option with
      | Some "__create__", Some _ ->
        let params = member "params" msg in
        let guid = member "guid" params |> to_string in
        let obj = {
          guid; connection = t;
          obj_type = member "type" params |> to_string;
          parent = None;
          initializer_ = member "initializer" params;
          events = Hashtbl.create 5;
        } in
        Hashtbl.replace t.objects guid obj
      | Some "__dispose__", Some guid -> Hashtbl.remove t.objects guid
      | Some event, Some guid ->
        (match Hashtbl.find_opt t.objects guid with
         | None -> ()
         | Some obj ->
           let listeners = Option.value ~default:[] (Hashtbl.find_opt obj.events event) in
           List.iter (fun listener ->
             if listener.active && t.state = Open then
               if t.event_tasks >= t.max_event_tasks then
                 close t (Printf.sprintf
                   "Playwright event task limit (%d) exceeded at %s.%s"
                   t.max_event_tasks guid event)
               else begin
                 t.event_tasks <- t.event_tasks + 1;
                 Queue.add (guid, event, listener, member "params" msg) t.event_queue;
                 Eio.Condition.broadcast t.event_ready
               end) listeners)
      | _ -> ()
  end

let is_cancellation = function Eio.Cancel.Cancelled _ -> true | _ -> false

let report_event_error t guid event ex bt =
  let error = { guid; event; exception_ = ex; backtrace = bt } in
  if Fiber.is_cancelled () then
    (* A finalizer can raise a real error during cancellation. It must neither
       disappear nor replace the scope's original failure. A potentially
       suspending user reporter cannot safely run in this canceled context. *)
    default_event_error error
  else
    try t.on_event_error error
    with report_ex ->
      let report_bt = Printexc.get_raw_backtrace () in
      if Fiber.is_cancelled () && is_cancellation report_ex then
        Printexc.raise_with_backtrace report_ex report_bt;
      default_event_error error;
      default_event_error { guid; event = event ^ " (error reporter)";
        exception_ = report_ex; backtrace = report_bt };
      close t ("Playwright event error reporter failed: " ^ Printexc.to_string report_ex)

let run_events t =
  Switch.run (fun sw ->
    while true do
      Fiber.check ();
      while Queue.is_empty t.event_queue do
        Eio.Condition.await_no_mutex t.event_ready
      done;
      let guid, event, listener, params = Queue.take t.event_queue in
      Fiber.fork ~sw (fun () ->
        Fun.protect ~finally:(fun () -> t.event_tasks <- t.event_tasks - 1) (fun () ->
          if listener.active then
            Fiber.with_binding callback_context_key () (fun () ->
              try
                Eio.Cancel.sub (fun cc ->
                  t.last_id <- t.last_id + 1;
                  let task_id = t.last_id in
                  listener.tasks <- (task_id, cc) :: listener.tasks;
                  Fun.protect
                    ~finally:(fun () ->
                      listener.tasks <- List.filter (fun (id, _) -> id <> task_id) listener.tasks)
                    (fun () -> listener.callback params))
              with ex ->
                let bt = Printexc.get_raw_backtrace () in
                if is_cancellation ex && Fiber.is_cancelled () then
                  Printexc.raise_with_backtrace ex bt;
                (* Only expected cancellation may be ignored after removal.
                   In particular, never swallow a failing user finalizer. *)
                if listener.active || not (is_cancellation ex) then
                  report_event_error t guid event ex bt)))
    done)

let run_loop t =
  if t.running then invalid_arg "Connection.run_loop already running";
  t.running <- true;
  Fun.protect ~finally:(fun () -> t.running <- false) (fun () ->
    try
      Fiber.any [
        (fun () ->
          try
            while t.state = Open do
              match Transport.read_message t.transport_r with
              | None -> close t "Playwright transport EOF"
              | Some message -> dispatch t (Yojson.Safe.from_string message)
            done
          with ex ->
            let bt = Printexc.get_raw_backtrace () in
            close t ("Playwright transport failed: " ^ Printexc.to_string ex);
            if Fiber.is_cancelled () then Printexc.raise_with_backtrace ex bt);
        (fun () -> run_events t);
        (fun () -> ignore (Promise.await t.closed));
      ]
    with ex ->
      let bt = Printexc.get_raw_backtrace () in
      close t ("Playwright runtime stopped: " ^ Printexc.to_string ex);
      Printexc.raise_with_backtrace ex bt)
