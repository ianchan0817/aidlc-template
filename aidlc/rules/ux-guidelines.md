# UX guidelines

Applies when `project.yml` declares a `web` or `mobile` surface. Visual vocabulary lives in `aidlc/rules/design-tokens.md`; this file is how a screen should **behave**.

## Hierarchy & position
- One primary action per view. If two compete, one is secondary — decide which.
- Position by importance: the thing you want clicked goes where the eye lands, not where there was room.
- Proximity is grouping. A label belongs nearer its own field than the field above it.
- Align to a shared edge — a ragged margin reads as broken even when nothing is.
- On mobile, primary actions live in the lower third (thumb reach). Destructive ones do not.
- Sticky elements cost screen height; earn it.

## Every state is a design
Ship all five: **loading** (skeleton, not spinner, past 300ms), **empty** (say what to do next, not "no data"), **partial**, **error** (what failed, what to do, how to retry), **success**. An unhandled empty or error state is an unfinished feature.

## Interaction
- Clickable things look clickable, and anything that looks clickable is.
- Acknowledge input within ~100ms even when the result is slow — an unacknowledged tap reads as broken.
- Prefer undo over confirm: dialogs train people to click through. Where confirmation is unavoidable, name the thing being destroyed and put the consequence in the button, not "OK".
- Prevent errors rather than report them: constrain inputs, default sensibly, disable what cannot apply — and say why it's disabled.
- Forgiving on input, strict on storage: accept stray whitespace and any sane date format; normalize on the way in.
- Progressive disclosure: common path visible, the rest one deliberate click away. Never hide something required.
- Never lose typed input to a navigation, validation failure, or refresh.
- Durations come from the motion tokens. Optimistic UI for toggles/saves, with visible rollback on failure.
- Every interactive element carries a stable, purpose-named test identifier — never auto-generated (`aidlc/construction/e2e.md`).

## Responsive & mobile
- Mobile-first: design at 375px, scale up. Breakpoints follow content, not device names.
- 44×44pt minimum tap target, 8px between adjacent targets.
- Primary CTA reachable without scrolling; no horizontal overflow at any width.
- Correct input types and `autocomplete` so the mobile keyboard matches the field.
- Bottom sheet over modal on small screens. No hover-only affordance — touch has no hover.
- Wide content (tables, code, diagrams) scrolls in its own container; the page never scrolls sideways.
- Reserve space for async content so nothing shifts on load.

## Accessibility (WCAG 2.1 AA floor)
- Contrast per the named pairs in `design-tokens.md`.
- Full keyboard operability: logical tab order, visible focus, no traps, Escape closes overlays. Focus enters a dialog on open, returns to the trigger on close.
- Semantic elements first (`button`, `nav`, `label`); ARIA only for a real gap. A `div` with a click handler is not a button.
- Every input has a programmatic label; non-decorative images have alt text.
- Announce async results in a live region — a silent DOM change is invisible to a screen reader.
- Honor `prefers-reduced-motion`. Never convey meaning by motion or color alone.
- Nothing flashes more than three times per second — a seizure threshold, not a preference; `prefers-reduced-motion` does not cover it. Parallax and auto-advance are opt-out.
- One term per concept across every surface: if it's "archive" in the menu it isn't "hide" in the toolbar.
- AA checks in CI on changed views; automated tools catch ~half, so keyboard-walk each new flow once by hand.
