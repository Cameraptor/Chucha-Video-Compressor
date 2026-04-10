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
