# Review

Phase: Construction. Pre-merge code review, two-pass.

## Context
```bash
git branch --show-current
git diff origin/main --stat 2>/dev/null | head -30
```

## Two-Pass Review
**Pass 1 (blocks merge):** bugs, security, N+1/unbounded queries, races, trust boundaries, test gaps (<100% coverage)
**Pass 2 (informational):** naming, structure, duplication, consistency

Checklist: correctness → security (per the `security` rule) → performance → coverage (100%) → maintainability.

Review the diff against the sprint contract and actual verification evidence. Do not accept self-reported completion without tests, runtime proof, or eval transcripts as applicable. Findings should point to the observable outcome that fails, not preference for a different valid implementation path.

Output: critical findings with file:line and explanation. **Never approve with open critical issues.**
