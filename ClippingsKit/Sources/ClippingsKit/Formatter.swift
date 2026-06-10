import Foundation

/// What gets handed to the system Share sheet. `caption` is present only for the
/// Split format and becomes a second activity item (System Design §2): Raw exports
/// one image item; Split exports two — image first, then caption text.
public struct ExportPayload: Equatable, Sendable {
    public var imageData: Data
    public var caption: String?

    public init(imageData: Data, caption: String? = nil) {
        self.imageData = imageData
        self.caption = caption
    }

    /// Number of activity items this payload yields (1 for Raw, 2 for Split).
    public var itemCount: Int { caption == nil ? 1 : 2 }
}

/// Composes the share payload from a clipping. Pure and platform-agnostic: it
/// decides *what* to share given already-encoded image bytes; the Apple-only
/// `ExportEncoder` decides *how* the image is encoded.
public enum Formatter {

    /// Build the export payload for a clipping whose image has already been
    /// encoded by `ExportEncoder`.
    ///
    /// - Raw: image only.
    /// - Split: image plus the trimmed caption. If the caption is empty after
    ///   trimming, it is dropped and the payload degrades to a single image item
    ///   rather than sharing an empty string.
    public static func payload(imageData: Data, for clipping: Clipping) -> ExportPayload {
        switch clipping.format {
        case .raw:
            return ExportPayload(imageData: imageData, caption: nil)
        case .split:
            let trimmed = clipping.extractedText?.trimmingCharacters(in: .whitespacesAndNewlines)
            let caption = (trimmed?.isEmpty == false) ? trimmed : nil
            return ExportPayload(imageData: imageData, caption: caption)
        }
    }
}
