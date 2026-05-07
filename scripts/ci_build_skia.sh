#!/bin/bash
set -euo pipefail
# Fetch + build Skia for CI (macOS universal or Linux x64).
# Output: libs/skia/lib/{osx|linux64}/libskia.a + libs/skia/include/
# Called by build-addon.yml pre_build_script. Skipped on cache hit.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ "$(uname)" == "Darwin" ]]; then
    brew install ninja
    bash "$SCRIPT_DIR/fetch_skia.sh"
    bash "$SCRIPT_DIR/build_skia_macos.sh"
else
    sudo apt-get install -y ninja-build python3 rsync
    bash "$SCRIPT_DIR/fetch_skia.sh"
    bash "$SCRIPT_DIR/build_skia_linux.sh"
fi
