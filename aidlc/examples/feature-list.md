# Example: Feature list (`memory/features/`)

Structured backlog for incremental work and handoffs. **One JSON file per
feature**, named for its id, because a single shared array makes every concurrent
session collide on the same lines and a conflict marker inside JSON stops the file
that gates every sign-off from parsing. Full schema, ordering and query recipes:
`memory/features/README.md`.

`memory/feature-list.json` is the **manifest** — schema version plus the glob that
locates records. Never append features to it.

```json
{ "schema": 2, "records": "memory/features/*.json", "features": [] }
```

A record, `memory/features/<id>.json`:

```json
{
  "id": "feat-001",
  "priority": 100,
  "category": "functional",
  "description": "New chat button creates a fresh conversation",
  "steps": [
    "Navigate to main interface",
    "Click the New Chat control",
    "Verify a new conversation is created and appears in sidebar"
  ],
  "verify": "bun test chat/new-conversation",
  "spec": "docs/specs/chat.md#new-conversation",
  "passes": false,
  "verified_sha": null,
  "verified_by": null
}
```

Fields:
- `id` — stable string (e.g. `feat-NNN` or slug), **equal to the filename minus
  `.json`**. That binding is what makes ids unique: a directory cannot hold two
  `feat-001.json`, so no scan has to remember to check.
- `priority` — integer, lower runs sooner; absent sorts as 1000. Ties break on
  `id`, so two sessions choosing the same number is not a conflict.
- `category` — e.g. `functional`, `ux`, `security`, `agent`.
- `description` — one line, outcome-focused.
- `steps` — optional verifiable checklist for runtime QA.
- `verify` — optional command that must pass (deterministic sensor).
- `spec` — optional provenance link to the accepted spec section.
- `passes` — boolean; `false` until reviewer-verified.
- `verified_sha` — full 40-char commit id verified against; `null` until then. A
  revision expression (`HEAD`, `main`) is rejected — it resolves to today's tip,
  so the QA it claims can never be re-run against what was reviewed.
- `verified_by` — who ran the QA; `null` until then.

Integrity rules (agents optimize against the sensor — keep it tamper-evident):
- Engineers **create** records; edits to someone else's need reviewer/human
  approval.
- Only **reviewer** sets `passes: true`, stamping `verified_sha` and `verified_by`
  in the same commit. One small file means `git log -p` on the record shows
  exactly which commit claimed the sign-off.
- A `passes: true` whose `verified_sha` predates changes to the code it covers is
  stale — re-verify.
