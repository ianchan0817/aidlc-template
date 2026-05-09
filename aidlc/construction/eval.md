# Eval (agent features)

Phase: Construction. **Automated evaluation** for AI/agent behavior — distinct from unit/integration/E2E **code** tests.

Use when the product includes tools, prompts, multi-turn flows, or autonomous loops. Follow `aidlc/examples/eval-suite.md` for task shape.

## Vocabulary
- **Task** — one test with defined inputs and success criteria.
- **Trial** — one run of a task; use multiple trials when outputs vary (non-determinism).
- **Grader** — scores transcript and/or **environment outcome** (prefer outcome over “did it use tool X in order”).
- **Transcript** — full trace (messages, tool calls, errors).

## Grader types
- **Code-based:** deterministic tests, static analysis, state checks in DB/API — prefer when possible.
- **Model-based:** rubric / LLM-as-judge — calibrate against humans; allow “unknown” when insufficient evidence.
- **Human:** spot-checks and calibration for subjective or high-stakes behavior.

## Suites
- **Capability (quality):** tasks the agent should struggle with; expect <100% pass — hill to climb.
- **Regression:** tasks that must stay green (~100%); run on every harness or prompt change.

Graduate capability tasks to regression when stable. Watch **eval saturation** (all tasks pass → suite no longer differentiates).

## Practice
- Start with 20–50 real failures from prod/support; unambiguous tasks; reference solution proving the task is solvable.
- Balance **should** and **should not** (e.g. search when needed vs avoid over-searching).
- Read transcripts on failures — fix agent, grader, or task spec; 0% pass@N often means a broken task.
- Re-run after model upgrades; tune prompts/rules with traces as signal.

**Future extension:** hooks/middleware (e.g. pre-completion checklist, loop detection) — add in tool-specific config when needed.
