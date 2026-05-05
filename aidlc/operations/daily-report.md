# Daily Report

Phase: Operations. Manager's daily executive summary.

Gather signals, then synthesize. Follow format in `aidlc/agents/manager.md` → Daily Report section.

## Gather
```bash
git log --since="24 hours ago" --oneline --all 2>/dev/null | head -30
git branch -a --sort=-committerdate 2>/dev/null | head -15
cat memory/progress.md 2>/dev/null
ls docs/adr/ 2>/dev/null
```

Present report. Be direct. Lead with most important thing. Update `memory/progress.md` after.
