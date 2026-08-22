import AppKit

/// Bridges the one toolbar capability unavailable to SwiftUI on macOS 13:
/// changing visibility while the window remains open.
final class WindowToolbarVisibilityHostView: NSView {
    private var isToolbarVisible: Bool

    init(isToolbarVisible: Bool) {
        self.isToolbarVisible = isToolbarVisible
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        applyToolbarVisibility()
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    func setToolbarVisible(_ isVisible: Bool) {
        isToolbarVisible = isVisible
        applyToolbarVisibility()
    }

    private func applyToolbarVisibility() {
        guard let toolbar = window?.toolbar, toolbar.isVisible != isToolbarVisible else { return }
        toolbar.isVisible = isToolbarVisible
    }
}
