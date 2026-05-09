---
description: Security baseline — input validation, secrets, PII, auth/authz
---

# Security

- Auth on every protected route. Authorize at data layer. Validate identity from JWT/session only.
- Validate all input at boundary. Parameterized queries only. No `eval`/`new Function`/`exec` with user input.
- File uploads: MIME by content, size limit, sanitize filename.
- No secrets in code, config, logs, errors. Use secrets manager. Rotate on offboarding.
- Minimize PII. Encrypt at rest + transit. No PII in URLs/logs/analytics. Tenant isolation via RLS.
- No `dangerouslySetInnerHTML` without DOMPurify. User URLs: `https?://` only. CSP on, no `unsafe-eval`.
- `SameSite=Strict` auth cookies. No sensitive data in localStorage.
- Audit deps in CI. No merge with Critical/High CVEs. Pin versions.
- Changes to auth, authorization, data access, file upload, external APIs, infra, or crypto → security review required.
