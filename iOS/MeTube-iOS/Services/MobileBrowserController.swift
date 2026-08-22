import Combine
import Foundation
import OSLog
import UIKit
import WebKit

@MainActor
final class MobileBrowserController: NSObject, ObservableObject {
    private static let logger = Logger(subsystem: "dev.bunn.metube", category: "MobileBrowser")

    @Published private(set) var title = "MeTube"
    @Published private(set) var addressText = ""
    @Published private(set) var canGoBack = false
    @Published private(set) var canGoForward = false
    @Published private(set) var isLoading = false
    @Published private(set) var hasLoadedContent = false
    @Published private(set) var progress = 0.0
    @Published private(set) var protectionSummary = "Preparing protection…"
    @Published private(set) var statusMessage: String?
    @Published private(set) var addressFocusRequest = 0

    let webView: WKWebView

    private let userContentController: WKUserContentController
    private var observations = [NSKeyValueObservation]()
    private var activeVideoID: String?
    private var playbackExperience = PlaybackExperience.current()

    private static let youtubeHomeURL: URL = {
        guard let url = URL(string: "https://m.youtube.com") else {
            preconditionFailure("The YouTube home URL literal must be valid")
        }
        return url
    }()

    override init() {
        let userContentController = WKUserContentController()
        AdBlocker.installUserScripts(on: userContentController)

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        configuration.websiteDataStore = .default()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.preferences.isElementFullscreenEnabled = true
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = true
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        self.userContentController = userContentController
        self.webView = WKWebView(frame: .zero, configuration: configuration)
        super.init()

        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true
        webView.scrollView.keyboardDismissMode = .onDrag
        webView.underPageBackgroundColor = .black

        #if DEBUG
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        #endif

        installObservations()
        prepareProtection()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDefaultsDidChange(_:)),
            name: UserDefaults.didChangeNotification,
            object: UserDefaults.standard
        )
    }

    deinit {
        observations.forEach { $0.invalidate() }
        NotificationCenter.default.removeObserver(
            self,
            name: UserDefaults.didChangeNotification,
            object: UserDefaults.standard
        )
    }

    func navigate(_ input: String) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        statusMessage = nil

        if let video = YouTubeURLParser.video(fromUserInput: trimmed) {
            openVideo(video)
            return
        }

        if let url = YouTubeURLParser.normalizedURL(from: trimmed),
           ["http", "https"].contains(url.scheme?.lowercased()) {
            loadBrowsePage(url)
            return
        }

        loadBrowsePage(YouTubeURLParser.searchURL(for: trimmed))
    }

    func browseYouTube() {
        loadBrowsePage(Self.youtubeHomeURL)
    }

    func goBack() {
        guard webView.canGoBack else { return }

        if activeVideoID != nil,
           let destination = webView.backForwardList.backList.reversed().first(where: {
               YouTubeURLParser.video(from: $0.url) == nil
           }) {
            activeVideoID = nil
            webView.go(to: destination)
        } else {
            activeVideoID = nil
            webView.goBack()
        }
    }

    func goForward() {
        guard webView.canGoForward else { return }
        webView.goForward()
    }

    func reload() {
        statusMessage = nil
        if let activeVideoID {
            loadPlayer(YouTubeVideo(id: activeVideoID, startSeconds: nil))
        } else {
            webView.reload()
        }
    }

    func stopOrReload() {
        if isLoading {
            webView.stopLoading()
        } else {
            reload()
        }
    }

    func requestAddressFocus() {
        addressFocusRequest &+= 1
    }

    private func prepareProtection() {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await AdBlocker.installContentRules(on: userContentController)
                protectionSummary = "Protection active"
                Self.logger.info("Compiled content protection is active")
            } catch {
                protectionSummary = "Script protection active"
                statusMessage = "Compiled network rules could not load; response filtering is still active."
                Self.logger.error("Content rule installation failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func openVideo(_ video: YouTubeVideo) {
        switch playbackExperience {
        case .optimizedPlayer:
            loadPlayer(video)
        case .fullYouTubePage:
            loadBrowsePage(video.canonicalURL)
        }
    }

    private func loadBrowsePage(_ url: URL) {
        activeVideoID = nil
        hasLoadedContent = true
        addressText = url.absoluteString
        webView.load(URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30))
    }

    private func loadPlayer(_ video: YouTubeVideo) {
        activeVideoID = video.id
        hasLoadedContent = true
        addressText = video.canonicalURL.absoluteString
        title = "MeTube Player"

        var request = URLRequest(url: video.embedURL)
        request.setValue("http://localhost/", forHTTPHeaderField: "Referer")
        webView.loadSimulatedRequest(request, responseHTML: PlayerPage.html(for: video))
    }

    private func installObservations() {
        observations.append(webView.observe(\.estimatedProgress, options: [.initial, .new]) { [weak self] webView, _ in
            Task { @MainActor in
                self?.progress = webView.estimatedProgress
            }
        })

        observations.append(webView.observe(\.isLoading, options: [.initial, .new]) { [weak self] webView, _ in
            Task { @MainActor in
                self?.isLoading = webView.isLoading
            }
        })

        observations.append(webView.observe(\.canGoBack, options: [.initial, .new]) { [weak self] webView, _ in
            Task { @MainActor in
                self?.canGoBack = webView.canGoBack
            }
        })

        observations.append(webView.observe(\.canGoForward, options: [.initial, .new]) { [weak self] webView, _ in
            Task { @MainActor in
                self?.canGoForward = webView.canGoForward
            }
        })

        observations.append(webView.observe(\.title, options: [.new]) { [weak self] webView, _ in
            Task { @MainActor in
                guard self?.activeVideoID == nil else { return }
                if let pageTitle = webView.title, !pageTitle.isEmpty {
                    self?.title = pageTitle
                } else {
                    self?.title = "MeTube"
                }
            }
        })

        observations.append(webView.observe(\.url, options: [.new]) { [weak self] webView, _ in
            Task { @MainActor in
                self?.handleObservedURL(webView.url)
            }
        })
    }

    private func handleObservedURL(_ url: URL?) {
        guard let url else { return }
        if let video = YouTubeURLParser.video(from: url) {
            if playbackExperience == .fullYouTubePage {
                activeVideoID = nil
                hasLoadedContent = true
                addressText = video.canonicalURL.absoluteString
                return
            }

            if activeVideoID == video.id,
               url.host?.lowercased().contains("youtube-nocookie.com") == true {
                addressText = video.canonicalURL.absoluteString
                return
            }

            openVideo(video)
        } else {
            activeVideoID = nil
            addressText = url.absoluteString
        }
    }

    @objc private func userDefaultsDidChange(_ notification: Notification) {
        let updatedExperience = PlaybackExperience.current()
        guard updatedExperience != playbackExperience else { return }

        playbackExperience = updatedExperience
        guard let video = currentVideo else { return }
        openVideo(video)
    }

    private var currentVideo: YouTubeVideo? {
        if let activeVideoID {
            return YouTubeVideo(id: activeVideoID, startSeconds: nil)
        }
        if let url = webView.url, let video = YouTubeURLParser.video(from: url) {
            return video
        }
        return YouTubeURLParser.video(fromUserInput: addressText)
    }

    private func reportNavigationError(_ error: Error) {
        let nsError = error as NSError
        guard nsError.code != NSURLErrorCancelled else { return }
        statusMessage = nsError.localizedDescription
        Self.logger.error("Navigation failed: \(nsError.localizedDescription, privacy: .public)")
    }
}

extension MobileBrowserController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        if let video = YouTubeURLParser.video(from: url) {
            if playbackExperience == .fullYouTubePage {
                decisionHandler(.allow)
                return
            }

            let isCurrentPlayerFrame = video.id == activeVideoID
                && url.host?.lowercased().contains("youtube-nocookie.com") == true

            if isCurrentPlayerFrame {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel)
                Task { @MainActor [weak self] in
                    self?.openVideo(video)
                }
            }
            return
        }

        if navigationAction.targetFrame == nil, ["http", "https"].contains(url.scheme?.lowercased()) {
            decisionHandler(.cancel)
            webView.load(URLRequest(url: url))
            return
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        statusMessage = nil
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        reportNavigationError(error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        reportNavigationError(error)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        Self.logger.error("Web content process terminated; reloading")
        statusMessage = "The web content process restarted to recover memory. Reloading…"
        reload()
    }
}

extension MobileBrowserController: WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard navigationAction.targetFrame == nil, let url = navigationAction.request.url else { return nil }
        if let video = YouTubeURLParser.video(from: url) {
            openVideo(video)
        } else {
            loadBrowsePage(url)
        }
        return nil
    }
}
