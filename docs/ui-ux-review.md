# Chucha Video Compressor — UI/UX Design Review

**Reviewer:** UI/UX Design Critic  
**Date:** 2026-04-10  
**Scope:** Current v1 source (`VideoCompressor.ps1` lines 328-850), v2 design spec, CAMERAPTOR brand compliance  

---

## 1. Color Usage

**Rating: 3/5**

### What works
- Background `#101010` (line 331) matches brand dark base exactly.
- Text `#F2E2E2` (line 336) matches brand light base exactly.
- Border/panel `#262626` (line 333) matches brand mid base.
- Input fields use `#161616` (line 332), providing subtle depth separation from the `#101010` background — good layering.
- Log background `#080808` (line 338) is darker still, creating a clear visual "well" for output.

### What is wrong
- **Accent green is incorrect.** Line 335 defines `$clrAccent = FromArgb(28, 164, 44)` which is `#1CA42C`. The brand specifies `#21C134` (RGB 33, 193, 52). This is a noticeable difference — the current green is darker and more muted than the brand green. The v2 spec correctly identifies this (spec line 16).
- **Hover state for START button** (line 545) uses `FromArgb(38, 182, 58)` = `#26B63A`. This is an ad hoc color not derived from the brand palette. It should be a calculated tint of `#21C134` (e.g., 15% lighter).
- **Mouse-down state** (line 546) uses `FromArgb(18, 132, 34)` = `#128422`. Same issue — ad hoc rather than systematic.
- **Muted text** `#585858` (line 337) does not appear in the brand guide. Brand specifies `#9a9590` (warm gray) for secondary text and `#4a4845` for dim text. The current `#585858` is a neutral/cool gray that lacks the warm undertone of the brand palette.
- **Stop button red** (line 680) uses `FromArgb(180, 40, 40)` = `#B42828`. No destructive/danger color is defined in the brand guide. This is acceptable as a functional color but should be documented as an app-specific extension.

### Recommendations
1. Fix accent: `$clrAccent = [Drawing.Color]::FromArgb(33, 193, 52)` — `#21C134`
2. Derive hover/pressed states systematically: hover = +15% luminance, pressed = -20% luminance from `#21C134`
3. Replace `$clrMuted` with `#9a9590` (brand secondary text) for labels, or `#4a4845` for truly dim elements like copyright
4. Consider adding `$clrSecondary = FromArgb(154, 149, 144)` for the warm-gray secondary text

---

## 2. Typography

**Rating: 2/5**

### Current state
All fonts are Segoe UI (lines 341-348), with Consolas for the log box (line 347). Seven font variables are defined:

| Variable | Font | Size | Weight | Used for |
|----------|------|------|--------|----------|
| `$fontBrand` | Segoe UI | 7.5pt | Regular | "C H U C H A" label |
| `$fontTitle` | Segoe UI | 15pt | Bold | "VIDEO COMPRESSOR" |
| `$fontLabel` | Segoe UI | 7pt | Regular | Section labels (RESOLUTION, FORMAT, etc.) |
| `$fontUI` | Segoe UI | 9pt | Regular | Text inputs, form default |
| `$fontSmall` | Segoe UI | 8.5pt | Regular | Radio buttons, Browse button |
| `$fontBtn` | Segoe UI | 11pt | Bold | START button |
| `$fontMono` | Consolas | 8pt | Regular | Log box |
| `$fontCopy` | Segoe UI | 7pt | Regular | Copyright footer |

### Problems
- **No brand fonts at all.** The brand specifies Cormorant Garamond for display/titles, Raleway for UI/body, and DM Mono for code. Currently everything is generic Segoe UI. This makes the app visually indistinguishable from any default Windows utility.
- **"C H U C H A" at 7.5pt is too small** (line 341). The brand name is the identity element and it is rendered smaller than the body text. At this size with letter-spacing, it becomes hard to read on high-DPI displays.
- **Section labels at 7pt** (line 343) are at the absolute minimum for readability. WCAG recommends minimum 9px (approximately 7pt) but this leaves no margin. On 1080p displays at 100% scaling, this will strain eyes.
- **Too many font sizes with too little differentiation.** The range from 7pt to 15pt uses six intermediate steps (7, 7.5, 8, 8.5, 9, 11, 15). Several of these are visually indistinguishable (7 vs 7.5, 8.5 vs 9). A tighter type scale would be clearer.
- **No letter-spacing control.** The "C H U C H A" text achieves spacing via literal spaces in the string (line 365). This is a crude workaround — the spacing between characters is the full width of a space character, which is too wide for a brand mark.

### Recommendations
1. **Implement the v2 font embedding plan** (Cormorant Garamond for title, Raleway for UI, DM Mono or Consolas for log). This is the single highest-impact visual change.
2. **Reduce to 4 type scale steps:** 8pt (small/labels), 9.5pt (body/UI), 11pt (buttons), 16pt (title). Remove 7pt and 7.5pt entirely.
3. **Increase brand label to 9pt** minimum and use Raleway with 300 weight + proper tracking instead of spaces.
4. **Consider the "VIDEO COMPRESSOR" title in Cormorant Garamond at 18-20pt** for stronger brand presence. The current 15pt bold Segoe UI reads as utilitarian, not branded.

**Proposed type scale for v2:**

| Role | Font | Size | Weight |
|------|------|------|--------|
| Title | Cormorant Garamond | 20pt | SemiBold (600) |
| Brand subtitle | Raleway | 9pt | Light (300), tracking +2px |
| Section labels | Raleway | 8pt | Medium (500), ALL CAPS |
| Body / inputs | Raleway | 9.5pt | Regular (400) |
| Buttons | Raleway | 11pt | SemiBold (600) |
| Log | DM Mono / Consolas | 8.5pt | Regular |
| Copyright | Raleway | 7.5pt | Regular |

---

## 3. Layout and Spacing

**Rating: 3/5**

### Current layout metrics
- **Form size:** 480x686px (line 353), fixed (no resize). A comfortable size for the content.
- **Left margin:** 24px consistently (lines 369, 394, 406, etc.). Good consistency.
- **Right margin:** Content ends at x=456 (24 + 432), giving 24px right margin. Symmetric. Good.
- **Vertical rhythm:** Inconsistent. Spacing between sections varies:
  - Header to separator: 82-37=45px gap after title
  - Separator to first control: 100-83=17px
  - Label to input: 16px (lines 403, 436, 515)
  - Between input rows: 46px (lines 427, 470, 534)
  - Between radio options: 24px (line 488)
  - Separator padding: 16px above (inferred), 16px below (line 506)

### Problems
- **No consistent vertical rhythm.** The spacings 16, 17, 22, 24, 38, 46, 58px are used without a clear system. A modular scale (e.g., 8px base: 8, 16, 24, 32, 48) would create better visual harmony.
- **The separator-to-content gap is 17px** (100-83), which is not on any clean grid. Should be 16px or 24px.
- **Gap between Output Mode radio buttons is only 24px** (line 488), making the two options feel slightly cramped. The descriptive text is long and wraps close to the next option.
- **The progress bar at 3px height** (line 556) is extremely thin. While this is a deliberate design choice (minimal), it is functionally problematic — users may not notice progress on a 3px bar, especially at a distance. Industry standard for progress bars is 4-8px minimum.
- **The log box at 150px height** (line 577) is reasonable but could show only ~15 lines of 8pt Consolas. During active compression with verbose output, this fills fast and the user must scroll.

### Recommendations
1. **Adopt an 8px grid.** All vertical spacings should be multiples of 8: 8, 16, 24, 32, 40, 48px. Current 46px gaps become 48px. The 17px gap becomes 16px. The 38px gap becomes 40px.
2. **Increase progress bar to 4px** minimum, or better, 6px with rounded corners (if WinForms supports it via custom painting).
3. **Increase gap between Output Mode radio buttons from 24px to 32px** to give the descriptive text more breathing room.
4. **Consider increasing log box height to 180px** in the collapsed state, especially since v2 adds more log verbosity (GPU info, encoder details).

**Before (current vertical spacing):**
```
Title area:     37px from top
Separator:      82px from top  (45px gap)
First control:  100px from top (18px gap — off-grid)
Label→Input:    16px
Row→Row:        46px (off-grid)
Radio→Radio:    24px
Section sep:    38px (off-grid)
```

**After (8px grid):**
```
Title area:     40px from top
Separator:      80px from top  (40px gap)
First control:  96px from top  (16px gap)
Label→Input:    16px
Row→Row:        48px
Radio→Radio:    32px
Section sep:    40px
```

---

## 4. Controls and Interactive Elements

**Rating: 3/5**

### Buttons
- **START button** (lines 537-549): 432x46px, full-width, green accent, white text, 11pt bold. This is well-executed — it dominates the visual hierarchy correctly as the primary CTA. The `>  START` text with the arrow gives directional affordance.
- **Browse button** (lines 523-532): 74x28px, dark background with border. Adequate but visually subordinate — correct for a secondary action.
- **Format radio buttons styled as button group** (lines 445-468): 82x30px each, flat style, border, centered text. This is a solid WinForms pattern for toggle groups. The checked state uses accent green which provides clear feedback.

### Problems
- **Format buttons have a 4px gap** between them (MP4 at x=0 width 82, MOV at x=86 width 82). This creates a visual split that weakens the "toggle group" metaphor. They should be adjacent (0px gap) or have a 1px shared border to read as a single component.
- **Output Mode uses native radio buttons** (lines 481-495) while Format uses button-styled radios. This inconsistency is jarring — two similar selection controls look completely different. Output Mode should also use the button-style pattern, or both should use native radios.
- **Text inputs lack padding.** WinForms TextBox with `FixedSingle` border has minimal internal padding (approximately 2px). The text sits too close to the border. This cannot easily be fixed in WinForms without owner-draw, but increasing the TextBox height to 32px (from the current default ~23px) would help vertically.
- **No focus indicators.** When tabbing between controls, there is no visible focus ring. The dark theme swallows the default Windows focus rectangle. This is an accessibility concern.
- **The "px" and "MB" suffix labels** (lines 411-424) are positioned manually at magic offsets (`$y + 5`). If font rendering changes, these will misalign. They should be vertically centered relative to their associated input.

### Recommendations
1. **Close the gap between format buttons** to 1px (change MOV x from 86 to 83, or make them 84px wide at x=0 and x=85).
2. **Unify selection controls** — use button-style radios for Output Mode as well, or introduce a third style for multi-line option descriptions.
3. **Add a custom focus indicator** by handling the `GotFocus`/`LostFocus` events on inputs to draw a 1px accent-green border.
4. **Increase TextBox height to 30-32px** for better touch targets and visual padding.

---

## 5. Visual Feedback and States

**Rating: 3/5**

### What works
- **START/STOP toggle** (lines 640-686): The button changes text to `[X]  STOP`, color to red, with matching hover/pressed states. Clear state communication.
- **Progress bar** uses accent green forecolor (line 558), matching the brand.
- **Status label** (lines 563-569) updates with file count and current filename during processing.
- **Log box** uses color-coded messages: LightGreen for success, Cyan for file names, OrangeRed for errors, DimGray for separators, Orange for warnings, Yellow for summary. Good semantic color use.
- **Cursor changes to Hand** on interactive elements (lines 462, 532, 548). Correct affordance.

### Problems
- **No hover state on Browse button.** The button has `$clrInput` background and `$clrBorder` border but no `MouseOverBackColor` is set (lines 523-532). By contrast, the format buttons have hover states (line 456). Inconsistent.
- **"Stopping..." state disables the button** (line 645) but provides no visual animation or spinning indicator. The user sees a frozen, grayed-out button with no indication that work is happening. A marquee progress bar during stop would help.
- **FFmpeg install state** (lines 688-695) switches to marquee progress and changes button text to "Installing FFmpeg..." but then resets button text to ">  START" (line 695) before the install might even finish. This is confusing — the text changes mid-process.
- **No transition between states.** WinForms does not support CSS-like transitions, but the instant color change from green to red on START→STOP is visually abrupt. Consider a brief intermediate state or at minimum ensuring the button text change is atomic with the color change.
- **The status label** uses the same muted gray for both "Ready" idle state and "FFmpeg ready" post-init state. These could be differentiated — idle in dim gray, ready-to-go in slightly brighter text.

### Recommendations
1. Add `MouseOverBackColor = $clrHover` to Browse button.
2. During STOP processing, keep progress bar in marquee mode instead of freezing.
3. Differentiate "Ready" (dim) from "FFmpeg ready" (normal text color) status.
4. Consider a pulsing or animated green accent on the progress bar during active encoding (custom painting).

---

## 6. Drop Zone Design (v2 Spec Review)

**Rating: 4/5**

### What the spec gets right
- **Background `#0A0A0A`** slightly darker than main bg creates a clear "well" effect (spec section 3.2). This matches the existing log box pattern (`#080808`).
- **Dashed border `#2A2A2A`** is appropriately subtle. Good restraint — many drop zones use loud dashed borders that look cheap.
- **Drag-hover feedback** flashes border to accent green `#21C134` (spec section 3.6, but note the spec still references `#1CA42C` in the same section — inconsistency at spec line 163 vs line 521).
- **File counter** ("3 files" or "1 folder (12 files found)") borrowed from Shutter Encoder is a smart addition — gives immediate confirmation of source selection.
- **Three-button row** (Browse files / Browse folder / Clear) is well-structured and covers all input methods.

### What needs improvement
- **130px height** (spec section 3.2) may be too small when showing the button row + icon + file list. The button row alone needs ~30px, the "Drop files here" text + icon needs ~40px, leaving only ~60px for the file list (about 4-5 lines of 8pt mono). Consider 150-160px minimum.
- **The spec does not define empty-state vs populated-state layout.** When files are loaded, should the "Drop files here" text/icon disappear? It should — showing both the prompt and the file list is redundant and cluttered.
- **No mention of drag-over visual for the entire file list area.** Only the border is described as changing. The entire panel background should subtly lighten (e.g., `#0F0F0F`) during drag-over to create a more obvious target.
- **Unicode down arrow** as the drop icon (`↓` or `⬇`) is weak. These render inconsistently across fonts. A custom-drawn icon (lines/arcs via GDI+) would look more polished and brand-consistent.
- **The spec does not address keyboard accessibility.** Tab order for Browse buttons, keyboard shortcut (Ctrl+O?) for browse, Enter to confirm.
- **The spec references `#1CA42C` at line 163** (drop zone drag accent) but `#21C134` at line 521 (brand corrections). This inconsistency should be fixed — all references should use `#21C134`.

### Recommendations
1. Increase drop zone height to 150px minimum, 160px preferred.
2. Define two explicit states: empty (icon + prompt + buttons) and populated (buttons + file list + counter, no icon/prompt).
3. Add background color change on drag-over: `#0A0A0A` → `#111111`.
4. Use GDI+ custom painting for the drop icon instead of Unicode characters.
5. Fix the `#1CA42C` reference in spec section 3.6 to `#21C134`.
6. Add keyboard navigation spec: Tab order, Ctrl+O shortcut.

---

## 7. Brand Compliance Summary

**Rating: 2.5/5**

| Element | Brand Spec | Current v1 | Compliant? |
|---------|-----------|------------|------------|
| Accent green | `#21C134` | `#1CA42C` | NO |
| Background dark | `#101010` | `#101010` | YES |
| Text light | `#F2E2E2` | `#F2E2E2` | YES |
| Border mid | `#262626` | `#262626` | YES |
| Title font | Cormorant Garamond | Segoe UI 15pt Bold | NO |
| UI font | Raleway | Segoe UI | NO (acceptable fallback) |
| Mono font | DM Mono | Consolas 8pt | NO (acceptable fallback) |
| Muted text | `#9a9590` (warm) | `#585858` (cool neutral) | NO |
| Link color | Not specified | `#373737` | N/A |
| Secondary colors | `#32BCB4` info, `#FF6E00` warn | Various ad hoc | PARTIAL |

**Overall brand compliance is low.** The dark background and light text are correct, but the accent green (the most visible brand element), the fonts (the most identity-defining element), and the secondary text color are all wrong. The app reads as "a dark-themed Windows utility" rather than "a CAMERAPTOR product."

### The budget-calculator.html comparison
Based on the brand reference, the budget calculator HTML uses:
- Cormorant Garamond for headings with generous weight variation
- Raleway for body and UI at comfortable sizes
- Card backgrounds at `#131313` with the dark base
- Warm gray secondary text `#9a9590`
- Green accent `#21C134` for CTAs and active states
- Generous padding (likely 16-24px inside cards, 32-48px between sections)

The Chucha app currently shares only the background color with this visual language. The typography, accent color, and text warmth are all divergent. After v2 font embedding + color correction, compliance should jump significantly.

---

## 8. Information Hierarchy

**Rating: 3.5/5**

### Current visual hierarchy (what grabs attention first)
1. **START button** — large, green, full-width. Correct as primary CTA.
2. **"VIDEO COMPRESSOR" title** — 15pt bold, high contrast. Correct as page identity.
3. **Input fields** — dark with light text, draws the eye to editable areas.
4. **Format toggle** — accent green checked state catches attention.
5. **Section labels** — muted, small, uppercase. Correctly subordinate.
6. **Log box** — dark well, recedes until populated with colored text.
7. **Copyright** — very dim, correctly the last thing noticed.

### What works
The hierarchy is fundamentally sound. The most important action (START) is the most prominent element. Settings are above the CTA, encouraging review before action. The log is below, appearing only as output. This top-to-bottom flow (configure → act → observe) is a standard and effective pattern.

### What could improve
- **"C H U C H A" brand mark is nearly invisible** at 7.5pt muted gray. It reads as decoration, not identity. On the budget calculator, the brand name likely has more presence. Consider making it the same size as section labels (8pt) in accent green or warm muted tone.
- **Source folder section does not visually stand out** despite being the most important input. The user MUST set a folder before START works, but visually it receives the same treatment as Resolution and Format. It should be visually elevated — perhaps with a border panel, or positioned immediately before the START button with more spacing.
- **Resolution and Max Size are equally weighted visually**, but Resolution has a wider input (170px vs 110px). The width difference implies Resolution is more important, which may or may not be intentional. If file size is the primary concern (it is, for a compressor), the Max Size field should be at least equally wide.

---

## 9. Accessibility Concerns

**Rating: 2/5**

### Contrast ratios (approximate)
| Element | Foreground | Background | Ratio | WCAG AA (4.5:1) |
|---------|-----------|------------|-------|------------------|
| Body text | `#F2E2E2` | `#101010` | ~15:1 | PASS |
| Muted labels | `#585858` | `#101010` | ~3.3:1 | FAIL |
| Input text | `#F2E2E2` | `#161616` | ~14:1 | PASS |
| Copyright | `#373737` | `#101010` | ~1.9:1 | FAIL |
| Start button | `#FFFFFF` | `#1CA42C` | ~3.8:1 | FAIL (large text OK) |
| Format checked | `#F2E2E2` | `#1CA42C` | ~3.5:1 | FAIL (large text borderline) |

### Critical issues
- **Muted text at `#585858` fails WCAG AA** for normal text. Section labels like "RESOLUTION", "FORMAT", "OUTPUT MODE" are functional labels, not decorative — they must be readable. Minimum: `#767676` on `#101010` for 4.5:1.
- **Copyright link at `#373737` fails badly** at 1.9:1. While decorative, it contains a clickable URL and should be at least 3:1 for WCAG AA large text, ideally 4.5:1.
- **White on green accent** for the START button is borderline. `#FFFFFF` on `#21C134` yields approximately 3.5:1 — passes for large text (11pt bold qualifies) but is tight. Using `#101010` (dark text) on green would yield ~6:1, though this conflicts with the visual weight of a light-on-dark CTA.
- **No keyboard focus indicators** visible in dark theme.
- **No tooltip/alt-text** for the "px" and "MB" suffix labels.
- **Radio buttons for Output Mode** use long descriptive text at 8.5pt. The clickable area is limited to the radio circle + text, with no padding. Touch/click targets are narrow.

### Recommendations
1. Increase `$clrMuted` from `#585858` to at minimum `#8a8a8a` (5:1 on `#101010`), or better, adopt brand's `#9a9590` (~6:1).
2. Increase copyright link color to `#4a4845` minimum.
3. Accept the white-on-green START button as a conscious brand choice (large bold text passes AA for large text).
4. Add focus rectangles via `GotFocus` event handlers.
5. Increase Output Mode radio button height to 28px minimum for better click targets.

---

## 10. v2 Spec — Specific Recommendations

### 10.1 Font embedding strategy (spec section 0)

The plan to embed WOFF2 fonts as Base64 in the PS1, extract to `%TEMP%`, and load via `PrivateFontCollection` is technically sound but has concerns:

- **WOFF2 is a web format.** `PrivateFontCollection` in .NET/GDI+ requires TTF or OTF files. WOFF2 must be decompressed to TTF first, which requires a WOFF2 decoder. **Recommendation: Embed TTF files, not WOFF2.**
- **Base64-encoded TTF files will significantly bloat the PS1.** Cormorant Garamond Regular TTF is approximately 300KB → ~400KB Base64. Raleway Variable is ~200KB → ~270KB. DM Mono Regular ~80KB → ~107KB. Total: ~777KB of Base64 text added to the script. This will slow ps2exe compilation and increase EXE size. **Recommendation: Embed only the weights actually used** (Cormorant SemiBold, Raleway Regular + Medium, DM Mono Regular) rather than full variable fonts.
- **Temp file cleanup** on process exit is fragile. If the process crashes or is killed, orphaned font files remain in `%TEMP%`. **Recommendation: Use a subfolder like `%TEMP%\ChuCha_Fonts\` and clean it on startup (delete stale files) as well as on exit.**
- **Fallback chain** (Georgia, Segoe UI, Consolas) is well-chosen. Georgia is the best system serif for approximating Cormorant Garamond. The silent fallback behavior is correct — no user-facing errors for font loading.

### 10.2 Advanced panel sizing (spec section 10)

- **180px panel height** contains 3 rows of controls. At 8px grid spacing: row 1 (30px control + 16px label above = 46px), gap 16px, row 2 (46px), gap 16px, row 3 (30px) = 154px + 16px top padding + 10px bottom = 180px. This is tight but workable.
- **Form expanding from 686px to 866px** is a 26% increase. On a 1080p display, this is fine. On a 768p laptop screen, 866px + title bar (~30px) + taskbar (~48px) = ~944px, which does NOT fit. **Recommendation: Check screen height on toggle and cap expansion if it would exceed available screen height.**

### 10.3 Mode toggle (spec section 4)

The video/audio mode toggle changing visible controls is good UX — it keeps the interface simple by showing only relevant options. However:

- **Hiding controls by toggling Visibility** can leave visual gaps if the layout is absolute-positioned (which WinForms is). The spec should define explicit Y positions for audio mode controls, not just hide/show.
- **The mode toggle should be the FIRST setting** (before Resolution, Format, etc.) because it changes what appears below. Currently the spec places it as a separate section but does not specify its Y position relative to other settings.

### 10.4 Color inconsistency in spec

As noted in section 6, the spec references `#1CA42C` at line 163 (drag accent color in section 3.6) while line 521 correctly states the fix to `#21C134`. All color references in the spec should be audited and updated to `#21C134`.

### 10.5 Missing from v2 spec

- **No mention of DPI awareness.** WinForms apps on high-DPI displays (125%, 150%) can look blurry or have misaligned controls. The spec should include `SetProcessDPIAware()` or `dpiAwareness` manifest settings.
- **No mention of minimum contrast ratios.** The spec inherits the v1 accessibility issues without addressing them.
- **No error states for inputs.** What happens when Resolution or Max Size has invalid input? Currently it shows a MessageBox (line 660). The v2 spec should consider inline validation (red border on invalid field) rather than modal dialogs that interrupt flow.
- **No loading/splash state.** FFmpeg detection and GPU probing happen on `Form_Shown`. On slow systems, this could take 1-2 seconds with no visual feedback. The spec should define what the user sees during initialization.

---

## 11. Score Summary

| Area | Score | Key Issue |
|------|-------|-----------|
| Color usage | 3/5 | Wrong accent green, cool muted grays instead of warm |
| Typography | 2/5 | No brand fonts, too-small labels, no hierarchy distinction |
| Layout & spacing | 3/5 | Good margins but inconsistent vertical rhythm |
| Controls & interaction | 3/5 | Inconsistent control styles, no focus indicators |
| Visual feedback | 3/5 | Good state management, weak hover coverage |
| Drop zone (v2 spec) | 4/5 | Well-designed, minor sizing and state issues |
| Brand compliance | 2.5/5 | Background correct, accent/fonts/warm tones wrong |
| Information hierarchy | 3.5/5 | Sound structure, source input underweighted |
| Accessibility | 2/5 | Multiple WCAG failures on muted text and links |
| **Overall** | **2.9/5** | **Functional but not branded; v2 fixes are directionally correct** |

---

## 12. Priority Action Items

### P0 — Must fix (brand-breaking)
1. **Fix accent green** `#1CA42C` → `#21C134` (line 335)
2. **Fix muted text color** `#585858` → `#9a9590` (line 337) for WCAG compliance and brand warmth
3. **Embed brand fonts** (Cormorant Garamond, Raleway) — use TTF not WOFF2

### P1 — Should fix (polish)
4. **Adopt 8px vertical grid** across all control spacing
5. **Unify control styles** — button-style radios everywhere or native radios everywhere
6. **Add hover states** to all interactive elements (Browse button missing)
7. **Fix v2 spec color inconsistency** — `#1CA42C` reference at section 3.6
8. **Add DPI awareness** to v2 implementation plan

### P2 — Nice to have (refinement)
9. **Increase progress bar height** from 3px to 6px
10. **Increase drop zone height** from 130px to 150px
11. **Add inline validation** for numeric inputs instead of modal dialogs
12. **Add screen-height check** before expanding Advanced panel
13. **Systematize hover/pressed color derivation** from accent green

---

*Review based on source code analysis at commit 262d67d. Brand reference from CAMERAPTOR Brand Guide and memory/reference_brand.md.*
