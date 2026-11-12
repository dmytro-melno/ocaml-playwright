# ocaml-playwright

Browser automation for OCaml, with [Playwright](https://playwright.dev) and
[Eio](https://github.com/ocaml-multicore/eio).

The library drives Chromium, Firefox and WebKit through the official Playwright driver, to
which it speaks the same protocol as the Playwright libraries for Node.js, Python, Java and
.NET. What the driver can do is therefore here: locators that wait for elements to be ready,
assertions that retry, network interception, isolated browser contexts, device emulation,
tracing.

```ocaml
open Playwright

let () =
    Eio_main.run @@ fun env ->
    Playwright.run ~env @@ fun pw ->
    let browser = BrowserType.launch (chromium pw) in
    let page = BrowserContext.new_page (Browser.new_context browser) in
    ignore (Page.goto page "https://playwright.dev");
    Page.get_by_role page `Link ~name:"Get started" |> Locator.click;
    Expect.to_be_visible (Page.get_by_role page `Heading ~name:"Installation");
    print_endline (Page.title page);
    Browser.close browser
```

This is version 0.2.0, which works with **Playwright 1.65**.

## Requirements

- OCaml 5.2 or later and dune 3.10 or later.
- **Node.js 20 or later**, as `node` on the `PATH`. Playwright's driver is a Node.js program,
  which is installed in a step of its own (see below).
- A browser: either one that Playwright installs or one that is on the machine already.
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
tool in the version that the library needs. Use it to install the driver and a browser:

```sh
ocaml-playwright install chromium     # also: firefox, webkit
ocaml-playwright install --with-deps chromium   # on Linux, with the system packages it needs
```

The command downloads the driver first if it is missing, checks it against a pinned checksum
and keeps it in the user's cache directory. The library itself never downloads anything:
`Playwright.create` fails with an error that names this command when the driver is not there.
A program that sets itself up calls `Playwright.Driver.install ()`, or
`Playwright.Driver.run [ "install"; "chromium" ]`, instead.

To use a browser that is installed already, pass `~channel:"chrome"` (or `"msedge"`), or
`~executable_path:"/usr/bin/chromium"`, to `BrowserType.launch`; `ocaml-playwright --version`
is then enough to get the driver.

## A short tour

Elements are found with locators, the way a user would describe them. Actions wait until the
element is there and ready, so there is no need for sleeps:

```ocaml
Page.get_by_label page "Email" |> Locator.fill "ada@example.com";
Page.get_by_role page `Button ~name:"Sign in" |> Locator.click;
Page.locator page "ul.results > li" |> Locator.filter ~has_text:"OCaml" |> Locator.first |> Locator.click
```

Assertions retry until they hold, and explain themselves when they give up:

```ocaml
Expect.to_have_title page "Dashboard";
Expect.to_have_text "3 items" (Page.get_by_test_id page "cart-count");
Expect.Not.to_be_visible (Page.get_by_role page `Progressbar)
```

JavaScript runs in the page and its values come back typed:

```ocaml
let width = Page.evaluate page "window.innerWidth" |> Js.to_int in
let sum = Page.evaluate page "([a, b]) => a + b" ~arg:(Js.list Js.int [ 1; 2 ]) |> Js.to_int in
Printf.printf "%d %d\n" width sum
```

Requests can be observed, changed, answered or refused:

```ocaml
Page.route page "**/api/user" (Route.fulfill ~json:(`Assoc [ "name", `String "Ada" ])) |> ignore;
Page.route page "**/*.{png,jpg}" Route.abort |> ignore;
Page.on page Page.Response (fun response -> Printf.printf "%d %s\n" (Response.status response) (Response.url response))
```

Events that an action causes are awaited around the action, so that they cannot be missed:

```ocaml
let download = Page.expect_event page Page.Download (fun () -> Page.get_by_text page "Export" |> Locator.click) in
Download.save_as download "export.csv"
```

Every call blocks its fiber only, so several pages are driven concurrently with plain Eio:

```ocaml
let title url =
    let page = BrowserContext.new_page context in
    Fun.protect ~finally:(fun () -> Page.close page) (fun () ->
        ignore (Page.goto page url);
        Page.title page)
in
Eio.Fiber.List.map title [ "https://ocaml.org"; "https://playwright.dev" ]
```

## Documentation

- [User guide](doc/guide.md): the library from first steps to tracing, with the conventions
  that map the Playwright API to OCaml.
- [API reference](lib/playwright.mli): the documented interface; `dune build @doc` renders it
  with odoc. The functions have the names of Playwright's methods, so the
  [Playwright documentation](https://playwright.dev/docs/intro) is a good companion.
- [Scope](doc/scope.md): what the library takes on and what it leaves to the program, and,
  for those who know Playwright from another language, the names that differ and the
  behaviour that does.
- [Examples](examples): small complete programs. Run one with
  `dune exec examples/quickstart.exe`.
- [Migrating from 0.1](doc/migration.md), the versions before this rewrite.
- [Changes](CHANGES.md).
- For work on the library itself: [architecture](doc/dev/architecture.md),
  [updating to a new Playwright version](doc/dev/protocol.md), [testing](doc/dev/testing.md)
  and [Windows](doc/dev/windows.md).

## Scope

The library binds Playwright's protocol; it is not a port of Playwright's client for
Node.js. To the protocol it adds what a program in OCaml needs: types, lifetimes that end,
events, errors. It leaves out the conveniences that the other clients add for their
languages: it opens no files, has one name for each operation, and installs nothing behind
the program's back.

Not bound at present: the test runner and what belongs to it (fixtures, `expect.poll`,
visual comparisons with `toHaveScreenshot`), HAR files, browsers behind a Playwright server
(`connect`), JavaScript and CSS coverage, screencasts, WebAuthn virtual authenticators,
Chromium's own tracing (`browser.startTracing`), Android and Electron.
[doc/scope.md](doc/scope.md) has the rule in full, what is left out with what takes its
place, and the ways to reach the rest.

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
