import XCTest
@testable import MeTube

final class SafariUserAgentTests: XCTestCase {
    func testUsesInstalledSafariMajorAndMinorVersion() {
        XCTAssertEqual(
            SafariUserAgent.macOS(installedSafariVersion: "26.6.2"),
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                + "AppleWebKit/605.1.15 (KHTML, like Gecko) "
                + "Version/26.6 Safari/605.1.15"
        )
    }

    func testMissingOrInvalidVersionUsesSafari26Fallback() {
        for version in [nil, "", "Technology Preview"] as [String?] {
            XCTAssertTrue(
                SafariUserAgent.macOS(installedSafariVersion: version)
                    .contains("Version/26.0 Safari/605.1.15")
            )
        }
    }
}
