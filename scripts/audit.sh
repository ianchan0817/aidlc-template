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

# Split the canonical tree by how it actually reaches a context window:
#   methodology — roles, rules, phases, common: loaded on demand while working
#   examples    — fill-in artifact templates, read only when producing that
#                 artifact (README: "documentation, not auto-loaded")
# Budgeting them as one number measures the wrong thing.
METHOD_TOTAL=$(find aidlc -name '*.md' -type f -not -path 'aidlc/examples/*' 2>/dev/null | sum_words)
EXAMPLES_TOTAL=$(find aidlc/examples -name '*.md' -type f 2>/dev/null | sum_words)
AIDLC_TOTAL=$((METHOD_TOTAL + EXAMPLES_TOTAL))
MEM_TOTAL=$(find memory -name '*.md' -type f 2>/dev/null | sum_words)
CLAUDE_TOTAL=$(find .claude -name '*.md' -type f 2>/dev/null | sum_words)
CURSOR_TOTAL=$(find .cursor \( -name '*.md' -o -name '*.mdc' \) -type f 2>/dev/null | sum_words)
CODEX_TOTAL=$(find .codex -name '*.md' -type f 2>/dev/null | sum_words)

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
if [[ $METHOD_TOTAL -gt 8000 ]]; then
  echo "[WARN] Methodology heavy ($METHOD_TOTAL words). Target: <8000."
  WARN=$((WARN+1))
fi
if [[ $EXAMPLES_TOTAL -gt 2500 ]]; then
  echo "[WARN] Artifact templates heavy ($EXAMPLES_TOTAL words). Target: <2500."
  WARN=$((WARN+1))
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
done < <(grep -rhoE '`[A-Za-z0-9_./{}<>*-]+`' --include='*.md' --include='*.mdc' aidlc .claude .cursor .codex AGENTS.md CLAUDE.md README.md SECURITY.md CONTRIBUTING.md docs 2>/dev/null | tr -d '`' | sort -u)
echo "  [ok]   internal reference check complete"

# 2b. Adapter loadability: a pointer the tool never reads is worse than no pointer.
#     Claude Code, Cursor, and Codex all require skills/<name>/SKILL.md — a flat
#     skills/<name>.md is silently ignored, so the slash command never exists.
SKILL_REF=""
SKILL_FAIL=0
for tool in .claude .cursor .codex; do
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
for c in aidlc/rules/*.md; do
  [[ -f "$c" ]] || continue
  base=$(basename "$c" .md)
  [[ -f ".claude/rules/$base.md" ]] || { printf "  [FAIL] no Claude rule pointer for %s\n" "$c"; FAIL=$((FAIL+1)); }
  [[ -f ".cursor/rules/$base.mdc" ]] || { printf "  [FAIL] no Cursor rule pointer for %s\n" "$c"; FAIL=$((FAIL+1)); }
done
echo "  [ok]   rule adapter parity check complete"

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

# 2e2. Repository hygiene files. A security policy that points at a Report
#      button, or a PR template encoding the gates, only works if it exists.
REPO_FAIL=0
for f in SECURITY.md CONTRIBUTING.md LICENSE docs/repo-setup.md \
         .github/dependabot.yml .github/PULL_REQUEST_TEMPLATE.md \
         .github/ISSUE_TEMPLATE/config.yml \
         .github/workflows/audit.yml .github/workflows/code-quality.yml; do
  [[ -e "$f" ]] || { printf "  [FAIL] missing repository file: %s\n" "$f"; FAIL=$((FAIL+1)); REPO_FAIL=$((REPO_FAIL+1)); }
done
# codeql must stay inactive: an active CodeQL run on a markdown-only repo fails
# every time and trains people to ignore a red X.
if [[ -f .github/workflows/codeql.yml ]] && ! git ls-files --error-unmatch \
     -- '*.ts' '*.tsx' '*.js' '*.py' '*.go' '*.rb' '*.rs' '*.java' >/dev/null 2>&1; then
  printf "  [FAIL] codeql.yml is active but the repo has no scannable source — keep it as codeql.yml.example\n"
  FAIL=$((FAIL+1)); REPO_FAIL=$((REPO_FAIL+1))
fi
[[ $REPO_FAIL -eq 0 ]] && echo "  [ok]   repository hygiene files present (policy, CI, PR/issue templates)"

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

# 2h. Docs must render on a phone: markdown tables and code blocks do not wrap,
#     so an over-wide row forces horizontal scrolling on mobile GitHub.
if command -v python3 >/dev/null 2>&1; then
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
  echo "  [ok]   no hardcoded model IDs (model: inherit only)"
fi

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

#    c) Shell scripts must parse — a syntax error silently disables a sensor.
for f in scripts/*.sh init.sh.example; do
  [[ -f "$f" ]] || continue
  if bash -n "$f" 2>/dev/null; then
    printf "  [ok]   bash -n: %s\n" "$f"
  else
    printf "  [FAIL] shell syntax error: %s\n" "$f"
    FAIL=$((FAIL+1))
  fi
done

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
else
  echo "[OK] Footprint within budget; structure clean."
fi
