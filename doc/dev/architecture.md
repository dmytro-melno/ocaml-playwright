# Architecture

This document is for people who work on the library. It explains how the code is organised
and why, so that changes land in the right place. Users of the library want the
[guide](../guide.md) instead.

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
│ playwright.mli / playwright.ml   the public face     │
├──────────────────────────────────────────────────────┤
│ client objects   page.ml, frame.ml, locator.ml, ...  │
│                  types.ml: their data                │
├──────────────────────────────────────────────────────┤
│ protocol.ml      generated: typed commands, events   │
├──────────────────────────────────────────────────────┤
│ connection.ml    objects, calls, replies, events     │
│ transport.ml     framing of messages                 │
│ driver_process.ml, driver.ml   the Node.js process   │
└───────┬──────────────────────────────────────────────┘
        │  pipes
   node cli.js run-driver  ──►  browsers
```

Each layer uses only the layers below it. The library is one dune library with one public
module, `Playwright`; the other modules are reachable as `Playwright__Connection` and so on,
which only the unit tests do.

## Layers

### Wire: `json.ml`, `transport.ml`

`Json` is a thin layer over Yojson: builders for objects with optional fields, and decoders
that raise `Json.Decode_error` with a path to the offending value. The generated code uses
nothing else to read and write messages.

`Transport` frames messages: each is a 4-byte little-endian length followed by JSON. A
transport is a pair of functions, `send` and `receive`, so that tests can substitute an
in-memory one, and so that a WebSocket tunnelled through the driver (see *Remote browsers*)
can be one too.

### The driver: `driver.ml`, `driver_process.ml`

`Driver` finds Node.js and the driver's package, and installs the package if it is missing:
a small Node.js script downloads the tarball from the npm registry, checks its SHA-512
against the digest compiled into the library, and unpacks it into a scratch directory, which
is then renamed into place, so that concurrent and interrupted installations do no harm.
Node.js is required anyway, and using it here is what keeps HTTP, TLS and tar
libraries out of the dependencies. `Driver.locate` blocks, so the facade calls it in a
system thread.

`Driver_process` runs the driver and exposes its pipes as a `Transport`. It has two
implementations behind one record of functions. *Native* uses `Eio.Process`. *Threads* uses
`Unix.create_process` and two system threads, one reading and one writing, which hand data
to fibers through an `Eio.Stream` and promises; it exists because Eio does not implement
processes and non-blocking pipes on Windows, and it is selected there. Stopping the driver
closes its standard input, which makes it exit and take its browsers along; if it has not
gone after a grace period, it is killed. See [windows.md](windows.md).

### The connection: `connection.ml`, `channel.ml`

The driver owns a tree of objects, each with a GUID and a type (`Page`, `Frame`, ...). It
announces a new object with `__create__`, retires one, with its subtree, with `__dispose__`,
and moves one with `__adopt__`. `Connection` mirrors that tree as `channel` values. It knows
nothing about what the objects mean. It provides:

- `call`: sends a command to an object and blocks the calling fiber until the reply
  arrives. If the fiber is cancelled meanwhile, the driver is asked to abort the command.
  If the connection closes, all pending calls fail with a `Target_closed` error.
- event delivery: every channel has an `on_event` hook.
- `fork`: runs something in a daemon fiber of the connection's switch, reporting exceptions
  through the `report` function instead of letting them take the switch down.
- `with_timeout`, the client-side timeout used for waiting on events.

Two fibers serve a connection, a reader and a writer. **The reader runs the `on_event`
hooks inline.** This is the central rule of the design: because one fiber applies all
events in the order of the protocol, the state of the client objects is always consistent
with what the driver has said so far, without locks. The price is that hooks must not
block. Whatever might block (user callbacks, commands sent in reaction to an event) is
forked.

A channel carries a field `impl` of the extensible type `Connection.impl`. The client object
of a channel is stored there, which lets the connection hand objects to upper layers
without knowing their types.

### The protocol: `protocol.ml`

Generated by `tools/gen_protocol` from `protocol/spec/*.yml`, and checked in. For every
type of object it has a module with:

- a function per command, with labelled arguments for the parameters and a record for the
  result: `Protocol.Frame.goto ?timeout ~url ?wait_until ?referer channel`;
- a variant `event` and its decoder;
- the record `Initializer.t`, the data that comes with `__create__`.

Structures and enumerations of the protocol become records and polymorphic variants. This
layer is the reason why an update of Playwright shows up as type errors exactly where the
client has to change. Nothing of it appears in the public interface. See
[protocol.md](protocol.md).

### Client objects: `types.ml` and one module per object

Playwright's objects refer to each other in cycles: a page has frames, a frame has a page, a
request has a frame and a response, and so on. So the *data* of all objects is defined in
one recursive group of records in `types.ml`, and the *behaviour* is in one module per
object, which may then call any other. Field names are unique across `types.ml`, hence the
prefixes.

`objects.ml` is the factory: when the connection reports a new channel, it calls the
`create` function of the matching module, which builds the record, stores it in the
channel's `impl` and installs the `on_event` hook. A hook decodes the event with the
generated decoder, updates the record, and emits a client event if there is one.

The supporting modules:

| Module | Purpose |
| --- | --- |
| `Emitter` | Typed event sources. Public listeners run in a fiber each, internal ones inline. An emitter can tell when it gains its first listener, for events that the driver sends on request only. |
| `Waiter` | Waiting for the first of several things: an event, a timeout, the page closing. Under `expect_event` and `wait_for_*`. |
| `Events` | `expect`: listen, run the action, return the event. |
| `Timeouts` | Default timeouts, inherited from context to page. |
| `Js` | Encoding and decoding of JavaScript values. |
| `Selector` | Builds the selectors behind `get_by_role` and the other locator functions. |
| `Url_match`, `Url_regex` | URL globs. The driver converts a glob to a regular expression, as for all clients; `Url_regex` implements the subset of regular expressions that this produces. |
| `Files` | Files to upload, and their transfer to a remote driver. |
| `Context_options`, `Screenshot`, `Cookie` | Conversion of options into protocol records. |
| `Route` | Routing of requests and WebSockets, HAR replay. |
| `Expect` | Assertions, on top of the `expect` command of frames. |
| `Json_pipe`, `Remote` | Remote browsers, see below. |

### The facade: `playwright.ml`, `playwright.mli`

`playwright.mli` is the public interface and the reference documentation. `playwright.ml`
assembles the modules, restricts them to that interface and holds the little that belongs
to no object: starting and stopping a driver.

The interface declares the object types first, as abstract types (`page`, `frame`, ...), and
then one module per object, so that modules can refer to each other's types in any order.
Signatures that several modules share are stated once: `Locator_queries` (the `get_by_*`
family), `Frame_operations` (what pages and frames have in common) and the option lists
`'a with_context_options`, `'a with_launch_options`, `'a with_screenshot_options`. These
are repeated in `playwright.ml`; the compiler checks that they agree.

## Life of a call

`Locator.click locator`:

1. `Locator.click` turns its options into a call of `Protocol.Frame.click` on the frame's
   channel with the locator's selector and `strict:true`, with the timeout taken from
   `Timeouts`.
2. The generated function builds the JSON parameters and calls `Connection.call`, which
   assigns an id, queues the message for the writer, and waits on a promise.
3. The driver finds the element, waits for it to be actionable, clicks, and replies.
4. The reader resolves the promise. The generated function decodes the result, here
   nothing, or `Connection.call` raises the error that the driver sent, converted by
   `Error.of_wire` into a `Playwright.Error` with its kind and call log.

Events travel the other way. When the click opens a popup, the driver sends `__create__`
for a page, on which `objects.ml` creates the client object, and later the event `page` to
the context. The context's hook finds the page object in the channel's `impl`, links it to
its opener and emits `Popup` on the opener's emitter; a listener registered with `Page.on`
is then run in a new fiber, and a fiber blocked in `Page.expect_popup` is woken.

## Concurrency

- Client state is changed by the reader fiber only, or by code that runs without yielding
  between reading and writing it. There are no locks, and the library must be used from one
  domain per driver.
- Listeners and route handlers run in daemon fibers forked from the connection's switch.
  They do not keep the switch alive. Their exceptions go to `on_error`.
- Functions that take an action and wait for an event (`expect_*`) register the listener
  before they run the action, in the same fiber, so the event cannot be missed.
- Closing: `Playwright.close` closes the connection, which fails pending calls, then stops
  the process. It is registered with the switch, protected from cancellation, and safe to
  call twice.

## Errors

`Error.t` is the single error type. Errors from the driver arrive as JSON and are classified
by name into `Timeout`, `Target_closed` and `Other`; `Assertion_failed` is produced by
`Expect`. `Invalid_argument` is raised for misuse that needs no browser to detect. Anything
else that escapes from the library is a bug.

## Remote browsers

`BrowserType.connect` asks the *local* driver to open a WebSocket to a Playwright server.
The driver hands back a `JsonPipe` object, through which messages of the same protocol are
sent to and received from the server. `Json_pipe` turns that into a `Transport`, and
`Remote` runs a second `Connection` over it, with a session marked `is_remote`. The client
objects are the same; the few places that deal with files (uploads, downloads, traces,
videos) check the flag and stream the content instead of passing paths.

## Where things go

| To do this | Change this |
| --- | --- |
| Follow a new version of Playwright | [protocol.md](protocol.md) |
| Add a method that exists in Playwright | the object's module, then `playwright.mli` and `playwright.ml`, a test, and the guide if it is of general interest |
| Add an option to an existing method | the same; if the option list is shared, its definition in both `playwright.mli` and `playwright.ml` |
| Add an event | the `event` GADT of the object in `playwright.mli` and `playwright.ml`, an emitter in `types.ml`, the hook in the object's module |
| Add a kind of object | a record in `types.ml`, a constructor of `Connection.impl`, a module, a line in `objects.ml` |

Conventions of the code: four spaces of indentation, no formatter, long lines where they
read better than wrapped ones; comments say why, not what.
