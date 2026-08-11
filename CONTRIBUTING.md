# Contributing

This repo is a methodology template, so the bar is unusual: **the change has to
survive being copied into someone else's project, on a different tool, with a
different model.**

Security reports do not go here — see [SECURITY.md](SECURITY.md).

## The one gate

```bash
bash scripts/audit.sh
```

Exit 0 or it isn't ready.

### Two modes, one marker file

`aidlc/.template` decides which sensors run. Its presence means *this is the
template repo*. **Deleting it is step 1 of adoption**, and that single deletion
self-disables the maintainer-only sensors — the ones that measure the template's
own shape and say nothing about the adopter's product.

| | template mode | adopter mode |
|---|---|---|
| marker | `aidlc/.template` present | removed |
| maintainer sensors | run | skipped |
| universal sensors | run | run |
| adopter arm | skipped | runs |

**Universal — run in both modes**, because they are true of any repo:

- valid JSON in every hook config
- no broken internal references
- every `model:` line in `.claude/agents/*.md` and `.cursor/agents/*.md` is
  **exactly `inherit`** — asserted inverted, plus a regex sweep of the wider tree
  for known vendor spellings. The sweep alone missed `claude-3-5-sonnet-20241022`
  and `o3-mini`; a regex of known names loses to the next naming scheme by
  construction, so the allowed value is what gets asserted
- no `../` path chains
- shell syntax (`bash -n`) on every script
- subagent frontmatter (`name`, `description`) and role write capability
- skill **shape** — `skills/<name>/SKILL.md`, never a flat file
- every rule has a working attach path (`globs`, `alwaysApply`, or `paths`)
- **declaration reachability** — for each tool directory that is present:
  `.claude/rules/project.md` exists and carries **no** `paths:` key (path-scoping
  the declaration hides it from every file it does not match),
  `.cursor/rules/project.mdc` exists and sets `alwaysApply: true`, and `AGENTS.md`
  names `project.yml` (Codex has no rules dir, so that is its only path to the
  declaration). Rule parity iterates `aidlc/rules/*.md`, and `project` has no
  canonical body, so it sat outside that loop and nothing measured it
- hook output schemas match each tool's contract
- the command guard's own self-test
- `.gitignore` covers secrets and no secret-shaped file is tracked
- CodeQL stays inactive unless the repo has scannable source
- **anti-explosion** — exactly this, no more: a **backticked** surface token
  (`` `web` `` `` `mobile` `` `` `http-api` `` `` `grpc` `` `` `events` ``
  `` `cli` `` `` `batch` ``) in `aidlc/**/*.md` outside `aidlc/examples/`, on a
  line that mentions neither `project.yml` nor declare/declares/declared. Two
  regressions therefore pass it and are known: an **unbackticked** surface word in
  a gate, and a backticked token on a line that says "declared" without naming the
  field. Requiring the literal `project.yml` would close both and costs one
  word-neutral edit in `aidlc/core-workflow.md`; until that lands, this bullet
  describes the check that runs rather than the one we want

**Maintainer-only — skipped once the marker is gone:**

- word budgets (root, methodology, artifact templates, and per file)
- three-tool parity: rule pointers per tool, identical skill sets per tool
- README renders without horizontal scrolling on mobile
- no upstream template URL left in `.github/`
- this template's own repository-hygiene file list

**Adopter arm — runs only with the marker removed:**

- `project.yml` exists, parses, has no placeholder left, and declares a non-empty
  `surfaces`, `release.rollback`, and `verify.test`
- **declared values are checked against the closed sets `project.yml` publishes**
  — every `surfaces` token against web/mobile/http-api/grpc/events/cli/batch,
  `release.channel` against continuous/store-staged/registry/scheduled,
  `release.rollback` against
  revert-commit/previous-artifact/forward-fix-only/halt-rollout+kill-switch. A
  typo is not a smaller declaration: `surfaces: [banana]` switches the UI and e2e
  gates off, which looks exactly like passing them. These three enums are
  template-owned, so checking them is not overriding adopter judgement
- `memory/feature-list.json` parses, `.features` is an array, **every feature has
  a non-empty `id`**, ids are unique, and every `passes: true` carries a
  `verified_sha` that `git cat-file -e` resolves. Presence is checked before
  uniqueness because `[.features[].id // empty]` drops untagged entries *before*
  `group_by`, so an id-less feature could never collide with anything
- `init.sh` present, executable, `bash -n` clean, and **not byte-identical to
  `init.sh.example`** — an unedited copy makes the smoke step a lie
- every workflow declares `permissions:`, and that declaration is neither
  `write-all` (strictly broader than the repo default the check exists to narrow)
  nor a bare `permissions:` with no scopes under it. `permissions: {}` and
  `read-all` are valid

## Rules for changes

**Single source of truth.** Content lives once in `aidlc/`. Tool directories
(`.claude/`, `.cursor/`, `.codex/`) hold only pointers plus the frontmatter that
tool's loader requires. If you find yourself pasting the same paragraph twice,
the second copy is the bug.

**Repo-rooted paths only.** Never `../../` — a moved file must not break a
reference. The audit fails on it.

**Tool- and model-agnostic.** No model IDs, no vendor runtime dependencies, no
stack-specific commands outside `project.yml`.

**Add a sensor, not just a rule.** Guidance is advisory to a model; a sensor is
deterministic. When you add an invariant, ask whether the audit can check it —
and if you add a check, **negative-test it**: regress the invariant on a scratch
copy and confirm the audit exits non-zero. A sensor that cannot fail is theater.

Watch for substring matches while you're at it. `grep -q "Write"` is satisfied by
`TodoWrite`, so an arm written that way can never fail; anchor on delimiters
instead. Prove the arm fires, don't assume.

### Rejected sensors and accepted blind spots — do not re-propose

These eight come up at every retro. Each was evaluated and either turned down or
accepted as a known limit, for a specific, still-valid reason. Reopening one needs
new evidence, not a new argument.

**`verified_sha` must be an *ancestor* of HEAD.** Breaks on shallow clones — the
object is present, the ancestry isn't — and on squash-merge, where the reviewed
commit is legitimately gone from the graph. `git cat-file -e` asks the honest
question instead: is this object here.

**Entropy-based secret scanning.** False-positives on lockfile hashes, base64
fixtures, and UUIDs. A secret sensor that cries wolf is a secret sensor someone
turns off. Push protection plus `.gitignore` cover this deterministically.

**Assert a coverage *percentage* from shell.** Needs the adopter's toolchain,
config, and a full test run. It belongs in the verify workflow reading
`verify.coverage`, where the toolchain already exists. The audit stays runnable
in seconds with nothing installed.

**"A plan exists for in-progress work."** Fires on every hotfix and every
one-line fix — exactly when nobody will write a plan. Guidance, not a gate.

**"`progress.md` was updated this session."** There is no defensible definition
of a session in a filesystem. Every proxy (mtime, commit count) is both gameable
and wrong.

**"An ADR exists for architectural changes."** Requires judging what counts as
architectural. That is a reviewer's call; as a regex it produces false alarms and
silent misses at the same time.

**`verify.test` is checked for non-emptiness only — `test: exit 0` passes.** That
is the design, not an oversight: the whole adopter arm is shape-shaped, and
deciding whether a command really tests anything needs the adopter's toolchain,
their repo, and a full run. The gate this field switches lives in
`.github/workflows/verify.yml.example`, where the toolchain exists. Closed enums
(above) are the exception because the template owns those value sets; a test
command is the adopter's.

**A word cap on `docs/`.** `docs/` is deliberately **uncapped** and is currently
4,949 words — more than half the size of the entire methodology tree. It is the
intended displacement target: prose pushed out of `aidlc/` to keep methodology
under 8,000 lands here, and per-surface reference tables belong here rather than
in a phase file. The growth pressure is therefore structural and **nothing
measures it**. Say so plainly instead of pretending otherwise: capping it would
just push the same prose back into the files an agent actually loads, which is the
footprint the budgets exist to protect. If `docs/` is ever loaded on demand rather
than read by humans, that trade-off changes and this entry expires.

**Earn the words.** Adding to a phase file or rule usually means displacing
something. State what you compressed.

**Two failures before a new rule.** `aidlc/operations/retro.md` is explicit:
add guidance after the same failure has appeared twice, and delete rules the
model already follows unprompted.

## Verifying adapter changes

The audit checks *shape*, not behaviour. A structurally valid adapter can still
be ignored by a tool. So for anything touching `.claude/`, `.cursor/`, or
`.codex/`, also confirm it loads live — the slash command appears, the subagent
registers, the rule attaches, the hook actually blocks — and say so in the PR.

Vendor formats change without notice. If a format claim is load-bearing, link
the vendor doc.

## Commits and PRs

Conventional-ish prefixes (`feat:`, `fix:`, `docs:`, `refactor:`, `chore:`), with
a scope where it helps (`fix(adapters):`). Explain the *why* and the evidence in
the body — the PR template asks for exactly what's needed.
