# Requirements: cal

## Introduction

`cal` prints a calendar: one month, a few months around a date, or a whole
year, in the terminal. This repository recreates util-linux `cal` (2.41) in
Loup: the `[[day] month] year` operands, month names and timestamps, `-1`,
`-3`, `-n`, `-S`, `-y`, `-Y`, Sunday or Monday weeks, day-of-year (`-j`) and
week-number (`-w`) columns, vertical layout, the number of months per row,
and the highlight of today's date on a terminal. The calendar is the
proleptic Gregorian calendar for every year, as util-linux shows it with
`--reform=gregorian`. Shell users run it to look up dates; scripts use it
with explicit dates, where the output must be exact.

## Requirements

### Requirement 1: Which months are shown

**User Story:** As a shell user, I want to name a month, a year or a date
so that cal shows the part of the calendar I need.

#### Acceptance Criteria

1. WHEN no operand is given, THE program SHALL show the current month.
2. WHEN one operand of digits is given, THE program SHALL take it as a year
   and show the whole year (as `-y`), unless `-n`, `-3` or `-Y` asks for a
   number of months; those start from the current month when the year is
   the current one, and from the current month's number in the given year
   otherwise.
3. WHEN two operands are given, THE program SHALL take them as MONTH YEAR,
   where MONTH is a number 1-12 or an English month name or abbreviation in
   any case (`feb`, `February`).
4. WHEN three operands are given, THE program SHALL take them as DAY MONTH
   YEAR and treat that date as the date to highlight.
5. WHEN one operand that is not all digits is given, THE program SHALL take
   it as a timestamp (`YYYY-MM-DD`, `YYYY-MM-DD HH:MM[:SS]`,
   `YYYY-MM-DDTHH:MM:SS`, `HH:MM[:SS]`, `@SECONDS`, `now`, `today`,
   `yesterday`, `tomorrow`, `+N` or `-N` days or weeks, `N days ago`) and show that date's month with that date
   as the one to highlight, or else as a month name of the current year.
6. WHEN `-3` is given, THE program SHALL show the previous, the given and
   the next month; WHEN `-n N` is given, N months starting with the given
   month; WHEN `-S` is given with several months, the given month SHALL be
   in the middle.
7. WHEN `-y` is given, THE program SHALL show the twelve months of the year
   under a centred year line; WHEN `-Y` is given, the twelve months starting
   with the given month, without the year line.
8. THE program SHALL accept years from 1 to 2147483646 and SHALL show the
   months before year 1 that `-3` or `-S` reach as year 0000 and earlier.

### Requirement 2: Month layout

**User Story:** As a reader, I want the familiar cal layout so that the
output looks like the calendar I know and lines up in scripts.

#### Acceptance Criteria

1. THE program SHALL print each month as a header with the month name and
   the four-digit year centred over the week, a line of two-letter weekday
   names, and six week lines of right-aligned day numbers, every line padded
   with spaces to the full width.
2. WHEN `-m` is given, weeks SHALL start on Monday; by default, or with
   `-s`, on Sunday.
3. WHEN `-j` is given, THE program SHALL show each day's number within the
   year (1-366) in four-character cells under three-letter weekday names.
4. WHEN several months are shown, THE program SHALL put three months side by
   side separated by two spaces (three with `-y` and `-Y`), or the number
   given by `-c N`; on a terminal without `-c` it SHALL put as many as fit
   the terminal width, up to three (`-c auto`: no limit).
5. WHEN `-v` is given, THE program SHALL print the weekdays down the left
   and the weeks across, months side by side separated by one space and
   rows of months separated by a blank line.
6. WHEN `-y` is given, the twelve months SHALL be headed by the month name
   only, below a line with the year centred over all columns and a blank
   line.

### Requirement 3: Week numbers

**User Story:** As a planner, I want week numbers beside the weeks so that I
can find "week 43" quickly.

#### Acceptance Criteria

1. WHEN `-w` or `--week` is given, THE program SHALL show a week number to
   the left of each week (below the weeks with `-v`).
2. WHEN weeks start on Monday, the numbers SHALL be ISO 8601 week numbers
   (week 1 holds the year's first Thursday; the last days of December may be
   in week 1 and the first days of January in week 52 or 53).
3. WHEN weeks start on Sunday, the numbers SHALL be US week numbers (week 1
   holds January 1).
4. WHEN `--week=N` is given without a month, THE program SHALL show the
   month that holds week N of the year; WHEN N is outside 1-54 or the year
   has no week N, it SHALL report an error.

### Requirement 4: Highlighting today

**User Story:** As a terminal user, I want today's date marked so that I see
it at a glance, without escape codes in files and pipes.

#### Acceptance Criteria

1. WHEN standard output is a terminal whose `TERM` is set and not `dumb`,
   and `NO_COLOR` is not set, THE program SHALL show today's date (or the
   DAY of DAY MONTH YEAR) in reverse video (`ESC[7m` ... `ESC[0m`).
2. WHEN standard output is not a terminal, or `--color=never` is given, THE
   program SHALL print no escape codes at all.
3. WHEN `--color=always` is given, THE program SHALL highlight even when the
   output is not a terminal; `--color` and `--color=auto` SHALL highlight on
   a terminal whatever `NO_COLOR` says.
4. WHEN `--week=N` is given and highlighting is on, THE program SHALL show
   week number N in reverse video.
5. THE program SHALL take today's date from the system clock in UTC.

### Requirement 5: Command line

**User Story:** As a shell user, I want util-linux's options and messages so
that my habits and scripts keep working.

#### Acceptance Criteria

1. THE program SHALL accept the short options `-1 -3 -m -j -s -S -y -w -Y
   -v -V -h`, `-n N` and `-c N`, clustered (`-3mj`, `-n6`), and the long
   options `--one --three --months --span --sunday --monday --julian
   --reform --iso --year --twelve --week[=N] --vertical --columns
   --color[=WHEN] --help --version`, abbreviated to any unambiguous prefix,
   with values as `--name=VALUE` or `--name VALUE` (`--week` and `--color`
   only with `=`).
2. THE program SHALL accept options before and after the operands; `--`
   SHALL end the options.
3. WHEN an option is unknown, ambiguous, lacks its value or has one it does
   not take, THE program SHALL print getopt's message, then `Try 'cal
   --help' for more information.`, and exit with status 1.
4. WHEN a value or operand is invalid, THE program SHALL print util-linux's
   message (`cal: illegal month value: use 1-12`, `cal: invalid month
   argument: 'x'`, `cal: unknown month name: foo`, ...) and exit with
   status 1; WHEN there are more than three operands it SHALL print `cal:
   bad usage` and the `Try` line.
5. WHEN two of `-y`, `-Y` and `-n` are given, THE program SHALL print `cal:
   mutually exclusive arguments: --twelve --months --year` and exit with
   status 1.
6. WHEN `--reform` names `gregorian` or `iso`, or `--iso` is given, THE
   program SHALL accept it; WHEN it names `1752` or `julian`, it SHALL say
   that only the Gregorian calendar is supported and exit with status 1.
7. WHEN `-h`/`--help` or `-V`/`--version` is read, THE program SHALL print
   the help or the version line and exit with status 0, ignoring the rest of
   the command line.
