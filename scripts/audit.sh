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

# Two modes, decided by one marker file.
#   aidlc/.template present  → this IS the template repo. Maintainer-only sensors
#                              run: word budgets, three-tool parity, README mobile
#                              render, upstream-URL check, repo-hygiene file list.
#   aidlc/.template absent   → an adopted copy. Those five measure the template's
#                              own shape and say nothing about the adopter's
#                              project, so they are skipped; the adopter arm runs
#                              instead (declaration, backlog, init.sh, workflows).
# Universal sensors — JSON validity, broken refs, guard self-test, bash -n, agent
# frontmatter, secrets/.gitignore, model-agnostic, no ../ chains, anti-explosion —
# run in BOTH modes. Deleting the marker is adoption, not an opt-out of safety.
if [[ -f aidlc/.template ]]; then
  TEMPLATE=1
  MODE="template (aidlc/.template present)"
else
  TEMPLATE=0
  MODE="adopter (aidlc/.template absent)"
fi

echo "=== AIDLC Audit — mode: $MODE ==="
echo

# ---------------------------------------------------------------------------
# TEMPLATE-ONLY: word budgets. The caps describe this template's own footprint;
# an adopter's memory/ and docs/ legitimately grow past them.
# Body deliberately left unindented so the budget history stays diff-readable.
# ---------------------------------------------------------------------------
if [[ $TEMPLATE -eq 1 ]]; then

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

# `find` on a missing directory exits 1, and under `set -euo pipefail` that aborts
# the whole run in a command substitution — silently, with zero checks reported.
# Deleting the tool dirs you do not use is step 1 of adoption (README), so the
# unguarded form made the audit die on the most common adopter action.
words_in() {
  { find "$@" -type f 2>/dev/null || true; } | sum_words
}

# Split the canonical tree by how it actually reaches a context window:
#   methodology — roles, rules, phases, common: loaded on demand while working
#   examples    — fill-in artifact templates, read only when producing that
#                 artifact (README: "documentation, not auto-loaded")
# Budgeting them as one number measures the wrong thing.
METHOD_TOTAL=$(words_in aidlc -name '*.md' -not -path 'aidlc/examples/*')
EXAMPLES_TOTAL=$(words_in aidlc/examples -name '*.md')
AIDLC_TOTAL=$((METHOD_TOTAL + EXAMPLES_TOTAL))
MEM_TOTAL=$(words_in memory -name '*.md')
CLAUDE_TOTAL=$(words_in .claude -name '*.md')
CURSOR_TOTAL=$(words_in .cursor \( -name '*.md' -o -name '*.mdc' \))
CODEX_TOTAL=$(words_in .codex -name '*.md')

printf "  %-40s %6d words\n" "aidlc/ methodology (loads on demand)" "$METHOD_TOTAL"
printf "  %-40s %6d words\n" "aidlc/examples/ (artifact templates)" "$EXAMPLES_TOTAL"
printf "  %-40s %6d words\n" "memory/**/*.md (project state)" "$MEM_TOTAL"
printf "  %-40s %6d words\n" ".claude/**/*.md (adapters)" "$CLAUDE_TOTAL"
printf "  %-40s %6d words\n" ".cursor/**/*.{md,mdc} (adapters)" "$CURSOR_TOTAL"
printf "  %-40s %6d words\n" ".codex/**/*.md (adapters)" "$CODEX_TOTAL"
echo "  ===================================="
GRAND=$((ROOT_TOTAL + AIDLC_TOTAL + MEM_TOTAL + CLAUDE_TOTAL + CURSOR_TOTAL + CODEX_TOTAL))
printf "  %-40s %6d words\n" "GRAND TOTAL" "$GRAND"
echo

if [[ $ROOT_TOTAL -gt 1500 ]]; then
  echo "[WARN] Root entry points heavy ($ROOT_TOTAL words). Target: <1500."
  WARN=$((WARN+1))
fi
# Bloat tripwires, not quality metrics. Methodology is the number that matters:
# it scales with phases (14), roles (3), rules (8) and common docs (3), any of
# which an agent may load while working. Examples get a looser cap because only
# one is ever read at a time, when that artifact is being produced.
# These two are FAIL, not WARN. CONTRIBUTING.md states "Exit 0 or it isn't ready"
# and lists the word budgets first, but a WARN exits 0 — so a PR that blew the cap
# merged green and the discipline the methodology rests on was never enforced.
# The budget is only a tripwire if tripping it stops something.
if [[ $METHOD_TOTAL -gt 8000 ]]; then
  echo "[FAIL] Methodology over budget ($METHOD_TOTAL words). Cap: 8000. Displace prose; do not raise the cap."
  FAIL=$((FAIL+1))
fi
if [[ $EXAMPLES_TOTAL -gt 2500 ]]; then
  echo "[FAIL] Artifact templates over budget ($EXAMPLES_TOTAL words). Cap: 2500."
  FAIL=$((FAIL+1))
fi
# Per-file size is the metric that actually affects adherence — an agent reads
# one phase file, not the whole tree. Past ~700 words a file stops being
# skimmable and its later instructions start getting dropped.
while IFS= read -r f; do
  n=$(wc -w <"$f" | tr -d ' ')
  if [[ $n -gt 700 ]]; then
    printf "  [WARN] %s is %d words — split it; long files lose their tail instructions\n" "$f" "$n"
    WARN=$((WARN+1))
  fi
done < <(find aidlc -name '*.md' -type f 2>/dev/null | sort)

else
  echo "  [skip] word budgets — template-only sensor"
fi
echo

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
# shellcheck disable=SC2016  # backticks are the search pattern, not a substitution
while IFS= read -r ref; do
  case "$ref" in
    *'{'*|*'*'*|*'<'*|*NNN*) continue ;;
  esac
  # A doc that describes all three tools names all three tools' files. Once an
  # adopter removes the tools they do not use, those references are intentionally
  # dangling, not broken — otherwise adoption step 1 makes the audit red and the
  # only way back to green is editing the shared docs. Skip refs into an absent
  # tool dir; still check them for every tool that is present.
  case "$ref" in
    .claude/*|.cursor/*|.codex/*)
      [[ -d "${ref%%/*}" ]] || continue
      ;;
    # The mode marker is DELETED at adoption by design, and the docs that
    # explain how to adopt have to be able to name it. Checking it in adopter
    # mode would make documenting the mechanism the thing that breaks it.
    aidlc/.template)
      [[ $TEMPLATE -eq 1 ]] || continue
      ;;
  esac
  case "$ref" in
    aidlc/*|memory/*|docs/*|scripts/*|.claude/*|.cursor/*|.codex/*|AGENTS.md|CLAUDE.md|README.md|init.sh.example|project.yml)
      if [[ "$ref" == */ ]]; then
        [[ -d "$ref" ]] || { printf "  [FAIL] broken dir ref: %s\n" "$ref"; FAIL=$((FAIL+1)); }
      else
        [[ -e "$ref" ]] || { printf "  [FAIL] broken file ref: %s\n" "$ref"; FAIL=$((FAIL+1)); }
      fi
      ;;
  esac
done < <(grep -rhoE '`[A-Za-z0-9_./{}<>*-]+`' --include='*.md' --include='*.mdc' aidlc .claude .cursor .codex AGENTS.md CLAUDE.md README.md SECURITY.md CONTRIBUTING.md docs 2>/dev/null | tr -d '`' | sort -u)
echo "  [ok]   internal reference check complete"

# 2b. Adapter loadability: a pointer the tool never reads is worse than no pointer.
#     Claude Code, Cursor, and Codex all require skills/<name>/SKILL.md — a flat
#     skills/<name>.md is silently ignored, so the slash command never exists.
SKILL_REF=""
SKILL_FAIL=0
# Codex discovers skills at `.agents/skills`, NOT `.codex/skills` — verified
# 2026-08-10 at https://learn.chatgpt.com/docs/build-skills. This repo shipped 14
# SKILL.md files under `.codex/skills` and this sensor printed [ok], so every
# phase command was dead in Codex while CI was green. Assert the documented path.
for tool in .claude .cursor .agents; do
  [[ -d "$tool/skills" ]] || continue
  while IFS= read -r stray; do
    printf "  [FAIL] flat skill file (needs %s/skills/<name>/SKILL.md): %s\n" "$tool" "$stray"
    FAIL=$((FAIL+1)); SKILL_FAIL=$((SKILL_FAIL+1))
  done < <(find "$tool/skills" -maxdepth 1 -name '*.md' -type f 2>/dev/null)

  names=""
  while IFS= read -r d; do
    name=$(basename "$d")
    if [[ ! -f "$d/SKILL.md" ]]; then
      printf "  [FAIL] skill dir without SKILL.md: %s\n" "$d"
      FAIL=$((FAIL+1)); SKILL_FAIL=$((SKILL_FAIL+1))
      continue
    fi
    for field in name description; do
      grep -qE "^${field}:" "$d/SKILL.md" || {
        printf "  [FAIL] %s/SKILL.md missing required '%s:' frontmatter\n" "$d" "$field"
        FAIL=$((FAIL+1)); SKILL_FAIL=$((SKILL_FAIL+1))
      }
    done
    names="$names $name"
  done < <(find "$tool/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

  # Identical skill SETS across tools is three-tool parity — a template-only
  # invariant. An adopter using two tools with different command sets is making
  # a choice, not a mistake. The shape checks above stay universal: a flat
  # skills/<name>.md is silently ignored by every tool, in every repo.
  [[ $TEMPLATE -eq 1 ]] || continue
  set_now=$(echo "$names" | tr ' ' '\n' | grep -v '^$' | sort | tr '\n' ' ')
  if [[ -z "$SKILL_REF" ]]; then
    SKILL_REF="$set_now"
  elif [[ "$set_now" != "$SKILL_REF" ]]; then
    printf "  [FAIL] skill set drift in %s\n         has:      %s\n         expected: %s\n" "$tool" "$set_now" "$SKILL_REF"
    FAIL=$((FAIL+1)); SKILL_FAIL=$((SKILL_FAIL+1))
  fi
done
if [[ $SKILL_FAIL -eq 0 ]]; then
  echo "  [ok]   skills load as <tool>/skills/<name>/SKILL.md, identical set per tool"
fi

# 2b-2. A manual-only skill must be manual-only ON EVERY TOOL. `/ship` pushes and
#       opens PRs, and `disable-model-invocation: true` is a Claude Code field —
#       Codex accepts only `name` and `description` in SKILL.md and ignores the
#       rest silently, so the model could invoke /ship on Codex unasked. Codex's
#       mechanism is a sibling `agents/openai.yaml` with
#       `policy: allow_implicit_invocation: false` (verified 2026-08-11,
#       https://learn.chatgpt.com/docs/build-skills). Assert the pair: a skill
#       marked manual for one tool must be marked manual for the other.
MANUAL_FAIL=0
if [[ -d .agents/skills ]]; then
  while IFS= read -r sk; do
    [[ -z $sk ]] && continue
    name=$(basename "$(dirname "$sk")")
    pol="$(dirname "$sk")/agents/openai.yaml"
    if [[ ! -f $pol ]]; then
      printf "  [FAIL] .agents/skills/%s is manual-only elsewhere but has no agents/openai.yaml — Codex would invoke it implicitly\n" "$name"
      FAIL=$((FAIL+1)); MANUAL_FAIL=$((MANUAL_FAIL+1))
    elif ! grep -qE '^[[:space:]]*allow_implicit_invocation:[[:space:]]*false' "$pol"; then
      printf "  [FAIL] %s does not set allow_implicit_invocation: false\n" "$pol"
      FAIL=$((FAIL+1)); MANUAL_FAIL=$((MANUAL_FAIL+1))
    fi
  done < <(grep -rl 'disable-model-invocation:[[:space:]]*true' .agents/skills 2>/dev/null || true)
  [[ $MANUAL_FAIL -eq 0 ]] && echo "  [ok]   manual-only skills are manual on Codex too (agents/openai.yaml policy)"
fi

# 2b-3. A SessionStart hook that fires only on a fresh start misses the sessions
#       that need bearings most — resumed, cleared and compacted ones, where the
#       context is stale or was just discarded. Codex documents the source set as
#       startup|resume|clear|compact and treats `matcher` as a regex (verified
#       2026-08-11, https://learn.chatgpt.com/docs/hooks); ours matched only
#       "startup" for months.
if [[ -f .codex/hooks.json ]] && command -v jq >/dev/null 2>&1; then
  narrow=$(jq -r '[.hooks.SessionStart[]?.matcher // ""] | map(select(. == "startup")) | length' .codex/hooks.json 2>/dev/null || echo 0)
  if [[ "${narrow:-0}" -gt 0 ]]; then
    printf "  [FAIL] .codex/hooks.json SessionStart matches only \"startup\" — no bearings on resume, clear or compact\n"
    FAIL=$((FAIL+1))
  else
    echo "  [ok]   SessionStart fires on resumed and compacted sessions, not only fresh starts"
  fi
fi

# 2c. Subagent frontmatter: `name` and `description` are required by Claude Code
#     and Cursor. Without `name` the agent silently fails to register.
for f in .claude/agents/*.md .cursor/agents/*.md; do
  [[ -f "$f" ]] || continue
  for field in name description; do
    grep -qE "^${field}:" "$f" || {
      printf "  [FAIL] %s missing required '%s:' frontmatter\n" "$f" "$field"
      FAIL=$((FAIL+1))
    }
  done
done
echo "  [ok]   subagent frontmatter check complete"

# 2c2. The reviewer holds the only exclusive write duty in the harness: flipping
#      `passes: true` and stamping `verified_sha` in memory/feature-list.json,
#      plus logging findings to memory/progress.md. A read-only reviewer makes
#      sign-off fail silently, or pushes the flip onto whoever wrote the code —
#      breaching the AGENTS.md non-negotiable.
#      Assert the capability POSITIVELY on both tools. Checking only for the
#      literal `readonly: true` passes when the key is deleted outright, and
#      says nothing about Claude's `tools:` list — both are silent regressions.
WRITE_FAIL=0
if [[ -f .cursor/agents/reviewer.md ]]; then
  grep -qE '^readonly:[[:space:]]*false' .cursor/agents/reviewer.md || {
    printf "  [FAIL] .cursor/agents/reviewer.md must declare 'readonly: false' — reviewer writes passes/verified_sha\n"
    FAIL=$((FAIL+1)); WRITE_FAIL=$((WRITE_FAIL+1))
  }
fi
# `tools:` is a comma-separated list, so the match must be delimiter-anchored.
# A bare `grep -q Write` is satisfied by `TodoWrite` — the arm then passes even
# with `Write` deleted, which is exactly the regression it exists to catch.
has_tool() { grep -m1 -E '^tools:' "$1" | grep -qE "(^|[,:[:space:]])$2([,[:space:]]|\$)"; }
if [[ -f .claude/agents/reviewer.md ]]; then
  for t in Write Edit; do
    has_tool .claude/agents/reviewer.md "$t" || {
      printf "  [FAIL] .claude/agents/reviewer.md tools: lacks %s — reviewer cannot record its verdict\n" "$t"
      FAIL=$((FAIL+1)); WRITE_FAIL=$((WRITE_FAIL+1))
    }
  done
fi
# The inverse invariant: manager decides but never writes, so a manager that
# gains write capability has quietly taken on the reviewer's recording duty.
if [[ -f .cursor/agents/manager.md ]] && ! grep -qE '^readonly:[[:space:]]*true' .cursor/agents/manager.md; then
  printf "  [FAIL] .cursor/agents/manager.md must stay 'readonly: true' — manager decides, reviewer records\n"
  FAIL=$((FAIL+1)); WRITE_FAIL=$((WRITE_FAIL+1))
fi
if [[ -f .claude/agents/manager.md ]]; then
  for t in Write Edit; do
    ! has_tool .claude/agents/manager.md "$t" || {
      printf "  [FAIL] .claude/agents/manager.md tools: grants %s — manager decides, reviewer records\n" "$t"
      FAIL=$((FAIL+1)); WRITE_FAIL=$((WRITE_FAIL+1))
    }
  done
fi
[[ $WRITE_FAIL -eq 0 ]] && echo "  [ok]   write capability matches role duty (reviewer writes, manager does not)"

# 2c3. Description COVERAGE, not presence. The description is the routing table:
#      it is what the delegating model reads when choosing a role. Presence-only
#      checking is what let all three descriptions drift while staying green,
#      leaving security and infra work with no named destination.
DESC_WARN=0
desc_needs() { # file, keyword regex, human label
  local f="$1" pat="$2" label="$3" desc
  [[ -f "$f" ]] || return 0
  desc=$(grep -m1 -E '^description:' "$f" || true)
  if ! printf '%s' "$desc" | grep -qiE "$pat"; then
    printf "  [WARN] %s description omits %s — that work will not route here\n" "$f" "$label"
    WARN=$((WARN+1)); DESC_WARN=$((DESC_WARN+1))
  fi
}
for d in .claude/agents .cursor/agents; do
  [[ -d "$d" ]] || continue
  desc_needs "$d/engineer.md" 'infra|deploy'    'infra/deploy'
  desc_needs "$d/reviewer.md" 'security'        'security'
  desc_needs "$d/manager.md"  'escalation|risk' 'escalation/risk'
done
[[ $DESC_WARN -eq 0 ]] && echo "  [ok]   adapter descriptions cover infra/deploy, security, escalation/risk"

# 2d. Rule parity: every canonical rule needs a pointer in each tool's native format.
#     Parity is only meaningful for tools this repo actually adapts. Adoption step 1
#     is deleting the tool dirs you do not use, so an absent .cursor/ is a choice,
#     not a defect — parity is checked per present tool, never for an absent one.
if [[ $TEMPLATE -eq 1 ]]; then
for c in aidlc/rules/*.md; do
  [[ -f "$c" ]] || continue
  base=$(basename "$c" .md)
  [[ ! -d .claude/rules ]] || [[ -f ".claude/rules/$base.md" ]] || { printf "  [FAIL] no Claude rule pointer for %s\n" "$c"; FAIL=$((FAIL+1)); }
  [[ ! -d .cursor/rules ]] || [[ -f ".cursor/rules/$base.mdc" ]] || { printf "  [FAIL] no Cursor rule pointer for %s\n" "$c"; FAIL=$((FAIL+1)); }
done
echo "  [ok]   rule adapter parity check complete"

# 2d2. SINGLE SOURCE OF TRUTH: an adapter POINTS at canonical prose, it never
#      restates it. Parity above proves a pointer EXISTS; it says nothing about
#      whether the body is a pointer or a copy, so a pasted rule body passed.
#      Two arms, both DERIVED rather than enumerated:
#        (a) every adapter body names the canonical file it defers to;
#        (b) no adapter body repeats a long run of prose from that file.
#      The canonical target is read from the adapter itself, so this needs no
#      table of adapter->source pairs to keep in sync.
#      Threshold is 8+ words: shorter overlaps are ordinary shared vocabulary
#      ("Apply rules in"), and a copied sentence is always longer. Honest limit:
#      this catches copy-paste, not paraphrase. Paraphrase is a review concern.
SOT_FAIL=0
norm() { # collapse whitespace, drop list/heading markers, lowercase
  sed -E 's/^[[:space:]]*[-*0-9.]+[[:space:]]*//; s/^#+[[:space:]]*//' \
    | tr -s '[:space:]' ' ' | tr '[:upper:]' '[:lower:]'
}
body() { # adapter body = everything after the closing frontmatter fence
  awk 'BEGIN{f=0;n=0} /^---[[:space:]]*$/{n++; if(n<=2){f=(n==2);next}} n>=2{print}' "$1"
}
for a in .claude/agents/*.md .cursor/agents/*.md .claude/rules/*.md .cursor/rules/*.mdc; do
  [[ -f "$a" ]] || continue
  src=$(grep -oE 'aidlc/(agents|rules|common|construction|inception|operations)/[a-z-]+\.md|project\.yml' "$a" | head -1 || true)
  if [[ -z "$src" ]]; then
    printf "  [FAIL] %s names no canonical source — an adapter must defer, not define\n" "$a"
    FAIL=$((FAIL+1)); SOT_FAIL=$((SOT_FAIL+1)); continue
  fi
  [[ -f "$src" ]] || continue          # broken-ref arm above already reports this
  [[ "$src" == *.yml ]] && continue    # a declaration has no prose to duplicate
  CANON=$(norm <"$src")
  while IFS= read -r line; do
    [[ $(printf '%s' "$line" | wc -w) -ge 8 ]] || continue
    if printf '%s' "$CANON" | grep -qF -- "$line"; then
      printf "  [FAIL] %s duplicates canonical prose from %s — point at it instead:\n         \"%s\"\n" \
        "$a" "$src" "$(printf '%s' "$line" | cut -c1-70)"
      FAIL=$((FAIL+1)); SOT_FAIL=$((SOT_FAIL+1))
      break
    fi
  done < <(body "$a" | norm | tr '.' '\n' | sed -E 's/^ +| +$//g' | grep -v '^$')
done
[[ $SOT_FAIL -eq 0 ]] && echo "  [ok]   every adapter names a canonical source and repeats no 8-word run of its prose"
else
  echo "  [skip] rule adapter parity — template-only sensor"
fi

# 2e. Rule ATTACH PATH: a rule with neither alwaysApply:true nor a usable glob
#     never fires. Cursor splits `globs` on commas, so brace expansion
#     (`*.{ts,tsx}`) shreds into invalid fragments and matches nothing —
#     three rules shipped dead this way before this check existed.
ATTACH_FAIL=0
for f in .cursor/rules/*.mdc; do
  [[ -f "$f" ]] || continue
  globs_line=$(grep -m1 -E '^globs:' "$f" || true)
  always=$(grep -m1 -E '^alwaysApply:[[:space:]]*true' "$f" || true)
  globs_val=${globs_line#globs:}
  globs_val=$(printf '%s' "$globs_val" | tr -d ' "')
  if [[ "$globs_line" == *'{'* || "$globs_line" == *'}'* ]]; then
    printf "  [FAIL] %s: brace expansion in globs — Cursor splits on commas, so this matches nothing\n" "$f"
    FAIL=$((FAIL+1)); ATTACH_FAIL=$((ATTACH_FAIL+1))
  fi
  if [[ -z "$always" && -z "$globs_val" ]]; then
    printf "  [FAIL] %s: no alwaysApply:true and no globs — rule can never attach\n" "$f"
    FAIL=$((FAIL+1)); ATTACH_FAIL=$((ATTACH_FAIL+1))
  fi
done
for f in .claude/rules/*.md; do
  [[ -f "$f" ]] || continue
  # Claude rules without `paths:` load unconditionally, which is valid — only an
  # empty `paths:` block is a dead rule.
  if grep -qE '^paths:[[:space:]]*$' "$f" && ! grep -qE '^[[:space:]]+- ' "$f"; then
    printf "  [FAIL] %s: empty paths: block — rule can never attach\n" "$f"
    FAIL=$((FAIL+1)); ATTACH_FAIL=$((ATTACH_FAIL+1))
  fi
done
[[ $ATTACH_FAIL -eq 0 ]] && echo "  [ok]   every rule has a working attach path (globs / alwaysApply / paths)"

# 2e2b. The UNCONDITIONAL set is per-session cost, so it is a budget, not a
#       detail. An unscoped pointer also forces a read of its canonical body on
#       every session. This drifted silently once: four rules loaded
#       unconditionally while CLAUDE.md documented one, costing ~745 tokens a
#       session in reads nobody asked for. Assert the exact set, not a count —
#       a count passes when one rule is swapped for another.
UNCOND_EXPECT="project security"
if [[ -d .claude/rules ]]; then
  got=""
  for f in .claude/rules/*.md; do
    [[ -f "$f" ]] || continue
    grep -qE '^paths:' "$f" || got="$got $(basename "$f" .md)"
  done
  got=$(printf '%s' "$got" | tr ' ' '\n' | grep -v '^$' | sort | tr '\n' ' ' | sed 's/ $//')
  want=$(printf '%s' "$UNCOND_EXPECT" | tr ' ' '\n' | sort | tr '\n' ' ' | sed 's/ $//')
  if [[ "$got" != "$want" ]]; then
    printf "  [FAIL] Claude unconditional rules are '%s', expected '%s' — every unscoped rule is paid for on every session\n" "$got" "$want"
    FAIL=$((FAIL+1))
  else
    printf "  [ok]   exactly the intended rules load unconditionally on Claude (%s)\n" "$want"
  fi
fi
if [[ -d .cursor/rules ]]; then
  cgot=""
  for f in .cursor/rules/*.mdc; do
    [[ -f "$f" ]] || continue
    grep -qE '^alwaysApply:[[:space:]]*true' "$f" && cgot="$cgot $(basename "$f" .mdc)"
  done
  cgot=$(printf '%s' "$cgot" | tr ' ' '\n' | grep -v '^$' | sort | tr '\n' ' ' | sed 's/ $//')
  cwant=$(printf '%s' "$UNCOND_EXPECT" | tr ' ' '\n' | sort | tr '\n' ' ' | sed 's/ $//')
  if [[ "$cgot" != "$cwant" ]]; then
    printf "  [FAIL] Cursor alwaysApply rules are '%s', expected '%s'\n" "$cgot" "$cwant"
    FAIL=$((FAIL+1))
  else
    printf "  [ok]   exactly the intended rules set alwaysApply on Cursor (%s)\n" "$cwant"
  fi
fi

# 2e2. Repository hygiene files. A security policy that points at a Report
#      button, or a PR template encoding the gates, only works if it exists.
#      The FILE LIST is template-only: it asserts this template ships its own
#      hygiene set. An adopter has their own SECURITY.md policy, their own CI
#      names, and no obligation to keep ours. The codeql arm below stays
#      universal — an always-red scan trains anyone to ignore a red X.
REPO_FAIL=0
if [[ $TEMPLATE -eq 1 ]]; then
for f in SECURITY.md CONTRIBUTING.md LICENSE docs/repo-setup.md \
         .github/dependabot.yml .github/PULL_REQUEST_TEMPLATE.md \
         .github/ISSUE_TEMPLATE/config.yml \
         .github/workflows/audit.yml .github/workflows/code-quality.yml; do
  [[ -e "$f" ]] || { printf "  [FAIL] missing repository file: %s\n" "$f"; FAIL=$((FAIL+1)); REPO_FAIL=$((REPO_FAIL+1)); }
done
fi
# codeql must stay inactive: an active CodeQL run on a markdown-only repo fails
# every time and trains people to ignore a red X.
# `--error-unmatch` with several pathspecs exits 1 when ANY one is unmatched, so
# the old form condemned a real TypeScript repo for having no .py files. Count
# matches instead: source present is a non-empty list, not an all-pathspecs hit.
SCANNABLE=$(git ls-files -- '*.ts' '*.tsx' '*.js' '*.py' '*.go' '*.rb' '*.rs' '*.java' 2>/dev/null | head -1)
if [[ -f .github/workflows/codeql.yml && -z $SCANNABLE ]]; then
  printf "  [FAIL] codeql.yml is active but the repo has no scannable source — keep it as codeql.yml.example\n"
  FAIL=$((FAIL+1)); REPO_FAIL=$((REPO_FAIL+1))
fi
# Deliberately NOT sensed: "you have source, so activate CodeQL". It fired on this
# repo's single 60-line SARIF converter, and a check that goes yellow when nothing
# is wrong is how a team learns to ignore the colour. That guidance is prose in
# docs/repo-setup.md, not a sensor.
if [[ $REPO_FAIL -eq 0 ]]; then
  if [[ $TEMPLATE -eq 1 ]]; then
    echo "  [ok]   repository hygiene files present (policy, CI, PR/issue templates)"
  else
    echo "  [ok]   codeql inactive-unless-scannable (hygiene file list: template-only, skipped)"
  fi
fi

# 2e3. `.gitignore` is the ONLY thing enforcing the "no .env in commits"
#      non-negotiable locally: the command guard blocks readers of .env but
#      nothing stops `git add .env`. Assert the rule works and that it does not
#      over-match the example file adopters are told to commit.
IGN_FAIL=0
if [[ ! -f .gitignore ]]; then
  printf "  [FAIL] no .gitignore — the 'no secrets in commits' non-negotiable has zero local enforcement\n"
  FAIL=$((FAIL+1)); IGN_FAIL=1
else
  git check-ignore -q .env 2>/dev/null || {
    printf "  [FAIL] .gitignore does not match .env\n"; FAIL=$((FAIL+1)); IGN_FAIL=1; }
  if git check-ignore -q .env.example 2>/dev/null; then
    printf "  [FAIL] .gitignore swallows .env.example — adopters need it committed\n"
    FAIL=$((FAIL+1)); IGN_FAIL=1
  fi
fi
# Committed secrets are the failure this exists to prevent; check the index too.
while IFS= read -r tracked; do
  [[ -z $tracked ]] && continue
  printf "  [FAIL] secret-shaped file is tracked by git: %s\n" "$tracked"
  FAIL=$((FAIL+1)); IGN_FAIL=1
done < <(git ls-files -- '.env' '.env.*' '*.pem' '*.key' '*.p12' 2>/dev/null | grep -vE '\.(example|sample)$' || true)
[[ $IGN_FAIL -eq 0 ]] && echo "  [ok]   .gitignore covers secrets, spares .env.example, no secrets tracked"

# 2e4. Template-author URLs must not survive adoption. A hardcoded advisory link
#      routes an adopter's vulnerability reports to a stranger's repo — a
#      disclosure leak that looks like a working button.
#      Template-only: it names this template's own slug, which is a maintainer
#      fact. An adopted repo that renamed its remote gets no signal from it.
if [[ $TEMPLATE -eq 1 ]]; then
UPSTREAM=$(grep -rlE 'github\.com/[A-Za-z0-9_-]+/aidlc-template' .github 2>/dev/null || true)
if [[ -n $UPSTREAM ]]; then
  printf "  [FAIL] upstream template URL still hardcoded in: %s — replace with OWNER/REPO\n" "$(echo "$UPSTREAM" | tr '\n' ' ')"
  FAIL=$((FAIL+1))
else
  echo "  [ok]   no upstream template URLs in .github/ (adopter reports route to the adopter)"
fi
else
  echo "  [skip] upstream template URL check — template-only sensor"
fi

# 2e5. DECLARATION REACHABILITY. Every surface-conditional gate reads project.yml,
#      and the only thing that puts it in front of a model is an always-on pointer
#      per tool. Nothing measured that: rule parity iterates `aidlc/rules/*.md` and
#      `project` deliberately has no canonical body, so it fell outside the loop.
#      Deleting .claude/rules/project.md, deleting both tool pointers, scoping the
#      Claude rule to `paths: ["**/*.tsx"]` so a Go API never loads it, and
#      stripping project.yml out of AGENTS.md all audited clean.
#      Checked per PRESENT tool only — deleting the tool dirs you do not use is
#      adoption step 1, not a regression.
DECLREACH_FAIL=0
if [[ -d .claude ]]; then
  if [[ ! -f .claude/rules/project.md ]]; then
    printf "  [FAIL] no .claude/rules/project.md — project.yml never reaches a Claude session\n"
    FAIL=$((FAIL+1)); DECLREACH_FAIL=$((DECLREACH_FAIL+1))
  elif grep -qE '^paths:' .claude/rules/project.md; then
    printf "  [FAIL] .claude/rules/project.md carries paths: — a path-scoped declaration is invisible to every file it does not match\n"
    FAIL=$((FAIL+1)); DECLREACH_FAIL=$((DECLREACH_FAIL+1))
  elif ! grep -q 'project\.yml' .claude/rules/project.md; then
    # Loading a rule that never names the declaration routes nowhere. The
    # AGENTS.md arm below already asserts the body; without the same check here
    # an empty shell with correct frontmatter passed as "reachable".
    printf "  [FAIL] .claude/rules/project.md never names project.yml — the rule loads but routes nowhere\n"
    FAIL=$((FAIL+1)); DECLREACH_FAIL=$((DECLREACH_FAIL+1))
  fi
fi
if [[ -d .cursor ]]; then
  if [[ ! -f .cursor/rules/project.mdc ]]; then
    printf "  [FAIL] no .cursor/rules/project.mdc — project.yml never reaches a Cursor session\n"
    FAIL=$((FAIL+1)); DECLREACH_FAIL=$((DECLREACH_FAIL+1))
  elif ! grep -qE '^alwaysApply:[[:space:]]*true' .cursor/rules/project.mdc; then
    printf "  [FAIL] .cursor/rules/project.mdc must set alwaysApply: true — a glob-scoped declaration loads only for matching files\n"
    FAIL=$((FAIL+1)); DECLREACH_FAIL=$((DECLREACH_FAIL+1))
  elif ! grep -q 'project\.yml' .cursor/rules/project.mdc; then
    printf "  [FAIL] .cursor/rules/project.mdc never names project.yml — the rule loads but routes nowhere\n"
    FAIL=$((FAIL+1)); DECLREACH_FAIL=$((DECLREACH_FAIL+1))
  fi
fi
# AGENTS.md is Codex's ONLY path to the declaration (no rules directory) and is
# also the universal entry the other tools import. Gate it on the file, not on
# .codex/: removing .codex does not stop Claude and Cursor reading AGENTS.md, so
# tying this arm to that directory would disable it for the tools still using it.
if [[ -f AGENTS.md ]] && ! grep -q 'project\.yml' AGENTS.md; then
  printf "  [FAIL] AGENTS.md never names project.yml — Codex has no rules dir, so the declaration reaches it from here or nowhere\n"
  FAIL=$((FAIL+1)); DECLREACH_FAIL=$((DECLREACH_FAIL+1))
fi
[[ $DECLREACH_FAIL -eq 0 ]] && echo "  [ok]   project.yml is reachable from every present tool (unscoped Claude rule, alwaysApply Cursor rule, AGENTS.md)"

# 2e6. Actions must be SHA-pinned. `aidlc/rules/reproducibility.md` bans floating
#      versions in production, and a mutable tag is exactly that: `@v4` and `@main`
#      re-point at the owner's discretion, so a compromised upstream tag executes
#      in CI with the workflow's token. Nothing measured this — a live workflow
#      reverted to `actions/checkout@main` audited clean.
#      `.yml.example` is included on purpose: docs/repo-setup.md tells adopters to
#      copy those files, so an unpinned example ships the defect downstream.
#      Anchored at end-of-line so a 7-char short SHA cannot satisfy it by prefix.
PIN_FAIL=0
while IFS= read -r use; do
  [[ -z $use ]] && continue
  ref=${use##*@}
  [[ $ref =~ ^[0-9a-f]{40}$ ]] && continue
  # A local action (./.github/actions/foo) has no upstream ref to pin.
  [[ $use == ./* ]] && continue
  printf "  [FAIL] unpinned action: %s — pin to a 40-char commit SHA; tags and branches are mutable\n" "$use"
  FAIL=$((FAIL+1)); PIN_FAIL=$((PIN_FAIL+1))
done < <(grep -rhoE '^[[:space:]]*(-[[:space:]]+)?uses:[[:space:]]*[^[:space:]#]+' \
           .github/workflows 2>/dev/null | sed -E 's/.*uses:[[:space:]]*//' | sort -u || true)
[[ $PIN_FAIL -eq 0 ]] && echo "  [ok]   every GitHub Action is SHA-pinned (workflows and .example files)"

# 2f. Hook output schemas differ per tool; the wrong key is silently ignored,
#     which turns a hook into a no-op that still reports success.
HOOK_FAIL=0
if [[ -f .cursor/hooks/aidlc-session-start.sh ]]; then
  grep -q 'additional_context' .cursor/hooks/aidlc-session-start.sh || {
    printf "  [FAIL] Cursor sessionStart hook must emit additional_context (agent_message is ignored there)\n"
    FAIL=$((FAIL+1)); HOOK_FAIL=$((HOOK_FAIL+1))
  }
fi
# `reason` is not in Cursor's permission schema — the block lands but the
# explanation is dropped, so the agent retries blindly. Match the escaped form
# too (`\"reason\":`), which is how it appears inside a JSON-embedded shell command.
for f in .cursor/hooks/aidlc-guard.sh .cursor/hooks.json; do
  [[ -f "$f" ]] || continue
  grep -qE '\\*"reason\\*"[[:space:]]*:' "$f" && {
    printf "  [FAIL] %s: Cursor deny payload uses undocumented 'reason' — use user_message/agent_message\n" "$f"
    FAIL=$((FAIL+1)); HOOK_FAIL=$((HOOK_FAIL+1))
  }
done
if [[ -f .codex/config.toml ]]; then
  grep -qE '^[[:space:]]*codex_hooks[[:space:]]*=' .codex/config.toml && {
    printf "  [FAIL] .codex/config.toml uses deprecated 'codex_hooks' alias — canonical key is 'hooks'\n"
    FAIL=$((FAIL+1)); HOOK_FAIL=$((HOOK_FAIL+1))
  }
fi
# Every Bash guard hook must extract the command, not grep the raw payload.
for f in .claude/settings.json .codex/hooks.json; do
  [[ -f "$f" ]] || continue
  if grep -q 'guard-command.sh' "$f"; then
    grep -q 'tool_input.command' "$f" || {
      printf "  [FAIL] %s: guard hook does not extract .tool_input.command (would match the raw JSON payload)\n" "$f"
      FAIL=$((FAIL+1)); HOOK_FAIL=$((HOOK_FAIL+1))
    }
  fi
done
[[ $HOOK_FAIL -eq 0 ]] && echo "  [ok]   hook output schemas match each tool's contract"

# 2g. The shared command guard is a safety sensor — prove it still works.
#     Cases live in a file so the dangerous strings never reach a shell.
if [[ -x scripts/guard-command.sh ]]; then
  GUARD_FAIL=0
  # shellcheck disable=SC2016
  while IFS=$'\t' read -r want cmd; do
    [[ -z "${want:-}" ]] && continue
    set +e; bash scripts/guard-command.sh "$cmd" >/dev/null 2>&1; got=$?; set -e
    if [[ "$got" != "$want" ]]; then
      printf "  [FAIL] guard-command.sh: want exit %s, got %s, for: %s\n" "$want" "$got" "$cmd"
      FAIL=$((FAIL+1)); GUARD_FAIL=$((GUARD_FAIL+1))
    fi
  done < scripts/guard-cases.tsv
  set +e; bash scripts/guard-command.sh >/dev/null 2>&1; noarg=$?; set -e
  if [[ "$noarg" != 2 ]]; then
    printf "  [FAIL] guard-command.sh must fail closed with no argument (got %s)\n" "$noarg"
    FAIL=$((FAIL+1)); GUARD_FAIL=$((GUARD_FAIL+1))
  fi
  [[ $GUARD_FAIL -eq 0 ]] && echo "  [ok]   command guard self-test ($(grep -cv '^$' scripts/guard-cases.tsv) cases + fail-closed)"
fi

# 2g2. The hand-written corpus above is an ENUMERATION, and an enumeration proves
#      only that its members work. Every bypass this guard shipped lived in the
#      complement of one — `rm -rf /etc` vs `rm -rf /`, `cat ./.env` vs `cat .env`,
#      `bash -c "cat .env"` vs `cat .env` — so the corpus is also mutated
#      mechanically (prefixes, quoting, subshells, interpreter wrapping, keyword
#      case) and each mutation carries an expected verdict. Over-firing is checked
#      by the same generator: every blocked case is re-emitted inside `echo`, a
#      commit message and a comment, where it must be ALLOWED.
#      Gated on -f, not -x, and bound to the guard's own presence: if the guard
#      ships without its derived arm the corpus silently reverts to a bare
#      enumeration, which is the failure this whole arm exists to prevent. A
#      dropped executable bit must not be able to switch a sensor off.
if [[ -f scripts/guard-command.sh && ! -f scripts/guard-mutate.sh ]]; then
  printf "  [FAIL] scripts/guard-mutate.sh is missing — the guard corpus would be a bare enumeration again\n"
  FAIL=$((FAIL+1))
elif [[ -f scripts/guard-mutate.sh ]]; then
  set +e; MUT_OUT=$(bash scripts/guard-mutate.sh 2>&1); MUT_RC=$?; set -e
  if [[ $MUT_RC -ne 0 ]]; then
    printf "  [FAIL] metamorphic guard corpus disagrees with scripts/guard-command.sh:\n%s\n" "$MUT_OUT"
    FAIL=$((FAIL+1))
  else
    printf "  [ok]   %s\n" "$(printf '%s' "$MUT_OUT" | tail -1)"
  fi
fi

# 2h. Docs must render on a phone: markdown tables and code blocks do not wrap,
#     so an over-wide row forces horizontal scrolling on mobile GitHub.
#     Template-only: it lints THIS README's prose. An adopter's README is their
#     product's front page, not a template artifact.
if [[ $TEMPLATE -eq 1 ]] && command -v python3 >/dev/null 2>&1 && [[ -f README.md ]]; then
  MOBILE=$(python3 - <<'PY'
import sys
bad=[]
lines=open('README.md',encoding='utf-8').read().split('\n')
inblk=False;mx=0;start=0
for i,l in enumerate(lines,1):
    if l.startswith('```'):
        if not inblk: inblk=True;mx=0;start=i
        else:
            inblk=False
            if mx>80: bad.append(f"code block at line {start} is {mx} chars (max 80)")
        continue
    if inblk: mx=max(mx,len(l)); continue
    if l.startswith('|') and len(l)>90:
        bad.append(f"table row {i} is {len(l)} chars (max 90)")
print('\n'.join(bad))
PY
)
  if [[ -n "$MOBILE" ]]; then
    printf "  [FAIL] README will need horizontal scrolling on mobile:\n"
    printf "         %s\n" "$MOBILE"
    FAIL=$((FAIL+1))
  else
    echo "  [ok]   README renders without horizontal scroll (tables <=90, code <=80)"
  fi
elif [[ $TEMPLATE -eq 0 ]]; then
  echo "  [skip] README mobile render — template-only sensor"
fi

# 3. Always-true invariants: model-agnostic and path-rooted.
#    a) No hardcoded model IDs — `model: inherit` is the only allowed form.
MODEL_HITS=$(grep -rniE 'claude-(sonnet|opus|haiku|fable)|gpt-[45o]|gemini-|glm-|minimax' \
  --include='*.md' --include='*.mdc' --include='*.json' --include='*.toml' \
  aidlc .claude .cursor .codex AGENTS.md CLAUDE.md 2>/dev/null || true)
if [[ -n "$MODEL_HITS" ]]; then
  printf "  [FAIL] hardcoded model ID(s):\n%s\n" "$MODEL_HITS"
  FAIL=$((FAIL+1))
else
  echo "  [ok]   no hardcoded model ID spellings in the tree"
fi

#    a2) The INVERTED form, which is the one that holds. The sweep above only
#        knows the vendor spellings that existed when it was written:
#        `claude-3-5-sonnet-20241022` (legacy Anthropic) and `o3-mini` (other
#        vendor) both audited clean through it. Widening the regex loses that
#        race by construction, so assert the allowed value instead — every
#        `model:` line in an agent adapter must be exactly `inherit`.
MODEL_PIN=0
for f in .claude/agents/*.md .cursor/agents/*.md; do
  [[ -f "$f" ]] || continue
  while IFS= read -r line; do
    v=$(printf '%s' "$line" | sed -e 's/^model:[[:space:]]*//' -e 's/[[:space:]]*$//' \
                                  -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'\$/\1/")
    if [[ "$v" != "inherit" ]]; then
      printf "  [FAIL] %s pins model '%s' — agent adapters must say 'model: inherit'\n" "$f" "$v"
      FAIL=$((FAIL+1)); MODEL_PIN=$((MODEL_PIN+1))
    fi
  done < <(grep -E '^model:' "$f" || true)
done
[[ $MODEL_PIN -eq 0 ]] && echo "  [ok]   every agent adapter model: line is exactly 'inherit'"

#    b) No relative path chains in canonical/adapters (root docs may mention the anti-pattern in prose).
REL_HITS=$(grep -rn '\.\./' \
  --include='*.md' --include='*.mdc' --include='*.json' --include='*.toml' \
  aidlc .claude .cursor .codex 2>/dev/null || true)
if [[ -n "$REL_HITS" ]]; then
  printf "  [FAIL] relative path chain(s) — use repo-rooted paths:\n%s\n" "$REL_HITS"
  FAIL=$((FAIL+1))
else
  echo "  [ok]   no ../ path chains (repo-rooted only)"
fi

#    d) Anti-explosion. The template must serve a Go API, an RN app and a Next.js
#       site from ONE methodology tree, so a gate may never assume a surface. The
#       shape checked is exact: a surface token written as an identifier (in
#       backticks) inside aidlc/ methodology. Prose uses of the same English words
#       ("never batch to session end") are untouched because they are not
#       backticked — matching bare words made this fire on 6 innocent lines.
#       A backticked token is allowed only on a line that also cites the
#       declaration (`project.yml`) or says declare/declares/declared, i.e. names
#       the switch. aidlc/examples/ is exempt: filled-in artifacts are where the
#       concrete per-surface spellings belong.
# shellcheck disable=SC2016  # backticks are the pattern, not a command substitution
SURFACE_HITS=$(grep -rnE '`(web|mobile|http-api|grpc|events|cli|batch)`' \
  --include='*.md' aidlc 2>/dev/null \
  | grep -v '^aidlc/examples/' \
  | grep -v 'project\.yml' || true)
if [[ -n "$SURFACE_HITS" ]]; then
  printf "  [FAIL] surface token hardcoded in a gate — name the project.yml field that switches it:\n%s\n" "$SURFACE_HITS"
  FAIL=$((FAIL+1))
else
  echo "  [ok]   no surface hardcoded in an aidlc/ gate (declaration-conditioned only)"
fi

#    c) Shell scripts must parse — a syntax error silently disables a sensor.
# .cursor/hooks/*.sh is the entire Cursor safety boundary and was outside this
# glob — a syntax error there disabled the guard while the audit printed [OK].
for f in scripts/*.sh .cursor/hooks/*.sh init.sh.example init.sh; do
  [[ -f "$f" ]] || continue
  if bash -n "$f" 2>/dev/null; then
    printf "  [ok]   bash -n: %s\n" "$f"
  else
    printf "  [FAIL] shell syntax error: %s\n" "$f"
    FAIL=$((FAIL+1))
  fi
done

# ---------------------------------------------------------------------------
# 3b. ADOPTER ARM — runs only with aidlc/.template removed.
#     Every assertion is filename- or shape-shaped: it reads a path, a file mode,
#     a JSON type, or an exit code. Nothing here judges content quality. Six
#     assertions were considered and REJECTED; CONTRIBUTING.md records each with
#     its reason so they stop being re-proposed at every retro.
# ---------------------------------------------------------------------------
if [[ $TEMPLATE -eq 0 ]]; then
echo
echo "=== Adopter checks ==="

# 3b-0. No template-maintenance state in an adopted copy. This repo is both a
#       template and a project, and the two kinds of state were mixed: an adopter
#       inherited this template's own changelog and session handoffs about fixing
#       its command guard as their project's starting memory. Every one of those
#       reads as project history to the next session, and a model has no way to
#       tell somebody else's narrative from its own.
#       Deleting `.maintainer/` is an adoption step, so its presence here is the
#       tell that the step was skipped.
MAINT_FAIL=0
if [[ -d .maintainer ]]; then
  printf "  [FAIL] .maintainer/ is present in an adopted copy — delete it; it holds the TEMPLATE's own history, not your project's\n"
  FAIL=$((FAIL+1)); MAINT_FAIL=1
fi
# A stale handoff is the same defect one level down: session records describe one
# session's work, so any that predate adoption belong to whoever wrote them.
while IFS= read -r stale; do
  [[ -z $stale ]] && continue
  printf "  [FAIL] %s ships with the template — a handoff describes one session's work and cannot describe yours\n" "$stale"
  FAIL=$((FAIL+1)); MAINT_FAIL=1
done < <(git ls-files 'memory/sessions/*.md' 2>/dev/null | grep -v 'README.md' || true)
[[ $MAINT_FAIL -eq 0 ]] && echo "  [ok]   no template-maintenance state inherited (memory/ describes this project only)"

# 3b-1. The declaration. Every surface-conditional gate reads project.yml. If it
#       is missing or half-filled, those gates evaluate to "not declared" and
#       stop applying — the project ships with the gates quietly switched off,
#       which looks identical to passing them.
DECL_FAIL=0
# One-level YAML scalar reader: `key` or `parent.key`. Comments stripped first.
# Deliberately not a YAML parser — the schema is flat and a parser is optional.
decl_get() {
  awk -v want="$1" '
    { line=$0; sub(/^#.*$/, "", line); sub(/[ \t]+#.*$/, "", line) }
    line ~ /^[A-Za-z_][A-Za-z0-9_]*:/ {
      k=line; sub(/:.*$/, "", k)
      v=line; sub(/^[^:]*:[ \t]*/, "", v)
      parent=k
      if (k==want) { print v; exit }
      next
    }
    line ~ /^[ \t]+[A-Za-z_][A-Za-z0-9_]*:/ {
      k=line; sub(/^[ \t]+/, "", k); sub(/:.*$/, "", k)
      v=line; sub(/^[^:]*:[ \t]*/, "", v)
      if (parent "." k == want) { print v; exit }
    }
  ' project.yml | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
                      -e 's/^"\(.*\)"$/\1/' -e "s/^'\\(.*\\)'\$/\\1/"
}
# `surfaces:` may be written inline (`[web, cli]`) or as a block sequence.
decl_has_block() {
  case "$1" in *.*) return 1 ;; esac
  awk -v want="$1" '
    $0 ~ "^" want ":" { f=1; next }
    f && /^[ \t]+-[ \t]*[^ \t]/ { print "yes"; exit }
    f && /^[A-Za-z]/ { exit }
  ' project.yml | grep -q yes
}
# `surfaces:` is list-valued in either spelling. Emit one token per line so the
# closed-set check can walk both `[web, cli]` and a block sequence.
decl_list() {
  local inline
  inline=$(decl_get "$1")
  case "$inline" in
    '['*']')
      printf '%s' "${inline#[}" | sed 's/]$//' | tr ',' '\n'
      ;;
    '')
      awk -v want="$1" '
        $0 ~ "^" want ":" { f=1; next }
        f && /^[ \t]*-[ \t]*/ { sub(/^[ \t]*-[ \t]*/, ""); sub(/[ \t]*#.*$/, ""); print; next }
        f && /^[A-Za-z]/ { exit }
      ' project.yml
      ;;
    *) printf '%s\n' "$inline" ;;
  esac | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
             -e 's/^"\(.*\)"$/\1/' -e "s/^'\\(.*\\)'\$/\\1/" | grep -v '^$' || true
}
# Declared VALUES, not just presence. `surfaces: [banana]` and
# `release.channel: telepathy` both audited clean, and a misspelled surface is
# not a smaller declaration — it switches the gate off, which is
# indistinguishable from passing it. These three are closed sets the template
# owns (project.yml publishes each one in the comment above the field), so
# checking them is not second-guessing the adopter's judgement.
in_set() { local v=$1; shift; local x; for x in "$@"; do [[ "$v" == "$x" ]] && return 0; done; return 1; }
decl_enum() { # field label, then the allowed values; tokens arrive on stdin
  local field=$1; shift
  local v
  while IFS= read -r v; do
    [[ -z $v ]] && continue
    in_set "$v" "$@" || {
      printf "  [FAIL] project.yml: %s '%s' is not one of: %s\n" "$field" "$v" "$*"
      FAIL=$((FAIL+1)); DECL_FAIL=$((DECL_FAIL+1))
    }
  done
}
decl_nonempty() { # key, why it matters
  local v; v=$(decl_get "$1")
  case "$v" in ""|'""'|"''"|"[]"|"{}")
    decl_has_block "$1" && return 0
    printf "  [FAIL] project.yml: %s is empty — %s\n" "$1" "$2"
    FAIL=$((FAIL+1)); DECL_FAIL=$((DECL_FAIL+1))
    ;;
  esac
}
if [[ ! -f project.yml ]]; then
  printf "  [FAIL] no project.yml — every conditional gate evaluates to 'not declared' and stops applying\n"
  FAIL=$((FAIL+1)); DECL_FAIL=$((DECL_FAIL+1))
else
  if command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1; then
    if ! python3 -c 'import yaml; yaml.safe_load(open("project.yml"))' >/dev/null 2>&1; then
      printf "  [FAIL] project.yml is not valid YAML — no tool can read the declaration\n"
      FAIL=$((FAIL+1)); DECL_FAIL=$((DECL_FAIL+1))
    fi
  else
    echo "  [info] no python3+PyYAML — project.yml read structurally, not parsed"
  fi
  # Placeholder tokens left from the copy. Comments are stripped first: the
  # explanatory header legitimately spells out <angle-bracket> forms.
  LEFTOVER=$(sed 's/#.*//' project.yml \
    | grep -nE 'TODO|FIXME|XXX|CHANGEME|REPLACE_ME|TBD|<[A-Za-z][A-Za-z0-9_ /-]*>' || true)
  if [[ -n "$LEFTOVER" ]]; then
    printf "  [FAIL] project.yml still holds template placeholders:\n"
    printf "         %s\n" "$LEFTOVER"
    FAIL=$((FAIL+1)); DECL_FAIL=$((DECL_FAIL+1))
  fi
  # An UNEDITED declaration is the worst case, not a neutral one: it passes every
  # emptiness and enum check while switching off the gates it is meant to switch
  # on. The template ships `surfaces: [cli]`, so a Next.js SaaS that forgot this
  # file silently disables design.md, design-tokens and ux-guidelines, and
  # `verify.test` resolves to running the template's own audit — a tautology that
  # passes by construction. Same treatment init.sh already gets.
  if [[ -f project.yml.example ]] && cmp -s project.yml project.yml.example; then
    printf "  [FAIL] project.yml is byte-identical to project.yml.example — every gate is switched by the template's shape, not yours\n"
    FAIL=$((FAIL+1)); DECL_FAIL=$((DECL_FAIL+1))
  fi
  decl_nonempty surfaces        'no surface declared means no e2e identity and no UI gates'
  decl_nonempty release.rollback 'ship.md cannot check a rollback lever that was never named'
  decl_nonempty verify.test      'every phase that runs tests has no command to run'
  decl_enum surfaces web mobile http-api grpc events cli batch < <(decl_list surfaces)
  decl_enum release.channel continuous store-staged registry scheduled < <(decl_get release.channel)
  decl_enum release.rollback revert-commit previous-artifact forward-fix-only halt-rollout+kill-switch \
    < <(decl_get release.rollback)

  # DERIVED, not declared: cross-check the declaration against what is actually
  # tracked. The declaration is written once at adoption and never rechecked, so
  # a service that grows a web console keeps `surfaces: [http-api]` and every
  # surface-conditional gate stays wrong — silently, because an undeclared
  # surface "does not apply" by contract. This is the one sensor standing between
  # that contract and a lie.
  #
  # Thresholds are deliberately loose, because a false positive here gets the
  # whole workflow disabled. UI needs 3+ component files, so one vendored fixture
  # or a single landing page does not trip it, and generated/vendored/test trees
  # are excluded. Paraphrase of the same idea: enough evidence that a human would
  # agree the surface exists.
  drift_count() { # extension globs -> count outside vendor/generated/test trees
    git ls-files -- "$@" 2>/dev/null \
      | grep -vE '(^|/)(node_modules|vendor|third_party|testdata|fixtures|__fixtures__|\.next|dist|build)/' \
      | grep -cvE '(^|/)[^/]*\.(test|spec)\.' || true
  }
  SURF_DECL=" $(decl_list surfaces | tr '\n' ' ') "
  UI_N=$(drift_count '*.tsx' '*.jsx' '*.vue' '*.svelte')
  if [[ ${UI_N:-0} -ge 3 && $SURF_DECL != *" web "* && $SURF_DECL != *" mobile "* ]]; then
    printf "  [FAIL] %s tracked UI component files but surfaces declares neither web nor mobile — the UI gates are switched off\n" "$UI_N"
    FAIL=$((FAIL+1)); DECL_FAIL=$((DECL_FAIL+1))
  fi
  PROTO_N=$(drift_count '*.proto')
  if [[ ${PROTO_N:-0} -ge 1 && $SURF_DECL != *" grpc "* ]]; then
    printf "  [FAIL] %s tracked .proto file(s) but surfaces does not declare grpc — the interface gate has no contract axis\n" "$PROTO_N"
    FAIL=$((FAIL+1)); DECL_FAIL=$((DECL_FAIL+1))
  fi
fi
[[ $DECL_FAIL -eq 0 ]] && echo "  [ok]   project.yml declares surfaces/rollback/verify and matches the tracked source"

# 3b-2. The backlog carries the only sign-off record in the harness. A
#       `passes: true` whose verified_sha does not resolve is an unfalsifiable
#       claim — the QA it asserts cannot be re-run against anything.
FL=memory/feature-list.json
FL_FAIL=0
if [[ ! -f $FL ]]; then
  printf "  [FAIL] missing %s — sign-off has nowhere to be recorded\n" "$FL"
  FAIL=$((FAIL+1)); FL_FAIL=$((FL_FAIL+1))
elif ! command -v jq >/dev/null 2>&1; then
  echo "  [info] jq not installed — feature-list checks skipped"
elif ! jq -e '.features | type == "array"' "$FL" >/dev/null 2>&1; then
  printf "  [FAIL] %s: .features is missing or not an array\n" "$FL"
  FAIL=$((FAIL+1)); FL_FAIL=$((FL_FAIL+1))
else
  # Subject set is DERIVED from the manifest's own `records` glob, not assumed to
  # be the inline array. Schema 2 ships `features: []` by design, so reading only
  # the array meant this sensor verified zero records and still reported [ok].
  FEAT_JSONL=$(mktemp "${TMPDIR:-/tmp}/aidlc-feat.XXXXXX")
  jq -c '.features[]?' "$FL" >"$FEAT_JSONL" 2>/dev/null || true
  REC_GLOB=$(jq -r '.records // empty' "$FL" 2>/dev/null || true)
  REC_N=0
  if [[ -n $REC_GLOB ]]; then
    for _r in $REC_GLOB; do
      [[ -f $_r ]] || continue
      if jq -e . "$_r" >/dev/null 2>&1; then
        jq -c '.' "$_r" >>"$FEAT_JSONL"; REC_N=$((REC_N+1))
      else
        printf "  [FAIL] %s is not valid JSON — an unparseable record is an invisible sign-off\n" "$_r"
        FAIL=$((FAIL+1)); FL_FAIL=$((FL_FAIL+1))
      fi
    done
  fi
  # Presence before uniqueness. `[.features[].id // empty]` drops untagged
  # entries BEFORE group_by, so a feature with no id could never collide with
  # anything and the dup check silently skipped it.
  NOID=$(jq -rs '[to_entries[] | select(((.value.id // "") | tostring) == "") | .key] | join(" ")' "$FEAT_JSONL")
  if [[ -n "$NOID" ]]; then
    printf "  [FAIL] %s: feature(s) at index %s have no id — an untagged entry is invisible to the duplicate check and to every sign-off\n" "$FL" "$NOID"
    FAIL=$((FAIL+1)); FL_FAIL=$((FL_FAIL+1))
  fi
  DUPES=$(jq -rs '[.[].id // empty] | group_by(.) | map(select(length>1) | .[0]) | join(" ")' "$FEAT_JSONL")
  if [[ -n "$DUPES" ]]; then
    printf "  [FAIL] %s: duplicate feature id(s): %s\n" "$FL" "$DUPES"
    FAIL=$((FAIL+1)); FL_FAIL=$((FL_FAIL+1))
  fi
  # `git cat-file -e` asks only "is this object here" — true on a shallow clone
  # and after a squash-merge. An ancestry test is the tempting version and it is
  # wrong: see CONTRIBUTING.md, Rejected sensors.
  while IFS=$'\t' read -r id sha; do
    [[ -z "${id:-}" ]] && continue
    if [[ -z "$sha" ]]; then
      printf "  [FAIL] %s: '%s' has passes:true with no verified_sha — sign-off is unverifiable\n" "$FL" "$id"
      FAIL=$((FAIL+1)); FL_FAIL=$((FL_FAIL+1))
    elif [[ ! $sha =~ ^[0-9a-f]{7,40}$ ]]; then
      # A revision EXPRESSION resolves forever, to whatever the tip is today, so
      # the QA it claims can never be re-run against the state that was reviewed.
      # `HEAD`, `main` and `HEAD~0` all satisfied `git cat-file -e`. This is a
      # shape check, not the ancestry check CONTRIBUTING.md rejects.
      printf "  [FAIL] %s: '%s' verified_sha '%s' is a revision expression, not a commit id\n" "$FL" "$id" "$sha"
      FAIL=$((FAIL+1)); FL_FAIL=$((FL_FAIL+1))
    elif ! git cat-file -e "${sha}^{commit}" 2>/dev/null; then
      printf "  [FAIL] %s: '%s' verified_sha %s is not a commit in this repo\n" "$FL" "$id" "$sha"
      FAIL=$((FAIL+1)); FL_FAIL=$((FL_FAIL+1))
    fi
  done < <(jq -r 'select(.passes==true) | [(.id // "?"), (.verified_sha // "")] | @tsv' "$FEAT_JSONL")
  rm -f "$FEAT_JSONL"
fi
if [[ $FL_FAIL -eq 0 ]]; then
  printf "  [ok]   backlog: %s record(s) checked from %s — ids present and unique, every passes:true has a 40-char sha in this repo\n" \
    "${REC_N:-0}" "${REC_GLOB:-inline array}"
fi

# 3b-3. `./init.sh` is session-lifecycle step 5 — the smoke that decides whether
#       this session builds a feature or fixes the baseline. An unedited copy of
#       the example reports green having tested nothing, which is worse than
#       having no smoke at all.
INIT_FAIL=0
if [[ ! -f init.sh ]]; then
  printf "  [FAIL] no init.sh — session bearings have no smoke to run (cp init.sh.example init.sh)\n"
  FAIL=$((FAIL+1)); INIT_FAIL=$((INIT_FAIL+1))
else
  [[ -x init.sh ]] || {
    printf "  [FAIL] init.sh is not executable — ./init.sh in the lifecycle will fail\n"
    FAIL=$((FAIL+1)); INIT_FAIL=$((INIT_FAIL+1)); }
  bash -n init.sh 2>/dev/null || {
    printf "  [FAIL] shell syntax error: init.sh\n"
    FAIL=$((FAIL+1)); INIT_FAIL=$((INIT_FAIL+1)); }
  if [[ -f init.sh.example ]] && cmp -s init.sh init.sh.example; then
    printf "  [FAIL] init.sh is byte-identical to init.sh.example — the smoke step is a placeholder, not a check\n"
    FAIL=$((FAIL+1)); INIT_FAIL=$((INIT_FAIL+1))
  fi
fi
[[ $INIT_FAIL -eq 0 ]] && echo "  [ok]   init.sh present, executable, parses, and edited from the example"

# 3b-4. A workflow with no `permissions:` inherits the repository default, which
#       can be write-all. Least privilege has to be written down per workflow.
#       Presence alone is not the invariant: `permissions: write-all` satisfied
#       the old grep while granting strictly MORE than the default it exists to
#       constrain, and a bare `permissions:` with no scopes underneath is a null
#       value whose effect is not something to guess at. Both are rejected.
#       `permissions: {}` (grant nothing) and `read-all` stay valid.
wf_permissions_defect() {
  awk '
    function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
    { line=$0; sub(/[ \t]*#.*$/, "", line) }
    line ~ /^[ \t]*permissions:/ {
      ind = match(line, /[^ \t]/) - 1
      v = line; sub(/^[ \t]*permissions:[ \t]*/, "", v); v = trim(v)
      if (v == "write-all") { print "grants write-all — broader than the repo default it is meant to narrow"; exit }
      if (v == "") { pend = 1; pind = ind; next }
      pend = 0; next
    }
    pend == 1 {
      if (line ~ /^[ \t]*$/) next
      ind = match(line, /[^ \t]/) - 1
      if (ind > pind && line ~ /:/) { pend = 0; next }
      print "has a bare permissions: with no scopes under it"; exit
    }
    END { if (pend == 1) print "has a bare permissions: with no scopes under it" }
  ' "$1"
}
WF_N=0; WF_FAIL=0
for f in .github/workflows/*.yml .github/workflows/*.yaml; do
  [[ -f "$f" ]] || continue
  WF_N=$((WF_N+1))
  if ! grep -qE '^[[:space:]]*permissions:' "$f"; then
    printf "  [FAIL] %s declares no permissions: — inherits the repo default token scope\n" "$f"
    FAIL=$((FAIL+1)); WF_FAIL=$((WF_FAIL+1))
    continue
  fi
  defect=$(wf_permissions_defect "$f")
  if [[ -n "$defect" ]]; then
    printf "  [FAIL] %s %s\n" "$f" "$defect"
    FAIL=$((FAIL+1)); WF_FAIL=$((WF_FAIL+1))
  fi
done
if [[ $WF_N -eq 0 ]]; then
  echo "  [info] no active workflows to check"
elif [[ $WF_FAIL -eq 0 ]]; then
  printf "  [ok]   all %d workflow(s) declare permissions:\n" "$WF_N"
fi
fi

# 4. Hook surface (count registered hooks per tool)
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
elif [[ $TEMPLATE -eq 1 ]]; then
  echo "[OK] Footprint within budget; structure clean."
else
  echo "[OK] Structure clean; declaration, backlog, init.sh and workflows check out."
fi
