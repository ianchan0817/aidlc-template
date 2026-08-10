# Operate

Phase: Operations. Post-deploy stewardship — monitoring, incident response, drift detection, feedback loop.

**Owners.** Engineer runs steps 1–2 and executes rollback. Reviewer owns step 3 root cause, writes the postmortem, and holds the stable gate — the deploy is not done until reviewer says so. Manager owns step 4 drift review, receives every escalation, and decides rollback vs. forward-fix. Engineer lands the step 5 fix or test; reviewer confirms it exists before closing. Name one incident owner before mitigation starts; an unowned incident is an outage with an audience.

## Process
1. **Verify deploy health** — the four signals named in `project.yml` → `release.signals`, green for the declared soak. Channel defaults (thresholds and windows): `docs/project-shapes.md`. Hold the declared rollback lever ready.
2. **Monitor** — every alert has a runbook. Structured logs with trace IDs. Distributed tracing across services.
3. **Triage incidents** — acknowledge → mitigate (rollback if SLO at risk) → root-cause → blameless postmortem within 48h. Postmortem format: `aidlc/examples/postmortem.md`.
4. **Detect drift** — performance regressions, error-budget burn, dependency CVE alerts, cost anomalies. Weekly check minimum.
5. **Close the loop** — every prod incident produces a fix, a test, or a rule update. No exceptions.

## Stable gate (before declaring deploy "done")
- Declared `release.window` elapsed, all signals green (continuous default: 24h)
- No Critical/High errors in window
- Declared rollback lever exercised; `forward-fix-only` verifies its kill switch instead
