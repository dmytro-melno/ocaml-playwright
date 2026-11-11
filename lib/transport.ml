(* Message transport to the Playwright driver: each message is a JSON document preceded by its
   byte length as a 32-bit little-endian integer.

   A message is copied once on its way in, from the buffer it was read into to the string that
   is parsed, and once on its way out.  Reading into the string and writing from it would save
   those copies, but they are not what a message costs: measured, a copy takes between 2 % (a
   call, a screenshot) and 10 % (a file of several megabytes) of the time that parsing or
   printing the same message takes. *)

type t = {
    send : Json.t -> unit;  (* Sends one message. Must not be called concurrently. *)
    receive : unit -> Json.t option;  (* [None] once the peer has closed the stream between messages. *)
}

exception Violation of string

let max_message_size = 1 lsl 30
let buffer_size = 1 lsl 16

(* Frames messages over a byte stream.  [read] fills part of a buffer and returns how much, raising
   [End_of_file] at the end of the stream; [write] sends all the buffers. *)
let of_stream ~(read : Cstruct.t -> int) ~(write : Cstruct.t list -> unit) =
    let buffer = Cstruct.create buffer_size in
    let pos = ref 0 in
    let len = ref 0 in
    let refill () =
        pos := 0;
        len := 0;
        len := read buffer
    in
    (* Small reads are served from [buffer]; a large message body is read straight into its
       destination instead of being copied through it. *)
    let rec fill dst off =
        let wanted = Cstruct.length dst - off in
        if wanted > 0 then
            if !len > 0 then begin
                let n = min !len wanted in
                Cstruct.blit buffer !pos dst off n;
                pos := !pos + n;
                len := !len - n;
                fill dst (off + n)
            end
            else if wanted >= buffer_size then fill dst (off + read (Cstruct.shift dst off))
            else begin
                refill ();
                fill dst off
            end
    in
    let take n =
        if n <= !len then begin
            let s = Cstruct.to_string ~off:!pos ~len:n buffer in
            pos := !pos + n;
            len := !len - n;
            s
        end
        else begin
            let dst = Cstruct.create_unsafe n in
            fill dst 0;
            Cstruct.to_string dst
        end
    in
    let header = Cstruct.create 4 in
    let receive () =
        match if !len = 0 then refill () with
        | exception End_of_file -> None
        | () ->
            (try
                fill header 0;
                let size = Int32.to_int (Cstruct.LE.get_uint32 header 0) land 0xFFFF_FFFF in
                if size > max_message_size then raise (Violation (Printf.sprintf "message of %d bytes exceeds the limit" size));
                Some (take size)
            with End_of_file -> raise (Violation "stream ended inside a message"))
            |> Option.map (fun text -> try Json.of_string text with Json.Decode_error reason -> raise (Violation ("malformed message: " ^ reason)))
    in
    let send message =
        let message = Json.to_string message in
        let size = String.length message in
        if size > max_message_size then invalid_arg "Playwright: message exceeds the transport limit";
        let header = Cstruct.create 4 in
        Cstruct.LE.set_uint32 header 0 (Int32.of_int size);
        write [ header; Cstruct.of_string message ]
    in
    { send; receive }

let of_flows (source : _ Eio.Flow.source) (sink : _ Eio.Flow.sink) = of_stream ~read:(Eio.Flow.single_read source) ~write:(Eio.Flow.write sink)
