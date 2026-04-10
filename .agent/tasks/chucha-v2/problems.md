# Problems: chucha-v2

3 of 18 acceptance criteria are not PASS.

---

### AC1: Brand accent green is FromArgb(33,193,52) (#21C134), not the old #1CA42C. Muted text is FromArgb(154,149,144) (#9A9590). All hover/pressed states derive from #21C134. Copyright link uses #4A4845 dim text.

- Status: FAIL
- Why it is not proven: The copyright dim color ($clrDim) is defined as FromArgb(120, 118, 115) at line 725, not FromArgb(74, 72, 69) which is the #4A4845 specified by the AC. The comment says "Brighter dim text for better contrast" indicating it was intentionally changed away from the spec value.
- Minimal reproduction steps: Read line 725 of VideoCompressor.ps1. Convert RGB(120,118,115) to hex = #787673, not #4A4845.
- Expected: `$clrDim = [Drawing.Color]::FromArgb(74, 72, 69)` (#4A4845)
- Actual: `$clrDim = [Drawing.Color]::FromArgb(120, 118, 115)` (#787673)
- Affected files: VideoCompressor.ps1 line 725
- Smallest safe fix: Change `FromArgb(120, 118, 115)` to `FromArgb(74, 72, 69)` on line 725.
- Corrective hint: Replace the RGB values in $clrDim to match the brand-specified #4A4845 (74, 72, 69). The "brighter for contrast" rationale does not override the spec requirement.

---

### AC2: DPI awareness is enabled via SetProcessDPIAware() call at script top, before any WinForms loading.

- Status: FAIL
- Why it is not proven: The SetProcessDPIAware() call is commented out on lines 2-3 of VideoCompressor.ps1. The comment reads "Disabled to allow native OS bitmap scaling on High-DPI screens." This means DPI awareness is NOT enabled.
- Minimal reproduction steps: Read lines 1-3 of VideoCompressor.ps1. Both the Add-Type and the try/catch calling SetProcessDPIAware() are prefixed with `#`.
- Expected: Active (uncommented) `Add-Type` defining DpiAware class and `[DpiAware]::SetProcessDPIAware()` call before line 5 (`Add-Type -AssemblyName System.Windows.Forms`).
- Actual: Both lines are commented out with `#`.
- Affected files: VideoCompressor.ps1 lines 2-3
- Smallest safe fix: Uncomment lines 2 and 3, removing the leading `# ` from each line.
- Corrective hint: Remove the comment markers from lines 2-3 to restore the DPI awareness call. The AC explicitly requires SetProcessDPIAware() to be active before WinForms loading.

---

### AC17: All vertical spacings are multiples of 8px. $lastY / $y accumulator pattern used for positioning.

- Status: FAIL
- Why it is not proven: Multiple `$y += N` increments use values that are not multiples of 8. Specifically: 12 (line 1382), 22 (lines 842, 1044, 1217, 1226), 38 (line 1062), 58 (line 1355), 138 (line 1337), 152 (line 1034), 158 (line 1406). Only 8, 24, 32, 40 are clean multiples of 8.
- Minimal reproduction steps: Run `grep -oE '\$y\s*\+=\s*[0-9]+' VideoCompressor.ps1 | grep -oE '[0-9]+$' | sort -n | uniq` and check which values are divisible by 8.
- Expected: All y-increment values divisible by 8 (e.g., 8, 16, 24, 32, 40, 48, 56, 64, 128, 136, 144, 152, 160).
- Actual: Values 12, 22, 38, 58, 138, 158 are not divisible by 8. (Note: 152 IS divisible by 8, 24 and 32 and 40 are correct.)
- Affected files: VideoCompressor.ps1 lines 842, 1034, 1044, 1062, 1217, 1226, 1337, 1355, 1382, 1406
- Smallest safe fix: Adjust each non-8px-multiple spacing to the nearest 8px multiple: 12->16, 22->24, 38->40, 58->56, 138->136, 158->160. Then visually test the form layout.
- Corrective hint: Round each y-increment to the nearest multiple of 8. Some increments (like 22) may need neighboring controls adjusted too. Test the form after changes to ensure nothing overlaps.
