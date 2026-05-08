# Build skia.lib for Windows (MSVC x64).
# Run fetch_skia_windows.ps1 first.
# Usage:
#   .\build_skia_windows.ps1           # Release (/MD,  is_debug=false)
#   .\build_skia_windows.ps1 -Debug    # Debug   (/MDd, is_debug=true)
param([switch]$Debug)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Prerequisite checks ───────────────────────────────────────────────────────

$DEPOT_TOOLS_DIR = "C:\depot_tools"
$env:Path = "$DEPOT_TOOLS_DIR;$env:Path"
$env:DEPOT_TOOLS_WIN_TOOLCHAIN = "0"

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Error "ERROR: python not found. Run fetch_skia_windows.ps1 first (it checks prerequisites)."
    exit 1
}
$pythonPath = (Get-Command python).Source
if ($pythonPath -like "*WindowsApps*") {
    Write-Error "ERROR: 'python' is the Microsoft Store stub ($pythonPath). See fetch_skia_windows.ps1 for fix."
    exit 1
}

$SKIA_DIR = "C:\skia\skia"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$OUT_DIR = Join-Path $SCRIPT_DIR "..\libs\skia"

if (-not (Test-Path $SKIA_DIR)) {
    Write-Error "ERROR: $SKIA_DIR not found. Run fetch_skia_windows.ps1 first."
    exit 1
}

Push-Location $SKIA_DIR

if (-not (Test-Path "bin\gn.exe")) {
    Write-Host "==> Fetching gn..."
    python bin/fetch-gn
}

if (-not (Test-Path "third_party\ninja\ninja.exe")) {
    Write-Host "==> Fetching ninja..."
    python bin/fetch-ninja
}
$env:Path = "$SKIA_DIR\third_party\ninja;$env:Path"

Write-Host "==> Syncing third-party dependencies..."
python tools/git-sync-deps

# ── Configuration ─────────────────────────────────────────────────────────────

if ($Debug) {
    $outSubdir = "out\vs_debug"
    $isDebug   = "true"
    $cflags    = '"/MDd"'
    $ldflags   = '"/DEFAULTLIB:msvcrtd.lib"'
    $libDst    = Join-Path $OUT_DIR "lib\vs\debug"
} else {
    $outSubdir = "out\vs"
    $isDebug   = "false"
    $cflags    = '"/MD"'
    $ldflags   = '"/DEFAULTLIB:msvcrt.lib"'
    $libDst    = Join-Path $OUT_DIR "lib\vs"
}

# Write args.gn directly — avoids PowerShell stripping double-quotes from
# string literals like target_os="win" when passed via --args= on the command line.
New-Item -ItemType Directory -Force -Path $outSubdir | Out-Null
$argsContent = @"
is_debug=$isDebug
target_os="win"
target_cpu="x64"
skia_use_gl=false
skia_use_metal=false
skia_use_vulkan=false
skia_use_dawn=false
skia_enable_skparagraph=false
skia_enable_skshaper=false
skia_use_harfbuzz=false
skia_use_icu=false
skia_use_freetype=true
skia_use_system_freetype2=false
skia_enable_pdf=true
skia_enable_svg=false
skia_use_expat=false
skia_use_libjpeg_turbo_decode=false
skia_use_libjpeg_turbo_encode=false
skia_use_libpng_decode=true
skia_use_libpng_encode=true
skia_use_libwebp_decode=false
skia_use_libwebp_encode=false
skia_use_wuffs=true
skia_use_zlib=true
skia_use_libavif=false
skia_use_libjxl_decode=false
extra_cflags=[$cflags]
extra_ldflags=[$ldflags]
"@
# Use WriteAllText for BOM-free UTF-8 — Set-Content -Encoding UTF8 adds BOM
# which GN rejects with "Invalid token" at 1:1.
[System.IO.File]::WriteAllText(
    (Join-Path (Get-Location) "$outSubdir\args.gn"),
    $argsContent
)

bin\gn gen $outSubdir
ninja -C $outSubdir skia

New-Item -ItemType Directory -Force -Path $libDst | Out-Null

# Merge satellite libs (libpng, zlib, freetype2, skcms, expat) into skia.lib so
# callers only need to link one file. lib.exe is bundled with VS.
$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$vsInstall = & $vsWhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
$libExe = Get-ChildItem -Path $vsInstall -Filter "lib.exe" -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match "x64\\lib\.exe$" } |
    Select-Object -First 1 -ExpandProperty FullName
if (-not $libExe) { Write-Error "lib.exe not found under $vsInstall"; exit 1 }

Write-Host "==> Merging satellite libs into skia.lib using: $libExe"
$satelliteLibs = @("$outSubdir\libpng.lib", "$outSubdir\zlib.lib", "$outSubdir\freetype2.lib",
                   "$outSubdir\skcms.lib", "$outSubdir\expat.lib")
$existingSatellites = $satelliteLibs | Where-Object { Test-Path $_ }
$mergeArgs = @("/OUT:$outSubdir\skia_merged.lib", "$outSubdir\skia.lib") + $existingSatellites
& $libExe @mergeArgs
if ($LASTEXITCODE -ne 0) { Write-Error "lib.exe merge failed"; exit 1 }
Move-Item -Force "$outSubdir\skia_merged.lib" "$outSubdir\skia.lib"

Copy-Item "$outSubdir\skia.lib" "$libDst\"

$incDst = Join-Path $OUT_DIR "include"
New-Item -ItemType Directory -Force -Path $incDst | Out-Null
robocopy include $incDst *.h /S /NFL /NDL /NJH /NJS | Out-Null
# modules/skcms/: skcms.h + src/skcms_public.h
New-Item -ItemType Directory -Force -Path "$OUT_DIR\modules\skcms\src" | Out-Null
Copy-Item "modules\skcms\skcms.h" "$OUT_DIR\modules\skcms\"
Copy-Item "modules\skcms\src\skcms_public.h" "$OUT_DIR\modules\skcms\src\"
# Reset LASTEXITCODE: robocopy returns 1 on success which looks like failure
$global:LASTEXITCODE = 0

Pop-Location

Write-Host "Done: $libDst\skia.lib"