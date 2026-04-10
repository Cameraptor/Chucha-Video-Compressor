# Shutter Encoder UI/UX Comparison — Reference for Chucha v2

**Date:** 2026-04-10
**Reference:** Shutter Encoder v20.x by Paul Pacifico (paulpacifico/shutter-encoder)
**Purpose:** Supplementary analysis for the UI/UX review agent. Compares SE's interface patterns with Chucha v2 planned design. Identifies what to adopt and what to avoid.

---

## 1. Shutter Encoder — UI Architecture Overview

Shutter Encoder is a Java Swing application (~1200x700px default) built on top of FFmpeg. Its main window is divided into these major zones, top to bottom:

### 1.1 Top Bar — Source Input Area

- **"Choose files" / "Choose function"** buttons across the top
- A large **file list panel** (JList) occupying roughly 40% of the left side of the window
- Files are displayed as full paths in a scrollable list
- A file counter label shows "N File(s)" next to the list
- **Browse** and **Clear** buttons flank the file list
- The entire file list area accepts drag-and-drop — files dragged onto it are added to the queue

**Drop zone behavior:**
- The file list area IS the drop zone — no separate visual drop target
- On drag hover, the list background subtly changes to indicate acceptance
- No large icon or "drop here" text when empty — just an empty list
- The "Choose files" button opens a standard Java JFileChooser

### 1.2 Center — Function Selector + Settings

**Function dropdown (`comboFonctions`):**
- A single JComboBox containing ~78 functions grouped conceptually:
  - Video codecs: H.264, H.265, VP9, AV1, MPEG, ProRes, DNxHD/HR, etc.
  - Audio formats: MP3, AAC, AC3, FLAC, OGG, WAV, AIFF, etc.
  - Image sequences: JPEG, PNG, BMP, TIFF, WebP, etc.
  - Utility functions: Cut, Replace audio, Rewrap, Conform, Extract, etc.
  - Analysis: Loudness, Black detect, etc.
- Selecting a function completely reconfigures the settings panel below
- The dropdown is always visible — it's the primary navigation mechanism
- No grouping headers in the dropdown — all 78 items in a flat alphabetical list

**Settings panel (center-right):**
- Dynamically changes based on selected function
- For video codecs (H.264/H.265): shows codec profile, level, tune, bitrate mode (CBR/VBR/CQ), bitrate value, max bitrate
- For audio: shows codec, sample rate, bitrate, channels
- Resolution/scaling: combo boxes for width, height, aspect ratio
- All settings are **always visible** — no collapsible sections within the settings area
- Settings use a dense grid of labeled combo boxes and text fields

### 1.3 Bottom Left — Output Configuration

**Output section (`destination` area):**
- **Prefix field** (`txtPrefix`): text prepended to output filename
- **Suffix field** (`txtSuffix`): text appended to output filename (e.g., "_compressed")
- **Subfolder name** (`txtSubfolder`): name of output subdirectory
- **Output path selector**: "Same as source" radio vs custom path radio
- **`caseOpenFolderAtEnd1`**: Checkbox — "Open destination folder at end"
- **`caseChangeFolder1`**: Checkbox — toggle between source-relative and custom output

This section is always visible, not collapsible. Users see prefix/suffix/subfolder controls even if they don't need them.

### 1.4 Bottom — Status Bar + Progress

**Status bar (bottom of window):**
- **GPU acceleration indicator** (`comboAccel`): Shows "Disabled" or the detected GPU (CUDA, QSV, AMF, etc.)
- **GPU decoding** (`comboGPUDecoding`): Separate combo for hardware-accelerated input decoding
- **Progress bar**: Standard JProgressBar showing per-file progress
- **Time remaining** label
- **File counter**: "Processing 2/5"
- **Start/Cancel button**: Toggles between "Start" and "Cancel" based on state

### 1.5 Advanced / Hidden Settings

SE does NOT have a collapsible advanced panel. Instead:
- ALL settings are visible at once in their respective sections
- The window is large enough (~1200x700) to show everything
- Some settings only appear when certain functions are selected (dynamic visibility)
- There is a **Settings menu** (top menu bar) with preferences like thread count, GPU preferences, and behavior toggles
- Color grading, subtitles, watermark, audio normalization — all in separate tabs/sections that appear based on function selection

---

## 2. Pattern-by-Pattern Comparison

### 2.1 Drop Zone

| Aspect | Shutter Encoder | Chucha v1 | Chucha v2 (planned) |
|--------|----------------|-----------|---------------------|
| Visual target | File list panel (no explicit "drop here" graphic) | No drop zone at all | Dedicated panel with arrow icon + "Drop files or folder here" text |
| Empty state | Blank white/light list | N/A — text field only | Muted icon + instructional text on dark bg |
| Drag feedback | Subtle list highlight | None | Border flashes #21C134 (Raptor Green) |
| File display | Full paths in list | Folder path in text box | Short filenames in ListBox, full path on tooltip hover |
| Counter | "N File(s)" label | None | "3 files" or "1 folder (12 files found)" |
| Clear action | Clear button removes all | N/A | [ Clear ] button resets list and counter |

**Recommendation for Chucha v2:**
- SE's approach (file list IS the drop zone) works but gives no visual affordance when empty — users don't immediately know they can drag files there. Chucha v2's explicit drop zone with icon and text is BETTER for first-time users.
- ADOPT from SE: the file counter concept ("N files") — already planned.
- ADOPT from SE: showing filenames in a scrollable list — already planned.
- DO NOT COPY from SE: the lack of visual drop affordance. Keep the planned arrow icon + instructional text.
- IMPROVEMENT over SE: Chucha v2's green border flash on drag hover is a stronger affordance than SE's subtle highlight.

### 2.2 Function/Mode Selection

| Aspect | Shutter Encoder | Chucha v1 | Chucha v2 (planned) |
|--------|----------------|-----------|---------------------|
| Mechanism | Single dropdown, 78 items | MP4/MOV radio only | MODE toggle: [ Compress video ] / [ Extract audio ] + CODEC: [ H.264 ] / [ H.265 ] + FORMAT: [ MP4 ] / [ MOV ] |
| Discoverability | Overwhelming — user must scroll 78 options | Clear but limited | Clear, progressive: mode first, then codec, then format |
| Dynamic UI | Entire settings panel reconfigures per function | Static | Audio mode hides video-specific settings, shows audio format/bitrate |
| Learning curve | High — which of 78 functions is "compress to smaller size"? | Zero | Low — two clear modes |

**Recommendation for Chucha v2:**
- SE's 78-item dropdown is its biggest UX problem. New users cannot find what they need. The dropdown mixes codecs, containers, utilities, and analysis tools with no visual grouping. This is the #1 pattern Chucha should NEVER adopt.
- ADOPT from SE: the concept of dynamic UI reconfiguration when mode changes. Already planned — audio mode hides resolution/size fields.
- DO NOT COPY from SE: flat function list. Chucha's two-mode toggle is vastly superior for its use case.
- KEEP Chucha's approach: progressive disclosure. Mode -> Codec -> Format. Three clear decisions, not one from 78 choices.

### 2.3 Settings Layout

| Aspect | Shutter Encoder | Chucha v1 | Chucha v2 (planned) |
|--------|----------------|-----------|---------------------|
| Density | Very dense — 30+ controls visible simultaneously | Minimal — 5 controls | Moderate — 6-8 visible + collapsible Advanced panel |
| Organization | Function-specific grid, all expanded | Flat list | Main settings visible, power-user settings collapsed |
| Bitrate control | Manual: CBR/VBR/CQ selector + bitrate field | Automatic from target MB | Automatic from target MB (unchanged) |
| Resolution | Width + Height + aspect ratio combos | Single "max long side" field | Single "max long side" field (unchanged) |
| Target size | Not a first-class concept — user must calculate bitrate | First-class: "Max size MB" | First-class: "Max size MB" (unchanged) |

**Recommendation for Chucha v2:**
- SE exposes raw FFmpeg concepts (CBR/VBR, profile, level, tune). This is powerful for experts but meaningless for Chucha's target audience (content creators who just want smaller files).
- KEEP Chucha's "target size in MB" as the primary control. This is Chucha's strongest UX advantage over SE.
- ADOPT from SE: having codec and GPU options available (but in the Advanced panel, not in the main view).
- DO NOT COPY from SE: exposing codec profile, level, tune, max bitrate, etc. These belong nowhere in Chucha.

### 2.4 GPU Acceleration

| Aspect | Shutter Encoder | Chucha v1 | Chucha v2 (planned) |
|--------|----------------|-----------|---------------------|
| Location | Status bar at bottom of window | None | Advanced panel (collapsed by default) |
| Controls | Two combos: `comboAccel` (encode) + `comboGPUDecoding` (decode) | None | Single combo: Auto/CPU/NVIDIA/AMD/Intel |
| Detection | Auto-detects on startup, populates combo | None | Auto-detects on startup, populates combo |
| Visibility | Always visible in status bar | N/A | Hidden in Advanced; Auto selected by default |
| Fallback | Manual selection, no auto-fallback | N/A | Auto-fallback to CPU on GPU encode failure |

**Recommendation for Chucha v2:**
- SE shows GPU status in the status bar — always visible, never in the way. This is actually a good pattern for a power tool.
- CONSIDER: Adding a small GPU indicator to the status/log area (e.g., "GPU: NVIDIA" in the summary line) even though the control is in Advanced. The v2 spec already plans this in the encoding summary log line — good.
- ADOPT from SE: auto-detection of available GPU encoders.
- IMPROVEMENT over SE: Chucha's automatic GPU-to-CPU fallback on failure is better than SE's silent failure mode. Keep this.
- DO NOT COPY from SE: separate decode GPU control. Overkill for Chucha. Single "GPU acceleration" combo is enough.

### 2.5 Output Section

| Aspect | Shutter Encoder | Chucha v1 | Chucha v2 (planned) |
|--------|----------------|-----------|---------------------|
| Naming | Prefix + Suffix text fields | Fixed "_compressed" suffix or subfolder | Same two modes (subfolder / alongside) |
| Destination | Same-as-source vs custom path | Same-as-source only | Same-as-source only (no change planned) |
| Subfolder | Configurable subfolder name | Fixed "Compressed" | Fixed "Compressed" |
| Open-on-done | Checkbox `caseOpenFolderAtEnd1` | None | Checkbox in Advanced panel |

**Recommendation for Chucha v2:**
- SE's prefix/suffix/subfolder customization is useful for power users but adds complexity.
- DO NOT COPY from SE: configurable prefix/suffix. Chucha's fixed naming is simpler and sufficient.
- ADOPT from SE: "Open folder at end" checkbox — already planned in Advanced panel.
- FUTURE CONSIDERATION: If users request custom suffix text, it could be added to Advanced. Not needed for v2.

### 2.6 Progress & Batch Status

| Aspect | Shutter Encoder | Chucha v1 | Chucha v2 (planned) |
|--------|----------------|-----------|---------------------|
| Progress bar | Standard JProgressBar per file | Custom progress bar, polled every 400ms | Same mechanism (unchanged) |
| Batch counter | "Processing 2/5" in status bar | "[1/3] file.mp4" in log | Same pattern (unchanged) |
| Time estimate | Time remaining label | Time display in progress | Same |
| Completion | Sound + open folder options | Nothing | Sound notification + open folder (Advanced) |
| Cancel | Cancel button replaces Start | STOP button | Same pattern |

**Recommendation for Chucha v2:**
- Both apps handle progress similarly. Chucha's log-based approach with "[1/3]" prefix is clear and sufficient.
- ADOPT from SE: completion sound — already planned.
- ADOPT from SE: open folder on completion — already planned.
- Chucha's approach of logging each file's result ("[ok] 1412 KB -> path") is more informative than SE's status bar. Keep it.

### 2.7 Advanced / Hidden Settings

| Aspect | Shutter Encoder | Chucha v1 | Chucha v2 (planned) |
|--------|----------------|-----------|---------------------|
| Strategy | Everything visible at once (large window) | No advanced settings | Collapsible panel, collapsed by default |
| Window size | ~1200x700 fixed | 480x686 fixed | 480x686 (collapsed) / 480x866 (expanded) |
| Access | Menu bar for some prefs | N/A | Toggle button "ADVANCED" |
| Philosophy | "Show everything, let user ignore what they don't need" | "Show only what's needed" | "Show essentials, reveal power options on demand" |

**Recommendation for Chucha v2:**
- SE's "show everything" approach works for a Swiss-army-knife tool but creates visual overload.
- Chucha v2's collapsible Advanced panel is the RIGHT approach for a focused utility.
- KEEP the planned progressive disclosure: simple view for 90% of users, Advanced toggle for power users.
- The form height expansion (686 -> 866) is clean. Consider smooth animation if WinForms supports it (likely not worth the complexity — instant toggle is fine).

---

## 3. SE Features That Chucha Should NEVER Add

These SE features add complexity without serving Chucha's "one-click compress" mission:

| SE Feature | Why NOT for Chucha |
|------------|-------------------|
| 78-function dropdown | Chucha does two things: compress video, extract audio. Period. |
| Video preview / frame-by-frame | Chucha is not an NLE or viewer |
| Color grading / LUT | Out of scope — use DaVinci Resolve |
| Subtitle burn-in / extraction | Out of scope |
| Watermark overlay | Out of scope |
| Audio normalization / loudness | Out of scope |
| Image sequence export | Out of scope |
| FTP upload / email | Out of scope |
| Waveform display | Out of scope |
| Multiple output destinations | Overcomplicates output logic |
| Custom FFmpeg command field | Defeats the purpose of simplicity |
| Configurable prefix/suffix | Fixed naming is sufficient |
| Separate GPU decode control | Single GPU combo is enough |
| Codec profile/level/tune | Power-user FFmpeg flags that Chucha's audience doesn't need |

---

## 4. SE Patterns Worth Adopting (Already Planned in v2 Spec)

These are good UX patterns from SE that the v2 spec correctly identifies and plans to implement:

| Pattern | SE Implementation | Chucha v2 Plan | Status |
|---------|------------------|----------------|--------|
| File counter | "N File(s)" label | "3 files" / "1 folder (N files)" | Planned, Section 3.4 |
| Drop zone accepts files AND folders | File list accepts both | Drop zone Panel accepts both | Planned, Section 3.6 |
| GPU auto-detection | comboAccel populates on startup | Get-AvailableGPUEncoders on Form_Shown | Planned, Section 5 |
| Open folder on completion | caseOpenFolderAtEnd1 checkbox | Checkbox in Advanced panel | Planned, Section 10.3 |
| Completion sound | casePlaySound | SystemSounds::Asterisk | Planned, Section 7 |
| Dynamic settings visibility | Settings change per function | Audio mode hides video settings | Planned, Section 4 |
| Batch processing with counter | "Processing 2/5" | "[1/3] file.mp4" log prefix | Existing, enhanced |

---

## 5. Additional Recommendations (Beyond Current v2 Spec)

### 5.1 Empty State Design (SE Weakness, Chucha Opportunity)

SE's empty state is just a blank file list — no guidance for new users. Chucha v2's drop zone with instructional text is better. Consider making the empty state even more informative:

```
Drop zone empty state:
  - Arrow icon (Unicode down arrow, muted color)
  - "Drop video files or a folder here"
  - Below that, in dimmer text: "or use Browse buttons above"
```

This is already close to what's planned. Ensure the secondary text ("or use Browse") is included.

### 5.2 Mode Toggle Visual Design

SE uses a single dropdown for function selection. Chucha v2 plans a button-group toggle for mode. Ensure the active mode button has strong visual contrast:

- Active button: Raptor Green (#21C134) background, dark text
- Inactive button: #262626 background, muted text (#9a9590)

This makes the current mode instantly scannable, unlike SE's dropdown which requires reading the selected text.

### 5.3 Error Feedback Patterns

SE shows errors in a separate console/log area. Chucha v1 already does this well with the log box. For v2, the GPU fallback messaging is important:

```
GPU encode failed for clip2.mp4, retrying on CPU...
```

This is already in the spec (Section 11). Good — SE silently retries or fails without clear messaging. Chucha's explicit log message is better UX.

### 5.4 Keyboard Accessibility

SE supports keyboard shortcuts for common actions. Chucha v2 should ensure:
- Tab order follows visual layout (drop zone buttons -> mode -> settings -> advanced -> start)
- Enter key triggers Start when focus is on the form
- Escape triggers Stop during encoding

This is not in the current spec but would be a low-effort improvement.

---

## 6. Summary — Design Philosophy Comparison

| | Shutter Encoder | Chucha v2 |
|--|----------------|-----------|
| **Philosophy** | "Every FFmpeg feature in one GUI" | "Compress videos to target size, nothing else" |
| **Target user** | Video professionals, FFmpeg power users | Content creators, social media managers, anyone who needs smaller files |
| **Complexity** | High — 78 functions, dozens of visible settings | Low — 2 modes, 6-8 visible settings, Advanced panel for power users |
| **Window size** | ~1200x700 (large) | 480x686-866 (compact) |
| **Learning curve** | 15+ minutes to understand layout | Under 30 seconds |
| **Strongest UX** | Comprehensive — handles any video task | Focused — "target size in MB" is instantly understood |
| **Weakest UX** | Information overload, no progressive disclosure | (v1) No drop zone, no GPU, limited codec options |

**The v2 spec correctly cherry-picks SE's best patterns (drop zone, file feedback, GPU detection, completion actions) while rejecting its complexity. This comparison confirms the v2 design direction is sound.**

---

*This document supplements the v2 design spec and the UI/UX review agent's analysis. It should be read alongside `docs/superpowers/specs/2026-04-10-chucha-v2-design.md`.*
