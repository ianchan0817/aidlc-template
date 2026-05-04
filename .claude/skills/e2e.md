---
description: /project:e2e — E2E quality assurance and release sign-off.
---

# E2E

## Context
```bash
git branch --show-current
git diff origin/main --stat 2>/dev/null | head -20
```

## Process
1. **Identify affected journeys** from the diff
2. **Run E2E suite** — feature branch: target affected flows. Staging: full regression.
3. **Write new journey tests** — `data-testid` selectors, no `sleep()`, each test owns its state
4. **Release sign-off** — all journeys passing, regression green, no quarantined in changed area, a11y clean, perf OK, rollback tested. **No sign-off if any red.**
5. **Log** — bugs → `.claude/memory/progress.md` Known Issues. Prod escapes get E2E test before fix closes.

Bug triage: Critical/High → block release. Medium → this sprint. Low → backlog.
