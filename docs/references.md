# References

Every link below was fetched and checked on **2026-08-11**. Sources whose only
contribution was already implemented are marked *provenance*; sources that
contributed nothing were removed rather than left as decoration. A reference list
with no verification date is a list nobody has re-read.

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

## Removed, and why

Kept out so nobody re-adds them expecting a contribution: **Metaflow** and
**ZenML** (ML-infrastructure tools, nothing transferable to a generic
lifecycle), **Made-With-ML** (a course, and its structure already maps onto the
three phases), and **awesome-production-machine-learning** (a tool directory —
though its dated monthly release is where the verification line at the top of
this file came from).
