// Apple-only: bridges the platform-agnostic ExportPayload to the array of items
// UIActivityViewController expects. Image first, caption text second (System
// Design §2).
//
// Phase 2 component. UNTESTED — in-extension share-sheet behavior is exactly what
// roadmap Spike A must validate on-device before the UI is built on top of it.

#if canImport(UIKit)
import UIKit

public enum ActivityItems {

    /// Build the activity items for the system Share sheet from an export payload.
    /// Returns an image item, optionally followed by the caption text item.
    public static func items(from payload: ExportPayload) -> [Any] {
        var items: [Any] = []
        if let image = UIImage(data: payload.imageData) {
            items.append(image)
        } else {
            // Fall back to raw data so the share still carries the image even if
            // UIImage decoding fails for an exotic format.
            items.append(payload.imageData)
        }
        if let caption = payload.caption {
            items.append(caption)
        }
        return items
    }
}
#endif
