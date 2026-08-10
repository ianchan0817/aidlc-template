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
# `-e` is required, not stylistic: a pattern starting with `-` (e.g. one
# matching `--env-file`) is otherwise parsed by grep as an option.
whole() { printf '%s' "$cmd" | grep -qE -e "$1"; }

# Secret files. A Bash allow-list cannot protect .env — `python -c "open('.env')"`
# sidesteps any Read() deny rule — so the boundary has to live here.
#
# Match .env only in a file-consuming POSITION, not anywhere in the string.
# Matching anywhere blocks `git commit -m "fix .env handling"`, and a guard that
# blocks committing is a guard people delete — which protects nothing. The
# trade-off is deliberate: an exotic reader outside this list slips through,
# while Read()/Edit() denies and secret scanning still cover that case.
READERS='cat|less|more|head|tail|nl|od|xxd|strings|base64|openssl|source|\.|cp|mv|ln|install|scp|rsync|tar|zip|curl|wget|grep|rg|ack|awk|sed|jq|xargs|dotenv'
INTERP='python3?|node|deno|bun|ruby|perl|php|osascript'
Q='["'"'"']?'
# A path prefix glued to the filename: ./.env, ../.env, /srv/app/.env, ~/.env.
# Everything up to the last separator, with no shell separator or space inside.
PFX='[^;|&[:space:]"'"'"']*'

# --- Per-segment checks (flag/target proximity matters) ----------------------
while IFS= read -r seg; do
  [ -z "$seg" ] && continue
  seg_has() { printf '%s' "$seg" | grep -qE -e "$1"; }

  # Recursive force-delete of a root-anchored path.
  #
  # This used to require the target to BE `/`, `~` or `$HOME` followed by a
  # terminator, which matched four literal spellings and nothing else — so
  # `rm -rf /etc`, `rm -rf ~/Documents` and `sudo rm -rf /var` all exited 0
  # while README claimed root paths were blocked. Match the path SHAPE instead:
  # anything anchored at /, ~ or $HOME is in scope, at any depth.
  #
  # Relative targets stay allowed — `rm -rf build/`, `node_modules`, `./tmp` are
  # ordinary work, and a guard that blocks ordinary work gets deleted, taking the
  # rules that do work with it. Temp roots are exempt for the same reason.
  if seg_has '(^|[[:space:]])rm([[:space:]]|$)' &&
     seg_has '(-[[:alnum:]-]*[rR]|--recursive)' &&
     seg_has '(-[[:alnum:]-]*[fF]|--force)'; then
    while IFS= read -r tgt; do
      [ -z "$tgt" ] && continue
      t=$(printf '%s' "$tgt" | tr -d '"'"'")
      case "$t" in
        /tmp|/tmp/*|/private/tmp|/private/tmp/*|/var/folders/*|/var/tmp/*) continue ;;
      esac
      block "recursive force-delete of a root-anchored path: $t"
    done < <(printf '%s' "$seg" | tr -s '[:space:]' '\n' \
               | grep -E '^["'"'"']?(/|~|\$HOME|\$\{HOME\})' || true)
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

  # Secret files, checked PER SEGMENT for the reason this loop exists. Testing
  # the .env.example exclusion against the whole command let a benign mention
  # disarm the block for a real read on the same line:
  # `cat .env.example && cat .env` exited 0.
  # Strip scaffolding filenames from the segment first, so the exemption applies
  # only to the token that earned it, then look for what is left.
  segx=$(printf '%s' "$seg" | sed -E 's/\.env\.(example|sample|template|dist)[[:alnum:]._-]*//g')
  segx_has() { printf '%s' "$segx" | grep -qE -e "$1"; }
  # `.env` must end the filename — `.environment` is not a secret file — but a
  # path prefix is allowed: `cat ./.env` is what tab-completion produces and the
  # previous form, which demanded whitespace immediately before `.env`, missed
  # every prefixed spelling.
  if segx_has "(^|[[:space:];|&(])($READERS)[[:space:]]+([^;|&]*[[:space:]])?${Q}${PFX}\.env([^[:alnum:]]|$)" ||
     segx_has "[<>][[:space:]]*${Q}${PFX}\.env([^[:alnum:]]|$)" ||
     segx_has "--env-file[[:space:]=]${Q}${PFX}\.env" ||
     segx_has "($INTERP)[[:space:]][^;|&]*(-c|-e|-p)[[:space:]][^;|&]*\.env"; then
    block "reads or copies a .env file — take secrets from your secrets manager, not the shell"
  fi
  # Trailing newline is required: without it `read` returns non-zero on the final
  # (only) segment and the loop body never runs — silently skipping every check.
done < <(printf '%s\n' "$cmd" | tr ';|&' '\n\n\n')

# --- Whole-command checks ----------------------------------------------------
# SQL may legitimately contain ';', so these run against the full string.
whole '(DROP|TRUNCATE)[[:space:]]+(TABLE|DATABASE|SCHEMA)' && block "destructive SQL (DROP/TRUNCATE)"
whole 'DELETE[[:space:]]+FROM[[:space:]]+[[:alnum:]_."]+[[:space:]]*(;|"|$)' && block "unbounded DELETE (no WHERE clause)"

exit 0
