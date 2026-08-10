# Core Workflow — AIDLC

Tool-agnostic phase index. AGENTS.md holds the harness rules and non-negotiables; this file lists phases and gates.

Session lifecycle: `aidlc/common/session-lifecycle.md`. Backlog: `memory/feature-list.json`.

## Three phases

```
Inception (WHAT/WHY) → Construction (HOW) → Operations (RUN)
       gate                gate                gate
```

Every initiative passes through all three. Each phase has a human-approved gate before the next, and opens by surfacing unknowns — elicitation moves in `aidlc/common/unknowns.md`.

## Project shape
`project.yml` declares surfaces, tenancy, release model, and verify commands. A gate whose surface or capability the project does not declare does not apply and needs no skip rationale; a gate it does declare cannot be skipped. Adapt by declaring, never by deleting.

### Inception
- `aidlc/inception/spec.md` — problem, use cases, RICE, acceptance criteria
- `aidlc/inception/design.md` — UI/component specs (`project.yml` declares `web`/`mobile`)

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

**Gate:** signals green through the declared `release.window`; every prod incident produces a fix, test, or rule update.

## Roles
`aidlc/agents/`: `engineer` (build), `reviewer` (quality/security/QA/E2E), `manager` (orchestrate).

## Decision gates & unknowns
`aidlc/common/decision-gates.md` — structured `[Answer]:` audit trail. `aidlc/common/unknowns.md` — elicitation moves per phase.

## Examples
Fill-in templates in `aidlc/examples/`.
