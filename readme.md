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

The matching `playwright-core` driver is downloaded automatically from npm on
first use to `~/.cache/playwright-ocaml-driver`.

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

The critical lifecycle suite has real assertions and externally bounded
subprocesses. It requires Linux, GNU `timeout`, the provisioned 1.59.1 driver,
Node.js, and `/usr/bin/chromium`. See [test details](test/critical/README.md).


## License

MIT © 2026 [Dmytro Melnychuk](https://github.com/dmytro-melno)
