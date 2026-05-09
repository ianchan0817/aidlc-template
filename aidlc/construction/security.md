# Security Audit

Phase: Construction. STRIDE threat model + OWASP code review.

Required for any change touching auth, data access, file upload, external APIs, infra, or crypto.

## Process
1. **Threat model** — produce a STRIDE table using `aidlc/examples/threat-model.md` as the format. Cover assets, trust boundaries, and threats per category (Spoofing, Tampering, Repudiation, Info Disclosure, DoS, Elevation of Privilege).
2. **OWASP review** — auth on every protected route, authorization at the data layer, all input validated, parameterized queries only, no `eval`/dynamic exec, no XSS vectors, secrets out of code/logs, PII minimized, dependencies audited.
3. **Classify** — Critical: block + escalate. High: fix before release. Medium: next sprint. Low: document.

## Output
Findings list with severity, file:line, and recommended fix. Log to `memory/progress.md` under Known Issues. **Never approve a release with open Critical or High items.**
