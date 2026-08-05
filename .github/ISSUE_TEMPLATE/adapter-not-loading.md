---
name: Adapter not loading
about: A rule, skill, or subagent that a tool silently ignores
title: "adapter: <tool> ignores <file>"
labels: [adapter, bug]
---

Every tool ignores a malformed adapter **silently** — no error, just an absent
capability. That makes this the highest-value bug class in the template, so
please be precise.

**Tool and version**
<!-- Claude Code / Codex CLI / Cursor, plus version and OS -->

**Adapter file**
<!-- e.g. .cursor/rules/code-style.mdc, .claude/skills/spec/SKILL.md -->

**Expected vs observed**
<!-- "/spec should appear as a slash command" vs "not listed" -->

**Does the audit catch it?**

```
$ bash scripts/audit.sh
```

<!-- If the audit passes but the adapter is dead, that is a MISSING SENSOR and
     the more important half of the report — say so. -->

**Vendor documentation**
<!-- Link the doc that specifies the correct format, if you found it. Formats
     change; a doc link is what lets us fix this without guessing. -->
