import XCTest
@testable import ClippingsKit

final class PreferencesTests: XCTestCase {

    /// Use a unique, in-process suite per test so we never touch real defaults.
    private func makePreferences() -> (Preferences, String) {
        let suite = "test.clippings.\(UUID().uuidString)"
        return (Preferences(suiteName: suite), suite)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testDefaultsWhenUnset() {
        let (prefs, suite) = makePreferences()
        defer { UserDefaults().removePersistentDomain(forName: suite) }
        XCTAssertEqual(prefs.defaultFormat, .rememberLast)
        XCTAssertEqual(prefs.defaultExportType, .jpeg)
        XCTAssertEqual(prefs.lastUsedFormat, .raw)
    }

    func testResolvedStartingFormatRespectsExplicitPreference() {
        let (prefs, suite) = makePreferences()
        defer { UserDefaults().removePersistentDomain(forName: suite) }
        prefs.defaultFormat = .split
        XCTAssertEqual(prefs.resolvedStartingFormat(), .split)
    }

    func testResolvedStartingFormatFollowsLastUsedWhenRemembering() {
        let (prefs, suite) = makePreferences()
        defer { UserDefaults().removePersistentDomain(forName: suite) }
        prefs.defaultFormat = .rememberLast
        prefs.lastUsedFormat = .split
        XCTAssertEqual(prefs.resolvedStartingFormat(), .split)
    }

    func testPreferencesPersistAcrossInstancesInSameSuite() {
        let suite = "test.clippings.\(UUID().uuidString)"
        defer { UserDefaults().removePersistentDomain(forName: suite) }
        do {
            let prefs = Preferences(suiteName: suite)
            prefs.defaultExportType = .png
            prefs.lastUsedFormat = .split
        }
        let reloaded = Preferences(suiteName: suite)
        XCTAssertEqual(reloaded.defaultExportType, .png)
        XCTAssertEqual(reloaded.lastUsedFormat, .split)
    }
}
