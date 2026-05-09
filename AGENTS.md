# AGENTS.md

Tool-agnostic instructions for any AI coding agent (Claude Code, Codex CLI, Cursor IDE, etc.). Canonical methodology lives in `aidlc/`. Tool-specific files (`.claude/`, `.cursor/`, `.codex/`) carry only what their tool's loaders require — everything shared lives here or under `aidlc/`.

## Working style

- Output code/answers directly. No preamble.
- Diff-only output unless a full rewrite is requested.
- Stop within 5s of detecting logic drift — clarify, don't guess.
- Non-trivial change → **explore → plan → implement → commit** before any code.
- When context is stale or compacted, trust repo artifacts (`memory/`, `git`, `init.sh`) over chat memory.
- Independent reviewer/eval gates sign-off; never self-mark a feature passing.
- If a user repeats an instruction, suggest editing the previous message instead of stacking corrections.

## Session lifecycle

**Start:** read `aidlc/common/session-lifecycle.md` — get bearings (`memory/progress.md`, `memory/feature-list.json`, `git log`, `./init.sh` smoke when applicable).
**End:** commit + update `memory/progress.md` handoff fields. Only `reviewer` flips `passes: true` on `memory/feature-list.json`.

## Memory & artifacts

- Project notes: `memory/progress.md` (decisions, last/next session, known issues).
- Backlog: `memory/feature-list.json` (template: `aidlc/examples/feature-list.md`).
- Status comes from `git log` — don't restate in memory files.
- ADRs: `docs/adr/ADR-NNN-title.md` (format: `aidlc/examples/adr.md`).

## Layout

```
.
├── AGENTS.md              Universal entry (this file) — agent working style + methodology
├── CLAUDE.md              Claude Code adapter — @-imports this; adds Claude-only specifics
├── README.md              Human-facing docs
├── init.sh.example        Copy to init.sh — bootstrap + smoke test
├── aidlc/                 Canonical methodology (single source of truth)
│   ├── core-workflow.md   One-page master orchestrator
│   ├── agents/            engineer, manager, reviewer
│   ├── inception/         spec, design                              (WHAT/WHY)
│   ├── construction/      plan, build, test, eval, review,
│   │                      security, e2e, ship                       (HOW)
│   ├── operations/        operate, retro, investigate, daily-report (RUN)
│   ├── rules/             code-style, testing, security, api-conventions,
│   │                      ux-guidelines, reproducibility, tech-stack
│   ├── common/            decision-gates.md, session-lifecycle.md
│   └── examples/          feature-spec, feature-list, eval-suite,
│                          adr, threat-model, e2e-test-plan, postmortem
├── memory/                progress.md + feature-list.json (handoff state)
├── .claude/               Claude Code-only: rules · agents · skills · settings
├── .cursor/               Cursor-only:     rules · agents · skills · hooks
├── .codex/                Codex-only:      config.toml · hooks.json
├── docs/adr/              ADRs (tool-neutral)
└── scripts/audit.sh       Footprint audit
```

Adapters reference canonical content via repo-rooted paths (e.g. `aidlc/agents/engineer.md`). No `../../` chains.

## Lifecycle: WHAT → HOW → RUN

Inception → Construction → Operations, with a gate between each. Full workflow: `aidlc/core-workflow.md`.

## Harness shape

The repo is the system of record. Five subsystems:

- **Instructions** — short entry points (this file, `aidlc/`); no giant prompt files.
- **State** — `memory/progress.md`, `memory/feature-list.json`, git history.
- **Scope** — one feature/slice at a time, tied to a verifiable sprint contract.
- **Verification** — tests, lint/type, E2E, security review, evals, transcripts.
- **Lifecycle** — initialize, work, verify, hand off, commit.

Rules and phase files are feedforward guides; hooks, tests, E2E, evals, and review are feedback sensors. Prefer deterministic sensors. Grade **outcomes**, not the exact path the agent took, unless policy requires a path.

## Roles

| Role | Scope | Canonical |
|------|-------|-----------|
| `engineer` | Build, test, deploy, architecture, DB, CI/CD | `aidlc/agents/engineer.md` |
| `reviewer` | Code review, security, runtime QA, agent evals, sprint contracts, E2E sign-off | `aidlc/agents/reviewer.md` |
| `manager`  | Initiatives, coordination, daily reports, harness review cadence | `aidlc/agents/manager.md` |

## Engineering rules

**Canonical bodies live in `aidlc/rules/*.md`** — single source of truth for every tool. Tool adapters are thin frontmatter wrappers that point at the canonical file:

- Claude Code → `.claude/rules/*.md` (`paths:`) → "Apply `aidlc/rules/X.md`"
- Cursor → `.cursor/rules/*.mdc` (`globs:` / `alwaysApply:`) → same pointer
- Codex → reads `aidlc/rules/*.md` directly when this `AGENTS.md` is loaded

Topics (one file per topic in `aidlc/rules/`): `code-style`, `testing`, `security`, `api-conventions`, `ux-guidelines`, `reproducibility`, `tech-stack`. Fill in `aidlc/rules/tech-stack.md` before the first session.

When a tool's rule loader fires, follow the pointer to read the canonical body. Bodies are kept terse so the extra read is negligible.

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

| Tool        | Entry                           | Tool-only files |
|-------------|---------------------------------|------------------|
| Codex CLI   | this `AGENTS.md` (hierarchical) | `.codex/config.toml`, `.codex/hooks.json` |
| Claude Code | `CLAUDE.md` (imports this)      | `.claude/{rules,agents,skills}/`, `.claude/settings.json` |
| Cursor IDE  | `.cursor/rules/*.mdc`           | `.cursor/{rules,agents,skills,hooks}/`, `.cursor/hooks.json` |
