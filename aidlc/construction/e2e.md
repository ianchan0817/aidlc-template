# E2E

Phase: Construction. End-to-end quality assurance and release sign-off.

## Context
```bash
git branch --show-current
git diff origin/main --stat 2>/dev/null | head -20
```

## Process
1. **Identify affected journeys** from the diff
2. **Run E2E suite** — feature branch: target affected flows. Staging: full regression.
3. **Write new journey tests** using template below
4. **Sign off release** using checklist below
5. **Log findings** — bugs → `memory/progress.md` Known Issues. Prod escapes get an E2E test before fix closes.

## Test Plan Template

```markdown
## E2E: [Feature]

### Journey: [Name]
| Step | Action | Expected |
|------|--------|----------|
| 1 | Navigate to [page] | Page loads, element visible |
| 2 | Enter [input] | Validation passes |
| 3 | Submit | API 200, data saved |
| 4 | UI reflects new state | Element updates, DB record present |
```

## Test Rules
- Each test sets up its own state — no shared mutable state
- `data-testid` selectors only — never CSS classes or text
- No `sleep()` — use `waitFor`, retry assertions
- Pass 3 consecutive times to be stable. Flaky = bug.

## Release Sign-off Checklist
- [ ] All E2E journeys passing in staging
- [ ] Full regression suite green
- [ ] No quarantined tests in changed area
- [ ] New feature journeys added and passing
- [ ] No new accessibility violations
- [ ] Performance within acceptable range
- [ ] Rollback tested

**No sign-off if any item is red.**

## Bug Triage

| Severity | Action |
|----------|--------|
| Critical | Block release, notify manager |
| High | Block release |
| Medium | Fix this sprint |
| Low | Backlog |
