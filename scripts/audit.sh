#!/usr/bin/env bash
# Token-cost audit for the AIDLC template.
# Reports word counts across canonical content and tool-specific adapters.

set -euo pipefail

if ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  cd "$ROOT"
else
  cd "$(dirname "$0")/.."
fi

echo "=== AIDLC Template Footprint Audit ==="
echo

# Helper: count words in a glob, suppressing missing-file errors
count() {
  local label="$1"; shift
  local total=0
  for f in "$@"; do
    [[ -f "$f" ]] || continue
    local n
    n=$(wc -w <"$f" | tr -d ' ')
    total=$((total + n))
  done
  printf "  %-40s %6d words\n" "$label" "$total"
  echo "$total"
}

echo "Root entry points"
ROOT_TOTAL=0
for f in AGENTS.md CLAUDE.md; do
  if [[ -f "$f" ]]; then
    n=$(wc -w <"$f" | tr -d ' ')
    printf "  %-40s %6d words\n" "$f" "$n"
    ROOT_TOTAL=$((ROOT_TOTAL + n))
  fi
done
echo "  ----"
printf "  %-40s %6d words\n" "subtotal" "$ROOT_TOTAL"
echo

echo "Canonical (aidlc/)"
AIDLC_TOTAL=0
while IFS= read -r f; do
  n=$(wc -w <"$f" | tr -d ' ')
  AIDLC_TOTAL=$((AIDLC_TOTAL + n))
done < <(find aidlc -name '*.md' -type f 2>/dev/null)
printf "  %-40s %6d words\n" "aidlc/**/*.md" "$AIDLC_TOTAL"
echo

echo "Memory (memory/)"
MEM_TOTAL=0
while IFS= read -r f; do
  n=$(wc -w <"$f" | tr -d ' ')
  MEM_TOTAL=$((MEM_TOTAL + n))
done < <(find memory -name '*.md' -type f 2>/dev/null)
printf "  %-40s %6d words\n" "memory/**/*.md" "$MEM_TOTAL"
echo

echo "Claude adapters (.claude/)"
CLAUDE_TOTAL=0
while IFS= read -r f; do
  n=$(wc -w <"$f" | tr -d ' ')
  CLAUDE_TOTAL=$((CLAUDE_TOTAL + n))
done < <(find .claude -name '*.md' -type f 2>/dev/null)
printf "  %-40s %6d words\n" ".claude/**/*.md" "$CLAUDE_TOTAL"
echo

echo "Cursor adapters (.cursor/)"
CURSOR_TOTAL=0
while IFS= read -r f; do
  n=$(wc -w <"$f" | tr -d ' ')
  CURSOR_TOTAL=$((CURSOR_TOTAL + n))
done < <(find .cursor \( -name '*.md' -o -name '*.mdc' \) -type f 2>/dev/null)
printf "  %-40s %6d words\n" ".cursor/**/*.{md,mdc}" "$CURSOR_TOTAL"
echo

GRAND=$((ROOT_TOTAL + AIDLC_TOTAL + CLAUDE_TOTAL + CURSOR_TOTAL))
echo "===================================="
printf "  %-40s %6d words\n" "GRAND TOTAL" "$GRAND"
echo

# Health checks
WARN=0
if [[ $ROOT_TOTAL -gt 1500 ]]; then
  echo "[WARN] Root entry points are heavy ($ROOT_TOTAL words). Target: <1500."
  WARN=$((WARN+1))
fi
if [[ $AIDLC_TOTAL -gt 8000 ]]; then
  echo "[WARN] Canonical content is heavy ($AIDLC_TOTAL words). Target: <8000."
  WARN=$((WARN+1))
fi
if [[ $WARN -eq 0 ]]; then
  echo "[OK] Footprint within budget."
fi

# Hook count check
if command -v jq >/dev/null 2>&1; then
  echo
  echo "Hook surface"
  for f in .claude/settings.json .codex/hooks.json .cursor/hooks.json; do
    if [[ -f "$f" ]]; then
      count_hooks=$(jq -r '[.hooks // {} | to_entries[] | .value | length] | add // 0' "$f" 2>/dev/null || echo 0)
      printf "  %-40s %6d hooks\n" "$f" "$count_hooks"
    fi
  done
fi
