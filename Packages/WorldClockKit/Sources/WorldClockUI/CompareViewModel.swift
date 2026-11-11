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
    public var dayRelationText: String { Self.label(for: zoneB.dayRelation(from: zoneA, at: instant)) }

    /// B's date, followed by its day relative to A's when they differ:
    /// "Friday, January 16 · next day", or just "Thursday, January 15" on the same day.
    public var zoneBDateText: String {
        let date = b.dateText
        guard zoneB.dayRelation(from: zoneA, at: instant) != .today else { return date }
        return "\(date) · \(dayRelationText.lowercased())"
    }

    /// `zoneBDateText` as VoiceOver reads it: "Friday, January 16, next day".
    public var zoneBSpokenDate: String {
        zoneBDateText.replacingOccurrences(of: " · ", with: ", ")
    }

    /// What VoiceOver reads for the difference: "Tokyo is 14 hours ahead of New York",
    /// "UTC has the same time as London".
    public var spokenDifference: String {
        let (a, b) = (zoneA.city, zoneB.city)
        guard zoneB.offset(from: zoneA, at: instant) != 0 else { return "\(b) has the same time as \(a)" }
        let offset = zoneB.spokenOffset(from: zoneA, at: instant)
        return "\(b) is \(offset)\(offset.hasSuffix("ahead") ? " of" : "") \(a)"
    }

    /// The scrubber's value for VoiceOver: A's time, then where that puts B, so adjusting it
    /// says the answer: "3:00 PM; in Tokyo 5:00 AM, next day".
    public var scrubberSpokenValue: String {
        let relation = zoneB.dayRelation(from: zoneA, at: instant)
        let day = relation == .today ? "" : ", \(Self.label(for: relation).lowercased())"
        return "\(a.timeText); in \(b.cityText) \(b.timeText)\(day)"
    }

    /// `zoneBDateText` with the longest day label ("2 days earlier"), for sizing the window so
    /// it doesn't change size while scrubbing.
    public var widestZoneBDateText: String {
        let labels = [DayRelation.yesterday, .tomorrow, .days(2), .days(-2)].map { Self.label(for: $0).lowercased() }
        return "\(b.dateText) · \(labels.max { $0.count < $1.count }!)"
    }

    private static func label(for relation: DayRelation) -> String {
        switch relation {
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
    public private(set) var scrubberMarks: [ScrubberMark]

    public struct ScrubberMark: Hashable, Sendable {
        public let minuteOfDay: Int
        public let label: String
    }

    @ObservationIgnored private let store: SettingsStore
    @ObservationIgnored private let minutes: MinuteClock
    @ObservationIgnored private let formatterA: ZoneFormatter
    @ObservationIgnored private let formatterB: ZoneFormatter
    /// Whether the locale shows 12-hour time, for reading typed times without AM/PM.
    @ObservationIgnored private var twelveHour: Bool

    /// - Parameters:
    ///   - defaultZones: shown when nothing (or nothing readable) is saved, each on its own.
    ///   - clock: the current instant; `Date.init` in the app.
    public init(store: SettingsStore, defaultZones: (a: Zone, b: Zone), locale: Locale = .autoupdatingCurrent,
                clock: @escaping () -> Date, ticker: Ticker) {
        self.store = store
        minutes = MinuteClock(clock: clock, ticker: ticker)
        let a = store.compareZoneA ?? defaultZones.a
        let b = store.compareZoneB ?? defaultZones.b
        zoneA = a
        zoneB = b
        now = clock()
        formatterA = ZoneFormatter(zone: a, locale: locale)
        formatterB = ZoneFormatter(zone: b, locale: locale)
        twelveHour = locale.usesTwelveHourTime
        scrubberMarks = Self.marks(locale: locale)
    }

    private static func marks(locale: Locale) -> [ScrubberMark] {
        let hour = Date.FormatStyle(locale: locale, timeZone: Zone.utc.timeZone).hour()
        return stride(from: 0, to: 24 * 60, by: 6 * 60).map { minute in
            ScrubberMark(minuteOfDay: minute, label: hour.format(Date(timeIntervalSince1970: Double(minute * 60))))
        }
    }

    /// Formats times and dates, and reads typed times, for `locale` from now on (the 12/24-hour
    /// setting changed, or the Mac's region settings did). A scrubbed time stays scrubbed.
    public func setLocale(_ locale: Locale) {
        formatterA.locale = locale
        formatterB.locale = locale
        twelveHour = locale.usesTwelveHourTime
        scrubberMarks = Self.marks(locale: locale)
        now = minutes.now()
    }

    /// Refreshes the time and ticks on every minute boundary until `stop`. Call when the window appears.
    public func start() {
        minutes.start { [weak self] in self?.now = $0 }
    }

    /// Stops ticking. Call when the window is hidden.
    public func stop() {
        minutes.stop()
    }

    /// Shows the time `minutes` after midnight in zone A, on the day zone A was on when
    /// scrubbing began. A time skipped by a DST gap moves forward.
    public func scrub(toMinuteOfDay minutes: Int) {
        let day = scrubbed ?? zoneA.wallTime(at: now)
        let clamped = min(max(minutes, 0), 24 * 60 - 1)
        scrubbed = WallTime(year: day.year, month: day.month, day: day.day, hour: clamped / 60, minute: clamped % 60)
    }

    /// Shows the time typed for zone A ("3:15 pm", "15:15", see `TimeEntry`), on the day A
    /// shows. Returns `false`, changing nothing, if `text` isn't a time.
    @discardableResult public func typeTimeA(_ text: String) -> Bool {
        guard let minutes = TimeEntry.minuteOfDay(from: text, twelveHour: twelveHour, editing: scrubberMinuteOfDay)
        else { return false }
        scrub(toMinuteOfDay: minutes)
        return true
    }

    /// Shows the time typed for zone B, on the day B shows; A moves to the same instant (and
    /// may change day). Returns `false`, changing nothing, if `text` isn't a time.
    @discardableResult public func typeTimeB(_ text: String) -> Bool {
        var wall = zoneB.wallTime(at: instant)
        guard let minutes = TimeEntry.minuteOfDay(from: text, twelveHour: twelveHour, editing: wall.hour * 60 + wall.minute)
        else { return false }
        wall.hour = minutes / 60
        wall.minute = minutes % 60
        wall.second = 0
        var a = zoneA.wallTime(at: zoneB.instant(for: wall))
        a.second = 0
        scrubbed = a
        return true
    }

    /// Goes back to showing the current time.
    public func returnToNow() {
        scrubbed = nil
        now = minutes.now()
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
}

extension CompareViewModel {
    /// The app's model: saved in UserDefaults, real time, the Mac's zone (A) and UTC (B) by default,
    /// and `locale` from the settings (`SettingsViewModel.locale`).
    public static func live(locale: Locale) -> CompareViewModel {
        CompareViewModel(
            store: UserDefaultsSettingsStore.live(),
            defaultZones: (.macZoneOrUTC, .utc),
            locale: locale,
            clock: Date.init,
            ticker: DispatchTicker()
        )
    }
}
