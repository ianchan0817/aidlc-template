# ADR-001: Adapters use prose pointers, not `@`-imports

- **Status:** Accepted
- **Date:** 2026-07-07
- **Deciders:** maintainer

## Context

Methodology lives once in `aidlc/`; each tool directory (`.claude/`, `.cursor/`,
`.codex/`) holds only what that tool's loader requires. Something has to carry a
loader-visible file to its canonical body. Claude Code supports `@path` imports,
which inline a file at load time and are the obvious mechanism — for one tool.

## Scale & performance assumptions

Three tools, 14 phase commands, 7 rules, 3 roles: roughly 70 adapter files, each
pointing at exactly one canonical file. Each pointer costs one extra file read
per invocation, on the order of a few hundred tokens; the alternative costs a
whole-tree rewrite whenever a file moves.

## Options considered

### Option A: `@`-imports in Claude adapters, prose pointers elsewhere
- **Pros:** content is inlined for Claude with no extra read.
- **Cons:** `@` resolves **relative to the containing file**, so every adapter
  needs a `../../aidlc/...` chain; the chains break on any move, and the two
  other tools ignore `@` entirely, so the bodies diverge per tool.
- **Cost:** three shapes to maintain, and a silent no-op on two of the three.

### Option B: prose pointers everywhere ("Read and execute `aidlc/<phase>/<name>.md`")
- **Pros:** repo-rooted paths, one identical body across all three tools, and a
  path string a sensor can check for existence.
- **Cons:** one extra Read per invocation.
- **Cost:** a small per-invocation token cost, paid every time.

### Option C: duplicate the canonical body into each adapter
- **Pros:** no indirection at all.
- **Cons:** three copies of every rule. Copies drift — proven in this repo, where
  three inline copies of one command-guard regex diverged until one matched the
  raw JSON payload.

## Decision

**Chose Option B.**

Reasoning: single-source-of-truth dominated. Option A buys a token saving in one
tool at the price of `../../` chains and per-tool divergence, and Option C
guarantees drift. A pointer is also *checkable*: `scripts/audit.sh` verifies
every backtick-quoted repo path resolves, so a dead pointer fails CI rather than
failing quietly mid-session.

Root `CLAUDE.md` still `@`-imports root `AGENTS.md`. That is one import, at the
repo root, where no relative chain exists — not an adapter pointer.

## Consequences

**Positive:**
- One canonical body per concept; three-tool symmetry is structural.
- Pointer correctness is a deterministic sensor, not a convention.

**Negative:**
- One extra file read per skill or rule invocation.

**Risks:**
- A tool could start resolving `@` repo-rooted, making Option A viable —
  mitigation: re-check at each harness review (`aidlc/operations/retro.md`).

## Follow-ups

- [x] Audit sensor: broken internal reference check
- [x] Audit sensor: no `../` path chains in `aidlc/` or adapter directories
