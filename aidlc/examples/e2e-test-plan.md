# Example: E2E Test Plan

Fill-in template produced by `aidlc/construction/e2e.md`. One per feature.

```markdown
# E2E Test Plan: [Feature]

## Affected Journeys
[List user flows touched by this change. Cross-reference the spec.]

## Test Environment
- Frontend: [staging URL]
- Backend: [staging API]
- Database: [test instance, seeded with: ...]
- Test framework: [Playwright / Cypress / etc.]

## Journey 1: [Name]

| Step | Action | Selector | Expected |
|------|--------|----------|----------|
| 1 | Navigate to /[page] | — | Page loads, `[data-testid=hero]` visible |
| 2 | Click "Start" | `[data-testid=start-btn]` | Form modal opens |
| 3 | Fill email field | `[data-testid=email-input]` | Validation message clears |
| 4 | Click "Submit" | `[data-testid=submit-btn]` | API POST /v1/items returns 201 |
| 5 | Assert UI updated | `[data-testid=items-list]` | New row visible with submitted data |
| 6 | Reload page | — | Row persists (DB write confirmed) |

## Journey 2: [Name]
[...]

## Edge Cases
- [ ] Empty input rejected with clear error
- [ ] Network failure shows retry CTA
- [ ] Concurrent submissions handled (idempotency)
- [ ] Session expiry redirects to login

## Accessibility
- [ ] Keyboard navigation reaches every interactive element
- [ ] Screen reader announces errors and state changes
- [ ] Focus visible at every step
- [ ] Color contrast WCAG AA on changed components

## Performance
- [ ] LCP < 2.5s on staging
- [ ] No new long tasks > 200ms
- [ ] Bundle size delta < +5KB compressed

## Regression
- [ ] Run full regression suite in CI — green
- [ ] No previously quarantined test reintroduced into changed area

## Sign-off
- [ ] All journeys pass 3 consecutive runs
- [ ] No flaky tests in CI
- [ ] Rollback path verified

Reviewer: [name]   Date: [...]
```
