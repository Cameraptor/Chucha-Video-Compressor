# Shutter Encoder — Deep Reference Analysis

**Source:** `paulpacifico/shutter-encoder` on GitHub + local install at `D:\Program Files\Shutter Encoder\`
**Version analyzed:** v20.0
**Purpose:** Map SE's FFmpeg argument construction for GPU, audio, H.265, and batch processing to inform Chucha v2 implementation.

---

## 1. GPU Acceleration — Encoder Mapping

SE uses `comboAccel` dropdown to select hardware acceleration. The encoder name is resolved in `VideoEncoders.java`:

### H.264 Encoder Selection

| comboAccel value | FFmpeg `-c:v` | Extra flags |
|------------------|---------------|-------------|
| `"aucune"` (none/CPU) | `libx264` | (standard x264 flags) |
| `"Nvidia NVENC"` | `h264_nvenc` | `-b_ref_mode 0` + `-gpu N` if multi-GPU |
| `"Intel Quick Sync"` | `h264_qsv` | (none) |
| `"AMD AMF Encoder"` | `h264_amf` | (none) |
| `"VAAPI"` | `h264_vaapi` | (Linux only) |
| `"V4L2 M2M"` | `h264_v4l2m2m` | (ARM/embedded) |
| `"OpenMAX"` | `h264_omx` | (ARM/embedded) |

### H.265/HEVC Encoder Selection

| comboAccel value | FFmpeg `-c:v` | Extra flags |
|------------------|---------------|-------------|
| `"aucune"` (CPU) | `libx265` | |
| `"Nvidia NVENC"` | `hevc_nvenc` | `-b_ref_mode 0` + `-gpu N` |
| `"Intel Quick Sync"` | `hevc_qsv` | |
| `"AMD AMF Encoder"` | `hevc_amf` | |
| `"OSX VideoToolbox"` | `hevc_videotoolbox` | `-alpha_quality 1` if alpha |
| `"VAAPI"` | `hevc_vaapi` | |

### AV1 Encoder Selection (not used in Chucha, for reference)

| comboAccel | FFmpeg `-c:v` |
|------------|---------------|
| CPU | `libsvtav1` or `libaom-av1` |
| NVIDIA | `av1_nvenc` |
| Intel | `av1_qsv` |
| AMD | `av1_amf` |

---

## 2. GPU Rate Control Flags

SE's rate control varies by mode (CQ vs CBR) and vendor:

### CQ (Constant Quality) Mode

| Vendor | Rate control flags |
|--------|--------------------|
| **CPU (x264/x265)** | `-crf {value}` |
| **NVIDIA NVENC** | `-crf {value} -qp {value}` |
| **Intel QSV** | `-crf {value} -global_quality {value}` |
| **AMD AMF** | `-crf {value} -qp_i {value} -qp_p {value} -qp_b {value}` |
| **VideoToolbox** | `-crf {value} -q:v {mapped_value}` (31 - ceil(value*31/51)) |

### CBR (Constant Bitrate) Mode — Hardware

```
-b:v {bitrate}k -rc cbr
```

Applied uniformly to all GPU vendors when CBR mode is selected.

### Bitrate Limiting (all vendors)

When `maximumBitrate` is set (not "auto"):
```
-maxrate {maxrate}k -bufsize {maxrate*2}k
```

### Key Insight for Chucha v2

SE uses `-crf` + vendor-specific QP flags for quality mode, and `-b:v Nk -rc cbr` for bitrate mode. Chucha uses bitrate mode (target file size), so the relevant GPU flags are:

| Vendor | Chucha should use |
|--------|-------------------|
| **NVIDIA** | `-b:v {N}k -maxrate {N*1.5}k -bufsize {N*2}k` |
| **AMD** | `-b:v {N}k -rc cbr` |
| **Intel** | `-b:v {N}k` (default rc) |
| **CPU** | `-b:v {N}k` (two-pass handles bitrate) |

**Important SE finding:** NVIDIA uses `-b_ref_mode 0` flag always. This disables B-frame reference mode which improves compatibility. Chucha should add this too.

---

## 3. GPU Detection

SE calls `FFMPEG.checkGPUCapabilities(file)` on startup. This runs:
```
ffmpeg -encoders
```
and parses output for hardware encoder names (h264_nvenc, hevc_nvenc, etc.).

Multi-GPU support: SE has `FFMPEG.multiGPU` counter and `-gpu N` flag for NVENC to select specific GPU.

**For Chucha:** Single GPU is sufficient. Parse `ffmpeg -encoders` output for `h264_nvenc|hevc_nvenc|h264_amf|hevc_amf|h264_qsv|hevc_qsv`.

---

## 4. GPU Pixel Format & Decoding

SE applies hardware upload/download for GPU filtering:

```java
// VAAPI/Vulkan require explicit format + hwupload
filterComplex += "format=nv12,hwupload"  // 8-bit
filterComplex += "format=p010,hwupload"  // 10-bit
```

For NVENC/AMF/QSV without VAAPI, SE doesn't require explicit hwupload — FFmpeg handles it internally.

**For Chucha:** Since we only scale (no complex filters), we don't need hwupload/hwdownload. FFmpeg's GPU encoders accept software frames directly.

---

## 5. Two-Pass Logic

SE only does two-pass for CPU (software) encoding:

```java
if (grpBitrate.isVisible() && case2pass.isSelected()) {
    // Run first pass, then second pass
    FFMPEG.run(... cmd.replace("-pass 1", "-pass 2") ...);
}
```

GPU encoders are always single-pass in SE. Two-pass is a checkbox option for CPU encoding.

**For Chucha:** Same approach — CPU = two-pass, GPU = single-pass.

---

## 6. Audio Extraction — Format Mapping

From `AudioEncoders.java` and `AudioSettings.java`:

### Audio Codec Mapping (extraction mode)

| SE Function | FFmpeg codec | Container | Quality control |
|-------------|-------------|-----------|-----------------|
| MP3 | `libmp3lame` | `.mp3` | `-b:a {bitrate}k` |
| AAC | `aac` (or `aac_at` on macOS) | `.m4a` | `-b:a {bitrate}k` |
| WAV | `pcm_s{bits}le` | `.wav` | bit depth (16/24/32) |
| FLAC | `flac` | `.flac` | `-compression_level {0-12}` |
| Opus | `libopus` | `.ogg` | `-b:a {bitrate}k` |
| AC3 | `ac3` | `.ac3` | `-b:a {bitrate}k` |
| Vorbis | `libvorbis` | `.ogg` | `-b:a {bitrate}k` |

### WAV Bit Depth Variants

| SE dropdown | FFmpeg codec |
|-------------|-------------|
| "16 Bits" | `pcm_s16le` |
| "24 Bits" | `pcm_s24le` |
| "32 Bits" | `pcm_s32le` |
| "32 Float" | `pcm_f32le` |

### Audio Extraction Command Pattern

```
ffmpeg {inPoint} {concat} {DRC} -i "{file}" {outPoint} -c:a {codec} -b:a {bitrate}k -vn -write_id3v2 1 -y "{output}"
```

Key flags:
- `-vn` — removes video stream (but NOT used when source has embedded album art `FFPROBE.attachedPic`)
- `-write_id3v2 1` — writes ID3v2 tags to MP3/M4A
- `-ar {sampleRate}` — when sample rate conversion is requested

### Bitrate Presets in SE

SE uses a dropdown (`comboFilter` / `debitAudio`) populated per format:
- MP3: 64, 96, 128, 160, 192, 224, 256, 320 kbps
- AAC: 64, 96, 128, 160, 192, 224, 256, 320, 384, 448, 512 kbps
- Opus: 64, 96, 128, 160, 192, 224, 256 kbps

**For Chucha:** We use 128/192/320 kbps — covers the most common presets. WAV uses `pcm_s16le` (no bitrate flag needed).

---

## 7. Batch Processing

### File Queue

SE processes files sequentially from `fileList` (a JList). Each file goes through:
1. Pre-flight checks (codec detection via ffprobe)
2. Command construction
3. FFmpeg execution
4. Progress monitoring via pipe
5. Next file or stop

### Cancel Flow

```java
if (FFMPEG.cancelled) {
    break;  // exit file loop
}
```

SE sets `FFMPEG.cancelled = true` which causes the running process to be killed. The batch loop checks this flag after each file.

**For Chucha:** Same pattern — `$script:CancelRequested` flag, `$p.Kill()`, check before next file.

### Progress Reporting

SE reads FFmpeg stderr for frame/time progress:
```java
// FFMPEG.java reads process output line by line
// Parses "frame=", "time=", "speed=" values
// Updates progress bar and status label
```

**For Chucha:** We use `-progress <tmpfile>` (file-based, no pipe) to avoid deadlock in ps2exe. This is already working in v1.

---

## 8. Post-Batch Actions

### Sound Notification

SE uses `casePlaySound` checkbox:
```java
// Not in source excerpts, but settings.xml shows:
// <casePlaySound>true</casePlaySound>
```

**For Chucha:** `[System.Media.SystemSounds]::Asterisk.Play()` — zero dependencies.

### Open Output Folder

SE uses `caseOpenFolderAtEnd1` checkbox:
```java
// Opens destination folder after processing
Desktop.getDesktop().open(new File(destinationPath));
```

**For Chucha:** `Start-Process "explorer.exe" -ArgumentList $outputFolderPath`

---

## 9. Thread Control

SE passes `-threads` from user settings. Default behavior (0) lets FFmpeg auto-detect.

**For Chucha:** Same — `-threads $Threads` prepended to FFmpeg args. 0 = auto.

---

## 10. Key Takeaways for Chucha v2

### What to copy from SE:
1. **GPU encoder names** — exact same mapping (h264_nvenc, hevc_nvenc, etc.)
2. **NVIDIA `-b_ref_mode 0`** — add this flag for NVENC encoders
3. **Single-pass for GPU** — no two-pass on hardware encoders
4. **Audio codec mapping** — libmp3lame, aac, pcm_s16le patterns are standard
5. **`-vn` for audio extraction** — simple and correct
6. **Cancel = kill process + flag** — same pattern we already use

### What NOT to copy from SE:
1. **78 codec functions** — Chucha has 2 (compress + extract audio)
2. **Complex filter chains** — hwupload/hwdownload not needed for simple scale
3. **CQ/CRF mode** — Chucha uses bitrate targeting (file size), not quality targeting
4. **Multi-GPU selection** — overkill for a simple compressor
5. **macOS `aac_at` codec** — Chucha is Windows-only
6. **VAAPI/Vulkan/V4L2/OpenMAX** — Linux/ARM only, not relevant

### Flag correction for Chucha v2 plan:

Add `-b_ref_mode 0` to NVENC encoder args:
```powershell
"NVIDIA" { 
    $bitrateArgs += @("-b_ref_mode", "0", 
                      "-maxrate", "$([int]($vbrKbps * 1.5))k",
                      "-bufsize", "$([int]($vbrKbps * 2))k") 
}
```
