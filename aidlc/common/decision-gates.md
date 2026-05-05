# Decision Gates — Structured Questions

Borrowed from AWS Labs AIDLC. When the workflow needs human input, write a structured question file rather than asking conversationally. The user answers in-place, the agent reads the answers, decisions become auditable.

## Format

```markdown
## Question 1
[Question text — clear and specific.]

A) [Option A]
B) [Option B]
C) [Option C]
D) Other (please describe)

[Answer]:
```

The agent waits for the `[Answer]:` line to be filled in before proceeding.

## Where to use

- **Inception → Spec:** clarify use cases, success metrics, out-of-scope
- **Inception → Design:** confirm responsive breakpoints, primary platform, accessibility scope
- **Construction → Plan:** choose between architectural options when an ADR is required
- **Construction → Build:** Part-1 plan approval before Part-2 code generation (no vibe coding)
- **Operations → Postmortem:** confirm root cause and action items

## Why this works

- **No context degradation.** The answer file persists across context resets.
- **Audit trail.** Every decision logged with a timestamp.
- **Reduces ambiguity.** Forces enumerated choice over open-ended chat.
- **Tool-agnostic.** Plain markdown, works in any agent.

## Two-Part Code Generation Pattern

For non-trivial implementation, separate planning from execution:

**Part 1 — Plan (no code):**
1. Read the relevant spec / ADR / existing code
2. Produce numbered execution steps in `memory/plans/{feature}-plan.md`
3. Wait for human approval

**Part 2 — Execute (approved plan only):**
1. Read the approved plan
2. Implement step-by-step with checkboxes
3. Verify each step before proceeding
4. Never deviate from the approved plan without re-approval

## Workspace Detection (Brownfield)

Before starting an initiative in an existing codebase:
1. Detect existing artifacts (specs, ADRs, prior plans)
2. Reverse-engineer current behavior if undocumented
3. Modify in place — do not create parallel-track files
