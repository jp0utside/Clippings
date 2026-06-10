import XCTest
@testable import ClippingsKit

final class FormatterTests: XCTestCase {

    private let imageData = Data([0xFF, 0xD8, 0xFF]) // stand-in bytes

    func testRawYieldsSingleImageItem() {
        var clipping = Clipping(sourceImageData: imageData, extractedText: "a caption", format: .raw)
        clipping.format = .raw
        let payload = Formatter.payload(imageData: imageData, for: clipping)
        XCTAssertEqual(payload.itemCount, 1)
        XCTAssertNil(payload.caption)
    }

    func testSplitYieldsImageAndCaption() {
        let clipping = Clipping(sourceImageData: imageData, extractedText: "a caption", format: .split)
        let payload = Formatter.payload(imageData: imageData, for: clipping)
        XCTAssertEqual(payload.itemCount, 2)
        XCTAssertEqual(payload.caption, "a caption")
    }

    func testSplitWithWhitespaceCaptionDegradesToSingleItem() {
        let clipping = Clipping(sourceImageData: imageData, extractedText: "   \n ", format: .split)
        let payload = Formatter.payload(imageData: imageData, for: clipping)
        XCTAssertEqual(payload.itemCount, 1)
        XCTAssertNil(payload.caption)
    }

    func testSplitTrimsCaption() {
        let clipping = Clipping(sourceImageData: imageData, extractedText: "  hello  ", format: .split)
        let payload = Formatter.payload(imageData: imageData, for: clipping)
        XCTAssertEqual(payload.caption, "hello")
    }
}

final class ClippingTests: XCTestCase {

    func testHasCaptionFalseForNilOrBlank() {
        XCTAssertFalse(Clipping(sourceImageData: Data(), extractedText: nil).hasCaption)
        XCTAssertFalse(Clipping(sourceImageData: Data(), extractedText: "   ").hasCaption)
    }

    func testHasCaptionTrueForRealText() {
        XCTAssertTrue(Clipping(sourceImageData: Data(), extractedText: "hi").hasCaption)
    }

    func testDefaultsAreRawJpeg() {
        let clipping = Clipping(sourceImageData: Data())
        XCTAssertEqual(clipping.format, .raw)
        XCTAssertEqual(clipping.exportType, .jpeg)
        XCTAssertNil(clipping.crop)
    }
}
