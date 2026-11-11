# User guide

This guide walks through the library by topic. It assumes no knowledge of Playwright, but it
does not try to replace Playwright's own documentation: where a subject deserves more depth,
it links to the matching page of [playwright.dev](https://playwright.dev/docs/intro), whose
explanations apply here as well. The complete list of functions is the documented interface,
[`lib/playwright.mli`](../lib/playwright.mli).

The code fragments use these names: `pw` for the Playwright instance, `browser`, `context`,
`page`, `frame` and `locator` for objects of the corresponding kinds, and `env` for the Eio
environment. They assume `open Playwright`.

**Contents**

1. [Getting started](#getting-started)
2. [How the API maps to OCaml](#how-the-api-maps-to-ocaml)
3. [Browsers, contexts and pages](#browsers-contexts-and-pages)
4. [Navigation](#navigation)
5. [Locators](#locators)
6. [Actions](#actions)
7. [Assertions](#assertions)
8. [JavaScript](#javascript)
9. [Events](#events)
10. [Network](#network)
11. [Emulation and state](#emulation-and-state)
12. [Frames](#frames)
13. [Screenshots, PDF and video](#screenshots-pdf-and-video)
14. [Tracing](#tracing)
15. [Concurrency](#concurrency)
16. [Errors, timeouts and cancellation](#errors-timeouts-and-cancellation)
17. [Other ways to get a browser](#other-ways-to-get-a-browser)
18. [Configuration](#configuration)
19. [Debugging](#debugging)
20. [Differences from Playwright](#differences-from-playwright)

## Getting started

Add the library to a dune project, together with an Eio backend:

```lisp
(executable
 (name first)
 (libraries playwright eio_main))
```

and install a browser with the command line tool that comes with the package:

```sh
ocaml-playwright install chromium
```

A first program:

```ocaml
open Playwright

let () =
    Eio_main.run @@ fun env ->
    Playwright.run ~env @@ fun pw ->
    let browser = BrowserType.launch (chromium pw) in
    let page = Browser.new_page browser in
    ignore (Page.goto "https://example.com" page);
    print_endline (Page.title page);
    ignore (Page.screenshot ~path:"example.png" page);
    Browser.close browser
```

`Playwright.run` starts Playwright's driver, a Node.js process that the library talks to, and
stops it when the function returns. The first run downloads the driver, which takes a few
seconds; after that, starting it takes a fraction of a second.

The browser runs headless, that is without a window. To watch it work, launch it with
`~headless:false`, and perhaps `~slow_mo:250.` to make it pause for 250 ms between operations.

## How the API maps to OCaml

Whoever knows Playwright from another language will find everything in its usual place. The
rules of translation:

- **Classes are modules.** `Page`, `Locator`, `BrowserContext`, `Request` and so on; a method
  `page.waitForURL` is a function `Page.wait_for_url`. Names that are OCaml keywords get a
  trailing underscore: `Keyboard.type_`, `Request.method_`.
- **The object comes last**, required arguments come before it, and everything optional is a
  labelled optional argument. Where two required arguments of the same type follow each other, a
  label tells them apart: `Page.fill "#name" ~value:"Ada" page`, `Mouse.move ~x:10. ~y:20. mouse`.
  Having the object last makes calls compose with `|>`:

  ```ocaml
  Page.get_by_role `Listitem page |> Locator.filter ~has_text:"Milk" |> Locator.get_by_role `Button ~name:"Remove" |> Locator.click
  ```

- **Calls block** the calling fiber until the browser has answered. There are no promises;
  [concurrency](#concurrency) is a matter of Eio fibers.
- **Durations are in milliseconds**, as floats, as in Playwright. A timeout of `0.` means no
  timeout.
- **Failures are exceptions**: `Playwright.Error`, which carries a record that tells timeouts
  and closed targets apart from other failures. See
  [Errors, timeouts and cancellation](#errors-timeouts-and-cancellation).
- **Regular expressions** are JavaScript's, since it is the browser that applies them. They
  are written as JavaScript literals in a string and go to the functions and arguments named
  `..._regex`: `Page.get_by_text_regex "/^total: \\d+$/i" page`.
- **URL patterns** are [glob patterns](https://playwright.dev/docs/network#glob-url-patterns)
  such as `"**/api/*"`. Where Playwright also accepts a regular expression or a predicate,
  there is a second function named `..._matching` which takes an OCaml predicate:
  `Page.wait_for_url_matching (String.ends_with ~suffix:"/done") page`.
- **JavaScript values** are of type `Js.t`, see [JavaScript](#javascript). Where plain JSON
  is all that can occur, as in the body of a response, it is `Yojson.Safe.t`.
- **Events** are constructors of a GADT that determines the type of what the event carries:
  `Page.on Page.Console (fun message -> ...) page`. See [Events](#events).
- **Objects have identity.** For one page in the browser there is one OCaml value, however it
  was obtained. Compare such values with `==`, never with `=`.

## Browsers, contexts and pages

There are four levels of objects:

- `Playwright.t`, the driver, from `Playwright.run` or `Playwright.create`.
- A *browser* (`Browser.t`) is a running browser process, started by `BrowserType.launch` from
  one of the browser types `chromium pw`, `firefox pw` and `webkit pw`.
- A *browser context* (`BrowserContext.t`) is an isolated session within a browser, like a
  fresh profile: it has its own cookies, storage, cache and permissions. Contexts are cheap;
  create one for every independent task or test.
- A *page* (`Page.t`) is a tab in a context.

```ocaml
let browser = BrowserType.launch ~headless:false (chromium pw) in
let context = Browser.new_context ~locale:"de-DE" ~viewport:(1280, 720) browser in
let page = BrowserContext.new_page context in
let other_page = BrowserContext.new_page context in
ignore (page, other_page);
BrowserContext.close context;
Browser.close browser
```

`Browser.new_page` creates a context and a page in it in one step, and closing that page
closes the context too. It takes the same options as `Browser.new_context`.

Which browser is launched is decided by the options of `BrowserType.launch`:

| Option | Browser |
| --- | --- |
| none | the one installed by `ocaml-playwright install` |
| `~channel:"chrome"`, `"msedge"`, `"chrome-beta"`, ... | Google Chrome or Microsoft Edge as installed on the machine |
| `~executable_path:"/usr/bin/chromium"` | the given program |

### Life cycle

Closing an object closes what it contains: `Browser.close` closes its contexts and pages,
and `Playwright.close`, or the end of `Playwright.run`, closes all browsers and stops the
driver. Nothing is left running when the program ends, not even when it ends with an
exception.

`Playwright.run` is the simplest way to get a driver. When its life should be tied to an Eio
switch instead, use `Playwright.create`:

```ocaml
Eio.Switch.run @@ fun sw ->
let pw = Playwright.create ~sw ~env () in
let browser = BrowserType.launch (chromium pw) in
ignore browser
(* The driver stops, and the browser closes, when the switch is released. *)
```

A program may use several drivers at the same time; they are independent of each other.

## Navigation

```ocaml
let response = Page.goto "https://example.com/login" page in
Option.iter (fun response -> assert (Response.ok response)) response;
ignore (Page.reload page);
ignore (Page.go_back page);
Page.wait_for_url "**/dashboard" page
```

`Page.goto` returns when the page has fired its `load` event; `~wait_until` selects another
moment: `` `Domcontentloaded ``, `` `Commit `` (as soon as the response starts to arrive) or
`` `Networkidle ``. It returns the response of the main document, or `None` when there is
none, as for `about:blank` and for navigations to another anchor of the same document. It
fails if the server cannot be reached; an HTTP status such as 404 is not a failure, it is
there to see in the response.

With the context option `~base_url`, relative URLs can be used in `Page.goto` and in URL
patterns:

```ocaml
let context = Browser.new_context ~base_url:"http://localhost:8080" browser in
let page = BrowserContext.new_page context in
ignore (Page.goto "/settings" page)
```

There is seldom a reason to wait for a navigation explicitly, because the actions and
assertions that follow wait for what they need. When there is one, there are
`Page.wait_for_url`, `Page.wait_for_load_state` and, for navigations caused by an action,
`Page.expect_navigation`.

`Page.set_content html page` loads a document from a string, which is handy in tests.

## Locators

A locator describes how to find elements in a page. It is a description only: creating one
does not talk to the browser, and every use of it looks the elements up anew. This is what
makes locators robust against pages that re-render.
[Playwright's guide to locators](https://playwright.dev/docs/locators) explains the idea in
depth.

The recommended locators find elements the way people and assistive technology do:

```ocaml
[ Page.get_by_role `Button ~name:"Submit" page;
  Page.get_by_role `Heading ~level:1 page;
  Page.get_by_role `Checkbox ~checked:true page;
  Page.get_by_label "Password" page;
  Page.get_by_placeholder "Search..." page;
  Page.get_by_text "Welcome back" page;
  Page.get_by_text ~exact:true "Log in" page;
  Page.get_by_alt_text "Company logo" page;
  Page.get_by_title "Close" page;
  Page.get_by_test_id "checkout" page ]
```

Text is matched case-insensitively and as a substring unless `~exact:true` is given. Each of
these has a variant that takes a regular expression, and `get_by_role` has `~name_regex`:

```ocaml
[ Page.get_by_text_regex "/^\\d+ results?$/" page; Page.get_by_role `Link ~name_regex:"/sign (in|up)/i" page ]
```

`Page.locator` takes a [CSS or XPath selector](https://playwright.dev/docs/other-locators),
or any other selector that Playwright understands:

```ocaml
[ Page.locator "form#login input[type=submit]" page; Page.locator "xpath=//table//tr[2]" page ]
```

`get_by_test_id` looks at the attribute `data-testid`;
`Selectors.set_test_id_attribute "data-test" pw` makes it use another one.

### Narrowing down

All of these functions exist on locators as well, where they search within the elements of
the locator. Together with `Locator.filter` and the functions that pick by position, this
gives precise descriptions without brittle selectors:

```ocaml
let row = Page.get_by_role `Row page |> Locator.filter ~has_text:"Ada Lovelace" in
let with_button = Page.get_by_role `Listitem page |> Locator.filter ~has:(Page.get_by_role `Button ~name:"Buy" page) in
let second = Page.get_by_role `Listitem page |> Locator.nth 1 in
let either = Locator.or_ (Page.get_by_text "Accept" page) (Page.get_by_text "Agree" page) in
Locator.get_by_role `Button ~name:"Edit" row |> Locator.click;
ignore (with_button, second, either)
```

`Locator.first`, `Locator.last` and `Locator.nth` (counting from 0) pick one of several
elements, `Locator.and_` and `Locator.or_` combine two locators, and `Locator.visible`
keeps the visible elements only.

### Strictness

An operation on one element, such as `Locator.click` or `Locator.inner_text`, fails if its
locator matches more than one element, instead of silently picking the first. The error
lists what matched. Make the locator more specific, or say which element is meant with
`Locator.first` or `Locator.nth`.

Operations on all elements have no such restriction:

```ocaml
let items = Page.get_by_role `Listitem page in
Printf.printf "%d items: %s\n" (Locator.count items) (String.concat ", " (Locator.all_inner_texts items));
List.iter (fun item -> print_endline (Locator.inner_text item)) (Locator.all items)
```

## Actions

Before it acts, an action waits for its element to be
[actionable](https://playwright.dev/docs/actionability): attached to the document, visible,
not moving, not covered by something else, enabled. It scrolls the element into view if
needed. If the element does not get there within the timeout, the action fails with an error
that says what it was waiting for.

```ocaml
Page.get_by_label "Name" page |> Locator.fill "Ada";
Page.get_by_label "Subscribe" page |> Locator.check;
Page.get_by_label "Colour" page |> Locator.select_option [ `Label "Blue" ] |> ignore;
Page.get_by_label "Photo" page |> Locator.set_input_files [ "photo.jpg" ];
Page.get_by_role `Textbox ~name:"Comment" page |> Locator.press_sequentially ~delay:50. "typed key by key";
Page.get_by_role `Textbox ~name:"Comment" page |> Locator.press "Control+A";
Page.get_by_role `Button ~name:"Send" page |> Locator.click
```

| Function | What it does |
| --- | --- |
| `Locator.click`, `dblclick`, `tap`, `hover` | pointer actions; options choose the button, modifier keys and position |
| `Locator.fill`, `clear` | set or clear the value of an input at once |
| `Locator.press_sequentially` | type text key by key, for pages that react to key events |
| `Locator.press` | press a key or a combination such as `"Enter"` or `"Shift+Tab"` |
| `Locator.check`, `uncheck`, `set_checked` | checkboxes and radio buttons |
| `Locator.select_option` | choose options of a `<select>` by value, label or index |
| `Locator.set_input_files`, `set_input_payloads` | choose files for an `<input type=file>`, from disk or from memory |
| `Locator.drag_to`, `drop` | drag one element to another; drop files or data onto an element |
| `Locator.focus`, `blur`, `scroll_into_view_if_needed` | |
| `Locator.dispatch_event` | fire a DOM event directly, without the checks above |

Options shared by most actions: `~timeout`; `~force:true` skips the actionability checks;
`~trial:true` performs the checks but not the action.

Lower-level input goes through the keyboard, mouse and touchscreen of the page:

```ocaml
Keyboard.press "Escape" (Page.keyboard page);
Mouse.move ~x:100. ~y:200. (Page.mouse page);
Mouse.wheel ~delta_x:0. ~delta_y:500. (Page.mouse page)
```

### Reading from the page

```ocaml
let heading = Page.get_by_role `Heading page |> Locator.first in
let text = Locator.inner_text heading in
let link = Page.get_by_role `Link ~name:"Docs" page |> Locator.get_attribute "href" in
let value = Page.get_by_label "Name" page |> Locator.input_value in
let visible = Page.get_by_text "Error" page |> Locator.is_visible in
(text, link, value, visible)
```

`Locator.text_content`, `inner_text`, `inner_html`, `get_attribute`, `input_value` and the
`is_...` functions return the state of the page at the moment of the call. For checking that
state, prefer an [assertion](#assertions), which waits for it.

When a page is too irregular for locators to wait on, `Locator.wait_for` waits for an element
to appear (or, with `~state`, to disappear), and `Page.wait_for_function` for a JavaScript
condition to become true.

## Assertions

The functions of `Expect` check something about a locator or a page, and they keep checking
until it holds or a timeout, 5 seconds by default, has passed. They return `()` or raise.
This removes the main cause of flaky tests, a check that runs a moment too early.

```ocaml
Expect.to_be_visible (Page.get_by_role `Alert page);
Expect.to_have_text "Saved" (Page.get_by_role `Status page);
Expect.to_contain_text "3 results" (Page.locator "#summary" page);
Expect.to_have_count 3 (Page.get_by_role `Listitem page);
Expect.to_have_texts [ "One"; "Two"; "Three" ] (Page.get_by_role `Listitem page);
Expect.to_have_value "Ada" (Page.get_by_label "Name" page);
Expect.to_be_checked (Page.get_by_label "Subscribe" page);
Expect.to_have_attribute "href" ~value:"/docs" (Page.get_by_role `Link ~name:"Docs" page);
Expect.to_have_url "https://example.com/dashboard" page;
Expect.to_have_title_regex "/dashboard/i" page
```

Each assertion has its negation in `Expect.Not`:

```ocaml
Expect.Not.to_be_visible (Page.get_by_text "Loading" page);
Expect.Not.to_have_class "disabled" (Page.get_by_role `Button ~name:"Send" page)
```

`~timeout` changes the time allowed for one assertion, and `Expect.set_default_timeout 10_000. pw`
that of all assertions about the pages of a driver. An assertion that fails raises `Playwright.Error` with the kind
`Assertion_failed` and a message like this one:

```text
Locator expected to have text "Saved"
Received: "Saving..."
Call log:
  - Expect "to.have.text" get_by_role("status") with timeout 5000ms
  - waiting for get_by_role("status")
    9 × locator resolved to <p role="status">Saving...</p>
       - unexpected value "Saving..."
```

The call log comes from Playwright's driver, which writes locators in its own notation.

The assertions do not depend on a test framework. In an Alcotest or OUnit test they fail the
test like any other exception.

Values that the library does not have an assertion for can be checked with
`Expect.to_have_js_property`, or by polling with `Page.wait_for_function`.

## JavaScript

`Page.evaluate` runs JavaScript in the page and returns its value. The code is an expression;
if the expression is a function, the function is called, with `~arg` if that is given.
Promises are awaited.

```ocaml
let title = Page.evaluate "document.title" page |> Js.to_string in
let links = Page.evaluate "() => [...document.links].map(link => link.href)" page |> Js.to_list Js.to_string in
let area =
    Page.evaluate "({ width, height }) => width * height" ~arg:(Js.obj [ "width", Js.int 3; "height", Js.int 4 ]) page |> Js.to_int
in
let status = Page.evaluate "fetch('/health').then(response => response.status)" page |> Js.to_int in
(title, links, area, status)
```

Values cross the boundary as `Js.t`, a variant that covers what JSON cannot express:
`undefined`, `NaN`, dates, big integers, regular expressions, typed arrays and more.
`Js.int`, `Js.string`, `Js.list`, `Js.obj` and their relatives build arguments, and
`Js.to_int`, `Js.to_string`, `Js.to_list`, `Js.member` and so on take results apart; the
latter raise `Playwright.Error` if the value is of another kind. For results that are plain
JSON, `Js.to_json` converts to `Yojson.Safe.t` in one go.

The same function exists for locators, where the function receives the element, and for
frames, workers and handles:

```ocaml
let id = Page.get_by_role `Row page |> Locator.first |> Locator.evaluate "row => row.dataset.id" |> Js.to_string in
let widths = Page.locator "td" page |> Locator.evaluate_all "cells => cells.map(cell => cell.offsetWidth)" |> Js.to_list Js.to_float in
(id, widths)
```

### Handles

`Page.evaluate_handle` returns a handle to an object in the page instead of a copy. A handle
can be passed back as an argument, as `Js.Handle handle`. Handles keep their object alive in
the page, so dispose of them when they are no longer needed. They are rarely necessary;
locators do the same job for elements, without the bookkeeping.

```ocaml
let map = Page.evaluate_handle "new Map([['answer', 42]])" page in
let answer = Page.evaluate "map => map.get('answer')" ~arg:(Js.Handle map) page |> Js.to_int in
JSHandle.dispose map;
answer
```

### Calling OCaml from the page

`Page.expose_function` installs a function in the page that calls back into OCaml. In the
page it returns a promise.

```ocaml
Page.expose_function "sha256" (function [ Js.String text ] -> Js.string (Digest.to_hex (Digest.string text)) | _ -> Js.null) page |> ignore;
Page.evaluate "sha256('hello')" page |> Js.to_string
```

`Page.add_init_script` runs a script, given as `` `Content`` text or as the `` `Path`` of a file, in every document of the page before the
page's own scripts, which is the place to install mocks and flags. Both functions exist for
contexts too, where they apply to all pages.

## Events

Pages, contexts, WebSockets and workers emit events. A listener is registered with `on`, or
with `once` for the next occurrence only:

```ocaml
Page.on Page.Console (fun message -> Printf.printf "console.%s: %s\n" (ConsoleMessage.type_ message) (ConsoleMessage.text message)) page |> ignore;
Page.on Page.Page_error (fun (error : Error.t) -> prerr_endline ("uncaught: " ^ error.message)) page |> ignore;
Page.on Page.Request_failed (fun request -> prerr_endline ("failed: " ^ Request.url request)) page |> ignore;
Page.once Page.Close (fun _ -> print_endline "the page was closed") page
```

The event determines the type of the listener's argument: `Page.Console` carries a console
message, `Page.Request_failed` a request. The events of a context cover all of its pages.

Listeners run in fibers of their own. They may take their time and may call any function of
the library. An exception that escapes from a listener cannot be raised anywhere useful; it
is given to the `~on_error` function of `Playwright.run` and `Playwright.create`, which by
default prints it to standard error.

`Page.on` returns a `Disposable.t`. Most listeners stay for as long as their page, and what
they return is ignored. To remove one, keep it and dispose of it:

```ocaml
let logging = Page.on Page.Request (fun request -> print_endline (Request.url request)) page in
ignore (Page.goto "https://example.com" page);
Disposable.dispose logging
```

### Waiting for an event

To get hold of something that an action causes, such as the popup a click opens, wrap the
action in an `expect_...` function. It starts listening, runs the action, and returns the
event. Waiting only after the action would be a race, since the event may have happened
by then.

```ocaml
let popup = Page.expect_popup (fun () -> Page.get_by_text "Open in a new tab" page |> Locator.click) page in
Page.wait_for_load_state popup;
print_endline (Page.title popup);

let request = Page.expect_request ~url:"**/api/save" (fun () -> Page.get_by_role `Button ~name:"Save" page |> Locator.click) page in
print_endline (Option.value (Request.post_data request) ~default:"");

let response = Page.expect_response ~url:"**/api/items" ~predicate:Response.ok (fun () -> ignore (Page.reload page)) page in
Response.json response
```

There are such functions for popups, downloads, file choosers, console messages, requests,
responses, WebSockets and workers, and `expect_event` for any event. All take a `~timeout`
and most a `~predicate` that selects among the events.

### Dialogs

JavaScript dialogs (`alert`, `confirm`, `prompt`) block their page until they are answered.
While there is no listener for `Page.Dialog`, they are dismissed automatically. To answer
them otherwise:

```ocaml
Page.on Page.Dialog
    (fun dialog ->
        Printf.printf "%s: %s\n" (Dialog.type_ dialog) (Dialog.message dialog);
        Dialog.accept ~prompt_text:"yes" dialog)
    page
```

### Downloads and uploads

```ocaml
let download = Page.expect_download (fun () -> Page.get_by_role `Link ~name:"Invoice" page |> Locator.click) page in
Download.save_as ("downloads/" ^ Download.suggested_filename download) download;

(* An upload through the file input itself... *)
Page.get_by_label "Attachment" page |> Locator.set_input_files [ "report.pdf" ];
(* ...from memory... *)
Page.get_by_label "Attachment" page |> Locator.set_input_payloads [ { name = "notes.txt"; mime_type = Some "text/plain"; buffer = "hello" } ];
(* ...or through the file chooser that a button opens. *)
let chooser = Page.expect_file_chooser (fun () -> Page.get_by_role `Button ~name:"Upload" page |> Locator.click) page in
FileChooser.set_files [ "report.pdf" ] chooser
```

### Looking back

A page remembers its recent console messages and uncaught exceptions, so they can be
inspected after the fact, without a listener: `Page.console_messages page` and
`Page.page_errors page`.

## Network

### Watching

Requests and responses are events (`Page.Request`, `Page.Response`, `Page.Request_finished`,
`Page.Request_failed`), and the modules `Request` and `Response` give access to URLs,
methods, headers, bodies and timing:

```ocaml
Page.on Page.Response
    (fun response ->
        let request = Response.request response in
        Printf.printf "%s %s -> %d\n" (Request.method_ request) (Request.url request) (Response.status response))
    page
```

### Intercepting

`Page.route` registers a handler for the requests whose URL matches a pattern; the handler
decides what happens with each. `BrowserContext.route` does the same for all pages of a
context.

```ocaml
(* Answer without asking the server. *)
Page.route "**/api/profile" (Route.fulfill ~json:(`Assoc [ "name", `String "Ada" ])) page |> ignore;

(* Refuse. *)
Page.route "**/*.{png,jpg,jpeg,webp}" Route.abort page |> ignore;

(* Let the request through, with a change. *)
Page.route "**/api/**"
    (fun route ->
        let headers = ("x-test", "1") :: Request.headers (Route.request route) in
        Route.continue ~headers route)
    page
|> ignore;

(* Get the real response and change it on its way to the page. *)
Page.route "**/api/items"
    (fun route ->
        let response = Route.fetch route in
        let items = match APIResponse.json response with `List items -> items | _ -> [] in
        Route.fulfill ~response ~json:(`List (List.filteri (fun index _ -> index < 3) items)) route)
    page
```

A handler must settle its route in one of four ways: `Route.fulfill` answers the request,
`Route.abort` fails it, `Route.continue` sends it to the network, and `Route.fallback` hands
it to the next handler that matches, which allows handlers to be layered. Handlers that were
registered later come first, and those of a page come before those of its context.

A handler that raises before it has settled its route fails the request, as `Route.abort`
does, and the exception is given to `~on_error`: what a handler was there to block does not
slip through because the handler has a bug.

`~times:n` makes a handler apply to the first `n` requests only. `Page.route_matching` takes
a predicate on the URL instead of a pattern. `Page.route` returns a `Disposable.t`, and
disposing of it removes that handler; `Page.unroute` removes the handlers of a pattern and
`Page.unroute_all` removes them all:

```ocaml
let offline = Page.route "**/api/**" Route.abort page in
Page.get_by_role `Button ~name:"Retry" page |> Locator.click;
Disposable.dispose offline
```

Note that a pattern has to match the whole URL, query string included: `"**/api/items"` does
not match `/api/items?page=2`, while `"**/api/items*"` and `"**/api/items?*"` do.

### Recording and replaying

A context can record its traffic into a [HAR file](https://playwright.dev/docs/mock#mocking-with-har-files),
and requests can be answered from such a file later, which makes tests independent of a
backend:

```ocaml
(* Record: the file is written when the context is closed. *)
let recording = Browser.new_context ~record_har_path:"shop.har" ~record_har_url_filter:"**/api/**" browser in
ignore (Page.goto "https://shop.example/" (BrowserContext.new_page recording));
BrowserContext.close recording;

(* Replay. *)
let context = Browser.new_context browser in
BrowserContext.route_from_har ~not_found:`Fallback "shop.har" context
```

### WebSockets

`Page.Web_socket` announces the WebSockets that a page opens, and the events of `WebSocket`
show their frames. `Page.route_web_socket` intercepts connections: the handler then plays the
server, or sits between the page and the real server.

```ocaml
Page.route_web_socket "wss://chat.example/socket"
    (fun socket ->
        WebSocketRoute.on_message
            (function Text "ping" -> WebSocketRoute.send (Text "pong") socket | _ -> ())
            socket)
    page
```

### Requests without a page

`APIRequestContext` sends HTTP requests directly, for testing an API or for preparing the
state of a server before a browser test. The one that belongs to a browser context shares
its cookies, so it is logged in whenever the pages are, and the other way round.

```ocaml
let api = BrowserContext.request context in
let response = APIRequestContext.post "https://example.com/api/items" ~json:(`Assoc [ "title", `String "New" ]) api in
Expect.to_be_ok response;
let id = APIResponse.json response |> Yojson.Safe.Util.member "id" in

(* A context that is independent of any browser. *)
let standalone = APIRequest.new_context ~base_url:"https://example.com" ~extra_http_headers:[ "authorization", "Bearer token" ] pw in
let items = APIRequestContext.get "/api/items" ~params:[ "page", "2" ] standalone |> APIResponse.json in
APIRequestContext.dispose standalone;
(id, items)
```

## Emulation and state

The options of `Browser.new_context` (and of `Browser.new_page`) set up what the pages of the
context see. A selection:

```ocaml
Browser.new_context ~viewport:(1920, 1080) ~locale:"fr-FR" ~timezone_id:"Europe/Paris" ~color_scheme:`Dark
    ~geolocation:(Geolocation.make ~latitude:48.8584 ~longitude:2.2945 ())
    ~permissions:[ "geolocation" ] ~user_agent:"MyCrawler/1.0"
    ~extra_http_headers:[ "x-requested-by", "tests" ]
    ~http_credentials:(Http_credentials.make ~username:"ada" ~password:"secret" ())
    ~ignore_https_errors:true browser
```

A whole device is emulated with one of Playwright's device descriptors, which set the
viewport, user agent, pixel density and touch support together:

```ocaml
let phone = Option.get (Playwright.device "iPhone 15" pw) in
let context = Browser.new_context ~device:phone ~locale:"en-GB" browser in
BrowserContext.new_page context
```

`Playwright.devices pw` lists them all. Some settings can be changed while the context is in
use: `BrowserContext.set_offline`, `set_geolocation`, `grant_permissions`,
`set_extra_http_headers`, and for a page `Page.set_viewport_size` and `Page.emulate_media`.

### Cookies and storage

```ocaml
BrowserContext.add_cookies [ Cookie.make ~url:"https://example.com" "session" ~value:"abc123" ] context;
let cookies = BrowserContext.cookies ~urls:[ "https://example.com" ] context in
List.iter (fun (cookie : Cookie.t) -> Printf.printf "%s=%s\n" cookie.name cookie.value) cookies;
BrowserContext.clear_cookies ~name:"session" context;

let storage = Page.local_storage page in
WebStorage.set_item "theme" ~value:"dark" storage;
WebStorage.get_item "theme" storage
```

### Logging in once

The cookies and the local storage of a context can be saved and given to new contexts,
which then start out logged in. This is the usual way to keep the login out of every test:

```ocaml
(* Once: *)
let context = Browser.new_context browser in
let page = BrowserContext.new_page context in
ignore (Page.goto "https://example.com/login" page);
Page.get_by_label "User" page |> Locator.fill "ada";
Page.get_by_label "Password" page |> Locator.fill "secret";
Page.get_by_role `Button ~name:"Log in" page |> Locator.click;
Page.wait_for_url "**/home" page;
ignore (BrowserContext.storage_state ~path:"auth.json" context);
BrowserContext.close context;

(* In every test: *)
Browser.new_context ~storage_state_path:"auth.json" browser
```

### Time

`Clock` puts the time that pages see under the control of the program, so that timeouts and
animations that take minutes can be tested in an instant:

```ocaml
Clock.install ~time:1_700_000_000_000. context;
ignore (Page.goto "https://example.com/session" page);
Clock.fast_forward (30. *. 60_000.) context;
Expect.to_be_visible (Page.get_by_text "Your session has expired" page)
```

## Frames

Elements inside an `<iframe>` are reached with a frame locator, which works like a locator
for the frame and gives access to the locators within it:

```ocaml
let payment = Page.frame_locator "iframe[title='Payment']" page in
FrameLocator.get_by_label "Card number" payment |> Locator.fill "4242 4242 4242 4242";
FrameLocator.get_by_role `Button ~name:"Pay" payment |> Locator.click
```

The frames themselves are available as `Page.main_frame`, `Page.frames` and `Page.frame`,
which finds one by name or URL. A `Frame.t` offers most of what a page offers: navigation,
locators, evaluation.

## Screenshots, PDF and video

```ocaml
let png = Page.screenshot page in
ignore (Page.screenshot ~path:"page.png" ~full_page:true page);
ignore (Page.screenshot ~type_:`Jpeg ~quality:80 ~clip:{ x = 0.; y = 0.; width = 400.; height = 300. } page);
ignore (Page.get_by_role `Table page |> Locator.screenshot ~path:"table.png" ~animations:`Disabled);
ignore (Page.pdf ~path:"page.pdf" ~format:"A4" ~print_background:true page);
String.length png
```

Screenshots and PDFs are returned as strings of bytes, and also written to `~path` if that
is given. `Page.pdf` needs Chromium.

A context created with `~record_video_dir` records a video of each of its pages. The file
is complete when the page has been closed:

```ocaml
let context = Browser.new_context ~record_video_dir:"videos" ~record_video_size:(1280, 720) browser in
let page = BrowserContext.new_page context in
ignore (Page.goto "https://example.com" page);
BrowserContext.close context;
Option.map Video.path (Page.video page)
```

Recording needs the ffmpeg build of Playwright: `ocaml-playwright install ffmpeg`.

## Tracing

A [trace](https://playwright.dev/docs/trace-viewer) records everything that happens in a
context: every action with the state of the page before and after it, network traffic,
console output. It is the best tool for finding out why a test failed on another machine.

```ocaml
let tracing = BrowserContext.tracing context in
Tracing.start ~screenshots:true ~snapshots:true tracing;
ignore (Page.goto "https://example.com" page);
Page.get_by_role `Link page |> Locator.first |> Locator.click;
Tracing.stop ~path:"trace.zip" tracing
```

Open the trace with `ocaml-playwright show-trace trace.zip`, or drop the file onto
[trace.playwright.dev](https://trace.playwright.dev). `Tracing.group` and
`Tracing.group_end` structure a trace into named steps, and `Tracing.start_chunk` and
`Tracing.stop_chunk` split one recording into several files, one per test for instance.

## Concurrency

Every function of the library blocks the fiber that calls it, and only that fiber. To work
on several pages at once, run a fiber for each:

```ocaml
let check url =
    let context = Browser.new_context browser in
    Fun.protect
        ~finally:(fun () -> BrowserContext.close context)
        (fun () ->
            let page = BrowserContext.new_page context in
            let response = Page.goto url page in
            url, Option.map Response.status response)
in
Eio.Fiber.List.map ~max_fibers:4 check [ "https://ocaml.org"; "https://example.com"; "https://playwright.dev" ]
```

Fibers can also share a page, for example one that waits for a response while another
clicks; the `expect_...` functions are built this way.

Things to know:

- All use of one driver has to happen in one domain, the one that created it. Different
  drivers can live in different domains.
- Listeners and route handlers run in their own fibers, concurrently with the rest of the
  program.
- A driver does not keep its switch from finishing. Once the function given to
  `Eio.Switch.run` has returned and the fibers that the program itself forked are done, the
  driver is stopped and its browsers are closed.

## Errors, timeouts and cancellation

Every failure is reported as the exception `Playwright.Error` with a record of type
`Error.t`:

| Field | Content |
| --- | --- |
| `kind` | `Timeout`, `Target_closed`, `Assertion_failed` or `Other` |
| `message` | what went wrong, with the call log if there is one |
| `name` | the name of the JavaScript error, such as `"TimeoutError"` |
| `stack` | the stack trace, for errors thrown by JavaScript code |
| `log` | the steps that the browser took, one per item |

```ocaml
match Page.get_by_role `Button ~name:"Accept cookies" page |> Locator.click ~timeout:2_000. with
| () -> ()
| exception Playwright.Error { kind = Timeout; _ } -> (* No cookie banner this time. *) ()
```

`Target_closed` means that the page, context or browser of the call was closed, or crashed,
before the call could finish. `Error.to_string` formats an error for people, and a printer
is registered with `Printexc`, so that an uncaught error is printed in full.

The messages are written to be read. This one comes from a click on a button that stayed
disabled:

```text
Timeout 1000ms exceeded.
Call log:
  - waiting for get_by_role("button", name="Send")
    - locator resolved to <button disabled>Send</button>
  - attempting click action
    2 × waiting for element to be visible, enabled and stable
      - element is not enabled
    - retrying click action
```

### Timeouts

| What | Default | How to change it |
| --- | --- | --- |
| actions, waiting, navigation | 30 s | `~timeout`; `Page.set_default_timeout`, `BrowserContext.set_default_timeout`; for navigation alone `set_default_navigation_timeout` |
| assertions | 5 s | `~timeout`; `Expect.set_default_timeout`, for a driver |
| launching a browser | 180 s | `~timeout` |

Functions that only read what the library knows already, such as `Page.url`, do not wait
and have no timeout.

### Cancellation

Calls can be cancelled like any other Eio operation: when the fiber is cancelled, the call
ends and the driver is told to stop working on it. This gives a way to put a deadline on a
whole sequence of operations:

```ocaml
match
    Eio.Time.with_timeout env#clock 10. (fun () ->
        ignore (Page.goto "https://example.com" page);
        Page.get_by_role `Link page |> Locator.first |> Locator.click;
        Ok (Page.title page))
with
| Ok title -> print_endline title
| Error `Timeout -> prerr_endline "that took more than 10 seconds"
```

Note that Eio counts in seconds, while the `~timeout` arguments of this library are in
milliseconds.

## Other ways to get a browser

**A persistent profile.** `BrowserType.launch_persistent_context` starts a browser with a
profile directory that outlives it, and returns the browser's single context. It takes the
options of both `launch` and `new_context`:

```ocaml
let context = BrowserType.launch_persistent_context ~headless:false "/home/ada/.cache/my-profile" (chromium pw) in
let page = match BrowserContext.pages context with page :: _ -> page | [] -> BrowserContext.new_page context in
ignore (Page.goto "https://example.com" page);
BrowserContext.close context
```

**A Playwright server.** Browsers can run elsewhere, in a container for instance, behind a
Playwright server of the same version. The server is started on that machine, which needs
the browsers installed, with `ocaml-playwright run-server --port 3000 --host 0.0.0.0` or
with `npx playwright@1.65.0 run-server --port 3000 --host 0.0.0.0`. It launches a browser
for every client that connects:

```ocaml
let browser = BrowserType.connect "ws://build-host:3000/" (chromium pw) in
Browser.new_page browser
```

Files to upload are sent over the connection, and `Download.save_as`, `Video.save_as` and
`Tracing.stop ~path` fetch their files through it: the paths given to these functions are on
the machine that the program runs on. `Download.path` and `Video.path` are not available
then, as those files are on the other machine.

**A running Chromium.** `BrowserType.connect_over_cdp` attaches to a Chromium-based browser
that was started with `--remote-debugging-port`, including its open tabs:

```ocaml
let browser = BrowserType.connect_over_cdp "http://localhost:9222" (chromium pw) in
let pages = List.concat_map BrowserContext.pages (Browser.contexts browser) in
List.iter (fun page -> print_endline (Page.url page)) pages
```

For Chromium there is also direct access to the
[Chrome DevTools Protocol](https://chromedevtools.github.io/devtools-protocol/), for the rare
things that Playwright has no function for:

```ocaml
let session = BrowserContext.new_cdp_session page context in
let metrics = CDPSession.send "Performance.getMetrics" session in
CDPSession.detach session;
metrics
```

## Configuration

The library needs no configuration. These environment variables change where it finds
things:

| Variable | Meaning |
| --- | --- |
| `PLAYWRIGHT_NODEJS_PATH` | The Node.js executable to run the driver with. Default: `node` from the `PATH`. |
| `PLAYWRIGHT_OCAML_CACHE_DIR` | Where the driver is kept. Default: `$XDG_CACHE_HOME/ocaml-playwright` or `~/.cache/ocaml-playwright`; on Windows `%LOCALAPPDATA%\ocaml-playwright`. |
| `PLAYWRIGHT_OCAML_DRIVER` | A directory that holds the driver already, that is the `playwright-core` package in the right version, for machines without network access. Nothing is downloaded then. |
| `PLAYWRIGHT_OCAML_DRIVER_URL` | Another place to download the driver's package from, such as a mirror of the npm registry. The checksum is verified all the same. |
| `HTTPS_PROXY`, `NO_PROXY` | The proxy for that download. This needs a recent Node.js (24, or 22.21 and later); browsers are downloaded through the proxy by any version. |
| `PLAYWRIGHT_BROWSERS_PATH` | Where Playwright installs and looks for browsers. This and the other [variables of Playwright](https://playwright.dev/docs/browsers#managing-browser-binaries) work as usual. |

The driver is the npm package `playwright-core` in exactly the version that
`Playwright.version` names. Its download is verified against a checksum that is compiled
into the library.

`ocaml-playwright` is the command line tool of that package. Besides `install` it offers,
among others, `show-trace`, `codegen` (records interactions; the generated code is for the
official languages, but its locators carry over), `run-server` and `--help`.
A program can run the tool itself, through `Playwright.Driver.command` and
`Playwright.Driver.run`:

```ocaml
let status = Playwright.Driver.run [ "install"; "chromium" ] in
if status <> 0 then failwith "could not install Chromium"
```

For deployment in a container, the points to take care of are: Node.js, the driver (let the
build run `ocaml-playwright --version` once to fetch it, or provide it through
`PLAYWRIGHT_OCAML_DRIVER`), and a browser with its system libraries
(`ocaml-playwright install --with-deps chromium`).

## Debugging

- **Watch it.** `BrowserType.launch ~headless:false ~slow_mo:300.` shows the browser and
  slows it down.
- **Pause.** `Page.pause page` stops the program and opens the Playwright Inspector on the
  page, in a headed browser. Setting the environment variable `PWDEBUG=1` does this from the
  start, and disables timeouts.
- **Trace.** Record a [trace](#tracing) and step through it afterwards.
- **Look at the page.** `Page.screenshot`, `Page.content` (the HTML) and
  `Page.aria_snapshot` (the accessibility tree as text, which shows what `get_by_role` sees)
  tell what the page looked like. `Locator.highlight` marks the elements of a locator in a
  headed browser.
- **Read the browser's console.** `Page.on Page.Console` and `Page.on Page.Page_error`.
- **Protocol log.** `DEBUG=pw:channel` in the environment prints every message exchanged with
  the driver to standard error. `DEBUG=pw:api` and `DEBUG=pw:browser*` make the driver itself
  talkative.

## Differences from Playwright

The library follows Playwright for Node.js and Python closely. Where it deviates, and what
it leaves out:

**By design**

- Regular expressions are JavaScript literals in strings (`..._regex`), and they are not
  accepted for URLs: use glob patterns or `..._matching` with a predicate.
- `Page.evaluate` and its relatives take JavaScript source. There is nothing like passing a
  function of the host language.
- The clock of a context is controlled through the `Clock` module, with the context as
  argument.
- Listeners are removed by disposing of what `on` and `once` returned; there is no `off`,
  because it would have to recognise a function. `route_web_socket` returns a disposable
  too, while `Tracing.start`, `Tracing.group` and the like return `()` and have their
  counterparts `stop` and `group_end`.
- If a route handler raises before it has settled its route, the exception goes to
  `~on_error` and the request fails. In Playwright for Node.js the exception is an
  unhandled rejection and the request stays pending.
- Assertions are plain functions that raise; there is no test runner, no fixtures, no soft
  assertions and no `expect.poll`.

**Not covered**

- JavaScript and CSS coverage (`page.coverage`).
- Screencasts (`page.screencast`) and visual comparisons (`toHaveScreenshot`,
  `toMatchSnapshot`).
- WebAuthn virtual authenticators.
- Chromium's own tracing, `browser.startTracing`. The Playwright trace is covered.
- Reading a download as a stream; use `Download.path` or `Download.save_as`.
- `browserType.launchServer`. A server is started with `ocaml-playwright run-server`.
- Android and Electron.
