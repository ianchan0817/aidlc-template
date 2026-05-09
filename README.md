# aidlc-template

A tool-agnostic AI Development Lifecycle (AIDLC) template that works across **Claude Code**, **OpenAI Codex CLI**, and **Cursor IDE**. Single canonical methodology, three native tool adapters, harness patterns for long-running agentic work.

> Inspired by [AWS Labs' AIDLC](https://github.com/awslabs/aidlc-workflows) (3-phase lifecycle, decision gates, tool-agnostic markdown), [Anthropic's harness research](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) (initializer + coding agent, feature list, progress notes), [Anthropic's evals guide](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) (tasks/graders/transcripts), and [LangChain harness engineering](https://www.langchain.com/blog/improving-deep-agents-with-harness-engineering) (build-verify, context onboarding, loop detection).

---

## Why this exists

Most agentic coding templates are tool-specific. You set up `.claude/` and your work is locked to Claude. You set up `.cursor/rules/` and the next person on Codex starts from scratch. The methodology is the same — review code, write tests, deploy carefully — but the wiring isn't portable.

This template separates **methodology** (the workflow, rules, role definitions, examples) from **wiring** (how each tool loads them). The methodology lives in `aidlc/`. Each tool has a thin adapter directory pointing at it.

It also encodes lessons from running agents across many context windows: a structured **session lifecycle**, a JSON **feature backlog**, **sprint contracts** between engineer and reviewer, and a dedicated **eval phase** for AI/agent behavior.

---

## The methodology — three phases

```
Inception (WHAT/WHY)  →  Construction (HOW)  →  Operations (RUN)
       gate                    gate                  gate
```

| Phase | Slash commands / phase prompts |
|-------|--------------------------------|
| **Inception** | `spec`, `design` |
| **Construction** | `plan`, `build`, `test`, `eval`, `review`, `security`, `e2e`, `ship` |
| **Operations** | `operate`, `retro`, `investigate`, `daily-report` |

Three roles handle the work:

- `engineer` — build, test, deploy, architecture, DB, CI/CD. One feature/slice at a time from the backlog.
- `reviewer` — code review, security (STRIDE), **runtime QA**, **agent evals**, sprint-contract approval, E2E sign-off, retros.
- `manager` — orchestrate, daily reports, **harness review** cadence after model/tool upgrades.

Definitions in `aidlc/agents/`. Always-on rules: code-style, testing, security, api-conventions, ux-guidelines, reproducibility, tech-stack — see `.claude/rules/` and `.cursor/rules/`.

Decision gates use the AIDLC structured-question pattern — see `aidlc/common/decision-gates.md`.

---

## Session lifecycle (long-running work)

Borrowed from Anthropic's harness research. Every session uses the same get-bearings → work → handoff loop so context survives resets.

```
session start          session work             session end
─────────────          ────────────             ───────────
read progress.md       sprint contract          commit
read feature-list.json one feature / slice      update progress.md
git log -20            TDD red→green→refactor   leave merge-ready
run ./init.sh smoke    runtime QA via reviewer  reviewer flips passes
```

Canonical doc: [`aidlc/common/session-lifecycle.md`](aidlc/common/session-lifecycle.md). The `SessionStart` hook in each tool adapter reminds agents to follow it.

Artifacts:

- [`memory/progress.md`](memory/progress.md) — Current Focus / Last Session / Next Session / Decisions / Open Questions / Known Issues
- [`memory/feature-list.json`](memory/feature-list.json) — incremental backlog (`{id, description, steps, passes}`); only the reviewer flips `passes: true`
- [`init.sh.example`](init.sh.example) — copy to `init.sh` for env bootstrap + smoke test

---

## Agent evals (AI behavior, not code)

Code is covered by tests. **Agent behavior** (tools, prompts, multi-turn flows) is covered by evals — different graders, different lifecycle. See [`aidlc/construction/eval.md`](aidlc/construction/eval.md).

| Aspect | Tests (`/test`) | Evals (`/eval`) |
|--------|-----------------|-----------------|
| Subject | Code paths | Agent transcripts + outcomes |
| Graders | Deterministic (assert) | Code + LLM-judge + human spot-checks |
| Suites | Unit / integration / E2E | Capability vs regression |
| When to add | Every change | When AI features ship or change |

Start with 20–50 real failures. Read transcripts on every failed run. Calibrate LLM-as-judge against humans. Fill-in template: [`aidlc/examples/eval-suite.md`](aidlc/examples/eval-suite.md).

---

## Tool support

| Tool | Entry point | Native features used |
|------|-------------|---------------------|
| **Claude Code** | `CLAUDE.md` (imports `AGENTS.md`) | `.claude/rules/` (with `paths:`), `.claude/agents/` subagents, `.claude/skills/` slash commands, `.claude/settings.json` hooks + permissions |
| **OpenAI Codex CLI** | `AGENTS.md` (hierarchical discovery) | `.codex/config.toml` (MCP servers, profiles), `.codex/hooks.json` (lifecycle hooks) |
| **Cursor IDE** | `.cursor/rules/*.mdc` (with `globs:`) | `.cursor/agents/` subagents, `.cursor/skills/` skills, `.cursor/hooks.json` + `.cursor/hooks/` scripts |

All three read `AGENTS.md` either natively (Codex), via import (Claude), or via reference (Cursor). The canonical methodology in `aidlc/` is referenced by every adapter.

---

## Directory structure

```
aidlc-template/
├── AGENTS.md                  # Universal entry — read by Codex natively, imported by CLAUDE.md
├── CLAUDE.md                  # Claude entry — @-imports AGENTS.md + Claude-specific behaviors
├── README.md                  # This file
├── init.sh.example            # Copy to init.sh — install/dev/smoke for get-bearings
├── aidlc/                     # Canonical methodology (tool-agnostic)
│   ├── core-workflow.md       #   One-page master orchestrator
│   ├── agents/                #   Roles: engineer, manager, reviewer
│   ├── inception/             #   spec, design (WHAT/WHY)
│   ├── construction/          #   plan, build, test, eval, review, security, e2e, ship (HOW)
│   ├── operations/            #   operate, retro, investigate, daily-report (RUN)
│   ├── common/                #   decision-gates.md, session-lifecycle.md
│   └── examples/              #   feature-spec, feature-list, eval-suite, adr, threat-model, e2e-test-plan, postmortem
├── memory/                    # Canonical handoff artifacts (tool-agnostic)
│   ├── progress.md            #   Decisions, last/next session, known issues
│   └── feature-list.json      #   Incremental feature backlog
├── .claude/                   # Claude Code adapters
│   ├── rules/                 #   7 rules with `paths:` frontmatter (Claude format)
│   ├── agents/                #   3 subagent adapters with model:/tools: frontmatter
│   ├── skills/                #   Slash-command adapters (incl. /eval), @-import canonical
│   ├── settings.json          #   Permissions + SessionStart bearings hook + safety hooks
│   └── memory/                #   Legacy pointer to root memory/
├── .cursor/                   # Cursor IDE adapters
│   ├── rules/                 #   7 .mdc files with `globs:`/`alwaysApply:` (Cursor format)
│   ├── agents/                #   3 subagent files (name, description, model, readonly)
│   ├── skills/                #   Skill files (incl. eval)
│   ├── hooks/                 #   Hook scripts (e.g. aidlc-session-start.sh)
│   └── hooks.json             #   Lifecycle hooks (sessionStart, beforeShellExecution)
├── .codex/                    # Codex CLI adapters
│   ├── config.toml            #   MCP servers, feature flags, profiles
│   └── hooks.json             #   PreToolUse safety + SessionStart bearings
├── docs/adr/                  # ADRs (tool-neutral)
└── scripts/audit.sh           # Token-cost footprint audit (root + canonical + adapters + memory)
```

`aidlc/` is the source-of-truth. `.claude/`, `.cursor/`, `.codex/` are tool-specific wiring that points at canonical content. `memory/` is tool-agnostic project state.

---

## Setup

### 1. Clone

```bash
git clone https://github.com/ianchan0817/aidlc-template.git my-project
cd my-project
rm -rf .git && git init
```

### 2. Fill in your stack

Edit `.claude/rules/tech-stack.md` and `.cursor/rules/tech-stack.mdc` — keep the two mirrors in sync. Skip the `rules/` step if you only target one tool.

### 3. Add your bootstrap and smoke

```bash
cp init.sh.example init.sh
$EDITOR init.sh   # fill install / dev-server / smoke commands
chmod +x init.sh
```

Add a `## How to Run` section to `AGENTS.md` mirroring those commands. The `SessionStart` hook in each tool will tell agents to read `init.sh` on session start.

### 4. Seed memory

`memory/progress.md` and `memory/feature-list.json` ship as empty templates. Fill `Current Focus` once and start logging features as you `/spec` them.

### 5. Verify the footprint

```bash
bash scripts/audit.sh
```

Expected: ~8–9k words total (~900 root + ~5.4k canonical + ~1.2k Claude adapters + ~1.4k Cursor adapters + small `memory/`). The script warns if root >1500 or canonical >8000.

### 6. Open in your tool

| Tool | Command |
|------|---------|
| Claude Code | `claude` (auto-loads `CLAUDE.md`) |
| Codex CLI | `codex` (auto-loads `AGENTS.md`) |
| Cursor | open the directory (auto-loads `.cursor/rules/*.mdc`) |

---

## How the workflow runs

For any new initiative, follow `aidlc/core-workflow.md`:

```
spec → design (if UI) → plan (+ sprint contract) → build (one feature/slice)
     → test → eval (if AI features) → review → security → e2e → ship
     → operate → retro (+ harness review)
```

Each phase has a gate before the next. Use `aidlc/common/decision-gates.md` (structured A/B/C/D questions with `[Answer]:`) when you need explicit human approval.

In Claude Code: `/spec`, `/build`, `/eval`, etc. as slash commands.
In Codex: invoke phase prompts by referencing the file path.
In Cursor: `/spec`, `/build`, etc. as skills.

---

## Personal vs project layering

Two layers of configuration, both supported by every tool:

| Layer | Location | What goes here |
|-------|----------|----------------|
| **Project** (this template) | `./CLAUDE.md`, `./AGENTS.md`, `./.claude/`, `./.cursor/`, `./.codex/`, `./aidlc/`, `./memory/` | Team conventions, AIDLC methodology, project-specific rules. Committed to git. |
| **Personal** | `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.cursor/rules/` | Your individual preferences across all projects. Communication style, preferred tools, workflow defaults. Not in any repo. |

The project layer dictates *what the codebase requires*. The personal layer dictates *how you prefer to work*. Tools merge both; project rules win on conflicts.

For Claude Code specifically: also see `~/.claude/projects/<project>/memory/MEMORY.md` — auto-memory written by Claude itself across sessions for the same git repo.

> **Constitution, not prompts.** Borrowing the framing from [Brij Kishore Pandey](https://www.linkedin.com/pulse/how-claude-code-becomes-full-engineering-team-brij-kishore-pandey-6eqkf/): treat each layer as durable infrastructure, not a one-off prompt. Bloating a layer with conversational corrections is anti-pattern — extract them into rules, skills, or hooks instead.

---

## Examples

The `aidlc/examples/` directory contains fill-in templates that the workflow phases produce:

- `feature-spec.md` — output of `/spec` (problem, use cases, RICE, acceptance criteria)
- `feature-list.md` — shape for `memory/feature-list.json` (incremental backlog)
- `eval-suite.md` — example agent-eval task YAML (`/eval`)
- `adr.md` — output of `/plan` when an architectural decision is involved
- `threat-model.md` — output of `/security` (STRIDE table)
- `e2e-test-plan.md` — output of `/e2e` (journey table + sign-off checklist)
- `postmortem.md` — output of `/operate` (timeline, root cause, action items)

These are concrete formats agents fill in, not abstract guidance.

---

## Hooks (deterministic enforcement)

Some rules need to be enforced, not requested. Each tool has a hooks system:

- **Claude Code**: [`.claude/settings.json`](.claude/settings.json) `hooks` field — fires on `PreToolUse`, `PostToolUse`, `SessionStart`, etc.
- **Codex CLI**: [`.codex/hooks.json`](.codex/hooks.json) — same lifecycle event names. Requires `[features] codex_hooks = true` in `.codex/config.toml`.
- **Cursor**: [`.cursor/hooks.json`](.cursor/hooks.json) — broader event set including `beforeShellExecution`, `afterFileEdit`, `sessionStart`.

The template ships with two hooks per tool out of the box:

1. `SessionStart` (or `sessionStart`) — injects the get-bearings reminder pointing at `aidlc/common/session-lifecycle.md`.
2. `PreToolUse` / `beforeShellExecution` — rejects obviously dangerous commands (`rm -rf /`, `chmod -R 777 /`, `git push --force` to main).

Extend as needed — e.g. format-on-save, lint-after-edit, pre-completion checklists, loop detection.

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
| [AWS AIDLC](https://github.com/awslabs/aidlc-workflows) | Three-phase lifecycle (Inception/Construction/Operations), tool-agnostic markdown, structured decision gates with `[Answer]:` files, two-part code planning (plan → execute) |
| [Anthropic — Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) | `init.sh` + progress file + JSON feature list, get-bearings on session start, one feature at a time, end-of-session handoff |
| [Anthropic — Harness design for long-running app development](https://www.anthropic.com/engineering/harness-design-long-running-apps) | Generator/evaluator separation (folded into reviewer), sprint contracts before code, runtime QA via browser/MCP, harness-review cadence as models improve |
| [Anthropic — Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) | Tasks/trials/graders vocabulary, capability vs regression suites, transcript review, calibrated LLM-as-judge, balanced problem sets |
| [LangChain — Harness engineering](https://www.langchain.com/blog/improving-deep-agents-with-harness-engineering) | Build-verify loop, context onboarding (cwd/tools/budgets), loop detection as future hook extension, harness simplification on model upgrades |
| [Metaflow](https://github.com/Netflix/metaflow) | Human-centric framing for engineers + reviewers; reproducibility-as-default rule |
| [Kedro](https://github.com/kedro-org/kedro) | Modular phase-based structure; separation of concerns |
| [ZenML](https://github.com/zenml-io/zenml) | Stage gates with explicit pass/fail criteria; artifact tracking via examples/ |
| [Made-With-ML](https://github.com/GokuMohandas/Made-With-ML) | End-to-end iteration loop (operate → retro feeds back into spec/plan) |
| [awesome-production-ML](https://github.com/EthicalML/awesome-production-machine-learning) | Operations phase emphasis (monitoring, incident response, drift) |
| [agent-skills](https://github.com/addyosmani/agent-skills) | Anti-rationalization framing (kept lightweight) |

ML-specific concepts (data catalog, experiment tracking, model registry, pipeline DAGs) were considered and rejected — they don't earn token cost for general SWE.

---

## License

MIT
