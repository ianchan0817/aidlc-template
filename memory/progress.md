# Project memory

Lean handoff across sessions. Git holds history; this file holds **decisions**, **context**, and **next actions**. Update at end of each substantive session per `aidlc/common/session-lifecycle.md`.

## Current focus
<!-- 1–2 sentences: active initiative or slice + lifecycle phase (inception/construction/operations) -->
Design-system round complete: design-tokens rule added (8 rules now), ux-guidelines refocused on behavior, /design phase rewritten as a designer's process. Template stable; next work is user-driven.

## Deferred (evaluated, worth doing, not yet done)
From the mcpmarket skills evaluation — each closes a real gap but was cut for budget this round:
- **Lint delta gating** in `review.md`: capture error/warning counts on a clean tree, compare on the branch; new errors block, warnings must not increase. Plus treat every `eslint-disable`/`# noqa`/`@SuppressWarnings` in the diff as a Pass-1 finding — remove it and prove the rule fires. (~55w) Catches the commonest way an agent makes a gate green without fixing anything.
- **Depth-not-presence** in `spec.md` Gate (~25w): a heading that exists but says nothing currently passes. NFRs need measurable targets with baselines; data contracts need field names/types.
- **Deviation analysis** in `plan.md` (~45w): before implementing in existing code, tabulate Aspect | Existing | Proposed | Why deviate | Decision; accepted deviations become ADRs. Our deviation machinery is currently retroactive only (implementation-notes, after the surprise).
- **Alert quality** in `operate.md` (~40w): alert on symptoms not causes; track alert-to-incident ratio and prune. Step 2 mandates a runbook per alert — a coverage check with no quality check.
- **Diagram guidance** in `plan.md` (~50w): diagram only when the shape is the point, cap 5–9 nodes, mermaid-in-markdown so it diffs as text, confirm it renders.

## Last session
<!-- What changed, commits, blockers resolved -->
2026-08-05: Design-system round. Split UI guidance by the question it answers: new `aidlc/rules/design-tokens.md` (color named by role not hue, every used fg/bg pair named with a measured ratio, dark mode as a second role set not inverted lightness, type scale with inverse line-height + 45–75ch measure, spacing/radius/elevation/motion steps) vs refocused `ux-guidelines.md` (hierarchy & position, five states, interaction — undo over confirm, prevent-not-report, forgiving input, never lose typed work — responsive, WCAG AA incl. 3-flash seizure threshold and terminology consistency). Rewrote `/design` as a designer's process: job before drawing, hierarchy in greyscale, every branch is a state, tokens not raw values, self-critique as a stranger. Adapter pointers added for both tools (audit enforces parity).

Evaluated 4 mcpmarket skills + the catalog (5 agents). **The marketplace is not a source** — every `/tools/skills/` page is an SEO wrapper with no skill body; real content sits in linked repos at 2–24 stars. `aidlc-design-architect` (7,477w) has *zero* UI/UX content despite the name and hard-depends on Atlassian/Linear MCP; `react-code-fix-linter` is 12 lines hardcoding two React-monorepo yarn scripts — full reject. Nothing installed or executed. Adopted 4 items, all fixing real gaps in our own files: **pinned review base SHA** (`review.md` ran `git diff origin/main` with no fetch and no pinned SHA — a fresh-context reviewer could judge a stale range), **untrusted-ref execution** (`security.md` covered prompt injection but not running contributor-controlled code with credentials in scope), the **3-flash seizure threshold**, and an **option-articulation contract** in decision-gates (name each option, state what it gives up; if you can't, collapse it — kills padded three-option gates).

Budget: rather than a 7th trim, fixed the metric. `aidlc/examples/` is 1,713w of fill-in templates the README calls "not auto-loaded" — counting them in a context-window budget measured the wrong thing. Now split: methodology <8000 (7,392) and templates <2500 (1,713), both negative-tested. Trimmed 6 files honestly along the way (ux-guidelines, design.md, session-lifecycle, postmortem, e2e-test-plan, unknowns).

Verification: audit exit 0, 18 sensors green, no warnings; 13/13 structural negative tests; both new budget sensors fire on injected bloat; guard 45/45.

2026-08-02 (later): Measured the README's real mobile behaviour (table rows to 255 chars; paragraphs wrap, tables and code blocks do not) and restructured it — TOC, badges, all tables ≤2 cols and ≤90 chars, code ≤80, 8 `<details>` sections, wide tables converted to bullets. Corrected my own first measurement: `awk length` counted UTF-8 bytes, so the "141-char" ASCII diagram was actually 61 chars — tables were the real problem, not diagrams.

Then verified all three tool configs against current vendor docs via 3 parallel agents, which found live bugs: (1) **three Cursor rules were dead** — brace expansion in `globs` collides with Cursor's documented comma-splitting, so `**/*.{ts,tsx}` shredded into invalid fragments and matched nothing; (2) Cursor's `sessionStart` hook emitted `agent_message` where the schema wants `additional_context`, making the bearings reminder a **no-op that reported success**; (3) Cursor's deny payload used an undocumented `reason` field, dropping the explanation; (4) `.codex/config.toml` used the deprecated `codex_hooks` alias; (5) **Codex's guard ran `grep` with no `jq` and no file argument**, matching the entire JSON payload — blocking benign commands whose cwd contained a match; (6) Claude's `Read(.env)` denies had no `Edit(.env)` counterpart and missed `.env.*` siblings.

Root cause of the drift: three inline copies of one regex. Consolidated into `scripts/guard-command.sh` (+ `guard-cases.tsv`), fails closed, per-segment flag/target proximity. Found and fixed two of my own bugs while building it: `git push -f` slipped through (regex required a space the `push ` had already consumed), and — caught by my own guard blocking my own test command — the four `rm` conditions were checked independently across the whole command, so `rm -rf ./tmp && ls /etc` tripped the root-delete rule. A third bug (`printf '%s'` with no trailing newline made `while read` skip the only segment, silently disabling every segment check) was caught by the case table.

Expanded `aidlc/rules/ux-guidelines.md` with every-state-is-a-design, responsive/mobile, and a WCAG 2.1 AA accessibility floor (contrast, keyboard operability, focus management, semantics-before-ARIA, live regions, reduced-motion). Folded a11y into the existing UX rule rather than adding an 8th rule file — avoids 3 new adapter pointers and a11y *is* UI guidance.

Verification: guard 45/45 cases + fail-closed; **13/13 negative tests** (each invariant regressed on a scratch copy must make the audit exit 1 — one initially MISSED, revealing the `reason` sensor only matched the unescaped form while real JSON-in-shell hooks contain `\"reason\"`; sensor fixed, not the test); `bash scripts/audit.sh` exit 0 with 18 green sensors.

Prior in-day round: adapter-loadability — 14 phase commands and 3 subagents were in formats no tool loads.

Fixed: (1) all 14 skills were flat `<tool>/skills/<name>.md` — Claude Code, Cursor, and Codex all require `skills/<name>/SKILL.md`, so **no `/spec`, `/plan`, `/build`… existed in any tool**. Regenerated as 42 directory-form SKILL.md pointers (3 tools × 14), `/ship` marked `disable-model-invocation: true` since it pushes. (2) All three `.claude/agents/*.md` lacked the **required** `name:` field, so the subagents never registered; `tools:` converted from YAML list to the documented comma string, and `TaskCreate/TaskUpdate/TaskList` dropped (filtered out of background subagents anyway) in favour of `TodoWrite`/`Skill`/`WebFetch`. (3) Codex had no command surface at all — it now supports skills, so `.codex/skills/` closes the three-tool parity gap.

Also folded in: four-tier "close the loop on done" (per-prompt → goal condition → stop-hook → fresh-context reviewer) answering the deferred Stop-hook question; fresh-context adversarial review plus its over-reporting caveat in review.md/reviewer.md; two-corrections-then-compact (was "repeated corrections"); human-in-the-loop and adapters-that-load as commitments.

Verification evidence: skills fix confirmed live — the 14 skills went from absent to present in Claude Code's runtime skill listing after the restructure. Four new audit sensors (skill shape + per-tool parity, agent frontmatter, rule parity) each negative-tested against a scratch copy: regressing to a flat skill file, stripping `name:`, deleting a rule pointer, and emptying a skill dir all produce `[FAIL]` and exit 1. `bash scripts/audit.sh` exit 0 on the real tree; `bash -n` clean.

Prior round (2026-07-07): `scripts/agent-test.sh` sensor, compaction protocol, spec-immutability clause — commit f3d2ff5.

## Next session
<!-- First action for the next person/agent -->
None queued. Adapter formats move fast — re-verify skill/agent frontmatter against vendor docs at each harness review (`aidlc/operations/retro.md` step 3), since a format change turns every pointer into a silent no-op.

## Recent decisions
<!-- YYYY-MM-DD: decision — rationale (one line each) -->
2026-08-02: One shared `scripts/guard-command.sh` instead of inline regex per tool — three copies provably drifted; each hook now only extracts the command and forwards the exit code.
2026-08-02: `permissions.allow` is documented as a convenience boundary, not a security boundary — it permits interpreters, so `Read(.env)` denies cannot hold; the secret check lives in the guard hook, which sees the real command.
2026-08-02: Canonical word budget raised 8,000 → 9,000 AND a per-file 700-word limit added — the total scales with phase/example count and was becoming a vanity metric; per-file size is what actually affects adherence.
2026-08-02: Accessibility folded into `ux-guidelines.md` rather than an 8th rule file — avoids 3 new adapter pointers, and a11y is UI guidance, not a separate concern.
2026-08-02: Adapter *shape* is an audit sensor, not a convention — existence checks passed while every slash command was dead; loaders fail silently, so CI must assert the loader's actual format.
2026-08-02: No Stop-hook ships with the template — it is the strongest completion gate but would fire every turn in a repo with no test command; documented as tier 3 of four, wired per project once `./init.sh` passes clean. Closes the open question carried since 2026-07-05.
2026-08-02: Codex gets a skills adapter (`.codex/skills/`) but still no agents adapter — Codex supports the Agent Skills layout natively; its subagent config is a different mechanism and stays prose-invoked.
2026-07-07: REJECTED 6-file Memory Bank (projectbrief/productContext/systemPatterns/…) — volatility split already exists (low: aidlc/rules + docs/adr; high: memory/); would duplicate and blow token budget.
2026-07-07: REJECTED audit.md append-only ledger + aidlc-state.md — git is the ledger, decisions/ files carry timestamps, progress.md tracks phase; re-affirms earlier rejection.
2026-07-07: REJECTED 4th "initializer" agent — triad + append-only feature-list + mid-flight change protocol already provide epistemic closure; added the missing halt-and-escalate clause to engineer.md instead.
2026-07-07: Adapters use prose pointers, never @-imports — @ resolves relative to the containing file (forces ../../ chains) and doesn't exist in Cursor/Codex; recorded in CLAUDE.md.
2026-07-07: Model-agnostic + path-rooted are enforced audit sensors, not conventions — `model: inherit` only, no ../ chains; CI fails otherwise.
2026-07-05: Guard hooks read stdin JSON, not env vars — env-var form never fired (verified no-op); stdin is the documented interface for Claude Code and Codex.
2026-07-05: Coverage gate is diff-based (100% on new/modified) — global 100% is unreachable in brownfield and contradicted AGENTS.md.
2026-07-05: `passes: true` requires `verified_sha` stamp — makes stale passes detectable and re-verification skippable when SHA unchanged.
2026-07-05: Ship gate for evals softened to "green when a suite exists" — template stays generic; runner named in tech-stack.md fill-in.
2026-07-05: Template gets its own CI (audit.sh in GitHub Actions) — three dangling refs and a broken hook survived manual review; structure checks are now deterministic sensors.

## Open questions
<!-- Owner per item -->
None. (Resolved 2026-08-02: pre-completion hooks are documented as a per-project tier, not shipped — see Recent decisions.)

## Known issues
<!-- Active bugs/debt; remove when resolved -->
None.
