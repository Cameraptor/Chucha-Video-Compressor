# 🐱 Chucha Video Compressor

[![GitHub](https://img.shields.io/badge/GitHub-Cameraptor-blue?logo=github)](https://github.com/Cameraptor/Chucha-Video-Compressor)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows)](https://github.com/Cameraptor/Chucha-Video-Compressor/releases)
[![Telegram](https://img.shields.io/badge/Telegram-Join%20Community-2CA5E0?logo=telegram)](https://t.me/voogieboogie)

<div align="center">
  <img src="assets/cover.png" alt="Chucha Video Compressor" width="256">
</div>

> **The fastest way to batch-compress videos to a target file size — no professional software needed. Just double-click and go.**

Standalone `.exe` tool for Windows that compresses any number of video files to a precise size limit using 2-pass H.264 encoding. Produces significantly better visual quality at low bitrates than Adobe Media Encoder.

**Author:** Voogie | **Project:** Cameraptor | [cameraptor.com/voogie](https://cameraptor.com/voogie)

---

<div align="center">
  <img src="assets/screenshot.jpg" alt="Chucha Video Compressor UI" width="420">
</div>

---

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| 🎯 **Target File Size** | Set exact MB limit — the tool calculates optimal bitrate automatically |
| 📦 **Batch Processing** | Drop an entire folder — all videos compressed in one click |
| 🎬 **2-Pass H.264** | Two-pass encoding with `preset slow` for maximum quality per byte |
| 🆚 **Beats Adobe AME** | Smarter bitrate allocation produces noticeably better quality at small sizes |
| 📐 **Resolution Control** | Set max long-side resolution (e.g. 1270 px) to further reduce file size |
| 🔧 **Zero Setup** | Single `.exe`, auto-installs FFmpeg via winget if missing |
| 🛡️ **Safe Processing** | Originals are never touched — output goes to a `Compressed/` subfolder |
| ⏹️ **STOP Button** | Cancel at any time without corrupting files |

---

## 🆚 Why Not Adobe Media Encoder?

Adobe Media Encoder uses single-pass CBR encoding when targeting small file sizes. This means it guesses the bitrate upfront and often produces visible artifacts — banding, blocking, and blurring.

**Chucha uses 2-pass VBR encoding:** the first pass analyzes the entire video, the second pass distributes bits intelligently. Complex scenes get more bitrate, simple scenes get less. The result is dramatically better visual quality at the same file size.

| | Adobe Media Encoder | Chucha Video Compressor |
|---|---|---|
| Encoding | Single-pass CBR | 2-pass VBR |
| Quality at 1.5 MB | Visible artifacts | Clean and watchable |
| Batch processing | Manual queue | One-click folder scan |
| Setup | Creative Cloud subscription | Free, single `.exe` |
| Speed | Faster | Slower (quality tradeoff) |

---

## 📦 Download & Install

### Quick Start (Recommended)

1. Download **`VideoCompressor.exe`** from [Releases](https://github.com/Cameraptor/Chucha-Video-Compressor/releases)
2. Place it anywhere on your PC
3. Double-click to launch

> 💡 **FFmpeg:** The tool will auto-detect FFmpeg on your system. If not found, it will install it via `winget` automatically.

### Manual FFmpeg Setup (Optional)

If auto-install doesn't work, install FFmpeg manually:

```
winget install Gyan.FFmpeg
```

Or download from [ffmpeg.org](https://ffmpeg.org/download.html) and add to PATH.

---

## 🕹️ Usage Guide

1. **Set resolution** — max long side in pixels (default: 1270)
2. **Set max size** — target file size in MB (default: 1.5)
3. **Choose format** — MP4 or MOV
4. **Choose output mode:**
   - `Compressed/` subfolder (preserves folder structure)
   - Alongside original with `_compressed` suffix
5. **Browse** for a source folder
6. Click **START**

> 💡 **Pre-flight check:** Before compressing, the tool analyzes all files. If any video physically can't fit within your size limit (e.g. a 2-minute video at 1.5 MB), you'll get a warning with the minimum achievable size.

> ⏹️ **Stopping:** Click STOP to cancel. The window won't close during processing — use STOP first.

---

## 📋 Parameters Reference

| Parameter | Default | Description |
|-----------|---------|-------------|
| **Resolution** | 1270 px | Maximum long-side dimension. Videos smaller than this won't be upscaled. |
| **Max Size** | 1.5 MB | Target file size. The encoder hits this as closely as possible. |
| **Format** | MP4 | Output container — MP4 (H.264 + AAC) or MOV (H.264 + AAC). |
| **Output Mode** | Subfolder | `Compressed/` subfolder preserves the original directory tree. |

### How Bitrate Is Calculated

```
total_budget  = max_size * 0.92          (8% container overhead)
audio_budget  = 96 kbps * duration
video_budget  = total_budget - audio_budget
video_bitrate = video_budget / duration   (min 80 kbps)
```

---

## 🛠️ Building from Source

The tool is a PowerShell WinForms application compiled to `.exe` via PS2EXE.

### Prerequisites

- Windows 10/11 with PowerShell 5.1+
- FFmpeg installed and in PATH

### Compile

```powershell
. .\ps2exe.ps1
Invoke-ps2exe .\VideoCompressor.ps1 .\VideoCompressor.exe `
    -noConsole -iconFile .\compressor.ico `
    -title 'Chucha Video Compressor' `
    -company 'CAMERAPTOR' `
    -copyright 'Voogie / cameraptor.com'
```

Or simply run:

```powershell
.\compile.ps1
```

### Source Structure

| File | Description |
|------|-------------|
| `VideoCompressor.ps1` | Main application — WinForms GUI + FFmpeg logic |
| `ps2exe.ps1` | PS2EXE compiler (converts PS1 to standalone EXE) |
| `compile.ps1` | One-click build script |
| `compressor.ico` | Application icon (16/32/48/256 px) |

---

## 🛡️ Technical Notes

- **No pipes:** FFmpeg runs without stdout/stderr redirection to avoid deadlocks in the PS2EXE runtime. Progress is tracked via `-progress <tempfile>`.
- **mbtree disabled:** x264's MB-tree feature is turned off (`mbtree=0`) to prevent incomplete stats files that corrupt output on certain clips.
- **Explicit passlogfile:** 2-pass log files use explicit temp paths instead of relying on the working directory, avoiding CWD mismatches between PowerShell and Win32.
- **Audio budget:** Audio is encoded at 96 kbps AAC. The bitrate calculator subtracts audio from the total budget before computing video bitrate.

---

## 🔧 Troubleshooting

| Issue | Solution |
|-------|----------|
| FFmpeg not found | Install via `winget install Gyan.FFmpeg` or place `ffmpeg.exe` next to the app |
| UAC prompt on launch | Re-download the EXE — it should not require admin privileges |
| Output larger than target | Expected for very long videos at small size limits — pre-flight warning will explain |
| App won't close | Click STOP first to cancel processing, then close normally |
| Antivirus flags EXE | PS2EXE-compiled scripts are sometimes flagged as false positives. Add an exception or run the `.ps1` directly. |

---

## 🤝 Support & Community

- **💬 Telegram:** [Join @voogieboogie](https://t.me/voogieboogie) — questions, feedback, feature requests
- **🐛 Issues:** [GitHub Issues](https://github.com/Cameraptor/Chucha-Video-Compressor/issues)
- **🌐 Website:** [cameraptor.com/voogie](https://cameraptor.com/voogie)

---

## 📄 License

MIT License — See [LICENSE](LICENSE) file for details.

---

<div align="center">

**Made with ❤️ by Voogie | Cameraptor**

[![Telegram](https://img.shields.io/badge/💬_Join_Telegram_Community-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/voogieboogie)

⭐ Star this repo if you find it useful!

</div>
