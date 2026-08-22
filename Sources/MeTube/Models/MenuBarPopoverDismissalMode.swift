import Foundation

enum MenuBarPopoverDismissalMode: String, CaseIterable, Identifiable {
    case closeWhenClickingOutside
    case menuBarButtonOnly

    static let storageKey = "menuBarPopoverDismissalMode"
    static let defaultValue = Self.closeWhenClickingOutside

    var id: Self { self }

    var title: String {
        switch self {
        case .closeWhenClickingOutside:
            "Close when clicking outside"
        case .menuBarButtonOnly:
            "Stay open until clicking the menu-bar button"
        }
    }

    static func current(in defaults: UserDefaults = .standard) -> Self {
        guard let rawValue = defaults.string(forKey: storageKey),
              let mode = Self(rawValue: rawValue) else {
            return defaultValue
        }
        return mode
    }
}
