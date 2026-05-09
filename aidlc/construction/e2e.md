# E2E

Phase: Construction. End-to-end journey verification and release sign-off.

## Process
1. **Identify affected journeys** from the diff against main
2. **Run E2E suite** — feature branch: target affected flows. Staging: full regression.
3. **Write new journey tests** using `aidlc/examples/e2e-test-plan.md` as the format
4. **Sign off** using the checklist in the example file
5. **Log findings** — bugs → `memory/progress.md` Known Issues. Every prod escape gets an E2E test before the fix closes.

## Test rules
- Each test seeds and cleans up its own state — no shared mutable state
- `data-testid` selectors only — never CSS classes or text content
- No `sleep()` — use `waitFor` or retry-assertions
- Pass 3 consecutive runs = stable. Flaky = bug (quarantine, diagnose, fix, restore after 5 clean runs).

**No sign-off if any required item is red.** Bug triage in `aidlc/agents/reviewer.md`.
