import SwiftUI

struct WelcomeView: View {
    let protectionSummary: String
    let browse: () -> Void
    let focusAddress: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "play.rectangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.red)
                .accessibilityHidden(true)

            VStack(spacing: 7) {
                Text("YouTube, minus the heavy watch page")
                    .font(.title2)
                    .bold()
                Text("Paste a video link, enter an 11-character video ID, or search from the toolbar.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 10) {
                Button("Open a Video", action: focusAddress)
                    .keyboardShortcut(.defaultAction)
                Button("Browse YouTube", action: browse)
            }

            Label(protectionSummary, systemImage: "shield.checkered")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(36)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}
