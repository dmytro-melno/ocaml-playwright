# Locator compatibility and ownership regression tests

Run newly built code, not a previously loaded REPL library:

```sh
dune build @all
dune runtest --force --display=short
```

Or run just this directory's rule:

```sh
dune runtest test/locator --force --display=short
```

Prerequisites: Linux, GNU `timeout`, Node.js, `/usr/bin/chromium`, and the cached
**playwright-core 1.59.1** package at
`$HOME/.cache/playwright-ocaml-driver/1.59.1/package`.
Provision it before testing. The tests do not download a browser or use an
external website. `reference.cjs` verifies the package version and launches
the exact same Chromium executable as the OCaml tests.

## Coverage

There are **124 PASS groups**, with multiple assertions/cases within groups:

| Executable / mode | Groups | Purpose |
| --- | ---: | --- |
| `browser_tests.exe strict` | 40 | All existing single-element methods; specific strict-mode diagnostics, no silent click, explicit disambiguation and untouched plurals/raw selectors |
| `browser_tests.exe selectors` | 6 | Page/Frame/nested helpers, configured attributes, text semantics, escaping, composition, equivalent frame wrappers and cross-frame/session rejection |
| `browser_tests.exe helpers` | 8 | Immediate visibility and genuine errors, geometry, evaluation wait/execution budget, scroll/screenshot success and failure, ownership and cancellation |
| `browser_tests.exe latency` | 3 | 160 ms custom selectors across all singular handle paths, one invocation per acquisition, finite 2.2 s page work with independently responsive driver, canceled unlimited wait recovery |
| `ownership_tests.exe` | 20 | Deterministic wire responses, strict flags, same-handle budgets, late-response races, cancellation and cleanup failures; normal slow replies/write queues versus canceled-response recovery |
| `reference.cjs` | 47 | JavaScript 1.59.1 assertions against shared `fixture.js` and `latency-fixture.json`, including separate `dragTo`, slow-selector and busy-page probes |

The wire peer runs the real public Locator/connection implementation but owns
the response schedule. It does not replace the selector helpers, use a stale
preloaded binding, or execute user callbacks in a reader. It includes identical
frame GUIDs in distinct sessions, cancellation before/after response dispatch,
during acquisition/element operations/disposal, and primary-error preservation
when cleanup fails. The browser cases additionally measure actual channel
handle counts and continued caller-handle usability.

Strictness and invalid-selector cases assert diagnostic content on
`Playwright.Error`; hidden actionability failures assert `TimeoutError:`.
JS asserts corresponding error messages/types. Connection/target errors are
not accepted as a substitute for selector errors. Stalled response recovery and
disposal check the specific recovery diagnostic or preserved cancellation, not
“any exception”. Normal slow responses and pre-write queues must stay open and
succeed; no timer starts just because those operations exceed one second.
Canceled, transmitted requests must consume late resources or close under the
separate bounded recovery policy. A possibly partial write still closes the
connection; cancellation before transmission must not do so.

`Locator.expect` tests the raw protocol result (`matches` / `error_message`),
not the Playwright Test assertion wrapper. `strict:false`, context-local
test-ID configuration, stricter `drag_to` validation and Eio ownership
recovery are deliberate OCaml extensions/safety policies, not JS parity.

Every subprocess has an external TERM/KILL deadline in `dune`. Public test
waits also have operation/application deadlines; wire tests synchronize on
requests, and browser tests on pending requests or JS flags. Small deliberate
response holds exercise budget accounting; there are no microsecond timing
expectations. The suites use a shared Dune resource lock with the existing
lifecycle/helper rules because concurrent Eio io_uring instances can exhaust
the host's per-user memlock budget. This serializes suites; it does not remove
their internal concurrency/race tests.

On the review host, even serialized back-to-back executables sometimes fail
before assertions with `Unix.ENOMEM` from `io_uring_queue_init`. Provision an
adequate per-user memlock budget for the Eio backend. The independent reviewer's
launcher (`review/locator-probes/bin/timeout`) sleeps two seconds, then executes
the original GNU timeout unchanged. A reproducible paced full run is:

```sh
PATH="$PWD/review/locator-probes/bin:$PATH" \
  dune runtest --force --display=short
```

This is a host-resource workaround, not a library fix or a change to assertion
deadlines. Retain failed direct-run logs; do not describe an infrastructure
failure as passing tests. The new latency tests use finite deliberate work and
request/console synchronization, not tight wall-clock acceptance thresholds.

For manual browser modes, run from the fixture directory after building:

```sh
dune build test/locator/browser_tests.exe test/locator/ownership_tests.exe
(cd test/locator && timeout --signal=TERM --kill-after=3s 45s \
  ../../_build/default/test/locator/browser_tests.exe helpers)
timeout --signal=TERM --kill-after=3s 25s \
  _build/default/test/locator/ownership_tests.exe
timeout --signal=TERM --kill-after=3s 40s node test/locator/reference.cjs
```

See [usage](../../doc/locators.md),
[initial implementation evidence](../../review/LOCATOR_FIXES.md), and
[LR01/LR02 revision evidence](../../review/LOCATOR_REVISIONS.md).
