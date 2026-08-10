# ADR-004: Adapt by declaring surfaces, not by deleting methodology

- **Status:** Accepted
- **Date:** 2026-08-10
- **Deciders:** maintainer

## Context

The methodology assumed a browser. `aidlc/construction/e2e.md` named
`data-testid`; `aidlc/operations/operate.md` named four web health signals;
`aidlc/construction/ship.md` assumed a redeploy could always roll back;
`aidlc/rules/testing.md` assumed lines could be instrumented. A headless Go API,
a React Native app and a Next.js site cannot all be served by those assumptions,
and the obvious workaround — an adopter deleting the files that do not apply —
is actively broken here: deleting the two UI rules leaves the backtick reference
to them in `aidlc/inception/design.md` dangling, so `scripts/audit.sh` fails.

## Scale & performance assumptions

Seven surfaces to support (`web`, `mobile`, `http-api`, `grpc`, `events`, `cli`,
`batch`), four release channels, five conditional gates. The methodology budget
is a hard CI failure at 8000 words with roughly 20 words of headroom, so any
mechanism that costs more than a few dozen words per gate is unaffordable.

## Options considered

### Option A: fork per project type
- **Pros:** each fork reads perfectly for its own stack.
- **Cons:** three trees to maintain; a fix lands in one and rots in two. There is
  no update channel for a copied template, so divergence is permanent.
- **Cost:** roughly triple maintenance, forever.

### Option B: adopter prunes the files that do not apply
- **Pros:** no new mechanism; the tree shrinks to what is relevant.
- **Cons:** breaks cross-references and the audit, as above. It also erases the
  distinction between "this gate does not apply here" and "we skipped this gate",
  which is exactly the distinction a review needs.
- **Cost:** a red build on day 0, and no record of what was switched off.

### Option C: a root declaration that switches gates, files stay put
- **Pros:** one file to edit; gates go inert rather than missing; the declaration
  is a readable record of what applies. Reachable on every session through a rule
  slot that is already unconditionally loaded.
- **Cons:** a second indirection — the methodology names the invariant and a
  reference table names the spelling.
- **Cost:** one root file, two adapter pointers, one reference document, and a
  new class of drift if a gate hardcodes a surface anyway.

## Decision

**Chose Option C.** Root `project.yml` declares `surfaces` (a list),
`stateful`, `multi_tenant`, `release` (channel, rollback lever, four signals,
observation window) and `verify` (the commands every phase invokes).

The contract, stated in `aidlc/core-workflow.md` and in both adapter rules: *a
gate whose surface or capability the project does not declare does not apply and
needs no skip rationale; a gate it does declare cannot be skipped.*

Two constraints keep it honest. A field exists only if it switches a **named**
gate — every field in `project.yml` carries a comment naming the gate, and a
field that cannot name one is decoration and is rejected. And the methodology
states invariants only; concrete per-surface spellings live in
`docs/project-shapes.md`, which is outside the word budget.

Reasoning: the binding constraint was that adopters must never edit the
methodology tree, because a copied template has no update channel and every
adopter edit is a permanent fork. Declaration keeps the tree byte-identical
across adopters; pruning does not.

## Consequences

**Positive:**
- One tree serves all seven surfaces; a methodology fix is a template-wide fix.
- Skipped-versus-not-applicable becomes machine-readable, so a reviewer can tell
  a missing gate from an inapplicable one.
- `verify:` gives CI, `init.sh`, and every phase file one set of commands, so the
  shell and the pipeline cannot drift apart.

**Negative:**
- Two hops to a concrete answer: invariant in `aidlc/`, spelling in
  `docs/project-shapes.md`. Web-specific numbers that used to be inline are now
  one file away.
- The declaration can be wrong. A project that under-declares silently switches
  gates off, and that looks identical to passing them.

**Risks:**
- A future gate hardcodes a surface again — mitigation: an anti-explosion sensor
  fails the audit on a backticked surface name inside `aidlc/` unless the same
  line names the `project.yml` field that switches it.
- An adopter leaves `project.yml` half-filled — mitigation: the adopter arm of
  `scripts/audit.sh` fails on a missing file, leftover placeholders, or an empty
  `surfaces`, `release.rollback`, or `verify.test`.
- Codex has no rules directory, so the always-on rule cannot reach it —
  mitigation: `AGENTS.md` names `project.yml` in its first section and tells
  Codex to read it at session start.

## Migration path

Adopters of an earlier copy: add `project.yml`, add the two adapter rule
pointers, delete the old stack rule and its two adapter pointers, and replace any
reference to it with `project.yml` (the eval runner path moved to
`verify.eval`). No methodology file needs deleting — that is the point.

## Follow-ups

- [x] Anti-explosion sensor over `aidlc/`
- [x] Adopter arm validating the declaration
- [ ] Run a real Go API, RN app and Next.js repo through the template and record
      which gates were unclear — the current claim rests on reading, not on
      three executed adoptions
