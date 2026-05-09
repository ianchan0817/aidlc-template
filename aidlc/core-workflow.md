# Core Workflow — AIDLC

Tool-agnostic methodology in one page. Adopted from AWS Labs AIDLC, adapted for general SWE.

**Session lifecycle:** `aidlc/common/session-lifecycle.md` — get bearings at start, handoff at end. **Feature backlog:** `memory/feature-list.json` (example: `aidlc/examples/feature-list.md`).

## Three phases

```
Inception (WHAT/WHY) → Construction (HOW) → Operations (RUN)
       gate                 gate                gate
```

Every initiative passes through all three. Each phase has a human-approved gate before the next.

### Inception
- `aidlc/inception/spec.md` — define the problem, use cases, RICE, acceptance criteria
- `aidlc/inception/design.md` — UI/component specs, mobile, interaction (when UI applies)

**Gate:** measurable success metric, ≥1 use case with acceptance criteria, explicit out-of-scope.

### Construction
- `aidlc/construction/plan.md` — architecture + task breakdown + **sprint contract** (reviewer-approved verifiable criteria)
- `aidlc/construction/build.md` — incremental TDD; **one feature/slice** aligned with feature-list when used
- `aidlc/construction/test.md` — coverage strategy and enforcement
- `aidlc/construction/eval.md` — **agent/LLM feature** evals (tasks, graders, transcripts) when applicable
- `aidlc/construction/review.md` — pre-merge two-pass code review
- `aidlc/construction/security.md` — STRIDE + OWASP (when auth/data/API touched)
- `aidlc/construction/e2e.md` — end-to-end journey verification (runtime QA vs sprint contract)
- `aidlc/construction/ship.md` — land the branch

**Gate:** all tests pass at 100% coverage; reviewed; E2E signed off; security cleared if applicable; agent eval suite green when the change touches agent behavior.

### Operations
- `aidlc/operations/operate.md` — post-deploy monitoring, incidents, drift, feedback
- `aidlc/operations/retro.md` — retrospective, harness review, agent improvement
- `aidlc/operations/investigate.md` — structured debugging
- `aidlc/operations/daily-report.md` — manager's daily summary

**Gate:** 24h stable signals; every prod incident produces a fix, test, or rule update.

## Roles
See `aidlc/agents/`: `engineer` (build), `reviewer` (quality, security, **runtime QA**, **evals**, E2E), `manager` (orchestrate, **harness review cadence**).

## Harness controls
The repo is the harness. Keep controls explicit and versioned:
- **Guides/feedforward:** `AGENTS.md`, tool adapters, rules, phase files, `init.sh.example`, ADRs
- **State:** `memory/progress.md`, `memory/feature-list.json`, git history
- **Sensors/feedback:** tests, lint/type checks, security scans, E2E, evals, transcripts, hooks, code review

Use deterministic sensors first. For agent or subjective behavior, use calibrated graders and human review. Evaluate the produced outcome against the sprint contract; avoid brittle checks on exact tool-call order unless compliance requires them.

## Always-on rules
Each tool has its own rules directory with format-specific frontmatter:
- Claude Code → `.claude/rules/*.md` (with `paths:` for path-scoping)
- Cursor → `.cursor/rules/*.mdc` (with `globs:`/`alwaysApply:`)
- Codex → AGENTS.md hierarchy + `.codex/config.toml`

Topics: code-style, testing, security, api-conventions, ux-guidelines, reproducibility, tech-stack.

## Non-negotiables
- 100% test coverage on new/modified code
- Code review before merge
- E2E sign-off before release
- Security review for auth/data/API changes
- Reproducible builds (locked deps, pinned runtime, CI is truth)
- Every error logged before fixed
- Every prod incident → fix, test, or rule update
- Recurring errors (2+) → update the relevant agent file

## Decision gates
When a phase needs human approval, use the structured-question format in `aidlc/common/decision-gates.md`.

## Examples
Fill-in templates in `aidlc/examples/`: `feature-spec`, `feature-list`, `eval-suite`, `adr`, `threat-model`, `e2e-test-plan`, `postmortem`.
