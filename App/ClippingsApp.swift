import SwiftUI

/// Container app entry point. The standalone Home Screen app hosts the full flow
/// (PHPicker import → Raw/Split + crop + export), onboarding, and settings
/// (System Design §1). Reviewers open this first, so it must demonstrate the
/// product on its own.
///
/// Phase 0 skeleton: a placeholder home screen. The full flow is built in Phase 3.
@main
struct ClippingsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
