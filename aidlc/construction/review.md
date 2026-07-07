# Review

Phase: Construction. Pre-merge code review, two-pass.

## Context
```bash
git branch --show-current
git diff origin/main --stat 2>/dev/null | head -30
```

## Two-Pass Review
**Pass 1 (blocks merge):** bugs, security vulns, N+1/unbounded queries, races, trust-boundary violations, missing indexes, unhandled errors, test gaps (<100% coverage on new/modified)
**Pass 2 (informational):** naming, structure, duplication, maintainability, consistency

Axes: correctness → security (per the `security` rule) → performance → coverage → reproducibility → maintainability.

Review the diff against the sprint contract and actual verification evidence. Do not accept self-reported completion without tests, runtime proof, or eval transcripts as applicable. Findings should point to the observable outcome that fails, not preference for a different valid implementation path.

For high-blast-radius merges, the reviewer may require a **change quiz** (mental model + non-obvious behaviors + scored questions — `aidlc/common/unknowns.md`): verified comprehension, not just green checks.

Output: critical findings with file:line and explanation. **Never approve with open critical issues.**
