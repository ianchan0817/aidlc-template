# Code style

Formatting and naming follow the language's canonical formatter — gofmt, black/ruff, rustfmt, ktlint, SwiftFormat, Prettier — configured in the repo and enforced in CI. Never hand-format against it.

## Language-neutral
- Functions: single responsibility, max 30 lines, early returns over nesting
- Booleans read as predicates: `is`, `has`, `can`, `should`
- Imports: absolute over relative, grouped external → internal → local, none unused
- Comments: why not what, no commented-out code, `TODO(name)` with issue link

## TypeScript
- No `any`, explicit return types on public functions, `interface` for objects, `type` for unions, strict mode, no unguarded `!`
- `camelCase` values, `PascalCase` types/components, `SCREAMING_SNAKE_CASE` constants, `kebab-case` files/CSS
