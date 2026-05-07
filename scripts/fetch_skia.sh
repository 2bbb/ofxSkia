#!/bin/bash
set -euo pipefail

DEPOT_TOOLS_DIR="/tmp/depot_tools"
SKIA_DIR="/tmp/skia"
SKIA_BRANCH="chrome/m130"

if [ ! -d "${DEPOT_TOOLS_DIR}" ]; then
  echo "==> Cloning depot_tools..."
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git "${DEPOT_TOOLS_DIR}"
else
  echo "==> depot_tools already exists at ${DEPOT_TOOLS_DIR}, skipping clone."
fi

export PATH="${DEPOT_TOOLS_DIR}:${PATH}"

if [ ! -d "${SKIA_DIR}" ]; then
  echo "==> Fetching Skia source (~1GB, this will take a while)..."
  mkdir -p "${SKIA_DIR}"
  cd "${SKIA_DIR}"
  fetch skia
else
  echo "==> Skia source already exists at ${SKIA_DIR}, skipping fetch."
fi

cd "${SKIA_DIR}/skia"

echo "==> Switching to branch ${SKIA_BRANCH}..."
git checkout "${SKIA_BRANCH}"

echo "==> Syncing dependencies..."
python3 tools/git-sync-deps

echo ""
echo "==> Done. Skia source at ${SKIA_DIR}"
