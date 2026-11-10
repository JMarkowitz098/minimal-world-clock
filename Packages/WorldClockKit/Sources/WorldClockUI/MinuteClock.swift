import Foundation

/// The current time for a view model: read now, and again on every minute boundary between
/// `start` and `stop`. Shared by the Clock and Compare view models so the ticking rules (one
/// tick at a time, nothing while stopped; later: seconds in M7, pausing while minimized in M10)
/// live in one place.
@MainActor final class MinuteClock {
    private let clock: () -> Date
    private let ticker: Ticker

    /// - Parameters:
    ///   - clock: the current instant; `Date.init` in the app.
    ///   - ticker: schedules the next tick; a fake in tests.
    init(clock: @escaping () -> Date, ticker: Ticker) {
        self.clock = clock
        self.ticker = ticker
    }

    /// The current instant.
    func now() -> Date {
        clock()
    }

    /// Calls `onTick` with the current time right away and on every minute boundary until `stop`.
    func start(_ onTick: @escaping @MainActor (Date) -> Void) {
        let now = clock()
        onTick(now)
        ticker.schedule(at: now.nextMinuteBoundary) { [weak self] in self?.start(onTick) }
    }

    /// Stops ticking. Call when the window is hidden, so the app does no work in the background.
    func stop() {
        ticker.cancel()
    }
}
