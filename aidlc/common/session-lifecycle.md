# Session lifecycle

Bearings (start) and handoff (end) so work survives context resets.

## Get bearings — session start
1. Confirm working directory (`pwd`); only edit inside the repo root.
2. Read `memory/progress.md` (issues, blockers) and the newest `memory/sessions/` handoff.
3. Take the lowest-`priority` `passes: false` record in `memory/features/`, or the agreed slice. Recipes: `memory/features/README.md`.
4. **Reconcile** — cross-check those claims against the repo (files exist, tests pass, `git log --oneline -20` agrees). On mismatch, trust the repo: fix the memory file and note it. Mandatory after compaction.
5. Run `./init.sh` if present. If the smoke fails, **fixing the baseline is this session's slice** — no new features on a broken base.
6. Phase unclear? Read `aidlc/core-workflow.md`.
7. Take exactly one unfinished slice unless a human-approved contract says otherwise.

## Work loop
1. State assumptions and the sprint contract before edits on non-trivial work.
2. Implement the smallest independently committable slice; **commit as soon as it verifies** — never batch to session end.
3. Verify with sensors: tests/lint/types, runtime smoke or E2E for changed journeys, security/evals when applicable.
4. On failure, fix and rerun. After 3 failed hypotheses, escalate per `aidlc/operations/investigate.md` — rerunning unchanged commands yields nothing new.
5. Record evidence, not confidence.

### Close the loop on "done"
An agent stops when work *looks* done, so name the check that decides and pick how hard it gates: **per-prompt** (name it in the request), **per-session** (a standing goal condition, where the tool has one), **deterministic** (a stop hook blocking the turn until the check exits 0 — strongest and most brittle, so wire it only once a command passes reliably on a clean tree, with a bypass for the session that fixes the check), or a **second opinion** (fresh-context `reviewer`, diff and contract only). Until the hook is safe, use the first plus `reviewer`. Grade the outcome, never the path.

## Compact — when context degrades
Long sessions rot: attention dilutes, early instructions fade. Triggers: ~half the window consumed, **two corrections on the same point** (a third rarely lands — the failures are now the context), or re-asking answered questions. Then:
1. **Write state first** — session handoff, `memory/progress.md`, implementation-notes fold-backs, feature records. Anything not in a file is lost.
2. Compact or clear, then re-enter through **Get bearings** — including reconcile.

## Handoff — session end
1. **Git** — descriptive commit; leave the branch merge-ready.
2. **Handoff** — write your own `memory/sessions/<date>-<slice>.md` (changed, evidence, not verified, decisions, next); never edit another session's. Issues and blockers go to `memory/progress.md`. Sanitize: no tokens or connection strings.
3. **Features** — engineers add one `memory/features/<id>.json` per feature; never flip `passes: true` (reviewer stamps `verified_sha` + `verified_by` after runtime QA/evals).
4. **Artifacts** — refresh ADRs, threat models, E2E plans if gates changed.

## Initializer — greenfield
First session in a new repo: copy `init.sh.example` → `init.sh`, decompose the accepted spec into one `memory/features/` record per use case (all `passes: false`, nothing speculative), seed `memory/progress.md`, initial commit listing the scaffold.
