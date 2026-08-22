import AppKit
import WebKit

@MainActor
final class MenuBarMiniPlayer: NSObject, NSWindowDelegate {
    private static let playerSize = NSSize(width: 520, height: 338)
    private static let panelFrameName = "MeTubeFloatingMiniPlayer"

    private weak var browser: BrowserController?
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let playerViewController: MenuBarPlayerViewController
    private var floatingPanel: NSPanel?
    private var isDetached = false
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
        playerViewController.onToggleDetached = { [weak self] in
            self?.toggleDetachedState()
        }
        playerViewController.attach(webView)

        popover.animates = false
        popover.behavior = .transient
        popover.contentViewController = playerViewController
        popover.contentSize = Self.playerSize

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
        floatingPanel?.orderOut(nil)
    }

    func invalidate() {
        guard !isInvalidated else { return }
        isInvalidated = true
        closePopover()
        floatingPanel?.delegate = nil
        floatingPanel?.contentViewController = nil
        floatingPanel = nil
        popover.contentViewController = nil
        NSStatusBar.system.removeStatusItem(statusItem)
    }

    @objc private func togglePopover(_ sender: Any?) {
        if isDetached {
            floatingPanel?.makeKeyAndOrderFront(sender)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            showPopover(relativeTo: button)
        }
    }

    private func toggleDetachedState() {
        isDetached ? attachToMenuBar() : detachIntoFloatingPanel()
    }

    private func detachIntoFloatingPanel() {
        guard !isDetached else { return }

        popover.performClose(nil)
        popover.contentViewController = nil

        let panel = floatingPanel ?? makeFloatingPanel()
        floatingPanel = panel
        panel.contentViewController = playerViewController
        playerViewController.setDetached(true)
        isDetached = true

        restoreOrPosition(panel)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func attachToMenuBar() {
        guard isDetached else { return }

        isDetached = false
        floatingPanel?.orderOut(nil)
        floatingPanel?.contentViewController = nil
        popover.contentViewController = playerViewController
        popover.contentSize = Self.playerSize
        playerViewController.setDetached(false)

        guard let button = statusItem.button else { return }
        showPopover(relativeTo: button)
    }

    private func showPopover(relativeTo button: NSStatusBarButton) {
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    private func makeFloatingPanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: Self.playerSize),
            styleMask: [.titled, .closable, .resizable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "MeTube Mini Player"
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.minSize = NSSize(width: 360, height: 250)
        panel.delegate = self
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        return panel
    }

    private func restoreOrPosition(_ panel: NSPanel) {
        let restoredSavedFrame = panel.setFrameUsingName(Self.panelFrameName)
        panel.setFrameAutosaveName(Self.panelFrameName)
        if restoredSavedFrame {
            return
        }

        panel.setContentSize(Self.playerSize)
        guard let visibleFrame = (browser?.webView.window?.screen ?? NSScreen.main)?.visibleFrame else {
            panel.center()
            return
        }

        let frame = panel.frame
        let origin = NSPoint(
            x: visibleFrame.maxX - frame.width - 24,
            y: visibleFrame.maxY - frame.height - 24
        )
        panel.setFrameOrigin(origin)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard sender === floatingPanel, !isInvalidated else { return true }
        attachToMenuBar()
        return false
    }
}

@MainActor
private final class MenuBarPlayerViewController: NSViewController {
    var onReturnToWindow: (() -> Void)?
    var onToggleDetached: (() -> Void)?

    private let videoContainer = NSView()
    private weak var detachButton: NSButton?

    override func loadView() {
        let rootView = NSView(frame: NSRect(origin: .zero, size: NSSize(width: 520, height: 338)))

        let titleLabel = NSTextField(labelWithString: "MeTube Mini Player")
        titleLabel.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
        titleLabel.lineBreakMode = .byTruncatingTail

        let returnButton = NSButton(
            title: "Main Window",
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

        let detachButton = NSButton(
            title: "Detach",
            target: self,
            action: #selector(toggleDetached(_:))
        )
        detachButton.bezelStyle = .rounded
        detachButton.image = NSImage(
            systemSymbolName: "pip.enter",
            accessibilityDescription: "Detach mini player"
        )
        detachButton.imagePosition = .imageLeading
        detachButton.toolTip = "Move the player into a floating window"
        self.detachButton = detachButton

        let header = NSStackView(views: [titleLabel, detachButton, returnButton])
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 8
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        detachButton.setContentHuggingPriority(.required, for: .horizontal)
        returnButton.setContentHuggingPriority(.required, for: .horizontal)

        videoContainer.wantsLayer = true
        videoContainer.layer?.backgroundColor = NSColor.black.cgColor

        header.translatesAutoresizingMaskIntoConstraints = false
        videoContainer.translatesAutoresizingMaskIntoConstraints = false
        rootView.addSubview(header)
        rootView.addSubview(videoContainer)

        NSLayoutConstraint.activate([
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

    func setDetached(_ isDetached: Bool) {
        detachButton?.title = isDetached ? "Attach to Menu Bar" : "Detach"
        detachButton?.image = NSImage(
            systemSymbolName: isDetached ? "pip.exit" : "pip.enter",
            accessibilityDescription: isDetached ? "Attach to menu bar" : "Detach mini player"
        )
        detachButton?.toolTip = isDetached
            ? "Put the player back in the menu-bar popover"
            : "Move the player into a floating window"
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        videoContainer.subviews.first?.frame = videoContainer.bounds
    }

    @objc private func returnToWindow(_ sender: Any?) {
        onReturnToWindow?()
    }

    @objc private func toggleDetached(_ sender: Any?) {
        onToggleDetached?()
    }
}
