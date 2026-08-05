# Example: Postmortem

Fill-in template produced by `aidlc/operations/operate.md`. Required within 48h of any Critical or High incident. Blameless.

```markdown
# Postmortem: [Incident] — [YYYY-MM-DD]

## Summary
[2–3 sentences: what happened, who was affected, how long.]

## Impact
- **Severity:** [Critical/High/Medium/Low — criteria in aidlc/agents/reviewer.md]
- **Users affected:** [count or %]   **Duration:** [start → end, UTC]
- **Symptoms:** [what users saw]    **SLO/revenue:** [if measurable]

## Timeline (UTC)
| Time | Event |
|------|-------|
| HH:MM | Trigger (e.g. deploy of v1.2.3) |
| HH:MM | First alert fires |
| HH:MM | On-call acknowledges |
| HH:MM | Mitigation applied (rollback / flag / manual) |
| HH:MM | Symptoms resolved → all-clear |

## Root cause
The actual cause, not the symptom — keep asking "why" until it stops
being about code and starts being about the process that let it through:

- Symptom: 5xx rate hit 12%
- Why: connection pool exhausted
- Why: a query held its connection across an external HTTP call
- Why: added in PR #1234, review had no checklist item for it
- **Root cause:** missing review rule — "no I/O while holding a DB connection"

## What went well / what didn't
- Well: [detection was fast because alert X was tuned]
- Not: [on-call paged 7 min late — threshold too lax; no rollback runbook]

## Action items
| # | Type | Action | Owner | Due |
|---|------|--------|-------|-----|
| 1 | Fix | [the code fix] | | |
| 2 | Test | [test that would have caught this] | | |
| 3 | Detection | [tighter alert / dashboard] | | |
| 4 | Prevention | [process or rule update] | | |
| 5 | Runbook | [document the response] | | |

## Closes when
- [ ] Fixes shipped · tests green in CI · rule updated (if applicable) · runbook published

Author: [name]   Reviewer: [name]   Closed: [date]
```
