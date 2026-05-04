---
description: /project:daily-report — Manager daily executive summary.
---

# Daily Report

Gather signals, then synthesize. Follow format in `manager.md` → Daily Report section.

## Gather
```bash
git log --since="24 hours ago" --oneline --all 2>/dev/null | head -30
git branch -a --sort=-committerdate 2>/dev/null | head -15
cat .claude/memory/progress.md 2>/dev/null
ls .claude/docs/adr/ 2>/dev/null
```

Present report. Be direct. Lead with most important thing. Update `.claude/memory/progress.md` after.
