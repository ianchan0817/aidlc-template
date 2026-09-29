# Security Audit

Phase: Construction. STRIDE threat model + OWASP code review.

Required for the change triggers listed in `aidlc/rules/security.md`.

## Process
1. **Threat model** — produce a STRIDE table using `aidlc/examples/threat-model.md` as the format. Cover assets, trust boundaries, and threats per category (Spoofing, Tampering, Repudiation, Info Disclosure, DoS, Elevation of Privilege).
2. **OWASP review** — every application clause in `aidlc/rules/security.md`, checked against the diff rather than recited.
3. **Classify** — severity ladder in `aidlc/agents/reviewer.md`.

## Output
Findings list with severity, file:line, and recommended fix. Log to `memory/progress.md` under Known Issues. **Never approve a release with open Critical or High items.**
