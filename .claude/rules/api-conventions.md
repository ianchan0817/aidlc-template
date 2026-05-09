---
description: REST API conventions — URL naming, response envelope, status codes, pagination
paths:
  - "**/api/**/*.{ts,tsx,js,py,go,rs}"
  - "**/routes/**/*.{ts,tsx,js,py,go,rs}"
  - "**/handlers/**/*.{ts,tsx,js,py,go,rs}"
  - "**/controllers/**/*.{ts,tsx,js,py,go,rs}"
---

# API Conventions

- URLs: plural nouns, kebab-case, no verbs, max 2 nesting levels, versioned `/v1/`, tenant in JWT not URL
- Success: `{ "data": {...}, "meta": {...} }` — Error: `{ "error": { "code": "SCREAMING_SNAKE", "message": "...", "fields": {...} } }`
- Status: 200 GET/PATCH/PUT, 201 POST-create, 204 DELETE, 400 malformed, 401 unauthed, 403 forbidden, 404 missing, 409 conflict, 422 validation (not 400), 429 rate limit, 500 server
- Pagination: cursor-based, default 20, max 100. Return `next_cursor`, `has_more`, `limit`.
- Auth: Bearer JWT (`sub`, `tenant_id`, `roles`, `exp`). Access 15min, refresh 30d HttpOnly Secure SameSite=Strict.
- Rate limit: per tenant. Headers: `X-RateLimit-Limit/Remaining/Reset`. 429 includes `Retry-After`.
- Idempotency: POST accepts `Idempotency-Key` (cached 24h). PUT/DELETE naturally idempotent.
- Versioning: breaking → new version. Deprecate with header, 6mo notice, maintain N-1.
- Errors: machine `code` (SCREAMING_SNAKE), human `message`, field-level `fields`. Never expose internals.
