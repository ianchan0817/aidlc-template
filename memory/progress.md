# Project memory

Lean handoff across sessions. Git holds history; this file holds **decisions**, **context**, and **next actions**. Update at end of each substantive session per `aidlc/common/session-lifecycle.md`.

## Current focus
<!-- 1–2 sentences: active initiative or slice -->
"Know Your Unknowns" elicitation layer integrated (Thariq's html-effectiveness collection). Template now covers both sensors-after-action and elicitation-before-action; next work is user-driven.

## Last session
<!-- What changed, commits, blockers resolved -->
2026-07-07: Added `aidlc/common/unknowns.md` (11 elicitation moves by phase: blindspot pass, interview, design directions, mock-first, intervention brainstorm, semantics map, tweakable plan, implementation notes, buy-in doc, change quiz) + `aidlc/examples/implementation-notes.md` (typed deviation log with fold-back loop). Wired one-line pointers into spec/design/plan/build/review/ship/retro. plan.md now orders by decision volatility. Two new always-true audit sensors: no hardcoded model IDs (model: inherit only), no ../ path chains (repo-rooted only). CLAUDE.md records why adapters use prose pointers, not @-imports. README gained unknowns section + source row.

Verification evidence: `bash scripts/audit.sh` exit 0 (both new sensors green, zero broken refs, canonical 7,436w < 8,000 budget).

## Next session
<!-- First action for the next person/agent -->
None queued. If extending: consider optional Stop-hook (pre-completion checklist) per tool — deferred until hook events verified per tool.

## Recent decisions
<!-- YYYY-MM-DD: decision — rationale (one line each) -->
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
