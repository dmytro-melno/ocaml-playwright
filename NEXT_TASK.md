# Next Tasks for OCaml Playwright Bindings

Tremendous progress was made in the previous session:
1. **High-Level API Wrappers**: We implemented the `tools/generate_hl.ml` script which correctly generated `lib/hl.ml`. This encapsulates the low-level `Api` and `Protocol` modules.
   - Requires minimal syntax from the end-user (labeled arguments instead of `Protocol` records).
   - Generates getters for object initializer properties (e.g., `Page.main_frame page`).
   - Exceptions are raised via `Playwright.Hl.Error of string` instead of messy `Result` unwrapping for RPC replies.
2. **Typed Event Listeners**: Events are now generated with typed callback signatures (`on_<event_name> t cb`). The `Connection.on` function has been refined to append typed listeners to objects.
3. **End-to-End Success**: Tested using `test/test_hl2.ml`. We successfully used the high-level wrappers to start the driver, launch Chromium, create a context, create a page, extract the `mainFrame` getter, and `goto` `example.com` cleanly.

### Next Steps:

1. **Top-Level Orchestration API (`playwright.ml`)**:
   - Currently, starting the driver and spinning up the connection loop requires 20 lines of boilerplate (`Eio.Process.pipe`, `Driver.run`, `Connection.create`, `Root.initialize`, etc.).
   - Create a `Playwright.create ~sw ~env ()` function that handles the driver run loop and root initialization in the background, returning a user-friendly high-level `Playwright` object (the one with the `chromium`, `firefox`, and `webkit` getters).
   - Add a `Playwright.close` or `stop` to cleanly kill the Eio pipes and driver process.

2. **Wait for Events / Promisification**:
   - Currently, `on_event` just registers a callback. We need a way to block the current fiber until a specific event fires (like `page.wait_for_request()` in Python).
   - Eio's `Promise` can be used to wrap events. Write a generalized `wait_for_event` utility.

3. **Refine Error Handling**:
   - Enhance the exception thrown in `Hl.ml`. If `dispatch` receives a full error stack trace via `SerializedError`, we should parse it and present it as a native OCaml backtrace or detailed string, using the `Error.ml` template drafted previously.

4. **Integration Tests**:
   - Translate standard Playwright end-to-end tests into our OCaml bindings to test locators, clicks, typing, and expect checks.

Start by examining `test/test_hl2.ml` and `lib/connection.ml` to see the current working boilerplate, then write the high-level `Playwright.create` orchestrator inside `lib/playwright.ml`.
