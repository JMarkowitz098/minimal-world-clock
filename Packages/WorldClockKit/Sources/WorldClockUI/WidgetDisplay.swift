import Foundation
import WorldClockCore

/// What the desktop widget shows for one zone at a timeline entry's date. The date and offset
/// are fixed strings (the timeline refreshes when they change, see `Zone.nextDisplayChange`);
/// hours and minutes are live, drawn by the system from `hourMinuteFormat`.
public struct WidgetDisplay: Equatable, Sendable {
    /// "Tokyo"
    public var cityText: String
    /// "Thursday, January 15" (medium widget)
    public var dateText: String
    /// "Thu, Jan 15" (small widget)
    public var shortDateText: String
    /// "UTC+9"
    public var offsetText: String
    /// Hours and minutes at the entry's date ("9:00"), as fixed text. The view lays the live
    /// time over it: on the desktop a live `Text` takes all the width it can, which pushed the
    /// time off center. Its width only changes when the hour gains or loses a digit, and the
    /// timeline has an entry then (`entryDates`).
    public var timeText: String
    /// Hours and minutes in the zone without AM/PM ("9:00", or "21:00" in a 24-hour locale).
    public var hourMinuteFormat: Date.FormatStyle
    /// AM/PM ("PM"), drawn smaller beside the time like the windows' time; nil in a 24-hour
    /// locale. Fixed text rather than live: on the desktop a live `Text` takes all the width it
    /// can, which pushed the time off center. It changes at noon and midnight, when the
    /// timeline refreshes anyway (`Zone.nextDisplayChange`).
    public var dayPeriodText: String?
    /// The zone's time zone. SwiftUI's `Text(_:format:)` replaces the format's time zone with
    /// the environment's, so the view must also set `\.timeZone` to this.
    public var timeZone: TimeZone

    public init(zone: Zone, at instant: Date, locale: Locale) {
        let display = ZoneFormatter(zone: zone, locale: locale).display(at: instant)
        let shortDate = DateFormatter()
        shortDate.locale = locale
        shortDate.timeZone = zone.timeZone
        shortDate.setLocalizedDateFormatFromTemplate("EEEMMMd")
        cityText = display.cityText
        dateText = display.dateText
        shortDateText = shortDate.string(from: instant)
        offsetText = display.offsetText
        hourMinuteFormat = Date.FormatStyle(locale: locale, timeZone: zone.timeZone)
            .hour(.defaultDigits(amPM: .omitted)).minute()
        timeText = hourMinuteFormat.format(instant)
        let usesDayPeriod = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: locale)?.contains("a") ?? false
        dayPeriodText = usesDayPeriod
            ? Date.VerbatimFormatStyle(format: "\(dayPeriod: .standard(.abbreviated))", locale: locale,
                                       timeZone: zone.timeZone, calendar: Calendar(identifier: .gregorian))
                .format(instant)
            : nil
        timeZone = zone.timeZone
    }

    /// The widget's next `count` timeline dates after `now`: when the date, AM/PM or offset
    /// changes (`Zone.displayChanges`), or the time's width does (9:59 → 10:00, 12:59 → 1:00),
    /// since `timeText` sizes the live time. Several a day at most; never one per minute.
    public static func entryDates(zone: Zone, after now: Date, locale: Locale, count: Int) -> [Date] {
        let format = Date.FormatStyle(locale: locale, timeZone: zone.timeZone)
            .hour(.defaultDigits(amPM: .omitted)).minute()
        var dates = Set(zone.displayChanges(after: now, count: count))
        // Every UTC offset is a multiple of 15 minutes, so stepping by 15 minutes from a quarter
        // hour visits every wall-clock hour; compare each with the minute before it.
        var t = Date(timeIntervalSince1970: (now.timeIntervalSince1970 / 900).rounded(.down) * 900 + 900)
        let end = dates.max() ?? now
        while t <= end {
            if format.format(t).count != format.format(t.addingTimeInterval(-60)).count { dates.insert(t) }
            t.addTimeInterval(900)
        }
        return Array(dates.sorted().prefix(count))
    }
}
