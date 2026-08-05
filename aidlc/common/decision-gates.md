# Decision Gates — Structured Questions

Borrowed from AWS Labs AIDLC. When the workflow needs human input, write a structured question file rather than asking conversationally. The user answers in-place, the agent reads the answers, decisions become auditable.

## Format

Store question files as `memory/decisions/NNN-topic.md`. Stamp `Date:` and `Answered-by:` when filled — that is the audit trail.

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

## Validate answers before acting

1. Every `[Answer]:` filled with a listed choice.
2. Vague answers ("depends", "maybe", "not sure") count as unanswered.
3. Check answers against each other for contradictions (e.g. "bug fix" scope + "breaking changes" risk).
4. Any failure → write a follow-up question file referencing the conflict. Never proceed on assumptions.
5. Options must be distinguishable. Name each for its essence ("Content-First Rail", not "Option B") and give it one line each of: the bet it makes, what it's good for, what it gives up. If you can't say what an option gives up, it isn't distinct — collapse it. Two real options beat three padded ones.

## Where to use

- **Inception → Spec:** clarify use cases, success metrics, out-of-scope
- **Inception → Design:** confirm responsive breakpoints, primary platform, accessibility scope
- **Construction → Plan:** choose between architectural options when an ADR is required
- **Construction → Build:** Part-1 plan approval before Part-2 code generation (no vibe coding)
- **Construction → Eval:** approve agent eval tasks/graders or scope for AI-facing changes
- **Operations → Postmortem:** confirm root cause and action items

## Two-Part Code Generation Pattern

For non-trivial implementation, separate planning from execution:

**Part 1 — Plan (no code):**
1. Read the relevant spec / ADR / existing code
2. Produce numbered execution steps in `memory/plans/{feature}-plan.md`
3. Wait for human approval

**Part 2 — Execute (approved plan only):**
1. Read the approved plan
2. Mark each step `[x]` in the plan file **in the same turn it completes** — never batch updates
3. After a crash or compaction, resume from the first unchecked step, spot-verifying that checked steps actually happened
4. Never deviate from the approved plan without re-approval

## Changing an approved decision

When a gated decision is reversed mid-flight: list the downstream artifacts it invalidates (plan steps, ADRs, tests, specs), confirm with the human, then update them all in the same change. Record the reversal in `memory/progress.md` Decisions.

## Workspace Detection (Brownfield)

Before starting an initiative in an existing codebase:
1. Detect existing artifacts (specs, ADRs, prior plans)
2. If undocumented, write a one-page survey before planning: what the system does, components + dependencies, tech stack, test/lint state
3. Before trusting existing docs/ADRs, check freshness against git history — refresh stale ones rather than planning on fiction
4. Modify in place — do not create parallel-track files
