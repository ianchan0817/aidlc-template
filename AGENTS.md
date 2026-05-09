# AGENTS.md

Tool-agnostic project instructions for any AI coding agent (works with Claude, GPT, Gemini, GLM, Minimax, etc., across Claude Code, Codex CLI, Cursor IDE, and any tool that respects this file). Canonical methodology lives in `aidlc/`.

## Session lifecycle

At **session start**: read `aidlc/common/session-lifecycle.md` — get bearings (`memory/progress.md`, `memory/feature-list.json`, recent `git log`, `./init.sh` smoke when applicable). At **session end**: commit + update `memory/progress.md` handoff fields.

## Layout

```
.
├── AGENTS.md             Universal entry point (this file)
├── CLAUDE.md             Claude Code entry — @-imports this
├── README.md             Human docs
├── init.sh.example       Copy to init.sh — bootstrap / smoke test for get-bearings
├── aidlc/                Canonical methodology
│   ├── core-workflow.md  Master orchestrator — start here
│   ├── agents/           Roles: engineer, manager, reviewer
│   ├── inception/        spec, design  (WHAT/WHY)
│   ├── construction/     plan, build, test, eval, review, security, e2e, ship  (HOW)
│   ├── operations/       operate, retro, investigate, daily-report  (RUN)
│   ├── common/           decision-gates.md, session-lifecycle.md
│   └── examples/         feature-spec, feature-list, eval-suite, adr, threat-model, e2e-test-plan, postmortem
├── .claude/              Claude Code adapters (rules, agents, skills, settings)
├── .cursor/              Cursor adapters (rules.mdc, agents, skills, hooks)
├── .codex/               Codex config (config.toml, hooks.json)
├── docs/adr/             Architecture Decision Records
├── memory/               Cross-tool notes: progress.md, feature-list.json
└── scripts/audit.sh      Token-cost audit
```

## Lifecycle: WHAT → HOW → RUN

Inception → Construction → Operations, with a gate between each. Full workflow in `aidlc/core-workflow.md`.

## Roles

| Role | When to act in this capacity | Definition |
|------|------------------------------|------------|
| `engineer` | Build, test, deploy, architecture, DB, CI/CD | `aidlc/agents/engineer.md` |
| `reviewer` | Code review, security, runtime QA, agent evals, E2E sign-off, retros | `aidlc/agents/reviewer.md` |
| `manager` | New initiative, coordination, daily reports, harness review cadence | `aidlc/agents/manager.md` |

## Engineering rules

Always-on, applied to every change. Each tool has its own rules directory with format-specific frontmatter:

- Claude Code → `.claude/rules/*.md` (`paths:` for path-scoping)
- Cursor → `.cursor/rules/*.mdc` (`globs:` / `alwaysApply:`)
- Codex → loaded via this AGENTS.md and any subdirectory `AGENTS.override.md`

Topics: `code-style`, `testing`, `security`, `api-conventions`, `ux-guidelines`, `reproducibility`, `tech-stack`. Fill in `tech-stack` before the first session.

## Do-not rules (non-negotiables)

- Do not merge without code review
- Do not ship a release without E2E sign-off
- Do not skip security review for changes to auth, data, or external APIs
- Do not commit secrets, credentials, or `.env` files
- Do not bypass the 100% coverage gate on new/modified code
- Do not use floating dependency ranges in production
- Do not add a fix without a test (every prod incident → fix, test, or rule update)
- Do not write code without a plan for non-trivial changes
- Do not mark `passes: true` in `memory/feature-list.json` without reviewer-verified QA

## Done is verified

A change is done when:
- All tests pass with 100% coverage on new/modified files
- Reviewed, all critical issues resolved
- E2E journeys signed off for changed flows
- Agent eval / regression suite green when behavior of AI-facing features changed (`aidlc/construction/eval.md`)
- Security audit clean if auth/data/API touched
- Build is reproducible (locked deps, pinned runtime, deploy traceable to commit SHA)
- 24h post-deploy with green signals (latency, error rate, traffic, saturation)

## Decision gates

When the workflow needs human input, use the structured-question format in `aidlc/common/decision-gates.md` instead of free-form chat. Creates an audit trail.

## Tool-specific entry points

| Tool | Entry | Native features |
|------|-------|-----------------|
| Codex CLI | this `AGENTS.md` (hierarchical: global → repo → subdirs) | `.codex/config.toml`, `.codex/hooks.json` |
| Claude Code | `CLAUDE.md` (imports this) | `.claude/{rules,agents,skills}/`, `.claude/settings.json` |
| Cursor IDE | `.cursor/rules/*.mdc` | `.cursor/{agents,skills}/`, `.cursor/hooks.json` |

Each tool's adapter directory is the format-specific projection of the canonical content. The methodology in `aidlc/` is shared.
