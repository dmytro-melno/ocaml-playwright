# Architecture

This document is for people who work on the library. It explains how the code is organised
and why, and states the rules that the code relies on, so that changes land in the right
place and keep them. Users of the library want the [guide](../guide.md) instead.

## The big picture

Playwright consists of a *driver*, a Node.js program that controls browsers, and *clients*
that tell the driver what to do. The official clients are those for Node.js, Python, Java
and .NET; this library is another one. Client and driver exchange JSON messages over the
standard input and output of the driver process. The protocol is described by YAML files in
the Playwright repository, from which every client generates code.

```
   your program
        │  Playwright.Page.click ...
┌───────▼──────────────────────────────────────────────┐
│ playwright.mli / playwright.ml   the public face     │  library playwright
├──────────────────────────────────────────────────────┤
│ instance.ml      a driver and its connection         │  library playwright_internal
│ client objects   page.ml, frame.ml, locator.ml, ...  │
│                  types.ml: their data                │
├──────────────────────────────────────────────────────┤
│ protocol.ml      generated: typed commands, events   │
│ channel.ml       objects of a known interface        │
├──────────────────────────────────────────────────────┤
│ connection.ml    objects, calls, replies, events,    │
│                  the fibers that serve them          │
│ transport.ml     framing of messages                 │
│ driver_process.ml, driver.ml   the Node.js process   │
└───────┬──────────────────────────────────────────────┘
        │  pipes
   node cli.js run-driver  ──►  browsers
```

Each layer uses only the layers below it. There are two dune libraries in `lib/`. The one
that applications depend on, `playwright`, is a single module: `playwright.ml`, the facade.
Everything else is in `playwright_internal`, which is private to the package: dune installs
it for the facade to link against, but nothing outside this project can name it. The unit
tests, which are inside, are written against it; the browser tests use the public
interface only.

## Layers

### Wire: `json.ml`, `transport.ml`

`Json` is a thin layer over Yojson: builders for objects with optional fields, and decoders
that raise `Json.Decode_error` with a path to the offending value. The generated code uses
nothing else to read and write messages.

`Transport` frames messages: each is a 4-byte little-endian length followed by JSON. A
transport is a pair of functions, `send` and `receive`, so that tests can substitute an
in-memory one.

### The driver: `driver.ml`, `driver_process.ml`

`Driver` finds Node.js and the driver's package, and installs the package if it is missing:
a small Node.js script downloads the tarball from the npm registry, checks its SHA-512
against the digest compiled into the library, and unpacks it into a scratch directory, which
is then renamed into place, so that concurrent and interrupted installations do no harm.
Node.js is required anyway, and using it here is what keeps HTTP, TLS and tar libraries out
of the dependencies. The installation is a child process that is polled, not waited for: it
is killed when it takes longer than its time limit, or when the fiber that asked for it is
cancelled. `Driver.locate` blocks, so `Instance` calls it in a system thread
(`Fibers.in_systhread`), which is what lets it be cancelled.

`Driver_process` runs the driver and exposes its pipes as a `Transport`. It has two
implementations behind one record of functions. *Native* uses `Eio.Process`. *Threads* uses
`Unix.create_process` and two system threads, one reading and one writing, which hand data
to fibers through an `Eio.Stream` and promises; it exists because Eio does not implement
processes and non-blocking pipes on Windows, and it is selected there. See
[windows.md](windows.md).

The driver does not inherit the program's standard error. Node.js makes the pipes that it
is given non-blocking, which is a property of the open file and not of the descriptor: the
program's own writes to standard error would start to fail. So the driver gets a pipe of
its own, and a system thread copies what comes out of it to standard error
(`Driver_process.Errors`).

Stopping the driver closes its standard input, which makes it exit and take its browsers
along; if it has not gone after a grace period, it is killed. Stopping is not interrupted
by cancellation, takes a bounded time, and is registered with the switch that the driver
was started under: no path leaves a driver behind.

### The connection: `connection.ml`

The driver owns a tree of objects, each with a GUID and a type (`Page`, `Frame`, ...). It
announces a new object with `__create__`, retires one, with its subtree, with `__dispose__`,
and moves one with `__adopt__`. `Connection` mirrors that tree as `channel` values. It knows
nothing about what the objects mean. It provides:

- `call`: sends a command to an object and blocks the calling fiber until the reply
  arrives. What happens when that fiber is cancelled is the subject of *Cancellation*
  below.
- three hooks per channel: `impl`, the client object, of the extensible type
  `Connection.impl`, which the connection's `factory` makes when the driver announces the
  object; `on_event`, which is given the events of the object; and `on_lost`, which is
  called when the connection ends while the object exists.
- the fibers in which everything runs that is not a call of the application: see
  *Who runs what*.
- `close`, the one way in which a connection ends: see *Lifetimes*.
- `with_timeout`, the client-side timeout for what the driver does not time.

Two fibers serve a connection, a reader and a writer. **The reader applies every message
itself, in the order of arrival: it creates and disposes the objects, settles the replies
and runs the `on_event` hooks.** This is the central rule of the design: because one fiber
brings the client's state up to date, that state is always consistent with what the driver
has said so far, without locks. The price is that hooks must not block. Whatever might block
(user code, commands sent in reaction to an event) is given a fiber of its own.

A reply is decoded by the reader too, before its command counts as answered. A message that
cannot be decoded, refers to an unknown object, or makes a hook raise means that the two
sides no longer agree, and ends the connection with a protocol error.

### Typed channels: `channel.ml`

`Connection.channel` is an object of whatever interface. The layers above work with
`'kind Channel.t`, an object of a known one: `[ `Frame ] Channel.t`, or
`[ `Js_handle | `Element_handle ] Channel.t` for an interface that extends another. The type
parameter is a phantom, and `Channel.t` is abstract, so a channel gets its interface in
checked ways only: from a reference in a message (`Channel.of_json`), or from the name that
the driver announced the object with (`Channel.of_any`). Both take a `'kind Channel.kind`,
and the only values of that type are the generated ones of `Protocol.Kind`. A reference to
an object of another interface than the protocol says is a protocol failure, like any other
message that cannot be decoded.

### The protocol: `protocol.ml`

Generated by `tools/gen_protocol` from `protocol/spec/*.yml`, and checked in. For every
type of object it has a module with:

- the type `t` of its channels, `kind Channel.t`;
- a function per command, with labelled arguments for the parameters and a record for the
  result: `Protocol.Frame.goto ?timeout ~url ?wait_until ?referer channel`. The receiver is
  a `[> kind ] Channel.t`: a frame command takes a frame, and a command of `JSHandle` takes
  an element handle too. Objects in parameters and results are typed in the same way;
- a variant `event`, and `listen`, which has the events of a channel handled;
- the record `Initializer.t`, the data that comes with `__create__`, and `initializer_`,
  which reads it from a channel.

Structures and enumerations of the protocol become records and polymorphic variants. Nothing
of this layer appears in the public interface.

What the types do for an update of Playwright, and what they do not:

| A new version of the protocol | Shows as |
| --- | --- |
| removes or renames a command, a parameter, a field of a result or an initializer, a value of an enumeration that the client uses; makes a parameter required | a type error where it is used |
| adds an interface | a match that is not exhaustive in `objects.ml` (`Protocol.Object.of_channel` has a constructor per interface) |
| adds an event to an interface whose events are handled | a match that is not exhaustive in the `handle_event` of its module |
| adds a command, or an interface that is not generated | a change of the generated [protocol-coverage.md](protocol-coverage.md) |
| adds an optional parameter to a command in use, a field to a result, a value to an enumeration that is only sent | nothing: only the diff of `protocol.ml` tells |
| changes what a command does without changing its shape | nothing: the release notes, the official client and the tests tell |

See [protocol.md](protocol.md) for the procedure.

### Client objects: `types.ml`, `ownership.ml` and one module per object

Playwright's objects refer to each other in cycles: a page has frames, a frame has a page, a
request has a frame and a response, and so on. So the *data* of all objects is defined in
one recursive group of records in `types.ml`, and the *behaviour* is in one module per
object. Field names are unique across `types.ml`, hence the prefixes.

The behaviour modules are not recursive. They form a chain, roughly `Js`, `Js_handle`,
`Frame`, `Element_handle`, `Locator`, `Network`, `Tracing`, `Worker`, `Api_request`,
`Expect`, `Route`, `Browser_context`, `Browser`, `Browser_type`, `Page`, `Objects`,
`Instance`, and a module can call the functions of those before it only. That is
less of a restriction than it looks, because a module can *read* the record of any object:
a frame finds its page, the page's context and the context's timeouts without calling
anybody. Where a module early in the chain depends on what a later one
learns, the dependence goes through data too: `Frame` and `Network` end their waits when
the page goes away by listening to `page.pe_close` and awaiting `page.p_gone`, which `Page`
fires and resolves. What pages and frames have in common is written once, in the functor
`Frame.Operations`, which `Page` applies to its main frame.

`objects.ml` is the factory: when the connection reports a new channel, it calls the
`create` function of the module for its interface, which builds the record, has the events
of the channel handled (`Protocol.Page.listen channel (handle_event page)`) and says what
to do when the object is lost (`Channel.on_lost`); the record becomes the channel's `impl`.
A handler updates the record and emits a client event if there is one. Since every object of
an interface that has a client side gets it there, before anything can refer to the object,
the functions that lead from a channel to its client object (`Types.page`, `Types.frame`,
...) cannot fail.

Every module can read every field of every record. Writing is restricted, by convention:

- A mutable field is written by the module of its record: `page.closed` by `Page`,
  `request.failure` by `Network.Request`. A module that has something to tell another
  object calls a function of that object's module (`Network.Request.did_fail`,
  `Tracing.set_traces_dir`).
- The fields that tie two objects together (`context.pages` and `page.context`,
  `page.frames` and `frame.page`, ...) are written by `Ownership` only. The two ends of such
  a tie hear of a change through different events, in different modules; `Ownership` is
  where they are kept in step.
- An emitter is fired by the module that hears of the event from the driver. That is not
  always the module of the record that holds the emitter: the driver reports the network
  activity, the console messages and the dialogs of a page to its context, and the load
  events to its main frame. In the other direction, what a page or a frame hears of
  (closing, loading, downloads, frames coming and going) is also emitted on the context
  (`ce_page_close`, `ce_frame_navigated`, ...), by `Page` and `Frame`. `types.ml` says which
  emitters those are.

State that belongs to no object is in the `session` record: the connection, the local
utilities of the driver, the selector settings and the default
timeout of assertions (`session.assertions`). There are no global variables other than the
counter in `serial.ml`.

The supporting modules:

| Module | Purpose |
| --- | --- |
| `Emitter` | Typed event sources: see *Events*. |
| `Waiter`, `Events` | Waiting for an event, around the action that causes it: see *Events*. |
| `Closing` | How far the closing of an object has got: see *Lifetimes*. |
| `Disposable` | What a registration returns, to take it back with: a function that is called at most once. |
| `Timeouts` | Default timeouts, inherited from context to page. |
| `Js` | Encoding and decoding of JavaScript values. |
| `Selector` | Builds the selectors behind `get_by_role` and the other locator functions. |
| `Url_match` | Which URLs are meant: a glob or a predicate. The driver makes a regular expression of a glob (`LocalUtils.globToRegex`), resolving it against the base URL as it does for itself, and `Re` runs it. Nothing of Playwright's `urlMatch.ts` is repeated here. |
| `Local_utils` | The utilities of the driver (archives of traces). |
| `Files` | The paths that are handed to the driver: made absolute, and told apart as files and directories (in a system thread). The library opens no file; the driver reads and writes them. |
| `Fibers` | `first` for operations that can fail; `in_systhread` for blocking work that must end when its fiber is cancelled; `is_cancellation`. |
| `Serial` | Numbers that tell the objects of the process apart: see *Identity*. |
| `Context_options`, `Screenshot`, `Cookie` | Conversion of options into protocol records. |
| `Route` | Routing of requests and WebSockets: see *Route handlers*. |
| `Expect` | Assertions, on top of the `expect` command of frames. |

### The facade: `playwright.ml`, `playwright.mli`

`playwright.mli` is the public interface and the reference documentation. `playwright.ml`
assembles the modules of the implementation and restricts them to that interface; it has no
logic of its own. Starting and stopping a driver, which belongs to no object, is in
`instance.ml`.

The types of the objects refer to one another: a page has frames, a frame has a page. The
interface therefore declares the modules of the objects, and `Js`, as one recursive group,
`module rec Js : sig ... end and BrowserType : sig ... end and ...`, in which each module
declares its own type `t` and names the others' as `Page.t`, `Frame.t`. There is no other
name for these types. The implementation is not recursive: its modules are those of the
private library, whose types are all defined in `types.ml`. What takes a driver and returns
an object (`chromium`, `APIRequest`) can only be declared after the group, as can `Expect`,
`Clock` and `Selectors`, which need not be part of it.

Signatures that several modules share are stated once, before the group: `Identity`
(`equal`, `compare`, `hash`, in every object module), `Locator_queries` (the `get_by_*`
family) and `Frame_operations` (what pages and frames have in common). Since they come
before the types that they mention, they take these as parameters: `type locator`,
`type js_value` and so on, which the modules substitute, as in
`include Locator_queries with type t := t and type locator := Locator.t`. The two long lists
of options that several functions accept are type abbreviations, `'a with_context_options`
and `'a with_launch_options`.

OCaml wants every type and module type that an interface defines to be defined by the
implementation too. `playwright.ml` therefore begins with a second statement of the value
types, the two abbreviations and the three shared signatures, without their documentation;
the compiler checks that they agree with the interface, the order of optional arguments
included. Keeping them in a third file for both to refer to would not remove the need: the
shared signatures mention the value types, so these would have to move there as well, and
the interface would no longer be readable on its own. `Expect.Assertions` is not restated:
it is `module type of` what the functor in `expect.ml` returns, which is why that functor
keeps its helpers in an `open struct`.

The conventions of the interface (the object comes last, required arguments are positional,
options are labelled, timeouts are milliseconds, events are a GADT, a registration returns
a `Disposable.t`) are stated at the top of `playwright.mli`, and [parity.md](../parity.md)
says how they map to Playwright's. A new function follows them.

### Identity

Every object module has `equal`, `compare` and `hash`. For an object of the driver they are
those of its channel, `Channel.equal` and so on, which rest on the `serial` number that a
channel is given when it is created (`serial.ml`). A guid would not do: it is unique within
its connection only, and the browser types of two drivers have the same one. Console
messages and web errors are not objects of the driver and carry a serial number of their
own; locators are compared by frame and selector, API responses by context and fetch id.
Inside the library, records are compared with `==` or these functions, never with the
polymorphic `=`, which would walk the cycles between them.

## Life of a call

`Locator.click locator`:

1. `Locator.click` turns its options into a call of `Protocol.Frame.click` on the frame's
   channel with the locator's selector and `strict:true`, with the timeout taken from
   `Timeouts`.
2. The generated function builds the JSON parameters and calls `Connection.call`, which
   assigns an id, queues the message for the writer, and waits on a promise.
3. The driver finds the element, waits for it to be actionable, clicks, and replies.
4. The reader decodes the result with the function that the generated code gave to `call`,
   here to nothing, and resolves the promise; or `Connection.call` raises the error that
   the driver sent, converted by `Error.of_wire` into a `Playwright.Error` with its kind and
   call log.

Events travel the other way. When the click opens a popup, the driver sends `__create__`
for a page, on which `objects.ml` creates the client object, and later the event `page` to
the context. The context's hook finds the page object in the channel's `impl`, has
`Ownership` put it among the context's pages and emits `Page` on the context's emitter and
`Popup` on the opener's; for each listener registered with `Page.on` a handler call is
started, and a fiber blocked in `Page.expect_popup` is given the page to examine.

## Who runs what

There are no locks, and the library must be used from one domain per driver. What keeps
the state consistent is which fiber does what:

| What | Where it runs | Rules |
| --- | --- | --- |
| Applying a message: creating and disposing objects, settling replies, `on_event` hooks, internal listeners (`Emitter.subscribe`), the collecting half of a `Waiter` | the reader of the connection | Must not block. An exception is a protocol failure and ends the connection; one from an internal listener is reported instead. |
| User code that an event calls: event listeners, route handlers, WebSocket route handlers, exposed functions, locator handlers | `Connection.handle`: a daemon fiber per call, in the scope of the instance | May block. Starts in the order of the events. Counted: see below. Exceptions go to `on_error`. Cancelled when the instance ends. |
| What the client does by itself in answer to an event: subscribing to events on demand, dismissing a dialog that nobody listens for, releasing the result of a cancelled command, reading a remote connection | `Connection.fork`: a daemon fiber in the same scope | Short, and no more of it than there are events, so not counted. Exceptions are reported. |
| The predicate of an `expect_*` or `wait_for_*` | a fiber of the waiting call (`Waiter.around`) | One event at a time, in the order of arrival, while the action runs. |
| Closing, disposing, cleaning up | `Connection.start` and what is built on it: a daemon fiber in the scope of the instance, for which the caller waits | Not interrupted when the caller is cancelled: see *Cancellation*. |
| Blocking system calls: looking at paths, installing the driver, the pipes of the thread-based driver process, the driver's standard error | system threads (`Files.partition_directories`, `Fibers.in_systhread`, `Driver_process`) | Hand their results to fibers; touch no client state. |

Code that reads and then writes client state outside the reader does so without yielding in
between.

*The scope of the instance* is a switch that `Connection.run` opens for the connection to
the driver and that lasts as long as that connection runs. Everything in it
is a daemon fiber: nothing in it keeps the instance alive, and all of it is cancelled when
the instance ends.

### The budget of handlers

The reader cannot wait for user code, so events arrive at the pace of the browser: a page
that logs ten thousand lines calls a console listener ten thousand times before the first
reply to anything those calls ask can be read. `Connection.handle` keeps that within two
bounds, which `Playwright.create` takes as `handler_concurrency` and `handler_backlog`:

- no more than `handler_concurrency` calls are in progress; the others wait in a queue,
  which costs a closure each, and are started in order as calls end;
- when more than `handler_backlog` wait, handlers are not keeping up or not returning. The
  connection is closed with an error that says so, which is also reported. No call is ever
  dropped while the instance lives.

Everything that calls user code because of an event goes through `handle`, so that the
bounds hold for the instance as a whole. Use `fork` only for work whose amount and duration
the library controls.

## Events

`Emitter` is a typed event source. `Emitter.on` and `once` add a listener of the
application, each call of which is a handler call; `subscribe` adds an internal one, which
runs inline in the reader. All three return the function that removes the listener. There
is no `off`: functions cannot be compared, so a listener is removed by what its
registration returned, which the facade wraps in a `Disposable.t`. The rules, all of which
have tests in `test/unit/test_events.ml`:

- `emit` calls the listeners in the order of their registration, and returns whether there
  was one (which is how a dialog that nobody handles gets dismissed).
- A listener that is added during an emission is not called for it. One that is removed is
  not called any more, also not for events that were emitted before and whose calls are
  still waiting for their turn.
- Adding, removing and emitting take constant time per listener.
- `set_watch` tells when the first listener arrives and the last one leaves.
  `Events.subscribe_on_demand` uses it for the events that the driver reports only on
  request (console messages, dialogs, requests, ...): the subscription is updated in a
  forked fiber, because a listener can be added where blocking is not allowed, and because
  nobody is there to handle a failure of it.

In the public interface the events of an object are a GADT, `type _ event = Close : t event
| Console : ConsoleMessage.t event | ...`, defined in the object's module next to the
function `emitter` that maps a constructor to its emitter. `on`, `once`, `expect_event` and
`wait_for_event` are written once in terms of it.

`Waiter` is what waiting for an event is built on, and `Events.expect` is its common use:
listen, run the action, return the first event that the predicate accepts.

- A waiter collects from the moment it is created, in the reader, so that nothing is missed
  between starting the action and waiting for its effect.
- The predicate is user code and may block, so it is not run in the reader: `Waiter.around`
  examines what was collected in a fiber of its own, one event at a time, as the events
  arrive and while the action is under way.
- The timeout counts from before the action and is on the *arrival* of the event. Neither
  the action nor the predicate is interrupted when the time is up; the failure is raised
  once the action is over, and a failure of the action itself takes precedence.
- `reject_on` makes the wait fail early, typically when the page closes or crashes.
- Events that arrive faster than they are examined are kept up to `handler_backlog`; beyond
  that the wait fails.

### Route handlers

A route arrives as an event of the page or the context, whose hook starts one handler call
(`handle "route"`) that offers the route to the handlers in order: those of the page before
those of the context, the most recently added first (`Route.Handler.dispatch`). What a
handler does with the route settles a promise, `route.handling`: `true` when the request was
fulfilled, continued or aborted, `false` when the handler fell back, on which the next
handler is tried. `Route.Handler` holds the rest of the policy:

- `run` counts the calls of a handler that are in progress (`rh_running`), which is what
  `unroute ~behavior:`Wait` waits for (`rh_idle`);
- `failed`: a handler that raises has not said what should become of the request. The
  request is aborted and the exception reported, since letting through what the handler may
  have been there to block is the wrong guess. Nothing is reported when the page is gone,
  and a handler that was removed with `` `Ignore_errors `` (`rh_quiet`) falls back in
  silence.

The driver is told which URLs to intercept (`Url_match.interception_patterns`); whether a
handler matches is then decided on the client, since a predicate can only run here: for a
glob, with the regular expression that the driver made of it when the handler was
registered. The driver is not asked while an event is handled.

## Lifetimes

### The instance

`Instance.create` locates the driver, starts the process, and forks one daemon fiber that
serves the instance and also takes it down: it runs `Connection.run`, and when that returns,
for whatever reason, stops the driver. `Playwright.close` closes the connection, which is
immediate, and waits for that fiber to finish. The switch that the instance was created
under does the same when it finishes.

### The end of a connection

A connection ends exactly once, in `Connection.close conn error`, whatever the cause: the
program closing it, the driver going away, a failure of the transport, a protocol error,
handlers that do not keep up. `close` does not block and can be called from any fiber:

1. Every command in flight fails with `error`, and so does every later one.
2. Every object that still exists is told that it is lost (`on_lost`), children before
   their parents, in the order of their creation. This is where an object settles what the
   driver can no longer tell it: a page marks itself closed, resolves `p_gone` and emits
   `Close`; a browser emits `Disconnected`. So the close and disconnection events are
   delivered however the connection ended, and waits that depend on them end.
3. The tables are emptied: a closed connection retains nothing.

Then `Connection.run` returns, and with it the scope of the instance ends: the handlers that
are still running are cancelled, including those of the events of step 2, which get to run
until they first block. A handler that closes its own instance is cancelled at that point,
like the others.

### Closing an object: `closing.ml`

Closing a context, a browser or an API request context takes several commands. `Closing`
holds how far that has got, `Open`, `Closing` or `Closed`, and gives closing these
properties:

- it is carried out in the scope of the instance, so a caller that is cancelled stops
  waiting and the object is closed all the same: `close` is safe in `Fun.protect` and
  `Switch.on_release`;
- callers that ask while the object is being closed wait for the same close, and all see
  how it ended; closing what is closed does nothing;
- a close that failed leaves the object `Open`, to be closed again;
- an object whose connection, browser or context went away first counts as closed.

`BrowserContext.is_closed` is true from the moment closing starts; `Browser.is_connected`
is true until the browser is gone.

### Cancellation

A fiber can be cancelled wherever it blocks, and it blocks in `Connection.call`. The rules:

- **A cancelled command is aborted, if that is safe.** `call` sends `__abort__` for the
  command and re-raises. That is only a request: the driver may have carried the command
  out already.
- **What a cancelled command made is released.** If the reply arrives after all and holds
  an object that would have been the caller's (a page, a context, a handle, a stream), the
  `orphan` function that the generated code passes to `call` gives it back, in a forked
  fiber. The generator derives that function from the type of the result: its table
  `released_with` names the command that gives back each kind of object.
- **Commands that make a page, a context or a browser are not aborted.** The driver does
  not abort them cleanly, and can leave behind what it was making, out of anybody's reach.
  They are left to finish (`~abortable:false`), and their result is released when it
  arrives. Listeners for `Page` can therefore see a page that is closed right away. The
  generator's tables `aborted_safely`, `results_not_owned` and `released_specially` hold the
  policy and its exceptions.
- **Clean-up is not interrupted.** `Connection.start` runs a function in the scope of the
  instance and gives a promise of its outcome; a caller that waits for it and is cancelled
  only stops waiting. On top of it: `detached f` (run and wait), `cleanup what f` (never
  raises: "target closed" means that there was nothing left to release, anything else is
  reported), `protect ~finally f` (`Fun.protect` for a `finally` that talks to the driver)
  and `guard ~undo f` (undo if `f` fails or is cancelled, for the steps that follow the
  making of something). Use these, not `Fun.protect` and not `Eio.Cancel.protect`, for
  anything that sends a command while unwinding.
- **Cancellation is never swallowed.** A handler for exceptions that must not catch
  `Eio.Cancel.Cancelled` says `when not (Connection.is_cancellation ex)`; the cancelled
  caller of a close still gets `Cancelled`.

`test/unit/test_ownership.ml` scripts the driver's side of these cases, and
`test/integration/test_cancellation.ml` checks them against a browser.

### Registrations: `disposable.ml`

Whatever is registered (a listener, a route, an init script, an exposed function) returns a
`Disposable.t`. Disposing calls the undo function at most once, and does
not fail when the page or context went away first. For a registration that the driver
keeps, the undo is the `dispose` command of the driver's `Disposable` object
(`Disposable.of_channel`).

## Errors

`Error.t` is the single error type. Errors from the driver arrive as JSON and are classified
by name into `Timeout`, `Target_closed` and `Other`; `Assertion_failed` is produced by
`Expect`. `Invalid_argument` is raised for misuse that needs no browser to detect. Anything
else that escapes from the library is a bug.

Exceptions that have no caller to be raised in go to the `report` function of the
connection, with a word about where they come from. `Instance.reporter` builds it from the
`on_error` of the application: it is called in a handler of the exception, so that the
backtrace is available, it is not cancelled, and if it raises, both exceptions are printed
to standard error.

## Where things go

| To do this | Change this |
| --- | --- |
| Follow a new version of Playwright | [protocol.md](protocol.md) |
| Add a method that exists in Playwright | the object's module, then `playwright.mli` (and `playwright.ml` if the module is assembled there), a browser test, the guide if it is of general interest, [parity.md](../parity.md) if it differs from the original |
| Add an option to an existing method | the same; if the option list is shared (`with_context_options`, `Frame_operations`, ...), its definition in both `playwright.mli` and `playwright.ml`, in the same order |
| Add an event | a constructor of the `event` GADT in `playwright.mli` and in the object's module, a case in its `emitter`, an emitter in `types.ml`, the case in `handle_event` that fires it |
| Call user code because of an event | `Connection.handle`, never `fork` |
| Add a kind of object | a record in `types.ml`, a constructor of `Connection.impl`, a module with `create`, an arm in `objects.ml` (which the compiler asks for when the protocol has a new interface) |
| Have one object change another | a function in the module of the object that changes; `Ownership` if it is about who has whom |
| Add something that is closed in several steps | a `Closing.t` in its record, `Closing.close` in its `close`, `Closing.set_closed` where it hears that it is gone |
| Release something when an operation is over | `Connection.protect`, `guard` or `cleanup` |
| Read or write a local file | Do not: take or return the content, or give the driver the path (`Files.absolute`) |

Conventions of the code: four spaces of indentation, no formatter, long lines where they
read better than wrapped ones; comments say why, not what. There are no classes and no
object types: data is records, behaviour is functions in modules.
