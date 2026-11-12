open Playwright_internal

(* {1 URL globs}

   The library does not read globs.  The driver makes a regular expression of one, and [Re]
   runs it ({!Url_match}).  What is checked here is that pair: that the expressions of the
   driver are of the kind that [Re] reads, and mean to it what they mean to JavaScript. *)

(* The base URL, the glob, a URL, and whether the glob matches it: the examples of Playwright's
   own tests (tests/page/interception.spec.ts), and then some of ours. *)
let examples =
    [ None, "**/*.js", "https://localhost:8080/foo.js", true;
      None, "**/*.css", "https://localhost:8080/foo.js", false;
      None, "*.js", "https://localhost:8080/foo.js", false;
      None, "https://**/*.js", "https://localhost:8080/foo.js", true;
      None, "http://localhost:8080/simple/path.js", "http://localhost:8080/simple/path.js", true;
      None, "**/{a,b}.js", "https://localhost:8080/a.js", true;
      None, "**/{a,b}.js", "https://localhost:8080/b.js", true;
      None, "**/{a,b}.js", "https://localhost:8080/c.js", false;
      None, "**/*.{png,jpg,jpeg}", "https://localhost:8080/c.jpg", true;
      None, "**/*.{png,jpg,jpeg}", "https://localhost:8080/c.jpeg", true;
      None, "**/*.{png,jpg,jpeg}", "https://localhost:8080/c.png", true;
      None, "**/*.{png,jpg,jpeg}", "https://localhost:8080/c.css", false;
      None, "foo*", "foo.js", true;
      None, "foo*", "foo/bar.js", false;
      None, "http://localhost:3000/signin-oidc*", "http://localhost:3000/signin-oidc/foo", false;
      None, "http://localhost:3000/signin-oidc*", "http://localhost:3000/signin-oidcnice", true;
      None, "**/*.js", "/foo.js", true;
      None, "asd/**.js", "/foo.js", false;
      None, "**/*.js", "bar_foo.js", false;
      (* Brackets and question marks stand for themselves. *)
      None, "**/api/v[0-9]", "http://example.com/api/v[0-9]", true;
      None, "**/api/v[0-9]", "http://example.com/api/version", false;
      None, "**/api\\?param", "http://example.com/api?param", true;
      None, "**/api\\?param", "http://example.com/api-param", false;
      None, "**/three-columns/settings.html\\?**id=settings-**", "http://mydomain:8080/blah/blah/three-columns/settings.html?id=settings-e3c58efe-02e9-44b0-97ac-dd138100cf7c&blah", true;
      None, "http://localhost:8080/?imple/path.js", "http://localhost:8080/Simple/path.js", false;
      None, "http://playwright.?ev", "http://playwright.dev/", false;
      None, "http://playwright.?ev", "http://playwright./?ev", true;
      None, "http://playwright.dev/f??", "http://playwright.dev/foo", false;
      None, "http://playwright.dev/f??", "http://playwright.dev/f??", true;
      None, "http://playwright.dev\\?x=y", "http://playwright.dev/?x=y", true;
      None, "http://playwright.dev/\\?x=y", "http://playwright.dev/?x=y", true;
      Some "http://playwright.dev/foo", "?bar", "http://playwright.dev/foo?bar", true;
      Some "http://playwright.dev/foo", "\\\\?bar", "http://playwright.dev/foo?bar", true;
      (* A glob is a URL, and is resolved and normalised as one. *)
      None, "http://playwright.dev", "http://playwright.dev/", true;
      None, "http://playwright.dev?a=b", "http://playwright.dev/?a=b", true;
      None, "h*://playwright.dev", "http://playwright.dev/", true;
      None, "http://*.playwright.dev?x=y", "http://api.playwright.dev/?x=y", true;
      None, "**/foo/**", "http://playwright.dev/foo/bar", true;
      Some "http://playwright.dev", "?x=y", "http://playwright.dev/?x=y", true;
      Some "http://playwright.dev/foo/", "./bar?x=y", "http://playwright.dev/foo/bar?x=y", true;
      None, "http://playwright.dev/foo$$bar", "http://playwright.dev/foo$$bar", true;
      None, "http://playwright.dev/a$&b", "http://playwright.dev/a$&b", true;
      Some "http://playwright.dev", "./p$$q", "http://playwright.dev/p$$q", true;
      None, "HtTpS://pLaYwRiGhT.dEv/fooBAR", "https://playwright.dev/fooBAR", true;
      Some "http://ignored", "HtTpS://pLaYwRiGhT.dEv/fooBAR", "https://playwright.dev/fooBAR", true;
      None, "https://playwright.dev/fooBAR", "https://playwright.dev/foobar", false;
      None, "https://playwright.dev/foobar?A=B", "https://playwright.dev/foobar?a=b", false;
      None, "http://example.com:80/path", "http://example.com/path", true;
      None, "https://example.com:443/path", "https://example.com/path", true;
      None, "http://example.com:8080/path", "http://example.com:8080/path", true;
      None, "http://localhost:80/**", "http://localhost/", true;
      None, "http://example.com/foo bar", "http://example.com/foo%20bar", true;
      None, "http://m\xc3\xbcnchen.de/", "http://xn--mnchen-3ya.de/", true;
      None, "http://B\xc3\x9cCHER.example/*", "http://xn--bcher-kva.example/list", true;
      None, "http://example\xe3\x80\x82com/*", "http://example.com/list", true;
      None, "**/?a=b", "https://localhost:3000/?a=b", true;
      None, "**?a=b", "https://localhost:3000/?a=b", true;
      None, "**=b", "https://localhost:3000/?a=b", true;
      None, "my.custom.protocol://**", "my.custom.protocol://foo", true;
      None, "my.{p,y}://**", "my.p://foo", false;
      None, "my.{p,y}://**", "my.p://foo/", true;
      None, "f*e://**", "file:///foo/", true;
      Some "http://first.host/", "**/foo", "http://second.host/foo", true;
      Some "http://playwright.dev/", "*//localhost/", "http://localhost/", true;
      None, "https://foo/**/bar.js", "https://foo/bar.js", true;
      None, "https://foo/**/**/bar.js", "https://foo/bar.js", true;
      (* Some schemes are not relative to anything. *)
      Some "http://playwright.dev/", "about:blank", "about:blank", true;
      Some "http://playwright.dev/", "http://playwright.dev/", "about:blank", false;
      None, "data:*", "data:blank", true;
      None, "about:*", "notabout:blank", false;
      (* Characters outside ASCII are matched as they are, a byte at a time. *)
      None, "**/\xd0\xbf\xd1\x83\xd1\x82\xd1\x8c/*", "http://example.com/\xd0\xbf\xd1\x83\xd1\x82\xd1\x8c/\xd1\x84\xd0\xb0\xd0\xb9\xd0\xbb", true;
      None, "**/\xd0\xbf\xd1\x83\xd1\x82\xd1\x8c/*", "http://example.com/\xd0\xbf\xd1\x83\xd1\x82\xd0\xb8/\xd1\x84\xd0\xb0\xd0\xb9\xd0\xbb", false;
      (* The empty glob is no condition at all. *)
      Some "http://playwright.dev/", "", "http://example.com/anything", true ]

(* The same for the URLs of WebSockets, where the base URL of a page stands for its WebSocket
   counterpart. *)
let web_socket_examples =
    [ Some "http://localhost:3000", "/ws", "ws://localhost:3000/ws", true;
      Some "https://example.com/app/", "socket", "wss://example.com/app/socket", true;
      Some "http://localhost:3000", "/ws", "http://localhost:3000/ws", false;
      None, "ws://localhost:3000/**", "ws://localhost:3000/a/b", true ]

let show_base = Option.fold ~none:"no base URL" ~some:(Printf.sprintf "base URL %S")

let test_examples session () =
    let check ~web_socket (base_url, glob, url, expected) =
        let matches = Url_match.of_glob session ?base_url ~web_socket glob in
        Alcotest.(check bool) (Printf.sprintf "glob %S, %s, URL %S" glob (show_base base_url) url) expected (matches url)
    in
    List.iter (check ~web_socket:false) examples;
    List.iter (check ~web_socket:true) web_socket_examples

(* Globs of every shape, with every kind of base URL: whatever the driver makes of them, [Re]
   must be able to read it, unless the driver has refused the glob itself. *)
let test_vocabulary session () =
    let bases = [ None; Some "http://localhost:3000"; Some "http://localhost:3000/app/index.html?x=1#top"; Some "HTTPS://Example.COM:443/a/b/"; Some "about:blank"; Some "not a url" ] in
    let globs =
        [ "*"; "**"; "**/*"; "\\?"; "\\"; "\\\\"; "\\["; "[a-z]"; "$^+.\\*()|\\?\\{\\}\\[\\]"; "a,b"; "{a,b"; "a}"; "{a,{b,c}}"; "{a,b}},c"; "../bar"; "../../bar/*.png"; "/abs/**"; "//other.test/x/*"; "#frag";
          "http://example.com/foo bar"; "http://user:pass@example.com/*"; "http://[::1]:8080/*"; "http://127.1/*"; "https://example.com/a/../b/./c/*"; "https://example.com/%7Euser/*";
          "x/{y,z}/*?q={1,2}"; "http://example.com/x\\?a=1&b=*"; "a\\*b"; "a\\{b\\}"; "www.*.com"; "path with space/*"; "http://example.com/a\nb"; "\xff\xfe"; "ws://localhost:3000/socket"; "wss://**" ]
    in
    let refused = ref 0 in
    let read ?base_url ~web_socket glob =
        match Url_match.of_glob session ?base_url ~web_socket glob with
        | matches -> ignore (matches "http://localhost:3000/app/index.html")
        | exception Error.E { message; _ } when String.starts_with ~prefix:"Invalid glob pattern" message -> incr refused
        | exception Error.E error -> Alcotest.failf "glob %S, %s: %s" glob (show_base base_url) (Error.to_string error)
    in
    List.iter (fun base_url -> List.iter (fun glob -> List.iter (fun web_socket -> read ?base_url ~web_socket glob) [ false; true ]) globs) bases;
    Alcotest.(check bool) "the driver refuses the globs with unbalanced braces" true (!refused > 0)

(* A matcher that backtracks does not come back from this one within the life of the test. *)
let test_linear_time session () =
    let matches = Url_match.of_glob session "**/*a*a*a*a*a*a*a*a*a*a*a*ab" in
    Alcotest.(check bool) "no match" false (matches ("http://example.test/" ^ String.make 40 'a'));
    Alcotest.(check bool) "a match" true (matches ("http://example.test/" ^ String.make 40 'a' ^ "b"))

let required = match Sys.getenv_opt "PLAYWRIGHT_TEST_REQUIRED" with Some ("1" | "true") -> true | _ -> false

let () =
    Eio_main.run @@ fun env ->
    Eio.Switch.run @@ fun sw ->
    match Instance.create ~sw ~env () with
    | exception Error.E error ->
        Printf.printf "Skipping the driver tests: %s\n%!" (Error.to_string error);
        if required then exit 1
    | playwright ->
        let session = playwright.session in
        Fun.protect
            ~finally:(fun () -> Instance.close playwright)
            (fun () ->
                Alcotest.run ~and_exit:false "playwright (driver)"
                    [ "URL globs",
                      [ Alcotest.test_case "examples" `Quick (test_examples session);
                        Alcotest.test_case "every expression can be read" `Quick (test_vocabulary session);
                        Alcotest.test_case "time is linear" `Quick (test_linear_time session) ] ])
