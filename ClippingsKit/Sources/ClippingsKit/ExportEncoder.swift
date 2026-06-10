// Apple-only: full-resolution encode with metadata stripped. Implements the
// export path of System Design §6 — decode once at full resolution, apply the
// normalized crop, encode to the chosen type, supplying no metadata so EXIF/GPS
// never travels with the share.
//
// Phase 2 component. Structurally complete but UNTESTED.

#if canImport(ImageIO) && canImport(CoreGraphics)
import ImageIO
import CoreGraphics
import Foundation
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

public enum ExportError: Error {
    case decodeFailed
    case encodeFailed
}

public struct ExportEncoder {

    /// Fixed v1 JPEG quality (no user-facing slider until v2).
    public static let jpegQuality: CGFloat = 0.9

    /// Safety valve: cap the longest edge so a pathological oversized input is
    /// downsized rather than crashing the extension (System Design §6). Screenshots
    /// never hit this; only absurd shared images would.
    public static let maxLongestEdge = 8192

    public init() {}

    /// Encode a clipping to its chosen output type, applying any crop at full
    /// resolution. Returns the encoded bytes ready for the Share sheet.
    public func encode(_ clipping: Clipping) throws -> Data {
        guard var image = ImageDecoding.fullResolutionImage(from: clipping.sourceImageData) else {
            throw ExportError.decodeFailed
        }

        if let crop = clipping.crop {
            let size = CGSize(width: image.width, height: image.height)
            let rect = CropMath.pixelRect(forNormalizedCrop: crop, imagePixelSize: size)
            if !rect.isEmpty, let cropped = image.cropping(to: rect) {
                image = cropped
            }
        }

        // NOTE (Phase 2): apply the maxLongestEdge safety valve here for
        // pathological inputs before encoding.

        return try encode(image: image, as: clipping.exportType)
    }

    private func encode(image: CGImage, as type: ExportType) throws -> Data {
        let identifier = utTypeIdentifier(for: type)
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data, identifier, 1, nil
        ) else {
            throw ExportError.encodeFailed
        }

        // Supplying no properties dictionary beyond compression means no source
        // metadata (EXIF/GPS/device) is carried into the output.
        var properties: [CFString: Any] = [:]
        if type == .jpeg {
            properties[kCGImageDestinationLossyCompressionQuality] = Self.jpegQuality
        }

        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw ExportError.encodeFailed
        }
        return data as Data
    }

    private func utTypeIdentifier(for type: ExportType) -> CFString {
        #if canImport(UniformTypeIdentifiers)
        switch type {
        case .jpeg: return UTType.jpeg.identifier as CFString
        case .png: return UTType.png.identifier as CFString
        }
        #else
        switch type {
        case .jpeg: return "public.jpeg" as CFString
        case .png: return "public.png" as CFString
        }
        #endif
    }
}
#endif
