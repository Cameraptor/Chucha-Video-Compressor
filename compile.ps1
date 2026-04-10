$root   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ps2exe = Join-Path $root 'ps2exe.ps1'
$src    = Join-Path $root 'VideoCompressor.ps1'
$exe    = Join-Path $root 'VideoCompressor.exe'
$ico    = Join-Path $root 'compressor.ico'
. $ps2exe
Invoke-ps2exe $src $exe -noConsole -requireAdmin -iconFile $ico -title 'Chucha Video Compressor' -company 'CAMERAPTOR' -copyright 'Voogie / cameraptor.com'
Write-Host 'COMPILE DONE'
