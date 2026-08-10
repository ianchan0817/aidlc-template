# Operate

Phase: Operations. Post-deploy stewardship — monitoring, incident response, drift detection, feedback loop.

**Owners.** Engineer: steps 1–2, rollback execution, and the step 5 fix or test. Reviewer: step 3 root cause, the postmortem, the stable gate — the deploy is not done until reviewer says so — and confirming the step 5 follow-up exists. Manager: step 4 drift review, every escalation, and rollback vs. forward-fix. Name one incident owner before mitigation starts; an unowned incident is an outage with an audience.

## Process
1. **Verify deploy health** — the four `release.signals` green for the declared soak (channel defaults: `docs/project-shapes.md`). Hold the declared rollback lever ready.
2. **Monitor** — every alert has a runbook. Structured logs with trace IDs. Distributed tracing across services.
3. **Triage incidents** — acknowledge → mitigate (rollback if SLO at risk) → root-cause → blameless postmortem within 48h. Postmortem format: `aidlc/examples/postmortem.md`.
4. **Detect drift** — run the recurring-maintenance schedule in `docs/project-shapes.md`. Every row has an owner and a cadence, because drift is invisible until it is an incident.
5. **Close the loop** — every prod incident produces a fix, a test, or a rule update. No exceptions.

## Stable gate (before declaring deploy "done")
- Declared `release.window` elapsed, all signals green (continuous default: 24h)
- No Critical/High errors in window
- Declared rollback lever exercised; `forward-fix-only` verifies its kill switch instead
