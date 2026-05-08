# Fetch Skia source for Windows.
# Requires: Git, Python 3
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Tool resolver ─────────────────────────────────────────────────────────────

function Resolve-Tool {
    param(
        [string]$Name,
        [string[]]$KnownPaths,
        [string]$InstallHint
    )
    if (Get-Command $Name -ErrorAction SilentlyContinue) { return }

    foreach ($dir in $KnownPaths) {
        if (Test-Path (Join-Path $dir "$Name.exe")) {
            Write-Host "==> $Name not in PATH, using: $dir"
            $env:Path = "$dir;$env:Path"
            return
        }
    }

    Write-Error @"
ERROR: '$Name' not found in PATH or known install locations.
$InstallHint
After installing, restart PowerShell and re-run.
"@
    exit 1
}

# ── Prerequisite checks ───────────────────────────────────────────────────────

# git
Resolve-Tool git `
    -KnownPaths @(
        "C:\Program Files\Git\bin",
        "C:\Program Files\Git\cmd"
    ) `
    -InstallHint "Install git with:  winget install Git.Git"

# python — must exist and must NOT be the Microsoft Store stub
Resolve-Tool python `
    -KnownPaths @(
        "$env:LOCALAPPDATA\Programs\Python\Python312",
        "$env:LOCALAPPDATA\Programs\Python\Python311",
        "$env:LOCALAPPDATA\Programs\Python\Python310",
        "C:\Python312",
        "C:\Python311"
    ) `
    -InstallHint "Install python with:  winget install Python.Python.3.12"

$pythonPath = (Get-Command python).Source
if ($pythonPath -like "*WindowsApps*") {
    Write-Error @"
ERROR: 'python' resolves to the Microsoft Store stub:
    $pythonPath
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
