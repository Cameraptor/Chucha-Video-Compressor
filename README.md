# Chucha Video Compressor

[![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows)](https://github.com/Cameraptor/Chucha-Video-Compressor/releases)
[![macOS](https://img.shields.io/badge/macOS-Intel%20%26%20Apple%20Silicon-000000?logo=apple)](https://github.com/Cameraptor/Chucha-Video-Compressor/releases)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Free](https://img.shields.io/badge/Price-Free-brightgreen)]()
[![Telegram](https://img.shields.io/badge/Telegram-Community-2CA5E0?logo=telegram)](https://t.me/voogieboogie)

<table width="100%" cellspacing="0" cellpadding="0"><tr>
<td width="45%" bgcolor="#101010" align="center" valign="middle"><img src="assets/demo.gif" width="100%" alt="Chucha demo"></td>
<td width="55%"><img src="assets/screenshot.jpg" width="100%" alt="Chucha UI"></td>
</tr></table>

---

## You have videos. You need them smaller. This should not be hard.

You shoot something. Client needs it under 2 MB. Or the upload form has a limit. Or you're sending 40 clips and email hates you.

So you open Adobe Media Encoder. Set the size limit. Export. Get a file that's 8× too big. Try again. Google the settings. Find a forum post from 2019. Give up and use HandBrake. Manually calculate the bitrate. Forget that video is 3 minutes long, not 2. Redo it.

**There is no reason this should take more than 10 seconds.**

Drop your files. Type the MB limit. Press Compress. Done.

That's Chucha. Free, single file, no install.

---

## What it does

**Chucha compresses any video to a precise target file size** using professional 2-pass encoding — the same technique used by Netflix, YouTube, and post-production studios. It calculates the exact bitrate needed for each file individually, runs two encoding passes to distribute quality where it matters, and hits your target size consistently.

Not "roughly." Not "usually." Consistently.

- Drop a whole folder → every video inside gets compressed, subfolder structure preserved
- Set 1.5 MB → every output file comes out at ≤1.5 MB
- GPU detected automatically → NVIDIA, AMD, Intel all work out of the box
- First run takes ~30 seconds to auto-install FFmpeg. After that: instant.

---

## Why existing tools fail at this

### Adobe Media Encoder — $55/month and it still gets the size wrong

AME has a "Max File Size" setting. It does not work. This is not an opinion — it's a [recurring complaint on Adobe's own forum](https://community.adobe.com/t5/adobe-media-encoder-discussions/max-file-size-does-nothing/m-p/15178705) where users set a 4 MB limit and get 36 MB files. The setting exists. The encoder ignores it.

Beyond that:

- **2-pass encoding disables GPU** — your $800 graphics card sits idle
- **2-pass is silently broken** — [documented cases](https://community.adobe.com/t5/adobe-media-encoder-discussions/media-encoder-only-does-1-pass-with-vbr-2-pass-settings-software-encoding/td-p/14743829) where AME performs 1 pass even when 2-pass is selected, with no error or warning
- **Can't go below ~5 MB** — [users report being unable to get files below 5 MB](https://creativecow.net/forums/thread/cant-get-h264-files-smaller-than-5mb-out-of-media/) regardless of settings
- **MainConcept encoder** — AME's H.264 encoder is ~20% less efficient than x264 at equivalent visual quality
- **Batch = manual queue** — you add files one by one, configure each separately

### DaVinci Resolve — the wrong tool for this job

DaVinci is the best video editor on the planet. It is spectacular at color grading a feature film. It is not the tool you want when you have 30 clips that need to be under 2 MB each.

To export one file to a target size: open project → import clip → create timeline → set in/out → open Deliver page → choose codec → manually calculate bitrate from target size (no automatic input) → render. Repeat 30 times.

DaVinci has no target-size input field. No batch folder scan. No drag-and-drop queue that preserves directory structure. It's built for a different problem entirely.

### HandBrake — good encoder, missing the point

HandBrake uses x264 under the hood, so encoding quality is solid. But:

- No target file size — you set bitrate manually, which means calculating it yourself per clip based on its runtime
- No recursive batch — files are queued one at a time; no folder scan, no structure preservation
- No GPU 2-pass — hardware encoding is single-pass only
- No audio extraction

### Chucha

| | Adobe ME | DaVinci | HandBrake | **Chucha** |
|---|---|---|---|---|
| **Hits target size** | ❌ Broken | ❌ No input | ❌ Manual math | ✅ Always |
| **Batch folder scan** | ❌ | ❌ | ❌ | ✅ Recursive |
| **GPU acceleration** | ⚠️ Disables on 2-pass | ✅ | ⚠️ Single-pass only | ✅ NVENC · AMF · QSV |
| **H.265 support** | ✅ | ✅ | ✅ | ✅ |
| **WebM / VP9** | ❌ | ❌ | ❌ | ✅ |
| **Audio extraction** | ❌ | ❌ | ❌ | ✅ MP3 · AAC · WAV |
| **Drag and drop** | ⚠️ | ⚠️ | ⚠️ | ✅ Files + folders |
| **Price** | $55/month | Free (complex) | Free | **Free** |
| **Setup time** | 10+ min install | 10+ min install | 5 min install | **< 1 min** |

---

## What changed in v2

The app was completely rebuilt. Here's the before/after:

| | v1 | v2 |
|---|---|---|
| **Input** | Folder picker only (Windows 95 dialog) | Drag-and-drop files + folders, modern Windows picker |
| **Codecs** | H.264 only | H.264 · H.265 · WebM/VP9 |
| **GPU** | CPU only, always | NVIDIA · AMD · Intel — auto-detected |
| **Resolution** | Up to 1920px | Up to 4K (3840px) |
| **Audio** | Video compression only | + Audio extraction mode (MP3/AAC/WAV) |
| **File picker** | Legacy FolderBrowserDialog | Native IFileOpenDialog (modern Windows Explorer UI) |
| **UI** | Basic flat controls | Dark titlebar, brand fonts, chip selectors, drop zone |
| **Formats** | MP4 · MOV | MP4 · MOV · WebM |

Here's what each new thing actually does:

**GPU encoding** — NVIDIA, AMD, and Intel GPUs are detected automatically at launch. Hardware encoding is 5–10× faster than CPU for large files. Select Auto and forget about it, or lock to a specific GPU if you need to.

**Drag and drop** — drop any mix of files and folders directly onto the window. The app recursively finds every video, compresses each one, and mirrors the original folder structure in the output. Drop your entire project folder and walk away.

**H.264 · H.265 · WebM** — H.265 gives 40% better compression at the same visual quality. WebM/VP9 for open-format delivery. Switch between them with a single click.

**Audio extraction** — toggle from video compression to audio extraction. Drop video files, pick MP3/AAC/WAV, get clean audio tracks out. One click to switch modes.

**4K support** — resolution selector up to 3840px. Portrait and landscape handled automatically.

**Modern file pickers** — replaced the Windows 95-era folder browser with `IFileOpenDialog` — the same native dialog used by modern Windows apps.

**Redesigned UI** — dark titlebar via DWM, brand fonts (Cormorant Garamond + Raleway), chip selectors for format and codec, drop zone with live file list.

---

## Download

### Windows — just get the EXE, nothing else needed

You don't need to download the repo. You don't need PowerShell or Python or anything else.
**One file. Double-click. It works.**

<div align="center">

### [⬇ Download VideoCompressor.exe](https://github.com/Cameraptor/Chucha-Video-Compressor/releases)

</div>

Put it anywhere on your PC. Double-click. FFmpeg is auto-detected on first launch — if not found, it installs itself silently in the background. You don't touch anything.

### macOS

1. Download **`chucha-compress.command`** from [**Releases →**](https://github.com/Cameraptor/Chucha-Video-Compressor/releases)
2. Double-click to open in Terminal
3. Blocked by macOS? Right-click → Open, or `chmod +x chucha-compress.command`

> Same compression engine, native macOS dialogs, FFmpeg auto-installed via Homebrew.

---

## How to use it

### Compress video

1. Drop files or folders onto the window — or hit **Browse files** / **Browse folder**
2. Set your target size in MB
3. Pick format (MP4 / MOV / WebM) and codec (H.264 / H.265)
4. Choose GPU mode — Auto works for most cases
5. Hit **COMPRESS**

### Extract audio

1. Click **Extract audio** at the top
2. Drop your video files
3. Pick MP3, AAC, or WAV
4. Hit **COMPRESS**

Pre-flight check runs before encoding — if any file can't physically fit in your size limit, you'll see a warning before anything starts.

---

## Settings reference

| Setting | Default | Options |
|---------|---------|---------|
| Mode | Compress video | Compress video · Extract audio |
| Resolution | 1280 px | 480 · 720 · 1080 · 1280 · 1920 · 2560 · 3840 |
| Max Size | 1.5 MB | Any value |
| Format | MP4 | MP4 · MOV · WebM |
| Codec | H.264 | H.264 · H.265 |
| GPU | Auto | Auto · CPU · NVIDIA · AMD · Intel |
| Scale | bicubic | bicubic · lanczos · bilinear |
| Output | Subfolder | Subfolder · Alongside original |

---

## How the size math works

```
total_budget  = target_mb × 0.92       — 8% reserved for container overhead
audio_budget  = 96 kbps × duration     — audio at constant 96 kbps AAC
video_bitrate = (total_budget − audio_budget) / duration
```

Each file is calculated independently. A 10-second clip and a 10-minute clip both hit the same MB target.

---

## Build from source

```powershell
# Windows
.\compile.ps1
```

```bash
# macOS — no build needed
chmod +x chucha-compress.command
```

Requires: PowerShell 5.1+, `ps2exe.ps1` (included), `compressor.ico` (included).

---

## System requirements

| | Windows | macOS |
|---|---|---|
| OS | Windows 10 / 11 | macOS 10.15+ |
| Runtime | PowerShell 5.1 (built-in) | bash (built-in) |
| GPU | Optional — NVIDIA/AMD/Intel for HW encode | — |
| FFmpeg | Auto-installed | Auto-installed via Homebrew |

---

## Support

**Telegram:** [Join @voogieboogie](https://t.me/voogieboogie) — questions, feedback, feature requests  
**Issues:** [GitHub Issues](https://github.com/Cameraptor/Chucha-Video-Compressor/issues)  
**Website:** [cameraptor.com/voogie](https://cameraptor.com/voogie)

---

## License

MIT — free to use, modify, distribute.

---

<div align="center">

**Made in Luga by Voogie | CAMERAPTOR**

[![Telegram](https://img.shields.io/badge/💬_Join_Telegram_Community-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/voogieboogie)

⭐ Star if it saved you time

</div>
