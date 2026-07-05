# Example: Feature list (`memory/feature-list.json`)

Structured backlog for incremental work and handoffs. **JSON** reduces accidental edits vs Markdown.

Integrity rules (agents optimize against the sensor — keep it tamper-evident):
- Engineers **append** items; edits to existing entries need reviewer/human approval.
- Only **reviewer** sets `passes: true`, stamping `verified_sha` with the commit it verified.
- A `passes: true` whose `verified_sha` is no longer an ancestor of HEAD for touched files is stale — re-verify.

```json
{
  "version": 1,
  "features": [
    {
      "id": "feat-001",
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
      "verified_sha": null
    }
  ]
}
```

Fields:
- `id` — stable string (e.g. `feat-NNN` or slug).
- `category` — e.g. `functional`, `ux`, `security`, `agent`.
- `description` — one line, outcome-focused.
- `steps` — optional verifiable checklist for runtime QA.
- `verify` — optional command that must pass (deterministic sensor).
- `spec` — optional provenance link to the accepted spec section.
- `passes` — boolean; default `false` until reviewer-verified.
- `verified_sha` — commit verified against; null until then.
