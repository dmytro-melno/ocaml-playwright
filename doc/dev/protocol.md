# Updating to a new version of Playwright

A release of this library works with exactly one release of Playwright's driver, because
the protocol between the two changes with every minor version. This document describes
what is pinned, and how to move to a new release.

## What is pinned

```
protocol/
  manifest.json    version, commit, driver tarball and checksum, checksums of the files below
  spec/*.yml       the protocol specification, copied from the Playwright repository
lib/protocol.ml    generated from the two above; checked in
```

`manifest.json` names

- the version and the commit of the Playwright release;
- the tarball of the npm package `playwright-core` of that version and its SHA-512, as the
  npm registry states them. This is the driver that the library downloads at run time, and
  the checksum is what the download is verified against;
- the SHA-256 of every file in `spec/`, so that an edited or half-updated specification is
  noticed.

`tools/gen_protocol` reads the specification and the manifest and prints `lib/protocol.ml`:
the typed commands, events and initializers of every kind of object, and the constants
`playwright_version`, `driver_tarball` and `driver_integrity`. It refuses to run if the
files do not match the manifest.

The generated file is checked in. This way building the library needs neither the generator
nor its dependencies (`yaml`, `digestif`), and changes of the protocol are visible in
reviews. `dune runtest` fails if the file is not what the generator would produce.

## The update, step by step

1. **Fetch the specification and pin the driver.**

   ```sh
   node tools/update_protocol.js 1.66.0
   ```

   This replaces `protocol/spec/*.yml` and rewrites `protocol/manifest.json`. It talks to
   GitHub and to the npm registry.

2. **Regenerate.**

   ```sh
   dune build @gen --auto-promote
   git diff --stat lib/protocol.ml
   ```

   If the generator fails, the specification uses something that it does not know yet, such
   as a new primitive type or a new form of declaration. The error says where. Extend
   `tools/gen_protocol/gen_protocol.ml`; it is a few hundred lines, and its model of the
   specification is at the top.

3. **Build, and follow the type errors.** `dune build 2>&1 | head -50`. Each error is a
   place where the client uses a command, a parameter or an event that has changed.
   A removed parameter means that an option of the public API goes away or is implemented
   differently; a new required parameter needs a value.

4. **Find out what else changed.** Type errors only show what broke. What was *added* has
   to be looked for:

   - Read the [release notes](https://playwright.dev/docs/release-notes) of every version
     in between.
   - Read the diff of the generated file from step 2: new commands, new parameters, new
     events and new fields of initializers are the raw material of new features.
   - Compare the official client, which is the reference for everything that the protocol
     does not say: how options map to parameters, in which order things are done, what is
     checked on the client.

     ```sh
     git clone https://github.com/microsoft/playwright && cd playwright
     git diff v1.65.0 v1.66.0 --stat -- packages/playwright-core/src/client
     git diff v1.65.0 v1.66.0 -- packages/playwright-core/src/client/page.ts
     ```

     `docs/src/api/*.md` in the same repository is the source of the API documentation,
     with a `since` version at every method and option.

   For each addition decide whether to offer it. If so: the object's module, the interface,
   a test.

5. **Run the tests** against the new driver: `dune runtest`. The first run downloads the
   driver. Browsers have to match it; if the tests use Playwright's own browsers, install
   them anew with `dune exec ocaml-playwright -- install chromium`.

6. **Update the texts**: the version in `README.md` and in the guide's example of
   `run-server`, and an entry in `CHANGES.md`.

## Notes on the generator

- Names are converted from `camelCase` to `snake_case`, and those that clash with OCaml
  keywords get an underscore appended.
- Inline objects and enumerations get modules named after their path, such as
  `Protocol.Page.Initializer_viewport_size`.
- The interfaces listed in `excluded_interfaces` (Android, Electron and some tools) are
  not generated. Objects of these kinds still exist as untyped channels.
- `SerializedValue` is passed through as raw JSON; `Js` encodes and decodes it by hand,
  since it is a recursive structure with back references.
- Mixins of the specification are expanded into the interfaces that use them.

The driver decides how it words error messages and the code it shows in call logs from the
`sdkLanguage` that the client states when it connects. This library says `python`, whose
conventions, `snake_case` and keyword arguments, are the closest to OCaml's.
