# Changes

The versions follow [semantic versioning](https://semver.org). Before 1.0 a new minor
version may change the interface; a new version of Playwright always means at least a new
minor version, since the behaviour of browsers and of the driver changes with it.

## 0.2.0 (unreleased)

A rewrite of the library, for Playwright 1.65. Every program written for 0.1 has to be
adapted; [doc/migration.md](doc/migration.md) says how.

### The interface

- One module, `Playwright`, written by hand and documented in `lib/playwright.mli`, in
  place of the functions that 0.1 generated from the protocol. Its names are those of the
  official Playwright libraries. It binds what the driver can do, not every convenience
  of those libraries; [doc/scope.md](doc/scope.md) states the rule, and lists what behaves
  differently and what is left out.
- Conventions that hold throughout: a page, a context, a browser or any other object is
  the first argument, as in `Page.goto page url`, except for locators and `Js` values, which
  are the last one, so that calls can be piped; required arguments are positional and in
  Playwright's order; everything optional is a labelled optional argument; timeouts are in
  milliseconds; choices are polymorphic variants; collections are lists.
- The types of objects are abstract (`Page.t`, `Locator.t`, `Request.t`, ...), and what
  lives in the browser has `equal`, `compare` and `hash`.
- `Playwright.run ~env f` starts the driver for the duration of a function.
  `Playwright.create ~sw ~env ()` ties it to a switch, and `Playwright.close` stops it.
- Errors are one exception, `Playwright.Error`, with a record: a kind (`Timeout`,
  `Target_closed`, `Assertion_failed`, `Other`), the message, the call log of the driver
  and the stack of a JavaScript error. Misuse that needs no browser to detect raises
  `Invalid_argument`.
- Events are typed: `Page.on page Page.Console (fun message -> ...)`. Browsers, contexts,
  pages, workers and WebSockets have `on`, `once` and `expect_event`, which runs an action
  and returns the event that it causes without a race; pages also have `expect_request`
  and `expect_response`, which select by URL.
- Whatever is registered (a listener, a route, an init script, an exposed function, a
  locator handler) returns a `Disposable.t` to take it back with.
- JavaScript values are `Js.t`, which covers `undefined`, non-finite numbers, dates, big
  integers, regular expressions, errors, typed arrays, URLs and handles, with converters
  from and to OCaml values and JSON.
- Locators after Playwright's model, with strictness and frame locators; assertions that
  retry (`Expect`, `Expect.Not`); routing of requests and WebSockets; `APIRequestContext`;
  cookies, storage state, emulation and `Clock`; dialogs, downloads and file choosers;
  tracing; workers; CDP sessions. The guide, [doc/guide.md](doc/guide.md), goes through
  them.
- From Playwright 1.60 to 1.65: `Page.get_by_ref` and ARIA snapshots with references, for
  programs that are driven by a language model; `Page.pick_locator`; `Locator.normalize`;
  `WebStorage`; the events of pages on their context (`BrowserContext.Page_close`,
  `Frame_navigated`, ...); the options `scroll`, `include_shadow`, `opfs`, `artifacts_dir`
  and `no_defaults`.

### Behaviour

- Listeners, route handlers and exposed functions run in a fiber for each call, and may
  block and call the library. At most 1024 calls run and 65536 wait at a time; when
  handlers fall behind beyond that, the connection is closed with an error that says so.
  0.1 closed it at 1024 events in progress.
- Exceptions that escape from handlers go to `on_error`, by default to standard error. A
  route handler that raises aborts its request.
- When the driver is closed or dies, every call in flight fails with a `Target_closed`
  error, the `Close` listeners of every object are called, and handlers that are still
  running are cancelled. No fiber is left waiting.
- Cancellation is safe. Cancelling a fiber cancels the call that it is blocked in and tells
  the driver to stop; what the call had made by then is released. `close`, `dispose` and
  the like are carried out even if their caller is cancelled, and closing something twice,
  or from two fibers at once, is fine.
- The library opens no files. Screenshots, PDFs and storage state are returned; scripts,
  certificates and the bodies of fulfilled routes are passed as text. The driver reads and
  writes the files whose paths it is given: uploads, downloads, videos, traces.

### The driver

- Playwright 1.65.0 instead of 1.59.1. The protocol description and the checksum of the
  driver are pinned in `protocol/`; `dune build @gen --auto-promote` regenerates the
  protocol layer and an inventory of what the client uses of it, and the tests fail when
  either is stale.
- Installing the driver is a step of its own: `ocaml-playwright install chromium` downloads
  the driver and that browser, and `Playwright.Driver.install` the driver alone.
  `Playwright.create` only looks for the driver, and fails with an error that names the
  command when it is missing. The driver is downloaded and unpacked by Node.js, which it
  needs anyway, and verified against a pinned SHA-512 checksum. It is kept in
  `ocaml-playwright/` under the user's cache directory.
- The driver never outlives the program's use of it: it is stopped when the instance is
  closed or its switch finishes, and killed if it does not comply.
- The driver's pipes are served by two threads on every system, so Windows needs no C
  stubs. The build for Windows is cross-compiled and was tried under Wine only; see
  [doc/dev/windows.md](doc/dev/windows.md).

### Removed

- The generated API (`Playwright.Playwright`, the `...Params` and `...Result` modules), the
  operations that take a selector or work on an `ElementHandle`, and the internal modules
  that were exported (`Connection`, `Transport`, `Internal`). The implementation is a
  private library: applications can name nothing but `Playwright`.
- `Playwright.destroy` (now `Playwright.close`) and the arguments `download_timeout`,
  `init_timeout`, `shutdown_timeout`, `max_event_tasks` and `on_event_error` of
  `Playwright.create`.
- The environment variable `PLAYWRIGHT_OCAML_CACHE_DIR`.
- The dependencies on `cohttp-eio`, `tls`, `tls-eio`, `ca-certs`, `mirage-crypto-rng`,
  `tar`, `tar-eio`, `ppx_deriving_yojson`, `mtime`, `uri` and others. What remains is
  `eio`, `cstruct`, `yojson`, `base64` and `re`.

## 0.1.1 and earlier

Bindings generated from the protocol of Playwright 1.59, with helpers for locators and
evaluation.
