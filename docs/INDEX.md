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
| Project phase progress and gates | docs/PROJECT_PHASES.md | Phase 0-3 with gate criteria |

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
│   ├── PROJECT_PHASES.md     <- Phase 0-3 with gates
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
