# Core Workflow — AIDLC

The methodology in one page. Tool-agnostic. Adopted from AWS Labs AIDLC and adapted for general SWE.

## Three Phases

```
Inception (WHAT/WHY) → Construction (HOW) → Operations (RUN)
```

Every initiative passes through all three. Each phase has a human-approved gate before the next begins.

### Inception — determine WHAT and WHY
- `aidlc/inception/spec.md` — define the problem, use cases, RICE prioritization, acceptance criteria
- `aidlc/inception/design.md` — UI/component specs, mobile, interaction, accessibility (when UI is involved)

**Gate:** measurable success metric defined, at least one complete use case, explicit out-of-scope.

### Construction — determine HOW and build it
- `aidlc/construction/plan.md` — architecture + task breakdown, ADR if needed
- `aidlc/construction/build.md` — incremental TDD in thin vertical slices
- `aidlc/construction/test.md` — coverage strategy and enforcement
- `aidlc/construction/review.md` — pre-merge two-pass code review
- `aidlc/construction/security.md` — STRIDE threat model + OWASP audit (when auth/data/API touched)
- `aidlc/construction/e2e.md` — end-to-end journey verification
- `aidlc/construction/ship.md` — land the branch

**Gate:** all tests passing at 100% coverage, code reviewed, E2E signed off, security cleared if applicable.

### Operations — RUN the system in production
- `aidlc/operations/operate.md` — post-deploy stewardship: monitoring, incident triage, drift, feedback loop
- `aidlc/operations/retro.md` — sprint retrospective and agent improvement
- `aidlc/operations/investigate.md` — structured debugging with root-cause discipline
- `aidlc/operations/daily-report.md` — manager's daily executive summary

**Gate:** 24h post-deploy stable signals, every prod incident resolved with a fix/test/rule update.

## Roles

See `aidlc/agents/`:
- `engineer` — full-stack implementation
- `reviewer` — quality, security, E2E sign-off
- `manager` — orchestration, daily reports, owner-facing decisions

## Always-On Rules

See `aidlc/rules/` — applied across every phase, every agent, every session:
- `code-style.md`, `testing.md`, `security.md`, `api-conventions.md`, `ux-guidelines.md`, `reproducibility.md`, `tech-stack.md`

## Non-Negotiables

- 100% test coverage on new/modified code
- Code review before merge
- E2E sign-off before release
- Security review for auth/data/API changes
- Reproducible builds (locked deps, pinned runtime, CI is truth)
- Every error logged before fixed
- Every production incident → a fix, a test, or a rule update
- Recurring errors (2+ occurrences) → update the relevant agent file

## Decision Gates

When a phase needs human approval, use the structured-question format in `aidlc/common/decision-gates.md` rather than asking conversationally. This creates an audit trail and reduces ambiguity.

## Examples

Concrete fill-in templates the agents produce, in `aidlc/examples/`:
- `feature-spec.md`, `adr.md`, `threat-model.md`, `e2e-test-plan.md`, `postmortem.md`
