# Project memory

Lean handoff across sessions. Git holds history; this file holds **decisions**, **context**, and **next actions**. Update at end of each substantive session per `aidlc/common/session-lifecycle.md`.

## Current focus
<!-- 1–2 sentences: active initiative or slice + lifecycle phase (inception/construction/operations) -->
Enterprise AI-DLC review round complete: agent-test.sh sensor, compaction protocol, spec-immutability clause. Template stable; next work is user-driven.

## Last session
<!-- What changed, commits, blockers resolved -->
2026-07-07 (later): Cross-checked user-supplied enterprise AI-DLC architectural review against current repo. Adopted: `scripts/agent-test.sh` (ANSI/OSC strip, CR-overwrite collapse, stack-trace truncation to 50 lines, 400-line cap with head+tail, raw log preserved, exit-code passthrough — verified with 4 crafted scenarios), Compact section in session-lifecycle.md (write state BEFORE clearing, re-bear after), spec-immutability clause in engineer.md (halt-and-escalate, never bend spec to code), bash -n syntax sensor in audit.sh, wrapper wiring in testing rule + test.md + init.sh.example.

Verification evidence: initial 4 scenarios pass, then adversarial workflow (2 agents) reproduced 2 critical bugs — concurrent raw-log clobber (fixed: per-run mktemp + last-symlink) and invalid-UTF-8 aborting BSD sed under UTF-8 locale (fixed: LC_ALL=C pipeline) — plus real-Python-traceback truncation no-op (fixed: trace-block state machine) and MAX_LINES<TAIL cap inversion (fixed: tail clamp). The mktemp fix itself had a BSD flaw (suffix after Xs) caught by rerun. Final regression R1–R6 all green; `bash scripts/audit.sh` exit 0.

Earlier same day: "Know Your Unknowns" elicitation layer (unknowns.md, implementation-notes.md, 8 phase pointers, model-ID + path-chain audit sensors) — commit b756496.

## Next session
<!-- First action for the next person/agent -->
None queued. If extending: consider optional Stop-hook (pre-completion checklist) per tool — deferred until hook events verified per tool.

## Recent decisions
<!-- YYYY-MM-DD: decision — rationale (one line each) -->
2026-07-07: REJECTED 6-file Memory Bank (projectbrief/productContext/systemPatterns/…) — volatility split already exists (low: aidlc/rules + docs/adr; high: memory/); would duplicate and blow token budget.
2026-07-07: REJECTED audit.md append-only ledger + aidlc-state.md — git is the ledger, decisions/ files carry timestamps, progress.md tracks phase; re-affirms earlier rejection.
2026-07-07: REJECTED 4th "initializer" agent — triad + append-only feature-list + mid-flight change protocol already provide epistemic closure; added the missing halt-and-escalate clause to engineer.md instead.
2026-07-07: Adapters use prose pointers, never @-imports — @ resolves relative to the containing file (forces ../../ chains) and doesn't exist in Cursor/Codex; recorded in CLAUDE.md.
2026-07-07: Model-agnostic + path-rooted are enforced audit sensors, not conventions — `model: inherit` only, no ../ chains; CI fails otherwise.
2026-07-05: Guard hooks read stdin JSON, not env vars — env-var form never fired (verified no-op); stdin is the documented interface for Claude Code and Codex.
2026-07-05: Coverage gate is diff-based (100% on new/modified) — global 100% is unreachable in brownfield and contradicted AGENTS.md.
2026-07-05: `passes: true` requires `verified_sha` stamp — makes stale passes detectable and re-verification skippable when SHA unchanged.
2026-07-05: Ship gate for evals softened to "green when a suite exists" — template stays generic; runner named in tech-stack.md fill-in.
2026-07-05: Template gets its own CI (audit.sh in GitHub Actions) — three dangling refs and a broken hook survived manual review; structure checks are now deterministic sensors.

## Open questions
<!-- Owner per item -->
Owner: manager/reviewer — ship optional pre-completion/loop-detection hooks per tool, or keep as project-specific extensions?

## Known issues
<!-- Active bugs/debt; remove when resolved -->
None.
