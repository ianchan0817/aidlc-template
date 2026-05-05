# Example: STRIDE Threat Model

Fill-in template produced by `aidlc/construction/security.md`. Required for any change touching auth, data, file upload, external APIs, or crypto.

```markdown
# Threat Model: [Feature]

## Assets
What are we protecting?
- [asset] — sensitivity: [public / internal / confidential / regulated]
- [asset] — sensitivity: [...]

## Trust Boundaries
Where does data cross from untrusted to trusted?
- [boundary 1] — e.g. browser → API gateway
- [boundary 2] — e.g. API → internal service
- [boundary 3] — e.g. service → database

## Threats (STRIDE)

| Category | Threat | Likelihood | Impact | Mitigation | Owner |
|----------|--------|-----------|--------|-----------|-------|
| Spoofing | [e.g. forged JWT] | H/M/L | H/M/L | [signature verification, key rotation] | |
| Tampering | [e.g. request body modified] | | | [HMAC, TLS] | |
| Repudiation | [e.g. user denies action] | | | [audit log with user ID + timestamp] | |
| Info Disclosure | [e.g. PII in error message] | | | [structured logging, no PII fields] | |
| Denial of Service | [e.g. unbounded query] | | | [rate limit, cursor pagination] | |
| Elevation of Privilege | [e.g. authz bypass] | | | [data-layer authz check on every read] | |

## Findings

| ID | Severity | File:Line | Issue | Status |
|----|---------|-----------|-------|--------|
| F1 | Critical / High / Medium / Low | [path:line] | [description] | Open / Mitigated / Accepted |

## Decision

- [ ] **Approved for release** — all Critical and High mitigated
- [ ] **Blocked** — open Critical/High items: [list]
```
