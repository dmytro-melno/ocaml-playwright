# Playwright Protocol (`protocol.yml`) Analysis & OCaml Mapping Strategy

The `protocol.yml` file is the source of truth for the Playwright RPC protocol. It describes all the entities (Channels), data structures, enumerations, commands (methods), and events that are transmitted between the Playwright client and the server.

## Top-Level Entity Types

1. **`interface`**: Represents a stateful object (a Channel) in the protocol, such as `Browser`, `Page`, `Worker`, or `ElementHandle`.
2. **`object`**: Represents a stateless data structure (a struct or record).
3. **`enum`**: Represents an enumeration of specific string literals.
4. **`mixin`**: A reusable set of properties/parameters (e.g. `ShowActionsOptions`).

## Interface Characteristics

- **`extends`**: Denotes inheritance.
- **`initializer`**: Properties that the server sends to the client when a new instance of this interface is created.
- **`commands`**: The RPC methods that can be called on the object.
- **`events`**: The events that the object can emit.

## OCaml Code Generation Strategy

Instead of multiple complex scripts, a single unified generator will translate the `protocol.yml` structures directly into idiomatic OCaml APIs.

### 1. Unified Structure and Circular Dependencies
The Playwright protocol has highly interdependent entities (e.g., `Page` depends on `Worker`, `Worker` depends on `Page`). To natively support this in OCaml, the generator will produce a single file utilizing mutually recursive modules:
```ocaml
module rec EventTarget : sig ... end = struct ... end
and Worker : sig ... end = struct ... end
and Page : sig ... end = struct ... end
```

### 2. State & Object Representation
Each stateful interface will be represented using a polymorphic wrapper that holds the connection context, its unique guid, and its specific initialization data:
```ocaml
type 'a obj = {
  conn : Connection.t;
  guid : string;
  init : 'a;
}
```
For an interface like `Worker`, we generate an initializer record and map `t` to this type:
```ocaml
type _initializer_t = {
  main_frame : Frame.t;
  viewport_size : viewport_size_t;
  is_closed : bool;
  opener : Page.t option;
  video : Artifact.t option;
}
type t = _initializer_t obj
```
Properties from the initializer will be exposed as pure getter functions (e.g., `let main_frame (w: t) = w.init.main_frame`).

### 3. Execution & Error Handling
Playwright automation scripts are highly imperative. Unwrapping `Result.t` for every single browser action (click, fill, evaluate) degrades the developer experience.
Commands will be generated to execute the RPC call via the `Connection` module, unpack the result, and **raise OCaml exceptions** upon failure (`Error e`).

### 4. Optional Parameters in Commands
Playwright heavily utilizes optional parameters. These map natively to OCaml's labeled optional arguments (`?reason:string`). To ensure OCaml eagerly evaluates functions containing optional labeled arguments, the positional `t` argument will be placed at the very end of the parameter list:
```ocaml
val disconnect : ?reason:string -> t -> unit
```

### 5. Event Waiters & Eio
Every `event` defined in the protocol will yield two functions:
- A listener registrar: `val on_console : t -> (ConsoleMessage.t -> unit) -> unit`
- A synchronous-looking waiter: `val wait_for_console : t -> ConsoleMessage.t`
Under the hood, `wait_for_*` functions will utilize OCaml 5's `Eio.Promise` to block the current fiber until the event fires, preserving a clean synchronous flow for the end-user.
