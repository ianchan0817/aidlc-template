# Guardrails & sensors

How this template enforces things rather than asking for them. `README.md` covers
what you get; this covers how it holds. Rules and phase files are **feedforward
guides**; hooks, tests, E2E, evals and review are **feedback sensors**. Prefer a
deterministic sensor, and grade outcomes rather than the path taken.

## Session lifecycle

Every session runs the same loop so work survives context resets. Canonical: [`aidlc/common/session-lifecycle.md`](../aidlc/common/session-lifecycle.md), reinforced by each tool's `SessionStart` hook.

- **Start** — read `memory/progress.md`, the newest handoff in `memory/sessions/`, the backlog in `memory/features/`, `git log --oneline -20`, run the `./init.sh` smoke.
- **Work** — agree the sprint contract with the reviewer, take one slice, TDD red/green/refactor, runtime QA.
- **End** — commit, update `memory/progress.md`, leave merge-ready; the reviewer flips `passes`.

Four self-healing rules:

- **Reconcile on start** — cross-check `memory/` claims against the repo (files exist, tests pass, git agrees). On mismatch, trust the repo and correct the memory file.
- **Broken smoke = the slice** — if `./init.sh` fails, fixing the baseline *is* this session's work.
- **Compact before you lose it** — when context degrades (half the window gone, two corrections on the same point, re-asked questions): write durable state to `memory/` *first*, then compact, then re-enter through get-bearings. Anything not in a file is lost. A third correction almost never lands — by then the failed approaches *are* the context.
- **Name the check that says "done"** — an agent stops when work *looks* finished, so decide in advance what produces the pass/fail and how hard it gates. Four tiers, weakest to strongest, in the session-lifecycle file.

State artifacts:

- [`memory/progress.md`](../memory/progress.md) — Current Focus, Last/Next session, Decisions, Open Questions, Known Issues.
- [`memory/features/`](../memory/features/) — one record per feature: `{id, description, steps, verify, spec, passes, verified_sha}`. One file per feature so concurrent sessions never write the same path, and `feature-list.json` is only the manifest. The reviewer flips `passes` and stamps `verified_sha` with a real 40-char commit, so a pass goes stale if code changes underneath it.
- [`memory/plans/`](../memory/plans/) — two-part execution plans: plan, approve, then execute with same-turn checkboxes.
- [`memory/decisions/`](../memory/decisions/) — `[Answer]:` question files; the audit trail for gated decisions.
- [`init.sh.example`](../init.sh.example) — copy to `init.sh` for env bootstrap and smoke test.

## Know your unknowns

The map is not the territory — the gap is your unknowns, and pre-implementation is the cheapest place to find them. [`aidlc/common/unknowns.md`](../aidlc/common/unknowns.md) catalogs 11 elicitation moves, wired into their phases:

- **`/spec`** — *interview* (agent asks, blast-radius order) · *intervention brainstorm* (S/M/L/XL options drawn from real code)
- **`/design`** — *design directions* (react to 3–4 incompatible renders) · *mock before wiring* (fake data, click it first)
- **`/plan`** — *blindspot pass* (unknown unknowns in unfamiliar code) · *semantics map* (prove comprehension before porting) · *tweakable plan* (decisions ordered by volatility, each with a reversal trigger)
- **`/build`** — *implementation notes* (typed deviation log; fold-back bullets feed the next plan)
- **`/review`** — *change quiz* (verified comprehension for high-blast-radius merges)
- **`/ship`** — *buy-in doc* (demo first, pre-answered objections, named sign-offs)
- **`/retro`** — repeated deviations mean a guide gap or a sensor gap; fix the harness

## Agent evals vs code tests

Tests cover code paths; evals cover agent behavior. Details in [`aidlc/construction/eval.md`](../aidlc/construction/eval.md); task format in [`aidlc/examples/eval-suite.md`](../aidlc/examples/eval-suite.md).

| Aspect | Tests → Evals |
|---|---|
| Subject | Code paths → agent transcripts + outcomes |
| Graders | Deterministic asserts → code, LLM-judge, human |
| Suites | Unit/integration/E2E → capability vs regression |
| Cadence | Every change → when AI features change |

Start with 20–50 real failures. Read transcripts on every failed run. Calibrate LLM-as-judge against humans. Gate releases on pass^k (all k trials), not pass@k.

## Hooks

Deterministic enforcement — actions that must happen, not requests. Two ship per tool: **session-start bearings** (injects the get-bearings reminder) and a **dangerous-command guard**.

| Tool | Config file |
|---|---|
| Claude Code | [`.claude/settings.json`](../.claude/settings.json) |
| Codex CLI | [`.codex/hooks.json`](../.codex/hooks.json) |
| Cursor | [`.cursor/hooks.json`](../.cursor/hooks.json) |

The matching logic lives in one place — [`scripts/guard-command.sh`](../scripts/guard-command.sh) — and each tool's hook only extracts the command and forwards the exit code. It previously lived inline in all three configs and **drifted**: the Codex copy lost its `jq` extraction and started matching the raw JSON payload, blocking benign commands whose working directory happened to contain a match. One file, self-tested against [`scripts/guard-cases.tsv`](../scripts/guard-cases.tsv) on every audit run, cannot drift.

It blocks recursive force-deletes of root-anchored paths (any depth, every flag spelling), force-push (while allowing `--force-with-lease`), recursive world-writable `chmod`, `git reset --hard`, `git clean -f`, `DROP`/`TRUNCATE`/unbounded `DELETE`, reads of `.env` and of private keys, writes to agent policy files (`.claude/`, `.cursor/`, `.codex/`, `.git/hooks/` — a session that can write those grants itself capability in the next one), package publish and app-store submission, `terraform destroy`, `helm uninstall`, `kubectl delete namespace`, `redis-cli FLUSHALL`, `docker prune -a --volumes`, printing a credential, and piping a download into an interpreter. `.env.example` stays usable, because a guard that blocks day-one setup is a guard people delete.

**The guard is a tokenizer, not a list of greps**, because both of its failure modes came from the same missing abstraction — position. Matching a dangerous string *anywhere* blocked `git commit -m "block chmod -R 777 in the guard"` and `echo "test case: git reset --hard"`; matching one literal spelling let `rm -rf /etc`, `cat ./.env` and `bash -c "cat .env"` through while the docs claimed otherwise. So the command is split quote-aware into segments, the command word is found by skipping `VAR=value` and wrapper words (`sudo`, `env -i`, `{`), and arguments are classified by what the command does with them: `echo` args and `git` commit messages are **data**, a `grep` pattern is data but its file operand is not, a `bash -c` payload **re-enters as a command**, and a `sed`/`python -c` payload is foreign code checked only for secret paths. Targets are matched by **shape** (anything anchored at `/`, `~`, `$HOME`; any `id_*` under `.ssh`), never by enumerated spelling.

That claim is enforced by a second sensor. [`scripts/guard-cases.tsv`](../scripts/guard-cases.tsv) is an enumeration, and an enumeration proves only that its members work — every bypass this guard shipped lived in the complement of one. So [`scripts/guard-mutate.sh`](../scripts/guard-mutate.sh) mutates every hand-written case mechanically (`sudo` prefix, subshell, `bash -c` wrapping, quoted target, path prefix, split flag groups, lowercased SQL) and asserts the verdict is unchanged, then re-emits every blocked case inside `echo`, a commit message and a comment and asserts it is **allowed**. Mutations that would not preserve the verdict are skipped with a printed reason rather than quietly dropped. Both arms run in `scripts/audit.sh`; run against the pre-rewrite guard, the generated corpus fails 115 of 782 cases that the 87-row hand-written table passed clean.

It fails **closed**: if `jq` is missing or the payload shape changes, the command is blocked rather than waved through.

> **A Bash allow-list is a convenience boundary, not a security boundary.** `permissions.allow` entries like `Bash(python *)` permit arbitrary code, so no `Read(.env)` deny can stop `python -c "open('.env')"`. That is why the secret-file check lives in the guard hook, which sees the actual command. Treat the allow-list as "don't prompt me for this", and the hook as the enforcement layer.

**No completion gate ships, on purpose.** A `Stop`/pre-completion hook that blocks the turn until tests pass is the strongest sensor available — and the one thing a template cannot ship, because it would fire on every turn of a repo that has no test command yet. Wire it per project once `./init.sh` reliably passes on a clean tree, and give it a bypass for the session that fixes the check itself.

Extend as needed (format-on-save, loop detection). If you add a hook, verify it actually fires — the audit checks JSON validity, but only a live test proves the guard blocks.

## AI-friendly test output

Raw terminal output is hostile to model context: ANSI codes fracture tokenization, progress bars flood via `\r`, one exception can emit a 300-line stack trace. [`scripts/agent-test.sh`](../scripts/agent-test.sh) wraps any test command:

```bash
scripts/agent-test.sh bun test      # or pytest, go test …
```

PASS/FAIL and exit code first · ANSI/OSC stripped · stack traces truncated (default 50, `AGENT_TEST_MAX_TRACE`) · output capped (default 400, `AGENT_TEST_MAX_LINES`) · untouched per-run raw log preserved, parallel-safe · exit code passes through, so it works in CI and hooks.

## The audit

`bash scripts/audit.sh`, also on every push/PR. Exits non-zero on structural failure. It runs in **two modes**, decided by whether `aidlc/.template` is present — full per-sensor list in [`CONTRIBUTING.md`](CONTRIBUTING.md).

**Universal**, because they are true of any repo: JSON validity of every hook config (a syntax error silently disables a safety hook) · broken internal references · no hardcoded model IDs (`model: inherit` only) · no `../` path chains · shell syntax (`bash -n`) · agent frontmatter, since a file without `name:` never registers as a subagent · skill *shape*, `<tool>/skills/<name>/SKILL.md`, because a flat file produces no slash command and no error · every rule has a working attach path · hook output schemas per tool, where the wrong key is *ignored* rather than rejected · the command guard's own self-test · `.gitignore` covers secrets and none is tracked · **anti-explosion**: a surface name in an `aidlc/` gate must name the `project.yml` field that switches it.

**Maintainer-only**, dropped the moment you delete the marker: word budgets · three-tool parity · README mobile render · upstream-URL check · this template's hygiene file list. **Adopter-only**, which start once it is gone: `project.yml` parses and declares real values · every backlog record in `memory/features/` is well-formed and every `passes: true` carries a resolvable 40-char commit SHA · `init.sh` exists and is not a byte-identical copy of the example · every workflow declares `permissions:`.

Every one of these is negative-tested: regressing the invariant on a scratch copy must make the audit exit non-zero. A sensor that cannot fail is theater.

---
