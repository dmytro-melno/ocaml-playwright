(* A small HTTP server for the pages that the tests visit. *)

open Eio.Std

type request = {
    method_ : string;
    path : string;
    query : string;
    headers : (string * string) list;  (* names in lower case *)
    body : string;
}

type response = {
    status : int;
    headers : (string * string) list;
    body : string;
    complete : bool;  (* [false] for a response that promises more than [body] and never sends it *)
}

type t = {
    port : int;
    mutable routes : (string * (request -> response)) list;
    mutable requests : request list;  (* most recent first *)
}

let respond ?(status = 200) ?(headers = []) ?(content_type = "text/plain") ?(complete = true) body =
    { status; headers = ("content-type", content_type) :: headers; body; complete }

let html ?status ?headers body = respond ?status ?headers ~content_type:"text/html; charset=utf-8" body
let json ?status ?headers value = respond ?status ?headers ~content_type:"application/json" (Yojson.Safe.to_string value)
let redirect ?(status = 302) location = respond ~status ~headers:[ "location", location ] ""

let reason = function
    | 200 -> "OK"
    | 204 -> "No Content"
    | 301 -> "Moved Permanently"
    | 302 -> "Found"
    | 401 -> "Unauthorized"
    | 404 -> "Not Found"
    | 500 -> "Internal Server Error"
    | _ -> "Status"

let serve t flow =
    let reader = Eio.Buf_read.of_flow flow ~max_size:(64 * 1024 * 1024) in
    let rec headers acc =
        match Eio.Buf_read.line reader with
        | "" -> List.rev acc
        | line ->
            (match String.index_opt line ':' with
            | Some i -> headers ((String.lowercase_ascii (String.sub line 0 i), String.trim (String.sub line (i + 1) (String.length line - i - 1))) :: acc)
            | None -> headers acc)
    in
    let rec loop () =
        match Eio.Buf_read.line reader with
        | exception End_of_file -> ()
        | request_line ->
            let method_, target = match String.split_on_char ' ' request_line with m :: target :: _ -> m, target | _ -> failwith "malformed request line" in
            let headers = headers [] in
            let body = Eio.Buf_read.take (match List.assoc_opt "content-length" headers with Some n -> int_of_string n | None -> 0) reader in
            let path, query =
                match String.index_opt target '?' with
                | Some i -> String.sub target 0 i, String.sub target (i + 1) (String.length target - i - 1)
                | None -> target, ""
            in
            let request = { method_; path; query; headers; body } in
            t.requests <- request :: t.requests;
            let response =
                match List.assoc_opt path t.routes with
                | Some handler -> (try handler request with Failure message -> respond ~status:500 message)
                (* Browsers ask for it when they feel like it, and log what they get for an answer. *)
                | None when path = "/favicon.ico" -> respond ~status:204 ""
                | None -> respond ~status:404 ("No route for " ^ path)
            in
            let head =
                Printf.sprintf "HTTP/1.1 %d %s\r\n%scontent-length: %d\r\n\r\n" response.status (reason response.status)
                    (String.concat "" (List.map (fun (name, value) -> Printf.sprintf "%s: %s\r\n" name value) response.headers))
                    (String.length response.body + if response.complete then 0 else 1)
            in
            Eio.Flow.copy_string (head ^ if method_ = "HEAD" then "" else response.body) flow;
            if response.complete then loop () else Fiber.await_cancel ()
    in
    try loop () with End_of_file | Eio.Io _ -> ()

let start ~sw ~net =
    let socket = Eio.Net.listen ~sw ~reuse_addr:true ~backlog:128 net (`Tcp (Eio.Net.Ipaddr.V4.loopback, 0)) in
    let port = match Eio.Net.listening_addr socket with `Tcp (_, port) -> port | _ -> failwith "not a TCP socket" in
    let t = { port; routes = []; requests = [] } in
    Fiber.fork_daemon ~sw (fun () -> Eio.Net.run_server socket ~on_error:(fun _ -> ()) (fun flow _ -> serve t flow));
    t

let origin t = Printf.sprintf "http://127.0.0.1:%d" t.port
let url t path = origin t ^ path

(* Registers the handler of a path, replacing an earlier one. *)
let route t path handler = t.routes <- (path, handler) :: List.remove_assoc path t.routes

let page t path body = route t path (fun _ -> html body)

(* The requests received for a path, oldest first. *)
let requests_for t path = List.rev (List.filter (fun (request : request) -> request.path = path) t.requests)
