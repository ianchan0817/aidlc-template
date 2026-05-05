---
description: Code style — naming, formatting, TypeScript strictness
paths:
  - "**/*.{ts,tsx,js,jsx,mjs,cjs}"
  - "**/*.{py,go,rs,java,kt,swift,rb}"
---

# Code Style

Mirror of `aidlc/rules/code-style.md` — keep in sync.

- 2-space indent, single quotes, no trailing semicolons, max 100 chars, trailing newline
- `camelCase` vars/functions, `PascalCase` types/components, `SCREAMING_SNAKE_CASE` constants, `kebab-case` files/CSS
- Booleans: `is`, `has`, `can`, `should` prefix
- TypeScript: no `any`, explicit return types on public functions, `interface` for objects, `type` for unions, strict mode, no unguarded `!`
- Functions: single responsibility, max 30 lines, early returns over nesting
- Imports: absolute > relative, grouped (external → internal → local), no unused
- Comments: why not what, no commented-out code, `// TODO(name): description` with issue link
