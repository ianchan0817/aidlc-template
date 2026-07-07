# Build

Phase: Construction. Incremental TDD in thin vertical slices.

## Process
0. **Get bearings** — `aidlc/common/session-lifecycle.md` (cwd, progress, feature-list, git log, `./init.sh` smoke).
1. **Health first** — if the smoke path or existing tests are broken, stabilize that before new feature work.
2. **Slice** — thin vertical slice: one testable behavior (often one feature-list item), ~5 files max, independently committable. Risk-first.
3. **Red → Green → Refactor** — failing test → minimal code → clean up.
4. **Verify** — tests pass, no lint/type errors, 100% coverage on modified files; run runtime/E2E proof for changed user journeys.
5. **Commit** — one slice = one commit, behavior-descriptive message.
6. **Log surprises** — keep implementation notes (format: `aidlc/examples/implementation-notes.md`): on deviation, pick the conservative option, log it, keep going. Fold-back bullets feed the next plan.
7. **Handoff** — update `memory/progress.md` (Last Session, Next Session, verification evidence). Leave merge-ready: no half-wired features without a Known Issues note.
8. **Repeat** — after all slices: full suite green, self-review, run `aidlc/construction/review.md`.

## Operating rules
- Surface assumptions before acting. Stop when confused.
- No drive-by refactoring. Simplicity over cleverness.
- Verify with evidence: passing tests, clean builds, runtime output.
- Do not mark work done from self-assessment alone; independent review/eval owns sign-off.
