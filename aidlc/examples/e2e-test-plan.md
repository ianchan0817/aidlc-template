# Example: E2E Test Plan

Fill-in template produced by `aidlc/construction/e2e.md`. One per feature.

The Selector column holds the surface's stable identifier — the sample below is a `web` plan. Other surfaces spell it differently: React Native `testID` and iOS `accessibilityIdentifier` for `mobile`; method + path + named response fields for `http-api`; service + method + message fields for `grpc`; topic + event type + payload fields for `events`; argv + exit code + stdout schema for `cli`; named input fixture → asserted output rows for `batch`. Full table: `docs/project-shapes.md`.

```markdown
# E2E Test Plan: [Feature]

## Scope
- **Journeys touched:** [flows this change affects; cross-reference the spec]
- **Environment:** [staging URL · API · seeded test DB · framework]

## Journey 1: [Name]
| Step | Action | Selector | Expected |
|------|--------|----------|----------|
| 1 | Navigate to /[page] | — | `[data-testid=hero]` visible |
| 2 | Click "Start" | `[data-testid=start-btn]` | Modal opens |
| 3 | Fill email | `[data-testid=email-input]` | Validation clears |
| 4 | Submit | `[data-testid=submit-btn]` | POST /v1/items → 201 |
| 5 | Assert list | `[data-testid=items-list]` | New row shows the data |
| 6 | Reload | — | Row persists (DB write confirmed) |

## Journey 2: [Name]
[...]

## Checks
- **Edge cases:** empty input rejected · network failure offers retry ·
  concurrent submit is idempotent · session expiry redirects to login
- **Accessibility:** keyboard reaches every control · errors and state
  changes announced · focus visible throughout · AA contrast on changes
- **Performance:** LCP <2.5s · no new long task >200ms · bundle delta <+5KB
- **Regression:** full suite green in CI · no quarantined test reintroduced

## Sign-off
- [ ] Every journey passes 3 consecutive runs · no flakes · rollback verified

Reviewer: [name]   Date: [...]
```
