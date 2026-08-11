#!/usr/bin/env bash
# Re-verify every external link in docs/references.md.
#
# Deliberately NOT called by scripts/audit.sh: the audit must pass offline and on
# a runner with no egress, so a network check there would make a green build
# depend on somebody else's uptime. Run this by hand at each harness review, then
# update the verification date at the top of docs/references.md.
#
# Exit 1 only on a link that is genuinely gone (4xx/5xx). Bot-blocked (403) and
# unreachable (timeout, DNS) are reported but do not fail — neither is evidence
# that the page is dead, and a sensor that cries wolf gets ignored.
set -uo pipefail

FILE="${1:-docs/references.md}"
UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'

command -v curl >/dev/null 2>&1 || { echo "[FAIL] curl not found — install curl, or check the links in a browser"; exit 1; }
[[ -f "$FILE" ]] || { echo "[FAIL] $FILE not found — run from the repo root"; exit 1; }

# No mapfile: macOS ships bash 3.2, where it does not exist.
URLS=(); N=0
while IFS= read -r u; do
  URLS+=("$u"); N=$((N+1))
done < <(grep -oE 'https?://[^ )>"`,]+' "$FILE" | sed 's/[.,)]*$//' | sort -u)
if [[ $N -eq 0 ]]; then
  echo "[FAIL] no URLs found in $FILE — the extraction regex or the file changed shape"
  exit 1
fi

echo "=== Link check: $FILE ($N unique URLs) ==="
DEAD=0; BLOCKED=0; UNREACHABLE=0; ALIVE=0

for u in "${URLS[@]}"; do
  code=$(curl -sS -o /dev/null -w '%{http_code}' -L --max-time 25 -A "$UA" "$u" 2>/dev/null || echo 000)
  case "$code" in
    2??|3??) ALIVE=$((ALIVE+1)) ;;
    403)     printf "  [blocked]     %s (403 — bot-blocked, open in a browser)\n" "$u"; BLOCKED=$((BLOCKED+1)) ;;
    429)     printf "  [blocked]     %s (429 — rate-limited, retry later)\n" "$u"; BLOCKED=$((BLOCKED+1)) ;;
    000)     printf "  [unreachable] %s (no response — network, DNS or timeout)\n" "$u"; UNREACHABLE=$((UNREACHABLE+1)) ;;
    *)       printf "  [DEAD]        %s (HTTP %s)\n" "$u" "$code"; DEAD=$((DEAD+1)) ;;
  esac
done

echo
printf "%d alive, %d blocked, %d unreachable, %d dead (of %d)\n" \
  "$ALIVE" "$BLOCKED" "$UNREACHABLE" "$DEAD" "$N"

if [[ $DEAD -gt 0 ]]; then
  echo
  echo "[FAIL] $DEAD dead link(s). Find the new URL and edit the entry — do not"
  echo "       delete it. A deleted entry is a source somebody re-researches from"
  echo "       scratch; a corrected URL keeps the verdict that was already earned."
  exit 1
fi
echo "[OK] no dead links. Update the verification date at the top of $FILE."
