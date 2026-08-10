# Template history — maintainer log

Session-by-session record of how this template got its current shape, moved out
of `memory/progress.md` so an adopter inherits a clean handoff file instead of
someone else's backlog. Durable architectural decisions are promoted to
`docs/adr/`; this file is the narrative, newest first.

Nothing here is required reading to use the template. Start at `README.md`.

## 2026-08-10 — The guard stops enumerating

Every bypass this guard had shipped was one defect: the rule was a prose
quantifier ("root paths", "reads of `.env`") while the sensor was a
hand-authored enumeration, and nothing bound them. `guard-cases.tsv` was the
only oracle and every expect-2 row spelled its target exactly one way, so the
gate was green the day `rm -rf /etc`, `cat ./.env` and `bash -c "cat .env"` all
exited 0. Negative-testing an enumeration proves its members work and says
nothing about the complement, which is where all three lived.

The mirror-image defect cost as much. Matching a dangerous string anywhere
blocked `git commit -m "block chmod -R 777 in the guard"`,
`echo "test case: git reset --hard"` and a `gh pr create --body` describing the
fix — measured at 6 of 92 realistic benign commands. Per the README's own
principle, a guard that blocks ordinary work gets deleted, taking the rules that
do work with it.

Both are the same missing abstraction: **position**. Rewrote the matcher as a
quote-aware tokenizer — segments split on separators outside quotes, command
substitution and `bash -c` payloads re-entered as commands, the command word
found by skipping `VAR=value` and wrapper words, and arguments classified by
what the command does with them (`echo` args and commit messages are data, a
`grep` pattern is data but its file operand is not, a `sed`/`python -c` payload
is foreign code checked only for secret paths). Targets match by shape, never by
spelling. Where an enumeration survives it is on the side that fails closed, or
on the exemption side where the claim is closed and checkable — `ls publish` and
`npm publish` are the same shape, so something must know which commands take a
path; enumerating those fails open only for them, while enumerating package
managers would fail open for every tool invented later.

Added the rules that were missing entirely (publish, store submission,
`terraform destroy`, `helm uninstall`, `kubectl delete namespace`, redis flush,
`docker prune -a --volumes`, `git clean -f`, private-key reads, credential
printing, `curl | sh`, and writes to agent policy files, which grant capability
to the next session). Each carries a blocking case and a near-miss.

The structural fix is `scripts/guard-mutate.sh`: it mutates every hand-written
case (privilege prefix, subshell, `bash -c` wrapping, quoted target, path
prefix, split flag group, lowercased SQL) asserting the verdict is unchanged,
and re-emits every blocked case inside `echo`, a commit message and a comment
asserting it is allowed. Mutations that would not preserve the verdict are
skipped with a printed reason — the flag-split mutation is capped at four
letters because a longer single-dash token is a long option (`-destroy`), and
splitting it would assert a falsehood. The generator found that in itself on its
first run. Run against the pre-rewrite guard, it fails 115 of 782 generated
cases the 87-row table passed clean.

Result: 182 hand-written rows plus 1483 generated, 0 of 92 benign commands
blocked (was 6), and the guard is ~10x faster per invocation because a pure-bash
tokenizer forks nothing where the old version forked ~25 greps.

## 2026-08-10 — Surfaces declaration

Made the template serve a headless Go API, a React Native app and a Next.js site
from one methodology tree, without an adopter deleting or forking any file.
Root `project.yml` became the declaration, reached through the always-on
`project` rule on Claude Code and Cursor and read directly from `AGENTS.md` on
Codex. Five hardcoded gates were dereferenced: the `data-testid` assumption in
`aidlc/construction/e2e.md`, the four browser health signals in
`aidlc/operations/operate.md`, the redeploy-always rollback in
`aidlc/construction/ship.md`, the coverage-percentage-only gate in
`aidlc/rules/testing.md`, and the fixed architecture axes in
`aidlc/construction/plan.md`. `aidlc/rules/code-style.md` was split into a
language-neutral half and a TypeScript half; `aidlc/rules/api-conventions.md`
became transport-neutral with REST as one instance. The 107-word stack rule was
deleted, which paid for most of the new prose; the rest came from displacing the
performance budgets and browser specifics into `docs/project-shapes.md`.

`aidlc/.template` was added as the mode marker: present means this is the
template repo and the maintainer-only sensors run; deleting it is the first
change adoption makes, and it switches `scripts/audit.sh` to the adopter arm.
The word budgets were
promoted from WARN to FAIL at the same time — a WARN exits 0, so a PR that blew
the cap merged green and the discipline the methodology rests on was never
enforced.

Decisions promoted to ADRs: `docs/adr/ADR-004-surfaces-declaration.md`.

## 2026-08-10 — Role grounding

Asked whether the three roles actually carried the security and infra duties the
workflow assumes. They did not. `engineer` had no security section at all, so the
trigger was reviewer-discovered — found too late; `manager` had escalation
nowhere; `reviewer` never mentioned supply chain despite a lockfile being the
highest-leverage line in any diff. All six adapter descriptions were rewritten,
because the description *is* the routing table a delegating model reads.

Running the template's own workflow on itself caught two things a self-review
would not have. The `engineer` subagent halted at 8002 words against the 8000
tripwire and refused to raise the threshold as sensor-gaming — the correct call.
The fresh-context `reviewer` then returned BLOCK twice: first for an unowned step
in `aidlc/operations/operate.md` and a manager write duty its own adapters
forbid; then for a 50%-inoperative sensor of my own — `grep -q "Write"` matches
`TodoWrite`, so the arm could never fail with `Write` deleted, which is exactly
the capability the reviewer needs to record sign-off. Both arms are now
delimiter-anchored.

## 2026-08-05 — Repository hygiene

The GitHub "Security and quality" surface had every file-based item missing.
Added `SECURITY.md` (scoped to what this repo actually ships), `CONTRIBUTING.md`,
`.github/dependabot.yml`, a ShellCheck-to-SARIF code-scanning workflow using a
local converter rather than an unpinned third-party action, an inactive CodeQL
example, a PR template encoding the gates, issue templates routing security to
private advisories, and `docs/repo-setup.md` for the toggles no commit can set.

Recommended *against* mirroring docs into the wiki: it is a separate git
repository that is not copied on clone or fork, so anything an adopter needs must
stay in `README.md` and `aidlc/`.

## 2026-08-05 — Design system

Split UI guidance by the question it answers: `aidlc/rules/design-tokens.md` for
the vocabulary versus `aidlc/rules/ux-guidelines.md` for behavior, with `/design`
rewritten as a designer's process. Evaluated four marketplace skills and the
catalog: every `/tools/skills/` page turned out to be an SEO wrapper with no skill
body, and the one named for design architecture had zero UI content. Four items
were adopted anyway because they fixed real gaps here — a pinned review base SHA,
untrusted-ref execution, the three-flash seizure threshold, and an
option-articulation contract in decision gates.

Rather than a seventh trim, the budget metric itself was fixed: `aidlc/examples/`
is fill-in templates the README calls "not auto-loaded", so counting them in a
context-window budget measured the wrong thing. Split into methodology and
templates, both negative-tested.

## 2026-08-02 — Mobile render, then adapter reality

Measured the README's real mobile behaviour (paragraphs wrap; tables and code
blocks do not) and restructured it. Corrected my own first measurement:
`awk length` counted UTF-8 bytes, so a "141-char" ASCII diagram was actually 61 —
tables were the real problem, not diagrams.

Verifying all three tool configs against vendor docs then found live bugs: three
Cursor rules were dead because brace expansion in `globs` collides with Cursor's
comma-splitting; Cursor's session-start hook emitted the wrong key and was a
no-op that reported success; its deny payload used an undocumented field;
`.codex/config.toml` used a deprecated alias; Codex's guard ran `grep` with no
`jq` and no file argument, matching the entire JSON payload; and Claude's `.env`
denies had no `Edit` counterpart. Root cause was three inline copies of one
regex, consolidated into `scripts/guard-command.sh` with
`scripts/guard-cases.tsv` as its case table. Building it surfaced two more bugs
in my own matcher, both caught by the table rather than by reading.

Earlier the same day: all 14 skills were flat `<tool>/skills/<name>.md` files,
which no tool loads — so no slash command existed in any tool, silently.
Regenerated as directory-form SKILL.md pointers, and all three agent files were
missing the required `name:` field, so no subagent had ever registered.

## Deferred — evaluated, worth doing, not yet done

Each closes a real gap and was cut for budget:

- **Lint delta gating** in `aidlc/construction/review.md`: compare error and
  warning counts against a clean tree, and treat every suppression comment in the
  diff as a Pass-1 finding. Catches the commonest way an agent makes a gate green
  without fixing anything.
- **Depth-not-presence** in `aidlc/inception/spec.md`: a heading that exists but
  says nothing currently passes the gate.
- **Deviation analysis** in `aidlc/construction/plan.md`: tabulate existing
  versus proposed before implementing in existing code. Today's machinery is
  retroactive only, i.e. after the surprise.
- **Alert quality** in `aidlc/operations/operate.md`: alert on symptoms not
  causes, and track the alert-to-incident ratio. The current step mandates a
  runbook per alert — coverage with no quality check.
- **Diagram guidance** in `aidlc/construction/plan.md`: diagram only when the
  shape is the point, cap the node count, keep it as text that diffs.

## Rejected, with reasons

- **Six-file Memory Bank** (2026-07-07) — the volatility split already exists:
  low-churn in `aidlc/rules/` and `docs/adr/`, high-churn in `memory/`. Would
  duplicate both and blow the budget.
- **Append-only audit ledger** (2026-07-07) — git is the ledger, decision files
  carry timestamps, and `memory/progress.md` tracks phase.
- **A fourth "initializer" role** (2026-07-07) — the triad plus an append-only
  backlog plus the mid-flight change protocol already close the loop. Added the
  missing halt-and-escalate clause to `aidlc/agents/engineer.md` instead.
- **A shipped completion hook** (2026-08-02) — the strongest gate available, and
  the one thing a template cannot ship: it would fire every turn in a repo with
  no test command. Documented as tier 3 of four, wired per project.
