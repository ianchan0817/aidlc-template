# Backlog records — one file per feature

`memory/features/<id>.json` holds one feature. `memory/feature-list.json` is the
**manifest**: it declares the schema version and the glob that locates records,
and nothing else. Nobody edits the manifest during normal work.

## Why one file per feature

Git's conflict unit is the line inside one path. Two sessions appending to one
JSON array touch the same lines, so a conflict is the steady state on a team, and
a conflict *inside a JSON object* leaves conflict markers where the parser
expects a value — the file that gates every sign-off stops parsing. Concurrent
sessions writing **different paths** cannot conflict at all: no merge driver, no
custom tooling, no recovery procedure.

Two sessions creating the *same* `<id>.json` still conflicts, and that is
correct: two people claimed one feature id, which is a real disagreement and the
one case a human should see. The filename is also what makes ids unique — a
directory cannot hold two `feat-001.json`, so uniqueness is structural rather
than a scan that has to be remembered.

## Record schema

```json
{
  "id": "feat-001",
  "priority": 100,
  "category": "functional",
  "description": "New chat button creates a fresh conversation",
  "steps": [
    "Navigate to main interface",
    "Click the New Chat control",
    "Verify a new conversation appears in the sidebar"
  ],
  "verify": "bun test chat/new-conversation",
  "spec": "docs/specs/chat.md#new-conversation",
  "passes": false,
  "verified_sha": null,
  "verified_by": null
}
```

| Field | Required | Rule |
|---|---|---|
| `id` | yes | Non-empty, `^[A-Za-z0-9][A-Za-z0-9._-]*$`, **equal to the filename minus `.json`**, and not swallowed by `.gitignore` — the secret patterns there are unanchored, so `credentials` and any `service-account*` id produces a record that exists for the session that wrote it and for nobody else. `feat-NNN` never collides |
| `priority` | no | Integer, lower runs sooner; absent sorts as 1000 |
| `category` | no | e.g. `functional`, `ux`, `security`, `agent` |
| `description` | yes | One line, outcome-focused |
| `steps` | no | Array of strings — runtime QA checklist |
| `verify` | no | Deterministic command that must pass |
| `spec` | no | Provenance link into the accepted spec |
| `passes` | yes | Boolean. **Reviewer only.** `false` until runtime-verified |
| `verified_sha` | yes when `passes` | Full 40-char lowercase commit id. A revision expression (`HEAD`, `main`, `HEAD~0`) is rejected: it resolves to whatever the tip is today, so the QA it claims can never be re-run against the state that was reviewed |
| `verified_by` | yes when `passes` | Who ran the QA (e.g. `reviewer`). A provenance record, not enforcement |

Ordering is `(priority, id)`, so two sessions that pick the same priority do not
conflict — the tie breaks on id.

**Write one field per line, 2-space indent.** Git's merge granularity is the line,
so one-field-per-line makes it field granularity: a reviewer stamping `passes` and
`verified_sha` merges cleanly against an engineer sharpening `description` in the
same record. Collapse the object onto one line and every edit to it collides.

That clean merge has one honest limitation. Git will happily combine a sign-off
with a change to the behaviour that was signed off, leaving `verified_sha`
pointing at the pre-edit commit. No sensor catches it — an ancestry check is
false on shallow clones and after squash-merges, so it is a rejected sensor. The
stale-sign-off rule below is the control, and the diff is two lines in one file,
which is why it is reviewable at all.

## Recipes

Aggregate view (never committed — a committed derived file reintroduces the
conflict this split removed):

```bash
find memory/features -maxdepth 1 -name '*.json' | sort | xargs cat | \
  jq -s 'sort_by(.priority // 1000, .id)'
```

Next slice to take:

```bash
find memory/features -maxdepth 1 -name '*.json' | sort | xargs cat | \
  jq -s 'map(select(.passes==false)) | sort_by(.priority // 1000, .id) | first'
```

Sign-off ledger, and who flipped each one:

```bash
find memory/features -maxdepth 1 -name '*.json' | sort | xargs cat | \
  jq -s 'map(select(.passes==true) | {id, verified_sha, verified_by})'
git log --oneline -- memory/features/feat-001.json
```

That last command is the point of the split for integrity too: the flip to
`passes: true` is a two-line diff in one small file, so `git log -p` on the
record shows exactly which commit claimed the sign-off and who authored it.

## Rules

- Engineers **create** records and edit their own `description`/`steps`/`verify`;
  edits to someone else's record need reviewer or human approval.
- Only the **reviewer** sets `passes: true`, stamping `verified_sha` and
  `verified_by` in the same commit.
- A `passes: true` whose `verified_sha` predates changes to the code it covers is
  stale — re-verify. Ancestry is deliberately **not** sensed: it is false on a
  shallow clone and after a squash-merge (`CONTRIBUTING.md`, Rejected sensors).
- Never append features to `memory/feature-list.json`. Its `features` array stays
  empty by design and a sensor fails a non-empty one.
