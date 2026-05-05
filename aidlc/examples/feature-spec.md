# Example: Feature Spec

Fill-in template produced by `aidlc/inception/spec.md`.

```markdown
# Feature Spec: [Name]

## Problem
[1–3 sentences. What's broken / missing today, who's affected, how badly.]

## Proposed Solution
[1–3 sentences. The simplest change that solves the problem.]

## Use Cases
1. **[Actor] [does X] when [trigger] so they can [outcome].**
   - Preconditions: [...]
   - Flow: [step → step → step]
   - Postconditions: [...]
   - Acceptance: Given [state], when [action], then [observable result].

## Success Metrics
| Metric | Baseline | Target | Measurement |
|--------|---------|--------|-------------|
| [name] | [today] | [in 90d] | [how to measure] |

## RICE Score
- Reach: [users/quarter]
- Impact: [0.25 / 0.5 / 1 / 2 / 3]
- Confidence: [50% / 80% / 100%]
- Effort: [person-weeks]
- **Score:** (R × I × C) / E = [value]

## Out of Scope
- [explicit non-goal] — reason: [...]
- [explicit non-goal] — reason: [...]

## Constraints & Risks
- [constraint or risk] — mitigation: [...]

## Integration Impact
- Data dependencies: [...]
- API surface changes: [...]
- Downstream consumers: [...]

## Open Questions
- [ ] [question] — owner: [...]
```
