# Spec

Phase: Inception. Define what to build and why. Runs before design or plan.

## First Principles
1. What is the user trying to accomplish? (job, not feature)
2. Why can't they today? (actual gap)
3. Who, how frequent, cost of not solving?
4. What does success look like, measurably?
5. Simplest thing that could work?
6. What are we explicitly NOT doing?

If ambiguity remains, run the **interview** move (agent asks one question at a time, blast-radius order); for solution space, run the **intervention brainstorm** (S/M/L/XL, grounded in code) — `aidlc/common/unknowns.md`.

## Outputs
- **Use cases** — business context, user segments, JTBD, actor/preconditions/flow/postconditions, out of scope
- **RICE** — Reach × Impact × Confidence / Effort
- **Feature spec** — problem, solution, acceptance criteria (Given/When/Then), success metrics, constraints, integration impact
- **Backlog** — one `passes: false` record per accepted use case at `memory/features/<id>.json`. Never append to `memory/feature-list.json`; it is a manifest and a non-empty `features` array fails the audit (schema: `memory/features/README.md`)

## Gate
Do not proceed to plan or design until: measurable success metric, at least one use case with acceptance criteria, explicit out-of-scope.
