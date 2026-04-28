# Playwright Architecture and Integration Guide for OCaml

This document outlines the architecture, code structure, and communication protocols of Playwright to assist in implementing OCaml bindings. It is based on the analysis of the official Playwright repository (https://github.com/microsoft/playwright).

## 1. Source Code Structure Map

The repository is organized as a monorepo containing multiple packages. The core logic resides in `packages/playwright-core` and `packages/protocol`.

- **`packages/playwright-core/`**: The heart of Playwright, containing the browser drivers, the Node.js client, and the CLI.
  - **`src/server/`**: The "Backend" (Driver). This code launches browsers, communicates with them via CDP/WebDriver BiDi, and exposes the Playwright RPC protocol.
  - **`src/client/`**: The Node.js "Frontend" (Client). It communicates with the server over the RPC protocol. **(Excellent reference for building the OCaml client)**. See `src/client/connection.ts` and `src/client/playwright.ts`.
  - **`src/cli/`**: CLI entrypoints. Contains `driver.ts` which implements the driver startup logic for non-Node.js bindings.
  - **`src/protocol/`**: Code for validating and routing RPC messages.
- **`packages/protocol/`**: The definition of the Playwright RPC protocol.
  - **`src/protocol.yml`**: The single source of truth for the RPC protocol. It defines all objects, methods, parameters, and events.
- **`utils/build/build-playwright-driver.sh`**: The script used to package the driver into standalone executables (bundling Node.js + playwright-core) for usage in Python, Java, and .NET.

## 2. Playwright Driver (Backend)

Non-Node.js language bindings do not reimplement the complex logic of controlling browsers (CDP, downloads, process management). Instead, they download a pre-compiled "Playwright Driver" (which bundles Node.js and the `playwright-core` code) and run it as a child process.

- **How to start the driver**:
  The driver is started as a child process by invoking the CLI entry point with the `run-driver` command.
  Example (if running from source): `node packages/playwright-core/cli.js run-driver`
  In pre-packaged drivers, it's typically just running the binary which automatically acts as the driver.
- **Source Reference**: `packages/playwright-core/src/cli/driver.ts` (specifically the `runDriver()` function).

## 3. Communication Mechanism (Transport Layer)

Communication between the language binding (Client) and the Playwright Driver (Server) happens over standard input (`stdin`) and standard output (`stdout`) using a length-prefixed JSON protocol.

- **Message Framing**:
  - Each message consists of a **32-bit Little-Endian Unsigned Integer** representing the length (in bytes) of the subsequent JSON payload.
  - Immediately following the length prefix is the **UTF-8 encoded JSON string**.
- **Source Reference**: `packages/utils/pipeTransport.ts` (`send` and `_dispatch` methods).

## 4. RPC Protocol Structure

The protocol is object-oriented. Both client and server maintain an object registry where each object has a unique `guid`. These objects are referred to as "Channels" (e.g., `Browser`, `Page`, `ElementHandle`).

The full schema is defined in **`packages/protocol/src/protocol.yml`**.

### 4.1. Message Formats

**Client to Server (Method Call):**
```json
{
  "id": 1,               // Auto-incrementing integer for matching responses
  "guid": "Browser@1",   // The target object's GUID
  "method": "newPage",   // The method name to execute
  "params": { ... },     // Arguments for the method
  "metadata": { ... }    // Optional metadata (e.g., stack frames, logging context)
}
```

**Server to Client (Method Response):**
```json
{
  "id": 1,               // Matches the ID of the request
  "result": { ... },     // The return value of the method (if successful)
  "error": { ... }       // Error details (if the method failed)
}
```

**Server to Client (Event / Object Creation):**
```json
{
  "guid": "Page@2",      // The source object's GUID emitting the event
  "method": "request",   // The event name
  "params": { ... }      // Event payload
}
```

### 4.2. Object Lifecycle

Object allocation is driven by the server. When the server creates a new object (e.g., resulting from a `browser.newPage()` call), it sends a special event `__create__` to the client.

- **`__create__`**: Instructs the client to instantiate a new object in its registry.
  - Payload: `{ type: "Page", guid: "Page@3", initializer: { ... } }`
- **`__adopt__`**: Associates an object with a new parent in the object hierarchy.
- **`__dispose__`**: Instructs the client to remove the object from its registry (garbage collection / closed).

**Source Reference**: `packages/playwright-core/src/client/connection.ts` (`dispatch()` method).

## 5. Next Steps for OCaml Integration

1. **Protocol Generation**: Write an OCaml script that parses `packages/protocol/src/protocol.yml` and generates OCaml types, classes, and method signatures. This ensures the binding stays up-to-date with Playwright upstream.
2. **Driver Management**: Implement a mechanism to download the official Playwright driver binaries for the user's platform (similar to how the Python/Java bindings do it).
3. **Transport Layer**: Implement the `stdin`/`stdout` 32-bit LE length-prefixed message transport.
4. **Client Connection**: Implement an object registry (`Connection` class) that keeps track of GUIDs, dispatches incoming JSON messages to the appropriate objects, and maps OCaml method calls to JSON RPC requests with auto-incrementing IDs.
