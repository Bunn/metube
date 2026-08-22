import AppKit
import SwiftUI
import WebKit

struct BrowserView: NSViewRepresentable {
    let browser: BrowserController

    func makeNSView(context: Context) -> BrowserWebViewHost {
        let host = BrowserWebViewHost()
        browser.installMainWebView(in: host)
        return host
    }

    func updateNSView(_ host: BrowserWebViewHost, context: Context) {
        browser.installMainWebView(in: host)
    }
}

/// A stable AppKit container lets the one live web view move between the main
/// window and the menu-bar popover without creating a second player or reload.
final class BrowserWebViewHost: NSView {
    func attach(_ webView: WKWebView) {
        guard webView.superview !== self else {
            webView.frame = bounds
            return
        }

        webView.removeFromSuperview()
        webView.translatesAutoresizingMaskIntoConstraints = true
        webView.autoresizingMask = [.width, .height]
        webView.frame = bounds
        addSubview(webView)
    }

    override func layout() {
        super.layout()
        subviews.first?.frame = bounds
    }
}
