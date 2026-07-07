# Retro

Phase: Operations. Sprint retrospective, agent improvement, **harness review**.

1. **Gather** — `git log --since="2 weeks ago" --oneline --all`, `git shortlog -sn`, read `memory/progress.md`
2. **Analyze** — what went well (specific), what went wrong (root cause), what was slow. Review implementation-notes deviations: a repeated deviation is a guide gap or a sensor gap — fix the harness, not just the code.
3. **Harness review** — when the model/tooling stack changed, repeated failures appear, or eval scores saturate: re-read `aidlc/common/session-lifecycle.md`, `aidlc/construction/eval.md`, and tool adapters (`.claude/`, `.cursor/`, `.codex/`). Check guide/sensor coverage, remove scaffolding that no longer helps, add missing guardrails, and retune per model/tool. Tuning rules: ablation-test guides (remove a rule; if behavior doesn't change, delete it); add a rule only after the same failure appears twice; delete rules the model follows unprompted. **Manager** ensures this happens at least quarterly or after a major model upgrade.
4. **Improve agents** — if pattern repeated 2+ times: update `aidlc/agents/[agent].md`, note in memory
5. **Update memory** — clear completed, move upcoming, log decisions, clean resolved issues
