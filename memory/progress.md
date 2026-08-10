# Project memory

Lean handoff across sessions. Git holds history; this file holds **decisions**,
**context**, and **next actions**. Read at session start and updated at session
end, per `aidlc/common/session-lifecycle.md`.

Keep it short. Everything here is re-read every session, so a long log costs
context on every turn and buys nothing that `git log` does not already give you.
Narrative that has stopped being actionable belongs in `docs/history.md`;
architectural rationale belongs in an ADR under `docs/adr/`.

## Current focus
<!-- 1-2 sentences: active initiative or slice + phase (inception/construction/operations) -->
Template maintenance. `project.yml` declares the shape; adaptation is by
declaration, never by deleting methodology files.

## Last session
<!-- What changed, and the evidence: commands run, what passed, what was NOT verified -->
Surfaces-declaration round: added `project.yml` and the always-on `project` rule
for Claude Code and Cursor, dereferenced the five gates that hardcoded a browser,
added `aidlc/.template` as the template/adopter mode marker, and moved the
maintainer log to `docs/history.md` with four ADRs under `docs/adr/`. Evidence:
`bash scripts/audit.sh` exit 0, zero WARN, zero FAIL. Not verified: no Go, React
Native, or Next.js project has actually been run through the template — the
shape-neutrality claim rests on reading, not on three executed adoptions.

## Next session
<!-- First concrete action for the next person or agent -->
Adopt the template into one real non-web repo and record which gates were
unclear. Adapter formats also move fast — re-verify skill and agent frontmatter
against vendor docs at each harness review (`aidlc/operations/retro.md` step 3),
since a format change turns every pointer into a silent no-op.

## Recent decisions
<!-- YYYY-MM-DD: decision - rationale (one line each). Promote durable ones to docs/adr/. -->
2026-08-10: Adapt by declaring in `project.yml`, never by deleting methodology —
deleting the UI rules dangles a reference and fails the audit (ADR-004).
2026-08-10: Word budgets are FAIL, not WARN — a WARN exits 0, so a PR that blew
the cap merged green and the budget enforced nothing.
2026-08-10: `aidlc/.template` selects the sensor set — maintainer-only sensors
measure the template's own shape and say nothing about an adopter's product.
2026-07-07: Prose pointers, not `@`-imports (ADR-001); repo-rooted paths only
(ADR-002); no hardcoded model IDs (ADR-003).

## Blocked on the owner (cannot be committed)
<!-- Anything only a human with repo/account access can do -->
GitHub toggles, verified 2026-08-10 and detailed in `docs/repo-setup.md`:
private vulnerability reporting is **off** (so `SECURITY.md` points at a Report
button that is not rendered), Dependabot **security** updates are **off**, and
there are **no branch rulesets**, so `audit` and `shellcheck` report without
blocking a merge.

## Open questions
<!-- One owner per item -->
None.

## Known issues
<!-- Active bugs or debt; delete the line when it is resolved -->
None.
