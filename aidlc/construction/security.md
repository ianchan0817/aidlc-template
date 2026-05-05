# Security Audit

Phase: Construction. STRIDE threat model + OWASP code review.

## 1. Threat Model (STRIDE)

```markdown
## Threat Model: [Feature]

### Assets — what are we protecting?
### Trust Boundaries — where does data cross from untrusted to trusted?
### Threats
| Category | Threat | Likelihood | Impact | Mitigation |
|----------|--------|-----------|--------|-----------|
| Spoofing | | H/M/L | H/M/L | |
| Tampering | | | | |
| Repudiation | | | | |
| Info Disclosure | | | | |
| Denial of Service | | | | |
| Elevation of Privilege | | | | |
```

## 2. Code Review (OWASP categories)

**Auth & Authz**
- [ ] Auth enforced on all protected routes
- [ ] Authorization at data layer, not just route
- [ ] Session tokens with proper expiry and rotation
- [ ] Password hashing: bcrypt or argon2

**Input Validation**
- [ ] All user input validated and sanitized
- [ ] SQL: parameterized queries only
- [ ] File uploads: MIME by content, size limited, filename sanitized
- [ ] Output encoded to prevent XSS

**Data Handling**
- [ ] PII minimized and documented
- [ ] Encrypted at rest and in transit
- [ ] No secrets in code, logs, or error messages
- [ ] No PII in URLs, logs, or analytics

**Client-Side**
- [ ] No `dangerouslySetInnerHTML` without DOMPurify
- [ ] No `eval`, `new Function`, dynamic execution
- [ ] User URLs validated for safe scheme
- [ ] CSP configured, no `unsafe-eval`
- [ ] No sensitive data in localStorage

**Dependencies**
- [ ] `npm audit` / `pip audit` / `cargo audit` — no critical/high CVEs
- [ ] Versions pinned and reviewed

## 3. Classify Findings

| Severity | Action |
|----------|--------|
| Critical | Block release, notify manager immediately |
| High | Must fix before release |
| Medium | Fix next sprint |
| Low | Document and monitor |

Output: findings with severity, file:line, recommended fix. Log to `memory/progress.md`. **Never approve with open Critical/High.**
