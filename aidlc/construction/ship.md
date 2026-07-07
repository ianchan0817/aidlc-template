# Ship

Phase: Construction. Land the current branch.

## Pre-conditions (all must be true)
- Code review done, criticals resolved
- E2E sign-off received
- 100% coverage on new/modified code
- Security review done for auth/data/API changes
- Agent/LLM feature changes: regression eval suite green, when a suite exists (`aidlc/construction/eval.md`)
- Rollback path verified (redeploy previous artifact or revert commit)

## Process
1. Sync with main (rebase/merge, resolve conflicts)
2. Run full test suite — all pass
3. Bump VERSION / CHANGELOG if repo uses them
4. Commit, push, open/update PR
5. Multi-stakeholder ship: package a **buy-in doc** — demo first, pre-answered objections, named sign-offs (`aidlc/common/unknowns.md`)

**Do not ship without review and E2E sign-off.**
