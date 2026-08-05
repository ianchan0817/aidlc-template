# Review

Phase: Construction. Pre-merge code review, two-pass.

## Context
Pin the range before reading it — a fresh-context reviewer that resolves the base itself judges against whatever stale ref it inherited.
```bash
git fetch --prune
BASE=$(git rev-parse origin/main)          # record this SHA in the verdict
git diff "$BASE"...HEAD --stat | head -30
```

## Two-Pass Review
**Pass 1 (blocks merge):** bugs, security vulns, N+1/unbounded queries, races, trust-boundary violations, missing indexes, unhandled errors, test gaps (<100% coverage on new/modified)
**Pass 2 (informational):** naming, structure, duplication, maintainability, consistency

Axes: correctness → security (per the `security` rule) → performance → coverage → reproducibility → maintainability.

Review the diff against the sprint contract and actual verification evidence. Do not accept self-reported completion without tests, runtime proof, or eval transcripts as applicable. Findings should point to the observable outcome that fails, not preference for a different valid implementation path.

**Review from a fresh context.** Delegate to the `reviewer` role in its own context (subagent, separate session, or a new conversation) so the judge sees the diff and the contract but not the reasoning that produced them. The author is the worst reviewer of their own work, and a session that just wrote the code is biased toward it.

A reviewer asked to find gaps will find some. Bound it: report only what breaks correctness or a stated requirement. Everything else is optional and labelled Pass 2 — chasing it produces defensive code, dead abstraction, and tests for cases that cannot happen.

For high-blast-radius merges, the reviewer may require a **change quiz** (mental model + non-obvious behaviors + scored questions — `aidlc/common/unknowns.md`): verified comprehension, not just green checks.

Output: critical findings with file:line and explanation. **Never approve with open critical issues.**
