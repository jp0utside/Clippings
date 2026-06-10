import XCTest
@testable import ClippingsKit

final class CropMathTests: XCTestCase {

    func testFullFrameCropMapsToWholeImage() {
        let size = CGSize(width: 1000, height: 2000)
        let rect = CropMath.pixelRect(forNormalizedCrop: CGRect(x: 0, y: 0, width: 1, height: 1), imagePixelSize: size)
        XCTAssertEqual(rect, CGRect(x: 0, y: 0, width: 1000, height: 2000))
    }

    func testCenterQuarterCrop() {
        let size = CGSize(width: 1000, height: 1000)
        let rect = CropMath.pixelRect(forNormalizedCrop: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5), imagePixelSize: size)
        XCTAssertEqual(rect, CGRect(x: 250, y: 250, width: 500, height: 500))
    }

    func testCropIsClampedToImageBounds() {
        let size = CGSize(width: 800, height: 600)
        // Extends past the right/bottom edges and starts slightly negative.
        let rect = CropMath.pixelRect(forNormalizedCrop: CGRect(x: -0.1, y: -0.1, width: 1.3, height: 1.3), imagePixelSize: size)
        XCTAssertEqual(rect, CGRect(x: 0, y: 0, width: 800, height: 600))
    }

    func testClampNormalizedStandardizesNegativeSize() {
        let clamped = CropMath.clampNormalized(CGRect(x: 0.6, y: 0.6, width: -0.2, height: -0.2))
        XCTAssertEqual(clamped, CGRect(x: 0.4, y: 0.4, width: 0.2, height: 0.2))
    }

    func testEdgesRoundOutwardToNotLosePixels() {
        let size = CGSize(width: 1000, height: 1000)
        // 0.3335 * 1000 = 333.5 -> floor 333 ; maxX 0.6665*1000=666.5 -> ceil 667
        let rect = CropMath.pixelRect(forNormalizedCrop: CGRect(x: 0.3335, y: 0.3335, width: 0.333, height: 0.333), imagePixelSize: size)
        XCTAssertEqual(rect.minX, 333)
        XCTAssertEqual(rect.maxX, 667)
    }
}
