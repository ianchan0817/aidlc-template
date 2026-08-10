---
description: API conventions — resource naming, request/response envelope, error codes, pagination, auth, idempotency, versioning; transport-neutral (HTTP, gRPC, events)
paths:
  - "**/api/**/*.{ts,tsx,js,py,go,rs}"
  - "**/routes/**/*.{ts,tsx,js,py,go,rs}"
  - "**/handlers/**/*.{ts,tsx,js,py,go,rs}"
  - "**/controllers/**/*.{ts,tsx,js,py,go,rs}"
  - "**/consumers/**"
  - "**/subscribers/**"
  - "**/events/**"
  - "**/proto/**"
  - "**/*.proto"
---

Apply rules in `aidlc/rules/api-conventions.md`.
