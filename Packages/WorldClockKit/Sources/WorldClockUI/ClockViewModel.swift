import Foundation
import Observation
import WorldClockCore

/// Display values for the Clock window: the time in one zone, refreshed on minute boundaries
/// while the window is visible (`start` / `stop`). The chosen zone is saved in `store`.
@MainActor @Observable public final class ClockViewModel {
    public private(set) var zone: Zone
    public private(set) var now: Date

    /// "9:00 PM" or "21:00", following the locale's 12/24-hour preference.
    public var timeText: String { timeFormatter.string(from: now) }
    /// "Thursday, January 15", the date in `zone`.
    public var dateText: String { dateFormatter.string(from: now) }
    /// "Tokyo"
    public var cityText: String { zone.city }
    /// "UTC+9"
    public var offsetText: String { zone.utcOffsetText(at: now) }

    @ObservationIgnored private let store: SettingsStore
    @ObservationIgnored private let clock: () -> Date
    @ObservationIgnored private let ticker: Ticker
    @ObservationIgnored private let timeFormatter: DateFormatter
    @ObservationIgnored private let dateFormatter: DateFormatter

    /// - Parameters:
    ///   - defaultZone: shown when nothing (or nothing readable) is saved.
    ///   - clock: the current instant; `Date.init` in the app.
    public init(store: SettingsStore, defaultZone: Zone, locale: Locale = .autoupdatingCurrent,
                clock: @escaping () -> Date, ticker: Ticker) {
        self.store = store
        self.clock = clock
        self.ticker = ticker
        let zone = store.clockZone ?? defaultZone
        self.zone = zone
        self.now = clock()
        timeFormatter = Self.formatter(template: "jmm", locale: locale, zone: zone)
        dateFormatter = Self.formatter(template: "EEEEMMMMd", locale: locale, zone: zone)
    }

    /// Refreshes the time and ticks on every minute boundary until `stop`. Call when the window appears.
    public func start() {
        tick()
    }

    /// Stops ticking. Call when the window is hidden, so the app does no work in the background.
    public func stop() {
        ticker.cancel()
    }

    /// Shows `zone` and saves it for the next launch.
    public func select(_ zone: Zone) {
        self.zone = zone
        timeFormatter.timeZone = zone.timeZone
        dateFormatter.timeZone = zone.timeZone
        store.clockZone = zone
    }

    private func tick() {
        now = clock()
        ticker.schedule(at: Self.nextMinute(after: now)) { [weak self] in self?.tick() }
    }

    /// The first whole minute after `date`. Every zone in use today is offset from UTC by
    /// whole minutes, so a UTC minute boundary is a minute boundary everywhere.
    static func nextMinute(after date: Date) -> Date {
        let t = date.timeIntervalSinceReferenceDate
        return Date(timeIntervalSinceReferenceDate: (t / 60).rounded(.down) * 60 + 60)
    }

    private static func formatter(template: String, locale: Locale, zone: Zone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = zone.timeZone
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter
    }
}

extension ClockViewModel {
    /// The app's model: saved in UserDefaults, real time, and the Mac's zone as the default.
    public static func live() -> ClockViewModel {
        ClockViewModel(
            store: UserDefaultsSettingsStore(),
            // The Mac's zone can be missing from the known list (e.g. `Asia/Kolkata` on a
            // system that lists `Asia/Calcutta`); UTC is the fallback then.
            defaultZone: Zone(identifier: TimeZone.current.identifier) ?? Zone(identifier: "UTC")!,
            clock: Date.init,
            ticker: DispatchTicker()
        )
    }
}
