#pragma once
#include "include/core/SkGraphics.h"
#include "ofxSkiaSurface.h"
#include "ofxSkiaUtils.h"

namespace ofxSkia {
    inline void init() { SkGraphics::Init(); }
}
