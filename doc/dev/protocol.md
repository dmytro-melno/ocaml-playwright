# Updating to a new version of Playwright

A release of this library works with exactly one release of Playwright's driver, because
the protocol between the two changes with every minor version. This document describes
what is pinned, and how to move to a new release.

## What is pinned

```
protocol/
  manifest.json                 version, commit, driver tarball and checksum, checksums of the files below
  spec/*.yml                    the protocol specification, copied from the Playwright repository
lib/protocol.ml                 generated from the two above; checked in
doc/dev/protocol-coverage.md    generated from the same and from the sources in lib/; checked in
```

`manifest.json` names

- the version and the commit of the Playwright release;
- the tarball of the npm package `playwright-core` of that version and its SHA-512, as the
  npm registry states them. This is the driver that `Driver.install` downloads, and the
  checksum is what the download is verified against;
- the SHA-256 of every file in `spec/`, so that an edited or half-updated specification is
  noticed.

`tools/gen_protocol` reads the specification and the manifest and prints `lib/protocol.ml`:
the typed commands, events and initializers of every kind of object, and the constants
`playwright_version`, `driver_tarball` and `driver_integrity`. It refuses to run if the
files do not match the manifest. With `--coverage` it prints
[protocol-coverage.md](protocol-coverage.md) instead: the commands of the protocol that no
module in `lib/` calls, the events of interfaces that nothing listens to, and the interfaces
that are left out.

Both generated files are checked in. This way building the library needs neither the
generator nor its dependencies (`yaml`, `digestif`), and changes of the protocol are visible
in reviews. `dune runtest` fails if either file is not what the generator would produce.

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
   git diff --stat lib/protocol.ml doc/dev/protocol-coverage.md
   ```

   If the generator fails, the specification uses something that it does not know yet, such
   as a new primitive type or a new form of declaration. The error says where. Extend
   `tools/gen_protocol/gen_protocol.ml`, whose model of the specification is at the top.

3. **Build, and follow the errors.** `dune build 2>&1 | head -50`. What the compiler shows
   of a new version, and what it does not:

   | A new version of the protocol | Shows as |
   | --- | --- |
   | removes or renames a command, a parameter, a field of a result or an initializer, a value of an enumeration that the client uses; makes a parameter required | a type error where it is used |
   | adds an interface | a match that is not exhaustive in `objects.ml` (`Protocol.Object.of_channel` has a constructor per interface) |
   | adds an event to an interface whose events are handled | a match that is not exhaustive in the `handle_event` of its module |
   | adds a command, or an interface that is not generated | a change of the generated [protocol-coverage.md](protocol-coverage.md) |
   | adds an optional parameter to a command in use, a field to a result, a value to an enumeration that is only sent | nothing: only the diff of `lib/protocol.ml` tells |
   | changes what a command does without changing its shape | nothing: the release notes, the official client and the tests tell |

   A removed parameter means that an option of the public API goes away or is implemented
   differently; a new required parameter needs a value.

4. **Find out what else changed**, in the diff of `lib/protocol.ml` and in the official
   client, which is the reference for everything that the protocol does not say: how options
   map to parameters, in which order things are done, what is checked on the client.

   ```sh
   git clone https://github.com/microsoft/playwright && cd playwright
   git diff v1.65.0 v1.66.0 --stat -- packages/playwright-core/src/client
   git diff v1.65.0 v1.66.0 -- packages/playwright-core/src/client/page.ts
   ```

   Some of its code is ported, not just followed; a change in one of these files has to be
   repeated here:

   | Upstream | Here |
   | --- | --- |
   | `packages/isomorphic/locatorUtils.ts` | `lib/selector.ml` |
   | `packages/protocol/src/serializers.ts`, `client/jsHandle.ts` | `lib/js.ml` |
   | `client/waiter.ts`, `client/timeoutSettings.ts` | `lib/waiter.ml`, `lib/timeouts.ml` (the behaviour, not the code) |

   An update has to keep true what the library offers already: an option of a function that
   is here, a field of a value that it returns. What Playwright *added* does not have to
   follow: *What belongs in the library* in [architecture.md](architecture.md) decides, and
   where the library leaves out something that a reader will look for,
   [scope.md](../scope.md) says what takes its place.

5. **Run the tests** against the new driver: install it with
   `dune exec ocaml-playwright -- install chromium`, which also installs the browser that
   matches it, for the tests that use Playwright's own; then `dune runtest`. The driver test
   (`test/driver`) fails when the driver has begun to make regular expressions of URL globs
   that `Re` cannot run, or reads a glob differently than before.

6. **Update the texts**: the versions in `README.md` and in [scope.md](../scope.md),
   an entry in `CHANGES.md`, and the version of the
   library in `dune-project` (a new minor version of Playwright is at least a new minor
   version here, since behaviour changes with it).

## Notes on the generator

- Names are converted from `camelCase` to `snake_case`, and those that clash with OCaml
  keywords get an underscore appended.
- Inline objects and enumerations get modules named after their path, such as
  `Protocol.Page.Initializer_viewport_size`.
- An enumeration is encoded by a match on its values, not looked up in a table. A parameter
  therefore accepts the values that the protocol has and no others, and a value that a new
  version removes or renames is a type error wherever the client sends it.
- Every interface gets a type in `Protocol.Kind`, a row of tags: its own and those of the
  interfaces that it extends (`type element_handle = [ js_handle | `Element_handle ]`), and
  a value of the same name that tells its objects from the others. Channels are typed with
  these; see the section on typed channels in [architecture.md](architecture.md). The
  commands and events of an extended interface are not repeated in the one that extends it.
- The interfaces listed in `excluded_interfaces` (Android, Electron and some tools) are
  not generated. Objects of these kinds still exist, as channels of no known interface
  (`Channel.any`), and so do the objects that the specification gives no interface to.
- `SerializedValue` is passed through as raw JSON; `Js` encodes and decodes it by hand,
  since it is a recursive structure with back references.
- Mixins of the specification are expanded into the interfaces that use them.

### What a cancelled command leaves behind

The generator also decides what happens to a command whose caller was cancelled (see
*Cancellation* in [architecture.md](architecture.md)). It derives that from the type of the
result and from four tables at its top, which a new version of the protocol can require
additions to:

| Table | Says | Add to it when |
| --- | --- | --- |
| `released_with` | for each interface whose objects a command hands over to its caller, the command that gives such an object back (`Page` → `close`, `JSHandle` → `dispose`, ...) | a command returns an object of a new interface that the caller owns. Nothing fails without the entry, the object of a cancelled call is just left behind: look at what the new commands return |
| `aborted_safely` | the interfaces whose objects a command can return and still be aborted when its caller is cancelled. Every other command that returns an object is left to finish, and its result released | never, unless the driver is known to abort the command without leaving anything behind |
| `results_not_owned` | commands whose result is not the caller's to release, although its type says so | a command returns an existing object rather than a new one |
| `released_specially` | commands whose result is released in a way that its type does not tell (`APIRequestContext.fetch`, whose response is a record with an id) | a result holds something to release that is not an object of the driver |

The driver decides how it words error messages and the code it shows in call logs from the
`sdkLanguage` that the client states when it connects. This library says `python`, whose
conventions, `snake_case` and keyword arguments, are the closest to OCaml's.
