# IDE Auto-Setup — Chucha Video Compressor

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Set up complete IDE_AUTO_SETUP v5.1 Level 2 Pro governance for the Chucha Video Compressor project so all future AI agent sessions have rules, context, and enforcement.

**Architecture:** This is a file-creation-only plan. No source code changes. We generate ~20 governance/docs/config files following the IDE_AUTO_SETUP v5.1 templates, filled in with Chucha-specific values. Existing files (README.md, docs/*.md, VideoCompressor.ps1) are NOT touched.

**Tech Stack:** Markdown governance files, Claude Code skills (energize), proof-loop subagents

**Reference:** IDE_AUTO_SETUP v5.1 knowledge base at `d:/Work/Obsidian/Voogie/60 Knowledge/Tools/IDE_AUTO_SETUP/`

---

## Setup Decisions (Q1–Q6 Pre-Answered)

| Question | Answer | Impact |
|----------|--------|--------|
| Q1: AI Tools | Claude Code only | Create CLAUDE.md + AGENTS.md. No .cursorrules needed |
| Q2: Deploy Setup | No server — manual ps2exe → GitHub Releases | No DEPLOY_COMMAND, no SERVER_DOCS_SYNC section |
| Q3: External APIs | None (FFmpeg is standard CLI) | No external docs directories |
| Q4: Project Phases | v1 DONE, v2 spec ready, define 4 phases | Fill PROJECT_PHASES.md with Chucha-specific phases |
| Q5: Proof-Loop | Yes — v2 is a substantial feature rewrite | Install proof-loop subagents |
| Q6: Architecture | Simple single-file app, no layer separation | Lightweight ARCHITECTURE.md, no layer tests |

---

## File Map — What Gets Created

| # | File | Action | Task |
|---|------|--------|------|
| 1 | `.gitignore` | **Modify** — add governance ignores | Task 1 |
| 2 | `CLAUDE.md` | **Create** — primary rules (single source of truth) | Task 2 |
| 3 | `AGENTS.md` | **Create** — 10-line pointer to CLAUDE.md | Task 3 |
| 4 | `docs/INDEX.md` | **Create** — task router for AI agents | Task 4 |
| 5 | `docs/PROJECT_PHASES.md` | **Create** — phase 0–3 with gates | Task 5 |
| 6 | `docs/CODING_STANDARDS.md` | **Create** — PowerShell rules | Task 6 |
| 7 | `docs/GIT_RULES.md` | **Create** — conventional commits | Task 7 |
| 8 | `docs/LESSONS_LEARNED.md` | **Create** — machine-navigable index | Task 8 |
| 9 | `docs/ARCHITECTURE.md` | **Create** — single-file app structure | Task 9 |
| 10 | `.ai/status.md` | **Create** — current phase tracker | Task 10 |
| 11 | `.ai/journal.md` | **Create** — build log | Task 10 |
| 12 | `.ai/reports/README.md` | **Create** — reports index | Task 10 |
| 13 | `.ai/temp/.gitkeep` | **Create** — temp dir | Task 10 |
| 14 | `.ai/logs/.gitkeep` | **Create** — journal archives dir | Task 10 |
| 15 | `.ai/reports/archive/.gitkeep` | **Create** — reports archive dir | Task 10 |
| 16 | `.claude/skills/energize/SKILL.md` | **Create** — skill metadata | Task 11 |
| 17 | `.claude/skills/energize/energize.md` | **Create** — 8-step protocol | Task 11 |
| 18 | `.claude/skills/energize/README.md` | **Create** — skill readme | Task 11 |
| 19 | `.claude/agents/task-spec-freezer.md` | **Create** — proof-loop agent | Task 12 |
| 20 | `.claude/agents/task-builder.md` | **Create** — proof-loop agent | Task 12 |
| 21 | `.claude/agents/task-verifier.md` | **Create** — proof-loop agent | Task 12 |
| 22 | `.claude/agents/task-fixer.md` | **Create** — proof-loop agent | Task 12 |
| 23 | `.agent/tasks/.gitkeep` | **Create** — proof-loop tasks dir | Task 12 |

**Existing files NOT touched:** `README.md`, `VideoCompressor.ps1`, `chucha-compress.command`, `compile.ps1`, `ps2exe.ps1`, `compressor.ico`, `LICENSE`, `assets/*`, `docs/ui-ux-review.md`, `docs/shutter-encoder-analysis.md`, `docs/shutter-encoder-ui-comparison.md`, `docs/superpowers/specs/*`, `docs/superpowers/plans/2026-04-10-chucha-v2-design.md`

---

## Task 1: Update .gitignore

**Files:**
- Modify: `.gitignore`

- [ ] **Step 1: Add governance ignores to .gitignore**

Append to the existing `.gitignore` (which currently has `ffmpeg2pass*`, `*.log`, `*.log.mbtree`, `Compressed/`):

```
# AI workspace temp
.ai/temp/*
!.ai/temp/.gitkeep

# Proof-loop skill repo (cloned submodule)
.claude/skills/repo-task-proof-loop/

# OS
.DS_Store
Thumbs.db
```

- [ ] **Step 2: Verify .gitignore**

Run: `cat .gitignore`

Expected: original 4 lines + new governance ignores appended.

- [ ] **Step 3: Commit**

```bash
git add .gitignore
git commit -m "chore: add governance ignores to .gitignore"
```

---

## Task 2: Create CLAUDE.md — Primary Rules

**Files:**
- Create: `CLAUDE.md`

This is the most critical file — single source of truth for all AI agents.

- [ ] **Step 1: Create CLAUDE.md with full content**

Write the file `CLAUDE.md` at project root with the following exact content:

```markdown
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
| Modify UI colors or fonts | docs/ui-ux-review.md (brand corrections) |
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
- NEVER hardcode pixel positions — use relative positioning based on `$lastY` accumulator pattern used in the existing UI code.
- NEVER add `Add-Type` C# blocks without testing compilation on PowerShell 5.1 — ps2exe targets .NET Framework, not .NET Core.
- NEVER forget `[void]$form.ShowDialog()` cleanup — WinForms forms must be disposed properly.
- NEVER use `Invoke-WebRequest` without `-UseBasicParsing` — full parsing fails without IE engine on some Windows installs.
- NEVER assume FFmpeg is in PATH — always use the full path stored in `$script:ffmpegPath`.
- NEVER use `-preset ultrafast` for final output — the app promises quality compression, always use `-preset slow`.
- NEVER change the 2-pass encoding budget formula without testing against known file sizes — the 0.92 overhead factor and 96kbps audio budget are calibrated.
- NEVER modify the scale filter without testing both landscape and portrait videos — the `if(gte(iw,ih))` conditional handles both orientations.

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
```

- [ ] **Step 2: Verify CLAUDE.md line count**

Run: `wc -l CLAUDE.md`

Expected: under 450 lines (target ~280–320 lines).

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: add CLAUDE.md — IDE_AUTO_SETUP v5.1 Level 2 Pro governance"
```

---

## Task 3: Create AGENTS.md — Universal Pointer

**Files:**
- Create: `AGENTS.md`

- [ ] **Step 1: Create AGENTS.md**

Write `AGENTS.md` at project root:

```markdown
# AGENTS.md — Universal AI Agent Rules

All project rules are defined in **CLAUDE.md** (single source of truth).
Read CLAUDE.md before starting any task.

<!-- MANAGED: repo-task-proof-loop -->
Active tasks: see .agent/tasks/
Subagents: .claude/agents/
<!-- /MANAGED -->

Quick Reference: Rules → CLAUDE.md | Entry → docs/INDEX.md | Status → .ai/status.md
```

- [ ] **Step 2: Commit**

```bash
git add AGENTS.md
git commit -m "docs: add AGENTS.md — pointer to CLAUDE.md"
```

---

## Task 4: Create docs/INDEX.md — Task Router

**Files:**
- Create: `docs/INDEX.md`

- [ ] **Step 1: Create docs/INDEX.md**

Write `docs/INDEX.md`:

```markdown
# docs/INDEX.md — Entry Point for AI Agents

> Read this file FIRST when starting any task.
> It tells you which doc to open, where files live, and what rules apply.

---

## 1. Task Router

| Task | Document | What is inside |
|------|----------|----------------|
| Starting a new phase or feature | .ai/status.md | Current phase, progress %, next actions |
| Modifying VideoCompressor.ps1 | docs/ARCHITECTURE.md | Section map, encoding logic, UI layout |
| Adding a v2 feature | docs/superpowers/specs/2026-04-10-chucha-v2-design.md | Full v2 spec (drop zone, GPU, H.265, audio) |
| Implementing v2 tasks | docs/superpowers/plans/2026-04-10-chucha-v2-design.md | 15-task implementation plan |
| Fixing UI colors or fonts | docs/ui-ux-review.md | Brand corrections, scoring, priority actions |
| Adding GPU encoding | docs/shutter-encoder-analysis.md | GPU encoder map, FFmpeg flags, audio codecs |
| Comparing UI patterns | docs/shutter-encoder-ui-comparison.md | SE vs Chucha v1 vs v2 patterns |
| Looking for past lessons or gotchas | docs/LESSONS_LEARNED.md | Machine-navigable [tag] index |
| Planning a new feature | docs/superpowers/plans/ | Active plans with Status + checklist |
| Git workflow or commit format | docs/GIT_RULES.md | Conventional commits, branch strategy |
| Coding standards or patterns | docs/CODING_STANDARDS.md | PowerShell rules, naming, anti-patterns |
| Project phase progress and gates | docs/PROJECT_PHASES.md | Phase 0–3 with gate criteria |

---

## 2. DOCS_SYNC Quick Reference

After ANY code change — update the matching doc. Full table in CLAUDE.md.

| What changed | Update |
|-------------|--------|
| VideoCompressor.ps1 (UI) | docs/ARCHITECTURE.md |
| VideoCompressor.ps1 (encoding) | docs/ARCHITECTURE.md |
| chucha-compress.command | docs/ARCHITECTURE.md |
| compile.ps1 / build process | docs/ARCHITECTURE.md |

**Unenforced doc = bug.** Next AI agent reads stale info and writes wrong code.

---

## 3. Project Map

```
Chucha_Video_Compressor/
├── CLAUDE.md                 <- AI rules (single source of truth)
├── AGENTS.md                 <- Pointer to CLAUDE.md
├── README.md                 <- Human-readable overview
├── LICENSE                   <- MIT (Voogie / Cameraptor)
│
├── VideoCompressor.ps1       <- Main Windows app (849 lines, WinForms)
├── VideoCompressor.exe       <- Compiled EXE (via compile.ps1)
├── chucha-compress.command   <- macOS bash equivalent (365 lines)
├── compile.ps1               <- ps2exe build script
├── ps2exe.ps1                <- PS1→EXE compiler tool
├── compressor.ico            <- App icon
│
├── assets/                   <- Demo images (cover, demo.gif, screenshot)
│
├── docs/
│   ├── INDEX.md              <- YOU ARE HERE
│   ├── ARCHITECTURE.md       <- System structure, section map
│   ├── CODING_STANDARDS.md   <- PowerShell rules
│   ├── GIT_RULES.md          <- Conventional commits
│   ├── PROJECT_PHASES.md     <- Phase 0–3 with gates
│   ├── LESSONS_LEARNED.md    <- [tag] indexed lessons
│   ├── ui-ux-review.md       <- UI/UX design critique (existing)
│   ├── shutter-encoder-analysis.md      <- GPU reference (existing)
│   ├── shutter-encoder-ui-comparison.md <- UI patterns (existing)
│   └── superpowers/
│       ├── specs/            <- Design specifications
│       └── plans/            <- Active implementation plans
│
├── .ai/
│   ├── status.md             <- Current phase + progress %
│   ├── journal.md            <- Build log (milestones only)
│   ├── logs/                 <- Journal archives
│   ├── reports/              <- Long analysis (YYYY-MM-DD_NAME.md)
│   └── temp/                 <- Temporary files (DELETE after use)
│
├── .claude/
│   ├── skills/energize/      <- End-of-session finalization
│   └── agents/               <- Proof-loop subagents
│
└── .agent/tasks/             <- Proof-loop task artifacts
```

---

## 4. Source of Truth

When information conflicts:
1. Working docs (docs/*.md) — always reflect current reality
2. .ai/status.md — current phase and blockers
3. Journal archives — historical record only

If reality diverges from docs → update the doc.

---

**Last Updated:** 2026-04-10
```

- [ ] **Step 2: Commit**

```bash
git add docs/INDEX.md
git commit -m "docs: add INDEX.md — AI agent task router"
```

---

## Task 5: Create docs/PROJECT_PHASES.md

**Files:**
- Create: `docs/PROJECT_PHASES.md`

- [ ] **Step 1: Create PROJECT_PHASES.md**

Write `docs/PROJECT_PHASES.md`:

```markdown
# Project Phases — Chucha Video Compressor

> Each phase must WORK and be TESTED before the next starts. No jumping ahead.

---

## Phase Status

| Phase | Name | Status | Gate |
|-------|------|--------|------|
| 0 | Setup & Governance | [x] | CLAUDE.md + docs/ + .ai/ structure complete |
| 1 | v1 Complete (Current Release) | [x] | Folder → 2-pass x264 → target MB works end-to-end |
| 2 | v2 Core Features | [ ] | All 15 v2 tasks implemented, tested, compiled to EXE |
| 3 | Release & Hardening | [ ] | EXE tested on clean Windows, README updated, GitHub release |

---

## Phase 0 — Setup & Governance (COMPLETE)

**Goal:** Working dev environment + AI governance in place.

Steps:
- [x] Repository initialized with git
- [x] README.md with usage instructions
- [x] MIT License
- [x] .gitignore for build artifacts
- [x] CLAUDE.md governance (IDE_AUTO_SETUP v5.1)
- [x] docs/ structure with INDEX.md, PROJECT_PHASES.md
- [x] .ai/ workspace (status, journal, reports)

**Gate:** `powershell -File VideoCompressor.ps1` launches the app without errors.

---

## Phase 1 — v1 Complete (DONE)

**Goal:** Working batch video compressor with target file size.

Steps:
- [x] FFmpeg auto-detection and installation
- [x] WinForms dark-theme UI (480×686px)
- [x] Folder browser for input
- [x] Resolution, max size, format, output mode controls
- [x] 2-pass x264 encoding with calculated bitrate
- [x] Recursive folder scanning with structure preservation
- [x] Progress bar and status log
- [x] Pre-flight analysis (file count, warn if target too small)
- [x] ps2exe compilation to standalone EXE
- [x] macOS bash equivalent (chucha-compress.command)

**Gate:** User can select a folder → app compresses all videos → each output ≤ target MB.

---

## Phase 2 — v2 Core Features (NEXT)

**Goal:** All v2 enhancements from spec. GPU, H.265, drop zone, audio extraction, advanced panel.

**Full spec:** docs/superpowers/specs/2026-04-10-chucha-v2-design.md
**Implementation plan:** docs/superpowers/plans/2026-04-10-chucha-v2-design.md

Steps:
- [ ] Brand color correction (#1CA42C → #21C134, #585858 → #9a9590)
- [ ] Font embedding (Cormorant Garamond + Raleway via Base64)
- [ ] IFileOpenDialog COM interop (modern file picker)
- [ ] Drop zone panel UI
- [ ] File list + counter
- [ ] Drag-and-drop handling
- [ ] Browse files/folder buttons
- [ ] Audio extraction mode (MP3/AAC/WAV)
- [ ] Mode toggle visibility
- [ ] GPU detection (NVIDIA/AMD/Intel)
- [ ] GPU encoder selection UI
- [ ] GPU encoding branches in FFmpeg calls
- [ ] H.265 codec radio button
- [ ] libx265 two-pass flags
- [ ] Advanced panel collapse/expand

**Gate:** All 15 tasks pass. EXE compiled. User can drop files → choose GPU/codec/mode → compress or extract audio.

---

## Phase 3 — Release & Hardening

**Goal:** Production-ready v2 release on GitHub.

Steps:
- [ ] Test EXE on clean Windows 10/11 (no dev tools)
- [ ] Test with GPU-equipped and CPU-only machines
- [ ] Test edge cases: 0-byte files, no video stream, unsupported codecs
- [ ] Update README.md with v2 features and screenshots
- [ ] Update macOS script with v2 parity (where applicable)
- [ ] Create GitHub release with changelog
- [ ] Screenshot new UI for assets/

**Gate:** GitHub release published. README describes all v2 features. No known critical bugs.

---

**Last Updated:** 2026-04-10
```

- [ ] **Step 2: Commit**

```bash
git add docs/PROJECT_PHASES.md
git commit -m "docs: add PROJECT_PHASES.md — phases 0-3 with v2 roadmap"
```

---

## Task 6: Create docs/CODING_STANDARDS.md

**Files:**
- Create: `docs/CODING_STANDARDS.md`

- [ ] **Step 1: Create CODING_STANDARDS.md**

Write `docs/CODING_STANDARDS.md`:

```markdown
# Coding Standards — Chucha Video Compressor

> All agents must read this before writing code.

---

## File Organization

| Rule | Detail |
|------|--------|
| Max file size | VideoCompressor.ps1 may reach ~1800 lines for v2. Warn at 2000. |
| Section headers | Every logical section starts with `# --- SECTION NAME ---` comment block |
| Single file | All Windows app code stays in VideoCompressor.ps1 unless >2000 lines |
| macOS parity | chucha-compress.command mirrors core features but uses bash/osascript |

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Functions | PascalCase (Verb-Noun) | `Write-Log`, `Get-VideoFiles`, `Invoke-FFmpeg` |
| Variables | camelCase with `$` | `$maxSizeMB`, `$outputPath` |
| Script-scope vars | `$script:` prefix | `$script:ffmpegPath`, `$script:running` |
| UI controls | `$` + descriptive name | `$btnStart`, `$txtStatus`, `$lblHeader` |
| Constants | UPPER_SNAKE in comments, camelCase in code | `$defaultMaxSize = 8` |

---

## PowerShell-Specific Rules

### WinForms UI

- All UI construction in a single sequential block — define controls top to bottom
- Use `$lastY` accumulator pattern for vertical positioning (existing pattern)
- Colors defined as `[System.Drawing.Color]::FromArgb(R,G,B)` — no hex strings
- Font objects created once, reused across controls
- Event handlers use `$control.Add_Click({ ... })` pattern

### FFmpeg Calls

- Always use `& $script:ffmpegPath` (never bare `ffmpeg`)
- 2-pass encoding: pass 1 uses `-f null NUL`, pass 2 writes output
- Bitrate calculated as: `(targetMB * 0.92 * 8192) / duration - audioBitrate`
- Scale filter: `-vf "scale=if(gte(iw,ih),RES,-2):if(gte(iw,ih),-2,RES)"`

### Error Handling

- NEVER swallow exceptions silently — log via `Write-Log`
- User-facing errors: show in status TextBox, never raw stack traces
- FFmpeg errors: parse stderr for meaningful message, show to user
- File operations: always check `Test-Path` before reading

### Functions / Methods

- Max function length: ~80 lines (PowerShell functions tend to be longer than other languages)
- Helper functions defined BEFORE the UI construction block
- No global state except `$script:`-scoped variables

---

## Anti-Patterns

- NEVER use `Write-Host` in the app — it goes to console, not the GUI log
- NEVER hardcode file paths — use `$env:TEMP`, `$env:LOCALAPPDATA`, folder browser
- NEVER commit commented-out code — delete it (git history preserves it)
- NEVER add `Start-Sleep` in the UI thread — it freezes the form
- NEVER use `Invoke-Expression` — security risk and debugging nightmare

---

**Last Updated:** 2026-04-10
```

- [ ] **Step 2: Commit**

```bash
git add docs/CODING_STANDARDS.md
git commit -m "docs: add CODING_STANDARDS.md — PowerShell/WinForms rules"
```

---

## Task 7: Create docs/GIT_RULES.md

**Files:**
- Create: `docs/GIT_RULES.md`

- [ ] **Step 1: Create GIT_RULES.md**

Write `docs/GIT_RULES.md`:

```markdown
# Git Rules — Chucha Video Compressor

---

## Conventional Commits

Format: `type(scope): description`

| Type | Use for |
|------|---------|
| feat | New feature |
| fix | Bug fix |
| docs | Documentation only |
| refactor | Code change that neither fixes bug nor adds feature |
| chore | Build process, dependencies, tooling |
| perf | Performance improvement |

Examples:
```
feat(ui): add drop zone panel with drag-and-drop
fix(encode): correct bitrate calculation for H.265 codec
docs(readme): update v2 feature list and screenshots
chore: recompile EXE with ps2exe
```

Rules:
- Present tense: "add" not "added"
- No period at end
- Max 72 characters in subject line
- Body explains WHY (not WHAT) if needed

---

## Branch Strategy

| Branch | Purpose |
|--------|---------|
| main | Production-ready code |
| feat/short-name | Feature work (v2 tasks) |
| fix/short-name | Bug fixes |

Solo developer — no develop branch needed. Feature branches merge to main via squash.

---

## Commit Hygiene

- Atomic commits: one logical change per commit
- Code + docs in same commit (DOCS_SYNC rule)
- No binary files >1MB in git (VideoCompressor.exe is ~237KB, OK)
- No secrets in any commit

---

**Last Updated:** 2026-04-10
```

- [ ] **Step 2: Commit**

```bash
git add docs/GIT_RULES.md
git commit -m "docs: add GIT_RULES.md — conventional commits and branch strategy"
```

---

## Task 8: Create docs/LESSONS_LEARNED.md

**Files:**
- Create: `docs/LESSONS_LEARNED.md`

- [ ] **Step 1: Create LESSONS_LEARNED.md**

Write `docs/LESSONS_LEARNED.md`:

```markdown
# Lessons Learned

> Machine-navigable index. One line per lesson. [tag] for grep. Never delete — only append.
> Usage: grep '\[tag\]' docs/LESSONS_LEARNED.md

---

## How to Add a Lesson

Format: `[tag] description — root cause or correct approach`

Rules:
- One line per lesson
- Tag: lowercase, hyphenated
- Include root cause or correct approach, not just the symptom
- Never delete lessons — append only

---

## Setup

- [setup] AI governance initialized with IDE_AUTO_SETUP v5.1 — see CLAUDE.md for all rules

## Encoding

- [encode-budget] Target file size formula: totalBudget = maxSizeMB * 0.92 (8% overhead for container) — changing the 0.92 factor breaks file size accuracy
- [encode-2pass] Always use 2-pass for CPU encoding (x264/x265) — 1-pass CRF cannot guarantee target size
- [encode-gpu] GPU encoders (NVENC/AMF/QSV) are single-pass only — they don't support true 2-pass, use CBR/VBR instead
- [encode-scale] Scale filter must handle both landscape and portrait — use conditional: `if(gte(iw,ih),RES,-2):if(gte(iw,ih),-2,RES)`

## UI / WinForms

- [ui-winforms] WinForms on PowerShell requires explicit disposal — always call ShowDialog() not Show(), and handle cleanup
- [ui-positioning] Use $lastY accumulator for vertical layout — hardcoded pixel Y values break when inserting new controls above

## FFmpeg

- [ffmpeg-path] Never call bare `ffmpeg` — always use $script:ffmpegPath after auto-detection
- [ffmpeg-install] Auto-install from gyan.dev HTTPS mirror — check both PATH and common install locations first

## Build

- [build-ps2exe] ps2exe targets .NET Framework (not .NET Core) — test Add-Type C# blocks on PS 5.1 before compiling
```

- [ ] **Step 2: Commit**

```bash
git add docs/LESSONS_LEARNED.md
git commit -m "docs: add LESSONS_LEARNED.md — initial lessons from v1 development"
```

---

## Task 9: Create docs/ARCHITECTURE.md

**Files:**
- Create: `docs/ARCHITECTURE.md`

- [ ] **Step 1: Create ARCHITECTURE.md**

Write `docs/ARCHITECTURE.md`:

```markdown
DOCUMENT_TYPE: ARCHITECTURE
Project: Chucha Video Compressor
Last Updated: 2026-04-10
Status: ACTIVE

---

# Architecture Overview

> Update after any structural change. Stale architecture = wrong future code.

---

## System Overview

**What it does:** Batch-compresses videos to a precise target file size using 2-pass H.264 encoding via FFmpeg
**Primary user action:** Select folder → set target MB → click START → get compressed videos
**Architecture:** Single-file desktop application (no layers, no server, no database)

---

## Platform Variants

| Platform | File | Language | UI Framework | Lines |
|----------|------|----------|-------------|-------|
| Windows | `VideoCompressor.ps1` | PowerShell 5.1+ | WinForms (.NET Framework) | ~849 |
| Windows | `VideoCompressor.exe` | Compiled from PS1 | ps2exe | Binary |
| macOS | `chucha-compress.command` | Bash | osascript (native dialogs) | ~365 |

---

## VideoCompressor.ps1 — Section Map (v1)

| Lines | Section | Purpose |
|-------|---------|---------|
| 1–9 | Assembly loading | Load System.Windows.Forms, System.Drawing |
| 10–99 | FFmpeg detection | Check PATH, common dirs, auto-install prompt |
| 100–250 | FFmpeg download | Download from gyan.dev, extract, add to PATH |
| 250–330 | Helper functions | Write-Log, Get-VideoFiles, Invoke-FFmpeg |
| 331–338 | Color palette | Dark theme: bg #1E1E1E, accent #1CA42C (→ #21C134 in v2) |
| 341–348 | Font definitions | Segoe UI variants (→ Cormorant/Raleway in v2) |
| 353 | Form setup | Fixed 480×686px window |
| 356–375 | Header | "C H U C H A" + "VIDEO COMPRESSOR" labels |
| 394–532 | Settings controls | Resolution, Max Size, Format, Output Mode, Browse |
| 537–549 | START button | Green accent, triggers compression |
| 556 | Progress bar | Green accent bar |
| 563–582 | Status/log area | TextBox showing operation log |
| 588–595 | Copyright link | "cameraptor.com/voogie" LinkLabel |
| 603–830 | Event handlers | FFmpeg check, folder browse, START/STOP, progress |

---

## Encoding Pipeline

```
User selects folder
  → Get-VideoFiles scans recursively (mp4, avi, mov, mkv, wmv, flv, webm)
  → Pre-flight: count files, warn if target too small for any
  → For each video:
      → ffprobe: get duration, resolution, audio streams
      → Calculate video bitrate: (targetMB * 0.92 * 8192 / duration) - 96kbps
      → Pass 1: ffmpeg -i input -c:v libx264 -b:v Xk -preset slow -pass 1 -f null NUL
      → Pass 2: ffmpeg -i input -c:v libx264 -b:v Xk -preset slow -pass 2 -c:a aac -b:a 96k output
  → Output to subfolder or alongside originals
  → Cleanup: delete ffmpeg2pass* temp files
```

---

## Build Process

```
compile.ps1
  → Calls ps2exe with parameters:
     -inputFile VideoCompressor.ps1
     -outputFile VideoCompressor.exe
     -iconFile compressor.ico
     -title "Chucha Video Compressor"
     -company "CAMERAPTOR"
     -copyright "Voogie"
  → Produces standalone ~237KB EXE
```

---

## External Dependencies

| Dependency | Why | How managed |
|-----------|-----|-------------|
| FFmpeg | Core video encoding engine | Auto-detected in PATH; auto-installed from gyan.dev if missing |
| ffprobe | Video metadata extraction (duration, resolution) | Bundled with FFmpeg |
| .NET Framework | WinForms UI rendering | Built into Windows |
| ps2exe | PS1 → EXE compilation | Included as ps2exe.ps1 in repo |

---

## v2 Planned Changes

See full spec: `docs/superpowers/specs/2026-04-10-chucha-v2-design.md`

Major additions:
- Drop zone panel with file list (replaces folder-only input)
- GPU acceleration (NVENC, AMF, QSV) with auto-detection
- H.265 codec option (40% better compression)
- Audio extraction mode (MP3/AAC/WAV)
- Advanced collapsible panel
- Brand fonts (Cormorant Garamond, Raleway) via Base64 embedding
- Corrected brand colors

File grows from ~849 lines to ~1600–1800 lines.

---

**Last Updated:** 2026-04-10
```

- [ ] **Step 2: Commit**

```bash
git add docs/ARCHITECTURE.md
git commit -m "docs: add ARCHITECTURE.md — section map, encoding pipeline, build process"
```

---

## Task 10: Create .ai/ Workspace

**Files:**
- Create: `.ai/status.md`
- Create: `.ai/journal.md`
- Create: `.ai/reports/README.md`
- Create: `.ai/temp/.gitkeep`
- Create: `.ai/logs/.gitkeep`
- Create: `.ai/reports/archive/.gitkeep`

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p .ai/temp .ai/logs .ai/reports/archive
```

- [ ] **Step 2: Create .ai/status.md**

Write `.ai/status.md`:

```markdown
# Project Status — Chucha Video Compressor

> MAX 100 lines. Update when progress changes >10% or phase changes.

---

## Current State

| Field | Value |
|-------|-------|
| Phase | 2 — v2 Core Features |
| Progress | 0% |
| Status | Ready to Start |
| Last Updated | 2026-04-10 |
| Next Milestone | Task 1: Brand color correction |

---

## Blockers

None.

---

## Phase Progress

### Phase 0 — Setup & Governance (COMPLETE)
Repository, governance, docs structure all in place.

### Phase 1 — v1 Complete (COMPLETE)
Working batch compressor with target file size. 849-line PS1 + 365-line bash.

### Phase 2 — v2 Core Features (Current)
- [ ] Brand color correction
- [ ] Font embedding (Cormorant + Raleway)
- [ ] IFileOpenDialog COM interop
- [ ] Drop zone panel UI
- [ ] File list + counter
- [ ] Drag-and-drop handling
- [ ] Browse files/folder buttons
- [ ] Audio extraction mode
- [ ] Mode toggle visibility
- [ ] GPU detection
- [ ] GPU encoder selection UI
- [ ] GPU encoding branches
- [ ] H.265 codec radio
- [ ] libx265 two-pass flags
- [ ] Advanced panel collapse/expand

### Phase 3 — Release & Hardening
- [ ] Clean Windows testing
- [ ] README update
- [ ] GitHub release

---

## Recent Decisions

- 2026-04-10: AI governance initialized with IDE_AUTO_SETUP v5.1
- 2026-04-10: v2 spec and implementation plan finalized (15 tasks)
```

- [ ] **Step 3: Create .ai/journal.md**

Write `.ai/journal.md`:

```markdown
# Build Journal — Chucha Video Compressor

> MAX 150 lines. When exceeded: run compaction procedure.

---

## Phase 0: Setup (2026-04-10)

Actions:
- Initialized AI governance with IDE_AUTO_SETUP v5.1 Level 2 Pro
- Created CLAUDE.md, AGENTS.md, docs/ structure, .ai/ workspace
- Created energize skill and proof-loop subagents

Files:
- CLAUDE.md, AGENTS.md
- docs/INDEX.md, PROJECT_PHASES.md, CODING_STANDARDS.md, GIT_RULES.md
- docs/LESSONS_LEARNED.md, ARCHITECTURE.md
- .ai/status.md, journal.md, reports/README.md
- .claude/skills/energize/, .claude/agents/

Lessons:
- [setup] AI governance with IDE_AUTO_SETUP v5.1 prevents common agent anti-patterns
```

- [ ] **Step 4: Create .ai/reports/README.md**

Write `.ai/reports/README.md`:

```markdown
# Reports Index

> Long analysis reports (>100 lines). Max 3 active at once (context budget).
> Naming: YYYY-MM-DD_DESCRIPTIVE_NAME.md

---

## Current Reports

<!-- No active reports yet -->

---

## Archived Reports

<!-- None yet -->

---

**Last Updated:** 2026-04-10
```

- [ ] **Step 5: Create .gitkeep files**

Create empty files:
- `.ai/temp/.gitkeep`
- `.ai/logs/.gitkeep`
- `.ai/reports/archive/.gitkeep`

- [ ] **Step 6: Commit**

```bash
git add .ai/
git commit -m "chore: add .ai/ workspace — status, journal, reports"
```

---

## Task 11: Create Energize Skill

**Files:**
- Create: `.claude/skills/energize/SKILL.md`
- Create: `.claude/skills/energize/energize.md`
- Create: `.claude/skills/energize/README.md`

Source templates: `d:/Work/Obsidian/Voogie/60 Knowledge/Tools/IDE_AUTO_SETUP/templates/skills/energize/`

- [ ] **Step 1: Create directory**

```bash
mkdir -p .claude/skills/energize
```

- [ ] **Step 2: Create SKILL.md**

Write `.claude/skills/energize/SKILL.md`:

```markdown
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
```

- [ ] **Step 3: Copy energize.md from template**

Copy the full energize protocol from the template at:
`d:/Work/Obsidian/Voogie/60 Knowledge/Tools/IDE_AUTO_SETUP/templates/skills/energize/energize.md`

Write it to `.claude/skills/energize/energize.md` — use the exact template content (184 lines, already read above).

- [ ] **Step 4: Create README.md**

Write `.claude/skills/energize/README.md`:

```markdown
# Energize Skill — README

## What It Does

End-of-session finalization for Chucha Video Compressor. Automates:
- Docs sync verification (DOCS_SYNC table)
- Journal and status updates
- SESSION_END_CHECKLIST
- Git commit

## How to Invoke

Say: "energize" (Claude Code reads SKILL.md and loads energize.md)

## Customization

This project has NO server deploy — Steps 3.5, 4, 7 are auto-skipped.
All project-specific values are in CLAUDE.md (not hardcoded here).
```

- [ ] **Step 5: Commit**

```bash
git add .claude/skills/energize/
git commit -m "feat: add energize skill — 8-step session finalization"
```

---

## Task 12: Install Proof-Loop Subagents

**Files:**
- Create: `.claude/agents/task-spec-freezer.md`
- Create: `.claude/agents/task-builder.md`
- Create: `.claude/agents/task-verifier.md`
- Create: `.claude/agents/task-fixer.md`
- Create: `.agent/tasks/.gitkeep`

Source templates: `d:/Work/Obsidian/Voogie/60 Knowledge/Tools/IDE_AUTO_SETUP/templates/proof-loop-setup.sh` (or copy from the IDE_AUTO_SETUP `.claude/agents/` directory)

Source path for agent files: `d:/Work/Obsidian/Voogie/60 Knowledge/Tools/IDE_AUTO_SETUP/.claude/agents/`

- [ ] **Step 1: Create directories**

```bash
mkdir -p .claude/agents .agent/tasks
```

- [ ] **Step 2: Copy all 4 proof-loop agent files**

Copy these files from the IDE_AUTO_SETUP knowledge base:
- `d:/Work/Obsidian/Voogie/60 Knowledge/Tools/IDE_AUTO_SETUP/.claude/agents/task-spec-freezer.md` → `.claude/agents/task-spec-freezer.md`
- `d:/Work/Obsidian/Voogie/60 Knowledge/Tools/IDE_AUTO_SETUP/.claude/agents/task-builder.md` → `.claude/agents/task-builder.md`
- `d:/Work/Obsidian/Voogie/60 Knowledge/Tools/IDE_AUTO_SETUP/.claude/agents/task-verifier.md` → `.claude/agents/task-verifier.md`
- `d:/Work/Obsidian/Voogie/60 Knowledge/Tools/IDE_AUTO_SETUP/.claude/agents/task-fixer.md` → `.claude/agents/task-fixer.md`

Read each source file in full and write the exact content to the destination.

- [ ] **Step 3: Create .agent/tasks/.gitkeep**

Create empty `.agent/tasks/.gitkeep`.

- [ ] **Step 4: Commit**

```bash
git add .claude/agents/ .agent/tasks/.gitkeep
git commit -m "feat: install proof-loop subagents — spec freezer, builder, verifier, fixer"
```

---

## Task 13: Final Verification

- [ ] **Step 1: Verify all files exist**

Run:
```bash
ls -la CLAUDE.md AGENTS.md
ls -la docs/INDEX.md docs/PROJECT_PHASES.md docs/CODING_STANDARDS.md docs/GIT_RULES.md docs/LESSONS_LEARNED.md docs/ARCHITECTURE.md
ls -la .ai/status.md .ai/journal.md .ai/reports/README.md
ls -la .ai/temp/.gitkeep .ai/logs/.gitkeep .ai/reports/archive/.gitkeep
ls -la .claude/skills/energize/SKILL.md .claude/skills/energize/energize.md .claude/skills/energize/README.md
ls -la .claude/agents/task-spec-freezer.md .claude/agents/task-builder.md .claude/agents/task-verifier.md .claude/agents/task-fixer.md
ls -la .agent/tasks/.gitkeep
```

Expected: all 23 files exist, no errors.

- [ ] **Step 2: Verify no placeholders remain**

Run:
```bash
grep -r '{{' CLAUDE.md AGENTS.md docs/INDEX.md docs/PROJECT_PHASES.md docs/CODING_STANDARDS.md docs/GIT_RULES.md docs/LESSONS_LEARNED.md docs/ARCHITECTURE.md .ai/status.md .ai/journal.md
```

Expected: zero matches (all `{{PLACEHOLDER}}` values have been replaced with real values).

- [ ] **Step 3: Verify CLAUDE.md line count**

Run: `wc -l CLAUDE.md`

Expected: under 450 lines.

- [ ] **Step 4: Verify .gitignore has governance entries**

Run: `grep "ai/temp" .gitignore`

Expected: `.ai/temp/*` line exists.

- [ ] **Step 5: Run git status to confirm clean state**

Run: `git status`

Expected: clean working tree (all files committed).

- [ ] **Step 6: Mark Phase 0 complete in status.md if all checks pass**

Update `.ai/status.md`: Phase 0 → COMPLETE, status → "Phase 2 ready to start".

- [ ] **Step 7: Final commit**

```bash
git add -A
git commit -m "chore: complete IDE_AUTO_SETUP v5.1 — all verification checks pass"
```
