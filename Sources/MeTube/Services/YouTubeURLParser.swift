import Foundation

enum YouTubeURLParser {
    private static let validVideoIDCharacters = CharacterSet(
        charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"
    )

    static func video(from url: URL) -> YouTubeVideo? {
        guard let host = url.host?.lowercased(), isYouTubeHost(host) else { return nil }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        let candidate: String?

        if host == "youtu.be" {
            candidate = pathComponents.first
        } else if pathComponents.first == "watch" {
            candidate = components?.queryItems?.first(where: { $0.name == "v" })?.value
        } else if ["embed", "shorts", "live"].contains(pathComponents.first) {
            candidate = pathComponents.dropFirst().first
        } else {
            candidate = nil
        }

        guard let candidate, isValidVideoID(candidate) else { return nil }
        let startValue = components?.queryItems?.first(where: { ["t", "start"].contains($0.name) })?.value
        return YouTubeVideo(id: candidate, startSeconds: parseStartTime(startValue))
    }

    static func video(fromUserInput input: String) -> YouTubeVideo? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if isValidVideoID(trimmed) {
            return YouTubeVideo(id: trimmed, startSeconds: nil)
        }

        guard let url = normalizedURL(from: trimmed) else { return nil }
        return video(from: url)
    }

    static func normalizedURL(from input: String) -> URL? {
        if let url = URL(string: input), url.scheme != nil {
            return url
        }

        let lowercased = input.lowercased()
        if lowercased.hasPrefix("youtube.com/")
            || lowercased.hasPrefix("www.youtube.com/")
            || lowercased.hasPrefix("m.youtube.com/")
            || lowercased.hasPrefix("youtu.be/") {
            return URL(string: "https://\(input)")
        }

        return nil
    }

    static func searchURL(for query: String) -> URL {
        guard var components = URLComponents(string: "https://m.youtube.com/results") else {
            preconditionFailure("The YouTube search URL literal must be valid")
        }
        components.queryItems = [URLQueryItem(name: "search_query", value: query)]
        guard let url = components.url else {
            preconditionFailure("A search query must produce a valid YouTube URL")
        }
        return url
    }

    static func isYouTubeHost(_ host: String) -> Bool {
        host == "youtu.be"
            || host == "youtube.com"
            || host.hasSuffix(".youtube.com")
            || host == "youtube-nocookie.com"
            || host.hasSuffix(".youtube-nocookie.com")
    }

    private static func isValidVideoID(_ candidate: String) -> Bool {
        candidate.count == 11
            && candidate.unicodeScalars.allSatisfy(validVideoIDCharacters.contains)
    }

    private static func parseStartTime(_ value: String?) -> Int? {
        guard let value = value?.lowercased(), !value.isEmpty else { return nil }
        if let seconds = Int(value) {
            return max(0, seconds)
        }

        var total = 0
        var currentDigits = ""
        var foundUnit = false

        for character in value {
            if character.isNumber {
                currentDigits.append(character)
                continue
            }

            guard let amount = Int(currentDigits) else { return nil }
            switch character {
            case "h": total += amount * 3_600
            case "m": total += amount * 60
            case "s": total += amount
            default: return nil
            }
            currentDigits = ""
            foundUnit = true
        }

        if !currentDigits.isEmpty {
            guard let seconds = Int(currentDigits) else { return nil }
            total += seconds
        }
        return foundUnit || total > 0 ? total : nil
    }
}
