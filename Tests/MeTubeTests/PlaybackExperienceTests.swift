import Foundation
import XCTest
@testable import MeTube

final class PlaybackExperienceTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suiteName = "dev.bunn.metube.tests.playback-experience"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testMissingOrInvalidPreferenceUsesOptimizedPlayer() {
        XCTAssertEqual(PlaybackExperience.current(in: defaults), .optimizedPlayer)

        defaults.set("invalid", forKey: PlaybackExperience.storageKey)
        XCTAssertEqual(PlaybackExperience.current(in: defaults), .optimizedPlayer)
    }

    func testFullPagePreferenceRoundTrips() {
        defaults.set(
            PlaybackExperience.fullYouTubePage.rawValue,
            forKey: PlaybackExperience.storageKey
        )

        XCTAssertEqual(PlaybackExperience.current(in: defaults), .fullYouTubePage)
    }
}
