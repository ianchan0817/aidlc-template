# Session lifecycle

Get bearings (start) and handoff (end) so work survives context resets. Pattern from long-running agent harness research: progress file + git + one feature at a time + runtime proof.

## Get bearings — session start
1. Confirm working directory (`pwd`); only edit inside the repo root.
2. Read `memory/progress.md` — Current Focus, Last Session, Known Issues.
3. Read `memory/feature-list.json` — pick highest-priority `passes: false` item (or the agreed sprint slice).
4. **Reconcile** — cross-check memory claims against the repo (files exist, tests pass, `git log --oneline -20` agrees). On mismatch, trust the repo: correct the memory file and note the fix. Re-run this step after any compaction.
5. Run `./init.sh` if present (template: `init.sh.example`). If the smoke fails, **fixing the baseline is this session's slice** — no new features on a broken base.
6. If the phase is unclear, read `aidlc/core-workflow.md`.
7. Select exactly one unfinished feature/slice unless a human-approved sprint contract says otherwise.

## Work loop
1. State assumptions and the sprint contract before edits on non-trivial work.
2. Implement the smallest independently committable slice; **commit as soon as it verifies** — never batch commits to session end.
3. Verify with sensors: tests/lint/types, runtime smoke or E2E for changed journeys, security/evals when applicable.
4. If verification fails, fix and rerun. After 3 failed hypotheses, escalate per `aidlc/operations/investigate.md` — rerunning unchanged commands yields no new information.
5. Record evidence, not confidence.

### Close the loop on "done"
An agent stops when the work *looks* done. Name the check that decides instead, and pick how hard it gates:

| Tier | Mechanism | Costs |
|------|-----------|-------|
| Per-prompt | Name the check in the request ("run the suite and iterate until green") | Nothing; works today |
| Per-session | A standing goal condition re-evaluated each turn, where the tool supports one | One-time setup |
| Deterministic | A stop/pre-completion hook that blocks the turn until the check exits 0 | Needs a real command; blocks every turn |
| Second opinion | Fresh-context `reviewer` sees only the diff and the contract | One extra pass |

Deterministic gates are the strongest and the most brittle: wire one only once the project has a command that reliably passes on a clean tree, and give it a bypass for the session that fixes the check itself. Until then use the first tier plus `reviewer`. Grade the produced outcome, never the tool path taken to it.

## Compact — when context degrades
Long sessions rot: attention dilutes, early instructions fade. Triggers: ~half the window consumed, **two corrections on the same point** (a third rarely lands — the failed approaches are now the context), or the model re-asking answered questions. Then:
1. **Write state first** — `memory/progress.md` (findings, decisions, next steps), implementation-notes fold-backs, feature-list updates. Anything not in a file is lost.
2. Compact or clear via your tool, then re-enter through **Get bearings** — the reconcile step is mandatory after compaction.

## Handoff — session end
1. **Git** — descriptive commit; leave the branch merge-ready.
2. **Progress** — update `memory/progress.md`: Last Session, Next Session, Decisions, Open Questions, Known Issues, verification evidence. Sanitize evidence first — no tokens, connection strings, or secrets in committed memory files.
3. **Feature list** — engineers append; never flip `passes: true` (reviewer stamps it with `verified_sha` after runtime QA / evals).
4. **Artifacts** — refresh ADRs, threat models, E2E plans if gates changed.

## Initializer — greenfield
First session in a new repo: copy `init.sh.example` → `init.sh`, decompose the accepted spec into `memory/feature-list.json` (all `passes: false` — everything the spec covers, nothing speculative), seed `memory/progress.md`, initial commit listing scaffold.
