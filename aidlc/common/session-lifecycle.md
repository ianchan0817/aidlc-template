# Session lifecycle

Structured **get bearings** (start) and **handoff** (end) so work survives context resets and new sessions. Inspired by long-running agent harness patterns: progress files + git + one feature at a time.

## Get bearings (start of session)
1. Confirm working directory (`pwd`); only edit inside the repo root.
2. Read `aidlc/core-workflow.md` if the initiative phase is unclear.
3. Read `memory/progress.md` — Current Focus, Last Session, Known Issues.
4. Read `memory/feature-list.json` — pick the highest-priority item with `passes: false` (or the agreed sprint slice).
5. `git log --oneline -20` — recent commits and messages.
6. If the project is runnable: run `./init.sh` (from `init.sh.example` if not yet created) — install, start dev stack, **smoke test** a core path before adding features.

## Handoff (end of session)
1. **Git** — commit with a descriptive message; leave the branch merge-ready (no known broken main path without a tracked issue).
2. **Progress** — update `memory/progress.md`: Last Session (what changed), Next Session (first action), Decisions, Open Questions.
3. **Feature list** — engineers do not set `passes: true`; reviewers flip after verified runtime QA / evals per `aidlc/agents/reviewer.md`.
4. **Artifacts** — ADRs, threat models, E2E plans updated if gates changed.

## Initializer (greenfield)
First session on a new codebase: add `init.sh` from `init.sh.example`, seed `memory/feature-list.json` and `memory/progress.md`, and an initial commit listing scaffold files.
