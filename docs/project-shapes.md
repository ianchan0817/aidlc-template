# Project shapes

The concrete instances behind the shape-neutral gates in `aidlc/`. Declare your
shape in `project.yml`; look the row up here.

The methodology names the *invariant* ("address elements by a stable,
purpose-named identifier"). This file names the *spelling* per surface. That
split is why an adopter never has to delete or fork a methodology file: a gate
whose surface is not declared simply does not apply.

| Surface | E2E identity — how a test names its target | Health signals after release | Rollback lever | Coverage equivalent when lines cannot be instrumented |
|---|---|---|---|---|
| `web` | `data-testid` attribute, `{component}-{role}` | latency p99, error rate, traffic vs baseline, saturation | `revert-commit` or `previous-artifact` | n/a — line coverage applies |
| `mobile` | React Native `testID`; iOS `accessibilityIdentifier`; Android `resource-id` | crash-free sessions, ANR rate, version adoption, staged-rollout halt threshold | `halt-rollout+kill-switch`, then `forward-fix-only` — a shipped binary cannot be un-shipped | n/a for app code; generated bindings owe a contract test |
| `http-api` | request/response contract: method, path, status, named body fields | latency p99, error rate by status class, request volume, saturation | `previous-artifact` or `revert-commit` | contract test per endpoint against a published schema |
| `grpc` | service + method + named message fields, per the `.proto` | latency p99, non-OK status codes by code, RPS, saturation | `previous-artifact` | one contract test per RPC; generated stubs are not counted as covered code |
| `events` | topic + event type + named payload fields; assert on the emitted event, not the producer call | consumer lag, DLQ depth, duplicate/redelivery rate, throughput | `forward-fix-only` plus a replay or compensating event — a published event cannot be recalled | schema-compatibility test per event type |
| `cli` | argv in, exit code + stdout schema out | exit-code distribution, run duration, install/version adoption, error output rate | `previous-artifact` (pin the prior version) | one invocation case per flag branch, exit code asserted |
| `batch` | named input fixture → asserted output rows | freshness (lag behind source), row volume vs expectation, schema drift, reconciliation gap | `forward-fix-only` plus a backfill or re-run of the prior job version | one assertion per model/transform: a named fixture and its expected output |

## Release-channel defaults

Where `project.yml` sets `release.channel` but not `release.signals` or
`release.window`, these are the defaults `aidlc/operations/operate.md` uses:

- `continuous` — latency p99 <2s, errors <1%, traffic ±30% baseline, saturation
  <80%, green 30 min before promotion, 24h before the release is done.
- `store-staged` — crash-free sessions, ANR rate, version adoption,
  staged-rollout halt threshold; window is one staged-rollout step.
- `registry` — install success rate, version adoption, dependent build breakage,
  advisory reports; window is one dependent release cycle.
- `scheduled` — run success rate, duration vs budget, output freshness,
  downstream reconciliation; window is two scheduled runs.

## Performance budgets

Displaced here from `aidlc/rules/ux-guidelines.md`, which now states only the
invariant (reserve space for async content; budget per surface). Adjust to the
stack — these are starting numbers, not physics.

- `web` — LCP <2.5s; interaction latency <200ms; cumulative layout shift <0.1;
  initial compressed JS <150KB; lazy-load below the fold; virtualize lists >100
  items; animate transform and opacity only.
- `mobile` — cold start <2s; 60fps scroll with no dropped-frame run >100ms;
  interaction feedback <100ms; install size delta budgeted per release.
- `http-api` / `grpc` — p99 within the SLO declared for the endpoint; no
  unbounded result set; no N+1 on any changed path.
- `cli` — startup <200ms for the help path; no network call on a `--help` or
  `--version` invocation.
- `batch` — run duration within the schedule interval, with headroom for one
  retry.

## How to use a row

1. Set `surfaces`, `release.channel`, and `release.rollback` in `project.yml`.
2. `aidlc/construction/e2e.md` gives the invariant; the E2E identity column gives
   the spelling. Record it in the plan produced from
   `aidlc/examples/e2e-test-plan.md`.
3. `aidlc/operations/operate.md` checks four signals; this table says which four.
4. `aidlc/construction/ship.md` requires a verified rollback lever; where the
   lever is `forward-fix-only`, verify the kill switch instead of a redeploy.
5. `aidlc/rules/testing.md` requires 100% diff coverage or a named equivalent;
   the last column is the equivalent.

A project with several surfaces takes the union of the rows it declares.

## What each `project.yml` field switches

Read this once, when filling in `project.yml`. It used to live as comments inside
that file — but `project.yml` is loaded on **every session by all three tools**,
so 3,609 of its 4,155 characters (~900 tokens per session, measured with
tiktoken cl100k) were spent explaining the schema to a human who reads it once.
A field exists only if it switches a gate named here; if you cannot name the
gate, it is decoration and does not belong in the declaration.

| Field | Allowed values | Gate it switches |
|---|---|---|
| `surfaces` | web · mobile · http-api · grpc · events · cli · batch (a **list**) | `web`/`mobile` switch on `aidlc/inception/design.md`, `aidlc/rules/design-tokens.md`, `aidlc/rules/ux-guidelines.md`. Any value selects the e2e identity in `aidlc/construction/e2e.md` and the row of the table above that applies. |
| `stateful` | true · false | Migration reversibility in `aidlc/construction/plan.md` and `aidlc/construction/ship.md`; encryption-at-rest items in `aidlc/rules/security.md`. |
| `multi_tenant` | true · false | Tenant isolation (row-level security, per-tenant rate limits) in `aidlc/rules/security.md` and the architecture step of `aidlc/construction/plan.md`. |
| `release.channel` | continuous · store-staged · registry · scheduled | Which four health signals `aidlc/operations/operate.md` checks, and the default soak window. Per-channel defaults are in the table above. |
| `release.rollback` | revert-commit · previous-artifact · forward-fix-only · halt-rollout+kill-switch | The rollback pre-condition in `aidlc/construction/ship.md` and the stable gate in `aidlc/operations/operate.md`. |
| `release.signals` | four names | Step 1 and the stable gate in `aidlc/operations/operate.md`. |
| `release.window` | a period | The stable gate in `aidlc/operations/operate.md`. |
| `verify.*` | commands | `aidlc/construction/build.md`, `test.md`, `ship.md`, `review.md`. |
| `verify.eval` | command | The eval pre-condition in `aidlc/construction/ship.md` and the runner path in `aidlc/construction/eval.md`. |

A shipped store binary cannot be un-shipped, and an applied migration often
cannot be reverted — declare `forward-fix-only` or `halt-rollout+kill-switch` and
verify the kill switch rather than pretending a redeploy exists.

An **empty** `verify` value declares that the project has no such check, which
leaves the gate explicitly unnamed rather than silently passed. Where `coverage`
is empty, `aidlc/rules/testing.md` requires a named coverage equivalent instead.
