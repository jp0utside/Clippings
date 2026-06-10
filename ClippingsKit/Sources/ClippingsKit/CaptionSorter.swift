import Foundation

/// A single recognized text observation, reduced to just what the ordering logic
/// needs. Kept platform-agnostic (no Vision import) so the sort is unit-testable
/// anywhere, including Linux CI.
///
/// `boundingBox` follows the **Vision convention**: normalized to 0...1 with the
/// origin at the bottom-left and the y-axis pointing up. `OCRService` passes
/// `VNRecognizedTextObservation.boundingBox` straight through.
public struct RecognizedLine: Equatable, Sendable {
    public var text: String
    public var boundingBox: CGRect

    public init(text: String, boundingBox: CGRect) {
        self.text = text
        self.boundingBox = boundingBox
    }
}

/// Turns Vision's layout-ordered observations into a single caption string in
/// human reading order (top-to-bottom, left-to-right within a line).
///
/// Vision returns observations in layout order, which does not reliably match
/// reading order on a screenshot full of interleaved UI (username, caption,
/// comments, timestamps). v1 applies a vertical-position sort; smarter
/// chrome-stripping heuristics are a v2 refinement (System Design §3.2).
public enum CaptionSorter {

    /// Two observations are treated as the same visual line when their vertical
    /// extents overlap by at least this fraction of the shorter box. This is the
    /// "line band" threshold left unspecified by the design; 0.5 keeps genuinely
    /// stacked lines apart while tolerating the small baseline jitter Vision
    /// produces across words on one line.
    public static let sameLineOverlapThreshold: CGFloat = 0.5

    /// The ordered caption, with words on a line joined by spaces and separate
    /// lines joined by newlines. Returns an empty string for no input.
    public static func caption(from lines: [RecognizedLine]) -> String {
        bands(from: lines)
            .map { band in band.map(\.text).joined(separator: " ") }
            .joined(separator: "\n")
    }

    /// Group observations into visual lines, ordered top-to-bottom, with each
    /// band's members ordered left-to-right. Exposed for testing.
    public static func bands(from lines: [RecognizedLine]) -> [[RecognizedLine]] {
        // Vision is y-up, so a larger midY sits higher on screen.
        let topToBottom = lines.sorted { $0.boundingBox.midY > $1.boundingBox.midY }

        var bands: [[RecognizedLine]] = []
        for line in topToBottom {
            if let lastIndex = bands.indices.last,
               let reference = bands[lastIndex].last,
               sameLine(line.boundingBox, reference.boundingBox) {
                bands[lastIndex].append(line)
            } else {
                bands.append([line])
            }
        }

        return bands.map { band in
            band.sorted { $0.boundingBox.minX < $1.boundingBox.minX }
        }
    }

    private static func sameLine(_ a: CGRect, _ b: CGRect) -> Bool {
        let overlap = min(a.maxY, b.maxY) - max(a.minY, b.minY)
        guard overlap > 0 else { return false }
        let shorter = min(a.height, b.height)
        guard shorter > 0 else { return false }
        return overlap / shorter >= sameLineOverlapThreshold
    }
}
