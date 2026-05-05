# Plan

Phase: Construction. Architecture design + task breakdown. Runs after spec.

## Process
1. **Architecture** — use case (R/W ratio, latency, scale), boundaries, sync vs async, resilience (timeouts, retries, DLQ, idempotency), data (schema from query, indexes, multi-tenant), security (threat model if auth/data/external)
2. **ADR** (if architectural decision) — write `docs/adr/ADR-NNN-title.md`: context, options, decision, consequences. See `aidlc/examples/adr.md` for format.
3. **Task Breakdown** — atomic tasks with S/M/L estimates, test tasks, dependencies, risks, definition of done (100% coverage, reviewed, E2E signed off)
4. **Update Memory** — `memory/progress.md` Current Focus + What's Next

Gate: do not implement until architecture documented, tasks broken down, dependencies sequenced.
