# Migrating from 0.1

Version 0.2 is a rewrite. The earlier versions, which targeted Playwright 1.59, exposed the
functions that were generated from Playwright's protocol, with some helpers on top. The
library now offers the Playwright API itself, hand-written over a generated protocol layer
that is no longer visible. Programs need to be adapted; this page tells how.

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

After:

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

1. **Required arguments are positional now.** `~url`, `~selector`, `~expression`, `~value`,
   `~key`, `~name`, `~text`, `~target` and the like have lost their labels. The object still
   comes last. The compiler points at every place: a label that no longer exists is an error.
2. **The driver's functions are at the top level.** `Playwright.Playwright.chromium` is
   `Playwright.chromium`, and `Playwright.destroy` is `Playwright.close`.
   `Playwright.create ~sw ~env ()` is as before; `Playwright.run ~env f` is new and takes
   care of closing.
3. **JavaScript values are `Js.t`,** not `Yojson.Safe.t`, in `evaluate`, its relatives and
   their `~arg`. Take results apart with `Js.to_string`, `Js.to_int`, `Js.to_list` and so on,
   or convert with `Js.to_json`; build arguments with `Js.string`, `Js.obj`, ..., or convert
   with `Js.of_json`. The argument `?is_function` is gone: an expression that evaluates to a
   function is called.
4. **Errors are structured.** `Playwright.Error` used to carry a string; it carries a record
   now. Code that looked for `"TimeoutError:"` at the start of the message matches on the
   kind instead: `exception Playwright.Error { kind = Timeout; _ }`. The text is in the
   field `message`.
5. **Lists and tuples replace arrays and records of the protocol.** `~args:[ "--no-sandbox" ]`
   instead of `~args:[| "--no-sandbox" |]`, `~position:(10., 20.)` instead of a point record,
   `` ~modifiers:[ `Shift ] ``, `` ~button:`Right ``.
6. **Roles are polymorphic variants:** `` Page.get_by_role `Button `` instead of
   `Page.get_by_role "button"`.
7. **Types are abstract.** A locator is no longer a record of a frame and a selector, and
   handles are not records with a `guid`. What was read from such fields is available
   through functions (`Locator.page`, `Locator.frame`), and objects are compared with `==`.
8. **Events are values.** `Page.on_console handler page` is
   `Page.on Page.Console handler page`, and `Page.wait_for_console` is
   `Page.wait_for_event Page.Console page` or, better, `Page.expect_console_message`. The
   event carries the object it is about, such as a `ConsoleMessage.t`, rather than the
   parameters of the protocol message.
9. **The protocol is internal.** `Playwright.Connection`, `Playwright.Transport`,
   `Playwright.Internal`, the `...Params`/`...Result` modules of the channels, and the functions
   that only made sense at that level (`Frame.expect`, `Page.expect` with protocol
   expressions) are gone. Assertions are in `Expect`. If something you used is missing,
   look for the Playwright method of the same name in `lib/playwright.mli`.

## Function by function

| 0.1 | 0.2 |
| --- | --- |
| `Playwright.create ~env ~sw ()` | unchanged; also `Playwright.run ~env f` |
| `Playwright.create ~download_timeout ~init_timeout ~shutdown_timeout ~max_event_tasks` | removed; cancel the fiber to give up early |
| `Playwright.create ~on_event_error` | `~on_error:(fun what exn -> ...)` |
| `Playwright.destroy pw` | `Playwright.close pw` |
| `Playwright.Playwright.chromium pw` (`firefox`, `webkit`) | `Playwright.chromium pw` |
| `Playwright.Playwright.t` | `Playwright.t` |
| `BrowserType.launch ~headless:true ~args:[\| a \|] bt` | `BrowserType.launch ~args:[ a ] bt`; headless is the default |
| `Page.goto ~url page` | `Page.goto url page` |
| `Page.locator ~selector page` | `Page.locator selector page` |
| `Page.get_by_role ~name "button" page` | `` Page.get_by_role ~name `Button page `` |
| `Page.evaluate ~expression ?is_function ?arg page` | `Page.evaluate ?arg expression page`, with `Js.t` |
| `Page.wait_for_function ~expression ~polling_interval page` | `Page.wait_for_function ~polling expression page` |
| `Page.eval_on_selector ~selector ~expression page` | `Page.eval_on_selector selector ~expression page` |
| `Page.dispatch_event ~selector ~type_ page` | `Page.dispatch_event selector ~type_ page` |
| `Locator.locator ~selector locator` | `Locator.locator selector locator` |
| `Locator.fill ~value locator` | `Locator.fill value locator` |
| `Locator.press ~key locator` | `Locator.press key locator` |
| `Locator.type_ ~text locator` | `Locator.press_sequentially text locator` |
| `Locator.get_attribute ~name locator` | `Locator.get_attribute name locator` |
| `Locator.evaluate ~expression locator` | `Locator.evaluate expression locator` |
| `Locator.select_option ~options:[\| ... \|] locator` | `` Locator.select_option [ `Value "v" ] locator `` |
| `Locator.set_input_files ~local_paths:[\| p \|] locator` | `Locator.set_input_files [ p ] locator` |
| `Locator.element_handle locator` (an option) | returns the handle, or raises |
| `Locator.element_handles locator` (an array) | a list |
| `Locator.is_visible ~timeout locator` | `Locator.is_visible locator` |
| `Locator.bounding_box` returning `Api.Rect.Wrap.t option` | returns `rect option` |
| `Locator.click ~strict:false locator` | removed; use `Locator.first` |
| `Locator.expect ...`, `Frame.expect ...` | the functions of `Expect` |
| `Page.on_<event> handler page` | `Page.on Page.<Event> handler page` |
| `Page.wait_for_<event> page` | `Page.expect_<event> action page`, `Page.wait_for_event Page.<Event> page` |
| `Playwright.Error message` | `Playwright.Error { kind; message; ... }` |

## Behaviour that changed

- **The driver** is still downloaded on first use, but by Node.js itself. The cache moved
  from `playwright-ocaml-driver` to `ocaml-playwright` in the user's cache directory; the
  old directory can be deleted. `PLAYWRIGHT_OCAML_CACHE_DIR` still overrides the location.
- **Timeouts.** A timeout is reported as `Playwright.Error` with the kind `Timeout`. The
  defaults are Playwright's: 30 seconds for actions and navigation, 5 seconds for assertions.
- **Listeners** still run in fibers of their own. The number of listener calls in progress
  is no longer limited, and there is no `max_event_tasks`.
- **Dialogs** are dismissed automatically when nothing listens for them, as in Playwright.
- **Dependencies.** The library needs `eio`, `yojson` and `base64` only. The HTTP, TLS and
  tar libraries, the ppx and the C stubs for Windows are gone.
- **Build.** There is one `dune-workspace.windows` for cross-compiling; the default build
  needs no workspace file.

## Notes for Agentiko

Agentiko refers to the library in three places.

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
`Playwright.close playwright;;`. Only two things differ from the old text:
`Playwright.Playwright.chromium` and `Playwright.destroy`. It is worth adding a sentence on
the conventions, since a model that knows the old API, or Playwright for another language,
will otherwise guess the labels wrong: required arguments are positional and come before the
object (`Playwright.Page.goto "https://..." page`), JavaScript values are `Playwright.Js.t`
(`Playwright.Page.evaluate "document.title" page |> Playwright.Js.to_string`), and
`#show Playwright.Page;;` prints the functions of a module.

*The worker's dune file* (`lib/repl/worker/dune`) copies the `.cmi` files of the library for
the toplevel. This keeps working: the directory now holds `playwright.cmi` and the
interfaces of the internal modules, named `playwright__*.cmi`. Only `playwright.cmi` is
needed to type-check code that uses the library, but copying all of them does no harm.

*The browser tests of weft* (`.windows/weft/tests`) use `Playwright.Playwright.chromium`,
`Playwright.Playwright.t`, `Playwright.destroy`, `Page.goto ~url`,
`Page.wait_for_function ~expression`, `Page.evaluate ~expression` with results matched as
`Yojson.Safe.t`, and `?chromium_args:string array`. Rules 1, 2, 3 and 5 above cover all of
them; `Playwright.Js.to_json` gives the old shape of an `evaluate` result where the code
would rather keep matching on JSON.
