# Project memory — cross-session state

Only state that **outlives a session** lives here: known issues, blockers, open
questions. It is re-read every session, so a long log costs context on every turn
and buys nothing `git log` does not already give you.

Per-session handoff — what changed, evidence, decisions, next action — is one
file per session in `memory/sessions/`, because a field every session rewrites is
a line every concurrent session collides on. Read the newest handoff at session
start (`memory/sessions/README.md`). Backlog records are one file per feature in
`memory/features/` (`memory/features/README.md`). Architectural rationale belongs
in an ADR under `docs/adr/`; finished narrative in `docs/history.md`.

## Blocked on the owner (cannot be committed)
<!-- Anything only a human with repo/account access can do -->
GitHub toggles, verified 2026-08-10 and detailed in `docs/repo-setup.md`: private
vulnerability reporting is **off** (so `SECURITY.md` points at a Report button
that is not rendered), Dependabot **security** updates are **off**, and there are
**no branch rulesets**, so `audit` and `shellcheck` report without blocking a
merge.

## Open questions
<!-- One owner per item -->
None.

## Known issues
<!-- Active bugs or debt; delete the line when it is resolved -->
- **Four rules load unconditionally**, not one: `project`, `testing`, `security`,
  `reproducibility` (no `paths:` on Claude, `alwaysApply: true` on Cursor).
  `CLAUDE.md` says "One exception: `rules/project.md`" — false. Each pointer also
  forces a read of its canonical body, so the real per-session cost is above the
  ~3,069 tokens the always-on files measure. Fix: scope `testing` and
  `reproducibility` by source glob, or correct the doc. Nothing senses the count.
- **`AGENTS.md` still names `memory/feature-list.json` as the backlog** in six
  places; schema 2 made it a manifest and `memory/features/README.md` says never
  to append to it. The stale instruction is in the always-loaded file.
- **"Adaptive to all projects" is overstated.** Proven: seven surfaces, one
  release train, Claude Code or Cursor. Not expressible: a published library
  (`surfaces: [library]` fails the enum, and semver/compat has no gate), a
  monorepo needing per-surface rollback levers (`release.*` are scalars), ML
  model quality (eval.md is scoped to agent behavior). A fourth tool gets no
  skills, no agent registration, and no guard.
- **`guard-mutate.sh` cannot find a missing case class** — it permutes spellings
  of rows it was given. It generated 1,511 cases and found none of the five
  false-positive mechanisms fixed on 2026-08-10.
