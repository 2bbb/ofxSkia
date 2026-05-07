#pragma once
#include "ofMain.h"
#include "include/core/SkSurface.h"
#include "include/core/SkCanvas.h"

class ofxSkiaSurface {
public:
    void allocate(int width, int height, float scale = 1.0f);
    void resize(int width, int height);
    void clear(const ofColor& color = ofColor(0, 0, 0, 0));

    void begin();
    void end();

    SkCanvas*        getCanvas();
    sk_sp<SkSurface> getSurface();

    void       updateTexture();
    ofTexture& getTexture();

    void draw(float x, float y);
    void draw(float x, float y, float w, float h);

    int   getWidth()    const;
    int   getHeight()   const;
    float getScale()    const;
    bool  isAllocated() const;

private:
    int   width_ = 0, height_ = 0;
    float scale_ = 1.0f;
    sk_sp<SkSurface> surface_;
    ofPixels  pixels_;
    ofTexture texture_;
};
