# Daily Report

Phase: Operations. Manager's daily executive summary.

Gather signals, then synthesize.

## Gather
```bash
git log --since="24 hours ago" --oneline --all 2>/dev/null | head -30
git branch -a --sort=-committerdate 2>/dev/null | head -15
cat memory/progress.md 2>/dev/null
ls docs/adr/ 2>/dev/null
```

## Report format
1. **The One Thing** — the single most important fact today
2. **Shipped / In Progress / Blocked** — with owner and ETA
3. **Health** — coverage, open errors, CI, E2E, security findings
4. **Decisions needed** — options + recommendation + deadline

Be direct. Lead with the most important thing. Never bury bad news. Update `memory/progress.md` after.
