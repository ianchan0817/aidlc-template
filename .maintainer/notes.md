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
