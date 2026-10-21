# loup-cmd-cal

util-linux `cal` recreated in [Loup](https://code-craft.ai/references/loup):
print a month, three months, any number of months or a whole year, with
Sunday or Monday weeks, days of the year (`-j`), US or ISO 8601 week numbers
(`-w`), a vertical layout (`-v`), and today's date highlighted on a
terminal. The calendar is the Gregorian one for every year.

Part of the **loup-cmd** series of example applications: classic Linux and
Windows commands, and projects for each Loup execution mode, each in its own
repository under [myronccai](https://github.com/myronccai?tab=repositories&q=loup-cmd).
This one is `host.dual` Loup built as a native binary.

## Requirements

- [Loup Lite](https://github.com/code-craft-ai-company/loup-releases) 1.26.0
  or later; see [Installing Loup Lite](#installing-loup-lite).
- `make`, and `clang` 17 or later for the native build.

## Installing Loup Lite

This example is built and tested with **Loup Lite**, the free public build of
the Loup toolchain from [Code Craft AI](https://code-craft.ai), meant for
education and training. Code Craft AI publishes the official builds,
installers and signed checksums at
**<https://github.com/code-craft-ai-company/loup-releases>**, for Linux
(x86-64, arm64), macOS (Apple silicon, Intel) and Windows (x86-64).

Linux and macOS:

```sh
curl -fsSL https://github.com/code-craft-ai-company/loup-releases/releases/latest/download/loup-install.sh | sh
```

Windows (PowerShell):

```powershell
irm https://github.com/code-craft-ai-company/loup-releases/releases/latest/download/loup-install.ps1 | iex
```

The installer picks the archive for your machine, checks it against the
release's `SHA256SUMS`, unpacks it into `~/.loup`
(`%LOCALAPPDATA%\Programs\Loup` on Windows) and puts its `bin` directory on
your `PATH`; it needs no administrator rights. You get `loup`, the Stage0
compiler `loup-bootstrap` and the Wasm runtime `loup-launcher`. Open a new
shell and check:

```sh
loup --version             # loup 1.26.0 or later
```

CI installs the exact version it tests with, 1.26.0. To do the same:

```sh
curl -fsSL https://github.com/code-craft-ai-company/loup-releases/releases/download/v1.26.0/loup-install.sh | sh -s -- --version 1.26.0
```

To install by hand, download your platform's archive from the
[releases page](https://github.com/code-craft-ai-company/loup-releases/releases),
check it against `SHA256SUMS`, unpack it anywhere and add its `bin` directory to
`PATH`. The [loup-releases README](https://github.com/code-craft-ai-company/loup-releases#verify-a-download)
explains how to verify the Sigstore signature on `SHA256SUMS`.

Loup Lite leaves out Loup's cryptography library and the full set of Loup
packages; this example needs neither. Commercial use of Loup needs a
license: <https://code-craft.ai/loup/license>.

## Usage

```sh
make build                                # native binary: build/cal
make ci                                   # check, unit tests, build, end-to-end tests
make run ARGS="-3 2 2024"                 # run from source (Stage0 interpreter)
```

Real output of the binary (cal pads every line with spaces to the full
width; the trailing spaces are left out here):

```text
$ build/cal 2 2026
    February 2026
Su Mo Tu We Th Fr Sa
 1  2  3  4  5  6  7
 8  9 10 11 12 13 14
15 16 17 18 19 20 21
22 23 24 25 26 27 28


$ build/cal -3 1 2026
    December 2025         January 2026          February 2026
Su Mo Tu We Th Fr Sa  Su Mo Tu We Th Fr Sa  Su Mo Tu We Th Fr Sa
    1  2  3  4  5  6               1  2  3   1  2  3  4  5  6  7
 7  8  9 10 11 12 13   4  5  6  7  8  9 10   8  9 10 11 12 13 14
14 15 16 17 18 19 20  11 12 13 14 15 16 17  15 16 17 18 19 20 21
21 22 23 24 25 26 27  18 19 20 21 22 23 24  22 23 24 25 26 27 28
28 29 30 31           25 26 27 28 29 30 31

$ build/cal -wm 1 2021
      January 2021
   Mo Tu We Th Fr Sa Su
53              1  2  3
 1  4  5  6  7  8  9 10
 2 11 12 13 14 15 16 17
 3 18 19 20 21 22 23 24
 4 25 26 27 28 29 30 31

$ build/cal -j 2 2024
       February 2024
Sun Mon Tue Wed Thu Fri Sat
                 32  33  34
 35  36  37  38  39  40  41
 42  43  44  45  46  47  48
 49  50  51  52  53  54  55
 56  57  58  59  60

$ build/cal -v 10 2026
    October 2026
Su     4 11 18 25
Mo     5 12 19 26
Tu     6 13 20 27
We     7 14 21 28
Th  1  8 15 22 29
Fr  2  9 16 23 30
Sa  3 10 17 24 31
$ build/cal -y 2026 | head -9
                               2026

       January               February                 March
Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa
             1  2  3    1  2  3  4  5  6  7    1  2  3  4  5  6  7
 4  5  6  7  8  9 10    8  9 10 11 12 13 14    8  9 10 11 12 13 14
11 12 13 14 15 16 17   15 16 17 18 19 20 21   15 16 17 18 19 20 21
18 19 20 21 22 23 24   22 23 24 25 26 27 28   22 23 24 25 26 27 28
25 26 27 28 29 30 31                          29 30 31
$ build/cal --color=always 15 2 2026 | cat -v
    February 2026
Su Mo Tu We Th Fr Sa
 1  2  3  4  5  6  7
 8  9 10 11 12 13 14
^[[7m15^[[0m 16 17 18 19 20 21
22 23 24 25 26 27 28


$ build/cal 30 2 2026; echo "exit $?"
cal: illegal day value: use 1-28
exit 1
```

On a terminal, today's date (or the DAY of `cal DAY MONTH YEAR`) is shown
in reverse video, as the `--color=always` example above makes visible.
In files and pipes nothing is highlighted.

Operands:

| Operands | Shows |
|---|---|
| (none) | the current month |
| `YEAR` | the whole year (as `-y`), or with `-n`/`-3`/`-Y` that many months from the current month's number |
| `MONTH YEAR` | that month; MONTH is 1-12 or an English name or three-letter abbreviation (`feb`) |
| `DAY MONTH YEAR` | that month, with DAY highlighted |
| `TIMESTAMP` | the month of `YYYY-MM-DD`, `YYYY-MM-DD HH:MM[:SS]`, `YYYY-MM-DDTHH:MM:SS`, `HH:MM[:SS]`, `@SECONDS`, `now`, `today`, `yesterday`, `tomorrow`, `+N`/`-N` days or weeks (`+3days`, `-2w`) or `N days ago`, with that date highlighted |
| `MONTHNAME` | that month of the current year |

Options:

| Option | Meaning |
|---|---|
| `-1`, `--one` | show one month (the default) |
| `-3`, `--three` | show the previous, the given and the next month |
| `-n`, `--months N` | show N months starting with the given one |
| `-S`, `--span` | with several months, put the given one in the middle |
| `-s`, `--sunday` | weeks start on Sunday (the default) |
| `-m`, `--monday` | weeks start on Monday |
| `-j`, `--julian` | number the days within the year (1-366) |
| `-y`, `--year` | show the whole year |
| `-Y`, `--twelve` | show twelve months starting with the given one |
| `-w`, `--week[=N]` | show week numbers: ISO 8601 with `-m`, US otherwise; with N, show the month of week N and highlight N |
| `-v`, `--vertical` | weekdays down the left, weeks across |
| `-c`, `--columns N` | put N months side by side; `auto` fills the terminal |
| `--color[=WHEN]` | highlight `auto` (on a terminal), `always` or `never` |
| `--reform gregorian`, `--reform iso`, `--iso` | accepted: the calendar is always Gregorian |
| `-h`, `--help`, `-V`, `--version` | print help or the version and exit |

Options and operands may be mixed, short options combine (`-3mj`, `-n6`),
long options may be abbreviated (`--mond`), and `--` ends the options.
Without `-c`, cal puts three months side by side (two spaces apart, three
with `-y`/`-Y`), or fewer when the terminal is narrower; the width comes
from `COLUMNS` or `stty size`. `NO_COLOR` turns the highlight off unless
`--color` is given.

Exit status: `0` if OK, `1` for any error: an invalid option or value, an
invalid date, or more than three operands.

## Differences from the original

- Only the Gregorian calendar, for every year: the output is that of
  util-linux `cal --reform=gregorian`. util-linux by default switches to
  the Julian calendar before September 14, 1752 (its `cal 9 1752` lacks
  September 3-13, and all earlier dates fall on other weekdays);
  `--reform 1752` and `--reform julian` are refused here:

  ```text
  $ build/cal 9 1752
     September 1752
  Su Mo Tu We Th Fr Sa
                  1  2
   3  4  5  6  7  8  9
  10 11 12 13 14 15 16
  17 18 19 20 21 22 23
  24 25 26 27 28 29 30

  $ build/cal --reform=1752 9 1752; echo "exit $?"
  cal: --reform '1752' is not supported: this cal uses the Gregorian calendar for every year
  exit 1
  ```

- Today is the date in UTC: Loup 1.26.0's `core.datetime` has no local time
  zone. Near midnight the current month and the highlighted day can differ
  from your local date. Timestamps are read in UTC too.
- English names and Sunday-first weeks whatever the locale says; `-m`
  starts weeks on Monday.
- Timestamps are a subset of util-linux's: relative ones in whole days or
  weeks only, no weekday names or two-digit years.
- Whether the terminal has colours is judged from `TERM` (set, not `dumb`)
  instead of terminfo; `terminal-colors.d` files are not read; the width
  comes from `COLUMNS` or `stty size` instead of the kernel.
- ISO week numbers follow ISO 8601 in every mode (util-linux 2.41 makes an
  exception with `--week=N` and colours on). Month arithmetic is exact:
  `cal -S -n 26 1 2026` starts in December 2024, where util-linux prints a
  month named `(null)`.
- `-n` counts above 2147483647 are refused; util-linux prints nothing.
- `--help` lists the supported options and ends with a note on the
  calendar; `--version` prints one line.

## Layout

```text
source/main.loup                 # entry point
source/appinfo.loup              # name, version, exit statuses
source/cli/args.loup             # getopt_long-style options, values, exclusions
source/cli/numbers.loup          # strtol-style numbers and util-linux's messages
source/cli/usage.loup            # --help and --version text
source/cli/app.loup              # run(): parse, dispatch, exit status
source/calendar/request.loup     # operands and timestamps: year, month, day to mark
source/calendar/days.loup        # weekdays, days of the year, month arithmetic
source/calendar/weeks.loup       # US and ISO 8601 week numbers
source/calendar/grid.loup        # a month as six weeks of cells
source/calendar/layout.loup      # drawing months: usual and vertical layout, highlight
source/calendar/names.loup       # month and weekday names
source/calendar/terminal.loup    # terminal detection, width, --color decision
source/commands/cal.loup         # calendar_lines(), run_cal()
tests/*_test.loup                # unit tests (make test)
tests/e2e.sh                     # end-to-end tests of build/cal (make e2e)
specs/cal/                       # requirements, design, tasks
```

[AGENTS.md](AGENTS.md) has every build and test command and the conventions
for changing the code.

## License

[MIT](LICENSE), copyright 2026 Code Craft AI LLC. The Loup skill in
[`skills/loup-programmer/`](skills/loup-programmer/) is copied from the Loup
project and is not covered by this license; it keeps the Loup project's terms.
