# Investigate

Phase: Operations. Structured debugging. No fixes without root cause.

1. **Reproduce** — exact error, steps, environment, since when (`git bisect` if needed)
2. **Isolate** — stack trace bottom-up, check recent changes, binary search if unclear
3. **Hypothesize** — state top 3 likely causes with reasoning before touching code
4. **Diagnose** — targeted logging, check assumptions against actual state
5. **Fix** — minimal change for root cause. No symptom patches. No refactoring during fix.
6. **Verify** — the new test **fails without the fix and passes with it**; no regressions elsewhere
7. **Log** — record in `memory/progress.md` Known Issues. Remove when resolved.

Rules: no fix without root cause, no fix without test, log before fixing. After 3 failed hypotheses, stop and escalate with findings — rerunning unchanged commands yields no new information.

## Measuring

**Verify on the real target.** A pass on a proxy — local machine, simulator, staging, mock — is not evidence about the real one. When the two disagree the target is right, and the proxy hides a bug rather than disproving it.

**Instruments lie.** Introspection calls can report state that contradicts observable behaviour. When a check and the output disagree, trust the output and stop trusting that check.

**Measure before the second hypothesis.** One wrong guess is cheap. Two in a row means the next step is an instrument, not another guess.

**Diagnostics are code and fail like code.** A report written after the failing line never runs; a truncating writer erases what another appended. Reading a stale artifact and concluding from it is the expensive version of this mistake — confirm the diagnostic actually updated before trusting what it says.
