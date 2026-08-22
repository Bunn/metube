import SwiftUI

private struct FocusedBrowserControllerKey: FocusedValueKey {
    typealias Value = BrowserController
}

extension FocusedValues {
    var browserController: BrowserController? {
        get { self[FocusedBrowserControllerKey.self] }
        set { self[FocusedBrowserControllerKey.self] = newValue }
    }
}
