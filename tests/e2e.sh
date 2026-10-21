#!/usr/bin/env bash
# End-to-end tests: run the built binary and compare its standard output
# (byte for byte) and exit status with the expected ones, and for errors
# its standard error. The expected calendars are util-linux cal 2.41's
# output with --reform=gregorian and TZ=UTC.
#
# Calendar lines end in spaces, so the expected text below marks each line
# end with `|`, and `^[` stands for the escape character.
#
# usage: tests/e2e.sh BINARY

set -u
BIN=$1
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
pass=0
fail=0

# compare NAME STATUS WANT_STATUS: compares $TMP/out with $TMP/want.
compare() {
    local name=$1 status=$2 want_status=$3
    if [ "$status" -eq "$want_status" ] && cmp -s "$TMP/want" "$TMP/out"; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        echo "FAIL: $name (exit $status, expected $want_status)"
        diff "$TMP/want" "$TMP/out" | cat -A | sed 's/^/    /' | head -20
        sed 's/^/    stderr: /' "$TMP/err" | head -5
    fi
}

# check_cal NAME STATUS [ARGS...] <<'EOF'
# Runs BINARY ARGS... and compares standard output with the text on
# standard input, after removing the `|` at each line end and turning `^[`
# into the escape character.
check_cal() {
    local name=$1 want_status=$2
    shift 2
    sed 's/|$//; s/\^\[/\x1b/g' > "$TMP/want"
    "$BIN" "$@" < /dev/null > "$TMP/out" 2> "$TMP/err"
    compare "$name" $? "$want_status"
}

# check_err NAME STATUS EXPECTED_STDERR [ARGS...]
# Runs BINARY ARGS... and compares standard error; standard output must be
# empty.
check_err() {
    local name=$1 want_status=$2
    printf '%s' "$3" > "$TMP/want_err"
    shift 3
    "$BIN" "$@" < /dev/null > "$TMP/out" 2> "$TMP/err"
    local status=$?
    if [ "$status" -eq "$want_status" ] && cmp -s "$TMP/want_err" "$TMP/err" && [ ! -s "$TMP/out" ]; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        echo "FAIL: $name (exit $status, expected $want_status)"
        diff "$TMP/want_err" "$TMP/err" | sed 's/^/    /' | head -10
        sed 's/^/    stdout: /' "$TMP/out" | head -5
    fi
}

# Every case runs in UTC, as cal itself reads today's date.
export TZ=UTC
unset NO_COLOR

# Single months.
check_cal "one month" 0 2 2026 <<'EOF'
    February 2026   |
Su Mo Tu We Th Fr Sa|
 1  2  3  4  5  6  7|
 8  9 10 11 12 13 14|
15 16 17 18 19 20 21|
22 23 24 25 26 27 28|
                    |
                    |
EOF
check_cal "month name" 0 sep 2026 <<'EOF'
   September 2026   |
Su Mo Tu We Th Fr Sa|
       1  2  3  4  5|
 6  7  8  9 10 11 12|
13 14 15 16 17 18 19|
20 21 22 23 24 25 26|
27 28 29 30         |
                    |
EOF
check_cal "Monday first" 0 -m 3 2026 <<'EOF'
     March 2026     |
Mo Tu We Th Fr Sa Su|
                   1|
 2  3  4  5  6  7  8|
 9 10 11 12 13 14 15|
16 17 18 19 20 21 22|
23 24 25 26 27 28 29|
30 31               |
EOF
check_cal "options after operands" 0 2 2024 -m <<'EOF'
    February 2024   |
Mo Tu We Th Fr Sa Su|
          1  2  3  4|
 5  6  7  8  9 10 11|
12 13 14 15 16 17 18|
19 20 21 22 23 24 25|
26 27 28 29         |
                    |
EOF
check_cal "day of the year" 0 -j 2 2024 <<'EOF'
       February 2024       |
Sun Mon Tue Wed Thu Fri Sat|
                 32  33  34|
 35  36  37  38  39  40  41|
 42  43  44  45  46  47  48|
 49  50  51  52  53  54  55|
 56  57  58  59  60        |
                           |
EOF

# Several months.
check_cal "three months" 0 -3 1 2026 <<'EOF'
    December 2025         January 2026          February 2026   |
Su Mo Tu We Th Fr Sa  Su Mo Tu We Th Fr Sa  Su Mo Tu We Th Fr Sa|
    1  2  3  4  5  6               1  2  3   1  2  3  4  5  6  7|
 7  8  9 10 11 12 13   4  5  6  7  8  9 10   8  9 10 11 12 13 14|
14 15 16 17 18 19 20  11 12 13 14 15 16 17  15 16 17 18 19 20 21|
21 22 23 24 25 26 27  18 19 20 21 22 23 24  22 23 24 25 26 27 28|
28 29 30 31           25 26 27 28 29 30 31                      |
                                                                |
EOF
check_cal "span" 0 -S -n 2 1 2026 <<'EOF'
    December 2025         January 2026    |
Su Mo Tu We Th Fr Sa  Su Mo Tu We Th Fr Sa|
    1  2  3  4  5  6               1  2  3|
 7  8  9 10 11 12 13   4  5  6  7  8  9 10|
14 15 16 17 18 19 20  11 12 13 14 15 16 17|
21 22 23 24 25 26 27  18 19 20 21 22 23 24|
28 29 30 31           25 26 27 28 29 30 31|
                                          |
EOF
check_cal "whole year" 0 -y 2026 <<'EOF'
                               2026                               |
|
       January               February                 March       |
Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa|
             1  2  3    1  2  3  4  5  6  7    1  2  3  4  5  6  7|
 4  5  6  7  8  9 10    8  9 10 11 12 13 14    8  9 10 11 12 13 14|
11 12 13 14 15 16 17   15 16 17 18 19 20 21   15 16 17 18 19 20 21|
18 19 20 21 22 23 24   22 23 24 25 26 27 28   22 23 24 25 26 27 28|
25 26 27 28 29 30 31                          29 30 31            |
                                                                  |
        April                   May                   June        |
Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa|
          1  2  3  4                   1  2       1  2  3  4  5  6|
 5  6  7  8  9 10 11    3  4  5  6  7  8  9    7  8  9 10 11 12 13|
12 13 14 15 16 17 18   10 11 12 13 14 15 16   14 15 16 17 18 19 20|
19 20 21 22 23 24 25   17 18 19 20 21 22 23   21 22 23 24 25 26 27|
26 27 28 29 30         24 25 26 27 28 29 30   28 29 30            |
                       31                                         |
        July                  August                September     |
Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa|
          1  2  3  4                      1          1  2  3  4  5|
 5  6  7  8  9 10 11    2  3  4  5  6  7  8    6  7  8  9 10 11 12|
12 13 14 15 16 17 18    9 10 11 12 13 14 15   13 14 15 16 17 18 19|
19 20 21 22 23 24 25   16 17 18 19 20 21 22   20 21 22 23 24 25 26|
26 27 28 29 30 31      23 24 25 26 27 28 29   27 28 29 30         |
                       30 31                                      |
       October               November               December      |
Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa|
             1  2  3    1  2  3  4  5  6  7          1  2  3  4  5|
 4  5  6  7  8  9 10    8  9 10 11 12 13 14    6  7  8  9 10 11 12|
11 12 13 14 15 16 17   15 16 17 18 19 20 21   13 14 15 16 17 18 19|
18 19 20 21 22 23 24   22 23 24 25 26 27 28   20 21 22 23 24 25 26|
25 26 27 28 29 30 31   29 30                  27 28 29 30 31      |
                                                                  |
EOF
check_cal "lone year, six columns" 0 -c 6 2027 <<'EOF'
                                                                  2027                                                                 |
|
       January               February                 March                  April                   May                   June        |
Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa|
                1  2       1  2  3  4  5  6       1  2  3  4  5  6                1  2  3                      1          1  2  3  4  5|
 3  4  5  6  7  8  9    7  8  9 10 11 12 13    7  8  9 10 11 12 13    4  5  6  7  8  9 10    2  3  4  5  6  7  8    6  7  8  9 10 11 12|
10 11 12 13 14 15 16   14 15 16 17 18 19 20   14 15 16 17 18 19 20   11 12 13 14 15 16 17    9 10 11 12 13 14 15   13 14 15 16 17 18 19|
17 18 19 20 21 22 23   21 22 23 24 25 26 27   21 22 23 24 25 26 27   18 19 20 21 22 23 24   16 17 18 19 20 21 22   20 21 22 23 24 25 26|
24 25 26 27 28 29 30   28                     28 29 30 31            25 26 27 28 29 30      23 24 25 26 27 28 29   27 28 29 30         |
31                                                                                          30 31                                      |
        July                  August                September               October               November               December      |
Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa|
             1  2  3    1  2  3  4  5  6  7             1  2  3  4                   1  2       1  2  3  4  5  6             1  2  3  4|
 4  5  6  7  8  9 10    8  9 10 11 12 13 14    5  6  7  8  9 10 11    3  4  5  6  7  8  9    7  8  9 10 11 12 13    5  6  7  8  9 10 11|
11 12 13 14 15 16 17   15 16 17 18 19 20 21   12 13 14 15 16 17 18   10 11 12 13 14 15 16   14 15 16 17 18 19 20   12 13 14 15 16 17 18|
18 19 20 21 22 23 24   22 23 24 25 26 27 28   19 20 21 22 23 24 25   17 18 19 20 21 22 23   21 22 23 24 25 26 27   19 20 21 22 23 24 25|
25 26 27 28 29 30 31   29 30 31               26 27 28 29 30         24 25 26 27 28 29 30   28 29 30               26 27 28 29 30 31   |
                                                                     31                                                                |
EOF
check_cal "twelve months" 0 -Y -c 4 11 2026 <<'EOF'
    November 2026          December 2026          January 2027           February 2027   |
Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa|
 1  2  3  4  5  6  7          1  2  3  4  5                   1  2       1  2  3  4  5  6|
 8  9 10 11 12 13 14    6  7  8  9 10 11 12    3  4  5  6  7  8  9    7  8  9 10 11 12 13|
15 16 17 18 19 20 21   13 14 15 16 17 18 19   10 11 12 13 14 15 16   14 15 16 17 18 19 20|
22 23 24 25 26 27 28   20 21 22 23 24 25 26   17 18 19 20 21 22 23   21 22 23 24 25 26 27|
29 30                  27 28 29 30 31         24 25 26 27 28 29 30   28                  |
                                              31                                         |
     March 2027             April 2027              May 2027               June 2027     |
Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa|
    1  2  3  4  5  6                1  2  3                      1          1  2  3  4  5|
 7  8  9 10 11 12 13    4  5  6  7  8  9 10    2  3  4  5  6  7  8    6  7  8  9 10 11 12|
14 15 16 17 18 19 20   11 12 13 14 15 16 17    9 10 11 12 13 14 15   13 14 15 16 17 18 19|
21 22 23 24 25 26 27   18 19 20 21 22 23 24   16 17 18 19 20 21 22   20 21 22 23 24 25 26|
28 29 30 31            25 26 27 28 29 30      23 24 25 26 27 28 29   27 28 29 30         |
                                              30 31                                      |
      July 2027             August 2027          September 2027          October 2027    |
Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa   Su Mo Tu We Th Fr Sa|
             1  2  3    1  2  3  4  5  6  7             1  2  3  4                   1  2|
 4  5  6  7  8  9 10    8  9 10 11 12 13 14    5  6  7  8  9 10 11    3  4  5  6  7  8  9|
11 12 13 14 15 16 17   15 16 17 18 19 20 21   12 13 14 15 16 17 18   10 11 12 13 14 15 16|
18 19 20 21 22 23 24   22 23 24 25 26 27 28   19 20 21 22 23 24 25   17 18 19 20 21 22 23|
25 26 27 28 29 30 31   29 30 31               26 27 28 29 30         24 25 26 27 28 29 30|
                                                                     31                  |
EOF
check_cal "below year 1" 0 -3 1 1 <<'EOF'
    December 0000         January 0001          February 0001   |
Su Mo Tu We Th Fr Sa  Su Mo Tu We Th Fr Sa  Su Mo Tu We Th Fr Sa|
                1  2      1  2  3  4  5  6               1  2  3|
 3  4  5  6  7  8  9   7  8  9 10 11 12 13   4  5  6  7  8  9 10|
10 11 12 13 14 15 16  14 15 16 17 18 19 20  11 12 13 14 15 16 17|
17 18 19 20 21 22 23  21 22 23 24 25 26 27  18 19 20 21 22 23 24|
24 25 26 27 28 29 30  28 29 30 31           25 26 27 28         |
31                                                              |
EOF
check_cal "largest year" 0 12 2147483646 <<'EOF'
 December 2147483646|
Su Mo Tu We Th Fr Sa|
                   1|
 2  3  4  5  6  7  8|
 9 10 11 12 13 14 15|
16 17 18 19 20 21 22|
23 24 25 26 27 28 29|
30 31               |
EOF

# Week numbers.
check_cal "US weeks" 0 -w 12 2026 <<'EOF'
     December 2026     |
   Su Mo Tu We Th Fr Sa|
49        1  2  3  4  5|
50  6  7  8  9 10 11 12|
51 13 14 15 16 17 18 19|
52 20 21 22 23 24 25 26|
53 27 28 29 30 31      |
                       |
EOF
check_cal "ISO weeks" 0 -wm 1 2021 <<'EOF'
      January 2021     |
   Mo Tu We Th Fr Sa Su|
53              1  2  3|
 1  4  5  6  7  8  9 10|
 2 11 12 13 14 15 16 17|
 3 18 19 20 21 22 23 24|
 4 25 26 27 28 29 30 31|
                       |
EOF
check_cal "ISO week 1 in December" 0 -wm 12 2025 <<'EOF'
     December 2025     |
   Mo Tu We Th Fr Sa Su|
49  1  2  3  4  5  6  7|
50  8  9 10 11 12 13 14|
51 15 16 17 18 19 20 21|
52 22 23 24 25 26 27 28|
 1 29 30 31            |
                       |
EOF
check_cal "ISO weeks, day of year" 0 -jmw -n 2 12 2026 <<'EOF'
         December 2026                   January 2027         |
   Mon Tue Wed Thu Fri Sat Sun     Mon Tue Wed Thu Fri Sat Sun|
49     335 336 337 338 339 340  53                   1   2   3|
50 341 342 343 344 345 346 347   1   4   5   6   7   8   9  10|
51 348 349 350 351 352 353 354   2  11  12  13  14  15  16  17|
52 355 356 357 358 359 360 361   3  18  19  20  21  22  23  24|
53 362 363 364 365               4  25  26  27  28  29  30  31|
                                                              |
EOF
check_cal "--week chooses the month" 0 --week=10 2026 <<'EOF'
       March 2026      |
   Su Mo Tu We Th Fr Sa|
10  1  2  3  4  5  6  7|
11  8  9 10 11 12 13 14|
12 15 16 17 18 19 20 21|
13 22 23 24 25 26 27 28|
14 29 30 31            |
                       |
EOF
check_cal "ISO week 53 of the year before" 0 -m --week=53 2021 <<'EOF'
      January 2021     |
   Mo Tu We Th Fr Sa Su|
53              1  2  3|
 1  4  5  6  7  8  9 10|
 2 11 12 13 14 15 16 17|
 3 18 19 20 21 22 23 24|
 4 25 26 27 28 29 30 31|
                       |
EOF

# Vertical.
check_cal "vertical" 0 -v 10 2026 <<'EOF'
    October 2026       |
Su     4 11 18 25   |
Mo     5 12 19 26   |
Tu     6 13 20 27   |
We     7 14 21 28   |
Th  1  8 15 22 29   |
Fr  2  9 16 23 30   |
Sa  3 10 17 24 31   |
EOF
check_cal "vertical with weeks" 0 -vw -3 1 2026 <<'EOF'
    December 2025      January 2026       February 2026      |
Su     7 14 21 28         4 11 18 25      1  8 15 22      |
Mo  1  8 15 22 29         5 12 19 26      2  9 16 23      |
Tu  2  9 16 23 30         6 13 20 27      3 10 17 24      |
We  3 10 17 24 31         7 14 21 28      4 11 18 25      |
Th  4 11 18 25         1  8 15 22 29      5 12 19 26      |
Fr  5 12 19 26         2  9 16 23 30      6 13 20 27      |
Sa  6 13 20 27         3 10 17 24 31      7 14 21 28      |
   49 50 51 52 53      1  2  3  4  5      6  7  8  9      |
EOF

# Timestamps.
check_cal "date" 0 2024-02-29 <<'EOF'
    February 2024   |
Su Mo Tu We Th Fr Sa|
             1  2  3|
 4  5  6  7  8  9 10|
11 12 13 14 15 16 17|
18 19 20 21 22 23 24|
25 26 27 28 29      |
                    |
EOF
check_cal "date and time" 0 '2024-02-29 23:59' <<'EOF'
    February 2024   |
Su Mo Tu We Th Fr Sa|
             1  2  3|
 4  5  6  7  8  9 10|
11 12 13 14 15 16 17|
18 19 20 21 22 23 24|
25 26 27 28 29      |
                    |
EOF
check_cal "epoch" 0 @0 <<'EOF'
    January 1970    |
Su Mo Tu We Th Fr Sa|
             1  2  3|
 4  5  6  7  8  9 10|
11 12 13 14 15 16 17|
18 19 20 21 22 23 24|
25 26 27 28 29 30 31|
                    |
EOF
check_cal "day past the month" 0 2026-02-30 <<'EOF'
     March 2026     |
Su Mo Tu We Th Fr Sa|
 1  2  3  4  5  6  7|
 8  9 10 11 12 13 14|
15 16 17 18 19 20 21|
22 23 24 25 26 27 28|
29 30 31            |
                    |
EOF

# Highlighting.
check_cal "highlight" 0 --color=always 15 2 2026 <<'EOF'
    February 2026   |
Su Mo Tu We Th Fr Sa|
 1  2  3  4  5  6  7|
 8  9 10 11 12 13 14|
^[[7m15^[[0m 16 17 18 19 20 21|
22 23 24 25 26 27 28|
                    |
                    |
EOF
check_cal "highlight, day of year" 0 --color=always -j 15 2 2026 <<'EOF'
       February 2026       |
Sun Mon Tue Wed Thu Fri Sat|
 32  33  34  35  36  37  38|
 39  40  41  42  43  44  45|
^[[7m 46^[[0m  47  48  49  50  51  52|
 53  54  55  56  57  58  59|
                           |
                           |
EOF
check_cal "highlight week" 0 --color=always -wm --week=8 15 2 2026 <<'EOF'
     February 2026     |
   Mo Tu We Th Fr Sa Su|
 5                    1|
 6  2  3  4  5  6  7  8|
 7  9 10 11 12 13 14 ^[[7m15^[[0m|
^[[7m 8^[[0m 16 17 18 19 20 21 22|
 9 23 24 25 26 27 28   |
                       |
EOF
check_cal "never" 0 --color=never 15 2 2026 <<'EOF'
    February 2026   |
Su Mo Tu We Th Fr Sa|
 1  2  3  4  5  6  7|
 8  9 10 11 12 13 14|
15 16 17 18 19 20 21|
22 23 24 25 26 27 28|
                    |
                    |
EOF

# Errors: getopt's messages are followed by the Try line, util-linux's own
# are not; every failure is status 1.
TRY=$'\nTry \'cal --help\' for more information.\n'
check_err "invalid option"     1 "cal: invalid option -- 'q'$TRY"                          -q
check_err "unknown long"       1 "cal: unrecognized option '--merge'$TRY"                  --merge
check_err "ambiguous"          1 "cal: option '--mon' is ambiguous; possibilities: '--monday' '--months'$TRY" --mon
check_err "missing value"      1 "cal: option requires an argument -- 'n'$TRY"             -n
check_err "long missing value" 1 "cal: option '--columns' requires an argument$TRY"        --columns
check_err "unwanted value"     1 "cal: option '--year' doesn't allow an argument$TRY"      --year=2026
check_err "bad usage"          1 "cal: bad usage$TRY"                                      1 2 3 4
check_err "exclusive"          1 $'cal: mutually exclusive arguments: --twelve --months --year\n' -y -n 2
check_err "month count"        1 $'cal: invalid month argument: \'x\'\n'                   -n x
check_err "negative count"     1 $'cal: invalid month argument: \'-1\': Numerical result out of range\n' -n -1
check_err "week value"         1 $'cal: illegal week value: use 1-54\n'                    --week=55
check_err "week argument"      1 $'cal: invalid week argument: \'x\'\n'                    --week=x
check_err "no ISO week 54"     1 $'cal: illegal week value: year 2026 doesn\'t have week 54\n' -m --week=54 2026
check_err "color mode"         1 $'cal: unsupported color mode: \'pink\'\n'                --color=pink
check_err "columns"            1 $'cal: failed to parse columns: \'x\': Invalid argument\n' -c x
check_err "reform value"       1 $'cal: invalid --reform value: \'x\'\n'                   --reform x
check_err "Julian calendar"    1 $'cal: --reform \'1752\' is not supported: this cal uses the Gregorian calendar for every year\n' --reform 1752
check_err "day 32"             1 $'cal: illegal day value: use 1-31\n'                     32 1 2026
check_err "February 30"        1 $'cal: illegal day value: use 1-29\n'                     30 2 2024
check_err "month 13"           1 $'cal: illegal month value: use 1-12\n'                   13 2026
check_err "month 1x"           1 $'cal: illegal month value: use 1-12: \'1x\'\n'           1x 2026
check_err "month name"         1 $'cal: unknown month name: foo\n'                         foo 2026
check_err "year 0"             1 $'cal: illegal year value: use positive integer\n'        0
check_err "year too big"       1 $'cal: illegal year value: \'2147483648\': Numerical result out of range\n' 2147483648
check_err "not a timestamp"    1 $'cal: failed to parse timestamp or unknown month name: 2026x\n' 2026x

# Help and version.
"$BIN" --version > "$TMP/out" 2>&1
printf 'cal (loup-cmd-cal) 0.1.0\n' > "$TMP/want"
compare "version" $? 0
"$BIN" --help > "$TMP/help" 2>&1
if [ $? -eq 0 ] && sed -n 2p "$TMP/help" | grep -qx 'Usage:' && grep -q '^ -w, --week\[=<num>\]' "$TMP/help"; then
    pass=$((pass + 1))
else
    fail=$((fail + 1))
    echo "FAIL: --help"
fi

# Today: the only case that depends on the clock. The current month's
# header, and nothing highlighted in a file.
"$BIN" > "$TMP/out" 2>&1
header=$(LC_ALL=C date -u '+%B %Y')
if [ $? -eq 0 ] && head -1 "$TMP/out" | grep -q "^ *$header *\$" && [ "$(wc -l < "$TMP/out")" -eq 8 ] && ! grep -q $'\x1b' "$TMP/out"; then
    pass=$((pass + 1))
else
    fail=$((fail + 1))
    echo "FAIL: current month (want '$header')"
    sed 's/^/    /' "$TMP/out"
fi

# On a terminal (script(1) gives the binary a pseudo-terminal), the given
# day is highlighted unless NO_COLOR is set or TERM is dumb; --color
# overrides NO_COLOR. script turns line ends into CR LF.
on_tty() {
    script -qec "$1" /dev/null < /dev/null | tr -d '\r'
}
if command -v script > /dev/null; then
    REVERSED=$'\x1b[7m15\x1b[0m 16 17 18 19 20 21'
    for setting in "TERM=xterm:yes" "TERM=xterm NO_COLOR=1:no" "TERM=dumb:no"; do
        envs=${setting%%:*}
        want=${setting##*:}
        got=no
        if env $envs bash -c "$(declare -f on_tty); on_tty '$BIN 15 2 2026'" | grep -qF "$REVERSED"; then
            got=yes
        fi
        if [ "$got" = "$want" ]; then
            pass=$((pass + 1))
        else
            fail=$((fail + 1))
            echo "FAIL: terminal with $envs: highlighted=$got, expected $want"
        fi
    done
    if env TERM=xterm NO_COLOR=1 bash -c "$(declare -f on_tty); on_tty '$BIN --color 15 2 2026'" | grep -qF "$REVERSED"; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        echo "FAIL: --color on a terminal with NO_COLOR"
    fi
    # Months per row follow the terminal width: two fit in 45 columns.
    if env TERM=xterm COLUMNS=45 bash -c "$(declare -f on_tty); on_tty '$BIN -3 1 2026'" | head -1 | grep -qx '    December 2025         January 2026    '; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        echo "FAIL: two months in 45 columns"
    fi
else
    echo "e2e: script(1) not found, terminal cases skipped"
fi

echo "e2e: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
