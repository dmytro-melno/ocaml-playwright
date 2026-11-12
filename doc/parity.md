# This library and Playwright, side by side

For those who know Playwright from Node.js, Python, Java or .NET: how its interface reads in
OCaml, where this library behaves differently on purpose, and what it does not cover.

It describes version 0.2.0 of the library, which drives **Playwright 1.65.0**. The
[user guide](guide.md) teaches the library from the start; the reference is the documentation
of the module `Playwright`, built with `dune build @doc`.

- [How the interface is translated](#how-the-interface-is-translated)
- [Members under another name](#members-under-another-name)
- [Where the behaviour differs](#where-the-behaviour-differs)
- [What is not covered](#what-is-not-covered)
- [How this is kept true](#how-this-is-kept-true)

## How the interface is translated

| Playwright | Here |
| --- | --- |
| A class: `Page`, `Locator`, `BrowserContext` | A module with a type `t`: `Page.t`, `Locator.t`, `BrowserContext.t`. The names of the modules are those of the classes. |
| A method: `page.waitForURL(url)` | A function that takes the object last: `Page.wait_for_url url page`. Chains are written with the pipe operator. |
| A property that is an object: `page.keyboard`, `context.tracing` | A function: `Page.keyboard page`, `BrowserContext.tracing context`. |
| An options object: `{ timeout: 500, force: true }` | Optional labelled arguments: `~timeout:500. ~force:true`. |
| A second required argument of the same type | A label: `WebStorage.set_item "theme" ~value:"dark" storage`. |
| A name that is a keyword of OCaml | A trailing underscore: `Keyboard.type_`, `Request.method_`, `Locator.and_`. |
| `async` functions and promises | Functions that block the calling fiber. Concurrency is a matter of [Eio](https://github.com/ocaml-multicore/eio) fibers. |
| `AbortSignal`, the option `signal` | Cancellation of the fiber: `Eio.Cancel`, `Eio.Time.with_timeout`, a switch that is turned off. |
| `string \| RegExp` | Two functions or two arguments: the plain one takes the string, the one named `..._regex` a JavaScript literal such as `"/^total: \\d+$/i"`. |
| A URL as `string \| RegExp \| (url) => boolean` | A glob pattern, or the function named `..._matching` with a predicate in OCaml. There are no regular expressions for URLs. |
| A union of other kinds | A polymorphic variant: `` `Content `` or `` `Url `` for a script tag, `` `Name `` or `` `Url `` for `Page.frame`, `` `Value ``, `` `Label `` or `` `Index `` for an option of a `<select>`. |
| An enumeration of strings: `'load'`, `'right'`, `'dark'` | Polymorphic variants: `` `Load ``, `` `Right ``, `` `Dark ``. ARIA roles too: `` `Button ``. |
| `T \| null` | `T option`. |
| `Buffer`, `bytes` | `string`. |
| A value that crosses into the page, and what comes back | `Js.t`, a variant that also has `undefined`, dates, bigints, typed arrays and handles. JSON that never was anything else, like the body of a response, is `Yojson.Safe.t`. |
| A function for the page: `page.evaluate(() => …)` | JavaScript source in a string, of an expression or of a function: `Page.evaluate "() => document.title" page`. |
| Milliseconds as numbers | Milliseconds as floats. `0.` means no timeout. |
| `TimeoutError`, `TargetClosedError`, `Error` | One exception, `Playwright.Error`, with a record whose `kind` is `Timeout`, `Target_closed`, `Assertion_failed` or `Other`. Misuse of a function raises `Invalid_argument`. |
| `x.on('event', f)` | `X.on X.Event f x`. The events of a module are the constructors of a GADT, which gives `f` its type. |
| `x.off('event', f)`, `removeAllListeners` | `Disposable.dispose` of what `on` returned. |
| `Disposable`, `await using` | `Disposable.t` and `Disposable.dispose`. Whatever is set up for later returns one: listeners, routes, init scripts, exposed functions. |
| `expect(locator).toBeVisible()` | `Expect.to_be_visible locator` |
| `expect(locator).not.toBeVisible()` | `Expect.Not.to_be_visible locator` |
| `playwright.chromium`, `playwright.devices`, `playwright.request`, `playwright.selectors` | `Playwright.chromium pw`, `Playwright.device "iPhone 15" pw`, `APIRequest.new_context pw`, `Selectors.register name script pw`, for a driver `pw` from `Playwright.run` or `Playwright.create`. |
| Comparing objects with `===` | `Page.equal`, `Frame.equal`, …; every such module also has `compare` and `hash`, and so goes into `Set.Make` and `Hashtbl.Make`. |

## Members under another name

| Playwright | Here |
| --- | --- |
| `page.waitForEvent('popup')` | `Page.expect_event Page.Popup ignore page` |
| `Promise.all([page.waitForEvent('popup'), action()])`; `with page.expect_popup()` | `Page.expect_event Page.Popup action page` |
| `page.waitForRequest(urlOrPredicate)` | `Page.expect_request ?url ?predicate action page` |
| `page.route(url, handler)` with a regular expression or a predicate | `Page.route_matching predicate handler page` |
| `page.unroute(url, handler)` | `Disposable.dispose` of what `Page.route` returned |
| `page.clock.install()`, `context.clock.runFor(ms)` | `Clock.install context`, `Clock.run_for ms context` |
| `page.frame('name')`, `page.frame({ url })` | ``Page.frame (`Name "name") page``, ``Page.frame (`Url glob) page`` |
| `page.addInitScript({ path })`, and every other `path` option that makes the client read or write a file: `screenshot`, `pdf`, `storageState`, `addScriptTag`, `route.fulfill`, client certificates | Not there. The functions take and return the content: `Page.add_init_script source page`, `Page.screenshot page`. Paths that the driver handles are there: uploads, downloads, videos, traces. |
| `page.addScriptTag({ url })` | ``Page.add_script_tag (`Url url) page`` |
| `locator.locator(otherLocator)` | `Locator.within outer inner` |
| `locator.filter({ hasText: /…/ })` | `Locator.filter ~has_text_regex:"/…/"` |
| `locator.setInputFiles({ name, mimeType, buffer })` | `Locator.set_input_payloads` |
| `locator.type(text)` | `Locator.press_sequentially text` |
| `locator.toString()` | `Locator.to_string`; the selector alone is `Locator.selector` |
| `expect(locator).toHaveText([…])`, `toContainText([…])` | `Expect.to_have_texts`, `Expect.to_contain_texts` |
| `expect(locator).toHaveAttribute(name)` | `Expect.to_have_attribute_present name` |
| `expect.configure({ timeout })` | `Expect.set_default_timeout ms pw` |
| `browser.on('disconnected')`, `browser.on('context')` | `Browser.on_disconnected`, `Browser.on_context` |
| `cdpSession.on(event, f)` | `CDPSession.on_event (fun name params -> …)`, for all events of the session |
| `context.newCDPSession(frame)` | `BrowserContext.new_cdp_session_for_frame` |
| `request.postDataBuffer()`, `response.body()` | `Request.post_data`, `Response.body`: strings hold bytes |
| `apiRequestContext.get(url, { data })` with an object | `APIRequestContext.get ~json url request`; `~data` is a body as it is |
| `npx playwright install` | `ocaml-playwright install` |

## Where the behaviour differs

**Handlers and listeners**

- Each call of a listener or handler runs in a fiber of its own, so it may block and may call
  back into Playwright, and several are in progress at a time. How many, and how many more
  may wait, is bounded: `~handler_concurrency` and `~handler_backlog` of `Playwright.run`.
  When both are exhausted the connection is closed with an error rather than left to grow
  without limit.
- An exception that escapes from a listener goes to the function `~on_error` of
  `Playwright.run`, which prints it by default. Nothing else happens: there is no unhandled
  rejection that ends the process.
- A route handler that raises before it has settled its route **aborts the request**, and its
  exception goes to `~on_error`. Playwright for Node.js leaves such a request pending.
- A listener that was removed is not called any more, not even for events that had arrived
  before it was removed.
- `Tracing.start`, `Tracing.group` and `Page.add_locator_handler` return
  `unit` where Playwright returns a disposable; they have their counterparts `stop`,
  `group_end` and `remove_locator_handler`. `route_web_socket` returns a
  disposable where Playwright returns nothing.

**Waiting for events**

- `expect_event` and the other `expect_...` functions take the action as a function. The
  timeout counts from before the action and limits when the event may arrive; the action is
  not interrupted, and when it fails, its failure is the one that is raised.
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
- Regular expressions are passed on to the browser as their source, so their syntax is
  JavaScript's, not that of an OCaml library.

**Smaller things**

- `Page.video` is `None` unless the context records videos, and `wait_for_selector` returns
  `None` when it waited for an element to go away.
- `~http_credentials` is always a list, and `Client_certificate` values carry the bytes of
  the certificates.
- The driver is told that its client speaks Python. That is where the notation of selectors
  in error messages and call logs comes from: `get_by_role("button", name="Save")`.
- Traces show the calls of the library, but not the places in the OCaml source that made
  them. `Tracing.group ~location:__POS__` attaches one to a group.
- The driver is not bundled. On first use the library downloads the package
  `playwright-core` from the npm registry into the cache directory of the user and runs it
  with the `node` it finds; see [Configuration](guide.md#configuration) for how to provide
  both in advance.

## What is not covered

| Playwright | Status |
| --- | --- |
| The test runner `@playwright/test`: fixtures, projects, reporters, `test.step`, retries | Not part of this library, which is the browser automation alone. Use it with any test framework; `Expect` raises `Playwright.Error` with the kind `Assertion_failed`. |
| `expect.poll`, `expect.soft`, `expect(value)` for values | Not there. The assertions are those on locators, pages and API responses. |
| `toHaveScreenshot`, `toMatchSnapshot` | Not there. `Page.screenshot` and `Locator.screenshot` give the images. |
| `page.coverage` | Not covered. Chromium's coverage can be driven through a `CDPSession`. |
| `page.screencast` | Not covered. Videos are recorded with `~record_video_dir`. |
| `context.credentials`, virtual WebAuthn authenticators | Not covered, except that `BrowserContext.storage_state ~credentials:true` saves what a context holds. |
| `context.debugger`, `page.webmcp` | Not covered. |
| `browser.startTracing`, `browser.stopTracing` | Not covered. This is Chromium's own tracing; Playwright's traces are covered by `Tracing`. |
| `download.createReadStream()` | Not there. Use `Download.path` or `Download.save_as`. |
| `tracing.start({ sources })` | Not covered: the library collects no call stacks, so there are no sources to put into a trace. `Tracing.group ~location` names a place in the source. |
| `routeFromHAR()`, the `recordHar` options, `tracing.startHar()` | Not covered: recording and replaying HAR files. `Page.route` with `Route.fulfill` mocks; traces record the network. |
| `browserType.connect()`, `browserType.launchServer()`, `BrowserServer`, `browser.bind()` | Not covered: browsers behind a Playwright server. `BrowserType.connect_over_cdp` reaches a remote Chromium. |
| `connectOverCDP` with a transport object | Not covered. `BrowserType.connect_over_cdp` takes an endpoint. |
| The operations by selector of `Page` and `Frame` (`page.click(selector)`, `page.$`, `page.$eval`, `page.waitForSelector` and the like) | Not there: Playwright discourages them. A `Locator` does each of them: `Locator.click (Page.locator selector page)`. |
| The operations of `ElementHandle` | Not there: Playwright discourages them. A handle can be passed to JavaScript and asked for its frames; a `Locator` acts on elements. `locator.elementHandles()` is `Locator.all`. |
| `page.waitForNavigation()`, `page.waitForTimeout()`, `page.type()` | Not there: deprecated in Playwright. `Page.wait_for_url`, `Eio.Time.sleep` and `Locator.press_sequentially` take their places. |
| `page.waitForEvent()`, `page.waitForRequest()` and the `expect_<event>` methods of Python | One function, `expect_event`, with the event as a value and `ignore` for no action; `Page.expect_request` and `Page.expect_response` match URLs. |
| `allHeaders()`, `headerValue()`, `headerValues()` | Not there. `headers` has lower-case names and merged values, for `List.assoc_opt`; `headers_array` has the headers as they went over the network. |
| `request.postDataJSON()`, `response.text()` | Not there. `Request.post_data` and `Response.body` are strings; `Yojson.Safe.from_string` parses them. |
| `browser.newPage()` | Not there: its page owns a context that closing the page closes. `BrowserContext.new_page (Browser.new_context browser)` says who owns what. |
| `context.backgroundPages()`, the event `backgroundpage` | Not there: deprecated in Playwright. |
| `context.setHTTPCredentials()` | Not there: deprecated in Playwright. Credentials are given when the context is created. |
| The option `noWaitAfter` | Only where Playwright still honours it: `click`, `press` and `add_locator_handler`. |
| The option `timeout` of `isVisible` and `isHidden` | Not there: Playwright ignores it. |
| The option `logger`, the class `Logger` | Not there. `DEBUG=pw:api` makes the driver log to the standard error, see [Debugging](guide.md#debugging). |
| A function of the host language as the argument of `evaluate` | Not possible: the page runs JavaScript. `expose_function` makes an OCaml function callable from the page. |
| Android, Electron | Not covered. |

## How this is kept true

- The protocol between the library and the driver is generated from the description that
  Playwright publishes with each version. [dev/protocol-coverage.md](dev/protocol-coverage.md)
  is generated with it: an inventory of the commands and events of the protocol that the
  library does not use. `dune runtest` fails when that file is out of date, so an update of
  Playwright shows what it added.
- [dev/protocol.md](dev/protocol.md) describes how the library is moved to a new version of
  Playwright, including the comparison of the public interface with Playwright's own
  declarations.
