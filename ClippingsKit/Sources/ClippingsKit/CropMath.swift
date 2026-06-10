import Foundation

/// Pure geometry for translating the user's normalized crop selection into a
/// concrete pixel rectangle at export time. Kept free of any imaging framework
/// so the math is unit-testable in isolation (System Design §9).
///
/// Crop rects use **image-pixel convention**: normalized 0...1 with the origin at
/// the top-left, matching `CGImage` pixel space. (This differs from Vision's
/// bottom-left convention used for OCR boxes — the two coordinate spaces are kept
/// deliberately separate.)
public enum CropMath {

    /// Clamp a normalized rect to the unit square, standardizing negative
    /// width/height first. The result may be empty if the input lies fully
    /// outside the unit square.
    public static func clampNormalized(_ rect: CGRect) -> CGRect {
        let r = rect.standardized
        let minX = min(max(r.minX, 0), 1)
        let minY = min(max(r.minY, 0), 1)
        let maxX = min(max(r.maxX, 0), 1)
        let maxY = min(max(r.maxY, 0), 1)
        return CGRect(x: minX, y: minY, width: max(maxX - minX, 0), height: max(maxY - minY, 0))
    }

    /// Convert a normalized crop into an integer pixel rect, clamped to the image
    /// bounds. Edges are rounded outward so the crop never loses selected pixels
    /// to rounding. Returns the full image rect for a `nil`/degenerate crop is the
    /// caller's responsibility — this function assumes a meaningful crop.
    public static func pixelRect(forNormalizedCrop crop: CGRect, imagePixelSize size: CGSize) -> CGRect {
        let c = clampNormalized(crop)
        let x = (c.minX * size.width).rounded(.down)
        let y = (c.minY * size.height).rounded(.down)
        let maxX = (c.maxX * size.width).rounded(.up)
        let maxY = (c.maxY * size.height).rounded(.up)
        let rect = CGRect(x: x, y: y, width: maxX - x, height: maxY - y)
        return rect.intersection(CGRect(origin: .zero, size: size))
    }
}
