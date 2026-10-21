# Design: cal

## Overview

`main()` passes `runtime.args()` to `cli.app.run`, which parses the options
into `Options` (getopt_long's rules), handles `--help` and `--version`, and
calls `commands.cal.run_cal`. `run_cal` gathers what cal needs from outside
(today's date, whether standard output is a terminal, its width, whether to
highlight) into `Surroundings` and hands both to `calendar_lines`, a pure
function that returns the lines to print. Tests call the pure functions
with pinned dates; only `run_cal` reads the clock and prints.

The calendar is computed in three steps:

1. `calendar.request.resolve_request` turns the operands and today's date
   into a `Request`: year, month, the day of the year to highlight, and
   whether a lone year means the whole year.
2. `calendar.grid.fill_month` lays out each month as 42 cells (six weeks)
   and six week numbers.
3. `calendar.layout.render_row` (or `render_vertical_row` for `-v`) draws a
   row of months side by side, every line padded to its full width.

## Modules

| Module | Contents |
|---|---|
| `source/main.loup` | entry point: `run(runtime.args())` |
| `source/appinfo.loup` | name, version, summary, exit statuses 0 and 1 |
| `source/cli/numbers.loup` | `parse_number(text, lowest, highest): (int, int)`: strtol rules, a (value, status) tuple; util-linux's message wording |
| `source/cli/args.loup` | `Columns` enum, `Options` and `ArgError` classes, the long option table as `(name, key, kind)` tuples, `apply()` per option, `parse_args` |
| `source/cli/usage.loup` | `usage()`, `version_line()` |
| `source/cli/app.loup` | `run()`: parse, help/version, `run_cal`, exceptions to status 1 |
| `source/calendar/terminal.loup` | `ColorMode`; `stdout_is_terminal()` (`test -t 1` through `execShell`), `terminal_width()` (`$COLUMNS`, then `stty size`), `colors_enabled()` (pure) |
| `source/calendar/names.loup` | English month and weekday names, `month_from_name`, `weekday_headings` |
| `source/calendar/days.loup` | `weekday_of` (Sunday = 0, from `Date.new(...).weekday()`), `day_of_year` (`monthLength`), `days_in_year` (`leapYear`), `format_year` (`padLeft`), `shift_month` returning a `(year, month)` tuple |
| `source/calendar/weeks.loup` | `Numbering` enum; `week_offset`, `week_number`, `week_start`, `month_of_week` for US and ISO weeks |
| `source/calendar/grid.loup` | `MonthGrid` class and `fill_month` |
| `source/calendar/layout.loup` | `Style` class and `make_style`; `center`, `left_align`, cells with the reverse-video highlight; the two renderers |
| `source/calendar/request.loup` | `Request` class, `parse_timestamp` (`Date?`), `resolve_request` |
| `source/commands/cal.loup` | `Surroundings`, `months_that_fit`, `months_per_row` (a guard on `Columns.Fixed(n)`), `style_for` (named arguments), `calendar_lines`, `run_cal` |

### Dates

`core.datetime` does the calendar arithmetic: `Date.new(y, m, 1).weekday()`
gives the weekday of each month's first day, from which every other day's
weekday follows by counting (so day numbers outside the month, which the
week rules use, need no special case); `monthLength` and `leapYear` give
month and year lengths; `Date.today()` is today (UTC); `addDays` moves
timestamps (`yesterday`, `+3days`, `2026-02-30` running on into March);
`Date.fromTimestamp` reads `@SECONDS`; `Date.ordinal()` is the day of the
year that the highlight compares. Months before or after the requested one
come from `shift_month`, which counts months since year 0 so that `-3`,
`-S` and `-n` cross years (and year 1) exactly.

### Week numbers

Both numberings are `(day of year + offset) / 7` with an offset from
January 1's weekday (`week_offset`). US weeks (Sunday first): offset
`jan1 + 6`, so January 1 is always in week 1. ISO weeks (Monday first):
offset `jan1 + 5`, or `jan1 - 2` when the year starts on Friday or
Saturday; a result below 1 means the last week of the year before, and
December 29-31 that fall on Monday to Wednesday, in a year ending Monday
to Wednesday, are week 1 of the next year. `fill_month` numbers the first
line and counts on, asking again once the count passes 52, as util-linux
does. `--week=N` picks the month in which week N starts (`week_start`,
`month_of_week`).

### Layout

A day cell is three characters (four with `-j`), its leading space
included; the first cell of a week drops that space unless a week number
column (two digits and a space) stands before it. Month headers are
centred with the odd space on the left (util-linux's `mbsalign`); every
month has six week lines. Months in a row are separated by two spaces,
three with `-y`/`-Y`, one with `-v`. Without `-c`, a terminal gets as many
months per row as fit (`months_that_fit`, at most three); a file or pipe
gets three.

### Highlighting

`colors_enabled` decides: `--color=always` yes, `never` no, `auto` (or a
bare `--color`) when standard output is a terminal whose `TERM` is set and
not `dumb`, and no `--color` at all also requires `NO_COLOR` to be unset.
When it says no, the day to mark is dropped, as util-linux drops it. The
marked day's digits and a `--week=N` week number are wrapped in `ESC[7m`
and `ESC[0m`.

## Differences from the original

- Only the Gregorian calendar, for every year: the output equals util-linux
  `cal --reform=gregorian`. util-linux's default (`--reform=1752`) switches
  to the Julian calendar before September 14, 1752, so September 1752
  there misses 11 days and earlier years differ; `--reform 1752` and
  `--reform julian` are refused here with a message.
- Today is the UTC date (`Date.today()`; Loup 1.26.0 has no local time
  zone): after local midnight but before UTC midnight, or the other way
  round, the current month and highlighted day are UTC's. Timestamps
  (`@SECONDS`, dates with times) are read in UTC as well.
- English month and weekday names only, and weeks start on Sunday unless
  `-m` is given: the locale (`LC_TIME`) is not consulted.
- Timestamps: a subset of util-linux's `parse_timestamp`. Relative
  timestamps take whole days or weeks (`+3days`, `-2w`, `5 days ago`);
  hours, months, combinations and weekday names (`Sun 2026-02-15`) are not
  accepted, nor two-digit years.
- Whether a terminal has colours is judged from `TERM` (set and not `dumb`)
  instead of terminfo, and the `terminal-colors.d` configuration files are
  not read. The terminal width comes from `COLUMNS` or `stty size`, not
  from the `TIOCGWINSZ` ioctl.
- ISO week numbers follow ISO 8601 in every mode. util-linux 2.41 skips its
  "December 29-31 may be week 1" rule when `--week=N` is given and colours
  are on.
- Month arithmetic is exact: `cal -S -n 26 1 2026` starts in December 2024,
  where util-linux 2.41 prints a month named `(null)`. A timestamp in year 0
  shows year 0000 (util-linux prints a garbage year).
- `-n` counts above 2147483647 are refused as out of range; util-linux
  stores them in an int and prints nothing.
- `--help` lists the options supported here and ends with a note on the
  calendar instead of the man page reference; `--version` prints one line.

## Error handling

Option errors are `ArgError` values: getopt's messages (`invalid option`,
`unrecognized option`, `is ambiguous`, `requires an argument`, `doesn't
allow an argument`) carry `try_help` for the `Try 'cal --help'` line;
util-linux's value messages do not. Operand errors are `Err(string)` from
`resolve_request`, printed by `run_cal` as `cal: MESSAGE`. Every failure is
status 1, as in util-linux. Dates are validated before `Date.new` is called,
so `ValueError` does not occur; `run()` still maps any exception to
status 1.

## Testing

- `tests/args_test.loup`: clusters, values, long options and abbreviations,
  optional values, `--`, every getopt and value message, `-y/-Y/-n`.
- `tests/numbers_test.loup`: signs, blanks, ranges, messages.
- `tests/days_test.loup`: weekdays, days of the year, years, month
  arithmetic, US and ISO week numbers against known calendars.
- `tests/layout_test.loup`: grids, names, centring, rendered months (usual,
  `-j`, `-w`, `-v`, side by side) and the highlight.
- `tests/request_test.loup`: every operand form and timestamp with a
  pinned today, and every operand message.
- `tests/cal_test.loup`: whole runs through `calendar_lines`: spans, `-y`,
  `-Y`, `-c`, rows on narrow and wide terminals, today's highlight.
- `tests/app_test.loup`: exit statuses through `run()`.
- `tests/e2e.sh`: the native binary against util-linux's output (with
  `--reform=gregorian`, `TZ=UTC`) for 28 calendars and 25 error messages,
  the current month, and highlighting and widths on a pseudo-terminal
  (`script`).
