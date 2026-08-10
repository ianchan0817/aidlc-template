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
- **Scope limits are now disclosed to adopters** in README.md ("What this is
  proven to fit, and what it is not") rather than only here. The limits stand:
  no `library` surface, `release.*` are scalars so a monorepo cannot declare
  per-surface levers, ML model quality has no gate, a fourth tool gets no guard.
- **`guard-mutate.sh` cannot find a missing case class** — it permutes spellings
  of rows it was given. It generated 1,511 cases and found none of the five
  false-positive mechanisms fixed on 2026-08-10.
