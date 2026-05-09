# CLAUDE.md

Read `AGENTS.md` first — it covers methodology, roles, working style, lifecycle, and the harness shape. This file is **only** the Claude-Code-specific delta.

@AGENTS.md

## Claude Code only

- **Plan mode** is Claude's slash for the explore→plan→implement→commit loop in `AGENTS.md` → Working style.
- **Auto-memory** (Claude-managed) lives at `~/.claude/projects/<project>/memory/` — outside the repo.
- **Adapter shape** (`.claude/`):
  - `agents/` — frontmatter (`model`, `tools`) + repo-rooted ref to `aidlc/agents/{engineer,manager,reviewer}.md`. Delegate via the Task tool.
  - `skills/` — slash commands `/spec /design /plan /build /test /eval /review /security /e2e /ship /operate /retro /investigate /daily-report`, each pointing at a phase file under `aidlc/{inception,construction,operations}/`.
  - `rules/` — path-scoped via `paths:` frontmatter; bodies mirror `.cursor/rules/*.mdc` (tool format requires duplication).
  - `settings.json` `hooks` — ships `SessionStart` (bearings reminder) and `PreToolUse` (dangerous-command guard).
