# Ideas for OCaml Playwright Bindings

## High-Level API Ergonomics

1. **Smart Defaults for `timeout`**:
   - In `protocol.yml`, `timeout` is usually typed as a required `float`.
   - In Node.js and Python clients, it's optional because the SDK automatically injects a default timeout (e.g., 30000ms or 0 for no timeout) or a user-configured default (via `page.set_default_timeout()`).
   - *Idea*: Update the `tools/generate_hl.ml` generator to expose `timeout` as an optional argument (`?timeout`) in OCaml, and automatically supply a default value (like `0.0`) when building the JSON payload if the user omits it.

2. **Positional Arguments**:
   - Currently, all required parameters are generated as labeled arguments (e.g., `~url:"https..."`, `~selector:"..."`).
   - While labeled arguments are safe and idiomatic in OCaml, common actions in Playwright (like `goto`, `click`, `fill`) are often more ergonomic with positional arguments for the main target (like Node.js `page.goto(url)` or `page.click(selector)`).
   - *Idea*: Maintain a hardcoded list of parameter names (e.g., `url`, `selector`, `text`) in the generator. If a command has one of these primary parameters, generate it as a positional argument instead of a labeled one.

3. **Context/Page level default configuration**:
   - Similar to Python/Node.js, allow users to set default timeouts on the `BrowserContext` or `Page` objects, and have the OCaml client automatically inject these defaults into the RPC calls when the user doesn't explicitly provide a `?timeout`.
