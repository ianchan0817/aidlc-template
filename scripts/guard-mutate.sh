#!/usr/bin/env bash
# Metamorphic corpus for scripts/guard-command.sh.
#
#   scripts/guard-mutate.sh          generate + check; exit 1 on any disagreement
#   scripts/guard-mutate.sh --list   print every generated case and every skip
#
# WHY THIS EXISTS
# scripts/guard-cases.tsv was the guard's only oracle, and every expect-2 row
# spelled its target exactly one way. Negative-testing an enumeration proves the
# enumerated members work and says NOTHING about the complement — and every
# bypass this guard has shipped lived in the complement: `rm -rf /etc` vs
# `rm -rf /`, `cat ./.env` vs `cat .env`, `bash -c "cat .env"` vs `cat .env`.
# So the corpus is no longer written by hand alone: each hand-written row is
# mechanically mutated along the dimensions an attacker (or a tired engineer)
# actually varies, and every mutation carries an EXPECTED verdict:
#
#   must still BLOCK (metamorphic invariance — the danger is unchanged)
#     sudo-prefix env-prefix lead-and lead-semi double-space subshell
#     shell-c flag-split quote-target path-prefix sql-lowercase
#   must still ALLOW (over-fire control — the same text in a DATA position)
#     as-echo as-commit-message as-comment
#
# Mutations that are NOT expected to preserve the verdict are skipped WITH A
# REASON, printed by --list and counted in the summary, never silently dropped.
# The load-bearing example: path-prefix is applied only to a bare secret-file
# operand. Prefixing a root-delete target instead (`rm -rf ./` from `rm -rf /`)
# makes the path RELATIVE, which the guard allows on purpose — `rm -rf build/`
# is ordinary work, and a guard that blocks ordinary work gets deleted.
#
# Expect-0 rows get the invariance mutations too (sudo-prefix, lead-and,
# double-space, quote-target), which is the near-miss half: it proves the new
# position logic did not start over-firing on benign work.

set -uo pipefail
# The generator reconstructs commands with `for t in $cmd`; without noglob a
# target of `/*` would expand against the real filesystem mid-generation.
set -f

if ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then cd "$ROOT"; else cd "$(dirname "$0")/.."; fi

CASES=scripts/guard-cases.tsv
GUARD=scripts/guard-command.sh
LIST=0
[ "${1:-}" = "--list" ] && LIST=1

[ -r "$CASES" ] || { echo "guard-mutate.sh: cannot read $CASES" >&2; exit 1; }
[ -r "$GUARD" ] || { echo "guard-mutate.sh: cannot read $GUARD" >&2; exit 1; }

TMPD=$(mktemp -d) || exit 1
trap 'rm -rf "$TMPD"' EXIT
GEN=$TMPD/cmds; MAP=$TMPD/map; SKIP=$TMPD/skip
: >"$GEN"; : >"$MAP"; : >"$SKIP"

emit() { # want, mutation, origin, mutated-command
  printf '%s\n' "$4" >>"$GEN"
  printf '%s\t%s\t%s\n' "$1" "$2" "$3" >>"$MAP"
}
skip() { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >>"$SKIP"; }

# Pick a quote style that can wrap the case without escaping. A case holding
# both quote styles, or a substitution that would EXECUTE inside double quotes,
# is skipped: wrapping it would change what the mutation means.
WRAP_OK=0; WRAP_Q=''
wrapped() {
  case $1 in
    *\'*)
      case $1 in
        *\"*|*'$('*|*'`'*) WRAP_OK=0; WRAP_Q='' ;;
        *) WRAP_OK=1; WRAP_Q='"' ;;
      esac ;;
    *) WRAP_OK=1; WRAP_Q="'" ;;
  esac
}

ROWS=0
while IFS=$'\t' read -r want cmd; do
  [ -z "${want:-}" ] && continue
  [ -z "${cmd:-}" ] && continue
  ROWS=$((ROWS + 1))

  # A row may encode newlines as the two characters \n — the corpus is
  # line-based and a heredoc is not. Every mutation below rewrites the command as
  # a single line (wrapping, prefixing, re-spacing, re-casing), and all of those
  # change what a heredoc MEANS: `sudo cat <<'EOF'` moves the body, and
  # `${cmd// /  }` re-spaces a delimiter line so it no longer terminates. Skip
  # the row rather than generate cases whose expected verdict is a guess.
  case $cmd in
    *'\n'*) skip "$want" heredoc-multiline "row spans lines; every mutation here is single-line and would change its meaning: $cmd"
            continue ;;
  esac

  # --- invariance: a wrapper, a prefix or extra whitespace changes nothing ----
  case $cmd in
    sudo\ *) skip "$want" sudo-prefix "already sudo-prefixed: $cmd" ;;
    *) emit "$want" sudo-prefix "$cmd" "sudo $cmd" ;;
  esac
  emit "$want" lead-and "$cmd" "ls && $cmd"
  emit "$want" double-space "$cmd" "${cmd// /  }"

  # --- quote the trailing operand -------------------------------------------
  case $cmd in
    *\"*|*\'*) skip "$want" quote-target "case already contains quotes: $cmd" ;;
    *)
      last=${cmd##* }; head=${cmd% *}
      case $last in
        -*) skip "$want" quote-target "trailing operand is a flag, not a path: $cmd" ;;
        *[/.~]*|\$HOME*)
          emit "$want" quote-target-dq "$cmd" "$head \"$last\""
          emit "$want" quote-target-sq "$cmd" "$head '$last'" ;;
        *) skip "$want" quote-target "trailing operand is not path-shaped: $cmd" ;;
      esac ;;
  esac

  if [ "$want" != 2 ]; then continue; fi

  emit 2 env-prefix "$cmd" "GUARD_PROBE=1 $cmd"
  emit 2 lead-semi "$cmd" "ls; $cmd"
  emit 2 subshell "$cmd" "( $cmd )"

  # --- combined short flags split apart -------------------------------------
  # Bounded at four letters ON PURPOSE. `-rf`, `-xfd`, `-af` and curl's `-fsSL`
  # are getopt-style groups where splitting is exactly equivalent. A longer
  # single-dash token is a LONG option in Terraform/Go style (`-destroy`), and
  # splitting it into `-d -e -s ...` changes what the command does — so the
  # mutation's "must still block" invariant would not hold, and asserting it
  # would be asserting a falsehood. This is an exclusion, not a weakening: it
  # drops an invalid mutation, never a valid one.
  split=''; found=0
  for t in $cmd; do
    if [ "$found" = 0 ] && [[ $t =~ ^-[A-Za-z][A-Za-z]{1,3}$ ]]; then
      found=1; i=1
      while [ "$i" -lt "${#t}" ]; do split="$split -${t:i:1}"; i=$((i + 1)); done
    else
      split="$split $t"
    fi
  done
  if [ "$found" = 1 ]; then
    emit 2 flag-split "$cmd" "${split# }"
  else
    skip 2 flag-split "no getopt-style combined short-flag group (a 5+ letter single-dash token is a long option; splitting it would change the command): $cmd"
  fi

  # --- a path prefix in front of a bare secret-file operand ------------------
  pfx=0
  for t in $cmd; do
    case $t in */*) continue ;; esac
    case $t in
      .env|.env.*|id_rsa|id_dsa|id_ecdsa|id_ed25519|*.pem|*.key|*.p12|*.pfx)
        for p in ./ ../ /srv/app/; do emit 2 path-prefix "$cmd" "${cmd/$t/$p$t}"; done
        pfx=1; break ;;
    esac
  done
  [ "$pfx" = 0 ] && skip 2 path-prefix \
    "no bare secret-file operand. NOT applied to a root-anchored delete: prefixing / with ./ makes the target relative, which the guard allows by design: $cmd"

  # --- SQL keywords are case-insensitive in every engine ---------------------
  case $cmd in
    *DROP*|*TRUNCATE*|*DELETE*)
      lc=${cmd//DROP/drop}; lc=${lc//TRUNCATE/truncate}; lc=${lc//DELETE/delete}
      lc=${lc//FROM/from}; lc=${lc//TABLE/table}; lc=${lc//DATABASE/database}
      lc=${lc//SCHEMA/schema}
      emit 2 sql-lowercase "$cmd" "$lc" ;;
    *) skip 2 sql-lowercase "no SQL keyword to re-case: $cmd" ;;
  esac

  # --- wrapped in an interpreter (block) vs in a data position (allow) ------
  wrapped "$cmd"
  if [ "$WRAP_OK" = 1 ]; then
    emit 2 shell-c "$cmd" "bash -c $WRAP_Q$cmd$WRAP_Q"
    emit 0 as-echo "$cmd" "echo $WRAP_Q$cmd$WRAP_Q"
    emit 0 as-commit-message "$cmd" "git commit -m $WRAP_Q$cmd$WRAP_Q"
  else
    skip 2 shell-c "case holds both quote styles or a substitution; wrapping needs escaping: $cmd"
    skip 0 as-echo "case holds both quote styles or a substitution; wrapping needs escaping: $cmd"
    skip 0 as-commit-message "case holds both quote styles or a substitution; wrapping needs escaping: $cmd"
  fi
  emit 0 as-comment "$cmd" "ls # $cmd"
done <"$CASES"

N=$(grep -c '' <"$GEN")
NSKIP=$(grep -c '' <"$SKIP")

if [ "$LIST" = 1 ]; then
  paste "$MAP" "$GEN" | while IFS=$'\t' read -r want mut origin mcmd; do
    printf 'case\t%s\t%s\t%s\n' "$want" "$mut" "$mcmd"
  done
  while IFS=$'\t' read -r want mut reason; do
    printf 'skip\t%s\t%s\t%s\n' "$want" "$mut" "$reason"
  done <"$SKIP"
fi

bash "$GUARD" --batch "$GEN" | cut -f1 >"$TMPD/got"
paste "$MAP" "$TMPD/got" "$GEN" >"$TMPD/joined"

BAD=0
while IFS=$'\t' read -r want mut origin got mcmd; do
  [ "$want" = "$got" ] && continue
  BAD=$((BAD + 1))
  printf '         [%s] want exit %s, got %s\n           mutated: %s\n           from:    %s\n' \
    "$mut" "$want" "$got" "$mcmd" "$origin"
done <"$TMPD/joined"

if [ "$BAD" -gt 0 ]; then
  printf '         %d of %d generated cases disagree with the guard\n' "$BAD" "$N"
  exit 1
fi
printf 'metamorphic guard corpus (%d cases generated from %d rows, %d mutations skipped with reason)\n' \
  "$N" "$ROWS" "$NSKIP"
