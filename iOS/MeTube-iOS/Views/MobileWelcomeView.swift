import SwiftUI

struct MobileWelcomeView: View {
    let protectionSummary: String
    let browse: () -> Void
    let focusAddress: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemBackground), Color.accentColor.opacity(0.12), Color(.systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                    Image(systemName: "play.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.red)
                }
                .frame(width: 88, height: 88)
                .shadow(color: .black.opacity(0.16), radius: 16, y: 8)
                .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("Watch lightly.")
                        .font(.largeTitle)
                        .bold()
                    Text("YouTube playback tuned for your iPhone. Paste a video link, enter a video ID, or search below.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 10) {
                    Button("Open a Video", systemImage: "link", action: focusAddress)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    Button("Browse YouTube", systemImage: "safari", action: browse)
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                }

                Label(protectionSummary, systemImage: "shield.checkered")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(32)
        }
    }
}
