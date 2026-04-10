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
| 1-9 | Assembly loading | Load System.Windows.Forms, System.Drawing |
| 10-99 | FFmpeg detection | Check PATH, common dirs, auto-install prompt |
| 100-250 | FFmpeg download | Download from gyan.dev, extract, add to PATH |
| 250-330 | Helper functions | Write-Log, Get-VideoFiles, Invoke-FFmpeg |
| 331-338 | Color palette | Dark theme: bg `#101010`, accent `#1CA42C` (→ `#21C134` in v2), muted `#585858` (→ `#9a9590` in v2) |
| 341-348 | Font definitions | Segoe UI variants (→ Cormorant Garamond + Raleway via TTF embedding in v2) |
| 353 | Form setup | Fixed 480x686px window |
| 356-375 | Header | "C H U C H A" + "VIDEO COMPRESSOR" labels |
| 394-532 | Settings controls | Resolution, Max Size, Format, Output Mode, Browse |
| 537-549 | START button | Green accent, triggers compression |
| 556 | Progress bar | Green accent bar |
| 563-582 | Status/log area | TextBox showing operation log |
| 588-595 | Copyright link | "cameraptor.com/voogie" LinkLabel |
| 603-830 | Event handlers | FFmpeg check, folder browse, START/STOP, progress |

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

File grows from ~849 lines to ~1600-1800 lines.

---

**Last Updated:** 2026-04-10
