# Plan

Phase: Construction. Architecture + task breakdown + sprint contracts. Runs after spec.

Unfamiliar code? Run a **blindspot pass** first. Porting a reference? Require a **semantics map** before any line is ported — `aidlc/common/unknowns.md`.

## Process
1. **Architecture** — use case (R/W ratio, latency, scale), boundaries, sync vs async, resilience (timeouts, retries, DLQ, idempotency), data (schema from query, indexes, multi-tenant), security (threat model if auth/data/external).
2. **ADR** (if architectural decision) — `docs/adr/ADR-NNN-title.md` per `aidlc/examples/adr.md`.
3. **Task breakdown** — atomic tasks, S/M/L estimates, test tasks, dependencies, risks. Order the plan by **decision volatility**, not build order: judgment calls first (each with recommendation, rejected alternative, one-line reversal trigger), then sequencing, then mechanical work. List each conditional phase (design, eval, security, e2e) as **run/skip with a one-line rationale** — reviewer may challenge skips at the gate. Definition of done: 100% coverage, reviewed, E2E signed off, evals green if AI features.
4. **Sprint contract** — `engineer` proposes deliverables + verifiable success criteria; `reviewer` approves until criteria are testable. Criteria should grade the produced outcome, not an exact tool path. Add partial-credit checkpoints for multi-part work. Record inline or in `memory/progress.md`. See `aidlc/agents/reviewer.md`.
5. **Feature list** — ensure `memory/feature-list.json` exists (template: `aidlc/examples/feature-list.md`); align tasks with open `passes: false` items.
6. **Memory** — update `memory/progress.md` Current Focus + Next Session.

**Gate:** do not implement until architecture documented, tasks sequenced, sprint contract agreed for the first slice.
