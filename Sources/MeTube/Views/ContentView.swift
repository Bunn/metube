import Combine
import SwiftUI

struct ContentView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var browser = BrowserController()
    @State private var addressInput = ""
    @FocusState private var isAddressFocused: Bool

    var body: some View {
        ZStack(alignment: .top) {
            BrowserView(browser: browser)

            if !browser.hasLoadedContent {
                WelcomeView(
                    protectionSummary: browser.protectionSummary,
                    browse: browser.browseYouTube,
                    focusAddress: browser.requestAddressFocus
                )
            }

            if browser.isLoading {
                ProgressView(value: browser.progress)
                    .progressViewStyle(.linear)
                    .frame(maxWidth: .infinity)
            }

            if let statusMessage = browser.statusMessage {
                StatusBanner(message: statusMessage)
                    .padding(.top, 12)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(minWidth: 720, minHeight: 480)
        .navigationTitle(browser.title)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button("Back", systemImage: "chevron.left", action: browser.goBack)
                    .labelStyle(.iconOnly)
                    .disabled(!browser.canGoBack)
                    .help("Back (⌘[)")

                Button("Forward", systemImage: "chevron.right", action: browser.goForward)
                    .labelStyle(.iconOnly)
                    .disabled(!browser.canGoForward)
                    .help("Forward (⌘])")

                Button(
                    browser.isLoading ? "Stop" : "Reload",
                    systemImage: browser.isLoading ? "xmark" : "arrow.clockwise",
                    action: browser.stopOrReload
                )
                .labelStyle(.iconOnly)
                .help(browser.isLoading ? "Stop" : "Reload (⌘R)")

                Button("YouTube Home", systemImage: "house", action: browser.browseYouTube)
                    .labelStyle(.iconOnly)
                    .help("YouTube Home (⇧⌘H)")
            }

            ToolbarItem(placement: .principal) {
                TextField("YouTube URL, video ID, or search", text: $addressInput)
                    .textFieldStyle(.roundedBorder)
                    .focused($isAddressFocused)
                    .onSubmit(submitAddress)
                    .frame(minWidth: 300, idealWidth: 540, maxWidth: 720)
            }

            ToolbarItemGroup(placement: .primaryAction) {
                Button(
                    "Move Video to Menu Bar",
                    systemImage: "menubar.rectangle",
                    action: browser.moveVideoToMenuBar
                )
                .labelStyle(.iconOnly)
                .disabled(!browser.canMoveVideoToMenuBar || browser.isVideoInMenuBar)
                .help("Move the playing video to the menu bar (⌥⌘M)")

                Image(systemName: "shield.checkered")
                    .foregroundStyle(.green)
                    .help(browser.protectionSummary)
                    .accessibilityLabel(browser.protectionSummary)
            }
        }
        .focusedSceneValue(\.browserController, browser)
        .onReceive(browser.$addressText) { address in
            guard !isAddressFocused else { return }
            addressInput = address
        }
        .onReceive(browser.$addressFocusRequest.dropFirst()) { _ in
            addressInput = browser.addressText
            DispatchQueue.main.async {
                isAddressFocused = true
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: browser.statusMessage)
    }

    private func submitAddress() {
        browser.navigate(addressInput)
        isAddressFocused = false
    }
}
