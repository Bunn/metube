import Foundation
import XCTest
@testable import MeTube

final class NavigationBarPreferencesTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suiteName = "dev.bunn.metube.tests.navigation-bar"

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

    func testMissingOrUnsupportedDelayUsesDefault() {
        XCTAssertEqual(
            NavigationBarPreferences.autoHideDelay(in: defaults),
            NavigationBarPreferences.defaultAutoHideDelay
        )

        defaults.set(19.0, forKey: NavigationBarPreferences.autoHideDelayKey)
        XCTAssertEqual(
            NavigationBarPreferences.autoHideDelay(in: defaults),
            NavigationBarPreferences.defaultAutoHideDelay
        )
    }

    func testSupportedDelayRoundTrips() {
        defaults.set(5.0, forKey: NavigationBarPreferences.autoHideDelayKey)
        XCTAssertEqual(NavigationBarPreferences.autoHideDelay(in: defaults), 5.0)
    }
}
