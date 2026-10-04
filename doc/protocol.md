# Protocol compatibility and migration (1.59.1)

## Version and provenance

The driver and generated API target **Playwright 1.59.1**. The vendored
`protocol/protocol.yml` is byte-for-byte upstream:

- Source: <https://raw.githubusercontent.com/microsoft/playwright/v1.59.1/packages/protocol/src/protocol.yml>
- SHA-256: `7245482d2da69e04476345536696093dc59b9a67a53859e281321117bfc637a3`

`protocol/provenance.json` is the version authority. Dune validates the source
URL/version and schema hash, then generates both the API and the version used
by `Driver`. Ordinary builds do **not** fetch the schema. The offline verifier
uses the declared `digestif` build-tool dependency. A version update requires
reviewing the exact schema, manifest, generated API and matching reference
tests together; changing a driver version literal is no longer sufficient.

```sh
dune exec tools/verify_protocol.exe -- check protocol/protocol.yml protocol/provenance.json
dune build @all
```

The verifier detects accidental drift; the checked-in provenance is not a
cryptographic attestation of upstream. Review the manifest against the pinned
upstream source when updating it. The upstream trailing blank lines are
intentional (and can trigger `git diff --check`'s EOF warning).

## Bytes are raw bytes, at every schema depth

A protocol `binary` field is now consistently `Playwright.Binary.t`, a public
alias of OCaml `string`. Its contents are **raw bytes**, not Base64 and not
necessarily UTF-8. Encoding/decoding happens at the binary leaf in generated
code, recursively through records, optional fields and arrays.

This applies to:

- direct screenshot, PDF, response-body and request-body parameters/results;
- `Frame.SetInputFilesParams_Payloads.buffer` and `FormField.File.buffer`;
- `Page.ExpectScreenshotResult.actual`, `diff` and `previous`;
- `Page.ScreencastFrameEvent.data`;
- `Request.Initializer.post_data` and `SerializedValue.Ta.b`;
- other fields declared `binary`, including those in optional/multi-field
  results, nested records, initializers and events.

For example, pass a raw string containing NUL and non-UTF-8 data:

```ocaml
Page.set_input_files ~selector:"#file"
  ~payloads:[|Frame.SetInputFilesParams_Payloads.{
    name = "raw.bin";
    mime_type = Some "application/octet-stream";
    buffer = "\000\255\128Hello";
  }|] page
```

**Remove old nested-field Base64 workarounds.** Passing `"SGVsbG8="` now uploads
those eight ASCII bytes, not `"Hello"`. Likewise, do not Base64-decode returned
screenshot/event strings again. Encode bytes explicitly for JSON logs or text
storage if necessary.

Ordinary protocol `string`/`json`/`any` values are not transformed. In particular,
a `string` accompanied by an explicit `isBase64` flag (such as route or
WebSocket data) still follows that method's declared protocol; it is not a
`binary` field.

`Binary.of_yojson` returns an error for non-string or noncanonical Base64 input
(invalid alphabet, padding, whitespace, trailing data or nonzero padding bits).
Generated command decoders propagate failure; event decoder errors use the
existing event-error reporting mechanism. Canonical padded standard Base64,
including the empty string, is accepted. This is deliberately stricter on
malformed input than JavaScript's permissive `Buffer.from(s, "base64")`; bytes
emitted by Playwright use canonical encoding.

`Connection.channel_owner.initializer_` is still **raw wire JSON**. The generated
`Request.Initializer.of_yojson` codec produces decoded fields; there is no second
transformation in Connection. The existing handle-decoding context requirement
for records containing channel handles is unchanged (there is no new general
public initializer accessor in this change).

## Anonymous type names now identify schema paths

The former leaf-only module names silently conflated incompatible records and
enums. Anonymous modules within an interface now use:

- `CommandParams_Field` for command parameters;
- `CommandResult_Field` for return fields;
- `EventEvent_Field` for nested fields of an event named `event`;
- `Initializer_Field` for initializer fields.

The command/event portion preserves upstream capitalization after capitalizing
its first letter (`StopCSSCoverage`, for example). Each field segment is
capitalized snake case, including OCaml keyword escaping. Nested field paths
append another segment; arrays and optionality do not discard the element's
path. Multi-field return/event root records keep names such as `ExpectResult`
and `ConsoleEvent`.

Top-level named protocol types remain named. Their immediate anonymous children
keep names such as `FormField.File`, `SerializedValue.O` and `SerializedValue.Ta`;
deeper names include that child path (`SerializedValue.Ta_K`).

Examples of source migrations (select the method-specific type, not a generic
alias to one old collision):

| Former name/use | Correct name/use |
| --- | --- |
| `BrowserContext.Event` for subscriptions | `BrowserContext.UpdateSubscriptionParams_Event` |
| `BrowserContext.Mode` for recorder mode | `BrowserContext.EnableRecorderParams_Mode` |
| `ElementHandle.State` for selector waits | `ElementHandle.WaitForSelectorParams_State` |
| `ElementHandle.State` for actionability | `ElementHandle.WaitForElementStateParams_State` |
| `Frame.State` for waits | `Frame.WaitForSelectorParams_State` |
| `Frame.Payloads` | `Frame.SetInputFilesParams_Payloads` |
| `Frame.Options` for select-option | `Frame.SelectOptionParams_Options` |
| `Frame.Modifiers` / `Frame.Button` for click | `Frame.ClickParams_Modifiers` / `Frame.ClickParams_Button` |
| `ElementHandle.Type_`, `Caret`, `Mask`, etc. for screenshots | `ElementHandle.ScreenshotParams_Type_`, `ScreenshotParams_Caret`, `ScreenshotParams_Mask`, etc. |
| `Page.Patterns` for network interception | `Page.SetNetworkInterceptionPatternsParams_Patterns` |
| `Page.Messages` for console history | `Page.ConsoleMessagesResult_Messages` |
| `JSHandle.Properties` for property lists | `JSHandle.GetPropertyListResult_Properties` |
| `Page.Entries` for JS coverage | `Page.StopJSCoverageResult_Entries` |
| `Page.Entries` for CSS coverage | `Page.StopCSSCoverageResult_Entries` |
| collided coverage `Ranges` | JS: `StopJSCoverageResult_Entries_Functions_Ranges`; CSS: `StopCSSCoverageResult_Entries_Ranges` |
| nested console `Location` | `BrowserContext.ConsoleEvent_Location` (or the relevant history method's path) |
| screenshot protocol locator record | `Page.ExpectScreenshotParams_Locator` (not the handwritten `Locator.t`) |

Page methods proxied to Frame use **Frame's** parameter/result modules.

Structurally equal records at different paths can still be distinct OCaml
record types. Do not assume all old shared records are interchangeable. Repeated
definitions at the *same generated name* are deduplicated only when both their
rendered type and codec definitions agree. Incompatible duplicates, normalized
label/variant/function conflicts, invalid identifiers and shadowing of outer
protocol/runtime modules fail generation with a diagnostic. No incompatible
compatibility aliases are provided.

Correct selector states are `` `Attached | `Detached | `Visible | `Hidden ``.
`` `Enabled `` belongs to `wait_for_element_state`, not `wait_for_selector`.
Context subscriptions accept `` `Console | `Dialog | `Request | `Response |
`Request_finished | `Request_failed ``; recorder values such as `` `Action_added ``
are not subscription events. Subscription is still explicit; merely registering
a callback does not enable a gated event. `pageError` itself is not gated by
`updateSubscription`.

## Schema/API alignment

These are intentional breaking corrections, not newly emulated capabilities:

- `Frame.ExpectResult.received` is `SerializedValue.t option`, not an anonymous
  object containing `value` and `ariaSnapshot`. For a failed count expectation,
  inspect `(Option.get result.received).n`, or use `Value.parse_serialized_value`
  on that value.
- `BrowserContext.PageErrorEvent` contains `error` and `page`; the extra required
  `location` was not sent by 1.59.1.
- `har_start` / `har_export` belong to **BrowserContext**, not Tracing.
- `BindingCall.Initializer.args` is optional; `handle : JSHandle.t option` is
  present. Page/context `expose_binding` accepts `?needs_handle`.
- Launch options include `?assistant_mode`. The Playwright initializer includes
  Electron; `Electron` and `ElectronApplication` now come from the exact schema.
- `BrowserType.connect_to_worker` is removed; upstream has
  `connect_over_cdp_transport` with binary transport data and browser/context
  results. These are different operations, not a rename with equivalent
  semantics. `connect_over_cdp` no longer has `?no_defaults`.
- Remove unsupported Page `hide_highlight`, Frame `aria_ref`, `drop`,
  `hide_highlight`, Worker `disconnect` and Worker-specific `on_console` /
  `wait_for_console`. Page proxies of removed Frame commands disappear too.
- Remove Frame/Page `aria_snapshot`'s `?boxes`, Frame/Locator `highlight`'s
  `?style`, and Frame/Page/Locator `expect`'s `?pseudo`.
  Screenshot `?style` remains supported. `highlight` takes only its selector
  at the protocol level.
- `WebSocketRoute.Initializer.protocols` is removed.

Do not send removed extensions to the 1.59.1 driver or treat them as successful
no-ops. Protocol presence for Electron/remote/CDP-transport/platform-specific
features is not a claim of live platform coverage.

## Special values and unchanged limitations

YAML enum spellings are preserved lexically. The special-value wire strings are
exactly `NaN`, `Infinity`, `-Infinity`, `-0`, `null` and `undefined`.

Migrate `` `Inf `` to `` `Infinity `` and `` `Minus_inf `` to
`` `Minus_infinity ``. `` `Nan `` remains the OCaml tag but now encodes `"NaN"`,
not `"nan"`. Both generated encoder and decoder implement the exact wire forms.

The convenience parser still represents incoming NaN/infinities as JSON strings
and negative zero as a float. This does **not** implement a richer JavaScript
value API: shared/cyclic object reconstruction, typed arrays in convenience
results, omitted-argument versus null semantics and outgoing nonfinite float
handling remain separate limitations. The convenience expectation helper's
explicit-null limitation is also unchanged; `expect_raw` with an explicitly
constructed `SerializedArgument` is still the control.

Session identity, reentrant callbacks, cancellation recovery, Locator strictness,
single-budget acquisition and late-handle ownership are unchanged. See
[lifecycle](lifecycle.md) and [Locator](locators.md) contracts.

## Regression tests

See [protocol tests](../test/protocol/README.md) for offline checks, compiled
synthetic fixtures, byte/enum codecs and bounded live OCaml/JS 1.59.1 comparisons.
