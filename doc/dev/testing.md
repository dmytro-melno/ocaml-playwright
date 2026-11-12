# Testing

`dune runtest` runs four sets of checks:

| Directory | What | Needs |
| --- | --- | --- |
| `test/unit` | the internals, without a driver | nothing |
| `test/driver` | what the library leaves to the driver itself: the reading of URL globs | Node.js, the driver |
| `test/integration` | the public interface against Chromium | Node.js, the driver, a Chromium |
| `test/docs` | the OCaml code in `README.md`, `doc/*.md` and the comments of `lib/playwright.mli` compiles | nothing |

It also fails if `lib/protocol.ml` or `doc/dev/protocol-coverage.md` is not what the
generator produces from `protocol/` (see [protocol.md](protocol.md)).

**Where there is no Node.js, no driver or no browser, the driver and browser tests are
skipped and the run succeeds**, with a line that says why. This keeps `dune runtest` usable
in sandboxes, such as the one opam builds in. `PLAYWRIGHT_TEST_REQUIRED=1` turns a skip into
a failure, for continuous integration. `dune exec ocaml-playwright -- install chromium`
installs the driver and a browser.

## Unit tests

`test/unit` is written against `playwright_internal`, the private library that holds the
implementation; `internal.ml` brings its modules into scope. A scripted transport plays the
driver, so that every order of events can be produced, which no browser does on demand.

| File | Covers |
| --- | --- |
| `test_wire.ml` | JSON decoding, framing of messages, and the connection: creation and disposal of objects, replies and errors, protocol failures, closing |
| `test_ownership.ml` | what a cancelled fiber leaves behind: replies that arrive late and what they hold, aborting, clean-up, closing that is concurrent, repeated or cancelled |
| `test_events.ml` | listeners (order, removal, changes during an emission, cost), the budget of handler calls and what happens beyond it, waiting for an event around an action |
| `test_process.ml` | running a child process over pipes with `Driver_process`: output, standard error, graceful stop, forced stop, cancellation. It uses `cat`, `sh` and `sleep` |
| `test_values.ml` | JavaScript values, selectors, snapshot templates, the URLs of assertions |
| `test_support.ml` | timeouts, paths, errors, and finding and installing the driver, with a script in place of Node.js |

```sh
dune build ./test/unit/main.exe && ./_build/default/test/unit/main.exe
./_build/default/test/unit/main.exe test connection        # one group
```

## Driver tests

`test/driver` starts the driver, but no browser. The driver makes a regular expression of a
URL glob and `Re` runs it (`lib/url_match.ml`); the test matches the examples of
Playwright's own tests in this way, sends globs of every shape to see that `Re` can read
what comes back, and matches a glob that a backtracking matcher does not survive. It is the
test to watch after an upgrade of Playwright.

## Browser tests

`test/integration` uses the public interface only, as an application would. It starts one
driver, one browser and one HTTP server (`server.ml`, on a free local port), and gives every
test a fresh browser context.

| File | Groups |
| --- | --- |
| `test_pages.ml` | `navigation`, `javascript` |
| `test_locators.ml` | `locators`, `expect` |
| `test_events.ml` | `events`: listeners, bursts, waiting, dialogs, downloads, popups |
| `test_network.ml` | `routing`, `network` |
| `test_context.ml` | `context`, `recording` |
| `test_cancellation.ml` | `cancellation`: what cancelled calls, closes and creations leave behind |
| `test_misc.ml` | `rendering`, `input`, `tools`, `objects`, `fibers`, `lifecycle` |

`harness.ml` has what the tests share, and `tls_server.ml` is an HTTPS server that asks for
a client certificate; it runs on Node.js, with a certificate that is part of the file.

Every test also checks that nothing was reported to the `on_error` hook, so an exception in
a background fiber fails the test during which it happened. A test that expects a report
takes it with `Harness.take_reports`.

The browser is, in this order: the one named by `PLAYWRIGHT_TEST_CHROMIUM`; the Chromium
that Playwright installed; a Chromium or Chrome found in the usual places of the system.
Tests are run with Chromium only: Firefox and WebKit go through the same code in this
library, and what differs between browsers is inside the driver. `DEBUG=pw:channel` prints
the protocol messages.

```sh
dune build ./test/integration/main.exe
./_build/default/test/integration/main.exe                     # all
./_build/default/test/integration/main.exe list                # the groups and tests
./_build/default/test/integration/main.exe test routing 3      # one test of a group
```

The test for video recording is skipped unless Playwright's ffmpeg is installed
(`dune exec ocaml-playwright -- install ffmpeg`). The test of failing launches leaves a few
empty directories named `playwright-artifacts-*` and `playwright_*dev_profile-*` in the
system's temporary directory: the driver does not remove them when a browser cannot be
started, with any client.

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
faster and keep the test in one place. `Harness.check_failure` checks the kind and the
message of a `Playwright.Error`.

A test should assert what a user of the library relies on, and it should fail if the
implementation is broken. Avoid sleeping; wait for a condition with `Expect`,
`expect_event` or `Harness.eventually`. Where time is what is tested, leave wide margins:
the tests also run on machines that are busy with something else. A test that passes only
when run alone, or only most of the time, points at a race worth finding.

## Documentation

`test/docs/extract.ml` collects the code blocks that are fenced with exactly ` ```ocaml ` from
`README.md` and `doc/*.md` (not `doc/dev`), and the examples in the comments of
`lib/playwright.mli`, into one source file, which is compiled and never run. A block that
starts with `open` or `let () =` is a program. Every other block is an expression in which
`Playwright` is open and `env`, `pw`, `browser`, `context`, `page`, `frame` and `locator`
are bound. Errors are reported at their place in the file that the block comes from. A
block that is not meant to compile is fenced with ` ```ocaml skip `.

`dune build @doc` builds the reference from `lib/playwright.mli` with odoc, which reports
references that do not resolve as warnings; there should be none. The programs in
`examples/` are built with everything else, and are run by hand.

## Before a release

```sh
dune build @all @runtest
PLAYWRIGHT_TEST_REQUIRED=1 dune test --force test/driver test/integration
dune build @doc 2>&1 | grep -c Warning      # needs odoc; 0
dune build --profile release @install
```

Run the browser tests several times: what they find that the unit tests cannot is mostly a
matter of timing. Then the cross-build for Windows, see [windows.md](windows.md).
