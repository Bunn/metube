import Combine
import SwiftUI

struct MobileContentView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var browser = MobileBrowserController()
    @State private var addressInput = ""
    @State private var presentedSheet: MobileSheetDestination?
    @FocusState private var isAddressFocused: Bool

    var body: some View {
        ZStack(alignment: .top) {
            MobileBrowserView(browser: browser)

            if !browser.hasLoadedContent {
                MobileWelcomeView(
                    protectionSummary: browser.protectionSummary,
                    browse: browser.browseYouTube,
                    focusAddress: browser.requestAddressFocus
                )
            }

            if browser.isLoading {
                ProgressView(value: browser.progress)
                    .progressViewStyle(.linear)
                    .tint(.accentColor)
            }

            if let statusMessage = browser.statusMessage {
                MobileStatusBanner(message: statusMessage)
                    .padding(.top)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MobileBrowserToolbar(
                browser: browser,
                addressInput: $addressInput,
                addressFocus: $isAddressFocused,
                submitAddress: submitAddress,
                openSettings: { presentedSheet = .settings }
            )
        }
        .sheet(item: $presentedSheet) { destination in
            switch destination {
            case .settings:
                MobileSettingsView()
            }
        }
        .onOpenURL { url in
            browser.navigate(url.absoluteString)
        }
        .onReceive(browser.$addressText) { address in
            guard !isAddressFocused else { return }
            addressInput = address
        }
        .onReceive(browser.$addressFocusRequest.dropFirst()) { _ in
            addressInput = browser.addressText
            isAddressFocused = true
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: browser.statusMessage)
    }

    private func submitAddress() {
        browser.navigate(addressInput)
        isAddressFocused = false
    }
}
