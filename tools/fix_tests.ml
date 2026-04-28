
let fix_file path =
  let ic = open_in path in
  let content = really_input_string ic (in_channel_length ic) in
  close_in ic;
  
  let content = Re.replace_string (Re.Pcre.regexp "_+") ~by:"_" res in
  let content = Re.replace_string (Re.Pcre.regexp "_+") ~by:"_" res in
  let content = Re.replace_string (Re.Pcre.regexp "_+") ~by:"_" res in
  let content = Re.replace_string (Re.Pcre.regexp "_+") ~by:"_" res in
  let content = Re.replace_string (Re.Pcre.regexp "_+") ~by:"_" res in
  let content = Re.replace_string (Re.Pcre.regexp "_+") ~by:"_" res in
  
  let oc = open_out path in
  output_string oc content;
  close_out oc

let () =
  fix_file "test/test_hl.ml";
  fix_file "test/test_events.ml";
  fix_file "test/test_screenshot.ml";
  fix_file "test/test_hl2.ml"
