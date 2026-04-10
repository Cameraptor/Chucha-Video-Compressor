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

---

## Phase 2: v2 Core Features — Session 1 (2026-04-10)

Actions:
- Implemented WebM/VP9 output format (libvpx-vp9 + libopus audio, proper 2-pass flags)
- Added GPU acceleration UI and logic (NVENC/AMF/QSV auto-detect + manual override)
- H.264/H.265 codec chip selector; libx265 2-pass with x265-params
- Resolution combobox extended to 4K (3840)
- Scale algorithm selector (bicubic/lanczos/bilinear)
- Audio extraction mode (MP3/AAC/WAV)
- Brand fonts: Cormorant Garamond SemiBold + Raleway Regular via Base64 TTF embedding
- Corrected brand colors (#21C134, #9A9590); DWM dark titlebar
- DarkComboBox subclass for proper dark dropdown rendering
- Logo overlay with color-matrix tint to #21C134
- Drop zone + file list + browse buttons

Files:
- VideoCompressor.ps1 (+334/-145 lines, now ~2040 lines)

Lessons:
- [webm] libvpx-vp9 has no GPU hw-enc path — always CPU for WebM
- [webm] WebM container needs -quality/-cpu-used instead of -preset; no -movflags
- [fonts] WOFF2 breaks PrivateFontCollection — TTF/OTF only
- [dwm] DwmSetWindowAttribute attr 20 for Win10 20H1+, fallback attr 19
- [brand] Never use #1CA42C — correct is #21C134; never use synthetic Bold on embedded fonts
