# Session lifecycle

Get bearings (start) and handoff (end) so work survives context resets: progress file + git + one slice at a time + runtime proof.

## Get bearings — session start
1. Confirm working directory (`pwd`); only edit inside the repo root.
2. Read `memory/progress.md` — Current Focus, Last Session, Known Issues.
3. Read `memory/feature-list.json` — take the highest-priority `passes: false` item, or the agreed sprint slice.
4. **Reconcile** — cross-check those claims against the repo (files exist, tests pass, `git log --oneline -20` agrees). On mismatch, trust the repo: fix the memory file and note it. Mandatory again after any compaction.
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
An agent stops when work *looks* done. Name the check that decides, and pick how hard it gates — weakest to strongest:

1. **Per-prompt** — name the check in the request ("run the suite, iterate until green"). Free, works today.
2. **Per-session** — a standing goal condition re-evaluated each turn, where the tool supports one.
3. **Deterministic** — a stop/pre-completion hook that blocks the turn until the check exits 0. Strongest and most brittle: wire it only once a command reliably passes on a clean tree, and give it a bypass for the session that fixes the check itself.
4. **Second opinion** — fresh-context `reviewer` sees only the diff and the contract.

Until tier 3 is safe, use tier 1 plus `reviewer`. Grade the produced outcome, never the tool path taken to it.

## Compact — when context degrades
Long sessions rot: attention dilutes, early instructions fade. Triggers: ~half the window consumed, **two corrections on the same point** (a third rarely lands — the failed approaches are now the context), or the model re-asking answered questions. Then:
1. **Write state first** — `memory/progress.md`, implementation-notes fold-backs, feature-list updates. Anything not in a file is lost.
2. Compact or clear, then re-enter through **Get bearings** — including reconcile.

## Handoff — session end
1. **Git** — descriptive commit; leave the branch merge-ready.
2. **Progress** — update `memory/progress.md` (Last/Next Session, Decisions, Open Questions, Known Issues, evidence). Sanitize first: no tokens or connection strings in committed memory.
3. **Feature list** — engineers append; never flip `passes: true` (reviewer stamps `verified_sha` after runtime QA/evals).
4. **Artifacts** — refresh ADRs, threat models, E2E plans if gates changed.

## Initializer — greenfield
First session in a new repo: copy `init.sh.example` → `init.sh`, decompose the accepted spec into `memory/feature-list.json` (all `passes: false`, nothing speculative), seed `memory/progress.md`, initial commit listing the scaffold.
