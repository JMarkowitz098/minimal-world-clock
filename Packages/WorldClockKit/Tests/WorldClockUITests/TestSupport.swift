import Foundation
@testable import WorldClockCore
@testable import WorldClockUI

/// Fixed instants in UTC. Never the Mac's own clock or zone.
func utc(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, _ second: Int = 0) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second))!
}

func zone(_ identifier: String) -> Zone {
    Zone(identifier: identifier)!
}

/// January 15, 2026, 12:00 UTC: a Thursday; 21:00 in Tokyo.
let jan15Noon = utc(2026, 1, 15, 12, 0)

/// Narrow no-break space, which en_US puts before AM/PM.
let nnbsp = "\u{202F}"

/// A clock the test moves by hand.
final class FakeClock {
    var now: Date
    init(_ now: Date) { self.now = now }
}

/// A ticker that records what was scheduled and fires only when the test says so.
@MainActor final class FakeTicker: Ticker {
    private(set) var scheduledDate: Date?
    private var action: (@MainActor () -> Void)?

    func schedule(at date: Date, _ action: @escaping @MainActor () -> Void) {
        scheduledDate = date
        self.action = action
    }

    func cancel() {
        scheduledDate = nil
        action = nil
    }

    /// Runs the pending action, as the real ticker would at `scheduledDate`.
    func fire() {
        let pending = action
        scheduledDate = nil
        action = nil
        pending?()
    }
}

@MainActor func makeClock(
    at now: Date = jan15Noon,
    store: SettingsStore = InMemorySettingsStore(),
    defaultZone: Zone = zone("Asia/Tokyo")
) -> (ClockViewModel, FakeClock, FakeTicker) {
    let clock = FakeClock(now)
    let ticker = FakeTicker()
    let model = ClockViewModel(
        store: store, defaultZone: defaultZone, locale: Locale(identifier: "en_US"),
        clock: { clock.now }, ticker: ticker
    )
    return (model, clock, ticker)
}

/// A Compare model at `now` whose defaults are New York (A) and Tokyo (B).
@MainActor func makeCompare(
    at now: Date = jan15Noon,
    store: SettingsStore = InMemorySettingsStore(),
    a: Zone = zone("America/New_York"),
    b: Zone = zone("Asia/Tokyo"),
    locale: String = "en_US"
) -> (CompareViewModel, FakeClock, FakeTicker) {
    let clock = FakeClock(now)
    let ticker = FakeTicker()
    let model = CompareViewModel(
        store: store, defaultZones: (a, b), locale: Locale(identifier: locale),
        clock: { clock.now }, ticker: ticker
    )
    return (model, clock, ticker)
}

/// A zone shown under its own city.
func place(_ identifier: String) -> Place {
    Place(zone(identifier))
}
