# Owner-only items for the template repo

Cannot be committed — they need repo or account access.

- **Private vulnerability reporting is off**, so `SECURITY.md` points at a Report
  button that GitHub does not render. Exact path: `docs/repo-setup.md`.
- **Dependabot security updates are off.** Alerts, secret scanning and push
  protection are on, and the ruleset requiring `audit` + `shellcheck` is active.

## Known gaps in the template's own controls

- One cloud bucket-removal command exits 0 in `scripts/guard-command.sh` — the
  same irreversible class as the cluster-namespace and destructive-SQL rules that
  do block. A coverage gap, not a philosophy difference. See the guard's own
  taxonomy comment for where it belongs.
- `scripts/guard-mutate.sh` permutes spellings of rows it was given, so it cannot
  discover a missing case class. It found none of the five false-positive
  mechanisms fixed on 2026-08-10.
- The last review's honesty lens died on a schema error and returned nothing, so
  overstated-claim hunting rested on two lenses instead of three.

## Reviewed 2026-08-11, worth doing, not done

From fetching all 21 references. Each is a real gap, not a nice-to-have.

- **Architecture-fitness sensor.** Fowler names three harness categories —
  maintainability (our coverage gate), behaviour (our evals), and architecture
  fitness — and `grep -rn fitness aidlc/ docs/ scripts/` returns nothing. The
  cheapest form is a dependency-direction check with the layer order declared in
  `project.yml` rather than hardcoded, so it stays generic across frontend,
  backend, infra and mobile.
- **A default Stop hook running the declared verify command.** The only measured
  effect size in the whole reference set: +13.7 points on Terminal Bench 2.0 with
  the model held fixed, because the dominant failure is an agent re-reading its
  own work, judging it fine, and stopping. Blocked on the usual problem — it would
  fire on every turn of a repo with no test command yet, so it must be
  conditional on `verify.test` being non-empty.
- **Tool-output token budget beyond the test sensor.** `scripts/agent-test.sh`
  caps and strips its output; `aidlc/rules/api-conventions.md` says nothing about
  an agent-facing tool returning high-signal text under an explicit budget.

## Guard false positive found 2026-08-11

`shopt -s nocasematch` makes the force-push rule's `-f` match `-F`, so
`git commit -F msg.txt` combined with a push in the same command string reads as
`git push --force`. Shell flags are case-sensitive; only the SQL and Redis
keyword rules need case-insensitivity. Fix: anchor the force-push flag test
case-sensitively, and add both spellings to `guard-cases.tsv`.
