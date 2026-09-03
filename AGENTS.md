# AGENTS.md

Tool-agnostic instructions for any AI coding agent. Canonical methodology lives in `aidlc/`; `.claude/`, `.cursor/`, and `.agents/` hold only what each tool's loader requires.

This file is loaded on **every session by every tool**, so it holds only what an agent must know *before* it knows the task. Reference material an agent can look up when needed lives in `README.md` (layout, tool entry points) and `docs/` — putting it here charges every session for it.

## Project shape — read first

`project.yml` at the repo root declares `surfaces`, `stateful`, `multi_tenant`, `release`, and `verify`. Claude Code and Cursor load it through an always-on rule; **Codex has no glob-scoped rule files — it scopes by directory instead, nearest `AGENTS.md` winning — so read `project.yml` from here at session start, and give a subtree that needs different rules its own nested `AGENTS.md`.**

**The contract:** a gate whose surface or capability `project.yml` does not declare does not apply and needs no skip rationale; a gate it does declare cannot be skipped. Adapt by declaring, never by deleting — a deleted file dangles a reference and fails `scripts/audit.sh`. What each field switches, and the per-surface spellings: `docs/project-shapes.md`.

## Working style

- Output code/answers directly. No preamble.
- Diff-only output unless a full rewrite is requested.
- Stop within 5s of detecting logic drift — clarify, don't guess.
- Non-trivial change → **explore → plan → implement → commit**.
- Trust repo artifacts (`memory/`, `git`, `init.sh`) over chat memory when context is stale.
- Reviewer/eval gates are independent — never self-mark a feature `passes: true`.
- State what you verified and what you did not. A claim beyond the evidence is worse than no claim.

## Session lifecycle & memory

Read `aidlc/common/session-lifecycle.md` at session start — bearings, reconcile against the repo, one slice, handoff at the end.

State lives by lifetime: cross-session issues and blockers in `memory/progress.md`; one handoff per session in `memory/sessions/`; one backlog record per feature in `memory/features/<id>.json`, where `memory/feature-list.json` is a manifest and must never be appended to. Status comes from `git log`, so don't restate it. ADRs: `docs/adr/ADR-NNN-title.md` (format: `aidlc/examples/adr.md`). Only `reviewer` flips `passes: true`.

## Lifecycle: WHAT → HOW → RUN

Inception → Construction → Operations, gate between each. Phase index and full workflow: `aidlc/core-workflow.md`. Rules and phase files are feedforward guides; hooks, tests, E2E, evals and review are feedback sensors. Prefer deterministic sensors, and grade **outcomes**, not the path.

Never let "looks done" be the stop signal — name the check that decides, and pick how hard it gates (`aidlc/common/session-lifecycle.md` → Close the loop on "done"). A sensor that verifies zero subjects must not report success.

## Roles

| Role | Scope | Canonical |
|------|-------|-----------|
| `engineer` | Build, test, deploy, architecture, DB, CI/CD | `aidlc/agents/engineer.md` |
| `reviewer` | Code review, security, runtime QA, evals, sprint contracts, E2E | `aidlc/agents/reviewer.md` |
| `manager`  | Initiatives, coordination, routing, harness review | `aidlc/agents/manager.md` |

Claude Code and Cursor load roles via `agents/` adapters (`name` + `description` required, or the role never registers). Codex has no instruction-loading agents adapter — state the role explicitly ("act as reviewer per `aidlc/agents/reviewer.md`") so role invariants hold.

Run `reviewer` in a **fresh context** — its own subagent or session. Reviewing inline, in the context that wrote the code, defeats the split.

## Engineering rules

Canonical bodies in `aidlc/rules/*.md`, one source of truth: `code-style`, `testing`, `verification`, `security`, `api-conventions`, `design-tokens`, `ux-guidelines`, `reproducibility`. Adapters are frontmatter wrappers pointing at them; only `project` and `security` load unconditionally, the rest attach by path. How each loader wires that up: `CONTRIBUTING.md` → Adapter shape.

## Done — the first five are non-negotiable

A change is done when every line below holds. The first five cannot be waived: no
merge, no release without them.

- **Reviewed** in a fresh context, every critical issue resolved
- **Tested** — suite green and the coverage gate in `aidlc/rules/testing.md` met, including where lines cannot be instrumented
- **Secure** — audit clean if auth, data or an external API changed; no secrets, credentials or `.env` in the commit
- **E2E signed off** for every changed flow
- **Reproducible** — exact-pinned deps, pinned runtime, deploy traceable to a commit SHA
- Verified on the real target, not a proxy, and what was *not* verified stated plainly
- Agent eval suite green when AI-facing behavior changed (`aidlc/construction/eval.md`)
- Every prod incident closed by a fix, a test, or a rule update
- `passes: true` set only by `reviewer`, with QA evidence and a resolvable commit SHA
- The declared `release.window` elapsed with all four `release.signals` green

## Decision gates

Structured-question format in `aidlc/common/decision-gates.md`. Creates an audit trail.

Layout, tool entry points and the adoption sequence: `README.md`.
