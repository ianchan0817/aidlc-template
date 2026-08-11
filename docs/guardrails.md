# Guardrails & sensors

How this template enforces things rather than asking for them. Rules and phase
files are **feedforward guides**; hooks, tests, E2E, evals and review are
**feedback sensors**. Prefer a deterministic sensor, and grade outcomes rather
than the path taken.

This file covers only what has no other home. The session loop lives in
[`aidlc/common/session-lifecycle.md`](../aidlc/common/session-lifecycle.md),
elicitation moves in [`aidlc/common/unknowns.md`](../aidlc/common/unknowns.md),
evals in [`aidlc/construction/eval.md`](../aidlc/construction/eval.md), and the
per-sensor list in [`CONTRIBUTING.md`](../CONTRIBUTING.md). Repeating any of them
here would create a second copy to keep in sync, and the copy always loses.

## Hooks

Two ship per tool: **session-start bearings** and a **dangerous-command guard**.
Config in [`.claude/settings.json`](../.claude/settings.json),
[`.codex/hooks.json`](../.codex/hooks.json) and
[`.cursor/hooks.json`](../.cursor/hooks.json) — but the matching logic lives in one
place, [`scripts/guard-command.sh`](../scripts/guard-command.sh), and each hook only
extracts the command and forwards the exit code. Inline copies drifted: one lost
its `jq` extraction and began matching the raw JSON payload, blocking benign
commands whose working directory happened to contain a match.

It blocks recursive force-deletes of root-anchored paths at any depth and flag
spelling, force-push (while allowing `--force-with-lease`), recursive
world-writable `chmod`, `git reset --hard`, `git clean -f`,
`DROP`/`TRUNCATE`/unbounded `DELETE`, reads of `.env` and of private keys, writes
to agent policy files, package publish and app-store submission, `terraform
destroy`, `helm uninstall`, `kubectl delete namespace`, `redis-cli FLUSHALL`,
`docker prune -a --volumes`, printing a credential, and piping a download into an
interpreter. `.env.example` stays usable, because a guard that blocks day-one
setup is a guard people delete.

**It is a tokenizer, not a list of greps**, because both of its failure modes came
from one missing abstraction — position. Matching a dangerous string *anywhere*
blocked `git commit -m "block chmod -R 777"`; matching one literal spelling let
`rm -rf /etc` and `cat ./.env` through while the docs claimed otherwise. So the
command is split quote-aware into segments, the command word is found by skipping
`VAR=value` and wrapper words (`sudo`, `env -i`), heredoc bodies are dropped as
data unless an unquoted delimiter lets them expand, and arguments are classified
by what the command does with them: `echo` args and commit messages are **data**,
a `grep` pattern is data but its file operand is not, a `bash -c` payload
**re-enters as a command**, and a `sed`/`python -c` payload is foreign code checked
only for secret paths. Targets match by **shape** — anything anchored at `/`, `~`,
`$HOME`; any `id_*` under `.ssh` — never by enumerated spelling.

A second sensor enforces that claim.
[`scripts/guard-cases.tsv`](../scripts/guard-cases.tsv) is an enumeration, and an
enumeration proves only that its members work — every bypass this guard shipped
lived in the complement of one. So
[`scripts/guard-mutate.sh`](../scripts/guard-mutate.sh) mutates every hand-written
case mechanically (`sudo` prefix, subshell, `bash -c` wrapping, quoted target, path
prefix, split flag groups, lowercased SQL) and asserts the verdict is unchanged,
then re-emits every blocked case inside `echo`, a commit message and a comment and
asserts it is **allowed**. Mutations that would not preserve the verdict are
skipped with a printed reason rather than quietly dropped. Both arms run in
`scripts/audit.sh`.

It fails **closed**: if `jq` is missing or the payload shape changes, the command
is blocked rather than waved through.

> **A Bash allow-list is a convenience boundary, not a security boundary.**
> `permissions.allow` entries like `Bash(python *)` permit arbitrary code, so no
> `Read(.env)` deny can stop `python -c "open('.env')"`. That is why the
> secret-file check lives in the guard hook, which sees the actual command. Treat
> the allow-list as "don't prompt me for this", and the hook as enforcement.

**No completion gate ships, on purpose.** A `Stop` hook that blocks the turn until
tests pass is the strongest sensor available, and the one thing a template cannot
ship: it would fire on every turn of a repo with no test command yet. Wire it per
project once `./init.sh` passes reliably on a clean tree, and give it a bypass for
the session that fixes the check itself.

If you add a hook, verify it actually fires. The audit checks JSON validity; only
a live test proves a guard blocks.

## AI-friendly test output

Raw terminal output is hostile to model context: ANSI codes fracture
tokenization, progress bars flood via `\r`, one exception can emit a 300-line
stack trace. [`scripts/agent-test.sh`](../scripts/agent-test.sh) wraps any test
command:

```bash
scripts/agent-test.sh bun test      # or pytest, go test …
```

PASS/FAIL and exit code first · ANSI/OSC stripped · stack traces truncated
(`AGENT_TEST_MAX_TRACE`, default 50) · output capped (`AGENT_TEST_MAX_LINES`,
default 400) · untouched raw log kept per run, parallel-safe · exit code passes
through, so it works in CI and in hooks.

## The audit

`bash scripts/audit.sh`, also on every push and PR, exits non-zero on structural
failure. Two modes, decided by whether `aidlc/.template` is present: maintainer
sensors measure the template's own shape and self-disable at adoption, adopter
sensors start then, and the safety sensors run in both.

Every sensor is negative-tested — regressing the invariant on a scratch copy must
make the audit exit non-zero. A sensor that cannot fail is theater, and a sensor
that verifies zero subjects must not report success.
