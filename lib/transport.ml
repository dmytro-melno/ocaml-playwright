open Eio.Flow

let read_message (source : _ source) : string option =
    let open Option.Syntax in
    let length_buf = Cstruct.create 4 in
    (* Only EOF before the header is a clean end of stream. A truncated frame or
       reset is an error, reported by the connection's single close transition. *)
    let* bytes_read = try Some (Eio.Flow.single_read source length_buf) with End_of_file -> None in
    Eio.Flow.read_exact source (Cstruct.shift length_buf bytes_read);
    let length      = Cstruct.LE.get_uint32 length_buf 0 |> Int32.to_int in
    let message_buf = Cstruct.create length in
    Eio.Flow.read_exact source message_buf;
    Some (Cstruct.to_string message_buf)

let write_message (sink : _ sink) (message : string) : unit =
    let length     = String.length message in
    let length_buf = Cstruct.create 4 in
    Cstruct.LE.set_uint32 length_buf 0 (Int32.of_int length);
    let message_buf = Cstruct.of_string message in
    Eio.Flow.write sink [length_buf; message_buf]
