# Example: Implementation notes (`memory/plans/{feature}-notes.md`)

Timestamped log kept **while building**. Captures mid-build surprises that would otherwise vanish into scrollback. On deviation: pick the conservative option, log it, keep going — don't block, don't silently improvise.

Entry types:

- **plan-confirmed** — step proceeded as planned (one line; keeps the log honest)
- **discovery** — existing pattern/infrastructure found mid-build
- **deviation** — what the plan assumed / what the code revealed / conservative choice made / revisit marker
- **todo-for-human** — decision needing product judgment; don't guess
- **fold-back** — bullets to paste into the next plan revision

```markdown
## 14:12 deviation
Plan assumed exports stream from `ExportService`; code reveals it buffers
whole files in memory. Conservative choice: keep buffering, cap at 50MB
with a clear error. Revisit: streaming refactor (own slice).

## 15:03 todo-for-human
Legacy rows have no `owner_id`. Export them as "unassigned" or skip?
Product call — blocked feature-list steps 4–5 until answered.

## fold-back (end of session)
- Precondition next plan on the 50MB buffer cap decision
- Ask the owner_id question at the next decision gate
```

Fold-back bullets become preconditions in the next plan — the loop that stops the next session from rediscovering this one's surprises. Review deviations at retro: repeated ones signal a guide gap or a sensor gap.
