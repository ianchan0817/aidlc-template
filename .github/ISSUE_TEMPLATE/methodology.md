---
name: Methodology change
about: Add, change, or remove a rule, phase, or gate
title: "methodology: <short description>"
labels: [methodology]
---

**What should change**

**What failure prompted it**
<!-- The template's own rule: add guidance only after the same failure has
     appeared twice (aidlc/operations/retro.md). What were the two? -->

**Guide or sensor?**
<!-- A guide gives context before action; a sensor catches drift after it.
     Prefer a deterministic sensor where one is possible — and say which this
     is, because "add a rule" is often the weaker answer. -->

**Token cost**
<!-- Budgets: methodology <8000 words total, 700 per file. What does this add,
     and what should it displace? `bash scripts/audit.sh` reports current use. -->

**Tool- and model-agnostic?**
<!-- Must hold on Claude Code / Codex / Cursor and on any model. Anything
     naming a specific model or a vendor runtime is out of scope. -->
