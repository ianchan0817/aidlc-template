# Security Policy

This repository is a **template**: methodology in markdown, plus a small set of
executable safety controls (`scripts/guard-command.sh`, the per-tool hook
configs, and `permissions.deny` rules). The markdown cannot be exploited. The
controls can — and a control that silently stops working is the failure mode
this project cares most about.

## Reporting a vulnerability

**Do not open a public issue for a security report.**

Use GitHub's private vulnerability reporting: **Security → Report a
vulnerability** on this repository. It creates a private advisory visible only
to maintainers.

<!-- Maintainer: add a fallback contact here (email or Keybase) if you want one,
     and enable Settings → Security → Private vulnerability reporting. -->

Please include:

- What you expected the control to do, and what it did instead
- A minimal reproduction — for guard issues, the exact command string and the
  observed exit code from `bash scripts/guard-command.sh "<command>"`
- Which tool and version (Claude Code / Codex CLI / Cursor), and OS
- Whether you are reporting against `main` or a copy you took earlier

## In scope

Because this repo ships enforcement, these are real vulnerabilities:

| Class | Example |
|---|---|
| **Guard bypass** | A destructive command the guard should block but exits 0 on |
| **Fail-open control** | A hook or sensor that approves when `jq` is absent |
| **False protection** | A `permissions.deny` rule that doesn't match what it claims |
| **Silent no-op** | A safety adapter the tool never loads, so it never fires |
| **Secret exposure** | A documented step that writes credentials into a tracked file |
| **Injection path** | Untrusted content reaching a shell or a tool call as instruction |

The last two are live concerns for this design, not hypotheticals: the handoff
step records command output into `memory/progress.md`, and agents routinely read
tool output, logs, and fetched pages.

## Out of scope

Reported honestly so you don't spend time on a known, documented trade-off:

- **`permissions.allow` interpreter escapes.** Entries such as `Bash(python *)`
  permit arbitrary code by design, so no `Read(.env)` deny can hold against
  `python -c "open('.env')"`. The allow-list is a *convenience* boundary — "stop
  prompting me for this" — and never a security boundary. That is exactly why
  the secret-file check lives in `scripts/guard-command.sh`, which sees the real
  command. A report showing a *guard* bypass is in scope; a report showing the
  allow-list is permissive is not.
- **A model not following a rule.** Everything in `aidlc/rules/` is advisory
  guidance to a language model, not enforcement. Non-compliance is a prompting
  or sensor gap, not a vulnerability. If a rule *should* be enforced
  deterministically, that is a valuable feature request — file it as an issue.
- **Vulnerabilities in your own project** built from this template.
- **Bugs in Claude Code, Codex CLI, or Cursor.** Report those upstream to the
  respective vendor.
- Findings that require an already-compromised machine or a maintainer to run
  attacker-supplied commands knowingly.

## Supported versions

Only `main` is supported. This is a template you copy, so **fixes do not reach
existing copies** — there is no update channel. After any advisory, re-check
your copy:

```bash
bash scripts/audit.sh        # structural sensors, incl. the guard self-test
```

The guard's behaviour is pinned by `scripts/guard-cases.tsv`; the audit runs
every case plus a fail-closed check on each invocation.

## Response

Solo-maintained, so no SLA is promised. Expected in practice: acknowledgement
within a week, and for a confirmed bypass a fix plus a new row in
`guard-cases.tsv` so the same hole cannot reopen. Credit in the advisory unless
you would rather stay anonymous.

## Hardening a copy of this template

Day-one checklist for a project that adopted it:

- Fill in `aidlc/rules/tech-stack.md`, then narrow `permissions.allow` in
  `.claude/settings.json` from the broad interpreter globs to the entry points
  you actually run.
- Keep `scripts/guard-command.sh` wired into all three hook configs. If you
  extend the patterns, add cases to `guard-cases.tsv` — an untested guard rule
  is a guess.
- Verify a hook actually fires. The audit proves the config is valid JSON and
  matches each tool's output schema; only a live test proves it blocks.
- Enable secret scanning and push protection on the repository.
- Never commit `.env`. Sanitize verification evidence before it lands in
  `memory/progress.md` — command output can carry tokens and connection strings.
- Wire a `Stop`/pre-completion hook once your test command reliably passes on a
  clean tree (`aidlc/common/session-lifecycle.md` → *Close the loop on "done"*).
