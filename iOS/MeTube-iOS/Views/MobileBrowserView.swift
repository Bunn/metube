import SwiftUI
import WebKit

struct MobileBrowserView: UIViewRepresentable {
    let browser: MobileBrowserController

    func makeUIView(context: Context) -> WKWebView {
        browser.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
