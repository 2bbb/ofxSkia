# ofxSkia

openFrameworks addon providing a [Skia](https://skia.org/) raster surface with `ofTexture` interop.

## What it does

Wraps a Skia raster `SkSurface` so you can draw 2D vector graphics with `SkCanvas`, then blit the result to an `ofTexture` for display in an OF window. Skia handles anti-aliasing, path rendering, PDF export, and correct color space handling — none of which OF's built-in 2D API does well.

## Classes

### `ofxSkiaSurface`
The main entry point. Manages a raster surface, pixel readback, and texture upload.

```cpp
ofxSkiaSurface surface;
surface.allocate(1280, 720);         // allocate at logical size
surface.allocate(1280, 720, 2.0f);   // with HiDPI scale factor

// draw frame
surface.begin();
SkCanvas* canvas = surface.getCanvas();
SkPaint paint;
paint.setColor(SK_ColorRED);
canvas->drawCircle(100, 100, 50, paint);
surface.end();

surface.updateTexture();             // blit pixels → ofTexture
surface.draw(0, 0);                  // render to OF window
surface.draw(0, 0, 640, 360);        // with explicit size

// introspection
surface.getWidth();
surface.getHeight();
surface.getScale();
surface.isAllocated();
```

### `ofxSkiaUtils.h`
Inline conversion helpers between OF and Skia types. Include directly; no `.cpp` needed.

```cpp
SkColor     ofColorToSk(const ofColor& c);
ofColor     skColorToOf(SkColor c);
SkRect      ofRectToSk(const ofRectangle& r);
ofRectangle skRectToOf(const SkRect& r);
SkPoint     ofVec2ToSk(const glm::vec2& v);
```

## Building the library

Skia must be built from source once. The build takes ~30 minutes but the result is cached in `libs/skia/`.

```bash
# Fetch depot_tools + Skia source (~1 GB)
bash scripts/fetch_skia.sh

# Build (macOS universal: arm64 + x64)
bash scripts/build_skia_macos.sh

# Linux x64
bash scripts/build_skia_linux.sh

# Windows — run in PowerShell (requires depot_tools)
.\scripts\fetch_skia_windows.ps1
.\scripts\build_skia_windows.ps1
```

Output: `libs/skia/lib/{osx,linux64,vs}/` + `libs/skia/include/` + `libs/skia/modules/skcms/`  
`libs/` is git-ignored; run the scripts once per machine.

### Skia build configuration (GN args)

Raster only — no GPU backend, no HarfBuzz/ICU duplication, PDF enabled:

```
is_debug=false
skia_use_gl=false  skia_use_metal=false  skia_use_vulkan=false
skia_enable_skparagraph=false  skia_enable_skshaper=false
skia_use_harfbuzz=false  skia_use_icu=false
skia_use_freetype=true  skia_use_system_freetype2=false
skia_enable_pdf=true
```

## Important: SK_TRIVIAL_ABI

`addon_config.mk` sets `-DSK_TRIVIAL_ABI=[[clang::trivial_abi]]`.  
Without this, `sk_sp<T>` return values are passed incorrectly on ARM64 due to ABI mismatch between the Skia static lib and the caller.

## CI

Skia is built from source on the first CI run and cached thereafter (`libs/skia` → `actions/cache`).

[![CI](https://github.com/2bbb/ofxSkia/actions/workflows/ci.yml/badge.svg)](https://github.com/2bbb/ofxSkia/actions/workflows/ci.yml)

Platforms: macOS (Make + Xcode), Linux x64, Windows x64

## Requirements

- openFrameworks 0.12.0+
- Skia chrome/m130
- macOS: Xcode CLI tools, `brew install ninja`
- Linux: `ninja-build python3 libfontconfig1-dev libfreetype6-dev`
- Windows: Visual Studio 2019+, Python 3, depot_tools

## License

MIT
