# Task: Implement Unified Playwright API Generator

## Objective
Simplify the current Playwright API generation system by replacing the multiple existing generator scripts with a single, straightforward generator script. The new script will read `deps/playwright/packages/protocol/src/protocol.yml` and emit a unified, idiomatic OCaml API.

## Background & Rationale
Currently, the codebase uses several files (like `generate_protocol.ml`, `generate_api.ml`, `generate_hl.ml`, etc.) and complex generation pipelines to build the RPC bindings. The goal is to consolidate (or better write a fresh one) this into one straightforward script (`tools/generate_unified.ml` or similar) that maps the Playwright RPC model into a single OCaml file utilizing mutually recursive modules to gracefully handle circular dependencies (e.g., `Page` referencing `Worker` and vice-versa).

## Requirements

1. **Architecture (Mutually Recursive Modules):**
   The generator must output a single file structure:
   ```ocaml
   module rec Entity1 : sig ... end = struct ... end
   and Entity2 : sig ... end = struct ... end
   ```

2. **Object Representation:**
   Use a common polymorphic record to represent stateful channels:
   ```ocaml
   type 'a obj = {
     conn : Connection.t;
     guid : string;
     init : 'a;
   }
   ```
   For each interface, generate its specific `_initializer_t` record and bind its main type `t`:
   ```ocaml
   type t = _initializer_t obj
   ```
   Generate pure getter functions for fields defined in the initializer.

3. **Commands (Exceptions over Results):**
   Map `protocol.yml` interface commands to OCaml functions.
   - Use labeled arguments (`~`) for required parameters and optional labeled arguments (`?`) for optional parameters.
   - Make the positional `t` argument the last argument in the signature. This naturally handles optional labeled arguments without requiring a trailing `unit`.
   - If the underlying RPC call fails (returns `Error e`), the generated function should unwrap it and **raise an exception**. (Do not return `(..., string) result`).

4. **Events and Waiters:**
   For each event defined in an interface, generate two functions:
   - `on_<event_name>`: Registers a callback.
   - `wait_for_<event_name>`: Uses `Eio.Promise` to asynchronously wait (blocking the current fiber) until the event is fired.

5. **Data Types:**
   Generate corresponding OCaml types for `object` (records/dicts) and `enum` types found in `protocol.yml`. Inline `$mixin` properties where required.

## References
For deeper details on mapping Playwright semantics (like modifiers, flags, internal fields) to the OCaml target, refer strictly to the **`protocol_report.md`** file located in the root of the repository.
