# Coding Standards — Chucha Video Compressor

> All agents must read this before writing code.

---

## File Organization

| Rule | Detail |
|------|--------|
| Max file size | VideoCompressor.ps1 may reach ~1800 lines for v2. Warn at 2000. |
| Section headers | Every logical section starts with `# --- SECTION NAME ---` comment block |
| Single file | All Windows app code stays in VideoCompressor.ps1 unless >2000 lines |
| macOS parity | chucha-compress.command mirrors core features but uses bash/osascript |

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Functions | PascalCase (Verb-Noun) | `Write-Log`, `Get-VideoFiles`, `Invoke-FFmpeg` |
| Variables | camelCase with `$` | `$maxSizeMB`, `$outputPath` |
| Script-scope vars | `$script:` prefix | `$script:ffmpegPath`, `$script:running` |
| UI controls | `$` + descriptive name | `$btnStart`, `$txtStatus`, `$lblHeader` |
| Constants | UPPER_SNAKE in comments, camelCase in code | `$defaultMaxSize = 8` |

---

## Brand Color Palette (CAMERAPTOR Brand Guide)

**Only these colors in the app. No extras. No ad hoc hex values.**

```powershell
# Primary palette — from BRAND.md
$clrBg      = [Drawing.Color]::FromArgb(16,  16,  16)   # #101010  Base DARK
$clrInput   = [Drawing.Color]::FromArgb(22,  22,  22)   # #161616  Input fields
$clrBorder  = [Drawing.Color]::FromArgb(38,  38,  38)   # #262626  Base MID
$clrAccent  = [Drawing.Color]::FromArgb(33,  193, 52)   # #21C134  Raptor GREEN
$clrText    = [Drawing.Color]::FromArgb(242, 226, 226)  # #e7e7e7  Base LIGHT
$clrMuted   = [Drawing.Color]::FromArgb(154, 149, 144)  # #9a9590  Brand warm gray
$clrDim     = [Drawing.Color]::FromArgb(74,  72,  69)   # #4a4845  Brand dim text

# Derived interactive states (from Raptor Green)
$clrHover   = [Drawing.Color]::FromArgb(42,  212, 63)   # #2AD43F  (+15% lum)
$clrPressed = [Drawing.Color]::FromArgb(26,  154, 42)   # #1A9A2A  (-20% lum)

# Functional (app-specific, documented in spec)
$clrDanger  = [Drawing.Color]::FromArgb(180, 40,  40)   # #B42828  Stop/error
```

## Brand Typography (embed TTF, NOT WOFF2)

```powershell
$fontTitle  = "Cormorant Garamond" 20pt SemiBold (600)  # or fallback: Georgia
$fontBrand  = "Raleway" 9pt Regular (400)                # or fallback: Segoe UI
$fontLabel  = "Raleway" 8pt Medium (500), ALL CAPS       # or fallback: Segoe UI
$fontUI     = "Raleway" 9.5pt Regular (400)              # or fallback: Segoe UI
$fontBtn    = "Raleway" 11pt Medium (500)                # or fallback: Segoe UI
$fontMono   = "DM Mono" / Consolas 8.5pt Regular
$fontCopy   = "Raleway" 7.5pt Regular (400)
```

## 8px Vertical Grid (Brand Guide: --space-1: 8px)

All vertical spacings = multiples of 8: 8, 16, 24, 32, 40, 48px. No exceptions.

---

## PowerShell-Specific Rules

### WinForms UI

- All UI construction in a single sequential block — define controls top to bottom
- Use `$lastY` accumulator pattern for vertical positioning (8px grid steps only)
- Colors defined as `[System.Drawing.Color]::FromArgb(R,G,B)` — no hex strings
- Font objects created once from PrivateFontCollection, reused across controls
- Event handlers use `$control.Add_Click({ ... })` pattern
- Focus indicators: every interactive control gets GotFocus/LostFocus with Raptor Green border

### FFmpeg Calls

- Always use `& $script:ffmpegPath` (never bare `ffmpeg`)
- 2-pass encoding: pass 1 uses `-f null NUL`, pass 2 writes output
- Bitrate calculated as: `(targetMB * 0.92 * 8192) / duration - audioBitrate`
- Scale filter: `-vf "scale=if(gte(iw,ih),RES,-2):if(gte(iw,ih),-2,RES)"`

### Error Handling

- NEVER swallow exceptions silently — log via `Write-Log`
- User-facing errors: show in status TextBox, never raw stack traces
- FFmpeg errors: parse stderr for meaningful message, show to user
- File operations: always check `Test-Path` before reading

### Functions / Methods

- Max function length: ~80 lines (PowerShell functions tend to be longer than other languages)
- Helper functions defined BEFORE the UI construction block
- No global state except `$script:`-scoped variables

---

## Anti-Patterns

- NEVER use `Write-Host` in the app — it goes to console, not the GUI log
- NEVER hardcode file paths — use `$env:TEMP`, `$env:LOCALAPPDATA`, folder browser
- NEVER commit commented-out code — delete it (git history preserves it)
- NEVER add `Start-Sleep` in the UI thread — it freezes the form
- NEVER use `Invoke-Expression` — security risk and debugging nightmare

---

**Last Updated:** 2026-04-10
