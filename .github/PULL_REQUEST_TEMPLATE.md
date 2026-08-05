<!-- Delete any section that genuinely does not apply, and say why. A skipped
     gate with a stated reason is reviewable; a silently dropped one is not. -->

## What changed and why

<!-- The outcome, not the diff. One or two sentences. -->

## Sprint contract

<!-- The verifiable criteria this was reviewed against
     (aidlc/construction/plan.md). Link the slice or paste the criteria. -->

- Base SHA reviewed against: <!-- git rev-parse origin/main -->

## Verification evidence

<!-- Commands run and their actual results — not "tests pass".
     Evidence, not confidence (aidlc/rules/testing.md). -->

```
$
```

- [ ] Tests pass, 100% coverage on new/modified code
- [ ] Lint and types clean; no new suppressions (`eslint-disable`, `# noqa`, …)
- [ ] Verified on the real target, not a proxy — stating what was *not* verified

## Gates

- [ ] **Review** — two-pass, no open critical issues (`/review`)
- [ ] **E2E** — journeys signed off for changed flows (`/e2e`), or n/a because …
- [ ] **Security** — required for auth, data access, upload, external API,
      infra, or crypto changes (`/security`), or n/a because …
- [ ] **Evals** — regression suite green if agent/LLM behavior changed
      (`/eval`), or no suite exists yet
- [ ] **Design** — tokens not raw values; every state designed; keyboard and
      contrast checked (`aidlc/rules/design-tokens.md`, `ux-guidelines.md`),
      or n/a because …

## Risk and rollback

- Blast radius:
- Rollback: <!-- revert commit, redeploy previous artifact, feature flag -->
- [ ] No secrets, credentials, or `.env` content in the diff or in
      `memory/progress.md`

## Follow-ups

<!-- Deviations worth folding into the next plan
     (aidlc/examples/implementation-notes.md), and anything deliberately
     deferred. -->
