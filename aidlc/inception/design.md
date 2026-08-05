# Design

Phase: Inception. UI/component specs, mobile review, interaction patterns.

Rules: `aidlc/rules/design-tokens.md` (color roles, type, spacing, motion) and `aidlc/rules/ux-guidelines.md` (hierarchy, states, interaction, a11y).

Can't articulate the design? Render **design directions** to react to, and **mock with fake data** before wiring — `aidlc/common/unknowns.md`.

## Process
1. **Job, not screen** — who is this for, what are they trying to finish, what does done feel like? Write the one-sentence job before drawing anything; a design that can't name its job is decoration.
2. **Structure before style** — what information, in what priority, grouped how. Get hierarchy right in greyscale: if it doesn't work without color, color won't save it.
3. **Flow** — happy path end to end, then the branches: first run, empty, slow, offline, permission denied, too much data, long names, other locales. Each branch is a state you owe a design.
4. **Tokens** — express the design in existing tokens. A new token is a deliberate decision, not a side effect of one screen; add it with its contrast pair.
5. **Component specs** — per component: purpose, anatomy (tokens used), all states (default/hover/focus/pressed/disabled/loading/error/empty), responsive behavior, keyboard and ARIA contract, one do/don't pair.
6. **Self-critique** — walk it as a stranger. What is the primary action, obvious in two seconds? What can't be undone? What breaks at 375px, at 200% zoom, keyboard-only? Fix that before anyone else reads it.
7. **Handoff** — every state described, component inventory (reuse vs new), responsive notes, edge cases. New pattern → update the rules so the next feature inherits it.

## Gate
Job stated · hierarchy legible in greyscale · every state designed · tokens not raw values · keyboard and contrast accounted for.
