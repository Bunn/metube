import Foundation

enum SafariUserAgent {
    private static let fallbackVersion = "26.0"

    static var currentMacOS: String {
        let installedVersion = Bundle(path: "/Applications/Safari.app")?
            .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return macOS(installedSafariVersion: installedVersion)
    }

    static func macOS(installedSafariVersion: String?) -> String {
        let version = normalizedVersion(installedSafariVersion)
        return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
            + "AppleWebKit/605.1.15 (KHTML, like Gecko) "
            + "Version/\(version) Safari/605.1.15"
    }

    private static func normalizedVersion(_ installedVersion: String?) -> String {
        guard let installedVersion else { return fallbackVersion }
        let components = installedVersion.split(separator: ".")
        guard components.count >= 2,
              Int(components[0]) != nil,
              Int(components[1]) != nil else {
            return fallbackVersion
        }
        return components.prefix(2).joined(separator: ".")
    }
}
