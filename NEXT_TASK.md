# Next Tasks for OCaml Playwright Bindings

Great progress was made in the previous session:
1. **Connection Lifecycle & Background Loop**: Handled successfully. The connection loop runs in an Eio Fiber, and shutting down the pipes allows the driver process to exit cleanly without hanging.
2. **Protocol Generation for Mixins**: The `tools/generate_protocol.ml` generator was updated to correctly expand `$mixin` and `$mixin1` references from `protocol.yml`. Previously, fields like `headless` or `executablePath` were missing from the `launch` arguments. Now, they are correctly generated, and all APIs typecheck.
3. **End-to-End Navigation Test**: We successfully wrote an end-to-end test (`test/test_connection.ml`) that:
   - Starts the Playwright driver.
   - Initializes the connection.
   - Launches a Chromium browser (`BrowserType.launch`).
   - Creates a browser context (`Browser.new_context`).
   - Creates a new page (`BrowserContext.new_page`).
   - Navigates to `https://example.com` (`Frame.goto`).

The generated low-level APIs work perfectly and communicate gracefully with the Playwright driver process.

### Next Steps:

1. **High-Level API Wrappers**:
   - Right now, the low-level generated API in `Api.ml` requires users to explicitly construct large records with many `None` values and manually pass `Connection.t` and object `guid`s around.
   - We need to create high-level OCaml wrappers that encapsulate the `Connection.t` and `guid` (similar to the Python `Page` and `Browser` classes).
   - This should ideally be generated automatically by a script (e.g. `tools/generate_high_level_api.ml`), or by extending `tools/generate_api.ml` to output a user-friendly wrapper module.
   - The user-friendly functions should use optional labeled arguments instead of requiring the user to pass a record with 30 `None`s.
   - Example desired syntax:
     ```ocaml
     let playwright = Playwright.create ~sw ~env () in
     let browser = BrowserType.launch playwright.chromium ~headless:true () in
     let page = Browser.new_page browser () in
     Page.goto page "https://example.com" ()
     ```

2. **Wait for Events (Concurrency/Synchronization)**:
   - When Playwright events occur (e.g., `Page.route`), they are sent as asynchronous JSON RPC events.
   - `lib/connection.ml` already maintains an `events` hashtable for objects. We need to expose a typed event listener system so users can register callbacks (e.g., `Page.on_request page (fun req -> ...)`).

3. **Error Handling**:
   - Wrap the `Error "msg"` results into specific exceptions or a unified error type.

Start by looking at `test/test_connection.ml` to see the working low-level flow, and begin designing the generation logic for the high-level API.
