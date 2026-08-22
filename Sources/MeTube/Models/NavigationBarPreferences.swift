import Foundation

enum NavigationBarPreferences {
    static let autoHideKey = "automaticallyHideNavigationBar"
    static let autoHideDelayKey = "navigationBarAutoHideDelay"

    static let defaultAutoHide = true
    static let defaultAutoHideDelay = 3.0
    static let supportedAutoHideDelays = [2.0, 3.0, 5.0]

    static func autoHideDelay(in defaults: UserDefaults = .standard) -> TimeInterval {
        let storedDelay = defaults.double(forKey: autoHideDelayKey)
        return supportedAutoHideDelays.contains(storedDelay)
            ? storedDelay
            : defaultAutoHideDelay
    }
}
