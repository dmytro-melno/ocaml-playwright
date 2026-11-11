(* What the tests share: one driver, one browser, one HTTP server. *)

open Eio.Std
open Playwright

type t = {
    env : Eio_unix.Stdenv.base;
    sw : Switch.t;
    pw : Playwright.t;
    browser : Browser.t;
    executable_path : string option;  (* the Chromium under test, unless it is Playwright's own *)
    server : Server.t;
    reported : (string * exn) list ref;  (* what went to the error hook during the current test *)
    scratch : string;  (* a directory for files, removed at the end *)
}

let rec rm_rf path =
    match Unix.lstat path with
    | exception Unix.Unix_error _ -> ()
    | { Unix.st_kind = S_DIR; _ } ->
        Array.iter (fun entry -> rm_rf (Filename.concat path entry)) (Sys.readdir path);
        (try Unix.rmdir path with Unix.Unix_error _ -> ())
    | _ -> (try Unix.unlink path with Unix.Unix_error _ -> ())

let read_file path = In_channel.with_open_bin path In_channel.input_all
let write_file path content = Out_channel.with_open_bin path (fun oc -> output_string oc content)

let counter = ref 0

(* A fresh path in the scratch directory. *)
let scratch_file t name =
    incr counter;
    Filename.concat t.scratch (Printf.sprintf "%d-%s" !counter name)

let sleep t seconds = Eio.Time.sleep (Eio.Stdenv.clock t.env) seconds

(* {1 Finding a browser} *)

let system_chromium () =
    List.find_opt Sys.file_exists
        [ "/usr/bin/chromium"; "/usr/bin/chromium-browser"; "/usr/bin/google-chrome"; "/usr/bin/google-chrome-stable"; "/snap/bin/chromium";
          "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"; "/Applications/Chromium.app/Contents/MacOS/Chromium" ]

(* [Some None] stands for the browser that Playwright installed. *)
let find_chromium pw =
    match Sys.getenv_opt "PLAYWRIGHT_TEST_CHROMIUM" with
    | Some path when path <> "" -> Some (Some path)
    | _ -> if Sys.file_exists (BrowserType.executable_path (chromium pw)) then Some None else Option.map Option.some (system_chromium ())

let required = match Sys.getenv_opt "PLAYWRIGHT_TEST_REQUIRED" with Some ("1" | "true") -> true | _ -> false

(* Reports why the tests cannot run; that is a failure only where they have been asked for. *)
let skip reason =
    Printf.printf "Skipping the browser tests: %s\n%!" reason;
    if required then exit 1 else exit 0

let run f =
    Eio_main.run @@ fun env ->
    Switch.run @@ fun sw ->
    let reported = ref [] in
    let pw =
        try Playwright.create ~sw ~env ~on_error:(fun what ex -> reported := (what, ex) :: !reported) ()
        with Playwright.Error error -> skip (Playwright.Error.to_string error)
    in
    let executable_path = match find_chromium pw with Some path -> path | None -> skip "no Chromium found; set PLAYWRIGHT_TEST_CHROMIUM" in
    let browser =
        try BrowserType.launch ?executable_path (chromium pw)
        with Playwright.Error error when not required -> skip (Playwright.Error.to_string error)
    in
    let scratch = Filename.temp_dir "playwright-test" "" in
    Fun.protect
        ~finally:(fun () -> rm_rf scratch)
        (fun () ->
            f { env; sw; pw; browser; executable_path; server = Server.start ~sw ~net:(Eio.Stdenv.net env); reported; scratch };
            Playwright.close pw)

(* {1 Test cases} *)

(* Nothing may reach the error hook unnoticed: a test that expects it to be called takes the
   reports with {!take_reports}. *)
let take_reports t =
    let reports = List.rev !(t.reported) in
    t.reported := [];
    reports

let check_no_reports t =
    match take_reports t with
    | [] -> ()
    | reports ->
        Alcotest.failf "unexpected errors in the background:\n%s"
            (String.concat "\n" (List.map (fun (what, ex) -> Printf.sprintf "- %s: %s" what (Printexc.to_string ex)) reports))

let case t name f =
    Alcotest.test_case name `Quick (fun () ->
        t.reported := [];
        f ();
        check_no_reports t)

(* A test with a page in a context of its own. *)
let page_case t name ?new_context f =
    case t name (fun () ->
        let context = match new_context with Some make -> make t.browser | None -> Browser.new_context t.browser in
        Fun.protect ~finally:(fun () -> BrowserContext.close context) (fun () -> f (BrowserContext.new_page context)))

(* {1 Assertions} *)

let error_kind =
    Alcotest.testable
        (fun ppf (kind : Error.kind) ->
            Format.pp_print_string ppf
                (match kind with Timeout -> "Timeout" | Target_closed -> "Target_closed" | Assertion_failed -> "Assertion_failed" | Other -> "Other"))
        ( = )

let js = Alcotest.testable Js.pp ( = )
let json = Alcotest.testable (fun ppf value -> Format.pp_print_string ppf (Yojson.Safe.to_string value)) Yojson.Safe.equal

let contains ~sub s =
    let n = String.length sub in
    let rec go i = i + n <= String.length s && (String.sub s i n = sub || go (i + 1)) in
    go 0

let check_contains what ~sub s = if not (contains ~sub s) then Alcotest.failf "%s: %S does not contain %S" what s sub

(* Playwright objects have identity; polymorphic equality is not for them. *)
let same_option a b = match a, b with Some a, Some b -> a == b | None, None -> true | _ -> false
let same_list a b = List.length a = List.length b && List.for_all2 ( == ) a b

(* A local port on which nothing listens. *)
let closed_port t =
    Eio.Switch.run @@ fun sw ->
    let socket = Eio.Net.listen ~sw ~backlog:1 (Eio.Stdenv.net t.env) (`Tcp (Eio.Net.Ipaddr.V4.loopback, 0)) in
    match Eio.Net.listening_addr socket with `Tcp (_, port) -> port | _ -> failwith "not a TCP socket"

(* The Playwright error that [f] raises. *)
let failure what f =
    match f () with
    | _ -> Alcotest.failf "%s: expected a Playwright error" what
    | exception Playwright.Error error -> error

let check_failure what ?kind ?message f =
    let error = failure what f in
    Option.iter (fun kind -> Alcotest.check error_kind (what ^ ": kind") kind error.kind) kind;
    Option.iter (fun sub -> check_contains (what ^ ": message") ~sub error.message) message

let eval_string expression page = Page.evaluate expression page |> Js.to_string
let eval_int expression page = Page.evaluate expression page |> Js.to_int
let eval_bool expression page = Page.evaluate expression page |> Js.to_bool
