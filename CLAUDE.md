# CLAUDE.md

## Behavior

- Output code/answers directly. No preamble, no "I'll help you with...".
- Diff-only output unless full rewrite requested.
- Stop within 5 seconds of detecting logic drift — ask to clarify, don't guess.
- At turn 15+, prompt user to run `/compact`.
- If user repeats an instruction, ask: "Edit your last message instead?"

## Agents

| Agent | When |
|-------|------|
| `engineer` | Build, test, deploy, architecture, DB, CI/CD |
| `reviewer` | Code review, security audit, E2E sign-off, retros |
| `manager` | New initiative, cross-concern coordination, daily report |

## Lifecycle (WHAT → HOW → RUN)

**Inception (WHAT/WHY):** `/project:spec` → `/project:design`
**Construction (HOW):** `/project:plan` → `/project:build` → `/project:test` → `/project:review` → `/project:security` → `/project:e2e` → `/project:ship`
**Operations (RUN):** `/project:operate` → `/project:retro`

Also: `/project:daily-report`, `/project:investigate`. Each phase has a human-approved gate before the next begins.

## Rules (loaded as separate files)

All rules in `.claude/rules/` — single source of truth. Agents and skills reference rules, never restate them.

## Non-Negotiables

- 100% test coverage on new/modified code
- Code review before merge
- E2E sign-off before release
- Security review for auth/data/API changes
- Log errors before fixing
- Recurring errors (2+) → update agent file
- Reproducible builds (locked deps, pinned runtime, CI is truth)
- Every production incident → fix, test, or rule update (close the loop)

## Memory

After major tasks, update `.claude/memory/progress.md`: what changed, decisions, what's next.
Derive status from `git log`. ADRs in `.claude/docs/adr/ADR-NNN-title.md`.

## Build Commands

```bash
# Fill in your project's actual commands
# bun install / bun dev / bun test / bun run build
```
