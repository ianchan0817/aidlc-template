#!/usr/bin/env bash
# Cursor beforeShellExecution guard. Pattern logic lives in scripts/guard-command.sh
# (shared with Claude Code and Codex); this wrapper only handles Cursor's I/O contract.
#
# Cursor's beforeShellExecution output schema:
#   {"permission": "allow"|"deny"|"ask", "user_message": "...", "agent_message": "..."}
# Emitting an undocumented `reason` field drops the explanation, so the agent
# retries blindly. We return the documented fields and exit 0 so the JSON is honored.

payload=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  printf '%s\n' '{"permission":"deny","user_message":"Command guard unavailable (jq not installed).","agent_message":"Blocked: scripts/guard-command.sh could not run because jq is missing. Install jq or ask the user before retrying."}'
  exit 0
fi

cmd=$(printf '%s' "$payload" | jq -r '.command // empty')

if reason=$(bash scripts/guard-command.sh "$cmd" 2>&1); then
  printf '%s\n' '{"permission":"allow"}'
  exit 0
fi

esc=$(printf '%s' "$reason" | jq -Rs .)
printf '{"permission":"deny","user_message":%s,"agent_message":%s}\n' "$esc" "$esc"
exit 0
