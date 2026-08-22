import SwiftUI

struct MobileBrowserToolbar: View {
    @ObservedObject var browser: MobileBrowserController
    @Binding var addressInput: String
    let addressFocus: FocusState<Bool>.Binding
    let submitAddress: () -> Void
    let openSettings: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "shield.checkered")
                    .foregroundStyle(.green)
                    .accessibilityLabel(browser.protectionSummary)

                TextField("YouTube URL, video ID, or search", text: $addressInput)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .submitLabel(.go)
                    .focused(addressFocus)
                    .onSubmit(submitAddress)

                Button("Go", systemImage: "arrow.right.circle.fill", action: submitAddress)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .foregroundStyle(.tint)
                    .accessibilityIdentifier("browser.go")
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .background(Color(uiColor: .secondarySystemBackground), in: Capsule())

            HStack {
                Button("Back", systemImage: "chevron.left", action: browser.goBack)
                    .disabled(!browser.canGoBack)
                    .accessibilityIdentifier("browser.back")

                Spacer()

                Button("Forward", systemImage: "chevron.right", action: browser.goForward)
                    .disabled(!browser.canGoForward)
                    .accessibilityIdentifier("browser.forward")

                Spacer()

                Button("YouTube Home", systemImage: "house", action: browser.browseYouTube)
                    .accessibilityIdentifier("browser.home")

                Spacer()

                Button(
                    browser.isLoading ? "Stop" : "Reload",
                    systemImage: browser.isLoading ? "xmark" : "arrow.clockwise",
                    action: browser.stopOrReload
                )
                .accessibilityIdentifier("browser.reload")

                Spacer()

                Button("Settings", systemImage: "gearshape", action: openSettings)
                    .accessibilityIdentifier("browser.settings")
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.plain)
            .frame(minHeight: 44)
            .padding(.horizontal, 18)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .background(.bar)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}
