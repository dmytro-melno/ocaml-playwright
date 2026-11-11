# Testing

There are three sets of checks, all run by `dune runtest`:

| Directory | What | Needs |
| --- | --- | --- |
| `test/unit` | the internals, without a driver | nothing |
| `test/integration` | the public API against Chromium | Node.js, the driver, a Chromium |
| `test/docs` | the OCaml code in `README.md` and `doc/*.md` compiles | nothing |

In addition, `dune runtest` fails if `lib/protocol.ml` is not what the generator produces
from `protocol/` (see [protocol.md](protocol.md)).

## Unit tests

`test/unit` is written against `playwright_internal`, the private library that holds the
implementation; `internal.ml` brings its modules into scope. It covers:

- `test_wire.ml`: JSON decoding, framing of messages, and the connection against a scripted
  transport: creation and disposal of objects, replies and errors, cancellation, closing.
- `test_values.ml`: JavaScript values, selectors, the regular expressions of URL globs.
- `test_support.ml`: emitters, waiters, timeouts.
- `test_process.ml`: running a child process over pipes, with both implementations of
  `Driver_process`: output, graceful stop, forced stop, cancellation. It uses `cat`, `sh`
  and `sleep`.

```sh
dune build ./test/unit/main.exe && ./_build/default/test/unit/main.exe
./_build/default/test/unit/main.exe test connection        # one group
```

## Browser tests

`test/integration` starts one driver, one browser and one HTTP server (`server.ml`, on a
free local port), and gives every test a fresh browser context. The tests are grouped by
subject: pages, locators, events, network, contexts, and a file of everything else
(tracing, CDP, remote browsers, life cycle).

Every test also checks that nothing was reported to the `on_error` hook, so an exception in
a background fiber fails the test during which it happened.

The browser is, in this order: the one named by `PLAYWRIGHT_TEST_CHROMIUM`; the Chromium
that Playwright installed; a Chromium or Chrome found in the usual places of the system.

**When there is no Node.js, no driver or no browser, the tests are skipped and the run
succeeds**, with a line that says why. This keeps `dune runtest` usable in sandboxes, such
as the one opam builds in. Where the tests must not be skipped, as in continuous
integration, set `PLAYWRIGHT_TEST_REQUIRED=1`, which turns a skip into a failure.

| Variable | Effect |
| --- | --- |
| `PLAYWRIGHT_TEST_CHROMIUM` | path of the browser to test with |
| `PLAYWRIGHT_TEST_REQUIRED=1` | fail instead of skipping |
| `PLAYWRIGHT_OCAML_DRIVER_IO=threads` | run the driver with the thread-based pipes that Windows uses, on any system |
| `DEBUG=pw:channel` | print the protocol messages |

```sh
dune build ./test/integration/main.exe
./_build/default/test/integration/main.exe                     # all
./_build/default/test/integration/main.exe list                # the groups and tests
./_build/default/test/integration/main.exe test routing        # one group
./_build/default/test/integration/main.exe test routing 3      # one test
PLAYWRIGHT_OCAML_DRIVER_IO=threads ./_build/default/test/integration/main.exe
```

The test for video recording is skipped unless Playwright's ffmpeg is installed
(`dune exec ocaml-playwright -- install ffmpeg`).

The test of failing launches leaves a few empty directories named `playwright-artifacts-*`
and `playwright_*dev_profile-*` in the system's temporary directory. They are created by
the driver, which does not remove them when a browser cannot be started; the official
clients behave the same.

Tests are run with Chromium only. Firefox and WebKit go through the same code in this
library; what differs between browsers is inside the driver.

### Writing a browser test

```ocaml skip
let test_fills_the_form page =
    Page.set_content {|<label>Name <input></label>|} page;
    Page.get_by_label "Name" page |> Locator.fill "Ada";
    Expect.to_have_value "Ada" (Page.get_by_label "Name" page)

let tests t = [ page_case t "fills the form" test_fills_the_form ]
```

`Harness.page_case` gives the test a page in a context of its own; `Harness.case` gives it
nothing, for tests that create their own contexts. `Server.page` registers a document on
the HTTP server for tests that need a real origin, and `Server.route` a function that
answers requests. Prefer `Page.set_content` and `Page.route` where they suffice: they are
faster and keep the test in one place.

A test should assert what a user of the library relies on, and it should fail if the
implementation is broken. Avoid sleeping; wait for a condition with `Expect` or an
`expect_...` function. A test that passes only when run alone, or only most of the time,
points at a race worth finding.

## Documentation

`test/docs/extract.ml` collects the code blocks that are fenced with exactly ` ```ocaml ` from
`README.md` and `doc/*.md` (not `doc/dev`) into one source file, which is compiled and never
run. A block that starts with `open` or `let () =` is a program. Every other block is an
expression in which `Playwright` is open and `env`, `pw`, `browser`, `context`, `page`,
`frame` and `locator` are bound. Errors are reported at their place in the Markdown file.
A block that is not meant to compile is fenced with ` ```ocaml skip `.

## Before a release

```sh
dune build @all @runtest
PLAYWRIGHT_TEST_REQUIRED=1 dune test --force test/integration
PLAYWRIGHT_TEST_REQUIRED=1 PLAYWRIGHT_OCAML_DRIVER_IO=threads dune test --force test/integration
dune build @doc                      # needs odoc
```

and the cross-build for Windows, see [windows.md](windows.md).
