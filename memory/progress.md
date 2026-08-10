# Project memory — cross-session state

Only state that **outlives a session** belongs here: known issues, blockers, open
questions. This file is re-read every session, so a long log costs context on
every turn and buys nothing `git log` does not already give you.

Everything else has a home with a matching lifetime. One session's handoff —
what changed, the evidence, the next action — goes in `memory/sessions/`, because
a field every session rewrites is a line every concurrent session collides on.
Backlog records are one file per feature in `memory/features/`. Architectural
rationale becomes an ADR under `docs/adr/`.

## Blocked on the owner (cannot be committed)
<!-- Only a human with repo or account access can action these. Delete when done. -->
None.

## Open questions
<!-- One named owner per item, or it is not a question, it is a wish. -->
None.

## Known issues
<!-- Active bugs or debt. Delete the line when it is resolved, not when it is noticed. -->
None.
