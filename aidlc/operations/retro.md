# Retro

Phase: Operations. Sprint retrospective, agent improvement, **harness review**.

1. **Gather** — `git log --since="2 weeks ago" --oneline --all`, `git shortlog -sn`, read `memory/progress.md`
2. **Analyze** — what went well (specific), what went wrong (root cause), what was slow
3. **Harness review** — when the model/tooling stack changed or eval scores saturate: re-read `aidlc/common/session-lifecycle.md`, `aidlc/construction/eval.md`, and tool adapters (`.claude/`, `.cursor/`, `.codex/`). Remove scaffolding that no longer helps; add missing guardrails. **Manager** ensures this happens at least quarterly or after a major model upgrade.
4. **Improve agents** — if pattern repeated 2+ times: update `aidlc/agents/[agent].md`, note in memory
5. **Update memory** — clear completed, move upcoming, log decisions, clean resolved issues
