# Design

Phase: Inception. UI/component design specs, mobile review, interaction patterns.

## Process
1. **UX Review** — primary action obvious? Visual hierarchy? 4px grid? Works at 375/768/1280px? Mobile: one-thumb reach, no horizontal scroll, correct input types. States: loading/empty/error/success all defined. Type scale consistent, body >=16px mobile, WCAG AA contrast.
2. **Component Specs** — for each new/modified component: purpose, anatomy (sizes/tokens/spacing), states (default/hover/pressed/disabled/loading/error), responsive behavior, accessibility (ARIA, keyboard), do/don't.
3. **Handoff** — every screen state described, component inventory, responsive notes, edge cases (long names, empty, slow). If new UX patterns emerge, update the `ux-guidelines` rule in your tool's rules directory.
