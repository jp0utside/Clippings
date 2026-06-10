import Foundation

/// The output format the user chooses for a clipping.
public enum ClippingFormat: String, Codable, CaseIterable, Sendable {
    /// Pass the screenshot through unchanged (one image item on export).
    case raw
    /// Image preserved plus the extracted caption (two items on export).
    case split
}

/// The encoded image type produced on export. A quality/compression slider is a
/// v2 concern — v1 ships a fixed sensible JPEG quality and lossless PNG.
public enum ExportType: String, Codable, CaseIterable, Sendable {
    case jpeg
    case png

    /// File extension for the encoded output.
    public var fileExtension: String { rawValue }
}

/// The in-memory working item for a single screenshot being formatted.
///
/// Nothing here is persisted; the value lives only for the duration of a single
/// format-and-share interaction. `sourceImageData` holds the original encoded
/// bytes exactly as received from the share context — the full-resolution decode
/// and crop happen lazily at export time (see System Design §6).
public struct Clipping: Equatable, Sendable {
    /// The original screenshot bytes, as received from the share context.
    public var sourceImageData: Data
    /// Caption recovered by OCR, top-to-bottom ordered, user-editable.
    /// `nil` until OCR completes; an empty/whitespace value means "no caption
    /// detected" and disables the Split format.
    public var extractedText: String?
    /// Chosen output format.
    public var format: ClippingFormat
    /// Optional crop, expressed in normalized (0...1) source-image coordinates so
    /// it is independent of the preview's display scale. Applied at full
    /// resolution on export. `nil` means "no crop".
    public var crop: CGRect?
    /// Encoded output type.
    public var exportType: ExportType

    public init(
        sourceImageData: Data,
        extractedText: String? = nil,
        format: ClippingFormat = .raw,
        crop: CGRect? = nil,
        exportType: ExportType = .jpeg
    ) {
        self.sourceImageData = sourceImageData
        self.extractedText = extractedText
        self.format = format
        self.crop = crop
        self.exportType = exportType
    }

    /// Whether a usable caption was detected. Split is only offered when true.
    public var hasCaption: Bool {
        guard let text = extractedText else { return false }
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
