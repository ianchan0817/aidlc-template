# ADR-003: Adapters name no model

- **Status:** Accepted
- **Date:** 2026-07-07
- **Deciders:** maintainer

## Context

Subagent definitions in `.claude/agents/` and `.cursor/agents/` accept a `model:`
field. Naming a specific model there is the natural way to say "review is worth a
bigger model". Model identifiers are also the fastest-rotating string in this
ecosystem: they get renamed, superseded, and retired on a cadence measured in
months, and a template is copied once and then lives for years.

## Scale & performance assumptions

Six agent adapter files today, one `model:` line each. Frontier model
generations turn over roughly every 6–12 months, and a retired identifier is a
hard error at load time in some tools and a silent fallback in others — the
silent case is the expensive one, because the role keeps running at an
unintended tier and nothing reports it.

## Options considered

### Option A: pin each role to a named model
- **Pros:** expresses the cost/quality intent directly; reviewer can be pinned
  higher than engineer.
- **Cons:** guaranteed to expire. An adopter who copied the template a year
  earlier gets an error or a silent downgrade, in a file they never read.
- **Cost:** an unbounded maintenance obligation on every copy ever made.

### Option B: `model: inherit` everywhere
- **Pros:** the role follows whatever the session already chose; never expires;
  the adopter controls tier at one place instead of six.
- **Cons:** cannot express "this role deserves a bigger model" in the file.
- **Cost:** tier selection moves to the human invoking the session.

### Option C: an alias indirection (`model: $REVIEW_MODEL`)
- **Pros:** one place to update.
- **Cons:** no tool resolves such a variable in agent frontmatter; it would be a
  pointer that does not load, which is the failure class this template exists to
  prevent.

## Decision

**Chose Option B**, enforced by a sensor: `scripts/audit.sh` greps the canonical
tree, both entry points, and all three adapter directories for known
model-identifier patterns and fails on any hit.

Reasoning: durability dominated. The value of pinning is a marginal quality gain
on one role; the cost is a template that quietly rots. Tier selection is a
session-level decision the human already makes, so it is not lost — only moved
to where it can be changed without editing six files.

## Consequences

**Positive:**
- The template does not expire; copies stay loadable across model generations.
- No adapter can be wrong about a model that no longer exists.

**Negative:**
- Per-role tiering must be done at invocation time.

**Risks:**
- A future tool could make `model:` mandatory — mitigation: re-verify adapter
  frontmatter against vendor docs at each harness review, per
  `aidlc/operations/retro.md`.

## Follow-ups

- [x] Sensor: no hardcoded model identifiers anywhere in the tree
- [x] Sensor: agent frontmatter carries `name` and `description`, without which
      the subagent silently never registers
