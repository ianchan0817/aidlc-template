# Example: Feature list (`memory/feature-list.json`)

Structured backlog for incremental work and handoffs. **JSON** reduces accidental edits vs Markdown. Engineers may add items or edit descriptions; only **reviewer** sets `passes: true` after verification.

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
        "Verify a new conversation is created",
        "Verify chat area shows welcome state",
        "Verify conversation appears in sidebar"
      ],
      "passes": false
    }
  ]
}
```

Fields:
- `id` — stable string (e.g. `feat-NNN` or slug).
- `category` — e.g. `functional`, `ux`, `security`, `agent`.
- `description` — one line, outcome-focused.
- `steps` — optional verifiable checklist for runtime QA.
- `passes` — boolean; default `false` until reviewer-verified.
