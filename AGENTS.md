# AGENTS.md

Tool-agnostic project instructions for any AI coding agent. Codex CLI reads this natively. Claude Code reads `CLAUDE.md` (which `@-imports` this). Cursor reads `.cursor/rules/*.mdc` (which mirror `aidlc/rules/`).

## Repository Layout

```
.
├── AGENTS.md                 # This file — universal entry point
├── CLAUDE.md                 # Claude Code entry (imports this + Claude-specific behaviors)
├── README.md
├── aidlc/                    # Canonical methodology — read these for the workflow
│   ├── core-workflow.md      # Master orchestrator (start here)
│   ├── agents/               # Role definitions: engineer, manager, reviewer
│   ├── inception/            # spec, design  (WHAT/WHY phase)
│   ├── construction/         # plan, build, test, review, security, e2e, ship  (HOW phase)
│   ├── operations/           # operate, retro, investigate, daily-report  (RUN phase)
│   ├── rules/                # Tool-neutral rule source (mirrored to .claude/rules/ and .cursor/rules/)
│   ├── common/               # decision-gates.md (structured-question pattern)
│   └── examples/             # Fill-in templates: feature-spec, adr, threat-model, e2e-test-plan, postmortem
├── .claude/                  # Claude Code adapters (rules with paths:, agents with model:, skills)
├── .cursor/                  # Cursor adapters (.mdc rules with globs:, agents, skills)
├── .codex/                   # Codex config (config.toml, hooks.json) — optional
├── docs/adr/                 # Architecture Decision Records
├── memory/                   # Shared progress notes (also see .claude/memory/ auto-memory)
└── scripts/                  # Utility scripts (audit.sh)
```

## How to Run This Project

Fill in the actual commands for your project. Examples:

```bash
# Install dependencies
# bun install / pnpm install / poetry install

# Develop
# bun dev / pnpm dev / python -m server

# Test
# bun test / pnpm test / pytest

# Lint
# bun run lint / pnpm lint / ruff check

# Build
# bun run build / pnpm build / cargo build --release
```

Update `aidlc/rules/tech-stack.md` with the real stack before the first session.

## Lifecycle: WHAT → HOW → RUN

```
Inception (WHAT/WHY)  →  Construction (HOW)  →  Operations (RUN)
       gate                    gate                  gate
```

Full workflow: `aidlc/core-workflow.md`. Phase prompts in `aidlc/{inception,construction,operations}/`.

## Roles (Subagents)

When acting in a specialized capacity, read the role file:

| Role | When | File |
|------|------|------|
| `engineer` | Build, test, deploy, architecture, DB, CI/CD | `aidlc/agents/engineer.md` |
| `reviewer` | Code review, security, E2E sign-off, retros | `aidlc/agents/reviewer.md` |
| `manager` | New initiative, cross-concern coordination, daily reports | `aidlc/agents/manager.md` |

## Engineering Conventions

Always-on rules in `aidlc/rules/` (mirrored per tool):

- `code-style.md` — naming, formatting, TypeScript strictness
- `testing.md` — 100% coverage, TDD, test co-location
- `security.md` — input validation, secrets, PII, auth/authz
- `api-conventions.md` — REST naming, response envelope, status codes
- `ux-guidelines.md` — spacing, typography, mobile, interaction
- `reproducibility.md` — locked deps, pinned runtime, deterministic builds
- `tech-stack.md` — your project's stack (fill in before first session)

## Do-Not Rules (Non-Negotiables)

- Do not merge without code review
- Do not ship a release without E2E sign-off
- Do not skip security review for changes touching auth, data, or external APIs
- Do not commit secrets, credentials, or `.env` files
- Do not bypass coverage gates (100% on new/modified code)
- Do not use floating dependency ranges in production
- Do not add a fix without a test (every prod incident must produce a fix, a test, or a rule update)
- Do not write code without a plan for non-trivial changes (use plan mode / two-part code planning)

## Success Criteria — How "Done" Is Verified

A change is done when:
- All tests pass with 100% coverage on new/modified files
- Code reviewed, all critical issues resolved
- E2E journeys signed off for changed flows
- Security audit clean if auth/data/API touched
- Build is reproducible (locked deps, pinned runtime, deploy traceable to commit SHA)
- 24h post-deploy with green signals (latency, error rate, traffic, saturation)

## Decision Gates

When the workflow needs human input, use the structured-question format in `aidlc/common/decision-gates.md` rather than free-form chat. This creates an audit trail and reduces ambiguity.

## Reference Examples

Concrete fill-in templates in `aidlc/examples/`:
- `feature-spec.md` — produced by `aidlc/inception/spec.md`
- `adr.md` — produced by `aidlc/construction/plan.md` when an architectural decision is involved
- `threat-model.md` — produced by `aidlc/construction/security.md`
- `e2e-test-plan.md` — produced by `aidlc/construction/e2e.md`
- `postmortem.md` — produced by `aidlc/operations/operate.md`

## Tool-Specific Entry Points

| Tool | Entry | Native Features |
|------|-------|-----------------|
| Codex CLI | `AGENTS.md` (this file), hierarchical | `.codex/config.toml` (MCP, profiles), `.codex/hooks.json` (lifecycle hooks) |
| Claude Code | `CLAUDE.md` (imports this) | `.claude/rules/`, `.claude/agents/`, `.claude/skills/`, `.claude/settings.json` (hooks, permissions) |
| Cursor IDE | `.cursor/rules/*.mdc` | `.cursor/agents/`, `.cursor/skills/`, `.cursor/hooks.json` |

Each tool has its own native location for rules/subagents/skills. Content is duplicated where each tool requires its own format (especially rule frontmatter), but the canonical methodology in `aidlc/` is shared.
