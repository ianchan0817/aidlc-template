# Project memory

Lean handoff across sessions. Git holds history; this file holds **decisions**, **context**, and **next actions**. Update at end of each substantive session per `aidlc/common/session-lifecycle.md`.

## Current focus
<!-- 1–2 sentences: active initiative or slice -->
Harness-template refresh based on current Claude/Codex/Cursor harness engineering references. Scope: align canonical AIDLC guidance and thin IDE adapters around state, scope, verification, lifecycle, evals, and guide/sensor feedback loops.

## Last session
<!-- What changed, commits, blockers resolved -->
2026-05-09: Updated AIDLC canonical docs, Claude/Codex/Cursor adapters, hooks, testing rules, README sources, and `init.sh.example` to emphasize one-slice work, runtime proof, outcome grading, independent reviewer/eval sign-off, stable Codex instruction layering, and guide/sensor harness design.

Verification evidence: `jq empty` passed for `.claude/settings.json`, `.codex/hooks.json`, `.cursor/hooks.json`; `git diff --check` passed; `bash scripts/audit.sh` passed with footprint within budget (8,890 words, 2 hooks per tool).

## Next session
<!-- First action for the next person/agent -->
Review the harness refresh diff, then decide whether to add optional pre-completion or loop-detection hooks per tool.

## Recent decisions
<!-- YYYY-MM-DD: decision — rationale (one line each) -->
2026-05-09: Keep best-practice changes mostly in `aidlc/` and only add adapter-specific reminders in `.claude/`, `.codex/`, and `.cursor/` — preserves one canonical methodology with thin tool wiring.

## Open questions
<!-- Owner per item -->
Owner: manager/reviewer — should this template ship optional pre-completion hooks, or keep them as project-specific extensions?

## Known issues
<!-- Active bugs/debt; remove when resolved -->
None.
