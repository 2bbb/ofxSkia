# Fetch + build Skia for Windows CI.
# Output: libs\skia\lib\vs\skia.lib + libs\skia\include\
# Called by build-addon.yml pre_build_script_windows. Skipped on cache hit.
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
& "$SCRIPT_DIR\fetch_skia_windows.ps1"
& "$SCRIPT_DIR\build_skia_windows.ps1"
