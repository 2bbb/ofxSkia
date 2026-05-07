#include "ofxSkiaSurface.h"
#include "ofxSkiaUtils.h"
#include "include/core/SkColorSpace.h"
#include "include/core/SkGraphics.h"
#include "include/core/SkImageInfo.h"
#include "include/core/SkSurface.h"
#include "ofLog.h"

void ofxSkiaSurface::allocate(int width, int height, float scale) {
    static bool sSkInit = (SkGraphics::Init(), true);
    width_  = width;
    height_ = height;
    scale_  = scale;

    int w = static_cast<int>(width  * scale);
    int h = static_cast<int>(height * scale);

    SkImageInfo info = SkImageInfo::MakeN32Premul(w, h);
    surface_ = SkSurfaces::Raster(info);

    if(!surface_) {
        ofLogError("ofxSkiaSurface::allocate") << "SkSurfaces::Raster failed";
        return;
    }

    pixels_.allocate(w, h, OF_PIXELS_RGBA);
}

void ofxSkiaSurface::resize(int width, int height) {
    allocate(width, height, scale_);
}

void ofxSkiaSurface::clear(const ofColor& color) {
    if(!surface_) return;
    surface_->getCanvas()->clear(ofColorToSk(color));
}

void ofxSkiaSurface::begin() {
    // raster backend では begin/end はステート管理のみ
}

void ofxSkiaSurface::end() {
}

SkCanvas* ofxSkiaSurface::getCanvas() {
    return surface_ ? surface_->getCanvas() : nullptr;
}

sk_sp<SkSurface> ofxSkiaSurface::getSurface() {
    return surface_;
}

void ofxSkiaSurface::updateTexture() {
    if(!surface_) return;

    SkPixmap pm;
    if(!surface_->peekPixels(&pm)) {
        ofLogError("ofxSkiaSurface::updateTexture") << "peekPixels failed";
        return;
    }

    // Skia N32Premul (BGRA on little-endian) → OF RGBA
    // peekPixels returns raw Skia pixel layout; we read as BGRA and convert
    int w = pm.width();
    int h = pm.height();
    const uint8_t* src = reinterpret_cast<const uint8_t*>(pm.addr());
    uint8_t* dst = pixels_.getData();

    for(int i = 0; i < w * h; ++i) {
        uint8_t b = src[i * 4 + 0];
        uint8_t g = src[i * 4 + 1];
        uint8_t r = src[i * 4 + 2];
        uint8_t a = src[i * 4 + 3];
        // premul → straight alpha
        if(a > 0) {
            dst[i * 4 + 0] = static_cast<uint8_t>(r * 255 / a);
            dst[i * 4 + 1] = static_cast<uint8_t>(g * 255 / a);
            dst[i * 4 + 2] = static_cast<uint8_t>(b * 255 / a);
        } else {
            dst[i * 4 + 0] = 0;
            dst[i * 4 + 1] = 0;
            dst[i * 4 + 2] = 0;
        }
        dst[i * 4 + 3] = a;
    }

    texture_.loadData(pixels_);
}

ofTexture& ofxSkiaSurface::getTexture() {
    return texture_;
}

void ofxSkiaSurface::draw(float x, float y) {
    texture_.draw(x, y, static_cast<float>(width_), static_cast<float>(height_));
}

void ofxSkiaSurface::draw(float x, float y, float w, float h) {
    texture_.draw(x, y, w, h);
}

int   ofxSkiaSurface::getWidth()    const { return width_;  }
int   ofxSkiaSurface::getHeight()   const { return height_; }
float ofxSkiaSurface::getScale()    const { return scale_;  }
bool  ofxSkiaSurface::isAllocated() const { return surface_ != nullptr; }
