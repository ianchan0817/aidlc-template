# AGENTS.md

Tool-agnostic instructions for any AI coding agent. Canonical methodology lives in `aidlc/`; `.claude/`, `.cursor/`, and `.agents/` hold only what each tool's loader requires.

This file is loaded on **every session by every tool**, so it holds only what an agent must know *before* it knows the task. Reference material an agent can look up when needed lives in `README.md` (layout, tool entry points) and `docs/` — putting it here charges every session for it.

## Project shape — read first

`project.yml` at the repo root declares `surfaces`, `stateful`, `multi_tenant`, `release`, and `verify`. Claude Code and Cursor load it through an always-on rule; **Codex has no rules directory, so read `project.yml` from here at session start.**

**The contract:** a gate whose surface or capability `project.yml` does not declare does not apply and needs no skip rationale; a gate it does declare cannot be skipped. Adapt by declaring, never by deleting — a deleted file dangles a reference and fails `scripts/audit.sh`. What each field switches, and the per-surface spellings: `docs/project-shapes.md`.

## Working style

- Output code/answers directly. No preamble.
- Diff-only output unless a full rewrite is requested.
- Stop within 5s of detecting logic drift — clarify, don't guess.
- Non-trivial change → **explore → plan → implement → commit**.
- Trust repo artifacts (`memory/`, `git`, `init.sh`) over chat memory when context is stale.
- Reviewer/eval gates are independent — never self-mark a feature `passes: true`.
- State what you verified and what you did not. A claim beyond the evidence is worse than no claim.

## Session lifecycle

**Start:** read `aidlc/common/session-lifecycle.md` — bearings from `memory/progress.md`, the newest handoff in `memory/sessions/`, the backlog in `memory/features/`, `git log`, and `./init.sh` smoke when applicable.
**End:** commit, then write this session's handoff to `memory/sessions/`. Only `reviewer` flips `passes: true` in a `memory/features/<id>.json` record.

## Memory & artifacts

- `memory/progress.md` — cross-session state only: known issues, blockers, open questions
- `memory/sessions/<date>-<slug>.md` — one handoff per session (a field every session rewrites is a line every concurrent session collides on)
- `memory/features/<id>.json` — one backlog record per feature; `memory/feature-list.json` is the manifest, never appended to
- Status comes from `git log` — don't restate it in memory files
- ADRs: `docs/adr/ADR-NNN-title.md` (format: `aidlc/examples/adr.md`)

## Lifecycle: WHAT → HOW → RUN

Inception → Construction → Operations, gate between each. Phase index and full workflow: `aidlc/core-workflow.md`. Rules and phase files are feedforward guides; hooks, tests, E2E, evals and review are feedback sensors. Prefer deterministic sensors, and grade **outcomes**, not the path.

Never let "looks done" be the stop signal — name the check that decides, and pick how hard it gates (`aidlc/common/session-lifecycle.md` → Close the loop on "done"). A sensor that verifies zero subjects must not report success.

## Roles

| Role | Scope | Canonical |
|------|-------|-----------|
| `engineer` | Build, test, deploy, architecture, DB, CI/CD | `aidlc/agents/engineer.md` |
| `reviewer` | Code review, security, runtime QA, evals, sprint contracts, E2E | `aidlc/agents/reviewer.md` |
| `manager`  | Initiatives, coordination, daily reports, harness review | `aidlc/agents/manager.md` |

Claude Code and Cursor load roles via `agents/` adapters (`name` + `description` required, or the role never registers). Codex has no agents dir — state the role explicitly ("act as reviewer per `aidlc/agents/reviewer.md`") so role invariants hold.

Run `reviewer` in a **fresh context** — its own subagent or session. Reviewing inline, in the context that wrote the code, defeats the split.

## Engineering rules

Canonical bodies in `aidlc/rules/*.md`, one source of truth: `code-style`, `testing`, `security`, `api-conventions`, `design-tokens`, `ux-guidelines`, `reproducibility`. Tool adapters are frontmatter wrappers pointing at the canonical file — Claude `paths:`, Cursor `globs:`/`alwaysApply:`, Codex reads the canonical file directly.

Only `project` and `security` load unconditionally; every other rule is path-scoped, because an unscoped pointer also forces a read of its canonical body on every session. `scripts/audit.sh` fails if that set changes.

## Non-negotiables

- No merge without code review
- No release without E2E sign-off
- No skipping security review on auth, data, or external API changes
- No secrets, credentials, or `.env` files in commits
- No bypassing the coverage gate on new/modified code — the gate is stated once, in `aidlc/rules/testing.md`, including what counts where lines cannot be instrumented
- No floating dependency ranges in production
- No fix without a test (every prod incident → fix, test, or rule update)
- No code without a plan for non-trivial changes
- No flipping `passes: true` on a backlog record without reviewer-verified QA and a resolvable commit SHA

## Done

A change is done when:

- Tests pass and the `testing` rule's coverage gate is met
- Verified on the real target, not a proxy — and what was verified stated plainly, along with what was not
- Reviewed, all critical issues resolved
- E2E journeys signed off for changed flows
- Agent eval suite green when AI-facing behavior changed (`aidlc/construction/eval.md`)
- Security audit clean if auth/data/API touched
- Build reproducible (locked deps, pinned runtime, deploy traceable to a commit SHA)
- The declared `release.window` elapsed with the four declared `release.signals` green

## Decision gates

Structured-question format in `aidlc/common/decision-gates.md`. Creates an audit trail.

Layout, tool entry points and the adoption sequence: `README.md`.
