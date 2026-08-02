#!/usr/bin/env bash
# Shared dangerous-command matcher — single source of truth for all three tools.
#
#   scripts/guard-command.sh "<command string>"
#
# Exit 0 = allowed.  Exit 2 = blocked, reason on stderr.
# Exit 2 is what Claude Code, Codex, and Cursor all treat as "deny", so each
# tool's hook only has to extract the command and forward the exit code.
#
# Why one script: this pattern used to be pasted inline into three hook configs
# and they drifted — the Codex copy lost its `jq` extraction and began matching
# the raw JSON payload, blocking benign commands whose cwd contained a match.
# One file, exercised by scripts/audit.sh against scripts/guard-cases.tsv,
# cannot drift.
#
# Fails CLOSED: a missing/empty argument blocks, so an upstream extraction
# failure can never silently disable the guard.
#
# Proximity matters. `rm`'s flags and its target must be checked inside the SAME
# command segment: testing them independently across the whole string means
# `rm -rf ./tmp && ls /etc` trips the root-delete rule because some other part
# of the line contains " /". So segment on shell separators first.

set -uo pipefail

if [ "$#" -lt 1 ] || [ -z "${1:-}" ]; then
  echo "Blocked: command guard could not read the command (missing arg, or jq/payload problem upstream)" >&2
  exit 2
fi

cmd="$1"
block() { echo "Blocked by scripts/guard-command.sh: $1" >&2; exit 2; }
whole() { printf '%s' "$cmd" | grep -qE "$1"; }

# --- Per-segment checks (flag/target proximity matters) ----------------------
while IFS= read -r seg; do
  [ -z "$seg" ] && continue
  seg_has() { printf '%s' "$seg" | grep -qE "$1"; }

  # Recursive force-delete of a root-level path. All four must hold in this segment.
  if seg_has '(^|[[:space:]])rm([[:space:]]|$)' &&
     seg_has '(-[[:alnum:]-]*[rR]|--recursive)' &&
     seg_has '(-[[:alnum:]-]*[fF]|--force)' &&
     seg_has 'rm[[:space:]].*[[:space:]]["'"'"']?(/|~|\$HOME)(["'"'"']|[[:space:]]|\*|$)'; then
    block "recursive force-delete of a root-level path"
  fi

  # Force push. --force-with-lease is the safe form and stays allowed.
  if seg_has '(^|[[:space:]])git[[:space:]]+push([[:space:]]|$)' &&
     seg_has '(--force([[:space:]]|$)|(^|[[:space:]])-f([[:space:]]|$))' &&
     ! seg_has '--force-with-lease'; then
    block "git push --force (prefer --force-with-lease; never on main/master)"
  fi

  seg_has 'chmod[[:space:]]+-R[[:space:]]+777' && block "chmod -R 777"
  seg_has '(^|[[:space:]])git[[:space:]]+reset[[:space:]]+--hard' &&
    block "git reset --hard discards uncommitted work"
  # Trailing newline is required: without it `read` returns non-zero on the final
  # (only) segment and the loop body never runs — silently skipping every check.
done < <(printf '%s\n' "$cmd" | tr ';|&' '\n\n\n')

# --- Whole-command checks ----------------------------------------------------
# SQL may legitimately contain ';', so these run against the full string.
whole '(DROP|TRUNCATE)[[:space:]]+(TABLE|DATABASE|SCHEMA)' && block "destructive SQL (DROP/TRUNCATE)"
whole 'DELETE[[:space:]]+FROM[[:space:]]+[[:alnum:]_."]+[[:space:]]*(;|"|$)' && block "unbounded DELETE (no WHERE clause)"

# Secret files. A Bash allow-list cannot protect .env — `python -c "open('.env')"`
# sidesteps any Read() deny rule — so the boundary has to live here.
# .env.example/.sample/.template/.dist are scaffolding and stay usable; block
# those and people disable the guard on day one.
if whole '(^|[^[:alnum:]_.-])\.env' &&
   ! whole '\.env\.(example|sample|template|dist)([^[:alnum:]]|$)'; then
  block "touches a .env file — read secrets from your secrets manager, not the shell"
fi

exit 0
