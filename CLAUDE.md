# CLAUDE.md

This project follows the AIDLC methodology. Canonical content is in `aidlc/`. Tool-agnostic instructions live in `AGENTS.md`. Always-on rules live in `.claude/rules/`. **Session lifecycle:** `aidlc/common/session-lifecycle.md` (get bearings + handoff).

@AGENTS.md

## Claude-specific behaviors

- Output code/answers directly. No preamble.
- Diff-only output unless full rewrite is requested.
- Stop within 5 seconds of detecting logic drift — clarify, don't guess.
- For non-trivial changes, prefer plan mode: explore → plan → implement → commit (see `aidlc/core-workflow.md`).
- If a user repeats an instruction, suggest editing the previous message instead of stacking corrections.

## Memory

- Auto memory writes to `~/.claude/projects/<project>/memory/` automatically.
- Project notes live in `memory/progress.md` — what changed, decisions, what's next. Feature backlog: `memory/feature-list.json` (see `aidlc/examples/feature-list.md`).
- Detailed status comes from `git log` — don't restate it in memory files.
- ADRs in `docs/adr/ADR-NNN-title.md`.

## Subagents (`.claude/agents/`)

Thin adapters with Claude-specific frontmatter (`model:`, `tools:`) that `@-import` canonical role definitions from `aidlc/agents/`. Three roles: `engineer`, `manager`, `reviewer`. Use the Task tool to delegate to them.

## Skills (`.claude/skills/`)

Slash-command workflows that `@-import` phase prompts from `aidlc/{inception,construction,operations}/`.

`/spec` `/design` `/plan` `/build` `/test` `/eval` `/review` `/security` `/e2e` `/ship` `/operate` `/retro` `/investigate` `/daily-report`

## Rules (`.claude/rules/`)

Path-scoped rules that auto-load when matching files are in context. Cross-cutting rules (testing, security, reproducibility, tech-stack) load every session. Frontend/backend/style rules load when relevant files are opened.

## Hooks (`.claude/settings.json`)

For deterministic enforcement — actions that must happen every time, not by Claude's judgment. `SessionStart` reminds agents to run get-bearings (`aidlc/common/session-lifecycle.md`). See `hooks` for other examples (lint after edit, block `.env` reads, etc.).
