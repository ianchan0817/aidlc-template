<!-- THE CONTRACT (project.yml): a gate whose surface or capability this project
     does not declare does not apply and needs no skip rationale; a gate it does
     declare cannot be skipped. So: check the boxes your declaration switches on,
     and delete the ones it switches off. Do not delete a gate you declared —
     that one needs evidence, not a reason. -->

## What changed and why

<!-- The outcome, not the diff. One or two sentences. -->

## Sprint contract

<!-- The verifiable criteria this was reviewed against
     (aidlc/construction/plan.md). Link the slice or paste the criteria. -->

- Base SHA reviewed against: <!-- git rev-parse origin/main -->
- Declared surfaces: <!-- copy `surfaces:` from project.yml -->

## Verification evidence

<!-- Commands run and their actual results — not "tests pass". The commands are
     the ones in project.yml `verify:`; CI runs the same ones.
     Evidence, not confidence (aidlc/rules/testing.md). -->

```
$
```

- [ ] `verify.test` passes
- [ ] `verify.lint` and `verify.types` clean; no new suppressions
      (`eslint-disable`, `# noqa`, `//nolint`, …)
- [ ] **Coverage** — `verify.coverage` at 100% on new/modified code. If
      `coverage:` is declared empty, name the equivalent used here instead:
      <!-- e.g. a case table with one row per branch -->
- [ ] Verified on the real target, not a proxy — stating what was *not* verified

## Gates

- [ ] **Review** — two-pass, no open critical issues (`/review`)
- [ ] **E2E** — journeys signed off for changed flows (`/e2e`). A journey is
      end-to-end in the identity of the declared surface: `web`/`mobile` → a
      real UI session; `http-api`/`grpc` → a client calling the deployed
      endpoint; `events` → publish-to-side-effect; `cli`/`batch` → argv in,
      exit code and artifact out. Delete this line only if no declared surface
      changed.
- [ ] **Security** — required for auth, data access, upload, external API,
      infra, or crypto changes (`/security`). `multi_tenant: true` also requires
      the tenant-isolation check; `stateful: true` also requires the
      migration-reversibility check. Or n/a because …
- [ ] **Evals** — regression suite green if agent/LLM behavior changed
      (`/eval`), or no suite exists yet
- [ ] **Design** — applies when `surfaces` includes `web` or `mobile`: tokens
      not raw values; every state designed; keyboard and contrast checked
      (`aidlc/rules/design-tokens.md`, `ux-guidelines.md`)

## Risk and rollback

- Blast radius:
- [ ] Rollback exercised, using the lever declared in `release.rollback` —
      `revert-commit` (revert and redeploy) · `previous-artifact` (the previous
      build is still deployable) · `forward-fix-only` (state the forward path
      and its lead time) · `halt-rollout+kill-switch` (name the switch and say
      you flipped it in a non-prod environment)
- [ ] Health signals to watch after merge are the ones in `release.signals`,
      over `release.window` (`aidlc/operations/operate.md`)
- [ ] No secrets, credentials, or `.env` content in the diff or in
      `memory/progress.md`

## Follow-ups

<!-- Deviations worth folding into the next plan
     (aidlc/examples/implementation-notes.md), and anything deliberately
     deferred. If this PR changed the project's shape, project.yml is part of
     the diff. -->
