# 2026-08-10 — surfaces declaration

**Changed** — added `project.yml` and the always-on `project` rule for Claude Code
and Cursor, dereferenced the five gates that hardcoded a browser, added
`aidlc/.template` as the template/adopter mode marker, and moved the maintainer
log to `docs/history.md` with four ADRs under `docs/adr/`.

**Evidence** — `bash scripts/audit.sh` exit 0, zero WARN, zero FAIL.

**Not verified** — no Go, React Native, or Next.js project has actually been run
through the template. The shape-neutrality claim rests on reading, not on three
executed adoptions.

**Decisions** — 2026-08-10: adapt by declaring in `project.yml`, never by deleting
methodology — deleting the UI rules dangles a reference and fails the audit
(ADR-004). 2026-08-10: word budgets are FAIL, not WARN — a WARN exits 0, so a PR
that blew the cap merged green and the budget enforced nothing. 2026-08-10:
`aidlc/.template` selects the sensor set — maintainer-only sensors measure the
template's own shape and say nothing about an adopter's product. 2026-07-07:
prose pointers, not `@`-imports (ADR-001); repo-rooted paths only (ADR-002); no
hardcoded model IDs (ADR-003).

**Next** — adopt the template into one real non-web repo and record which gates
were unclear. Adapter formats also move fast — re-verify skill and agent
frontmatter against vendor docs at each harness review
(`aidlc/operations/retro.md` step 3), since a format change turns every pointer
into a silent no-op.
