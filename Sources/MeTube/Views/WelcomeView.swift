import AppKit
import SwiftUI

struct WelcomeView: View {
    let protectionSummary: String
    let browse: () -> Void
    let focusAddress: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color.accentColor.opacity(0.08),
                    Color(nsColor: .windowBackgroundColor)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 92, height: 92)
                    .shadow(color: .black.opacity(0.28), radius: 18, y: 8)
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("Watch lightly.")
                        .font(.largeTitle)
                        .bold()
                    Text("YouTube playback tuned for your Mac. Paste a video link, enter a video ID, or search from the address bar.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 470)
                }

                HStack(spacing: 10) {
                    Button("Open a Video", systemImage: "link", action: focusAddress)
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                    Button("Browse YouTube", systemImage: "safari", action: browse)
                        .buttonStyle(.bordered)
                }

                Label(protectionSummary, systemImage: "shield.checkered")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.regularMaterial, in: Capsule())
            }
            .padding(40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
