# aidlc-template

[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A generic AI Development Lifecycle template for **Claude Code**, **OpenAI Codex
CLI** and **Cursor IDE** — one methodology, three thin adapters. It covers
frontend, backend, infra, mobile and web work from the same tree, because the
gates are written as invariants and your `project.yml` decides which apply.

**Jump to:** [Day 0](#day-0) · [Adaptation](#how-it-adapts) ·
[Workflow](#workflow) · [Guardrails](#guardrails) · [Layout](#layout)

[Security policy](SECURITY.md) · [Contributing](CONTRIBUTING.md) ·
[Guardrails in depth](docs/guardrails.md) · [Repo setup](docs/repo-setup.md)

---

## Why

Agentic templates are usually tool-locked. Pick `.claude/` and you cannot share
with Codex; pick `.cursor/` and Claude Code starts from nothing. The methodology
is the same either way — review code, write tests, deploy carefully — but the
wiring is not portable.

So the methodology lives once in `aidlc/`, and each tool gets a thin adapter
pointing at it. Six commitments, enforced by CI where a check is possible:

| Commitment | Meaning |
|---|---|
| Single source of truth | Lives once in `aidlc/`; adapters are pointers |
| Shape by declaration | Gates switch on `project.yml`, never by deleting |
| Model and tool agnostic | `model: inherit`, repo-rooted paths only |
| Adapters that load | Every pointer checked against its real loader |
| Sensors over confidence | Tests, hooks, evals, review — never self-report |
| Human in the loop | Gated decisions written, answered, recorded |

**An adapter is only real if the tool loads it.** All three tools ignore a
malformed adapter *silently* — a flat `skills/spec.md` produces no `/spec` and no
error; an agent file without `name:` never registers. So the audit checks adapter
shape, and a dead pointer fails CI instead of failing quietly at 2am.

---

## Day 0

GitHub → **Use this template** → *Create a new repository*. That gives a clean
history; `git clone` would drag the template's commits into your log.

Then seven steps. Each says what it buys.

1. **Delete `aidlc/.template`.** The marker is what tells `scripts/audit.sh` this
   repo *is* the template — removing it drops the maintainer-only sensors and
   starts the adopter checks. The safety sensors run in **both** modes.
2. **Start `memory/` from empty.** It ships as structure only, so the first
   session writes your first record instead of reading a stranger's.
3. **Fill in `project.yml`.** The one file you must edit. Every conditional gate
   reads it and it loads every session. See [how it adapts](#how-it-adapts).
4. **Delete the adapter dirs you do not use** — `.claude/`, `.cursor/`,
   `.codex/` + `.agents/`. Parity is checked only for tools still present.
5. **Replace `OWNER/REPO`** in `.github/ISSUE_TEMPLATE/config.yml`, or your
   reporters' vulnerability link opens an advisory on a stranger's repo.
6. **Copy the two `.example` files** — `init.sh.example` → `init.sh` and
   `.github/workflows/verify.yml.example` → `.github/workflows/verify.yml`. Both
   read `verify:` from `project.yml`, so your shell and your CI run one contract.
7. **Uncomment your ecosystem in `.github/dependabot.yml`.** Nothing watches
   your application dependencies until you do.

Then run `bash scripts/audit.sh` and turn on the repo switches no commit can set
([`docs/repo-setup.md`](docs/repo-setup.md)).

Open it: `claude` reads `CLAUDE.md`, `codex` reads `AGENTS.md`, Cursor reads
`.cursor/rules/*.mdc`. First feature: `/spec` → `/plan` → `/build` → `/review`.

---

## How it adapts

**You declare; you do not delete.** [`project.yml`](project.yml) names your
surfaces and capabilities. A gate whose surface you did not declare **does not
apply and needs no skip rationale**; a gate you did declare **cannot be
skipped**.

Deleting methodology files is not the mechanism, and it breaks the build: drop
the two UI rules for a headless API and the reference to them in
`aidlc/inception/design.md` dangles, so the audit fails. Files stay; gates go
inert.

One tree serves a Go API, a React Native app and a Next.js site because the
methodology names invariants, not spellings — "address every element by a stable,
purpose-named identifier", not "use `data-testid`".
[`docs/project-shapes.md`](docs/project-shapes.md) holds the spelling per
surface, plus what each field switches and the recurring-maintenance schedule.

### Proven, and not

**Proven:** the seven declarable surfaces — `web` `mobile` `http-api` `grpc`
`events` `cli` `batch` — on one release train, under any of the three tools.
Three shapes have been built end-to-end from this tree and audit clean with zero
deletions from `aidlc/`.

**Not expressible yet**, so expect to add your own gate: a published library (no
`library` surface, no yank lever, no semver gate); a monorepo needing different
release levers per surface (`release.*` are scalars); ML model quality
(`eval.md` covers agent behavior, not accuracy regression or lineage); a fourth
tool (methodology as prose, but no slash commands and **no command guard**); and
languages outside the style adapters' thirteen extensions.

---

## Workflow

Inception (WHAT) → Construction (HOW) → Operations (RUN), with a gate between
each. Every command is one canonical file under `aidlc/`, surfaced as a slash
command in all three tools. Open the file directly if you prefer — the slash is
convenience, not requirement.

| Command | Use when |
|---|---|
| `/spec` | New feature, or requirements still ambiguous |
| `/design` | The feature has a user interface |
| `/plan` | Spec approved, before any code |
| `/build` | Contract agreed — TDD on one slice |
| `/test` | Auditing or closing coverage gaps |
| `/eval` | Change touches AI or agent behavior |
| `/security` | Auth, data, upload, external API, crypto |
| `/review` | Ready to merge — two-pass review |
| `/e2e` | Before release — journeys and sign-off |
| `/ship` | All gates green — land the branch |
| `/operate` | Post-deploy, incident, or the stable check |
| `/investigate` | Bug or failure — root cause before fix |
| `/retro` | Sprint end, or after a model upgrade |

Common paths:

- **Feature** — `/spec` → `/design`\* → `/plan` → `/build` → `/test` →
  `/review` → `/e2e` → `/ship` → `/operate`
- **AI feature** — the same, plus `/eval` before `/review`
- **Auth or data change** — the same, plus `/security` before `/e2e`
- **Bug** — `/investigate` → `/build` → `/test` → `/review` → `/ship`
- **Incident** — `/operate` → `/investigate` → fix → `/operate`

\* if it has UI. For decisions needing explicit human approval,
[`aidlc/common/decision-gates.md`](aidlc/common/decision-gates.md) gives A/B/C/D
questions with `[Answer]:` lines, stored in `memory/decisions/`.

### Roles

Three, defined in [`aidlc/agents/`](aidlc/agents/). **engineer** implements one
slice at a time and treats the approved spec as immutable mid-build — on
contradiction, halt and escalate rather than bend the spec to the code.
**reviewer** owns review, security, runtime QA, evals and E2E sign-off, is the
only role that flips `passes: true`, and runs in a **fresh context**, because a
context that just wrote the code already believes its own reasoning. **manager**
orchestrates and holds the harness-review cadence.

---

## Guardrails

Deterministic enforcement, not requests. Full detail:
[`docs/guardrails.md`](docs/guardrails.md).

- **Session lifecycle** — bearings at start, one slice, handoff at end, so work
  survives a context reset. Reconcile memory against the repo on start and trust
  the repo on mismatch.
- **Command guard** — one matcher ([`scripts/guard-command.sh`](scripts/guard-command.sh))
  wired into all three tools, blocking irreversible commands only, and failing
  closed. It is a tokenizer rather than a list of greps, because position is what
  separates a real `rm -rf /etc` from a commit message describing one.
- **The audit** — [`scripts/audit.sh`](scripts/audit.sh) checks adapter shape,
  broken references, secrets, model-agnosticism and the guard's own case table
  on every run, in CI.
- **Evals for agent behavior** — tests cover code paths, evals cover transcripts
  and outcomes ([`aidlc/construction/eval.md`](aidlc/construction/eval.md)).
- **A Bash allow-list is a convenience boundary, not a security boundary.**
  `Bash(python *)` permits arbitrary code, so no `Read(.env)` deny holds against
  `python -c "open('.env')"`. Enforcement lives in the guard, which sees the
  real command.

---

## Layout

```
project.yml          Shape declaration — the file you edit
AGENTS.md            Universal entry (Codex reads natively)
CLAUDE.md            Claude entry — imports AGENTS.md
aidlc/               Canonical methodology
  core-workflow.md   Phase index
  agents/            engineer · reviewer · manager
  inception/         spec · design
  construction/      plan · build · test · eval · review ·
                     security · e2e · ship
  operations/        operate · retro · investigate ·
  rules/             7 canonical rule bodies
  common/            decision-gates · unknowns · lifecycle
  examples/          Fill-in artifact templates
memory/              Project state — progress · features · sessions
docs/                project-shapes · guardrails · adr · repo-setup
scripts/             audit · guard-command · guard-mutate · agent-test
.claude/ .cursor/    Tool adapters — rules · agents · skills
.codex/ .agents/     Codex config · Codex skills
```

Adapters use repo-rooted paths, so moving a file never breaks a reference. Your
personal layer (`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`) stays uncommitted
and applies across projects; everything here is the project layer.

Where the ideas come from, which ones earned their place, and the doc hubs worth
re-reading on a cadence: [`docs/references.md`](docs/references.md). It is the
registry for every external link in the repo — entries keep their verdict instead
of being deleted, `bash scripts/check-links.sh` re-verifies them, and the audit
fails if the list shrinks.

---

## License

MIT — see [LICENSE](LICENSE).
