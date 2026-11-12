# Scope: what the library covers, and how it relates to Playwright

Version 0.2.0 of the library drives **Playwright 1.65.0**. This document says what the
library takes on and what it leaves alone, and, for those who know Playwright from Node.js,
Python, Java or .NET, how its interface reads in OCaml and where the behaviour differs. The
[user guide](guide.md) teaches the library from the start; the reference is the documentation
of the module `Playwright`, built with `dune build @doc`.

- [The rule](#the-rule)
- [How Playwright's interface reads in OCaml](#how-playwrights-interface-reads-in-ocaml)
- [Where the behaviour differs](#where-the-behaviour-differs)
- [What is left out](#what-is-left-out)
- [Reaching what is left out](#reaching-what-is-left-out)
- [How this is kept true](#how-this-is-kept-true)

## The rule

**The library binds Playwright's protocol. It is not a port of Playwright's client for
Node.js.**

The work is done by Playwright's driver: it launches browsers, finds elements, waits for
them, retries assertions, records traces. A client tells the driver what to do, over a
protocol that Playwright publishes with every version. On top of that, the clients for
Node.js and Python have a layer of conveniences made for their languages: options that read
and write files, several names for one operation, shortcuts that hide a step. This library
has the protocol and not that layer.

What it adds to the protocol is what a program in OCaml needs in order to use it:

- **Types.** An object of the driver is a value of an abstract type, an option is a labelled
  argument, an enumeration is a variant, and an event gives its listener the type of what it
  carries.
- **Lifetimes.** What was opened is closed: when the program says so, when a fiber is
  cancelled half way, when the driver dies. Whatever is set up for later returns a
  `Disposable.t`.
- **Events.** Listeners that may block and call back into the library, and `expect_event`,
  which waits for an event around the action that causes it.
- **Errors.** One exception, with the driver's message and its log of the call.

What it holds back from:

- **Values in, values out.** A function takes its input as a value and returns its result as
  one. The library opens no files; a path is given only for what the driver itself reads or
  writes: uploads, downloads, videos, traces, profile directories.
- **One way to do a thing.** No aliases, and no second function that differs from the first
  by a default.
- **No guessing.** A body is sent as it was given. Nothing chooses a serialisation or a
  content type by looking at headers or at the shape of a value: JSON is sent by saying
  `~json`.
- **Owners are named.** No object is created behind another one. The program that makes a
  context is the one that closes it.
- **No standards rebuilt for a convenience.** URL patterns are compiled by the driver, whose
  syntax they are; nothing here parses or normalises URLs the way a browser does.
- **Nothing that Playwright has given up.** What Playwright deprecates or discourages is not
  bound.
- **Installing is a step of its own.** A program that starts a driver never downloads one.
- **State for a reason.** The library keeps state on its side only where the protocol or a
  lifetime requires it: the objects that the driver has announced, the handlers it will ask
  for, the timeouts that go out with each call.

So a *capability* of the browser that is missing here is a gap, to be filled when someone
needs it: the layer that speaks the protocol is generated and has every command, and a
binding on top of it is a few lines. A *convenience* that is missing is missing on purpose.

## How Playwright's interface reads in OCaml

The conventions are in the guide, under
[How the API maps to OCaml](guide.md#how-the-api-maps-to-ocaml): a class is a module, a
method is a function that takes the object last, options are labelled arguments, enumerations
are variants, events are constructors, and promises are calls that block a fiber. What the
conventions do not tell:

| Playwright | Here |
| --- | --- |
| `playwright.chromium`, `playwright.devices`, `playwright.request`, `playwright.selectors` | `Playwright.chromium pw`, `Playwright.device "iPhone 15" pw`, `APIRequest.new_context pw`, `Selectors.register name script pw`, for a driver `pw` from `Playwright.run` or `Playwright.create` |
| A property that is an object: `page.keyboard`, `context.tracing` | A function: `Page.keyboard page`, `BrowserContext.tracing context` |
| `page.clock.install()`, `context.clock.runFor(ms)` | `Clock.install context`, `Clock.run_for ms context` |
| `x.off('event', f)`, `removeAllListeners`, `await using` | `Disposable.dispose` of what `on` returned |
| `AbortSignal`, the option `signal` | Cancellation of the fiber: `Eio.Cancel`, `Eio.Time.with_timeout`, a switch that is turned off |
| Comparing objects with `===` | `Page.equal`, `Frame.equal`, …; every module of objects of the browser also has `compare` and `hash`, and so goes into `Set.Make` and `Hashtbl.Make` |
| `expect(locator).not.toBeVisible()` | `Expect.Not.to_be_visible locator` |
| `expect(locator).toHaveText([…])`, `toContainText([…])` | `Expect.to_have_texts`, `Expect.to_contain_texts` |
| `expect(locator).toHaveAttribute(name)` | `Expect.to_have_attribute_present name` |
| `expect.configure({ timeout })` | `Expect.set_default_timeout ms pw` |
| `Promise.all([page.waitForEvent('popup'), action()])`; `with page.expect_popup()` | `Page.expect_event Page.Popup action page` |
| `page.waitForRequest(urlOrPredicate)` | `Page.expect_request ?url ?predicate action page` |
| `page.route(url, handler)` with a regular expression or a predicate | `Page.route_matching predicate handler page`; there are no regular expressions for URLs |
| `page.frame('name')`, `page.frame({ url })` | ``Page.frame (`Name "name") page``, ``Page.frame (`Url glob) page`` |
| `page.addScriptTag({ url })` | ``Page.add_script_tag (`Url url) page`` |
| `locator.locator(otherLocator)` | `Locator.within outer inner` |
| `locator.filter({ hasText: /…/ })` | `Locator.filter ~has_text_regex:"/…/"`: a JavaScript literal in a string |
| `locator.setInputFiles({ name, mimeType, buffer })` | `Locator.set_input_payloads` |
| `locator.toString()` | `Locator.to_string`; the selector alone is `Locator.selector` |
| `browser.on('disconnected')`, `browser.on('context')` | `Browser.on_disconnected`, `Browser.on_context` |
| `cdpSession.on(event, f)` | `CDPSession.on_event (fun name params -> …)`, for all events of the session |
| `context.newCDPSession(frame)` | `BrowserContext.new_cdp_session_for_frame` |
| `request.postDataBuffer()`, `response.body()` | `Request.post_data`, `Response.body`: strings hold bytes |
| `apiRequestContext.get(url, { data })` with an object | `APIRequestContext.get ~json url request`; `~data` is a body as it is |
| `TimeoutError`, `TargetClosedError` | `Playwright.Error` with the `kind` `Timeout` or `Target_closed` |
| `npx playwright install` | `ocaml-playwright install` |

## Where the behaviour differs

**Handlers and listeners**

- Each call of a listener or handler runs in a fiber of its own, so it may block and may call
  back into Playwright, and several are in progress at a time. How many, and how many more
  may wait, is bounded: 1024 in progress and 65536 waiting. When both are exhausted the
  connection is closed with an error rather than left to grow without limit.
- An exception that escapes from a listener goes to the function `~on_error` of
  `Playwright.run`, which prints it by default. Nothing else happens: there is no unhandled
  rejection that ends the process.
- A route handler that raises before it has settled its route **aborts the request**, and its
  exception goes to `~on_error`. Playwright for Node.js leaves such a request pending.
- A listener that was removed is not called any more, not even for events that had arrived
  before it was removed.
- `Tracing.start`, `Tracing.group` and `Page.add_locator_handler` return `unit` where
  Playwright returns a disposable; they have their counterparts `stop`, `group_end` and
  `remove_locator_handler`. `route_web_socket` returns a disposable where Playwright
  returns nothing.

**Waiting for events**

- `expect_event`, `Page.expect_request` and `Page.expect_response` take the action as a
  function. The timeout counts from before the action and limits when the event may arrive;
  the action is not interrupted, and when it fails, its failure is the one that is raised.
- A predicate is called for the events as they arrive, also while the action is running.

**Closing and cancelling**

- `close` of a driver, a browser, a context and a page can be called any number of times and
  from several fibers at once, and does its work even if the fiber that calls it is
  cancelled. It is therefore safe in `Fun.protect ~finally` and `Switch.on_release`.
- Cancelling a fiber cancels the call that it is blocked in. An object that was being created
  by such a call is closed again in the background.
- When the driver ends, by `Playwright.close`, by the end of its switch or by a crash of the
  process, every object says that it is closed, the `Close` and `on_disconnected` listeners are
  called, and the handlers that are still at work are cancelled.

**Values**

- `Js.t` is a tree. An object that the page reaches twice arrives twice, and a reference back
  into an object that contains it arrives as `Undefined`.
- `Js.int` refuses integers that a JavaScript number cannot hold exactly, beyond ±(2⁵³ − 1).
- `Js.to_json` converts what JSON can express and nothing else. For a value with an
  `undefined`, a date or a handle in it, it fails and says where that is.
- Regular expressions are passed on to the browser as their source, so their syntax is
  JavaScript's, not that of an OCaml library.

**Smaller things**

- `Page.video` is `None` unless the context records videos.
- `~http_credentials` is always a list, and `Client_certificate` values carry the bytes of
  the certificates.
- The driver is told that its client speaks Python. That is where the notation of selectors
  in error messages and call logs comes from: `get_by_role("button", name="Save")`.
- Traces show the calls of the library, but not the places in the OCaml source that made
  them. `Tracing.group ~location:__POS__` attaches one to a group.
- The driver is not bundled, and not downloaded behind the program's back.
  `ocaml-playwright install` and `Playwright.Driver.install` download the package
  `playwright-core` from the npm registry into the cache directory of the user, and the
  library runs it with the `node` it finds; see [Configuration](guide.md#configuration)
  for how to provide both differently.

## What is left out

By the rule above, and with what takes its place. The lists name what a reader is likely to
look for; they are not a ledger of Playwright's interface.

**Left to the program**

| Playwright | Instead |
| --- | --- |
| The `path` options that make the client read or write a file: `screenshot`, `pdf`, `storageState`, `addInitScript`, `addScriptTag`, `route.fulfill`, client certificates | The functions take and return the content: `Page.add_init_script source page`, `Page.screenshot page`. A file is one line of the program: `Eio.Path.save`, `Out_channel.with_open_bin`. |
| `request.postDataJSON()`, `response.text()` | `Request.post_data` and `Response.body` are strings; `Yojson.Safe.from_string` parses them. |
| `allHeaders()`, `headerValue()`, `headerValues()` | `headers` has lower-case names and merged values, for `List.assoc_opt`; `headers_array` has the headers as they went over the network. |
| `page.waitForEvent()`, `page.waitForRequest()`, the `expect_<event>` methods of Python | One function, `expect_event`, with the event as a value and `ignore` for no action; `Page.expect_request` and `Page.expect_response` match URLs. |
| `page.unroute(url)` | `Disposable.dispose` of what `route` returned, or `unroute_all`. |
| `browser.newPage()` | `BrowserContext.new_page (Browser.new_context browser)`, which says who owns the context. |
| `page.waitForTimeout()` | `Eio.Time.sleep`. |
| The option `logger`, the class `Logger` | `DEBUG=pw:api` makes the driver log to the standard error, see [Debugging](guide.md#debugging). |
| A function of the host language as the argument of `evaluate` | JavaScript source: the page runs JavaScript. `expose_function` makes an OCaml function callable from the page. |

**Given up by Playwright itself**

| Playwright | Instead |
| --- | --- |
| The operations by selector of `Page` and `Frame`: `page.click(selector)`, `page.$`, `page.$eval`, `page.waitForSelector` and the like | A `Locator` does each of them: `Locator.click (Page.locator selector page)`. |
| The operations of `ElementHandle` | A handle can be passed to JavaScript and asked for its frames; a `Locator` acts on elements. `locator.elementHandles()` is `Locator.all`. |
| `page.waitForNavigation()`, `page.type()`, `locator.type()` | `Page.wait_for_url`, `Locator.press_sequentially`. |
| `context.backgroundPages()`, the event `backgroundpage` | Nothing. |
| `context.setHTTPCredentials()` | Credentials are given when the context is created. |
| The option `noWaitAfter` | Only where Playwright still honours it: `click`, `press` and `add_locator_handler`. |
| The option `timeout` of `isVisible` and `isHidden` | Nothing: Playwright ignores it. |

**Not bound**

| Playwright | Instead |
| --- | --- |
| The test runner `@playwright/test`: fixtures, projects, reporters, `test.step`, retries | Any test framework of OCaml; `Expect` raises `Playwright.Error` with the kind `Assertion_failed`. |
| `expect.poll`, `expect.soft`, `expect(value)` for values | The assertions are those on locators, pages and API responses. |
| `toHaveScreenshot`, `toMatchSnapshot` | `Page.screenshot` and `Locator.screenshot` give the images. |
| `page.coverage` | Chromium's coverage through a `CDPSession`, see below. |
| `page.screencast` | Videos are recorded with `~record_video_dir`. |
| `context.credentials`, virtual WebAuthn authenticators | `BrowserContext.storage_state ~credentials:true` saves what a context holds; Chromium's authenticators through a `CDPSession`. |
| `context.debugger`, `page.webmcp` | Nothing. |
| `browser.startTracing`, `browser.stopTracing` | This is Chromium's own tracing, which a `CDPSession` reaches; Playwright's traces are covered by `Tracing`. |
| `download.createReadStream()` | `Download.path` or `Download.save_as`. |
| `tracing.start({ sources })` | The library collects no call stacks, so there are no sources to put into a trace. `Tracing.group ~location` names a place in the source. |
| `routeFromHAR()`, the `recordHar` options, `tracing.startHar()` | `Page.route` with `Route.fulfill` mocks; traces record the network. |
| `browserType.connect()`, `browserType.launchServer()`, `BrowserServer`, `browser.bind()` | Browsers behind a Playwright server are not reached. `BrowserType.connect_over_cdp` reaches a remote Chromium. |
| `connectOverCDP` with a transport object | `BrowserType.connect_over_cdp` takes an endpoint. |
| Android, Electron | Nothing. |

## Reaching what is left out

- **Anything a page can do** is JavaScript away: `Page.evaluate`, and `Page.evaluate_handle`
  for what cannot be copied out of the page.
- **Anything Chromium can do** is in its DevTools protocol, which a `CDPSession` speaks.
  Coverage of JavaScript, for instance:

  ```ocaml
  let session = BrowserContext.new_cdp_session page context in
  ignore (CDPSession.send "Profiler.enable" session);
  ignore (CDPSession.send "Profiler.startPreciseCoverage" ~params:(`Assoc [ "detailed", `Bool true ]) session);
  ignore (Page.goto "https://example.com" page);
  let coverage = CDPSession.send "Profiler.takePreciseCoverage" session in
  CDPSession.detach session;
  coverage
  ```

- **Playwright's command line tools** (`codegen`, `show-trace`, `install`, `open`) are those
  of the driver: `ocaml-playwright` on the command line, `Playwright.Driver.command` and
  `Playwright.Driver.run` from a program.
- **A command of the protocol that has no function here** needs one to be written, since the
  layer below the public interface is private to the package.
  [dev/protocol-coverage.md](dev/protocol-coverage.md) lists the commands that the library
  does not send, and [dev/architecture.md](dev/architecture.md#where-things-go) says where
  a new function goes. Ask for it, or send it.

## How this is kept true

- The protocol between the library and the driver is generated from the description that
  Playwright publishes with each version. [dev/protocol-coverage.md](dev/protocol-coverage.md)
  is generated with it: an inventory of the commands and events of the protocol that the
  library does not use. `dune runtest` fails when that file is out of date, so an update of
  Playwright shows what it added.
- [dev/protocol.md](dev/protocol.md) describes how the library is moved to a new version of
  Playwright, and how the rule above decides what is done with the additions.
- The code in this document, in the guide and in the reference is compiled by `dune runtest`.
