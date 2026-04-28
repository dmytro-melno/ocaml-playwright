
let fix_file path =
  let ic = open_in path in
  let content = really_input_string ic (in_channel_length ic) in
  close_in ic;
  
  let content = Str.global_replace (Str.regexp " root ()") " root" content in
  let content = Str.global_replace (Str.regexp " chromium ()") " chromium" content in
  let content = Str.global_replace (Str.regexp " browser ()") " browser" content in
  let content = Str.global_replace (Str.regexp " ctx ()") " ctx" content in
  let content = Str.global_replace (Str.regexp " page ()") " page" content in
  let content = Str.global_replace (Str.regexp " main_frame ()") " main_frame" content in
  
  let oc = open_out path in
  output_string oc content;
  close_out oc

let () =
  fix_file "test/test_hl.ml";
  fix_file "test/test_events.ml";
  fix_file "test/test_screenshot.ml";
  fix_file "test/test_hl2.ml"
