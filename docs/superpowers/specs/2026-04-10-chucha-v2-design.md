# Chucha Video Compressor — v2 Enhancement Spec
**Date:** 2026-04-10  
**Reference app:** Shutter Encoder v20.0 (settings.xml + UI screenshots)  
**Constraint:** Stay a simple single-EXE PowerShell + WinForms utility. No video preview. No menus. No NLE features.

---

## 0. Brand Compliance (CAMERAPTOR Brand Guide)

**Source:** `D:\Work\Assets\Projects\Business\CAMERAPTOR\CAMERAPTOR.COM\docs\BRAND.md`

### Colors — corrections for v2

| Token | Hex | RGB | v1 state | Action |
|-------|-----|-----|----------|--------|
| Raptor Green (CTA/accent) | `#21C134` | 33, 193, 52 | `#1CA42C` — WRONG | Fix in v2 |
| Base Dark (bg) | `#101010` | 16, 16, 16 | `#101010` | ✓ correct |
| Base Light (text) | `#F2E2E2` | 242, 226, 226 | `#F2E2E2` | ✓ correct |
| Base Mid (borders/panels) | `#262626` | 38, 38, 38 | `#262626` | ✓ correct |
| Muted text (secondary) | `#9a9590` | 154, 149, 144 | `#585858` — WRONG | Fix in v2: brand warm gray, not cool neutral |
| Dim text (copyright) | `#4a4845` | 74, 72, 69 | `#373737` — WRONG | Fix in v2: brand dim, not neutral |
| Input bg | `#161616` | 22, 22, 22 | `#161616` | ✓ correct (subtle depth) |
| Log well bg | `#080808` | 8, 8, 8 | `#080808` | ✓ correct |
| Drop zone bg | `#0A0A0A` | 10, 10, 10 | N/A | NEW in v2 |

### Derived interactive states (from Raptor Green `#21C134`)

| State | Hex | Derivation |
|-------|-----|------------|
| Hover | `#2AD43F` | +15% luminance from `#21C134` |
| Pressed | `#1A9A2A` | -20% luminance from `#21C134` |
| Disabled | `#145A1A` | 40% opacity equivalent |
| Focus ring | `#21C134` | Same as accent, 2px border |

### Secondary functional colors (not in brand palette — app-specific extensions)

| Token | Hex | Use |
|-------|-----|-----|
| Stop/danger red | `#B42828` | STOP button, error states |
| Warning orange | `#FF6E00` | Brand Orange — pre-flight warnings |
| Info cyan | `#32BCB4` | Brand Tiffany — informational log lines |
| Success | `#21C134` | Raptor Green — success states (brand-consistent) |

Only green + dark greys + light text as primary palette. Secondary palette (orange/teal) used sparingly for functional states only — single-purpose utility.

### Fonts — embedding plan

| Font | Role | WinForms strategy |
|------|------|-------------------|
| Cormorant Garamond SemiBold | Display title "VIDEO COMPRESSOR" | Embed **TTF** (not WOFF2!) → extract to `%TEMP%\ChuCha_Fonts\` on startup, load via `PrivateFontCollection` |
| Raleway Regular + Medium | UI labels, buttons, body | Same: embed **TTF** + `PrivateFontCollection` |
| DM Mono Regular | Log box output | Fallback to Consolas (system) — acceptable |

**CRITICAL: Use TTF, not WOFF2.** `PrivateFontCollection` in .NET/GDI+ requires TTF or OTF files. WOFF2 is a web format and cannot be loaded by WinForms.

### Font embedding — implementation details

**Embed only needed weights** (not variable fonts) to minimize PS1 bloat:
- Cormorant Garamond SemiBold (600) — ~150KB TTF → ~200KB Base64
- Raleway Regular (400) — ~100KB TTF → ~133KB Base64  
- Raleway Medium (500) — ~100KB TTF → ~133KB Base64
- Total: ~466KB Base64 added to PS1

**Extraction path:** `%TEMP%\ChuCha_Fonts\` (subfolder, not root temp)
- On startup: create folder, extract TTFs, load via PrivateFontCollection
- On startup: also **clean stale files** (delete folder if exists from prior crash, recreate)
- On process exit: delete folder via `Register-EngineEvent PowerShell.Exiting`

Fallback if `PrivateFontCollection` load fails: Georgia (Cormorant stand-in), Segoe UI (Raleway stand-in), Consolas (DM Mono). Silent fallback, no error shown.

### Type scale for v2 (4 steps, derived from Brand Guide)

| Role | Font | Size | Weight | WinForms var |
|------|------|------|--------|-------------|
| Title "VIDEO COMPRESSOR" | Cormorant Garamond | 20pt | SemiBold (600) | `$fontTitle` |
| Brand "C H U C H A" | Raleway | 9pt | Regular (400), tracking via spaces | `$fontBrand` |
| Section labels (RESOLUTION, FORMAT) | Raleway | 8pt | Medium (500), ALL CAPS | `$fontLabel` |
| Body / inputs / radios | Raleway | 9.5pt | Regular (400) | `$fontUI` |
| Buttons (START, Browse) | Raleway | 11pt | Medium (500) | `$fontBtn` |
| Log box | DM Mono / Consolas | 8.5pt | Regular | `$fontMono` |
| Copyright | Raleway | 7.5pt | Regular (400) | `$fontCopy` |

---

## 1. Current State (v1 baseline)

**File:** `VideoCompressor.ps1` → compiled to `VideoCompressor.exe` via ps2exe

| What | How |
|------|-----|
| Encoding | Two-pass x264 (`libx264`, `preset slow`) |
| Bitrate | Calculated from target MB + duration + audio budget |
| Audio | AAC 96 kbps if present |
| Scale | `scale='if(gte(iw,ih),RES,-2)':'if(gte(iw,ih),-2,RES)'` (long-side cap) |
| Formats out | MP4 (faststart) or MOV |
| Input source | Single folder, recursive scan |
| Output modes | `Compressed/` subfolder OR `_compressed` suffix alongside |
| FFmpeg install | Auto via winget, then direct download from gyan.dev |
| UI | Fixed 480×686 WinForms, dark theme, green accent (#1CA42C) |
| Progress | `ffmpeg -progress <tmpfile>` polled every 400 ms, no pipe |
| Cancellation | `$script:CancelRequested` flag, `p.Kill()` |
| Pre-flight | Warns if file physically cannot fit within target MB |
| Error log | Written to `$env:TEMP\VideoCompressor_error.txt` |

**Pain points borrowed from Shutter Encoder UI analysis (screenshots):**
- No GPU acceleration → slow on long clips
- Single codec (x264) → H.265 would give ~50% better compression for same quality
- Old Windows 95 `FolderBrowserDialog` tree-view
- No drop zone — user must type or click Browse, no visual feedback that a source is loaded
- Only folder input — SE accepts individual files too; user might want to compress one file fast
- No audio extraction — SE has "MP3", "AAC", etc. functions; quick audio strip is very useful
- No completion sound → user has to watch the window
- No thread control → FFmpeg defaults; user can't tune for their machine
- All settings exposed flat; SE shows simple view collapsed by default

**UI balance analysis (screenshots):**

| | Shutter Encoder | Chucha v1 |
|--|--|--|
| Drop zone | Large dark panel, icon, "Drop files here" | Text field only |
| File feedback | "1 File" counter, path in list | Nothing visible |
| Source type | Files OR folder | Folder only |
| Function select | Dropdown (78 items!) | MP4/MOV radio |
| Output settings | Visible, always expanded | Minimal |
| GPU | Status bar at bottom | None |
| Codec choice | 78 options | None |

**SE is overloaded** (video preview, 3 output tabs, FTP/email, waveform, frame-by-frame, 78 codec options, color grading, subtitles...).  
**Chucha is underloaded** (no drop zone, no file feedback, no codec, no GPU, no audio).  
**v2 target:** SE's drop zone + file feedback + audio mode + GPU + advanced collapse. Nothing else from SE.

---

## 2. Design Goals for v2

1. **Drop zone UI** — large panel replaces the text field; accepts drag of files OR folders.
2. **Files OR folder mode** — user can drop/browse individual video files, or a whole folder.
3. **Audio extraction mode** — quick "Extract audio → MP3" toggle, borrowing SE's audio function concept.
4. **GPU acceleration** — NVIDIA/AMD/Intel hw encoders, auto-detect, CPU fallback.
5. **H.265 codec option** — one extra radio button, big quality-per-MB gain.
6. **Sound notification on done** — .NET system sound, zero dependencies.
7. **Thread control** — single numeric field passed to `-threads N`.
8. **Modern folder/file picker** — IFileOpenDialog COM interop (same dialog as Windows Explorer).
9. **Advanced panel** — collapsible section; keeps simple UI simple.
10. **Open output folder on done** — checkbox from SE `caseOpenFolderAtEnd1`.
11. **Scale algorithm** — bicubic/lanczos/bilinear in Advanced.

**Not in scope:** video preview, presets, multiple output destinations, AI features, audio normalization, VMAF, yt-dlp, color grading, subtitles, watermark, waveform display, 3 output tabs, FTP, any network call not already present.

---

## 3. Drop Zone + Source Input Redesign

### 3.1 Problem

Current source input is a plain TextBox + Browse button. No visual feedback. Old tree-view dialog. Folder-only.

From SE screenshots: the "Choose files" area is a dark panel with a large drop zone, "Drop files here" text + icon, Browse/Clear buttons, and a file counter ("1 File"). This is the first thing you see and it communicates intent immediately.

### 3.2 New layout — SOURCE area replaces old folder row

**Remove:** `$txtFolder` TextBox + `$btnBrowse` Button (current Browse row)

**Add:** A `Panel` acting as the drop zone:

```
┌─────────────────────────────────────────────────────┐
│  [ Browse files ]  [ Browse folder ]  [ Clear ]  3 files │
│                                                     │
│              ↓  Drop files or folder here           │
│                                                     │
│  D:\Videos\clip1.mp4                                │
│  D:\Videos\clip2.mp4                                │
└─────────────────────────────────────────────────────┘
```

- Panel background: `#0A0A0A` (slightly darker than main bg `#101010`)
- Border: 1px dashed `#2A2A2A` (subtle, not loud)
- Height: 150px (not 130 — extra 20px gives 6 visible file rows instead of 4); fixed height with vertical scroll on overflow
- Icon: Unicode `↓` or `⬇` drawn in muted color centered when list is empty
- Text when empty: `"Drop files or folder here"` in muted gray

### 3.3 File list display inside drop zone

Internal `ListBox` or `RichTextBox` (ReadOnly) showing short filenames:
- Background matches panel (`#0A0A0A`), no border
- Font: Consolas 8pt (matches existing `$fontMono`)
- Shows only filename (not full path) — tooltip on hover = full path
- Max visible rows: ~5; scrolls if more

### 3.4 File counter

Label to the right of the Browse buttons: `"3 files"` or `"1 folder (12 files found)"`. Borrowed directly from SE's `"1 File"` counter.

Updates when user adds/removes sources.

### 3.5 Browse buttons

**[ Browse files ]** — opens IFileOpenDialog with multiselect, filter: video files (`*.mp4;*.mov;*.avi;*.mkv;*.webm;*.mxf;*.m4v;*.wmv`). Returns array of file paths.

**[ Browse folder ]** — opens IFileOpenDialog with `FOS_PICKFOLDERS` flag. Returns single folder path. On confirmation: scans folder recursively for video files (same `Get-VideoFiles` logic), shows count in counter.

**[ Clear ]** — clears the list, resets counter to "0 files".

### 3.6 Drag & drop

Drop zone Panel and the Form accept drag:
- **Files dropped:** filter to video extensions only, add to list (or replace if folder was previously set)
- **Folder dropped:** scan recursively, populate list with found video files, show "1 folder (N files)"
- `DragEnter`: if contains FileDrop data → `DragDropEffects.Copy`, panel border flashes to Raptor Green `#21C134`, panel bg lightens to `#111111`
- `DragLeave` / `DragDrop`: border returns to `#2A2A2A`, bg returns to `#0A0A0A`

### 3.7 Internal state

```powershell
$script:SourceFiles = @()        # [System.IO.FileInfo[]] — all files to process
$script:SourceFolderRoot = $null # string — set when a folder was browsed (for output path calculation)
```

`Get-VideoFiles` populates `$script:SourceFiles` from folder path.  
Browse files sets `$script:SourceFiles` directly from file list.  
Folder mode sets both `$script:SourceFolderRoot` and `$script:SourceFiles`.

Output path logic uses `$script:SourceFolderRoot` when set (preserves existing subfolder/alongside behavior). When files-only mode (no root folder), always saves alongside original with `_compressed` suffix.

---

## 4. Audio Extraction Mode

### 4.1 Concept

Borrowed from SE's "Choose function" → audio format options (MP3, AAC, FLAC, etc.).

In Chucha: a simple **mode toggle** instead of a dropdown with 78 options:

```
MODE
[ Compress video ]  [ Extract audio ]
```

Two radio buttons styled as button group (same style as existing MP4/MOV buttons). Switching modes reconfigures the settings area below.

### 4.2 Video mode (default)

Normal Chucha UI: Resolution, Max size, Format (MP4/MOV), output mode — all visible as now.

### 4.3 Audio extraction mode

When "Extract audio" is selected:
- **Hide:** Resolution field, Max size field, Format (MP4/MOV) group, Codec row
- **Show:** Audio format selector: `[ MP3 ]  [ AAC ]  [ WAV ]`
- **Show:** Audio bitrate: `[ 128 kbps ]  [ 192 kbps ]  [ 320 kbps ]`
- **Keep:** Source drop zone, Output mode, START button

FFmpeg command for audio extraction (MP3 example):
```
ffmpeg -y -i input.mp4 -vn -c:a libmp3lame -b:a 192k output.mp3
```

No two-pass, no resolution, no size target. Just extract audio track.

Output file extension changes to match: `.mp3`, `.aac`, `.wav`.

Output naming: same output mode logic (Compressed subfolder OR alongside), just different extension.

### 4.4 Pre-flight for audio mode

Check if source file has audio stream. If not: log "No audio track found in [file], skipping." and mark as failed. No dialog — just log and continue to next file.

---

## 5. GPU Acceleration

### 3.1 Detection

On startup (after FFmpeg is found), probe available hardware encoders:

```
ffmpeg -encoders 2>&1 | grep -E "h264_nvenc|hevc_nvenc|h264_amf|hevc_amf|h264_qsv|hevc_qsv"
```

Internally store a `$script:AvailableGPUEncoders` hashtable:

```powershell
$script:AvailableGPUEncoders = @{
    NVIDIA = $false   # h264_nvenc / hevc_nvenc
    AMD    = $false   # h264_amf  / hevc_amf
    Intel  = $false   # h264_qsv  / hevc_qsv
}
```

Populate on `Form_Shown` after FFmpeg found. Log which GPU encoders were detected.

### 3.2 UI — GPU selector (in Advanced panel)

ComboBox or button group: **Auto | CPU | NVIDIA | AMD | Intel**

- **Auto** (default): pick first available in order NVIDIA → AMD → Intel → CPU.
- **CPU**: force libx264 / libx265 (two-pass).
- Named GPU: force that vendor; if encoding fails mid-file, log error and fall back to CPU for that file only.

### 3.3 Encoding logic changes per GPU path

| Path | Video encoder | Passes | Bitrate control |
|------|--------------|--------|-----------------|
| CPU H.264 | `libx264 -preset slow` | 2-pass | `-b:v NNNk` |
| CPU H.265 | `libx265 -preset slow` | 2-pass | `-b:v NNNk` |
| GPU H.264 NVIDIA | `h264_nvenc` | 1-pass | `-b:v NNNk -bufsize 2*NNNk -maxrate 1.5*NNNk` |
| GPU H.264 AMD | `h264_amf` | 1-pass | `-b:v NNNk -rc cbr` |
| GPU H.264 Intel | `h264_qsv` | 1-pass | `-b:v NNNk` |
| GPU H.265 NVIDIA | `hevc_nvenc` | 1-pass | same as h264_nvenc pattern |
| GPU H.265 AMD | `hevc_amf` | 1-pass | same |
| GPU H.265 Intel | `hevc_qsv` | 1-pass | same |

GPU path skips pass-1 entirely (no passlog file). Bitrate calculation formula is the same (`$vbrKbps`).

**GPU fallback rule:** If GPU encode returns non-zero exit code AND not cancelled:
- Log "GPU encode failed for [file], retrying with CPU..."
- Re-run `Compress-Video` with GPU override = "CPU" for that file only.
- Count retry result toward done/failed totals normally.

### 3.4 Encoder function signature change

```powershell
function Compress-Video {
    param($File, $OutputPath, $MaxSizeMB, $MaxRes, $Format,
          $LogBox, $StatusLabel,
          $GpuMode,       # "Auto"|"CPU"|"NVIDIA"|"AMD"|"Intel"
          $Codec,         # "H.264"|"H.265"
          $ScaleAlgo,     # "bicubic"|"lanczos"|"bilinear"
          $Threads)       # 0 = auto
}
```

---

## 6. H.265 Codec Option

### 6.1 UI

Radio group alongside existing MP4/MOV: **H.264 | H.265**

Or — cleaner — separate label+row:
```
CODEC
[ H.264 ]  [ H.265 ]
```

H.264 is default. H.265 note in log: "H.265 encodes slower but ~40% smaller at equal quality."

### 6.2 Container compatibility

| Codec | MP4 | MOV |
|-------|-----|-----|
| H.264 | ✓   | ✓   |
| H.265 | ✓   | ✓   |

No restrictions needed — both codecs work in both containers.

### 6.3 libx265 two-pass note

libx265 two-pass requires `-x265-params pass=1` and `-x265-params pass=2` instead of x264's `-pass 1`/`-pass 2`. The `Compress-Video` function must branch on codec for pass flags:

```powershell
if ($Codec -eq "H.265") {
    $passFlag1 = @("-x265-params", "pass=1")
    $passFlag2 = @("-x265-params", "pass=2:stats=${passLog}.log")
} else {
    $passFlag1 = @("-pass", "1", "-passlogfile", $passLog)
    $passFlag2 = @("-pass", "2", "-passlogfile", $passLog)
}
```

---

## 7. Sound Notification

### 7.1 Mechanism

Use .NET built-in, no external files:

```powershell
[System.Media.SystemSounds]::Asterisk.Play()
```

Called at end of batch if not cancelled. No volume slider — system sounds respect Windows volume.

### 7.2 UI

Checkbox in Advanced panel: `[ ] Play sound when done`  
Stored in `$script:PlaySoundOnDone` boolean. Default: `$true`.

---

## 8. Thread Control

### 8.1 FFmpeg flag

Add `-threads N` to all ffmpeg invocations. `N=0` means FFmpeg auto (its default behavior).

```powershell
$threadArgs = @("-threads", $Threads.ToString())
```

Inserted before input `-i` flag in both passes.

### 8.2 UI

Small numeric TextBox in Advanced panel, label "CPU THREADS (0=auto)".  
Width: 60px. Default value: `"0"`.  
Validation: must be integer 0–64. Invalid → warn and reset to 0.

---

## 9. Modern File/Folder Picker (IFileOpenDialog)

### 9.1 Problem

Current `FolderBrowserDialog` shows the classic Windows XP tree-view dialog. Now superseded by the drop zone (Section 3), but Browse buttons still need to open the modern Explorer-style picker.

### 9.2 Solution — IFileOpenDialog via C# Add-Type

One C# type block added via `Add-Type` at script top. Exposes two public static methods:

```csharp
public static string PickFolder(IntPtr owner)
// Opens IFileOpenDialog with FOS_PICKFOLDERS | FOS_FORCEFILESYSTEM
// Returns selected path or null if cancelled

public static string[] PickFiles(IntPtr owner, string filter)
// Opens IFileOpenDialog with FOS_ALLOWMULTISELECT | FOS_FORCEFILESYSTEM
// Returns array of selected file paths or null if cancelled
```

Internal: `IFileOpenDialog` COM interface with CLSID `DC1C5A9C-E88A-4dde-A5A1-60F82A20AEF7`.  
Options flag `FOS_PICKFOLDERS = 0x20`, `FOS_FORCEFILESYSTEM = 0x40`, `FOS_ALLOWMULTISELECT = 0x200`.

**Fallback:** If `Add-Type` or COM call throws, catch silently and fall back to `FolderBrowserDialog` with `AutoUpgradeEnabled = $true`. Transparent to user.

### 9.3 Browse buttons wire-up

- `[ Browse files ]` → calls `PickFiles`, populates `$script:SourceFiles`, updates drop zone list + counter
- `[ Browse folder ]` → calls `PickFolder`, calls `Get-VideoFiles`, populates `$script:SourceFiles` + `$script:SourceFolderRoot`, updates list + counter

---

## 10. Advanced Panel (Collapsible)

### 10.1 Layout

Below the main settings, above the log box. Collapsed by default.

Toggle button: `"▼  ADVANCED"` / `"▲  ADVANCED"` (flat, muted color).

When collapsed: form height = current 686px  
When expanded: form height = 686 + 180 = 866px  
(All controls below the Advanced panel shift down when it expands.)

### 10.2 Controls inside Advanced panel

| Row | Control | Type | Default | Borrowed from |
|-----|---------|------|---------|---------------|
| 1 | GPU ACCELERATION | ComboBox: Auto/CPU/NVIDIA/AMD/Intel | Auto | SE `comboAccel` |
| 1 | CODEC | Radio: H.264 / H.265 | H.264 | SE `comboFonctions` |
| 2 | SCALE ALGORITHM | ComboBox: bicubic/lanczos/bilinear | bicubic | SE `comboScale` |
| 2 | CPU THREADS (0=auto) | TextBox 60px | 0 | SE `txtThreads` |
| 3 | [ ] Play sound when done | Checkbox | checked | SE `casePlaySound` |
| 3 | [ ] Open output folder when done | Checkbox | unchecked | SE `caseOpenFolderAtEnd1` |

### 10.3 "Open output folder" behavior

After batch completes (not cancelled, not error-only):
```powershell
Start-Process "explorer.exe" -ArgumentList $outputFolderPath
```
Where `$outputFolderPath` is the root `Compressed\` folder or the source folder depending on output mode.

### 10.4 Form resize implementation

```powershell
$ADVANCED_HEIGHT = 180

$btnAdvanced.Add_Click({
    if ($advancedVisible) {
        $advancedPanel.Visible = $false
        $form.ClientSize = [Drawing.Size]::new(480, 686)
        $form.MinimumSize = [Drawing.Size]::new(496, 725)
        $form.MaximumSize = [Drawing.Size]::new(496, 725)
        $btnAdvanced.Text = "▼  ADVANCED"
        $advancedVisible = $false
    } else {
        $advancedPanel.Visible = $true
        $form.ClientSize = [Drawing.Size]::new(480, 686 + $ADVANCED_HEIGHT)
        $form.MinimumSize = [Drawing.Size]::new(496, 725 + $ADVANCED_HEIGHT)
        $form.MaximumSize = [Drawing.Size]::new(496, 725 + $ADVANCED_HEIGHT)
        $btnAdvanced.Text = "▲  ADVANCED"
        $advancedVisible = $true
    }
})
```

All controls below the separator (progress bar, status label, log box, copyright) must have their `Location.Y` shifted by `+$ADVANCED_HEIGHT` when panel opens. Simplest approach: wrap them in a `$lowerPanel = Panel` anchored to the bottom, so they shift automatically with form resize. OR recalculate Y on toggle.

---

## 11. Log Changes

Additional log lines to add:

```
GPU encoders found: NVIDIA (h264_nvenc, hevc_nvenc)
Using encoder: h264_nvenc  (GPU: NVIDIA)
[1/3]  video.mp4
  Pass 1/2 (GPU — single pass)  00:01:23 / 00:05:00  (27%)
  [ok]  1412 KB -> D:\...\Compressed\video.mp4
GPU encode failed for clip2.mp4, retrying on CPU...
```

---

## 12. Files Changed / Created

| File | Change |
|------|--------|
| `VideoCompressor.ps1` | All changes live here — no new files |
| `VideoCompressor.exe` | Re-compiled via `ps2exe.ps1` after PS1 updated |
| `compile.ps1` | No change needed |

---

## 13. Encoding Summary Log Line

Current summary line:
```
Done: 3 successful
```

Enhanced:
```
Done: 3 successful  |  GPU: NVIDIA (h264_nvenc)  |  Threads: auto
```

---

## 14. DPI Awareness (NEW — missing from v1)

### 14.1 Problem

WinForms apps on high-DPI displays (125%, 150%, 175%) render blurry or have misaligned controls. Windows tries to scale the app bitmap, causing fuzzy text and offset click targets. This affects Cormorant Garamond rendering especially — serif fonts look terrible when bitmap-scaled.

### 14.2 Solution — SetProcessDPIAware at script start

Add before any assembly loading (line 1 of script):

```powershell
Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
public class DpiAware {
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
}
'@
[DpiAware]::SetProcessDPIAware()
```

This tells Windows "I handle my own scaling" — WinForms then renders at native DPI with crisp fonts and correct control sizes.

### 14.3 Screen height guard for Advanced panel

Before expanding the Advanced panel, check if it fits:

```powershell
$screen = [Windows.Forms.Screen]::FromControl($form)
$availableHeight = $screen.WorkingArea.Height
$expandedHeight = 725 + $ADVANCED_HEIGHT  # 905px

if ($expandedHeight -gt $availableHeight) {
    # Don't expand — just show a scrollable inner panel instead
    # Or: expand to maximum available, clip bottom
}
```

This prevents the form from going off-screen on 768p laptops.

---

## 15. 8px Vertical Grid System (NEW — replacing inconsistent spacing)

### 15.1 Problem

v1 uses inconsistent spacings: 16, 17, 22, 24, 38, 46px. No visual rhythm. Brand Guide specifies 8px base grid (--space-1: 8px).

### 15.2 Spacing tokens for WinForms

| Token | Pixels | Use |
|-------|--------|-----|
| `$sp1` | 8 | Minimum gap (label to label) |
| `$sp2` | 16 | Label to input, inner padding |
| `$sp3` | 24 | Between controls in same group |
| `$sp4` | 32 | Between radio options |
| `$sp5` | 40 | Between sections |
| `$sp6` | 48 | Between major blocks |

### 15.3 Corrected vertical layout

```
Title "VIDEO COMPRESSOR":  Y = 40px from top    (was 37 — off-grid)
Separator:                 Y = 80px from top    (was 82 — off-grid)
First control row:         Y = 96px from top    (was 100 — 16px gap from separator)
Label → Input gap:         16px                  (was 16 — ✓ correct)
Row → Row gap:             48px                  (was 46 — off-grid)
Radio → Radio gap:         32px                  (was 24 — too cramped)
Section separator gap:     40px                  (was 38 — off-grid)
Progress bar height:       6px                   (was 3 — too thin, barely visible)
```

### 15.4 Horizontal constants

| Token | Pixels | Use |
|-------|--------|-----|
| Left margin | 24 | All content (existing — ✓ correct) |
| Right margin | 24 | Symmetric (existing — ✓ correct) |
| Content width | 432 | 480 - 24 - 24 (existing — ✓ correct) |
| Button gap | 1 | Between toggle group buttons (was 4 — tighten to read as single component) |

---

## 16. Focus Indicators & Accessibility (NEW)

### 16.1 Problem

Dark theme swallows default Windows focus rectangles. Tab navigation has zero visual feedback. Muted text fails WCAG AA.

### 16.2 Focus ring implementation

For every interactive control (TextBox, Button, ComboBox, Radio):

```powershell
$control.Add_GotFocus({
    $this.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(33, 193, 52)  # #21C134
    $this.FlatAppearance.BorderSize = 2
})
$control.Add_LostFocus({
    $this.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(38, 38, 38)  # #262626
    $this.FlatAppearance.BorderSize = 1
})
```

For TextBox controls (which don't have FlatAppearance):
- Handle `GotFocus` / `LostFocus` by changing the control's `BackColor` to a slightly lighter shade (`#1A1A1A`) on focus, back to `#161616` on blur.

### 16.3 Contrast fixes

| Element | v1 (FAIL) | v2 (PASS) | Ratio on #101010 |
|---------|-----------|-----------|-------------------|
| Muted labels | `#585858` (3.3:1) | `#9a9590` (~6:1) | WCAG AA ✓ |
| Copyright link | `#373737` (1.9:1) | `#4a4845` (~3.5:1) | WCAG AA large ✓ |
| White on green CTA | `#FFFFFF` on `#1CA42C` (3.8:1) | `#FFFFFF` on `#21C134` (~3.5:1) | WCAG AA large text ✓ (11pt bold qualifies) |

### 16.4 Keyboard shortcuts

| Shortcut | Action |
|----------|--------|
| Tab / Shift+Tab | Navigate between controls (standard) |
| Enter | Trigger START (when focused on START button) |
| Escape | Trigger STOP (during compression) |
| Ctrl+O | Open Browse files dialog |

---

## 17. Pre-Implementation — Deep Reference Study (AGENT TASK)

**Before writing the implementation plan, a dedicated research agent must do a thorough study of Shutter Encoder.**

The current spec is based on `settings.xml` dissection and two UI screenshots. That's not enough to fully understand the reference. The agent must:

1. **Find the Shutter Encoder source code** — it's open source on GitHub (`paulpacifico/shutter-encoder`). Fetch the repo or key source files.
2. **Study the full function list** — `settings.xml` shows 78 functions in `comboFonctions`. Catalog all of them, then identify which ones map to what we're building (compression, audio extraction).
3. **Study how SE handles GPU** — find the actual Java code for `comboAccel`, `comboGPUDecoding`, `comboGPUFilter`. Map the exact FFmpeg flags it generates.
4. **Study the audio extraction functions** — how SE maps MP3/AAC/WAV/FLAC selections to FFmpeg args. Bitrate presets, quality flags.
5. **Catalog UI interaction patterns** — how SE's output section works (prefix/suffix/subfolder), how the batch queue functions, what the "Cancel" flow does, how "Open destination at end" is implemented.
6. **Document findings in `docs/shutter-encoder-analysis.md`** with: function→FFmpeg arg mapping table, GPU flag mapping, audio format mapping, UI patterns worth stealing.

This analysis enriches step details in the implementation plan that follows.

---

## 18. Implementation Order (for writing-plans)

Each step is independently testable before moving to the next.

0. **[AGENT] Deep Shutter Encoder reference study** — see Section 14 above. Produces `docs/shutter-encoder-analysis.md`.
1. **Brand corrections** — fix accent color `#1CA42C` → `#21C134`. Add Cormorant Garamond + Raleway font embedding via `PrivateFontCollection`. Fallback to Georgia/Segoe UI if load fails.
2. **IFileOpenDialog Add-Type block** — add C# COM interop at top of script. Exposes `PickFolder(owner)` and `PickFiles(owner, filter)`. Fallback to FolderBrowserDialog on COM failure.
3. **Drop zone UI** — replace old TextBox+Browse row with drop zone Panel (130px, dark, dashed border). Inner ListBox for file list. Counter label. Browse files + Browse folder + Clear buttons. Wire DragEnter/DragDrop for files and folders. Populate `$script:SourceFiles` + `$script:SourceFolderRoot`. Border flashes `#21C134` on valid drag hover.
4. **Mode toggle (video/audio)** — add MODE row: `[ Compress video ]  [ Extract audio ]`. Wire show/hide of resolution/size/format rows vs audio format/bitrate rows. No encoding yet.
5. **Audio extraction encoding** — `Invoke-AudioExtract` function: `-vn -c:a libmp3lame/aac/pcm_s16le -b:a NNNk`. Wire to START button in audio mode. Pre-flight: check audio stream exists.
6. **Advanced panel structure** — collapsible panel with `▼ ADVANCED` toggle. Form height expansion. All controls (GPU, Codec, Scale, Threads, Sound, Open-folder) wired to `$script:` variables. No encoding changes yet.
7. **Sound + open-folder** — add `[System.Media.SystemSounds]::Asterisk.Play()` + `Start-Process explorer.exe` to post-batch block. Gated on checkboxes.
8. **Thread control** — add `-threads $script:Threads` to `Invoke-FFmpeg` args. Default 0.
9. **H.265 codec** — branch in `Compress-Video`: x265 pass flags, `libx265` encoder name. Test single file CPU H.265 encode.
10. **GPU detection** — `Get-AvailableGPUEncoders` on Form_Shown. Parse `ffmpeg -encoders` output. Log detected encoders.
11. **GPU encoding path** — branch in `Compress-Video`: 1-pass GPU per vendor with correct flags (nvenc/amf/qsv). Auto-fallback to CPU on non-zero exit. Re-test same file CPU.
12. **Scale algorithm** — append `:flags=$ScaleAlgo` to the scale vf filter string.
13. **Wire all Advanced → encoding functions** — pass GpuMode, Codec, ScaleAlgo, Threads into `Compress-Video` and `Invoke-AudioExtract`.
14. **Full end-to-end test** — folder mode + file mode + audio mode + GPU mode + H.265 + Advanced panel open. Fix regressions.
15. **Compile EXE + push to GitHub** — `ps2exe.ps1`, verify EXE on clean machine (no FFmpeg). Push to `https://github.com/Cameraptor/Chucha-Video-Compressor`.
