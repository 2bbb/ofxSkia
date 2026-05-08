# Build skia.lib for Windows (MSVC x64).
# Run fetch_skia_windows.ps1 first.
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$DEPOT_TOOLS_DIR = "C:\depot_tools"
$SKIA_DIR = "C:\skia\skia"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$OUT_DIR = Join-Path $SCRIPT_DIR "..\libs\skia"

if (-not (Test-Path $SKIA_DIR)) {
    Write-Error "ERROR: $SKIA_DIR not found. Run fetch_skia_windows.ps1 first."
    exit 1
}

$env:Path = "$DEPOT_TOOLS_DIR;$env:Path"
$env:DEPOT_TOOLS_WIN_TOOLCHAIN = "0"

Push-Location $SKIA_DIR

if (-not (Test-Path "bin\gn.exe")) {
    Write-Host "==> Fetching gn..."
    python bin/fetch-gn
}

Write-Host "==> Syncing third-party dependencies..."
python tools/git-sync-deps

$GN_ARGS = @"
is_debug=false
target_os="win" target_cpu="x64"
skia_use_gl=false skia_use_metal=false skia_use_vulkan=false skia_use_dawn=false
skia_enable_skparagraph=false skia_enable_skshaper=false
skia_use_harfbuzz=false skia_use_icu=false
skia_use_freetype=true skia_use_system_freetype2=false
skia_enable_pdf=true skia_enable_svg=false skia_use_expat=false
skia_use_libjpeg_turbo_decode=true skia_use_libjpeg_turbo_encode=true
skia_use_libpng_decode=false skia_use_libpng_encode=false
skia_use_libwebp_decode=false skia_use_libwebp_encode=false
skia_use_wuffs=false skia_use_zlib=true
skia_use_libavif=false skia_use_libjxl_decode=false
"@

bin\gn gen out\vs ("--args=" + ($GN_ARGS -replace "`n", " "))
ninja -C out\vs skia

$libDst = Join-Path $OUT_DIR "lib\vs"
New-Item -ItemType Directory -Force -Path $libDst | Out-Null
Copy-Item out\vs\skia.lib "$libDst\"

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
