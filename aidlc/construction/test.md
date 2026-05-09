# Test

Phase: Construction. Test strategy and coverage enforcement.

Follows the `testing` rule (in your tool's rules directory) — do not restate it here.

## Process
1. **Audit** — run test suite with coverage. Identify gaps.
2. **Write** — tests for each gap describing expected behavior.
3. **Enforce** — CI blocks merge below 100%:
```js
coverage: { thresholds: { statements: 100, branches: 100, functions: 100, lines: 100 } }
```

## Gate
All tests passing, 100% on new/modified, no flaky tests, CI enforcement configured.
