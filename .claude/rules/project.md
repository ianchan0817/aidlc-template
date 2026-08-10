---
description: Project shape — surfaces, release model, verify commands. Fill before first session.
---

Read `project.yml` at the repo root before applying any gate. It declares this
project's surfaces, statefulness, tenancy, release model, and verify commands.

A gate whose surface or capability `project.yml` does not declare does not apply
and needs no skip rationale; a gate it does declare cannot be skipped. Adapt by
editing `project.yml` — never by deleting methodology files.

Concrete per-surface reference (e2e identity, health signals, rollback lever,
coverage equivalent): `docs/project-shapes.md`.
