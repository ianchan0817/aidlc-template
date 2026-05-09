# aidlc-template

Tool-agnostic AI Development Lifecycle (AIDLC) template for **Claude Code**, **OpenAI Codex CLI**, and **Cursor IDE**. One canonical methodology, three native adapters, harness patterns for long-running agentic work.

> Inspired by [AWS Labs AIDLC](https://github.com/awslabs/aidlc-workflows) (3-phase lifecycle, decision gates), [Anthropic harness research](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) (initializer + coding agent, feature list), [Anthropic evals guide](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) (tasks/graders/transcripts), [Anthropic harness design](https://www.anthropic.com/engineering/harness-design-long-running-apps) (generator/evaluator, sprint contracts), [OpenAI Codex loop](https://openai.com/index/unrolling-the-codex-agent-loop/) (instruction layering, sandbox/context handling), [LangChain harness engineering](https://www.langchain.com/blog/improving-deep-agents-with-harness-engineering) (self-verification, traces), and [Martin Fowler](https://martinfowler.com/articles/harness-engineering.html) / [Learn Harness Engineering](https://github.com/walkinglabs/learn-harness-engineering) (guides, sensors, lifecycle).

---

## Why

Agentic coding templates are usually tool-specific: pick `.claude/` and you can't share with Codex; pick `.cursor/` and Claude Code starts from scratch. The methodology is the same — review code, write tests, deploy carefully — but the wiring isn't portable.

This template separates **methodology** (workflow, rules, roles) from **wiring** (how each tool loads it). Methodology lives in `aidlc/`. Each tool has a thin adapter directory that points at it via repo-rooted paths.

It also bakes in patterns from long-running-agent research: a structured **session lifecycle**, a JSON **feature backlog**, **sprint contracts** between engineer and reviewer, and a dedicated **eval phase** for AI/agent behavior.

The harness is intentionally five-part:
- **Instructions** route agents through focused files instead of one giant prompt.
- **State** persists progress, backlog, and git history across resets.
- **Scope** keeps work to one independently committable slice.
- **Verification** uses tests, hooks, E2E, evals, transcripts, and review as sensors.
- **Lifecycle** forces initialize → work → verify → handoff → commit.

---

## Architecture

```
                      ┌──────────────────────────────┐
                      │  aidlc/  (canonical, shared) │
                      │  agents · phases · examples  │
                      └──────────┬───────────────────┘
                                 │  repo-rooted refs
            ┌────────────────────┼────────────────────┐
            ▼                    ▼                    ▼
       .claude/             .cursor/              .codex/
   rules · agents       rules · agents        config · hooks
   skills · settings    skills · hooks
   (Claude Code)        (Cursor IDE)          (Codex CLI)

       memory/progress.md        memory/feature-list.json
            (handoff)                  (backlog)
```

Adapters never use `../../` chains — every reference is repo-rooted (e.g. `aidlc/agents/engineer.md`). Renaming or moving an adapter file never breaks references.

---

## Methodology — three phases

```
Inception (WHAT/WHY)  →  Construction (HOW)  →  Operations (RUN)
       gate                    gate                  gate
```

| Phase | Slash commands |
|-------|----------------|
| **Inception** | `spec`, `design` |
| **Construction** | `plan`, `build`, `test`, `eval`, `review`, `security`, `e2e`, `ship` |
| **Operations** | `operate`, `retro`, `investigate`, `daily-report` |

Three roles (definitions in `aidlc/agents/`):

- **engineer** — implementation, architecture, DB, CI/CD; one feature/slice at a time from the backlog.
- **reviewer** — code review, security (STRIDE), runtime QA, agent evals, sprint-contract approval, E2E sign-off.
- **manager** — orchestrate, daily reports, harness-review cadence after model/tool upgrades.

Always-on rules — single source of truth in [`aidlc/rules/*.md`](aidlc/rules/): `code-style`, `testing`, `security`, `api-conventions`, `ux-guidelines`, `reproducibility`, `tech-stack`. `.claude/rules/*.md` and `.cursor/rules/*.mdc` are thin pointers in each tool's native frontmatter format. Decision gates use the structured-question pattern in `aidlc/common/decision-gates.md`.

---

## Session lifecycle

Every session uses the same get-bearings → work → handoff loop so context survives resets.

| Start | Work | End |
|-------|------|-----|
| Read `memory/progress.md` | Sprint contract w/ reviewer | Commit |
| Read `memory/feature-list.json` | One feature/slice | Update `memory/progress.md` |
| `git log --oneline -20` | TDD red→green→refactor | Leave merge-ready |
| Run `./init.sh` smoke | Runtime QA via reviewer | Reviewer flips `passes` |

Canonical: [`aidlc/common/session-lifecycle.md`](aidlc/common/session-lifecycle.md). The `SessionStart` hook in each tool injects this reminder.

Artifacts:

- [`memory/progress.md`](memory/progress.md) — Current Focus / Last / Next / Decisions / Open Questions / Known Issues
- [`memory/feature-list.json`](memory/feature-list.json) — incremental backlog (`{id, description, steps, passes}`); only the reviewer flips `passes: true`
- [`init.sh.example`](init.sh.example) — copy to `init.sh` for env bootstrap + smoke

---

## Agent evals vs code tests

Tests cover code paths. Evals cover agent behavior — different graders, different lifecycle.

| Aspect | Tests (`/test`) | Evals (`/eval`) |
|--------|-----------------|-----------------|
| Subject | Code paths | Agent transcripts + outcomes |
| Graders | Deterministic asserts | Code + LLM-judge + human spot-checks |
| Suites | Unit / integration / E2E | Capability vs regression |
| When to add | Every change | When AI features ship or change |

Start with 20–50 real failures. Read transcripts on every failed run. Calibrate LLM-as-judge against humans. See [`aidlc/construction/eval.md`](aidlc/construction/eval.md) and [`aidlc/examples/eval-suite.md`](aidlc/examples/eval-suite.md).

---

## Tool support

| Tool | Entry | Native features |
|------|-------|-----------------|
| **Claude Code** | `CLAUDE.md` (imports `AGENTS.md`) | `.claude/{rules,agents,skills}/`, `.claude/settings.json` |
| **Codex CLI** | `AGENTS.md` (hierarchical) | `.codex/config.toml`, `.codex/hooks.json` |
| **Cursor IDE** | `.cursor/rules/*.mdc` | `.cursor/{rules,agents,skills,hooks}/`, `.cursor/hooks.json` |

All three read `AGENTS.md` — natively (Codex), via `@-import` (Claude), or by reference (Cursor). Adapters point at canonical content in `aidlc/` via repo-rooted paths.

Keep root instructions compact and stable. Put detailed method content under `aidlc/`, then let each tool load only its native adapter plus the canonical files it needs.

---

## Directory structure

```
aidlc-template/
├── AGENTS.md              Universal entry — read by Codex natively
├── CLAUDE.md              Claude entry — @-imports AGENTS.md
├── README.md              This file
├── init.sh.example        Copy to init.sh — install + dev + smoke
├── aidlc/                 Canonical methodology (single source of truth)
│   ├── core-workflow.md   One-page master orchestrator
│   ├── agents/            engineer, manager, reviewer
│   ├── inception/         spec, design                              (WHAT/WHY)
│   ├── construction/      plan, build, test, eval, review,
│   │                      security, e2e, ship                       (HOW)
│   ├── operations/        operate, retro, investigate, daily-report (RUN)
│   ├── rules/             7 canonical rule bodies (single source of truth)
│   ├── common/            decision-gates.md, session-lifecycle.md
│   └── examples/          feature-spec, feature-list, eval-suite,
│                          adr, threat-model, e2e-test-plan, postmortem
├── memory/                Tool-agnostic handoff state
│   ├── progress.md        Decisions, last/next session, known issues
│   └── feature-list.json  Incremental feature backlog
├── .claude/               Claude Code adapters (frontmatter + pointers, no duplicated content)
│   ├── rules/             7 .md pointers (paths: frontmatter) → aidlc/rules/
│   ├── agents/            engineer · manager · reviewer → aidlc/agents/
│   ├── skills/            14 slash commands → aidlc/{inception,construction,operations}/
│   └── settings.json      Permissions + hooks
├── .cursor/               Cursor adapters (frontmatter + pointers, no duplicated content)
│   ├── rules/             7 .mdc pointers (globs: / alwaysApply:) → aidlc/rules/
│   ├── agents/            engineer · manager · reviewer → aidlc/agents/
│   ├── skills/            14 skills → aidlc/{inception,construction,operations}/
│   ├── hooks/             Hook scripts (e.g. aidlc-session-start.sh)
│   └── hooks.json         Lifecycle hooks (sessionStart, beforeShellExecution)
├── .codex/                Codex CLI adapters
│   ├── config.toml        MCP servers, feature flags
│   └── hooks.json         PreToolUse safety + SessionStart bearings
├── docs/adr/              ADRs (tool-neutral)
└── scripts/audit.sh       Footprint audit
```

---

## Setup

```bash
git clone https://github.com/ianchan0817/aidlc-template.git my-project
cd my-project && rm -rf .git && git init
```

1. **Stack** — edit `aidlc/rules/tech-stack.md` (single source; all three tools point at it).
2. **Bootstrap** — `cp init.sh.example init.sh` and fill install / dev / smoke commands. Mirror them in `AGENTS.md` `## How to Run`.
3. **Memory** — `memory/progress.md` and `memory/feature-list.json` ship as empty templates. Set Current Focus once.
4. **Audit** — `bash scripts/audit.sh`. Expected: ~8–9k words total. Warns if root >1500 or canonical >8000.
5. **Open** —

   | Tool | Command |
   |------|---------|
   | Claude Code | `claude` (auto-loads `CLAUDE.md`) |
   | Codex CLI | `codex` (auto-loads `AGENTS.md`) |
   | Cursor | open the directory |

---

## Workflow

```
spec → design (if UI) → plan (+ sprint contract) → build (one feature/slice)
     → test → eval (if AI features) → review → security → e2e → ship
     → operate → retro (+ harness review)
```

Each phase has a gate before the next. Use `aidlc/common/decision-gates.md` (structured A/B/C/D + `[Answer]:`) when explicit human approval is needed.

In Claude Code and Cursor: invoke as slash commands (`/spec`, `/build`, `/eval`, …). In Codex: reference the phase file directly.

---

## Hooks

Deterministic enforcement — actions that must happen, not requests.

| Tool | File | Events |
|------|------|--------|
| Claude Code | [`.claude/settings.json`](.claude/settings.json) | `SessionStart`, `PreToolUse`, `PostToolUse` |
| Codex CLI | [`.codex/hooks.json`](.codex/hooks.json) | Same names; requires `[features] codex_hooks = true` |
| Cursor | [`.cursor/hooks.json`](.cursor/hooks.json) | `sessionStart`, `beforeShellExecution`, `afterFileEdit`, … |

Two hooks ship out of the box per tool:

1. **Session-start bearings** — injects the get-bearings reminder pointing at `aidlc/common/session-lifecycle.md`.
2. **Dangerous-command guard** — rejects `rm -rf /`, `chmod -R 777 /`, `git push --force` to main.

Extend as needed (format-on-save, pre-completion checklists, loop detection).

---

## Personal vs project layering

| Layer | Location | Purpose |
|-------|----------|---------|
| **Project** | `./CLAUDE.md`, `./AGENTS.md`, `./.claude/`, `./.cursor/`, `./.codex/`, `./aidlc/`, `./memory/` | Team conventions and methodology — committed |
| **Personal** | `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.cursor/rules/` | Individual preferences across all projects — not committed |

Project layer dictates *what the codebase requires*. Personal layer dictates *how you prefer to work*. Tools merge both; project rules win on conflicts.

> **Constitution, not prompts.** Treat each layer as durable infrastructure, not a one-off prompt. Bloating a layer with conversational corrections is anti-pattern — extract them into rules, skills, or hooks. (Framing from [Brij Kishore Pandey](https://www.linkedin.com/pulse/how-claude-code-becomes-full-engineering-team-brij-kishore-pandey-6eqkf/).)

---

## Examples (`aidlc/examples/`)

Concrete fill-in templates the workflow phases produce:

- `feature-spec.md` — `/spec` output (problem, use cases, RICE, acceptance criteria)
- `feature-list.md` — shape for `memory/feature-list.json`
- `eval-suite.md` — agent-eval task YAML (`/eval`)
- `adr.md` — `/plan` output when an architectural decision is involved
- `threat-model.md` — `/security` (STRIDE table)
- `e2e-test-plan.md` — `/e2e` (journey table + sign-off checklist)
- `postmortem.md` — `/operate` (timeline, root cause, action items)

---

## MCP (external tools)

- **Codex** — `.codex/config.toml` under `[mcp_servers.NAME]`
- **Claude Code** — `claude mcp add` or edit `.claude/settings.json`
- **Cursor** — see Cursor's MCP docs

No MCP servers configured by default — add per project.

---

## Sources

| Source | Concept folded in |
|--------|------------------|
| [AWS AIDLC](https://github.com/awslabs/aidlc-workflows) | Three-phase lifecycle, structured `[Answer]:` decision gates, two-part code planning |
| [Anthropic — Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) | `init.sh` + progress file + JSON feature list, get-bearings, one feature at a time |
| [Anthropic — Harness design for long-running app development](https://www.anthropic.com/engineering/harness-design-long-running-apps) | Generator/evaluator (folded into reviewer), sprint contracts, runtime QA, harness-review cadence |
| [Anthropic — Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) | Tasks/trials/graders, capability vs regression, transcript review, calibrated LLM-as-judge |
| [OpenAI — Unrolling the Codex agent loop](https://openai.com/index/unrolling-the-codex-agent-loop/) | Layered project docs, sandbox/approval context, compact and stable adapter loading |
| [LangChain — Harness engineering](https://www.langchain.com/blog/improving-deep-agents-with-harness-engineering) | Build-verify loop, context onboarding, traces as feedback, loop detection as future hook extension |
| [Martin Fowler — Harness engineering for coding agent users](https://martinfowler.com/articles/harness-engineering.html) | Feedforward guides, feedback sensors, harness templates, quality-left framing |
| [Learn Harness Engineering](https://github.com/walkinglabs/learn-harness-engineering) | Five-subsystem harness shape: instructions, state, verification, scope, lifecycle |
| [Metaflow](https://github.com/Netflix/metaflow) | Human-centric framing; reproducibility-as-default |
| [Kedro](https://github.com/kedro-org/kedro) | Modular phase-based structure |
| [ZenML](https://github.com/zenml-io/zenml) | Stage gates with explicit pass/fail criteria |
| [Made-With-ML](https://github.com/GokuMohandas/Made-With-ML) | End-to-end iteration loop (operate → retro) |
| [awesome-production-ML](https://github.com/EthicalML/awesome-production-machine-learning) | Operations phase emphasis |
| [agent-skills](https://github.com/addyosmani/agent-skills) | Anti-rationalization framing (kept lightweight) |

---

## License

MIT
