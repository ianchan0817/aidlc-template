# aidlc-template

A tool-agnostic AI Development Lifecycle (AIDLC) template that works across **Claude Code**, **OpenAI Codex CLI**, and **Cursor IDE**. Single canonical methodology, three native tool adapters.

> Inspired by [AWS Labs' AIDLC](https://github.com/awslabs/aidlc-workflows) (3-phase lifecycle, decision gates, tool-agnostic markdown), [Metaflow](https://github.com/Netflix/metaflow), [Kedro](https://github.com/kedro-org/kedro), [ZenML](https://github.com/zenml-io/zenml), [Made-With-ML](https://github.com/GokuMohandas/Made-With-ML), and [awesome-production-machine-learning](https://github.com/EthicalML/awesome-production-machine-learning).

---

## Why this exists

Most agentic coding templates are tool-specific. You set up `.claude/` and your work is locked to Claude. You set up `.cursor/rules/` and the next person on Codex starts from scratch. The methodology is the same — review code, write tests, deploy carefully — but the wiring isn't portable.

This template separates **methodology** (the workflow, rules, role definitions, examples) from **wiring** (how each tool loads them). The methodology lives in `aidlc/`. Each tool has a thin adapter directory pointing at it.

---

## The methodology — three phases

```
Inception (WHAT/WHY)  →  Construction (HOW)  →  Operations (RUN)
       gate                    gate                  gate
```

| Phase | Slash commands / phase prompts |
|-------|--------------------------------|
| **Inception** | `spec`, `design` |
| **Construction** | `plan`, `build`, `test`, `review`, `security`, `e2e`, `ship` |
| **Operations** | `operate`, `retro`, `investigate`, `daily-report` |

Three roles handle the work: `engineer` (build), `reviewer` (quality/security/E2E), `manager` (orchestrate). Definitions in `aidlc/agents/`.

Always-on rules in `aidlc/rules/`: code-style, testing, security, api-conventions, ux-guidelines, reproducibility, tech-stack.

Concrete fill-in templates in `aidlc/examples/`: feature-spec, ADR, threat-model, e2e-test-plan, postmortem.

Decision gates use the AIDLC structured-question pattern — see `aidlc/common/decision-gates.md`.

---

## Tool support

| Tool | Entry point | Native features used |
|------|-------------|---------------------|
| **Claude Code** | `CLAUDE.md` (imports `AGENTS.md`) | `.claude/rules/` (with `paths:`), `.claude/agents/` subagents, `.claude/skills/` slash commands, `.claude/settings.json` hooks + permissions |
| **OpenAI Codex CLI** | `AGENTS.md` (hierarchical discovery) | `.codex/config.toml` (MCP servers, profiles), `.codex/hooks.json` (lifecycle hooks) |
| **Cursor IDE** | `.cursor/rules/*.mdc` (with `globs:`) | `.cursor/agents/` subagents, `.cursor/skills/` skills, `.cursor/hooks.json` lifecycle hooks |

All three read `AGENTS.md` either natively (Codex), via import (Claude), or via reference (Cursor). The canonical methodology in `aidlc/` is referenced by every adapter.

---

## Directory structure

```
aidlc-template/
├── AGENTS.md                  # Universal entry — read by Codex natively, imported by CLAUDE.md
├── CLAUDE.md                  # Claude entry — @-imports AGENTS.md + Claude-specific behaviors
├── README.md                  # This file
├── aidlc/                     # ★ Canonical methodology (tool-agnostic)
│   ├── core-workflow.md       #   Master orchestrator
│   ├── agents/                #   Role definitions: engineer, manager, reviewer
│   ├── inception/             #   Phase prompts: spec, design
│   ├── construction/          #   Phase prompts: plan, build, test, review, security, e2e, ship
│   ├── operations/            #   Phase prompts: operate, retro, investigate, daily-report
│   ├── rules/                 #   Tool-neutral rule source (mirrored to .claude/rules/, .cursor/rules/)
│   ├── common/                #   decision-gates.md
│   └── examples/              #   feature-spec, adr, threat-model, e2e-test-plan, postmortem
├── .claude/                   # Claude Code adapters
│   ├── CLAUDE.md → ../CLAUDE.md (or duplicate)
│   ├── rules/                 #   7 rules with `paths:` frontmatter (Claude format)
│   ├── agents/                #   3 subagent adapters with model:/tools: frontmatter, @-import canonical
│   ├── skills/                #   13 slash-command adapters, @-import canonical phase prompts
│   ├── settings.json          #   Permissions + hooks
│   ├── memory/                #   Project notes (progress.md)
│   └── docs/adr/              #   ADR storage
├── .cursor/                   # Cursor IDE adapters
│   ├── rules/                 #   7 .mdc files with `globs:` frontmatter (Cursor format)
│   ├── agents/                #   3 subagent files (Cursor frontmatter: name, description, model, readonly)
│   ├── skills/                #   13 skill files (SKILL.md format with name, description)
│   └── hooks.json             #   Lifecycle hooks
├── .codex/                    # Codex CLI adapters
│   ├── config.toml            #   MCP servers, feature flags, profiles
│   └── hooks.json             #   PreToolUse/SessionStart hooks
├── docs/adr/                  # ADRs (tool-neutral)
├── memory/                    # Cross-tool progress notes (or use .claude/memory/)
└── scripts/audit.sh           # Token-cost footprint audit
```

`aidlc/` is the source-of-truth. `.claude/`, `.cursor/`, `.codex/` are tool-specific wiring that points at canonical content.

---

## Setup

### 1. Clone

```bash
git clone https://github.com/ianchan0817/aidlc-template.git my-project
cd my-project
rm -rf .git && git init
```

### 2. Fill in your stack

Edit `aidlc/rules/tech-stack.md` (mirrored to `.claude/rules/tech-stack.md` and `.cursor/rules/tech-stack.mdc`).

### 3. Add your build commands

Add a `## How to Run` section to `AGENTS.md` with your install/dev/test/lint/build commands. Codex best-practices recommend keeping these in `AGENTS.md` so any agent reads them at session start.

### 4. Verify the footprint

```bash
bash scripts/audit.sh
```

Expected: ~9k words total (1k root + 5.5k canonical + 1.3k Claude adapters + 1.4k Cursor adapters).

### 5. Open in your tool

| Tool | Command |
|------|---------|
| Claude Code | `claude` (auto-loads `CLAUDE.md`) |
| Codex CLI | `codex` (auto-loads `AGENTS.md`) |
| Cursor | open the directory (auto-loads `.cursor/rules/*.mdc`) |

---

## How the workflow runs

For any new initiative, follow `aidlc/core-workflow.md`:

```
spec → design (if UI) → plan → build → test → review → security → e2e → ship → operate → retro
```

Each phase has a gate before the next. Use `aidlc/common/decision-gates.md` (structured A/B/C/D questions with `[Answer]:`) when you need explicit human approval.

In Claude Code: `/spec`, `/build`, `/review`, etc. as slash commands.
In Codex: invoke phase prompts by referencing the file path.
In Cursor: `/spec`, `/build`, etc. as skills.

---

## Personal vs project layering

Two layers of configuration, both supported by every tool:

| Layer | Location | What goes here |
|-------|----------|----------------|
| **Project** (this template) | `./CLAUDE.md`, `./AGENTS.md`, `./.claude/`, `./.cursor/`, `./.codex/`, `./aidlc/` | Team conventions, AIDLC methodology, project-specific rules. Committed to git. |
| **Personal** | `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.cursor/rules/` | Your individual preferences across all projects. Communication style, preferred tools, workflow defaults. Not in any repo. |

The project layer dictates *what the codebase requires*. The personal layer dictates *how you prefer to work*. Tools merge both; project rules win on conflicts.

For Claude Code specifically: also see `~/.claude/projects/<project>/memory/MEMORY.md` — auto-memory written by Claude itself across sessions for the same git repo.

> **Constitution, not prompts.** Borrowing the framing from [Brij Kishore Pandey](https://www.linkedin.com/pulse/how-claude-code-becomes-full-engineering-team-brij-kishore-pandey-6eqkf/): treat each layer as durable infrastructure, not a one-off prompt. Bloating a layer with conversational corrections is anti-pattern — extract them into rules, skills, or hooks instead.

---

## Examples

The `aidlc/examples/` directory contains five fill-in templates that the workflow phases produce:

- `feature-spec.md` — output of `/spec` (problem, use cases, RICE, acceptance criteria)
- `adr.md` — output of `/plan` when an architectural decision is involved
- `threat-model.md` — output of `/security` (STRIDE table)
- `e2e-test-plan.md` — output of `/e2e` (journey table + sign-off checklist)
- `postmortem.md` — output of `/operate` (timeline, root cause, action items)

These are concrete formats agents fill in, not abstract guidance.

---

## Hooks (deterministic enforcement)

Some rules need to be enforced, not requested. Each tool has a hooks system:

- **Claude Code**: `.claude/settings.json` `hooks` field — fires on `PreToolUse`, `PostToolUse`, `SessionStart`, etc.
- **Codex CLI**: `.codex/hooks.json` — same lifecycle event names. Requires `[features] codex_hooks = true` in `.codex/config.toml`.
- **Cursor**: `.cursor/hooks.json` — broader event set including `beforeShellExecution`, `afterFileEdit`, `subagentStart`.

The template ships with one example hook in each: a `PreToolUse` / `beforeShellExecution` block that rejects obviously dangerous commands. Extend as needed.

---

## MCP (external tools)

- **Codex**: configure in `.codex/config.toml` under `[mcp_servers.NAME]`
- **Claude Code**: `claude mcp add` or edit `.claude/settings.json`
- **Cursor**: see Cursor's MCP docs

The template doesn't configure any MCP servers by default — add yours per project.

---

## Reference: ideas borrowed from each source

| Source | Concept folded in |
|--------|------------------|
| [AWS AIDLC](https://github.com/awslabs/aidlc-workflows) | Three-phase lifecycle (Inception/Construction/Operations), tool-agnostic markdown methodology, structured decision gates with `[Answer]:` files, two-part code planning (plan → execute) |
| [Metaflow](https://github.com/Netflix/metaflow) | "Human-centric" framing for engineers + reviewers; reproducibility-as-default rule |
| [Kedro](https://github.com/kedro-org/kedro) | Modular phase-based structure; separation of concerns; rule-of-five organization |
| [ZenML](https://github.com/zenml-io/zenml) | Stage gates with explicit pass/fail criteria; artifact tracking via examples/ |
| [Made-With-ML](https://github.com/GokuMohandas/Made-With-ML) | End-to-end iteration loop (operate → retro feeds back into spec/plan) |
| [awesome-production-ML](https://github.com/EthicalML/awesome-production-machine-learning) | Operations phase emphasis (monitoring, incident response, drift) |
| [agent-skills](https://github.com/addyosmani/agent-skills) | Anti-rationalization framing (kept lightweight) |

ML-specific concepts (data catalog, experiment tracking, model registry, pipeline DAGs) were considered and rejected — they don't earn token cost for general SWE.

---

## License

MIT
