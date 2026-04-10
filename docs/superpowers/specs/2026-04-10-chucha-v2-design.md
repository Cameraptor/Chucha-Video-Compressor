# Chucha Video Compressor — v2 Enhancement Spec
**Date:** 2026-04-10  
**Reference app:** Shutter Encoder v20.0 (settings.xml + UI screenshots)  
**Constraint:** Stay a simple single-EXE PowerShell + WinForms utility. No video preview. No menus. No NLE features.

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
- Height: 130px when showing 1–3 file names; fixed height with vertical scroll on overflow
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
- `DragEnter`: if contains FileDrop data → `DragDropEffects.Copy`, panel border flashes to accent color `#1CA42C`
- `DragLeave` / `DragDrop`: border returns to `#2A2A2A`

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

## 14. Implementation Order (for writing-plans)

Each step is independently testable before moving to the next.

1. **IFileOpenDialog Add-Type block** — add C# COM interop at top of script. Test PickFolder and PickFiles return correct paths. Fallback to FolderBrowserDialog on failure.
2. **Drop zone UI** — replace TextBox+Browse with drop zone Panel + inner ListBox + counter label + Browse files/folder buttons. Wire Browse buttons to IFileOpenDialog. Wire DragEnter/DragDrop. Populate `$script:SourceFiles`. No encoding changes yet.
3. **Mode toggle (video/audio)** — add MODE radio group. Wire show/hide of settings rows (resolution, size, format vs audio format, bitrate). No encoding yet.
4. **Audio extraction encoding** — `Invoke-AudioExtract` function using `-vn -c:a libmp3lame/aac/pcm_s16le`. Wire to START button when in audio mode.
5. **Advanced panel structure** — collapsible panel below settings, form resize logic. Wire all controls to `$script:` variables. No encoding changes yet.
6. **Sound + open-folder** — post-batch block additions. Two lines. Test with a real encode.
7. **Thread control** — add `-threads $Threads` to `Invoke-FFmpeg`. Default 0. Test with threads=4.
8. **H.265 codec** — branch in `Compress-Video` for x265 pass flags + `libx265` encoder name. Test single file H.265 CPU encode.
9. **GPU detection** — `Get-AvailableGPUEncoders` function on Form_Shown. Populates `$script:AvailableGPUEncoders`. Logs findings.
10. **GPU encoding path** — branch in `Compress-Video` for 1-pass GPU encode per vendor, fallback on non-zero exit. Test with available GPU.
11. **Scale algorithm** — `:flags=ALGO` appended to scale filter string from Advanced combo.
12. **Wire all Advanced → Compress-Video params** — pass GpuMode, Codec, ScaleAlgo, Threads through to encoding functions.
13. **Full end-to-end test** — folder mode + file mode + audio mode + GPU mode + H.265 + Advanced open. Fix any regressions.
14. **Compile EXE** — run `ps2exe.ps1`, verify EXE launches, test on clean machine without FFmpeg (auto-install path).
