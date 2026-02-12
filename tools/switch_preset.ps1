# ============================================================
# PCSX2 Visual Enhancement Suite - Preset Switcher
# Usage: .\switch_preset.ps1 <PresetName>
# Example: .\switch_preset.ps1 Cinematic
# ============================================================

param(
    [Parameter(Position=0)]
    [string]$PresetName,
    [switch]$List
)

$pcsx2Root = Split-Path (Split-Path $PSScriptRoot -Parent)
$presetsDir = Join-Path $PSScriptRoot "presets"
$activePreset = Join-Path $pcsx2Root "ReShadePreset.ini"

if ($List -or -not $PresetName) {
    Write-Host ""
    Write-Host "Available Presets:" -ForegroundColor Cyan
    Write-Host "==================" -ForegroundColor Cyan
    Get-ChildItem $presetsDir -Filter "*.ini" | ForEach-Object {
        $name = $_.BaseName
        $active = ""
        if (Test-Path $activePreset) {
            $currentContent = Get-Content $activePreset -Raw
            $presetContent = Get-Content $_.FullName -Raw
            if ($currentContent -eq $presetContent) {
                $active = " [ACTIVE]"
            }
        }
        switch ($name) {
            "Default_Balanced"  { Write-Host "  $name$active" -ForegroundColor $(if($active){"Green"}else{"White"}); Write-Host "    SMAA + Sharpening + Clarity + Vibrance (recommended)" -ForegroundColor Gray }
            "Maximum_Clarity"   { Write-Host "  $name$active" -ForegroundColor $(if($active){"Green"}else{"White"}); Write-Host "    Aggressive sharpening + FakeHDR + full post-processing" -ForegroundColor Gray }
            "Cinematic"         { Write-Host "  $name$active" -ForegroundColor $(if($active){"Green"}else{"White"}); Write-Host "    Enhanced contrast + color grading (Black, Getaway, Warriors)" -ForegroundColor Gray }
            "Vibrant"           { Write-Host "  $name$active" -ForegroundColor $(if($active){"Green"}else{"White"}); Write-Host "    Color boost + saturation (Sims 2, Barnyard, Guitar Hero)" -ForegroundColor Gray }
            "Performance"       { Write-Host "  $name$active" -ForegroundColor $(if($active){"Green"}else{"White"}); Write-Host "    Minimal shaders for maximum FPS" -ForegroundColor Gray }
            "Retro_Warm"        { Write-Host "  $name$active" -ForegroundColor $(if($active){"Green"}else{"White"}); Write-Host "    Warm retro tone with subtle sharpening" -ForegroundColor Gray }
            default             { Write-Host "  $name$active" -ForegroundColor $(if($active){"Green"}else{"White"}) }
        }
    }
    Write-Host ""
    Write-Host "Usage: .\switch_preset.ps1 <PresetName>" -ForegroundColor Yellow
    Write-Host "Example: .\switch_preset.ps1 Cinematic" -ForegroundColor Yellow
    Write-Host ""
    exit 0
}

# Find matching preset
$presetFile = Get-ChildItem $presetsDir -Filter "*.ini" | Where-Object { $_.BaseName -like "*$PresetName*" } | Select-Object -First 1

if (-not $presetFile) {
    Write-Host "Preset not found: $PresetName" -ForegroundColor Red
    Write-Host "Run .\switch_preset.ps1 -List to see available presets." -ForegroundColor Yellow
    exit 1
}

Copy-Item -Path $presetFile.FullName -Destination $activePreset -Force
Write-Host "[OK] " -ForegroundColor Green -NoNewline
Write-Host "Switched to preset: $($presetFile.BaseName)"
Write-Host "     Changes take effect on next game launch (or press Scroll Lock to reload)." -ForegroundColor Gray
