# Session lifecycle

Get bearings (start) and handoff (end) so work survives context resets. Pattern from long-running agent harness research: progress file + git + one feature at a time.

## Get bearings — session start
1. Confirm working directory (`pwd`); only edit inside the repo root.
2. Read `memory/progress.md` — Current Focus, Last Session, Known Issues.
3. Read `memory/feature-list.json` — pick highest-priority `passes: false` item (or the agreed sprint slice).
4. `git log --oneline -20` — recent context.
5. Run `./init.sh` if present (template: `init.sh.example`) — install, start dev stack, smoke a core path before adding features.
6. If the phase is unclear, read `aidlc/core-workflow.md`.

## Handoff — session end
1. **Git** — descriptive commit; leave the branch merge-ready.
2. **Progress** — update `memory/progress.md`: Last Session, Next Session, Decisions, Open Questions, Known Issues.
3. **Feature list** — engineers never flip `passes: true`; only `reviewer` after verified runtime QA / evals.
4. **Artifacts** — refresh ADRs, threat models, E2E plans if gates changed.

## Initializer — greenfield
First session in a new repo: copy `init.sh.example` → `init.sh`, seed `memory/feature-list.json` and `memory/progress.md`, initial commit listing scaffold.
