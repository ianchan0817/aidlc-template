# aidlc-template

[![template-audit](https://github.com/ianchan0817/aidlc-template/actions/workflows/audit.yml/badge.svg)](https://github.com/ianchan0817/aidlc-template/actions/workflows/audit.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Tools: 3](https://img.shields.io/badge/tools-Claude%20Code%20%C2%B7%20Codex%20%C2%B7%20Cursor-blue.svg)](#quick-start)

Tool-agnostic AI Development Lifecycle template for **Claude Code**, **OpenAI Codex CLI**, and **Cursor IDE**. One canonical methodology, three thin adapters, harness patterns for long-running agentic work.

**Jump to:** [Why](#why) · [Quick start](#quick-start) · [Architecture](#architecture) · [Workflow](#daily-workflow) · [Guardrails](#guardrails--sensors) · [Reference](#reference) · [Sources](#sources)

---

## Why

**Agentic templates are usually tool-locked.** Pick `.claude/` and you can't share with Codex; pick `.cursor/` and Claude Code starts from scratch. The methodology is identical — review code, write tests, deploy carefully — but the wiring isn't portable.

**This template separates methodology from wiring.** Methodology lives once in `aidlc/`; each tool gets a thin adapter directory pointing at it via repo-rooted paths. It also bakes in long-running-agent research: a structured session lifecycle, a JSON feature backlog, sprint contracts between engineer and reviewer, and a dedicated eval phase for AI behavior.

Six commitments, enforced by CI where possible:

| Commitment | Meaning |
|---|---|
| Single source of truth | Lives once in `aidlc/`; adapters are pointers |
| Model + tool agnostic | `model: inherit` only, repo-rooted paths only |
| Adapters that load | Every pointer checked against its real loader format |
| Scoped work | One slice per session, tied to a sprint contract |
| Sensors over confidence | Tests, hooks, evals, review — never self-reported |
| Human in the loop | Gated decisions are written, answered, recorded |

The harness is five-part: **Instructions** (focused files, no giant prompt) · **State** (memory + git survive resets) · **Scope** (one committable slice) · **Verification** (tests, hooks, E2E, evals, review) · **Lifecycle** (initialize → work → verify → handoff → commit).

---

## Quick start

```bash
git clone https://github.com/ianchan0817/aidlc-template.git my-project
cd my-project && rm -rf .git && git init
```

1. **Pick your tool(s).** Using only one? Delete the other adapter dirs (`.claude/`, `.codex/`, `.cursor/`) — `aidlc/`, `AGENTS.md`, and `memory/` work standalone.
2. **Fill in your stack** — `aidlc/rules/tech-stack.md` (one place; every tool points at it).
3. **Bootstrap** — `cp init.sh.example init.sh`, add install / dev / smoke commands.
4. **Seed memory** — set `Current Focus` in `memory/progress.md`. Leave `memory/feature-list.json` empty; `/spec` appends items.
5. **Audit** — `bash scripts/audit.sh` (budgets + structure; also runs in CI).
6. **Open it** — `claude` loads `CLAUDE.md`; `codex` loads `AGENTS.md`; Cursor loads `.cursor/rules/*.mdc`.
7. **First feature** — `/spec`, then `/plan` → `/build` → `/test` → `/review` → `/ship`.

---

## Architecture

```
        ┌────────────────────────────┐
        │ aidlc/ (canonical, shared) │
        │ agents · phases · examples │
        └─────────────┬──────────────┘
                      │ repo-rooted refs
      ┌───────────────┼───────────────┐
      ▼               ▼               ▼
  .claude/        .cursor/        .codex/
  rules           rules           skills
  agents          agents          config
  skills          skills          hooks
  settings        hooks

  memory/progress.md   memory/feature-list.json
      (handoff)             (backlog)
```

- **Repo-rooted paths only** — no `../../` chains, so moving a file never breaks a reference. Enforced by `scripts/audit.sh`.
- **Rules live once** in [`aidlc/rules/`](aidlc/rules/). `.claude/rules/*.md` (`paths:`) and `.cursor/rules/*.mdc` (`globs:`/`alwaysApply:`) are thin pointers in each tool's native frontmatter.
- **Commands live once** in `aidlc/{inception,construction,operations}/`. Each tool gets a `skills/<name>/SKILL.md` pointer — all three converged on the same [Agent Skills](https://agentskills.io) layout, so pointer bodies are identical and only the parent directory differs.
- **Keep root instructions compact.** Deep methodology stays under `aidlc/` and loads on demand.

> **An adapter is only real if the tool loads it.** Every tool ignores a malformed adapter *silently* — a flat `skills/spec.md` produces no `/spec` and no error; an agent file without `name:` never registers. The audit checks adapter **shape**, so a dead pointer fails CI instead of failing quietly at 2am.

---

## Daily workflow

```
Inception (WHAT/WHY) → Construction (HOW) → Operations (RUN)
       gate                  gate                gate
```

Each command is one canonical file, surfaced in all three tools as a `/slash` command. You can always open the canonical file directly — slash commands are convenience, not requirement.

### Inception — decide what and why

| Command | Use when |
|---|---|
| `/spec` | New feature; or requirements still ambiguous |
| `/design` | The feature has a user interface |

### Construction — build it

| Command | Use when |
|---|---|
| `/plan` | Spec approved, before any code |
| `/build` | Contract agreed — TDD on one slice |
| `/test` | Auditing or closing coverage gaps |
| `/eval` | Change touches AI/agent behavior |
| `/review` | Ready for merge — two-pass review |
| `/security` | Auth, data, upload, external API, crypto |
| `/e2e` | Before release — journeys + sign-off |
| `/ship` | All gates green — land the branch |

### Operations — run it

| Command | Use when |
|---|---|
| `/operate` | Post-deploy, incident, or 24h check |
| `/investigate` | Bug or failure — root cause first |
| `/daily-report` | Standup or status roll-up |
| `/retro` | Sprint end, or after a model upgrade |

### Common paths

- **New feature** — `/spec` → `/design`\* → `/plan` → `/build` → `/test` → `/review` → `/e2e` → `/ship` → `/operate`
- **AI/LLM feature** — the same, plus `/eval` between `/test` and `/review`
- **Auth/data change** — the same, plus `/security` before `/e2e`
- **Bug report** — `/investigate` → `/build` → `/test` → `/review` → `/ship`
- **Incident** — `/operate` → `/investigate` → fix → `/operate`

\* if it has UI. Each phase has a gate. When explicit human approval is needed, use [`aidlc/common/decision-gates.md`](aidlc/common/decision-gates.md) — A/B/C/D questions with `[Answer]:` lines, stored in `memory/decisions/` as the audit trail.

### Roles

Definitions in [`aidlc/agents/`](aidlc/agents/):

- **engineer** — implementation, architecture, DB, CI/CD; one slice at a time. The approved spec is **immutable mid-build**: on contradiction, halt and escalate — never bend the spec to fit the code.
- **reviewer** — code review, security (STRIDE), runtime QA, agent evals, sprint-contract approval, E2E sign-off. Only the reviewer flips `passes: true`. Runs in a **fresh context** (own subagent or session): a context that just wrote the code already believes its own reasoning.
- **manager** — orchestration, daily reports, harness-review cadence after model or tool upgrades.

---

## Guardrails & sensors

### Session lifecycle

Every session runs the same loop so work survives context resets. Canonical: [`aidlc/common/session-lifecycle.md`](aidlc/common/session-lifecycle.md), reinforced by each tool's `SessionStart` hook.

- **Start** — read `memory/progress.md`, read `memory/feature-list.json`, `git log --oneline -20`, run the `./init.sh` smoke.
- **Work** — agree the sprint contract with the reviewer, take one slice, TDD red/green/refactor, runtime QA.
- **End** — commit, update `memory/progress.md`, leave merge-ready; the reviewer flips `passes`.

Four self-healing rules:

- **Reconcile on start** — cross-check `memory/` claims against the repo (files exist, tests pass, git agrees). On mismatch, trust the repo and correct the memory file.
- **Broken smoke = the slice** — if `./init.sh` fails, fixing the baseline *is* this session's work.
- **Compact before you lose it** — when context degrades (half the window gone, two corrections on the same point, re-asked questions): write durable state to `memory/` *first*, then compact, then re-enter through get-bearings. Anything not in a file is lost. A third correction almost never lands — by then the failed approaches *are* the context.
- **Name the check that says "done"** — an agent stops when work *looks* finished, so decide in advance what produces the pass/fail and how hard it gates. Four tiers, weakest to strongest, in the session-lifecycle file.

State artifacts:

- [`memory/progress.md`](memory/progress.md) — Current Focus, Last/Next session, Decisions, Open Questions, Known Issues.
- [`memory/feature-list.json`](memory/feature-list.json) — backlog of `{id, description, steps, verify, spec, passes, verified_sha}`. Engineers append; the reviewer flips `passes` and stamps `verified_sha`, so a pass goes stale if code changes underneath it.
- [`memory/plans/`](memory/plans/) — two-part execution plans: plan, approve, then execute with same-turn checkboxes.
- [`memory/decisions/`](memory/decisions/) — `[Answer]:` question files; the audit trail for gated decisions.
- [`init.sh.example`](init.sh.example) — copy to `init.sh` for env bootstrap and smoke test.

### Know your unknowns

The map is not the territory — the gap is your unknowns, and pre-implementation is the cheapest place to find them. [`aidlc/common/unknowns.md`](aidlc/common/unknowns.md) catalogs 11 elicitation moves, wired into their phases:

- **`/spec`** — *interview* (agent asks, blast-radius order) · *intervention brainstorm* (S/M/L/XL options drawn from real code)
- **`/design`** — *design directions* (react to 3–4 incompatible renders) · *mock before wiring* (fake data, click it first)
- **`/plan`** — *blindspot pass* (unknown unknowns in unfamiliar code) · *semantics map* (prove comprehension before porting) · *tweakable plan* (decisions ordered by volatility, each with a reversal trigger)
- **`/build`** — *implementation notes* (typed deviation log; fold-back bullets feed the next plan)
- **`/review`** — *change quiz* (verified comprehension for high-blast-radius merges)
- **`/ship`** — *buy-in doc* (demo first, pre-answered objections, named sign-offs)
- **`/retro`** — repeated deviations mean a guide gap or a sensor gap; fix the harness

### Agent evals vs code tests

Tests cover code paths; evals cover agent behavior. Details in [`aidlc/construction/eval.md`](aidlc/construction/eval.md); task format in [`aidlc/examples/eval-suite.md`](aidlc/examples/eval-suite.md).

| Aspect | Tests → Evals |
|---|---|
| Subject | Code paths → agent transcripts + outcomes |
| Graders | Deterministic asserts → code, LLM-judge, human |
| Suites | Unit/integration/E2E → capability vs regression |
| Cadence | Every change → when AI features change |

Start with 20–50 real failures. Read transcripts on every failed run. Calibrate LLM-as-judge against humans. Gate releases on pass^k (all k trials), not pass@k.

### Hooks

Deterministic enforcement — actions that must happen, not requests. Two ship per tool: **session-start bearings** (injects the get-bearings reminder) and a **dangerous-command guard**.

| Tool | Config file |
|---|---|
| Claude Code | [`.claude/settings.json`](.claude/settings.json) |
| Codex CLI | [`.codex/hooks.json`](.codex/hooks.json) |
| Cursor | [`.cursor/hooks.json`](.cursor/hooks.json) |

The matching logic lives in one place — [`scripts/guard-command.sh`](scripts/guard-command.sh) — and each tool's hook only extracts the command and forwards the exit code. It previously lived inline in all three configs and **drifted**: the Codex copy lost its `jq` extraction and started matching the raw JSON payload, blocking benign commands whose working directory happened to contain a match. One file, self-tested against [`scripts/guard-cases.tsv`](scripts/guard-cases.tsv) on every audit run, cannot drift.

It blocks recursive force-deletes of root paths (every flag spelling: `-rf`, `-fr`, `-r -f`, `--recursive --force`), force-push (`--force` and `-f`, while allowing `--force-with-lease`), `chmod -R 777`, `git reset --hard`, `DROP`/`TRUNCATE`/unbounded `DELETE`, and reads of `.env` — while leaving `.env.example` usable, because a guard that blocks day-one setup is a guard people delete. Flags and targets are matched **per command segment**, so `rm -rf ./build && ls /usr/local` is allowed while `cd /tmp && rm -rf /` is not. It fails **closed**: if `jq` is missing or the payload shape changes, the command is blocked rather than waved through.

> **A Bash allow-list is a convenience boundary, not a security boundary.** `permissions.allow` entries like `Bash(python *)` permit arbitrary code, so no `Read(.env)` deny can stop `python -c "open('.env')"`. That is why the secret-file check lives in the guard hook, which sees the actual command. Treat the allow-list as "don't prompt me for this", and the hook as the enforcement layer.

**No completion gate ships, on purpose.** A `Stop`/pre-completion hook that blocks the turn until tests pass is the strongest sensor available — and the one thing a template cannot ship, because it would fire on every turn of a repo that has no test command yet. Wire it per project once `./init.sh` reliably passes on a clean tree, and give it a bypass for the session that fixes the check itself.

Extend as needed (format-on-save, loop detection). If you add a hook, verify it actually fires — the audit checks JSON validity, but only a live test proves the guard blocks.

### AI-friendly test output

Raw terminal output is hostile to model context: ANSI codes fracture tokenization, progress bars flood via `\r`, one exception can emit a 300-line stack trace. [`scripts/agent-test.sh`](scripts/agent-test.sh) wraps any test command:

```bash
scripts/agent-test.sh bun test      # or pytest, go test …
```

PASS/FAIL and exit code first · ANSI/OSC stripped · stack traces truncated (default 50, `AGENT_TEST_MAX_TRACE`) · output capped (default 400, `AGENT_TEST_MAX_LINES`) · untouched per-run raw log preserved, parallel-safe · exit code passes through, so it works in CI and hooks.

### Template CI

`bash scripts/audit.sh`, also on every push/PR. Exits non-zero on structural failure.

- **Word budgets** — total canonical as a bloat tripwire, plus a per-file limit, since an agent loads one phase file and long files lose their tail instructions.
- **JSON validity** of hook configs — a syntax error silently disables a safety hook.
- **Broken internal references** — pointers to files that moved or never existed.
- **No hardcoded model IDs** (`model: inherit` only) — adapters pinned to a model that will be deprecated.
- **No `../` path chains** — references that break when a file moves.
- **Shell syntax** (`bash -n`) — a sensor script that cannot run.
- **Skill shape** — `<tool>/skills/<name>/SKILL.md` with `name` + `description`, identical set across tools. Catches flat files no tool loads, and commands that exist in one tool only.
- **Agent shape** — `name` + `description` in every agent file, or the subagent never registers.
- **Rule parity** — every `aidlc/rules/*.md` has a pointer per tool, so no rule is enforced in one tool and invisible in another.
- **Rule attach path** — a rule needs `alwaysApply: true` or a working glob. Cursor splits `globs` on commas, so brace expansion (`*.{ts,tsx}`) shreds into invalid fragments; three rules shipped dead this way before the check existed.
- **Hook output schemas** — each tool has its own contract, and the wrong key is *ignored*, not rejected: a Cursor `sessionStart` hook emitting `agent_message` instead of `additional_context` is a no-op that still reports success.
- **Command-guard self-test** — the guard is run against a table of must-block and must-allow commands, plus a fail-closed check, so a safety sensor can't quietly stop working.
- **Docs render on mobile** — table rows and code blocks stay under width, so the README never needs horizontal scrolling on a phone.

Every one of these is negative-tested: regressing each invariant on a scratch copy must make the audit exit non-zero. A sensor that cannot fail is theater.

---

## Reference

<details>
<summary><b>Directory structure</b></summary>

```
aidlc-template/
├── AGENTS.md            Universal entry (Codex reads natively)
├── CLAUDE.md            Claude entry — imports AGENTS.md
├── README.md            This file
├── init.sh.example      Copy to init.sh — install + smoke
├── aidlc/               Canonical methodology
│   ├── core-workflow.md   Phase index
│   ├── agents/            engineer, manager, reviewer
│   ├── inception/         spec, design
│   ├── construction/      plan, build, test, eval,
│   │                      review, security, e2e, ship
│   ├── operations/        operate, retro, investigate,
│   │                      daily-report
│   ├── rules/             7 canonical rule bodies
│   ├── common/            decision-gates, unknowns,
│   │                      session-lifecycle
│   └── examples/          8 fill-in artifact templates
├── memory/              Tool-agnostic handoff state
│   ├── progress.md        Decisions, last/next, issues
│   ├── feature-list.json  Backlog (append-only)
│   ├── plans/             Two-part execution plans
│   └── decisions/         [Answer]: gate files
├── .claude/             Claude Code adapters
│   ├── rules/ agents/          → aidlc/
│   ├── skills/<name>/SKILL.md  → aidlc/<phase>/
│   └── settings.json           Permissions + hooks
├── .cursor/             Cursor adapters
│   ├── rules/ agents/          → aidlc/
│   ├── skills/<name>/SKILL.md  → aidlc/<phase>/
│   ├── hooks/                  Bearings + guard wrappers
│   └── hooks.json              Lifecycle hooks
├── .codex/              Codex CLI adapters
│   ├── skills/<name>/SKILL.md  → aidlc/<phase>/
│   ├── config.toml             MCP, feature flags
│   └── hooks.json              Guard + bearings
├── .github/workflows/   CI — audit.sh on push/PR
├── docs/adr/            ADRs (tool-neutral)
└── scripts/
    ├── audit.sh         Footprint + structural audit
    ├── agent-test.sh    AI-friendly test sensor
    ├── guard-command.sh Shared dangerous-command matcher
    └── guard-cases.tsv  Guard self-test table
```

</details>

<details>
<summary><b>Artifact examples</b> (<code>aidlc/examples/</code>)</summary>

Fill-in templates for what each phase produces — documentation, not auto-loaded.

**Always useful:** `feature-spec.md` (`/spec` output) · `feature-list.md` (backlog shape) · `e2e-test-plan.md` (journey table + sign-off).

**Conditional:** `adr.md` (`/plan`, architectural decisions) · `threat-model.md` (`/security`, STRIDE) · `eval-suite.md` (`/eval`, AI features) · `implementation-notes.md` (`/build` deviation log) · `postmortem.md` (`/operate`, Critical/High incidents).

</details>

<details>
<summary><b>Personal vs project layering</b></summary>

- **Project layer** (committed) — `AGENTS.md`, `CLAUDE.md`, `aidlc/`, the adapter dirs, `memory/`.
- **Personal layer** (never committed) — `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.cursor/rules/`.

The project layer dictates *what the codebase requires*; the personal layer dictates *how you prefer to work*. Tools merge both; project wins on conflict.

> **Constitution, not prompts.** Treat each layer as durable infrastructure. Bloating a layer with conversational corrections is the anti-pattern — extract them into rules, skills, or hooks. (Framing: [Brij Kishore Pandey](https://www.linkedin.com/pulse/how-claude-code-becomes-full-engineering-team-brij-kishore-pandey-6eqkf/).)

</details>

<details>
<summary><b>MCP (external tools)</b></summary>

- **Codex** — `.codex/config.toml` under `[mcp_servers.NAME]`
- **Claude Code** — `claude mcp add`, or edit `.claude/settings.json`
- **Cursor** — see Cursor's MCP docs

None configured by default — add per project.

</details>

---

## Sources

<details>
<summary><b>Lifecycle &amp; harness design</b></summary>

- [AWS AIDLC](https://github.com/awslabs/aidlc-workflows) (incl. 2.0 GA) — three-phase lifecycle, structured `[Answer]:` decision gates, two-part code planning, adaptive stage selection, human-in-the-loop tenet.
- [Learn Harness Engineering](https://github.com/walkinglabs/learn-harness-engineering) — five-subsystem harness shape; loop engineering (generator/evaluator split, goal loops).
- [Martin Fowler — Harness engineering](https://martinfowler.com/articles/harness-engineering.html) — feedforward guides vs feedback sensors, quality-left framing.
- [OpenAI — Harness engineering](https://openai.com/index/harness-engineering/) — agent-first framing behind the guide/sensor split.
- [LangChain — Harness engineering](https://www.langchain.com/blog/improving-deep-agents-with-harness-engineering) — build-verify loop, context onboarding, traces as feedback.

</details>

<details>
<summary><b>Long-running agents &amp; context</b></summary>

- [Anthropic — Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) — `init.sh` + progress file + JSON feature list, get-bearings, one feature at a time.
- [Anthropic — Harness design for long-running apps](https://www.anthropic.com/engineering/harness-design-long-running-apps) — generator/evaluator (folded into reviewer), sprint contracts, runtime QA, harness-review cadence.
- [Anthropic — Effective context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) — session-start reconciliation, just-in-time retrieval, compaction protocol.
- [OpenAI — Unrolling the Codex agent loop](https://openai.com/index/unrolling-the-codex-agent-loop/) — layered project docs, sandbox/approval context, stable adapter loading.

</details>

<details>
<summary><b>Verification, evals &amp; tooling</b></summary>

- [Anthropic — Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) — tasks/trials/graders, capability vs regression, pass@k vs pass^k, transcript review.
- [Anthropic — Writing tools for agents](https://www.anthropic.com/engineering/writing-tools-for-agents) — agent-friendly output, behind `scripts/agent-test.sh`.
- [Anthropic — Claude Code best practices](https://code.claude.com/docs/en/best-practices) — give the agent a check it can run; four gating tiers for "done"; fresh-context adversarial review and its over-reporting caveat.
- [Agent Skills standard](https://agentskills.io) — `skills/<name>/SKILL.md`, the one adapter layout all three tools load.
- [Know Your Unknowns](https://thariqs.github.io/html-effectiveness/unknowns/) — the 11 elicitation moves in `aidlc/common/unknowns.md`.

</details>

<details>
<summary><b>Pipeline &amp; operations lineage</b></summary>

- [Metaflow](https://github.com/Netflix/metaflow) — human-centric framing; reproducibility-as-default.
- [Kedro](https://github.com/kedro-org/kedro) — modular phase-based structure.
- [ZenML](https://github.com/zenml-io/zenml) — stage gates with explicit pass/fail criteria.
- [Made-With-ML](https://github.com/GokuMohandas/Made-With-ML) — end-to-end iteration loop (operate → retro).
- [awesome-production-ML](https://github.com/EthicalML/awesome-production-machine-learning) — operations-phase emphasis.
- [agent-skills](https://github.com/addyosmani/agent-skills) — anti-rationalization framing, kept lightweight.

</details>

---

## License

MIT — see [LICENSE](LICENSE).
