import AppKit
import SwiftUI

struct MouseActivityView: NSViewRepresentable {
    let onActivity: () -> Void

    func makeNSView(context: Context) -> MouseTrackingView {
        MouseTrackingView(onActivity: onActivity)
    }

    func updateNSView(_ nsView: MouseTrackingView, context: Context) {
        nsView.onActivity = onActivity
    }
}

final class MouseTrackingView: NSView {
    var onActivity: () -> Void

    init(onActivity: @escaping () -> Void) {
        self.onActivity = onActivity
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(
            NSTrackingArea(
                rect: bounds,
                options: [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow, .inVisibleRect],
                owner: self,
                userInfo: nil
            )
        )
    }

    override func mouseEntered(with event: NSEvent) {
        onActivity()
    }

    override func mouseMoved(with event: NSEvent) {
        onActivity()
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }
}
