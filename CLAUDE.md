# CLAUDE.md

Read `AGENTS.md` first — it covers methodology, roles, working style, lifecycle, and the harness shape. This file is **only** the Claude-Code-specific delta.

@AGENTS.md

## Claude Code only

- **Plan mode** is Claude's slash for the explore→plan→implement→commit loop in `AGENTS.md` → Working style. Skip it when the diff fits in one sentence; the overhead only pays off on multi-file or unfamiliar work.
- **Auto-memory** (Claude-managed) lives at `~/.claude/projects/<project>/memory/` — outside the repo. Repo state stays in `memory/`; the two are not interchangeable.
- **Fresh-context review** — delegate `/review` to the `reviewer` subagent rather than reviewing inline. A context that wrote the code cannot judge it (`aidlc/construction/review.md`).
- **Commands** are `.claude/skills/<name>/SKILL.md`: `/spec /design /plan /build /test /eval /review /security /e2e /ship /operate /retro /investigate`.

Changing the `.claude/` adapter itself — frontmatter each loader requires, which rules load unconditionally, hook wiring: `CONTRIBUTING.md` → Adapter shape.
