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
| Windows | `VideoCompressor.ps1` | PowerShell 5.1+ | WinForms (.NET Framework) | ~2040 |
| Windows | `VideoCompressor.exe` | Compiled from PS1 | ps2exe | Binary |
| macOS | `chucha-compress.command` | Bash | osascript (native dialogs) | ~365 |

---

## VideoCompressor.ps1 — Section Map (v2, current)

| Lines | Section | Purpose |
|-------|---------|---------|
| 1-9 | Assembly loading | Load System.Windows.Forms, System.Drawing |
| 10-99 | FFmpeg detection | Check PATH, common dirs, auto-install prompt |
| 100-210 | FFmpeg download + ModernPicker | Download from gyan.dev; IFileOpenDialog COM interop |
| 210-250 | Helper functions | Show-FolderPicker, Show-FilePicker, Write-Log, Get-VideoFiles, Invoke-FFmpeg |
| 250-330 | Font embedding | Base64 TTF → Cormorant Garamond (SemiBold) + Raleway (Regular) via PrivateFontCollection |
| 330-500 | GPU detection + Compress-Video | Resolve-GpuMode (NVENC/AMF/QSV/CPU auto-detect); 2-pass CPU + single-pass GPU encoding; WebM/VP9 path |
| 500-540 | Audio extraction | Extract-Audio function; MP3/AAC/WAV output |
| 540-720 | Color palette + fonts | Brand colors (#21C134 green, #101010 bg, #F2E2E2 text, #9A9590 warm gray); Cormorant + Raleway fonts |
| 720-760 | DWM + form init | DarkTitle C# block; DWM dark titlebar (attr 20/19); form 480×900px |
| 760-850 | Logo rendering | Embedded glyph bitmap → color-matrix tint to #21C134; LogoPanel click-through overlay |
| 850-950 | DarkComboBox | WM_PAINT subclass for fully dark dropdown button + items |
| 950-1100 | Drop zone + file list | DragDrop panel, file counter, ListView with remove buttons |
| 1100-1400 | Settings controls | Resolution (480→3840), Max Size, Format chips (MP4/MOV/WebM), Codec chips (H.264/H.265), GPU selector, Scale algo, Output mode, Thread count |
| 1400-1500 | Audio mode panel | Mode toggle (Video/Audio), audio format selector (MP3/AAC/WAV) |
| 1500-1600 | Advanced panel | Collapsible: scale algorithm, thread count |
| 1600-1800 | START/STOP + progress | Green START button, progress bar, status log TextBox, cancel logic |
| 1800-2040 | Event handlers | FFmpeg check, browse, drag-drop, START/STOP, per-file progress updates |

---

## Encoding Pipeline

```
User adds files (drag-drop, Browse Files, or Browse Folder)
  → Drop zone accepts any mix of files and folders
  → Get-VideoFiles scans recursively (mp4, avi, mov, mkv, wmv, flv, webm, mxf, m4v)
  → Pre-flight: count files, warn if target too small for any

  Video compression mode:
    → ffprobe: get duration, resolution, audio streams
    → Calculate video bitrate: (targetMB * 0.92 * 8192 / duration) - 96kbps
    → GPU path (NVENC/AMF/QSV):
        single-pass constrained VBR with selected hardware encoder
        H.264: h264_nvenc / h264_amf / h264_qsv
        H.265: hevc_nvenc / hevc_amf / hevc_qsv
    → CPU path — 2-pass:
        H.264:  libx264 -preset slow, -x264-params mbtree=0
        H.265:  libx265 via x265-params pass=1/pass=2
        WebM:   libvpx-vp9 -quality good -cpu-used 2, audio: libopus
      → Output: MP4 / MOV / WebM per user selection
  
  Audio extraction mode:
    → ffmpeg extracts audio only → MP3 / AAC / WAV
  
  → Output to subfolder or alongside originals (per Output Mode setting)
  → Cleanup: delete ffmpeg2pass* temp files from %TEMP%
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

## v2 Features — Implemented

- **Drop zone + file list** — drag-and-drop files/folders; browse buttons for files and folder; file counter
- **WebM output** — VP9 encoder (libvpx-vp9) + Opus audio (libopus); proper 2-pass flags, no -movflags
- **GPU acceleration** — NVENC (NVIDIA), AMF (AMD), QSV (Intel) auto-detect; manual override UI
- **H.265 / H.264 codec toggle** — chip selector; H.265 via libx265 with x265-params pass handling
- **Resolution up to 4K** — combobox: 480, 720, 1080, 1280, 1920, 2560, 3840
- **Scale algorithm** — bicubic / lanczos / bilinear selector
- **Audio extraction mode** — mode toggle (Video / Audio); MP3/AAC/WAV output
- **Advanced collapsible panel** — thread count + scale algo grouped
- **Brand fonts** — Cormorant Garamond SemiBold + Raleway Regular via Base64 TTF → PrivateFontCollection
- **Brand colors corrected** — #21C134 Raptor Green, #9A9590 warm gray, DWM dark titlebar
- **DarkComboBox** — WM_PAINT subclass; fully dark dropdown arrow + items
- **Logo overlay** — color-matrix tint glyph to #21C134; click-through LogoPanel
- **DWM dark titlebar** — DWMWA_USE_IMMERSIVE_DARK_MODE (attr 20, fallback attr 19)
- **passlogfile in %TEMP%** — no CWD dependency; GUID-based unique filenames

---

**Last Updated:** 2026-04-10
