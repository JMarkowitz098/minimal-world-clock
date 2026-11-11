import Foundation

/// The current time for a view model: read now, and again on every minute boundary between
/// `start` and `stop` while the window is visible. Shared by the Clock and Compare view models
/// so the ticking rules (one tick at a time, nothing while stopped or hidden) live in one place.
@MainActor final class MinuteClock {
    private let clock: () -> Date
    private let ticker: Ticker
    /// Set between `start` and `stop`.
    private var onTick: (@MainActor (Date) -> Void)?
    private var isVisible = true

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

    /// Calls `onTick` with the current time right away and on every minute boundary until
    /// `stop`, skipping the time the window is hidden (`setVisible`).
    func start(_ onTick: @escaping @MainActor (Date) -> Void) {
        self.onTick = onTick
        tick()
    }

    /// Stops ticking. Call when the window closes.
    func stop() {
        onTick = nil
        ticker.cancel()
    }

    /// Pauses ticking while the window can't be seen (minimized, covered, on another Space, the
    /// app hidden), and catches up right away when it can again. Doesn't start a stopped clock.
    func setVisible(_ visible: Bool) {
        guard visible != isVisible else { return }
        isVisible = visible
        if visible { tick() } else { ticker.cancel() }
    }

    private func tick() {
        guard let onTick else { return }
        let now = clock()
        onTick(now)
        guard isVisible else { return }
        ticker.schedule(at: now.nextMinuteBoundary) { [weak self] in self?.tick() }
    }
}
