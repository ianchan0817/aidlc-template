---
description: /project:review — Pre-merge code review. Two-pass.
---

# Review

## Context
```bash
git branch --show-current
git diff origin/main --stat 2>/dev/null | head -30
```

## Two-Pass Review
**Pass 1 (blocks merge):** bugs, security, N+1/unbounded queries, races, trust boundaries, test gaps (<100% coverage)
**Pass 2 (informational):** naming, structure, duplication, consistency

Checklist: correctness → security (per rules/security.md) → performance → coverage (100%) → maintainability

Output: critical findings with file:line and explanation. **Never approve with open critical issues.**
