// Apple-only: Vision text recognition. Compiles where Vision is available
// (iOS); drops out of the build elsewhere so the pure logic stays cross-platform.
//
// Phase 2 component (development_roadmap.md). Structurally complete but UNTESTED —
// must be run against the OCR fixture suite on a Mac/device before being trusted.

#if canImport(Vision)
import Vision
import CoreGraphics
import Foundation

public enum OCRError: Error {
    case requestFailed(Error)
}

/// Recovers a screenshot's caption via on-device Vision OCR, returning it in
/// reading order (System Design §3.2). No network, no model bundling.
public struct OCRService {

    public init() {}

    /// Recognize text in an image and return the ordered caption.
    /// - Returns: the joined caption, or `nil` when no text is detected (which the
    ///   UI surfaces as the "no caption" state that disables Split).
    public func recognizeCaption(in cgImage: CGImage) throws -> String? {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            throw OCRError.requestFailed(error)
        }

        let lines: [RecognizedLine] = (request.results ?? []).compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            // VNRecognizedTextObservation.boundingBox is already normalized in
            // Vision's bottom-left convention — exactly what RecognizedLine expects.
            return RecognizedLine(text: candidate.string, boundingBox: observation.boundingBox)
        }

        guard !lines.isEmpty else { return nil }
        return CaptionSorter.caption(from: lines)
    }
}
#endif
