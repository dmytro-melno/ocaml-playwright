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


## License

MIT © 2026 [Dmytro Melnychuk](https://github.com/dmytro-melno)
