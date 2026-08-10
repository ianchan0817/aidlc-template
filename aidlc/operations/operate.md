# Operate

Phase: Operations. Post-deploy stewardship — monitoring, incident response, drift detection, feedback loop.

A live system needs active stewardship. Monitoring isn't passive.

**Owners.** Engineer runs steps 1–2 and executes rollback. Reviewer owns step 3 root cause, writes the postmortem, and holds the 24h stable gate — the deploy is not done until reviewer says so. Manager owns step 4 drift review, receives every escalation, and decides rollback vs. forward-fix. Engineer lands the step 5 fix or test; reviewer confirms it exists before closing. Name one incident owner before mitigation starts; an unowned incident is an outage with an audience.

## Process
1. **Verify deploy health** — four signals green for 30 min: latency p99 <2s, errors <1%, traffic ±30% baseline, saturation <80%. Hold rollback ready.
2. **Monitor** — every alert has a runbook. Structured logs with trace IDs. Distributed tracing across services.
3. **Triage incidents** — acknowledge → mitigate (rollback if SLO at risk) → root-cause → blameless postmortem within 48h. Postmortem format: `aidlc/examples/postmortem.md`.
4. **Detect drift** — performance regressions, error-budget burn, dependency CVE alerts, cost anomalies. Weekly check minimum.
5. **Close the loop** — every prod incident produces a fix, a test, or a rule update. No exceptions.

## Stable gate (before declaring deploy "done")
- 24h post-deploy with all signals green
- No Critical/High errors in window
- Rollback path verified working
