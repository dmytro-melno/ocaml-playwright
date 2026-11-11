# Windows

## Status

The library builds for 64-bit Windows with a cross compiler on Linux, and the result has
been run under Wine: installing the driver, installing a browser with the command line
tool, a session with a real browser (launch, content, click, evaluation, screenshot,
close), and stopping the driver when the program ends or its switch fails. No process was
left behind.

**It has not been run on Windows itself.** Wine is a good sign, not a proof. The test
suites have not been run for the Windows build either: they would first have to be ported,
as the process tests use Unix tools and the test dependencies are not built for the target.
Treat Windows as experimental.

## What is different there

Little, and all of it in two modules. Everything else that touches the system (files, the
installation of the driver, the driver's standard error) is done with the Unix library in
system threads, in the same way on every system.

**Processes and pipes (`driver_process.ml`).** Eio has no process manager on Windows and its
pipes cannot be read without blocking there. So the driver is started with
`Unix.create_process`, and each of its two pipes is served by a system thread that does
blocking I/O. The reading thread hands chunks to the fibers through an `Eio.Stream`, taking
a new chunk only when the previous one was consumed; the writing thread takes jobs from a
queue and resolves a promise for each. Fibers wait on the stream and on promises, which is
ordinary cancellable Eio waiting. Nothing here is specific to Windows, which has two
benefits: there are no C stubs, and the same code runs on Linux, where the tests exercise
it (`PLAYWRIGHT_OCAML_DRIVER_IO=threads`).

Stopping the driver is the same everywhere: its standard input is closed, on which it
closes its browsers and exits; after ten seconds without success it is killed. If the OCaml
program is killed, the driver sees the end of its input in the same way. Earlier versions
of the library put the driver into a job object to have Windows kill it with the program.
This was dropped together with the C stubs, as the driver takes care of itself and of its
browsers.

**Finding Node.js (`driver.ml`).** `node.exe` is searched for in the directories of `PATH`
by the library itself, and the full path is used to start it. Windows would otherwise look
into the current directory first, which must not decide what program is run. Relative
entries of `PATH` are ignored for the same reason. `PLAYWRIGHT_NODEJS_PATH` names the
executable directly.

**Installing the driver (`driver.ml`).** The installer is a Node.js script, started with
`Unix.create_process_env` and polled with `Unix.waitpid [ WNOHANG ]` until it ends, its time
is up or the caller is cancelled; it is then killed with `Unix.kill pid Sys.sigkill`, which
the Unix library carries out with `TerminateProcess` on Windows. Its standard input is
`NUL` there. The unpacked package is renamed into place with `Unix.rename`. When that fails
because another process has installed the driver meanwhile, as it does on Windows where a
directory cannot be renamed over another, the installation counts as done.

**Standard error.** The driver writes to a pipe, and a system thread copies from it to the
program's standard error (see *The driver* in [architecture.md](architecture.md)). The pipe
is made with `Unix.pipe ~cloexec:true`, and the write end is passed to
`Unix.create_process` as the child's standard error, which makes that one handle
inheritable.

The cache is in `%LOCALAPPDATA%\ocaml-playwright`. The command `ocaml-playwright` runs
Playwright's tool as a child process and waits for it, where on Unix it replaces itself
with it.

## Cross-compiling

The build needs a Windows cross compiler that findlib knows as the toolchain `windows`, and
the dependencies built for it: `eio`, `yojson`, `base64` and what they depend on. A program
also needs `eio_main` and `eio_windows`. The
[opam-cross-windows](https://github.com/ocaml-cross/opam-cross-windows) repository provides
the compiler and the conventions for such packages.

```sh
ocamlfind -toolchain windows ocamlc -config | grep os_type     # must say Win32
dune build --workspace dune-workspace.windows @install
```

`dune-workspace.windows` adds the target `windows` to the default context; the artefacts are
in `_build/default.windows/`. The default build of the library does not use this file and
needs no cross compiler.

If the environment sets `OCAMLLIB`, `OCAMLPATH`, `OCAMLFIND_CONF` or `OCAMLFIND_TOOLCHAIN`,
as some tools do, unset them for the build; they make findlib mix up host and target.

## Trying it under Wine

A Windows build of Node.js is needed; the zip archive from nodejs.org unpacks to a
directory with `node.exe`.

```sh
export WINEPREFIX=$HOME/.wine-playwright WINEDEBUG=-all
export WINEPATH="$(winepath -w /path/to/node-win-x64)"
wine _build/default.windows/bin/main.exe --version > out.txt 2> err.txt
wine _build/default.windows/bin/main.exe install chromium-headless-shell > out.txt 2> err.txt
```

Under Wine, redirect the output of these programs to files: Node.js fails to write to the
pipe or terminal of a Unix process that it inherits as standard output. This is a quirk of
Wine and does not happen with the pipes that the library itself creates.

## What needs doing

- A run of the browser tests on Windows itself.
- Paths: long paths, UNC paths and non-ASCII user names in the cache directory have not
  been tried.
- A check that browsers are gone after the OCaml program was terminated abruptly, with
  each of the three browsers.
