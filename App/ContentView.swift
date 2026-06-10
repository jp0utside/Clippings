import SwiftUI
import ClippingsKit

/// Placeholder home screen for the Phase 0 skeleton. Confirms the container app
/// links ClippingsKit and launches. The PHPicker import, onboarding, and
/// formatting flow are built in Phase 3.
struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "scissors")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)
                Text("Clippings")
                    .font(.largeTitle.bold())
                Text("Turn a social screenshot into something clean to send to the people who aren't on the app.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Text("Full flow arrives in Phase 3.")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 8)
            }
            .padding()
            .navigationTitle("Clippings")
        }
    }
}

#Preview {
    ContentView()
}
