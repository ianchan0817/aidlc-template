# CLAUDE.md

Read `AGENTS.md` first — it covers methodology, roles, working style, lifecycle, and the harness shape. This file is **only** the Claude-Code-specific delta.

@AGENTS.md

## Claude Code only

- **Plan mode** is Claude's slash for the explore→plan→implement→commit loop in `AGENTS.md` → Working style. Skip it when the diff fits in one sentence; the overhead only pays off on multi-file or unfamiliar work.
- **Auto-memory** (Claude-managed) lives at `~/.claude/projects/<project>/memory/` — outside the repo. Repo state stays in `memory/`; the two are not interchangeable.
- **Fresh-context review** — delegate `/review` to the `reviewer` subagent rather than reviewing inline. A context that wrote the code cannot judge it (`aidlc/construction/review.md`).
- **Adapter shape** (`.claude/`):
  - Adapters use prose pointers ("Read and execute `aidlc/<phase>/<name>.md`"), **not** `@`-imports: `@` paths resolve relative to the containing file (forcing `../../` chains) and don't exist in Cursor/Codex. One Read per invocation buys repo-rooted paths and three-tool symmetry; the audit verifies every target exists.
  - `agents/<role>.md` — `name` + `description` (both **required**, or the subagent never registers), `model: inherit`, comma-separated `tools`, then a repo-rooted ref to `aidlc/agents/{engineer,manager,reviewer}.md`.
  - `skills/<name>/SKILL.md` — the directory name is the command: `/spec /design /plan /build /test /eval /review /security /e2e /ship /operate /retro /investigate /daily-report`. A flat `skills/<name>.md` is **not** loaded; `/ship` carries `disable-model-invocation: true` because it pushes.
  - `rules/` — path-scoped via `paths:` frontmatter; bodies are pointers to canonical `aidlc/rules/*.md` (single source of truth shared with Cursor and Codex). Exactly **two** ship no `paths:` block and so load unconditionally: `project.md` (how the `project.yml` declaration reaches every session) and `security.md` (the rule you least want missed). Every other rule is scoped, because an unconditional pointer also forces a read of its canonical body on every session — that is real per-session cost, and the audit fails if the unconditional set changes. An *empty* `paths:` block is a dead rule and the audit fails it; an absent block is not.
  - `settings.json` `hooks` — ships `SessionStart` (bearings reminder) and `PreToolUse` (dangerous-command guard, delegating to `scripts/guard-command.sh` so the pattern is shared with Codex and Cursor rather than pasted three times). `permissions.allow` is a convenience boundary, not a security boundary: it permits interpreters, so the secret-file check has to live in the hook. A `Stop` hook is the deterministic completion gate; wire one per project once a check reliably passes on a clean tree (`aidlc/common/session-lifecycle.md` → Close the loop).
