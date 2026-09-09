# Critical lifecycle regressions

Run from the repository root:

```sh
dune build @all
dune runtest --force --display=short
# Only this suite:
dune build @test/critical/runtest --force
```

The alias runs **41 assertion-based test groups** in six separately bounded
subprocesses (four modes of `critical_tests`, two of `public_regression`).
An assertion or unexpected exception is fatal. GNU `timeout` adds TERM/KILL
deadlines around cases capable of hanging; Eio deadlines bound individual waits.
Tests are not skipped when a prerequisite is missing.

Prerequisites: Linux (`/proc` resource assertions), GNU `timeout`, Node.js, Eio,
the pinned **playwright-core 1.59.1** driver already provisioned in the normal
cache, and `/usr/bin/chromium`. The browser tests use local HTML or intercepted
requests to `fixture.invalid`, not public websites. Driver-failure tests use a
private HOME, a provisioned fake driver, and real Node; they never download or
alter the real cache. The fake driver does not create grandchildren.

| Mode | Coverage |
| --- | --- |
| `internal` | RPC success/error, serialization/write failure, blocked writers, lock cancellation, late responses, 200 close/response races, 100 cancellations, EOF/truncation/malformed input, event ordering/reentrancy, overlapping predicates, cancellation after channel disposal, failing cancellation finalizers, 100 event shutdown races, backpressure and reporter failure |
| `events` | Public console/title, binding/resolve, dialog/dismiss, route/fulfill, predicate/title RPCs; suspended/reentrant/error callbacks; generated decoder and no-parameter waits; destroy inside callback; concurrent large RPCs and normal browser workflows |
| `ownership` | Public instances in both destruction orders; nested/independent/canceled switches; cross-session callback destruction, creation without inherited retention, and error isolation; double destroy; weak-reference, descriptor, callback/task and child-process cleanup, including a still-live owning switch |
| `drivers` | Missing executable after pipe allocation, immediate exit, protocol initialization error, startup deadline and caller cancellation, concurrent failed initialization with a healthy survivor, EOF, process exit with stdout deliberately held open, TERM-resistant shutdown, killed real driver |
| `public_regression console/multiple` | Small, stable-public-API acceptance tests that compile unchanged against the reviewed revision |

Expected stderr includes intentional callback/reporter failures and the missing
executable diagnostic. These are asserted failure-policy tests, not ignored
unexpected exceptions.

Automatic event subscriptions (review E01) are **not** fixed by this task.
Tests explicitly use valid `Page.update_subscription` calls for console/dialog
and network-interception patterns for routes. They do not work around callback
RPCs by forking them manually.

`review/reproduce-critical-baseline.sh` builds only the public regression tests
against a disposable archive of revision `57da8a7...`. Both fail there (console
RPC timeout, wrong instance destroyed); both pass in this alias. More detailed
internal tests exercise the new runtime invariants and thus intentionally use
`Playwright.Internal.connection` and the exposed `Connection` implementation.

See [lifecycle semantics](../../doc/lifecycle.md) and
[fix evidence](../../review/CRITICAL_FIXES.md). Resource assertions check owned
direct child processes, not unrelated host processes. Browser/driver subprocesses
are always cleaned up by the owning scope; outer process deadlines are a final
test-runner safety net.
