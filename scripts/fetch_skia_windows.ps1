# Fetch Skia source for Windows.
# Requires: Git, Python3
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$DEPOT_TOOLS_DIR = "C:\depot_tools"
$SKIA_DIR = "C:\skia"
$SKIA_BRANCH = "chrome/m130"

if (-not (Test-Path $DEPOT_TOOLS_DIR)) {
    Write-Host "==> Cloning depot_tools..."
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git $DEPOT_TOOLS_DIR
} else {
    Write-Host "==> depot_tools already exists, skipping."
}

$env:Path = "$DEPOT_TOOLS_DIR;$env:Path"
# depot_tools on Windows needs DEPOT_TOOLS_WIN_TOOLCHAIN=0 for non-Googlers
$env:DEPOT_TOOLS_WIN_TOOLCHAIN = "0"

if (-not (Test-Path "$SKIA_DIR\skia")) {
    Write-Host "==> Fetching Skia source (~1GB)..."
    New-Item -ItemType Directory -Force -Path $SKIA_DIR | Out-Null
    Push-Location $SKIA_DIR
    fetch skia
    Pop-Location
} else {
    Write-Host "==> Skia source already exists, skipping."
}

Push-Location "$SKIA_DIR\skia"
Write-Host "==> Switching to branch $SKIA_BRANCH..."
git checkout $SKIA_BRANCH
Write-Host "==> Syncing dependencies..."
python tools/git-sync-deps
Pop-Location

Write-Host "Done. Skia source at $SKIA_DIR\skia"
