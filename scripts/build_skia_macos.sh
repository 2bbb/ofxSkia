#!/bin/bash
set -euo pipefail

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
  echo "==> Fetching gn..."
  python3 bin/fetch-gn
fi

# Sync deps needed for PDF (libjpeg-turbo, zlib)
echo "==> Syncing third-party dependencies..."
python3 tools/git-sync-deps

GN_ARGS_COMMON='
  is_debug=false

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

  skia_use_libjpeg_turbo_decode=true
  skia_use_libjpeg_turbo_encode=true
  skia_use_libpng_decode=false
  skia_use_libpng_encode=false
  skia_use_libwebp_decode=false
  skia_use_libwebp_encode=false
  skia_use_wuffs=false
  skia_use_zlib=true
  skia_use_libavif=false
  skia_use_libjxl_decode=false
'

echo "==> Building Skia for macOS (arm64 + x64)..."

for ARCH in arm64 x64; do
  echo "  -> ${ARCH}"
  bin/gn gen "out/${ARCH}" --args="
    ${GN_ARGS_COMMON}
    target_os=\"mac\"
    target_cpu=\"${ARCH}\"
  "
  ninja -C "out/${ARCH}" skia
done

echo "==> Creating universal binary..."
mkdir -p "${OUT_DIR}/lib/osx"
lipo "out/arm64/libskia.a" "out/x64/libskia.a" \
     -create -output "${OUT_DIR}/lib/osx/libskia.a"

echo "==> Copying public headers..."
mkdir -p "${OUT_DIR}/include"
rsync -a --include="*/" --include="*.h" --exclude="*" \
      include/ "${OUT_DIR}/include/"
# modules/skcms/skcms.h: ADDON_INCLUDES=libs/skia, so path is libs/skia/modules/skcms/skcms.h
mkdir -p "${OUT_DIR}/modules/skcms"
cp modules/skcms/skcms.h "${OUT_DIR}/modules/skcms/"

echo ""
echo "==> Done."
echo "    Library: ${OUT_DIR}/lib/osx/libskia.a"
echo "    Headers: ${OUT_DIR}/include/"
lipo -info "${OUT_DIR}/lib/osx/libskia.a"
