# Reproducibility

- Lockfile committed. Builds pinned to exact versions. No floating ranges in production.
- Runtime version pinned (`.nvmrc`, `.python-version`, container image tag — never `latest`).
- Config separate from code (12-factor). Env vars for what changes between environments. Code for what doesn't.
- Secrets via secrets manager, never in config files (see `security.md`).
- Migrations versioned alongside code, applied deterministically, reversible.
- Build artifacts content-addressed (hash, not timestamp). Same source → identical artifact.
- Never hand-edit generated files, and prefer assets built by a committed script over sourced binaries — commit the script, not its output, so provenance is self-evident and the result cannot drift from its inputs.
- A value that varies by environment must vary everywhere referencing it; a copy in a build script drifts, and the mismatch reads as a third-party outage.
- CI is the source of truth. "Works on my machine" is a bug.
- Every release tagged and traceable to a commit SHA.
