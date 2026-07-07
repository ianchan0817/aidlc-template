#!/usr/bin/env bash
# AI-friendly test sensor — wrap any test command so its output is agent-parseable.
#   scripts/agent-test.sh <command> [args...]      e.g.  scripts/agent-test.sh bun test
#
# Raw terminal output is hostile to model context: ANSI color codes fracture
# tokenization, progress bars flood via carriage returns, and one exception can
# emit a 300-line stack trace. This wrapper:
#   1. prints RESULT + exit code FIRST (summary before detail)
#   2. strips ANSI/VT control sequences and collapses \r progress overwrites
#   3. truncates stack-trace blocks (default 50 lines; AGENT_TEST_MAX_TRACE)
#   4. caps total output (default 400 lines; AGENT_TEST_MAX_LINES), keeping head+tail
#   5. preserves the untouched raw log on disk (unique per run, so parallel
#      invocations never clobber each other) and names it in the summary;
#      agent-test-last.log symlinks to the most recent run
# Exit code of the wrapped command is preserved.
# Text pipeline runs under LC_ALL=C: stray non-UTF-8 bytes in test output must
# never abort the filter and silently drop the failure message.

set -uo pipefail

MAX_TRACE="${AGENT_TEST_MAX_TRACE:-50}"
MAX_LINES="${AGENT_TEST_MAX_LINES:-400}"
TAIL_KEEP=80

if [ "$#" -lt 1 ]; then
  echo "usage: $0 <test command> [args...]" >&2
  exit 2
fi

# Trailing Xs only — BSD mktemp rejects templates with a suffix after the Xs.
RAW=$(mktemp "${TMPDIR:-/tmp}/agent-test.XXXXXX") || { echo "agent-test: mktemp failed" >&2; exit 2; }
ln -sf "$RAW" "${TMPDIR:-/tmp}/agent-test-last.log" 2>/dev/null || true

# Ask runners to skip color where they honor it; strip anyway below.
NO_COLOR=1 TERM=dumb "$@" >"$RAW" 2>&1
STATUS=$?

TOTAL_LINES=$(awk 'END { print NR }' "$RAW")
CMD_DESC=$(printf '%s' "$*" | tr '\n\r' '  ')
if [ "$STATUS" -eq 0 ]; then
  echo "RESULT: PASS (exit 0) — $CMD_DESC"
else
  echo "RESULT: FAIL (exit $STATUS) — $CMD_DESC"
fi
echo "raw log: $RAW ($TOTAL_LINES lines)"
echo "---"

# shellcheck disable=SC2016
LC_ALL=C sed -E \
  -e 's/\r$//' \
  -e 's/.*\r//' \
  -e $'s/\x1b\\[[0-9;:?<=>]*[ -\\/]*[@-~]//g' \
  -e $'s/\x1b\\][^\x07\x1b]*(\x07|\x1b\\\\)//g' \
  -e $'s/\x1b[@-Z\\\\^_]//g' \
  "$RAW" \
| LC_ALL=C awk -v maxt="$MAX_TRACE" '
    # Trace-block state machine: a starter line opens a block; any indented
    # line continues it (real Python tracebacks alternate File/source lines).
    # A non-indented line closes the block.
    function flushtrace() {
      if (n > maxt) printf("    ... [%d stack-trace lines truncated]\n", n - maxt)
      n = 0; intrace = 0
    }
    {
      starter = ($0 ~ /^[[:space:]]+(at |File \"|from |in <)/ || $0 ~ /^Traceback \(most recent call last\)/)
      cont = (intrace && $0 ~ /^[[:space:]]/)
      if (starter || cont) {
        intrace = 1
        n++
        if (n <= maxt) print
        next
      }
      flushtrace(); print
    }
    END { flushtrace() }
  ' \
| LC_ALL=C awk -v max="$MAX_LINES" -v tail="$TAIL_KEEP" -v raw="$RAW" '
    { lines[NR] = $0 }
    END {
      if (NR <= max) { for (i = 1; i <= NR; i++) print lines[i]; exit }
      t = tail; if (t >= max) t = max - 1
      head = max - t
      omitted = NR - head - t
      if (omitted < 1) { for (i = 1; i <= NR; i++) print lines[i]; exit }
      for (i = 1; i <= head; i++) print lines[i]
      printf("... [%d lines omitted — full output: %s]\n", omitted, raw)
      for (i = NR - t + 1; i <= NR; i++) print lines[i]
    }
  '

exit "$STATUS"
