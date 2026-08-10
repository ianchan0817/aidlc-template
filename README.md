# aidlc-template

[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Tools: 3](https://img.shields.io/badge/tools-Claude%20Code%20%C2%B7%20Codex%20%C2%B7%20Cursor-blue.svg)](#day-0)

Tool-agnostic AI Development Lifecycle template for **Claude Code**, **OpenAI Codex CLI**, and **Cursor IDE**. One canonical methodology, three thin adapters, harness patterns for long-running agentic work.

**Jump to:** [Why](#why) · [Day 0](#day-0) · [Adaptation](#adaptation-model) · [Architecture](#architecture) · [Workflow](#daily-workflow) · [Guardrails](#guardrails--sensors) · [Reference](#reference) · [Sources](#sources)

[Security policy](SECURITY.md) · [Contributing](CONTRIBUTING.md) · [Repo setup: security & quality](docs/repo-setup.md)

---

## Why

**Agentic templates are usually tool-locked.** Pick `.claude/` and you can't share with Codex; pick `.cursor/` and Claude Code starts from scratch. The methodology is identical — review code, write tests, deploy carefully — but the wiring isn't portable.

**This template separates methodology from wiring.** Methodology lives once in `aidlc/`; each tool gets a thin adapter directory pointing at it via repo-rooted paths. It also bakes in long-running-agent research: a structured session lifecycle, a JSON feature backlog, sprint contracts between engineer and reviewer, and a dedicated eval phase for AI behavior.

Seven commitments, enforced by CI where possible:

| Commitment | Meaning |
|---|---|
| Single source of truth | Lives once in `aidlc/`; adapters are pointers |
| Shape by declaration | Gates switch on `project.yml`, never by deleting files |
| Model + tool agnostic | `model: inherit` only, repo-rooted paths only |
| Adapters that load | Every pointer checked against its real loader format |
| Scoped work | One slice per session, tied to a sprint contract |
| Sensors over confidence | Tests, hooks, evals, review — never self-reported |
| Human in the loop | Gated decisions are written, answered, recorded |

The harness is five-part: **Instructions** (focused files, no giant prompt) · **State** (memory + git survive resets) · **Scope** (one committable slice) · **Verification** (tests, hooks, E2E, evals, review) · **Lifecycle** (initialize → work → verify → handoff → commit).

---

## Day 0

**Start here:** GitHub → **Use this template** → *Create a new repository*. This repo is marked as a template, so that button exists. It buys a clean history — `git clone` would drag the template's commits into your project's log.

Then six steps, in order. Each says what it buys.

1. **Delete `aidlc/.template`.** That marker is what tells `scripts/audit.sh` this repo *is* the template. Removing it drops the maintainer-only sensors (word budgets, three-tool parity, README mobile render, upstream-URL check, hygiene file list) and starts the adopter checks instead. The safety sensors — guard self-test, secrets, broken references, shell syntax — run in **both** modes.
2. **Fill in `project.yml`.** The one file you must edit: `surfaces`, `stateful`, `multi_tenant`, `release`, `verify`. Every conditional gate reads it, and it loads on every session. See [Adaptation model](#adaptation-model).
3. **Delete the adapter dirs you do not use** — `.claude/`, `.codex/`, `.cursor/`. `aidlc/`, `AGENTS.md`, `project.yml`, and `memory/` work standalone; parity is checked only for the tools still present.
4. **Replace `OWNER/REPO`** in `.github/ISSUE_TEMPLATE/config.yml`. Left as a placeholder, your reporters' "Report a vulnerability" link opens an advisory on a stranger's repository.
5. **Copy the two `.example` files** — `init.sh.example` → `init.sh` (session-start smoke) and `.github/workflows/verify.yml.example` → `.github/workflows/verify.yml` (the same checks in CI). Both read `verify:` from `project.yml`, so your shell and your PR run one contract instead of two that drift.
6. **Uncomment your ecosystem in `.github/dependabot.yml`** — its header maps manifest file → ecosystem name (`go.mod` → `gomod`, `package.json` → `npm`). The `github-actions` block already ships active, which is what keeps the workflow SHA pins current; nothing watches your *application* dependencies until you uncomment their block.

Then set `Current Focus` in `memory/progress.md`, run `bash scripts/audit.sh`, and turn on the repo-side switches no commit can set ([`docs/repo-setup.md`](docs/repo-setup.md)).

Open it: `claude` loads `CLAUDE.md`; `codex` loads `AGENTS.md`; Cursor loads `.cursor/rules/*.mdc`. First feature — `/spec`, then `/plan` → `/build` → `/test` → `/review` → `/ship`.

---

## Adaptation model

**You declare; you do not delete.** `project.yml` names this project's surfaces and capabilities. A gate whose surface or capability you did not declare **does not apply and needs no skip rationale**; a gate you did declare **cannot be skipped**. That contract is the whole adaptation mechanism.

Deleting methodology files is *not* how you adapt, and it breaks the build. Drop the two UI rules for a headless API and the backtick reference to them in `aidlc/inception/design.md` dangles, so `scripts/audit.sh` fails on a broken reference. Files stay; gates go inert.

One tree serves a Go API, a React Native app and a Next.js site because the methodology names **invariants**, not spellings — "address every element by a stable, purpose-named identifier", not "use `data-testid`". [`docs/project-shapes.md`](docs/project-shapes.md) holds the spelling per surface: E2E identity, health signals, rollback lever, and the coverage equivalent for code that cannot be line-instrumented.

The two deletions adoption *does* want are `aidlc/.template` (step 1) and the tool dirs you skipped (step 3). Both are sensed: the audit switches modes on the first and checks parity only for tools present.

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
- **Rules live once** in [`aidlc/rules/`](aidlc/rules/), one body per topic. `.claude/rules/*.md` (`paths:`) and `.cursor/rules/*.mdc` (`globs:`/`alwaysApply:`) are thin pointers in each tool's native frontmatter.
- **One always-on rule has no canonical body**: `project` points at [`project.yml`](project.yml) and loads unconditionally (Claude: no `paths:` block; Cursor: `alwaysApply: true`). Codex has no rules directory, so `AGENTS.md` tells it to read the declaration directly — that is the parity fix, not an oversight.
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

### Design & UX

Two rules, split by the question they answer. Both open by stating they apply only when `project.yml` declares a `web` or `mobile` surface — on a headless API they go inert, and you delete neither.

[`design-tokens.md`](aidlc/rules/design-tokens.md) is the **vocabulary**: color named by *role*, never by hue (`primary`, not `blue-500`, which is a leak that won't survive a rebrand); every foreground/background pair the product uses named with a measured contrast ratio, because an unnamed pair is an unchecked pair; dark mode as a second set of role values rather than inverted lightness; a type scale with line-height inverse to size and a 45–75 character measure; and spacing, radius, elevation and motion as fixed steps.

[`ux-guidelines.md`](aidlc/rules/ux-guidelines.md) is the **behavior**: hierarchy and position (one primary action per view; proximity *is* grouping; primary actions in the thumb zone and destructive ones never), all five states designed (loading, empty, partial, error, success), interaction (undo over confirm, prevent errors rather than report them, forgiving on input and strict on storage, never lose typed work), responsive rules, and a WCAG 2.1 AA floor — including the three-flashes-per-second seizure threshold, which is a legal limit rather than a preference and which `prefers-reduced-motion` does not cover.

`/design` ([`aidlc/inception/design.md`](aidlc/inception/design.md)) is the process: name the job before drawing anything, get hierarchy right in greyscale (if it doesn't work without color, color won't save it), design every branch as a state, express it in existing tokens, then self-critique as a stranger before handoff.

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

### The audit

`bash scripts/audit.sh`, also on every push/PR. Exits non-zero on structural failure. It runs in **two modes**, decided by whether `aidlc/.template` is present — full per-sensor list in [`CONTRIBUTING.md`](CONTRIBUTING.md).

**Universal**, because they are true of any repo: JSON validity of every hook config (a syntax error silently disables a safety hook) · broken internal references · no hardcoded model IDs (`model: inherit` only) · no `../` path chains · shell syntax (`bash -n`) · agent frontmatter, since a file without `name:` never registers as a subagent · skill *shape*, `<tool>/skills/<name>/SKILL.md`, because a flat file produces no slash command and no error · every rule has a working attach path · hook output schemas per tool, where the wrong key is *ignored* rather than rejected · the command guard's own self-test · `.gitignore` covers secrets and none is tracked · **anti-explosion**: a surface name in an `aidlc/` gate must name the `project.yml` field that switches it.

**Maintainer-only**, dropped the moment you delete the marker: word budgets · three-tool parity · README mobile render · upstream-URL check · this template's hygiene file list. **Adopter-only**, which start once it is gone: `project.yml` parses and declares real values · `memory/feature-list.json` is well-formed and every `passes: true` resolves to a real commit · `init.sh` exists and is not a byte-identical copy of the example · every workflow declares `permissions:`.

Every one of these is negative-tested: regressing the invariant on a scratch copy must make the audit exit non-zero. A sensor that cannot fail is theater.

---

## Reference

<details>
<summary><b>Directory structure</b></summary>

```
aidlc-template/
├── project.yml          Shape declaration — the file you edit
├── AGENTS.md            Universal entry (Codex reads natively)
├── CLAUDE.md            Claude entry — imports AGENTS.md
├── README.md            This file
├── init.sh.example      Copy to init.sh — install + smoke
├── aidlc/               Canonical methodology
│   ├── .template          Marker: delete on adoption
│   ├── core-workflow.md   Phase index
│   ├── agents/            engineer, manager, reviewer
│   ├── inception/         spec, design
│   ├── construction/      plan, build, test, eval,
│   │                      review, security, e2e, ship
│   ├── operations/        operate, retro, investigate,
│   │                      daily-report
│   ├── rules/             Canonical rule bodies
│   ├── common/            decision-gates, unknowns,
│   │                      session-lifecycle
│   └── examples/          Fill-in artifact templates
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
├── .github/
│   ├── workflows/         audit + code-quality; codeql and
│   │                      verify ship as .yml.example
│   ├── dependabot.yml     Uncomment your ecosystem
│   └── ISSUE_TEMPLATE/    Replace OWNER/REPO
├── docs/
│   ├── adr/               Architecture decision records
│   ├── project-shapes.md  Per-surface gate spellings
│   ├── repo-setup.md      GitHub toggles no commit can set
│   └── history.md         Maintainer log (yours to replace)
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
