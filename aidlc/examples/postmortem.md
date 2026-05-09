# Example: Postmortem

Fill-in template produced by `aidlc/operations/operate.md`. Required within 48h of any Critical or High incident. Blameless.

```markdown
# Postmortem: [Incident Name] — [YYYY-MM-DD]

## Summary
[2–3 sentences. What happened, who was affected, how long.]

## Severity
[Critical / High / Medium / Low] — see triage criteria in `aidlc/agents/reviewer.md`.

## Impact
- **Users affected:** [count or %]
- **Duration:** [start → end timestamps in UTC]
- **Symptoms:** [what users saw / experienced]
- **Revenue / SLO impact:** [if measurable]

## Timeline (UTC)

| Time | Event |
|------|-------|
| HH:MM | [trigger — e.g. deploy of v1.2.3] |
| HH:MM | First alert fires |
| HH:MM | On-call acknowledges |
| HH:MM | Mitigation applied (rollback / feature flag / manual fix) |
| HH:MM | Symptoms resolved |
| HH:MM | All-clear declared |

## Root Cause

[The actual cause, not the symptom. Trace it back as far as it goes — usually 3+ "why?"s.]

Example structure:
- Symptom: 5xx rate spiked to 12%
- Why: connection pool exhausted
- Why: query held connection across an external HTTP call
- Why: pattern was added in PR #1234 without code review catching it
- **Root cause:** missing review checklist item for "no I/O while holding DB connection"

## What Went Well
- [Detection time was short because alert X was tuned]
- [Rollback was clean because deploy artifact was reproducible]

## What Didn't Go Well
- [On-call paged 7 minutes after symptoms started — alert threshold too lax]
- [Rollback procedure was not documented for this service]

## Action Items

| ID | Type | Action | Owner | Due |
|----|------|--------|-------|-----|
| 1 | Fix | [the actual code fix] | | |
| 2 | Test | [test that would have caught this] | | |
| 3 | Detection | [tighter alert / new dashboard] | | |
| 4 | Prevention | [process / rule / agent update] | | |
| 5 | Runbook | [document the response procedure] | | |

## Closing the Loop

This postmortem closes when:
- [ ] All Type:Fix items shipped
- [ ] Tests added and passing in CI
- [ ] Rule update merged (if applicable, in your tool's rules directory)
- [ ] Runbook published

Author: [name]   Reviewer: [name]   Date closed: [...]
```
