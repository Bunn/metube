import Combine
import Foundation

@MainActor
final class NavigationBarVisibilityController: NSObject, ObservableObject {
    @Published private(set) var isVisible = true

    private var autoHide = NavigationBarPreferences.defaultAutoHide
    private var delay = NavigationBarPreferences.defaultAutoHideDelay
    private var canHide = false
    private var timer: Timer?

    func configure(autoHide: Bool, delay: TimeInterval, canHide: Bool) {
        self.autoHide = autoHide
        self.delay = delay
        self.canHide = canHide

        if autoHide, canHide {
            scheduleHide()
        } else {
            reveal()
        }
    }

    func recordPointerActivity() {
        reveal()
        guard autoHide, canHide else { return }
        scheduleHide()
    }

    func reveal() {
        isVisible = true
        timer?.invalidate()
        timer = nil
    }

    private func scheduleHide() {
        timer?.invalidate()
        let timer = Timer(
            timeInterval: delay,
            target: self,
            selector: #selector(hideTimerFired(_:)),
            userInfo: nil,
            repeats: false
        )
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    @objc private func hideTimerFired(_ timer: Timer) {
        guard autoHide, canHide else { return }
        isVisible = false
        self.timer = nil
    }
}
