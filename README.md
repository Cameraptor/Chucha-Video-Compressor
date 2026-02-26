# 🐱 Chucha Video Compressor

[![GitHub](https://img.shields.io/badge/GitHub-Cameraptor-blue?logo=github)](https://github.com/Cameraptor/Chucha-Video-Compressor)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows)](https://github.com/Cameraptor/Chucha-Video-Compressor/releases)
[![macOS](https://img.shields.io/badge/macOS-Intel%20%26%20Apple%20Silicon-000000?logo=apple)](https://github.com/Cameraptor/Chucha-Video-Compressor/releases)
[![Free](https://img.shields.io/badge/Price-Free-brightgreen)]()
[![Telegram](https://img.shields.io/badge/Telegram-Join%20Community-2CA5E0?logo=telegram)](https://t.me/voogieboogie)

<div align="center">
  <table><tr>
    <td width="50%"><img src="assets/demo.gif" alt="Chucha Video Compressor" width="100%"></td>
    <td width="50%"><img src="assets/screenshot.jpg" alt="Chucha Video Compressor UI" width="100%"></td>
  </tr></table>
</div>

> **The fastest way to batch-compress videos to a target file size — no professional software needed. Just double-click and go.**

Free, portable, single-file tool for **Windows** (`.exe`) and **macOS** (`.command`). Compresses any number of video files to a precise size limit using 2-pass H.264 encoding via x264 — the same encoder used by Netflix, YouTube, and professional studios. Produces significantly better visual quality at low bitrates compared to Adobe Media Encoder.

Point it at any folder — even with dozens of subfolders and mixed file types — and it will find every video, compress it to your target size, and mirror the entire folder structure in the output. No manual file picking, no drag-and-drop queues. One folder, one click, all done.

**Download → double-click → select folder → done.** That's it. No installation, no accounts, no subscriptions.

> 🍎 **macOS version available** — same compression engine, same quality, same one-click workflow. The Mac version runs in Terminal with native macOS dialogs instead of a graphical window. The encoding core is identical — the only difference is the interface.
>
> *Why no GUI on Mac? Building a native macOS app requires Xcode, Apple Developer signing ($99/year), and notarization — turning a 20 KB script into a 10 MB bundle with distribution hurdles. A `.command` file keeps the same philosophy: one file, double-click, done.*

**Author:** Voogie | **Project:** Cameraptor | [cameraptor.com/voogie](https://cameraptor.com/voogie)

---

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| 🎯 **Target File Size** | Set exact MB limit — the tool calculates optimal bitrate automatically |
| 📦 **Batch + Subfolders** | Point to any folder — automatically discovers all videos in all subfolders, preserves directory structure in output |
| 🎬 **2-Pass x264** | Two-pass encoding with `preset slow` for maximum quality per byte |
| 🆚 **Better Than AME** | x264 encoder is ~20% more efficient than Adobe's MainConcept at low bitrates |
| 📐 **Resolution Control** | Set max long-side resolution (e.g. 1270 px) to further reduce file size |
| 💰 **100% Free** | No subscriptions, no accounts, no trials. MIT license, open source. |
| 📁 **Single File** | One file per platform. No installation. Just download and run. Auto-installs FFmpeg if missing. |
| 🍎 **Windows + macOS** | Native versions for both platforms — `.exe` for Windows, `.command` for Mac |
| 🛡️ **Safe Processing** | Originals are never touched — output goes to a `Compressed/` subfolder |
| ⏹️ **STOP Button** | Cancel at any time without corrupting files |
| 🔍 **Pre-flight Analyzer** | Warns you before encoding if a file can't physically fit in your size limit |

---

## 🆚 Why Not Adobe Media Encoder?

Adobe Media Encoder defaults to **VBR 1 Pass** encoding with its built-in **MainConcept** H.264 encoder. While it does support 2-pass mode, there are significant real-world problems:

- **2-pass requires software encoding** — disables GPU acceleration, making it very slow
- **2-pass is buggy** — [documented cases](https://community.adobe.com/t5/adobe-media-encoder-discussions/media-encoder-only-does-1-pass-with-vbr-2-pass-settings-software-encoding/td-p/14743829) where AME silently performs only 1 pass even when 2-pass is selected
- **Target file size is unreliable** — users [report setting 4 MB limits and getting 36 MB files](https://community.adobe.com/t5/adobe-media-encoder-discussions/max-file-size-does-nothing/m-p/15178705)
- **Metadata bloat** — Content Credentials and metadata can inflate small files unexpectedly
- **Can't go below ~5 MB** — users [report being unable to get H.264 files smaller than 5 MB](https://creativecow.net/forums/thread/cant-get-h264-files-smaller-than-5mb-out-of-media/) even at very low bitrates
- **MainConcept vs x264** — independent testing shows [x264 is ~20% more efficient](https://www.streamingmedia.com/Articles/ReadArticle.aspx?ArticleID=147394) at equivalent quality

**Chucha uses 2-pass VBR encoding with x264:** the first pass analyzes the entire video, the second pass distributes bits intelligently. Complex scenes get more bitrate, simple scenes get less. At low bitrates (1–3 MB target), the quality difference is clearly visible.

| | Adobe Media Encoder | Chucha Video Compressor |
|---|---|---|
| **Encoder** | MainConcept (less efficient) | x264 (industry standard) |
| **2-Pass** | Buggy, disables GPU, sometimes silently falls back to 1-pass | Always works, reliable |
| **Target file size** | Unreliable — often overshoots by 5–10x | Precise — hits target consistently |
| **Min achievable size** | ~5 MB floor | No floor — goes as low as needed |
| **Batch processing** | Manual queue, one file at a time | One-click folder scan with subfolders |
| **Setup** | Creative Cloud subscription ($55/month) | Free. Single file. No install. Windows + macOS. |
| **Encoding speed** | 2-pass is ~4x slower than ffmpeg | Fast 2-pass via optimized x264 |

---

## 📦 Download

> **You only need one file. That's it.**

### Windows

1. Download **`VideoCompressor.exe`** from [Releases](https://github.com/Cameraptor/Chucha-Video-Compressor/releases)
2. Put it anywhere on your PC
3. Double-click to launch

> 💡 **FFmpeg:** Auto-detects FFmpeg on your system. If not found, installs it automatically via `winget`.

### macOS

1. Download **`chucha-compress.command`** from [Releases](https://github.com/Cameraptor/Chucha-Video-Compressor/releases)
2. Put it anywhere on your Mac
3. Double-click to launch in Terminal
4. If macOS blocks it: right-click → Open, or run `chmod +x chucha-compress.command`

> 💡 **FFmpeg:** Auto-detects FFmpeg. If not found, installs it via [Homebrew](https://brew.sh). Settings are configured through native macOS dialogs; progress is shown in Terminal.

No installation. No dependencies to manage. No accounts.

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

The tool automatically discovers all video files in the selected folder **and all subfolders** — no need to select files one by one. Directory structure is preserved in the output.

> 💡 **Pre-flight check:** Before compressing, the tool analyzes every file. If any video physically can't fit within your size limit (e.g. a 2-minute video at 1.5 MB), you'll get a warning showing the minimum achievable size for each file.

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

### Windows

The Windows version is a PowerShell WinForms application compiled to `.exe` via PS2EXE.

**Prerequisites:** Windows 10/11 with PowerShell 5.1+, FFmpeg in PATH.

```powershell
.\compile.ps1
```

### macOS

The Mac version is a standalone bash script — no compilation needed. Just make it executable:

```bash
chmod +x chucha-compress.command
```

### Source Structure

| File | Platform | Description |
|------|----------|-------------|
| `VideoCompressor.ps1` | Windows | Main application — WinForms GUI + FFmpeg logic |
| `chucha-compress.command` | macOS | Terminal app — osascript dialogs + FFmpeg logic |
| `ps2exe.ps1` | Windows | PS2EXE compiler (converts PS1 to standalone EXE) |
| `compile.ps1` | Windows | One-click build script |
| `compressor.ico` | Windows | Application icon (16/32/48/256 px) |

---

## 🛡️ Technical Notes

- **x264 encoder** — the most efficient H.264 encoder available, used by Netflix, YouTube, and Handbrake. Consistently outperforms MainConcept (Adobe) and QuickSync (Intel) at low bitrates.
- **mbtree disabled:** x264's MB-tree feature is turned off (`mbtree=0`) to prevent incomplete stats files that corrupt output on certain clips.
- **Explicit passlogfile:** 2-pass log files use explicit temp paths instead of relying on the working directory.
- **Audio budget:** Audio is encoded at 96 kbps AAC. The bitrate calculator subtracts audio from the total budget before computing video bitrate.
- **Windows:** FFmpeg runs without stdout/stderr redirection to avoid pipe deadlocks in the PS2EXE runtime. Progress is tracked via `-progress <tempfile>`.
- **macOS:** Settings via native `osascript` dialogs (folder picker, text input). Progress parsed from ffmpeg stderr in real time. Sends macOS notification on completion.

---

## 💻 System Requirements

| | Windows | macOS |
|---|---|---|
| **OS** | Windows 10 / 11 (x64) | macOS 10.15+ (Intel & Apple Silicon) |
| **RAM** | 4 GB | 4 GB |
| **Disk** | ~200 KB for the EXE | ~20 KB for the script |
| **Runtime** | PowerShell 5.1 (built-in) | bash (built-in) |
| **FFmpeg** | Auto-installed via winget | Auto-installed via Homebrew |
| **Internet** | Only for FFmpeg auto-install | Only for FFmpeg auto-install |

> 💡 No GPU required — encoding is CPU-based (x264). Any modern CPU works fine; faster CPU = faster encoding.

---

## 🔧 Troubleshooting

| Issue | Platform | Solution |
|-------|----------|----------|
| FFmpeg not found | Windows | Install via `winget install Gyan.FFmpeg` or place `ffmpeg.exe` next to the app |
| FFmpeg not found | macOS | Install via `brew install ffmpeg` |
| UAC prompt on launch | Windows | Re-download the EXE — it should not require admin privileges |
| "Unidentified developer" | macOS | Right-click the file → Open, or run `chmod +x chucha-compress.command` |
| Output larger than target | Both | Expected for very long videos at small size limits — pre-flight warning will explain |
| App won't close | Windows | Click STOP first to cancel processing, then close normally |
| Antivirus flags EXE | Windows | PS2EXE-compiled scripts are sometimes flagged as false positives. Add an exception or run `.ps1` directly |

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
