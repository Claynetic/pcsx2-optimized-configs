# ============================================================
# PCSX2 Optimized Configs - Auto Setup
# Detects your games, generates optimized per-game configs
# from PCSX2's official GameIndex.yaml, and installs presets.
# ============================================================

param(
    [string]$PCSX2Path,
    [switch]$SkipReShade,
    [switch]$DryRun,
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$Version = "1.0.0"

# ============================================================
# HELP
# ============================================================
if ($Help) {
    Write-Host ""
    Write-Host "PCSX2 Optimized Configs - Auto Setup v$Version" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\setup.ps1 -PCSX2Path 'C:\path\to\pcsx2'" -ForegroundColor White
    Write-Host "  .\setup.ps1 -PCSX2Path 'H:\PlayStation 2' -SkipReShade" -ForegroundColor White
    Write-Host "  .\setup.ps1 -PCSX2Path 'C:\PCSX2' -DryRun" -ForegroundColor White
    Write-Host ""
    Write-Host "Parameters:" -ForegroundColor Yellow
    Write-Host "  -PCSX2Path     Path to your PCSX2 installation (required)" -ForegroundColor White
    Write-Host "  -SkipReShade   Skip ReShade preset installation" -ForegroundColor White
    Write-Host "  -DryRun        Show what would be done without writing files" -ForegroundColor White
    Write-Host "  -Help          Show this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "What this does:" -ForegroundColor Yellow
    Write-Host "  1. Scans your PCSX2 game library for installed games" -ForegroundColor White
    Write-Host "  2. Reads PCSX2's GameIndex.yaml for official recommended fixes" -ForegroundColor White
    Write-Host "  3. Generates optimized per-game configs (.ini) for each game" -ForegroundColor White
    Write-Host "  4. Detects your GPU and sets appropriate upscale multiplier" -ForegroundColor White
    Write-Host "  5. Installs ReShade visual enhancement presets (optional)" -ForegroundColor White
    Write-Host ""
    exit 0
}

# ============================================================
# HELPERS
# ============================================================
function Write-Status($msg) {
    Write-Host "[SETUP] " -ForegroundColor Cyan -NoNewline
    Write-Host $msg
}

function Write-Ok($msg) {
    Write-Host "  [OK] " -ForegroundColor Green -NoNewline
    Write-Host $msg
}

function Write-Warn($msg) {
    Write-Host "  [!]  " -ForegroundColor Yellow -NoNewline
    Write-Host $msg
}

function Write-Err($msg) {
    Write-Host "  [X]  " -ForegroundColor Red -NoNewline
    Write-Host $msg
}

function Write-Info($msg) {
    Write-Host "       " -NoNewline
    Write-Host $msg -ForegroundColor Gray
}

# ============================================================
# VALIDATE PCSX2 PATH
# ============================================================
Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " PCSX2 Optimized Configs - Auto Setup v$Version" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

if (-not $PCSX2Path) {
    # Try to auto-detect common locations
    $commonPaths = @(
        "$env:ProgramFiles\PCSX2",
        "${env:ProgramFiles(x86)}\PCSX2",
        "$env:LOCALAPPDATA\PCSX2",
        "$env:USERPROFILE\PCSX2",
        "C:\PCSX2",
        "D:\PCSX2",
        "H:\PlayStation 2"
    )
    foreach ($p in $commonPaths) {
        if (Test-Path (Join-Path $p "pcsx2-qt.exe")) {
            $PCSX2Path = $p
            Write-Status "Auto-detected PCSX2 at: $p"
            break
        }
    }
    if (-not $PCSX2Path) {
        Write-Err "Could not auto-detect PCSX2 installation."
        Write-Host ""
        Write-Host "  Please specify your PCSX2 path:" -ForegroundColor Yellow
        Write-Host "  .\setup.ps1 -PCSX2Path 'C:\path\to\pcsx2'" -ForegroundColor White
        Write-Host ""
        exit 1
    }
}

$pcsx2Exe = Join-Path $PCSX2Path "pcsx2-qt.exe"
if (-not (Test-Path $pcsx2Exe)) {
    Write-Err "pcsx2-qt.exe not found at: $PCSX2Path"
    Write-Host "  Make sure the path points to the folder containing pcsx2-qt.exe." -ForegroundColor Yellow
    exit 1
}

Write-Ok "PCSX2 found: $PCSX2Path"

# ============================================================
# DETECT GPU
# ============================================================
Write-Status "Detecting GPU..."

$gpuName = "Unknown"
$gpuTier = "mid"  # low, mid, high
$defaultUpscale = 4

try {
    $gpu = Get-CimInstance -ClassName Win32_VideoController | Where-Object { $_.Status -eq "OK" -and $_.AdapterRAM -gt 0 } | Select-Object -First 1
    if ($gpu) {
        $gpuName = $gpu.Name
        $vramMB = [math]::Round($gpu.AdapterRAM / 1MB)

        # Classify GPU tier based on name patterns
        $highEnd = @("RTX 40[789]0", "RTX 4080", "RTX 3080", "RTX 3090", "RX 7[89]00", "RX 6[89]00", "RTX 50[6789]0", "RTX 5080", "RTX 5090")
        $midRange = @("RTX 40[56]0", "RTX 30[567]0", "RX 7[67]00", "RX 6[67]00", "GTX 1[06789][78]0", "RTX 20[678]0", "RTX 50[56]0")
        $lowEnd = @("GTX 1[0-6][56]0", "RX 5[56]00", "RX 6[45]00", "GTX 9[56]0", "RX 7[56]00 *XT")

        $isHigh = $false
        $isMid = $false
        foreach ($pat in $highEnd) {
            if ($gpuName -match $pat) { $isHigh = $true; break }
        }
        if (-not $isHigh) {
            foreach ($pat in $midRange) {
                if ($gpuName -match $pat) { $isMid = $true; break }
            }
        }

        if ($isHigh) {
            $gpuTier = "high"
            $defaultUpscale = 6
        } elseif ($isMid) {
            $gpuTier = "mid"
            $defaultUpscale = 4
        } else {
            $gpuTier = "low"
            $defaultUpscale = 3
        }
    }
} catch {
    Write-Warn "Could not detect GPU. Using mid-range defaults (4x upscale)."
}

Write-Ok "GPU: $gpuName"
Write-Info "Tier: $gpuTier | Default upscale: ${defaultUpscale}x native"

# Check for AMD RDNA2/3 (Vulkan bug warning)
$isAMD_RDNA = $gpuName -match "RX [67]\\d00|RX 7[0-9]00"
if ($isAMD_RDNA) {
    Write-Warn "AMD RDNA2/3 detected. Vulkan has known timeout issues (PCSX2 #10720)."
    Write-Info "Recommendation: Use DX11 renderer (Renderer=3) for stability."
}

# ============================================================
# PARSE GAMEINDEX.YAML
# ============================================================
Write-Status "Loading GameIndex.yaml..."

$gameIndexPath = Join-Path $PCSX2Path "resources\GameIndex.yaml"
if (-not (Test-Path $gameIndexPath)) {
    Write-Err "GameIndex.yaml not found at: $gameIndexPath"
    Write-Host "  This file ships with PCSX2. Make sure your installation is complete." -ForegroundColor Yellow
    exit 1
}

Write-Ok "GameIndex.yaml loaded"

# Parse YAML manually (PCSX2's GameIndex.yaml is a specific format)
# Each entry starts with SERIAL: at indent level 0
Write-Status "Parsing game database (this may take a moment)..."

$gameIndex = @{}
$currentSerial = $null
$currentEntry = $null
$currentSection = $null
$lineNum = 0

foreach ($line in [System.IO.File]::ReadLines($gameIndexPath)) {
    $lineNum++

    # Skip comments and empty lines
    if ($line -match '^\s*#' -or $line -match '^\s*$') { continue }

    # Top-level serial entry (no indent, ends with colon)
    if ($line -match '^([A-Z]{2,4}-?\d+[A-Z]?):' -or $line -match '^([A-Z]{2,4}_\d+\.\d+):') {
        if ($currentSerial -and $currentEntry) {
            $gameIndex[$currentSerial] = $currentEntry
        }
        $currentSerial = $Matches[1]
        $currentEntry = @{
            serial = $currentSerial
            name = ""
            region = ""
            gsHWFixes = @{}
            gameFixes = @()
            clampModes = @{}
            roundModes = @{}
            speedHacks = @{}
            patches = @{}
        }
        $currentSection = $null
        continue
    }

    if (-not $currentSerial) { continue }

    # Indented properties
    if ($line -match '^\s{2}name:\s*"(.+)"') {
        $currentEntry.name = $Matches[1]
    }
    elseif ($line -match '^\s{2}name-en:\s*"(.+)"') {
        if (-not $currentEntry.name -or $currentEntry.name -match '[^\x00-\x7F]') {
            $currentEntry.name = $Matches[1]
        }
    }
    elseif ($line -match '^\s{2}region:\s*"(.+)"') {
        $currentEntry.region = $Matches[1]
    }
    elseif ($line -match '^\s{2}gsHWFixes:') {
        $currentSection = "gsHWFixes"
    }
    elseif ($line -match '^\s{2}gameFixes:') {
        $currentSection = "gameFixes"
    }
    elseif ($line -match '^\s{2}clampModes:') {
        $currentSection = "clampModes"
    }
    elseif ($line -match '^\s{2}roundModes:') {
        $currentSection = "roundModes"
    }
    elseif ($line -match '^\s{2}speedHacks:') {
        $currentSection = "speedHacks"
    }
    elseif ($line -match '^\s{2}(compat|patches|memcardFilters|name-sort):') {
        $currentSection = "other"
    }
    # Section content (4-space indent)
    elseif ($line -match '^\s{4}' -and $currentSection) {
        switch ($currentSection) {
            "gsHWFixes" {
                if ($line -match '^\s{4}(\w+):\s*(.+?)(\s*#.*)?$') {
                    $key = $Matches[1]
                    $val = $Matches[2].Trim().Trim('"')
                    # Skip internal-only fixes that can't be set via .ini
                    if ($key -notin @("getSkipCount", "beforeDraw")) {
                        $currentEntry.gsHWFixes[$key] = $val
                    }
                }
            }
            "gameFixes" {
                if ($line -match '^\s{4}-\s+(\w+)') {
                    $currentEntry.gameFixes += $Matches[1]
                }
            }
            "clampModes" {
                if ($line -match '^\s{4}(\w+):\s*(\d+)') {
                    $currentEntry.clampModes[$Matches[1]] = [int]$Matches[2]
                }
            }
            "roundModes" {
                if ($line -match '^\s{4}(\w+):\s*(\d+)') {
                    $currentEntry.roundModes[$Matches[1]] = [int]$Matches[2]
                }
            }
            "speedHacks" {
                if ($line -match '^\s{4}(\w+):\s*(\d+)') {
                    $currentEntry.speedHacks[$Matches[1]] = [int]$Matches[2]
                }
            }
        }
    }
    elseif ($line -match '^\s{2}\w') {
        $currentSection = $null
    }
}
# Don't forget the last entry
if ($currentSerial -and $currentEntry) {
    $gameIndex[$currentSerial] = $currentEntry
}

Write-Ok "Parsed $($gameIndex.Count) game entries from GameIndex.yaml"

# ============================================================
# SCAN USER'S GAME LIBRARY
# ============================================================
Write-Status "Scanning your game library..."

$gamesettingsDir = Join-Path $PCSX2Path "gamesettings"
$cacheFile = Join-Path $PCSX2Path "cache\gamelist.cache"

# Method 1: Read gamelist.cache (binary — extract serial/CRC pairs)
# The cache is binary, but serials and game names are readable strings
$detectedGames = @{}

# Method 2: Scan existing gamesettings/ for serials
if (Test-Path $gamesettingsDir) {
    $existingConfigs = Get-ChildItem $gamesettingsDir -Filter "*.ini" -ErrorAction SilentlyContinue
    foreach ($cfg in $existingConfigs) {
        if ($cfg.BaseName -match '^([A-Z]{2,4}-\d+)_([A-F0-9]+)$') {
            $serial = $Matches[1]
            $crc = $Matches[2]
            if (-not $detectedGames.ContainsKey($serial)) {
                $name = if ($gameIndex.ContainsKey($serial)) { $gameIndex[$serial].name } else { "Unknown" }
                $detectedGames[$serial] = @{ serial = $serial; crc = $crc; name = $name; source = "existing_config" }
            }
        }
    }
}

# Method 3: Scan cache file for serial patterns
if (Test-Path $cacheFile) {
    try {
        $cacheBytes = [System.IO.File]::ReadAllBytes($cacheFile)
        $cacheText = [System.Text.Encoding]::UTF8.GetString($cacheBytes)
        # Extract SLUS/SLES/SCES/SCUS patterns followed by CRC-like hex
        $matches = [regex]::Matches($cacheText, '(S[A-Z]{3}-\d{5})\x00.*?([A-F0-9]{8})')
        foreach ($m in $matches) {
            $serial = $m.Groups[1].Value
            $crc = $m.Groups[2].Value
            if (-not $detectedGames.ContainsKey($serial)) {
                $name = if ($gameIndex.ContainsKey($serial)) { $gameIndex[$serial].name } else { "Unknown" }
                $detectedGames[$serial] = @{ serial = $serial; crc = $crc; name = $name; source = "cache" }
            }
        }
    } catch {
        Write-Warn "Could not parse gamelist.cache: $_"
    }
}

# Method 4: Scan for ISO/BIN/CHD files and extract serials
$gamesDirs = @(
    (Join-Path $PCSX2Path "games"),
    (Join-Path $PCSX2Path "isos"),
    (Join-Path $PCSX2Path "roms")
)

# Also check PCSX2.ini for configured game directories
$pcsx2Ini = Join-Path $PCSX2Path "inis\PCSX2.ini"
if (Test-Path $pcsx2Ini) {
    $iniContent = Get-Content $pcsx2Ini -Raw
    if ($iniContent -match 'RecursivePaths\s*=\s*(.+)') {
        $paths = $Matches[1] -split ','
        $gamesDirs += $paths | ForEach-Object { $_.Trim() } | Where-Object { $_ -and (Test-Path $_) }
    }
    # Also check individual path entries
    $pathMatches = [regex]::Matches($iniContent, 'GameSearchPath\d*\s*=\s*(.+)')
    foreach ($pm in $pathMatches) {
        $gPath = $pm.Groups[1].Value.Trim()
        if ($gPath -and (Test-Path $gPath)) {
            $gamesDirs += $gPath
        }
    }
}

foreach ($gDir in ($gamesDirs | Select-Object -Unique)) {
    if (-not (Test-Path $gDir)) { continue }
    $gameFiles = Get-ChildItem $gDir -Include "*.iso","*.bin","*.chd","*.gz","*.cso" -Recurse -ErrorAction SilentlyContinue
    if ($gameFiles) {
        Write-Info "Found $($gameFiles.Count) game files in: $gDir"
    }
}

if ($detectedGames.Count -eq 0) {
    Write-Warn "No games detected automatically."
    Write-Info "The tool will install bundled configs for all 24 pre-configured games."
    Write-Info "You can also add games manually by placing configs in gamesettings/"
}
else {
    Write-Ok "Detected $($detectedGames.Count) games in your library"
}

# ============================================================
# GENERATE PER-GAME CONFIGS
# ============================================================
Write-Status "Generating optimized per-game configs..."

# Create gamesettings directory if needed
if (-not (Test-Path $gamesettingsDir)) {
    if (-not $DryRun) {
        New-Item -Path $gamesettingsDir -ItemType Directory -Force | Out-Null
    }
    Write-Ok "Created gamesettings directory"
}

# First, install bundled pre-tested configs from this repo
$bundledDir = Join-Path $PSScriptRoot "..\gamesettings"
$bundledConfigs = @()
if (Test-Path $bundledDir) {
    $bundledConfigs = Get-ChildItem $bundledDir -Filter "*.ini"
}

# Map of gsHWFix names to .ini key names
$hwFixMap = @{
    "halfPixelOffset"            = "UserHacks_HalfPixelOffset"
    "nativeScaling"              = "UserHacks_native_scaling"
    "roundSprite"                = "UserHacks_round_sprite_offset"
    "autoFlush"                  = "UserHacks_AutoFlushLevel"
    "textureInsideRt"            = "UserHacks_TextureInsideRt"
    "cpuSpriteRenderBW"          = "UserHacks_CPUSpriteRenderBW"
    "cpuSpriteRenderLevel"       = "UserHacks_CPUSpriteRenderLevel"
    "cpuCLUTRender"              = "UserHacks_GPUTargetCLUTMode"
    "gpuTargetCLUTMode"          = "UserHacks_GPUTargetCLUTMode"
    "bilinearUpscale"            = "UserHacks_BilinearHack"
    "recommendedBlendingLevel"   = "accurate_blending_unit"
    "maximumBlendingLevel"       = "accurate_blending_unit"
    "preloadFrameData"           = "preload_frame_with_gs_data"
    "estimateTextureRegion"      = "UserHacks_EstimateTextureRegion"
    "trilinearFiltering"         = "TriFilter"
    "skipDrawStart"              = "UserHacks_SkipDraw_Start"
    "skipDrawEnd"                = "UserHacks_SkipDraw_End"
    "wildHack"                   = "UserHacks_WildHack"
    "mergeSprite"                = "UserHacks_merge_pp_sprite"
    "alignSprite"                = "UserHacks_align_sprite"
    "disablePartialInvalidation" = "UserHacks_DisablePartialInvalidation"
    "texturePreloading"          = "texture_preloading"
    "deinterlace"                = "deinterlace_mode"
    "mipmap"                     = "hw_mipmap"
    "pointListPalette"           = "PointListPalette"
    "disableDepthSupport"        = "UserHacks_DisableDepthSupport"
    "disableSafeFeatures"        = "UserHacks_DisableSafeFeatures"
}

# Map of gamefix names to .ini key names under [EmuCore/Gamefixes]
$gameFixMap = @{
    "EETimingHack"               = "EETimingHack"
    "SoftwareRendererFMVHack"    = "SoftwareRendererFMVHack"
    "FpuNegDivHack"              = "FpuNegDivHack"
    "GoemonTlbHack"              = "GoemonTlbHack"
    "IbitHack"                   = "IbitHack"
    "VuAddSubHack"               = "VuAddSubHack"
    "VuClipFlagHack"             = "VuClipFlagHack"
    "OPHFlagHack"                = "OPHFlagHack"
    "DMABusyHack"                = "DMABusyHack"
    "SkipMPEGHack"               = "SkipMPEGHack"
    "BlitInternalFPSHack"        = "BlitInternalFPSHack"
    "GIFFIFOHack"                = "GIFFIFOHack"
    "VIF1StallHack"              = "VIF1StallHack"
    "XGKickHack"                 = "XGKickHack"
    "FullVU0SyncHack"            = "FullVU0SyncHack"
    "VUSyncHack"                 = "VUSyncHack"
}

# Performance-heavy HW fixes that may need upscale reduction
$heavyFixes = @("cpuSpriteRenderBW", "gpuTargetCLUTMode", "cpuCLUTRender")

$configsGenerated = 0
$configsSkipped = 0
$configsBundled = 0

function Generate-GameConfig {
    param(
        [string]$Serial,
        [string]$CRC,
        [hashtable]$Entry,
        [int]$Upscale,
        [string]$OutputDir,
        [bool]$IsDryRun
    )

    $fileName = "${Serial}_${CRC}.ini"
    $filePath = Join-Path $OutputDir $fileName

    # Check if we have a bundled (pre-tested) config for this exact serial+CRC
    $bundled = $bundledConfigs | Where-Object { $_.Name -eq $fileName }
    if ($bundled) {
        if (-not $IsDryRun) {
            Copy-Item -Path $bundled.FullName -Destination $filePath -Force
        }
        return @{ type = "bundled"; name = $Entry.name; file = $fileName }
    }

    # Generate config from GameIndex.yaml data
    $lines = @()
    $lines += "# $($Entry.name)"
    $lines += "# Serial: $Serial | CRC: $CRC"
    $lines += "# Auto-generated from PCSX2 GameIndex.yaml"
    $lines += ""

    # Determine if any heavy fixes are present
    $hasHeavyFixes = $false
    foreach ($hf in $heavyFixes) {
        if ($Entry.gsHWFixes.ContainsKey($hf)) {
            $hasHeavyFixes = $true
            break
        }
    }

    # Adjust upscale for heavy fix stacks
    $gameUpscale = $Upscale
    if ($hasHeavyFixes -and $gameUpscale -gt 3) {
        $gameUpscale = 3
    }

    # Build [EmuCore/GS] section
    $gsLines = @()
    $gsLines += "upscale_multiplier = $gameUpscale"
    $needsUserHacks = $false

    # Check if hw_mipmap should be off (engine issues)
    $mipOff = $Entry.gsHWFixes.ContainsKey("mipmap") -and $Entry.gsHWFixes["mipmap"] -eq "0"
    if ($mipOff) {
        $gsLines += "hw_mipmap = false"
    } else {
        $gsLines += "hw_mipmap = true"
    }

    $gsLines += "pcrtc_antiblur = true"

    # Process gsHWFixes
    foreach ($fix in $Entry.gsHWFixes.GetEnumerator()) {
        $key = $fix.Key
        $val = $fix.Value

        # Skip mipmap (handled above) and internal-only
        if ($key -eq "mipmap") { continue }
        if ($key -in @("getSkipCount", "beforeDraw")) { continue }

        if ($hwFixMap.ContainsKey($key)) {
            $iniKey = $hwFixMap[$key]

            # Handle boolean values
            if ($val -eq "1" -and $key -in @("preloadFrameData", "estimateTextureRegion", "pointListPalette", "disableDepthSupport", "disableSafeFeatures", "mergeSprite", "alignSprite", "disablePartialInvalidation", "wildHack")) {
                $gsLines += "$iniKey = true"
            }
            else {
                $gsLines += "$iniKey = $val"
            }

            # Track if UserHacks is needed
            if ($iniKey -like "UserHacks_*") {
                $needsUserHacks = $true
            }
        }
    }

    # Add performance enhancements
    $gsLines += "LoadTextureReplacements = true"
    $gsLines += "LoadTextureReplacementsAsync = true"

    # Write [EmuCore/GS] section
    $lines += "[EmuCore/GS]"
    if ($needsUserHacks) {
        $lines += "UserHacks = true"
    }
    $lines += $gsLines
    $lines += ""

    # [EmuCore/Speedhacks]
    $lines += "[EmuCore/Speedhacks]"
    $lines += "vuThread = true"
    $lines += "vu1Instant = true"
    foreach ($sh in $Entry.speedHacks.GetEnumerator()) {
        $lines += "$($sh.Key) = $($sh.Value)"
    }
    $lines += ""

    # [EmuCore]
    $lines += "[EmuCore]"
    $lines += "EnableThreadPinning = true"
    $lines += ""

    # [EmuCore/Gamefixes] (if any)
    if ($Entry.gameFixes.Count -gt 0) {
        $lines += "[EmuCore/Gamefixes]"
        foreach ($gf in $Entry.gameFixes) {
            if ($gameFixMap.ContainsKey($gf)) {
                $lines += "$($gameFixMap[$gf]) = true"
            }
        }
        $lines += ""
    }

    # [EmuCore/CPU/Recompiler] — clamp modes
    if ($Entry.clampModes.Count -gt 0) {
        $lines += "[EmuCore/CPU/Recompiler]"
        foreach ($cm in $Entry.clampModes.GetEnumerator()) {
            $lines += "$($cm.Key) = $($cm.Value)"
        }
        $lines += ""
    }

    # [EmuCore/CPU] — round modes
    if ($Entry.roundModes.Count -gt 0) {
        $lines += "[EmuCore/CPU]"
        foreach ($rm in $Entry.roundModes.GetEnumerator()) {
            # Map roundMode names to .ini format
            switch ($rm.Key) {
                "eeRoundMode" { $lines += "FPU.Roundmode = $($rm.Value)" }
                "vuRoundMode" { $lines += "VU.Roundmode = $($rm.Value)" }
                default { $lines += "$($rm.Key) = $($rm.Value)" }
            }
        }
        $lines += ""
    }

    # Write the file
    if (-not $IsDryRun) {
        $content = ($lines -join "`r`n").TrimEnd()
        Set-Content -Path $filePath -Value $content -Encoding UTF8NoBOM
    }

    return @{ type = "generated"; name = $Entry.name; file = $fileName }
}

# Process detected games
$results = @()

if ($detectedGames.Count -gt 0) {
    foreach ($game in $detectedGames.Values) {
        $serial = $game.serial
        $crc = $game.crc

        if (-not $gameIndex.ContainsKey($serial)) {
            Write-Warn "  $serial ($($game.name)) — not found in GameIndex.yaml, skipping"
            $configsSkipped++
            continue
        }

        $entry = $gameIndex[$serial]
        $result = Generate-GameConfig -Serial $serial -CRC $crc -Entry $entry -Upscale $defaultUpscale -OutputDir $gamesettingsDir -IsDryRun $DryRun

        if ($result.type -eq "bundled") {
            Write-Ok "$($result.name) — installed pre-tested config"
            $configsBundled++
        } else {
            Write-Ok "$($result.name) — generated from GameIndex.yaml"
            $configsGenerated++
        }
        $results += $result
    }
}

# Also install any bundled configs that weren't already handled
foreach ($bc in $bundledConfigs) {
    $targetPath = Join-Path $gamesettingsDir $bc.Name
    $alreadyHandled = $results | Where-Object { $_.file -eq $bc.Name }

    if (-not $alreadyHandled) {
        if ($bc.BaseName -match '^([A-Z]{2,4}-\d+)_([A-F0-9]+)$') {
            $serial = $Matches[1]
            $gameName = if ($gameIndex.ContainsKey($serial)) { $gameIndex[$serial].name } else { $bc.BaseName }

            if (-not $DryRun) {
                Copy-Item -Path $bc.FullName -Destination $targetPath -Force
            }
            Write-Ok "$gameName — installed bundled config"
            $configsBundled++
        }
    }
}

Write-Host ""
Write-Status "Config generation complete:"
Write-Info "Bundled (pre-tested): $configsBundled"
Write-Info "Auto-generated:      $configsGenerated"
Write-Info "Skipped:             $configsSkipped"

# ============================================================
# INSTALL RESHADE PRESETS
# ============================================================
if (-not $SkipReShade) {
    Write-Host ""
    Write-Status "Installing ReShade presets..."

    $presetsSource = Join-Path $PSScriptRoot "..\reshade-presets"
    $presetsTarget = Join-Path $PCSX2Path "tools\PCSX2_Visual_Suite\presets"

    if (Test-Path $presetsSource) {
        if (-not $DryRun) {
            if (-not (Test-Path $presetsTarget)) {
                New-Item -Path $presetsTarget -ItemType Directory -Force | Out-Null
            }
            Copy-Item -Path "$presetsSource\*.ini" -Destination $presetsTarget -Force
        }
        $presetCount = (Get-ChildItem $presetsSource -Filter "*.ini").Count
        Write-Ok "Installed $presetCount ReShade presets to: $presetsTarget"
    }

    # Copy tools
    $toolsSource = Join-Path $PSScriptRoot "..\tools"
    $toolsTarget = Join-Path $PCSX2Path "tools\PCSX2_Visual_Suite"

    foreach ($script in @("switch_preset.ps1", "toggle_enhancements.ps1")) {
        $src = Join-Path $toolsSource $script
        if (Test-Path $src) {
            if (-not $DryRun) {
                Copy-Item -Path $src -Destination (Join-Path $toolsTarget $script) -Force
            }
        }
    }

    # Check if ReShade is installed
    $dxgiDll = Join-Path $PCSX2Path "dxgi.dll"
    if (Test-Path $dxgiDll) {
        Write-Ok "ReShade detected (dxgi.dll present)"

        # Check/fix EffectSearchPaths
        $reshadeIni = Join-Path $PCSX2Path "ReShade.ini"
        if (Test-Path $reshadeIni) {
            $iniContent = Get-Content $reshadeIni -Raw
            $shadersBase = Join-Path $PCSX2Path "reshade-shaders\Shaders"

            if ((Test-Path $shadersBase) -and $iniContent -notmatch "Shaders\\SweetFX") {
                Write-Warn "ReShade EffectSearchPaths missing subdirectories!"
                Write-Info "ReShade does NOT recursively search shader directories."
                Write-Info "Add SweetFX, AstrayFX, qUINT subdirs to EffectSearchPaths in ReShade.ini"
            }

            if ($iniContent -match "AutoSavePreset=1") {
                Write-Warn "AutoSavePreset is ON — ReShade will overwrite your preset files!"
                Write-Info "Set AutoSavePreset=0 in ReShade.ini to protect presets."
            }
        }
    } else {
        Write-Warn "ReShade not installed (dxgi.dll not found)"
        Write-Host ""
        Write-Host "  To install ReShade:" -ForegroundColor Yellow
        Write-Host "  1. Download from: https://reshade.me" -ForegroundColor White
        Write-Host "  2. Select pcsx2-qt.exe as the target" -ForegroundColor White
        Write-Host "  3. Choose Direct3D 10/11/12 as the API" -ForegroundColor White
        Write-Host "  4. Install shader packages: Standard, SweetFX, AstrayFX, qUINT" -ForegroundColor White
        Write-Host ""
        Write-Host "  After installing, set these in ReShade.ini:" -ForegroundColor Yellow
        Write-Host "  - AutoSavePreset=0" -ForegroundColor White
        Write-Host "  - Add subdirectories to EffectSearchPaths:" -ForegroundColor White
        Write-Host "    Shaders\SweetFX, Shaders\AstrayFX, Shaders\qUINT" -ForegroundColor White
    }
}

# ============================================================
# SUMMARY
# ============================================================
Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " Setup Complete!" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  PCSX2 Path:    $PCSX2Path" -ForegroundColor White
Write-Host "  GPU:           $gpuName" -ForegroundColor White
Write-Host "  GPU Tier:      $gpuTier (${defaultUpscale}x upscale)" -ForegroundColor White
Write-Host "  Configs:       $($configsBundled + $configsGenerated) installed ($configsBundled bundled, $configsGenerated generated)" -ForegroundColor White
if (-not $SkipReShade) {
    Write-Host "  ReShade:       Presets installed" -ForegroundColor White
}
Write-Host ""

if ($DryRun) {
    Write-Host "  [DRY RUN] No files were written. Remove -DryRun to apply changes." -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "  Next steps:" -ForegroundColor Yellow
Write-Host "  1. Launch PCSX2 and play a game" -ForegroundColor White
Write-Host "  2. Press Home in-game to access ReShade overlay" -ForegroundColor White
Write-Host "  3. If a game has issues, check the GitHub repo for updates" -ForegroundColor White
Write-Host ""
