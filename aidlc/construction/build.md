# Build

Phase: Construction. Incremental TDD in thin vertical slices.

## Process
0. **Get bearings** — `aidlc/common/session-lifecycle.md` (cwd, progress, feature-list, git log, `./init.sh` smoke).
1. **Slice** — thin vertical slice: one testable behavior (often one feature-list item), ~5 files max, independently committable. Risk-first.
2. **Red → Green → Refactor** — failing test → minimal code → clean up.
3. **Verify** — tests pass, no lint/type errors, 100% coverage on modified files.
4. **Commit** — one slice = one commit, behavior-descriptive message.
5. **Handoff** — update `memory/progress.md` (Last Session, Next Session). Leave merge-ready: no half-wired features without a Known Issues note.
6. **Repeat** — after all slices: full suite green, self-review, run `aidlc/construction/review.md`.

## Operating rules
- Surface assumptions before acting. Stop when confused.
- No drive-by refactoring. Simplicity over cleverness.
- Verify with evidence: passing tests, clean builds, runtime output.
