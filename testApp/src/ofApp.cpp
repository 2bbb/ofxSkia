#include "ofApp.h"

void ofApp::setup() {
    ofxSkiaSurface surface;
    surface.allocate(256, 256);

    if (!surface.isAllocated()) {
        ofLogError("testApp") << "Surface allocation failed";
        ofExit(1);
    }

    surface.begin();
    surface.getCanvas()->clear(SkColorSetARGB(255, 255, 0, 0));  // red
    SkPaint paint;
    paint.setColor(SkColorSetARGB(255, 0, 0, 255));  // blue rect
    surface.getCanvas()->drawRect(SkRect::MakeXYWH(64, 64, 128, 128), paint);
    surface.end();

    surface.updateTexture();
    if (!surface.getTexture().isAllocated()) {
        ofLogError("testApp") << "Texture not allocated after updateTexture";
        ofExit(1);
    }

    ofLogNotice("testApp") << "Surface " << surface.getWidth() << "x" << surface.getHeight() << " OK";
    ofLogNotice("testApp") << "All tests passed.";
    ofExit(0);
}
