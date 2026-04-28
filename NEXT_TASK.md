# Next Tasks for OCaml Playwright Bindings

The OCaml types corresponding to the objects, enums, mixins, commands, and events from Playwright's `protocol.yml` have been generated into `lib/protocol.ml` using a topological sort to handle mutually recursive types.

The next steps are:

1. **Driver Management (`lib/driver.ml`)**:
   - Implement downloading of the pre-compiled Playwright driver binary (which bundles Node.js and Playwright Core). The URL structure is typically:
     `https://playwright.azureedge.net/builds/driver/playwright-<version>-<platform>-<arch>.zip` (or similar, needs to be researched for the exact URL format used by Python/Java).
   - Alternatively, for local development, we can spawn `node packages/playwright-core/cli.js run-driver` inside the Playwright source directory if available, but downloading the binary is the standard approach for language bindings.

2. **Transport Layer (`lib/transport.ml`)**:
   - Implement the `stdin`/`stdout` transport layer using `Eio`.
   - The protocol uses a 32-bit Little-Endian Unsigned Integer representing the length (in bytes) of the JSON payload, followed by the UTF-8 encoded JSON string itself.
   - We need an `Eio` loop reading these messages and parsing them with `Yojson`.
   - We also need a function to send messages using the same framing.

3. **Connection & Object Registry (`lib/connection.ml`)**:
   - Implement the `Connection` registry.
   - Keep track of objects by `guid`.
   - Handle the `__create__`, `__adopt__`, and `__dispose__` messages to manage the object lifecycle.
   - Maintain a map of auto-incrementing request IDs to `Eio.Promise.u` so that RPC responses can resolve the pending promises.

4. **Client API Generation / Wrapping**:
   - Expand the `tools/generate_protocol.ml` script (or write a new one) to generate the actual OCaml functions/classes for the Playwright methods (e.g., `Browser.new_context`, `Page.goto`), which construct the request JSON and await the response from the `Connection`.
