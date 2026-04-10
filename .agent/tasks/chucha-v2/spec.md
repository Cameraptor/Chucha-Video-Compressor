# Task Spec: chucha-v2

## Metadata
- Task ID: chucha-v2
- Created: 2026-04-10T12:28:35+00:00
- Frozen: 2026-04-10T12:35:00+00:00
- Repo root: D:\Work\Assets\Projects\Business\CAMERAPTOR\Dev_Projects\Chucha_Video_Compressor
- Working directory at init: D:\Work\Assets\Projects\Business\CAMERAPTOR\Dev_Projects\Chucha_Video_Compressor

## Guidance sources
- CLAUDE.md
- AGENTS.md
- docs/CODING_STANDARDS.md
- docs/ARCHITECTURE.md
- docs/superpowers/specs/2026-04-10-chucha-v2-design.md
- docs/superpowers/plans/2026-04-10-chucha-v2-design.md
- docs/shutter-encoder-analysis.md

## Original task statement

Implement all 15 v2 feature tasks for Chucha Video Compressor in `VideoCompressor.ps1`. The app is a single-file PowerShell WinForms desktop utility for batch video compression via 2-pass FFmpeg. V2 adds: brand color correction, embedded fonts, modern file picker, drag-and-drop zone, audio extraction mode, GPU-accelerated encoding, H.265 codec, and a collapsible advanced settings panel. All changes stay in the single file. Brand: CAMERAPTOR — green #21C134, dark #101010, light text #F2E2E2.

## Acceptance criteria

- AC1: Brand accent green is `FromArgb(33, 193, 52)` (#21C134), not the old #1CA42C. Muted text is `FromArgb(154, 149, 144)` (#9A9590), not the old #585858. All hover/pressed states derive from #21C134. Copyright link uses #4A4845 dim text.
- AC2: DPI awareness is enabled via `SetProcessDPIAware()` call at script top, before any WinForms loading.
- AC3: Cormorant Garamond (title) and Raleway (UI) fonts are embedded as Base64-encoded TTF strings, decoded to `%TEMP%\chucha_*.ttf` at startup via `PrivateFontCollection`. Silent fallback to Georgia/Segoe UI if loading fails. Temp font files cleaned up on form close.
- AC4: `IFileOpenDialog` COM interop is available via `Add-Type` C# block. `Show-FolderPicker` and `Show-FilePicker` functions exist with fallback to classic `FolderBrowserDialog`/`OpenFileDialog` if COM fails.
- AC5: Drop zone panel exists (130px+ dark panel with dashed border at #2A2A2A). Contains a `ListBox` for file names and a placeholder label "Drop files or folder here" when empty. Browse files, Browse folder, and Clear buttons above the panel. File counter label shows count.
- AC6: Drag-and-drop works on both the drop zone panel and the form. Single folder drop scans recursively for video files. Multiple file drop filters by video extensions. `$script:SourceFiles` array is the single source of truth for files to process.
- AC7: Mode toggle exists with "Compress video" and "Extract audio" radio buttons. Switching modes shows/hides the appropriate settings panel (video settings vs audio settings). Audio settings panel has format (MP3/AAC/WAV) and bitrate (128/192/320 kbps) radio buttons.
- AC8: `Invoke-AudioExtract` function exists. Extracts audio via FFmpeg with correct codec per format (libmp3lame/aac/pcm_s16le). Checks for audio stream presence via ffprobe before extraction. START handler branches on `$script:Mode` to call either `Compress-Video` or `Invoke-AudioExtract`.
- AC9: Collapsible Advanced panel exists with toggle button. Contains: GPU acceleration dropdown (Auto/CPU/NVIDIA/AMD/Intel), codec radio buttons (H.264/H.265), scale algorithm dropdown (bicubic/lanczos/bilinear), thread count input, "Play sound when done" checkbox, "Open output folder when done" checkbox. Form height adjusts on expand/collapse. Screen height guard prevents expanding beyond screen.
- AC10: Thread control works — `Invoke-FFmpeg` accepts `-Threads` parameter, prepends `-threads N` to FFmpeg args when non-zero. Both `Compress-Video` and `Invoke-AudioExtract` pass threads through.
- AC11: H.265 (HEVC) codec support via `libx265` with correct x265-specific two-pass flags (`-x265-params pass=1/2:stats=...`). Encoder selection branches on `$script:Codec`. START handler passes codec to `Compress-Video`.
- AC12: GPU encoder detection runs on startup via `Get-AvailableGPUEncoders` (checks FFmpeg `-encoders` output for h264_nvenc, h264_amf, h264_qsv). Results logged. `Resolve-GpuMode` resolves "Auto" to first available GPU or CPU fallback.
- AC13: GPU encoding path in `Compress-Video` uses single-pass encoding with vendor-specific rate control flags (NVIDIA: b_ref_mode+maxrate+bufsize, AMD: rc=cbr). GPU failure falls back to CPU 2-pass. Correct encoder names per vendor and codec (h264_nvenc/hevc_nvenc, h264_amf/hevc_amf, h264_qsv/hevc_qsv).
- AC14: Scale algorithm selection is passed through to FFmpeg scale filter as `:flags=$ScaleAlgo`.
- AC15: Post-batch actions work: system sound plays if checkbox checked, output folder opens in Explorer if checkbox checked. Neither fires on cancel.
- AC16: The script launches without errors, form renders correctly, all existing v1 compression functionality still works (2-pass x264 to target file size).
- AC17: All vertical spacings are multiples of 8px. `$lastY` / `$y` accumulator pattern used for positioning.
- AC18: VideoCompressor.ps1 stays under 2000 lines. All code remains in the single file.

## Constraints

- Single-file architecture: all changes in `VideoCompressor.ps1`
- PowerShell 5.1+ / WinForms (.NET Framework) only
- Brand colors only — no ad hoc hex values outside the defined palette
- Font embedding uses TTF (not WOFF2) — `PrivateFontCollection` requires TTF/OTF
- `-preset slow` for CPU encoding (never ultrafast)
- 0.92 overhead factor and 96kbps audio budget for bitrate calculation unchanged
- Scale filter must handle both landscape and portrait via `if(gte(iw,ih))` conditional
- No `Write-Host` — use `Write-Log` function
- Always use `$script:ffmpegPath`, never bare `ffmpeg`
- `Add-Type` C# blocks must compile on PowerShell 5.1 (.NET Framework)
- 8px vertical grid for all spacing
- Focus indicators on interactive controls (GotFocus/LostFocus with green border) — apply as new controls are created
- DPI awareness before any UI code

## Non-goals

- macOS parity (`chucha-compress.command` not modified in this task)
- Pester test suite (future phase)
- Server deployment or CI/CD
- Variable font embedding (only specific weights)
- Batch queue / priority system
- Video preview or thumbnail generation
- Settings persistence / config file
- Auto-update mechanism
- Compiling to EXE (Task 15 is compile + push, but the EXE binary is not an AC for code correctness)

## Verification plan
- Build: `powershell -ExecutionPolicy Bypass -File VideoCompressor.ps1` — script loads without errors, form renders
- Unit tests: N/A (no Pester tests yet)
- Integration tests: Manual — compress a short video file, extract audio, test GPU if available
- Lint: PowerShell syntax check via `powershell -Command "& { $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content VideoCompressor.ps1 -Raw), [ref]$null) }"`
- Manual checks:
  - Colors match brand palette (visual inspection)
  - Drop zone accepts files and folders via drag-drop and browse
  - Mode toggle shows/hides correct panels
  - Advanced panel expands/collapses form
  - H.265 produces valid HEVC output (ffprobe check)
  - GPU detection logs results on startup
  - Post-batch sound and folder-open work when enabled
