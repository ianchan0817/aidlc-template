# Contributing

This repo is a methodology template, so the bar is unusual: **the change has to
survive being copied into someone else's project, on a different tool, with a
different model.**

Security reports do not go here — see [SECURITY.md](SECURITY.md).

## The one gate

```bash
bash scripts/audit.sh
```

Exit 0 or it isn't ready. It enforces what review can't reliably catch:

- word budgets (root, methodology, artifact templates, and per file)
- valid JSON in every hook config
- no broken internal references
- no hardcoded model IDs — `model: inherit` only
- no `../` path chains
- shell syntax on every script
- skill / subagent / rule **shape**, per tool, identical sets
- every rule has a working attach path (`globs`, `alwaysApply`, or `paths`)
- hook output schemas match each tool's contract
- the command guard's own self-test
- README renders without horizontal scrolling on mobile

## Rules for changes

**Single source of truth.** Content lives once in `aidlc/`. Tool directories
(`.claude/`, `.cursor/`, `.codex/`) hold only pointers plus the frontmatter that
tool's loader requires. If you find yourself pasting the same paragraph twice,
the second copy is the bug.

**Repo-rooted paths only.** Never `../../` — a moved file must not break a
reference. The audit fails on it.

**Tool- and model-agnostic.** No model IDs, no vendor runtime dependencies, no
stack-specific commands outside `aidlc/rules/tech-stack.md`.

**Add a sensor, not just a rule.** Guidance is advisory to a model; a sensor is
deterministic. When you add an invariant, ask whether the audit can check it —
and if you add a check, **negative-test it**: regress the invariant on a scratch
copy and confirm the audit exits non-zero. A sensor that cannot fail is theater.

**Earn the words.** Adding to a phase file or rule usually means displacing
something. State what you compressed.

**Two failures before a new rule.** `aidlc/operations/retro.md` is explicit:
add guidance after the same failure has appeared twice, and delete rules the
model already follows unprompted.

## Verifying adapter changes

The audit checks *shape*, not behaviour. A structurally valid adapter can still
be ignored by a tool. So for anything touching `.claude/`, `.cursor/`, or
`.codex/`, also confirm it loads live — the slash command appears, the subagent
registers, the rule attaches, the hook actually blocks — and say so in the PR.

Vendor formats change without notice. If a format claim is load-bearing, link
the vendor doc.

## Commits and PRs

Conventional-ish prefixes (`feat:`, `fix:`, `docs:`, `refactor:`, `chore:`), with
a scope where it helps (`fix(adapters):`). Explain the *why* and the evidence in
the body — the PR template asks for exactly what's needed.
