# References

This file has two jobs: record where each idea came from, and give you a re-check
list you can work through periodically. **Nothing is deleted from this file when a
source stops being useful** — the entry stays with its verdict, because a link
removed is a link somebody re-researches from scratch next year. A verdict is
cheap to write once and expensive to rediscover.

There is deliberately **no "last verified" date** here. A date ages into a false
claim without anyone touching the file; a command stays true. Re-verify with:

```bash
bash scripts/check-links.sh
```

It is deliberately *not* wired into `scripts/audit.sh` — the audit must pass
offline and on a runner with no egress, so a network check there would make a
green build depend on someone else's uptime. Expect two `[blocked]`, not dead:
`openai.com/index/*` answers **403 to every automated fetch** and has to be opened
in a browser.

---

## Re-check on a cadence — index pages, where new material appears

The entries further down are frozen artifacts. These are the pages that *change*,
so they are the ones worth revisiting on a schedule. None of them is loaded by any
session; they cost nothing until you open them.

| Hub | What it is |
|-----|------------|
| [Anthropic — Engineering blog](https://www.anthropic.com/engineering) | Where most load-bearing entries below came from. ~25 posts as of the check date. |
| [Claude — Developer platform docs](https://platform.claude.com/docs/en/home) | API, tools, agent SDK. Canonical for anything the API does. |
| [Claude — Managed Agents](https://platform.claude.com/docs/en/managed-agents/overview) | Hosted agent harness: agent / environment / session / events. Vendor-run execution, so its session model is a product, not a portable principle — see the note under *Surveyed*. |
| [Claude — Use cases](https://claude.com/resources/use-cases) | Filterable gallery, product-oriented. |
| [Claude — Tutorials](https://claude.com/resources/tutorials) | Written and video lessons, by product and industry. |
| [Codex — Docs](https://learn.chatgpt.com/docs) | Root of the docs whose adapter formats this template depends on. |
| [Codex — Developers](https://learn.chatgpt.com/docs/developers) | Skills, plugins, hooks, SDK, GitHub Actions. |
| [Codex — Use cases](https://learn.chatgpt.com/use-cases) | 100+ workflow gallery, filterable by category and task. |
| [Codex — Resources](https://learn.chatgpt.com/resources) | Videos, dev blog, cookbook, courses. |

**When you check the hubs, check the *vendor contracts* section too.** A hub adds
posts; a contract page changes a format, and a format change turns one of this
repo's pointers into a silent no-op.

### Not yet read — queue from the Anthropic index

Titles and URLs verified on the check date; **the content is unread**, so none of
it has been weighed against the design. Listed so the queue survives a context
window, not as endorsement.

- [Beyond permission prompts: Claude Code sandboxing](https://www.anthropic.com/engineering/claude-code-sandboxing)
- [Equipping agents for the real world with Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
- [Code execution with MCP](https://www.anthropic.com/engineering/code-execution-with-mcp)
- [Building effective agents](https://www.anthropic.com/engineering/building-effective-agents)
- [How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system)
- [Scaling Managed Agents: decoupling the brain from the hands](https://www.anthropic.com/engineering/managed-agents)
- [How we contain Claude across products](https://www.anthropic.com/engineering/how-we-contain-claude)
- [Claude Code auto mode: a safer way to skip permissions](https://www.anthropic.com/engineering/claude-code-auto-mode)
- [Designing AI-resistant technical evaluations](https://www.anthropic.com/engineering/AI-resistant-technical-evaluations)
- [Introducing advanced tool use](https://www.anthropic.com/engineering/advanced-tool-use)
- [Building a C compiler with a team of parallel Claudes](https://www.anthropic.com/engineering/building-c-compiler)
- [Claude Code: best practices for agentic coding](https://www.anthropic.com/engineering/claude-code-best-practices) — the blog original; the docs version below is the one this template cites.

---

## Load-bearing — these changed the design

**[Anthropic — Harness design for long-running apps](https://www.anthropic.com/engineering/harness-design-long-running-apps)**
Splitting generator from evaluator does not by itself remove leniency. Out of the
box a reviewer "identif[ies] legitimate issues, then talk[s] itself into deciding
they weren't a big deal and approve[s] the work anyway" — so the evaluator needs
separate calibration and criteria carrying hard failure thresholds. This is why
`aidlc/agents/reviewer.md` requires a fresh context *and* a blocking threshold,
not just a second opinion.

**[LangChain — Improving deep agents with harness engineering](https://www.langchain.com/blog/improving-deep-agents-with-harness-engineering)**
The only measured effect size in this whole list: a blocking pre-completion
verification pass moved Terminal Bench 2.0 from 52.8% to 66.5% with the model
held fixed. The dominant failure it fixes is an agent re-reading its own code,
judging it fine, and stopping. That is the argument for a completion gate over
more instructions.

**[Anthropic — Claude Code best practices](https://code.claude.com/docs/en/best-practices)**
Four tiers for how hard a check gates the stop: in-prompt, a `/goal` condition, a
Stop hook, a fresh-context reviewer. Note the bound, which is easy to miss and
which this template previously got wrong — **Claude Code overrides a Stop hook
and ends the turn after 8 consecutive blocks**, so the hook is strong but not
absolute. Also the caveat behind `aidlc/construction/review.md`: a reviewer asked
to find gaps will report some even when the work is sound.

**[Martin Fowler / Birgitta Böckeler — Harness engineering](https://martinfowler.com/articles/harness-engineering.html)**
Source of the guides-versus-sensors vocabulary this template is built on, and of
a third harness category it does **not** yet implement: architecture fitness
(dependency direction, performance budgets) enforced deterministically, alongside
maintainability (coverage) and behaviour (evals).

**[Anthropic — Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)**
Tasks, trials, graders; capability versus regression suites; gate on pass^k
rather than pass@k. The whole shape of `aidlc/construction/eval.md`.

**[Anthropic — Effective context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)**
Just-in-time retrieval over preloading, and session-start reconciliation. The
reason methodology loads on demand and only two rules are unconditional.

**[Anthropic — Writing tools for agents](https://www.anthropic.com/engineering/writing-tools-for-agents)**
A tool's output is context spend: return high-signal text under an explicit
budget, and write errors that name the cheaper next step. Implemented for the
test sensor in `scripts/agent-test.sh`.

**[Agent Skills](https://agentskills.io)**
The `skills/<name>/SKILL.md` layout all three tools load, and progressive
disclosure — only name and description load at discovery, the body on
activation. That is why a skill description is worth writing carefully.

## Source of one specific file

Losing these two links is how this file came to be rewritten: the ideas were
still in the repo, the attribution was not.

- **[Know Your Unknowns](https://thariqs.github.io/html-effectiveness/unknowns/)**
  — the 11 elicitation moves in `aidlc/common/unknowns.md`, and its framing that
  the map is not the territory. Grouped as this template groups them: eight before
  implementation (blindspot pass, teach me my unknowns, four design directions,
  mock before you wire, brainstorm the intervention, the interview, point at a
  reference, the tweakable plan), one during (implementation notes), two after
  (the buy-in doc, quiz me before I merge).
- **[Brij Kishore Pandey — How Claude Code becomes a full engineering team](https://www.linkedin.com/pulse/how-claude-code-becomes-full-engineering-team-brij-kishore-pandey-6eqkf/)**
  — the *constitution, not prompts* framing: treat each instruction layer as
  durable infrastructure, and extract conversational corrections into rules,
  skills or hooks instead of letting a layer accumulate them.

## Provenance — the lineage, already implemented

- **[AWS AI-DLC](https://github.com/awslabs/aidlc-workflows)** — the three-phase
  lifecycle and `[Answer]:` decision gates. One divergence worth knowing: AI-DLC
  adapts per *request*, this template adapts per *project* via `project.yml`.
- **[Learn Harness Engineering](https://github.com/walkinglabs/learn-harness-engineering)**
  — the five-subsystem harness shape and the idea that a shell audit is what makes
  a harness checkable rather than aspirational.
- **[Anthropic — Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)**
  — origin of `init.sh` + progress file + feature list. Dated: its central
  claim that per-session context resets are necessary is walked back by the
  harness-design post above, so treat the architecture as the contribution and
  the reset advice as superseded.
- **[Kedro](https://github.com/kedro-org/kedro)** — pipeline conventions that
  informed the phase/gate split.
- **[OpenAI — Harness engineering](https://openai.com/index/harness-engineering/)**
  — an agent-first experiment at roughly a million lines with no
  manually-written source, using enforced dependency layering plus structural
  tests. **Not first-party verified:** the page returns 403 to automated fetches,
  so this description comes from secondary coverage. The guides/sensors framing
  this template uses is Böckeler's, not this post's — an earlier version of these
  notes credited it wrongly.
- **[OpenAI — Unrolling the Codex agent loop](https://openai.com/index/unrolling-the-codex-agent-loop/)**
  — layered project docs, sandbox and approval context, and keeping adapter
  loading compact and stable. Behind the decision that adapters are thin
  pointers with repo-rooted paths. **Also 403 to automated fetches**, same
  caveat as above.

## Peer projects — same problem, a different bet

Worth tracking rather than copying: each is a large opinionated skill set for one
tool, where this template is a small methodology for three.

- **[garrytan/gstack](https://github.com/garrytan/gstack)** — 23 role-shaped
  skills (CEO, designer, eng manager, QA, release) plus browser automation and
  cross-agent coordination, for Claude Code. An early inspiration for this repo.
- **[addyosmani/agent-skills](https://github.com/addyosmani/agent-skills)** — 24
  lifecycle skills, 8 slash commands, 4 agent personas, portable across Claude
  Code / Cursor / Copilot / Codex and others. Source of the anti-rationalization
  framing, kept lightweight here. Direct comparison for anyone weighing this
  template against an off-the-shelf skill pack.

## Vendor contracts — re-verify these at each harness review

Adapter formats move, and a format change turns a pointer into a silent no-op.
Each of these has already been wrong in this repo once.

- **[Codex skills](https://learn.chatgpt.com/docs/build-skills)** — discovery is
  `.agents/skills/<name>/SKILL.md`, and SKILL.md accepts only `name` and
  `description`. `disable-model-invocation` is a Claude Code field that Codex
  ignores silently, so a manual-only skill needs a sibling
  `agents/openai.yaml` with `policy: allow_implicit_invocation: false` — without
  it the model can invoke `/ship`, which pushes, unasked.
- **[Codex hooks](https://learn.chatgpt.com/docs/hooks)** — `SessionStart.source`
  is one of `startup|resume|clear|compact` and `matcher` is a regex. Matching only
  `startup` skips the sessions whose context is stale or was just discarded.
- **[Codex rules](https://learn.chatgpt.com/docs/agent-configuration/rules)** —
  `.codex/rules/*.rules` is a Starlark **command-execution policy**
  (`prefix_rule` → `allow`/`prompt`/`forbidden`), not an instruction loader.
  Worth noting: it supports `match`/`not_match` test cases and a
  `codex execpolicy check` validator — the same discipline as
  `scripts/guard-cases.tsv`, arrived at independently.
- **[Claude Code best practices](https://code.claude.com/docs/en/best-practices)**
  — a Stop hook is overridden after 8 consecutive blocks.

## Also read, and what they add

- **[Anthropic — Infrastructure noise](https://www.anthropic.com/engineering/infrastructure-noise)**
  — an eval's resource envelope is a confounder big enough to swamp model
  differences: holding model, harness and task set fixed, resourcing alone moved
  Terminal-Bench 2.0 by ~6 points. Pin the trial envelope or an eval gate is
  measuring the runner.
- **[Anthropic — Eval awareness](https://www.anthropic.com/engineering/eval-awareness-browsecomp)**
  — an agent may satisfy a benchmark by recognising it and recovering the answer
  key instead of doing the task, and the tell is token cost rather than output.
- **[Codex custom review rules](https://learn.chatgpt.com/blog/custom-code-review-rules-for-codex)**
  — a prose rule is itself testable: one diff that must trip it, one near-miss
  that must not, one unrelated diff that must stay silent. Their own suite put
  rule-guided review at 98% of required findings against 58.3% for the control —
  directional only, since the harness is unpublished.

## Surveyed, and what they did not contribute

Kept with their verdicts so nobody re-reads them expecting more. Not dead links —
live sources that were weighed and did not change a rule or a sensor.

- **[Metaflow](https://github.com/Netflix/metaflow)** and
  **[ZenML](https://github.com/zenml-io/zenml)** — ML-infrastructure tools.
  Reproducibility-as-default and explicit pass/fail stage gates were already
  covered; nothing else transfers to a generic lifecycle.
- **[Made-With-ML](https://github.com/GokuMohandas/Made-With-ML)** — a course; its
  end-to-end iteration loop already maps onto the three phases.
- **[awesome-production-machine-learning](https://github.com/EthicalML/awesome-production-machine-learning)**
  — a tool directory. Its dated monthly release is where the verification line at
  the top of this file came from, which is the whole contribution.
- **Codex and Claude use-case galleries** (linked under *Re-check* above) — the
  contribution is starter prompts welded to named vendor plugins. Not portable
  across three tools, so nothing was lifted.
- **[Claude Managed Agents](https://platform.claude.com/docs/en/managed-agents/overview)**
  — a hosted-execution product. Its session, sandbox and event model is vendor-run
  infrastructure rather than a principle to copy into a repo-local harness.
- **Anthropic's agent-security posts** — four were read and produced no new rule
  or sensor: `aidlc/rules/security.md` already covers the ground.
