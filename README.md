# aidlc-template

Tool-agnostic AI Development Lifecycle (AIDLC) template for **Claude Code**, **OpenAI Codex CLI**, and **Cursor IDE**. One canonical methodology, three native adapters, harness patterns for long-running agentic work.

> Inspired by [AWS Labs AIDLC](https://github.com/awslabs/aidlc-workflows) (3-phase lifecycle, decision gates), [Anthropic harness research](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) (initializer + coding agent, feature list), [Anthropic evals guide](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) (tasks/graders/transcripts, pass@k), [Anthropic context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) (session reconciliation, just-in-time retrieval), [Anthropic — writing tools for agents](https://www.anthropic.com/engineering/writing-tools-for-agents) (agent-friendly test output), [Anthropic harness design](https://www.anthropic.com/engineering/harness-design-long-running-apps) (generator/evaluator, sprint contracts), [OpenAI Codex loop](https://openai.com/index/unrolling-the-codex-agent-loop/) (instruction layering, sandbox/context handling), [LangChain harness engineering](https://www.langchain.com/blog/improving-deep-agents-with-harness-engineering) (self-verification, traces), and [Martin Fowler](https://martinfowler.com/articles/harness-engineering.html) / [Learn Harness Engineering](https://github.com/walkinglabs/learn-harness-engineering) (guides, sensors, lifecycle).

---

## Why

Agentic coding templates are usually tool-specific: pick `.claude/` and you can't share with Codex; pick `.cursor/` and Claude Code starts from scratch. The methodology is the same — review code, write tests, deploy carefully — but the wiring isn't portable.

This template separates **methodology** (workflow, rules, roles) from **wiring** (how each tool loads it). Methodology lives in `aidlc/`. Each tool has a thin adapter directory that points at it via repo-rooted paths.

It also bakes in patterns from long-running-agent research: a structured **session lifecycle**, a JSON **feature backlog**, **sprint contracts** between engineer and reviewer, and a dedicated **eval phase** for AI/agent behavior.

Designed around a few simple commitments: **single source of truth** (everything lives once in `aidlc/`), **thin adapters** (tool dirs are pointers, not copies), **scoped work** (one feature/slice at a time), and **sensors over confidence** (tests, hooks, evals, review). The harness is intentionally five-part:

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

## Methodology

```
Inception (WHAT/WHY)  →  Construction (HOW)  →  Operations (RUN)
       gate                    gate                  gate
```

Each phase is one canonical file in `aidlc/{inception,construction,operations}/`. Roles and rules below.

### Commands — when to use each

| Command | Phase | When to use |
|---------|-------|-------------|
| `/spec` | Inception | Starting a new feature or initiative — define problem, use cases, RICE, acceptance criteria |
| `/design` | Inception | The feature has UI — component specs, mobile, interaction patterns |
| `/plan` | Construction | Spec is approved — architecture, task breakdown, sprint contract with reviewer |
| `/build` | Construction | Sprint contract is agreed — incremental TDD on one feature/slice |
| `/test` | Construction | Build is in progress — coverage strategy, enforce 100% on new/modified |
| `/eval` | Construction | The change touches AI/agent behavior (tools, prompts, multi-turn flows) |
| `/review` | Construction | Code is ready for merge — pre-merge two-pass code review |
| `/security` | Construction | The change touches auth, data, file upload, external APIs, or crypto |
| `/e2e` | Construction | Before release — end-to-end journey verification, sign-off |
| `/ship` | Construction | Review + E2E + (security/evals if applicable) all green — land the branch |
| `/operate` | Operations | Just deployed; or an alert/incident fired; or 24h post-deploy check |
| `/investigate` | Operations | A bug, test failure, or unexpected behavior — root-cause first, no symptom patches |
| `/daily-report` | Operations | Manager's daily executive summary (typically morning) |
| `/retro` | Operations | End of sprint / every 2 weeks; or after a major model/tool upgrade |

### How to invoke

| Tool | Mechanism |
|------|-----------|
| Claude Code | Slash command — `/spec`, `/build`, `/eval`, etc. (`.claude/skills/<name>.md` points at `aidlc/<phase>/<name>.md`) |
| Cursor IDE | Skill — `/spec`, `/build`, etc. (`.cursor/skills/<name>.md` points at the same file) |
| Codex CLI | Plain prose — "Follow `aidlc/construction/build.md`". No slash-command system. |

You can always open the canonical file directly and follow it — slash commands are convenience, not requirement.

### Common scenarios

| Situation | Command sequence |
|-----------|------------------|
| New feature | `/spec` → `/design` (if UI) → `/plan` → `/build` → `/test` → `/review` → `/e2e` → `/ship` → `/operate` |
| New **AI/LLM** feature | …same, plus `/eval` between `/test` and `/review` |
| Auth/data/API change | …same, plus `/security` before `/e2e` |
| Bug report | `/investigate` → `/build` (fix + regression test) → `/test` → `/review` → `/ship` |
| Production incident | `/operate` (acknowledge → mitigate) → `/investigate` (root cause) → fix loop → `/operate` (postmortem) |
| Daily standup | `/daily-report` |
| End of sprint / 2 weeks | `/retro` |
| After a major model upgrade | `/retro` (harness review step — strip stale scaffolding) |

Each phase has a gate before the next. Use `aidlc/common/decision-gates.md` (structured A/B/C/D + `[Answer]:`) when explicit human approval is needed.

### Roles

Three roles, definitions in `aidlc/agents/`:

- **engineer** — implementation, architecture, DB, CI/CD; one feature/slice at a time from the backlog.
- **reviewer** — code review, security (STRIDE), runtime QA, agent evals, sprint-contract approval, E2E sign-off.
- **manager** — orchestrate, daily reports, harness-review cadence after model/tool upgrades.

### Rules

Always-on, single source of truth in [`aidlc/rules/*.md`](aidlc/rules/): `code-style`, `testing`, `security`, `api-conventions`, `ux-guidelines`, `reproducibility`, `tech-stack`. `.claude/rules/*.md` and `.cursor/rules/*.mdc` are thin pointers in each tool's native frontmatter format. Decision gates use the structured-question pattern in `aidlc/common/decision-gates.md`.

### Know your unknowns

The map is not the territory — the gap is your unknowns, and pre-implementation is the cheapest place to find them. [`aidlc/common/unknowns.md`](aidlc/common/unknowns.md) catalogs 11 elicitation moves, each wired into its phase:

| Phase | Moves |
|-------|-------|
| `/spec` | **Interview** (agent asks, blast-radius order) · **intervention brainstorm** (S/M/L/XL option space from real code) |
| `/design` | **Design directions** (react to 3–4 incompatible renders) · **mock before wiring** (fake data, click it first) |
| `/plan` | **Blindspot pass** (unknown unknowns in unfamiliar code) · **semantics map** (prove reference comprehension before porting) · **tweakable plan** (decisions ordered by volatility, each with a reversal trigger) |
| `/build` | **Implementation notes** (typed deviation log → fold-back bullets feed the next plan) |
| `/review` | **Change quiz** (verified comprehension for high-blast-radius merges) |
| `/ship` | **Buy-in doc** (demo first, pre-answered objections, named sign-offs) |
| `/retro` | Repeated deviations = guide gap or sensor gap — fix the harness |

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
- [`memory/feature-list.json`](memory/feature-list.json) — incremental backlog (`{id, description, steps, verify, spec, passes, verified_sha}`). Engineers append; only the reviewer flips `passes: true`, stamping `verified_sha` so a pass goes stale if the code changes underneath it.
- [`memory/plans/`](memory/plans/) — per-feature execution plans (two-part: plan, then execute with same-turn checkboxes)
- [`memory/decisions/`](memory/decisions/) — structured `[Answer]:` question files — the audit trail for gated decisions
- [`init.sh.example`](init.sh.example) — copy to `init.sh` for env bootstrap + smoke. A failing smoke **is** the next session's slice, not a thing to work around.

Session-start self-heals: cross-check `memory/` claims against the repo (files exist, tests pass, git agrees). On mismatch, trust the repo and correct the memory file — see `aidlc/common/session-lifecycle.md`.

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
│   ├── feature-list.json  Incremental feature backlog (append-only, verified_sha)
│   ├── plans/             Two-part execution plans (plan → approve → execute)
│   └── decisions/         Structured [Answer]: decision-gate files (audit trail)
├── .claude/               Claude Code adapters (frontmatter + pointers, no duplicated content)
│   ├── rules/             7 .md pointers (paths: frontmatter) → aidlc/rules/
│   ├── agents/            engineer · manager · reviewer → aidlc/agents/
│   ├── skills/            14 slash commands → aidlc/{inception,construction,operations}/
│   └── settings.json      Permissions + hooks (stdin-JSON guard)
├── .cursor/               Cursor adapters (frontmatter + pointers, no duplicated content)
│   ├── rules/             7 .mdc pointers (globs: / alwaysApply:) → aidlc/rules/
│   ├── agents/            engineer · manager · reviewer → aidlc/agents/
│   ├── skills/            14 skills → aidlc/{inception,construction,operations}/
│   ├── hooks/             Hook scripts (e.g. aidlc-session-start.sh)
│   └── hooks.json         Lifecycle hooks (sessionStart, beforeShellExecution)
├── .codex/                Codex CLI adapters
│   ├── config.toml        MCP servers, feature flags
│   └── hooks.json         PreToolUse safety (stdin-JSON guard) + SessionStart bearings
├── .github/workflows/     CI — audit.sh on every push/PR
├── docs/adr/              ADRs (tool-neutral)
└── scripts/audit.sh       Footprint + structural audit (JSON validity, broken refs)
```

---

## New project — 5 minutes

```bash
git clone https://github.com/ianchan0817/aidlc-template.git my-project
cd my-project && rm -rf .git && git init
```

1. **Pick your tool(s).** If you only use one of Claude Code / Codex / Cursor, **delete the other adapter dirs** (`.claude/`, `.codex/`, `.cursor/`). The methodology in `aidlc/` and the entry files (`AGENTS.md`, `memory/`) work standalone.
2. **Edit your stack** — `aidlc/rules/tech-stack.md` (one place; all kept tools point at it).
3. **Bootstrap** — `cp init.sh.example init.sh` and fill install / dev / smoke commands. Record verify commands (test/lint/types) in `aidlc/rules/tech-stack.md`.
4. **Seed memory** — set `Current Focus` in `memory/progress.md`. Leave `memory/feature-list.json` empty (your `/spec` will append items).
5. **Audit** — `bash scripts/audit.sh`. Checks word budget (root <1500, canonical <8000) and structure (valid JSON, no broken internal references); exits non-zero on structural failure. Runs automatically in CI on every push/PR.
6. **Open in your tool** —

   | Tool | Command |
   |------|---------|
   | Claude Code | `claude` (auto-loads `CLAUDE.md`) |
   | Codex CLI | `codex` (auto-loads `AGENTS.md`) |
   | Cursor | open the directory (auto-loads `.cursor/rules/*.mdc`) |

7. **First feature** — `/spec` your first feature, then `/plan` → `/build` → `/test` → `/review` → `/ship`.

---

## Hooks

Deterministic enforcement — actions that must happen, not requests.

| Tool | File | Events |
|------|------|--------|
| Claude Code | [`.claude/settings.json`](.claude/settings.json) | `SessionStart`, `PreToolUse` |
| Codex CLI | [`.codex/hooks.json`](.codex/hooks.json) | Same names; requires `[features] codex_hooks = true` |
| Cursor | [`.cursor/hooks.json`](.cursor/hooks.json) | `sessionStart`, `beforeShellExecution`, `afterFileEdit`, … |

Two hooks ship out of the box per tool:

1. **Session-start bearings** — injects the get-bearings reminder pointing at `aidlc/common/session-lifecycle.md`.
2. **Dangerous-command guard** — rejects `rm -rf /`, `chmod -R 777 /`, `git push --force` to main/master, `git reset --hard`. Reads the command from the tool's actual hook payload (stdin JSON for Claude Code and Codex, piped JSON for Cursor) — not an environment variable, which never fires.

Extend as needed (format-on-save, pre-completion checklists, loop detection). If you add or edit a hook, verify it actually fires — `bash scripts/audit.sh` checks the config is valid JSON, but only a live test confirms the guard blocks what it claims to.

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

Concrete fill-in templates — reference shapes for what each phase produces. They're documentation, not auto-loaded.

**Always useful** (most projects):

- `feature-spec.md` — `/spec` output (problem, use cases, RICE, acceptance criteria)
- `feature-list.md` — shape for `memory/feature-list.json`
- `e2e-test-plan.md` — `/e2e` journey table + sign-off checklist

**Conditional** (only when the situation arises):

- `adr.md` — `/plan` when an architectural decision is involved
- `threat-model.md` — `/security` (STRIDE), only when auth/data/API changes
- `eval-suite.md` — `/eval` task YAML, only for AI/agent features
- `implementation-notes.md` — `/build` deviation log; fold-back bullets feed the next plan
- `postmortem.md` — `/operate` after a Critical/High incident

You don't need to touch any of these to start — phases reference them when relevant.

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
| [Anthropic — Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) | Tasks/trials/graders, capability vs regression, pass@k vs pass^k, transcript review, calibrated LLM-as-judge |
| [Anthropic — Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) | Session-start reconciliation (trust the repo over stale memory), just-in-time retrieval |
| [Anthropic — Writing tools for agents](https://www.anthropic.com/engineering/writing-tools-for-agents) | Agent-friendly test output (greppable one-line failures) |
| [OpenAI — Unrolling the Codex agent loop](https://openai.com/index/unrolling-the-codex-agent-loop/) | Layered project docs, sandbox/approval context, compact and stable adapter loading |
| [LangChain — Harness engineering](https://www.langchain.com/blog/improving-deep-agents-with-harness-engineering) | Build-verify loop, context onboarding, traces as feedback, loop detection as future hook extension |
| [Martin Fowler — Harness engineering for coding agent users](https://martinfowler.com/articles/harness-engineering.html) | Feedforward guides, feedback sensors, harness templates, quality-left framing |
| [Learn Harness Engineering](https://github.com/walkinglabs/learn-harness-engineering) | Five-subsystem harness shape: instructions, state, verification, scope, lifecycle |
| [Know Your Unknowns](https://thariqs.github.io/html-effectiveness/unknowns/) | 11 elicitation moves per phase (`aidlc/common/unknowns.md`): blindspot pass, interview, tweakable plan, implementation notes, change quiz |
| [Metaflow](https://github.com/Netflix/metaflow) | Human-centric framing; reproducibility-as-default |
| [Kedro](https://github.com/kedro-org/kedro) | Modular phase-based structure |
| [ZenML](https://github.com/zenml-io/zenml) | Stage gates with explicit pass/fail criteria |
| [Made-With-ML](https://github.com/GokuMohandas/Made-With-ML) | End-to-end iteration loop (operate → retro) |
| [awesome-production-ML](https://github.com/EthicalML/awesome-production-machine-learning) | Operations phase emphasis |
| [agent-skills](https://github.com/addyosmani/agent-skills) | Anti-rationalization framing (kept lightweight) |

---

## License

MIT
