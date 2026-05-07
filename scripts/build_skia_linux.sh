#!/bin/bash
set -euo pipefail
# Build libskia.a for linux64 (x86_64).
# Run fetch_skia.sh first.

DEPOT_TOOLS_DIR="/tmp/depot_tools"
SKIA_DIR="/tmp/skia"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/../libs/skia"

if [ ! -d "${SKIA_DIR}/skia" ]; then
  echo "ERROR: ${SKIA_DIR}/skia not found. Run fetch_skia.sh first."
  exit 1
fi

export PATH="${DEPOT_TOOLS_DIR}:${PATH}"
cd "${SKIA_DIR}/skia"

if [ ! -f "bin/gn" ]; then
  python3 bin/fetch-gn
fi

echo "==> Syncing third-party dependencies..."
python3 tools/git-sync-deps

bin/gn gen out/linux64 --args='
  is_debug=false
  target_os="linux" target_cpu="x64"
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
'

ninja -C out/linux64 skia

mkdir -p "${OUT_DIR}/lib/linux64"
cp out/linux64/libskia.a "${OUT_DIR}/lib/linux64/"

mkdir -p "${OUT_DIR}/include"
rsync -a --include="*/" --include="*.h" --exclude="*" include/ "${OUT_DIR}/include/"
mkdir -p "${OUT_DIR}/include/modules/skcms"
cp modules/skcms/skcms.h "${OUT_DIR}/include/modules/skcms/"

echo "Done: ${OUT_DIR}/lib/linux64/libskia.a"
file "${OUT_DIR}/lib/linux64/libskia.a"
