# Next Tasks for OCaml Playwright Bindings

Great progress was made in the previous session:
1. **Driver Management (`lib/driver.ml`)**: Downloading and running the pre-compiled Playwright driver binary works successfully via `Eio.Process.spawn`.
2. **Transport Layer (`lib/transport.ml`)**: `stdin`/`stdout` transport layer using `Eio` works.
3. **Connection & Object Registry (`lib/connection.ml`)**: Basic `Connection` logic, handling auto-incrementing IDs and object creation/disposal via `__create__` and `__dispose__` events, works!
4. **Client API Generation (`tools/generate_api.ml` and `tools/generate_protocol.ml`)**:
   - `lib/protocol.ml` now correctly generates variants for enums with manual `to_yojson` and `of_yojson` handlers (to handle dashed strings like `"-inf"` or `"mac-arm64"`).
   - `lib/api.ml` generated functions are fully typed. We successfully called `Api.Root.initialize` and received the resulting `Playwright` object.

### Next Steps:

1. **Connection Lifecycle & Background Loop**:
   - Currently, `Playwright.Connection.run_loop` runs indefinitely, so `test_connection.exe` never exits. We need a way to cleanly shutdown the connection and kill the Playwright driver process.
   - The driver is spawned using `Eio.Process.spawn`. We should probably store the process handle and send it a termination signal (or close the stdin pipe) when the connection is closed.

2. **Wait for Events (Concurrency/Synchronization)**:
   - When Playwright events occur (e.g., `Page.route`), they are sent as asynchronous JSON RPC events (without an `id`).
   - We need an event listener system in `Connection` (or `ChannelOwner`) so users can register callbacks (e.g., `page |> Page.on_route (fun route -> ...)`).

3. **High-Level API Wrappers**:
   - Right now, `Api.ml` exposes raw functions like `Api.Page.goto conn guid args`.
   - We need to wrap these in higher-level OCaml classes or modules that encapsulate the `conn` and `guid` (similar to the Python `Page` class).
   - For example:
     ```ocaml
     let browser = BrowserType.launch playwright.chromium ~headless:true () in
     let page = Browser.new_page browser () in
     Page.goto page "https://example.com" ()
     ```
   - This might require adjusting the generator scripts to generate these wrappers instead of or in addition to the raw API.

4. **Testing**:
   - Write a proper end-to-end test (e.g., opening a browser, navigating to a page, taking a screenshot) to validate the end-to-end flow.
   - Use locally installed browser executable `/usr/bin/chromium`, not a one shipped with bundled Playwright. The bundled browsers work only on Ubuntu, they wont work in Arch Linux.

See `test/test_connection.ml` for a working example of spinning up the driver and sending the `initialize` command.
