# UX guidelines

## Layout & type
- Spacing: 4px grid. Tokens: 4/8/12/16/24/32/48px.
- Type: display 32+/700, h1 28/700, h2 22/600, h3 18/600, body 16/400, small 14/400, micro 12/400. Min 12px; micro for timestamps only.
- Color: primary=actions, destructive=irreversible (confirm first), success, warning, muted. Never color-only — pair with icon/label.

## Mobile & interaction
- 44×44pt min tap, primary CTA above fold, no horizontal overflow, correct input types, bottom sheet > modal.
- Transitions 200–300ms ease-out; feedback 100–150ms. Skeleton for loads >300ms. Optimistic UI for toggles/likes/saves.
- Every interactive element: stable `data-testid` (`{component}-{role}`, e.g. `login-form-submit`); never auto-generated; change only when the element's purpose changes.

## Performance budgets (adjust per stack)
- Largest Contentful Paint <2.5s; Interaction latency <200ms; layout shift <0.1.
- Initial compressed JS <150KB. Lazy-load below-the-fold. Virtualize lists >100 items.
- CSS: design tokens only, mobile-first, animate `transform`/`opacity` only.
