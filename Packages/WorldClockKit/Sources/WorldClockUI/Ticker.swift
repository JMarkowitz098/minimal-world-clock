import Foundation

/// Calls back at a chosen moment. View models schedule one tick at a time (the next minute
/// boundary), so the app is idle between ticks. Injected so tests can fire ticks by hand.
@MainActor public protocol Ticker: AnyObject {
    /// Calls `action` on the main actor at `date`, replacing any pending call.
    func schedule(at date: Date, _ action: @escaping @MainActor () -> Void)
    /// Drops the pending call, if any.
    func cancel()
}

/// The app's ticker. It waits on a wall-clock deadline, so a tick due while the Mac slept
/// fires right after it wakes instead of an uptime-based interval later.
@MainActor public final class DispatchTicker: Ticker {
    private var pending: DispatchWorkItem?

    public init() {}

    public func schedule(at date: Date, _ action: @escaping @MainActor () -> Void) {
        cancel()
        let item = DispatchWorkItem {
            MainActor.assumeIsolated { action() }
        }
        pending = item
        DispatchQueue.main.asyncAfter(wallDeadline: .now() + max(0, date.timeIntervalSinceNow), execute: item)
    }

    public func cancel() {
        pending?.cancel()
        pending = nil
    }
}

extension Date {
    /// The first whole minute after this date. Every zone in use today is offset from UTC by
    /// whole minutes, so a UTC minute boundary is a minute boundary everywhere.
    var nextMinuteBoundary: Date {
        let t = timeIntervalSinceReferenceDate
        return Date(timeIntervalSinceReferenceDate: (t / 60).rounded(.down) * 60 + 60)
    }
}
