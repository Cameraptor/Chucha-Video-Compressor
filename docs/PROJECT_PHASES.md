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
- [x] WinForms dark-theme UI (480x686px)
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
