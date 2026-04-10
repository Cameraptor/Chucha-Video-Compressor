---
name: energize
description: End-of-session finalization — docs sync, journal, status, git commit. Adaptive: reads CLAUDE.md at runtime to work with any project.
trigger: when user says "energize" or equivalent session-end signal
version: 5.0
---

# Energize Skill

## Purpose

Universal post-session finalization for any project. All steps are conditional — missing features skip gracefully. Reads CLAUDE.md at runtime to adapt without hardcoded values.

## Invocation

User says: "energize" (or "end session", "wrap up", "commit and push")

## What It Does

Executes an 8-step adaptive protocol:
- Step 0: Proof-loop task check (conditional)
- Steps 1-3: Docs sync, journal, status
- Step 5: SESSION_END_CHECKLIST (universal — always runs)
- Steps 6: Git operations
- Step 8: Summary report

Note: Steps 3.5, 4, 7 skipped (no server deploy configured for this project).

## Full Protocol

See energize.md in this directory for the complete step-by-step protocol.
