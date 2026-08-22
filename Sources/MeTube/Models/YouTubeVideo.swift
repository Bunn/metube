import Foundation

struct YouTubeVideo: Equatable {
    let id: String
    let startSeconds: Int?

    var canonicalURL: URL {
        guard var components = URLComponents(string: "https://www.youtube.com/watch") else {
            preconditionFailure("The canonical YouTube URL literal must be valid")
        }
        var items = [URLQueryItem(name: "v", value: id)]
        if let startSeconds, startSeconds > 0 {
            items.append(URLQueryItem(name: "t", value: String(startSeconds)))
        }
        components.queryItems = items
        guard let url = components.url else {
            preconditionFailure("A validated video ID must produce a canonical YouTube URL")
        }
        return url
    }

    var embedURL: URL {
        guard var components = URLComponents(string: "https://www.youtube-nocookie.com/embed/\(id)") else {
            preconditionFailure("A validated video ID must produce an embed URL")
        }
        var items = [
            URLQueryItem(name: "autoplay", value: "1"),
            URLQueryItem(name: "playsinline", value: "1"),
            URLQueryItem(name: "rel", value: "0")
        ]
        if let startSeconds, startSeconds > 0 {
            items.append(URLQueryItem(name: "start", value: String(startSeconds)))
        }
        components.queryItems = items
        guard let url = components.url else {
            preconditionFailure("A validated video ID must produce a complete embed URL")
        }
        return url
    }
}
