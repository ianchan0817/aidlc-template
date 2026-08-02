#!/usr/bin/env bash
# Cursor sessionStart bearings reminder. Canonical steps: aidlc/common/session-lifecycle.md
# Cursor's sessionStart output schema is {"env": {...}, "additional_context": "..."}.
# `agent_message` belongs to the beforeShellExecution/permission schema and is
# silently ignored here — using it made this hook a no-op.
printf '%s\n' '{"additional_context":"AIDLC session start: follow aidlc/common/session-lifecycle.md — get bearings (progress.md, feature-list.json, git log, ./init.sh smoke), one slice, then handoff."}'
exit 0
