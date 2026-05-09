# Session lifecycle

Get bearings (start) and handoff (end) so work survives context resets. Pattern from long-running agent harness research: progress file + git + one feature at a time + runtime proof.

## Get bearings — session start
1. Confirm working directory (`pwd`); only edit inside the repo root.
2. Read `memory/progress.md` — Current Focus, Last Session, Known Issues.
3. Read `memory/feature-list.json` — pick highest-priority `passes: false` item (or the agreed sprint slice).
4. `git log --oneline -20` — recent context.
5. Run `./init.sh` if present (template: `init.sh.example`) — install, start dev stack, smoke a core path before adding features.
6. If the phase is unclear, read `aidlc/core-workflow.md`.
7. Select exactly one unfinished feature/slice unless a human-approved sprint contract says otherwise.

## Work loop
1. State assumptions and the sprint contract before edits on non-trivial work.
2. Implement the smallest independently committable slice.
3. Verify with sensors: tests/lint/types, runtime smoke or E2E for changed journeys, security/evals when applicable.
4. If verification fails, fix and rerun before claiming completion.
5. Record evidence, not confidence.

## Handoff — session end
1. **Git** — descriptive commit; leave the branch merge-ready.
2. **Progress** — update `memory/progress.md`: Last Session, Next Session, Decisions, Open Questions, Known Issues, verification evidence.
3. **Feature list** — engineers never flip `passes: true`; only `reviewer` after verified runtime QA / evals.
4. **Artifacts** — refresh ADRs, threat models, E2E plans if gates changed.

## Initializer — greenfield
First session in a new repo: copy `init.sh.example` → `init.sh`, seed `memory/feature-list.json` and `memory/progress.md`, initial commit listing scaffold.
