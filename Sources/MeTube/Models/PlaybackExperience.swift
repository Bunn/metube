import Foundation

enum PlaybackExperience: String, CaseIterable, Identifiable {
    case optimizedPlayer
    case fullYouTubePage

    static let storageKey = "playbackExperience"
    static let defaultValue = PlaybackExperience.optimizedPlayer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .optimizedPlayer:
            "Optimized player"
        case .fullYouTubePage:
            "Full YouTube page"
        }
    }

    var detail: String {
        switch self {
        case .optimizedPlayer:
            "Uses less memory and CPU by loading only the video player. Comments are unavailable."
        case .fullYouTubePage:
            "Loads the normal watch page, including comments and recommendations. This uses more memory and CPU."
        }
    }

    static func current(in defaults: UserDefaults = .standard) -> PlaybackExperience {
        guard let rawValue = defaults.string(forKey: storageKey),
              let experience = PlaybackExperience(rawValue: rawValue) else {
            return defaultValue
        }
        return experience
    }
}
