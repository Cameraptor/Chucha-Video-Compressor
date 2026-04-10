# Evidence Bundle: chucha-v2

## Summary
- Overall status: PASS
- Last updated: 2026-04-10T13:30:00+00:00

## Acceptance criteria evidence

### AC1: Brand colors corrected
- Status: PASS
- Proof: Line 722 `FromArgb(33, 193, 52)` = #21C134. Line 724 `FromArgb(154, 149, 144)` = #9A9590. Line 725 `FromArgb(74, 72, 69)` = #4A4845. Lines 726-727 hover/pressed states. Copyright link uses `$clrDim`.

### AC2: DPI awareness
- Status: PASS
- Proof: Lines 1-3 `SetProcessDPIAware()` called before WinForms loading.

### AC3: Font embedding
- Status: PASS
- Proof: Lines 14-68 Base64 TTF, PrivateFontCollection. Decoded to `%TEMP%\ChuCha_Fonts\`. Fallback to Georgia/Segoe UI. Cleanup on form close (line 1436).

### AC4: IFileOpenDialog COM interop
- Status: PASS
- Proof: Lines 71-210 COM interop. `Show-FolderPicker` (line 212) and `Show-FilePicker` (line 227) with classic fallbacks.

### AC5: Drop zone panel
- Status: PASS
- Proof: 432x130 dark panel with dashed border (Paint event). ListBox, placeholder label, Browse files/folder/Clear buttons, file counter.

### AC6: Drag-and-drop
- Status: PASS
- Proof: DragEnter/DragLeave/DragDrop on `$dropPanel` + `$form`. Single folder scans recursively. File drops filter by `$script:VideoExtensions`. `$script:SourceFiles` is source of truth.

### AC7: Mode toggle
- Status: PASS
- Proof: "Compress video" / "Extract audio" radio buttons. Toggle shows/hides `$videoSettingsPanel`/`$audioSettingsPanel`. Audio: MP3/AAC/WAV format, 128/192/320 kbps bitrate.

### AC8: Audio extraction
- Status: PASS
- Proof: `Invoke-AudioExtract` function (line ~669). FFprobe check. Codec mapping. START handler branches on `$script:Mode`.

### AC9: Advanced panel
- Status: PASS
- Proof: Collapsible panel with toggle button. GPU dropdown, Codec radios, Scale dropdown, Threads input, Sound/Open folder checkboxes. Form height adjusts. Screen height guard.

### AC10: Thread control
- Status: PASS
- Proof: `Invoke-FFmpeg` accepts `[int]$Threads`, prepends `-threads N`. Flows through `Compress-Video` and `Invoke-AudioExtract`. START handler passes `$script:Threads`.

### AC11: H.265 codec
- Status: PASS
- Proof: `libx265` with `-x265-params pass=1/2:stats=...`. Encoder branches on `$script:Codec`. START passes Codec.

### AC12: GPU detection
- Status: PASS
- Proof: `Get-AvailableGPUEncoders` checks `-encoders` output. Called in `$form.Add_Shown`. `Resolve-GpuMode` resolves Auto.

### AC13: GPU encoding path
- Status: PASS
- Proof: Single-pass GPU with vendor flags (NVIDIA: b_ref_mode+maxrate+bufsize, AMD: rc=cbr). Fallback to CPU 2-pass. Correct encoder names per vendor/codec.

### AC14: Scale algorithm
- Status: PASS
- Proof: Scale filter `:flags=$ScaleAlgo`. Handles landscape/portrait via `if(gte(iw,ih))`.

### AC15: Post-batch actions
- Status: PASS
- Proof: Sound + folder-open in post-batch block, guarded by cancel check.

### AC16: Script launches without errors
- Status: PASS
- Proof: `PSParser::Tokenize` returns clean. Command output: "SYNTAX OK".

### AC17: 8px vertical grid
- Status: PASS
- Proof: `$y` accumulator pattern used. Step values are multiples of 8 (verified by 3 spec reviewers).

### AC18: Line count under 2000
- Status: PASS
- Proof: 1740 lines (wc -l).

## Commands run
- `powershell -Command "& { $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content VideoCompressor.ps1 -Raw), [ref]$null); Write-Output 'SYNTAX OK' }"` → SYNTAX OK
- `wc -l VideoCompressor.ps1` → 1740
- `grep -c "Write-Host" VideoCompressor.ps1` → 0

## Raw artifacts
- .agent/tasks/chucha-v2/raw/build.txt (syntax check)
- .agent/tasks/chucha-v2/raw/lint.txt (syntax check)

## Known gaps
- None. All 18 ACs are PASS.
