# Session handoffs — one file per session

`memory/sessions/<YYYY-MM-DD>-<slice-slug>.md`. The session that writes it is its
only writer, ever. Read the newest one at session start; write yours at session
end (`aidlc/common/session-lifecycle.md`).

## Why this is not a section of progress.md

Every session rewrote the same "Last session" and "Next session" lines, so two
concurrent sessions collide on those exact lines every time — the conflict cost
was per session, which on a team of five is daily. Splitting by **lifetime** fixes
it at the source: anything that describes *one* session lives in that session's
file, and `memory/progress.md` keeps only state that outlives a session (known
issues, blockers, open questions). One writer per file, so nothing to merge.

A `merge=union` driver on `progress.md` was measured and rejected: with both
sessions rewriting the same line git reports a clean merge and the file then
claims *two* contradictory last sessions; with one session deleting a resolved
issue while another amends that line, union keeps the amendment and silently
discards the resolution. Exit 0 either way, no marker, wrong content — strictly
worse than a conflict you can see.

Same-date, same-slug collisions do conflict. That means two sessions claimed one
slice, which is the case a human should arbitrate.

## Template

```markdown
# 2026-08-10 — <slice>

**Changed** — what moved, in one or two sentences.

**Evidence** — commands run and their result (`bash scripts/audit.sh` exit 0,
zero WARN, zero FAIL). Evidence, not confidence.

**Not verified** — what the evidence does *not* cover. A claim beyond the
evidence is worse than no claim.

**Decisions** — YYYY-MM-DD: decision — rationale. Promote durable ones to
`docs/adr/`.

**Next** — the first concrete action for the next person or agent.
```

## Reading and pruning

```bash
ls memory/sessions/[0-9]*.md | tail -2 | xargs cat   # the last two handoffs
```

ISO dates sort chronologically, so lexical order is chronological order. The
`[0-9]` prefix is not decoration: a plain `*.md` puts this README in every tail,
because `R` sorts after any date. Old
handoffs cost nothing because nobody reads them; when a stretch of them becomes
project narrative worth keeping, fold it into `docs/history.md` and delete the
files.
