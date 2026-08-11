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

Grade **outcomes and artifacts** before process. Avoid brittle "must call tool X then Y" checks unless compliance or safety requires that path. For multi-part tasks, include partial credit so evals distinguish near misses from total failures.

## Suites
- **Capability** — tasks the agent should struggle with (<100% pass; hill to climb).
- **Regression** — must stay green (~100%); run on every harness/prompt change.

**Injection resistance.** Hold fixture repo files, documents, and tool outputs carrying embedded instructions; grade the action taken — did it call an unrequested tool, fetch an attacker-supplied URL, move data — not whether the text looked suspicious. Run before any release that changes tools or prompts.

Graduate stable capability tasks to regression. Watch **eval saturation** (all tasks pass → suite no longer differentiates).

Metrics: **pass@k** = any of k trials succeeds (capability); **pass^k** = all k succeed. They diverge fast — 75% per-trial ≈ 42% pass^3. Gate user-facing flows on pass^k.

## Practice
- Start with 20–50 real failures; unambiguous tasks; reference solution proving solvability.
- Isolate trials — reset environment between runs, no state leakage, and pin the resource
  envelope (CPU, memory, timeout): an unpinned gate is measuring the runner.
- Balance **should** vs **should not** (search when needed vs avoid over-searching).
- Read transcripts on failures — fix agent, grader, or task spec at the right layer. 0% across all trials usually means a broken task.
- Agents optimize against the sensor: audit graders and contracts for gameable criteria before trusting green.
- Track what explains a regression: tool calls, tokens, latency, error loops, evidence.
- Re-run after model upgrades (`aidlc/operations/retro.md` step 3).
- Keep tasks under `evals/` (or the `verify.eval` path in `project.yml`); record the runner command there too.
