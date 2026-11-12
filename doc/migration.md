# Migrating from 0.1

Version 0.2 is a rewrite. Version 0.1, which targeted Playwright 1.59, exposed the functions
that were generated from Playwright's protocol, with some helpers on top. The library now
offers Playwright's API, hand-written over a generated protocol layer that is no longer
visible. Programs need to be adapted; this page tells how.

## At a glance

Before:

```ocaml skip
let () =
    Eio_main.run @@ fun env ->
    Eio.Switch.run @@ fun sw ->
    let pw = Playwright.create ~env ~sw () in
    Fun.protect ~finally:(fun () -> Playwright.destroy pw) @@ fun () ->
    let chromium = Playwright.Playwright.chromium pw in
    let browser = Playwright.BrowserType.launch ~executable_path:"/usr/bin/chromium" ~headless:true chromium in
    let context = Playwright.Browser.new_context browser in
    let page = Playwright.BrowserContext.new_page context in
    ignore (Playwright.Page.goto ~url:"https://example.com" ~timeout:15000. page);
    ignore (Playwright.Page.wait_for_function ~expression:"window.ready === true" ~timeout:10000. page);
    (match Playwright.Page.evaluate ~expression:"document.title" page with
    | `String title -> print_endline title
    | _ -> ());
    Playwright.Page.close page;
    Playwright.Browser.close browser
```

After, with the driver installed (rule 1):

```ocaml
let () =
    Eio_main.run @@ fun env ->
    Playwright.run ~env @@ fun pw ->
    let chromium = Playwright.chromium pw in
    let browser = Playwright.BrowserType.launch ~executable_path:"/usr/bin/chromium" chromium in
    let context = Playwright.Browser.new_context browser in
    let page = Playwright.BrowserContext.new_page context in
    ignore (Playwright.Page.goto ~timeout:15000. "https://example.com" page);
    ignore (Playwright.Page.wait_for_function ~timeout:10000. "window.ready === true" page);
    print_endline (Playwright.Page.evaluate "document.title" page |> Playwright.Js.to_string);
    Playwright.Page.close page;
    Playwright.Browser.close browser
```

## The rules

1. **The driver is installed in a step of its own.** `Playwright.create` used to download
   the driver when it was missing. It no longer does: run `ocaml-playwright install chromium`,
   which comes with the package and installs the driver and that browser, or call
   `Playwright.Driver.install ()`, for the driver alone, before `Playwright.create`. Without
   the driver, `Playwright.create` fails with an error that names the command.
2. **Required arguments are positional.** `~url`, `~selector`, `~expression`, `~key`,
   `~name`, `~text` and the like have lost their labels. The object still comes last. Where
   two required arguments of the same type follow each other, the second keeps a label:
   `WebStorage.set_item "theme" ~value:"dark" storage`. The compiler points at every place:
   a label that no longer exists is an error.
3. **The driver's functions are at the top level.** `Playwright.Playwright.chromium` is
   `Playwright.chromium`, and `Playwright.destroy` is `Playwright.close`.
   `Playwright.create ~sw ~env ()` is as before; `Playwright.run ~env f` is new and takes
   care of closing.
4. **JavaScript values are `Js.t`,** not `Yojson.Safe.t`, in `evaluate`, its relatives and
   their `~arg`. Take results apart with `Js.to_string`, `Js.to_int`, `Js.to_list` and so on,
   or, where the result is plain JSON, convert with `Js.to_json`; build arguments with
   `Js.string`, `Js.obj`, ..., or convert with `Js.of_json`. The argument `?is_function` is
   gone: an expression that evaluates to a function is called.
5. **Errors are structured.** `Playwright.Error` used to carry a string; it carries a record
   now. Code that looked for `"TimeoutError:"` at the start of the message matches on the
   kind instead: `exception Playwright.Error { kind = Timeout; _ }`. The text is in the
   field `message`. A call that is wrong whatever the browser does, such as two options that
   exclude each other, raises `Invalid_argument`.
6. **Lists, tuples and variants replace the arrays and records of the protocol.**
   `~args:[ "--no-sandbox" ]` instead of `~args:[| "--no-sandbox" |]`, `~position:(10., 20.)`
   instead of a point record, `` ~modifiers:[ `Shift ] ``, `` ~button:`Right ``, and
   `` Page.get_by_role `Button `` instead of `Page.get_by_role "button"`.
7. **Types are abstract, and objects have identity.** A locator is no longer a record of a
   frame and a selector, and handles are not records with a `guid`. What was read from such
   fields is available through functions (`Locator.page`, `Locator.frame`,
   `Locator.selector`). Objects are compared with the `equal` of their module, as in
   `Page.equal a b`, not with `=` or `==`; `compare` and `hash` are there for
   `Set.Make (Page)` and `Hashtbl.Make (Page)`.
8. **Events are values, and registering returns something.**
   `BrowserContext.on_console context handler` is
   `BrowserContext.on BrowserContext.Console handler context`, and `Page.wait_for_download page`
   is `Page.expect_event Page.Download action page`, which runs the action that causes the
   event. The events are those of Playwright's API rather than those of the protocol:
   console messages, dialogs and requests are events of a page as well as of its context,
   need no `Page.update_subscription`, and carry the object they are about, such as a
   `ConsoleMessage.t`. `on` returns a `Disposable.t`, which removes the listener when it is
   disposed of; where the listener is to stay, write `|> ignore` after the call. Routes,
   init scripts and exposed functions return one as well.
9. **Elements are reached through locators.** The operations that took a selector
   (`Page.fill ~selector`, `Page.eval_on_selector`, `Page.wait_for_selector`) and those of
   `ElementHandle` are gone; Playwright discourages both. `Page.locator selector page` gives
   the locator that has the operation.
10. **The protocol is internal.** `Playwright.Connection`, `Playwright.Transport`,
    `Playwright.Internal`, the `...Params`/`...Result` modules of the channels, and the
    functions that only made sense at that level (`Frame.expect`, `Page.expect`) are gone.
    Assertions are in `Expect`. If something you used is missing, look for the Playwright
    method of the same name in `lib/playwright.mli`, or in [scope.md](scope.md), which lists
    the members that have another name here and those that are left out.

## Function by function

| 0.1 | 0.2 |
| --- | --- |
| `Playwright.create ~env ~sw ()` | unchanged, but see rule 1; also `Playwright.run ~env f` |
| `Playwright.create ~download_timeout ~init_timeout ~shutdown_timeout` | removed. `Playwright.create` can be cancelled at any time, so `Eio.Time.with_timeout` around it limits all of it. |
| `Playwright.create ~max_event_tasks` | removed, see [below](#behaviour-that-changed) |
| `Playwright.create ~on_event_error` | `~on_error:(fun what exn -> ...)` |
| `Playwright.destroy pw` | `Playwright.close pw` |
| `Playwright.Driver.download ~env ()` | `Playwright.Driver.install ()` |
| `Playwright.Playwright.chromium pw` (`firefox`, `webkit`) | `Playwright.chromium pw` |
| `Playwright.Playwright.t` | `Playwright.t` |
| `BrowserType.launch ~headless:true ~args:[\| a \|] bt` | `BrowserType.launch ~args:[ a ] bt`; headless is the default |
| `Page.goto ~url page`, `Page.locator ~selector page`, `Locator.fill ~value locator`, `Locator.press ~key locator`, `Locator.get_attribute ~name locator`, ... | the same without the label: `Page.goto url page` |
| `Page.get_by_role ~name "button" page` | `` Page.get_by_role ~name `Button page `` |
| `Page.evaluate ~expression ?is_function ?arg page` | `Page.evaluate ?arg expression page`, with `Js.t` |
| `Page.wait_for_function ~expression ~polling_interval page` | `Page.wait_for_function ~polling expression page` |
| `Page.fill ~selector ~value page`, and the other operations by selector | `Locator.fill value (Page.locator selector page)` |
| `Page.eval_on_selector ~selector ~expression page` | `Locator.evaluate expression (Page.locator selector page)` |
| `Page.dispatch_event ~selector ~type_ page` | `Locator.dispatch_event type_ (Page.locator selector page)` |
| `Page.wait_for_selector ~selector page` | `Locator.wait_for (Page.locator selector page)` |
| `ElementHandle.click handle`, and the other operations on handles | the same operation of a `Locator` |
| `Locator.type_ ~text locator` | `Locator.press_sequentially text locator` |
| `Locator.select_option ~options:[\| ... \|] locator` | `` Locator.select_option [ `Value "v" ] locator `` |
| `Locator.set_input_files ~local_paths:[\| p \|] locator` | `Locator.set_input_files [ p ] locator` |
| `Locator.element_handle locator` (an option) | returns the handle, or raises |
| `Locator.element_handles locator` | `Locator.all locator`, or `Locator.evaluate_all` for the elements in the page |
| `Locator.is_visible ~timeout locator` | `Locator.is_visible locator` |
| `Locator.bounding_box` returning `Api.Rect.Wrap.t option` | returns `rect option` |
| `Locator.click ~strict:false locator` | removed; use `Locator.first` |
| `Locator.expect ...`, `Frame.expect ...` | the functions of `Expect` |
| `Page.on_<event> page handler` | `Page.on Page.<Event> handler page \|> ignore` |
| `Page.wait_for_<event> page` | `Page.expect_event Page.<Event> action page` |
| `Playwright.Error message` | `Playwright.Error { kind; message; ... }` |

## Behaviour that changed

- **The driver's cache** moved from `playwright-ocaml-driver` to `ocaml-playwright` in the
  user's cache directory; the old directory can be deleted. `PLAYWRIGHT_OCAML_CACHE_DIR` is
  gone: the location follows `XDG_CACHE_HOME`, and `PLAYWRIGHT_OCAML_DRIVER` names a driver
  that is somewhere else.
- **Timeouts.** The defaults are Playwright's: 30 seconds for actions and navigation,
  5 seconds for assertions.
- **Listeners** still run in fibers of their own. `~max_event_tasks`, 1024 by default, was
  the number of events that could be in the hands of listeners before the connection was
  closed, which a page that logs a few thousand lines could reach. Now at most 1024 calls
  are in progress and further ones wait in a queue of up to 65536; only when that is full is
  the connection closed. An exception that escapes from a listener goes to `~on_error`.
- **Route handlers** that raise before they have settled their route abort the request.
- **Closing** is idempotent everywhere, may be called from several fibers at once, and is
  carried out even when the calling fiber is cancelled, so it belongs in
  `Fun.protect ~finally`. When the driver ends, for whatever reason, the objects that came
  from it say that they are closed and their `Close` listeners are called.
- **Cancellation** of a fiber cancels the call it is blocked in and leaves nothing behind:
  a page or a browser that was being created is closed again.
- **Dialogs** are dismissed automatically when nothing listens for them, as in Playwright.
- **URL patterns** are globs in Playwright's syntax; a malformed pattern is an error where
  it is given.
- **Dependencies.** The library needs `eio`, `yojson`, `cstruct`, `base64` and `re` only. The
  HTTP, TLS and tar libraries, the ppx and the C stubs for Windows are gone.
- **Build.** The default build needs no workspace file; `dune-workspace.windows` is the one
  for cross-compiling, see [dev/windows.md](dev/windows.md).

## Notes for Agentiko

Agentiko refers to the library in four places.

*The system prompt* (`lib/context/system_prompt.ml`) shows the model how to start a browser.
In the new API the same steps are:

```ocaml skip
let browser_executable = Some "/usr/bin/chromium";;
let playwright = Playwright.create ~env:eio_env ~sw:eio_sw ();;
let chromium = Playwright.chromium playwright;;
let browser = Playwright.BrowserType.launch ?executable_path:browser_executable ~headless:true chromium;;
let browser_ctx = Playwright.Browser.new_context browser;;
let page = Playwright.BrowserContext.new_page browser_ctx;;
```

and they are closed with `Playwright.Browser.close browser;;` and
`Playwright.close playwright;;`. Two names differ from the old text:
`Playwright.Playwright.chromium` and `Playwright.destroy`. It is worth adding a sentence on
the conventions, since a model that knows the old API, or Playwright for another language,
will otherwise guess the labels wrong: required arguments are positional and come before the
object (`Playwright.Page.goto "https://..." page`), JavaScript values are `Playwright.Js.t`
(`Playwright.Page.evaluate "document.title" page |> Playwright.Js.to_string`), `on` returns
a `Playwright.Disposable.t` (`Playwright.Page.on Playwright.Page.Console f page |> ignore`),
and `#show Playwright.Page;;` prints the functions of a module. For a model that is to act
on pages, `Playwright.Page.aria_snapshot ~mode:`Ai page` and `Playwright.Page.get_by_ref`
are the pair to mention: see [Elements by reference](guide.md#elements-by-reference).

*The driver.* Agentiko relied on `Playwright.create` to download the driver. Now either
its installation runs `ocaml-playwright --version`, which fetches the driver and no browser,
or the program calls `Playwright.Driver.install ()`, which does nothing when the driver is
there, before the first `Playwright.create`; the setup of the prompt could start with
`Playwright.Driver.install ();;`.

*The build scripts.* `scripts/build-windows.sh` refuses a checkout that has no
`lib/driver_process_windows.ml`. There is no such file any more: `lib/driver_process.ml`
serves every system, so that check has to go. The worker's dune file
(`lib/repl/worker/dune`) copies the `.cmi` files of the library for the toplevel, with
`find` from the directory of `playwright.cmi`. This keeps working: `playwright.cmi` is the
only interface that code using the library is checked against. Depending on how the library
is installed, `find` also comes across the interfaces of the implementation, named
`playwright_internal__*.cmi`; copying them does no harm and serves no purpose.

*The browser tests of weft*, in the snapshot that Agentiko builds from
(`.portable/weft/tests`), use `Playwright.Playwright.chromium`, `Playwright.Playwright.t`,
`Playwright.destroy`, `Page.goto ~url`, `Page.wait_for_function ~expression`,
`Page.evaluate ~expression` with results matched as `Yojson.Safe.t`, and
`~args` as an array. Rules 2, 3, 4 and 6 above cover all of them; where the code would
rather keep matching on JSON, `Playwright.Js.to_json` converts an `evaluate` result that is
plain JSON. An integral number is an `` `Int `` now, and a result with `undefined` in it,
which used to be `` `Null ``, is refused.
