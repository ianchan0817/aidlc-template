#!/usr/bin/env bash
# Template health audit: token footprint + structural integrity.
# Run in CI and before releases. Exit non-zero on structural failures.

set -euo pipefail

if ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  cd "$ROOT"
else
  cd "$(dirname "$0")/.."
fi

FAIL=0
WARN=0

echo "=== AIDLC Template Footprint Audit ==="
echo

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

sum_words() {
  local total=0 n
  while IFS= read -r f; do
    n=$(wc -w <"$f" | tr -d ' ')
    total=$((total + n))
  done
  echo "$total"
}

AIDLC_TOTAL=$(find aidlc -name '*.md' -type f 2>/dev/null | sum_words)
MEM_TOTAL=$(find memory -name '*.md' -type f 2>/dev/null | sum_words)
CLAUDE_TOTAL=$(find .claude -name '*.md' -type f 2>/dev/null | sum_words)
CURSOR_TOTAL=$(find .cursor \( -name '*.md' -o -name '*.mdc' \) -type f 2>/dev/null | sum_words)

printf "  %-40s %6d words\n" "aidlc/**/*.md (canonical)" "$AIDLC_TOTAL"
printf "  %-40s %6d words\n" "memory/**/*.md (project state)" "$MEM_TOTAL"
printf "  %-40s %6d words\n" ".claude/**/*.md (adapters)" "$CLAUDE_TOTAL"
printf "  %-40s %6d words\n" ".cursor/**/*.{md,mdc} (adapters)" "$CURSOR_TOTAL"
echo "  ===================================="
GRAND=$((ROOT_TOTAL + AIDLC_TOTAL + MEM_TOTAL + CLAUDE_TOTAL + CURSOR_TOTAL))
printf "  %-40s %6d words\n" "GRAND TOTAL" "$GRAND"
echo

if [[ $ROOT_TOTAL -gt 1500 ]]; then
  echo "[WARN] Root entry points heavy ($ROOT_TOTAL words). Target: <1500."
  WARN=$((WARN+1))
fi
if [[ $AIDLC_TOTAL -gt 8000 ]]; then
  echo "[WARN] Canonical content heavy ($AIDLC_TOTAL words). Target: <8000."
  WARN=$((WARN+1))
fi

echo "=== Structural checks ==="

# 1. JSON validity (hooks are safety sensors — a syntax error silently disables them)
if command -v jq >/dev/null 2>&1; then
  for f in .claude/settings.json .codex/hooks.json .cursor/hooks.json memory/feature-list.json; do
    if [[ -f "$f" ]]; then
      if jq empty "$f" 2>/dev/null; then
        printf "  [ok]   valid JSON: %s\n" "$f"
      else
        printf "  [FAIL] invalid JSON: %s\n" "$f"
        FAIL=$((FAIL+1))
      fi
    fi
  done
else
  echo "  [skip] jq not installed — JSON checks skipped"
fi

# 2. Broken internal references: backtick-quoted repo paths in md files must exist.
#    Only paths rooted at known dirs/files; skip templates ({...}, NNN, *, <).
while IFS= read -r ref; do
  case "$ref" in
    *'{'*|*'*'*|*'<'*|*NNN*) continue ;;
  esac
  case "$ref" in
    aidlc/*|memory/*|docs/*|scripts/*|.claude/*|.cursor/*|.codex/*|AGENTS.md|CLAUDE.md|README.md|init.sh.example)
      if [[ "$ref" == */ ]]; then
        [[ -d "$ref" ]] || { printf "  [FAIL] broken dir ref: %s\n" "$ref"; FAIL=$((FAIL+1)); }
      else
        [[ -e "$ref" ]] || { printf "  [FAIL] broken file ref: %s\n" "$ref"; FAIL=$((FAIL+1)); }
      fi
      ;;
  esac
done < <(grep -rhoE '`[A-Za-z0-9_./{}<>*-]+`' --include='*.md' --include='*.mdc' aidlc .claude .cursor AGENTS.md CLAUDE.md README.md 2>/dev/null | tr -d '`' | sort -u)
echo "  [ok]   internal reference check complete"

# 3. Hook surface (count registered hooks per tool)
if command -v jq >/dev/null 2>&1; then
  for f in .claude/settings.json .codex/hooks.json .cursor/hooks.json; do
    if [[ -f "$f" ]]; then
      count_hooks=$(jq -r '[.hooks // {} | to_entries[] | .value | length] | add // 0' "$f" 2>/dev/null || echo 0)
      printf "  [info] %-30s %2d hooks\n" "$f" "$count_hooks"
    fi
  done
fi

echo
if [[ $FAIL -gt 0 ]]; then
  echo "[FAIL] $FAIL structural failure(s)."
  exit 1
elif [[ $WARN -gt 0 ]]; then
  echo "[WARN] $WARN warning(s); no structural failures."
else
  echo "[OK] Footprint within budget; structure clean."
fi
