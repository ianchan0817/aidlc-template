# CLAUDE.md

AIDLC project. Canonical methodology in `aidlc/`. Tool-agnostic instructions in `AGENTS.md`. Always-on rules in `.claude/rules/`. Session lifecycle: `aidlc/common/session-lifecycle.md` (get bearings + handoff).

@AGENTS.md

## Claude-specific behaviors
- Output code/answers directly. No preamble.
- Diff-only output unless full rewrite is requested.
- Stop within 5 seconds of detecting logic drift — clarify, don't guess.
- Non-trivial changes: prefer plan mode (explore → plan → implement → commit).
- When context is stale or compacted, trust repo artifacts (`memory/`, git, `init.sh`) over chat memory.
- Use independent review/eval for sign-off; do not mark a feature passing from self-review alone.
- If a user repeats an instruction, suggest editing the previous message instead of stacking corrections.

## Memory
- Project notes: `memory/progress.md` (decisions, last/next session). Backlog: `memory/feature-list.json` (template: `aidlc/examples/feature-list.md`).
- Detailed status comes from `git log` — don't restate it in memory files.
- ADRs: `docs/adr/ADR-NNN-title.md`.
- Auto-memory (Claude-managed): `~/.claude/projects/<project>/memory/` — outside the repo.

## Adapters (`.claude/`)
- **Subagents** (`.claude/agents/`) — frontmatter (`model`, `tools`) + repo-rooted reference to `aidlc/agents/{engineer,manager,reviewer}.md`. Delegate via the Task tool.
- **Skills** (`.claude/skills/`) — slash commands `/spec /design /plan /build /test /eval /review /security /e2e /ship /operate /retro /investigate /daily-report`. Each points to a phase file under `aidlc/{inception,construction,operations}/`.
- **Rules** (`.claude/rules/`) — path-scoped via `paths:` frontmatter. Cross-cutting rules load every session; frontend/backend/style rules load when relevant files are open.
- **Hooks** (`.claude/settings.json`) — deterministic enforcement. Ships with `SessionStart` (get-bearings reminder) and `PreToolUse` (dangerous-command guard).
