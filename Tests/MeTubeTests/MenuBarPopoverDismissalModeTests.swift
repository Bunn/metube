import Foundation
import XCTest
@testable import MeTube

final class MenuBarPopoverDismissalModeTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suiteName = "dev.bunn.metube.tests.popover-dismissal"

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

    func testMissingOrInvalidPreferenceUsesCloseOnOutsideClick() {
        XCTAssertEqual(
            MenuBarPopoverDismissalMode.current(in: defaults),
            .closeWhenClickingOutside
        )

        defaults.set("invalid", forKey: MenuBarPopoverDismissalMode.storageKey)
        XCTAssertEqual(
            MenuBarPopoverDismissalMode.current(in: defaults),
            .closeWhenClickingOutside
        )
    }

    func testButtonOnlyPreferenceRoundTrips() {
        defaults.set(
            MenuBarPopoverDismissalMode.menuBarButtonOnly.rawValue,
            forKey: MenuBarPopoverDismissalMode.storageKey
        )

        XCTAssertEqual(
            MenuBarPopoverDismissalMode.current(in: defaults),
            .menuBarButtonOnly
        )
    }
}
