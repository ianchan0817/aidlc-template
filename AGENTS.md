# AGENTS.md

Tool-agnostic instructions for any AI coding agent (Claude Code, Codex CLI, Cursor IDE, etc.). Canonical methodology lives in `aidlc/`. Tool-specific dirs (`.claude/`, `.cursor/`, `.codex/`) hold only what each tool's loader requires — shared content lives here or in `aidlc/`.

## Working style

- Output code/answers directly. No preamble.
- Diff-only output unless a full rewrite is requested.
- Stop within 5s of detecting logic drift — clarify, don't guess.
- Non-trivial change → **explore → plan → implement → commit**.
- Trust repo artifacts (`memory/`, `git`, `init.sh`) over chat memory when context is stale.
- Reviewer/eval gates are independent — never self-mark a feature `passes: true`.
- If a user repeats an instruction, suggest editing the previous message.

## Session lifecycle

**Start:** read `aidlc/common/session-lifecycle.md` — bearings from `memory/progress.md`, `memory/feature-list.json`, `git log`, `./init.sh` smoke when applicable.
**End:** commit + update `memory/progress.md` handoff fields. Only `reviewer` flips `passes: true` in `memory/feature-list.json`.

## Memory & artifacts

- `memory/progress.md` — decisions, last/next session, known issues
- `memory/feature-list.json` — backlog (shape: `aidlc/examples/feature-list.md`)
- Status comes from `git log` — don't restate in memory files
- ADRs: `docs/adr/ADR-NNN-title.md` (format: `aidlc/examples/adr.md`)

## Layout

```
AGENTS.md               Universal entry (this file)
CLAUDE.md               Claude Code adapter — @-imports this
README.md               Human-facing docs
init.sh.example         Copy to init.sh — bootstrap + smoke
aidlc/                  Canonical methodology (single source of truth)
  core-workflow.md      Phase index
  agents/               engineer, manager, reviewer
  inception/            spec, design                            (WHAT/WHY)
  construction/         plan, build, test, eval, review,
                        security, e2e, ship                     (HOW)
  operations/           operate, retro, investigate,
                        daily-report                            (RUN)
  rules/                8 canonical rules
  common/               decision-gates, session-lifecycle, unknowns
  examples/             feature-spec, feature-list, eval-suite,
                        adr, threat-model, e2e-test-plan,
                        implementation-notes, postmortem
memory/                 progress.md · feature-list.json · plans/ · decisions/
.claude/ .cursor/ .codex/   Tool adapters (skills/<name>/SKILL.md per tool)
docs/adr/               ADRs
scripts/                audit.sh (structure + budget) · agent-test.sh (AI-friendly
                        test sensor) · guard-command.sh (+ guard-cases.tsv):
                        one dangerous-command matcher shared by all three tools
```

Adapters use repo-rooted paths (e.g. `aidlc/agents/engineer.md`) — no `../../` chains.

## Lifecycle: WHAT → HOW → RUN

Inception → Construction → Operations, gate between each. Full workflow: `aidlc/core-workflow.md`.

## Harness shape

Five subsystems:

- **Instructions** — short entry points (this file, `aidlc/`); no giant prompts.
- **State** — `memory/progress.md`, `memory/feature-list.json`, git history.
- **Scope** — one feature/slice per session, tied to a verifiable sprint contract.
- **Verification** — tests, lint/type, E2E, security, evals, transcripts.
- **Lifecycle** — initialize, work, verify, hand off, commit.

Rules and phase files are feedforward guides; hooks, tests, E2E, evals, and review are feedback sensors. Prefer deterministic sensors. Grade **outcomes**, not the path.

Never let "looks done" be the stop signal — name the check that decides, and pick how hard it gates (`aidlc/common/session-lifecycle.md` → Close the loop on "done").

## Roles

| Role | Scope | Canonical |
|------|-------|-----------|
| `engineer` | Build, test, deploy, architecture, DB, CI/CD | `aidlc/agents/engineer.md` |
| `reviewer` | Code review, security, runtime QA, evals, sprint contracts, E2E | `aidlc/agents/reviewer.md` |
| `manager`  | Initiatives, coordination, daily reports, harness review | `aidlc/agents/manager.md` |

Claude Code and Cursor load roles via `agents/` adapters (`name` + `description` required, or the role never registers). Codex has no agents dir — state the role explicitly ("act as reviewer per `aidlc/agents/reviewer.md`") so role invariants (only reviewer flips `passes`) hold.

Run `reviewer` in a **fresh context** — its own subagent or session. Reviewing inline, in the context that wrote the code, defeats the split.

## Engineering rules

Canonical bodies in `aidlc/rules/*.md` — one source of truth. Tool adapters are frontmatter wrappers pointing at the canonical file:

- Claude Code → `.claude/rules/*.md` (`paths:`)
- Cursor → `.cursor/rules/*.mdc` (`globs:` / `alwaysApply:`)
- Codex → reads `aidlc/rules/*.md` directly via AGENTS.md context

Topics: `code-style`, `testing`, `security`, `api-conventions`, `design-tokens`, `ux-guidelines`, `reproducibility`, `tech-stack`. Fill in `aidlc/rules/tech-stack.md` before the first session.

UI work reads two of these: `design-tokens` for the vocabulary (color roles, type scale, spacing, motion) and `ux-guidelines` for behavior (hierarchy, states, interaction, accessibility).

## Non-negotiables

- No merge without code review
- No release without E2E sign-off
- No skipping security review on auth, data, or external API changes
- No secrets, credentials, or `.env` files in commits
- No bypassing the 100% coverage gate on new/modified code
- No floating dependency ranges in production
- No fix without a test (every prod incident → fix, test, or rule update)
- No code without a plan for non-trivial changes
- No flipping `passes: true` in `memory/feature-list.json` without reviewer-verified QA

## Done

A change is done when:

- Tests pass at 100% coverage on new/modified files
- Verified on the real target, not a proxy — and what was verified stated plainly, along with what was not
- Reviewed, all critical issues resolved
- E2E journeys signed off for changed flows
- Agent eval suite green when AI-facing behavior changed (`aidlc/construction/eval.md`)
- Security audit clean if auth/data/API touched
- Build reproducible (locked deps, pinned runtime, deploy traceable to commit SHA)
- 24h post-deploy with green signals (latency, error rate, traffic, saturation)

## Decision gates

Structured-question format in `aidlc/common/decision-gates.md`. Creates an audit trail.

## Tool entry points

| Tool | Entry | Tool-only files |
|------|-------|-----------------|
| Codex CLI | this `AGENTS.md` (hierarchical) | `.codex/skills/`, `.codex/config.toml`, `.codex/hooks.json` |
| Claude Code | `CLAUDE.md` (imports this) | `.claude/{rules,agents,skills}/`, `.claude/settings.json` |
| Cursor IDE | `.cursor/rules/*.mdc` | `.cursor/{rules,agents,skills,hooks}/`, `.cursor/hooks.json` |

All three load skills as `<tool>/skills/<name>/SKILL.md` (the Agent Skills layout) — one directory per phase command, body identical across tools. A flat `skills/<name>.md` is silently ignored by all three; `scripts/audit.sh` fails on it.
