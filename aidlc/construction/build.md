# Build

Phase: Construction. Incremental TDD implementation in thin vertical slices.

## Process
0. **Get bearings** — follow `aidlc/common/session-lifecycle.md`: confirm cwd, read `memory/progress.md`, `memory/feature-list.json`, recent `git log`, run `./init.sh` smoke (copy from `init.sh.example` if needed) so the app is not left broken before new work.
1. **Slice** — thin vertical slices. Each: one testable behavior (often one `feature-list` item), ~5 files max, independently committable. Risk-first order.
2. **Per slice: Red → Green → Refactor** — write failing test → minimal code to pass → clean up
3. **Verify** — all tests pass, no lint/type errors, 100% coverage on modified files
4. **Commit** — one slice = one commit, behavior-descriptive message
5. **Handoff** — update `memory/progress.md` (Last Session / Next Session). Leave merge-ready state: no half-wired features without a note in Known Issues.
6. **Repeat** — after all slices: full suite green, 100% coverage, self-review, run `aidlc/construction/review.md`

## Operating Rules
- Surface assumptions before acting. Stop when confused.
- No drive-by refactoring. Simplicity over cleverness.
- Verify with evidence: passing tests, clean builds, runtime output.
