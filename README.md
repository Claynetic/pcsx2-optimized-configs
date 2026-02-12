# PCSX2 Optimized Configs

Per-game configurations, auto-detection, and ReShade visual enhancement presets for PCSX2 — optimized for high-resolution upscaling on modern GPUs.

Every config is cross-referenced against PCSX2's official [GameIndex.yaml](https://github.com/PCSX2/pcsx2/blob/master/bin/resources/GameIndex.yaml) to include all recommended HW fixes, clamp modes, and round modes — then tuned for visual quality at up to 6x native resolution.

## Credits

Built by **[Claynetic](https://github.com/Claynetic)** with **[Claude](https://claude.ai)** (Anthropic). Every config, script, preset, and line of documentation in this project was developed through AI-assisted pair programming using Claude Code.

## Quick Start

### Automatic Setup (Recommended)

The setup script auto-detects your games, GPU tier, and generates optimized configs:

```powershell
.\tools\setup.ps1 -PCSX2Path "C:\path\to\PCSX2"
```

**What it does:**
1. Scans your PCSX2 game library (existing configs, gamelist cache, game directories)
2. Parses GameIndex.yaml for each detected game's official recommended fixes
3. Detects your GPU and sets the appropriate upscale multiplier (3x-6x)
4. Generates per-game `.ini` configs with all HW fixes translated to PCSX2 format
5. Installs 24 pre-tested configs for known games (these override auto-generated ones)
6. Installs ReShade visual enhancement presets

**Options:**
```powershell
.\tools\setup.ps1 -PCSX2Path "C:\PCSX2" -DryRun        # Preview without writing files
.\tools\setup.ps1 -PCSX2Path "C:\PCSX2" -SkipReShade    # Skip ReShade preset install
.\tools\setup.ps1 -Help                                   # Full usage info
```

### Manual Installation

1. Copy `.ini` files from `gamesettings/` into your PCSX2 `gamesettings` folder
2. Files are named `SERIAL_CRC.ini` — they apply automatically to the matching game
3. Launch the game and settings load automatically

## What's Included

### Auto-Detection Engine (`tools/setup.ps1`)

The setup script works with **any PS2 game**, not just the 24 pre-tested titles:

- **GPU Detection** — Identifies your GPU model and classifies it as low/mid/high tier to set appropriate upscale multipliers
- **Game Library Scanning** — Reads your existing PCSX2 configs, gamelist cache, and configured game directories
- **GameIndex.yaml Parsing** — Extracts every recommended fix for each detected game: `gsHWFixes`, `gameFixes`, `clampModes`, `roundModes`
- **Config Generation** — Translates GameIndex fixes to per-game `.ini` format with correct key names
- **Performance Tuning** — Automatically caps upscale for games with heavy fix stacks (CPU sprite rendering, GPU CLUT, etc.)
- **RDNA Detection** — Warns AMD RDNA2/3 users about the Vulkan timeout bug and recommends DX11

### Pre-Tested Configs (`gamesettings/`)

24 hand-tuned configurations that go beyond GameIndex defaults with performance-tested visual enhancements:

| Game | Serial | Key Fixes | Upscale |
|---|---|---|---|
| 007: Everything or Nothing | SLES-52005 | preloadFrameData, HPO 2 | 6x |
| 007: From Russia with Love | SLUS-21282 | textureInsideRT, HPO 4, blending 4, SW FMV hack | 6x |
| 24: The Game | SCES-53358 | vuClampMode 2, autoFlush, roundSprite | 6x |
| 50 Cent: Bulletproof | SLUS-21315 | roundSprite | 6x |
| B-Boy | SCES-53960 | autoFlush, HPO 4, nativeScaling | 6x |
| Barnyard | SLUS-21277 | HPO 2, autoFlush 2, nativeScaling | 6x |
| Black | SLUS-21376 | vuClampMode 3, blending 2, HPO 5, autoFlush 2, nativeScaling 2 | 6x |
| Def Jam: Fight for NY | SLUS-21004 | HPO 4, nativeScaling 2 | 6x |
| GTA: Vice City Stories | SLES-54622 | HPO 2 | 6x |
| Gun | SLUS-21139 | VU1 round 0, blending 3, HPO 5, autoFlush, nativeScaling 2 | 6x |
| Guitar Hero | SLUS-21224 | VU1 round 1 | 4x |
| Guitar Hero III | SLUS-21672 | VU1 round 0, textureInsideRT, HPO 4, nativeScaling, autoFlush | 4x |
| Guitar Hero 5 | SLUS-21865 | VU1 round 0, HPO 4, nativeScaling | 4x |
| Guitar Hero: Greatest Hits | SLES-55544 | VU1 round 0, cpuCLUTRender, HPO 4, nativeScaling, autoFlush | 4x |
| Jackass: The Game | SLUS-21627 | HPO 1 | 6x |
| Matrix: Path of Neo | SLUS-21273 | HPO 2, autoFlush, nativeScaling 2 | 6x |
| Mercenaries | SLUS-20932 | autoFlush 2, nativeScaling | 6x |
| Red Dead Revolver | SLUS-20500 | *(no HW fixes needed)* | 6x |
| Reservoir Dogs | SLUS-21479 | EETimingHack, textureInsideRT, HPO 2, nativeScaling | 6x |
| Sims 2: Castaway | SLUS-21664 | HPO 4 | 6x |
| Sopranos: Road to Respect | SLUS-21388 | HPO 4, nativeScaling, texturePreloading | 6x |
| The Getaway | SCES-51426 | textureInsideRT, texturePreloading, HPO 2 | 6x |
| The Warriors | SLUS-21215 | HPO 4, autoFlush 2, nativeScaling 2 | 6x |
| True Crime: New York City | SLUS-21106 | eeClampMode 2, cpuSpriteBW, gpuTargetCLUT, HPO 5, nativeScaling 2, bilinearUpscale, triFilter | 3x |

> **Note on True Crime NYC:** Heaviest fix stack in the collection. CPU sprite rendering and GPU CLUT fixes are extremely demanding — upscale is capped at 3x even on high-end GPUs.

> **Note on Guitar Hero titles:** Upscale capped at 4x with `hw_mipmap = false` due to engine mipmap bugs that cause artifacts at higher resolutions.

### Visual Enhancement Suite (`tools/visual-suite/`)

ReShade-based post-processing presets and management tools.

#### ReShade Presets (`reshade-presets/`)

6 presets for ReShade 6.x running in DX11 mode:

| Preset | Effects | Best For |
|---|---|---|
| **Default_Balanced** | SMAA, LumaSharpen, Clarity, Vibrance, Curves | Everyday use — clean and sharp |
| **Maximum_Clarity** | SMAA, Smart_Sharp, Clarity, CAS, Levels, Curves | Maximum texture detail |
| **Cinematic** | SMAA, LumaSharpen, Clarity, HDR, LiftGammaGain, BloomingHDR, Vignette | Film-like atmosphere with bloom |
| **Vibrant** | SMAA, LumaSharpen, Vibrance, LiftGammaGain, Tonemap, Levels, Curves | Saturated, pop-out colors |
| **Performance** | FXAA, CAS, Curves | Minimal GPU cost |
| **Retro_Warm** | FXAA, LumaSharpen, DPX, LiftGammaGain, FilmGrain, Vignette | Nostalgic warm film look |

#### Tools

| Tool | Description |
|---|---|
| `tools/setup.ps1` | Auto-detection + config generation + installation |
| `tools/switch_preset.ps1` | Switch ReShade presets from CLI |
| `tools/toggle_enhancements.ps1` | Enable/disable ReShade (renames dxgi.dll) |
| `tools/visual-suite/dashboard.html` | Reference dashboard with controls, presets, and settings |

## ReShade Installation Guide

### Step 1: Install ReShade

1. Download from [reshade.me](https://reshade.me/) (standard version, not the add-on version)
2. Run the installer and click **Browse**
3. Navigate to your `pcsx2-qt.exe`
4. Select **Direct3D 10/11/12** as the rendering API
5. Install these shader packages:
   - **Standard Effects**
   - **SweetFX**
   - **qUINT**
   - **AstrayFX**

### Step 2: Configure ReShade.ini

After installation, edit `ReShade.ini` in your PCSX2 folder:

**Critical settings:**

```ini
[GENERAL]
AutoSavePreset=0
```
> Without this, ReShade silently overwrites your preset files when you toggle effects in-game.

**EffectSearchPaths** — must include subdirectories (ReShade does NOT recurse):
```ini
EffectSearchPaths=.\reshade-shaders\Shaders,.\reshade-shaders\Shaders\SweetFX,.\reshade-shaders\Shaders\AstrayFX,.\reshade-shaders\Shaders\qUINT
```

**TextureSearchPaths** — same treatment for SMAA and other texture dependencies:
```ini
TextureSearchPaths=.\reshade-shaders\Textures,.\reshade-shaders\Textures\SweetFX,.\reshade-shaders\Textures\AstrayFX
```

### Step 3: Install Presets

Copy the `.ini` files from `reshade-presets/` into your preferred directory, then set `PresetPath` in `ReShade.ini` to point to your chosen preset.

Or use the CLI switcher:
```powershell
.\tools\switch_preset.ps1 -List              # See all presets
.\tools\switch_preset.ps1 Cinematic          # Switch to Cinematic
.\tools\switch_preset.ps1 Default_Balanced   # Switch to Default
```

### Step 4: Clear Shader Cache

After changing `EffectSearchPaths`, clear the ReShade shader cache:
```
%LOCALAPPDATA%\Temp\ReShade\
```
Delete the contents of this folder, then restart PCSX2.

## Recommended Global Settings

These global `PCSX2.ini` settings complement the per-game configs:

```ini
[EmuCore/GS]
Renderer = 3                    # DX11 — stable on AMD RDNA2/3
upscale_multiplier = 6          # 6x native (adjust for your GPU)
hw_mipmap = true                # Correct mipmap handling
CASMode = 1                     # Contrast Adaptive Sharpening
MaxAnisotropy = 16              # Maximum anisotropic filtering
texture_preloading = 2          # Full texture preloading
pcrtc_antiblur = true           # Remove PS2 blur
ScreenshotQuality = 85          # High quality screenshots

[EmuCore/Speedhacks]
vuThread = true                 # Multi-threaded VU1
vu1Instant = true               # Instant VU1

[EmuCore]
EnableThreadPinning = true      # Pin threads to cores
EnableFastBoot = true           # Skip BIOS intro

[SPU2/Output]
Backend = Cubeb                 # Required for ReShade compatibility
```

### Why DX11?

Vulkan has known driver timeout issues on RDNA3 GPUs in PCSX2 ([GitHub #10720](https://github.com/PCSX2/pcsx2/issues/10720)). The PCSX2 team changed the Auto renderer default to OpenGL for RDNA2/3 ([PR #12144](https://github.com/PCSX2/pcsx2/pull/12144)). DX11 provides the best stability and ReShade compatibility.

## Performance Notes

| Game | Issue | Solution |
|---|---|---|
| **Black** | GameIndex recommends blending 4, causes ~5fps at 6x | Use blending 2 — still looks great |
| **True Crime NYC** | CPU sprite rendering + GPU CLUT + 7 other HW fixes | Cap at 3x upscale |
| **Guitar Hero (all)** | Engine mipmap bugs | Cap at 4x, disable hw_mipmap |

**GPU Tier Guide** (auto-detected by setup.ps1):

| Tier | GPUs | Default Upscale |
|---|---|---|
| **High** | RTX 4070+, RX 7800+, RTX 3080+ | 6x |
| **Mid** | RTX 3060-3070, RX 6700-6800, GTX 1070-1080 | 4x |
| **Low** | RX 6500-6600, GTX 1050-1060, older | 3x |

## How These Configs Were Built

1. Every game's serial matched against [GameIndex.yaml](https://github.com/PCSX2/pcsx2/blob/master/bin/resources/GameIndex.yaml) for all officially recommended fixes
2. HW fixes (`gsHWFixes`), clamp modes, round modes, and game fixes translated to per-game `.ini` format
3. Visual enhancements layered on top: upscaling, CAS sharpening, texture replacement support, anti-blur
4. Performance tested on RX 7800 XT — settings that dropped framerate were dialed back with documented reasons
5. ReShade presets built using verified shader technique names (technique names differ from filenames)
6. Internal-only GameIndex fixes (`getSkipCount`, `beforeDraw`) excluded — these only work inside GameIndex.yaml itself

## Contributing

### Report an Issue

Found a game that needs tweaking? Open an issue with:
- Game name and serial (e.g., `SLUS-21376`)
- CRC (visible in PCSX2's game list or log)
- What's broken and what you tried
- Your GPU model and PCSX2 version

### Submit a Config

Pull requests with new per-game configs are welcome:

1. Cross-reference against GameIndex.yaml for official fixes
2. Test at your GPU's appropriate upscale multiplier
3. Strip personal settings (cheats, patches, UI preferences, memcard paths)
4. Include the game name and serial in a comment header:
   ```ini
   # Game Name
   # Serial: SLUS-XXXXX | CRC: XXXXXXXX
   ```

### Improve the Auto-Detection

The setup script's GameIndex.yaml parser handles the most common fix types. If you find games where fixes aren't translating correctly, please open an issue with the serial and the expected vs. actual config output.

## License

MIT
