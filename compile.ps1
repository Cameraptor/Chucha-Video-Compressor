$ps2exe = 'd:/Work/Assets/Projects/Client Work/BrainRocket/Vegas_Hero/DELIVERY/ps2exe.ps1'
$src    = 'd:/Work/Assets/Projects/Client Work/BrainRocket/Vegas_Hero/DELIVERY/VideoCompressor.ps1'
$exe    = 'd:/Work/Assets/Projects/Client Work/BrainRocket/Vegas_Hero/DELIVERY/VideoCompressor_new.exe'
$ico    = 'd:/Work/Assets/Projects/Client Work/BrainRocket/Vegas_Hero/DELIVERY/compressor.ico'
. $ps2exe
Invoke-ps2exe $src $exe -noConsole -requireAdmin -iconFile $ico -title 'Chucha Video Compressor' -company 'CAMERAPTOR' -copyright 'Voogie / cameraptor.com'
Write-Host 'COMPILE DONE'
