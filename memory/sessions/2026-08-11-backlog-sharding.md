# 2026-08-11 — single-writer backlog and handoff

**Changed** — split the two files every session writes. The backlog is now one
record per feature at `memory/features/<id>.json`, with `memory/feature-list.json`
reduced to a manifest (schema version + the glob that locates records, `features`
permanently empty). Per-session handoff moved out of `memory/progress.md` into one
file per session under `memory/sessions/`; `progress.md` keeps only state that
outlives a session. Updated `aidlc/common/session-lifecycle.md`,
`aidlc/examples/feature-list.md` and `aidlc/operations/daily-report.md` to match.

**Evidence** — reproduced the defect and its absence with real merges on
git-inited copies. Before: two branches each appending a feature to the single
array gave `CONFLICT (content)` and the merged file failed `jq` (exit 5); the same
two sessions writing `progress.md` handoff fields also conflicted. After: the same
two sessions merged at exit 0 with no markers and a valid aggregate view; two
handoff files merged at exit 0. `bash scripts/audit.sh` exit 0, zero WARN, zero
FAIL. Reference sensor for the new shape: 29/29 arms, 20 regressions caught and 9
near-miss controls green, including a record whose id is swallowed by
`.gitignore`.

**Not verified** — the sensor is a reference implementation only; nothing in
`scripts/audit.sh` checks the sharded shape yet, so an ill-formed record is
currently caught by no committed sensor. Prose in files outside this session's
ownership still describes the old single-file shape (`AGENTS.md`, `README.md`,
`CONTRIBUTING.md`, `aidlc/inception/spec.md`, `aidlc/construction/plan.md`,
`aidlc/agents/reviewer.md`). No multi-person concurrent run has happened — the
proof is two-branch merges, not five engineers for a week.

**Decisions** — 2026-08-11: shard the backlog by path rather than ship a merge
driver. `merge=union` on the JSON object was measured: git reports a clean merge
and `jq` then fails, so the corruption becomes silent instead of marked. Union on
`progress.md` was measured too: same-line rewrites leave the file claiming two
contradictory last sessions, and delete-vs-amend silently discards the deletion —
exit 0, no marker, wrong content. 2026-08-11: rejected the append-only log; union
merge of two appends is order-dependent, so merging A into B folded `feat-a` to
`passes:false` while merging B into A folded the identical pair to `passes:true`.
A sign-off record whose value depends on merge direction is not a record.
2026-08-11: the filename carries the id, which makes uniqueness structural and
turns a same-id collision into a normal add/add conflict a human should arbitrate.

**Next** — wire the reference sensor into `scripts/audit.sh` section 3b-2
(replacing the array walk) and update the stale prose listed above.
