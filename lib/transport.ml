
open Eio.Flow

let read_message (source : _ source) : string option =
  let length_buf = Cstruct.create 4 in
  try
    Eio.Flow.read_exact source length_buf;
    let length = Cstruct.LE.get_uint32 length_buf 0 |> Int32.to_int in
    let message_buf = Cstruct.create length in
    Eio.Flow.read_exact source message_buf;
    Some (Cstruct.to_string message_buf)
  with
  | End_of_file -> None
  | Eio.Io (Eio.Net.E (Eio.Net.Connection_reset _), _) -> None

let write_message (sink : _ sink) (message : string) : unit =
  let length = String.length message in
  let length_buf = Cstruct.create 4 in
  Cstruct.LE.set_uint32 length_buf 0 (Int32.of_int length);
  let message_buf = Cstruct.of_string message in
  Eio.Flow.write sink [length_buf; message_buf]
