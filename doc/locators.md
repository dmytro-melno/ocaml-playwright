# Locators: strictness, selectors, timeouts and handles

The handwritten Locator layer targets **playwright-core 1.59.1**. The behavior
below is covered by freshly built OCaml tests and a pinned JavaScript comparison
using the same Chromium executable. This is not a claim of complete JavaScript
API, serialization, or browser-engine parity.

## Strict by default

A single-element Locator operation rejects **more than one match** with
`Playwright.Error` containing `strict mode violation`. It must not silently
act on the first match. This includes actions, getters, state queries,
`wait_for` (including hidden/detached waits), `evaluate`, `element_handle`,
`bounding_box`, scrolling and screenshots.

Prefer identifying the intended element:

```ocaml
let save = Page.get_by_role ~name:"Save" ~exact:true "button" page in
Locator.click ~timeout:2000. save
```

Disambiguation is explicit, and indexes are zero-based:

```ocaml
let buttons = Page.locator ~selector:"button" page in
Locator.click (Locator.first buttons);
Locator.click (Locator.nth 1 buttons);
let last_text = Locator.inner_text (Locator.last buttons) in
ignore last_text
```

`first`/`last`/`nth` remain live locators, not snapshots of DOM identity. Use them
only when the ordering is intentional. An `or_` union matching two different
elements is still ambiguous for `click`; union does not choose a preferred arm.

Existing methods that expose `?strict` retain **`~strict:false` as an OCaml
compatibility extension**. It opts back into unsafe first-match behavior.
Prefer explicit disambiguation, especially in agent code. Methods without that
option always enforce strictness. Raw `Frame`/`Page` selector methods have not
had their defaults changed.

Plural operations remain plural: `count`, `evaluate_all`, `element_handles`,
`all`, `all_inner_texts`, `all_text_contents` and `highlight`. They do not wait
for a desired number of elements. `all` produces indexed locators for the
current count; it does not freeze the elements.

`Locator.expect` is a low-level protocol extension, **not** Playwright Test's
assertion API. Single-target expressions report ambiguity in the returned
`ExpectResult.error_message` with `matches = false`; they do not necessarily
raise. Count/array expressions are plural. Inspect the result. Existing
serialization limitations in this extension remain.

## Selector helpers and composition

Use the shared helpers on `Page`, `Frame` or a nested `Locator`:

- `get_by_text` / `get_by_label`: text matching; default substring,
  case-insensitive matching, or `~exact:true`.
- `get_by_role ~name`, `get_by_placeholder`, `get_by_alt_text`,
  `get_by_title`: Playwright's corresponding internal matchers.
- `get_by_test_id`: exact, case-sensitive attribute matching.
- `filter ~has_text`: case-insensitive substring matching with Playwright's
  text whitespace normalization, not whole-string equality.
- `filter ~has`: retain elements with a matching descendant. The inner locator
  is evaluated relative to each candidate, not from the document root.
- `and_` / `or_`: intersection/union of locator selectors, including mixed
  engines and chained selectors. They are not CSS string concatenation.

```ocaml
let rows = Page.locator ~selector:"article" page in
let ready_rows = Locator.filter ~has_text:"READY" rows in
let with_save =
  Locator.filter ~has:(Page.get_by_role ~name:"Save" "button" page) ready_rows
in
let choices = Locator.or_ with_save (Page.get_by_test_id "fallback" page) in
ignore (Locator.count choices)
```

Strings are encoded according to their grammar: JSON for nested selectors and
text matchers; the attribute matcher grammar for attribute values and role
names. Quotes, backslashes, LF, TAB, CR and valid UTF-8 text are covered by
tests. Do not pre-escape helper arguments or use the nested-selector JSON
encoder as a general CSS identifier/attribute escape function. Raw
`locator ~selector` strings remain the caller's responsibility.

### Test-ID attribute configuration

The default is `data-testid`. The existing context API now affects all three
helper entry points, including frames in that context:

```ocaml
BrowserContext.set_test_id_attribute_name
  ~test_id_attribute_name:"data-qa" context;
let submit = Page.get_by_test_id "submit" page in
Locator.click submit
```

The `~test_id_attribute_name` context creation option is also honored.
Configuration is **context-local**, unlike JavaScript 1.59.1's global
`selectors.setTestIdAttribute`. Different contexts/sessions do not overwrite
one another's configuration. Set it before constructing locators: an existing
locator keeps its encoded selector when configuration changes.

### Frames and sessions

`and_`, `or_`, `filter ~has` and `drag_to` require the same underlying frame
**and exact session**. Equivalent wrappers for one frame work; equal GUID
strings in different sessions do not. Incompatible operands raise
`Invalid_argument` mentioning `same frame and session`, before sending an RPC.

This deliberately strengthens JavaScript 1.59.1 `dragTo`, which only uses the
target's selector and does not perform the explicit frame check found in
`and`/`or`/`has`. Cross-frame drag is not implemented. Do not pass a foreign
locator expecting it to be reinterpreted in the source frame.

These are locator-operand checks, not a new parser for arbitrary raw selectors.
There is no typed `FrameLocator` API, locator-valued `locator` overload,
regex helper argument, or `has_not` helper in this batch.

## Immediate queries versus waits

`is_visible` and `is_hidden` query the current visibility state without waiting
for it to change. Hidden/absent elements give `false`/`true` respectively.
They still take an RPC round trip; “immediate” does not mean offline or
zero-latency. Neither allocates an ElementHandle.

Invalid selectors, ambiguity, target closure and connection errors remain
errors. Do not interpret an operational failure as “not visible”.

The existing `is_visible ?timeout` argument is retained but **ignored**, like
JavaScript's compatibility option. In particular, `~timeout:0.` does not turn
this query into an unlimited visibility wait.

```ocaml
if Locator.is_visible save then Printf.printf "Visible now\n%!";
Locator.wait_for ~state:`Visible ~timeout:2000. save;
Locator.click ~timeout:2000. save
```

Use `wait_for` for a state transition. Its default state is visible.
Other state getters such as `is_enabled` can wait for the target to exist,
but they are not retrying assertions that wait for the returned boolean to
become true. Actions perform their own Playwright actionability checks.

## Timeout rules

Locator timeout arguments use **milliseconds**, unlike
`Eio.Time.with_timeout_exn`, which uses seconds. Default waiting/action budgets
are 30,000 ms in this binding. It does not expose/mirror JavaScript's mutable
page/context default-timeout settings or `PWDEBUG` timeout policy.

| Operation | Meaning of `timeout` |
| --- | --- |
| Ordinary actions, waiting getters, `wait_for` | Forwarded to the appropriate strict Frame operation |
| `is_visible` | Ignored; immediate query |
| `is_hidden` | No timeout option; immediate query |
| `element_handle` | Resolve a strict, attached element |
| `evaluate` | Resolve a strict, attached element **only** |
| `bounding_box` | Resolve a strict, attached element **only** |
| `scroll_into_view_if_needed`, `screenshot` | One monotonic budget for acquisition and the subsequent element operation |
| Plural operations | No element-appearance wait or Locator timeout option |

For waiting operations, `timeout = 0` means no overall operation deadline.
Handle-based helpers reject negative/non-finite budgets. Expired finite
deadlines raise `Playwright.Error` containing `TimeoutError:`; they are never
converted to zero/unlimited. Screenshot/scroll do not restart the whole timeout
after acquisition.

**`Locator.evaluate ~timeout` is not a JavaScript execution timeout.** An
arbitrary promise may remain pending after element acquisition, just as in
the reference. If needed, impose an application-level Eio deadline:

```ocaml
let result =
  Eio.Time.with_timeout_exn (Eio.Stdenv.clock env) 5. (fun () ->
    Locator.evaluate ~timeout:1500. ~expression:"el => el.textContent" save)
in
ignore result
```

Cancellation stops the local wait, not arbitrary JavaScript or a remote action.
It cannot undo side effects already performed in the browser.

## Temporary and caller-owned handles

`evaluate`, `bounding_box`, `scroll_into_view_if_needed` and `screenshot` resolve
one strict, attached element, operate on **that same handle**, then release it.
They do not re-query a selector after acquisition.

- `bounding_box` uses Playwright's element geometry: `None` for a `display:none`
  element; iframe coordinates are relative to the top-level viewport. This is
  not an occlusion test, and CSS `visibility:hidden` is not equivalent to
  having no layout box.
- Scrolling uses Playwright's actionability/stability operation, not a DOM
  `scrollIntoView` substitute. A hidden element can time out.
- `screenshot` returns a binary OCaml string, not a base64-encoded string.
- Temporary handles are disposed after success, error or caller cancellation.
  A cleanup failure does not replace an existing operation error/cancellation.

In contrast, successful `element_handle` and `element_handles` transfer
ownership to the caller. Other Locator operations do not dispose those handles:

```ocaml
match Locator.element_handle ~timeout:2000. save with
| None -> () (* retained option return type; normal absence waits then times out *)
| Some handle ->
    Fun.protect ~finally:(fun () -> ElementHandle.dispose handle) (fun () ->
      ignore (ElementHandle.bounding_box handle))
```

Dispose each handle returned in an `element_handles` array. Caller-owned
finalizers need their own cancellation/error policy; the library's internal
ownership helper is not a general-purpose public handle scope.

### Normal acquisition versus bounded ownership recovery

An uncanceled singular acquisition sends **one** strict attached-wait request
with its available timeout. It does not split selector execution into short
retry attempts. `element_handles` sends one plural query, without an appearance
wait. Neither has an independent one-second acquisition deadline: a slow
selector, a temporarily busy page, or local write-lock contention is not in
itself grounds for closing the session. A plural query must still wait for the
page's JavaScript event loop even though it does not wait for elements to appear.

Playwright 1.59.1 has no per-request remote cancellation. Merely dropping the
response wait could lose a newly created handle. Locator acquisition therefore
uses this explicit ownership policy:

- Before transmission, cancellation sends no request and requires no recovery.
  Cancellation during a possibly partial frame write retains the connection's
  conservative stream-corruption close policy.
- After a complete request was sent, cancellation starts a **one-second
  response-recovery deadline**. The caller retains the original response
  promise; the reader still only dispatches responses. A late handle is decoded
  and disposed, not handed to a canceled caller.
- If that canceled request cannot settle within the recovery deadline, close
  **that Playwright session** and propagate the original cancellation. This
  affects all of its browsers/contexts/pages, not unrelated sessions. There is
  no detached cleanup fiber or indefinitely retained pending request.
- Internally owned handle disposal is separately cancellation-protected and
  bounded to **one second per handle**. Failed/stalled disposal closes the
  session; an existing operation error/cancellation remains primary. An
  already-closed connection requires no disposal RPC, and target-already-closed
  disposal is tolerated. Secondary cleanup errors are diagnosed on stderr.

This is a deliberate Eio ownership/recovery policy, **not JavaScript cancellation
parity**. For example, an uncanceled `timeout:0` wait can remain pending
indefinitely. If its caller cancels while the element is still absent, the
remote wait may never reply: the recovery deadline then closes that session.
If the element appears, or the server's finite timeout expires during recovery,
the response can be consumed and the session stays usable. An ordinary,
uncanceled `timeout:0` request has no such recovery timer.

Cleanup adds latency beyond the operation/application budget. Unpublished
plural handles are released individually. Bounds require cooperative Eio
scheduling, not hard real time. Recovery does not cancel already-running
JavaScript or actions and does not impose an execution timeout on evaluation.

The underlying lifecycle guarantees (exact-session identity, reader-independent
callbacks, pending-entry removal, bounded shutdown) remain unchanged. See
[lifecycle semantics](lifecycle.md) and
[locator regression instructions](../test/locator/README.md).

## Compatibility limits

This repairs the existing Locator surface, not all JavaScript APIs or generated
protocol codecs. Rich role options, regex helpers, cross-frame composition,
mask/other nested protocol option correctness, special JavaScript values and
general recursive channel disposal are not newly guaranteed. Firefox, WebKit,
CDP attachment and persistent-context configurations were not differentially
tested in this batch. See the [initial implementation report](../review/LOCATOR_FIXES.md)
and [acquisition revision report](../review/LOCATOR_REVISIONS.md) for the exact
validated scope and remaining review findings.
