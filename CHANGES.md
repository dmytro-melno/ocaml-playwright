# Changes

The versions follow [semantic versioning](https://semver.org). Before 1.0 a new minor
version may change the interface; a new version of Playwright always means at least a new
minor version, since the behaviour of browsers and of the driver changes with it.

## 0.2.0 (unreleased)

A rewrite of the library, for Playwright 1.65. Every program written for 0.1 has to be
adapted; [doc/migration.md](doc/migration.md) says how.

### The interface

- One module, `Playwright`, written by hand and documented in `lib/playwright.mli`, in
  place of the functions that 0.1 generated from the protocol. It follows the interface of
  the official Playwright libraries; [doc/parity.md](doc/parity.md) lists how names and
  types are translated, what behaves differently and what is not covered.
- Conventions that hold throughout: the object is the last argument, so that calls can be
  piped; required arguments are positional; everything optional is a labelled optional
  argument; timeouts are in milliseconds; choices are polymorphic variants; collections are
  lists.
- Every kind of object has a module with an abstract type `t` (`Page.t`, `Locator.t`,
  `Request.t`, ...) and with `equal`, `compare` and `hash`, so that objects can be compared
  and kept in sets and tables.
- `Playwright.run ~env f` starts the driver for the duration of a function.
  `Playwright.create ~sw ~env ()` ties it to a switch, and `Playwright.close` stops it.
- Errors are one exception, `Playwright.Error`, with a record: a kind (`Timeout`,
  `Target_closed`, `Assertion_failed`, `Other`), the message, the call log of the driver
  and the stack of a JavaScript error. Misuse that needs no browser to detect raises
  `Invalid_argument`.
- Events are typed: `Page.on Page.Console (fun message -> ...) page`. There are `once`
  and `expect_event`, which runs an action and returns the event that it causes without a
  race, and `expect_request` and `expect_response`, which select by URL.
- Whatever is registered (a listener, a route, an init script, an exposed function) returns
  a `Disposable.t` to take it back with.
- JavaScript values are `Js.t`, which covers `undefined`, non-finite numbers, dates, big
  integers, regular expressions, errors, typed arrays, URLs and handles, with converters
  from and to OCaml values and JSON.

### What it covers

- Browser types, browsers, contexts with the full set of options, device descriptors
  (`Playwright.device`), persistent contexts, `BrowserType.connect_over_cdp`.
- Pages and frames: navigation, content, evaluation, init scripts, exposed functions,
  emulation, screenshots, PDF, video, web storage, keyboard, mouse and touch.
- Locators after Playwright's model: `get_by_role` with all its options, `get_by_text`,
  `get_by_label` and the others with variants for regular expressions, `filter`, `and_`,
  `or_`, `nth`, `visible`, `describe`, frame locators, strictness, locator handlers,
  `drag_to`, uploads from disk and from memory.
- Assertions that retry: the module `Expect`, with `Expect.Not`, for locators, pages and
  API responses, including ARIA snapshots.
- Network: requests, responses and WebSockets with their events; `route` and
  `route_matching` with `fulfill`, `continue`, `fallback`, `abort` and `fetch`;
  `route_web_socket`; client certificates, HTTP
  credentials, proxies.
- `APIRequestContext` for HTTP requests without a page, on a context or alone
  (`APIRequest.new_context`).
- Cookies, storage state, permissions, geolocation, `Clock`.
- Dialogs, downloads, file choosers, console messages and page errors, also as history.
- Tracing, with chunks and groups. Workers and service workers. CDP sessions. Custom
  selector engines.
- What Playwright added up to 1.65: `Page.get_by_ref` and ARIA snapshots with references
  for programs that are driven by a language model, `Page.aria_snapshot_json`,
  `Page.pick_locator`, `Locator.within`, `description`, `normalize`, `selector` and
  `wait_for_function`, `APIResponse.server_addr`, `security_details` and `timing`,
  `APIRequestContext.tracing`, `WebError.location`, the events of pages on their context
  (`BrowserContext.Page_close`, `Page_load`, `Frame_navigated`, `Download`, ...),
  `Dialog_closed`, the options `scroll`, `include_shadow`, `opfs`, `artifacts_dir` and
  `no_defaults`, `Expect.to_have_accessible_error_message`.
- The command `ocaml-playwright`, which is Playwright's command line tool for the driver in
  use (`install`, `show-trace`, `codegen`), and `Playwright.Driver` to run it
  from a program.

### Behaviour

- Listeners, route handlers and exposed functions run in a fiber for each call, and may
  block and call the library. The library bounds
  how many calls run (1024) and wait (65536) at a time; when handlers fall behind
  beyond that, the connection is closed with an error that says so. 0.1 closed the
  connection at 1024 events in progress (`max_event_tasks`).
- Exceptions that escape from handlers go to `on_error`, by default to standard error. A
  route handler that raises aborts its request.
- When the driver is closed or dies, every call in flight fails with a `Target_closed`
  error, the `Close` and `Disconnected` listeners of every object are called, and handlers
  that are still running are cancelled. No fiber is left waiting.
- Cancellation is safe. Cancelling a fiber cancels the call that it is blocked in and tells
  the driver to stop; what the call had made by then is released. `close`, `dispose` and
  the like are carried out even if their caller is cancelled, so they can be used in
  `Fun.protect` and `Switch.on_release`. Closing something twice, or from two fibers at
  once, is fine.
- `Eio.Time.with_timeout` works around any call, including `Playwright.create` while it
  downloads the driver.
- The time limit of `expect_*` and `wait_for_*` is on the arrival of the event and counts
  from before the action; the predicate is called as events arrive and may itself call the
  library.
- URL globs are read by the driver, as in every Playwright client, base URL and all; a
  malformed glob is an error where the route is registered or the wait begins.
- The library opens no files. Screenshots, PDFs and storage state are returned; scripts,
  certificates and the bodies of fulfilled routes are passed as text. The driver reads and
  writes the files whose paths it is given: uploads, downloads, videos, traces.

### The driver

- Playwright 1.65.0 instead of 1.59.1. The protocol description and the checksum of the
  driver are pinned in `protocol/`; `dune build @gen --auto-promote` regenerates the
  protocol layer and an inventory of what the client uses of it, and the tests fail when
  either is stale.
- The driver is downloaded and unpacked by Node.js, which it needs anyway, and verified
  against a pinned SHA-512 checksum. It is cached in `ocaml-playwright/` under the user's
  cache directory. The download is given up after five minutes
  (`PLAYWRIGHT_OCAML_DRIVER_INSTALL_TIMEOUT`), or when the fiber that started Playwright is
  cancelled.
- The driver never outlives the program's use of it: it is stopped when the instance is
  closed or its switch finishes, and killed if it does not comply. Its standard error is
  relayed, so that it cannot make the program's own standard error non-blocking.
- Windows needs no C stubs any more: the driver's pipes are served by two threads. The
  build for Windows is cross-compiled and was tried under Wine only; see
  [doc/dev/windows.md](doc/dev/windows.md).
- The dependencies are `eio`, `cstruct`, `yojson`, `base64` and `re`.

### Inside

- A connection layer that knows nothing about Playwright's objects, a generated protocol
  layer in which every object has the type of its interface, client objects on top, and the
  public module as a facade. The implementation is a private library: applications can
  name nothing but `Playwright`. See [doc/dev/architecture.md](doc/dev/architecture.md).
- Unit tests that script the driver's side of the connection, tests of the ported URL
  matching against the driver, and a suite of tests against Chromium that uses the public
  interface only, all run with both implementations of the driver's pipes. The OCaml code in
  the documentation is compiled as part of the tests.
- A user guide, a comparison with Playwright, a migration guide, examples, and
  documentation for work on the library.

### Removed

- The generated API (`Playwright.Playwright`, the `...Params` and `...Result` modules) and
  the internal modules that were exported (`Connection`, `Transport`, `Driver`, `Internal`,
  and every `Playwright__...` module).
- `Playwright.destroy` (now `Playwright.close`) and the arguments `download_timeout`,
  `init_timeout`, `shutdown_timeout`, `max_event_tasks` and `on_event_error` of
  `Playwright.create`.
- The dependencies on `cohttp-eio`, `tls`, `tls-eio`, `ca-certs`, `mirage-crypto-rng`,
  `tar`, `tar-eio`, `ppx_deriving_yojson`, `mtime`, `re`, `uri` and others.

## 0.1.1 and earlier

Bindings generated from the protocol of Playwright 1.59, with helpers for locators and
evaluation.
