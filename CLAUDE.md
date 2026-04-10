DOCUMENT_TYPE: PROJECT_RULES
Version: 5.1
Project: Chucha Video Compressor
Last Updated: 2026-04-10

---

# CLAUDE.md — Chucha Video Compressor

---

# PHILOSOPHY — Read First, Every Time

1. Single-file architecture — VideoCompressor.ps1 contains all UI, logic, and FFmpeg calls. Keep sections clearly delimited with comment headers. Do not split into modules unless the file exceeds 2000 lines.
2. WinForms (.NET) is the UI framework, not the product. The product is reliable 2-pass video compression to a target file size.
3. Project Phases order is law. Each phase must work before the next starts. No jumping ahead.
4. Path of least resistance. Use what exists. Do not build what is not needed yet.
5. Docs = living architecture. Stale doc = next agent writes wrong code. Update after every code change.

---

# PROJECT STRUCTURE

## File Locations

| File Type | Location | Example |
|-----------|----------|---------|
| Main Windows app | `VideoCompressor.ps1` | All UI + compression logic |
| macOS app | `chucha-compress.command` | Bash equivalent |
| Compiled EXE | `VideoCompressor.exe` | Built via `compile.ps1` |
| Build scripts | root | `compile.ps1`, `ps2exe.ps1` |
| App icon | root | `compressor.ico` |
| Demo assets | `assets/` | `cover.png`, `demo.gif`, `screenshot.jpg` |
| Design specs | `docs/superpowers/specs/` | v2 enhancement spec |
| Implementation plans | `docs/superpowers/plans/` | Active plans only — DELETE when Status: COMPLETE |
| Reference docs | `docs/` | `shutter-encoder-analysis.md`, `ui-ux-review.md` |
| AI workspace | `.ai/` | `.ai/status.md`, `.ai/journal.md` |
| Temp files | `.ai/temp/` | DELETE after use (gitignored) |
| Reports | `.ai/reports/` | `.ai/reports/YYYY-MM-DD_NAME.md` |
| User docs | `docs/` | `docs/INDEX.md` |

## Before Creating Any File

1. Check table above for correct location
2. Search if similar file exists — avoid duplicates
3. Temp files go to .ai/temp/ only
4. Reports use YYYY-MM-DD_NAME.md format (underscore, not dashes)
5. Plans use YYYY-MM-DD-name.md format (dashes)

---

# BEFORE_EVERY_ACTION

PRIORITY: CRITICAL — check before every file operation

- Check file location table — confirm correct destination
- Search for existing similar file — avoid duplicates
- Verify temp files go to .ai/temp/ only
- DOCS_SYNC: if code changed → update matching doc (see table below)

---

# DOCS_SYNC — MANDATORY

PRIORITY: CRITICAL — after EVERY code change, update the matching documentation

> **Navigation:** docs/INDEX.md — entry point. Read it first when starting a task.

## Rule: code changed → doc updated

| What changed in code | Update this document |
|--------------------|-----------------|
| VideoCompressor.ps1 UI layout | docs/ARCHITECTURE.md |
| VideoCompressor.ps1 encoding logic | docs/ARCHITECTURE.md |
| chucha-compress.command | docs/ARCHITECTURE.md (macOS section) |
| compile.ps1 or build process | docs/ARCHITECTURE.md (build section) |
| Added new feature or mode | docs/PROJECT_PHASES.md (check off step) |
| Changed coding patterns or standards | docs/CODING_STANDARDS.md |
| Compacted journal.md | docs/LESSONS_LEARNED.md + .ai/logs/journal-archive-YYYY-MM-DD.md |

**Unenforced doc = bug.** Next AI agent reads stale info and writes wrong code.

## Workflow When Starting a Task

1. Open docs/INDEX.md → find relevant docs for your task
2. Read those docs → understand current state
3. Do the work
4. Update affected docs (table above)
5. Commit includes both code AND updated docs (atomic)

---

# MANDATORY_READS_BY_ACTION

PRIORITY: CRITICAL — read BEFORE writing, not after

| You are about to... | Read FIRST |
|---------------------|-----------|
| Modify VideoCompressor.ps1 | docs/ARCHITECTURE.md (section map at ~850 lines) |
| Add new v2 feature | docs/superpowers/specs/2026-04-10-chucha-v2-design.md |
| Start a v2 implementation task | docs/superpowers/plans/2026-04-10-chucha-v2-design.md |
| Modify UI colors or fonts | docs/ui-ux-review.md + docs/CODING_STANDARDS.md (brand palette + type scale) |
| Add GPU encoding | docs/shutter-encoder-analysis.md (GPU flags + encoder map) |
| Compare UI patterns | docs/shutter-encoder-ui-comparison.md |
| Modify chucha-compress.command | Read the existing macOS script first (365 lines) |
| Change build process | Read compile.ps1 first |
| Write implementation plan | Invoke superpowers:writing-plans skill |

---

# CRITICAL MISTAKES TO AVOID

PRIORITY: CRITICAL — add NEVER rules as bugs are discovered. Never shrink this list.

## Generic NEVER Rules

- NEVER create files outside File Location Table — check table first. Scattered files cause duplication.
- NEVER skip DOCS_SYNC — code + doc update in same commit. Stale docs cause wrong future code.
- NEVER commit without running SESSION_END_CHECKLIST. Silent governance drift accumulates.
- NEVER keep temp files — DELETE from .ai/temp/ immediately after use.
- NEVER accumulate completed plans — DELETE when Status: COMPLETE. They pollute active context.
- NEVER deploy without testing the compiled EXE on a fresh system (no dev tools).

## PowerShell / WinForms NEVER Rules

- NEVER use `Write-Host` for logging inside the app — use the `Write-Log` function that outputs to the status TextBox.
- NEVER call FFmpeg without checking `$script:ffmpegPath` is set — the app auto-installs FFmpeg on first run, but the path must be confirmed.
- NEVER hardcode pixel positions — use relative positioning based on `$lastY` accumulator pattern with 8px grid steps only.
- NEVER add `Add-Type` C# blocks without testing compilation on PowerShell 5.1 — ps2exe targets .NET Framework, not .NET Core.
- NEVER forget `[void]$form.ShowDialog()` cleanup — WinForms forms must be disposed properly.
- NEVER use `Invoke-WebRequest` without `-UseBasicParsing` — full parsing fails without IE engine on some Windows installs.
- NEVER assume FFmpeg is in PATH — always use the full path stored in `$script:ffmpegPath`.
- NEVER use `-preset ultrafast` for final output — the app promises quality compression, always use `-preset slow`.
- NEVER change the 2-pass encoding budget formula without testing against known file sizes — the 0.92 overhead factor and 96kbps audio budget are calibrated.
- NEVER modify the scale filter without testing both landscape and portrait videos — the `if(gte(iw,ih))` conditional handles both orientations.

## Brand NEVER Rules (CAMERAPTOR Brand Guide)

- NEVER use color `#1CA42C` — the correct Raptor Green is `#21C134`. Root cause: v1 had wrong accent, all references must use brand-correct value.
- NEVER use `#585858` for muted text — use `#9a9590` (brand warm gray). Root cause: cool neutral gray violates brand warmth and fails WCAG AA (3.3:1 vs needed 4.5:1).
- NEVER use WOFF2 fonts with PrivateFontCollection — it requires TTF/OTF. Root cause: WOFF2 is web-only, .NET GDI+ cannot decode it.
- NEVER use vertical spacings that aren't multiples of 8px — brand grid is 8px base. Root cause: inconsistent spacing (17px, 46px) creates visual arrhythmia.
- NEVER invent ad hoc hover/pressed colors — derive from `#21C134`: hover = +15% lum (`#2AD43F`), pressed = -20% lum (`#1A9A2A`).
- NEVER skip DPI awareness call — `SetProcessDPIAware()` must be called before any WinForms rendering. Root cause: without it, high-DPI displays render blurry bitmap-scaled UI.

## How to Add Rules

When a bug is found or a fix commit is needed:
1. Identify root cause — not the symptom, the structural reason it happened.
2. Write NEVER rule: "NEVER [action]. Root cause: [why this causes a problem]."
3. Add the rule to this section above.
4. Add a [tag] entry to docs/LESSONS_LEARNED.md
5. This list grows — never shrinks.

---

# TECH STACK

- **Primary language:** PowerShell 5.1+ (Windows), Bash (macOS)
- **UI Framework:** WinForms (.NET Framework) via `System.Windows.Forms`
- **Core dependency:** FFmpeg (auto-installed, 2-pass x264/x265 encoding)
- **Build tool:** ps2exe (compiles .ps1 → .exe)
- **Infrastructure:** Local desktop app — no server, no Docker
- **Testing:** Manual testing + Pester (PowerShell testing framework) for future tests
- **Repo:** https://github.com/cameraptor/Chucha-Video-Compressor
- **Full details:** See docs/ARCHITECTURE.md

---

# ENERGIZE PROTOCOL

PRIORITY: CRITICAL — triggered when user says "energize"

Full protocol: .claude/skills/energize/energize.md (8-step adaptive, reads CLAUDE.md at runtime).

Steps:
- Step 0: Proof-loop task check (if .agent/tasks/ exists)
- Step 1: DOCS_SYNC verification
- Step 2: Journal update (if milestone completed)
- Step 3: Status update (if progress >10%)
- Step 5: SESSION_END_CHECKLIST
- Step 6: git add + commit
- Step 8: Report summary

Note: Steps 3.5 (server sync), 4 (cross-project sync), 7 (deploy) are skipped — no server deployment configured.

---

# SESSION_END_CHECKLIST

PRIORITY: CRITICAL — run before every commit and session end

- .ai/temp/ contains only .gitkeep (no stray temp files)
- .ai/journal.md updated if phase or milestone completed
- .ai/status.md progress % is current
- .ai/reports/README.md has no orphaned entries
- No [TODO] placeholders remain in any generated file
- DOCS_SYNC: every code change has matching doc update
- STALE check: no doc has unresolved STALE banner
- If reports archived: lessons extracted to LESSONS_LEARNED.md first
- Proof-loop: no .agent/tasks/ with abandoned evidence (if tasks exist)
- CONTEXT BUDGET: check line counts; run overflow procedure if exceeded
- VideoCompressor.ps1 line count < 2000 (warn if approaching)

---

# CONTEXT_BUDGET — Overflow Prevention

PRIORITY: HIGH — check during SESSION_END_CHECKLIST

| File | MAX | Overflow Procedure |
|------|-----|-------------------|
| CLAUDE.md | 450 lines | Extract largest section → docs/, replace with 1-line ref. Never extract: File Locations, BEFORE_EVERY_ACTION, DOCS_SYNC, SESSION_END, Security, this table |
| .ai/journal.md | 150 lines | Compaction: (1) lessons → LESSONS_LEARNED.md, (2) entries → .ai/logs/journal-archive-YYYY-MM-DD.md, (3) compress to 1-line + archive ref |
| .ai/status.md | 100 lines | Collapse completed steps to summary; keep full detail for current phase only |
| docs/INDEX.md | 200 lines | Max 20 router rows; remove content duplicating other docs |
| .ai/reports/ active | 3 max | Archive oldest: extract lessons → archive/ → update README |

---

# CRITICAL SECURITY RULES

## No Server — Desktop App Rules
- NO hardcoded paths to user files — always use folder browser or drop zone
- FFmpeg download URL must use HTTPS (gyan.dev mirror)
- ps2exe output must not embed sensitive metadata (check compile.ps1)
- .gitignore must exclude `Compressed/` output folder and temp ffmpeg pass files

---

# GIT RULES → docs/GIT_RULES.md

See docs/GIT_RULES.md for conventional commits, branch strategy, PR rules, merge policy.

---

# GIT_ACCESS — Reading Commit History

PRIORITY: HIGH — use these methods, not the GitHub browser

## Method 1: Direct file read (fastest)
```
.git/logs/HEAD
```

## Method 2: GitHub API (public repo)
```
https://api.github.com/repos/cameraptor/Chucha-Video-Compressor/commits?per_page=50
```

## Method 3: git commands
```bash
git log --oneline -20
git show <hash>
git diff <hash1> <hash2> -- path/to/file
```

---

# PROOF-LOOP (repo-task-proof-loop)

For substantial features, refactors, and bug fixes:

- Artifacts: .agent/tasks/<TASK_ID>/
- Required sequence: spec freeze → build → evidence → verify → fix loop
- Rules:
  - Never claim completion unless every AC is PASS
  - Verifier judges current code, not prior chat claims
  - Fixer makes the smallest defensible diff

- Repo: https://github.com/DenisSergeevitch/repo-task-proof-loop
- SESSION_END: check .agent/tasks/ for incomplete tasks before committing

---

# TOOL-SPECIFIC: CLAUDE CODE FILE OPERATIONS

## Use Native File Tools (Not Shell)

| Tool | Purpose |
|------|---------|
| Read | Read file content |
| Write | Create/overwrite file |
| Edit | Edit file (find/replace) |
| Glob | Find files by pattern |
| Grep | Search file contents |

NEVER use shell for file ops (cp, mv, cat > file, echo > file).
ALWAYS use Read/Write/Edit/Glob/Grep tools instead.

<!-- repo-task-proof-loop:start -->
## Repo task proof loop

For substantial features, refactors, and bug fixes, use the repo-task-proof-loop workflow.

Required artifact path:
- Keep all task artifacts in `.agent/tasks/<TASK_ID>/` inside this repository.

Required sequence:
1. Freeze `.agent/tasks/<TASK_ID>/spec.md` before implementation.
2. Implement against explicit acceptance criteria (`AC1`, `AC2`, ...).
3. Create `evidence.md`, `evidence.json`, and raw artifacts.
4. Run a fresh verification pass against the current codebase and rerun checks.
5. If verification is not `PASS`, write `problems.md`, apply the smallest safe fix, and reverify.

Hard rules:
- Do not claim completion unless every acceptance criterion is `PASS`.
- Verifiers judge current code and current command results, not prior chat claims.
- Fixers should make the smallest defensible diff.

Installed workflow agents:
- `.claude/agents/task-spec-freezer.md`
- `.claude/agents/task-builder.md`
- `.claude/agents/task-verifier.md`
- `.claude/agents/task-fixer.md`

Claude Code note:
- If `init` just created or refreshed these files during the current Claude Code session, do not assume the refreshed workflow agents are already available.
- The main Claude session may auto-delegate to these workflow agents when the current proof-loop phase matches their descriptions. If automatic delegation is not precise enough, make the current proof-loop phase more explicit in natural language.
- TodoWrite or the visible task/todo UI is optional session-scoped progress display only. The canonical durable proof-loop state is the repo-local artifact set under `.agent/tasks/<TASK_ID>/`.
- Keep this workflow flat. These generated workflow agents are role endpoints, not recursive orchestrators.
- Keep this block in the root `CLAUDE.md`. If the workflow needs longer repo guidance, prefer `@path` imports or `.claude/rules/*.md` instead of expanding this block.
<!-- repo-task-proof-loop:end -->
