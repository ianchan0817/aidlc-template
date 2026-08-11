# Repository setup — security & quality

Two kinds of thing live behind GitHub's **Security and quality** page. This
template ships everything that can be a file; the rest are account-side toggles
that no commit can set, so they're listed here with exact paths.

## Shipped as files (already done)

| Item | File | Effect |
|---|---|---|
| Security policy | [`SECURITY.md`](../SECURITY.md) | Satisfies "Security policy"; adds a Report link |
| Dependabot updates | [`.github/dependabot.yml`](../.github/dependabot.yml) | Weekly PRs for pinned action versions |
| Code scanning | [`.github/workflows/code-quality.yml`](../.github/workflows/code-quality.yml) | ShellCheck → SARIF → Code scanning tab |
| Code scanning (apps) | `.github/workflows/codeql.yml.example` | Copy to `.yml` once you add app code |
| Template CI | [`.github/workflows/audit.yml`](../.github/workflows/audit.yml) | Runs `scripts/audit.sh` on push/PR |
| Project verify CI | `.github/workflows/verify.yml.example` | Copy to `.yml`; runs the `verify:` commands from `project.yml` |
| PR gate checklist | `.github/PULL_REQUEST_TEMPLATE.md` | AIDLC gates as a review checklist |
| Issue routing | `.github/ISSUE_TEMPLATE/` | Sends security reports to private advisories |

## Read your own state first

No commit can set any of these, so no file can record them either — a checked-in
list of settings is stale the moment someone flips a switch. Read the live values,
then work the list below:

```bash
gh api repos/{owner}/{repo} --jq '{private,has_wiki,has_discussions,description,topics}'
gh api repos/{owner}/{repo}/rulesets --jq '.[].name'
```

Security toggles are under Settings → Advanced Security. Two consequences worth
knowing before you look: with **private vulnerability reporting** off,
`SECURITY.md` points at a Report button GitHub does not render; with **Dependabot
security updates** off, `dependabot.yml` still opens version PRs but nothing opens
*vulnerability* PRs.

## Toggles you must set by hand

Settings → **Advanced Security** (or Security → Overview, per the buttons on
that page):

1. **Private vulnerability reporting** → *Enable*. Without it, `SECURITY.md`
   points at a Report button that does not exist, and reporters fall back to
   public issues — the outcome the policy exists to prevent.
2. **Dependabot alerts** → *Enable*. `dependabot.yml` opens update PRs;
   **alerts** are what tell you a dependency is *vulnerable*. Different feature,
   separate switch. Add **Dependabot security updates** to get patch PRs
   automatically.
3. **Secret scanning** → *Enable*, and turn on **push protection**. Scanning
   finds committed secrets; push protection blocks them at `git push`, which is
   the only one that prevents rather than reports. Relevant here because the
   handoff step writes command output into `memory/progress.md`.
4. **Code scanning** — nothing to click once `code-quality.yml` has run; the
   default setup prompt disappears when SARIF arrives.
5. **Description and topics** → fill both. Costs one minute and is the only way
   anyone finds the repo.

Free public repos get secret scanning, Dependabot, and code scanning. On private
repos, secret-scanning push protection needs GitHub Advanced Security.

## Activate CodeQL once you have real source

`codeql.yml.example` is inactive on purpose. Copy it to
`.github/workflows/codeql.yml` and set `languages:` the moment your repo holds
application code in a CodeQL-supported language — Go, TypeScript, Python, Java,
Ruby, C#, C/C++, Kotlin, Swift. ShellCheck (already active) covers shell only,
so until CodeQL runs, an injection or deserialization bug in app code has **no**
scanner looking for it.

This deliberately is **not** an audit sensor. A "you have source, activate
CodeQL" check fires on any repo holding a single helper script, and a check that
goes red when nothing is wrong is how a team learns to ignore the colour. It
stays prose, here and in the header of `codeql.yml.example`. The inverse *is*
sensed:
`scripts/audit.sh` fails if `codeql.yml` is active while the repo has no
scannable source, because a workflow that fails every run is worse than none.

## Quality: make the gate real

A green check nobody enforces is decoration: until a ruleset requires them,
`audit` and `shellcheck` report without blocking anything. Settings →
**Rules → Rulesets** → New branch ruleset, target `main`:

- Require a pull request before merging (1 approval; dismiss stale approvals)
- **Require status checks to pass** → add `audit` and `shellcheck`
- Require branches to be up to date before merging
- Block force pushes
- Optionally require signed commits and linear history

Blocking force pushes matters most: `scripts/guard-command.sh` blocks them
locally, but a local guard is advice. A ruleset is enforcement — server-side, and
it applies to anyone with write access.

## Wiki

The wiki is a **separate git repository** (`<repo>.wiki.git`), so it is not
copied when someone clones or forks the template. That makes it the wrong home
for anything an adopter needs — and mirroring the README into it would break the
single-source-of-truth rule the template is built on.

Use it for material that should *not* ship in the repo — anything dated,
instance-specific, or narrative:

- Roadmap, and what is deliberately deferred
- Changelog — which reference each rule came from, and why rejected ideas were
  rejected
- Observed state of your repo's settings, if you want it written down anywhere
- FAQ and adoption notes ("we tried this on a Rails repo, here's what changed")
- Migration notes between template versions, for people who copied an older one

Everything an adopter needs stays in `README.md` and `aidlc/`. If a wiki page
would duplicate either, write it once in the repo and link to it instead.
