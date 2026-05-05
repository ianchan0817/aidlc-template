---
description: /project:operate — Post-deploy operations. Monitoring, incident response, drift, feedback loop.
---

# Operate

The phase after ship. A live system needs active stewardship — monitoring isn't passive.

## Process

1. **Verify deploy health** — four signals green: latency p99 <2s, error rate <1%, traffic ±30% of baseline, saturation <80%. Hold rollback ready for 30min post-deploy.
2. **Monitor** — every alert has a runbook. No silent failures. Structured logs with trace IDs. Distributed tracing across services.
3. **Triage incidents** — acknowledge → mitigate (rollback if SLO at risk) → root-cause → blameless postmortem within 48h. Action items tracked.
4. **Detect drift** — performance regressions, error budget burn, dependency CVE alerts, cost anomalies. Weekly check minimum.
5. **Feedback loop** — prod signals (errors, latency, user reports) feed back into spec/plan as concrete tickets. Close the loop: every production incident must produce either a fix, a test, or a rule update.

## Postmortem Template
```
## Incident: [name] — [date]
- Impact: [users affected, duration, severity]
- Timeline: [detection → mitigation → resolution]
- Root cause: [the actual cause, not the symptom]
- Action items: [fix / prevention / detection / response]
- What went well / what didn't
```

## Gate (before declaring deploy "stable")
- 24h post-deploy with all signals green
- No critical/high errors in window
- Rollback path verified working
