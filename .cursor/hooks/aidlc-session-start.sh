#!/usr/bin/env bash
# Injects get-bearings reminder on Cursor session start. No stdin parsing required.
printf '%s\n' '{"agent_message":"AIDLC get bearings: read aidlc/common/session-lifecycle.md, then memory/progress.md and memory/feature-list.json, git log -20; run ./init.sh if present (see init.sh.example)."}'
exit 0
