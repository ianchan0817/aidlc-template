#!/usr/bin/env bash
# Injects get-bearings reminder on Cursor session start. No stdin parsing required.
printf '%s\n' '{"agent_message":"AIDLC get bearings: read aidlc/core-workflow.md and aidlc/common/session-lifecycle.md, then memory/progress.md and memory/feature-list.json, git log -20; run ./init.sh if present. Work one slice, record verification evidence, and leave passes flips to reviewer."}'
exit 0
