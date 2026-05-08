# Fetch Skia source for Windows.
# Requires: Git, Python 3
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Prerequisite checks ───────────────────────────────────────────────────────

# git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error @"
ERROR: git not found in PATH.
Install it with:
    winget install Git.Git
Then restart PowerShell and re-run this script.
"@
    exit 1
}

# python — must exist and must NOT be the Microsoft Store stub
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Error @"
ERROR: python not found in PATH.
Install it with:
    winget install Python.Python.3.12
Then restart PowerShell and re-run this script.
"@
    exit 1
}
$pythonPath = (Get-Command python).Source
if ($pythonPath -like "*WindowsApps*") {
    Write-Error @"
ERROR: 'python' resolves to the Microsoft Store stub:
    $pythonPath
This stub does not work for Skia's build tools.
Fix: Settings -> Apps -> App execution aliases -> disable python.exe and python3.exe.
Then install the real Python:
    winget install Python.Python.3.12
And restart PowerShell.
"@
    exit 1
}
Write-Host "==> python OK: $pythonPath"

# ── Long path support (Skia source tree exceeds 260-char limit) ───────────────

$longPathKey  = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
$longPathValue = (Get-ItemProperty -Path $longPathKey -Name LongPathsEnabled -ErrorAction SilentlyContinue).LongPathsEnabled
if ($longPathValue -ne 1) {
    Write-Host "==> Enabling long path support (requires admin)..."
    try {
        New-ItemProperty -Path $longPathKey -Name LongPathsEnabled -Value 1 `
            -PropertyType DWORD -Force | Out-Null
        git config --system core.longpaths true
        Write-Host "    Long paths enabled."
    } catch {
        Write-Warning @"
Could not enable long paths (not running as admin?).
Run PowerShell as Administrator and execute:
    New-ItemProperty -Path '$longPathKey' -Name LongPathsEnabled -Value 1 -PropertyType DWORD -Force
    git config --system core.longpaths true
Then re-run this script.
"@
    }
} else {
    Write-Host "==> Long paths already enabled."
}

# ── Fetch ─────────────────────────────────────────────────────────────────────

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
