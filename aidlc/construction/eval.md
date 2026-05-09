# Eval (agent features)

Phase: Construction. **Automated evaluation** for AI/agent behavior — distinct from `aidlc/construction/test.md` (which covers code).

Use when the product includes tools, prompts, multi-turn flows, or autonomous loops. Task format: `aidlc/examples/eval-suite.md`.

## Vocabulary
- **Task** — one test with defined inputs and success criteria.
- **Trial** — one run of a task; multiple trials when outputs vary.
- **Grader** — scores transcript and/or environment outcome (prefer outcome).
- **Transcript** — full trace (messages, tool calls, errors).

## Grader types
- **Code-based** — deterministic tests, static analysis, DB/API state checks. Prefer when possible.
- **Model-based** — rubric / LLM-as-judge. Calibrate against humans; allow "unknown" on insufficient evidence.
- **Human** — spot-checks and calibration for subjective or high-stakes behavior.

## Suites
- **Capability** — tasks the agent should struggle with (<100% pass; hill to climb).
- **Regression** — must stay green (~100%); run on every harness/prompt change.

Graduate stable capability tasks to regression. Watch **eval saturation** (all tasks pass → suite no longer differentiates).

## Practice
- Start with 20–50 real failures; unambiguous tasks; reference solution proving solvability.
- Balance **should** vs **should not** (search when needed vs avoid over-searching).
- Read transcripts on failures — fix agent, grader, or task spec at the right layer. 0% pass@N usually means a broken task.
- Re-run after model upgrades; tune prompts/rules with traces as signal.

Future extension: hooks/middleware (pre-completion checklist, loop detection) — add per-tool when needed.
