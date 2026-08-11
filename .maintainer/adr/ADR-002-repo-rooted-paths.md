# ADR-002: Every reference is repo-rooted

- **Status:** Accepted
- **Date:** 2026-07-07
- **Deciders:** maintainer

## Context

Adapters, phase files, and rules cross-reference each other constantly. Three
tools load them from three different working directories, and adoption deletes
whole adapter directories (`README.md` → Day 0). A reference form that depends on where the
*referring* file sits will break under both.

## Scale & performance assumptions

Roughly 70 adapter files plus 30 methodology files, with several hundred
cross-references between them. Every file move is a potential mass breakage; the
audit already walks every backtick-quoted path on each run, so validation is
free once the form is uniform.

## Options considered

### Option A: relative paths (`../../aidlc/rules/testing.md`)
- **Pros:** works in a plain markdown renderer from any directory depth.
- **Cons:** the depth is encoded in the string, so moving either end rewrites it;
  a nesting-depth change silently invalidates a whole directory of pointers.
- **Cost:** every restructure becomes a find-and-replace with no safety net.

### Option B: repo-rooted paths (`aidlc/rules/testing.md`)
- **Pros:** one canonical spelling per file, identical in all three tools;
  trivially checkable against the filesystem from the repo root.
- **Cons:** GitHub's markdown renderer will not resolve them as links from a
  subdirectory, so they are written as code spans, not hyperlinks.
- **Cost:** loses clickability inside `aidlc/`; the human-facing `README.md` uses
  real relative links because it sits at the root.

### Option C: absolute filesystem paths
- **Pros:** unambiguous.
- **Cons:** machine-specific. Not portable to any other clone.

## Decision

**Chose Option B**, and made it a sensor rather than a convention:
`scripts/audit.sh` fails on any `../` in `aidlc/` or the adapter directories, and
separately fails on any backtick-quoted repo path that does not resolve.

Reasoning: the binding constraint is that the tree gets restructured and pruned.
A convention that only holds while everyone remembers it is not a constraint;
the `../` check is what makes it one.

## Consequences

**Positive:**
- Moving a file breaks nothing as long as its own path string is updated once.
- Adapters read identically across the three tools.

**Negative:**
- Code-span references inside `aidlc/` are not clickable on GitHub.

**Risks:**
- Root-level documents legitimately need relative links for rendering —
  mitigation: the `../` sensor scopes to `aidlc/` and the adapter directories,
  where the anti-pattern actually causes breakage.

## Follow-ups

- [x] Sensor: no `../` chains in canonical or adapter files
- [x] Sensor: every backtick-quoted repo path resolves
