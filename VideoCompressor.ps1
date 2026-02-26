Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$script:FFmpegPath        = $null
$script:FFprobePath       = $null
$script:CancelRequested   = $false
$script:CurrentFFmpegProc = $null
$script:IsProcessing      = $false

# --- FFmpeg detection & install -----------------------------------------------

function Find-FFmpeg {
    $candidates = @()

    try {
        $exeDir = Split-Path -Parent ([Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
        $candidates += Join-Path $exeDir "ffmpeg.exe"
        $candidates += Join-Path $exeDir "bin\ffmpeg.exe"
    } catch {}
    if ($PSScriptRoot) {
        $candidates += Join-Path $PSScriptRoot "ffmpeg.exe"
        $candidates += Join-Path $PSScriptRoot "bin\ffmpeg.exe"
    }

    $inPath = Get-Command ffmpeg -ErrorAction SilentlyContinue
    if ($inPath) { $candidates += $inPath.Source }

    $wingetBase = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages"
    if (Test-Path $wingetBase) {
        $wg = Get-ChildItem $wingetBase -Filter "ffmpeg.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($wg) { $candidates += $wg.FullName }
    }

    $appLocal = "$env:LOCALAPPDATA\VideoCompressor\ffmpeg"
    if (Test-Path $appLocal) {
        $al = Get-ChildItem $appLocal -Filter "ffmpeg.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($al) { $candidates += $al.FullName }
    }

    $candidates += @(
        "C:\Program Files\ffmpeg\bin\ffmpeg.exe",
        "C:\ffmpeg\bin\ffmpeg.exe",
        "$env:USERPROFILE\scoop\shims\ffmpeg.exe",
        "$env:USERPROFILE\AppData\Local\Programs\ffmpeg\bin\ffmpeg.exe"
    )

    $scanRoots = @("C:\", "D:\", "E:\")
    $knownDirs = @(
        "ComfiUi","ComfyUI","pinokio","Blender","DaVinci","Reallusion",
        "obs-studio","HandBrake","kdenlive","Shotcut"
    )
    foreach ($root in $scanRoots) {
        if (-not (Test-Path $root)) { continue }
        foreach ($dir in $knownDirs) {
            $hit = Get-ChildItem "$root*$dir*" -ErrorAction SilentlyContinue |
                   Where-Object { $_.PSIsContainer } | Select-Object -First 1
            if ($hit) {
                $ff = Get-ChildItem $hit.FullName -Filter "ffmpeg.exe" -Recurse -Depth 6 -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($ff) { $candidates += $ff.FullName }
            }
        }
    }

    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c -ErrorAction SilentlyContinue)) { return $c }
    }
    return $null
}

function Install-FFmpegSilently {
    param($LogBox, $StatusLabel, $ProgressBar)

    $wg = Get-Command winget -ErrorAction SilentlyContinue
    if ($wg) {
        Write-Log $LogBox "Installing FFmpeg via winget..." "Orange"
        $StatusLabel.Text = "Installing FFmpeg via winget..."
        [Windows.Forms.Application]::DoEvents()

        $wgProc = Start-Process "winget" `
            -ArgumentList "install Gyan.FFmpeg --silent --accept-package-agreements --accept-source-agreements" `
            -WindowStyle Hidden -PassThru
        while (-not $wgProc.HasExited) {
            [Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 300
        }

        $env:PATH = [Environment]::GetEnvironmentVariable("PATH","Machine") + ";" +
                    [Environment]::GetEnvironmentVariable("PATH","User")

        $found = Find-FFmpeg
        if ($found) { return $found }
        Write-Log $LogBox "winget finished but ffmpeg not found -- downloading directly..." "Orange"
    } else {
        Write-Log $LogBox "winget unavailable -- downloading FFmpeg directly (~80 MB)..." "Orange"
    }

    return Invoke-FFmpegDownload $LogBox $StatusLabel $ProgressBar
}

function Invoke-FFmpegDownload {
    param($LogBox, $StatusLabel, $ProgressBar)

    $destDir = "$env:LOCALAPPDATA\VideoCompressor\ffmpeg"
    $zipPath = "$env:TEMP\ffmpeg_essentials.zip"

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $wc = New-Object Net.WebClient

        $script:_dlDone  = $false
        $script:_dlError = $null
        $script:_dlPct   = 0
        $script:_dlMB    = "0"

        $wc.add_DownloadProgressChanged({
            param($s,$e)
            $script:_dlPct = $e.ProgressPercentage
            $script:_dlMB  = [Math]::Round($e.BytesReceived/1MB,1)
        })
        $wc.add_DownloadFileCompleted({
            param($s,$e)
            $script:_dlDone  = $true
            if ($e.Error) { $script:_dlError = $e.Error.Message }
        })

        $ProgressBar.Style   = "Continuous"
        $ProgressBar.Maximum = 100
        $ProgressBar.Value   = 0

        $wc.DownloadFileAsync([Uri]"https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip", $zipPath)

        while (-not $script:_dlDone) {
            $ProgressBar.Value = $script:_dlPct
            $StatusLabel.Text  = "Downloading FFmpeg: $($script:_dlMB) MB  ($($script:_dlPct)%)"
            [Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 150
        }

        $ProgressBar.Value = 100

        if ($script:_dlError) {
            Write-Log $LogBox "Download error: $($script:_dlError)" "Red"
            return $null
        }

        Write-Log $LogBox "Downloaded. Extracting -- may take ~30 sec..." "Orange"
        $StatusLabel.Text = "Extracting FFmpeg..."
        [Windows.Forms.Application]::DoEvents()

        if (Test-Path $destDir) { Remove-Item $destDir -Recurse -Force }
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $destDir)
        Remove-Item $zipPath -Force

        $ffmpeg = Get-ChildItem $destDir -Filter "ffmpeg.exe" -Recurse | Select-Object -First 1
        if ($ffmpeg) {
            Write-Log $LogBox "FFmpeg ready: $($ffmpeg.FullName)" "LightGreen"
            return $ffmpeg.FullName
        }
    } catch {
        Write-Log $LogBox "Error: $_" "Red"
    }
    return $null
}

# --- Helpers ------------------------------------------------------------------

function Write-Log {
    param($RichBox, $Text, $ColorName = "White")
    $RichBox.SelectionStart  = $RichBox.TextLength
    $RichBox.SelectionLength = 0
    $RichBox.SelectionColor  = [Drawing.Color]::FromName($ColorName)
    $RichBox.AppendText("$Text`n")
    $RichBox.ScrollToCaret()
    [Windows.Forms.Application]::DoEvents()
}

function Get-VideoFiles {
    param($Folder)
    $exts = @("*.mp4","*.mov","*.avi","*.webm","*.mkv","*.mxf","*.m4v","*.wmv")
    $all  = @()
    foreach ($e in $exts) {
        $all += Get-ChildItem -Path $Folder -Filter $e -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -notmatch '\\Compressed\\' }
    }
    return @($all | Sort-Object FullName)
}

function Get-Duration {
    param($FilePath)
    $out = & $script:FFprobePath -v quiet -show_entries format=duration -of csv=p=0 "$FilePath" 2>&1
    $val = ($out -join "" -replace ',','.').Trim()
    try { return [double]$val } catch { return 10.0 }
}

function Invoke-FFmpeg {
    param(
        [string[]]$FfmpegArgs,
        [double]$TotalDuration = 0,
        $StatusLabel = $null,
        [string]$PassLabel = "",
        [string]$ProgressFile = ""
    )
    $psi = New-Object Diagnostics.ProcessStartInfo
    $psi.FileName  = $script:FFmpegPath
    $psi.Arguments = ($FfmpegArgs | ForEach-Object { if ($_ -match '\s') { "`"$_`"" } else { $_ } }) -join " "
    $psi.WindowStyle            = [Diagnostics.ProcessWindowStyle]::Hidden
    $psi.UseShellExecute        = $false
    $psi.CreateNoWindow         = $true
    # Do NOT redirect stdout/stderr -- pipe deadlocks corrupt output in PS2EXE.
    # Progress is read from a temp file via -progress <file> instead.
    $psi.RedirectStandardError  = $false
    $psi.RedirectStandardOutput = $false
    $p = [Diagnostics.Process]::Start($psi)
    if ($null -eq $p) { return -1 }
    $script:CurrentFFmpegProc = $p

    $durUs = if ($TotalDuration -gt 0) { [long]($TotalDuration * 1000000) } else { 0 }

    while (-not $p.HasExited) {
        if ($script:CancelRequested) {
            try { $p.Kill() } catch {}
            break
        }

        # Read progress from temp file (written by ffmpeg -progress <file>)
        if ($ProgressFile -and $durUs -gt 0 -and $null -ne $StatusLabel) {
            $tUs = 0
            try {
                $lines = [IO.File]::ReadAllLines($ProgressFile)
                for ($li = $lines.Count - 1; $li -ge 0; $li--) {
                    if ($lines[$li] -match '^out_time_us=(\d+)') {
                        $tUs = [long]$Matches[1]; break
                    }
                }
            } catch {}
            if ($tUs -gt 0) {
                $pct = [Math]::Min(99, [int]($tUs * 100 / $durUs))
                $cur = [TimeSpan]::FromSeconds($tUs / 1000000)
                $tot = [TimeSpan]::FromSeconds($TotalDuration)
                try { $StatusLabel.Text = "$PassLabel   {0:mm\:ss} / {1:mm\:ss}   ({2}%)" -f $cur, $tot, $pct } catch {}
            } else {
                try { $StatusLabel.Text = "$PassLabel   starting..." } catch {}
            }
        }

        [Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 400
    }

    try { $p.WaitForExit() } catch {}
    $code = -1
    try { $code = $p.ExitCode } catch {}
    return $code
}

function Compress-Video {
    param($File, $OutputPath, $MaxSizeMB, $MaxRes, $Format, $LogBox, $StatusLabel = $null)

    $duration = Get-Duration $File.FullName
    if ($duration -le 0) { $duration = 10 }

    # Check audio FIRST so we can reserve budget for it before computing video bitrate
    $hasAudio = (& $script:FFprobePath -v quiet -select_streams a:0 `
        -show_entries stream=index -of csv=p=0 "$($File.FullName)" 2>&1) -match '\d'

    $audioBitrateK = if ($hasAudio) { 96 } else { 0 }
    $totalBudgetKB = [int]($MaxSizeMB * 1024 * 0.92)          # 8% container overhead
    $audioBudgetKB = [int]($audioBitrateK * $duration / 8.0)   # KB used by audio track
    $videoBudgetKB = [Math]::Max(50, $totalBudgetKB - $audioBudgetKB)
    $vbrKbps       = [Math]::Max(80, [int]($videoBudgetKB * 8.0 / $duration))

    $scale = "scale='if(gte(iw,ih),$MaxRes,-2)':'if(gte(iw,ih),-2,$MaxRes)'"

    $ext     = if ($Format -eq "MOV") { ".mov" } else { ".mp4" }
    $outFull = [IO.Path]::ChangeExtension($OutputPath, $ext)
    $outDir  = Split-Path -Parent $outFull
    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

    # Use explicit passlogfile in TEMP so we never depend on CWD
    # (PowerShell Set-Location does NOT change Win32 CWD used by child processes)
    $passLog = Join-Path $env:TEMP "ffpass_$([guid]::NewGuid().ToString('N').Substring(0,8))"
    $progressFile = ""

    try {
        # Pass 1 -- analysis (no progress, fast)
        # mbtree=0: avoids x264 "Incomplete MB-tree stats file" bug on some clips
        if ($StatusLabel) { $StatusLabel.Text = "Pass 1/2 -- analyzing..." }
        $p1 = @("-y","-i",$File.FullName,"-vf",$scale,
                "-c:v","libx264","-b:v","${vbrKbps}k",
                "-x264-params","mbtree=0",
                "-passlogfile",$passLog,
                "-pass","1","-an","-f","null","NUL")
        $exit1 = Invoke-FFmpeg $p1
        if ($exit1 -ne 0 -and -not $script:CancelRequested) {
            return @{ Success=$false }
        }

        if ($script:CancelRequested) { return @{ Success=$false } }

        # Pass 2 -- encoding with live progress via temp file (not pipe -- avoids deadlock)
        $audioArgs = if ($hasAudio) { @("-c:a","aac","-b:a","${audioBitrateK}k") } else { @("-an") }
        $progressFile = Join-Path $env:TEMP "ffprog_$([guid]::NewGuid().ToString('N').Substring(0,8)).txt"
        $p2 = @("-y","-progress",$progressFile,"-i",$File.FullName,"-vf",$scale,
                "-c:v","libx264","-b:v","${vbrKbps}k",
                "-x264-params","mbtree=0",
                "-passlogfile",$passLog,
                "-pass","2","-preset","slow") + $audioArgs +
               @("-movflags","+faststart",$outFull)
        $exit2 = Invoke-FFmpeg $p2 -TotalDuration $duration -StatusLabel $StatusLabel -PassLabel "Pass 2/2" -ProgressFile $progressFile
        if ($exit2 -ne 0 -and -not $script:CancelRequested) {
            return @{ Success=$false }
        }
    } finally {
        Remove-Item "${passLog}*" -Force -ErrorAction SilentlyContinue
        if ($progressFile) { Remove-Item $progressFile -Force -ErrorAction SilentlyContinue }
    }

    if (-not $script:CancelRequested -and (Test-Path $outFull)) {
        $kb = [int]((Get-Item $outFull).Length / 1024)
        return @{ Success=$true; SizeKB=$kb; OutPath=$outFull }
    }
    return @{ Success=$false }
}

# --- Build UI -----------------------------------------------------------------

[Windows.Forms.Application]::EnableVisualStyles()

# -- Color palette -------------------------------------------------------------
$clrBg      = [Drawing.Color]::FromArgb(16,  16,  16)   # #101010  Base DARK
$clrInput   = [Drawing.Color]::FromArgb(22,  22,  22)   # #161616
$clrBorder  = [Drawing.Color]::FromArgb(38,  38,  38)   # #262626  Base MID
$clrHover   = [Drawing.Color]::FromArgb(50,  50,  50)
$clrAccent  = [Drawing.Color]::FromArgb(28,  164, 44)   # #1CA42C  muted Raptor GREEN
$clrText    = [Drawing.Color]::FromArgb(242, 226, 226)  # #F2E2E2  Base LIGHT
$clrMuted   = [Drawing.Color]::FromArgb(88,  88,  88)
$clrLogBg   = [Drawing.Color]::FromArgb(8,   8,   8)

# -- Fonts ---------------------------------------------------------------------
$fontBrand  = New-Object Drawing.Font("Segoe UI", 7.5)
$fontTitle  = New-Object Drawing.Font("Segoe UI", 15, [Drawing.FontStyle]::Bold)
$fontLabel  = New-Object Drawing.Font("Segoe UI", 7,  [Drawing.FontStyle]::Regular)
$fontUI     = New-Object Drawing.Font("Segoe UI", 9)
$fontSmall  = New-Object Drawing.Font("Segoe UI", 8.5)
$fontBtn    = New-Object Drawing.Font("Segoe UI", 11, [Drawing.FontStyle]::Bold)
$fontMono   = New-Object Drawing.Font("Consolas",  8)
$fontCopy   = New-Object Drawing.Font("Segoe UI", 7)

# -- Form ----------------------------------------------------------------------
$form = New-Object Windows.Forms.Form
$form.Text            = "Chucha Video Compressor"
$form.ClientSize      = [Drawing.Size]::new(480, 686)
$form.MinimumSize     = [Drawing.Size]::new(496, 725)
$form.MaximumSize     = [Drawing.Size]::new(496, 725)
$form.StartPosition   = "CenterScreen"
$form.BackColor       = $clrBg
$form.ForeColor       = $clrText
$form.Font            = $fontUI
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox     = $false

# -- Header --------------------------------------------------------------------
$lblBrand = New-Object Windows.Forms.Label
$lblBrand.Text      = "C H U C H A"
$lblBrand.Font      = $fontBrand
$lblBrand.ForeColor = $clrMuted
$lblBrand.AutoSize  = $true
$lblBrand.Location  = [Drawing.Point]::new(24, 22)
$form.Controls.Add($lblBrand)

$lblTitle = New-Object Windows.Forms.Label
$lblTitle.Text      = "VIDEO COMPRESSOR"
$lblTitle.Font      = $fontTitle
$lblTitle.ForeColor = $clrText
$lblTitle.AutoSize  = $true
$lblTitle.Location  = [Drawing.Point]::new(22, 37)
$form.Controls.Add($lblTitle)

# -- Separator -----------------------------------------------------------------
$sep1 = New-Object Windows.Forms.Panel
$sep1.Location  = [Drawing.Point]::new(24, 82)
$sep1.Size      = [Drawing.Size]::new(432, 1)
$sep1.BackColor = $clrBorder
$form.Controls.Add($sep1)

# -- Settings ------------------------------------------------------------------
$y = 100

# Resolution + Max size
$lblResLbl = New-Object Windows.Forms.Label
$lblResLbl.Text = "RESOLUTION  (LONG SIDE)"; $lblResLbl.Font = $fontLabel
$lblResLbl.ForeColor = $clrMuted; $lblResLbl.AutoSize = $true
$lblResLbl.Location = [Drawing.Point]::new(24, $y)
$form.Controls.Add($lblResLbl)

$lblSizeLbl = New-Object Windows.Forms.Label
$lblSizeLbl.Text = "MAX SIZE"; $lblSizeLbl.Font = $fontLabel
$lblSizeLbl.ForeColor = $clrMuted; $lblSizeLbl.AutoSize = $true
$lblSizeLbl.Location = [Drawing.Point]::new(228, $y)
$form.Controls.Add($lblSizeLbl)

$y += 16

$txtRes = New-Object Windows.Forms.TextBox
$txtRes.Text = "1270"; $txtRes.Location = [Drawing.Point]::new(24, $y)
$txtRes.Size = [Drawing.Size]::new(170, 28); $txtRes.BackColor = $clrInput
$txtRes.ForeColor = $clrText; $txtRes.BorderStyle = "FixedSingle"; $txtRes.Font = $fontUI
$form.Controls.Add($txtRes)

$lblPx = New-Object Windows.Forms.Label
$lblPx.Text = "px"; $lblPx.Font = $fontSmall; $lblPx.ForeColor = $clrMuted
$lblPx.AutoSize = $true; $lblPx.Location = [Drawing.Point]::new(202, ($y + 5))
$form.Controls.Add($lblPx)

$txtSize = New-Object Windows.Forms.TextBox
$txtSize.Text = "1.5"; $txtSize.Location = [Drawing.Point]::new(228, $y)
$txtSize.Size = [Drawing.Size]::new(110, 28); $txtSize.BackColor = $clrInput
$txtSize.ForeColor = $clrText; $txtSize.BorderStyle = "FixedSingle"; $txtSize.Font = $fontUI
$form.Controls.Add($txtSize)

$lblMB = New-Object Windows.Forms.Label
$lblMB.Text = "MB"; $lblMB.Font = $fontSmall; $lblMB.ForeColor = $clrMuted
$lblMB.AutoSize = $true; $lblMB.Location = [Drawing.Point]::new(346, ($y + 5))
$form.Controls.Add($lblMB)

$y += 46

# Format
$lblFmtLbl = New-Object Windows.Forms.Label
$lblFmtLbl.Text = "FORMAT"; $lblFmtLbl.Font = $fontLabel
$lblFmtLbl.ForeColor = $clrMuted; $lblFmtLbl.AutoSize = $true
$lblFmtLbl.Location = [Drawing.Point]::new(24, $y)
$form.Controls.Add($lblFmtLbl)

$y += 16

# Format as button-style radio group
$fmtPanel = New-Object Windows.Forms.Panel
$fmtPanel.Location = [Drawing.Point]::new(24, $y)
$fmtPanel.Size = [Drawing.Size]::new(172, 30)
$fmtPanel.BackColor = $clrBg
$form.Controls.Add($fmtPanel)

function New-FmtBtn { param($Lbl, $X, $W=80, $On=$false)
    $rb = New-Object Windows.Forms.RadioButton
    $rb.Text = $Lbl
    $rb.Location = [Drawing.Point]::new($X, 0)
    $rb.Size = [Drawing.Size]::new($W, 30)
    $rb.Appearance = [Windows.Forms.Appearance]::Button
    $rb.FlatStyle = [Windows.Forms.FlatStyle]::Flat
    $rb.FlatAppearance.BorderColor = $clrBorder
    $rb.FlatAppearance.BorderSize  = 1
    $rb.FlatAppearance.CheckedBackColor   = $clrAccent
    $rb.FlatAppearance.MouseDownBackColor = $clrAccent
    $rb.FlatAppearance.MouseOverBackColor = $clrHover
    $rb.BackColor = $clrInput
    $rb.ForeColor = $clrText
    $rb.Font = $fontSmall
    $rb.Checked = $On
    $rb.TextAlign = [Drawing.ContentAlignment]::MiddleCenter
    $rb.Cursor = [Windows.Forms.Cursors]::Hand
    $rb
}
$rbMP4  = New-FmtBtn "MP4"   0   82 $true
$rbMOV  = New-FmtBtn "MOV"   86  82
$fmtPanel.Controls.Add($rbMP4)
$fmtPanel.Controls.Add($rbMOV)

$y += 46

# Output mode
$lblOutLbl = New-Object Windows.Forms.Label
$lblOutLbl.Text = "OUTPUT MODE"; $lblOutLbl.Font = $fontLabel
$lblOutLbl.ForeColor = $clrMuted; $lblOutLbl.AutoSize = $true
$lblOutLbl.Location = [Drawing.Point]::new(24, $y)
$form.Controls.Add($lblOutLbl)

$y += 16

$rbCompressed = New-Object Windows.Forms.RadioButton
$rbCompressed.Text = "Save in Compressed/ subfolder  (preserves folder structure)"
$rbCompressed.Location = [Drawing.Point]::new(24, $y)
$rbCompressed.AutoSize = $true; $rbCompressed.Checked = $true
$rbCompressed.ForeColor = $clrText; $rbCompressed.Font = $fontSmall
$form.Controls.Add($rbCompressed)

$y += 24

$rbSideBySide = New-Object Windows.Forms.RadioButton
$rbSideBySide.Text = "Save alongside original  (_compressed suffix)"
$rbSideBySide.Location = [Drawing.Point]::new(24, $y)
$rbSideBySide.AutoSize = $true
$rbSideBySide.ForeColor = $clrText; $rbSideBySide.Font = $fontSmall
$form.Controls.Add($rbSideBySide)

$y += 38

# -- Separator -----------------------------------------------------------------
$sep2 = New-Object Windows.Forms.Panel
$sep2.Location  = [Drawing.Point]::new(24, $y)
$sep2.Size      = [Drawing.Size]::new(432, 1)
$sep2.BackColor = $clrBorder
$form.Controls.Add($sep2)

$y += 16

# -- Source folder -------------------------------------------------------------
$lblFolderLbl = New-Object Windows.Forms.Label
$lblFolderLbl.Text = "SOURCE FOLDER"; $lblFolderLbl.Font = $fontLabel
$lblFolderLbl.ForeColor = $clrMuted; $lblFolderLbl.AutoSize = $true
$lblFolderLbl.Location = [Drawing.Point]::new(24, $y)
$form.Controls.Add($lblFolderLbl)

$y += 16

$txtFolder = New-Object Windows.Forms.TextBox
$txtFolder.Text = ""; $txtFolder.Location = [Drawing.Point]::new(24, $y)
$txtFolder.Size = [Drawing.Size]::new(350, 28); $txtFolder.BackColor = $clrInput
$txtFolder.ForeColor = $clrText; $txtFolder.BorderStyle = "FixedSingle"; $txtFolder.Font = $fontUI
$form.Controls.Add($txtFolder)

$btnBrowse = New-Object Windows.Forms.Button
$btnBrowse.Text = "Browse"
$btnBrowse.Location = [Drawing.Point]::new(382, $y)
$btnBrowse.Size = [Drawing.Size]::new(74, 28)
$btnBrowse.BackColor = $clrInput; $btnBrowse.ForeColor = $clrText
$btnBrowse.FlatStyle = "Flat"
$btnBrowse.FlatAppearance.BorderColor = $clrBorder
$btnBrowse.Font = $fontSmall
$btnBrowse.Cursor = [Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnBrowse)

$y += 46

# -- START button --------------------------------------------------------------
$btnStart = New-Object Windows.Forms.Button
$btnStart.Text = ">  START"
$btnStart.Location = [Drawing.Point]::new(24, $y)
$btnStart.Size = [Drawing.Size]::new(432, 46)
$btnStart.BackColor = $clrAccent
$btnStart.ForeColor = [Drawing.Color]::White
$btnStart.FlatStyle = "Flat"
$btnStart.FlatAppearance.BorderSize = 0
$btnStart.FlatAppearance.MouseOverBackColor = [Drawing.Color]::FromArgb(38, 182, 58)
$btnStart.FlatAppearance.MouseDownBackColor = [Drawing.Color]::FromArgb(18, 132, 34)
$btnStart.Font = $fontBtn
$btnStart.Cursor = [Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnStart)

$y += 58

# -- Progress ------------------------------------------------------------------
$progress = New-Object Windows.Forms.ProgressBar
$progress.Location = [Drawing.Point]::new(24, $y)
$progress.Size = [Drawing.Size]::new(432, 3)
$progress.Style = "Continuous"
$progress.ForeColor = $clrAccent
$form.Controls.Add($progress)

$y += 12

$lblStatus = New-Object Windows.Forms.Label
$lblStatus.Text = "Ready"
$lblStatus.Font = $fontSmall
$lblStatus.ForeColor = $clrMuted
$lblStatus.AutoSize = $true
$lblStatus.Location = [Drawing.Point]::new(24, $y)
$form.Controls.Add($lblStatus)

$y += 22

# -- Log -----------------------------------------------------------------------
$logBox = New-Object Windows.Forms.RichTextBox
$logBox.Location = [Drawing.Point]::new(24, $y)
$logBox.Size = [Drawing.Size]::new(432, 150)
$logBox.BackColor = $clrLogBg
$logBox.ForeColor = $clrText
$logBox.Font = $fontMono
$logBox.ReadOnly = $true
$logBox.BorderStyle = "None"
$logBox.ScrollBars = "Vertical"
$form.Controls.Add($logBox)

$y += 158

# -- Copyright -----------------------------------------------------------------
$lblCopy = New-Object Windows.Forms.LinkLabel
$lblCopy.Text = "Made by Voogie  |  cameraptor.com/voogie"
$lblCopy.Font = $fontCopy
$lblCopy.Location = [Drawing.Point]::new(24, $y)
$lblCopy.AutoSize = $true
$lblCopy.LinkColor = [Drawing.Color]::FromArgb(55, 55, 55)
$lblCopy.ActiveLinkColor = [Drawing.Color]::FromArgb(100, 100, 100)
$lblCopy.VisitedLinkColor = [Drawing.Color]::FromArgb(55, 55, 55)
$lblCopy.LinkBehavior = [Windows.Forms.LinkBehavior]::HoverUnderline
$lblCopy.Add_LinkClicked({ Start-Process "http://cameraptor.com/voogie" })
$form.Controls.Add($lblCopy)

# --- Events -------------------------------------------------------------------

$btnBrowse.Add_Click({
    $dlg = New-Object Windows.Forms.FolderBrowserDialog
    $dlg.Description = "Select folder with video files"
    if ($dlg.ShowDialog() -eq "OK") { $txtFolder.Text = $dlg.SelectedPath }
})

$form.Add_FormClosing({
    param($s, $e)
    if ($script:IsProcessing) {
        $e.Cancel = $true
        [Windows.Forms.MessageBox]::Show(
            "Processing in progress.`nUse the STOP button first.",
            "Cannot close", "OK", "Warning") | Out-Null
    }
})

$form.Add_Shown({
    $script:FFmpegPath = Find-FFmpeg

    if ($script:FFmpegPath) {
        $probePath = $script:FFmpegPath -replace "ffmpeg\.exe$","ffprobe.exe"
        if (Test-Path $probePath) {
            $script:FFprobePath = $probePath
        } else {
            Write-Log $logBox "WARNING: ffprobe.exe not found next to ffmpeg.exe" "Orange"
            $script:FFprobePath = $null
        }
        Write-Log $logBox "FFmpeg found: $($script:FFmpegPath)" "LightGreen"
        Write-Log $logBox "Select a source folder and click START." "White"
        $lblStatus.Text = "FFmpeg ready"
    } else {
        Write-Log $logBox "FFmpeg not found -- will be installed automatically when you click START." "Orange"
        $lblStatus.Text      = "FFmpeg not found -- will install on Start"
        $lblStatus.ForeColor = [Drawing.Color]::Orange
    }
})

$btnStart.Add_Click({
    # -- STOP mode -------------------------------------------------------------
    if ($btnStart.Tag -eq "stop") {
        $script:CancelRequested = $true
        $btnStart.Text      = "Stopping..."
        $btnStart.BackColor = [Drawing.Color]::FromArgb(120, 30, 30)
        $btnStart.Enabled   = $false
        return
    }

    # -- START mode ------------------------------------------------------------
    try {
    $folder = $txtFolder.Text.Trim()
    if (-not $folder -or -not (Test-Path $folder)) {
        [Windows.Forms.MessageBox]::Show("Folder not found. Please select a valid source folder.","Error","OK","Error") | Out-Null
        return
    }

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

    $format     = if ($rbMOV.Checked) {"MOV"} else {"MP4"}
    $outputMode = if ($rbSideBySide.Checked) {"Side"} else {"Compressed"}

    $files = Get-VideoFiles $folder
    if ($files.Count -eq 0) {
        [Windows.Forms.MessageBox]::Show("No video files found in the selected folder.","Nothing found","OK","Warning") | Out-Null
        return
    }

    $script:CancelRequested = $false
    $script:IsProcessing    = $true
    $btnStart.Text      = "[X]  STOP"
    $btnStart.BackColor = [Drawing.Color]::FromArgb(180, 40, 40)
    $btnStart.FlatAppearance.MouseOverBackColor = [Drawing.Color]::FromArgb(210, 55, 55)
    $btnStart.FlatAppearance.MouseDownBackColor = [Drawing.Color]::FromArgb(140, 25, 25)

    # Re-wire click to cancel
    $btnStart.Tag = "stop"

    if (-not $script:FFmpegPath) {
        $btnStart.Text  = "Installing FFmpeg..."
        $progress.Style = "Marquee"
        [Windows.Forms.Application]::DoEvents()

        $script:FFmpegPath = Install-FFmpegSilently $logBox $lblStatus $progress

        $progress.Style = "Continuous"
        $btnStart.Text  = ">  START"

        if (-not $script:FFmpegPath) {
            Write-Log $logBox "ERROR: FFmpeg could not be installed." "Red"
            Write-Log $logBox "Download manually: https://ffmpeg.org/download.html" "OrangeRed"
            $script:IsProcessing = $false
            $btnStart.Text      = ">  START"
            $btnStart.BackColor = $clrAccent
            $btnStart.FlatAppearance.MouseOverBackColor = [Drawing.Color]::FromArgb(38, 182, 58)
            $btnStart.FlatAppearance.MouseDownBackColor = [Drawing.Color]::FromArgb(18, 132, 34)
            $btnStart.Tag     = "start"
            $btnStart.Enabled = $true
            return
        }
        $probePath2 = $script:FFmpegPath -replace "ffmpeg\.exe$","ffprobe.exe"
        if (Test-Path $probePath2) { $script:FFprobePath = $probePath2 }
        $lblStatus.ForeColor = $clrMuted
        Write-Log $logBox "FFmpeg ready. Starting compression..." "LightGreen"
    }

    $progress.Maximum = $files.Count
    $progress.Value   = 0
    $done = 0; $failed = 0

    # -- Pre-flight: warn about files that physically cannot fit ----------------
    $lblStatus.Text = "Analyzing $($files.Count) file(s)..."
    [Windows.Forms.Application]::DoEvents()

    $tooLarge = @()
    foreach ($f in $files) {
        $dur = Get-Duration $f.FullName
        if ($dur -le 0) { $dur = 10 }
        $hasAud = (& $script:FFprobePath -v quiet -select_streams a:0 `
            -show_entries stream=index -of csv=p=0 "$($f.FullName)" 2>&1) -match '\d'
        $aBR   = if ($hasAud) { 96 } else { 0 }
        # Minimum achievable size: 80 kbps video + audio bitrate + 8% container overhead
        $minMB = [Math]::Round((80 + $aBR) * $dur / 8.0 / 1024.0 * 1.08, 2)
        if ($minMB -gt $maxSizeMB) {
            $tooLarge += "  *  $($f.Name)  --  min ~$($minMB) MB  ($([int]$dur)s)"
        }
    }

    if ($tooLarge.Count -gt 0) {
        $warnMsg  = "$($tooLarge.Count) file(s) CANNOT fit within $maxSizeMB MB at minimum quality:`n`n"
        $warnMsg += $tooLarge -join "`n"
        $warnMsg += "`n`nThese files will be compressed as small as possible`nbut will likely exceed your size limit.`n`nContinue anyway?"
        $answer = [Windows.Forms.MessageBox]::Show($warnMsg, "Size Limit Warning", "YesNo", "Warning")
        if ($answer -ne "Yes") {
            $script:IsProcessing = $false
            $btnStart.Text      = ">  START"
            $btnStart.BackColor = $clrAccent
            $btnStart.FlatAppearance.MouseOverBackColor = [Drawing.Color]::FromArgb(38, 182, 58)
            $btnStart.FlatAppearance.MouseDownBackColor = [Drawing.Color]::FromArgb(18, 132, 34)
            $btnStart.Tag     = "start"
            $btnStart.Enabled = $true
            $lblStatus.Text   = "Aborted"
            $script:CancelRequested = $false
            return
        }
    }
    # -------------------------------------------------------------------------

    Write-Log $logBox "--------------------------------------" "DimGray"
    Write-Log $logBox "Files      : $($files.Count)" "White"
    Write-Log $logBox "Resolution : ${maxRes}px   Max size: ${maxSizeMB} MB   Format: $format" "White"
    Write-Log $logBox "--------------------------------------" "DimGray"

    for ($i = 0; $i -lt $files.Count; $i++) {
        if ($script:CancelRequested) { break }

        $file = $files[$i]
        $num  = $i + 1

        $lblStatus.Text = "[$num / $($files.Count)]  $($file.Name)"
        Write-Log $logBox "[$num/$($files.Count)]  $($file.Name)" "Cyan"
        [Windows.Forms.Application]::DoEvents()

        if ($outputMode -eq "Compressed") {
            $rel        = $file.FullName.Substring($folder.Length).TrimStart('\','/')
            $outputPath = Join-Path $folder "Compressed\$rel"
        } else {
            $base       = [IO.Path]::GetFileNameWithoutExtension($file.Name)
            $outputPath = Join-Path $file.DirectoryName "${base}_compressed$([IO.Path]::GetExtension($file.Name))"
        }

        try {
            $result = Compress-Video $file $outputPath $maxSizeMB $maxRes $format $logBox $lblStatus
        } catch {
            $result = @{ Success=$false }
            Write-Log $logBox "  [x]  Exception: $_" "OrangeRed"
        }

        if ($script:CancelRequested) {
            Write-Log $logBox "  [x]  Cancelled" "OrangeRed"
            break
        }

        if ($result.Success) {
            Write-Log $logBox "  [ok]  $($result.SizeKB) KB -> $($result.OutPath)" "LightGreen"
            $done++
        } else {
            if (-not $script:CancelRequested) {
                Write-Log $logBox "  [x]  Encoding error" "OrangeRed"
            }
            $failed++
        }

        $progress.Value = $num
        [Windows.Forms.Application]::DoEvents()
    }

    Write-Log $logBox "--------------------------------------" "DimGray"
    $summary = if ($script:CancelRequested) { "Cancelled. Done: $done" } else { "Done: $done successful" }
    if ($failed -gt 0) { $summary += ", $failed errors" }
    Write-Log $logBox $summary $(if ($script:CancelRequested) { "Orange" } else { "Yellow" })

    # Restore START button
    $script:IsProcessing = $false
    $btnStart.Text      = ">  START"
    $btnStart.BackColor = $clrAccent
    $btnStart.FlatAppearance.MouseOverBackColor = [Drawing.Color]::FromArgb(38, 182, 58)
    $btnStart.FlatAppearance.MouseDownBackColor = [Drawing.Color]::FromArgb(18, 132, 34)
    $btnStart.Tag     = "start"
    $btnStart.Enabled = $true

    $lblStatus.Text = $summary

    if (-not $script:CancelRequested) {
        [Windows.Forms.MessageBox]::Show("$summary`n`nFiles: $($files.Count)  |  Resolution: ${maxRes}px",
            "Done", "OK", "Information") | Out-Null
    }

    } catch {
        # Global safety net -- write diagnostics to file since -noConsole hides errors
        $errMsg = "$(Get-Date -f 'HH:mm:ss')  $_`n$($_.ScriptStackTrace)"
        try { [IO.File]::AppendAllText("$env:TEMP\VideoCompressor_error.txt", $errMsg + "`n") } catch {}
        try {
            Write-Log $logBox "CRASH: $_" "Red"
            Write-Log $logBox "Details saved to: $env:TEMP\VideoCompressor_error.txt" "OrangeRed"
        } catch {}
        # Restore button so the app stays usable
        $script:IsProcessing = $false
        try {
            $btnStart.Text      = ">  START"
            $btnStart.BackColor = $clrAccent
            $btnStart.FlatAppearance.MouseOverBackColor = [Drawing.Color]::FromArgb(38, 182, 58)
            $btnStart.FlatAppearance.MouseDownBackColor = [Drawing.Color]::FromArgb(18, 132, 34)
            $btnStart.Tag     = "start"
            $btnStart.Enabled = $true
            $lblStatus.Text   = "Error -- see log"
        } catch {}
    }
})

$form.ShowDialog() | Out-Null
