import Foundation

/// The user's default-format choice. "Remember last used" resolves to whatever
/// format was last exported, shared across targets via the App Group store.
public enum DefaultFormatPreference: String, Codable, CaseIterable, Sendable {
    case raw
    case split
    case rememberLast
}

/// Thin wrapper over the App Group `UserDefaults` shared by the container app and
/// the share extension (System Design §5). The v1 settings surface is exactly:
/// default format, default export type, and the remembered last-used format.
/// Metadata stripping is always-on and deliberately not a setting.
public final class Preferences {

    /// App Group identifier. **Placeholder** — must match the App Group registered
    /// in the Apple Developer portal and enabled on both targets (see README).
    public static let appGroupIdentifier = "group.com.example.clippings"

    private enum Key {
        static let defaultFormat = "defaultFormatPreference"
        static let defaultExportType = "defaultExportType"
        static let lastUsedFormat = "lastUsedFormat"
    }

    private let defaults: UserDefaults

    public init(suiteName: String = Preferences.appGroupIdentifier) {
        // Falls back to standard defaults if the suite is unavailable (e.g. the
        // App Group is misconfigured) so the app degrades rather than crashes.
        self.defaults = UserDefaults(suiteName: suiteName) ?? .standard
    }

    public var defaultFormat: DefaultFormatPreference {
        get {
            defaults.string(forKey: Key.defaultFormat)
                .flatMap(DefaultFormatPreference.init(rawValue:)) ?? .rememberLast
        }
        set { defaults.set(newValue.rawValue, forKey: Key.defaultFormat) }
    }

    public var defaultExportType: ExportType {
        get {
            defaults.string(forKey: Key.defaultExportType)
                .flatMap(ExportType.init(rawValue:)) ?? .jpeg
        }
        set { defaults.set(newValue.rawValue, forKey: Key.defaultExportType) }
    }

    /// The format last used at export. Written by whichever target performed the
    /// export so "remember last used" stays consistent across the two processes.
    public var lastUsedFormat: ClippingFormat {
        get {
            defaults.string(forKey: Key.lastUsedFormat)
                .flatMap(ClippingFormat.init(rawValue:)) ?? .raw
        }
        set { defaults.set(newValue.rawValue, forKey: Key.lastUsedFormat) }
    }

    /// The format a freshly opened clipping should start in, resolving the
    /// "remember last used" preference against the stored last-used value.
    public func resolvedStartingFormat() -> ClippingFormat {
        switch defaultFormat {
        case .raw: return .raw
        case .split: return .split
        case .rememberLast: return lastUsedFormat
        }
    }
}
