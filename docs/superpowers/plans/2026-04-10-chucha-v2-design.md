# Chucha Video Compressor v2 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade Chucha from a folder-only x264 compressor to a drop-zone-driven, GPU-accelerated, H.265-capable tool with audio extraction — all in one PowerShell file.

**Architecture:** Single-file PowerShell WinForms app (`VideoCompressor.ps1`), compiled to EXE via ps2exe. All changes happen inside this one file. New UI sections (drop zone, mode toggle, advanced panel) are inserted into the existing layout. New encoding logic branches on GPU/codec/mode parameters passed into `Compress-Video` and new `Invoke-AudioExtract`. Font embedding uses Base64-encoded WOFF2 decoded to `%TEMP%` at startup.

**Tech Stack:** PowerShell 5.1+, WinForms (.NET Framework), FFmpeg (external), ps2exe (compilation), C# Add-Type (IFileOpenDialog COM interop)

**Spec:** `docs/superpowers/specs/2026-04-10-chucha-v2-design.md`
**SE Reference:** `docs/shutter-encoder-analysis.md` (GPU flags, audio mapping, batch patterns)

---

## File Structure

All changes are in a single file:

| File | Change |
|------|--------|
| `VideoCompressor.ps1` | **Modify** — all 15 tasks modify this file |
| `compile.ps1` | **No change** — existing ps2exe compile script |
| `VideoCompressor.exe` | **Regenerated** — via compile.ps1 in final task |

The file grows from ~850 lines to ~1600–1800 lines. Code sections (top to bottom):

```
[1]   Assembly loading + script variables        (existing, expanded)
[2]   Font embedding (Base64 decode + load)      (NEW)
[3]   IFileOpenDialog C# Add-Type                (NEW)
[4]   Find-FFmpeg / Install / Download           (existing, unchanged)
[5]   Helpers: Write-Log, Get-VideoFiles, etc.   (existing, minor edits)
[6]   GPU detection function                     (NEW)
[7]   Invoke-FFmpeg                              (existing, +threads param)
[8]   Compress-Video                             (existing, major refactor for GPU/H.265)
[9]   Invoke-AudioExtract                        (NEW)
[10]  Color palette + font definitions           (existing, color fix + new fonts)
[11]  Form setup                                 (existing, height change)
[12]  Header                                     (existing, font swap)
[13]  Drop zone panel                            (NEW, replaces old source folder)
[14]  Mode toggle (video/audio)                  (NEW)
[15]  Video settings (res, size, format)         (existing, wrapped in panel)
[16]  Audio settings (format, bitrate)           (NEW, hidden by default)
[17]  Output mode                                (existing, unchanged)
[18]  Advanced button + panel                    (NEW)
[19]  START button                               (existing, Y shift)
[20]  Progress / Status / Log / Copyright        (existing, Y shift)
[21]  Event handlers                             (existing, major refactor)
```

---

## Task 1: Brand Color Correction

**Files:**
- Modify: `VideoCompressor.ps1:335` (color palette section)

Fix the accent green from `#1CA42C` to `#21C134` per brand guide.

- [ ] **Step 1: Fix accent color definition**

Find line 335:
```powershell
$clrAccent  = [Drawing.Color]::FromArgb(28,  164, 44)   # #1CA42C  muted Raptor GREEN
```

Replace with:
```powershell
$clrAccent  = [Drawing.Color]::FromArgb(33,  193, 52)   # #21C134  Raptor GREEN (brand)
```

- [ ] **Step 2: Fix muted text color to match brand warm gray**

Find line 337:
```powershell
$clrMuted   = [Drawing.Color]::FromArgb(88,  88,  88)
```

Replace with:
```powershell
$clrMuted   = [Drawing.Color]::FromArgb(154, 149, 144)  # #9A9590  brand warm gray (WCAG AA ~6:1)
```

Also update copyright link color (currently `#373737`, WCAG fail at 1.9:1):
```powershell
$lblCopy.LinkColor        = [Drawing.Color]::FromArgb(74, 72, 69)  # #4A4845  brand dim text
$lblCopy.VisitedLinkColor = [Drawing.Color]::FromArgb(74, 72, 69)
```

- [ ] **Step 3: Add DPI awareness**

Add at the very top of the script (before any WinForms loading):

```powershell
Add-Type -TypeDefinition 'using System.Runtime.InteropServices; public class DpiAware { [DllImport("user32.dll")] public static extern bool SetProcessDPIAware(); }' -ErrorAction SilentlyContinue
try { [DpiAware]::SetProcessDPIAware() } catch {}
```

- [ ] **Step 4: Update START button hover/down colors to match new green**

Find all hardcoded `FromArgb(38, 182, 58)` (hover) and `FromArgb(18, 132, 34)` (down) throughout the file. These appear in:
- Line 545: `$btnStart.FlatAppearance.MouseOverBackColor`
- Line 546: `$btnStart.FlatAppearance.MouseDownBackColor`
- Line 681, 702, 814, 840: Reset blocks after processing

Replace every instance:
```powershell
# Old hover: FromArgb(38, 182, 58)  → New: FromArgb(45, 210, 68)
# Old down:  FromArgb(18, 132, 34)  → New: FromArgb(25, 155, 42)
```

- [ ] **Step 3: Verify — run the script**

```bash
powershell -ExecutionPolicy Bypass -File VideoCompressor.ps1
```

Expected: Form opens. START button is noticeably brighter green (`#21C134`). Hover/press states match. All other colors unchanged.

- [ ] **Step 4: Commit**

```bash
git add VideoCompressor.ps1
git commit -m "fix: correct accent green to #21C134 per brand guide"
```

---

## Task 2: Font Embedding (Cormorant Garamond + Raleway)

**Files:**
- Modify: `VideoCompressor.ps1` — add font embedding block after assembly loading, update font definitions

This task embeds two brand fonts via Base64-encoded WOFF2 files, decoded to `%TEMP%` at startup and loaded via `PrivateFontCollection`. Silent fallback to system fonts if loading fails.

- [ ] **Step 1: Prepare font Base64 strings**

Download Cormorant Garamond SemiBold (for title) and Raleway Regular + Raleway SemiBold (for UI) as **TTF** files. **NOT WOFF2** — `PrivateFontCollection` requires TTF/OTF.

Sources: Google Fonts → download TTF family → pick specific weights.

Convert each to Base64:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("CormorantGaramond-SemiBold.ttf"))
[Convert]::ToBase64String([IO.File]::ReadAllBytes("Raleway-Regular.ttf"))
[Convert]::ToBase64String([IO.File]::ReadAllBytes("Raleway-SemiBold.ttf"))
```

Store the output strings. These will be embedded in the script.

> **Important (from UI/UX review):** Embed only the weights actually used, not full variable fonts. Each TTF = ~200-300KB → ~270-400KB Base64. Total ~900KB added to PS1.

- [ ] **Step 2: Add font loading block after assembly imports (line 2)**

Insert after line 2 (`Add-Type -AssemblyName System.Drawing`):

```powershell
# --- Font embedding (Cormorant Garamond + Raleway) ---------------------------
# Fonts decoded from Base64 to %TEMP%, loaded via PrivateFontCollection.
# Fallback: Georgia (title), Segoe UI (labels/buttons), Consolas (log).

$script:FontCollection = $null
$script:FontCormorant  = $null
$script:FontRaleway    = $null
$script:FontTempFiles  = @()

function Initialize-EmbeddedFonts {
    $fonts = @{
        CormorantGaramond = "<BASE64_CORMORANT_BOLD_TTF>"
        RalewayRegular    = "<BASE64_RALEWAY_REGULAR_TTF>"
        RalewayBold       = "<BASE64_RALEWAY_BOLD_TTF>"
    }

    try {
        $script:FontCollection = New-Object Drawing.Text.PrivateFontCollection
        $tempDir = $env:TEMP

        foreach ($name in $fonts.Keys) {
            $bytes = [Convert]::FromBase64String($fonts[$name])
            $tmpFile = Join-Path $tempDir "chucha_${name}.ttf"
            [IO.File]::WriteAllBytes($tmpFile, $bytes)
            $script:FontTempFiles += $tmpFile
            $script:FontCollection.AddFontFile($tmpFile)
        }

        # Find loaded font families
        foreach ($fam in $script:FontCollection.Families) {
            if ($fam.Name -like "*Cormorant*") { $script:FontCormorant = $fam.Name }
            if ($fam.Name -like "*Raleway*")   { $script:FontRaleway   = $fam.Name }
        }
    } catch {
        # Silent fallback — will use system fonts
        $script:FontCormorant = $null
        $script:FontRaleway   = $null
    }
}

function Remove-EmbeddedFontFiles {
    foreach ($f in $script:FontTempFiles) {
        Remove-Item $f -Force -ErrorAction SilentlyContinue
    }
}

Initialize-EmbeddedFonts
```

> **Note:** Replace `<BASE64_...>` placeholders with actual Base64 strings from Step 1. Each string will be ~50–200 KB of text.

- [ ] **Step 3: Update font definitions (currently lines 340–348)**

Replace the font definition block:

```powershell
# -- Fonts ---------------------------------------------------------------------
# Brand fonts via PrivateFontCollection; fallback to system fonts
$titleFontFamily = if ($script:FontCormorant) { $script:FontCormorant } else { "Georgia" }
$uiFontFamily    = if ($script:FontRaleway)   { $script:FontRaleway }   else { "Segoe UI" }

$fontBrand  = New-Object Drawing.Font($uiFontFamily, 7.5)
$fontTitle  = New-Object Drawing.Font($titleFontFamily, 15, [Drawing.FontStyle]::Bold)
$fontLabel  = New-Object Drawing.Font($uiFontFamily, 7, [Drawing.FontStyle]::Regular)
$fontUI     = New-Object Drawing.Font($uiFontFamily, 9)
$fontSmall  = New-Object Drawing.Font($uiFontFamily, 8.5)
$fontBtn    = New-Object Drawing.Font($uiFontFamily, 11, [Drawing.FontStyle]::Bold)
$fontMono   = New-Object Drawing.Font("Consolas", 8)
$fontCopy   = New-Object Drawing.Font($uiFontFamily, 7)
```

- [ ] **Step 4: Add cleanup on form close**

Add to the `$form.Add_FormClosing` handler:

```powershell
Remove-EmbeddedFontFiles
```

- [ ] **Step 5: Verify**

```bash
powershell -ExecutionPolicy Bypass -File VideoCompressor.ps1
```

Expected: Title "VIDEO COMPRESSOR" renders in Cormorant Garamond (serif). Labels render in Raleway. If fonts not found on disk, Georgia/Segoe UI used — no error shown.

- [ ] **Step 6: Commit**

```bash
git add VideoCompressor.ps1
git commit -m "feat: embed Cormorant Garamond + Raleway fonts with fallback"
```

---

## Task 3: IFileOpenDialog COM Interop

**Files:**
- Modify: `VideoCompressor.ps1` — add C# Add-Type block after font embedding, before FFmpeg functions

Modern Windows file/folder picker via COM interop, replacing the ancient `FolderBrowserDialog`.

- [ ] **Step 1: Add the C# interop type**

Insert after `Initialize-EmbeddedFonts` call (before `# --- FFmpeg detection`):

```powershell
# --- Modern file picker (IFileOpenDialog COM) ---------------------------------
try {
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class ModernPicker {
    [DllImport("ole32.dll")]
    static extern int CoCreateInstance(
        ref Guid clsid, IntPtr outer, uint ctx, ref Guid iid, out IntPtr ppv);

    static readonly Guid CLSID_FileOpenDialog =
        new Guid("DC1C5A9C-E88A-4dde-A5A1-60F82A20AEF7");
    static readonly Guid IID_IFileOpenDialog =
        new Guid("d57c7288-d4ad-4768-be02-9d969532d960");

    const uint FOS_PICKFOLDERS      = 0x00000020;
    const uint FOS_FORCEFILESYSTEM  = 0x00000040;
    const uint FOS_ALLOWMULTISELECT = 0x00000200;

    [ComImport, Guid("d57c7288-d4ad-4768-be02-9d969532d960"),
     InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IFileOpenDialog {
        // IModalWindow
        [PreserveSig] int Show(IntPtr hwnd);
        // IFileDialog
        void SetFileTypes(uint cTypes, IntPtr rgSpec);
        void SetFileTypeIndex(uint iIndex);
        void GetFileTypeIndex(out uint piIndex);
        void Advise(IntPtr pEvents, out uint pdwCookie);
        void Unadvise(uint dwCookie);
        void SetOptions(uint fos);
        void GetOptions(out uint pfos);
        void SetDefaultFolder(IntPtr psi);
        void SetFolder(IntPtr psi);
        void GetFolder(out IntPtr ppsi);
        void GetCurrentSelection(out IntPtr ppsi);
        void SetFileName([MarshalAs(UnmanagedType.LPWStr)] string pszName);
        void GetFileName(out IntPtr pszName);
        void SetTitle([MarshalAs(UnmanagedType.LPWStr)] string pszTitle);
        void SetOkButtonLabel([MarshalAs(UnmanagedType.LPWStr)] string pszText);
        void SetFileNameLabel([MarshalAs(UnmanagedType.LPWStr)] string pszLabel);
        void GetResult(out IntPtr ppsi);
        void AddPlace(IntPtr psi, int fdap);
        void SetDefaultExtension([MarshalAs(UnmanagedType.LPWStr)] string pszExt);
        void Close(int hr);
        void SetClientGuid(ref Guid guid);
        void ClearClientData();
        void SetFilter(IntPtr pFilter);
        // IFileOpenDialog
        void GetResults(out IntPtr ppenum);
        void GetSelectedItems(out IntPtr ppsai);
    }

    [ComImport, Guid("43826D1E-E718-42EE-BC55-A1E261C37BFE"),
     InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IShellItem {
        void BindToHandler(IntPtr pbc, ref Guid bhid, ref Guid riid, out IntPtr ppv);
        void GetParent(out IntPtr ppsi);
        void GetDisplayName(uint sigdnName, out IntPtr ppszName);
        void GetAttributes(uint sfgaoMask, out uint psfgaoAttribs);
        void Compare(IntPtr psi, uint hint, out int piOrder);
    }

    [ComImport, Guid("b63ea76d-1f85-456f-a19c-48159efa858b"),
     InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IShellItemArray {
        void BindToHandler(IntPtr pbc, ref Guid bhid, ref Guid riid, out IntPtr ppv);
        void GetPropertyStore(int flags, ref Guid riid, out IntPtr ppv);
        void GetPropertyDescriptionList(IntPtr keyType, ref Guid riid, out IntPtr ppv);
        void GetAttributes(int attribFlags, uint sfgaoMask, out uint psfgaoAttribs);
        void GetCount(out uint pdwNumItems);
        void GetItemAt(uint dwIndex, out IntPtr ppsi);
        void EnumItems(out IntPtr ppenumShellItems);
    }

    const uint SIGDN_FILESYSPATH = 0x80058000;

    static string GetShellItemPath(IntPtr psi) {
        var item = (IShellItem)Marshal.GetObjectForIUnknown(psi);
        IntPtr namePtr;
        item.GetDisplayName(SIGDN_FILESYSPATH, out namePtr);
        string path = Marshal.PtrToStringUni(namePtr);
        Marshal.FreeCoTaskMem(namePtr);
        Marshal.ReleaseComObject(item);
        return path;
    }

    public static string PickFolder(IntPtr owner) {
        IntPtr ppv;
        var clsid = CLSID_FileOpenDialog;
        var iid = IID_IFileOpenDialog;
        CoCreateInstance(ref clsid, IntPtr.Zero, 1, ref iid, out ppv);
        var dlg = (IFileOpenDialog)Marshal.GetObjectForIUnknown(ppv);
        uint opts;
        dlg.GetOptions(out opts);
        dlg.SetOptions(opts | FOS_PICKFOLDERS | FOS_FORCEFILESYSTEM);
        dlg.SetTitle("Select folder with video files");
        int hr = dlg.Show(owner);
        if (hr != 0) { Marshal.ReleaseComObject(dlg); return null; }
        IntPtr psi;
        dlg.GetResult(out psi);
        string path = GetShellItemPath(psi);
        Marshal.Release(psi);
        Marshal.ReleaseComObject(dlg);
        return path;
    }

    public static string[] PickFiles(IntPtr owner) {
        IntPtr ppv;
        var clsid = CLSID_FileOpenDialog;
        var iid = IID_IFileOpenDialog;
        CoCreateInstance(ref clsid, IntPtr.Zero, 1, ref iid, out ppv);
        var dlg = (IFileOpenDialog)Marshal.GetObjectForIUnknown(ppv);
        uint opts;
        dlg.GetOptions(out opts);
        dlg.SetOptions(opts | FOS_ALLOWMULTISELECT | FOS_FORCEFILESYSTEM);
        dlg.SetTitle("Select video files");
        int hr = dlg.Show(owner);
        if (hr != 0) { Marshal.ReleaseComObject(dlg); return null; }
        IntPtr ppenum;
        dlg.GetResults(out ppenum);
        var arr = (IShellItemArray)Marshal.GetObjectForIUnknown(ppenum);
        uint count;
        arr.GetCount(out count);
        string[] result = new string[count];
        for (uint i = 0; i < count; i++) {
            IntPtr psi;
            arr.GetItemAt(i, out psi);
            result[i] = GetShellItemPath(psi);
            Marshal.Release(psi);
        }
        Marshal.Release(ppenum);
        Marshal.ReleaseComObject(dlg);
        return result;
    }
}
'@ -ReferencedAssemblies System.Runtime.InteropServices -ErrorAction Stop
    $script:HasModernPicker = $true
} catch {
    $script:HasModernPicker = $false
}
```

- [ ] **Step 2: Add helper wrappers for picker with fallback**

Insert after the Add-Type block:

```powershell
function Show-FolderPicker {
    param([IntPtr]$Owner = [IntPtr]::Zero)
    if ($script:HasModernPicker) {
        try {
            $result = [ModernPicker]::PickFolder($Owner)
            if ($result) { return $result }
            return $null
        } catch {}
    }
    # Fallback to classic dialog
    $dlg = New-Object Windows.Forms.FolderBrowserDialog
    $dlg.Description = "Select folder with video files"
    if ($dlg.ShowDialog() -eq "OK") { return $dlg.SelectedPath }
    return $null
}

function Show-FilePicker {
    param([IntPtr]$Owner = [IntPtr]::Zero)
    if ($script:HasModernPicker) {
        try {
            $result = [ModernPicker]::PickFiles($Owner)
            if ($result) { return $result }
            return $null
        } catch {}
    }
    # Fallback to classic dialog
    $dlg = New-Object Windows.Forms.OpenFileDialog
    $dlg.Multiselect = $true
    $dlg.Filter = "Video files|*.mp4;*.mov;*.avi;*.mkv;*.webm;*.mxf;*.m4v;*.wmv|All files|*.*"
    if ($dlg.ShowDialog() -eq "OK") { return $dlg.FileNames }
    return $null
}
```

- [ ] **Step 3: Verify**

```powershell
# Quick inline test — should show modern Explorer-style folder picker
Add-Type -AssemblyName System.Windows.Forms
# (run the full script and click Browse folder)
```

```bash
powershell -ExecutionPolicy Bypass -File VideoCompressor.ps1
```

Expected: Browse buttons (wired in Task 3) open the modern Windows Explorer-style picker. If COM fails, classic dialog appears. No crash.

- [ ] **Step 4: Commit**

```bash
git add VideoCompressor.ps1
git commit -m "feat: add IFileOpenDialog COM interop with fallback to classic picker"
```

---

## Task 4: Drop Zone UI

**Files:**
- Modify: `VideoCompressor.ps1` — replace source folder section (lines 508–533), add new state variables, rewire events

This is the biggest UI change. The old TextBox+Browse row becomes a 130px drop zone panel with file list, counter, and Browse/Clear buttons.

- [ ] **Step 1: Add new script-scoped state variables (after existing script vars, line 8)**

```powershell
$script:SourceFiles      = @()    # [System.IO.FileInfo[]] — all files to process
$script:SourceFolderRoot = $null  # string — set when folder was browsed/dropped
```

- [ ] **Step 2: Add video extension filter constant (after state vars)**

```powershell
$script:VideoExtensions = @(".mp4",".mov",".avi",".webm",".mkv",".mxf",".m4v",".wmv")
```

- [ ] **Step 3: Remove old source folder section**

Delete the old source folder UI block (lines 508–533 approximately):
- `$lblFolderLbl` (SOURCE FOLDER label)
- `$txtFolder` (TextBox)
- `$btnBrowse` (Browse button)

Also delete the old `$btnBrowse.Add_Click` handler (lines 602–606).

- [ ] **Step 4: Insert drop zone panel in the same Y position**

After the output mode section (after `$rbSideBySide`), insert:

```powershell
$y += 38

# -- Separator -----------------------------------------------------------------
$sep2 = New-Object Windows.Forms.Panel
$sep2.Location  = [Drawing.Point]::new(24, $y)
$sep2.Size      = [Drawing.Size]::new(432, 1)
$sep2.BackColor = $clrBorder
$form.Controls.Add($sep2)

$y += 16

# -- Drop zone ----------------------------------------------------------------
$lblSourceLbl = New-Object Windows.Forms.Label
$lblSourceLbl.Text = "SOURCE"; $lblSourceLbl.Font = $fontLabel
$lblSourceLbl.ForeColor = $clrMuted; $lblSourceLbl.AutoSize = $true
$lblSourceLbl.Location = [Drawing.Point]::new(24, $y)
$form.Controls.Add($lblSourceLbl)

$y += 16

# Button row: Browse files | Browse folder | Clear | counter
$btnBrowseFiles = New-Object Windows.Forms.Button
$btnBrowseFiles.Text = "Browse files"
$btnBrowseFiles.Location = [Drawing.Point]::new(24, $y)
$btnBrowseFiles.Size = [Drawing.Size]::new(100, 26)
$btnBrowseFiles.BackColor = $clrInput; $btnBrowseFiles.ForeColor = $clrText
$btnBrowseFiles.FlatStyle = "Flat"
$btnBrowseFiles.FlatAppearance.BorderColor = $clrBorder
$btnBrowseFiles.Font = $fontSmall
$btnBrowseFiles.Cursor = [Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnBrowseFiles)

$btnBrowseFolder = New-Object Windows.Forms.Button
$btnBrowseFolder.Text = "Browse folder"
$btnBrowseFolder.Location = [Drawing.Point]::new(130, $y)
$btnBrowseFolder.Size = [Drawing.Size]::new(110, 26)
$btnBrowseFolder.BackColor = $clrInput; $btnBrowseFolder.ForeColor = $clrText
$btnBrowseFolder.FlatStyle = "Flat"
$btnBrowseFolder.FlatAppearance.BorderColor = $clrBorder
$btnBrowseFolder.Font = $fontSmall
$btnBrowseFolder.Cursor = [Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnBrowseFolder)

$btnClear = New-Object Windows.Forms.Button
$btnClear.Text = "Clear"
$btnClear.Location = [Drawing.Point]::new(246, $y)
$btnClear.Size = [Drawing.Size]::new(60, 26)
$btnClear.BackColor = $clrInput; $btnClear.ForeColor = $clrMuted
$btnClear.FlatStyle = "Flat"
$btnClear.FlatAppearance.BorderColor = $clrBorder
$btnClear.Font = $fontSmall
$btnClear.Cursor = [Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnClear)

$lblFileCount = New-Object Windows.Forms.Label
$lblFileCount.Text = "0 files"
$lblFileCount.Font = $fontSmall
$lblFileCount.ForeColor = $clrMuted
$lblFileCount.AutoSize = $true
$lblFileCount.Location = [Drawing.Point]::new(316, ($y + 5))
$form.Controls.Add($lblFileCount)

$y += 32

# Drop zone panel (dark, dashed border drawn via Paint event)
$clrDropBg = [Drawing.Color]::FromArgb(10, 10, 10)  # #0A0A0A
$clrDropBorder = [Drawing.Color]::FromArgb(42, 42, 42)  # #2A2A2A

$dropPanel = New-Object Windows.Forms.Panel
$dropPanel.Location = [Drawing.Point]::new(24, $y)
$dropPanel.Size = [Drawing.Size]::new(432, 130)  # 150px total with button row; UI review recommends 150px+ for file list
$dropPanel.BackColor = $clrDropBg
$dropPanel.AllowDrop = $true
$form.Controls.Add($dropPanel)

# File list inside drop panel
$lstFiles = New-Object Windows.Forms.ListBox
$lstFiles.Location = [Drawing.Point]::new(4, 4)
$lstFiles.Size = [Drawing.Size]::new(424, 122)
$lstFiles.BackColor = $clrDropBg
$lstFiles.ForeColor = $clrText
$lstFiles.Font = $fontMono
$lstFiles.BorderStyle = "None"
$lstFiles.IntegralHeight = $false
$lstFiles.HorizontalScrollbar = $true
$dropPanel.Controls.Add($lstFiles)

# Placeholder label (visible when list is empty)
$lblDropHint = New-Object Windows.Forms.Label
$lblDropHint.Text = "`u{2193}  Drop files or folder here"
$lblDropHint.Font = $fontUI
$lblDropHint.ForeColor = [Drawing.Color]::FromArgb(60, 60, 60)
$lblDropHint.AutoSize = $false
$lblDropHint.Size = [Drawing.Size]::new(432, 130)
$lblDropHint.TextAlign = [Drawing.ContentAlignment]::MiddleCenter
$lblDropHint.Location = [Drawing.Point]::new(0, 0)
$dropPanel.Controls.Add($lblDropHint)
$lblDropHint.BringToFront()

$y += 138  # 130px panel + 8px gap
```

- [ ] **Step 5: Add helper function to update drop zone display**

Insert in the helpers section (after `Get-VideoFiles`):

```powershell
function Update-DropZoneDisplay {
    $lstFiles.Items.Clear()
    if ($script:SourceFiles.Count -eq 0) {
        $lblDropHint.Visible = $true
        $lstFiles.Visible = $false
        $lblFileCount.Text = "0 files"
        return
    }
    $lblDropHint.Visible = $false
    $lstFiles.Visible = $true
    foreach ($f in $script:SourceFiles) {
        $lstFiles.Items.Add($f.Name)
    }
    if ($script:SourceFolderRoot) {
        $lblFileCount.Text = "1 folder ($($script:SourceFiles.Count) files)"
    } else {
        $lblFileCount.Text = "$($script:SourceFiles.Count) files"
    }
}
```

- [ ] **Step 6: Wire Browse buttons + Clear**

Add event handlers (in the events section):

```powershell
$btnBrowseFiles.Add_Click({
    $paths = Show-FilePicker $form.Handle
    if ($paths) {
        $script:SourceFolderRoot = $null
        $script:SourceFiles = @()
        foreach ($p in $paths) {
            $ext = [IO.Path]::GetExtension($p).ToLower()
            if ($script:VideoExtensions -contains $ext) {
                $script:SourceFiles += [IO.FileInfo]::new($p)
            }
        }
        Update-DropZoneDisplay
    }
})

$btnBrowseFolder.Add_Click({
    $folder = Show-FolderPicker $form.Handle
    if ($folder -and (Test-Path $folder)) {
        $script:SourceFolderRoot = $folder
        $script:SourceFiles = @(Get-VideoFiles $folder)
        Update-DropZoneDisplay
    }
})

$btnClear.Add_Click({
    $script:SourceFiles = @()
    $script:SourceFolderRoot = $null
    Update-DropZoneDisplay
})
```

- [ ] **Step 7: Wire drag & drop on the panel AND the form**

```powershell
$dropDragEnter = {
    param($s, $e)
    if ($e.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) {
        $e.Effect = [Windows.Forms.DragDropEffects]::Copy
        $dropPanel.BackColor = [Drawing.Color]::FromArgb(20, 40, 20)  # subtle green tint
    }
}
$dropDragLeave = {
    $dropPanel.BackColor = $clrDropBg
}
$dropDragDrop = {
    param($s, $e)
    $dropPanel.BackColor = $clrDropBg
    $dropped = $e.Data.GetData([Windows.Forms.DataFormats]::FileDrop)
    if (-not $dropped) { return }

    # Single folder dropped?
    if ($dropped.Count -eq 1 -and (Test-Path $dropped[0] -PathType Container)) {
        $script:SourceFolderRoot = $dropped[0]
        $script:SourceFiles = @(Get-VideoFiles $dropped[0])
        Update-DropZoneDisplay
        return
    }

    # Files dropped — filter to video extensions
    $script:SourceFolderRoot = $null
    $script:SourceFiles = @()
    foreach ($p in $dropped) {
        if (Test-Path $p -PathType Leaf) {
            $ext = [IO.Path]::GetExtension($p).ToLower()
            if ($script:VideoExtensions -contains $ext) {
                $script:SourceFiles += [IO.FileInfo]::new($p)
            }
        }
    }
    Update-DropZoneDisplay
}

$dropPanel.Add_DragEnter($dropDragEnter)
$dropPanel.Add_DragLeave($dropDragLeave)
$dropPanel.Add_DragDrop($dropDragDrop)

# Also accept drag on the form itself
$form.AllowDrop = $true
$form.Add_DragEnter($dropDragEnter)
$form.Add_DragLeave($dropDragLeave)
$form.Add_DragDrop($dropDragDrop)
```

- [ ] **Step 8: Draw dashed border on drop panel via Paint event**

```powershell
$dropPanel.Add_Paint({
    param($s, $e)
    $pen = New-Object Drawing.Pen($clrDropBorder, 1)
    $pen.DashStyle = [Drawing.Drawing2D.DashStyle]::Dash
    $rect = New-Object Drawing.Rectangle(0, 0, ($s.Width - 1), ($s.Height - 1))
    $e.Graphics.DrawRectangle($pen, $rect)
    $pen.Dispose()
})
```

- [ ] **Step 9: Update START click handler to use `$script:SourceFiles` instead of `$txtFolder`**

In the `$btnStart.Add_Click` handler, replace the folder validation block:

Old:
```powershell
$folder = $txtFolder.Text.Trim()
if (-not $folder -or -not (Test-Path $folder)) {
    [Windows.Forms.MessageBox]::Show("Folder not found...","Error","OK","Error") | Out-Null
    return
}
# ...
$files = Get-VideoFiles $folder
```

New:
```powershell
if ($script:SourceFiles.Count -eq 0) {
    [Windows.Forms.MessageBox]::Show(
        "No source files selected.`nDrop files/folder or use Browse.",
        "Error", "OK", "Error") | Out-Null
    return
}

$files = $script:SourceFiles
$folder = if ($script:SourceFolderRoot) { $script:SourceFolderRoot }
          else { $files[0].DirectoryName }
```

Also update the output path logic in the batch loop. When in file mode (no `$script:SourceFolderRoot`), always use `_compressed` suffix:

```powershell
if ($outputMode -eq "Compressed" -and $script:SourceFolderRoot) {
    $rel        = $file.FullName.Substring($folder.Length).TrimStart('\','/')
    $outputPath = Join-Path $folder "Compressed\$rel"
} else {
    $base       = [IO.Path]::GetFileNameWithoutExtension($file.Name)
    $outputPath = Join-Path $file.DirectoryName "${base}_compressed$([IO.Path]::GetExtension($file.Name))"
}
```

- [ ] **Step 10: Update form height**

The drop zone adds ~160px. Update form dimensions:

```powershell
$form.ClientSize  = [Drawing.Size]::new(480, 780)
$form.MinimumSize = [Drawing.Size]::new(496, 819)
$form.MaximumSize = [Drawing.Size]::new(496, 819)
```

> Adjust these exact values during testing so all controls fit without clipping.

- [ ] **Step 11: Verify**

```bash
powershell -ExecutionPolicy Bypass -File VideoCompressor.ps1
```

Test checklist:
1. Drop zone visible with "Drop files or folder here" placeholder
2. Drag a video file onto the drop zone → file appears in list, counter shows "1 files"
3. Drag a folder → scans recursively, shows "1 folder (N files)"
4. Click "Browse files" → modern picker opens (multiselect)
5. Click "Browse folder" → modern picker opens (folder mode)
6. Click "Clear" → list empties, counter resets
7. Click START with files selected → compression runs (using old `Compress-Video`)
8. Click START with no files → error dialog

- [ ] **Step 12: Commit**

```bash
git add VideoCompressor.ps1
git commit -m "feat: add drop zone UI with drag-drop, file/folder browse, and file list"
```

---

## Task 5: Mode Toggle (Video / Audio)

**Files:**
- Modify: `VideoCompressor.ps1` — add mode radio buttons, wrap settings in conditional panels

- [ ] **Step 1: Add mode script variable**

```powershell
$script:Mode = "Video"  # "Video" | "Audio"
```

- [ ] **Step 2: Insert MODE toggle row after sep1 (before settings)**

After the first separator, before the Resolution section:

```powershell
# -- Mode toggle ---------------------------------------------------------------
$lblModeLbl = New-Object Windows.Forms.Label
$lblModeLbl.Text = "MODE"; $lblModeLbl.Font = $fontLabel
$lblModeLbl.ForeColor = $clrMuted; $lblModeLbl.AutoSize = $true
$lblModeLbl.Location = [Drawing.Point]::new(24, $y)
$form.Controls.Add($lblModeLbl)

$y += 16

$modePanel = New-Object Windows.Forms.Panel
$modePanel.Location = [Drawing.Point]::new(24, $y)
$modePanel.Size = [Drawing.Size]::new(300, 30)
$modePanel.BackColor = $clrBg
$form.Controls.Add($modePanel)

$rbModeVideo = New-FmtBtn "Compress video"  0   145  $true
$rbModeAudio = New-FmtBtn "Extract audio"   149 145
$modePanel.Controls.Add($rbModeVideo)
$modePanel.Controls.Add($rbModeAudio)

$y += 40
```

- [ ] **Step 3: Wrap video-only settings in a panel**

Wrap Resolution, Max Size, Format controls in `$videoSettingsPanel`:

```powershell
$videoSettingsPanel = New-Object Windows.Forms.Panel
$videoSettingsPanel.Location = [Drawing.Point]::new(0, $y)
$videoSettingsPanel.Size = [Drawing.Size]::new(480, 130)
$videoSettingsPanel.BackColor = $clrBg
$form.Controls.Add($videoSettingsPanel)

# All resolution, size, format controls go inside $videoSettingsPanel
# with Y offsets relative to the panel (starting at 0)
```

Move all the Resolution + Max Size + Format controls to be children of `$videoSettingsPanel` instead of `$form`. Their Y positions become relative to the panel.

- [ ] **Step 4: Create audio settings panel (hidden by default)**

```powershell
$audioSettingsPanel = New-Object Windows.Forms.Panel
$audioSettingsPanel.Location = $videoSettingsPanel.Location  # same position
$audioSettingsPanel.Size = [Drawing.Size]::new(480, 130)
$audioSettingsPanel.BackColor = $clrBg
$audioSettingsPanel.Visible = $false
$form.Controls.Add($audioSettingsPanel)

# Audio format
$lblAudioFmtLbl = New-Object Windows.Forms.Label
$lblAudioFmtLbl.Text = "AUDIO FORMAT"; $lblAudioFmtLbl.Font = $fontLabel
$lblAudioFmtLbl.ForeColor = $clrMuted; $lblAudioFmtLbl.AutoSize = $true
$lblAudioFmtLbl.Location = [Drawing.Point]::new(24, 0)
$audioSettingsPanel.Controls.Add($lblAudioFmtLbl)

$audioFmtPanel = New-Object Windows.Forms.Panel
$audioFmtPanel.Location = [Drawing.Point]::new(24, 16)
$audioFmtPanel.Size = [Drawing.Size]::new(260, 30)
$audioFmtPanel.BackColor = $clrBg
$audioSettingsPanel.Controls.Add($audioFmtPanel)

$rbAudioMP3 = New-FmtBtn "MP3"  0   80  $true
$rbAudioAAC = New-FmtBtn "AAC"  84  80
$rbAudioWAV = New-FmtBtn "WAV"  168 80
$audioFmtPanel.Controls.Add($rbAudioMP3)
$audioFmtPanel.Controls.Add($rbAudioAAC)
$audioFmtPanel.Controls.Add($rbAudioWAV)

# Audio bitrate
$lblAudioBrLbl = New-Object Windows.Forms.Label
$lblAudioBrLbl.Text = "BITRATE"; $lblAudioBrLbl.Font = $fontLabel
$lblAudioBrLbl.ForeColor = $clrMuted; $lblAudioBrLbl.AutoSize = $true
$lblAudioBrLbl.Location = [Drawing.Point]::new(24, 56)
$audioSettingsPanel.Controls.Add($lblAudioBrLbl)

$audioBrPanel = New-Object Windows.Forms.Panel
$audioBrPanel.Location = [Drawing.Point]::new(24, 72)
$audioBrPanel.Size = [Drawing.Size]::new(300, 30)
$audioBrPanel.BackColor = $clrBg
$audioSettingsPanel.Controls.Add($audioBrPanel)

$rbBr128 = New-FmtBtn "128 kbps"  0   95  $false
$rbBr192 = New-FmtBtn "192 kbps"  99  95  $true
$rbBr320 = New-FmtBtn "320 kbps"  198 95
$audioBrPanel.Controls.Add($rbBr128)
$audioBrPanel.Controls.Add($rbBr192)
$audioBrPanel.Controls.Add($rbBr320)
```

- [ ] **Step 5: Wire mode toggle to show/hide panels**

```powershell
$toggleMode = {
    if ($rbModeVideo.Checked) {
        $script:Mode = "Video"
        $videoSettingsPanel.Visible = $true
        $audioSettingsPanel.Visible = $false
    } else {
        $script:Mode = "Audio"
        $videoSettingsPanel.Visible = $false
        $audioSettingsPanel.Visible = $true
    }
}

$rbModeVideo.Add_CheckedChanged($toggleMode)
$rbModeAudio.Add_CheckedChanged($toggleMode)
```

- [ ] **Step 6: Verify**

```bash
powershell -ExecutionPolicy Bypass -File VideoCompressor.ps1
```

Test: Click "Extract audio" → Resolution/Size/Format hide, Audio Format/Bitrate appear. Click "Compress video" → back to normal. No encoding wired yet.

- [ ] **Step 7: Commit**

```bash
git add VideoCompressor.ps1
git commit -m "feat: add mode toggle UI for video compression vs audio extraction"
```

---

## Task 6: Audio Extraction Encoding

**Files:**
- Modify: `VideoCompressor.ps1` — add `Invoke-AudioExtract` function, wire to START in audio mode

- [ ] **Step 1: Add `Invoke-AudioExtract` function (after `Compress-Video`)**

```powershell
function Invoke-AudioExtract {
    param(
        $File,
        [string]$OutputPath,
        [string]$AudioFormat,    # "MP3"|"AAC"|"WAV"
        [int]$AudioBitrateK,     # 128, 192, 320
        $LogBox,
        $StatusLabel = $null
    )

    $duration = Get-Duration $File.FullName

    # Pre-flight: check for audio stream
    $hasAudio = (& $script:FFprobePath -v quiet -select_streams a:0 `
        -show_entries stream=index -of csv=p=0 "$($File.FullName)" 2>&1) -match '\d'
    if (-not $hasAudio) {
        Write-Log $LogBox "  No audio track found, skipping." "Orange"
        return @{ Success = $false; Reason = "no-audio" }
    }

    # Determine codec and extension
    switch ($AudioFormat) {
        "MP3" { $codec = "libmp3lame"; $ext = ".mp3" }
        "AAC" { $codec = "aac";        $ext = ".aac" }
        "WAV" { $codec = "pcm_s16le";  $ext = ".wav" }
    }

    $outFull = [IO.Path]::ChangeExtension($OutputPath, $ext)
    $outDir  = Split-Path -Parent $outFull
    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

    $progressFile = Join-Path $env:TEMP "ffprog_$([guid]::NewGuid().ToString('N').Substring(0,8)).txt"

    try {
        $bitrateArgs = if ($AudioFormat -eq "WAV") { @() } else { @("-b:a", "${AudioBitrateK}k") }
        $ffArgs = @("-y", "-progress", $progressFile,
                    "-i", $File.FullName,
                    "-vn", "-c:a", $codec) + $bitrateArgs + @($outFull)

        $exit = Invoke-FFmpeg $ffArgs -TotalDuration $duration -StatusLabel $StatusLabel `
                    -PassLabel "Extracting audio" -ProgressFile $progressFile

        if ($exit -ne 0 -and -not $script:CancelRequested) {
            return @{ Success = $false }
        }
    } finally {
        if ($progressFile) { Remove-Item $progressFile -Force -ErrorAction SilentlyContinue }
    }

    if (-not $script:CancelRequested -and (Test-Path $outFull)) {
        $kb = [int]((Get-Item $outFull).Length / 1024)
        return @{ Success = $true; SizeKB = $kb; OutPath = $outFull }
    }
    return @{ Success = $false }
}
```

- [ ] **Step 2: Branch the START handler on mode**

In `$btnStart.Add_Click`, after validation and pre-flight, in the file processing loop, branch on `$script:Mode`:

```powershell
# Inside the for loop, replace the direct Compress-Video call:
if ($script:Mode -eq "Audio") {
    $audioFmt = if ($rbAudioAAC.Checked) { "AAC" }
                elseif ($rbAudioWAV.Checked) { "WAV" }
                else { "MP3" }
    $audioBr  = if ($rbBr128.Checked) { 128 }
                elseif ($rbBr320.Checked) { 320 }
                else { 192 }

    # Output path: change extension based on audio format
    if ($outputMode -eq "Compressed" -and $script:SourceFolderRoot) {
        $rel = $file.FullName.Substring($folder.Length).TrimStart('\','/')
        $outputPath = Join-Path $folder "Compressed\$rel"
    } else {
        $base = [IO.Path]::GetFileNameWithoutExtension($file.Name)
        $outputPath = Join-Path $file.DirectoryName "${base}$([IO.Path]::GetExtension($file.Name))"
    }

    try {
        $result = Invoke-AudioExtract $file $outputPath $audioFmt $audioBr $logBox $lblStatus
    } catch {
        $result = @{ Success = $false }
        Write-Log $logBox "  [x]  Exception: $_" "OrangeRed"
    }
} else {
    # Existing video compression path
    try {
        $result = Compress-Video $file $outputPath $maxSizeMB $maxRes $format $logBox $lblStatus
    } catch {
        $result = @{ Success = $false }
        Write-Log $logBox "  [x]  Exception: $_" "OrangeRed"
    }
}
```

- [ ] **Step 3: Skip Resolution/Size validation in audio mode**

In the START handler, wrap the resolution/size validation in a mode check:

```powershell
if ($script:Mode -eq "Video") {
    $maxRes    = 0
    $maxSizeMB = 0.0
    if (-not [int]::TryParse($txtRes.Text.Trim(), [ref]$maxRes) -or $maxRes -lt 100) {
        [Windows.Forms.MessageBox]::Show("Invalid resolution value.","Error","OK","Error") | Out-Null; return
    }
    if (-not [double]::TryParse($txtSize.Text.Trim().Replace(',','.'),
        [Globalization.NumberStyles]::Any, [Globalization.CultureInfo]::InvariantCulture, [ref]$maxSizeMB) `
        -or $maxSizeMB -le 0) {
        [Windows.Forms.MessageBox]::Show("Invalid file size value.","Error","OK","Error") | Out-Null; return
    }
    $format = if ($rbMOV.Checked) { "MOV" } else { "MP4" }
}
```

Also skip the pre-flight "too large" check when in Audio mode (it's not applicable).

- [ ] **Step 4: Update log header for audio mode**

```powershell
if ($script:Mode -eq "Audio") {
    Write-Log $logBox "Mode       : Extract audio ($audioFmt, ${audioBr} kbps)" "White"
} else {
    Write-Log $logBox "Resolution : ${maxRes}px   Max size: ${maxSizeMB} MB   Format: $format" "White"
}
```

- [ ] **Step 5: Verify**

```bash
powershell -ExecutionPolicy Bypass -File VideoCompressor.ps1
```

Test:
1. Switch to "Extract audio" mode
2. Drop a video file with audio
3. Click START → should extract audio as MP3 192kbps
4. Output file has `.mp3` extension
5. Drop a file without audio → log says "No audio track found, skipping"

- [ ] **Step 6: Commit**

```bash
git add VideoCompressor.ps1
git commit -m "feat: add audio extraction mode (MP3/AAC/WAV)"
```

---

## Task 7: Advanced Panel Structure

**Files:**
- Modify: `VideoCompressor.ps1` — add collapsible panel with all advanced controls

- [ ] **Step 1: Add script variables for advanced settings**

```powershell
$script:GpuMode       = "Auto"     # "Auto"|"CPU"|"NVIDIA"|"AMD"|"Intel"
$script:Codec         = "H.264"    # "H.264"|"H.265"
$script:ScaleAlgo     = "bicubic"  # "bicubic"|"lanczos"|"bilinear"
$script:Threads       = 0          # 0 = auto
$script:PlaySoundOnDone    = $true
$script:OpenFolderOnDone   = $false
```

- [ ] **Step 2: Add ADVANCED toggle button (after output mode, before START)**

```powershell
# -- Advanced toggle -----------------------------------------------------------
$ADVANCED_HEIGHT = 160

$btnAdvanced = New-Object Windows.Forms.Button
$btnAdvanced.Text = [char]0x25BC + "  ADVANCED"  # ▼ ADVANCED
$btnAdvanced.Location = [Drawing.Point]::new(24, $y)
$btnAdvanced.Size = [Drawing.Size]::new(432, 28)
$btnAdvanced.BackColor = $clrBg
$btnAdvanced.ForeColor = $clrMuted
$btnAdvanced.FlatStyle = "Flat"
$btnAdvanced.FlatAppearance.BorderColor = $clrBorder
$btnAdvanced.FlatAppearance.BorderSize = 0
$btnAdvanced.FlatAppearance.MouseOverBackColor = [Drawing.Color]::FromArgb(30, 30, 30)
$btnAdvanced.Font = $fontLabel
$btnAdvanced.TextAlign = [Drawing.ContentAlignment]::MiddleLeft
$btnAdvanced.Cursor = [Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnAdvanced)

$y += 32
$advYBase = $y  # remember where advanced panel starts
```

- [ ] **Step 3: Create the advanced panel (hidden by default)**

```powershell
$advancedPanel = New-Object Windows.Forms.Panel
$advancedPanel.Location = [Drawing.Point]::new(24, $y)
$advancedPanel.Size = [Drawing.Size]::new(432, $ADVANCED_HEIGHT)
$advancedPanel.BackColor = $clrBg
$advancedPanel.Visible = $false
$form.Controls.Add($advancedPanel)

$ay = 0  # Y offset inside advanced panel

# Row 1: GPU + Codec
$lblGpuLbl = New-Object Windows.Forms.Label
$lblGpuLbl.Text = "GPU ACCELERATION"; $lblGpuLbl.Font = $fontLabel
$lblGpuLbl.ForeColor = $clrMuted; $lblGpuLbl.AutoSize = $true
$lblGpuLbl.Location = [Drawing.Point]::new(0, $ay)
$advancedPanel.Controls.Add($lblGpuLbl)

$lblCodecLbl = New-Object Windows.Forms.Label
$lblCodecLbl.Text = "CODEC"; $lblCodecLbl.Font = $fontLabel
$lblCodecLbl.ForeColor = $clrMuted; $lblCodecLbl.AutoSize = $true
$lblCodecLbl.Location = [Drawing.Point]::new(230, $ay)
$advancedPanel.Controls.Add($lblCodecLbl)

$ay += 16

$cmbGpu = New-Object Windows.Forms.ComboBox
$cmbGpu.Items.AddRange(@("Auto", "CPU", "NVIDIA", "AMD", "Intel"))
$cmbGpu.SelectedIndex = 0
$cmbGpu.Location = [Drawing.Point]::new(0, $ay)
$cmbGpu.Size = [Drawing.Size]::new(200, 28)
$cmbGpu.BackColor = $clrInput
$cmbGpu.ForeColor = $clrText
$cmbGpu.Font = $fontSmall
$cmbGpu.DropDownStyle = "DropDownList"
$cmbGpu.FlatStyle = "Flat"
$advancedPanel.Controls.Add($cmbGpu)

$codecPanel = New-Object Windows.Forms.Panel
$codecPanel.Location = [Drawing.Point]::new(230, $ay)
$codecPanel.Size = [Drawing.Size]::new(200, 30)
$codecPanel.BackColor = $clrBg
$advancedPanel.Controls.Add($codecPanel)

$rbH264 = New-FmtBtn "H.264"  0   95  $true
$rbH265 = New-FmtBtn "H.265"  99  95
$codecPanel.Controls.Add($rbH264)
$codecPanel.Controls.Add($rbH265)

$ay += 40

# Row 2: Scale algo + Threads
$lblScaleLbl = New-Object Windows.Forms.Label
$lblScaleLbl.Text = "SCALE ALGORITHM"; $lblScaleLbl.Font = $fontLabel
$lblScaleLbl.ForeColor = $clrMuted; $lblScaleLbl.AutoSize = $true
$lblScaleLbl.Location = [Drawing.Point]::new(0, $ay)
$advancedPanel.Controls.Add($lblScaleLbl)

$lblThreadsLbl = New-Object Windows.Forms.Label
$lblThreadsLbl.Text = "CPU THREADS (0=auto)"; $lblThreadsLbl.Font = $fontLabel
$lblThreadsLbl.ForeColor = $clrMuted; $lblThreadsLbl.AutoSize = $true
$lblThreadsLbl.Location = [Drawing.Point]::new(230, $ay)
$advancedPanel.Controls.Add($lblThreadsLbl)

$ay += 16

$cmbScale = New-Object Windows.Forms.ComboBox
$cmbScale.Items.AddRange(@("bicubic", "lanczos", "bilinear"))
$cmbScale.SelectedIndex = 0
$cmbScale.Location = [Drawing.Point]::new(0, $ay)
$cmbScale.Size = [Drawing.Size]::new(200, 28)
$cmbScale.BackColor = $clrInput
$cmbScale.ForeColor = $clrText
$cmbScale.Font = $fontSmall
$cmbScale.DropDownStyle = "DropDownList"
$cmbScale.FlatStyle = "Flat"
$advancedPanel.Controls.Add($cmbScale)

$txtThreads = New-Object Windows.Forms.TextBox
$txtThreads.Text = "0"
$txtThreads.Location = [Drawing.Point]::new(230, $ay)
$txtThreads.Size = [Drawing.Size]::new(60, 28)
$txtThreads.BackColor = $clrInput
$txtThreads.ForeColor = $clrText
$txtThreads.BorderStyle = "FixedSingle"
$txtThreads.Font = $fontSmall
$advancedPanel.Controls.Add($txtThreads)

$ay += 40

# Row 3: Checkboxes
$chkSound = New-Object Windows.Forms.CheckBox
$chkSound.Text = "Play sound when done"
$chkSound.Location = [Drawing.Point]::new(0, $ay)
$chkSound.AutoSize = $true
$chkSound.Checked = $true
$chkSound.ForeColor = $clrText
$chkSound.Font = $fontSmall
$advancedPanel.Controls.Add($chkSound)

$chkOpenFolder = New-Object Windows.Forms.CheckBox
$chkOpenFolder.Text = "Open output folder when done"
$chkOpenFolder.Location = [Drawing.Point]::new(230, $ay)
$chkOpenFolder.AutoSize = $true
$chkOpenFolder.Checked = $false
$chkOpenFolder.ForeColor = $clrText
$chkOpenFolder.Font = $fontSmall
$advancedPanel.Controls.Add($chkOpenFolder)
```

- [ ] **Step 4: Wire the toggle button**

```powershell
$script:AdvancedVisible = $false

$btnAdvanced.Add_Click({
    if ($script:AdvancedVisible) {
        $advancedPanel.Visible = $false
        $btnAdvanced.Text = [char]0x25BC + "  ADVANCED"  # ▼
        $script:AdvancedVisible = $false

        # Shift all controls below back up
        $shift = -$ADVANCED_HEIGHT
    } else {
        # Check if expanded form fits on screen (UI review: 866px won't fit on 768p laptops)
        $screenH = [Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Height
        $expandedH = $form.Height + $ADVANCED_HEIGHT
        if ($expandedH -gt $screenH) {
            # Don't expand beyond screen — show warning or reduce panel
            # For now, proceed but reposition form if needed
            $form.Top = [Math]::Max(0, $screenH - $expandedH)
        }

        $advancedPanel.Visible = $true
        $btnAdvanced.Text = [char]0x25B2 + "  ADVANCED"  # ▲
        $script:AdvancedVisible = $true

        $shift = $ADVANCED_HEIGHT
    }

    # Move everything below the advanced panel
    foreach ($ctl in @($btnStart, $progress, $lblStatus, $logBox, $lblCopy)) {
        $ctl.Location = [Drawing.Point]::new($ctl.Location.X, $ctl.Location.Y + $shift)
    }

    # Resize form
    $newH = $form.ClientSize.Height + $shift
    $form.ClientSize  = [Drawing.Size]::new(480, $newH)
    $form.MinimumSize = [Drawing.Size]::new(496, $newH + 39)
    $form.MaximumSize = [Drawing.Size]::new(496, $newH + 39)
})
```

- [ ] **Step 5: Wire advanced controls to script variables**

```powershell
$cmbGpu.Add_SelectedIndexChanged({
    $script:GpuMode = $cmbGpu.SelectedItem.ToString()
})

$rbH264.Add_CheckedChanged({
    if ($rbH264.Checked) { $script:Codec = "H.264" }
})
$rbH265.Add_CheckedChanged({
    if ($rbH265.Checked) { $script:Codec = "H.265" }
})

$cmbScale.Add_SelectedIndexChanged({
    $script:ScaleAlgo = $cmbScale.SelectedItem.ToString()
})

$txtThreads.Add_Leave({
    $val = 0
    if (-not [int]::TryParse($txtThreads.Text.Trim(), [ref]$val) -or $val -lt 0 -or $val -gt 64) {
        $txtThreads.Text = "0"
        $script:Threads = 0
    } else {
        $script:Threads = $val
    }
})
```

- [ ] **Step 6: Verify**

```bash
powershell -ExecutionPolicy Bypass -File VideoCompressor.ps1
```

Test:
1. Click "▼ ADVANCED" → panel expands, form grows, START/log shift down
2. Click "▲ ADVANCED" → panel collapses, form shrinks back
3. All dropdowns/textboxes work
4. Checkboxes toggle

- [ ] **Step 7: Commit**

```bash
git add VideoCompressor.ps1
git commit -m "feat: add collapsible Advanced panel with GPU, codec, scale, threads controls"
```

---

## Task 8: Sound Notification + Open Output Folder

**Files:**
- Modify: `VideoCompressor.ps1` — add post-batch logic in START handler

- [ ] **Step 1: Add sound + open-folder to the post-batch block**

In the START click handler, after the batch summary log line and before restoring the START button, add:

```powershell
# Post-batch actions
if (-not $script:CancelRequested -and $done -gt 0) {
    if ($chkSound.Checked) {
        try { [System.Media.SystemSounds]::Asterisk.Play() } catch {}
    }
    if ($chkOpenFolder.Checked) {
        $openPath = if ($outputMode -eq "Compressed" -and $script:SourceFolderRoot) {
            Join-Path $folder "Compressed"
        } else {
            $folder
        }
        if (Test-Path $openPath) {
            Start-Process "explorer.exe" -ArgumentList $openPath
        }
    }
}
```

- [ ] **Step 2: Verify**

```bash
powershell -ExecutionPolicy Bypass -File VideoCompressor.ps1
```

Test:
1. Open Advanced panel, ensure "Play sound when done" is checked
2. Compress a file → system "Asterisk" sound plays after completion
3. Check "Open output folder when done" → folder opens in Explorer after batch
4. Cancel mid-batch → no sound, no folder open

- [ ] **Step 3: Commit**

```bash
git add VideoCompressor.ps1
git commit -m "feat: add sound notification and open-folder on batch completion"
```

---

## Task 9: Thread Control

**Files:**
- Modify: `VideoCompressor.ps1` — add `-threads` arg to `Invoke-FFmpeg` calls

- [ ] **Step 1: Update `Invoke-FFmpeg` to accept a Threads parameter**

Change the `Invoke-FFmpeg` function signature:

```powershell
function Invoke-FFmpeg {
    param(
        [string[]]$FfmpegArgs,
        [double]$TotalDuration = 0,
        $StatusLabel = $null,
        [string]$PassLabel = "",
        [string]$ProgressFile = "",
        [int]$Threads = 0
    )
```

At the top of the function body, prepend thread args if non-zero:

```powershell
    if ($Threads -gt 0) {
        $FfmpegArgs = @("-threads", $Threads.ToString()) + $FfmpegArgs
    }
```

- [ ] **Step 2: Pass threads from `Compress-Video`**

Update `Compress-Video` signature to accept `[int]$Threads = 0` parameter.

In both pass-1 and pass-2 calls to `Invoke-FFmpeg`, add `-Threads $Threads`:

```powershell
$exit1 = Invoke-FFmpeg $p1 -Threads $Threads
# ...
$exit2 = Invoke-FFmpeg $p2 -TotalDuration $duration -StatusLabel $StatusLabel -PassLabel "Pass 2/2" -ProgressFile $progressFile -Threads $Threads
```

- [ ] **Step 3: Pass threads from `Invoke-AudioExtract`**

Update `Invoke-AudioExtract` signature to accept `[int]$Threads = 0`.

```powershell
$exit = Invoke-FFmpeg $args -TotalDuration $duration -StatusLabel $StatusLabel `
            -PassLabel "Extracting audio" -ProgressFile $progressFile -Threads $Threads
```

- [ ] **Step 4: Pass `$script:Threads` from START handler**

In the batch loop where `Compress-Video` or `Invoke-AudioExtract` is called, pass the threads value:

```powershell
$result = Compress-Video $file $outputPath $maxSizeMB $maxRes $format $logBox $lblStatus -Threads $script:Threads
# and
$result = Invoke-AudioExtract $file $outputPath $audioFmt $audioBr $logBox $lblStatus -Threads $script:Threads
```

- [ ] **Step 5: Verify**

```bash
powershell -ExecutionPolicy Bypass -File VideoCompressor.ps1
```

Test: Set threads to 2 in Advanced panel, compress a file. Check task manager — FFmpeg should use 2 threads. Set to 0 — auto behavior.

- [ ] **Step 6: Commit**

```bash
git add VideoCompressor.ps1
git commit -m "feat: add thread control (-threads N) for FFmpeg"
```

---

## Task 10: H.265 Codec

**Files:**
- Modify: `VideoCompressor.ps1` — branch in `Compress-Video` for x265 pass flags

- [ ] **Step 1: Update `Compress-Video` signature**

Add `[string]$Codec = "H.264"` parameter.

- [ ] **Step 2: Branch encoder and pass flags**

Replace the hardcoded `libx264` encoder selection in `Compress-Video` with:

```powershell
$encoderName = if ($Codec -eq "H.265") { "libx265" } else { "libx264" }

# Pass flags differ between x264 and x265
if ($Codec -eq "H.265") {
    $passFlag1 = @("-x265-params", "pass=1:stats=${passLog}.log")
    $passFlag2 = @("-x265-params", "pass=2:stats=${passLog}.log")
    $extraParams = @()  # no mbtree flag for x265
} else {
    $passFlag1 = @("-pass", "1", "-passlogfile", $passLog)
    $passFlag2 = @("-pass", "2", "-passlogfile", $passLog)
    $extraParams = @("-x264-params", "mbtree=0")
}
```

- [ ] **Step 3: Rebuild pass-1 and pass-2 argument arrays**

```powershell
# Pass 1
$p1 = @("-y", "-i", $File.FullName, "-vf", $scale,
        "-c:v", $encoderName, "-b:v", "${vbrKbps}k") +
       $extraParams + $passFlag1 + @("-an", "-f", "null", "NUL")

# Pass 2
$p2 = @("-y", "-progress", $progressFile, "-i", $File.FullName, "-vf", $scale,
        "-c:v", $encoderName, "-b:v", "${vbrKbps}k") +
       $extraParams + $passFlag2 + @("-preset", "slow") + $audioArgs +
       @("-movflags", "+faststart", $outFull)
```

- [ ] **Step 4: Pass codec from START handler**

```powershell
$result = Compress-Video $file $outputPath $maxSizeMB $maxRes $format $logBox $lblStatus `
              -Threads $script:Threads -Codec $script:Codec
```

- [ ] **Step 5: Log codec choice**

In the batch header log:
```powershell
Write-Log $logBox "Resolution : ${maxRes}px   Max size: ${maxSizeMB} MB   Format: $format   Codec: $($script:Codec)" "White"
```

- [ ] **Step 6: Verify**

```bash
powershell -ExecutionPolicy Bypass -File VideoCompressor.ps1
```

Test:
1. Open Advanced → select H.265
2. Compress a single short video
3. Output should be valid H.265 file (verify with `ffprobe -v quiet -show_streams output.mp4` — `codec_name=hevc`)
4. Switch back to H.264 → confirm still works

- [ ] **Step 7: Commit**

```bash
git add VideoCompressor.ps1
git commit -m "feat: add H.265 (HEVC) codec support with x265 two-pass"
```

---

## Task 11: GPU Detection

**Files:**
- Modify: `VideoCompressor.ps1` — add `Get-AvailableGPUEncoders` function, call on Form_Shown

- [ ] **Step 1: Add GPU detection function (in helpers section)**

```powershell
function Get-AvailableGPUEncoders {
    $script:AvailableGPUEncoders = @{
        NVIDIA = $false
        AMD    = $false
        Intel  = $false
    }
    if (-not $script:FFmpegPath) { return }

    try {
        $output = & $script:FFmpegPath -encoders 2>&1 | Out-String
        if ($output -match 'h264_nvenc')  { $script:AvailableGPUEncoders.NVIDIA = $true }
        if ($output -match 'h264_amf')    { $script:AvailableGPUEncoders.AMD    = $true }
        if ($output -match 'h264_qsv')    { $script:AvailableGPUEncoders.Intel  = $true }
    } catch {}
}
```

- [ ] **Step 2: Call on Form_Shown after FFmpeg found**

In the `$form.Add_Shown` handler, after `Write-Log $logBox "FFmpeg found: ..."`:

```powershell
Get-AvailableGPUEncoders
$gpuList = @()
if ($script:AvailableGPUEncoders.NVIDIA) { $gpuList += "NVIDIA" }
if ($script:AvailableGPUEncoders.AMD)    { $gpuList += "AMD" }
if ($script:AvailableGPUEncoders.Intel)  { $gpuList += "Intel" }
if ($gpuList.Count -gt 0) {
    Write-Log $logBox "GPU encoders found: $($gpuList -join ', ')" "LightGreen"
} else {
    Write-Log $logBox "No GPU encoders found (CPU only)" "DimGray"
}
```

- [ ] **Step 3: Add helper to resolve "Auto" GPU mode**

```powershell
function Resolve-GpuMode {
    param([string]$RequestedMode)
    if ($RequestedMode -eq "CPU") { return "CPU" }
    if ($RequestedMode -ne "Auto") {
        # Specific GPU requested — check if available
        if ($script:AvailableGPUEncoders[$RequestedMode]) { return $RequestedMode }
        return "CPU"  # not available, fall back
    }
    # Auto: pick first available
    if ($script:AvailableGPUEncoders.NVIDIA) { return "NVIDIA" }
    if ($script:AvailableGPUEncoders.AMD)    { return "AMD" }
    if ($script:AvailableGPUEncoders.Intel)  { return "Intel" }
    return "CPU"
}
```

- [ ] **Step 4: Verify**

```bash
powershell -ExecutionPolicy Bypass -File VideoCompressor.ps1
```

Expected: On startup, log shows "GPU encoders found: NVIDIA" (or appropriate) or "No GPU encoders found (CPU only)".

- [ ] **Step 5: Commit**

```bash
git add VideoCompressor.ps1
git commit -m "feat: add GPU encoder detection on startup (NVIDIA/AMD/Intel)"
```

---

## Task 12: GPU Encoding Path

**Files:**
- Modify: `VideoCompressor.ps1` — branch in `Compress-Video` for 1-pass GPU encoding per vendor

- [ ] **Step 1: Add `$GpuMode` parameter to `Compress-Video`**

```powershell
function Compress-Video {
    param($File, $OutputPath, $MaxSizeMB, $MaxRes, $Format, $LogBox, $StatusLabel = $null,
          [int]$Threads = 0, [string]$Codec = "H.264",
          [string]$GpuMode = "Auto", [string]$ScaleAlgo = "bicubic")
```

- [ ] **Step 2: Resolve GPU mode and select encoder**

At the top of `Compress-Video`, after duration/audio checks:

```powershell
$resolvedGpu = Resolve-GpuMode $GpuMode
$isGpu = ($resolvedGpu -ne "CPU")

# Select encoder name
if ($isGpu) {
    $encoderName = switch ($resolvedGpu) {
        "NVIDIA" { if ($Codec -eq "H.265") { "hevc_nvenc" } else { "h264_nvenc" } }
        "AMD"    { if ($Codec -eq "H.265") { "hevc_amf"  } else { "h264_amf"  } }
        "Intel"  { if ($Codec -eq "H.265") { "hevc_qsv"  } else { "h264_qsv"  } }
    }
} else {
    $encoderName = if ($Codec -eq "H.265") { "libx265" } else { "libx264" }
}
```

- [ ] **Step 3: Branch encoding between GPU (1-pass) and CPU (2-pass)**

Replace the existing pass-1 / pass-2 block with:

```powershell
$scale = "scale='if(gte(iw,ih),$MaxRes,-2)':'if(gte(iw,ih),-2,$MaxRes)':flags=$ScaleAlgo"

# Audio args and pass log must be defined BEFORE the GPU/CPU branch
$audioArgs = if ($hasAudio) { @("-c:a","aac","-b:a","${audioBitrateK}k") } else { @("-an") }
$passLog = Join-Path $env:TEMP "ffpass_$([guid]::NewGuid().ToString('N').Substring(0,8))"
$progressFile = ""

if ($isGpu) {
    # GPU: single pass
    if ($StatusLabel) { $StatusLabel.Text = "Encoding (GPU: $resolvedGpu)..." }
    Write-Log $LogBox "  Using encoder: $encoderName  (GPU: $resolvedGpu)" "DimGray"

    $bitrateArgs = @("-b:v", "${vbrKbps}k")
    # Vendor-specific rate control (flags from SE source: VideoEncoders.java)
    switch ($resolvedGpu) {
        "NVIDIA" { $bitrateArgs += @("-b_ref_mode", "0",
                                     "-maxrate", "$([int]($vbrKbps * 1.5))k",
                                     "-bufsize", "$([int]($vbrKbps * 2))k") }
        "AMD"    { $bitrateArgs += @("-rc", "cbr") }
        "Intel"  { }  # QSV uses default rate control
    }

    $progressFile = Join-Path $env:TEMP "ffprog_$([guid]::NewGuid().ToString('N').Substring(0,8)).txt"
    $gpuArgs = @("-y", "-progress", $progressFile, "-i", $File.FullName,
                 "-vf", $scale, "-c:v", $encoderName) + $bitrateArgs +
               $audioArgs + @("-movflags", "+faststart", $outFull)

    $exitGpu = Invoke-FFmpeg $gpuArgs -TotalDuration $duration -StatusLabel $StatusLabel `
                   -PassLabel "GPU encode" -ProgressFile $progressFile -Threads $Threads

    if ($progressFile) { Remove-Item $progressFile -Force -ErrorAction SilentlyContinue }

    if ($exitGpu -ne 0 -and -not $script:CancelRequested) {
        # GPU failed — fallback to CPU
        Write-Log $LogBox "  GPU encode failed, retrying with CPU..." "Orange"
        $isGpu = $false
        $encoderName = if ($Codec -eq "H.265") { "libx265" } else { "libx264" }
        # Fall through to CPU path below
    }
}

if (-not $isGpu -and -not $script:CancelRequested) {
    # CPU: two-pass
    if ($Codec -eq "H.265") {
        $passFlag1 = @("-x265-params", "pass=1:stats=${passLog}.log")
        $passFlag2 = @("-x265-params", "pass=2:stats=${passLog}.log")
        $extraParams = @()
    } else {
        $passFlag1 = @("-pass", "1", "-passlogfile", $passLog)
        $passFlag2 = @("-pass", "2", "-passlogfile", $passLog)
        $extraParams = @("-x264-params", "mbtree=0")
    }

    # Pass 1
    if ($StatusLabel) { $StatusLabel.Text = "Pass 1/2 -- analyzing..." }
    $p1 = @("-y", "-i", $File.FullName, "-vf", $scale,
            "-c:v", $encoderName, "-b:v", "${vbrKbps}k") +
           $extraParams + $passFlag1 + @("-an", "-f", "null", "NUL")
    $exit1 = Invoke-FFmpeg $p1 -Threads $Threads
    if ($exit1 -ne 0 -and -not $script:CancelRequested) {
        return @{ Success = $false }
    }

    if ($script:CancelRequested) { return @{ Success = $false } }

    # Pass 2
    $progressFile = Join-Path $env:TEMP "ffprog_$([guid]::NewGuid().ToString('N').Substring(0,8)).txt"
    $p2 = @("-y", "-progress", $progressFile, "-i", $File.FullName, "-vf", $scale,
            "-c:v", $encoderName, "-b:v", "${vbrKbps}k") +
           $extraParams + $passFlag2 + @("-preset", "slow") + $audioArgs +
           @("-movflags", "+faststart", $outFull)
    $exit2 = Invoke-FFmpeg $p2 -TotalDuration $duration -StatusLabel $StatusLabel `
                 -PassLabel "Pass 2/2" -ProgressFile $progressFile -Threads $Threads
    if ($progressFile) { Remove-Item $progressFile -Force -ErrorAction SilentlyContinue }
    if ($exit2 -ne 0 -and -not $script:CancelRequested) {
        return @{ Success = $false }
    }
}
```

- [ ] **Step 4: Update START handler to pass GPU and Scale params**

```powershell
$result = Compress-Video $file $outputPath $maxSizeMB $maxRes $format $logBox $lblStatus `
              -Threads $script:Threads -Codec $script:Codec `
              -GpuMode $script:GpuMode -ScaleAlgo $script:ScaleAlgo
```

- [ ] **Step 5: Update summary log line**

```powershell
$gpuSummary = Resolve-GpuMode $script:GpuMode
$summary += "  |  GPU: $gpuSummary ($encoderUsed)  |  Threads: $(if ($script:Threads -eq 0) {'auto'} else {$script:Threads})"
```

For a cleaner approach, track the encoder used during batch:

```powershell
# Before batch loop:
$script:LastEncoderUsed = ""

# Inside Compress-Video, after resolving encoder:
$script:LastEncoderUsed = $encoderName
```

Then in the summary:
```powershell
$gpuLabel = if ($script:LastEncoderUsed -match 'nvenc|amf|qsv') { Resolve-GpuMode $script:GpuMode } else { "CPU" }
Write-Log $logBox "Done: $done successful  |  Encoder: $($script:LastEncoderUsed)  |  Threads: $(if ($script:Threads -eq 0) {'auto'} else {$script:Threads})" $(if ($script:CancelRequested) { "Orange" } else { "Yellow" })
```

- [ ] **Step 6: Verify**

```bash
powershell -ExecutionPolicy Bypass -File VideoCompressor.ps1
```

Test matrix (test what hardware is available):
1. Auto mode + NVIDIA card → should use h264_nvenc (single pass, fast)
2. Force CPU → should use libx264 (two pass)
3. If no GPU: Auto → falls back to CPU
4. GPU encode deliberately failing → should retry on CPU (test by forcing a GPU that doesn't exist)

- [ ] **Step 7: Commit**

```bash
git add VideoCompressor.ps1
git commit -m "feat: add GPU encoding (NVIDIA/AMD/Intel) with CPU fallback"
```

---

## Task 13: Scale Algorithm

**Files:**
- Modify: `VideoCompressor.ps1` — already handled in Task 12 (`:flags=$ScaleAlgo` in scale filter)

This was already implemented in Task 12 Step 3 where the scale filter string was updated to:

```powershell
$scale = "scale='if(gte(iw,ih),$MaxRes,-2)':'if(gte(iw,ih),-2,$MaxRes)':flags=$ScaleAlgo"
```

- [ ] **Step 1: Verify scale algorithm is passed correctly**

Confirm that `$script:ScaleAlgo` is being read from the `$cmbScale` ComboBox (wired in Task 7, Step 5) and passed through to `Compress-Video` (done in Task 12, Step 4).

- [ ] **Step 2: Verify**

```bash
powershell -ExecutionPolicy Bypass -File VideoCompressor.ps1
```

Test: Open Advanced → change Scale to "lanczos" → compress a file. Check log or output quality (lanczos produces sharper output than bicubic on downscale).

- [ ] **Step 3: Commit**

```bash
git add VideoCompressor.ps1
git commit -m "feat: add scale algorithm selection (bicubic/lanczos/bilinear)"
```

---

## Task 14: Full End-to-End Testing

**Files:**
- No code changes — this is a testing pass

- [ ] **Step 1: Test matrix — video compression**

| Test | Mode | Source | GPU | Codec | Scale | Threads | Output | Expected |
|------|------|--------|-----|-------|-------|---------|--------|----------|
| V1 | Video | Drop 1 file | Auto | H.264 | bicubic | 0 | Alongside | ✓ compressed file created |
| V2 | Video | Drop folder | CPU | H.264 | lanczos | 2 | Compressed/ | ✓ all files in subfolder |
| V3 | Video | Browse files (2) | Auto | H.265 | bicubic | 0 | Alongside | ✓ H.265 output |
| V4 | Video | Browse folder | Force GPU | H.264 | bilinear | 0 | Compressed/ | ✓ GPU encode |
| V5 | Video | Drop file | CPU | H.265 | bicubic | 4 | Alongside | ✓ x265 two-pass |

Run each test. Verify output file exists, plays, is correct codec.

- [ ] **Step 2: Test matrix — audio extraction**

| Test | Format | Bitrate | Source | Expected |
|------|--------|---------|--------|----------|
| A1 | MP3 | 192 | Video with audio | .mp3 file created |
| A2 | AAC | 320 | Video with audio | .aac file created |
| A3 | WAV | — | Video with audio | .wav file created |
| A4 | MP3 | 128 | Video without audio | "No audio track" in log |

- [ ] **Step 3: Test UI interactions**

1. Advanced panel open/close cycles (10x rapid clicks — no UI glitch)
2. Mode toggle back and forth (video → audio → video)
3. Clear then add files, Clear again
4. Start compression, click STOP mid-batch → cancellation works
5. Drag-drop edge cases: drag non-video file (should be filtered), drag mix of video + non-video
6. Close form during processing → warning dialog, can't close

- [ ] **Step 4: Test FFmpeg auto-install**

On a machine without FFmpeg, verify the auto-install flow still works:
1. Remove FFmpeg from PATH
2. Launch app → "FFmpeg not found" message
3. Click START → winget install or direct download
4. After install → FFmpeg found, GPU detection runs, compression works

- [ ] **Step 5: Fix any regressions found**

Address issues discovered during testing. After fixes, re-run the failing test case.

- [ ] **Step 6: Commit fixes (if any)**

```bash
git add VideoCompressor.ps1
git commit -m "fix: address e2e test regressions"
```

---

## Task 15: Compile EXE + Push to GitHub

**Files:**
- Regenerate: `VideoCompressor.exe` via `compile.ps1`

- [ ] **Step 1: Review compile.ps1**

Read `compile.ps1` to understand the ps2exe invocation and any flags used.

- [ ] **Step 2: Run compilation**

```bash
powershell -ExecutionPolicy Bypass -File compile.ps1
```

Expected: `VideoCompressor.exe` generated without errors.

- [ ] **Step 3: Test the EXE**

Run `VideoCompressor.exe` directly (not the .ps1). Verify:
1. Window opens with correct brand colors + fonts
2. Drop zone works
3. Mode toggle works
4. Advanced panel opens/closes
5. Compression completes successfully
6. Audio extraction works

- [ ] **Step 4: Test on a clean machine (if possible)**

Copy the EXE to a machine without FFmpeg installed. Run it. Verify FFmpeg auto-install works through the EXE.

- [ ] **Step 5: Commit the EXE**

```bash
git add VideoCompressor.ps1 VideoCompressor.exe
git commit -m "release: Chucha v2 — GPU, H.265, audio extraction, drop zone, advanced panel"
```

- [ ] **Step 6: Push to GitHub**

```bash
git push origin main
```

---

## Appendix A: Full `Compress-Video` Signature (Final)

After all tasks, the function signature is:

```powershell
function Compress-Video {
    param(
        $File,
        [string]$OutputPath,
        [double]$MaxSizeMB,
        [int]$MaxRes,
        [string]$Format,
        $LogBox,
        $StatusLabel = $null,
        [int]$Threads = 0,
        [string]$Codec = "H.264",
        [string]$GpuMode = "Auto",
        [string]$ScaleAlgo = "bicubic"
    )
```

## Appendix B: Full `Invoke-AudioExtract` Signature (Final)

```powershell
function Invoke-AudioExtract {
    param(
        $File,
        [string]$OutputPath,
        [string]$AudioFormat,
        [int]$AudioBitrateK,
        $LogBox,
        $StatusLabel = $null,
        [int]$Threads = 0
    )
```

## Appendix C: Script Variable Registry (All new v2 vars)

```powershell
$script:SourceFiles            = @()       # FileInfo[] — files to process
$script:SourceFolderRoot       = $null     # string — folder path when folder mode
$script:VideoExtensions        = @(...)    # string[] — valid video extensions
$script:Mode                   = "Video"   # "Video"|"Audio"
$script:GpuMode                = "Auto"    # "Auto"|"CPU"|"NVIDIA"|"AMD"|"Intel"
$script:Codec                  = "H.264"   # "H.264"|"H.265"
$script:ScaleAlgo              = "bicubic" # "bicubic"|"lanczos"|"bilinear"
$script:Threads                = 0         # 0–64
$script:PlaySoundOnDone        = $true
$script:OpenFolderOnDone       = $false
$script:AdvancedVisible        = $false
$script:AvailableGPUEncoders   = @{}       # hashtable: NVIDIA/AMD/Intel → bool
$script:HasModernPicker        = $false    # IFileOpenDialog COM available
$script:FontCollection         = $null     # PrivateFontCollection
$script:FontCormorant          = $null     # font family name or null
$script:FontRaleway            = $null     # font family name or null
$script:FontTempFiles          = @()       # temp font file paths for cleanup
$script:LastEncoderUsed        = ""        # for summary log
```

## Appendix D: GPU → FFmpeg Flag Reference

From spec section 5 and Shutter Encoder analysis:

| GPU | H.264 encoder | H.265 encoder | Rate control flags |
|-----|---------------|---------------|--------------------|
| NVIDIA | `h264_nvenc` | `hevc_nvenc` | `-b_ref_mode 0 -b:v Nk -maxrate 1.5*Nk -bufsize 2*Nk` |
| AMD | `h264_amf` | `hevc_amf` | `-b:v Nk -rc cbr` |
| Intel | `h264_qsv` | `hevc_qsv` | `-b:v Nk` (default rc) |
| CPU | `libx264` | `libx265` | `-b:v Nk` (two-pass controls bitrate) |
