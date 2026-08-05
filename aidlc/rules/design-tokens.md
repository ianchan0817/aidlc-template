# Design tokens

Tokens are the product's visual vocabulary. Components reference tokens, never raw values — a hardcoded hex or px cannot be themed, audited, or changed once. Fill in the values per project; keep the structure.

## Color — name by role, not by hue
- Roles, not colors: `surface`, `surface-raised`, `text`, `text-muted`, `border`, `primary`, `success`, `warning`, `danger`, `info`. `blue-500` inside a component is a leak; `--color-primary` survives a rebrand.
- Each role ships as a small set, not one value: `base`, `hover`, `active`, `subtle` (tinted background), and `on-<role>` — the foreground guaranteed readable on it.
- Palette size: one primary, one neutral ramp (7–9 steps), four status hues. Past that, nothing reads as emphasis.
- Every foreground/background combination the product actually uses is a **named pair with a measured ratio** (≥4.5:1 body text, ≥3:1 large text and meaningful UI boundaries). An unnamed pair is an unchecked pair.
- Reserve `danger` for irreversible actions. If everything is red, nothing is.
- Dark mode is a second set of role values, not inverted lightness: lift surfaces instead of darkening text, desaturate accents, and avoid pure black or pure white.
- Never carry meaning in hue alone — pair with icon, text, or weight.

## Type
- One scale, ~1.2–1.25 ratio, six or seven steps. Line-height moves inversely to size: ~1.5 body, ~1.2 headings.
- Measure 45–75 characters. Wider loses the line return; narrower breaks rhythm.
- Two or three weights (e.g. 400/600/700). Weight and size carry hierarchy — not color.
- Body ≥16px on mobile (smaller triggers iOS zoom-on-focus). Nothing below 12px.
- One UI family plus one mono for code. Tabular numerals for any column of numbers.
- Set `font-display: swap` and a matched fallback stack so text is readable before the webfont lands.

## Spacing, radius, elevation, motion
- Spacing on a 4px base: 4/8/12/16/24/32/48. Space belongs to the container, not scattered margins on children.
- Radius: two or three steps, consistent within a component family. Nested corners shrink inward.
- Elevation: three or four steps, each a shadow **and** a surface value. Elevation signals layering — dropdown, sticky, modal — not decoration.
- Motion: two or three durations (~100/200/300ms) and two easings, all tokenized. Every duration in the product is one of them.
