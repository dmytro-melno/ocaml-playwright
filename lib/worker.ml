open Eio.Std
open Types

type t = worker

let equal (a : t) (b : t) = Channel.equal a.w_channel b.w_channel
let compare (a : t) (b : t) = Channel.compare a.w_channel b.w_channel
let hash (t : t) = Channel.hash t.w_channel

type _ event =
    | Close : worker event
    | Console : console_message event

let emitter : type a. t -> a event -> a Emitter.t =
    fun worker -> function
    | Close -> worker.we_close
    | Console -> worker.we_console

let event_name : type a. a event -> string = function Close -> "close" | Console -> "console"

let close_error (worker : t) =
    match worker.w_page with
    | Some page -> Frame.page_close_error page
    | None -> Error.target_closed ()

(* The worker is gone: it ended, or its page or the connection to it went away. *)
let did_close (worker : t) =
    if not (Promise.is_resolved worker.w_gone) then begin
        Ownership.remove_worker worker;
        Promise.resolve worker.w_gone_resolver (close_error worker);
        ignore (Emitter.emit worker.w_session.conn worker.we_close worker)
    end

let handle_event (worker : t) : Protocol.Worker.event -> unit = function
    | Console { type_; text; args; location; timestamp } ->
        (* Only workers attached to directly report their console here; others go through the context. *)
        let message =
            { cm_serial = Serial.next (); cm_type = type_; cm_text = text; cm_args = List.map Types.js_handle args; cm_location = location; cm_timestamp = timestamp;
              cm_page = None; cm_worker = Some worker }
        in
        ignore (Emitter.emit worker.w_session.conn worker.we_console message)
    | Close -> did_close worker

let create session (channel : Protocol.Worker.t) : t =
    let init = Protocol.Worker.initializer_ channel in
    let w_gone, w_gone_resolver = Promise.create () in
    let worker =
        { w_channel = channel; w_session = session; w_url = init.url; w_page = None; w_context = None; w_gone; w_gone_resolver;
          we_close = Emitter.create (); we_console = Emitter.create () }
    in
    Events.subscribe_on_demand session.conn worker.we_console (fun ~enabled -> Protocol.Worker.update_subscription ~event:`Console ~enabled channel);
    Protocol.Worker.listen channel (handle_event worker);
    Channel.on_lost channel (fun _ -> did_close worker);
    worker

let url (worker : t) = worker.w_url

let evaluate ?(arg = Js.Undefined) expression (worker : t) =
    Protocol.Worker.evaluate_expression ~expression ~arg:(Js.to_argument arg) worker.w_channel |> Js.of_wire

let evaluate_handle ?(arg = Js.Undefined) expression (worker : t) =
    Protocol.Worker.evaluate_expression_handle ~expression ~arg:(Js.to_argument arg) worker.w_channel |> Types.js_handle

let on event listener (worker : t) = Disposable.listener (Emitter.on (emitter worker event) listener)
let once event listener (worker : t) = Disposable.listener (Emitter.once (emitter worker event) listener)

let timeouts (worker : t) =
    match worker.w_page, worker.w_context with
    | Some page, _ -> page.p_timeouts
    | None, Some context -> context.c_timeouts
    | None, None -> Timeouts.create ()

let expect_event (type a) ?timeout ?predicate (event : a event) action (worker : t) : a =
    let timeout = Timeouts.action ?timeout (timeouts worker) in
    let rejections waiter =
        match event with
        | Close -> ()
        | Console -> Waiter.reject_on waiter worker.we_close (fun _ -> Some (close_error worker))
    in
    Events.expect worker.w_session.conn ~timeout ~name:(event_name event) ?predicate ~rejections (emitter worker event) action

let wait_for_event ?timeout ?predicate event worker = expect_event ?timeout ?predicate event ignore worker
