# AGENTS.md

This repository recreates util-linux `cal` in the Loup programming language,
as part of the loup-cmd series of example applications. The program is
`host.dual` Loup built as a native executable.

## Skills

| Skill | Location | Use it when |
|-------|----------|-------------|
| `loup-programmer` | [skills/loup-programmer/SKILL.md](skills/loup-programmer/SKILL.md) | Writing, reviewing, debugging or explaining Loup code: `.lpscr`, `.loup`, `.lphc`, `.lpweb` or `.lpfree` source files, `.lppkg` manifests, `@mode(...)` directives, or the `loup` / `loup-bootstrap` commands. |

Read `skills/loup-programmer/SKILL.md` before writing or changing any Loup code
in this repository. It links to detailed references under
`skills/loup-programmer/references/` for syntax, types and ownership, execution
modes and projects, errors and diagnostics, the standard library, and common
mistakes. Load those only as needed.

## Code layout

```text
.
├── package.lppkg                # Loup manifest: name, version, toolchain, [build] entry, [test] pattern
├── Makefile                     # run, check, test, build, e2e, ci, clean
├── LICENSE                      # MIT license (copyright Code Craft AI LLC)
├── source/                      # all Loup code; modules import each other by path from here
│   ├── main.loup                # entry point: func main() calls run(runtime.args())
│   ├── appinfo.loup             # APP_NAME, APP_VERSION, APP_SUMMARY, exit statuses (0, 1)
│   ├── cli/
│   │   ├── args.loup            # enum Columns, class Options, class ArgError, parse_args(): getopt_long rules
│   │   ├── numbers.loup         # parse_number(): strtol rules as a (value, status) tuple; number_message()
│   │   ├── usage.loup           # usage(), version_line()
│   │   └── app.loup             # run(): parse, --help/--version, run_cal, exit status
│   ├── calendar/
│   │   ├── request.loup         # class Request, parse_timestamp(), resolve_request(): operands with a given today
│   │   ├── days.loup            # weekday_of(), day_of_year(), format_year(), shift_month() on core.datetime
│   │   ├── weeks.loup           # enum Numbering, week_number(), week_start(), month_of_week(): US and ISO weeks
│   │   ├── grid.loup            # class MonthGrid, fill_month(): 42 cells and 6 week numbers
│   │   ├── layout.loup          # class Style, make_style(), render_row(), render_vertical_row(), highlight
│   │   ├── names.loup           # month and weekday names, month_from_name()
│   │   └── terminal.loup        # enum ColorMode, stdout_is_terminal(), terminal_width(), colors_enabled()
│   └── commands/
│       └── cal.loup             # class Surroundings, months_per_row(), calendar_lines(), run_cal()
├── tests/
│   ├── *_test.loup              # unit tests: func test_*(): void
│   └── e2e.sh                   # end-to-end tests of the native binary
├── specs/cal/                   # requirements.md, design.md, tasks.md
├── skills/loup-programmer/      # the Loup skill and its references
├── .github/workflows/ci.yml     # installs Loup and runs `make ci`
└── build/                       # build output (git-ignored)
```

## Build, run and test

Prerequisites: Loup 1.26.0 (`loup` and `loup-bootstrap` on `PATH`), `make`,
and `clang` 17 or later for native builds.

Loup Lite comes from <https://github.com/code-craft-ai-company/loup-releases>;
[README.md](README.md#installing-loup-lite) has the install commands.

| Task | Command | Notes |
|------|---------|-------|
| Run from source | `make run ARGS="-3 2 2024"` | `loup-bootstrap run source/main.loup -- ARGS` (Stage0: the self-hosted `loup run` lacks `execShell`) |
| Type-check | `make check` | checks `source/main.loup` and every module it imports; tests are not checked |
| Run all tests | `make test` | every `tests/*_test.loup`, one at a time (`--no-parallel`) |
| Run matching tests | `make test TEST_ARGS="--filter week"` | tests whose name contains `week` |
| Run one test file | `make test TEST_ARGS="--file tests/layout_test.loup"` | |
| Build | `make build` | native binary at `build/cal` |
| Run the binary | `build/cal -3` | |
| End-to-end tests | `make e2e` | runs `tests/e2e.sh build/cal`: calendars and messages compared byte for byte |
| Everything CI runs | `make ci` | check, test, build, e2e, then `build/cal --version` |
| Clean | `make clean` | removes `build/`, `.temp/` and `.loup-cache/` |

Run `make ci` before reporting a change as done. `loup run` and the native
build do not support the same things, so a change can pass `make test` and
still fail `make build` or crash the binary: run `make e2e` too.

Do not call `loup test` or `loup check` directly on Linux x86-64. There `loup`
is the self-hosted driver: it refuses `check`, and its test runner cannot
resolve this project's imports. The Makefile uses `loup-bootstrap` (Stage0) for
both, and sets `LOUPPATH=source` for tests.

The e2e expectations are util-linux cal 2.41's output with
`--reform=gregorian` and `TZ=UTC`. Where util-linux cal is installed,
compare new cases with `TZ=UTC cal --reform=gregorian ...` before adding
them.

## Making a change

1. Update the spec in `specs/cal/` (see [specs/README.md](specs/README.md)).
2. Change the code under `source/`.
3. Add or update unit tests in `tests/` and cases in `tests/e2e.sh`.
4. Run `make ci`.
5. Tick the finished tasks in `specs/cal/tasks.md`.

Keep behaviour in functions that return values (`calendar_lines` returns the
lines, `resolve_request` a `Request`) and pass the outside world in
(`Surroundings`: today, terminal, width, colours), so unit tests can pin the
date; only `run_cal` reads the clock and prints.

## Conventions

- Every source file is `@mode(host.dual)` with the `.loup` extension. Only
  `source/main.loup` has a `main()`.
- Modules import each other by path from `source/`:
  `from cli.args import (Options);`. Tests import them the same way. Do not
  use relative imports.
- Records that cross modules (`Options`, `ArgError`, `Request`, `MonthGrid`,
  `Style`, `Surroundings`) are classes, built by a constructor or factory in
  their own module: native builds corrupt struct values that cross module
  boundaries.
- Named arguments only for calls within one module (`style_for(julian =
  ...)` in `commands/cal.loup`): a named-argument call into another module
  crashes the native build of Loup 1.26.0.
- Native match guards: never put a guard on the first arm of a `match` on
  an int (it segfaults); `Columns.Fixed(n) if (n > 0)` on an enum payload
  works. Use `if` expressions for plain numbers.
- Calls that build strings through `core.string_utils.padLeft` crashed the
  native binary when one function had two of them on different return
  paths (`format_year`): compute the parts, then call it once.
- `system.text` (`parseInt`, `padStart`) does not link natively: numbers go
  through `cli.numbers.parse_number`, padding through `core.string_utils`.
- Today comes from `Date.today()`, which is UTC. Tests never depend on the
  real date except the e2e smoke test of `build/cal` without arguments.
- Keep `APP_VERSION` in `source/appinfo.loup` equal to `version` in
  `package.lppkg`.
- The skill's examples use the `loup init` layout (`src/`, `tests/`, and
  `from ..src.x import` in tests). This project uses `source/` and
  `tests/` with plain imports; follow this file.
- The skill documents toolchain 1.25.1; this project targets 1.26.0. When
  they disagree, trust the toolchain's behaviour.
