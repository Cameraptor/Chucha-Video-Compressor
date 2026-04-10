# 🐱 Chucha Video Compressor

[![GitHub](https://img.shields.io/badge/GitHub-Cameraptor-blue?logo=github)](https://github.com/Cameraptor/Chucha-Video-Compressor)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows)](https://github.com/Cameraptor/Chucha-Video-Compressor/releases)
[![macOS](https://img.shields.io/badge/macOS-Intel%20%26%20Apple%20Silicon-000000?logo=apple)](https://github.com/Cameraptor/Chucha-Video-Compressor/releases)
[![Free](https://img.shields.io/badge/Price-Free-brightgreen)]()
[![Telegram](https://img.shields.io/badge/Telegram-Community-2CA5E0?logo=telegram)](https://t.me/voogieboogie)

<table width="100%" cellspacing="0" cellpadding="0"><tr>
<td width="45%" bgcolor="#101010" align="center" valign="middle"><img src="assets/demo.gif" width="100%" alt="Chucha demo"></td>
<td width="55%"><img src="assets/screenshot.jpg" width="100%" alt="Chucha UI"></td>
</tr></table>

> **Batch-compress videos to a precise target file size — GPU-accelerated, drag-and-drop, folder structure preserved. Free.**

Free, portable tool for **Windows** (`.exe`) and **macOS** (`.command`). Drop a folder of videos, set your MB limit, press Compress — the tool finds every video across all subfolders, compresses each one to your exact size, and mirrors the original folder structure in the output. No manual queue. No file picking. One folder in, same folder out — smaller.

Uses 2-pass H.264/H.265 encoding via x264/x265 — the same encoders used by Netflix, YouTube, and professional post-production. With GPU acceleration on NVIDIA, AMD, and Intel for 5–10× faster processing.

**Windows: [Download `VideoCompressor.exe` →](https://github.com/Cameraptor/Chucha-Video-Compressor/releases) — one file, double-click, done. No installation.**

> 🍎 **macOS version available** — same engine, native Terminal-based workflow with macOS dialogs.

**Author:** Voogie | **Project:** CAMERAPTOR | [cameraptor.com/voogie](https://cameraptor.com/voogie)

---

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| 🎯 **Precise Target Size** | Set exact MB limit — bitrate is calculated per-file automatically |
| 📁 **Batch + Full Subfolder Scan** | Drop a folder — finds every video in every nested subfolder, preserves directory tree in output |
| 🖥️ **GPU Acceleration** | NVIDIA (NVENC), AMD (AMF), Intel (QSV) auto-detected — 5–10× faster than CPU |
| 🎬 **H.264 · H.265 · WebM** | x264 two-pass, x265 two-pass (40% better compression), VP9 for open-format delivery |
| 🎵 **Audio Extraction** | Extract MP3/AAC/WAV from any video in one click — switch modes at the top |
| 🖱️ **Drag & Drop** | Drop files and folders directly onto the window — mix both freely |
| 📐 **Resolution up to 4K** | Max long-side: 480 → 720 → 1080 → 1280 → 1920 → 2560 → 3840 |
| 💰 **100% Free** | No subscriptions, no accounts, no trials. MIT license, open source. |
| 📦 **Single EXE** | One file per platform. Auto-installs FFmpeg if missing. |
| 🛡️ **Safe** | Originals never touched — output goes to `Compressed/` subfolder or alongside with `_compressed` suffix |
| ⏹️ **STOP Button** | Cancel at any time without corrupting files |
| 🔍 **Pre-flight Analyzer** | Warns before encoding if a file physically can't fit in your size limit |

---

## 📁 How the Batch + Folder Structure Works

This is the core feature. Here's what actually happens when you drop a folder:

```
Your project/
├── client/
│   ├── interview.mp4
│   └── broll/
│       └── wide_shot.mov
└── exports/
    └── final_cut.mkv
```

After compressing to 2 MB:

```
Your project/
├── Compressed/              ← created automatically
│   ├── client/
│   │   ├── interview.mp4    ← compressed, same name
│   │   └── broll/
│   │       └── wide_shot.mp4
│   └── exports/
│       └── final_cut.mp4
├── client/                  ← originals untouched
└── exports/
```

The tool scans recursively for `.mp4 .mov .avi .mkv .webm .mxf .m4v .wmv`, skips any files already inside a `Compressed/` folder, and rebuilds the exact same tree under `Compressed/` next to your source. You can also choose "Save alongside original" mode — each file gets a `_compressed` suffix in the same directory as the original.

---

## 🆚 Why Not Adobe Media Encoder / DaVinci / HandBrake?

### Adobe Media Encoder — $55/month, still gets the size wrong

AME's "Max File Size" setting is [documented as broken by users on Adobe's own forum](https://community.adobe.com/t5/adobe-media-encoder-discussions/max-file-size-does-nothing/m-p/15178705) — people set a 4 MB limit and get 36 MB files. Beyond that:

- **2-pass disables GPU** — your graphics card sits idle while CPU grinds
- **2-pass is silently buggy** — [documented cases](https://community.adobe.com/t5/adobe-media-encoder-discussions/media-encoder-only-does-1-pass-with-vbr-2-pass-settings-software-encoding/td-p/14743829) where AME performs 1 pass even when 2-pass is selected, no warning
- **Can't go below ~5 MB** — [users can't get files under 5 MB](https://creativecow.net/forums/thread/cant-get-h264-files-smaller-than-5mb-out-of-media/) regardless of settings
- **MainConcept encoder** — [x264 is ~20% more efficient](https://www.streamingmedia.com/Articles/ReadArticle.aspx?ArticleID=147394) at equivalent quality
- **Batch = manual queue** — add and configure files one by one

### DaVinci Resolve — the wrong tool for this job

DaVinci is the best video editor on the planet. It is not the right tool when you have 30 clips that need to be under 2 MB each. To export one file to a target size: open project → import clip → create timeline → Deliver page → manually calculate bitrate from target duration (no automatic input field) → render. Repeat per file. There is no target-size input, no recursive folder scan, no structure preservation.

### HandBrake — good encoder, missing the essentials

Uses x264/x265 under the hood, so encoding quality is solid. But: no target file size input (you set bitrate manually and do the math yourself), no recursive batch with structure preservation, no GPU 2-pass, no audio extraction.

### The comparison

| | Adobe ME | DaVinci | HandBrake | **Chucha** |
|---|---|---|---|---|
| **Hits target size** | ❌ Often broken | ❌ No input | ❌ Manual math | ✅ Per-file, automatic |
| **Batch folder scan** | ❌ | ❌ | ❌ | ✅ Recursive, all subfolders |
| **Preserves folder structure** | ❌ | ❌ | ❌ | ✅ Exact mirror |
| **GPU on 2-pass** | ❌ Disabled | ✅ | ❌ Single-pass only | ✅ NVENC · AMF · QSV |
| **H.265** | ✅ | ✅ | ✅ | ✅ |
| **WebM / VP9** | ❌ | ❌ | ❌ | ✅ |
| **Audio extraction** | ❌ | ❌ | ❌ | ✅ MP3 · AAC · WAV |
| **Price** | $55/month | Free (large install) | Free | **Free, 1 file** |

---

## 📦 Download

> **Windows: you only need `VideoCompressor.exe` — nothing else.**

### Windows

1. Download **`VideoCompressor.exe`** from [Releases](https://github.com/Cameraptor/Chucha-Video-Compressor/releases)
2. Put it anywhere on your PC
3. Double-click to launch

No installation. No dependencies. FFmpeg is auto-detected — if not found, installed automatically via `winget`. You don't need to do anything.

### macOS

1. Download **`chucha-compress.command`** from [Releases](https://github.com/Cameraptor/Chucha-Video-Compressor/releases)
2. Double-click to launch in Terminal
3. If macOS blocks it: right-click → Open, or run `chmod +x chucha-compress.command`

> FFmpeg auto-installed via Homebrew if missing. Same compression engine, native macOS dialogs, progress shown in Terminal.

---

## 🕹️ Usage

### Compress video

1. Drop files or folders onto the window — or use **Browse files** / **Browse folder**
2. Set **Resolution** — max long side in pixels
3. Set **Max Size** — target file size in MB
4. Pick **Format** — MP4 / MOV / WebM
5. Pick **Codec** — H.264 / H.265
6. Choose **GPU** mode — Auto detects and uses the best available
7. Choose **Output mode** — `Compressed/` subfolder (preserves structure) or alongside original
8. Click **COMPRESS**

### Extract audio

1. Click **Extract audio** at the top to switch modes
2. Drop your video files
3. Pick output format — MP3 / AAC / WAV
4. Click **COMPRESS**

> 💡 **Pre-flight check:** Before encoding starts, every file is analyzed. If any video can't physically fit in your size limit, you'll see a warning with the minimum achievable size before anything is written.

> ⏹️ **Stopping:** Click STOP to cancel at any time. The window won't close during processing — stop first.

---

## 📋 Parameters Reference

| Parameter | Default | Options | Description |
|-----------|---------|---------|-------------|
| **Mode** | Compress video | Compress video · Extract audio | Video or audio-only output |
| **Resolution** | 1280 px | 480 · 720 · 1080 · 1280 · 1920 · 2560 · 3840 | Max long-side — portrait and landscape handled correctly |
| **Max Size** | 1.5 MB | Any | Target file size per video |
| **Format** | MP4 | MP4 · MOV · WebM | Output container |
| **Codec** | H.264 | H.264 · H.265 | H.265 = ~40% better compression at same quality |
| **GPU** | Auto | Auto · CPU · NVIDIA · AMD · Intel | Encoder selection |
| **Scale algorithm** | bicubic | bicubic · lanczos · bilinear | Downscale filter quality |
| **Output mode** | Subfolder | Subfolder · Alongside | Where output files are saved |
| **Threads** | Auto | 1–32 | FFmpeg thread count |

### How Bitrate Is Calculated

```
total_budget  = max_size × 0.92         (8% reserved for container overhead)
audio_budget  = 96 kbps × duration
video_bitrate = (total_budget − audio_budget) / duration   (min 80 kbps)
```

Each video is calculated independently based on its own duration — a 10-second clip and a 10-minute clip both hit the same MB target.

---

## 🛠️ Building from Source

### Windows

```powershell
.\compile.ps1
```

Requires PowerShell 5.1+. `ps2exe.ps1` and `compressor.ico` are included in the repo.

### macOS

No build step needed — the script runs directly:

```bash
chmod +x chucha-compress.command
./chucha-compress.command
```

### Source Structure

| File | Platform | Description |
|------|----------|-------------|
| `VideoCompressor.ps1` | Windows | WinForms GUI + all encoding logic |
| `chucha-compress.command` | macOS | Bash script — osascript dialogs + FFmpeg |
| `ps2exe.ps1` | Windows | PS2EXE compiler (PS1 → standalone EXE) |
| `compile.ps1` | Windows | One-click build script |
| `compressor.ico` | Windows | Application icon |

---

## 🛡️ Technical Notes

- **2-pass CPU encoding** — pass 1 analyzes the entire video; pass 2 distributes bits where they matter. Complex scenes get more bitrate, static scenes get less. At 1–3 MB targets the difference is clearly visible vs 1-pass.
- **GPU path** — single-pass constrained VBR via hardware encoder (NVENC/AMF/QSV). WebM/VP9 always uses CPU — no hardware VP9 encoder path exists in FFmpeg.
- **mbtree=0** — x264's macroblock-tree is disabled to prevent incomplete stats files that corrupt output on certain clips.
- **passlogfile in %TEMP%** — 2-pass log files use GUID-named temp paths, not the working directory. Avoids CWD mismatches in the PS2EXE runtime.
- **Folder scan exclusion** — files already inside a `Compressed\` subfolder are automatically skipped to prevent double-compression.

---

## 💻 System Requirements

| | Windows | macOS |
|---|---|---|
| **OS** | Windows 10 / 11 (x64) | macOS 10.15+ (Intel & Apple Silicon) |
| **RAM** | 4 GB | 4 GB |
| **GPU** | Optional — NVIDIA/AMD/Intel for hardware encoding | — |
| **Runtime** | PowerShell 5.1 (built-in) | bash (built-in) |
| **FFmpeg** | Auto-installed via winget | Auto-installed via Homebrew |

---

## 🔧 Troubleshooting

| Issue | Solution |
|-------|----------|
| FFmpeg not found (Windows) | `winget install Gyan.FFmpeg` or place `ffmpeg.exe` next to the app |
| FFmpeg not found (macOS) | `brew install ffmpeg` |
| GPU encoder not detected | Switch to CPU mode manually; check that GPU drivers are current |
| Output larger than target | Expected for very short clips at extreme size limits — pre-flight warning explains |
| App won't close | Click STOP to cancel processing first |
| Antivirus flags the EXE | PS2EXE-compiled scripts are sometimes false-positived. Add an exception or run `.ps1` directly in PowerShell. |
| macOS "unidentified developer" | Right-click → Open, or `chmod +x chucha-compress.command` |

---

## 🤝 Support & Community

- **💬 Telegram:** [Join @voogieboogie](https://t.me/voogieboogie) — questions, feedback, feature requests
- **🐛 Issues:** [GitHub Issues](https://github.com/Cameraptor/Chucha-Video-Compressor/issues)
- **🌐 Website:** [cameraptor.com/voogie](https://cameraptor.com/voogie)

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

<div align="center">

**Made in Luga by Voogie | CAMERAPTOR**

[![Telegram](https://img.shields.io/badge/💬_Join_Telegram_Community-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/voogieboogie)

⭐ Star this repo if it saves you time

</div>
