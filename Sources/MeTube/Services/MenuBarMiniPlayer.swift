import AppKit
import WebKit

@MainActor
final class MenuBarMiniPlayer: NSObject {
    private weak var browser: BrowserController?
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let playerViewController: MenuBarPlayerViewController
    private var isInvalidated = false

    init(browser: BrowserController, webView: WKWebView) {
        self.browser = browser
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.popover = NSPopover()
        self.playerViewController = MenuBarPlayerViewController()
        super.init()

        playerViewController.onReturnToWindow = { [weak browser] in
            browser?.restoreVideoFromMenuBar()
        }
        playerViewController.attach(webView)

        popover.animates = false
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 520, height: 338)
        popover.contentViewController = playerViewController

        if let button = statusItem.button {
            let image = NSImage(
                systemSymbolName: "play.rectangle.fill",
                accessibilityDescription: "MeTube mini player"
            )
            image?.isTemplate = true
            button.image = image
            button.imagePosition = .imageOnly
            button.target = self
            button.action = #selector(togglePopover(_:))
            button.toolTip = "MeTube Mini Player"
            button.setAccessibilityLabel("MeTube mini player")
            button.setAccessibilityHelp("Opens the video player")
        }
    }

    func closePopover() {
        popover.performClose(nil)
    }

    func invalidate() {
        guard !isInvalidated else { return }
        isInvalidated = true
        closePopover()
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}

@MainActor
private final class MenuBarPlayerViewController: NSViewController {
    var onReturnToWindow: (() -> Void)?

    private let videoContainer = NSView()

    override func loadView() {
        let rootView = NSView()
        rootView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = NSTextField(labelWithString: "MeTube Mini Player")
        titleLabel.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
        titleLabel.lineBreakMode = .byTruncatingTail

        let returnButton = NSButton(
            title: "Return to Window",
            target: self,
            action: #selector(returnToWindow(_:))
        )
        returnButton.bezelStyle = .rounded
        returnButton.image = NSImage(
            systemSymbolName: "macwindow",
            accessibilityDescription: "Return to window"
        )
        returnButton.imagePosition = .imageLeading
        returnButton.keyEquivalent = "\r"

        let header = NSStackView(views: [titleLabel, returnButton])
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 12
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        returnButton.setContentHuggingPriority(.required, for: .horizontal)

        videoContainer.wantsLayer = true
        videoContainer.layer?.backgroundColor = NSColor.black.cgColor

        header.translatesAutoresizingMaskIntoConstraints = false
        videoContainer.translatesAutoresizingMaskIntoConstraints = false
        rootView.addSubview(header)
        rootView.addSubview(videoContainer)

        NSLayoutConstraint.activate([
            rootView.widthAnchor.constraint(equalToConstant: 520),
            rootView.heightAnchor.constraint(equalToConstant: 338),

            header.topAnchor.constraint(equalTo: rootView.topAnchor, constant: 8),
            header.leadingAnchor.constraint(equalTo: rootView.leadingAnchor, constant: 12),
            header.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: -12),
            header.heightAnchor.constraint(equalToConstant: 30),

            videoContainer.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 8),
            videoContainer.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
            videoContainer.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
            videoContainer.bottomAnchor.constraint(equalTo: rootView.bottomAnchor)
        ])

        view = rootView
    }

    func attach(_ webView: WKWebView) {
        _ = view
        webView.removeFromSuperview()
        webView.translatesAutoresizingMaskIntoConstraints = true
        webView.autoresizingMask = [.width, .height]
        webView.frame = videoContainer.bounds
        videoContainer.addSubview(webView)
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        videoContainer.subviews.first?.frame = videoContainer.bounds
    }

    @objc private func returnToWindow(_ sender: Any?) {
        onReturnToWindow?()
    }
}
