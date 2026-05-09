# Ship

Phase: Construction. Land the current branch.

## Pre-conditions (all must be true)
- Code review done, criticals resolved
- E2E sign-off received
- 100% coverage on new/modified code
- Security review done for auth/data/API changes
- Agent/LLM feature changes: regression eval suite green (`aidlc/construction/eval.md`)

## Process
1. Sync with main (rebase/merge, resolve conflicts)
2. Run full test suite — all pass
3. Bump VERSION / CHANGELOG if repo uses them
4. Commit, push, open/update PR

**Do not ship without review and E2E sign-off.**
