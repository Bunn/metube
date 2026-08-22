import SwiftUI

struct WindowToolbarVisibilityView: NSViewRepresentable {
    let isVisible: Bool

    func makeNSView(context: Context) -> WindowToolbarVisibilityHostView {
        WindowToolbarVisibilityHostView(isToolbarVisible: isVisible)
    }

    func updateNSView(_ nsView: WindowToolbarVisibilityHostView, context: Context) {
        nsView.setToolbarVisible(isVisible)
    }
}
