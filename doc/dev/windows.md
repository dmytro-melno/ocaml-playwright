# Windows

## Status

The library builds for 64-bit Windows with a cross compiler on Linux. **It has not been run
on Windows itself**, and the test suites have not been run for the Windows build: they
would first have to be ported, as the process tests use Unix tools and the test
dependencies are not built for the target. Treat Windows as experimental.

What there is instead is a session under Wine, with Node.js for Windows and Playwright's
Chromium for Windows, during the work on 0.2:

- installing the driver, and installing a browser with the command line tool;
- launch, a route that is fulfilled, navigation, a listener and `expect_event` around a
  click, an upload from disk, evaluation, a screenshot, a call cancelled with
  `Eio.Time.with_timeout`, close;
- the driver's log (`DEBUG=pw:browser`) arriving on the program's standard error;
- stopping the driver when the program ends, when its switch fails, and when it dies of
  an uncaught exception, with no process left behind.

Two changes came after that session and have only been cross-compiled and tested on Linux:
installing the driver became a step of its own, and the way the driver process is run on
Windows became the only one. Repeat the session (see below) before relying on the build.

## What is different there

Almost nothing: the same code runs on every system, and what touches the system (the
driver's process and pipes, files, the installation of the driver) is done with the Unix
library. This is where Windows shaped that code.

**Processes and pipes (`driver_process.ml`).** Eio has no process manager on Windows and its
pipes cannot be read without blocking there, hence `Unix.create_process` and a system thread
per pipe (see *The driver* in [architecture.md](architecture.md)). There are no C stubs.

**Stopping.** The driver's standard input is closed, on which it closes its browsers and
exits; after ten seconds without success it is killed. If the OCaml program is killed, the
driver sees the end of its input in the same way. Version 0.1 put the driver into a job
object to have Windows kill it with the program; that went with the C stubs, as the driver
takes care of itself and of its browsers.

**Finding Node.js (`driver.ml`).** `node.exe` is searched for in the directories of `PATH`
by the library itself, and the full path is used to start it. Windows would otherwise look
into the current directory first, which must not decide what program is run. Relative
entries of `PATH` are ignored for the same reason. `PLAYWRIGHT_NODEJS_PATH` names the
executable directly.

**Installing the driver (`driver.ml`).** The installer is a Node.js script, started with
`Unix.create_process_env` and waited for with `Unix.waitpid`; its standard input is `NUL`.
The unpacked package is renamed into place with `Unix.rename`. When that fails because
another process has installed the driver meanwhile, as it does on Windows where a directory
cannot be renamed over another, the installation counts as done.

**Standard error.** The pipe that the driver writes its errors to is made with
`Unix.pipe ~cloexec:true`, and the write end is passed to `Unix.create_process` as the
child's standard error, which makes that one handle inheritable.

The cache is in `%LOCALAPPDATA%\ocaml-playwright`. The command `ocaml-playwright` runs
Playwright's tool as a child process and waits for it, where on Unix it replaces itself
with it.

## Cross-compiling

The build needs a Windows cross compiler that findlib knows as the toolchain `windows`, and
the dependencies built for it: `eio`, `yojson`, `base64`, `re` and what they depend on. A
program also needs `eio_main` and `eio_windows`. The
[opam-cross-windows](https://github.com/ocaml-cross/opam-cross-windows) repository provides
the compiler and the conventions for such packages.

```sh
ocamlfind -toolchain windows ocamlc -config | grep os_type     # must say Win32
dune build --workspace dune-workspace.windows @install
```

`dune-workspace.windows` adds the target `windows` to the default context; the artefacts are
in `_build/default.windows/`. The default build of the library does not use this file and
needs no cross compiler. If the environment sets `OCAMLLIB`, `OCAMLPATH`, `OCAMLFIND_CONF`
or `OCAMLFIND_TOOLCHAIN`, as some tools do, unset them for the build; they make findlib mix
up host and target.

## Trying it under Wine

A Windows build of Node.js is needed; the zip archive from nodejs.org unpacks to a
directory with `node.exe`.

```sh
export WINEPREFIX=$HOME/.wine-playwright WINEDEBUG=-all
export WINEPATH="$(winepath -w /path/to/node-win-x64)"
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
