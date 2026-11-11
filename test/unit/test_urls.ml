(* URLs and the globs that match them.

   The library must predict the address that a page reports, and must read globs as the driver
   reads them.  The expected values of the first table are those of [new URL(reference, base)]
   in Node.js; the tables of globs are those of Playwright's own tests. *)

open Internal

(* {1 URLs} *)

(* The base, the reference, and the normal form and the origin that they give. *)
let urls =
    [
      (* An absolute URL is normalised. *)
      None, "https://example.com/a?b#c", Some ("https://example.com/a?b#c", "https://example.com");
      None, "http://example.com", Some ("http://example.com/", "http://example.com");
      None, "http://example.com?x=1", Some ("http://example.com/?x=1", "http://example.com");
      None, "http://example.com#top", Some ("http://example.com/#top", "http://example.com");
      None, "HTTP://EXAMPLE.com:80/%7Efoo/%2e%2E/bar", Some ("http://example.com/bar", "http://example.com");
      None, "https://example.com:443/a/./b/../c", Some ("https://example.com/a/c", "https://example.com");
      None, "http://example.com:8080/", Some ("http://example.com:8080/", "http://example.com:8080");
      None, "ws://example.com:80/chat", Some ("ws://example.com/chat", "ws://example.com");
      None, "  http://example.com/a  ", Some ("http://example.com/a", "http://example.com");
      None, "ht\ttp://exa\nmple.com/", Some ("http://example.com/", "http://example.com");
      None, "http:\\\\example.com\\a\\..\\b", Some ("http://example.com/b", "http://example.com");
      None, "http:example.com/x", Some ("http://example.com/x", "http://example.com");
      Some "http://other.test/", "https://example.com/a?b#c", Some ("https://example.com/a?b#c", "https://example.com");
      (* A relative URL is resolved against the base. *)
      Some "http://localhost:8080/app/index.html", "/checkout", Some ("http://localhost:8080/checkout", "http://localhost:8080");
      Some "http://localhost:8080", "/checkout", Some ("http://localhost:8080/checkout", "http://localhost:8080");
      Some "http://localhost:8080/app/index.html?x=1", "cart", Some ("http://localhost:8080/app/cart", "http://localhost:8080");
      Some "http://localhost:8080/app/", "./cart", Some ("http://localhost:8080/app/cart", "http://localhost:8080");
      Some "http://localhost:8080", "cart", Some ("http://localhost:8080/cart", "http://localhost:8080");
      Some "http://localhost:8080/app?page=1#top", "?page=2", Some ("http://localhost:8080/app?page=2", "http://localhost:8080");
      Some "http://localhost:8080/app?page=1#top", "#end", Some ("http://localhost:8080/app?page=1#end", "http://localhost:8080");
      Some "http://localhost:8080/app?page=1#top", "", Some ("http://localhost:8080/app?page=1", "http://localhost:8080");
      Some "https://localhost:8080/app", "//cdn.test/x.js", Some ("https://cdn.test/x.js", "https://cdn.test");
      Some "http://example.com/a/b/", "../c", Some ("http://example.com/a/c", "http://example.com");
      Some "http://example.com/a/b/", "../../../c", Some ("http://example.com/c", "http://example.com");
      Some "http://example.com/a/b", "c/.", Some ("http://example.com/a/c/", "http://example.com");
      Some "http://example.com/a/b", "c/..", Some ("http://example.com/a/", "http://example.com");
      Some "http://example.com/a/b/", "..", Some ("http://example.com/a/", "http://example.com");
      Some "http://example.com/a/b/", "%2e%2e/y", Some ("http://example.com/a/y", "http://example.com");
      Some "http://h/a/b", "http:foo", Some ("http://h/a/foo", "http://h");
      Some "http://h/a/b", "https:foo", Some ("https://foo/", "https://foo");
      Some "foo://host/a/b", "c", Some ("foo://host/a/c", "null");
      Some "foo:/a/b", "../c", Some ("foo:/c", "null");
      (* Characters that a URL cannot hold are percent-encoded. *)
      Some "http://example.com", "/a b/ü?q=a b'#x y", Some ("http://example.com/a%20b/%C3%BC?q=a%20b%27#x%20y", "http://example.com");
      Some "foo://example.com", "/a b/ü?q=a b'#x y", Some ("foo://example.com/a%20b/%C3%BC?q=a%20b'#x%20y", "null");
      None, "http://example.com/a^b{c}|d`e\"f<g>h", Some ("http://example.com/a%5Eb%7Bc%7D|d%60e%22f%3Cg%3Eh", "http://example.com");
      None, "http://example.com/?a^b{c}|d`e\"f<g>h", Some ("http://example.com/?a^b{c}|d`e%22f%3Cg%3Eh", "http://example.com");
      None, "http://example.com/#a^b{c}|d`e\"f<g>h", Some ("http://example.com/#a^b{c}|d%60e%22f%3Cg%3Eh", "http://example.com");
      None, "http://user name:p@ss@example.com/", Some ("http://user%20name:p%40ss@example.com/", "http://example.com");
      (* Hosts are normalised. *)
      None, "http://[0:0:0:0:0:0:0:1]:8080/", Some ("http://[::1]:8080/", "http://[::1]:8080");
      None, "http://[2001:DB8::FF00:42:8329]/", Some ("http://[2001:db8::ff00:42:8329]/", "http://[2001:db8::ff00:42:8329]");
      None, "http://[::ffff:192.168.0.1]/", Some ("http://[::ffff:c0a8:1]/", "http://[::ffff:c0a8:1]");
      None, "http://[1:0:0:2:0:0:0:3]/", Some ("http://[1:0:0:2::3]/", "http://[1:0:0:2::3]");
      None, "http://127.1/", Some ("http://127.0.0.1/", "http://127.0.0.1");
      None, "http://0x7f.0.0.1/", Some ("http://127.0.0.1/", "http://127.0.0.1");
      None, "http://ex%41mple.com/", Some ("http://example.com/", "http://example.com");
      None, "http://example.com./", Some ("http://example.com./", "http://example.com.");
      None, "http://пример.рф/путь?q=ы#я", Some ("http://xn--e1afmkfd.xn--p1ai/%D0%BF%D1%83%D1%82%D1%8C?q=%D1%8B#%D1%8F", "http://xn--e1afmkfd.xn--p1ai");
      None, "http://bücher.example/", Some ("http://xn--bcher-kva.example/", "http://xn--bcher-kva.example");
      None, "http://例え.jp/", Some ("http://xn--r8jz45g.jp/", "http://xn--r8jz45g.jp");
      (* Other schemes. *)
      Some "http://example.com/", "about:blank", Some ("about:blank", "null");
      None, "data:text/html,<p>a/b</p>", Some ("data:text/html,<p>a/b</p>", "null");
      Some "about:blank", "#f", Some ("about:blank#f", "null");
      None, "mailto:a@b.c ?subject=x", Some ("mailto:a@b.c%20?subject=x", "null");
      None, "blob:https://example.com:8443/uuid", Some ("blob:https://example.com:8443/uuid", "https://example.com:8443");
      None, "foo://host/a/../b", Some ("foo://host/b", "null");
      None, "foo:/a/../b", Some ("foo:/b", "null");
      None, "foo:/.//p", Some ("foo:/.//p", "null");
      None, "foo://", Some ("foo://", "null");
      None, "file:///C:/a/../b", Some ("file:///C:/b", "null");
      None, "file:///C:/..", Some ("file:///C:/", "null");
      Some "file:///D:/a/b", "C|/x", Some ("file:///C:/x", "null");
      Some "file:///D:/a/b", "/x", Some ("file:///D:/x", "null");
      Some "file:///D:/a/b", "x", Some ("file:///D:/a/x", "null");
      None, "file://localhost/etc", Some ("file:///etc", "null");
      Some "file:///a/b", "file:x", Some ("file:///a/x", "null");
      (* What is not a URL. *)
      None, "relative", None;
      Some "about:blank", "relative", None;
      Some "not a url", "http://h/a/b", None;
      None, "http://a:b:c/", None;
      None, "http://:80/", None;
      None, "http://x@/", None;
      None, "http://ex ample.com/", None;
      None, "http://example.com:65536/", None;
      None, "http://1.2.3.4.5/", None;
      None, "http://256.0.0.1/", None;
      None, "http://[1::2::3]/", None;
      None, "http://", None;
    ]

let test_urls () =
    List.iter
        (fun (base, reference, expected) ->
            let what = Printf.sprintf "%S%s" reference (Option.fold ~none:"" ~some:(Printf.sprintf " against %S") base) in
            let actual = Option.map (fun url -> Url.to_string url, Url.origin url) (Url.parse ?base reference) in
            Alcotest.(check (option (pair string string))) what expected actual)
        urls

let test_resolve () =
    Alcotest.(check string) "the normal form" "http://localhost:8080/c" (Url.resolve ~base:"http://localhost:8080/a/b" "../c");
    Alcotest.(check string) "what is not a URL is left alone" "/checkout" (Url.resolve "/checkout");
    Alcotest.(check string) "also with a base that is not one" "../c" (Url.resolve ~base:"nowhere" "../c")

(* {1 Globs} *)

let test_glob_patterns () =
    let check glob expected = Alcotest.(check string) (Printf.sprintf "%S" glob) expected (Glob.to_regex_pattern glob) in
    check {|**/*.js|} {|^(.*/)([^/]*)\.js$|};
    check {|https://foo/**/bar.js|} {|^https://foo/((.+/)|)bar\.js$|};
    check {|**/*.{png,jpg}|} {|^(.*/)([^/]*)\.(png|jpg)$|};
    check {|a,b|} {|^a\,b$|};
    check {|\?|} {|^\?$|};
    check {|\|} {|^\\$|};
    check {|\\|} {|^\\$|};
    check {|\[|} {|^\[$|};
    check {|[a-z]|} {|^\[a-z\]$|};
    check {|$^+.\*()|\?\{\}\[\]|} {|^\$\^\+\.\*\(\)\|\?\{\}\[\]$|};
    List.iter
        (fun glob ->
            match Glob.to_regex_pattern glob with
            | _ -> Alcotest.failf "the glob %S must be refused" glob
            | exception Invalid_argument message -> check_contains "the message names the glob" ~sub:(Printf.sprintf "%S" glob) message)
        [ "{a,b"; "a}"; "{a,{b,c}}" ]

(* A glob as it is written, with nothing to resolve it against. *)
let test_glob_syntax () =
    let check glob url expected =
        Alcotest.(check bool) (Printf.sprintf "%S against %S" glob url) expected (Url_regex.matches (Url_regex.parse (Glob.to_regex_pattern glob)) url)
    in
    check "**/*.js" "https://localhost:8080/foo.js" true;
    check "**/*.css" "https://localhost:8080/foo.js" false;
    check "*.js" "https://localhost:8080/foo.js" false;
    check "https://**/*.js" "https://localhost:8080/foo.js" true;
    check "http://localhost:8080/simple/path.js" "http://localhost:8080/simple/path.js" true;
    check "**/{a,b}.js" "https://localhost:8080/a.js" true;
    check "**/{a,b}.js" "https://localhost:8080/b.js" true;
    check "**/{a,b}.js" "https://localhost:8080/c.js" false;
    check "**/*.{png,jpg,jpeg}" "https://localhost:8080/c.jpg" true;
    check "**/*.{png,jpg,jpeg}" "https://localhost:8080/c.jpeg" true;
    check "**/*.{png,jpg,jpeg}" "https://localhost:8080/c.png" true;
    check "**/*.{png,jpg,jpeg}" "https://localhost:8080/c.css" false;
    check "foo*" "foo.js" true;
    check "foo*" "foo/bar.js" false;
    check "http://localhost:3000/signin-oidc*" "http://localhost:3000/signin-oidc/foo" false;
    check "http://localhost:3000/signin-oidc*" "http://localhost:3000/signin-oidcnice" true;
    check "**/*.js" "/foo.js" true;
    check "asd/**.js" "/foo.js" false;
    check "**/*.js" "bar_foo.js" false;
    (* Brackets are not ranges. *)
    check "**/api/v[0-9]" "http://example.com/api/v[0-9]" true;
    check "**/api/v[0-9]" "http://example.com/api/version" false;
    (* A question mark must be escaped to stand for itself. *)
    check {|**/api\?param|} "http://example.com/api?param" true;
    check {|**/api\?param|} "http://example.com/api-param" false;
    check {|**/three-columns/settings.html\?**id=settings-**|} "http://mydomain:8080/blah/blah/three-columns/settings.html?id=settings-e3c58efe-02e9-44b0-97ac-dd138100cf7c&blah" true;
    check "http://localhost:8080/?imple/path.js" "http://localhost:8080/Simple/path.js" false

(* The base URL, the URL, the glob, and whether the glob matches the URL. *)
let matches =
    [ None, "http://playwright.dev/", "http://playwright.dev", true;
      None, "http://playwright.dev/?a=b", "http://playwright.dev?a=b", true;
      None, "http://playwright.dev/", "h*://playwright.dev", true;
      None, "http://api.playwright.dev/?x=y", "http://*.playwright.dev?x=y", true;
      None, "http://playwright.dev/foo/bar", "**/foo/**", true;
      None, "anything at all", "", true;
      Some "http://playwright.dev", "http://playwright.dev/?x=y", "?x=y", true;
      Some "http://playwright.dev/foo/", "http://playwright.dev/foo/bar?x=y", "./bar?x=y", true;
      Some "http://playwright.dev/foo/", "http://playwright.dev/bar", "../bar", true;
      Some "http://playwright.dev/foo/", "http://playwright.dev/foo/bar", "../bar", false;
      (* Characters with a meaning in replacement strings are nothing special. *)
      None, "http://playwright.dev/foo$$bar", "http://playwright.dev/foo$$bar", true;
      None, "http://playwright.dev/a$&b", "http://playwright.dev/a$&b", true;
      Some "http://playwright.dev", "http://playwright.dev/p$$q", "./p$$q", true;
      (* Schemes and hosts are matched in any case, paths and queries as they are. *)
      None, "https://playwright.dev/fooBAR", "HtTpS://pLaYwRiGhT.dEv/fooBAR", true;
      Some "http://ignored", "https://playwright.dev/fooBAR", "HtTpS://pLaYwRiGhT.dEv/fooBAR", true;
      None, "http://api.playwright.dev/", "http://{API,www}.playwright.dev/", true;
      None, "https://playwright.dev/foobar", "https://playwright.dev/fooBAR", false;
      None, "https://playwright.dev/foobar?a=b", "https://playwright.dev/foobar?A=B", false;
      (* What is literal in a glob is normalised as a URL is. *)
      None, "http://example.com/path", "http://example.com:80/path", true;
      None, "https://example.com/path", "https://example.com:443/path", true;
      None, "http://example.com:8080/path", "http://example.com:8080/path", true;
      None, "http://localhost/", "http://localhost:80/**", true;
      None, "http://example.com/foo%20bar", "http://example.com/foo bar", true;
      None, "http://xn--mnchen-3ya.de/", "http://m\xc3\xbcnchen.de/", true;
      None, "https://localhost:3000/?a=b", "**/?a=b", true;
      None, "https://localhost:3000/?a=b", "**?a=b", true;
      None, "https://localhost:3000/?a=b", "**=b", true;
      (* Schemes of one's own. *)
      None, "my.custom.protocol://foo", "my.custom.protocol://**", true;
      None, "my.p://foo", "my.{p,y}://**", false;
      None, "my.p://foo/", "my.{p,y}://**", true;
      None, "file:///foo/", "f*e://**", true;
      (* A question mark starts the query; it does not stand for one character. *)
      None, "http://playwright.dev/", "http://playwright.?ev", false;
      None, "http://playwright./?ev", "http://playwright.?ev", true;
      None, "http://playwright.dev/foo", "http://playwright.dev/f??", false;
      None, "http://playwright.dev/f??", "http://playwright.dev/f??", true;
      None, "http://playwright.dev/?x=y", {|http://playwright.dev\?x=y|}, true;
      None, "http://playwright.dev/?x=y", {|http://playwright.dev/\?x=y|}, true;
      Some "http://playwright.dev/foo", "http://playwright.dev/foo?bar", "?bar", true;
      Some "http://playwright.dev/foo", "http://playwright.dev/foo?bar", {|\\?bar|}, true;
      (* A glob that starts with a star is not resolved against the base. *)
      Some "http://first.host/", "http://second.host/foo", "**/foo", true;
      Some "http://playwright.dev/", "http://localhost/", "*//localhost/", true;
      (* Between slashes, two stars also match no directory at all. *)
      None, "https://foo/bar.js", "https://foo/**/bar.js", true;
      None, "https://foo/bar.js", "https://foo/**/**/bar.js", true;
      None, "https://foo/a/b/bar.js", "https://foo/**/bar.js", true;
      (* URLs that are not relative to anything. *)
      Some "http://playwright.dev/", "about:blank", "about:blank", true;
      Some "http://playwright.dev/", "about:blank", "http://playwright.dev/", false;
      None, "data:blank", "data:*", true;
      None, "notdata:blank", "data:*", false;
      Some "http://playwright.dev/", "file:///tmp/a.html", "file:///tmp/*.html", true ]

let test_glob_matching () =
    List.iter
        (fun (base_url, url, glob, expected) ->
            let what = Printf.sprintf "%S against %S%s" glob url (Option.fold ~none:"" ~some:(Printf.sprintf " with the base %S") base_url) in
            Alcotest.(check bool) what expected (Glob.matcher ?base_url glob url))
        matches

let test_web_socket_globs () =
    let check what expected ~base_url glob url = Alcotest.(check bool) what expected (Glob.matcher ~base_url ~web_socket:true glob url) in
    check "the base of the pages serves for their sockets" true ~base_url:"http://localhost:3000/app/" "/socket/*" "ws://localhost:3000/socket/1";
    check "over TLS as well" true ~base_url:"HTTPS://localhost:3000/app/" "socket" "wss://localhost:3000/app/socket";
    check "but an HTTP URL is no socket" false ~base_url:"http://localhost:3000/app/" "/socket/*" "http://localhost:3000/socket/1";
    Alcotest.(check bool) "and a page is not matched as a socket" false (Glob.matcher ~base_url:"http://localhost:3000" "/socket" "ws://localhost:3000/socket")

(* {1 The regular expressions of globs} *)

let test_url_regex () =
    let matches source url = Url_regex.matches (Url_regex.parse source) url in
    let images = {|^((.+/)|)([^/]*)\.(png|jpg)$|} in
    Alcotest.(check bool) "a choice of extensions" true (matches images "https://example.com/static/logo.png");
    Alcotest.(check bool) "at the root" true (matches images "logo.jpg");
    Alcotest.(check bool) "other extension" false (matches images "https://example.com/static/logo.gif");
    Alcotest.(check bool) "extension must end the URL" false (matches images "https://example.com/logo.png?x=1");
    let api = {|^https://example\.com/api/([^/]*)$|} in
    Alcotest.(check bool) "one segment" true (matches api "https://example.com/api/users");
    Alcotest.(check bool) "not two segments" false (matches api "https://example.com/api/users/1");
    Alcotest.(check bool) "dot is literal" false (matches api "https://exampleXcom/api/users");
    let anything = {|^https://example\.com/(.*)$|} in
    Alcotest.(check bool) "any rest" true (matches anything "https://example.com/a/b/c?d=e#f");
    Alcotest.(check bool) "empty rest" true (matches anything "https://example.com/");
    Alcotest.(check bool) "escaped metacharacters" true (matches {|^a\?b\+c\$\(\)\[\]\{\}\|\\$|} {|a?b+c$()[]{}|\|});
    Alcotest.(check bool) "anchored at both ends" false (matches {|^b$|} "abc");
    (* Backtracking over nested repetition terminates quickly on a non-match. *)
    Alcotest.(check bool) "no blow-up" false (matches {|^((.+/)|)([^/]*)\.zip$|} (String.concat "/" (List.init 200 (fun _ -> "segment")) ^ ".tar"));
    match Url_regex.parse {|^[a-z]+\d$|} with
    | _ -> Alcotest.fail "unsupported syntax must be refused rather than misinterpreted"
    | exception Url_regex.Unsupported _ -> ()

let tests =
    [ "url",
      [ Alcotest.test_case "parsing and resolution" `Quick test_urls;
        Alcotest.test_case "resolve" `Quick test_resolve;
        Alcotest.test_case "globs as regular expressions" `Quick test_glob_patterns;
        Alcotest.test_case "glob syntax" `Quick test_glob_syntax;
        Alcotest.test_case "globs against URLs" `Quick test_glob_matching;
        Alcotest.test_case "globs for WebSockets" `Quick test_web_socket_globs;
        Alcotest.test_case "the regular expressions of globs" `Quick test_url_regex ] ]
