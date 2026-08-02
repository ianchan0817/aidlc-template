# Project memory

Lean handoff across sessions. Git holds history; this file holds **decisions**, **context**, and **next actions**. Update at end of each substantive session per `aidlc/common/session-lifecycle.md`.

## Current focus
<!-- 1–2 sentences: active initiative or slice + lifecycle phase (inception/construction/operations) -->
Adapter-loadability round complete: the 14 phase commands and 3 subagents were written in formats no tool actually loads; fixed, and the audit now checks adapter *shape*, not just existence. Template stable; next work is user-driven.

## Last session
<!-- What changed, commits, blockers resolved -->
2026-08-02: Re-read the full repo, checked current vendor docs and reference repos, and found the template's own slash commands and subagents were dead.

Fixed: (1) all 14 skills were flat `<tool>/skills/<name>.md` — Claude Code, Cursor, and Codex all require `skills/<name>/SKILL.md`, so **no `/spec`, `/plan`, `/build`… existed in any tool**. Regenerated as 42 directory-form SKILL.md pointers (3 tools × 14), `/ship` marked `disable-model-invocation: true` since it pushes. (2) All three `.claude/agents/*.md` lacked the **required** `name:` field, so the subagents never registered; `tools:` converted from YAML list to the documented comma string, and `TaskCreate/TaskUpdate/TaskList` dropped (filtered out of background subagents anyway) in favour of `TodoWrite`/`Skill`/`WebFetch`. (3) Codex had no command surface at all — it now supports skills, so `.codex/skills/` closes the three-tool parity gap.

Also folded in: four-tier "close the loop on done" (per-prompt → goal condition → stop-hook → fresh-context reviewer) answering the deferred Stop-hook question; fresh-context adversarial review plus its over-reporting caveat in review.md/reviewer.md; two-corrections-then-compact (was "repeated corrections"); human-in-the-loop and adapters-that-load as commitments.

Verification evidence: skills fix confirmed live — the 14 skills went from absent to present in Claude Code's runtime skill listing after the restructure. Four new audit sensors (skill shape + per-tool parity, agent frontmatter, rule parity) each negative-tested against a scratch copy: regressing to a flat skill file, stripping `name:`, deleting a rule pointer, and emptying a skill dir all produce `[FAIL]` and exit 1. `bash scripts/audit.sh` exit 0 on the real tree; `bash -n` clean.

Prior round (2026-07-07): `scripts/agent-test.sh` sensor, compaction protocol, spec-immutability clause — commit f3d2ff5.

## Next session
<!-- First action for the next person/agent -->
None queued. Adapter formats move fast — re-verify skill/agent frontmatter against vendor docs at each harness review (`aidlc/operations/retro.md` step 3), since a format change turns every pointer into a silent no-op.

## Recent decisions
<!-- YYYY-MM-DD: decision — rationale (one line each) -->
2026-08-02: Adapter *shape* is an audit sensor, not a convention — existence checks passed while every slash command was dead; loaders fail silently, so CI must assert the loader's actual format.
2026-08-02: No Stop-hook ships with the template — it is the strongest completion gate but would fire every turn in a repo with no test command; documented as tier 3 of four, wired per project once `./init.sh` passes clean. Closes the open question carried since 2026-07-05.
2026-08-02: Codex gets a skills adapter (`.codex/skills/`) but still no agents adapter — Codex supports the Agent Skills layout natively; its subagent config is a different mechanism and stays prose-invoked.
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
None. (Resolved 2026-08-02: pre-completion hooks are documented as a per-project tier, not shipped — see Recent decisions.)

## Known issues
<!-- Active bugs/debt; remove when resolved -->
None.
