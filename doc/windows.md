# Windows and Linux-to-Windows cross-compilation

## Scope and status

The Windows runtime target is **x86-64 Windows 10 or later**, built from Linux
with MinGW-w64 and OCaml 5.2 or later. Use the same OCaml version for the host and
cross compiler (5.4.1 is one such version supported by opam-cross-windows).
The validated dependency profile uses OCaml 5.4.1 and patched Eio 1.6; Eio 1.3
does not have the required Windows filesystem fixes. This change does not
provide a Windows-host development/test workflow.

The library no longer depends on `eio_linux`, external `curl`/`tar` commands, or
Eio's Windows process manager. The latter is unimplemented in Eio 1.3 and 1.6,
so merely selecting `eio_windows` would not have been sufficient.

Validation so far:

- Native Linux library builds and all 208 existing regression checks pass with
  both Eio 1.3 and Eio 1.6.
- The in-process HTTPS/tar-gzip downloader has completed a cold-cache install,
  followed by a real driver/Chromium session on Linux. Concurrent processes also
  shared one successful install in a cache path containing spaces and Unicode.
- The complete target dependency profile installs with OCaml 5.4.1 and
  MinGW-w64 GCC 16.2. Both library targets and the unchanged `test/test_eval.ml`
  application build; the Windows executable is x86-64 PE, not host ELF.
- Under Wine 11.17, that Windows executable performs a cold HTTPS download and
  extraction, starts Windows Node 22.23.3 and Chrome headless shell
  147.0.7727.15, evaluates JavaScript to `8.000000`, and shuts down successfully.
- Two Windows processes under Wine also completed cold-cache sessions using
  `C:\playwright cache Ω тест`, sharing exactly one driver download and leaving
  no staging directories.

Windows support remains **experimental**: Wine checks are not validation on a
real Windows installation. Cancellation/forced-shutdown stress, restrictive job
policies, long/UNC paths, and real-Windows trust-store/proxy configurations still
need coverage. The example's hardcoded `/usr/bin/chromium` was supplied as a
Windows browser at `C:\usr\bin\chromium` in a private Wine prefix; the example
source was not changed.

## Host and target dependencies are different

Install the host dependencies normally:

```sh
opam install . --deps-only
```

For native-only development:

```sh
dune build --workspace dune-workspace.native @install
env -u PLAYWRIGHT_OCAML_CACHE_DIR -u XDG_CACHE_HOME \
  dune runtest --workspace dune-workspace.native test
```

The ordinary opam package build uses this native-only workspace too; adding this
library to a Linux application must not require a Windows cross compiler.

For a Windows target, install a MinGW-w64 C compiler and a matching Windows OCaml
cross compiler/findlib toolchain. The
[opam-cross-windows repository](https://github.com/ocaml-cross/opam-cross-windows)
documents installation, version constraints and target-package conventions.
For example, in an OCaml 5.4.1 host switch:

```sh
opam repository add windows https://github.com/ocaml-cross/opam-cross-windows.git
opam install ocaml-windows.5.4.1
ocamlfind -toolchain windows ocamlc -config
```

Check that the last command reports `os_type: Win32` and the Windows sysroot,
not the host compiler. Findlib can warn about an undefined toolchain and silently
fall back to the host! This repository's build checks reject that fallback for
the `.windows` context.

**The compiler alone is not enough.** All linked libraries and C stubs must also
exist in the Windows sysroot. This includes Eio/Eio Unix interfaces, Cstruct,
Mtime, Yojson, Base64, Cohttp-Eio, TLS-Eio, CA certificates, Mirage Crypto RNG,
Tar/Tar-Eio and their transitive dependencies. Applications using `Eio_main.run`
also need target builds of `eio_main` and `eio_windows`.

## Reusable local overlay

The `agentiko-cross-windows-local` overlay supplies the missing target recipes
and a reusable `agentiko-windows` dependency profile. On the development machine
it is registered from:

```text
/home/dmytrom/projects/agentiko/opam-cross-windows-local
```

This is a separate local repository, not bundled with this library or published
to the default opam repository. Copy/provide it separately on another host.
Its `README.md` explains its package versions, patches, prerequisites and reuse
in other projects; `setup.sh` creates a dedicated switch without changing the
globally selected switch:

```sh
OVERLAY=/path/to/opam-cross-windows-local
"$OVERLAY/setup.sh" agentiko-windows

# Clear overrides that can survive `opam exec --switch`:
unset OCAMLLIB OCAMLPATH OCAMLFIND_CONF OCAMLFIND_TOOLCHAIN \
  CAML_LD_LIBRARY_PATH OCAML_TOPLEVEL_PATH OCAMLTOP_INCLUDE_PATH

# From this library's checkout, install native build tools/dependencies too:
opam install --switch=agentiko-windows . --deps-only --with-test
opam exec --switch=agentiko-windows -- dune build @install
opam exec --switch=agentiko-windows -- dune build test/test_eval.exe
```

The profile includes patched Eio 1.6, Cohttp 6.3.0, TLS 2.1.3, Mirage Crypto
2.4.1, CA certificates 1.0.3, Tar 3.5.0, and the required transitive dependencies.
GMP 6.3.0 is cross-built statically into the sysroot for Zarith; MXE/system
Windows GMP is not needed. Eio's local patches provide read/write access for
`open_out` and a bounded loopback wakeup-socket fallback when AF_UNIX is absent.
The profile does **not** install Playwright, Node, browsers, or an Eio process
manager, and is usable independently of this library.

Keep host tools and target libraries separate. Do not copy Linux `.cmxa`, `.a`
or shared libraries into `windows-sysroot`, and do not assume
`opam install . --deps-only` installs target dependencies.

YAML parsing, protocol hash verification, code generation and PPX execution run
on the **host**. The Dune rules use `%{exe:...}`, so cross contexts run host-built
generators rather than attempting to execute Windows programs during the build.
Target PPX runtime libraries are still required.

## Build once the sysroot is ready

The checked-in `dune-workspace` is:

```lisp
(lang dune 3.10)
(context (default (targets native windows)))
```

Build both library targets with:

```sh
dune build @install
```

The Windows context is `_build/default.windows`; the native one is
`_build/default`. In a consuming application's workspace, configure the same
Windows target and link `playwright` and `eio_main`. The library does not select
the application's Eio backend.

Use `@install`, not `@all`, for a library cross build. The current test runners
are Linux-specific (`sh`, `sed`, GNU `timeout`, `/proc`, `/usr/bin/chromium`);
cross-compiling the library does not port or execute those tests. Run them in the
native-only workspace.

See [Dune's cross-compilation documentation](https://dune.readthedocs.io/en/stable/cross-compilation.html)
for target selection and installation. An OCaml library alone is not a Windows
executable: the consuming application must also be cross-compiled and deployed
with the DLLs required by its target toolchain/dependencies.

## Runtime provisioning

On the target machine, provide:

- `node.exe` (Node.js 18 or later) on `PATH`;
- a supported browser executable or matching Playwright-managed browser;
- outbound HTTPS access to the npm registry for a cold cache, and a usable
  system CA trust store.

Provisioning is automatic and mandatory on a cache miss. The library downloads
the version pinned by the protocol provenance (**1.59.1**) as a `playwright-core`
npm archive. It is not the Node-bundled Playwright driver ZIP; Node and browser
installation remain separate responsibilities.

`create ~env ~sw ?download_timeout ()` bounds provisioning separately from
protocol initialization. The default download timeout is 120 seconds. No shell,
`curl.exe`, `tar.exe` or `npm` executable is needed by the library.

Cache roots:

| Platform | Default |
| --- | --- |
| Windows | `%LOCALAPPDATA%\playwright-ocaml-driver` |
| Windows fallback | `%USERPROFILE%\AppData\Local\playwright-ocaml-driver` |
| Linux | `$XDG_CACHE_HOME/playwright-ocaml-driver`, otherwise `~/.cache/playwright-ocaml-driver` |

`PLAYWRIGHT_OCAML_CACHE_DIR` overrides the root. Each version has its own
subdirectory. Use a directory writable only by the application/user: cached
driver code is executable code, not untrusted input. HTTPS verifies the server
certificate; package version checks are not a cryptographic archive signature.
Existing compatible caches remain usable offline.

New installs are locked across fibers/processes, downloaded and extracted into
a private staging directory, checked for the expected version/CLI, then renamed
into place. Archive extraction rejects traversal, links, special files and
Windows-unsafe paths, with download/extraction size limits. Interrupted installs
do not publish a partial version directory. The protocol YAML is pinned to LF
with `.gitattributes` because its provenance hash covers the exact upstream bytes.

## Windows process ownership

`Driver_process` selects the platform implementation. Unix retains
`Eio.Process`; Windows uses `CreateProcessW` with explicitly inherited binary
stdin/stdout handles and proper Windows argument quoting. The parent pipe ends
are overlapped named pipes: in-flight I/O buffers live in C memory, not in the
OCaml heap. Eio fibers poll completion cooperatively; process creation and
cancellation retirement run in system threads. This avoids both the missing
Eio process manager and `Unix.set_nonblock` on Windows anonymous pipes.

The driver is assigned to a kill-on-close job object **before** its first thread
resumes, so browser descendants are owned too. Graceful shutdown closes stdin
and drains stdout. If the driver does not exit, shutdown terminates the job,
waits for process exit, cancels/joins pending pipe I/O and closes handles. Windows
escalation is not represented as Unix TERM/KILL signals. A restrictive enclosing
job may prevent assignment; startup then fails and cleans up the suspended
child rather than leaving it unowned.

The low-level `Driver.run` API now takes `~env`, not `~process_mgr`, and returns a
library-owned process. See [lifecycle compatibility notes](lifecycle.md#compatibility-and-testing).
The high-level `Playwright.create ~env ~sw ()` API remains compatible.
