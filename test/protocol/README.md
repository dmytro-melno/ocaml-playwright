# Protocol/generator/codec regressions

These assertion tests are wired into `dune runtest`, under the same Eio process
lock as the lifecycle and Locator suites. They use freshly built executables,
never the API preloaded into a development REPL.

## Reproduce

From the repository root, after installing the README prerequisites:

```sh
dune build @all
timeout --signal=TERM --kill-after=3s 80s dune runtest test/protocol --force --display=short
dune runtest --force --display=short
```

Live tests require Linux, GNU `timeout`, Node.js, `/usr/bin/chromium`, and the
cached driver/package at `~/.cache/playwright-ocaml-driver/1.59.1/package`.
The JS reference asserts that package's version before use and launches the
same browser. `fixture.cjs` serves only loopback HTTP, with an external CSS file
and byte/multipart echoes. The OCaml child has a 35-second process-group bound
(3-second kill grace) and a 30-second Eio bound; each live Dune action has a
45-second external bound. Event polling has a 3-second bound.

Tests do not download schemas or install browsers. Initial driver provisioning,
if absent, retains the library's existing behavior; provision before testing.

On the reviewed host, repeated Eio process startups have historically produced
`ENOMEM` before assertions. If that recurs, the review-only host pacer can be used:

```sh
PATH="$PWD/review/locator-probes/bin:$PATH" \
  timeout --signal=TERM --kill-after=3s 110s \
  dune runtest test/protocol --force --display=short
```

That wrapper delays process starts by two seconds; it does not change internal
assertions/deadlines. Report paced results separately from unpaced runs. It is
not a product dependency.

## Coverage (38 assertion groups)

- `offline_checks.sh` (3): fresh CLI ML/MLI regeneration twice, equality to
  Dune's generated API, offline hash/version rejection controls, and positive/
  negative compilation of public selector/subscription enums. Negative tests
  require the expected type/variant diagnostics, not just any compiler failure.
- `schema_tests.ml` (6): pinned driver/manifest and complete-diff surface checks,
  deterministic real/synthetic generation, path isolation, identical/conflicting
  definitions, normalized-name/outer-module shadowing errors, exact lexical
  enum literals.
- `codec_tests.ml` (5): compiled generated synthetic implementation **and**
  signature, binary codecs across direct/optional/nested/array/initializer/event/
  multi-result fields, actual mock Connection request/response frames, invalid
  Base64 failure, exact special-number wire forms and corrected real public
  record shapes.
- `live_tests.ml` and `reference.cjs` (12 each): manual context subscriptions,
  typed console/page errors, failed expectation actual values, selector versus
  actionability states, nonempty JS and external-CSS ranges, raw file/multipart/
  request/response bytes, real Request initializer data, PNG/PDF/nested screenshot
  results, JPEG screencast events, incoming/outgoing exact special-value literals.

The binary edge set is empty data, NUL, mixed non-UTF-8/NUL/text and all 256 byte
values. Ordinary strings that look like Base64 remain ordinary strings. Multipart
echoes extract the exact file body, rather than searching for an expected
substring. Binary response-body controls use browser `fetch` (navigating to an
octet-stream response starts a download).

`fixture.yml` deliberately reuses `state`, `options`, `entries` and `ranges` with
incompatible nested object/array/enum shapes in separate commands, as well as
genuinely identical mixin definitions. The compiled fixture ensures implementation
and signature references agree. Tests also reject same-name conflicting definitions
and accidental shadowing of the binary leaf/runtime/protocol modules.

The reference uses real JS 1.59.1 public methods plus private channels where the
OCaml API directly exposes a protocol operation. JS uses Buffers, OCaml uses raw
strings. Wire/byte assertions are equivalent; the convenience special-value
representations differ intentionally (JS numbers vs OCaml's existing JSON-string
convention for NaN/infinities).

These tests do not claim coverage of Electron, Android, remote CDP transport or
every launch option. Full schema equality/offline hashing and compilation cover
their declarations. Nor do they address automatic subscriptions, rich-value
semantics, explicit-null expectations, public handle decoding, descendant
ownership or provisioning redesign.
