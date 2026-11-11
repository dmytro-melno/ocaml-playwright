# ocaml-playwright

Browser automation for OCaml, with [Playwright](https://playwright.dev) and
[Eio](https://github.com/ocaml-multicore/eio).

The library drives Chromium, Firefox and WebKit through the official Playwright driver, to
which it speaks the same protocol as the Playwright libraries for Node.js, Python, Java and
.NET. It brings their API to OCaml: locators that wait for elements to be ready, assertions
that retry, network interception, isolated browser contexts, device emulation, tracing.

```ocaml
open Playwright

let () =
    Eio_main.run @@ fun env ->
    Playwright.run ~env @@ fun pw ->
    let browser = BrowserType.launch (chromium pw) in
    let page = Browser.new_page browser in
    ignore (Page.goto "https://playwright.dev" page);
    Page.get_by_role `Link ~name:"Get started" page |> Locator.click;
    Expect.to_be_visible (Page.get_by_role `Heading ~name:"Installation" page);
    print_endline (Page.title page);
    Browser.close browser
```

This version works with **Playwright 1.65**.

## Requirements

- OCaml 5.2 or later and dune 3.10 or later.
- **Node.js 20 or later**, as `node` on the `PATH`. Playwright's driver is a Node.js program;
  the library downloads it on first use, checks it against a pinned checksum and keeps it
  in the user's cache directory.
- A browser: either one that Playwright installs (see below) or one that is on the machine
  already.
- Linux is where the library is developed and tested. Nothing in it is specific to Linux, so
  macOS is expected to work. Windows is supported as a cross-compilation target and has been
  exercised under Wine only; see [doc/dev/windows.md](doc/dev/windows.md).

## Installation

The package is not in the opam repository yet. Pin it:

```sh
opam pin add playwright https://github.com/dmytro-melno/ocaml-playwright.git
```

and use it from dune:

```lisp
(executable
 (name my_program)
 (libraries playwright eio_main))
```

The package installs a command, `ocaml-playwright`, which is Playwright's own command line
tool in the version that the library needs. Use it to install browsers:

```sh
ocaml-playwright install chromium     # also: firefox, webkit
ocaml-playwright install --with-deps chromium   # on Linux, with the system packages it needs
```

To use a browser that is installed already, pass `~channel:"chrome"` (or `"msedge"`), or
`~executable_path:"/usr/bin/chromium"`, to `BrowserType.launch`.

## A short tour

Elements are found with locators, the way a user would describe them. Actions wait until the
element is there and ready, so there is no need for sleeps:

```ocaml
Page.get_by_label "Email" page |> Locator.fill "ada@example.com";
Page.get_by_role `Button ~name:"Sign in" page |> Locator.click;
Page.locator "ul.results > li" page |> Locator.filter ~has_text:"OCaml" |> Locator.first |> Locator.click
```

Assertions retry until they hold, and explain themselves when they give up:

```ocaml
Expect.to_have_title "Dashboard" page;
Expect.to_have_text "3 items" (Page.get_by_test_id "cart-count" page);
Expect.Not.to_be_visible (Page.get_by_role `Progressbar page)
```

JavaScript runs in the page and its values come back typed:

```ocaml
let width = Page.evaluate "window.innerWidth" page |> Js.to_int in
let sum = Page.evaluate "([a, b]) => a + b" ~arg:(Js.list Js.int [ 1; 2 ]) page |> Js.to_int in
Printf.printf "%d %d\n" width sum
```

Requests can be observed, changed, answered or refused:

```ocaml
Page.route "**/api/user" (Route.fulfill ~json:(`Assoc [ "name", `String "Ada" ])) page;
Page.route "**/*.{png,jpg}" Route.abort page;
Page.on Page.Response (fun response -> Printf.printf "%d %s\n" (Response.status response) (Response.url response)) page
```

Events that an action causes are awaited around the action, so that they cannot be missed:

```ocaml
let download = Page.expect_download (fun () -> Page.get_by_text "Export" page |> Locator.click) page in
Download.save_as "export.csv" download
```

Every call blocks its fiber only, so several pages are driven concurrently with plain Eio:

```ocaml
let title url =
    let page = Browser.new_page browser in
    Fun.protect ~finally:(fun () -> Page.close page) (fun () ->
        ignore (Page.goto url page);
        Page.title page)
in
Eio.Fiber.List.map title [ "https://ocaml.org"; "https://playwright.dev" ]
```

## Documentation

- [User guide](doc/guide.md): the library from first steps to tracing, with the conventions
  that map the Playwright API to OCaml.
- [API reference](lib/playwright.mli): the documented interface; `dune build @doc` renders it
  with odoc. Since the API follows Playwright's closely, the
  [Playwright documentation](https://playwright.dev/docs/intro) is a good companion.
- [Examples](examples): small complete programs. Run one with
  `dune exec examples/quickstart.exe`.
- [Migrating from 0.1](doc/migration.md), the versions before this rewrite.
- [Changes](CHANGES.md).
- For work on the library itself: [architecture](doc/dev/architecture.md),
  [updating to a new Playwright version](doc/dev/protocol.md), [testing](doc/dev/testing.md)
  and [Windows](doc/dev/windows.md).

## What is not covered

Most of the Playwright API is here. These parts are not, at present: JavaScript and CSS
coverage, screencasts, visual comparisons (`toHaveScreenshot`), WebAuthn virtual
authenticators, Chromium's own tracing (`browser.startTracing`), Android and Electron. The
guide lists the [differences from the Playwright API](doc/guide.md#differences-from-playwright)
in detail.

## Development

```sh
opam install . --deps-only --with-test
dune build
dune runtest
```

`dune runtest` runs the unit tests and, if Node.js and a Chromium are available, the tests
against a real browser; [doc/dev/testing.md](doc/dev/testing.md) has the details.

## License

MIT, see [LICENSE](LICENSE).
