# Testing

Coverage: 100% statement, branch, function, line **on new and modified code** (diff-based). CI blocks merge below that. Legacy code improves opportunistically, not as a gate.

Completion requires evidence, not confidence: include command output, runtime checks, or eval transcript links in the handoff.

## Unit (engineer owns)
- TDD: test before/alongside code. Co-located: `foo.test.ts` next to `foo.ts`
- Behavior names, one assertion per test, no I/O, Arrange/Act/Assert
- Test: every public function, every branch, every error path, every boundary (zero/null/empty/max)
- Agent-friendly output: summary lines only by default; failures greppable on one line (test name + expected vs actual)

## Integration (engineer owns)
- Real DB, real cache — no mocks for system under test
- Each test seeds own data, cleans up. Runs in CI.

## E2E (reviewer owns)
- Full journeys: UI → API → DB → UI. Mechanics and sign-off: `aidlc/construction/e2e.md`.

Skip: framework internals, third-party behavior, private functions, trivial getters.

Tests cover **code**. For **AI/agent** behavior (tools, prompts, multi-turn flows), also maintain an eval suite — `aidlc/construction/eval.md`.
