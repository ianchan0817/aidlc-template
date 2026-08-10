---
description: Reproducibility — locked deps, pinned runtime, deterministic builds, deploy traceable to a SHA
paths:
  - "**/{package,composer,deno}.json"
  - "**/*.lock"
  - "**/{package-lock,npm-shrinkwrap}.json"
  - "**/{Gemfile,Pipfile,pyproject.toml,requirements*.txt,go.mod,go.sum,Cargo.toml,pom.xml,build.gradle*}"
  - "**/{Dockerfile,Containerfile,docker-compose*.yml,*.tf,*.tfvars}"
  - ".github/workflows/**"
---

Apply rules in `aidlc/rules/reproducibility.md`.
