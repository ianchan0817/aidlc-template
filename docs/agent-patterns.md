# Agent patterns

Applies when the product itself contains tools, prompts, multi-turn flows or
autonomous loops — the same trigger as `aidlc/construction/eval.md`. That file
says how to *measure* an agentic feature; this one says what to *build*, which is
the decision that comes first.

## The default is not an agent

Two shapes, and the distinction is load-bearing. A **workflow** has "LLMs and
tools orchestrated through predefined code paths". An **agent** is a system where
"LLMs dynamically direct their own processes and tool usage".

The trade is explicit: agentic systems "often trade latency and cost for better
task performance", and autonomy brings "higher costs, and the potential for
compounding errors". So the rule is to start with the simplest thing that could
work — often a single call with retrieval and good examples — and **add
complexity only when it demonstrably improves outcomes**. "Demonstrably" means an
eval, not an opinion: if you cannot show the autonomous version beating the fixed
one on a suite you wrote first, you have bought cost and variance for nothing.

Three principles carry across every shape below: keep the design simple, make the
agent's planning steps visible rather than implicit, and treat the tool surface as
a designed interface.

## Pattern catalog

Pick the cheapest row that fits. Each step down the table buys capability with
latency, spend and failure modes.

| Pattern | Use when | What it costs you |
|---|---|---|
| Single augmented call | Retrieval and examples are enough | Nothing — this is the baseline to beat |
| Prompt chaining | "The task can be easily and cleanly decomposed into fixed subtasks" | Latency, traded for accuracy per step |
| Routing | Inputs fall into distinct categories that deserve different handling | A classifier that can misroute silently |
| Parallelization | Independent subtasks (sectioning), or several attempts raise confidence (voting) | N× spend; voting needs a tie-break rule |
| Orchestrator-workers | "Complex tasks where you can't predict the subtasks needed" | Unbounded fan-out unless you cap it |
| Evaluator-optimizer | "Clear evaluation criteria" exist and "iterative refinement provides measurable value" | Loops forever without a stopping condition |
| Autonomous agent | Open-ended work where the environment gives ground truth each step | Compounding errors; needs sandbox and checkpoints |

## You are already running one of these

Name the pattern before inventing one. This template's own harness is an
**evaluator-optimizer**: `engineer` produces, `reviewer` grades in a fresh context
against criteria with a blocking threshold, and the loop repeats. Its stopping
conditions are the sprint contract and the reviewer's verdict; its human
checkpoint is `aidlc/common/decision-gates.md`; its deterministic grader is
`scripts/audit.sh`. Recognising that saves you from building a second, worse copy
of it inside the product.

## Stopping conditions are not optional

Any loop that decides its own next step needs a bound, and "the model will stop
when it's done" is not one. Give every autonomous loop at least a maximum
iteration count, an explicit blocker path that returns to a human for information
or judgement, and a checkpoint before anything irreversible. A loop whose only
exit is success will spend your budget proving it cannot succeed.

Pair this with the gating tiers in `aidlc/common/session-lifecycle.md` → Close the
loop on "done": the same question — *what check decides this is finished* — applies
to the agent you ship, not just the one you code with.

## Agent-computer interface

Tool definitions deserve the same effort as the prompt. One team reported they
"spent more time optimizing our tools than the overall prompt", and it is the
cheaper lever: a prompt fix helps one path, a tool fix helps every call.

Give the model room to think before it commits to a call, rather than a format
that forces it to write itself into a corner. Keep argument formats close to what
occurs naturally in text, and avoid formatting overhead the model has to spend
attention on. Document each tool as you would document a function for a new hire:
what it does, an example call, the edge cases, and what it will refuse.

Then **poka-yoke** it — shape the interface so the likely mistake is impossible
rather than merely documented. An absolute path where a relative one silently
resolves elsewhere, an enum where a free-string invites a typo, a required
confirmation flag on the destructive variant. Test tools against real transcripts
before trusting them, and hold the output to an explicit budget
(`aidlc/rules/api-conventions.md`, and `scripts/agent-test.sh` as the worked
example).

## Source caveat

The post this draws from carries its own note that much of the tooling landscape
has changed since it was written. Treat the **patterns and the cost argument** as
durable, and any specific framework or SDK advice in it as dated — check the
current platform docs in `docs/references.md` before following tooling guidance.
