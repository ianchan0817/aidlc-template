---
description: /project:plan — Architecture design + task breakdown. Runs after spec.
---

# Plan

## Process
1. **Architecture** — use case (R/W ratio, latency, scale), boundaries, sync vs async, resilience (timeouts, retries, DLQ, idempotency), data (schema from query, indexes, multi-tenant), security (threat model if auth/data/external)
2. **ADR** (if architectural decision) — write `.claude/docs/adr/ADR-NNN-title.md`: context, options, decision, consequences
3. **Task Breakdown** — atomic tasks with S/M/L estimates, test tasks, dependencies, risks, definition of done (100% coverage, reviewed, E2E signed off)
4. **Update Memory** — `.claude/memory/progress.md` Current Focus + What's Next

Gate: do not implement until architecture documented, tasks broken down, dependencies sequenced.
