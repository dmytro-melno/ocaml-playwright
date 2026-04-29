# Next Tasks for OCaml Playwright Bindings

Good progress was made in the current session:
1. **Wait for Events / Promisification**: Added auto-generated `wait_for_<event> ?predicate` functions to all interfaces. It creates an `Eio.Promise`, registers a temporary listener, evaluates the optional predicate, and cleans up the listener upon success.
2. **Refine Error Handling**: We parsed the JSON payload of `SerializedError` inside `Connection.ml`. If an RPC call returns a serialized Playwright error (like `net::ERR_NAME_NOT_RESOLVED`), it is reconstructed into a readable OCaml string/backtrace, and thrown as an Exception (`Playwright.Hl.Error`).
3. **Integration Tests**: Wrote `test_e2e.ml`, testing TodoMVC with `goto`, `fill`, `press`, and `expect`. Everything passes beautifully.

### Next Steps:

Currently, end-users interact with the `Playwright.Hl` module, which maps 1:1 to the internal Playwright protocol (e.g., calling `Playwright.Hl.Frame.fill ~selector:"..." main_frame`).
However, standard Playwright code (in TS/Python) uses a higher-level client abstraction: `Page`, `Locator`, and `Expect`.

**Task 1: Idiomatic Client-Side Abstractions**
- Create a `Client` (or similar) layer in `lib/` to wrap `Hl`.
- **Page Wrapper**: `Page.goto`, `Page.click`, `Page.fill` should automatically forward to the `mainFrame` of the page.
- **Locator API**: Playwright shifted to a strict Locator-based API. Implement a `Locator` module that holds a `Frame` and a `selector` string.
  - Provide `Page.locator "selector"` which returns a Locator.
  - Implement `Locator.click`, `Locator.fill`, `Locator.press`, etc., which call the corresponding `Frame` protocol functions with `~strict:true` and the captured selector.
  - Support locator chaining (e.g., `Locator.locator "child" loc` -> appends ` >> child`).

**Task 2: Expect Module (Assertions)**
- The protocol provides a `Frame.expect` command. Expose this cleanly in the client API.
- e.g., `Expect.to_have_text "foo" locator`, `Expect.to_have_count 3 locator`. These should map to `Frame.expect ~selector ~expression:"to.have.text" ~expected_text:"foo"`.

**Task 3: Browser Install CLI**
- OCaml Playwright currently requires Chromium to be already installed (or passed via `/usr/bin/chromium`).
- The Node driver supports installing browsers: `node cli.js install`.
- Expose a simple `Playwright.install_browsers ()` or a dune executable that developers can run to download the Playwright browsers.

Start by reviewing `test_e2e.ml` to see the current raw `Hl` usage, and design the `Locator` module to simplify it.
