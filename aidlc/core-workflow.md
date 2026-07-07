# Core Workflow — AIDLC

Tool-agnostic phase index. AGENTS.md holds the harness rules and non-negotiables; this file lists phases, gates, and canonical prompts.

Session lifecycle: `aidlc/common/session-lifecycle.md`. Backlog: `memory/feature-list.json`.

## Three phases

```
Inception (WHAT/WHY) → Construction (HOW) → Operations (RUN)
       gate                gate                gate
```

Every initiative passes through all three. Each phase has a human-approved gate before the next, and opens by surfacing unknowns — elicitation moves in `aidlc/common/unknowns.md`.

### Inception
- `aidlc/inception/spec.md` — problem, use cases, RICE, acceptance criteria
- `aidlc/inception/design.md` — UI/component specs (when UI applies)

**Gate:** measurable success metric, ≥1 use case with acceptance criteria, explicit out-of-scope.

### Construction
- `aidlc/construction/plan.md` — architecture + task breakdown + **sprint contract**
- `aidlc/construction/build.md` — incremental TDD; one feature/slice
- `aidlc/construction/test.md` — coverage strategy and enforcement
- `aidlc/construction/eval.md` — agent/LLM feature evals (when applicable)
- `aidlc/construction/review.md` — pre-merge two-pass code review
- `aidlc/construction/security.md` — STRIDE + OWASP (when auth/data/API touched)
- `aidlc/construction/e2e.md` — end-to-end verification vs sprint contract
- `aidlc/construction/ship.md` — land the branch

**Gate:** tests + 100% coverage pass; reviewed; E2E signed off; security cleared if applicable; eval suite green when agent behavior changed.

### Operations
- `aidlc/operations/operate.md` — post-deploy monitoring, incidents, drift, feedback
- `aidlc/operations/retro.md` — retrospective + harness review
- `aidlc/operations/investigate.md` — structured debugging
- `aidlc/operations/daily-report.md` — manager's daily summary

**Gate:** 24h stable signals; every prod incident produces a fix, test, or rule update.

## Roles
`aidlc/agents/`: `engineer` (build), `reviewer` (quality/security/QA/evals/E2E), `manager` (orchestrate + harness review).

## Decision gates
Structured `[Answer]:` format in `aidlc/common/decision-gates.md`. Creates an audit trail for anything ambiguous.

## Unknowns
Elicitation moves per phase (blindspot pass, interview, tweakable plan, change quiz, …) in `aidlc/common/unknowns.md`.

## Examples
Fill-in templates in `aidlc/examples/`: `feature-spec`, `feature-list`, `eval-suite`, `adr`, `threat-model`, `e2e-test-plan`, `implementation-notes`, `postmortem`.
