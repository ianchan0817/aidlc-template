---
description: /project:security — Security audit with STRIDE threat model.
---

# Security Audit

1. **Threat Model (STRIDE)** — assets, trust boundaries, threats table (Spoofing/Tampering/Repudiation/InfoDisclosure/DoS/EoP with likelihood/impact/mitigation)
2. **Code Review (OWASP)** — auth on all routes, authorization at data layer, input validated, parameterized queries, file uploads safe, no eval/dynamic exec, no XSS vectors, no secrets in code/logs, PII minimized, deps audited
3. **Classify** — Critical: block + notify. High: fix before release. Medium: next sprint. Low: document.

Output: findings with severity, file:line, recommended fix. Log to `.claude/memory/progress.md`. **Never approve with open Critical/High.**
