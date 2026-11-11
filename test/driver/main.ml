open Playwright_internal

(* {1 URL globs}

   The driver matches the URLs of requests against the globs of routes, and so does the client,
   to find the handler; a difference between the two would leave requests unhandled.  The driver
   can be asked for the regular expression that it makes of a glob ([LocalUtils.globToRegex]),
   which must be the one that {!Glob} makes. *)

let bases = [ None; Some "http://localhost:3000"; Some "http://localhost:3000/app/index.html?x=1#top"; Some "HTTPS://Example.COM:443/a/b/"; Some "http://playwright.dev/foo"; Some "about:blank"; Some "not a url" ]

let globs =
    [ ""; "*"; "**"; "**/*"; "**/*.js"; "*.js"; "**/*.{png,jpg,jpeg}"; "**/{a,b}.js"; "**/api/v[0-9]"; "**/api\\?param"; "**/three-columns/settings.html\\?**id=settings-**";
      "foo*"; "asd/**.js"; "\\?"; "\\"; "\\\\"; "\\["; "[a-z]"; "$^+.\\*()|\\?\\{\\}\\[\\]"; "a,b"; "{a,b"; "a}"; "{a,{b,c}}";
      "http://playwright.dev"; "http://playwright.dev?a=b"; "h*://playwright.dev"; "http://*.playwright.dev?x=y"; "**/foo/**"; "?x=y"; "./bar?x=y"; "../bar"; "../../bar/*.png"; "/abs/**";
      "bar"; "bar/*"; "//other.test/x/*"; "#frag"; "http://playwright.dev/foo$$bar"; "http://playwright.dev/a$&b"; "./p$$q"; "HtTpS://pLaYwRiGhT.dEv/fooBAR"; "http://example.com:80/path";
      "https://example.com:443/path"; "http://example.com:8080/path"; "http://localhost:80/**"; "http://example.com/foo bar"; "http://m\xc3\xbcnchen.de/"; "**/?a=b"; "**?a=b"; "**=b";
      "my.custom.protocol://**"; "my.{p,y}://**"; "f*e://**"; "http://localhost:8080/?imple/path.js"; "http://playwright.?ev"; "http://playwright.dev/f??"; "http://playwright.dev\\?x=y";
      "http://playwright.dev/\\?x=y"; "\\\\?bar"; "*//localhost/"; "https://foo/**/bar.js"; "https://foo/**/**/bar.js"; "about:blank"; "about:*"; "data:text/html,*"; "chrome:*"; "edge:blank";
      "file:///tmp/*.html"; "file:*"; "ws://localhost:3000/socket"; "wss://**"; "/socket/*"; "socket"; "http://LOCALHOST:3000/{A,B}/C"; "http://{a,b}.Example.com/X"; "http://*.EXAMPLE.com/Path";
      "https://example.com/a/../b/./c/*"; "https://example.com/%7Euser/*"; "https://example.com/a%20b/**"; "http://[::1]:8080/*"; "http://127.1/*"; "http://user:pass@example.com/*";
      "example.com/*"; "www.*.com"; "a\\*b"; "a\\{b\\}"; "x/{y,z}/*?q={1,2}"; "http://example.com/x?*"; "http://example.com/x\\?a=1&b=*"; "path with space/*"; "http://example.com/\xd0\xbf\xd1\x83\xd1\x82\xd1\x8c/*" ]

let ours ?base_url ~web_socket glob = match Glob.to_regex_pattern (Glob.resolve ?base_url ~web_socket glob) with pattern -> Ok pattern | exception Invalid_argument _ -> Error ()

let theirs ?base_url ~web_socket glob utils =
    match Protocol.Local_utils.glob_to_regex ~glob ?base_url ~web_socket_url:web_socket utils with pattern -> Ok pattern | exception Error.E _ -> Error ()

let test_globs utils () =
    let show = function Ok pattern -> pattern | Error () -> "(invalid glob)" in
    let differences =
        List.concat_map
            (fun base_url ->
                List.concat_map
                    (fun glob ->
                        List.filter_map
                            (fun web_socket ->
                                let ours = ours ?base_url ~web_socket glob and theirs = theirs ?base_url ~web_socket glob utils in
                                if ours = theirs then None
                                else
                                    Some
                                        (Printf.sprintf "glob %S, base %s%s:\n    driver: %s\n    client: %s" glob
                                             (Option.fold ~none:"none" ~some:(Printf.sprintf "%S") base_url)
                                             (if web_socket then ", for a WebSocket" else "")
                                             (show theirs) (show ours)))
                            [ false; true ])
                    globs)
            bases
    in
    if differences <> [] then Alcotest.failf "%d globs are read differently:\n%s" (List.length differences) (String.concat "\n" differences)

let required = match Sys.getenv_opt "PLAYWRIGHT_TEST_REQUIRED" with Some ("1" | "true") -> true | _ -> false

let () =
    Eio_main.run @@ fun env ->
    Eio.Switch.run @@ fun sw ->
    match Instance.create ~sw ~env () with
    | exception Error.E error ->
        Printf.printf "Skipping the driver tests: %s\n%!" (Error.to_string error);
        if required then exit 1
    | playwright ->
        let utils = Local_utils.of_session playwright.session in
        Fun.protect
            ~finally:(fun () -> Instance.close playwright)
            (fun () -> Alcotest.run ~and_exit:false "playwright (driver)" [ "ported", [ Alcotest.test_case "URL globs" `Quick (test_globs utils) ] ])
