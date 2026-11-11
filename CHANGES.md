# Changes

## 0.2.0 (unreleased)

A rewrite of the library for Playwright 1.65. The API changed throughout; see
[doc/migration.md](doc/migration.md) for how to adapt programs written for 0.1.

### Added

- The Playwright API in OCaml, hand-written and documented in `lib/playwright.mli`, in place
  of the functions generated from the protocol: abstract types, positional required
  arguments with the object last, optional arguments for everything else, lists and
  polymorphic variants instead of arrays and protocol records.
- `Playwright.run`, which starts the driver for the duration of a function.
- Locators after Playwright's model: `get_by_role` with all its options, `get_by_text`,
  `get_by_label` and the others with regular expression variants, `filter`, `and_`, `or_`,
  `nth`, `visible`, `describe`, frame locators, strictness.
- Assertions that retry: the module `Expect`, with `Expect.Not`.
- JavaScript values as `Js.t`, covering `undefined`, non-finite numbers, dates, big integers,
  regular expressions, errors, typed arrays and handles.
- Typed events (`Page.on Page.Console ...`) with `once`, `off`, `wait_for_event` and the
  race-free `expect_event`, `expect_popup`, `expect_download`, `expect_request`,
  `expect_response` and so on.
- Network interception: `route` and `route_matching` with `fulfill`, `continue`, `fallback`,
  `abort` and `fetch`; `route_from_har`; `route_web_socket`; HAR recording.
- `APIRequestContext` for HTTP requests without a page, `APIRequest.new_context`.
- Browser contexts with the full set of options, device descriptors (`Playwright.device`),
  cookies, storage state, permissions, geolocation, `Clock`.
- Dialogs, downloads, file choosers, uploads from disk and from memory, drag and drop.
- Screenshots of pages and elements, PDF, video recording, ARIA snapshots.
- Tracing, with chunks and groups.
- Workers, WebSockets, console and page error history, web storage, CDP sessions, custom
  selector engines, locator handlers.
- `BrowserType.connect` to a Playwright server, including file transfer, and
  `BrowserType.connect_over_cdp`; `BrowserType.launch_persistent_context`.
- Structured errors: `Playwright.Error` carries a record with a kind (`Timeout`,
  `Target_closed`, `Assertion_failed`, `Other`), the message, the call log and the stack.
- Cancelling a fiber cancels the call it is blocked in, and tells the driver to stop.
- The command `ocaml-playwright`, which is Playwright's command line tool for the driver in
  use (`install`, `show-trace`, `codegen`, `run-server`), and `Playwright.Driver` to run it
  from a program.
- A user guide, examples, and documentation for work on the library.
- Unit tests that need no browser and a suite of tests against Chromium. The OCaml code in
  the documentation is compiled as part of the tests.

### Changed

- Playwright 1.65.0 instead of 1.59.1. The protocol description and the checksum of the
  driver are pinned in `protocol/`; `dune build @gen --auto-promote` regenerates the protocol
  layer, and the tests fail when it is stale.
- The driver is downloaded and unpacked by Node.js, which it needs anyway, and verified
  against a pinned SHA-512 checksum. It is cached in `ocaml-playwright/` under the user's
  cache directory.
- The architecture: a connection layer that knows nothing about Playwright's objects, a
  generated and typed protocol layer, client objects on top, and one public module. See
  [doc/dev/architecture.md](doc/dev/architecture.md).
- Windows support no longer needs C stubs: the driver's pipes are served by two threads.
- Dependencies are down to `eio`, `yojson` and `base64`.

### Removed

- The generated API (`Playwright.Playwright`, the `...Params` and `...Result` modules) and
  the internal modules that were exported (`Connection`, `Transport`, `Driver`, `Internal`).
- `Playwright.destroy` (now `Playwright.close`) and the arguments `download_timeout`,
  `init_timeout`, `shutdown_timeout`, `max_event_tasks` and `on_event_error` of
  `Playwright.create`.
- The dependencies on `cohttp-eio`, `tls`, `tls-eio`, `ca-certs`, `mirage-crypto-rng`,
  `tar`, `tar-eio`, `ppx_deriving_yojson`, `mtime`, `re`, `uri`, `cstruct` and others.

## 0.1.1 and earlier

Bindings generated from the protocol of Playwright 1.59, with helpers for locators and
evaluation.
