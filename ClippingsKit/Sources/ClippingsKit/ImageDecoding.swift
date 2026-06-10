// Apple-only: ImageIO-based decode paths. The two-path strategy of System
// Design §6 — downsampled decode for preview/OCR, full-resolution decode only at
// export — lives here so the share extension never holds more than one full
// bitmap at a time.
//
// Phase 2 component. Structurally complete but UNTESTED — validate peak memory in
// Instruments (roadmap Spike B) before relying on it.

#if canImport(ImageIO) && canImport(CoreGraphics)
import ImageIO
import CoreGraphics
import Foundation

public enum ImageDecoding {

    /// Decode a downsampled `CGImage` whose longest edge is at most `maxPixelSize`,
    /// using ImageIO's thumbnail API so the full bitmap is never resident. Used for
    /// the on-screen preview and the Vision request.
    public static func downsampledImage(from data: Data, maxPixelSize: Int) -> CGImage? {
        let sourceOptions: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary) else {
            return nil
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    /// Decode the source once at full resolution. Used only at export time, inside
    /// an autorelease scope, per the memory strategy.
    public static func fullResolutionImage(from data: Data) -> CGImage? {
        let options: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else {
            return nil
        }
        return CGImageSourceCreateImageAtIndex(source, 0, options as CFDictionary)
    }
}
#endif
