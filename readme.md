# ocaml-playwright

OCaml bindings for [Playwright](https://playwright.dev/), generated from the Playwright protocol and built on Eio.

## Status

Experimental. The API mostly mirrors Playwright's protocol objects, with a few convenience helpers for locators and JavaScript evaluation.

## Requirements

- OCaml 5+
- dune
- Eio
- `curl`, `tar`, and Node.js 18+ for the Playwright driver
- a browser executable, or Playwright-managed browsers available on the machine

The matching **1.59.1** `playwright-core` driver is downloaded automatically from
npm on first use to `~/.cache/playwright-ocaml-driver`. The exact upstream schema
and its version/hash are checked offline during the build.

## Install

From this repository:

```sh
opam install . --deps-only
dune build
```

As a dependency:

```sh
opam pin add playwright git+https://github.com/dmytro-melno/ocaml-playwright.git
```

In `dune`:

```lisp
(executable
 (name example)
 (libraries playwright eio_main))
```

## Example

```ocaml
open Playwright

let () =
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let pw = create ~env ~sw () in
  Fun.protect ~finally:(fun () -> destroy pw) @@ fun () ->
    let chromium = Playwright.chromium pw in
    let browser =
      BrowserType.launch
        ~executable_path:"/usr/bin/chromium"
        ~headless:true
        chromium
    in
    let context = Browser.new_context browser in
    let page = BrowserContext.new_page context in

    ignore (Page.goto ~url:"https://example.com" page);

    let title = Page.locator ~selector:"h1" page |> Locator.inner_text in
    Printf.printf "h1: %s\n%!" title
```

## API notes

- Single-element Locator operations are strict by default: ambiguous matches
  raise rather than silently choosing a target. Use `first`, `last` or `nth`
  when ordering is intentional; plural operations remain plural.
- `Locator.is_visible` / `is_hidden` are immediate queries, not waits.
  Handle-based Locator helpers release temporary handles; handles explicitly
  returned to callers remain caller-owned.
- See [Locator usage and compatibility](doc/locators.md) for selector
  composition, test-ID configuration, frame/session restrictions, timeouts,
  cancellation safety and the retained `strict:false` extension.
- Protocol `binary` fields are raw-byte strings at every nesting level; do not
  pre-encode nested uploads or decode returned event/screenshot bytes again.
- See [protocol compatibility and migration](doc/protocol.md) for schema-aligned
  API removals, path-scoped generated type names, byte semantics and special-value
  wire spellings.
- JavaScript values are represented as `Yojson.Safe.t` in helpers such as `Page.evaluate`
- Playwright protocol errors are raised as `Playwright.Error string`
- Sessions belong to the supplied Eio switch; multiple instances are independent.
  `destroy` is idempotent, and leaving the switch cleans up the session.
- Event handlers and predicates run in owned Eio fibers outside the response
  reader. They can make RPCs directly, but invocations may overlap. Callback
  exceptions are reported on stderr by default, or through `create`'s
  `on_event_error` hook.
- See [session/event lifecycle semantics](doc/lifecycle.md) for ordering,
  cancellation, backpressure, error handling, deadline options and limitations.
  Cold driver provisioning is still blocking and outside the startup deadline.

## Tests

```sh
dune build @all
dune runtest --force --display=short
```

The lifecycle, Locator and protocol suites have real assertions and externally
bounded subprocesses. They require Linux, GNU `timeout`, the provisioned 1.59.1 driver,
Node.js, and `/usr/bin/chromium`. The Locator and protocol suites also run
differential assertions against that exact JavaScript package and browser. See
[lifecycle tests](test/critical/README.md),
[Locator tests](test/locator/README.md) and
[protocol tests](test/protocol/README.md).


## License

MIT © 2026 [Dmytro Melnychuk](https://github.com/dmytro-melno)
