# Test

Phase: Construction. Test strategy and coverage enforcement.

Follows the `testing` rule (in your tool's rules directory) — do not restate it here.

## Process
1. **Audit** — run test suite with coverage. Identify gaps in changed files.
2. **Write** — tests for each gap describing expected behavior.
3. **Enforce** — CI blocks merge below 100% on new/modified code (use diff-based coverage where tooling supports it; global thresholds otherwise).

## Gate
All tests passing, 100% on new/modified, no flaky tests, CI enforcement configured.
