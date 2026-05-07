// Stub implementations for Skia encoder symbols excluded from the build.
// These are referenced by SkWriteBuffer (serialization) but not needed for raster rendering.
#include "include/encode/SkPngEncoder.h"
#include "include/core/SkData.h"
#include "include/core/SkStream.h"

namespace SkPngEncoder {

bool Encode(SkWStream*, const SkPixmap&, const Options&) { return false; }

sk_sp<SkData> Encode(GrDirectContext*, const SkImage*, const Options&) { return nullptr; }

std::unique_ptr<SkEncoder> Make(SkWStream*, const SkPixmap&, const Options&) { return nullptr; }

}  // namespace SkPngEncoder
