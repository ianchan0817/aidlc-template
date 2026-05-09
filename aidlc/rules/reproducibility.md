# Reproducibility

- Lockfile committed. Builds pinned to exact versions. No floating ranges in production.
- Runtime version pinned (`.nvmrc`, `.python-version`, container image tag — never `latest`).
- Config separate from code (12-factor). Env vars for what changes between environments. Code for what doesn't.
- Secrets via secrets manager, never in config files (see `security.md`).
- Migrations versioned alongside code, applied deterministically, reversible.
- Build artifacts content-addressed (hash, not timestamp). Same source → identical artifact.
- CI is the source of truth. "Works on my machine" is a bug.
- Every release tagged. Every deploy traceable to a commit SHA.
