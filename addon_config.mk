meta:
	ADDON_NAME = ofxSkia
	ADDON_DESCRIPTION = Skia rendering bridge for openFrameworks
	ADDON_AUTHOR = 2bbb
	ADDON_TAGS = "rendering" "2d" "vector" "typography"
	ADDON_URL = http://github.com/2bbb/ofxSkia

common:
	ADDON_INCLUDES = src
	ADDON_INCLUDES += libs/skia
	ADDON_CPPFLAGS = -DSK_TRIVIAL_ABI=[[clang::trivial_abi]]

osx:
	ADDON_LIBS = libs/skia/lib/osx/libskia.a
	ADDON_FRAMEWORKS = CoreFoundation CoreGraphics CoreText ImageIO

linux64:
	ADDON_LIBS = libs/skia/lib/linux64/libskia.a
	ADDON_LDFLAGS = -lfontconfig -lfreetype

linuxaarch64:
	ADDON_LIBS = libs/skia/lib/linuxaarch64/libskia.a
	ADDON_LDFLAGS = -lfontconfig -lfreetype

vs:
	ADDON_LIBS = libs/skia/lib/vs/skia.lib
	ADDON_LDFLAGS = opengl32.lib gdi32.lib user32.lib

msys2:

emscripten:

android:
