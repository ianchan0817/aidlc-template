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
| PR gate checklist | `.github/PULL_REQUEST_TEMPLATE.md` | AIDLC gates as a review checklist |
| Issue routing | `.github/ISSUE_TEMPLATE/` | Sends security reports to private advisories |

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

Free public repos get secret scanning, Dependabot, and code scanning. On private
repos, secret-scanning push protection needs GitHub Advanced Security.

## Quality: make the gate real

A green check nobody enforces is decoration. Settings → **Rules → Rulesets** →
New branch ruleset, target `main`:

- Require a pull request before merging (1 approval; dismiss stale approvals)
- **Require status checks to pass** → add `audit` and `shellcheck`
- Require branches to be up to date before merging
- Block force pushes
- Optionally require signed commits and linear history

That last part matters for this repo specifically: `scripts/guard-command.sh`
blocks force-pushes locally, but a local guard is advice. A ruleset is
enforcement — server-side, and it applies to anyone with write access.

## Wiki

The wiki is a **separate git repository** (`<repo>.wiki.git`), so it is not
copied when someone clones or forks the template. That makes it the wrong home
for anything an adopter needs — and mirroring the README into it would break the
single-source-of-truth rule the template is built on.

Use it for maintainer-side material that should *not* ship in the template:

- Roadmap and what's deliberately deferred (currently in `memory/progress.md`)
- Methodology changelog — which reference each rule came from, and why rejected
  ideas were rejected
- FAQ and adoption notes ("we tried this on a Rails repo, here's what changed")
- Migration notes between template versions, for people who copied an older one

Everything an adopter needs stays in `README.md` and `aidlc/`. If a wiki page
would duplicate either, write it once in the repo and link to it instead.
