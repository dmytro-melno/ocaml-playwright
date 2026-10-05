# Sessions, events, cancellation and shutdown

These semantics apply to the Eio implementation using the pinned
**playwright-core 1.59.1** driver. They are not a promise of parity with every
stateful wait or event subscription in Playwright's JavaScript API.

## Session identity and ownership

`create ~env ~sw ()` returns a handle that carries its exact connection, as do
all generated channel handles. Protocol GUIDs are only meaningful **within**
that connection. In particular, many live sessions legitimately have the GUID
`"Playwright"`.

There is no global instance registry. Each session has a daemon supervisor
owned by the supplied switch and a private resource switch for its driver,
pipes, reader and callback tasks. Sessions in one switch remain independent.
Exiting or canceling an inner switch does not close sessions owned by an outer
or unrelated switch. The supplied owning switch—not the location of the call
to `create`—determines the successful session's lifetime.

Explicit `destroy` and switch-driven cleanup converge on the same idempotent
close transition. After closure, new RPCs reject without writing. Repeated
destroy, concurrent destroy, and destroy after the switch has ended are safe.
Objects, listeners, queued events, requests and the cleanup-join closure are
released when their respective cleanup completes. Retaining an old handle does
not keep a process running or keep its old channel table populated.

An ordinary `destroy pw` waits for owned cleanup and is cancellation-protected.
**In a Playwright callback context (including inherited fiber-local context),
destroy initiates closure but does not join cleanup.** Joining could deadlock
on that callback, or form a cross-session cycle if two callbacks destroy one
another. An ordinary caller can subsequently call destroy to join; the owning
switch also joins its resources. Further callback RPCs on the closed session
fail.

The inherited callback-context marker contains no connection reference. Creating
session B from a callback in A does not retain A in B's supervisor.

Connection state and callbacks are owned by **one Eio domain**. Do not share a
session across OCaml domains. This change does not add multi-domain locking.

## Event execution and pressure

The transport reader only decodes protocol envelopes, updates channel state,
settles responses and enqueues listener snapshots. User handlers, event decoders
and wait predicates run in separate, session-owned Eio fibers.

Invocations **start in wire-event order and listener-registration order**.
Suspended invocations may overlap, including invocations of the **same**
listener. Completion order is not guaranteed. A callback can perform an RPC,
wait for another event, and depend on another callback without monopolizing
the reader or a serial callback worker.

This is not an unlimited fire-and-forget dispatcher:

- `max_event_tasks` bounds the sum of queued and active listener invocations
  (default **1024**, positive integer).
- Tasks remain in the session's callback scope until they finish; shutdown
  cancels and joins that scope.
- If an event would exceed the limit, the session closes with an
  `"event task limit ... exceeded"` reason. Pending RPCs/waits fail and remaining
  callbacks are canceled. The reader neither waits for space nor silently drops
  events while leaving the session apparently healthy.
- The limit counts invocations, **not bytes**; a protocol frame or event payload
  can still be large. It is not a general heap or hostile-driver memory limit.

A handler can call `Page.title`, `BindingCall.resolve`, `Dialog.dismiss`, or
`Route.fulfill` directly. Do not fork just to keep the response reader alive.

**Cooperative scheduling is essential.** A blocking syscall or CPU-bound loop
in user code still blocks the Eio domain. Yield, use asynchronous Eio operations,
or explicitly offload blocking work. Nonterminating cancellation-protected code
cannot be preempted; it can also prevent shutdown from completing.

Subscriptions have not been overhauled. Some protocol events require an
explicit valid subscription, for example:

```ocaml
Page.update_subscription ~event:`Console ~enabled:true page;
BrowserContext.on_console context (fun _event ->
  Printf.printf "%s\n%!" (Page.title page))
```

Network route handlers likewise need interception patterns. An asynchronously
delivered event is not a guarantee that its referenced page/context is still
open when the handler uses it.

## Observable error policy

Supply a per-session reporter, or use the default stderr reporter:

```ocaml
let pw =
  create ~env ~sw
    ~download_timeout:120.
    ~init_timeout:30.
    ~shutdown_timeout:1.
    ~max_event_tasks:1024
    ~on_event_error:(fun (error : Connection.event_error) ->
      Printf.eprintf "Event %s on %s failed: %s\n%s%!"
        error.event error.guid
        (Printexc.to_string error.exception_)
        (Printexc.raw_backtrace_to_string error.backtrace))
    ()
```

An ordinary handler or typed event decoder exception is reported and that
invocation ends. It does not fail the caller's switch or another session, and
other listeners still run. A callback-local cancellation that is not cancellation
of its owned runtime is also reported. Genuine shutdown/listener-removal
cancellation is propagated for task cleanup, not reported as a callback failure.
A **real exception in a user finalizer during cancellation is not suppressed**:
after listener removal it is reported normally; if the whole callback scope is
already canceled it goes directly to stderr, without running a potentially
suspending user reporter in that canceled context or replacing the original
scope failure.

The reporter runs in the failing task, outside the reader, and may suspend or
perform RPCs. Reporter invocations may overlap too. If the reporter raises
(including its own local cancellation), both errors are diagnosed on stderr
and **that connection** closes. Do not use a reporter that silently discards
errors. Backtrace detail depends on OCaml backtrace recording/build settings.

A wait predicate or wait-event decoding error instead fails **the waiting
caller**, with its exception/backtrace. It is not converted to `false`, swallowed,
or sent to the ordinary callback reporter.

## Event waits and cancellation

Generated `wait_for_*` helpers register owned event listeners. Predicates may
perform RPCs and may overlap when several events arrive. The first matching
completion or predicate/decoder failure settles the waiter once. Finishing,
canceling or timing out the wait removes its listener, invalidates queued
invocations and cancels active predicate evaluations—including a predicate
whose channel was disposed while it was suspended. Canceled evaluations finish
under the callback scope; shutdown joins them.

Connection closure fails pending waits with `Connection.Closed reason`.
Registering a listener on an already closed connection raises the same exception.
Registering on an unknown/disposed channel raises `Invalid_argument`.
RPC methods and initializer-reference getters on closed sessions raise
`Playwright.Error reason`.

These remain **next-event** waits. They do not infer already-reached load/close
state or automatically fail every wait when a page/context channel is disposed.
Use `Eio.Time.with_timeout_exn` to bound application waits. Recursive channel
adoption/disposal and JS-style stateful waits are separate work.

## Requests and races

The connection transitions once from Open to Closed; the first close reason
wins. EOF, malformed/truncated protocol, read/write failure, driver exit, failed
initialization, explicit destroy and scope cancellation all use this transition.

Serialization happens before request registration. Once registered, the entry
is removed on every exit: success, protocol error, write failure, caller
cancellation or connection close. Dispatch removes the entry **before**
resolving it; closure clears all entries. Late responses to abandoned ordinary
requests are ignored. A response already settled before close can succeed;
close cannot resolve it a second time.

Complete RPC frames are serialized under a per-connection mutex. Cancellation
while waiting for the mutex or an ordinary response is local: it removes the
pending entry but **does not cancel execution in the driver/browser**. The operation may
still run remotely. Cancellation/failure **during a frame write** closes the
connection conservatively because partial output could corrupt the stream.
Connection closure also interrupts blocked writes and lock waiters.

`Connection.send_message` returns a closed/protocol failure as `Error reason`;
the generated public RPC wrappers raise `Playwright.Error`. Local serialization
errors and caller cancellation retain their original exception.

### Locator handle ownership

The [Locator helpers](locators.md) use a narrow, explicit exception to immediate
response abandonment. Singular acquisition sends one strict attached-wait
request with its available timeout; plural acquisition sends one query. Normal
acquisitions are not retried in short slices or subject to a fatal one-second
latency deadline.

`Connection.send_message` has an internal opt-in `on_cancel` recovery hook for
these resource-bearing responses. It runs in the caller, **not the reader**,
only if a complete request frame was sent and that caller was canceled. The
original promise/registration remains owned until response recovery completes
or connection closure clears it. Cancellation while queued for the write lock
does not invoke recovery or close the session. Ordinary generated calls keep
their original cancellation behavior.

Locator response recovery is cancellation-protected and bounded to one second.
A late handle is decoded and disposed before cancellation is re-raised. If no
reply arrives (including a canceled, unlimited wait for an absent element),
recovery closes that exact session rather than orphaning remote handles or
pending requests. Disposal is independently protected and bounded to one second
per handle. Operation errors/cancellation survive secondary cleanup errors.
There are no unowned cleanup fibers or reader callbacks.

This is not general remote cancellation: remote actions/JavaScript may continue
after local cancellation, and arbitrary JavaScript execution is not bounded by
a Locator's element-acquisition timeout. See the Locator guide for timeout-zero,
operation-specific budgets and the explicit post-cancellation close policy.

## Startup and shutdown deadlines

Optional `create` parameters preserve existing call sites:

| Option | Default | Meaning |
| --- | --- | --- |
| `download_timeout` | 120 seconds | Cold-cache provisioning, including waiting for the install lock |
| `init_timeout` | 30 seconds | Deadline for spawn and protocol initialization **after provisioning** |
| `shutdown_timeout` | 1 second | Deadline for each driver shutdown phase |
| `max_event_tasks` | 1024 | Queued + active callback invocation limit |
| `on_event_error` | stderr | Session-local handler/decoder error reporter |

Timeouts must be finite and positive. The startup timeout includes scheduling
the supervisor and awaiting `Root.initialize`. Process exit is observed
independently of stdout EOF. Failed or canceled creation closes/joins its own
resources before re-raising the original exception and backtrace; it does not
leave an abandoned daemon or affect another session.

On explicit close the reader and callback tasks stop, stdin closes to request
a graceful driver exit, and late stdout is drained. Shutdown waits at most one
phase, then escalates. On Unix this sends TERM and waits another phase, then
sends KILL and waits a final phase. On Windows it terminates the driver's job
object, which also contains its child processes; Unix signals are not used.
Normally this is at most `3 * shutdown_timeout` plus cooperative task cleanup
and scheduling. Secondary cleanup errors are diagnosed, not substituted for
the primary initialization/connection failure.

Switch cancellation may cause the process owner to kill/reap the process
earlier rather than wait through the graceful path. Its private process switch
is the final kill/reap safety net: Eio.Process on Unix, or the library's own
process/job/overlapped-pipe adapter on Windows. Userspace cannot impose an
absolute deadline on kernel reaping of a process stuck in uninterruptible sleep; similarly it
cannot forcibly terminate uncooperative OCaml callback code. These are not
claimed to be hard real-time deadlines.

Cold provisioning runs **before** `init_timeout`, with its own
`download_timeout`. It remains automatic on every cache miss. HTTPS uses the
system CA trust store; the tar/gzip archive is extracted without invoking a
shell or external downloader. Installs are serialized between fibers/processes,
validated against the pinned version, and published by renaming a staging
directory. Failed or canceled installs clean up their staging directory without
publishing a partial cache. A cache hit needs neither network access nor TLS
initialization. These are cooperative deadlines: filesystem operations,
platform process creation and cancellation-protected cleanup may take additional
time. The timeout is not a hard real-time bound.

Node.js and browser executables are still separate runtime prerequisites. See
[Windows and cross-compilation](windows.md) for cache locations and deployment.

## Compatibility and testing

The public `create`, `destroy`, handler and waiter call shapes remain valid.
Observable changes are deliberate: handlers can overlap; errors are reported
rather than swallowed; waits clean up and propagate predicate errors; dead
sessions reject; overflow closes; and callbacks do not synchronously join
destroy. The accidental public `instances` global has been removed. Exposed
`Connection` record internals changed; `Internal.connection` exists for
handwritten integration and diagnostics, not as a stable representation API.

The exposed low-level `Driver` API has changed: `download ~env ?timeout ()`
requires an Eio environment, and `run ~sw ~env ?dir ()` returns a library-owned
process rather than an `Eio.Process.t`. Use `Driver.stdin`, `Driver.stdout`,
`Driver.await` and `Driver.shutdown` instead of accessing Eio process resources.
The old `~process_mgr` and optional redirection/environment arguments to `run`
are no longer supported. High-level `create ~env ~sw ()` calls remain valid.

Tests use newly built Dune executables, never the preloaded library in a
persistent REPL. See [regression instructions](../test/critical/README.md).
