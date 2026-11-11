import Foundation
import Observation
import WorldClockCore

/// Display values for the Clock window: the time in one zone, refreshed on minute boundaries
/// while the window is visible (`start` / `stop`). The chosen place (zone and city) is saved in
/// `store`.
@MainActor @Observable public final class ClockViewModel {
    public private(set) var place: Place
    public var zone: Zone { place.zone }
    public private(set) var now: Date

    private var display: ZoneDisplay { formatter.display(at: now) }
    /// "9:00 PM" or "21:00", following the locale's 12/24-hour preference.
    public var timeText: String { display.timeText }
    /// `timeText` with its parts marked, for drawing AM/PM smaller.
    public var time: AttributedString { display.time }
    /// "Thursday, January 15", the date in `zone`.
    public var dateText: String { display.dateText }
    /// "Tokyo", or the city picked in the zone ("San Francisco")
    public var cityText: String { display.cityText }
    /// What VoiceOver reads for the time and date: "Tokyo, 9:00 PM, Thursday, January 15".
    public var spokenText: String { "\(display.cityText), \(display.timeText), \(display.dateText)" }

    @ObservationIgnored private let store: SettingsStore
    @ObservationIgnored private let minutes: MinuteClock
    @ObservationIgnored private let formatter: ZoneFormatter

    /// - Parameters:
    ///   - defaultZone: shown when nothing (or nothing readable) is saved.
    ///   - clock: the current instant; `Date.init` in the app.
    public init(store: SettingsStore, defaultZone: Zone, locale: Locale = .autoupdatingCurrent,
                clock: @escaping () -> Date, ticker: Ticker) {
        self.store = store
        minutes = MinuteClock(clock: clock, ticker: ticker)
        let place = store.clockPlace ?? Place(defaultZone)
        self.place = place
        self.now = clock()
        formatter = ZoneFormatter(place: place, locale: locale)
    }

    /// Refreshes the time and ticks on every minute boundary until `stop`. Call when the window appears.
    public func start() {
        minutes.start { [weak self] in self?.now = $0 }
    }

    /// Stops ticking. Call when the window is hidden, so the app does no work in the background.
    public func stop() {
        minutes.stop()
    }

    /// Formats times and dates for `locale` from now on (the 12/24-hour setting changed, or
    /// the Mac's region settings did).
    public func setLocale(_ locale: Locale) {
        formatter.locale = locale
        now = minutes.now()
    }

    /// Shows `place` and saves it for the next launch.
    public func select(_ place: Place) {
        formatter.place = place
        self.place = place
        store.clockPlace = place
    }
}

extension ClockViewModel {
    /// The app's model: saved in UserDefaults, real time, the Mac's zone as the default, and
    /// `locale` from the settings (`SettingsViewModel.locale`).
    public static func live(locale: Locale) -> ClockViewModel {
        ClockViewModel(
            store: UserDefaultsSettingsStore.live(),
            defaultZone: .macZoneOrUTC,
            locale: locale,
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
