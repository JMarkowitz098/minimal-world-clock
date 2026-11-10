import Foundation
import WorldClockCore

/// What the desktop widget shows for one zone at a timeline entry's date. The date and offset
/// are fixed strings (the timeline refreshes when they change, see `Zone.nextDisplayChange`);
/// the time is live, drawn by the system from `hourMinuteFormat` and `dayPeriodFormat`.
public struct WidgetDisplay: Equatable, Sendable {
    /// "Tokyo"
    public var cityText: String
    /// "Thursday, January 15" (medium widget)
    public var dateText: String
    /// "Thu, Jan 15" (small widget)
    public var shortDateText: String
    /// "UTC+9"
    public var offsetText: String
    /// Hours and minutes in the zone without AM/PM ("9:00", or "21:00" in a 24-hour locale).
    public var hourMinuteFormat: Date.FormatStyle
    /// AM/PM alone ("PM"), drawn smaller beside the time like the windows' time; nil in a
    /// 24-hour locale. Both are system format types: the widget is drawn from an archived view
    /// and stays on its placeholder with a custom format (ROADMAP → Notes).
    public var dayPeriodFormat: Date.VerbatimFormatStyle?
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
        let usesDayPeriod = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: locale)?.contains("a") ?? false
        dayPeriodFormat = usesDayPeriod
            ? Date.VerbatimFormatStyle(format: "\(dayPeriod: .standard(.abbreviated))", locale: locale,
                                       timeZone: zone.timeZone, calendar: Calendar(identifier: .gregorian))
            : nil
        timeZone = zone.timeZone
    }
}
