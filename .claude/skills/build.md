---
description: /project:build — Incremental TDD implementation in thin vertical slices.
---

# Build

## Process
1. **Slice** — break into thin vertical slices. Each: one testable behavior, ~5 files max, independently committable. Risk-first order.
2. **Per slice: Red → Green → Refactor** — write failing test → minimal code to pass → clean up
3. **Verify** — all tests pass, no lint/type errors, 100% coverage on modified files
4. **Commit** — one slice = one commit, behavior-descriptive message
5. **Repeat** — after all slices: full suite green, 100% coverage, self-review, request `/project:review`

## Operating Rules
- Surface assumptions before acting. Stop when confused.
- No drive-by refactoring. Simplicity over cleverness.
- Verify with evidence: passing tests, clean builds, runtime output.
