import Foundation
import Observation
import WorldClockCore

/// Display values for the Clock window: the time in one zone, refreshed on minute boundaries
/// while the window is visible (`start` / `stop`). The chosen zone is saved in `store`.
@MainActor @Observable public final class ClockViewModel {
    public private(set) var zone: Zone
    public private(set) var now: Date

    private var display: ZoneDisplay { formatter.display(at: now) }
    /// "9:00 PM" or "21:00", following the locale's 12/24-hour preference.
    public var timeText: String { display.timeText }
    /// `timeText` with its parts marked, for drawing AM/PM smaller.
    public var time: AttributedString { display.time }
    /// "Thursday, January 15", the date in `zone`.
    public var dateText: String { display.dateText }
    /// "Tokyo"
    public var cityText: String { display.cityText }
    /// "UTC+9"
    public var offsetText: String { display.offsetText }

    @ObservationIgnored private let store: SettingsStore
    @ObservationIgnored private let clock: () -> Date
    @ObservationIgnored private let ticker: Ticker
    @ObservationIgnored private let formatter: ZoneFormatter

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
        formatter = ZoneFormatter(zone: zone, locale: locale)
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
        formatter.zone = zone
        self.zone = zone
        store.clockZone = zone
    }

    private func tick() {
        now = clock()
        ticker.schedule(at: now.nextMinuteBoundary) { [weak self] in self?.tick() }
    }
}

extension ClockViewModel {
    /// The app's model: saved in UserDefaults, real time, and the Mac's zone as the default.
    public static func live() -> ClockViewModel {
        ClockViewModel(
            store: UserDefaultsSettingsStore(),
            defaultZone: .macZoneOrUTC,
            clock: Date.init,
            ticker: DispatchTicker()
        )
    }
}

extension Zone {
    /// The Mac's zone, or UTC when it's missing from the known list. Only for `live()` factories.
    static var macZoneOrUTC: Zone {
        Zone(systemZone: .current)
    }
}
