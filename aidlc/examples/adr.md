# Example: ADR

Fill-in template for `docs/adr/ADR-NNN-title.md`. Produced by `aidlc/construction/plan.md` when an architectural decision is involved.

```markdown
# ADR-NNN: [Decision Title]

- **Status:** Proposed | Accepted | Superseded by ADR-XXX
- **Date:** YYYY-MM-DD
- **Deciders:** [names / roles]

## Context

[2–4 sentences. The forces at play. What problem are we solving? What constraints apply (scale, latency, team skills, existing infra)? Why now?]

## Scale & Performance Assumptions

[Concrete numbers. Read/write ratio. Expected QPS. Data volume. SLO targets. Without these, the decision can't be evaluated.]

## Options Considered

### Option A: [name]
- **Pros:** [...]
- **Cons:** [...]
- **Cost:** [time / money / complexity]

### Option B: [name]
- **Pros:** [...]
- **Cons:** [...]
- **Cost:** [...]

### Option C: [name]
- ...

## Decision

**Chose Option [X].**

Reasoning: [Which constraint dominated. What trade-off we explicitly accepted.]

## Consequences

**Positive:**
- [...]

**Negative:**
- [...]

**Risks:**
- [risk] — mitigation: [...]

## Migration Path

[If this replaces an existing system: how we get from here to there. Backward compat strategy. Rollback plan.]

## Follow-ups

- [ ] [Action item]
- [ ] [Action item]
```
