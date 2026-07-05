# Project memory

Lean handoff across sessions. Git holds history; this file holds **decisions**, **context**, and **next actions**. Update at end of each substantive session per `aidlc/common/session-lifecycle.md`.

## Current focus
<!-- 1–2 sentences: active initiative or slice -->
Source-grounded hardening round complete (AWS AIDLC, Anthropic harness/evals/context-engineering, ZenML, agent-skills, learn-harness-engineering re-read via 8-agent research + adversarial critic). Template is stable; next work is user-driven.

## Last session
<!-- What changed, commits, blockers resolved -->
2026-07-05: Fixed two dead PreToolUse guard hooks (env-var → stdin JSON; live-verified — the fixed hook blocked its own test command), gave engineer subagent Write/Edit, reconciled diff-based coverage gate across three files, hardened feature-list schema (append-only, `verified_sha`, `verify`, `spec`), added session-start reconciliation + smoke-fail-is-the-slice rules, decision-gate answer validation + same-turn checkboxes + mid-flight change protocol + brownfield survey, pass@k vs pass^k + trial isolation + grader gameability in eval.md, prompt-injection defense in security rule, retro ablation tuning, deduplicated reviewer.md → phase-file pointers, fixed dangling refs (daily-report format inlined, engineer thresholds pointer), audit.sh v2 with structural checks (JSON validity + broken-ref detection, exit non-zero), CI workflow added.

Verification evidence: `bash scripts/audit.sh` exit 0 (all JSON valid, zero broken refs, canonical 6,554w < 8,000 budget); PreToolUse hook block confirmed live in-session.

## Next session
<!-- First action for the next person/agent -->
None queued. If extending: consider optional Stop-hook (pre-completion checklist) per tool — deferred until hook events verified per tool.

## Recent decisions
<!-- YYYY-MM-DD: decision — rationale (one line each) -->
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
