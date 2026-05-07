#pragma once
#include "ofMain.h"
#include "include/core/SkColor.h"
#include "include/core/SkRect.h"
#include "include/core/SkPoint.h"

inline SkColor ofColorToSk(const ofColor& c) {
    return SkColorSetARGB(c.a, c.r, c.g, c.b);
}

inline ofColor skColorToOf(SkColor c) {
    return ofColor(SkColorGetR(c), SkColorGetG(c), SkColorGetB(c), SkColorGetA(c));
}

inline SkRect ofRectToSk(const ofRectangle& r) {
    return SkRect::MakeXYWH(r.x, r.y, r.width, r.height);
}

inline ofRectangle skRectToOf(const SkRect& r) {
    return ofRectangle(r.x(), r.y(), r.width(), r.height());
}

inline SkPoint ofVec2ToSk(const glm::vec2& v) {
    return SkPoint::Make(v.x, v.y);
}
