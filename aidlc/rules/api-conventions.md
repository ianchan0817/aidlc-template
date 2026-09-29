# Interface conventions

Every interface — HTTP, gRPC, event topic, CLI, batch contract — owes five things: a **version** in the address or envelope; a **compatibility rule** (breaking → new version, N-1 maintained, deprecation announced); an **error taxonomy** with a machine code distinct from the human message, no internals leaked; **bounded results**, never unbounded; **idempotency** on every write. REST below is one instance.

An agent-facing **tool** is an interface too, and the cheapest one to fix — a prompt change helps one path, a tool change helps every call. Document what it does, one example call, its edge cases and what it refuses; hold output to an explicit budget; and **poka-yoke** the shape so the likely mistake is impossible rather than merely documented — an enum over a free string, a required flag on the destructive variant (`docs/agent-patterns.md`).

## REST
- URLs: plural nouns, kebab-case, no verbs, max 2 nesting levels, versioned `/v1/`, tenant in JWT not URL
- Success: `{ "data": {...}, "meta": {...} }` — Error: `{ "error": { "code": "SCREAMING_SNAKE", "message": "...", "fields": {...} } }`
- Status: 200 GET/PATCH/PUT, 201 POST-create, 204 DELETE, 400 malformed, 401 unauthed, 403 forbidden, 404 missing, 409 conflict, 422 validation (not 400), 429 rate limit, 500 server
- Pagination: cursor-based, default 20, max 100. Return `next_cursor`, `has_more`, `limit`. POST accepts `Idempotency-Key` (cached 24h); PUT/DELETE are naturally idempotent.
- Auth: Bearer JWT (`sub`, `tenant_id`, `roles`, `exp`). Access 15min, refresh 30d HttpOnly Secure SameSite=Strict.
- Rate limit: per tenant. Headers: `X-RateLimit-Limit/Remaining/Reset`. 429 includes `Retry-After`.
