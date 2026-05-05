# Investigate

Phase: Operations. Structured debugging. No fixes without root cause.

1. **Reproduce** — exact error, steps, environment, since when (`git bisect` if needed)
2. **Isolate** — stack trace bottom-up, check recent changes, binary search if unclear
3. **Hypothesize** — state top 3 likely causes with reasoning before touching code
4. **Diagnose** — targeted logging, check assumptions against actual state
5. **Fix** — minimal change for root cause. No symptom patches. No refactoring during fix.
6. **Verify** — original failure resolved, no regression, new test covers the bug
7. **Log** — record in `memory/progress.md` Known Issues. Remove when resolved.

Rules: no fix without root cause, no fix without test, log before fixing.
