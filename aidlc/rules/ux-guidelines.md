# UX guidelines

## Layout & type
- Spacing: 4px grid. Tokens: 4/8/12/16/24/32/48px.
- Type: display 32+/700, h1 28/700, h2 22/600, h3 18/600, body 16/400, small 14/400, micro 12/400. Min 12px; micro for timestamps only.
- Color: primary=actions, destructive=irreversible (confirm first), success, warning, muted. Never color-only — pair with icon/label.

## Every state is a design
Ship all five before calling a view done: **loading** (skeleton, not spinner, past 300ms), **empty** (say what to do next, not "no data"), **partial**, **error** (what failed, what to do, how to retry), **success**. An unhandled empty or error state is an unfinished feature.

## Responsive & mobile
- Mobile-first: design at 375px, scale up. Breakpoints are content-driven, not device-named.
- 44×44pt minimum tap target; 8px minimum between adjacent targets.
- Primary CTA reachable without scrolling; no horizontal overflow at any width.
- Correct input types and `autocomplete` (`email`, `tel`, `numeric`) so mobile keyboards match the field.
- Bottom sheet over modal on small screens. Never a hover-only affordance — touch has no hover.
- Wide content (tables, code, diagrams) scrolls inside its own container; the page body never scrolls sideways.

## Accessibility (WCAG 2.1 AA floor)
- Contrast ≥4.5:1 body text, ≥3:1 large text and meaningful UI boundaries.
- Full keyboard operability: logical tab order, visible focus, no traps, Escape closes overlays. Focus moves into a dialog on open and returns to the trigger on close.
- Semantic elements first (`button`, `nav`, `label`); ARIA only to fill a genuine gap. A `div` with a click handler is not a button.
- Every input has a programmatic label; every non-decorative image has alt text; decorative images have empty alt.
- Announce async results in a live region — a silent DOM change is invisible to a screen reader.
- Honor `prefers-reduced-motion`; never convey meaning by motion or color alone.
- Target AA in CI (axe or equivalent) on changed views; automated checks catch roughly half, so keyboard-walk each new flow once by hand.

## Interaction
- Transitions 200–300ms ease-out; direct feedback 100–150ms. Optimistic UI for toggles/likes/saves, with rollback on failure.
- Destructive actions confirm, and name the thing being destroyed.
- Every interactive element gets a stable `data-testid` (`{component}-{role}`, e.g. `login-form-submit`) — never auto-generated; change only when the element's purpose changes.

## Performance budgets (adjust per stack)
- Largest Contentful Paint <2.5s; interaction latency <200ms; layout shift <0.1.
- Initial compressed JS <150KB. Lazy-load below the fold. Virtualize lists >100 items.
- CSS: design tokens only, mobile-first, animate `transform`/`opacity` only.
- Reserve space for async content (width/height or aspect-ratio) so nothing shifts on load.
