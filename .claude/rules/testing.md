---
description: Testing standards — 100% coverage required, TDD discipline
---

# Testing

Mirror of `aidlc/rules/testing.md` — keep in sync. Always-on (no `paths:` frontmatter).

Coverage: 100% statement, branch, function, line. CI blocks merge on drop.

## Unit (engineer owns)
- TDD: test before/alongside code. Co-located: `foo.test.ts` next to `foo.ts`
- Behavior names, one assertion per test, no I/O, Arrange/Act/Assert
- Test: every public function, every branch, every error path, every boundary (zero/null/empty/max)

## Integration (engineer owns)
- Real DB, real cache — no mocks for system under test
- Each test seeds own data, cleans up. Runs in CI.

## E2E (reviewer owns)
- Full journeys: UI → API → DB → UI. No `sleep()` — use `waitFor`.
- Pass 3 consecutive times = stable. Flaky = bug.
- Every prod escape gets an E2E test before fix closes.

## Skip: framework internals, third-party behavior, private functions, trivial getters
