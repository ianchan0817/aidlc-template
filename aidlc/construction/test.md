# Test

Phase: Construction. Test strategy and coverage enforcement.

Follows the `testing` rule (in your tool's rules directory) — do not restate it here.

## Process
1. **Audit** — run the suite with coverage, via `scripts/agent-test.sh <cmd>` when present (agent-parseable output). Identify gaps in changed files.
2. **Write** — tests for each gap describing expected behavior.
3. **Enforce** — CI blocks merge below 100% on new/modified code (use diff-based coverage where tooling supports it; global thresholds otherwise).

## Harness fidelity
A harness that constructs the system differently from production can pass while production fails. Build the system under test the way production builds it, or state plainly which difference remains and what it therefore cannot catch.

Validate the sensor, not only the subject: break the behaviour on purpose and confirm the test fails. A check that has never failed has not been shown to detect anything.

## Gate
All tests passing, 100% on new/modified, no flaky tests, CI enforcement configured.
