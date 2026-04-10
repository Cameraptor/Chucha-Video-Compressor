# Energize Protocol — v5.0

> Universal 8-step adaptive post-session finalization.
> READS CLAUDE.md AT RUNTIME — adapts to any project without hardcoded values.
> ALL STEPS ARE CONDITIONAL — missing features skip gracefully.
> Universal checks always run regardless of project configuration.

---

## RUNTIME SETUP

Before executing any step:
1. Read CLAUDE.md from project root
2. Extract: DOCS_SYNC table, SESSION_END_CHECKLIST, DEPLOY_COMMAND (if present), CROSS_PROJECT_SYNC (if present)
3. Check: does .agent/tasks/ exist? does .ai/journal.md exist? does .ai/status.md exist?
4. Proceed with steps below

---

## STEP 0: PROOF-LOOP CHECK

Condition: skip if .agent/tasks/ does not exist in project root.

If .agent/tasks/ exists:
- List all task folders under .agent/tasks/
- For each task folder: check if evidence.md is present
- If spec.md exists but evidence.md is absent or last modified >7 days ago → WARN: "Task {{TASK_ID}} has no recent evidence — consider running evidence mode before committing"
- If verdict.json exists with status FAIL → WARN: "Task {{TASK_ID}} has failing verdict — resolve before committing"
- Do NOT block the commit — only warn

---

## STEP 1: DOCS_SYNC VERIFICATION

Condition: always runs (universal).

Actions:
1. Read the DOCS_SYNC table from CLAUDE.md (extracted in runtime setup)
2. Run: git diff --name-only HEAD (or git status for uncommitted changes)
3. For each changed file: check if matching doc update is needed per DOCS_SYNC table
4. If any doc is stale → update it now
5. If DOCS_SYNC table not found in CLAUDE.md → skip this step, note in Step 8 report

Output: list of docs checked, list of docs updated (or "no updates needed")

---

## STEP 2: JOURNAL UPDATE

Condition: skip if .ai/journal.md does not exist.

If .ai/journal.md exists:
- Ask yourself: was a phase or milestone completed in this session?
- If yes → add entry to .ai/journal.md using format:
  ```
  ## Phase N: [Name] (YYYY-MM-DD)
  Actions: [what was done]
  Files: [files created or modified]
  Lessons: [tag] lesson — root cause or correct approach
  ```
- If no milestone → skip (do not add entries for small changes)
- Check journal line count: if >150 lines → run compaction:
  1. Extract ALL Lessons bullets → append to docs/LESSONS_LEARNED.md
  2. Copy full entries → .ai/logs/journal-archive-YYYY-MM-DD.md
  3. Compress journal to 1-line summaries + archive reference

---

## STEP 3: STATUS UPDATE

Condition: skip if .ai/status.md does not exist.

If .ai/status.md exists:
- Check: did progress change >10% in this session?
- If yes → update .ai/status.md: progress %, current phase, blockers, last updated date
- If no significant change → skip

---

## STEP 3.5: SERVER DOCS SYNC

Condition: skip if SERVER_DOCS_SYNC is not configured in CLAUDE.md.

If SERVER_DOCS_SYNC is configured in CLAUDE.md:
- Check: did this session introduce a new container, port, cron job, backup change, or new project row?
- If yes → update the master server reference doc at the path specified in CLAUDE.md SERVER_DOCS_SYNC:
  - Update: project row, Critical Paths, Running Services, Cron, Lessons Learned (as applicable)
  - Do NOT sync: UI changes, business logic, API parameters, database schema — infra only
- If only project-internal changes → skip this step

---

## STEP 4: CROSS-PROJECT SYNC

Condition: skip if CROSS_PROJECT_SYNC is not configured in CLAUDE.md AND SERVER_DOCS_SYNC not configured.

If CROSS_PROJECT_SYNC is configured in CLAUDE.md:
- Check if this session introduced universal lessons (new infra pattern, new server config, new container)
- If yes → update the configured external knowledge base per CLAUDE.md instructions
- If only project-internal changes → skip

---

## STEP 5: SESSION_END_CHECKLIST

Condition: ALWAYS runs (universal checks regardless of project).

Execute every check from the SESSION_END_CHECKLIST in CLAUDE.md.
If SESSION_END_CHECKLIST section not found → run these universal checks:

Universal checks (always run):
- [ ] .ai/temp/ contains only .gitkeep (no stray temp files — delete if found)
- [ ] No [TODO] placeholders remain in any file changed this session
- [ ] .cursorrules and CLAUDE.md are in sync (if both exist — check they differ only in title + tool section)
- [ ] No secrets or API keys in staged files (grep for: API_KEY, SECRET, PASSWORD, PRIVATE_KEY, TOKEN)
- [ ] Any fix commits since last energize? If yes: was a NEVER rule added to CLAUDE.md Critical Mistakes?

Additional checks from CLAUDE.md SESSION_END_CHECKLIST (if present):
- Run each item in order
- For each failed item: fix it now if possible, or add to WARN list for Step 8 report

---

## STEP 6: GIT OPERATIONS

Condition: always runs if there are uncommitted changes.

Actions:
1. git status — identify changed files
2. git add: stage relevant changed files (code + docs together, atomic commit)
   - Stage: all changed source files, all changed docs
   - Do NOT stage: .env, secrets, .ai/temp/ files
3. git commit with descriptive message:
   - Format: conventional commit (feat/fix/docs/chore/refactor)
   - Message: describe WHY, not just WHAT
   - NO Co-Authored-By lines (per project rules)
4. If no changes to commit → note in Step 8 report

---

## STEP 7: DEPLOY + HEALTH CHECK

Condition: skip if DEPLOY_COMMAND is not configured in CLAUDE.md.

If DEPLOY_COMMAND is configured in CLAUDE.md:
1. Read the deploy command(s) from CLAUDE.md
2. Ask user for confirmation before deploying (deploy is irreversible)
3. Execute deploy commands in order
4. Run health check:
   - If HEALTH_CHECK_URL is configured → curl/fetch the URL, expect 200
   - If health check script exists (scripts/health-check.sh) → run it
   - If neither configured → manually verify the service responds
5. If health check fails:
   - WARN: "Health check failed after deploy"
   - Suggest rollback command if documented in CLAUDE.md or docs/DEPLOYMENT.md
   - Do NOT auto-rollback — user must decide

---

## STEP 8: REPORT

Condition: always runs (universal).

Output a summary covering:

```
ENERGIZE COMPLETE — Session Summary
=====================================
DOCS_SYNC:    [N docs checked, N updated / no updates needed]
JOURNAL:      [updated / skipped — no milestone]
STATUS:       [updated to X% / skipped — no change]
SERVER_SYNC:  [master doc updated / skipped — no infra change / not configured]
PROOF-LOOP:   [N tasks checked, N warnings / no tasks / not installed]
CHECKLIST:    [all passed / N warnings: list them]
GIT:          [committed: "message" / no changes to commit]
DEPLOY:       [deployed successfully / skipped — not configured / FAILED: reason]
HEALTH:       [OK / FAILED / not checked]

WARNINGS (action required):
- [list any unresolved warnings from steps above]
```

If any warnings exist → show them prominently at the top of the report.
