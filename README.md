# aidlc-template

Tool-agnostic AI Development Lifecycle (AIDLC) template for **Claude Code**, **OpenAI Codex CLI**, and **Cursor IDE**. One canonical methodology, three thin native adapters, harness patterns for long-running agentic work.

Built from AWS Labs' AIDLC, Anthropic's harness/evals/context-engineering research, and the harness-engineering literature — full credits in [Sources](#sources).

**Contents:** [Why](#why) · [Quick start](#quick-start--5-minutes) · [Architecture](#architecture) · [Daily workflow](#daily-workflow) · [Guardrails & sensors](#guardrails--sensors) · [Reference](#reference) · [Sources](#sources)

---

## Why

**Agentic templates are usually tool-locked.** Pick `.claude/` and you can't share with Codex; pick `.cursor/` and Claude Code starts from scratch. The methodology is identical — review code, write tests, deploy carefully — but the wiring isn't portable.

**This template separates methodology from wiring.** Methodology lives once in `aidlc/`; each tool has a thin adapter directory pointing at it via repo-rooted paths. It also bakes in long-running-agent research: a structured **session lifecycle**, a JSON **feature backlog**, **sprint contracts** between engineer and reviewer, and a dedicated **eval phase** for AI behavior.

**Four commitments**, enforced by CI where possible:

| Commitment | Meaning |
|------------|---------|
| Single source of truth | Everything lives once in `aidlc/`; adapters are pointers, not copies |
| Model + tool agnostic | `model: inherit` only, repo-rooted paths only — both are CI-failing audit sensors |
| Adapters that actually load | Every skill, agent, and rule pointer is checked against its tool's real loader format, in CI |
| Scoped work | One feature/slice per session, tied to a verifiable sprint contract |
| Sensors over confidence | Tests, hooks, evals, review — never self-reported "done" |
| Human in the loop | Gated decisions are written questions with recorded answers, not chat that scrolls away |

The harness is five-part: **Instructions** (focused files, no giant prompt) · **State** (memory + git survive resets) · **Scope** (one committable slice) · **Verification** (tests, hooks, E2E, evals, transcripts, review) · **Lifecycle** (initialize → work → verify → handoff → commit).

---

## Quick start — 5 minutes

```bash
git clone https://github.com/ianchan0817/aidlc-template.git my-project
cd my-project && rm -rf .git && git init
```

1. **Pick your tool(s).** Using only one of Claude Code / Codex / Cursor? Delete the other adapter dirs (`.claude/`, `.codex/`, `.cursor/`) — `aidlc/`, `AGENTS.md`, and `memory/` work standalone.
2. **Fill in your stack** — `aidlc/rules/tech-stack.md` (one place; every tool points at it).
3. **Bootstrap** — `cp init.sh.example init.sh`, add install / dev / smoke commands.
4. **Seed memory** — set `Current Focus` in `memory/progress.md`. Leave `memory/feature-list.json` empty; `/spec` appends items.
5. **Audit** — `bash scripts/audit.sh` (word budgets + structural checks; also runs in CI on every push).
6. **Open in your tool:**

   | Tool | Command | Auto-loads |
   |------|---------|-----------|
   | Claude Code | `claude` | `CLAUDE.md` (imports `AGENTS.md`) |
   | Codex CLI | `codex` | `AGENTS.md` (hierarchical) |
   | Cursor | open the directory | `.cursor/rules/*.mdc` |

7. **First feature** — `/spec`, then `/plan` → `/build` → `/test` → `/review` → `/ship`.

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
   rules · agents       rules · agents        skills · config
   skills · settings    skills · hooks        hooks
   (Claude Code)        (Cursor IDE)          (Codex CLI)

       memory/progress.md        memory/feature-list.json
            (handoff)                  (backlog)
```

- Adapters never use `../../` chains — every reference is repo-rooted (e.g. `aidlc/agents/engineer.md`), so moving files never breaks references. Enforced by `scripts/audit.sh`.
- Rules live once in [`aidlc/rules/`](aidlc/rules/); `.claude/rules/*.md` (`paths:` frontmatter) and `.cursor/rules/*.mdc` (`globs:`/`alwaysApply:`) are thin pointers in each tool's native format.
- Commands live once in `aidlc/{inception,construction,operations}/`; each tool gets a `skills/<name>/SKILL.md` pointer. All three tools converged on the same [Agent Skills](https://agentskills.io) directory layout, so the pointer bodies are byte-identical — only the parent directory differs.
- Keep root instructions compact and stable; deep methodology stays under `aidlc/` and loads on demand.

> **Adapters are only real if the tool loads them.** Every tool silently ignores a malformed adapter — a flat `skills/spec.md` produces no `/spec` and no error, an agent file without `name:` never registers. The audit checks adapter *shape*, not just existence, so a dead pointer fails CI instead of failing quietly at 2am.

---

## Daily workflow

```
Inception (WHAT/WHY)  →  Construction (HOW)  →  Operations (RUN)
       gate                    gate                  gate
```

Each command is one canonical file in `aidlc/{inception,construction,operations}/`, surfaced in all three tools as `/slash` commands via `<tool>/skills/<name>/SKILL.md`. You can always open the canonical file directly — slash commands are convenience, not requirement.

### Commands

| Command | Phase | When to use |
|---------|-------|-------------|
| `/spec` | Inception | New feature/initiative — problem, use cases, RICE, acceptance criteria |
| `/design` | Inception | The feature has UI — component specs, mobile, interaction |
| `/plan` | Construction | Spec approved — architecture, task breakdown, sprint contract |
| `/build` | Construction | Contract agreed — incremental TDD on one feature/slice |
| `/test` | Construction | Coverage strategy — 100% on new/modified code |
| `/eval` | Construction | Change touches AI/agent behavior (tools, prompts, multi-turn) |
| `/review` | Construction | Ready for merge — two-pass code review |
| `/security` | Construction | Touches auth, data, file upload, external APIs, or crypto |
| `/e2e` | Construction | Before release — journey verification + sign-off |
| `/ship` | Construction | All gates green — land the branch |
| `/operate` | Operations | Just deployed / incident / 24h post-deploy check |
| `/investigate` | Operations | Bug or failure — root cause first, no symptom patches |
| `/daily-report` | Operations | Manager's daily executive summary |
| `/retro` | Operations | Sprint end, or after a major model/tool upgrade |

### Common scenarios

| Situation | Sequence |
|-----------|----------|
| New feature | `/spec` → `/design` (if UI) → `/plan` → `/build` → `/test` → `/review` → `/e2e` → `/ship` → `/operate` |
| New **AI/LLM** feature | …same, plus `/eval` between `/test` and `/review` |
| Auth/data/API change | …same, plus `/security` before `/e2e` |
| Bug report | `/investigate` → `/build` (fix + regression test) → `/test` → `/review` → `/ship` |
| Production incident | `/operate` (mitigate) → `/investigate` (root cause) → fix loop → `/operate` (postmortem) |
| Daily standup | `/daily-report` |
| Sprint end / model upgrade | `/retro` (harness review — strip stale scaffolding) |

Each phase has a gate. When explicit human approval is needed, use [`aidlc/common/decision-gates.md`](aidlc/common/decision-gates.md) — structured A/B/C/D questions with `[Answer]:` lines, stored in `memory/decisions/` as the audit trail.

### Roles

Definitions in [`aidlc/agents/`](aidlc/agents/):

- **engineer** — implementation, architecture, DB, CI/CD; one slice at a time. The approved spec is **immutable mid-build**: contradiction → halt and escalate, never bend the spec to fit the code.
- **reviewer** — code review, security (STRIDE), runtime QA, agent evals, sprint-contract approval, E2E sign-off. Only the reviewer flips `passes: true`. Runs in a **fresh context** (own subagent or session): a context that just wrote the code already believes its own reasoning.
- **manager** — orchestrate, daily reports, harness-review cadence after model/tool upgrades.

---

## Guardrails & sensors

### Session lifecycle

Every session runs the same loop so work survives context resets — canonical: [`aidlc/common/session-lifecycle.md`](aidlc/common/session-lifecycle.md), reinforced by each tool's `SessionStart` hook.

| Start | Work | End |
|-------|------|-----|
| Read `memory/progress.md` | Sprint contract w/ reviewer | Commit |
| Read `memory/feature-list.json` | One feature/slice | Update `memory/progress.md` |
| `git log --oneline -20` | TDD red→green→refactor | Leave merge-ready |
| Run `./init.sh` smoke | Runtime QA via reviewer | Reviewer flips `passes` |

Four self-healing rules:

- **Reconcile on start** — cross-check `memory/` claims against the repo (files exist, tests pass, git agrees). On mismatch, trust the repo and correct the memory file.
- **Broken smoke = the slice** — if `./init.sh` fails, fixing the baseline *is* this session's work.
- **Compact before you lose it** — when context degrades (half the window gone, **two corrections on the same point**, re-asked questions): write durable state to `memory/` *first*, then compact/clear, then re-enter through get-bearings. Anything not in a file is lost. A third correction almost never lands — by then the failed approaches *are* the context.
- **Name the check that says "done"** — an agent stops when the work looks finished, so decide in advance what produces the pass/fail and how hard it gates. Four tiers, weakest to strongest, in [`aidlc/common/session-lifecycle.md`](aidlc/common/session-lifecycle.md).

State artifacts:

| File | Holds |
|------|-------|
| [`memory/progress.md`](memory/progress.md) | Current Focus / Last / Next / Decisions / Open Questions / Known Issues |
| [`memory/feature-list.json`](memory/feature-list.json) | Backlog `{id, description, steps, verify, spec, passes, verified_sha}` — engineers append; reviewer flips `passes` and stamps `verified_sha`, so a pass goes stale if code changes underneath it |
| [`memory/plans/`](memory/plans/) | Two-part execution plans (plan → approve → execute with same-turn checkboxes) |
| [`memory/decisions/`](memory/decisions/) | `[Answer]:` question files — audit trail for gated decisions |
| [`init.sh.example`](init.sh.example) | Copy to `init.sh` — env bootstrap + smoke |

### Know your unknowns

The map is not the territory — the gap is your unknowns, and pre-implementation is the cheapest place to find them. [`aidlc/common/unknowns.md`](aidlc/common/unknowns.md) catalogs 11 elicitation moves, wired into their phases:

| Phase | Moves |
|-------|-------|
| `/spec` | **Interview** (agent asks, blast-radius order) · **intervention brainstorm** (S/M/L/XL options from real code) |
| `/design` | **Design directions** (react to 3–4 incompatible renders) · **mock before wiring** (fake data, click it first) |
| `/plan` | **Blindspot pass** (unknown unknowns in unfamiliar code) · **semantics map** (prove reference comprehension before porting) · **tweakable plan** (decisions ordered by volatility, each with a reversal trigger) |
| `/build` | **Implementation notes** (typed deviation log → fold-back bullets feed the next plan) |
| `/review` | **Change quiz** (verified comprehension for high-blast-radius merges) |
| `/ship` | **Buy-in doc** (demo first, pre-answered objections, named sign-offs) |
| `/retro` | Repeated deviations = guide gap or sensor gap — fix the harness |

### Agent evals vs code tests

Tests cover code paths; evals cover agent behavior. Details: [`aidlc/construction/eval.md`](aidlc/construction/eval.md) · task format: [`aidlc/examples/eval-suite.md`](aidlc/examples/eval-suite.md).

| Aspect | Tests (`/test`) | Evals (`/eval`) |
|--------|-----------------|-----------------|
| Subject | Code paths | Agent transcripts + outcomes |
| Graders | Deterministic asserts | Code + LLM-judge + human spot-checks |
| Suites | Unit / integration / E2E | Capability vs regression |
| When | Every change | When AI features ship or change |

Start with 20–50 real failures. Read transcripts on every failed run. Calibrate LLM-as-judge against humans. Gate releases on pass^k (all k trials), not pass@k.

### Hooks

Deterministic enforcement — actions that must happen, not requests. Two ship per tool: **session-start bearings** (injects the get-bearings reminder) and a **dangerous-command guard** (`rm -rf /`, `chmod -R 777 /`, force-push to main/master, `git reset --hard`). The guard reads the tool's actual hook payload (stdin JSON) — not an environment variable, which never fires.

| Tool | File | Events |
|------|------|--------|
| Claude Code | [`.claude/settings.json`](.claude/settings.json) | `SessionStart`, `PreToolUse` |
| Codex CLI | [`.codex/hooks.json`](.codex/hooks.json) | Same names; needs `[features] codex_hooks = true` |
| Cursor | [`.cursor/hooks.json`](.cursor/hooks.json) | `sessionStart`, `beforeShellExecution`, … |

**No completion gate ships on purpose.** A `Stop`/pre-completion hook that blocks the turn until tests pass is the strongest sensor available — and the one thing a template cannot ship, because it would fire on every turn of a repo that has no test command yet. Wire it per project once `./init.sh` reliably passes on a clean tree, and give it a bypass for the session that fixes the check itself. The four gating tiers, weakest to strongest, are in [`aidlc/common/session-lifecycle.md`](aidlc/common/session-lifecycle.md) → *Close the loop on "done"*.

Extend as needed (format-on-save, loop detection). If you add a hook, verify it actually fires — the audit checks JSON validity, but only a live test proves the guard blocks.

### AI-friendly test output

Raw terminal output is hostile to model context: ANSI codes fracture tokenization, progress bars flood via `\r`, one exception can emit a 300-line stack trace. [`scripts/agent-test.sh`](scripts/agent-test.sh) wraps any test command:

```bash
scripts/agent-test.sh bun test        # or pytest, cargo test, go test ...
```

PASS/FAIL + exit code first · ANSI/OSC stripped · stack traces truncated (default 50, `AGENT_TEST_MAX_TRACE`) · output capped (default 400, `AGENT_TEST_MAX_LINES`) · untouched per-run raw log preserved (parallel-safe) · exit code passes through, so it works in CI and hooks.

### Template CI

`bash scripts/audit.sh` (also on every push/PR via `.github/workflows/`). Exits non-zero on structural failure.

| Check | Catches |
|-------|---------|
| Word budgets (root <1500, canonical <8000) | Instruction bloat, which degrades adherence |
| JSON validity of hook configs | A syntax error that silently disables a safety hook |
| Broken internal references | Pointers to files that moved or never existed |
| No hardcoded model IDs (`model: inherit` only) | Adapters pinned to a model that will be deprecated |
| No `../` path chains | References that break when a file moves |
| Shell-script syntax (`bash -n`) | A sensor script that can't run |
| **Skill shape** — `<tool>/skills/<name>/SKILL.md`, `name`+`description`, identical set across tools | Flat `skills/foo.md` files no tool loads; a command that exists in one tool only |
| **Agent shape** — `name`+`description` in every agent file | A subagent that never registers |
| **Rule parity** — every `aidlc/rules/*.md` has a pointer per tool | A rule enforced in Cursor but invisible in Claude Code |

---

## Reference

### Directory structure

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
│   ├── rules/             7 canonical rule bodies
│   ├── common/            decision-gates, session-lifecycle, unknowns
│   └── examples/          feature-spec, feature-list, eval-suite, adr,
│                          threat-model, e2e-test-plan, implementation-notes,
│                          postmortem
├── memory/                Tool-agnostic handoff state
│   ├── progress.md        Decisions, last/next session, known issues
│   ├── feature-list.json  Backlog (append-only, verified_sha)
│   ├── plans/             Two-part execution plans
│   └── decisions/         [Answer]: decision-gate files (audit trail)
├── .claude/               Claude Code adapters (pointers, no duplicated content)
│   ├── rules/  agents/                  → aidlc/
│   ├── skills/<name>/SKILL.md           → aidlc/<phase>/<name>.md
│   └── settings.json      Permissions + hooks (stdin-JSON guard)
├── .cursor/               Cursor adapters (pointers, no duplicated content)
│   ├── rules/  agents/  hooks/          → aidlc/
│   ├── skills/<name>/SKILL.md           → aidlc/<phase>/<name>.md
│   └── hooks.json         sessionStart + beforeShellExecution
├── .codex/                Codex CLI adapters
│   ├── skills/<name>/SKILL.md           → aidlc/<phase>/<name>.md
│   ├── config.toml        MCP servers, feature flags
│   └── hooks.json         PreToolUse guard + SessionStart bearings
├── .github/workflows/     CI — audit.sh on every push/PR
├── docs/adr/              ADRs (tool-neutral)
└── scripts/
    ├── audit.sh           Footprint + structural audit
    └── agent-test.sh      AI-friendly test sensor
```

### Examples (`aidlc/examples/`)

Fill-in templates for what each phase produces — documentation, not auto-loaded.

**Always useful:** `feature-spec.md` (`/spec` output) · `feature-list.md` (backlog shape) · `e2e-test-plan.md` (journey table + sign-off).

**Conditional:** `adr.md` (`/plan`, architectural decisions) · `threat-model.md` (`/security`, STRIDE) · `eval-suite.md` (`/eval`, AI features) · `implementation-notes.md` (`/build` deviation log) · `postmortem.md` (`/operate`, Critical/High incidents).

### Personal vs project layering

| Layer | Location | Purpose |
|-------|----------|---------|
| **Project** | `./AGENTS.md`, `./CLAUDE.md`, `./aidlc/`, adapter dirs, `./memory/` | Team conventions and methodology — committed |
| **Personal** | `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.cursor/rules/` | Your preferences across all projects — not committed |

Project layer dictates *what the codebase requires*; personal layer dictates *how you prefer to work*. Tools merge both; project wins on conflict.

> **Constitution, not prompts.** Treat each layer as durable infrastructure. Bloating a layer with conversational corrections is the anti-pattern — extract them into rules, skills, or hooks. (Framing: [Brij Kishore Pandey](https://www.linkedin.com/pulse/how-claude-code-becomes-full-engineering-team-brij-kishore-pandey-6eqkf/).)

### MCP (external tools)

- **Codex** — `.codex/config.toml` under `[mcp_servers.NAME]`
- **Claude Code** — `claude mcp add` or edit `.claude/settings.json`
- **Cursor** — see Cursor's MCP docs

None configured by default — add per project.

---

## Sources

| Source | Concept folded in |
|--------|------------------|
| [AWS AIDLC](https://github.com/awslabs/aidlc-workflows) (incl. 2.0 GA) | Three-phase lifecycle, structured `[Answer]:` decision gates, two-part code planning, adaptive stage selection (run/skip with rationale), human-in-the-loop tenet |
| [Anthropic — Claude Code best practices](https://code.claude.com/docs/en/best-practices) | Give the agent a check it can run; four gating tiers for "done"; fresh-context adversarial review and its over-reporting caveat; two-corrections-then-clear |
| [Agent Skills standard](https://agentskills.io) | `skills/<name>/SKILL.md` as the one adapter layout all three tools load |
| [OpenAI — Harness engineering](https://openai.com/index/harness-engineering/) | Agent-first harness framing behind the guide/sensor split |
| [Anthropic — Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) | `init.sh` + progress file + JSON feature list, get-bearings, one feature at a time |
| [Anthropic — Harness design for long-running app development](https://www.anthropic.com/engineering/harness-design-long-running-apps) | Generator/evaluator (folded into reviewer), sprint contracts, runtime QA, harness-review cadence |
| [Anthropic — Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) | Tasks/trials/graders, capability vs regression, pass@k vs pass^k, transcript review, calibrated LLM-as-judge |
| [Anthropic — Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) | Session-start reconciliation (trust the repo over stale memory), just-in-time retrieval, compaction protocol |
| [Anthropic — Writing tools for agents](https://www.anthropic.com/engineering/writing-tools-for-agents) | Agent-friendly test output (`scripts/agent-test.sh`) |
| [OpenAI — Unrolling the Codex agent loop](https://openai.com/index/unrolling-the-codex-agent-loop/) | Layered project docs, sandbox/approval context, compact and stable adapter loading |
| [LangChain — Harness engineering](https://www.langchain.com/blog/improving-deep-agents-with-harness-engineering) | Build-verify loop, context onboarding, traces as feedback, loop detection as future hook extension |
| [Martin Fowler — Harness engineering for coding agent users](https://martinfowler.com/articles/harness-engineering.html) | Feedforward guides, feedback sensors, harness templates, quality-left framing |
| [Learn Harness Engineering](https://github.com/walkinglabs/learn-harness-engineering) | Five-subsystem harness shape: instructions, state, verification, scope, lifecycle; loop engineering (generator/evaluator split, goal loops) |
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
