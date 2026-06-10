import XCTest
@testable import ClippingsKit

/// Vision uses a bottom-left origin (y up), so these fixtures place higher
/// `boundingBox` y-values toward the top of the screenshot.
final class CaptionSorterTests: XCTestCase {

    private func line(_ text: String, x: CGFloat, y: CGFloat, w: CGFloat = 0.3, h: CGFloat = 0.04) -> RecognizedLine {
        RecognizedLine(text: text, boundingBox: CGRect(x: x, y: y, width: w, height: h))
    }

    func testEmptyInputProducesEmptyCaption() {
        XCTAssertEqual(CaptionSorter.caption(from: []), "")
    }

    func testOrdersTopToBottomRegardlessOfInputOrder() {
        // Provided out of order; expect reading order top -> bottom.
        let lines = [
            line("bottom", x: 0.1, y: 0.20),
            line("top", x: 0.1, y: 0.80),
            line("middle", x: 0.1, y: 0.50)
        ]
        XCTAssertEqual(CaptionSorter.caption(from: lines), "top\nmiddle\nbottom")
    }

    func testWordsOnSameLineOrderLeftToRightJoinedBySpace() {
        // Same vertical band (overlapping y), provided right-to-left.
        let lines = [
            line("world", x: 0.55, y: 0.50),
            line("hello", x: 0.10, y: 0.505)
        ]
        XCTAssertEqual(CaptionSorter.caption(from: lines), "hello world")
    }

    func testSeparateLinesAreNotMergedIntoOneBand() {
        let lines = [
            line("first line", x: 0.1, y: 0.80),
            line("second line", x: 0.1, y: 0.60)
        ]
        let bands = CaptionSorter.bands(from: lines)
        XCTAssertEqual(bands.count, 2)
        XCTAssertEqual(CaptionSorter.caption(from: lines), "first line\nsecond line")
    }

    func testOverlappingWordsCountAsSameLine() {
        // Two boxes whose vertical overlap exceeds the threshold should merge.
        let a = line("a", x: 0.1, y: 0.500, h: 0.04)
        let b = line("b", x: 0.4, y: 0.515, h: 0.04) // overlaps a by > 50% of height
        XCTAssertEqual(CaptionSorter.bands(from: [a, b]).count, 1)
    }
}
