# ============================================================
# PCSX2 Visual Enhancement Suite - Toggle On/Off
# Enables or disables ReShade by renaming dxgi.dll
# ============================================================

$pcsx2Root = Split-Path (Split-Path $PSScriptRoot -Parent)
$dxgiDll = Join-Path $pcsx2Root "dxgi.dll"
$dxgiDisabled = Join-Path $pcsx2Root "dxgi.dll.disabled"

# Check if PCSX2 is running
$running = Get-Process -Name "pcsx2-qt" -ErrorAction SilentlyContinue
if ($running) {
    Write-Host "[WARNING] " -ForegroundColor Yellow -NoNewline
    Write-Host "PCSX2 is running. Toggle will take effect on next launch."
}

if (Test-Path $dxgiDll) {
    # Currently enabled -> disable
    Rename-Item -Path $dxgiDll -NewName "dxgi.dll.disabled" -Force
    Write-Host "[OFF] " -ForegroundColor Red -NoNewline
    Write-Host "Visual enhancements DISABLED"
    Write-Host "       ReShade will not load on next PCSX2 launch." -ForegroundColor Gray
}
elseif (Test-Path $dxgiDisabled) {
    # Currently disabled -> enable
    Rename-Item -Path $dxgiDisabled -NewName "dxgi.dll" -Force
    Write-Host "[ON] " -ForegroundColor Green -NoNewline
    Write-Host "Visual enhancements ENABLED"
    Write-Host "      ReShade will load on next PCSX2 launch." -ForegroundColor Gray
}
else {
    Write-Host "[ERROR] " -ForegroundColor Red -NoNewline
    Write-Host "ReShade not installed. Run install_reshade.ps1 first."
    exit 1
}
