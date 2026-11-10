import Foundation
import Observation
import WorldClockCore

/// Display values for the Compare window: the same instant in two zones. The instant is live
/// (now, refreshed on minute boundaries between `start` and `stop`) until the user scrubs to a
/// time of day in zone A; `returnToNow` goes back to live. Both zones are saved in `store`.
@MainActor @Observable public final class CompareViewModel {
    public private(set) var zoneA: Zone
    public private(set) var zoneB: Zone
    public private(set) var now: Date
    /// The time the user scrubbed to, read on zone A's clocks; `nil` while live.
    private(set) var scrubbed: WallTime?

    /// Whether the instant shown is now (as opposed to a scrubbed time).
    public var isLive: Bool { scrubbed == nil }
    /// The instant both zones show.
    public var instant: Date { scrubbed.map(zoneA.instant(for:)) ?? now }

    public var a: ZoneDisplay { formatterA.display(at: instant) }
    public var b: ZoneDisplay { formatterB.display(at: instant) }
    /// How far B is ahead of A: "+14 h", "−3 h 30 min", "Same time".
    public var differenceText: String { zoneB.offsetText(from: zoneA, at: instant) }
    /// B's date relative to A's: "Same day", "Next day", "Previous day", "2 days later".
    public var dayRelationText: String {
        switch zoneB.dayRelation(from: zoneA, at: instant) {
        case .today: "Same day"
        case .tomorrow: "Next day"
        case .yesterday: "Previous day"
        case .days(let n): n > 0 ? "\(n) days later" : "\(-n) days earlier"
        }
    }

    /// Zone A's time of day in minutes since midnight (0...1439), for the scrubber.
    public var scrubberMinuteOfDay: Int {
        let wall = zoneA.wallTime(at: instant)
        return wall.hour * 60 + wall.minute
    }

    /// Labels under the scrubber every six hours: "12 AM", "6 AM"… (or "00", "06"… in 24-hour
    /// locales), at their minute of the day.
    public let scrubberMarks: [ScrubberMark]

    public struct ScrubberMark: Hashable, Sendable {
        public let minuteOfDay: Int
        public let label: String
    }

    @ObservationIgnored private let store: SettingsStore
    @ObservationIgnored private let clock: () -> Date
    @ObservationIgnored private let ticker: Ticker
    @ObservationIgnored private let formatterA: ZoneFormatter
    @ObservationIgnored private let formatterB: ZoneFormatter

    /// - Parameters:
    ///   - defaultZones: shown when nothing (or nothing readable) is saved, each on its own.
    ///   - clock: the current instant; `Date.init` in the app.
    public init(store: SettingsStore, defaultZones: (a: Zone, b: Zone), locale: Locale = .autoupdatingCurrent,
                clock: @escaping () -> Date, ticker: Ticker) {
        self.store = store
        self.clock = clock
        self.ticker = ticker
        let a = store.compareZoneA ?? defaultZones.a
        let b = store.compareZoneB ?? defaultZones.b
        zoneA = a
        zoneB = b
        now = clock()
        formatterA = ZoneFormatter(zone: a, locale: locale)
        formatterB = ZoneFormatter(zone: b, locale: locale)
        let utc = TimeZone(identifier: "UTC")!
        let hour = Date.FormatStyle(locale: locale, timeZone: utc).hour()
        scrubberMarks = stride(from: 0, to: 24 * 60, by: 6 * 60).map { minute in
            ScrubberMark(minuteOfDay: minute, label: hour.format(Date(timeIntervalSince1970: Double(minute * 60))))
        }
    }

    /// Refreshes the time and ticks on every minute boundary until `stop`. Call when the window appears.
    public func start() {
        tick()
    }

    /// Stops ticking. Call when the window is hidden.
    public func stop() {
        ticker.cancel()
    }

    /// Shows the time `minutes` after midnight in zone A, on the day zone A was on when
    /// scrubbing began. A time skipped by a DST gap moves forward.
    public func scrub(toMinuteOfDay minutes: Int) {
        let day = scrubbed ?? zoneA.wallTime(at: now)
        let clamped = min(max(minutes, 0), 24 * 60 - 1)
        scrubbed = WallTime(year: day.year, month: day.month, day: day.day, hour: clamped / 60, minute: clamped % 60)
    }

    /// Goes back to showing the current time.
    public func returnToNow() {
        scrubbed = nil
        now = clock()
    }

    /// Exchanges the zones, keeping the instant shown.
    public func swap() {
        let shown = instant
        let (oldA, oldB) = (zoneA, zoneB)
        setZoneA(oldB)
        setZoneB(oldA)
        if scrubbed != nil {
            var wall = zoneA.wallTime(at: shown)
            wall.second = 0
            scrubbed = wall
        }
    }

    /// Changes zone A. A scrubbed time keeps its reading (3 PM stays 3 PM in the new zone).
    public func selectA(_ zone: Zone) {
        setZoneA(zone)
    }

    /// Changes zone B; the instant stays the same.
    public func selectB(_ zone: Zone) {
        setZoneB(zone)
    }

    private func setZoneA(_ zone: Zone) {
        formatterA.zone = zone
        zoneA = zone
        store.compareZoneA = zone
    }

    private func setZoneB(_ zone: Zone) {
        formatterB.zone = zone
        zoneB = zone
        store.compareZoneB = zone
    }

    private func tick() {
        now = clock()
        ticker.schedule(at: now.nextMinuteBoundary) { [weak self] in self?.tick() }
    }
}

extension CompareViewModel {
    /// The app's model: saved in UserDefaults, real time, the Mac's zone (A) and UTC (B) by default.
    public static func live() -> CompareViewModel {
        CompareViewModel(
            store: UserDefaultsSettingsStore(),
            defaultZones: (.macZoneOrUTC, Zone(identifier: "UTC")!),
            clock: Date.init,
            ticker: DispatchTicker()
        )
    }
}
