# Plan

Phase: Construction. Architecture design + task breakdown + sprint contracts. Runs after spec.

## Process
1. **Architecture** — use case (R/W ratio, latency, scale), boundaries, sync vs async, resilience (timeouts, retries, DLQ, idempotency), data (schema from query, indexes, multi-tenant), security (threat model if auth/data/external)
2. **ADR** (if architectural decision) — write `docs/adr/ADR-NNN-title.md`: context, options, decision, consequences. See `aidlc/examples/adr.md` for format.
3. **Task Breakdown** — atomic tasks with S/M/L estimates, test tasks, dependencies, risks, definition of done (100% coverage, reviewed, E2E signed off)
4. **Sprint contract (per slice or batch)** — `engineer` proposes deliverables + **verifiable** success criteria (unit/integration commands, API assertions, UI steps). `reviewer` approves or iterates until criteria are testable. Record in `memory/progress.md` or inline in the plan. See `aidlc/agents/reviewer.md`.
5. **Feature list** — ensure `memory/feature-list.json` exists (template: `aidlc/examples/feature-list.md`); align tasks with open `passes: false` items where applicable.
6. **Update Memory** — `memory/progress.md` Current Focus + What's Next

Gate: do not implement until architecture documented, tasks broken down, dependencies sequenced, and sprint contract agreed for the first implementation slice.
