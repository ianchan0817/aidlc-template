# Example: Agent eval task (YAML)

Illustrative task for an agent that must fix an auth issue. In practice: fewer graders per task unless each adds signal. See `aidlc/construction/eval.md`.

```yaml
task:
  id: fix-auth-bypass_1
  desc: "Fix authentication bypass when password field is empty"
  graders:
    - type: deterministic_tests
      required: [test_empty_pw_rejected.py, test_null_pw_rejected.py]
    - type: llm_rubric
      rubric: prompts/code_quality.md
    - type: static_analysis
      commands: [ruff, mypy, bandit]
    - type: state_check
      expect:
        security_logs: { event_type: "auth_blocked" }
  tracked_metrics:
    - type: transcript
      metrics: [n_turns, n_toolcalls, n_total_tokens]
    - type: latency
      metrics: [time_to_first_token, time_to_last_token]
```

Prefer **outcome** and **tests** over brittle “must call tool X then Y” requirements unless policy demands it.
