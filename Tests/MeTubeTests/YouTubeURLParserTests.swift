import XCTest
@testable import MeTube

final class YouTubeURLParserTests: XCTestCase {
    func testWatchURLParsesVideoAndCompoundTimestamp() throws {
        let url = try XCTUnwrap(URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=1h2m3s"))

        XCTAssertEqual(
            YouTubeURLParser.video(from: url),
            YouTubeVideo(id: "dQw4w9WgXcQ", startSeconds: 3_723)
        )
    }

    func testShortURLParsesVideoAndNumericTimestamp() throws {
        let url = try XCTUnwrap(URL(string: "https://youtu.be/dQw4w9WgXcQ?t=42"))

        XCTAssertEqual(
            YouTubeURLParser.video(from: url),
            YouTubeVideo(id: "dQw4w9WgXcQ", startSeconds: 42)
        )
    }

    func testShortsAndEmbedURLsParse() throws {
        let shorts = try XCTUnwrap(URL(string: "https://m.youtube.com/shorts/dQw4w9WgXcQ"))
        let embed = try XCTUnwrap(URL(string: "https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ?start=9"))

        XCTAssertEqual(YouTubeURLParser.video(from: shorts)?.id, "dQw4w9WgXcQ")
        XCTAssertEqual(YouTubeURLParser.video(from: embed)?.startSeconds, 9)
    }

    func testLookalikeDomainIsRejected() throws {
        let url = try XCTUnwrap(URL(string: "https://youtube.com.example.org/watch?v=dQw4w9WgXcQ"))

        XCTAssertNil(YouTubeURLParser.video(from: url))
    }

    func testBareVideoIDIsAccepted() {
        XCTAssertEqual(
            YouTubeURLParser.video(fromUserInput: "dQw4w9WgXcQ"),
            YouTubeVideo(id: "dQw4w9WgXcQ", startSeconds: nil)
        )
    }

    func testSearchURLUsesMobileYouTube() {
        let url = YouTubeURLParser.searchURL(for: "swift concurrency")
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        XCTAssertEqual(url.host, "m.youtube.com")
        XCTAssertEqual(components?.queryItems?.first?.value, "swift concurrency")
    }
}
