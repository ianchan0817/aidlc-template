# Plan

Phase: Construction. Architecture + task breakdown + sprint contracts. Runs after spec.

Unfamiliar code? Run a **blindspot pass** first. Porting a reference? Require a **semantics map** before any line is ported — `aidlc/common/unknowns.md`.

## Process
1. **Architecture** — use case (R/W ratio, latency, scale), boundaries, sync vs async, resilience (timeouts, retries, DLQ, idempotency), data (schema from query, indexes, multi-tenant), security (threat model if auth/data/external). `stateful` and `multi_tenant` in `project.yml` switch migrations and isolation; the rest always apply.
2. **ADR** (if architectural decision) — `docs/adr/ADR-NNN-title.md` per `aidlc/examples/adr.md`.
3. **Task breakdown** — atomic tasks, S/M/L estimates, test tasks, dependencies, risks. Order the plan by **decision volatility**, not build order: judgment calls first (each with recommendation, rejected alternative, one-line reversal trigger), then sequencing, then mechanical work. List each conditional phase (design, eval, security, e2e) as **run/skip with a one-line rationale** — reviewer may challenge skips at the gate. Definition of done: `AGENTS.md` → Done, filtered by `project.yml`.
4. **Sprint contract** — `engineer` proposes deliverables + verifiable success criteria; `reviewer` approves until criteria are testable. Criteria should grade the produced outcome, not an exact tool path. Add partial-credit checkpoints for multi-part work. Record inline or in `memory/progress.md`. See `aidlc/agents/reviewer.md`.
5. **Feature list** — ensure `memory/feature-list.json` exists (schema: `memory/features/README.md`); align tasks with open `passes: false` records.
6. **Memory** — plan to `memory/plans/`; open questions and blockers to `memory/progress.md`.

**Gate:** do not implement until architecture documented, tasks sequenced, sprint contract agreed for the first slice.
