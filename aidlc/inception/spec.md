# Spec

Phase: Inception. Define what to build and why. Runs before design or plan.

## First Principles
1. What is the user trying to accomplish? (job, not feature)
2. Why can't they today? (actual gap)
3. Who, how frequent, cost of not solving?
4. What does success look like, measurably?
5. Simplest thing that could work?
6. What are we explicitly NOT doing?

## Outputs
- **Use cases** — business context, user segments, JTBD, actor/preconditions/flow/postconditions, out of scope
- **RICE** — Reach × Impact × Confidence / Effort
- **Feature spec** — problem, solution, acceptance criteria (Given/When/Then), success metrics, constraints, integration impact
- **Backlog** — append accepted use cases to `memory/feature-list.json` as `passes: false` entries (shape: `aidlc/examples/feature-list.md`)

## Gate
Do not proceed to plan or design until: measurable success metric, at least one use case with acceptance criteria, explicit out-of-scope.
