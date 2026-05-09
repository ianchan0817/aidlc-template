# AGENTS.md

Tool-agnostic instructions for any AI coding agent (Claude Code, Codex CLI, Cursor IDE, etc.). Canonical methodology lives in `aidlc/`.

## Session lifecycle

**Start:** read `aidlc/common/session-lifecycle.md` — get bearings (`memory/progress.md`, `memory/feature-list.json`, `git log`, `./init.sh` smoke when applicable).
**End:** commit + update `memory/progress.md` handoff fields. Only `reviewer` flips `passes: true` on `memory/feature-list.json`.

## Layout

```
.
├── AGENTS.md              Universal entry (this file)
├── CLAUDE.md              Claude Code entry — @-imports this
├── README.md              Human docs
├── init.sh.example        Copy to init.sh — bootstrap + smoke test
├── aidlc/                 Canonical methodology (single source of truth)
│   ├── core-workflow.md   One-page master orchestrator
│   ├── agents/            engineer, manager, reviewer
│   ├── inception/         spec, design                       (WHAT/WHY)
│   ├── construction/      plan, build, test, eval, review,
│   │                      security, e2e, ship                (HOW)
│   ├── operations/        operate, retro, investigate,
│   │                      daily-report                       (RUN)
│   ├── common/            decision-gates.md, session-lifecycle.md
│   └── examples/          feature-spec, feature-list, eval-suite,
│                          adr, threat-model, e2e-test-plan, postmortem
├── memory/                progress.md + feature-list.json (handoff state)
├── .claude/               Claude Code adapters (rules, agents, skills, settings)
├── .cursor/               Cursor adapters (rules, agents, skills, hooks)
├── .codex/                Codex config (config.toml, hooks.json)
├── docs/adr/              ADRs (tool-neutral)
└── scripts/audit.sh       Footprint audit
```

Adapters reference canonical content via repo-rooted paths (e.g. `aidlc/agents/engineer.md`). No `../../` chains.

## Lifecycle: WHAT → HOW → RUN

Inception → Construction → Operations, with a gate between each. Full workflow: `aidlc/core-workflow.md`.

## Harness shape

This repo is the system of record. Keep the harness split into five subsystems:
- **Instructions** — short entry points that route to focused files; no giant prompt files.
- **State** — `memory/progress.md`, `memory/feature-list.json`, and git history.
- **Scope** — one feature/slice at a time, tied to a verifiable sprint contract.
- **Verification** — tests, lint/type checks, E2E, security review, evals, and transcripts.
- **Lifecycle** — initialize, work, verify, hand off, commit.

Treat rules and phase files as feedforward guides; treat hooks, tests, E2E, evals, and review as feedback sensors. Prefer deterministic sensors. Grade outcomes, not the exact path an agent took, unless policy requires a path.

## Roles

| Role | Scope | Definition |
|------|-------|------------|
| `engineer` | Build, test, deploy, architecture, DB, CI/CD | `aidlc/agents/engineer.md` |
| `reviewer` | Code review, security, runtime QA, agent evals, sprint contracts, E2E sign-off | `aidlc/agents/reviewer.md` |
| `manager`  | Initiatives, coordination, daily reports, harness review cadence | `aidlc/agents/manager.md` |

## Engineering rules

Always-on, applied to every change. Tool-specific frontmatter, identical content:

- Claude Code → `.claude/rules/*.md` (`paths:`)
- Cursor → `.cursor/rules/*.mdc` (`globs:` / `alwaysApply:`)
- Codex → loaded via this `AGENTS.md` and any subdirectory `AGENTS.override.md`

Topics: `code-style`, `testing`, `security`, `api-conventions`, `ux-guidelines`, `reproducibility`, `tech-stack`. Fill in `tech-stack` before the first session.

## Non-negotiables

- No merge without code review
- No release without E2E sign-off
- No skipping security review on auth, data, or external API changes
- No secrets, credentials, or `.env` files in commits
- No bypassing the 100% coverage gate on new/modified code
- No floating dependency ranges in production
- No fix without a test (every prod incident → fix, test, or rule update)
- No code without a plan for non-trivial changes
- No flipping `passes: true` in `memory/feature-list.json` without reviewer-verified QA

## Done

A change is done when:
- Tests pass at 100% coverage on new/modified files
- Reviewed, all critical issues resolved
- E2E journeys signed off for changed flows
- Agent eval / regression suite green when AI-facing behavior changed (`aidlc/construction/eval.md`)
- Security audit clean if auth/data/API touched
- Build reproducible (locked deps, pinned runtime, deploy traceable to commit SHA)
- 24h post-deploy with green signals (latency, error rate, traffic, saturation)

## Decision gates

Use the structured-question format in `aidlc/common/decision-gates.md` instead of free-form chat. Creates an audit trail.

## Tool entry points

| Tool        | Entry                         | Native features |
|-------------|-------------------------------|-----------------|
| Codex CLI   | this `AGENTS.md` (hierarchical) | `.codex/config.toml`, `.codex/hooks.json` |
| Claude Code | `CLAUDE.md` (imports this)    | `.claude/{rules,agents,skills}/`, `.claude/settings.json` |
| Cursor IDE  | `.cursor/rules/*.mdc`         | `.cursor/{agents,skills,hooks}/`, `.cursor/hooks.json` |
